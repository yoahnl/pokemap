import 'dart:async';
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_query_adapter.dart';
import 'authoring_session_lifecycle.dart';
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
final class AuthoringMutationAdapter
    implements EditorAuthoringLifecycleParticipant {
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
        ),
      );
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<String> confirm(EditorAuthoringMutationPlan plan) async {
    try {
      final session = await _open(plan.projectRootPath);
      return await session.use(
        () async {
          final response = await session.mutations.confirm(
            session.projectHandle,
            planId: plan.planId,
          );
          return response['confirmationToken']! as String;
        },
      );
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
      return await session.use(
        () async {
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
        },
      );
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
      return await session.use(
        () async {
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
        },
      );
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
  }) async {
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
  }

  Future<EditorAuthoringMutationResult> _applyInSession(
    _EditorMutationSession session,
    EditorAuthoringMutationPlan plan, {
    required String operationId,
    String? confirmationToken,
  }) async {
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
      return await session.use(
        () async {
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
          final after = await session.snapshot();
          final mapRevision =
              narrativeEventBytesFingerprint(after.resourceBytes(identity));
          return EditorAuthoringMutationResult(
            receipt: applied.receipt,
            snapshotRevision: after.revision,
            resourceRevision: mapRevision,
          );
        },
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
    final canonicalRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    _requireAllowedRoot(canonicalRoot);
    final current = _sessions[canonicalRoot];
    if (current != null) {
      final session = await current;
      if (identical(_sessions[canonicalRoot], current) &&
          !session.isClosing &&
          _isAllowedRoot(canonicalRoot)) {
        return session;
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

Map<String, Object?> _strictJsonMap(Map<String, dynamic> value) =>
    (jsonDecode(jsonEncode(value)) as Map<String, dynamic>)
        .cast<String, Object?>();

final class _EditorMutationSession {
  _EditorMutationSession._({
    required this.canonicalRoot,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.reads,
    required this.mutations,
    required ProjectSnapshotLoader snapshots,
    required void Function(int delta) onOperationDelta,
    required void Function() onClosed,
  })  : _snapshots = snapshots,
        _onOperationDelta = onOperationDelta,
        _onClosed = onClosed;

  static Future<_EditorMutationSession> open({
    required String canonicalRoot,
    required ProjectFileReader fileReader,
    required void Function(int delta) onOperationDelta,
    required void Function() onClosed,
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
        onOperationDelta: onOperationDelta,
        onClosed: onClosed,
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
  final void Function(int delta) _onOperationDelta;
  final void Function() _onClosed;
  var _activeOperations = 0;
  var _closing = false;
  Completer<void>? _operationsDrained;
  Future<void>? _closeOperation;

  bool get isClosing => _closing;

  Future<ProjectSnapshot> snapshot() => _snapshots.load(projectHandle);

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

Future<void> _closeMutationSessions(
  Iterable<Future<_EditorMutationSession>> sessions,
) async {
  await Future.wait<void>(
    sessions.map((opening) async => (await opening).close()),
  );
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
