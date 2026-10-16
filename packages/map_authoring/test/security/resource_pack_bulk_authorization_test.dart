import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/src/security/resource_pack_bulk_capability.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:test/test.dart';

import '../transactions/bulk_transaction_checkpoint_test.dart'
    show
        BulkTransactionFixture,
        CountingBulkGateway,
        BulkMemoryIdempotencyStore;

void main() {
  AuthoringAuthorizationPolicy policy() => AuthoringAuthorizationPolicy(
      confirmations:
          AuthoringConfirmationStore(clock: () => BulkTransactionFixture.now),
      clock: () => BulkTransactionFixture.now);
  final actor = AuthoringActor(
      actorId: 'actor_bulk', permissions: AuthoringPermissionScope.values);
  AuthoringAuthorizationRequest request(BulkTransactionFixture fixture,
          {ResourcePackBulkCapability? capability,
          String? projectId,
          int? requestBytes,
          String? diffFingerprint}) =>
      AuthoringAuthorizationRequest(
          actor: actor,
          projectId: projectId ?? fixture.scope.projectId,
          operation: AuthoringSecurityOperation.apply,
          actionId: fixture.plan.request.actionId,
          actionVersion: 1,
          riskLevel: AuthoringRiskLevel.medium,
          requestBytes: requestBytes ?? fixture.plan.authorizationRequestBytes,
          touchedResources: fixture.plan.changeSet.changes.length,
          planId: fixture.plan.planId,
          diffFingerprint: diffFingerprint ??
              bulkDiffFingerprint(fixture.plan.changeSet.diff),
          operationId: fixture.operationId,
          bulkCapability: capability);

  test('only a bound internal capability grants a bulk touched budget', () {
    final fixture = BulkTransactionFixture(501);
    addTearDown(fixture.plans.dispose);
    expect(() => policy().authorize(request(fixture)),
        throwsA(isA<AuthoringAuthorizationException>()));
    expect(
        () =>
            policy().authorize(request(fixture, capability: fixture.certify())),
        returnsNormally);
  });

  for (final action in [
    'asset.import',
    'history.undo',
    'history.redo',
    'history.revert'
  ]) {
    test('$action and forged client extensions retain ordinary budgets', () {
      final fixture =
          BulkTransactionFixture(501, actionId: action, extensions: const {
        'bulk': true,
        'clientActionId': 'resource_pack.import',
        'limits': {'maxTouchedResources': 40002},
        'bulkCapability': {'certified': true},
      });
      addTearDown(fixture.plans.dispose);
      expect(() => policy().authorize(request(fixture)),
          throwsA(isA<AuthoringAuthorizationException>()));
      expect(fixture.certify, throwsArgumentError);
    });
  }

  test('bulk capability remains bound to project and full diff', () {
    final fixture = BulkTransactionFixture(501);
    addTearDown(fixture.plans.dispose);
    final capability = fixture.certify();
    expect(
        () => policy().authorize(request(fixture,
            capability: capability, projectId: 'project_other')),
        throwsA(isA<AuthoringAuthorizationException>()));
    expect(
        () => policy().authorize(request(fixture,
            capability: capability,
            diffFingerprint: BulkTransactionFixture.revision)),
        throwsA(isA<AuthoringAuthorizationException>()));
  });

  test('bulk keeps the 1 MiB request limit and 60 operations per minute', () {
    final fixture = BulkTransactionFixture(501);
    addTearDown(fixture.plans.dispose);
    final capability = fixture.certify();
    final bound = request(fixture, capability: capability);
    expect(
        () => policy().authorize(request(fixture,
            capability: capability, requestBytes: 1024 * 1024 + 1)),
        throwsA(isA<AuthoringAuthorizationException>()
            .having((e) => e.code, 'code', 'authorization.request_too_large')));
    final metered = policy();
    for (var index = 0; index < 60; index++) {
      metered.authorize(bound);
    }
    expect(
        () => metered.authorize(bound),
        throwsA(isA<AuthoringAuthorizationException>()
            .having((e) => e.code, 'code', 'authorization.rate_limited')));
  });

  test(
      'certified 501 import undo redo reconstructs and recovers from canonical history',
      () async {
    final directory = await Directory.systemTemp.createTemp('bulk-history-');
    addTearDown(() => directory.delete(recursive: true));
    final fixture = BulkTransactionFixture(501);
    addTearDown(fixture.plans.dispose);
    fixture.certify();
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: directory.path);
    final history =
        await FileAuthoringHistoryStore.open(projectRoot: directory.path);
    final blobs =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    final ledgerPath = '${directory.path}/.pokemap/authoring/bulk-ledger.jsonl';
    AuthoringIdempotencyLedger ledger() => AuthoringIdempotencyLedger(
        store: FileIdempotencyStore(filePath: ledgerPath),
        clock: () => BulkTransactionFixture.now);
    final audit = await FileAuthoringAuditLog.open(projectRoot: directory.path);
    var auditSerial = 0;
    var tokenSerial = 0;
    String token(String prefix) => '$prefix${tokenSerial++}';
    final planner = AuthoringActionPlanner(
        store: fixture.plans, tokenFactory: token, seedFactory: () => 1);
    var crashRedo = false;
    final executor = SecureAuthoringMutationExecutor(
        transaction: JournaledAuthoringTransaction(
            plans: fixture.plans,
            gateway: gateway,
            idempotency: ledger(),
            clock: () => BulkTransactionFixture.now,
            commitHook: recorder,
            faultInjector: (context) {
              if (crashRedo &&
                  context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterResourcePromoted &&
                  context.promotionIndex == 250) {
                throw const AuthoringTransactionSimulatedCrash();
              }
            }),
        policy: policy(),
        auditLog: audit,
        clock: () => BulkTransactionFixture.now,
        auditIdFactory: () => 'audit_${auditSerial++}');
    final importAction = AuthoringActionDescriptor(
        id: 'resource_pack.import',
        version: 1,
        summary: 'Import resource pack',
        inputSchemaId: 'schema.resource_pack.import.input.v1',
        outputSchemaId: 'schema.authoringReceipt.v1',
        riskLevel: AuthoringRiskLevel.medium,
        requiredPermissions: const [
          AuthoringPermission.projectWrite,
          AuthoringPermission.importRun
        ]);
    final imported = await executor.apply(
        actor: actor,
        projectId: fixture.scope.projectId,
        action: importAction,
        plan: fixture.plan,
        currentProjectRevision: fixture.plan.baseRevision,
        scope: fixture.scope,
        operationId: fixture.operationId);
    ProjectSnapshot snapshot(String revision) => ProjectSnapshot(
        projectHandle: const ProjectHandle('project_bulk'),
        revision: revision,
        manifest: ProjectManifest(
            name: 'Bulk history', maps: const [], tilesets: const []),
        maps: const [],
        resourceFingerprints: {'project': revision});
    final undo = AuthoringUndoService(
        history: history,
        blobs: blobs,
        gateway: gateway,
        planner: planner,
        policy: policy(),
        executor: executor,
        tokenFactory: token);
    final undoPlan = await undo.planUndo(
        actor: actor,
        projectId: fixture.scope.projectId,
        entryId: imported.receiptId,
        snapshot: snapshot(imported.afterRevision!),
        workspaceHandle: fixture.plan.request.workspaceHandle,
        idempotencyKey: 'key_undo');
    expect(undoPlan.plan.bulkCapability!.inventory.length, 501);
    final undone = await undo.apply(undoPlan);
    expect(await gateway.readResourceRevision('resources/000000.json'), isNull);
    final redoPlan = await undo.planRedo(
        actor: actor,
        projectId: fixture.scope.projectId,
        entryId: imported.receiptId,
        snapshot: snapshot(undone.afterRevision!),
        workspaceHandle: fixture.plan.request.workspaceHandle,
        idempotencyKey: 'key_redo');
    crashRedo = true;
    await expectLater(undo.apply(redoPlan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    final reconstructedHistory =
        await FileAuthoringHistoryStore.open(projectRoot: directory.path);
    final reconstructedBlobs =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    final recovery = AuthoringRecoveryService(
        gateway:
            await LocalTransactionFileGateway.open(projectRoot: directory.path),
        idempotency: ledger(),
        clock: () => BulkTransactionFixture.now,
        commitHook: AuthoringHistoryRecorder(
            store: reconstructedHistory, blobs: reconstructedBlobs));
    final recovered = await recovery.resume(redoPlan.operationId);
    expect(recovered.diff.toJson(), imported.diff.toJson());
    for (final change in fixture.plan.changeSet.changes) {
      expect(await gateway.readResourceRevision(change.storageKey),
          change.afterRevision);
    }
    final recoveredEntry = await reconstructedHistory.get(
        projectId: fixture.scope.projectId, entryId: recovered.receiptId);
    expect(recoveredEntry!.bulkCapability!.originEntryId, imported.receiptId);
    await File('${directory.path}/resources/000000.json')
        .writeAsString('external');
    final revert = AuthoringRevisionRevertService(
        history: reconstructedHistory,
        blobs: reconstructedBlobs,
        gateway: gateway,
        planner: planner,
        policy: policy(),
        executor: executor,
        tokenFactory: token);
    final revertPlan = await revert.planRevert(
        actor: actor,
        projectId: fixture.scope.projectId,
        targetEntryId: imported.receiptId,
        expectedHeadEntryId: recovered.receiptId,
        snapshot: snapshot(BulkTransactionFixture.revision),
        workspaceHandle: fixture.plan.request.workspaceHandle,
        idempotencyKey: 'key_revert');
    expect(revertPlan.plan.bulkCapability!.inventory.length, 1);
    expect(revertPlan.plan.bulkCapability!.logicalOutputCount, 1);
    final source = await reconstructedHistory.get(
        projectId: fixture.scope.projectId, entryId: imported.receiptId);
    final mutated = ResourcePackBulkInventoryEntry.fromChange(
        revertPlan.plan.changeSet.changes.single,
        role: 'logical');
    expect(
        () => verifyBulkHistoryMutation(
            origin: source!,
            actionId: 'history.redo',
            inventory: [mutated],
            diff: revertPlan.plan.changeSet.diff),
        throwsA(isA<AuthoringHistoryException>()));
    expect(
        () => verifyBulkHistoryMutation(
            origin: source!,
            actionId: 'history.undo',
            inventory: [mutated],
            diff: revertPlan.plan.changeSet.diff),
        throwsA(isA<AuthoringHistoryException>()));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
      'logical files include licences and generated borders with bounded CAS and metadata',
      () {
    ResourcePackBulkCapability certify(Map<String, String> roles) {
      final changes = <AuthoringResourceChange>[];
      var index = 0;
      for (final path in roles.keys) {
        changes.add(AuthoringResourceChange(
            resource:
                AuthoringResourceRef(kind: 'asset', id: 'output_${index++}'),
            storageKey: path,
            beforeBytes: null,
            afterBytes: [1]));
      }
      final plan = AuthoringPlan(
          planId: 'plan_files',
          receiptId: 'receipt_files',
          request: AuthoringRequest(
              requestId: 'request_files',
              actionId: 'resource_pack.import',
              actionVersion: 1,
              workspaceHandle: 'workspace_files',
              expectedRevision: BulkTransactionFixture.revision,
              idempotencyKey: 'key_files'),
          baseRevision: BulkTransactionFixture.revision,
          seed: 1,
          createdAt: BulkTransactionFixture.now,
          expiresAt: BulkTransactionFixture.now.add(const Duration(minutes: 1)),
          changeSet: AuthoringChangeSet(
              changes: changes,
              diff: AuthoringDiff([
                for (final change in changes)
                  AuthoringDiffEntry(
                      operation: AuthoringDiffOperation.add,
                      resource: change.resource,
                      path: r'$',
                      after: change.afterRevision)
              ])));
      return ResourcePackBulkAuthority.certifyImport(
          plan: plan,
          actorId: actor.actorId,
          projectId: 'project_files',
          operationId: 'operation_files',
          logicalStorageKeys: roles.entries
              .where((entry) => entry.value == 'logical')
              .map((entry) => entry.key),
          contentBlobStorageKeys: roles.entries
              .where((entry) => entry.value == 'blob')
              .map((entry) => entry.key));
    }

    final capability = certify({
      'licenses/pack.txt': 'logical',
      'assets/generated-border.png': 'logical',
      'assets/cas/one': 'blob',
      'assets/cas/two': 'blob',
      'project.json': 'metadata',
      'assets/.pokemap-assets.json': 'metadata'
    });
    expect(capability.logicalOutputCount, 2);
    expect(capability.contentBlobCount, 2);
    expect(capability.metadataCount, 2);
    expect(capability.inventory.length, 2 * capability.logicalOutputCount + 2);
    expect(
        () => certify({
              'assets/logical.png': 'logical',
              'assets/cas/one': 'blob',
              'assets/cas/two': 'blob'
            }),
        throwsArgumentError);
    expect(
        () => certify({
              'assets/logical.png': 'logical',
              'third-metadata.json': 'metadata'
            }),
        throwsArgumentError);
  });

  for (final count in [1, 501]) {
    test(
        'canonical blob-only revert preserves effective counts for $count blobs',
        () {
      final subset = _BlobOnlySubset(count);
      addTearDown(subset.importPlan.releasePayloads);
      addTearDown(subset.revertPlan.releasePayloads);
      verifyBulkHistoryMutation(
          origin: subset.entry,
          actionId: 'history.revert',
          inventory: subset.inventory,
          diff: subset.revertPlan.changeSet.diff);
      final capability = ResourcePackBulkAuthority.certifyHistory(
          plan: subset.revertPlan,
          actorId: actor.actorId,
          projectId: 'project_bulk',
          operationId: 'operation_revert',
          originEntryId: subset.entry.entryId,
          origin: subset.origin,
          verifiedInventory: subset.inventory);
      expect(capability.logicalOutputLimit, count);
      expect(capability.logicalOutputCount, 0);
      expect(capability.contentBlobCount, count);
      expect(capability.inventory.length, count);
      policy().authorize(AuthoringAuthorizationRequest(
          actor: actor,
          projectId: 'project_bulk',
          operation: AuthoringSecurityOperation.apply,
          actionId: 'history.revert',
          actionVersion: 1,
          riskLevel: AuthoringRiskLevel.medium,
          requestBytes: subset.revertPlan.authorizationRequestBytes,
          touchedResources: count,
          planId: subset.revertPlan.planId,
          operationId: 'operation_revert',
          diffFingerprint:
              bulkDiffFingerprint(subset.revertPlan.changeSet.diff),
          bulkCapability: capability));
    });
  }

  test('bulk history rejects altered ceilings and missing canonical provenance',
      () async {
    final directory = await Directory.systemTemp.createTemp('bulk-ceiling-');
    addTearDown(() => directory.delete(recursive: true));
    final subset = _BlobOnlySubset(1);
    addTearDown(subset.importPlan.releasePayloads);
    addTearDown(subset.revertPlan.releasePayloads);
    final history =
        await FileAuthoringHistoryStore.open(projectRoot: directory.path);
    await history.append(subset.entry);
    final recorder = AuthoringHistoryRecorder(
        store: history,
        blobs: await FileAuthoringContentBlobStore.open(
            projectRoot: directory.path));
    final certificate = ResourcePackBulkAuthority.certifyHistory(
        plan: subset.revertPlan,
        actorId: actor.actorId,
        projectId: 'project_bulk',
        operationId: 'operation_revert',
        originEntryId: subset.entry.entryId,
        origin: subset.origin,
        verifiedInventory: subset.inventory);
    final receipt =
        _BlobOnlySubset.receipt(subset.revertPlan, 'operation_revert');
    await recorder.requireBulkHistoryRecoveryAllowed(
        capability: certificate, intendedReceipt: receipt);
    for (final change in [
      <String, Object?>{'logicalOutputLimit': 2},
      <String, Object?>{'originEntryId': 'receipt_missing'}
    ]) {
      final altered = ResourcePackBulkCapability.fromJournalJson(
          {...certificate.toJson(), ...change});
      await expectLater(
          recorder.requireBulkHistoryRecoveryAllowed(
              capability: altered, intendedReceipt: receipt),
          throwsA(isA<AuthoringHistoryException>()));
    }
    expect(
        () => ResourcePackBulkCapability.fromJournalJson(
            {...subset.origin.toJson(), 'logicalOutputLimit': 2}),
        throwsFormatException);
    expect(
        () => ResourcePackBulkCapability.fromJournalJson(
            {...certificate.toJson(), 'logicalOutputLimit': 0}),
        throwsFormatException);
    expect(
        () => ResourcePackBulkCapability.fromJournalJson(
            {...certificate.toJson(), 'logicalOutputLimit': 20001}),
        throwsFormatException);
    expect(
        () => ResourcePackBulkCapability.fromJournalJson(
            {...certificate.toJson(), 'schemaVersion': 1}),
        throwsFormatException);
  });

  test(
      '501 blob-only revert undo redo retains its canonical ceiling after reconstruction',
      () async {
    final subset = _BlobOnlySubset(501);
    addTearDown(subset.importPlan.releasePayloads);
    addTearDown(subset.revertPlan.releasePayloads);
    final history = _SubsetHistoryStore();
    final blobs = _SubsetBlobStore();
    final retained = await blobs.put([1, 2, 3]);
    final entry = AuthoringHistoryEntry.fromJson({
      ...subset.entry.toJson(),
      'changes': [
        for (final change in subset.entry.changes)
          {...change.toJson(), 'afterBlobId': retained.id}
      ]
    });
    await history.append(entry);
    final gateway = CountingBulkGateway()..maxJournalWrites = 100;
    for (final change in subset.importPlan.changeSet.changes) {
      gateway.files[change.storageKey] =
          change.resource.kind == 'contentBlob' ? [9] : [1, 2, 3];
    }
    final plans = AuthoringPlanStore(clock: () => BulkTransactionFixture.now);
    addTearDown(plans.dispose);
    var serial = 0;
    String token(String prefix) => '$prefix${serial++}';
    final planner = AuthoringActionPlanner(
        store: plans, tokenFactory: token, seedFactory: () => 1);
    final ledgerStore = BulkMemoryIdempotencyStore();
    AuthoringIdempotencyLedger ledger() => AuthoringIdempotencyLedger(
        store: ledgerStore, clock: () => BulkTransactionFixture.now);
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    var crashRedo = false;
    final executor = SecureAuthoringMutationExecutor(
        transaction: JournaledAuthoringTransaction(
            plans: plans,
            gateway: gateway,
            idempotency: ledger(),
            clock: () => BulkTransactionFixture.now,
            commitHook: recorder,
            faultInjector: (context) {
              if (crashRedo &&
                  context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterResourcePromoted &&
                  context.promotionIndex == 250) {
                throw const AuthoringTransactionSimulatedCrash();
              }
            }),
        policy: policy(),
        auditLog: _SubsetAuditLog(),
        clock: () => BulkTransactionFixture.now,
        auditIdFactory: () => token('audit_'));
    ProjectSnapshot snapshot(String revision) => ProjectSnapshot(
        projectHandle: const ProjectHandle('project_bulk'),
        revision: revision,
        manifest:
            ProjectManifest(name: 'Subset', maps: const [], tilesets: const []),
        maps: const [],
        resourceFingerprints: {'project': revision});
    final revert = AuthoringRevisionRevertService(
        history: history,
        blobs: blobs,
        gateway: gateway,
        planner: planner,
        policy: policy(),
        executor: executor,
        tokenFactory: token);
    final prepared = await revert.planRevert(
        actor: actor,
        projectId: 'project_bulk',
        targetEntryId: entry.entryId,
        expectedHeadEntryId: entry.entryId,
        snapshot: snapshot(BulkTransactionFixture.revision),
        workspaceHandle: 'workspace_bulk',
        idempotencyKey: 'subset_revert');
    void expectSubset(ResourcePackBulkCapability capability) {
      expect(capability.logicalOutputLimit, 501);
      expect(capability.logicalOutputCount, 0);
      expect(capability.contentBlobCount, 501);
      expect(capability.inventory.length, 501);
    }

    expectSubset(prepared.plan.bulkCapability!);
    final reverted = await revert.apply(prepared);
    final undo = AuthoringUndoService(
        history: history,
        blobs: blobs,
        gateway: gateway,
        planner: planner,
        policy: policy(),
        executor: executor,
        tokenFactory: token);
    final undoPlan = await undo.planUndo(
        actor: actor,
        projectId: 'project_bulk',
        entryId: reverted.receiptId,
        snapshot: snapshot(reverted.afterRevision!),
        workspaceHandle: 'workspace_bulk',
        idempotencyKey: 'subset_undo');
    expectSubset(undoPlan.plan.bulkCapability!);
    final undone = await undo.apply(undoPlan);
    expect(await gateway.readResource('assets/blobs/blob_0.png'), [9]);
    final redoPlan = await undo.planRedo(
        actor: actor,
        projectId: 'project_bulk',
        entryId: reverted.receiptId,
        snapshot: snapshot(undone.afterRevision!),
        workspaceHandle: 'workspace_bulk',
        idempotencyKey: 'subset_redo');
    expectSubset(redoPlan.plan.bulkCapability!);
    crashRedo = true;
    await expectLater(undo.apply(redoPlan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    final reconstructedHistory = _SubsetHistoryStore()
      ..rows.addAll([
        for (final row in history.rows)
          AuthoringHistoryEntry.fromJson(row.toJson())
      ]);
    final recovery = AuthoringRecoveryService(
        gateway: gateway,
        idempotency: ledger(),
        clock: () => BulkTransactionFixture.now,
        commitHook: AuthoringHistoryRecorder(
            store: reconstructedHistory, blobs: blobs));
    final journal = (await gateway.readJournal(redoPlan.operationId))!;
    final observed = [
      for (final change in subset.revertPlan.changeSet.changes)
        await gateway.readResourceRevision(change.storageKey)
    ];
    final promotions = gateway.promotions;
    for (final alteration in [
      <String, Object?>{'logicalOutputLimit': 502},
      <String, Object?>{'originEntryId': 'receipt_missing'}
    ]) {
      final changedJournal = AuthoringTransactionJournal.fromJson({
        ...journal.toJson(),
        'bulkCapability': {...journal.bulkCapability!.toJson(), ...alteration}
      });
      await gateway.writeJournal(changedJournal);
      await expectLater(recovery.resume(redoPlan.operationId),
          throwsA(isA<AuthoringHistoryException>()));
      await expectLater(recovery.compensate(redoPlan.operationId),
          throwsA(isA<AuthoringHistoryException>()));
      expect(gateway.promotions, promotions);
      expect([
        for (final change in subset.revertPlan.changeSet.changes)
          await gateway.readResourceRevision(change.storageKey)
      ], observed);
    }
    await gateway.writeJournal(journal);
    final recovered = await recovery.resume(redoPlan.operationId);
    final recoveredEntry = await reconstructedHistory.get(
        projectId: 'project_bulk', entryId: recovered.receiptId);
    expectSubset(recoveredEntry!.bulkCapability!);
    expect(recoveredEntry.bulkCapability!.originEntryId, reverted.receiptId);
    for (final change in subset.importPlan.changeSet.changes) {
      expect(await gateway.readResource(change.storageKey), [1, 2, 3]);
    }
  });

  test('frozen import inventory rejects quota overflow and missing outputs',
      () {
    final fixture = BulkTransactionFixture(20001);
    addTearDown(fixture.plans.dispose);
    expect(fixture.certify, throwsArgumentError);
    final small = BulkTransactionFixture(4);
    addTearDown(small.plans.dispose);
    expect(
        () => ResourcePackBulkAuthority.certifyImport(
            plan: small.plan,
            actorId: actor.actorId,
            projectId: small.scope.projectId,
            operationId: small.operationId,
            logicalStorageKeys: const [],
            contentBlobStorageKeys: const []),
        throwsArgumentError);
  });
}

final class _BlobOnlySubset {
  _BlobOnlySubset(int count) {
    final logical = [
      for (var i = 0; i < count; i++)
        AuthoringResourceChange(
            resource: AuthoringResourceRef(kind: 'asset', id: 'native_$i'),
            storageKey: 'assets/native_$i.png',
            beforeBytes: null,
            afterBytes: [1, 2, 3])
    ];
    final blobs = [
      for (var i = 0; i < count; i++)
        AuthoringResourceChange(
            resource: AuthoringResourceRef(kind: 'contentBlob', id: 'blob_$i'),
            storageKey: 'assets/blobs/blob_$i.png',
            beforeBytes: null,
            afterBytes: [1, 2, 3])
    ];
    importPlan = plan('import', 'resource_pack.import', [...logical, ...blobs]);
    origin = ResourcePackBulkAuthority.certifyImport(
        plan: importPlan,
        actorId: 'actor_bulk',
        projectId: 'project_bulk',
        operationId: 'operation_import',
        logicalStorageKeys: logical.map((change) => change.storageKey),
        contentBlobStorageKeys: blobs.map((change) => change.storageKey));
    final changes = [
      for (final blob in blobs)
        AuthoringResourceChange(
            resource: blob.resource,
            storageKey: blob.storageKey,
            beforeBytes: [9],
            afterBytes: [1, 2, 3])
    ];
    revertPlan = plan('revert', 'history.revert', changes);
    inventory = [
      for (final change in changes)
        ResourcePackBulkInventoryEntry.fromChange(change, role: 'blob')
    ];
    entry = AuthoringHistoryEntry(
        entryId: importPlan.receiptId,
        projectId: 'project_bulk',
        actorId: 'actor_bulk',
        planId: importPlan.planId,
        operationId: 'operation_import',
        kind: AuthoringHistoryKind.mutation,
        receipt: receipt(importPlan, 'operation_import'),
        committedAt: BulkTransactionFixture.now,
        bulkCapability: origin,
        changes: [
          for (final change in importPlan.changeSet.changes)
            AuthoringHistoryResourceChange(
                resource: change.resource,
                storageKey: change.storageKey,
                beforeRevision: change.beforeRevision,
                afterRevision: change.afterRevision,
                beforeBlobId: change.beforeRevision,
                afterBlobId: change.afterRevision)
        ]);
  }
  late final AuthoringPlan importPlan;
  late final AuthoringPlan revertPlan;
  late final ResourcePackBulkCapability origin;
  late final AuthoringHistoryEntry entry;
  late final List<ResourcePackBulkInventoryEntry> inventory;

  static AuthoringPlan plan(
          String id, String actionId, List<AuthoringResourceChange> changes,
          {Map<String, Object?> extensions = const {}}) =>
      AuthoringPlan(
          planId: 'plan_$id',
          receiptId: 'receipt_$id',
          request: AuthoringRequest(
              requestId: 'request_$id',
              actionId: actionId,
              actionVersion: 1,
              workspaceHandle: 'workspace_bulk',
              expectedRevision: BulkTransactionFixture.revision,
              idempotencyKey: 'key_$id',
              extensions: extensions),
          baseRevision: BulkTransactionFixture.revision,
          seed: 1,
          createdAt: BulkTransactionFixture.now,
          expiresAt:
              BulkTransactionFixture.now.add(const Duration(minutes: 10)),
          changeSet: AuthoringChangeSet(
              changes: changes,
              diff: AuthoringDiff([
                for (final change in changes)
                  revisionHistoryDiff(change.resource,
                      beforeRevision: change.beforeRevision,
                      afterRevision: change.afterRevision)
              ])));

  static AuthoringReceipt receipt(AuthoringPlan plan, String operationId) =>
      AuthoringReceipt(
          receiptId: plan.receiptId,
          requestId: plan.request.requestId,
          actionId: plan.request.actionId,
          actionVersion: plan.request.actionVersion,
          status: AuthoringReceiptStatus.applied,
          beforeRevision:
              AuthoringRevisionSet.beforeChangeSet(plan.changeSet).fingerprint,
          afterRevision:
              AuthoringRevisionSet.afterChangeSet(plan.changeSet).fingerprint,
          createdAtUtc: BulkTransactionFixture.now.toIso8601String(),
          diff: plan.changeSet.diff,
          extensions: {
            'planId': plan.planId,
            'operationId': operationId,
            'history':
                AuthoringHistoryContext.fromExtensions(plan.request.extensions)
                    .toJson()
          });
}

final class _SubsetHistoryStore implements AuthoringHistoryStore {
  final rows = <AuthoringHistoryEntry>[];
  @override
  Future<void> append(AuthoringHistoryEntry entry) async {
    if (rows.any((row) =>
        row.projectId == entry.projectId && row.entryId == entry.entryId)) {
      throw StateError('Duplicate canonical history identity.');
    }
    rows.add(AuthoringHistoryEntry.fromJson(entry.toJson()));
  }

  @override
  Future<AuthoringHistoryEntry?> get(
      {required String projectId, required String entryId}) async {
    final row = rows
        .where((row) => row.projectId == projectId && row.entryId == entryId)
        .firstOrNull;
    return row == null ? null : AuthoringHistoryEntry.fromJson(row.toJson());
  }

  @override
  Future<AuthoringHistoryPage> list(
          {required String projectId,
          required int limit,
          AuthoringHistoryCursor? cursor}) async =>
      AuthoringHistoryPage(
          entries: rows.reversed
              .where((row) => row.projectId == projectId)
              .take(limit)
              .toList());
  @override
  Future<AuthoringHistoryEntry> markNonUndoable(
          {required String projectId,
          required String entryId,
          required String reason}) async =>
      (await get(projectId: projectId, entryId: entryId))!
          .markNonUndoable(reason);
}

final class _SubsetBlobStore
    implements AuthoringContentBlobStore, StreamingAuthoringContentBlobStore {
  final bytes = <String, List<int>>{};
  @override
  Future<AuthoringContentBlobRef> put(Iterable<int> value) async {
    final data = value.toList();
    final id = computeAuthoringBytesFingerprint(data,
        logicalName: 'authoring-history-blob');
    bytes[id] = data;
    return AuthoringContentBlobRef(id: id, byteLength: data.length);
  }

  @override
  Future<AuthoringContentBlobRef> putPayload(AuthoringPayload payload) async =>
      put(await payload.readBytes());
  @override
  Future<AuthoringPayload?> get(String id) =>
      capturePayload(id, storageKey: 'authoring-history-blob');
  @override
  Future<AuthoringPayload?> capturePayload(String id,
          {required String storageKey}) async =>
      bytes[id] == null
          ? null
          : AuthoringPayload.inline(bytes[id]!, storageKey: storageKey);
  @override
  Future<bool> contains(String id) async => bytes.containsKey(id);
  @override
  Future<List<String>> listIds() async => bytes.keys.toList();
  @override
  Future<int> prune({required Set<String> retainIds}) async {
    final before = bytes.length;
    bytes.removeWhere((key, value) => !retainIds.contains(key));
    return before - bytes.length;
  }
}

final class _SubsetAuditLog implements AuthoringAuditLog {
  final records = <AuthoringAuditRecord>[];
  @override
  Future<void> append(AuthoringAuditRecord record) async {
    records.add(record);
  }

  @override
  Future<List<AuthoringAuditRecord>> readAll() async =>
      List.unmodifiable(records);
}
