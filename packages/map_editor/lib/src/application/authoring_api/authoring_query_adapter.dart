import 'dart:async';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../services/editor_snapshot_profile_recorder.dart';
import 'authoring_session_lifecycle.dart';

/// Opens one coherent Authoring snapshot for the editor's read projections.
///
/// This adapter intentionally exposes typed PokeMap models to the editor while
/// keeping handles, path authorization, revision calculation, query ordering,
/// pagination, and reference diagnostics owned by `map_authoring`.

final class AuthoringQueryAdapter
    implements EditorAuthoringLifecycleParticipant {
  AuthoringQueryAdapter({
    required ProjectFileReader fileReader,
    ProjectSnapshotFingerprintCache? fingerprintCache,
    ProjectSnapshotCache? snapshotCache,
    EditorSnapshotProfileRecorder? profileRecorder,
  }) : _fileReader = fileReader,
       _fingerprintCache =
           fingerprintCache ?? ProjectSnapshotFingerprintCache(),
       _snapshotCache = snapshotCache ?? ProjectSnapshotCache(),
       _profileRecorder = profileRecorder;

  final ProjectFileReader _fileReader;
  final ProjectSnapshotFingerprintCache _fingerprintCache;
  final ProjectSnapshotCache _snapshotCache;
  final EditorSnapshotProfileRecorder? _profileRecorder;
  final Map<String, Future<EditorAuthoringReadSession>> _sessions = {};
  final Set<String> _openingRoots = {};
  String? _retainedRoot;
  String? _candidateRoot;
  int _retiringSessions = 0;
  int _activeOperations = 0;
  int _closeCount = 0;

  EditorAuthoringSessionDiagnostics get diagnostics =>
      EditorAuthoringSessionDiagnostics(
        retainedRoot: _retainedRoot,
        candidateRoot: _candidateRoot,
        liveSessions: _sessions.length,
        openingSessions: _openingRoots.length,
        retiringSessions: _retiringSessions,
        activeOperations: _activeOperations,
        closeCount: _closeCount,
      );

  Future<EditorAuthoringReadSession> open(String projectRootPath) async {
    final canonicalRoot = await _fileReader.canonicalizeDirectory(
      projectRootPath,
    );
    _requireAllowedRoot(canonicalRoot);
    final existing = _sessions[canonicalRoot];
    if (existing != null) {
      final session = await existing;
      if (identical(_sessions[canonicalRoot], existing) &&
          !session.isClosed &&
          _isAllowedRoot(canonicalRoot)) {
        return session;
      }
      await session.close();
      if (identical(_sessions[canonicalRoot], existing)) {
        _sessions.remove(canonicalRoot);
      }
      throw const EditorAuthoringStaleSessionException();
    }
    final opening = _openTracked(canonicalRoot);
    _sessions[canonicalRoot] = opening;
    try {
      final session = await opening;
      if (!identical(_sessions[canonicalRoot], opening) ||
          !_isAllowedRoot(canonicalRoot)) {
        await session.close();
        throw const EditorAuthoringStaleSessionException();
      }
      return session;
    } on Object {
      if (identical(_sessions[canonicalRoot], opening)) {
        _sessions.remove(canonicalRoot);
      }
      rethrow;
    }
  }

  @override
  Future<void> allowCandidate(String canonicalRoot) async {
    _candidateRoot = canonicalRoot == _retainedRoot ? null : canonicalRoot;
  }

  Future<void> invalidate(String projectRootPath) async {
    final canonicalRoot = await _fileReader.canonicalizeDirectory(
      projectRootPath,
    );
    await closeProject(canonicalRoot);
  }

  @override
  Future<void> retainOnly(String canonicalRoot) async {
    _retainedRoot = canonicalRoot;
    _candidateRoot = null;
    final retired = <Future<EditorAuthoringReadSession>>[];
    for (final entry in _sessions.entries.toList(growable: false)) {
      if (entry.key == canonicalRoot) continue;
      if (identical(_sessions.remove(entry.key), entry.value)) {
        retired.add(entry.value);
      }
    }
    _retiringSessions += retired.length;
    try {
      await _closeSessions(retired);
    } finally {
      _retiringSessions -= retired.length;
    }
  }

  @override
  Future<void> closeProject(String canonicalRoot) async {
    if (_candidateRoot == canonicalRoot) _candidateRoot = null;
    final session = _sessions.remove(canonicalRoot);
    if (session == null) return;
    _retiringSessions++;
    try {
      await (await session).close();
    } finally {
      _retiringSessions--;
    }
  }

  @override
  Future<void> closeAll() async {
    final sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    _retainedRoot = null;
    _candidateRoot = null;
    _retiringSessions += sessions.length;
    try {
      await _closeSessions(sessions);
    } finally {
      _retiringSessions -= sessions.length;
    }
  }

  bool _isAllowedRoot(String canonicalRoot) {
    final retainedRoot = _retainedRoot;
    final candidateRoot = _candidateRoot;
    if (retainedRoot == null && candidateRoot == null) return true;
    return canonicalRoot == retainedRoot || canonicalRoot == candidateRoot;
  }

  void _requireAllowedRoot(String canonicalRoot) {
    if (!_isAllowedRoot(canonicalRoot)) {
      throw const EditorAuthoringStaleSessionException();
    }
  }

  Future<EditorAuthoringReadSession> _openTracked(String canonicalRoot) async {
    _openingRoots.add(canonicalRoot);
    try {
      return await _openCanonical(canonicalRoot);
    } finally {
      _openingRoots.remove(canonicalRoot);
    }
  }

  Future<EditorAuthoringReadSession> _openCanonical(
    String canonicalRoot,
  ) async {
    // The user-selected project is the complete allowed root for this direct
    // editor session. Every declared resource is subsequently constrained to
    // that canonical directory by WorkspacePolicy/ProjectFileReader.
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [canonicalRoot],
      fileReader: _fileReader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(
      handles: handles,
      fingerprintCache: _fingerprintCache,
      snapshotCache: _snapshotCache,
      profileSink: _profileRecorder?.sinkFor('read'),
    );
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: _fileReader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final opened = await api.openProject(canonicalRoot);
    final workspaceHandle = opened.workspaceHandle;
    final projectHandle = opened.projectHandle;
    try {
      final snapshot = await snapshots.load(
        projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      return EditorAuthoringReadSession._(
        api: api,
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
        snapshot: snapshot,
        onOperationDelta: (delta) => _activeOperations += delta,
        onClosed: () => _closeCount++,
      );
    } on Object {
      await api.close(workspaceHandle);
      rethrow;
    }
  }
}

/// Immutable editor view over exactly one Authoring snapshot revision.
final class EditorAuthoringReadSession {
  EditorAuthoringReadSession._({
    required AuthoringReadServicePort api,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required ProjectSnapshot snapshot,
    required void Function(int delta) onOperationDelta,
    required void Function() onClosed,
  }) : _api = api,
       _workspaceHandle = workspaceHandle,
       _projectHandle = projectHandle,
       _snapshot = snapshot,
       _onOperationDelta = onOperationDelta,
       _onClosed = onClosed;

  final AuthoringReadServicePort _api;
  final WorkspaceHandle _workspaceHandle;
  final ProjectHandle _projectHandle;
  final ProjectSnapshot _snapshot;
  final void Function(int delta) _onOperationDelta;
  final void Function() _onClosed;
  final ProjectQueryService _queries = const ProjectQueryService();
  bool _closed = false;
  int _activeOperations = 0;
  Completer<void>? _operationsDrained;
  Future<void>? _closing;

  bool get isClosed => _closed;

  String get snapshotRevision => _snapshot.revision;

  PresentationCinematicDraft presentationCinematicDraft({
    required ProjectManifest expectedProject,
    bool allowProjectedProject = false,
  }) {
    _requireOpen();
    return PresentationCinematicDraft.fromSnapshot(
      _snapshot,
      expectedProject: expectedProject,
      allowProjectedProject: allowProjectedProject,
    );
  }

  ProjectManifest get manifest {
    _requireOpen();
    return _snapshot.manifest;
  }

  List<MapData> get maps {
    _requireOpen();
    return _snapshot.maps;
  }

  MapData? mapById(String mapId) {
    _requireOpen();
    return _snapshot.mapById(mapId);
  }

  MapData? mapByStorageKey(String storageKey) {
    _requireOpen();
    for (final entry in _snapshot.resourceStorageKeys.entries) {
      if (entry.value == storageKey && entry.key.startsWith('map:')) {
        return _snapshot.mapById(entry.key.substring('map:'.length));
      }
    }
    return null;
  }

  List<int>? assetBytes(String assetId) {
    _requireOpen();
    final page = _queries.query(
      _snapshot,
      AuthoringQueryRequest(
        resourceKind: 'asset',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: <String>[assetId],
      ),
    );
    final artifact = page.items.single['artifact'];
    if (artifact is! Map || artifact['digest'] is! String) return null;
    final identity = assetBlobResourceIdentity(artifact['digest']! as String);
    final bytes = _snapshot.findResourceBytes(identity);
    return bytes == null ? null : List.unmodifiable(bytes);
  }

  String? resourceRevision(String resourceIdentity) {
    _requireOpen();
    if (!_snapshot.resourceFingerprints.containsKey(resourceIdentity)) {
      return null;
    }
    // Editor map CAS predates the Authoring project fingerprint and is defined
    // over the exact document bytes only. Convert explicitly; never pass the
    // path-aware Authoring resource fingerprint off as the editor revision.
    return narrativeEventBytesFingerprint(
      _snapshot.resourceBytes(resourceIdentity),
    );
  }

  /// Executes against the frozen snapshot; repeated UI projections cannot
  /// trigger another parse or observe a mixed disk revision.
  Map<String, Object?> query(AuthoringQueryRequest request) {
    _requireOpen();
    return _queries.query(_snapshot, request).toJson();
  }

  /// Validation is deliberately fresh. It uses the canonical API again so an
  /// external edit is visible instead of being hidden by the UI snapshot.
  Future<Map<String, Object?>> validateFresh() async {
    _beginOperation();
    try {
      return (await _api.validateProject(_projectHandle)).toJson();
    } finally {
      _endOperation();
    }
  }

  /// Snapshot-local diagnostics used by ordinary panels. This avoids I/O and
  /// therefore cannot disagree with the models currently projected by the UI.
  Map<String, Object?> validate() {
    _requireOpen();
    final references = ProjectReferenceIndex.fromSnapshot(_snapshot);
    final hasErrors =
        references.diagnostics.any(
          (diagnostic) => diagnostic.severity == ProjectReferenceSeverity.error,
        ) ||
        _snapshot.loadDiagnostics.any((diagnostic) => diagnostic.blocking);
    return {
      'snapshotRevision': _snapshot.revision,
      'valid': !hasErrors,
      'references': <String, Object?>{
        'nodeCount': references.nodes.length,
        'edgeCount': references.edges.length,
        'hasErrors': hasErrors,
        'diagnostics': [
          for (final diagnostic in references.diagnostics) diagnostic.toJson(),
          for (final diagnostic in _snapshot.loadDiagnostics)
            diagnostic.toJson(),
        ],
      },
    };
  }

  Future<void> close() async {
    final closing = _closing;
    if (closing != null) return closing;
    final operation = _close();
    _closing = operation;
    return operation;
  }

  Future<void> _close() async {
    _closed = true;
    if (_activeOperations > 0) {
      _operationsDrained ??= Completer<void>();
      await _operationsDrained!.future;
    }
    await _api.closeWorkspace(_workspaceHandle);
    _onClosed();
  }

  void _beginOperation() {
    _requireOpen();
    _activeOperations++;
    _onOperationDelta(1);
  }

  void _endOperation() {
    _activeOperations--;
    _onOperationDelta(-1);
    if (_activeOperations == 0) {
      final drained = _operationsDrained;
      _operationsDrained = null;
      if (drained != null && !drained.isCompleted) drained.complete();
    }
  }

  void _requireOpen() {
    if (_closed) {
      throw StateError('The editor Authoring read session is closed.');
    }
  }
}

Future<void> _closeSessions(
  Iterable<Future<EditorAuthoringReadSession>> sessions,
) async {
  await Future.wait<void>(
    sessions.map((opening) async => (await opening).close()),
  );
}
