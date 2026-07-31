# PMCP-030 — Created Files Full Content

This appendix reproduces every production, test, and planning file created by
PMCP-030 exactly as it stood immediately before the lot commit. The Evidence
Pack and this appendix are reporting artifacts and are intentionally not
self-reproduced.

## `pokemap_authoring_api_mcp_phase_4_implementation_plan.md`

~~~~~~~~markdown
# PokeMap Authoring API — Phase 4 Implementation Plan

> Phase: **4 — Maps de bout en bout**
> Lots: **PMCP-030 → PMCP-035**
> Execution: current `main` branch, one verified commit per lot, no push
> Initial Git state: clean at `1e3d8787a feat(authoring): add mutation history and undo`

## Goal and exit contract

Phase 4 exposes map authoring through the protocol-neutral API built in phases
1–3. A structured request must be able to plan, preview, validate, apply,
recover, and undo a complete map workflow without importing Flutter or editor
infrastructure into `map_authoring`.

The phase is complete only when fresh tests prove all of the following:

- map lifecycle changes preserve exact pre-images and write the manifest and
  map documents through one recoverable transaction;
- every write has a structured diff, a revision-bound preview, a receipt, and
  an undo path;
- layer and bounded region operations batch atomically and preserve layer
  dimensions;
- semantic terrain, path, surface, and autotile requests are deterministic for
  the same seed and refuse missing presets with repair guidance;
- environment and border generation is deterministic, local, diagnosed, and
  refuses unpublished or invalid blueprint state;
- placed elements, entities, triggers, gameplay zones, and collision expose
  typed mutations plus effective-collision provenance and reachability checks;
- warps and bidirectional connections update both maps in one recoverable
  transaction, and the world graph is deterministic;
- rendering is accessed through a port and is always tied to a saved snapshot
  revision; the pure package does not depend on Flutter or Flame;
- the JSONL worker exposes the same plan/apply contracts without returning
  canonical filesystem paths.

## Architecture decisions

- `map_authoring` remains pure Dart and depends only on `map_core`.
- Domain handlers build immutable `AuthoringMutationDraft` values from one
  `ProjectSnapshot`; only the Phase 3 secure executor receives a write gateway.
- Exact snapshot bytes are retained under path-free resource identities so
  compare-and-swap uses real disk pre-images rather than re-encoded objects.
- Map documents use the editor-compatible two-space JSON representation.
  Manifest writes merge typed fields into the original JSON object so unknown
  top-level project fields survive lifecycle operations.
- Public resource references stay typed and path-free. Safe manifest-owned
  relative paths remain private transaction storage keys.
- A local mutation session captures the authorized canonical root behind
  opaque project/workspace handles and composes the Phase 3 journal,
  idempotency, audit, history, confirmation, recovery, and undo services.
- Rendering uses an injected `MapRenderPort`; the default pure adapter returns
  a deterministic render model, while Flutter/Flame adapters remain outside
  `map_authoring`.

## Verification and review passes

Sub-agent delegation is disabled by the active repository/session rules. Each
lot therefore records five separate local passes required by `codex_rule.md`:

1. **Audit / Architecture** — boundaries, contracts, and dependency review;
2. **Implementation** — scoped diff review against the lot exit criteria;
3. **Tests** — RED/GREEN, guards, failure cases, and non-regression;
4. **Build / Validation** — focused tests, package suite, analyzer, formatter,
   and JSONL executable smoke where relevant;
5. **Critique finale** — durability, determinism, security, overclaim, and
   remaining-risk review.

## PMCP-030 — Canonical map lifecycle

- Add lifecycle handlers for create, save, rename, duplicate, delete, and
  resize, plus dependency and resize-impact preflights.
- Add a generic map mutation dispatcher and local secure mutation session.
- Add JSONL `plan`, `confirm`, `apply`, `undo`, and `recover` commands while
  retaining the read-only worker mode used by Phase 2.
- Prove manifest+map crash recovery, reference protection, receipt/history,
  create/resize undo, legacy path ownership, and editor-compatible encoding.
- Evidence: `reports/analysis/pmcp_030_map_lifecycle_evidence.md` plus created
  content appendix.
- Commit: `feat(authoring): add canonical map lifecycle`

## PMCP-031 — Layers, regions, and operation batches

- Add lifecycle support for every `MapLayer` kind and a bounded
  `map.apply_operations` batch.
- Support paint, erase, stamp, fill, replace, flood fill, line, polyline,
  rectangle, polygon, clipboard move/copy/cut/paste, rotate, and flip where the
  layer semantics allow them.
- Apply the complete batch in memory, validate once, and emit one map change,
  one receipt, and one undo entry; any invalid operation rejects the full
  batch.
- Evidence: `reports/analysis/pmcp_031_map_operations_evidence.md` plus appendix.
- Commit: `feat(authoring): add atomic map operation batches`

## PMCP-032 — Terrain, paths, surfaces, and autotile

- Add typed semantic operations using project preset IDs instead of raw tile
  coordinates in the normal workflow.
- Freeze the generation seed in the plan and prove preview/apply determinism.
- Diagnose missing presets with stable codes and repair suggestions.
- Evidence: `reports/analysis/pmcp_032_semantic_painting_evidence.md` plus
  appendix.
- Commit: `feat(authoring): add semantic map painting`

## PMCP-033 — Environment and borders

- Add deterministic environment areas, masks, generation, placements, and
  manual overrides.
- Add border stroke, feature, blueprint link/relink, materialization, resize,
  diagnostics, readiness, and preview operations by adapting `map_core`.
- Bind every generated preview to revision and seed and prove local-halo
  behavior.
- Evidence: `reports/analysis/pmcp_033_environment_border_evidence.md` plus
  appendix.
- Commit: `feat(authoring): add environment and border actions`

## PMCP-034 — Spatial objects and effective collision

- Add typed CRUD and atomic batch moves for placed elements, entities, NPCs,
  triggers, gameplay zones, and collision layers.
- Add effective-collision inspection with source provenance, walkability, and
  deterministic reachability diagnostics.
- Refuse incompatible payloads and out-of-bounds batches before mutation.
- Evidence: `reports/analysis/pmcp_034_spatial_collision_evidence.md` plus
  appendix.
- Commit: `feat(authoring): add spatial map authoring`

## PMCP-035 — Warps, connections, world graph, and rendering

- Add warp/connection CRUD plus reciprocal/bidirectional two-map plans.
- Add deterministic graph inspection, connected/disconnected sets,
  consistency validation, and pathfinding.
- Add alignment preview and revision-bound map/region/layer render requests
  through `MapRenderPort`, including optional collision/entity/warp overlays.
- Explicitly report that no global authored `worldLayout` exists.
- Evidence: `reports/analysis/pmcp_035_world_graph_render_evidence.md` plus
  appendix.
- Commit: `feat(authoring): add world graph and map rendering`

## Final phase validation

From `packages/map_authoring`:

```bash
dart test
dart analyze
dart format --output=none --set-exit-if-changed lib test bin
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host </dev/null
```

Run focused `map_core`, `map_editor`, and `map_runtime` checks whenever a lot
changes or adapts their public contracts. Record exact results and final Git
status in the PMCP-035 evidence pack; do not update roadmap status without an
explicit request.
~~~~~~~~

## `packages/map_authoring/lib/src/api/authoring_mutation_api.dart`

~~~~~~~~dart
import '../contracts/authoring_request.dart';
import '../workspace/workspace_handle_store.dart';

/// Mutation port consumed by protocol adapters alongside the read API.
abstract interface class AuthoringMutationApiPort {
  Map<String, Object?> describeMutations();

  Future<void> attachProject({
    required String projectRootPath,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
  });

  Future<bool> detachWorkspace(WorkspaceHandle workspaceHandle);

  Future<Map<String, Object?>> plan(
    ProjectHandle projectHandle,
    AuthoringRequest request,
  );

  Future<Map<String, Object?>> confirm(
    ProjectHandle projectHandle, {
    required String planId,
  });

  Future<Map<String, Object?>> apply(
    ProjectHandle projectHandle, {
    required String planId,
    required String operationId,
    String? confirmationToken,
  });

  Future<Map<String, Object?>> undo(
    ProjectHandle projectHandle, {
    required String entryId,
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> recover(
    ProjectHandle projectHandle, {
    required String operationId,
  });
}
~~~~~~~~

## `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/json_contract_support.dart';
import '../domains/maps/map_mutation_dispatcher.dart';
import '../history/content_blob_store.dart';
import '../history/file_history_store.dart';
import '../history/history_store.dart';
import '../history/undo_service.dart';
import '../ports/idempotency_store.dart';
import '../ports/project_file_reader.dart';
import '../security/audit_log.dart';
import '../security/authoring_permission.dart';
import '../security/authorization_policy.dart';
import '../security/confirmation_token.dart';
import '../security/secure_mutation_executor.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/action_planner.dart';
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
final class LocalMapAuthoringMutationApi implements AuthoringMutationApiPort {
  LocalMapAuthoringMutationApi({
    required WorkspacePolicy policy,
    required ProjectSnapshotLoader snapshotLoader,
    MapMutationDispatcher? dispatcher,
    AuthoringActor? actor,
    DateTime Function()? clock,
    AuthoringTransactionFaultInjector? faultInjector,
  })  : _policy = policy,
        _snapshotLoader = snapshotLoader,
        _dispatcher = dispatcher ?? MapMutationDispatcher.canonical(),
        _actor = actor ?? _localActor,
        _clock = clock ?? _systemClock,
        _faultInjector = faultInjector;

  final WorkspacePolicy _policy;
  final ProjectSnapshotLoader _snapshotLoader;
  final MapMutationDispatcher _dispatcher;
  final AuthoringActor _actor;
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
            {'id': 'plan', 'summary': 'Plan and preview a map mutation.'},
            {'id': 'recover', 'summary': 'Resume a recoverable transaction.'},
            {'id': 'undo', 'summary': 'Undo one committed history entry.'},
          ],
          'actions': [
            for (final descriptor in _dispatcher.descriptors)
              descriptor.toJson(),
          ],
          'multiFileGuarantee': 'recoverable',
        },
        field: 'describeMutations',
      );

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
    return session;
  }

  Future<void> _requireRootMatchesSnapshot(
    String canonicalRoot,
    ProjectSnapshot snapshot,
  ) async {
    const reader = LocalProjectFileReader();
    final manifest = await reader.readBytes(
      projectRoot: canonicalRoot,
      relativePath: 'project.json',
    );
    if (!_bytesEqual(manifest, snapshot.resourceBytes('project'))) {
      throw const WorkspaceHandleException(
        'workspace.mutation_binding_mismatch',
        'The mutation root does not match the opened project handle.',
      );
    }
    for (final entry in snapshot.manifest.maps) {
      final bytes = await reader.readBytes(
        projectRoot: canonicalRoot,
        relativePath: entry.relativePath,
      );
      if (!_bytesEqual(bytes, snapshot.resourceBytes('map:${entry.id}'))) {
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
        _recovery = recovery;

  static Future<_LocalMapAuthoringSession> open({
    required String canonicalProjectRoot,
    required String projectId,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required ProjectSnapshotLoader snapshotLoader,
    required MapMutationDispatcher dispatcher,
    required AuthoringActor actor,
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
  final AuthoringRecoveryService _recovery;

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
    return _receiptResult(receipt);
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

  Future<Map<String, Object?>> _receiptResult(AuthoringReceipt receipt) async {
    final snapshot = await _snapshotLoader.load(projectHandle);
    return freezeContractJsonObject(
      {
        'receipt': receipt.toJson(),
        'snapshotRevision': snapshot.revision,
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
    AuthoringPermissionScope.recoveryApply,
    AuthoringPermissionScope.renderRun,
  ],
);
~~~~~~~~

## `packages/map_authoring/lib/src/domains/maps/map_lifecycle_actions.dart`

~~~~~~~~dart
import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_lifecycle_adapter.dart';

/// Canonical lifecycle action family registered by the map mutation API.
final class MapLifecycleActions {
  const MapLifecycleActions({
    MapLifecycleAdapter adapter = const MapLifecycleAdapter(),
  }) : _adapter = adapter;

  final MapLifecycleAdapter _adapter;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor(
        'map.create', 'Create a complete map', AuthoringRiskLevel.medium),
    _descriptor(
      'map.delete_apply',
      'Delete an unreferenced map',
      AuthoringRiskLevel.high,
    ),
    _descriptor(
        'map.duplicate', 'Duplicate a complete map', AuthoringRiskLevel.low),
    _descriptor(
        'map.rename', 'Rename an unreferenced map', AuthoringRiskLevel.medium),
    _descriptor('map.resize_apply', 'Resize a map without data loss',
        AuthoringRiskLevel.medium),
    _descriptor(
        'map.save', 'Save a complete validated map', AuthoringRiskLevel.medium),
  ]);

  AuthoringActionDescriptor descriptor(String actionId) {
    for (final descriptor in descriptors) {
      if (descriptor.id == actionId) return descriptor;
    }
    throw MapAuthoringException(
      code: 'map.action_unsupported',
      message: 'The requested map lifecycle action is unsupported.',
      details: {'actionId': actionId},
    );
  }

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionVersion != 1) {
      throw MapAuthoringException(
        code: 'map.action_version_unsupported',
        message: 'The requested map lifecycle action version is unsupported.',
        details: {'actionVersion': context.request.actionVersion},
      );
    }
    return switch (context.request.actionId) {
      'map.create' => _adapter.create(context),
      'map.delete_apply' => _adapter.delete(context),
      'map.duplicate' => _adapter.duplicate(context),
      'map.rename' => _adapter.rename(context),
      'map.resize_apply' => _adapter.resize(context),
      'map.save' => _adapter.save(context),
      _ => throw MapAuthoringException(
          code: 'map.action_unsupported',
          message: 'The requested map lifecycle action is unsupported.',
          details: {'actionId': context.request.actionId},
        ),
    };
  }
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary,
  AuthoringRiskLevel risk,
) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'schema.$id.input.v1',
    outputSchemaId: 'schema.map.mutation.output.v1',
    riskLevel: risk,
    resourceKinds: const ['map', 'project'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: const {'multiFileGuarantee': 'recoverable'},
  );
}
~~~~~~~~

## `packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/project_file_reader.dart';
import '../../references/project_reference_index.dart';
import '../../references/reference_impact.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';

/// Stable domain failure returned by map action adapters.
final class MapAuthoringException implements Exception {
  MapAuthoringException({
    required this.code,
    required this.message,
    Map<String, Object?> details = const {},
    Iterable<String> remediation = const [],
  })  : details = Map.unmodifiable(details),
        remediation = List.unmodifiable(remediation);

  final String code;
  final String message;
  final Map<String, Object?> details;
  final List<String> remediation;

  @override
  String toString() => 'MapAuthoringException($code): $message';
}

/// Pure map lifecycle adapter. It never receives a filesystem write port.
final class MapLifecycleAdapter {
  const MapLifecycleAdapter();

  AuthoringMutationDraft create(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {
        'mapId',
        'name',
        'width',
        'height',
        'groupId',
        'role',
        'tilesetId',
      },
    );
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final mapId = _requireAvailableMapId(
      parameters.string('mapId'),
      snapshot.manifest,
    );
    final name = _mapName(parameters.optionalString('name') ?? mapId);
    final width = parameters.positiveInt('width');
    final height = parameters.positiveInt('height');
    final groupId = parameters.optionalString('groupId');
    if (groupId != null &&
        !snapshot.manifest.groups.any((group) => group.id == groupId)) {
      throw _failure(
        'map.group_missing',
        'The requested map group does not exist.',
        details: {'groupId': groupId},
      );
    }
    final role = _mapRole(parameters.optionalString('role') ?? 'exterior');
    final explicitTilesetId = parameters.optionalString('tilesetId');
    final tilesetId = explicitTilesetId == null
        ? _pickDefaultTilesetId(snapshot.manifest, groupId)
        : _requireTileset(snapshot.manifest, explicitTilesetId);
    final map = MapData(
      id: mapId,
      name: name,
      size: GridSize(width: width, height: height),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      tilesetId: tilesetId ?? '',
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tilesetId: tilesetId,
          tiles: List<int>.filled(width * height, 0, growable: false),
        ),
        MapLayer.terrain(
          id: 'l_terrain',
          name: 'Terrain',
          terrains: List<TerrainType>.filled(
            width * height,
            TerrainType.none,
            growable: false,
          ),
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: List<bool>.filled(
            width * height,
            false,
            growable: false,
          ),
        ),
      ],
    );
    final path = _canonicalMapPath(mapId);
    _requireAvailablePath(snapshot.manifest, path);
    final manifest = snapshot.manifest.copyWith(
      maps: [
        ...snapshot.manifest.maps,
        ProjectMapEntry(
          id: mapId,
          name: name,
          relativePath: path,
          groupId: groupId,
          role: role,
        ),
      ],
    );
    _validateProjected(manifest, [map]);
    final mapRef = AuthoringResourceRef(kind: 'map', id: mapId);
    final projectRef = _existingResource(snapshot, 'project', 'project');
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapRef,
            storageKey: path,
            beforeBytes: null,
            afterBytes: encodeMapAuthoringDocument(map),
          ),
          _manifestChange(snapshot, manifest, projectRef),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: mapRef,
            path: '/',
            after: _mapSummary(map),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: projectRef,
            path: '/maps/$mapId',
            after: _entrySummary(manifest.maps.last),
          ),
        ]),
      ),
      preview: {
        'operation': 'create',
        'mapId': mapId,
        'name': name,
        'size': {'width': width, 'height': height},
        'layerCount': map.layers.length,
        'storageGuarantee': 'recoverable',
      },
    );
  }

  AuthoringMutationDraft save(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'map'},
    );
    final rawMap = parameters.object('map');
    late final MapData updated;
    try {
      updated = MapData.fromJson(Map<String, dynamic>.from(rawMap));
    } on Object {
      throw _failure(
        'map.document_invalid',
        'The supplied map document is not valid PokeMap data.',
      );
    }
    _requireCanonicalMapId(updated.id);
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final entry = _requireMapEntry(snapshot.manifest, updated.id);
    final before = _requireMap(snapshot, updated.id);
    _validateProjected(snapshot.manifest, [updated]);
    final beforeBytes = snapshot.resourceBytes('map:${updated.id}');
    final afterBytes = encodeMapAuthoringDocument(updated);
    _requireChanged(beforeBytes, afterBytes);
    final resource = _existingResource(snapshot, 'map', updated.id);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: resource,
            storageKey: entry.relativePath,
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/',
            before: _mapSummary(before),
            after: _mapSummary(updated),
          ),
        ]),
      ),
      preview: {
        'operation': 'save',
        'mapId': updated.id,
        'before': _mapSummary(before),
        'after': _mapSummary(updated),
      },
    );
  }

  AuthoringMutationDraft rename(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'mapId', 'newMapId', 'name'},
    );
    final snapshot = context.snapshot;
    final oldId = parameters.string('mapId');
    _requireManifestOwnership(snapshot.manifest, allowedLegacyId: oldId);
    final entry = _requireMapEntry(snapshot.manifest, oldId);
    final source = _requireMap(snapshot, oldId);
    final newId = _requireAvailableMapId(
      parameters.string('newMapId'),
      snapshot.manifest,
      excludingId: oldId,
    );
    final name = _mapName(parameters.optionalString('name') ?? newId);
    final newPath = _canonicalMapPath(newId);
    _requireAvailablePath(
      snapshot.manifest,
      newPath,
      excludingId: oldId,
    );
    if (_pathKey(entry.relativePath) == _pathKey(newPath)) {
      throw _failure(
        'map.case_equivalent_rename',
        'Case-equivalent map paths require an explicit migration.',
      );
    }
    final impact = _referenceImpact(snapshot, oldId, newId: newId);
    _requireNoDependents(impact);
    final renamed = source.copyWith(id: newId, name: name);
    final manifest = snapshot.manifest.copyWith(
      maps: [
        for (final candidate in snapshot.manifest.maps)
          if (candidate.id == oldId)
            candidate.copyWith(id: newId, name: name, relativePath: newPath)
          else
            candidate,
      ],
    );
    _validateProjected(
      manifest,
      [
        for (final map in snapshot.maps)
          if (map.id == oldId) renamed else map,
      ],
    );
    final oldRef = _existingResource(snapshot, 'map', oldId);
    final newRef = AuthoringResourceRef(kind: 'map', id: newId);
    final projectRef = _existingResource(snapshot, 'project', 'project');
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: oldRef,
            storageKey: entry.relativePath,
            beforeBytes: snapshot.resourceBytes('map:$oldId'),
            afterBytes: null,
          ),
          AuthoringResourceChange(
            resource: newRef,
            storageKey: newPath,
            beforeBytes: null,
            afterBytes: encodeMapAuthoringDocument(renamed),
          ),
          _manifestChange(snapshot, manifest, projectRef),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: oldRef,
            path: '/',
            before: _mapSummary(source),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: newRef,
            path: '/',
            after: _mapSummary(renamed),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.move,
            resource: projectRef,
            path: '/maps/$oldId',
            before: _entrySummary(entry),
            after: _entrySummary(
              manifest.maps.singleWhere((candidate) => candidate.id == newId),
            ),
          ),
        ]),
      ),
      preview: {
        'operation': 'rename',
        'mapId': oldId,
        'newMapId': newId,
        'storageGuarantee': 'recoverable',
      },
      referenceImpact: _boundedImpact(impact),
    );
  }

  AuthoringMutationDraft duplicate(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'sourceMapId', 'targetMapId', 'name'},
    );
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final sourceId = parameters.string('sourceMapId');
    final entry = _requireMapEntry(snapshot.manifest, sourceId);
    final source = _requireMap(snapshot, sourceId);
    final requestedId = parameters.optionalString('targetMapId');
    final targetId = requestedId == null
        ? _nextCopyId(sourceId, snapshot.manifest.maps.map((map) => map.id))
        : _requireAvailableMapId(requestedId, snapshot.manifest);
    final name = _mapName(parameters.optionalString('name') ?? targetId);
    final path = _canonicalMapPath(targetId);
    _requireAvailablePath(snapshot.manifest, path);
    final duplicated = source.copyWith(id: targetId, name: name);
    final manifest = snapshot.manifest.copyWith(
      maps: [
        ...snapshot.manifest.maps,
        ProjectMapEntry(
          id: targetId,
          name: name,
          relativePath: path,
          groupId: entry.groupId,
          role: entry.role,
        ),
      ],
    );
    _validateProjected(manifest, [...snapshot.maps, duplicated]);
    final mapRef = AuthoringResourceRef(kind: 'map', id: targetId);
    final projectRef = _existingResource(snapshot, 'project', 'project');
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapRef,
            storageKey: path,
            beforeBytes: null,
            afterBytes: encodeMapAuthoringDocument(duplicated),
          ),
          _manifestChange(snapshot, manifest, projectRef),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: mapRef,
            path: '/',
            after: _mapSummary(duplicated),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: projectRef,
            path: '/maps/$targetId',
            after: _entrySummary(manifest.maps.last),
          ),
        ]),
      ),
      preview: {
        'operation': 'duplicate',
        'sourceMapId': sourceId,
        'mapId': targetId,
        'storageGuarantee': 'recoverable',
      },
    );
  }

  AuthoringMutationDraft delete(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'mapId'},
    );
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final mapId = parameters.string('mapId');
    final entry = _requireMapEntry(snapshot.manifest, mapId);
    final map = _requireMap(snapshot, mapId);
    final impact = _referenceImpact(snapshot, mapId);
    _requireNoDependents(impact);
    final manifest = snapshot.manifest.copyWith(
      maps: snapshot.manifest.maps
          .where((candidate) => candidate.id != mapId)
          .toList(growable: false),
    );
    _validateProjected(
      manifest,
      snapshot.maps
          .where((candidate) => candidate.id != mapId)
          .toList(growable: false),
    );
    final mapRef = _existingResource(snapshot, 'map', mapId);
    final projectRef = _existingResource(snapshot, 'project', 'project');
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapRef,
            storageKey: entry.relativePath,
            beforeBytes: snapshot.resourceBytes('map:$mapId'),
            afterBytes: null,
          ),
          _manifestChange(snapshot, manifest, projectRef),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: mapRef,
            path: '/',
            before: _mapSummary(map),
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: projectRef,
            path: '/maps/$mapId',
            before: _entrySummary(entry),
          ),
        ]),
      ),
      preview: {
        'operation': 'delete',
        'mapId': mapId,
        'storageGuarantee': 'recoverable',
      },
      referenceImpact: _boundedImpact(impact),
    );
  }

  AuthoringMutationDraft resize(AuthoringPlanningContext context) {
    final parameters = _Parameters(
      context.request.parameters,
      allowed: const {'mapId', 'width', 'height'},
    );
    final snapshot = context.snapshot;
    _requireManifestOwnership(snapshot.manifest);
    final mapId = parameters.string('mapId');
    final entry = _requireMapEntry(snapshot.manifest, mapId);
    final map = _requireMap(snapshot, mapId);
    final width = parameters.positiveInt('width');
    final height = parameters.positiveInt('height');
    final plan = planMapResize(
      map,
      width: width,
      height: height,
      project: snapshot.manifest,
      tileSizePx: GridSize(
        width: snapshot.manifest.settings.tileWidth,
        height: snapshot.manifest.settings.tileHeight,
      ),
    );
    if (plan.isNoOp) {
      throw _failure('map.no_change', 'The requested resize changes nothing.');
    }
    if (!plan.canApply) {
      throw _failure(
        'map.resize_impacts',
        'The resize would discard or invalidate authored map data.',
        details: {
          'mapId': mapId,
          'impactCount': plan.impacts.length,
          'impacts':
              plan.impacts.map(_resizeImpactJson).toList(growable: false),
          'borderDiagnostics': plan.borderDiagnostics.diagnostics
              .map(_borderDiagnosticJson)
              .toList(growable: false),
        },
        remediation: const [
          'Move or clear the impacted authored data before resizing.',
        ],
      );
    }
    final result = resizeMapDataWithBorderDiagnostics(
      map,
      width: width,
      height: height,
      tileSizePx: GridSize(
        width: snapshot.manifest.settings.tileWidth,
        height: snapshot.manifest.settings.tileHeight,
      ),
    );
    if (!result.canApply || result.map == null) {
      throw _failure(
        'map.resize_border_invalid',
        'Border diagnostics prevent this map resize.',
        details: {
          'diagnostics': result.diagnosticReport.diagnostics
              .map(_borderDiagnosticJson)
              .toList(growable: false),
        },
      );
    }
    final resized = result.map!;
    _validateProjected(snapshot.manifest, [resized]);
    final mapRef = _existingResource(snapshot, 'map', mapId);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapRef,
            storageKey: entry.relativePath,
            beforeBytes: snapshot.resourceBytes('map:$mapId'),
            afterBytes: encodeMapAuthoringDocument(resized),
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: mapRef,
            path: '/size',
            before: _sizeJson(map.size),
            after: _sizeJson(resized.size),
          ),
        ]),
      ),
      preview: {
        'operation': 'resize',
        'mapId': mapId,
        'before': _sizeJson(map.size),
        'after': _sizeJson(resized.size),
        'impactCount': 0,
        'borderDiagnostics': result.diagnosticReport.diagnostics
            .map(_borderDiagnosticJson)
            .toList(growable: false),
      },
    );
  }
}

/// Editor-compatible canonical bytes for one complete map document.
List<int> encodeMapAuthoringDocument(MapData map) => utf8.encode(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );

List<int> _encodeManifest(
  ProjectSnapshot snapshot,
  ProjectManifest manifest,
) {
  late final Map<String, Object?> original;
  try {
    final decoded = jsonDecode(utf8.decode(snapshot.resourceBytes('project')));
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      throw const FormatException();
    }
    original = Map<String, Object?>.from(decoded);
  } on Object {
    throw _failure(
      'project.manifest_invalid',
      'The original project manifest cannot be preserved safely.',
    );
  }
  final next = Map<String, Object?>.from(original)
    ..addAll(Map<String, Object?>.from(manifest.toJson()));
  return utf8.encode(const JsonEncoder.withIndent('  ').convert(next));
}

AuthoringResourceChange _manifestChange(
  ProjectSnapshot snapshot,
  ProjectManifest manifest,
  AuthoringResourceRef resource,
) {
  return AuthoringResourceChange(
    resource: resource,
    storageKey: 'project.json',
    beforeBytes: snapshot.resourceBytes('project'),
    afterBytes: _encodeManifest(snapshot, manifest),
  );
}

AuthoringResourceRef _existingResource(
  ProjectSnapshot snapshot,
  String kind,
  String id,
) {
  final identity = kind == 'project' ? 'project' : '$kind:$id';
  final revision = snapshot.resourceFingerprints[identity];
  if (revision == null) {
    throw _failure(
      'map.resource_preimage_missing',
      'A required resource revision is unavailable.',
      details: {'kind': kind, 'id': id},
    );
  }
  return AuthoringResourceRef(kind: kind, id: id, revision: revision);
}

void _validateProjected(ProjectManifest manifest, Iterable<MapData> maps) {
  try {
    ProjectValidator.validate(manifest);
    for (final map in maps) {
      MapValidator.validate(map, projectDialogueContext: manifest);
    }
  } on Object catch (error) {
    throw _failure(
      'map.projected_state_invalid',
      'The lifecycle operation would produce invalid PokeMap data.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

ProjectMapEntry _requireMapEntry(ProjectManifest manifest, String mapId) {
  for (final entry in manifest.maps) {
    if (entry.id == mapId) return entry;
  }
  throw _failure(
    'map.not_found',
    'The requested map does not exist.',
    details: {'mapId': mapId},
  );
}

MapData _requireMap(ProjectSnapshot snapshot, String mapId) {
  final map = snapshot.mapById(mapId);
  if (map == null) {
    throw _failure(
      'map.document_missing',
      'The requested map document is unavailable.',
      details: {'mapId': mapId},
    );
  }
  return map;
}

String _requireAvailableMapId(
  String value,
  ProjectManifest manifest, {
  String? excludingId,
}) {
  final id = _requireCanonicalMapId(value);
  for (final entry in manifest.maps) {
    if (entry.id == excludingId) continue;
    if (entry.id.toLowerCase() == id.toLowerCase()) {
      throw _failure(
        'map.id_conflict',
        'A map already owns the requested identity.',
        details: {'mapId': id},
      );
    }
  }
  return id;
}

String _requireCanonicalMapId(String value) {
  if (value.length > 64 ||
      !RegExp(r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$').hasMatch(value) ||
      _windowsReservedMapIds.contains(value.toLowerCase())) {
    throw _failure(
      'map.id_invalid',
      'Map IDs must be portable lowercase filename-safe identifiers.',
      details: {'mapId': value},
    );
  }
  return value;
}

void _requireManifestOwnership(
  ProjectManifest manifest, {
  String? allowedLegacyId,
}) {
  final ids = <String>{};
  final paths = <String>{};
  for (final entry in manifest.maps) {
    if (!ids.add(entry.id.toLowerCase())) {
      throw _failure(
        'map.manifest_id_conflict',
        'Map manifest identities are ambiguous.',
      );
    }
    if (entry.id != allowedLegacyId) _requireCanonicalMapId(entry.id);
    late final String path;
    try {
      path = validateProjectRelativePath(entry.relativePath).join('/');
    } on Object {
      throw _failure(
        'map.manifest_path_invalid',
        'A map manifest path is unsafe.',
        details: {'mapId': entry.id},
      );
    }
    if (!paths.add(_pathKey(path))) {
      throw _failure(
        'map.manifest_path_conflict',
        'Multiple map entries own the same portable path.',
      );
    }
  }
}

void _requireAvailablePath(
  ProjectManifest manifest,
  String path, {
  String? excludingId,
}) {
  final key = _pathKey(path);
  for (final entry in manifest.maps) {
    if (entry.id == excludingId) continue;
    if (_pathKey(entry.relativePath) == key) {
      throw _failure(
        'map.path_conflict',
        'A map manifest entry already owns the target document path.',
      );
    }
  }
}

ProjectReferenceImpact _referenceImpact(
  ProjectSnapshot snapshot,
  String mapId, {
  String? newId,
}) {
  final target = ProjectReferenceKey(
    kind: NarrativeDependencyTargetKind.sourceMap.name,
    id: mapId,
    scope: 'map',
    parentId: mapId,
    sourceKind: 'map',
  );
  final analyzer = ProjectReferenceImpactAnalyzer(
    ProjectReferenceIndex.fromSnapshot(snapshot),
  );
  return newId == null
      ? analyzer.deletionImpact(target)
      : analyzer.renameImpact(target, newId: newId);
}

void _requireNoDependents(ProjectReferenceImpact impact) {
  if (impact.affectedEdges.isEmpty) return;
  throw _failure(
    'map.references_blocking',
    'The map is still referenced and cannot be renamed or deleted safely.',
    details: _boundedImpact(impact),
    remediation: const [
      'Remove or explicitly rewrite every incoming reference first.',
    ],
  );
}

Map<String, Object?> _boundedImpact(ProjectReferenceImpact impact) => {
      'kind': impact.kind.name,
      'target': impact.target.toJson(),
      if (impact.replacement != null)
        'replacement': impact.replacement!.toJson(),
      'dependentCount': impact.directDependents.length,
      'edgeCount': impact.affectedEdges.length,
      'runtimeBlocking': impact.runtimeBlocking,
      'dependents': impact.directDependents
          .take(32)
          .map((dependent) => dependent.toJson())
          .toList(growable: false),
      'edges': impact.affectedEdges
          .take(64)
          .map((edge) => edge.toJson())
          .toList(growable: false),
      'truncated': impact.directDependents.length > 32 ||
          impact.affectedEdges.length > 64,
    };

String? _pickDefaultTilesetId(ProjectManifest manifest, String? groupId) {
  if (manifest.tilesets.isEmpty) return null;
  final sorted = manifest.tilesets.toList()
    ..sort((left, right) {
      final order = left.sortOrder.compareTo(right.sortOrder);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  if (groupId != null) {
    final ancestors = <String>{};
    String? cursor = groupId;
    while (cursor != null && ancestors.add(cursor)) {
      cursor = manifest.groups
          .where((group) => group.id == cursor)
          .firstOrNull
          ?.parentGroupId;
    }
    final grouped = sorted.where(
      (tileset) =>
          tileset.scope == TilesetScope.group &&
          tileset.groupId != null &&
          ancestors.contains(tileset.groupId),
    );
    if (grouped.isNotEmpty) return grouped.first.id;
  }
  final world = sorted.where((tileset) => tileset.isWorldTileset);
  if (world.isNotEmpty) return world.first.id;
  final global =
      sorted.where((tileset) => tileset.scope == TilesetScope.global);
  return global.isNotEmpty ? global.first.id : sorted.first.id;
}

String _requireTileset(ProjectManifest manifest, String id) {
  if (!manifest.tilesets.any((tileset) => tileset.id == id)) {
    throw _failure(
      'map.tileset_missing',
      'The requested tileset does not exist.',
      details: {'tilesetId': id},
    );
  }
  return id;
}

String _nextCopyId(String sourceId, Iterable<String> existingIds) {
  _requireCanonicalMapId(sourceId);
  final occupied = existingIds.map((id) => id.toLowerCase()).toSet();
  for (var copy = 0; copy < 100000; copy++) {
    final suffix = copy == 0 ? '_copy' : '_copy_$copy';
    final bounded = sourceId.substring(
      0,
      sourceId.length.clamp(1, 64 - suffix.length),
    );
    final candidate = '$bounded$suffix';
    if (!occupied.contains(candidate.toLowerCase())) return candidate;
  }
  throw _failure(
    'map.copy_id_unavailable',
    'No portable copy identity could be allocated.',
  );
}

MapRole _mapRole(String value) {
  for (final role in MapRole.values) {
    if (role.name == value) return role;
  }
  throw _failure(
    'map.role_invalid',
    'The requested map role is unsupported.',
    details: {'role': value},
  );
}

String _mapName(String value) {
  if (value.trim() != value || value.isEmpty || value.length > 160) {
    throw _failure(
      'map.name_invalid',
      'Map names must be nonblank, trimmed, and at most 160 characters.',
    );
  }
  return value;
}

Map<String, Object?> _mapSummary(MapData map) => {
      'id': map.id,
      'name': map.name,
      'size': _sizeJson(map.size),
      'layerCount': map.layers.length,
      'entityCount': map.entities.length,
      'warpCount': map.warps.length,
    };

Map<String, Object?> _entrySummary(ProjectMapEntry entry) => {
      'id': entry.id,
      'name': entry.name,
      if (entry.groupId != null) 'groupId': entry.groupId,
      'role': entry.role.name,
      'sortOrder': entry.sortOrder,
    };

Map<String, Object?> _sizeJson(GridSize size) => {
      'width': size.width,
      'height': size.height,
    };

Map<String, Object?> _resizeImpactJson(MapResizeImpact impact) => {
      'kind': impact.kind.name,
      'reason': impact.reason.name,
      'subjectId': impact.subjectId,
      'subjectLabel': impact.subjectLabel,
      if (impact.layerId != null) 'layerId': impact.layerId,
      'affectedCount': impact.affectedCount,
      'positions': impact.positions
          .map((position) => {'x': position.x, 'y': position.y})
          .toList(growable: false),
      'relatedIds': impact.relatedIds,
      if (impact.diagnosticCode != null)
        'diagnosticCode': impact.diagnosticCode,
    };

Map<String, Object?> _borderDiagnosticJson(BorderDiagnostic diagnostic) => {
      'code': diagnostic.code,
      'severity': diagnostic.severity.name,
      'phase': diagnostic.phase.name,
      'scope': diagnostic.scope.name,
      if (diagnostic.blueprintId != null) 'blueprintId': diagnostic.blueprintId,
      if (diagnostic.featureId != null) 'featureId': diagnostic.featureId,
      if (diagnostic.cell != null)
        'cell': {'x': diagnostic.cell!.x, 'y': diagnostic.cell!.y},
      'parameters': diagnostic.parameters,
      'suggestedAction': diagnostic.suggestedAction,
    };

void _requireChanged(List<int> before, List<int> after) {
  if (before.length != after.length) return;
  for (var index = 0; index < before.length; index++) {
    if (before[index] != after[index]) return;
  }
  throw _failure('map.no_change', 'The supplied map changes nothing.');
}

String _canonicalMapPath(String mapId) => 'maps/$mapId.json';

String _pathKey(String path) {
  try {
    return validateProjectRelativePath(path).join('/').toLowerCase();
  } on Object {
    throw _failure('map.path_invalid', 'A map path is unsafe.');
  }
}

MapAuthoringException _failure(
  String code,
  String message, {
  Map<String, Object?> details = const {},
  Iterable<String> remediation = const [],
}) {
  return MapAuthoringException(
    code: code,
    message: message,
    details: details,
    remediation: remediation,
  );
}

final class _Parameters {
  _Parameters(Map<String, Object?> values, {required Set<String> allowed})
      : _values = values {
    final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw _failure(
        'map.request_invalid',
        'The map action contains unsupported parameters.',
        details: {'unknownParameters': unknown},
      );
    }
  }

  final Map<String, Object?> _values;

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim() != value || value.isEmpty) {
      throw _invalid(key, 'a nonblank trimmed string');
    }
    return value;
  }

  String? optionalString(String key) {
    final value = _values[key];
    return value == null ? null : string(key);
  }

  int positiveInt(String key) {
    final value = _values[key];
    if (value is! int || value <= 0) throw _invalid(key, 'a positive integer');
    return value;
  }

  Map<String, Object?> object(String key) {
    final value = _values[key];
    if (value is! Map || value.keys.any((candidate) => candidate is! String)) {
      throw _invalid(key, 'a JSON object');
    }
    return Map<String, Object?>.from(value);
  }

  MapAuthoringException _invalid(String key, String expected) => _failure(
        'map.request_invalid',
        'Parameter "$key" must be $expected.',
        details: {'parameter': key, 'expected': expected},
      );
}

const Set<String> _windowsReservedMapIds = {
  'con',
  'prn',
  'aux',
  'nul',
  'com1',
  'com2',
  'com3',
  'com4',
  'com5',
  'com6',
  'com7',
  'com8',
  'com9',
  'lpt1',
  'lpt2',
  'lpt3',
  'lpt4',
  'lpt5',
  'lpt6',
  'lpt7',
  'lpt8',
  'lpt9',
};
~~~~~~~~

## `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`

~~~~~~~~dart
import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_lifecycle_actions.dart';
import 'map_lifecycle_adapter.dart';

typedef MapMutationDraftBuilder = AuthoringMutationDraft Function(
  AuthoringPlanningContext context,
);

final class MapMutationActionRegistration {
  const MapMutationActionRegistration({
    required this.descriptor,
    required this.build,
  });

  final AuthoringActionDescriptor descriptor;
  final MapMutationDraftBuilder build;
}

/// Deterministic action-to-domain-handler registry used by direct and JSONL APIs.
final class MapMutationDispatcher {
  MapMutationDispatcher(Iterable<MapMutationActionRegistration> registrations)
      : _registrations = _validatedRegistrations(registrations);

  factory MapMutationDispatcher.canonical() {
    const lifecycle = MapLifecycleActions();
    return MapMutationDispatcher([
      for (final descriptor in MapLifecycleActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: lifecycle.build,
        ),
    ]);
  }

  final Map<String, MapMutationActionRegistration> _registrations;

  List<AuthoringActionDescriptor> get descriptors => List.unmodifiable(
        _registrations.values.map((registration) => registration.descriptor),
      );

  AuthoringActionDescriptor descriptor(String actionId) =>
      _registration(actionId).descriptor;

  AuthoringMutationDraft build(AuthoringPlanningContext context) =>
      _registration(context.request.actionId).build(context);

  MapMutationActionRegistration _registration(String actionId) {
    final registration = _registrations[actionId];
    if (registration == null) {
      throw MapAuthoringException(
        code: 'map.action_unsupported',
        message: 'The requested map authoring action is unsupported.',
        details: {'actionId': actionId},
      );
    }
    return registration;
  }
}

Map<String, MapMutationActionRegistration> _validatedRegistrations(
  Iterable<MapMutationActionRegistration> values,
) {
  final registrations = <String, MapMutationActionRegistration>{};
  for (final registration in values) {
    final previous = registrations[registration.descriptor.id];
    if (previous != null) {
      throw ArgumentError.value(
        registration.descriptor.id,
        'registrations',
        'map mutation action IDs must be unique',
      );
    }
    registrations[registration.descriptor.id] = registration;
  }
  final ordered = registrations.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Map.unmodifiable(Map.fromEntries(ordered));
}
~~~~~~~~

## `packages/map_authoring/test/domains/maps/map_lifecycle_contract_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapLifecycleActions', () {
    test('advertises the complete canonical lifecycle mutation set', () {
      expect(
        MapLifecycleActions.descriptors.map((action) => action.id),
        [
          'map.create',
          'map.delete_apply',
          'map.duplicate',
          'map.rename',
          'map.resize_apply',
          'map.save',
        ],
      );
      for (final descriptor in MapLifecycleActions.descriptors) {
        expect(descriptor.guarantees, contains(AuthoringGuarantee.dryRun));
        expect(
          descriptor.guarantees,
          contains(AuthoringGuarantee.revisionChecked),
        );
        expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      }
    });

    test('creates an editor-compatible map and manifest in one draft', () {
      final snapshot = _snapshot();
      final request = _request(
        snapshot,
        actionId: 'map.create',
        parameters: const {
          'mapId': 'route_01',
          'name': 'Route 01',
          'width': 4,
          'height': 3,
          'role': 'exterior',
        },
      );

      final draft = const MapLifecycleActions().build(
        _context(snapshot, request),
      );

      expect(
        draft.changeSet.changes.map((change) => change.resource.toJson()),
        [
          {'kind': 'map', 'id': 'route_01'},
          {
            'kind': 'project',
            'id': 'project',
            'revision': snapshot.resourceFingerprints['project'],
          },
        ],
      );
      final mapChange = draft.changeSet.changes.first;
      final created = MapData.fromJson(
        jsonDecode(utf8.decode(mapChange.afterBytes!)) as Map<String, dynamic>,
      );
      expect(created.id, 'route_01');
      expect(created.name, 'Route 01');
      expect(created.size, const GridSize(width: 4, height: 3));
      expect(
        created.layers.map((layer) => layer.id),
        ['l_base', 'l_terrain', 'l_collisions'],
      );
      expect((created.layers[0] as TileLayer).tiles, hasLength(12));
      expect((created.layers[1] as TerrainLayer).terrains, hasLength(12));
      expect(
        (created.layers[2] as CollisionLayer).collisions,
        hasLength(12),
      );
      expect(
        utf8.decode(mapChange.afterBytes!),
        const JsonEncoder.withIndent('  ').convert(created.toJson()),
      );
      expect(draft.preview, containsPair('mapId', 'route_01'));
      expect(draft.preview, containsPair('operation', 'create'));
    });

    test('saves a validated full map against its exact disk pre-image', () {
      final original = _map('town', width: 3, height: 2);
      final snapshot = _snapshot(maps: [original]);
      final updated = original.copyWith(name: 'Town Updated');
      final request = _request(
        snapshot,
        actionId: 'map.save',
        parameters: {'map': updated.toJson()},
      );

      final draft = const MapLifecycleActions().build(
        _context(snapshot, request),
      );

      expect(draft.changeSet.changes, hasLength(1));
      final change = draft.changeSet.changes.single;
      expect(change.storageKey, 'maps/town.json');
      expect(change.beforeBytes, snapshot.resourceBytes('map:town'));
      expect(
        MapData.fromJson(
          jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
        ).name,
        'Town Updated',
      );
    });

    test('duplicates a map without changing the source document', () {
      final source = _map('town', width: 2, height: 2);
      final snapshot = _snapshot(maps: [source]);
      final request = _request(
        snapshot,
        actionId: 'map.duplicate',
        parameters: const {'sourceMapId': 'town'},
      );

      final draft = const MapLifecycleActions().build(
        _context(snapshot, request),
      );

      final mapChange = draft.changeSet.changes
          .singleWhere((change) => change.resource.kind == 'map');
      expect(mapChange.resource.id, 'town_copy');
      expect(mapChange.beforeBytes, isNull);
      expect(mapChange.storageKey, 'maps/town_copy.json');
      expect(
        MapData.fromJson(
          jsonDecode(utf8.decode(mapChange.afterBytes!))
              as Map<String, dynamic>,
        ).id,
        'town_copy',
      );
    });

    test('refuses rename and delete while another map references the target',
        () {
      final target = _map('target');
      final owner = _map('owner').copyWith(
        warps: const [
          MapWarp(
            id: 'warp_to_target',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'target',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final snapshot = _snapshot(maps: [owner, target]);

      for (final request in [
        _request(
          snapshot,
          actionId: 'map.rename',
          parameters: const {'mapId': 'target', 'newMapId': 'target_new'},
        ),
        _request(
          snapshot,
          actionId: 'map.delete_apply',
          parameters: const {'mapId': 'target'},
        ),
      ]) {
        expect(
          () => const MapLifecycleActions().build(
            _context(snapshot, request),
          ),
          throwsA(
            isA<MapAuthoringException>()
                .having(
                  (error) => error.code,
                  'code',
                  'map.references_blocking',
                )
                .having(
                  (error) => error.details['dependentCount'],
                  'dependentCount',
                  1,
                ),
          ),
        );
      }
    });

    test('previews resize impacts and refuses lossy shrinking', () {
      final original = _map('field', width: 3, height: 2).copyWith(
        layers: [
          MapLayer.tile(
            id: 'l_base',
            name: 'Base',
            tiles: const [0, 0, 7, 0, 0, 0],
          ),
          MapLayer.terrain(
            id: 'l_terrain',
            name: 'Terrain',
            terrains: List<TerrainType>.filled(6, TerrainType.none),
          ),
          MapLayer.collision(
            id: 'l_collisions',
            name: 'Collisions',
            collisions: List<bool>.filled(6, false),
          ),
        ],
      );
      final snapshot = _snapshot(maps: [original]);
      final request = _request(
        snapshot,
        actionId: 'map.resize_apply',
        parameters: const {'mapId': 'field', 'width': 2, 'height': 2},
      );

      expect(
        () => const MapLifecycleActions().build(
          _context(snapshot, request),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'map.resize_impacts',
              )
              .having(
                (error) => error.details['impactCount'],
                'impactCount',
                1,
              ),
        ),
      );
    });

    test('renames a reference-free map with one recoverable three-file set',
        () {
      final original = _map('legacy_name');
      final snapshot = _snapshot(maps: [original]);
      final request = _request(
        snapshot,
        actionId: 'map.rename',
        parameters: const {
          'mapId': 'legacy_name',
          'newMapId': 'better_name',
          'name': 'Better Name',
        },
      );

      final draft = const MapLifecycleActions().build(
        _context(snapshot, request),
      );

      expect(draft.changeSet.changes, hasLength(3));
      expect(
        draft.changeSet.changes.map((change) => change.storageKey),
        ['maps/better_name.json', 'maps/legacy_name.json', 'project.json'],
      );
      expect(
        draft.changeSet.changes
            .singleWhere(
                (change) => change.storageKey == 'maps/legacy_name.json')
            .afterBytes,
        isNull,
      );
      expect(draft.referenceImpact['dependentCount'], 0);
    });
  });
}

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot,
  AuthoringRequest request,
) {
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: request,
    planId: 'plan_test',
    seed: 42,
  );
}

AuthoringRequest _request(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) {
  return AuthoringRequest(
    requestId: 'request_test',
    actionId: actionId,
    actionVersion: 1,
    workspaceHandle: 'ws_test',
    parameters: parameters,
    expectedRevision: snapshot.revision,
    idempotencyKey: 'idem_test',
    dryRun: true,
  );
}

ProjectSnapshot _snapshot({List<MapData> maps = const []}) {
  final entries = [
    for (final map in maps)
      ProjectMapEntry(
        id: map.id,
        name: map.name,
        relativePath: 'maps/${map.id}.json',
      ),
  ];
  final manifest = ProjectManifest(
    name: 'Lifecycle Fixture',
    version: ProjectVersion.v3,
    maps: entries,
    tilesets: const [],
  );
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = {
    for (final map in maps) 'map:${map.id}': _encode(map.toJson()),
  };
  final revision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: manifestBytes,
    ),
    for (final map in maps)
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/${map.id}.json',
        bytes: mapBytes['map:${map.id}']!,
      ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_test'),
    revision: revision,
    manifest: manifest,
    maps: maps,
    resourceFingerprints: {
      'project': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: manifestBytes,
        ),
      ]),
      for (final map in maps)
        'map:${map.id}': computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
            relativePath: 'maps/${map.id}.json',
            bytes: mapBytes['map:${map.id}']!,
          ),
        ]),
    },
    resourceBytes: {'project': manifestBytes, ...mapBytes},
  );
}

MapData _map(String id, {int width = 2, int height = 2}) {
  final count = width * height;
  return MapData(
    id: id,
    name: id,
    size: GridSize(width: width, height: height),
    version: ProjectVersion.v3,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.terrain(
        id: 'l_terrain',
        name: 'Terrain',
        terrains: List<TerrainType>.filled(count, TerrainType.none),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Collisions',
        collisions: List<bool>.filled(count, false),
      ),
    ],
  );
}

List<int> _encode(Object? value) => utf8.encode(
      const JsonEncoder.withIndent('  ').convert(value),
    );
~~~~~~~~

## `packages/map_authoring/test/domains/maps/map_lifecycle_transaction_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalMapAuthoringMutationApi lifecycle', () {
    test('plans, applies, records, and undoes map creation', () async {
      final setup = await _Setup.create();
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'route_01',
          'name': 'Route 01',
          'width': 3,
          'height': 2,
        },
      );

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      expect(planned['plan'], isA<Map<String, Object?>>());
      expect(
        (planned['receipt']! as Map<String, Object?>)['status'],
        'planned',
      );
      expect(
        await File('${setup.root.path}/maps/route_01.json').exists(),
        isFalse,
      );

      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_create_route_01',
      );
      final receipt = applied['receipt']! as Map<String, Object?>;
      expect(receipt['status'], 'applied');
      expect(applied['snapshotRevision'], startsWith('sha256:'));
      final mapFile = File('${setup.root.path}/maps/route_01.json');
      expect(await mapFile.exists(), isTrue);
      expect(
        MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
        ).name,
        'Route 01',
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps.single.id,
        'route_01',
      );

      final undone = await setup.mutations.undo(
        setup.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem_undo_route_01',
      );
      expect(
        (undone['receipt']! as Map<String, Object?>)['actionId'],
        'history.undo',
      );
      expect(await mapFile.exists(), isFalse);
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps,
        isEmpty,
      );
    });

    test('requires one-use confirmation for destructive deletion', () async {
      final setup = await _Setup.create(
        maps: [_map('town')],
      );
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.delete_apply',
        parameters: const {'mapId': 'town'},
      );
      final planned = await setup.mutations.plan(setup.projectHandle, request);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_delete_town_denied',
        ),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'confirmation.required',
          ),
        ),
      );
      final confirmation = await setup.mutations.confirm(
        setup.projectHandle,
        planId: planned['planId']! as String,
      );
      final token = confirmation['confirmationToken']! as String;
      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_delete_town',
        confirmationToken: token,
      );
      expect(
        (applied['receipt']! as Map<String, Object?>)['status'],
        'applied',
      );
      expect(await File('${setup.root.path}/maps/town.json').exists(), isFalse);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_delete_town_reuse',
          confirmationToken: token,
        ),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'confirmation.used',
          ),
        ),
      );
    });

    test('recovers manifest plus map after a crash between promotions',
        () async {
      var crash = true;
      final setup = await _Setup.create(
        faultInjector: (context) {
          if (crash &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'recovered_map',
          'width': 2,
          'height': 2,
        },
      );
      final planned = await setup.mutations.plan(setup.projectHandle, request);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_recovered_map',
        ),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      expect(
        await File('${setup.root.path}/maps/recovered_map.json').exists(),
        isTrue,
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps,
        isEmpty,
      );

      crash = false;
      final recovered = await setup.mutations.recover(
        setup.projectHandle,
        operationId: 'operation_recovered_map',
      );
      expect(
        (recovered['receipt']! as Map<String, Object?>)['status'],
        'recovered',
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps.single.id,
        'recovered_map',
      );
    });
  });
}

final class _Setup {
  _Setup._({
    required this.root,
    required this.mutations,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.snapshots,
  });

  static Future<_Setup> create({
    List<MapData> maps = const [],
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final root = await Directory.systemTemp.createTemp('map-lifecycle-');
    final manifest = ProjectManifest(
      name: 'Lifecycle Transaction Fixture',
      version: ProjectVersion.v3,
      maps: [
        for (final map in maps)
          ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
      ],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    if (maps.isNotEmpty) {
      await Directory('${root.path}/maps').create();
      for (final map in maps) {
        await File('${root.path}/maps/${map.id}.json').writeAsBytes(
          encodeMapAuthoringDocument(map),
          flush: true,
        );
      }
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '${prefix}fixture',
    );
    final open = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await open.openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      faultInjector: faultInjector,
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _Setup._(
      root: root,
      mutations: mutations,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      snapshots: snapshots,
    );
  }

  final Directory root;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;

  Future<AuthoringRequest> requestAsync({
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    final snapshot = await snapshots.load(projectHandle);
    return AuthoringRequest(
      requestId: 'request_${actionId.replaceAll('.', '_')}',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: workspaceHandle.value,
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_${actionId.replaceAll('.', '_')}',
      dryRun: false,
    );
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(workspaceHandle);
    if (await root.exists()) await root.delete(recursive: true);
  }
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tiles: List<int>.filled(4, 0),
        ),
        MapLayer.terrain(
          id: 'l_terrain',
          name: 'Terrain',
          terrains: List<TerrainType>.filled(4, TerrainType.none),
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: List<bool>.filled(4, false),
        ),
      ],
    );
~~~~~~~~

## `packages/map_authoring/test/tooling/jsonl_mutation_worker_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL exposes lifecycle plan and apply without leaking roots',
      () async {
    final root = await Directory.systemTemp.createTemp('jsonl-mutation-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final manifest = ProjectManifest(
      name: 'JSONL Mutation Fixture',
      version: ProjectVersion.v3,
      maps: const [],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    final worker = JsonlWorker(api: readApi, mutations: mutations);

    final described = await _request(worker, 'describe');
    expect(described.status, AuthoringResultStatus.success);
    expect(described.data['readOnly'], isFalse);
    expect(
      (described.data['commands']! as List)
          .cast<Map<String, Object?>>()
          .map((command) => command['id']),
      [
        'apply',
        'close',
        'confirm',
        'describe',
        'open',
        'plan',
        'query',
        'recover',
        'undo',
        'validate'
      ],
    );

    final opened = await _request(
      worker,
      'open',
      args: {'projectRoot': root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    expect(opened.data['readOnly'], isFalse);
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final request = AuthoringRequest(
      requestId: 'create-jsonl-map',
      actionId: 'map.create',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const {
        'mapId': 'jsonl_map',
        'width': 2,
        'height': 2,
      },
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_jsonl_map',
      dryRun: false,
    );
    final planned = await _request(
      worker,
      'plan',
      args: {
        'projectHandle': projectHandle,
        'request': request.toJson(),
      },
    );
    expect(planned.status, AuthoringResultStatus.success);
    final applied = await _request(
      worker,
      'apply',
      args: {
        'projectHandle': projectHandle,
        'planId': planned.data['planId'],
        'operationId': 'operation_jsonl_map',
      },
    );
    expect(applied.status, AuthoringResultStatus.success);
    expect(
      (applied.data['receipt']! as Map<String, Object?>)['status'],
      'applied',
    );
    expect(await File('${root.path}/maps/jsonl_map.json').exists(), isTrue);

    final transcript = jsonEncode({
      'describe': described.toJson(),
      'open': opened.toJson(),
      'plan': planned.toJson(),
      'apply': applied.toJson(),
    });
    expect(transcript, isNot(contains(root.path)));
    expect(transcript, isNot(contains('/private/')));
  });
}

Future<AuthoringResult> _request(
  JsonlWorker worker,
  String command, {
  Map<String, Object?> args = const {},
}) async {
  final decoded = jsonDecode(
    await worker.processLine(
      jsonEncode({
        'id': 'request-$command',
        'command': command,
        'args': args,
      }),
    ),
  ) as Map<String, dynamic>;
  return AuthoringResult.fromJson(decoded);
}
~~~~~~~~
