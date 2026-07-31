import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_query_adapter.dart';
import 'editor_receipt_presenter.dart';

abstract interface class EditorProjectRootLocator {
  Future<String> locateForResource(String resourcePath);
}

final class EditorAuthoringMutationPlan {
  const EditorAuthoringMutationPlan._({
    required this.projectRootPath,
    required this.planId,
    required this.snapshotRevision,
    required this.receipt,
  });

  final String projectRootPath;
  final String planId;
  final String snapshotRevision;
  final AuthoringReceipt receipt;
}

final class EditorAuthoringMutationResult {
  const EditorAuthoringMutationResult({
    required this.receipt,
    required this.snapshotRevision,
    this.resourceRevision,
  });

  final AuthoringReceipt receipt;
  final String snapshotRevision;
  final String? resourceRevision;
}

/// Direct-Dart bridge from editor gestures to canonical plan/apply/history.
///
/// The adapter owns only session composition and editor CAS translation. All
/// domain planning, authorization, confirmation, idempotency, transaction,
/// history, and recovery behavior remains inside `map_authoring`.
final class AuthoringMutationAdapter {
  AuthoringMutationAdapter({
    required ProjectFileReader fileReader,
    required AuthoringQueryAdapter queries,
    required EditorProjectRootLocator projectRoots,
  })  : _fileReader = fileReader,
        _queries = queries,
        _projectRoots = projectRoots;

  final ProjectFileReader _fileReader;
  final AuthoringQueryAdapter _queries;
  final EditorProjectRootLocator _projectRoots;
  final Map<String, Future<_EditorMutationSession>> _sessions = {};
  int _identityCounter = 0;
  AuthoringReceipt? _lastAppliedReceipt;

  AuthoringReceipt? get lastAppliedReceipt => _lastAppliedReceipt;

  Future<EditorAuthoringMutationPlan> plan(
    String projectRootPath, {
    required String actionId,
    required Map<String, Object?> parameters,
    required String idempotencyKey,
    String? requestId,
    String? expectedRevision,
  }) async {
    try {
      final session = await _open(projectRootPath);
      final snapshot = await session.snapshot();
      final response = await session.mutations.plan(
        session.projectHandle,
        AuthoringRequest(
          requestId: requestId ?? _identity('editor_request'),
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: session.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: expectedRevision ?? snapshot.revision,
          idempotencyKey: idempotencyKey,
          // `plan` is non-mutating regardless. `dryRun: true` deliberately
          // creates a preview-only plan that the canonical API refuses to
          // apply, so editor plans intended for confirmation use `false`.
          dryRun: false,
        ),
      );
      return EditorAuthoringMutationPlan._(
        projectRootPath: session.canonicalRoot,
        planId: response['planId']! as String,
        snapshotRevision: response['snapshotRevision']! as String,
        receipt: _receipt(response),
      );
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<String> confirm(EditorAuthoringMutationPlan plan) async {
    try {
      final session = await _open(plan.projectRootPath);
      final response = await session.mutations.confirm(
        session.projectHandle,
        planId: plan.planId,
      );
      return response['confirmationToken']! as String;
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
      final response = await session.mutations.apply(
        session.projectHandle,
        planId: plan.planId,
        operationId: operationId,
        confirmationToken: confirmationToken,
      );
      final result = EditorAuthoringMutationResult(
        receipt: _receipt(response),
        snapshotRevision: response['snapshotRevision']! as String,
      );
      _lastAppliedReceipt = result.receipt;
      await _queries.invalidate(session.canonicalRoot);
      return result;
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
      final response = await session.mutations.undo(
        session.projectHandle,
        entryId: entryId,
        idempotencyKey: idempotencyKey,
      );
      final result = EditorAuthoringMutationResult(
        receipt: _receipt(response),
        snapshotRevision: response['snapshotRevision']! as String,
      );
      _lastAppliedReceipt = result.receipt;
      await _queries.invalidate(session.canonicalRoot);
      return result;
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
      final response = await session.mutations.recover(
        session.projectHandle,
        operationId: operationId,
      );
      final result = EditorAuthoringMutationResult(
        receipt: _receipt(response),
        snapshotRevision: response['snapshotRevision']! as String,
      );
      _lastAppliedReceipt = result.receipt;
      await _queries.invalidate(session.canonicalRoot);
      return result;
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
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
      final before = await session.snapshot();
      final identity = 'map:${map.id}';
      if (!before.resourceFingerprints.containsKey(identity)) {
        throw const EditorConflictException(
          'The map is not declared by the current Authoring snapshot.',
        );
      }
      final liveMapRevision =
          narrativeEventBytesFingerprint(before.resourceBytes(identity));
      if (liveMapRevision != expectedMapRevision) {
        throw const EditorConflictException(
          'The map changed outside the editor.',
        );
      }
      final key = _identity('editor_map_save');
      final mutationPlan = await plan(
        session.canonicalRoot,
        actionId: 'map.save',
        parameters: {'map': map.toJson()},
        idempotencyKey: key,
        requestId: key,
        expectedRevision: before.revision,
      );
      final applied = await apply(mutationPlan, operationId: key);
      final after = await session.snapshot();
      final mapRevision =
          narrativeEventBytesFingerprint(after.resourceBytes(identity));
      return EditorAuthoringMutationResult(
        receipt: applied.receipt,
        snapshotRevision: after.revision,
        resourceRevision: mapRevision,
      );
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflictCode(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }

  Future<void> closeAll() async {
    final sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    for (final opening in sessions) {
      await (await opening).close();
    }
  }

  Future<_EditorMutationSession> _open(String projectRootPath) async {
    final canonicalRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    final current = _sessions[canonicalRoot];
    if (current != null) return current;
    final opening = _EditorMutationSession.open(
      canonicalRoot: canonicalRoot,
      fileReader: _fileReader,
    );
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

  String _identity(String prefix) {
    _identityCounter++;
    return '${prefix}_${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_identityCounter';
  }
}

final class _EditorMutationSession {
  const _EditorMutationSession._({
    required this.canonicalRoot,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.reads,
    required this.mutations,
    required ProjectSnapshotLoader snapshots,
  }) : _snapshots = snapshots;

  static Future<_EditorMutationSession> open({
    required String canonicalRoot,
    required ProjectFileReader fileReader,
  }) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [canonicalRoot],
      fileReader: fileReader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final reads = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: fileReader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final opened = await reads.open(canonicalRoot);
    final workspaceHandle =
        WorkspaceHandle(opened['workspaceHandle']! as String);
    final projectHandle = ProjectHandle(opened['projectHandle']! as String);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
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
        snapshots: snapshots,
      );
    } on Object {
      await reads.close(workspaceHandle);
      rethrow;
    }
  }

  final String canonicalRoot;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader _snapshots;

  Future<ProjectSnapshot> snapshot() => _snapshots.load(projectHandle);

  Future<void> close() async {
    await mutations.detachWorkspace(workspaceHandle);
    await reads.close(workspaceHandle);
  }
}

AuthoringReceipt _receipt(Map<String, Object?> response) {
  final raw = response['receipt'];
  if (raw is! Map) {
    throw const FormatException('Authoring response receipt is missing.');
  }
  return AuthoringReceipt.fromJson(Map<String, dynamic>.from(raw));
}

bool _isConflictCode(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
