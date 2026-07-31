import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('AuthoringUndoService', () {
    test('undo and redo are new secure CAS-checked idempotent transactions',
        () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();

      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-undo',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final undoReplay = await harness.undo.apply(undoPlan);
      expect(undoReplay.toJson(), undoReceipt.toJson());
      await harness.expectBeforeState();

      final redoPlan = await harness.undo.planRedo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-redo',
      );
      final redoReceipt = await harness.undo.apply(redoPlan);
      expect(redoReceipt.status, AuthoringReceiptStatus.applied);
      await harness.expectAfterState();

      final history = await harness.history.list(
        projectId: harness.projectId,
        limit: 10,
      );
      expect(
        history.entries.map((entry) => entry.kind),
        [
          AuthoringHistoryKind.redo,
          AuthoringHistoryKind.undo,
          AuthoringHistoryKind.mutation,
        ],
      );
      expect(history.entries[1].targetEntryId, original.receiptId);
      expect(history.entries[0].targetEntryId, original.receiptId);
    });

    test('refuses external changes and persists pruned-blob non-undoability',
        () async {
      final changed = await _HistoryHarness.create();
      addTearDown(changed.dispose);
      final original = await changed.applyOriginal();
      await File(
        _join(changed.base.projectDirectory.path, 'data', 'a.json'),
      ).writeAsString('{"external":true}');

      await expectLater(
        () => changed.undo.planUndo(
          actor: changed.actor,
          projectId: changed.projectId,
          entryId: original.receiptId,
          snapshot: changed.snapshot(original.afterRevision!),
          workspaceHandle: 'workspace:history',
          idempotencyKey: 'idem-history-conflict',
        ),
        _throwsHistory('history.resource_changed'),
      );

      final pruned = await _HistoryHarness.create();
      addTearDown(pruned.dispose);
      final prunedOriginal = await pruned.applyOriginal();
      await pruned.blobs.prune(retainIds: const {});
      final undoability = await pruned.undo.inspectUndoability(
        projectId: pruned.projectId,
        entryId: prunedOriginal.receiptId,
      );
      expect(undoability.undoable, isFalse);
      expect(undoability.reason, 'history.blob_missing');
      expect(
        (await pruned.history.get(
          projectId: pruned.projectId,
          entryId: prunedOriginal.receiptId,
        ))!
            .nonUndoableReason,
        'history.blob_missing',
      );
    });

    test('cannot apply an undo without project write permission', () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final readOnlyActor = AuthoringActor(actorId: harness.actor.actorId);
      final plan = await harness.undo.planUndo(
        actor: readOnlyActor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-denied',
      );

      await expectLater(
        () => harness.undo.apply(plan),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'authorization.permission_denied',
          ),
        ),
      );
      await harness.expectAfterState();
    });

    test('invalidates a redo when a branch appears after planning', () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-pre-redo',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final redoPlan = await harness.undo.planRedo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-racing-redo',
      );
      await harness.history.append(
        _divergentEntry(harness.projectId, 'redo'),
      );

      await expectLater(
        () => harness.undo.apply(redoPlan),
        _throwsHistory('history.redo_branch_diverged'),
      );
      await harness.expectBeforeState();
    });

    test('recovery also refuses a redo after a divergent branch', () async {
      var interruptRedo = false;
      final harness = await _HistoryHarness.create(
        faultInjector: (context) {
          if (interruptRedo &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterReservation) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-recovery-undo',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final redoPlan = await harness.undo.planRedo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-recovery-redo',
      );
      interruptRedo = true;
      await expectLater(
        () => harness.undo.apply(redoPlan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      await harness.history.append(
        _divergentEntry(harness.projectId, 'recovery'),
      );
      final recovery = AuthoringRecoveryService(
        gateway: harness.base.gateway,
        idempotency: harness.base.ledger,
        clock: () => harness.base.now,
        commitHook: harness.recorder,
      );

      await expectLater(
        () => recovery.resume(redoPlan.operationId),
        _throwsHistory('history.redo_branch_diverged'),
      );
      await harness.expectBeforeState();
    });

    test('recovery completes a redo while its expected head is unchanged',
        () async {
      var interruptRedo = false;
      final harness = await _HistoryHarness.create(
        faultInjector: (context) {
          if (interruptRedo &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterReservation) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-positive-recovery-undo',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final redoPlan = await harness.undo.planRedo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-positive-recovery-redo',
      );
      interruptRedo = true;
      await expectLater(
        () => harness.undo.apply(redoPlan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      final recovery = AuthoringRecoveryService(
        gateway: harness.base.gateway,
        idempotency: harness.base.ledger,
        clock: () => harness.base.now,
        commitHook: harness.recorder,
      );

      final receipt = await recovery.resume(redoPlan.operationId);
      expect(receipt.status, AuthoringReceiptStatus.recovered);
      await harness.expectAfterState();
      expect(
        (await harness.history.list(
          projectId: harness.projectId,
          limit: 1,
        ))
            .entries
            .single
            .kind,
        AuthoringHistoryKind.redo,
      );
    });
  });

  group('AuthoringRevisionRevertService', () {
    test('revert is forward-only, head-checked, and invalidates redo',
        () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();

      await expectLater(
        () => harness.revert.planRevert(
          actor: harness.actor,
          projectId: harness.projectId,
          targetEntryId: original.receiptId,
          expectedHeadEntryId: 'receipt-stale',
          snapshot: harness.snapshot(original.afterRevision!),
          workspaceHandle: 'workspace:history',
          idempotencyKey: 'idem-stale-revert',
        ),
        _throwsHistory('history.head_stale'),
      );

      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-before-revert',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final head = (await harness.history.list(
        projectId: harness.projectId,
        limit: 1,
      ))
          .entries
          .single;

      final revertPlan = await harness.revert.planRevert(
        actor: harness.actor,
        projectId: harness.projectId,
        targetEntryId: original.receiptId,
        expectedHeadEntryId: head.entryId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-revert',
      );
      await harness.revert.apply(revertPlan);
      await harness.expectAfterState();

      await expectLater(
        () => harness.undo.planRedo(
          actor: harness.actor,
          projectId: harness.projectId,
          entryId: original.receiptId,
          snapshot: harness.snapshot(revertPlan.plan.projectedRevision),
          workspaceHandle: 'workspace:history',
          idempotencyKey: 'idem-diverged-redo',
        ),
        _throwsHistory('history.redo_branch_diverged'),
      );
      expect(
        (await harness.history.list(
          projectId: harness.projectId,
          limit: 1,
        ))
            .entries
            .single
            .kind,
        AuthoringHistoryKind.revert,
      );
    });

    test('refuses a revert when the head changes after planning', () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-pre-racing-revert',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final head = (await harness.history.list(
        projectId: harness.projectId,
        limit: 1,
      ))
          .entries
          .single;
      final revertPlan = await harness.revert.planRevert(
        actor: harness.actor,
        projectId: harness.projectId,
        targetEntryId: original.receiptId,
        expectedHeadEntryId: head.entryId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-racing-revert',
      );
      await harness.history.append(
        _divergentEntry(harness.projectId, 'revert'),
      );

      await expectLater(
        () => harness.revert.apply(revertPlan),
        _throwsHistory('history.head_stale'),
      );
      await harness.expectBeforeState();
    });
  });
}

AuthoringHistoryEntry _divergentEntry(String projectId, String suffix) {
  final resource = AuthoringResourceRef(kind: 'fixture', id: 'branch-$suffix');
  final before = _fingerprint(suffix.codeUnitAt(0));
  final after = _fingerprint(suffix.codeUnitAt(0) + 1);
  final receipt = AuthoringReceipt(
    receiptId: 'receipt-divergent-$suffix',
    requestId: 'request-divergent-$suffix',
    actionId: 'fixture.branch',
    actionVersion: 1,
    status: AuthoringReceiptStatus.applied,
    beforeRevision: before,
    afterRevision: after,
    createdAtUtc: DateTime.utc(2026, 7, 31, 15).toIso8601String(),
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$.value',
        before: 0,
        after: 1,
      ),
    ]),
  );
  return AuthoringHistoryEntry(
    entryId: receipt.receiptId,
    projectId: projectId,
    actorId: 'actor-divergent',
    planId: 'plan-divergent-$suffix',
    operationId: 'operation-divergent-$suffix',
    kind: AuthoringHistoryKind.mutation,
    receipt: receipt,
    committedAt: DateTime.utc(2026, 7, 31, 15),
    changes: [
      AuthoringHistoryResourceChange(
        resource: resource,
        storageKey: 'data/branch-$suffix.json',
        beforeRevision: before,
        afterRevision: after,
        beforeBlobId: _fingerprint(suffix.codeUnitAt(0) + 2),
        afterBlobId: _fingerprint(suffix.codeUnitAt(0) + 3),
      ),
    ],
  );
}

String _fingerprint(int seed) =>
    'sha256:${seed.toRadixString(16).padLeft(64, '0').substring(0, 64)}';

final class _HistoryHarness {
  _HistoryHarness._({
    required this.base,
    required this.history,
    required this.blobs,
    required this.actor,
    required this.recorder,
    required this.executor,
    required this.undo,
    required this.revert,
  });

  static Future<_HistoryHarness> create({
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final base = await TransactionTestHarness.create();
    final history = await FileAuthoringHistoryStore.open(
      projectRoot: base.projectDirectory.path,
    );
    final blobs = await FileAuthoringContentBlobStore.open(
      projectRoot: base.projectDirectory.path,
    );
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    final transaction = JournaledAuthoringTransaction(
      plans: base.planStore,
      gateway: base.gateway,
      idempotency: base.ledger,
      clock: () => base.now,
      commitHook: recorder,
      faultInjector: faultInjector,
    );
    final confirmations = AuthoringConfirmationStore(clock: () => base.now);
    final policy = AuthoringAuthorizationPolicy(
      confirmations: confirmations,
      clock: () => base.now,
    );
    final audit = await FileAuthoringAuditLog.open(
      projectRoot: base.projectDirectory.path,
    );
    var auditId = 0;
    final executor = SecureAuthoringMutationExecutor(
      transaction: transaction,
      policy: policy,
      auditLog: audit,
      clock: () => base.now,
      auditIdFactory: () => 'audit-history-${auditId++}',
    );
    var token = 0;
    String tokenFactory(String prefix) => '$prefix${token++}';
    final planner = AuthoringActionPlanner(
      store: base.planStore,
      tokenFactory: tokenFactory,
      seedFactory: () => 9001,
    );
    final actor = AuthoringActor(
      actorId: base.scope.actorId,
      permissions: const [
        AuthoringPermissionScope.projectRead,
        AuthoringPermissionScope.projectWrite,
      ],
    );
    final undo = AuthoringUndoService(
      history: history,
      blobs: blobs,
      gateway: base.gateway,
      planner: planner,
      policy: policy,
      executor: executor,
      tokenFactory: tokenFactory,
    );
    final revert = AuthoringRevisionRevertService(
      history: history,
      blobs: blobs,
      gateway: base.gateway,
      planner: planner,
      policy: policy,
      executor: executor,
      tokenFactory: tokenFactory,
    );
    return _HistoryHarness._(
      base: base,
      history: history,
      blobs: blobs,
      actor: actor,
      recorder: recorder,
      executor: executor,
      undo: undo,
      revert: revert,
    );
  }

  final TransactionTestHarness base;
  final FileAuthoringHistoryStore history;
  final FileAuthoringContentBlobStore blobs;
  final AuthoringActor actor;
  final AuthoringHistoryRecorder recorder;
  final SecureAuthoringMutationExecutor executor;
  final AuthoringUndoService undo;
  final AuthoringRevisionRevertService revert;

  String get projectId => base.scope.projectId;

  Future<AuthoringReceipt> applyOriginal() {
    return executor.apply(
      actor: actor,
      projectId: projectId,
      action: _fixtureAction(),
      plan: base.plan,
      currentProjectRevision: base.currentProjectRevision,
      scope: base.scope,
      operationId: base.operationId,
    );
  }

  ProjectSnapshot snapshot(String revision) => ProjectSnapshot(
        projectHandle: const ProjectHandle('project-history'),
        revision: revision,
        manifest: ProjectManifest(
          name: 'History Fixture',
          maps: const [],
          tilesets: const [],
        ),
        maps: const [],
        resourceFingerprints: {'project': revision},
      );

  Future<void> expectBeforeState() async {
    expect(await base.readA(), TransactionTestHarness.beforeA);
    expect(await base.readB(), TransactionTestHarness.beforeB);
    expect(await base.readCreated(), isNull);
    expect(await base.readDeleted(), TransactionTestHarness.beforeDeleted);
  }

  Future<void> expectAfterState() async {
    expect(await base.readA(), TransactionTestHarness.afterA);
    expect(await base.readB(), TransactionTestHarness.afterB);
    expect(await base.readCreated(), TransactionTestHarness.afterCreated);
    expect(await base.readDeleted(), isNull);
  }

  Future<void> dispose() => base.dispose();
}

AuthoringActionDescriptor _fixtureAction() => AuthoringActionDescriptor(
      id: 'fixture.multiWrite',
      version: 1,
      summary: 'History fixture mutation',
      inputSchemaId: 'schema.fixture.input.v1',
      outputSchemaId: 'schema.fixture.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

Matcher _throwsHistory(String code) => throwsA(
      isA<AuthoringHistoryException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    );

String _join(String first, String second, String third) =>
    [first, second, third].join(Platform.pathSeparator);
