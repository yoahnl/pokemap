import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

/// Opens one coherent Authoring snapshot for the editor's read projections.
///
/// This adapter intentionally exposes typed PokeMap models to the editor while
/// keeping handles, path authorization, revision calculation, query ordering,
/// pagination, and reference diagnostics owned by `map_authoring`.
final class AuthoringQueryAdapter {
  AuthoringQueryAdapter({required ProjectFileReader fileReader})
      : _fileReader = fileReader;

  final ProjectFileReader _fileReader;
  final Map<String, Future<EditorAuthoringReadSession>> _sessions = {};

  Future<EditorAuthoringReadSession> open(String projectRootPath) async {
    final canonicalRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    final existing = _sessions[canonicalRoot];
    if (existing != null) {
      final session = await existing;
      if (!session.isClosed) return session;
      _sessions.remove(canonicalRoot);
    }
    final opening = _openCanonical(canonicalRoot);
    _sessions[canonicalRoot] = opening;
    try {
      return await opening;
    } on Object {
      if (identical(_sessions[canonicalRoot], opening)) {
        _sessions.remove(canonicalRoot);
      }
      rethrow;
    }
  }

  Future<void> invalidate(String projectRootPath) async {
    final canonicalRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    final session = _sessions.remove(canonicalRoot);
    if (session != null) await (await session).close();
  }

  Future<void> closeAll() async {
    final sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    for (final session in sessions) {
      await (await session).close();
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
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: _fileReader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final opened = await api.open(canonicalRoot);
    final workspaceHandle =
        WorkspaceHandle(opened['workspaceHandle']! as String);
    final projectHandle = ProjectHandle(opened['projectHandle']! as String);
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
    required AuthoringReadApiPort api,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required ProjectSnapshot snapshot,
  })  : _api = api,
        _workspaceHandle = workspaceHandle,
        _projectHandle = projectHandle,
        _snapshot = snapshot;

  final AuthoringReadApiPort _api;
  final WorkspaceHandle _workspaceHandle;
  final ProjectHandle _projectHandle;
  final ProjectSnapshot _snapshot;
  final ProjectQueryService _queries = const ProjectQueryService();
  bool _closed = false;

  bool get isClosed => _closed;

  String get snapshotRevision => _snapshot.revision;

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
  Future<Map<String, Object?>> validateFresh() {
    _requireOpen();
    return _api.validate(_projectHandle);
  }

  /// Snapshot-local diagnostics used by ordinary panels. This avoids I/O and
  /// therefore cannot disagree with the models currently projected by the UI.
  Map<String, Object?> validate() {
    _requireOpen();
    final references = ProjectReferenceIndex.fromSnapshot(_snapshot);
    final hasErrors = references.diagnostics.any(
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
    if (_closed) return;
    _closed = true;
    await _api.close(_workspaceHandle);
  }

  void _requireOpen() {
    if (_closed) {
      throw StateError('The editor Authoring read session is closed.');
    }
  }
}
