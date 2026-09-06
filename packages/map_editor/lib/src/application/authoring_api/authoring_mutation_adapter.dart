import 'dart:async';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../services/editor_performance_telemetry.dart';
import '../services/editor_snapshot_profile_recorder.dart';
import '../services/tiled_image_collection_raster_codec.dart';
import 'authoring_query_adapter.dart';
import 'authoring_session_lifecycle.dart';
import 'editor_receipt_presenter.dart';

abstract interface class EditorProjectRootLocator {
  Future<String> locateForResource(String resourcePath);
}

/// Security limits for the editor's own local authoring session.
///
/// The actor here is the person typing in the editor, not a remote client, so
/// the rate window that guards the exposed MCP surface does not apply.
const editorAuthoringSecurityLimits = AuthoringSecurityLimits(
  maxRequestBytes: 64 << 20,
  maxOperationsPerWindow: null,
);

final class EditorAuthoringMutationPlan {
  const EditorAuthoringMutationPlan._({
    required this.projectRootPath,
    required this.planId,
    required this.snapshotRevision,
    required this.receipt,
    required this.preview,
  });

  final String projectRootPath;
  final String planId;
  final String snapshotRevision;
  final AuthoringReceipt receipt;
  final Map<String, Object?> preview;
}

final class EditorAuthoringMutationResult {
  const EditorAuthoringMutationResult({
    required this.receipt,
    required this.snapshotRevision,
    this.resourceRevision,
    this.projection,
  });

  final AuthoringReceipt receipt;
  final String snapshotRevision;
  final String? resourceRevision;
  final EditorAuthoringMutationProjection? projection;
}

final class EditorAuthoringMutationProjection {
  EditorAuthoringMutationProjection._(ProjectSnapshot snapshot)
    : _snapshot = snapshot,
      snapshotRevision = snapshot.revision,
      manifest = snapshot.manifest,
      mapsById = Map<String, MapData>.unmodifiable(<String, MapData>{
        for (final map in snapshot.maps) map.id: map,
      });

  final ProjectSnapshot _snapshot;
  final String snapshotRevision;
  final ProjectManifest manifest;
  final Map<String, MapData> mapsById;

  MapData? mapById(String mapId) => mapsById[mapId];

  String? resourceRevision(String identity) {
    if (!_snapshot.resourceFingerprints.containsKey(identity)) return null;
    return narrativeEventBytesFingerprint(_snapshot.resourceBytes(identity));
  }
}

final class EditorStagedArtifact {
  const EditorStagedArtifact({
    required this.reference,
    required this.deduplicated,
  });

  final ContentArtifactRef reference;
  final bool deduplicated;
}

/// Direct-Dart bridge from editor gestures to canonical plan/apply/history.
///
/// The adapter owns only session composition and editor CAS translation. All
/// domain planning, authorization, confirmation, idempotency, transaction,
/// history, and recovery behavior remains inside `map_authoring`.
final class AuthoringMutationAdapter
    implements EditorAuthoringLifecycleParticipant {
  AuthoringMutationAdapter({
    required ProjectFileReader fileReader,
    required AuthoringQueryAdapter queries,
    required EditorProjectRootLocator projectRoots,
    WorkspaceHandleStore Function()? workspaceHandles,
    ProjectSnapshotFingerprintCache? fingerprintCache,
    ProjectSnapshotCache? snapshotCache,
    EditorSnapshotProfileRecorder? profileRecorder,
    void Function(String projectRoot)? invalidatePokemonSpeciesSnapshot,
  }) : _fileReader = fileReader,
       _queries = queries,
       _projectRoots = projectRoots,
       _workspaceHandles = workspaceHandles ?? (() => WorkspaceHandleStore()),
       _fingerprintCache =
           fingerprintCache ?? ProjectSnapshotFingerprintCache(),
       _snapshotCache = snapshotCache ?? ProjectSnapshotCache(),
       _profileRecorder = profileRecorder,
       _invalidatePokemonSpeciesSnapshot =
           invalidatePokemonSpeciesSnapshot ??
           _ignorePokemonSpeciesSnapshotInvalidation;

  final ProjectFileReader _fileReader;
  final AuthoringQueryAdapter _queries;
  final EditorProjectRootLocator _projectRoots;
  final WorkspaceHandleStore Function() _workspaceHandles;
  final ProjectSnapshotFingerprintCache _fingerprintCache;
  final ProjectSnapshotCache _snapshotCache;
  final EditorSnapshotProfileRecorder? _profileRecorder;
  final void Function(String projectRoot) _invalidatePokemonSpeciesSnapshot;
  final Map<String, Future<_EditorMutationSession>> _sessions = {};
  final Set<String> _openingRoots = {};
  String? _retainedRoot;
  String? _candidateRoot;
  int _retiringSessions = 0;
  int _activeOperations = 0;
  int _closeCount = 0;
  int _identityCounter = 0;
  AuthoringReceipt? _lastAppliedReceipt;

  AuthoringReceipt? get lastAppliedReceipt => _lastAppliedReceipt;

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

  Future<EditorAuthoringMutationPlan> plan(
    String projectRootPath, {
    required String actionId,
    required Map<String, Object?> parameters,
    required String idempotencyKey,
    String? requestId,
    String? expectedRevision,
    bool dryRun = false,
  }) async {
    try {
      final session = await _open(projectRootPath);
      return await session.use(
        () => _planInSession(
          session,
          actionId: actionId,
          parameters: parameters,
          idempotencyKey: idempotencyKey,
          requestId: requestId,
          expectedRevision: expectedRevision,
          dryRun: dryRun,
        ),
      );
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<String> readRevision(String projectRootPath) async {
    final session = await _open(projectRootPath);
    return session.use(() async => (await session.snapshot()).revision);
  }

  /// Stages one exact file selected by the local user into an opaque handle.
  ///
  /// The source path never enters an action request, receipt, plan or project
  /// document. The session grants only this resolved file, not its directory.
  Future<EditorStagedArtifact> stageArtifact(
    String projectRootPath, {
    required String sourcePath,
    String? declaredMediaType,
  }) async {
    try {
      final session = await _open(projectRootPath);
      return await session.use(() async {
        await session.artifactStore.authorizeSourceFile(sourcePath);
        final result = await session.mutations.stageArtifactFile(
          sourcePath: sourcePath,
          declaredMediaType: declaredMediaType,
        );
        return EditorStagedArtifact(
          reference: result.reference,
          deduplicated: result.deduplicated,
        );
      });
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<List<int>> readArtifact(
    String projectRootPath, {
    required String handle,
  }) async {
    try {
      final session = await _open(projectRootPath);
      return await session.use(() => session.artifactStore.read(handle));
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<void> releaseArtifact(
    String projectRootPath, {
    required String handle,
  }) async {
    try {
      final session = await _open(projectRootPath);
      await session.use(() => session.artifactStore.release(handle));
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<String> confirm(EditorAuthoringMutationPlan plan) async {
    try {
      final session = await _open(plan.projectRootPath);
      return await session.use(() async {
        final response = await session.mutations.confirmMutation(
          session.projectHandle,
          planId: plan.planId,
        );
        return response.confirmationToken;
      });
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<EditorAuthoringMutationResult> apply(
    EditorAuthoringMutationPlan plan, {
    required String operationId,
    String? confirmationToken,
  }) async {
    try {
      final session = await _open(plan.projectRootPath);
      return await session.use(
        () => _applyInSession(
          session,
          plan,
          operationId: operationId,
          confirmationToken: confirmationToken,
        ),
      );
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<EditorAuthoringMutationResult> undo(
    String projectRootPath, {
    required String entryId,
    required String idempotencyKey,
  }) async {
    try {
      final session = await _open(projectRootPath);
      return await session.use(() async {
        final response = await session.mutations.undoMutation(
          session.projectHandle,
          entryId: entryId,
          idempotencyKey: idempotencyKey,
        );
        final result = EditorAuthoringMutationResult(
          receipt: response.receipt,
          snapshotRevision: response.snapshotRevision,
        );
        _lastAppliedReceipt = result.receipt;
        _invalidateSpeciesSnapshotIfTouched(
          session.canonicalRoot,
          result.receipt,
        );
        await _queries.invalidate(session.canonicalRoot);
        return result;
      });
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<EditorAuthoringMutationResult> recover(
    String projectRootPath, {
    required String operationId,
  }) async {
    try {
      final session = await _open(projectRootPath);
      return await session.use(() async {
        final response = await session.mutations.recoverMutation(
          session.projectHandle,
          operationId: operationId,
        );
        final result = EditorAuthoringMutationResult(
          receipt: response.receipt,
          snapshotRevision: response.snapshotRevision,
        );
        _lastAppliedReceipt = result.receipt;
        _invalidateSpeciesSnapshotIfTouched(
          session.canonicalRoot,
          result.receipt,
        );
        await _queries.invalidate(session.canonicalRoot);
        return result;
      });
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<EditorAuthoringMutationPlan> _planInSession(
    _EditorMutationSession session, {
    required String actionId,
    required Map<String, Object?> parameters,
    required String idempotencyKey,
    String? requestId,
    String? expectedRevision,
    bool dryRun = false,
  }) async {
    final snapshot = await session.snapshot(
      cacheValidation: ProjectSnapshotCacheValidation.session,
    );
    final response = await session.mutations.planMutation(
      session.projectHandle,
      AuthoringRequest(
        requestId: requestId ?? _identity('editor_request'),
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: session.workspaceHandle.value,
        parameters: parameters,
        expectedRevision: expectedRevision ?? snapshot.revision,
        idempotencyKey: idempotencyKey,
        dryRun: dryRun,
      ),
    );
    return EditorAuthoringMutationPlan._(
      projectRootPath: session.canonicalRoot,
      planId: response.planId,
      snapshotRevision: response.snapshotRevision,
      receipt: response.receipt,
      preview: response.plan.preview,
    );
  }

  Future<EditorAuthoringMutationResult> _applyInSession(
    _EditorMutationSession session,
    EditorAuthoringMutationPlan plan, {
    required String operationId,
    String? confirmationToken,
  }) async {
    final response = await session.mutations.applyMutation(
      session.projectHandle,
      planId: plan.planId,
      operationId: operationId,
      confirmationToken: confirmationToken,
    );
    final snapshot = await session.snapshot(
      cacheValidation: ProjectSnapshotCacheValidation.session,
    );
    final result = EditorAuthoringMutationResult(
      receipt: response.receipt,
      snapshotRevision: response.snapshotRevision,
      projection: snapshot.revision == response.snapshotRevision
          ? EditorAuthoringMutationProjection._(snapshot)
          : null,
    );
    _lastAppliedReceipt = result.receipt;
    _profileRecorder?.recordCacheCounters(_snapshotCache);
    _invalidateSpeciesSnapshotIfTouched(session.canonicalRoot, result.receipt);
    await _queries.invalidate(session.canonicalRoot);
    return result;
  }

  void _invalidateSpeciesSnapshotIfTouched(
    String projectRoot,
    AuthoringReceipt receipt,
  ) {
    final touchesSpecies = receipt.affectedResources.any(
      (resource) =>
          resource.kind == 'pokemonDocument' &&
          resource.id.startsWith('species:'),
    );
    if (touchesSpecies) {
      _invalidatePokemonSpeciesSnapshot(projectRoot);
    }
  }

  /// Canonical product path for saving one already-declared map document.
  Future<EditorAuthoringMutationResult> saveMap(
    MapData map,
    String resourcePath, {
    required String expectedMapRevision,
  }) async {
    final root = await _projectRoots.locateForResource(resourcePath);
    try {
      final session = await _open(root);
      return await session.use(() async {
        final before = await session.snapshot();
        final identity = 'map:${map.id}';
        if (!before.resourceFingerprints.containsKey(identity)) {
          throw const EditorConflictException(
            'The map is not declared by the current Authoring snapshot.',
          );
        }
        final liveMapRevision = narrativeEventBytesFingerprint(
          before.resourceBytes(identity),
        );
        if (liveMapRevision != expectedMapRevision) {
          throw const EditorConflictException(
            'The map changed outside the editor.',
          );
        }
        final key = _identity('editor_map_save');
        final mutationPlan = await _planInSession(
          session,
          actionId: 'map.save',
          parameters: {'map': _strictJsonMap(map.toJson())},
          idempotencyKey: key,
          requestId: key,
          expectedRevision: before.revision,
        );
        final applied = await _applyInSession(
          session,
          mutationPlan,
          operationId: key,
        );
        final after = await session.snapshot(
          cacheValidation: ProjectSnapshotCacheValidation.session,
        );
        final mapRevision = narrativeEventBytesFingerprint(
          after.resourceBytes(identity),
        );
        return EditorAuthoringMutationResult(
          receipt: applied.receipt,
          snapshotRevision: after.revision,
          resourceRevision: mapRevision,
        );
      });
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflictCode(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }

  Future<EditorAuthoringMutationResult> savePresentation(
    ProjectPresentationProfile profile,
    String projectRootPath, {
    required String expectedProjectRevision,
    required String operationId,
  }) async {
    try {
      final session = await _open(projectRootPath);
      return await session.use(() async {
        final before = await session.snapshot();
        final liveProjectRevision = narrativeEventBytesFingerprint(
          before.resourceBytes('project'),
        );
        if (liveProjectRevision != expectedProjectRevision) {
          throw const EditorConflictException(
            'The project changed outside the Personalization Studio.',
          );
        }
        final mutationPlan = await _planInSession(
          session,
          actionId: 'presentation.update',
          parameters: <String, Object?>{
            'profile': _strictJsonMap(profile.toJson()),
          },
          idempotencyKey: operationId,
          requestId: operationId,
          expectedRevision: before.revision,
        );
        return _applyInSession(session, mutationPlan, operationId: operationId);
      });
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflictCode(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }

  @override
  Future<void> allowCandidate(String canonicalRoot) async {
    _candidateRoot = canonicalRoot == _retainedRoot ? null : canonicalRoot;
  }

  @override
  Future<void> retainOnly(String canonicalRoot) async {
    _retainedRoot = canonicalRoot;
    _candidateRoot = null;
    final retired = <Future<_EditorMutationSession>>[];
    for (final entry in _sessions.entries.toList(growable: false)) {
      if (entry.key == canonicalRoot) continue;
      if (identical(_sessions.remove(entry.key), entry.value)) {
        retired.add(entry.value);
      }
    }
    _retiringSessions += retired.length;
    try {
      await _closeMutationSessions(retired);
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
      await _closeMutationSessions(sessions);
    } finally {
      _retiringSessions -= sessions.length;
    }
  }

  Future<_EditorMutationSession> _open(String projectRootPath) async {
    final canonicalRoot = await _fileReader.canonicalizeDirectory(
      projectRootPath,
    );
    _requireAllowedRoot(canonicalRoot);
    final current = _sessions[canonicalRoot];
    if (current != null) {
      final session = await current;
      if (identical(_sessions[canonicalRoot], current) &&
          !session.isClosing &&
          _isAllowedRoot(canonicalRoot)) {
        if (session.hasActiveWorkspace) return session;
        _sessions.remove(canonicalRoot);
        await session.close();
        return _open(canonicalRoot);
      }
      await session.close();
      if (identical(_sessions[canonicalRoot], current)) {
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

  Future<_EditorMutationSession> _openTracked(String canonicalRoot) async {
    _openingRoots.add(canonicalRoot);
    try {
      return await _EditorMutationSession.open(
        canonicalRoot: canonicalRoot,
        fileReader: _fileReader,
        workspaceHandles: _workspaceHandles,
        fingerprintCache: _fingerprintCache,
        snapshotCache: _snapshotCache,
        profileRecorder: _profileRecorder,
        onOperationDelta: (delta) => _activeOperations += delta,
        onClosed: () => _closeCount++,
      );
    } finally {
      _openingRoots.remove(canonicalRoot);
    }
  }

  String _identity(String prefix) {
    _identityCounter++;
    return '${prefix}_${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_identityCounter';
  }
}

void _ignorePokemonSpeciesSnapshotInvalidation(String projectRoot) {}

Map<String, Object?> _strictJsonMap(Map<String, dynamic> value) {
  final encoded = EditorPerformanceTelemetry.encodeJson(value);
  return (EditorPerformanceTelemetry.decodeJson(encoded)
          as Map<String, dynamic>)
      .cast<String, Object?>();
}

final class _EditorMutationSession {
  _EditorMutationSession._({
    required this.canonicalRoot,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.reads,
    required this.mutations,
    required this.artifactStore,
    required WorkspaceHandleStore handles,
    required ProjectSnapshotLoader snapshots,
    required void Function(int delta) onOperationDelta,
    required void Function() onClosed,
  }) : _handles = handles,
       _snapshots = snapshots,
       _onOperationDelta = onOperationDelta,
       _onClosed = onClosed;

  static Future<_EditorMutationSession> open({
    required String canonicalRoot,
    required ProjectFileReader fileReader,
    required WorkspaceHandleStore Function() workspaceHandles,
    required ProjectSnapshotFingerprintCache fingerprintCache,
    required ProjectSnapshotCache snapshotCache,
    required EditorSnapshotProfileRecorder? profileRecorder,
    required void Function(int delta) onOperationDelta,
    required void Function() onClosed,
  }) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [canonicalRoot],
      fileReader: fileReader,
    );
    final handles = workspaceHandles();
    final snapshots = ProjectSnapshotLoader(
      handles: handles,
      fingerprintCache: fingerprintCache,
      snapshotCache: snapshotCache,
      profileSink: profileRecorder?.sinkFor('mutation'),
    );
    final reads = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: fileReader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final opened = await reads.openProject(canonicalRoot);
    final workspaceHandle = opened.workspaceHandle;
    final projectHandle = opened.projectHandle;
    final artifactStore = LocalArtifactStore(
      allowedSourceRoots: [canonicalRoot],
      maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifactStore,
      authorizationLimits: editorAuthoringSecurityLimits,
      tiledImageCollectionRasterCodec:
          const ImagePackageTiledImageCollectionRasterCodec(),
      performanceObserver: const _EditorAuthoringPerformanceObserver(),
    );
    try {
      await mutations.attachProject(
        projectRootPath: canonicalRoot,
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
      );
      return _EditorMutationSession._(
        canonicalRoot: canonicalRoot,
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
        reads: reads,
        mutations: mutations,
        artifactStore: artifactStore,
        handles: handles,
        snapshots: snapshots,
        onOperationDelta: onOperationDelta,
        onClosed: onClosed,
      );
    } on Object {
      await reads.closeWorkspace(workspaceHandle);
      rethrow;
    }
  }

  final String canonicalRoot;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final LocalArtifactStore artifactStore;
  final WorkspaceHandleStore _handles;
  final ProjectSnapshotLoader _snapshots;
  final void Function(int delta) _onOperationDelta;
  final void Function() _onClosed;
  var _activeOperations = 0;
  var _closing = false;
  Completer<void>? _operationsDrained;
  Future<void>? _closeOperation;

  bool get isClosing => _closing;

  bool get hasActiveWorkspace {
    try {
      _handles.resolveProject(projectHandle);
      return true;
    } on WorkspaceHandleException {
      return false;
    }
  }

  Future<ProjectSnapshot> snapshot({
    ProjectSnapshotCacheValidation cacheValidation =
        ProjectSnapshotCacheValidation.canonical,
  }) => _snapshots.load(projectHandle, cacheValidation: cacheValidation);

  Future<T> use<T>(Future<T> Function() operation) async {
    if (_closing) {
      throw StateError('The editor Authoring mutation session is closing.');
    }
    _activeOperations++;
    _onOperationDelta(1);
    try {
      return await operation();
    } finally {
      _activeOperations--;
      _onOperationDelta(-1);
      if (_activeOperations == 0) {
        final drained = _operationsDrained;
        _operationsDrained = null;
        if (drained != null && !drained.isCompleted) drained.complete();
      }
    }
  }

  Future<void> close() {
    final current = _closeOperation;
    if (current != null) return current;
    _closing = true;
    final operation = _close();
    _closeOperation = operation;
    return operation;
  }

  Future<void> _close() async {
    if (_activeOperations > 0) {
      _operationsDrained ??= Completer<void>();
      await _operationsDrained!.future;
    }
    await mutations.detachWorkspace(workspaceHandle);
    await reads.close(workspaceHandle);
    _onClosed();
  }
}

final class _EditorAuthoringPerformanceObserver
    implements AuthoringPerformanceObserver {
  const _EditorAuthoringPerformanceObserver();

  @override
  AuthoringPerformanceSpan? startSpan(String name) {
    final span = EditorPerformanceTelemetry.startSpan(name);
    return span == null ? null : _EditorAuthoringPerformanceSpan(span);
  }

  @override
  void incrementCounter(String name, {int by = 1}) {
    EditorPerformanceTelemetry.incrementCounter(name, by: by);
  }
}

final class _EditorAuthoringPerformanceSpan
    implements AuthoringPerformanceSpan {
  const _EditorAuthoringPerformanceSpan(this._span);

  final EditorPerformanceSpan _span;

  @override
  void finish() => _span.finish();
}

Future<void> _closeMutationSessions(
  Iterable<Future<_EditorMutationSession>> sessions,
) async {
  await Future.wait<void>(
    sessions.map((opening) async => (await opening).close()),
  );
}

bool _isConflictCode(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
