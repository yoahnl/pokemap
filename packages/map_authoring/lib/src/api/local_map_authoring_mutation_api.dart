import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/json_contract_support.dart';
import '../domains/maps/map_mutation_dispatcher.dart';
import '../domains/assets/tiled_image_collection_packer.dart';
import '../history/content_blob_store.dart';
import '../history/file_history_store.dart';
import '../history/history_store.dart';
import '../history/undo_service.dart';
import '../parity/full_authoring_parity.dart';
import '../ports/idempotency_store.dart';
import '../ports/artifact_store.dart';
import '../ports/project_file_reader.dart';
import '../security/audit_log.dart';
import '../security/authoring_permission.dart';
import '../security/authorization_policy.dart';
import '../security/confirmation_token.dart';
import '../security/secure_mutation_executor.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/action_planner.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/idempotency_ledger.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/local_transaction_file_gateway.dart';
import '../transactions/plan_store.dart';
import '../transactions/recovery_service.dart';
import '../workspace/project_snapshot.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/workspace_handle_store.dart';
import '../workspace/workspace_policy.dart';
import 'authoring_mutation_api.dart';

/// Filesystem composition root for secure map mutation sessions.
///
/// Canonical roots are captured only by server-side adapters. They never enter
/// action contracts, receipts, errors, audit records, or JSONL responses.
final class LocalMapAuthoringMutationApi
    implements AuthoringMutationApiPort, AuthoringArtifactStagingPort {
  LocalMapAuthoringMutationApi({
    required WorkspacePolicy policy,
    required ProjectSnapshotLoader snapshotLoader,
    MapMutationDispatcher? dispatcher,
    ArtifactStore? artifactStore,
    TiledImageCollectionRasterCodec? tiledImageCollectionRasterCodec,
    AuthoringActor? actor,
    AuthoringSecurityLimits authorizationLimits =
        const AuthoringSecurityLimits(),
    DateTime Function()? clock,
    AuthoringTransactionFaultInjector? faultInjector,
  })  : _policy = policy,
        _snapshotLoader = snapshotLoader,
        _actor = actor ?? _localActor,
        _authorizationLimits = authorizationLimits,
        _clock = clock ?? _systemClock,
        _faultInjector = faultInjector {
    artifacts =
        artifactStore ?? MemoryArtifactStore(maximumArtifactBytes: 64 << 20);
    _dispatcher = dispatcher ??
        MapMutationDispatcher.canonical(
          artifactStore: artifacts,
          tiledImageCollectionRasterCodec: tiledImageCollectionRasterCodec,
        );
  }

  final WorkspacePolicy _policy;
  final ProjectSnapshotLoader _snapshotLoader;
  late final MapMutationDispatcher _dispatcher;
  late final ArtifactStore artifacts;
  final AuthoringActor _actor;
  final AuthoringSecurityLimits _authorizationLimits;
  final DateTime Function() _clock;
  final AuthoringTransactionFaultInjector? _faultInjector;
  final Map<ProjectHandle, _LocalMapAuthoringSession> _sessions = {};
  final Map<WorkspaceHandle, ProjectHandle> _projectsByWorkspace = {};

  @override
  Map<String, Object?> describeMutations() => freezeContractJsonObject(
        {
          'schemaVersion': 1,
          'protocol': 'pokemap.authoring.mutation.v1',
          'readOnly': false,
          'commands': const [
            {'id': 'apply', 'summary': 'Apply a frozen mutation plan.'},
            {'id': 'confirm', 'summary': 'Confirm one destructive plan.'},
            {'id': 'history', 'summary': 'List committed history entries.'},
            {'id': 'plan', 'summary': 'Plan and preview a map mutation.'},
            {'id': 'recover', 'summary': 'Resume a recoverable transaction.'},
            {
              'id': 'stage_artifact',
              'summary': 'Securely stage a local file for an asset mutation.',
            },
            {'id': 'undo', 'summary': 'Undo one committed history entry.'},
          ],
          'actions': [
            for (final descriptor in _dispatcher.descriptors)
              descriptor.toJson(),
          ],
          'multiFileGuarantee': 'recoverable',
          'fullParity': AuthoringFullParityCatalog.canonical().toJson(),
        },
        field: 'describeMutations',
      );

  @override
  Future<Map<String, Object?>> stageArtifact({
    required String sourcePath,
    String? declaredMediaType,
  }) async {
    final store = artifacts;
    if (store is! ArtifactFileStager) {
      throw const ArtifactStoreException(
        'artifact.file_staging_unsupported',
        'The configured artifact store cannot stage local files.',
      );
    }
    final stager = store as ArtifactFileStager;
    final stored = await stager.importFile(
      sourcePath,
      declaredMediaType: declaredMediaType,
    );
    final reference = stored.reference;
    return freezeContractJsonObject(
      {
        'artifactHandle': reference.handle,
        'digest': reference.digest,
        'mediaType': reference.mediaType,
        'byteLength': reference.byteLength,
        'deduplicated': stored.deduplicated,
      },
      field: 'stageArtifact',
    );
  }

  @override
  Future<void> attachProject({
    required String projectRootPath,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
  }) async {
    if (_sessions.containsKey(projectHandle) ||
        _projectsByWorkspace.containsKey(workspaceHandle)) {
      throw const WorkspaceHandleException(
        'workspace.mutation_session_exists',
        'A mutation session is already attached to these handles.',
      );
    }
    final canonicalRoot = await _policy.authorizeProjectRoot(projectRootPath);
    final snapshot = await _snapshotLoader.load(projectHandle);
    await _requireRootMatchesSnapshot(canonicalRoot, snapshot);
    final projectId = _projectIdentity(canonicalRoot);
    final session = await _LocalMapAuthoringSession.open(
      canonicalProjectRoot: canonicalRoot,
      projectId: projectId,
      workspaceHandle: workspaceHandle,
      projectHandle: projectHandle,
      snapshotLoader: _snapshotLoader,
      dispatcher: _dispatcher,
      actor: _actor,
      authorizationLimits: _authorizationLimits,
      clock: _clock,
      faultInjector: _faultInjector,
    );
    _sessions[projectHandle] = session;
    _projectsByWorkspace[workspaceHandle] = projectHandle;
  }

  @override
  Future<bool> detachWorkspace(WorkspaceHandle workspaceHandle) async {
    final projectHandle = _projectsByWorkspace.remove(workspaceHandle);
    if (projectHandle == null) return false;
    _sessions.remove(projectHandle);
    return true;
  }

  @override
  Future<Map<String, Object?>> plan(
    ProjectHandle projectHandle,
    AuthoringRequest request,
  ) =>
      _session(projectHandle).plan(request);

  @override
  Future<Map<String, Object?>> confirm(
    ProjectHandle projectHandle, {
    required String planId,
  }) =>
      _session(projectHandle).confirm(planId);

  @override
  Future<Map<String, Object?>> apply(
    ProjectHandle projectHandle, {
    required String planId,
    required String operationId,
    String? confirmationToken,
  }) =>
      _session(projectHandle).apply(
        planId: planId,
        operationId: operationId,
        confirmationToken: confirmationToken,
      );

  @override
  Future<Map<String, Object?>> undo(
    ProjectHandle projectHandle, {
    required String entryId,
    required String idempotencyKey,
  }) =>
      _session(projectHandle).undo(
        entryId: entryId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<Map<String, Object?>> history(
    ProjectHandle projectHandle, {
    required int limit,
    String? cursor,
  }) =>
      _session(projectHandle).history(limit: limit, cursor: cursor);

  @override
  Future<Map<String, Object?>> recover(
    ProjectHandle projectHandle, {
    required String operationId,
  }) =>
      _session(projectHandle).recover(operationId);

  _LocalMapAuthoringSession _session(ProjectHandle projectHandle) {
    final session = _sessions[projectHandle];
    if (session == null) {
      throw const WorkspaceHandleException(
        'workspace.mutation_session_unknown',
        'The requested mutation session is unknown.',
      );
    }
    _snapshotLoader.requireActiveProject(projectHandle);
    return session;
  }

  Future<void> _requireRootMatchesSnapshot(
    String canonicalRoot,
    ProjectSnapshot snapshot,
  ) async {
    const reader = LocalProjectFileReader();
    for (final entry in snapshot.resourceStorageKeys.entries) {
      final bytes = await reader.readBytes(
        projectRoot: canonicalRoot,
        relativePath: entry.value,
      );
      if (!_bytesEqual(bytes, snapshot.resourceBytes(entry.key))) {
        throw const WorkspaceHandleException(
          'workspace.mutation_binding_mismatch',
          'The mutation root does not match the opened project handle.',
        );
      }
    }
  }
}

final class _LocalMapAuthoringSession {
  const _LocalMapAuthoringSession._({
    required this.projectId,
    required this.workspaceHandle,
    required this.projectHandle,
    required ProjectSnapshotLoader snapshotLoader,
    required MapMutationDispatcher dispatcher,
    required AuthoringActor actor,
    required AuthoringPlanStore plans,
    required AuthoringActionPlanner planner,
    required AuthoringAuthorizationPolicy policy,
    required AuthoringConfirmationStore confirmations,
    required SecureAuthoringMutationExecutor executor,
    required AuthoringUndoService undoService,
    required AuthoringHistoryStore history,
    required AuthoringRecoveryService recovery,
  })  : _snapshotLoader = snapshotLoader,
        _dispatcher = dispatcher,
        _actor = actor,
        _plans = plans,
        _planner = planner,
        _policy = policy,
        _confirmations = confirmations,
        _executor = executor,
        _undoService = undoService,
        _history = history,
        _recovery = recovery;

  static Future<_LocalMapAuthoringSession> open({
    required String canonicalProjectRoot,
    required String projectId,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required ProjectSnapshotLoader snapshotLoader,
    required MapMutationDispatcher dispatcher,
    required AuthoringActor actor,
    required AuthoringSecurityLimits authorizationLimits,
    required DateTime Function() clock,
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final gateway = await LocalTransactionFileGateway.open(
      projectRoot: canonicalProjectRoot,
    );
    final history = await FileAuthoringHistoryStore.open(
      projectRoot: canonicalProjectRoot,
    );
    final blobs = await FileAuthoringContentBlobStore.open(
      projectRoot: canonicalProjectRoot,
    );
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    final audit = await FileAuthoringAuditLog.open(
      projectRoot: canonicalProjectRoot,
    );
    final plans = AuthoringPlanStore(clock: clock);
    final planner = AuthoringActionPlanner(store: plans);
    final idempotency = AuthoringIdempotencyLedger(
      store: FileIdempotencyStore(
        filePath: _joinAll([
          canonicalProjectRoot,
          '.pokemap',
          'authoring',
          'idempotency.jsonl',
        ]),
      ),
      clock: clock,
    );
    final transaction = JournaledAuthoringTransaction(
      plans: plans,
      gateway: gateway,
      idempotency: idempotency,
      clock: clock,
      faultInjector: faultInjector,
      commitHook: recorder,
    );
    final confirmations = AuthoringConfirmationStore(clock: clock);
    final policy = AuthoringAuthorizationPolicy(
      confirmations: confirmations,
      limits: authorizationLimits,
      clock: clock,
    );
    final executor = SecureAuthoringMutationExecutor(
      transaction: transaction,
      policy: policy,
      auditLog: audit,
      clock: clock,
      auditIdFactory: () => _secureIdentity('audit_'),
    );
    final undoService = AuthoringUndoService(
      history: history,
      blobs: blobs,
      gateway: gateway,
      planner: planner,
      policy: policy,
      executor: executor,
      tokenFactory: _secureIdentity,
    );
    final recovery = AuthoringRecoveryService(
      gateway: gateway,
      idempotency: idempotency,
      clock: clock,
      commitHook: recorder,
      mutationGuard: () => snapshotLoader.requireActiveProject(projectHandle),
    );
    return _LocalMapAuthoringSession._(
      projectId: projectId,
      workspaceHandle: workspaceHandle,
      projectHandle: projectHandle,
      snapshotLoader: snapshotLoader,
      dispatcher: dispatcher,
      actor: actor,
      plans: plans,
      planner: planner,
      policy: policy,
      confirmations: confirmations,
      executor: executor,
      undoService: undoService,
      history: history,
      recovery: recovery,
    );
  }

  final String projectId;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader _snapshotLoader;
  final MapMutationDispatcher _dispatcher;
  final AuthoringActor _actor;
  final AuthoringPlanStore _plans;
  final AuthoringActionPlanner _planner;
  final AuthoringAuthorizationPolicy _policy;
  final AuthoringConfirmationStore _confirmations;
  final SecureAuthoringMutationExecutor _executor;
  final AuthoringUndoService _undoService;
  final AuthoringHistoryStore _history;
  final AuthoringRecoveryService _recovery;

  Future<Map<String, Object?>> history({
    required int limit,
    String? cursor,
  }) async {
    final page = await _history.list(
      projectId: projectId,
      limit: limit,
      cursor:
          cursor == null ? null : AuthoringHistoryCursor.fromWireValue(cursor),
    );
    return freezeContractJsonObject(
      {
        'entries': [for (final entry in page.entries) entry.toJson()],
        if (page.nextCursor case final next?) 'nextCursor': next.wireValue,
      },
      field: 'mutationHistory',
    );
  }

  Future<Map<String, Object?>> plan(AuthoringRequest request) async {
    _requireWorkspace(request.workspaceHandle);
    final idempotencyKey = request.idempotencyKey;
    if (idempotencyKey == null) {
      throw AuthoringPlanException(
        code: 'plan.idempotency_key_required',
        message: 'Mutation planning requires an idempotency key.',
      );
    }
    final descriptor = _dispatcher.descriptor(request.actionId);
    if (descriptor.version != request.actionVersion) {
      throw AuthoringPlanException(
        code: 'plan.action_version_unsupported',
        message: 'The requested action version is unsupported.',
      );
    }
    _policy.authorize(
      AuthoringAuthorizationRequest(
        actor: _actor,
        projectId: projectId,
        operation: AuthoringSecurityOperation.plan,
        actionId: descriptor.id,
        actionVersion: descriptor.version,
        riskLevel: descriptor.riskLevel,
        requestBytes:
            utf8.encode(canonicalAuthoringJson(request.toJson())).length,
        touchedResources: 0,
        additionalPermissions:
            descriptor.requiredPermissions.map(_permissionScope),
      ),
    );
    final snapshot = await _snapshotLoader.load(projectHandle);
    final plan = await _planner.plan(
      request: request,
      snapshot: snapshot,
      build: _dispatcher.build,
    );
    return freezeContractJsonObject(
      {
        'planId': plan.planId,
        'applicable': plan.applicable,
        if (plan.nonApplicableReason case final reason?)
          'nonApplicableReason': reason,
        'snapshotRevision': snapshot.revision,
        'plan': plan.toJson(),
        'receipt': plan.toPlannedReceipt().toJson(),
      },
      field: 'mutationPlan',
    );
  }

  Future<Map<String, Object?>> confirm(String planId) async {
    final snapshot = await _snapshotLoader.load(projectHandle);
    final plan = _plans.resolve(
      _safeIdentity(planId, 'planId'),
      currentProjectRevision: snapshot.revision,
    );
    _requireApplicablePlan(plan);
    final token = _confirmations.issue(
      AuthoringConfirmationBinding.forPlan(
        actorId: _actor.actorId,
        projectId: projectId,
        plan: plan,
      ),
    );
    return Map.unmodifiable({
      'planId': plan.planId,
      'confirmationToken': token.wireValue,
      'expiresInSeconds': _confirmations.lifetime.inSeconds,
    });
  }

  Future<Map<String, Object?>> apply({
    required String planId,
    required String operationId,
    String? confirmationToken,
  }) async {
    final safePlanId = _safeIdentity(planId, 'planId');
    final safeOperationId = _safeIdentity(operationId, 'operationId');
    final plan = _plans.resolveActive(safePlanId);
    _requireApplicablePlan(plan);
    _requireWorkspace(plan.request.workspaceHandle);
    final key = plan.request.idempotencyKey;
    if (key == null) {
      throw AuthoringPlanException(
        code: 'plan.idempotency_key_required',
        message: 'Mutation apply requires an idempotency key.',
      );
    }
    final snapshot = await _snapshotLoader.load(projectHandle);
    final descriptor = _dispatcher.descriptor(plan.request.actionId);
    final receipt = await _executor.apply(
      actor: _actor,
      projectId: projectId,
      action: descriptor,
      plan: plan,
      currentProjectRevision: snapshot.revision,
      scope: AuthoringIdempotencyScope(
        actorId: _actor.actorId,
        projectId: projectId,
        actionId: descriptor.id,
        actionVersion: descriptor.version,
        key: key,
      ),
      operationId: safeOperationId,
      confirmationToken: confirmationToken == null
          ? null
          : AuthoringConfirmationToken.fromWireValue(confirmationToken),
    );
    final projected = receipt.status == AuthoringReceiptStatus.applied
        ? await _snapshotLoader.adoptAppliedChanges(
            projectHandle,
            baseRevision: plan.baseRevision,
            changes: plan.changeSet.changes,
          )
        : null;
    return _receiptResult(receipt, snapshot: projected);
  }

  Future<Map<String, Object?>> undo({
    required String entryId,
    required String idempotencyKey,
  }) async {
    final snapshot = await _snapshotLoader.load(projectHandle);
    final prepared = await _undoService.planUndo(
      actor: _actor,
      projectId: projectId,
      entryId: _safeIdentity(entryId, 'entryId'),
      snapshot: snapshot,
      workspaceHandle: workspaceHandle.value,
      idempotencyKey: _safeIdentity(idempotencyKey, 'idempotencyKey'),
    );
    final receipt = await _undoService.apply(prepared);
    return _receiptResult(receipt);
  }

  Future<Map<String, Object?>> recover(String operationId) async {
    final safeOperationId = _safeIdentity(operationId, 'operationId');
    _policy.authorize(
      AuthoringAuthorizationRequest(
        actor: _actor,
        projectId: projectId,
        operation: AuthoringSecurityOperation.recover,
        actionId: 'transaction.recover',
        actionVersion: 1,
        riskLevel: AuthoringRiskLevel.high,
        requestBytes: utf8.encode(safeOperationId).length,
        touchedResources: 0,
      ),
    );
    final receipt = await _recovery.resume(safeOperationId);
    return _receiptResult(receipt);
  }

  Future<Map<String, Object?>> _receiptResult(
    AuthoringReceipt receipt, {
    ProjectSnapshot? snapshot,
  }) async {
    final resolvedSnapshot =
        snapshot ?? await _snapshotLoader.load(projectHandle);
    return freezeContractJsonObject(
      {
        'receipt': receipt.toJson(),
        'snapshotRevision': resolvedSnapshot.revision,
      },
      field: 'mutationReceipt',
    );
  }

  void _requireWorkspace(String value) {
    if (value != workspaceHandle.value) {
      throw const WorkspaceHandleException(
        'workspace.mutation_handle_mismatch',
        'The request workspace does not own this mutation session.',
      );
    }
  }
}

void _requireApplicablePlan(AuthoringPlan plan) {
  if (plan.applicable) return;
  throw AuthoringPlanException(
    code: 'plan.dry_run_not_applicable',
    message:
        'This plan is a dry-run preview and cannot be confirmed or applied.',
    remediation: const [
      'Create a new plan with dryRun set to false before requesting apply.',
    ],
  );
}

AuthoringPermissionScope _permissionScope(AuthoringPermission permission) =>
    AuthoringPermissionScope.fromWireName(permission.wireName);

String _projectIdentity(String canonicalRoot) {
  final fingerprint = computeAuthoringJsonFingerprint(
    canonicalRoot,
    logicalName: 'local-project-root.json',
  );
  return 'local_project_${fingerprint.substring(7)}';
}

String _safeIdentity(String value, String field) {
  try {
    return safeAuthoringSecurityIdentifier(value, field);
  } on ArgumentError {
    throw FormatException('$field must be a safe opaque identity.');
  }
}

String _secureIdentity(String prefix) {
  final random = Random.secure();
  final body = List.generate(
    24,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix$body';
}

String _joinAll(List<String> segments) => segments.join(Platform.pathSeparator);

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

DateTime _systemClock() => DateTime.now().toUtc();

final AuthoringActor _localActor = AuthoringActor(
  actorId: 'local_cli',
  permissions: const [
    AuthoringPermissionScope.projectRead,
    AuthoringPermissionScope.projectWrite,
    AuthoringPermissionScope.projectDestructive,
    AuthoringPermissionScope.assetRead,
    AuthoringPermissionScope.assetWrite,
    AuthoringPermissionScope.importRun,
    AuthoringPermissionScope.recoveryApply,
    AuthoringPermissionScope.renderRun,
  ],
);
