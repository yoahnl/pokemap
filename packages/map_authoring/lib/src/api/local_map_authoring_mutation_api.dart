import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../application/map_mutation_dispatcher.dart';
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
import '../security/secure_recovery_executor.dart';
import '../support/authoring_fingerprint.dart';
import '../support/authoring_performance_observer.dart';
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
import 'authoring_mutation_contracts.dart';
import 'authoring_mutation_api.dart';

/// Filesystem composition root for secure map mutation sessions.
///
/// Canonical roots are captured only by server-side adapters. They never enter
/// action contracts, receipts, errors, audit records, or JSONL responses.
final class LocalMapAuthoringMutationApi
    implements
        AuthoringMutationApiPort,
        AuthoringArtifactStagingPort,
        AuthoringMutationServicePort,
        AuthoringArtifactStagingServicePort {
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
    AuthoringPerformanceObserver? performanceObserver,
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
          performanceObserver: performanceObserver,
        );
    _performanceObserver = performanceObserver;
  }

  final WorkspacePolicy _policy;
  final ProjectSnapshotLoader _snapshotLoader;
  late final MapMutationDispatcher _dispatcher;
  late final ArtifactStore artifacts;
  final AuthoringActor _actor;
  final AuthoringSecurityLimits _authorizationLimits;
  final DateTime Function() _clock;
  final AuthoringTransactionFaultInjector? _faultInjector;
  late final AuthoringPerformanceObserver? _performanceObserver;
  final Map<ProjectHandle, _LocalMapAuthoringSession> _sessions = {};
  final Map<WorkspaceHandle, ProjectHandle> _projectsByWorkspace = {};

  @override
  AuthoringMutationDescription describeMutationContracts() =>
      AuthoringMutationDescription(
        commands: const [
          AuthoringMutationCommandDescriptor(
            id: 'apply',
            summary: 'Apply a frozen mutation plan.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'confirm',
            summary: 'Confirm one destructive plan.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'history',
            summary: 'List committed history entries.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'plan',
            summary: 'Plan and preview a map mutation.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'recover',
            summary: 'Resume a recoverable transaction.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'stage_artifact',
            summary: 'Securely stage a local file for an asset mutation.',
          ),
          AuthoringMutationCommandDescriptor(
            id: 'undo',
            summary: 'Undo one committed history entry.',
          ),
        ],
        actions: _dispatcher.descriptors,
        fullParity: AuthoringFullParityCatalog.canonical(),
      );

  @override
  Map<String, Object?> describeMutations() =>
      describeMutationContracts().toJson();

  @override
  Future<AuthoringArtifactStageResult> stageArtifactFile({
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
    return AuthoringArtifactStageResult(
      reference: stored.reference,
      deduplicated: stored.deduplicated,
    );
  }

  @override
  Future<Map<String, Object?>> stageArtifact({
    required String sourcePath,
    String? declaredMediaType,
  }) async =>
      (await stageArtifactFile(
        sourcePath: sourcePath,
        declaredMediaType: declaredMediaType,
      ))
          .toJson();

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
      performanceObserver: _performanceObserver,
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
  Future<AuthoringMutationPlanResult> planMutation(
    ProjectHandle projectHandle,
    AuthoringRequest request,
  ) =>
      _session(projectHandle).planMutation(request);

  @override
  Future<Map<String, Object?>> plan(
    ProjectHandle projectHandle,
    AuthoringRequest request,
  ) async =>
      (await planMutation(projectHandle, request)).toJson();

  @override
  Future<AuthoringMutationConfirmationResult> confirmMutation(
    ProjectHandle projectHandle, {
    required String planId,
  }) =>
      _session(projectHandle).confirmMutation(planId);

  @override
  Future<Map<String, Object?>> confirm(
    ProjectHandle projectHandle, {
    required String planId,
  }) async =>
      (await confirmMutation(projectHandle, planId: planId)).toJson();

  @override
  Future<AuthoringMutationResult> applyMutation(
    ProjectHandle projectHandle, {
    required String planId,
    required String operationId,
    String? confirmationToken,
  }) =>
      _session(projectHandle).applyMutation(
        planId: planId,
        operationId: operationId,
        confirmationToken: confirmationToken,
      );

  @override
  Future<Map<String, Object?>> apply(
    ProjectHandle projectHandle, {
    required String planId,
    required String operationId,
    String? confirmationToken,
  }) async =>
      (await applyMutation(
        projectHandle,
        planId: planId,
        operationId: operationId,
        confirmationToken: confirmationToken,
      ))
          .toJson();

  @override
  Future<AuthoringMutationResult> undoMutation(
    ProjectHandle projectHandle, {
    required String entryId,
    required String idempotencyKey,
  }) =>
      _session(projectHandle).undoMutation(
        entryId: entryId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<Map<String, Object?>> undo(
    ProjectHandle projectHandle, {
    required String entryId,
    required String idempotencyKey,
  }) async =>
      (await undoMutation(
        projectHandle,
        entryId: entryId,
        idempotencyKey: idempotencyKey,
      ))
          .toJson();

  @override
  Future<AuthoringMutationHistoryResult> listMutationHistory(
    ProjectHandle projectHandle, {
    required int limit,
    String? cursor,
  }) =>
      _session(projectHandle).listMutationHistory(limit: limit, cursor: cursor);

  @override
  Future<Map<String, Object?>> history(
    ProjectHandle projectHandle, {
    required int limit,
    String? cursor,
  }) async =>
      (await listMutationHistory(
        projectHandle,
        limit: limit,
        cursor: cursor,
      ))
          .toJson();

  @override
  Future<AuthoringMutationResult> recoverMutation(
    ProjectHandle projectHandle, {
    required String operationId,
  }) =>
      _session(projectHandle).recoverMutation(operationId);

  @override
  Future<Map<String, Object?>> recover(
    ProjectHandle projectHandle, {
    required String operationId,
  }) async =>
      (await recoverMutation(projectHandle, operationId: operationId)).toJson();

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
    required SecureAuthoringRecoveryExecutor recoveryExecutor,
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
        _recoveryExecutor = recoveryExecutor;

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
    AuthoringPerformanceObserver? performanceObserver,
  }) async {
    final gateway = await LocalTransactionFileGateway.open(
      projectRoot: canonicalProjectRoot,
      performanceObserver: performanceObserver,
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
    final recoveryExecutor = SecureAuthoringRecoveryExecutor(
      recover: recovery.resume,
      policy: policy,
      auditLog: audit,
      clock: clock,
      auditIdFactory: () => _secureIdentity('audit_'),
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
      recoveryExecutor: recoveryExecutor,
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
  final SecureAuthoringRecoveryExecutor _recoveryExecutor;

  Future<AuthoringMutationHistoryResult> listMutationHistory({
    required int limit,
    String? cursor,
  }) async {
    final page = await _history.list(
      projectId: projectId,
      limit: limit,
      cursor:
          cursor == null ? null : AuthoringHistoryCursor.fromWireValue(cursor),
    );
    return AuthoringMutationHistoryResult(page);
  }

  Future<AuthoringMutationPlanResult> planMutation(
    AuthoringRequest request,
  ) async {
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
    return AuthoringMutationPlanResult(
      plan: plan,
      snapshotRevision: snapshot.revision,
      receipt: plan.toPlannedReceipt(),
    );
  }

  Future<AuthoringMutationConfirmationResult> confirmMutation(
    String planId,
  ) async {
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
    return AuthoringMutationConfirmationResult(
      planId: plan.planId,
      confirmationToken: token.wireValue,
      expiresInSeconds: _confirmations.lifetime.inSeconds,
    );
  }

  Future<AuthoringMutationResult> applyMutation({
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
    return _mutationResult(receipt, snapshot: projected);
  }

  Future<AuthoringMutationResult> undoMutation({
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
    return _mutationResult(receipt);
  }

  Future<AuthoringMutationResult> recoverMutation(String operationId) async {
    final safeOperationId = _safeIdentity(operationId, 'operationId');
    final receipt = await _recoveryExecutor.recover(
      actor: _actor,
      projectId: projectId,
      operationId: safeOperationId,
    );
    return _mutationResult(receipt);
  }

  Future<AuthoringMutationResult> _mutationResult(
    AuthoringReceipt receipt, {
    ProjectSnapshot? snapshot,
  }) async {
    final resolvedSnapshot =
        snapshot ?? await _snapshotLoader.load(projectHandle);
    return AuthoringMutationResult(
      receipt: receipt,
      snapshotRevision: resolvedSnapshot.revision,
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
