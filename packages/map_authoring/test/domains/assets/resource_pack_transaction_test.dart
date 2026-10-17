import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_pack_import_fixture.dart';
import 'resource_pack_export_test.dart' as source;
import '../../support/resource_pack_recovery_exit_worker.dart' as recovery_d;

void main() {
  group('resource pack recovery D', () {
    for (final defect in recovery_d.recoveryDCleanupGuards) {
      test('cleanup guard $defect', () async {
        await recovery_d.recoveryDCleanupGuard(defect);
      });
    }
    for (final failure in ['read', 'delete']) {
      test('best effort replay failure $failure', () async {
        await recovery_d.recoveryDBestEffortReplay(failure);
      });
    }
    for (final checkpoint in recovery_d.recoveryDCheckpoints) {
      test('cooperative $checkpoint', () async {
        await recovery_d.recoveryDCooperative(checkpoint);
      });
    }
    for (final checkpoint in ['beforeResourcePromotion', 'afterResourcePromoted']) {
      test('cooperative $checkpoint middle', () async {
        await recovery_d.recoveryDCooperative(checkpoint, middle: true);
      });
    }
    group('real exit77', () {
      setUpAll(recovery_d.recoveryDCompileWorker);
      tearDownAll(recovery_d.recoveryDDisposeWorker);
      for (final checkpoint in ['afterJournalPrepared', 'afterResourcePromoted']) {
        test(checkpoint, () async {
          await recovery_d.recoveryDRealExit(checkpoint);
        });
      }
    });
  }, skip: Platform.environment['POKEMAP_RESOURCE_PACK_RECOVERY_LOCAL'] != '1');
  test(
      'JSONL describes the semantic action and returns a clear prepared-handle rejection',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final worker =
          JsonlWorker(api: fixture.readApi, mutations: fixture.mutations);
      final describe = AuthoringResult.fromJson(jsonDecode(
              await worker.processLine(jsonEncode(
                  {'id': 'describe', 'command': 'describe', 'args': {}})))
          as Map<String, dynamic>);
      expect(describe.status, AuthoringResultStatus.success);
      expect(
          (describe.data['mutationActions'] as List)
              .cast<Map>()
              .where((a) => a['id'] == 'resource_pack.import'),
          hasLength(1));
      final result = AuthoringResult.fromJson(
          jsonDecode(await worker.processLine(jsonEncode({
        'id': 'plan',
        'command': 'plan',
        'args': {
          'projectHandle': fixture.opened.projectHandle.value,
          'request': AuthoringRequest(
              requestId: 'invalid-prepared',
              actionId: 'resource_pack.import',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision:
                  (await fixture.loader.load(fixture.opened.projectHandle))
                      .revision,
              idempotencyKey: 'invalid-prepared',
              parameters: {'preparedImportHandle': 'foreign'}).toJson()
        }
      }))) as Map<String, dynamic>);
      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error!.details['domainCode'],
          'resource_pack.prepared_unknown');
      expect(result.error!.code, AuthoringErrorCode.validationFailed);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'native apply installs once and replays after reconstruction without a journal',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final before =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final prepared = await fixture.prepare();
      final planned = await fixture.plan(prepared);
      expect(planned.applicable, isTrue);
      final applied =
          await fixture.apply(planned, operationId: 'durable-import');
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      expect(snapshot.manifest.elements.length, greaterThan(0));
      expect(snapshot.manifest.models3d.single.relativePath,
          'assets/models3d/${snapshot.manifest.models3d.single.id}.glb');
      expect(snapshot.manifest.settings, before.settings);
      expect(snapshot.manifest.maps, before.maps);
      expect(snapshot.manifest.scenes, before.scenes);
      expect(snapshot.manifest.dialogues, before.dialogues);
      expect(
          snapshot.manifest.tilesets.every(
              (t) => !t.isWorldTileset && t.scope == TilesetScope.global),
          isTrue);
      expect(
          (jsonDecode(await File('${fixture.root.path}/project.json')
              .readAsString()) as Map)['unknownNativeMetadata'],
          {
            'keep': ['verbatim', 7]
          });
      final history =
          File('${fixture.root.path}/.pokemap/authoring/history.jsonl');
      final historyBefore = await history.readAsString();
      final projectBefore =
          await File('${fixture.root.path}/project.json').readAsString();
      final tx =
          Directory('${fixture.root.path}/.pokemap/authoring/transactions');
      expect(
          await tx.exists()
              ? await tx
                  .list(recursive: true)
                  .where((e) => e is File && e.path.endsWith('.json'))
                  .length
              : 0,
          0);
      await fixture.close();
      await fixture.open();
      final replay = await fixture.mutations.applyMutation(
          fixture.opened.projectHandle,
          planId: planned.planId,
          operationId: 'durable-import');
      expect(replay.receipt.toJson(), applied.receipt.toJson());
      expect(await history.readAsString(), historyBefore);
      expect(await File('${fixture.root.path}/project.json').readAsString(),
          projectBefore);
      final again = await fixture.mutations.applyMutation(
          fixture.opened.projectHandle,
          planId: planned.planId,
          operationId: 'durable-import');
      expect(again.receipt.toJson(), applied.receipt.toJson());
      await expectLater(
          fixture.mutations.applyMutation(fixture.opened.projectHandle,
              planId: 'another-plan', operationId: 'durable-import'),
          throwsA(anything));
      await expectLater(
          fixture.mutations.applyMutation(fixture.opened.projectHandle,
              planId: planned.planId, operationId: 'unknown-operation'),
          throwsA(isA<AuthoringPlanException>()));
    } finally {
      await fixture.dispose();
    }
  });

  for (final defect in [
    'plan',
    'action',
    'version',
    'operation',
    'actor',
    'ambiguous',
    'pending',
    'corrupt-history'
  ]) {
    test('durable replay refuses $defect without another native commit',
        () async {
      final fixture = await NativeResourcePackImportFixture.create();
      try {
        final planned = await fixture.plan(await fixture.prepare());
        await fixture.apply(planned, operationId: 'replay-negative');
        final project = File('${fixture.root.path}/project.json');
        final projectBefore = await project.readAsString();
        final history =
            File('${fixture.root.path}/.pokemap/authoring/history.jsonl');
        final ledger =
            File('${fixture.root.path}/.pokemap/authoring/idempotency.jsonl');
        await fixture.close();
        final events = (await ledger.readAsLines())
            .where((line) => line.isNotEmpty)
            .map((line) => Map<String, dynamic>.from(jsonDecode(line) as Map))
            .toList();
        final event = events.last;
        final record = event['record'] as Map;
        final receipt = record['receipt'] as Map;
        final scope = record['scope'] as Map;
        switch (defect) {
          case 'plan':
            (receipt['extensions'] as Map)['planId'] = 'wrong-plan';
          case 'action':
            receipt['actionId'] = 'asset.delete';
          case 'version':
            receipt['actionVersion'] = 2;
          case 'operation':
            (receipt['extensions'] as Map)['operationId'] = 'wrong-operation';
          case 'actor':
            scope['actorId'] = 'foreign-actor';
          case 'ambiguous':
            final duplicate =
                jsonDecode(jsonEncode(event)) as Map<String, dynamic>;
            ((duplicate['record'] as Map)['scope'] as Map)['keyFingerprint'] =
                'sha256:${List.filled(64, 'a').join()}';
            events.add(duplicate);
          case 'pending':
            record['status'] = 'pending';
            record.remove('expiresAtUtc');
            record.remove('receipt');
          case 'corrupt-history':
            final text = await history.readAsString();
            await history
                .writeAsString(text.replaceFirst('sha256:', 'sha257:'));
        }
        await ledger.writeAsString('${events.map(jsonEncode).join('\n')}\n');
        final historyBefore = await history.readAsString();
        await fixture.open();
        await expectLater(
            fixture.mutations.applyMutation(fixture.opened.projectHandle,
                planId: planned.planId, operationId: 'replay-negative'),
            throwsA(anything));
        expect(await project.readAsString(), projectBefore);
        expect(await history.readAsString(), historyBefore);
      } finally {
        await fixture.dispose();
      }
    });
  }

  test(
      'completed replay expires after retention and cannot resurrect a missing plan',
      () async {
    var now = DateTime.utc(2026, 10, 17);
    final fixture =
        await NativeResourcePackImportFixture.create(clock: () => now);
    try {
      final planned = await fixture.plan(await fixture.prepare());
      await fixture.apply(planned, operationId: 'expired-replay');
      await fixture.close();
      now = now.add(const Duration(days: 31));
      await fixture.open();
      await expectLater(
          fixture.mutations.applyMutation(fixture.opened.projectHandle,
              planId: planned.planId, operationId: 'expired-replay'),
          throwsA(isA<AuthoringPlanException>()
              .having((e) => e.code, 'code', 'plan.unknown')));
      expect(
          (await fixture.mutations
                  .listMutationHistory(fixture.opened.projectHandle, limit: 10))
              .entries,
          hasLength(1));
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'a newly occupied unregistered path is rejected by the locked second observation',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final plan = await fixture.plan(await fixture.prepare());
      final output = plan.plan.changeSet.changes
          .firstWhere((c) => c.resource.kind == 'asset');
      final file = File('${fixture.root.path}/${output.storageKey}');
      await file.parent.create(recursive: true);
      await file.writeAsString('occupied after final certificate');
      await expectLater(
          fixture.apply(plan, operationId: 'stale-path'),
          throwsA(isA<ResourcePackImportException>()
              .having((e) => e.code, 'code', 'resource_pack.path_occupied')));
      expect(await file.readAsString(), 'occupied after final certificate');
      expect(
          (await fixture.mutations
                  .listMutationHistory(fixture.opened.projectHandle, limit: 10))
              .entries,
          isEmpty);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'client catalog inventory quota and file roles cannot enter the import action',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final prepared = await fixture.prepare();
      for (final key in [
        'catalog',
        'inventory',
        'quota',
        'logicalStorageKeys',
        'fileRoles'
      ]) {
        await expectLater(
            fixture.plan(prepared, parameters: {
              'preparedImportHandle': prepared.preparedImportHandle,
              key: {'forged': true}
            }),
            throwsA(anything));
      }
      expect(
          (await fixture.mutations
                  .listMutationHistory(fixture.opened.projectHandle, limit: 10))
              .entries,
          isEmpty);
    } finally {
      await fixture.dispose();
    }
  });

  test('an added output cannot receive the internal final-plan capability',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final result = await fixture.plan(await fixture.prepare());
      final plan = result.plan;
      final extraResource = AuthoringResourceRef(kind: 'asset', id: 'impostor');
      final extra = AuthoringResourceChange(
          resource: extraResource,
          storageKey: 'assets/impostor.txt',
          beforeBytes: null,
          afterBytes: [1]);
      final forged = AuthoringPlan(
          planId: plan.planId,
          receiptId: plan.receiptId,
          request: plan.request,
          baseRevision: plan.baseRevision,
          seed: plan.seed,
          createdAt: plan.createdAt,
          expiresAt: plan.expiresAt,
          changeSet: AuthoringChangeSet(
              changes: [...plan.changeSet.changes, extra],
              diff: AuthoringDiff([
                ...plan.changeSet.diff.entries,
                AuthoringDiffEntry(
                    operation: AuthoringDiffOperation.add,
                    resource: extraResource,
                    path: '/')
              ])));
      expect(
          () => fixture.preparer.certifyPlan(
              plan: forged,
              actorId: 'local_cli',
              projectId: fixture.preparer.scope.projectId,
              operationId: 'forged'),
          throwsA(isA<ResourcePackImportException>().having(
              (e) => e.code, 'code', 'resource_pack.inventory_changed')));
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'reconstructed replay keeps authorization and audits zero touched resources',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final plan = await fixture.plan(await fixture.prepare());
      await fixture.apply(plan, operationId: 'permissions-replay');
      final history =
          await File('${fixture.root.path}/.pokemap/authoring/history.jsonl')
              .readAsString();
      await fixture.close();
      await fixture.open(
          actor: AuthoringActor(
              actorId: 'local_cli',
              permissions: [AuthoringPermissionScope.projectRead]));
      await expectLater(
          fixture.mutations.applyMutation(fixture.opened.projectHandle,
              planId: plan.planId, operationId: 'permissions-replay'),
          throwsA(isA<AuthoringAuthorizationException>()));
      final audit =
          await FileAuthoringAuditLog.open(projectRoot: fixture.root.path);
      expect(
          (await audit.readAll()).last.decision, AuthoringAuditDecision.denied);
      expect(
          await File('${fixture.root.path}/.pokemap/authoring/history.jsonl')
              .readAsString(),
          history);
      await fixture.close();
      await fixture.open();
      await fixture.mutations.applyMutation(fixture.opened.projectHandle,
          planId: plan.planId, operationId: 'permissions-replay');
      final last = (await audit.readAll()).last;
      expect(last.details['touchedResources'], 0);
      expect(last.details['idempotentReplay'], true);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'a refresh fault after commit retains the applied receipt and diagnostic',
      () async {
    late NativeResourcePackImportFixture fixture;
    var injected = false;
    fixture = await NativeResourcePackImportFixture.create(
        faultInjector: (context) async {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterJournalCommitted) {
        injected = true;
        await File('${fixture.root.path}/project.json')
            .writeAsString('{invalid after commit');
      }
    });
    try {
      final plan = await fixture.plan(await fixture.prepare());
      final result = await fixture.apply(plan, operationId: 'refresh-fault');
      expect(injected, isTrue);
      expect(result.receipt.status, AuthoringReceiptStatus.applied);
      expect(result.snapshotRevision, isNull);
      expect(result.diagnostic!.code, 'snapshot.refresh_unavailable');
      final replay = await fixture.mutations.applyMutation(
          fixture.opened.projectHandle,
          planId: plan.planId,
          operationId: 'refresh-fault');
      expect(replay.receipt.toJson(), result.receipt.toJson());
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'an unavailable output discovered under lock forces recovery and never reports applied',
      () async {
    late NativeResourcePackImportFixture fixture;
    var injected = false;
    fixture = await NativeResourcePackImportFixture.create(
        faultInjector: (context) async {
      if (!injected &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.beforeResourcePromotion &&
          context.storageKey!.startsWith('assets/')) {
        injected = true;
        final occupied = File('${fixture.root.path}/${context.storageKey}');
        await occupied.parent.create(recursive: true);
        await occupied.writeAsString('foreign output');
      }
    });
    try {
      final plan = await fixture.plan(await fixture.prepare());
      await expectLater(fixture.apply(plan, operationId: 'foreign-promotion'),
          throwsA(anything));
      expect(injected, isTrue);
      await expectLater(
          fixture.mutations.applyMutation(fixture.opened.projectHandle,
              planId: plan.planId, operationId: 'foreign-promotion'),
          throwsA(anything));
      expect(
          (await fixture.mutations
                  .listMutationHistory(fixture.opened.projectHandle, limit: 10))
              .entries,
          isEmpty);
    } finally {
      await fixture.dispose();
    }
  });

  for (final fault in [
    AuthoringTransactionCheckpoint.afterResourcePromoted,
    AuthoringTransactionCheckpoint.afterJournalCommitted
  ]) {
    test(
        'fault at ${fault.name} has a durable receipt or requires explicit recovery',
        () async {
      var injected = false;
      final fixture = await NativeResourcePackImportFixture.create(
          faultInjector: (context) {
        if (!injected && context.checkpoint == fault) {
          injected = true;
          throw const FileSystemException('No space left on device');
        }
      });
      try {
        final plan = await fixture.plan(await fixture.prepare());
        AuthoringMutationResult? result;
        try {
          result = await fixture.apply(plan, operationId: 'disk-full');
        } catch (_) {}
        expect(injected, isTrue);
        if (result != null) {
          expect(result.receipt.status, AuthoringReceiptStatus.applied);
          expect(
              (await fixture.mutations.listMutationHistory(
                      fixture.opened.projectHandle,
                      limit: 10))
                  .entries,
              hasLength(1));
        } else {
          final recovered = await fixture.mutations.recoverMutation(
              fixture.opened.projectHandle,
              operationId: 'disk-full');
          expect(
              recovered.receipt.status,
              anyOf(AuthoringReceiptStatus.applied,
                  AuthoringReceiptStatus.recovered));
        }
      } finally {
        await fixture.dispose();
      }
    });
  }

  test('bulk native inventory above 500 applies, undoes, redoes and reopens',
      () async {
    const count = 501;
    NativeResourcePackImportFixture? fixture;
    final watch = Stopwatch()..start();
    var phase = 'fixture';
    void record(String stage, {int? promotionIndex}) => print(jsonEncode({
          'bulkRoots': count,
          'phase': phase,
          'stage': stage,
          'elapsedMs': watch.elapsedMilliseconds,
          if (promotionIndex != null) 'promotionIndex': promotionIndex
        }));
    try {
      final manifest = source.originalManifest().copyWith(
          smartTileCatalog: const ProjectSmartTileCatalog.empty(),
          tilesets: [
            for (var i = 0; i < count; i++)
              source.originalManifest().tilesets.single.copyWith(
                  id: 'tileset-$i',
                  relativePath: 'assets/image-$i.png',
                  source: ProjectTilesetSource.regularAtlas(
                      assetId: 'image-$i',
                      pixelWidth: 2,
                      pixelHeight: 2,
                      tileWidth: 2,
                      tileHeight: 2))
          ]);
      record('start');
      fixture = await NativeResourcePackImportFixture.create(
          sourceManifest: manifest,
          sourceFiles: [
            for (var i = 0; i < count; i++)
              source.nativeImage(id: 'image-$i', path: 'assets/image-$i.png')
          ],
          roots: [
            for (var i = 0; i < count; i++)
              NativeResourcePackRef(
                  kind: ResourcePackKind.tileset, id: 'tileset-$i')
          ],
          faultInjector: (context) {
            final index = context.promotionIndex;
            if (index == null ||
                (context.checkpoint ==
                        AuthoringTransactionCheckpoint.afterResourcePromoted &&
                    (index % 100 == 0 || index == count + 4))) {
              record(context.checkpoint.name, promotionIndex: index);
            }
          });
      final selected = await fixture.select(roots: [
        for (final t in fixture.source.archive.inspection.catalog.tilesets)
          ResourcePackRef(kind: ResourcePackKind.tileset, id: t.id)
      ]);
      final prepared = await fixture.prepare(selection: selected);
      final plan = await fixture.plan(prepared);
      expect(plan.plan.changeSet.changes.length, greaterThan(500));
      expect(plan.plan.bulkCapability, isNull);
      record('prepared');
      phase = 'apply';
      record('start');
      final applied = await fixture.apply(plan, operationId: 'bulk-import');
      final history = await fixture.mutations
          .listMutationHistory(fixture.opened.projectHandle, limit: 10);
      final entry = history.entries.single;
      expect(entry.bulkCapability!.logicalOutputCount, count + 1);
      expect(entry.bulkCapability!.logicalOutputLimit, count + 1);
      expect(entry.bulkCapability!.contentBlobCount, 2);
      record('verified');
      final appliedHead = (await fixture.mutations
              .listMutationHistory(fixture.opened.projectHandle, limit: 1))
          .entries
          .single;
      expect(appliedHead.receipt.receiptId, applied.receipt.receiptId);
      expect(
          (await fixture.loader.load(fixture.opened.projectHandle))
              .manifest
              .tilesets,
          hasLength(count));
      phase = 'undo';
      record('start');
      final undone = await fixture.mutations.undoMutation(
          fixture.opened.projectHandle,
          entryId: applied.receipt.receiptId,
          idempotencyKey: 'undo-bulk');
      expect(undone.receipt.status, AuthoringReceiptStatus.applied);
      expect(
          (await fixture.loader.load(fixture.opened.projectHandle))
              .manifest
              .tilesets,
          isEmpty);
      record('verified');
      final undoneHead = (await fixture.mutations
              .listMutationHistory(fixture.opened.projectHandle, limit: 1))
          .entries
          .single;
      expect(undoneHead.kind, AuthoringHistoryKind.undo);
      expect(undoneHead.targetEntryId, applied.receipt.receiptId);
      expect(
          (await fixture.loader.load(fixture.opened.projectHandle))
              .manifest
              .tilesets,
          isEmpty);
      phase = 'redo';
      record('start');
      final redone = await redoNativeImport(fixture, applied.receipt.receiptId);
      expect(redone.status, AuthoringReceiptStatus.applied);
      expect(
          (await fixture.loader.load(fixture.opened.projectHandle))
              .manifest
              .tilesets,
          hasLength(count));
      record('verified');
      phase = 'reopen';
      record('start');
      await fixture.close();
      await fixture.open();
      expect(
          (await fixture.loader.load(fixture.opened.projectHandle))
              .manifest
              .tilesets,
          hasLength(count));
      final reopenedHistory = await fixture.mutations
          .listMutationHistory(fixture.opened.projectHandle, limit: 10);
      expect(reopenedHistory.entries.first.bulkCapability!.logicalOutputLimit,
          count + 1);
      record('verified');
    } finally {
      phase = 'dispose';
      record('start');
      await fixture?.dispose();
      record('done');
    }
  }, timeout: const Timeout(Duration(seconds: 180)));
}
