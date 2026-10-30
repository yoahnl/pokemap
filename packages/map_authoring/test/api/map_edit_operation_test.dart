import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/reliability_map_fixture.dart';

void main() {
  test('a facade confirmation continues through canonical apply with selected dependencies',() async {
    final canonical=MapMutationDispatcher.canonical();
    final descriptor=AuthoringActionDescriptor.fromJson({
      ...canonical.descriptor('map3d.edit_batch').toJson(),'riskLevel':'high'});
    final fixture=await ReliabilityMapFixture.create(variant:ReliabilityMapVariant.interiorHole,
      qaRoot:'${ReliabilityMapFixture.defaultQaRoot}/confirmation',dispatcher:MapMutationDispatcher([
        MapMutationActionRegistration(descriptor:descriptor,build:canonical.build),
      ]));
    addTearDown(fixture.dispose);
    await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
    final before=await fixture.mapFile.readAsBytes();
    final operation=MapEditOperation(operationId:'confirmed-edit',mapId:'map',operations:[{
      'actionId':'smart_tile.cell.paint','actionVersion':1,'parameters':{
        'layerId':'terrain','materialId':'grass','cells':[{'x':12,'y':8}]}}]);
    final result=await fixture.api.mapEdit(fixture.opened.projectHandle,operation);
    expect(result['status'],'confirmation_required');
    expect(await fixture.mapFile.readAsBytes(),before);
    final planId=result['planId'] as String;
    final confirmation=await fixture.api.confirmMutation(fixture.opened.projectHandle,planId:planId);
    final applied=await fixture.api.applyMutation(fixture.opened.projectHandle,planId:planId,
      operationId:operation.operationId,confirmationToken:confirmation.confirmationToken);
    expect(applied.receipt.status,AuthoringReceiptStatus.applied);
    await fixture.reopen();
    final replay=await fixture.api.mapEdit(fixture.opened.projectHandle,operation);
    expect(replay['status'],'applied');
    expect((replay['receipt'] as Map)['receiptId'],applied.receipt.receiptId);
  });
  for (final storage in ReliabilityStorage.values) {
    test('$storage concurrent calls return one durable logical result',() async {
      final fixture=await ReliabilityMapFixture.create(variant:ReliabilityMapVariant.interiorHole,
        storage:storage,qaRoot:'${ReliabilityMapFixture.defaultQaRoot}/concurrent');
      addTearDown(fixture.dispose);
      await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
      final operation=MapEditOperation(operationId:'same-intention',mapId:'map',operations:[{
        'actionId':'smart_tile.cell.paint','actionVersion':1,'parameters':{
          'layerId':'terrain','materialId':'grass','cells':[{'x':12,'y':8}]}}]);
      final results=await Future.wait([for(var i=0;i<2;i++) fixture.api.mapEdit(fixture.opened.projectHandle,operation)]);
      expect(results.map((result)=>result['status']),everyElement('applied'));
      expect(results.first['receipt'],results.last['receipt']);
    });
    test('$storage identical painting after undo is a new logical application',() async {
      final fixture=await ReliabilityMapFixture.create(variant:ReliabilityMapVariant.interiorHole,
        storage:storage,qaRoot:'${ReliabilityMapFixture.defaultQaRoot}/undo');
      addTearDown(fixture.dispose);
      await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
      final before=await fixture.mapFile.readAsBytes();
      final firstOperation=MapEditOperation(operationId:'before-undo',mapId:'map',operations:[{
        'actionId':'smart_tile.cell.paint','actionVersion':1,'parameters':{
          'layerId':'terrain','materialId':'grass','cells':[{'x':12,'y':8}]}}]);
      final first=await fixture.api.mapEdit(fixture.opened.projectHandle,firstOperation);
      await fixture.api.undoMutation(fixture.opened.projectHandle,
        entryId:(first['receipt'] as Map)['receiptId'] as String,idempotencyKey:'undo-first');
      expect(await fixture.mapFile.readAsBytes(),before);
      final second=await fixture.api.mapEdit(fixture.opened.projectHandle,
        MapEditOperation.fromJson({...firstOperation.toJson(),'operationId':'after-undo'}));
      expect(second['status'],'applied');
      expect((second['receipt'] as Map)['receiptId'],isNot((first['receipt'] as Map)['receiptId']));
      await fixture.reopen();
      final map=await fixture.readMap();
      expect(smartTileMaterialIdAt(map.layers.whereType<SmartTileLayer>().first,
        mapSize:map.size,x:12,y:8),'grass');
    });
    test(
        '$storage cancellation during staging cannot reserve or promote a map edit',
        () async {
      var cancelled = false;
      final fixture = await ReliabilityMapFixture.create(
          variant: ReliabilityMapVariant.interiorHole,
          storage: storage,
          qaRoot: '${ReliabilityMapFixture.defaultQaRoot}/cancel',
          faultInjector: (checkpoint) {
            if (checkpoint.checkpoint ==
                AuthoringTransactionCheckpoint.afterJournalStaged) {
              cancelled = true;
            }
          });
      addTearDown(fixture.dispose);
      await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
      final before = await fixture.mapFile.readAsBytes();
      await expectLater(fixture.api.mapEdit(
          fixture.opened.projectHandle,
          MapEditOperation(
              operationId: 'cancel-stage-${storage.name}',
              mapId: 'map',
              operations: [
                {
                  'actionId': 'smart_tile.cell.paint',
                  'actionVersion': 1,
                  'parameters': {
                    'layerId': 'terrain',
                    'materialId': 'grass',
                    'cells': [
                      {'x': 12, 'y': 8}
                    ]
                  },
                }
              ]),
          isCancelled: () => cancelled),throwsA(isA<AuthoringPlanException>()
            .having((error)=>error.code,'code','map_edit.cancelled')));
      expect(cancelled, isTrue);
      expect(await fixture.mapFile.readAsBytes(), before);
    });
  }
  test('semantic identity normalizes defaults and excludes transport identity',
      () {
    final base = _operation();
    final explicit = MapEditOperation.fromJson(
        {...base.toJson(), 'operationId': 'new-intention', 'dryRun': true});
    final implicit = MapEditOperation.fromJson({
      'operationId': 'first',
      'mapId': 'field',
      'operations': base.operations
    });
    expect(() => MapEditOperation.fromJson({...base.toJson(), 'seed': null}),
        throwsFormatException);
    expect(() => MapEditOperation.fromJson({...base.toJson(), 'dryRun': null}),
        throwsFormatException);
    expect(() => MapEditOperation.fromJson({...base.toJson(), 'guards': null}),
        throwsFormatException);
    expect(base.semanticFingerprint, explicit.semanticFingerprint);
    expect(base.semanticFingerprint, implicit.semanticFingerprint);
    expect(_operation(seed: 1).semanticFingerprint,
        isNot(base.semanticFingerprint));
    expect(
        () => MapEditOperation.fromJson(
            {...base.toJson(), 'expectedRevision': 'old'}),
        throwsFormatException);
    expect(
        () => MapEditOperation.fromJson({
              ...base.toJson(),
              'guards': {'unknown': 'report'}
            }),
        throwsFormatException);
    expect(
        () => MapEditOperation.fromJson({
              ...base.toJson(),
              'operations': [
                {...base.operations.single, 'unknown': true}
              ]
            }),
        throwsFormatException);
  });

  test(
      'generated IDs depend on logical identity and seed rather than plan token',
      () {
    final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('project'),
        revision: _revision,
        manifest:
            const ProjectManifest(name: 'Fixture', maps: [], tilesets: []),
        maps: const [],
        resourceFingerprints: const {});
    AuthoringPlanningContext context(String plan, String? logical, int seed) =>
        AuthoringPlanningContext(
            snapshot: snapshot,
            request: _request(),
            planId: plan,
            seed: seed,
            logicalOperationId: logical);
    expect(context('plan-a', 'edit', 42).generateId('feature'),
        context('plan-b', 'edit', 42).generateId('feature'));
    expect(context('plan-a', 'new-edit', 42).generateId('feature'),
        isNot(context('plan-a', 'edit', 42).generateId('feature')));
    expect(context('plan-a', null, 42).generateId('feature'),
        isNot(context('plan-b', null, 42).generateId('feature')));
  });

  test(
      'safe stale retries are bounded and never retry an observed durable intent',
      () async {
    var attempts = 0;
    var inspections = 0;
    final waits = <Duration>[];
    final execution = MapEditExecution(
        inspect: (_) async {
          inspections++;
          return null;
        },
        plan: (_, __) async {
          attempts++;
          throw AuthoringPlanException(code: 'plan.stale', message: 'changed');
        },
        apply: (_, __) async => throw StateError('must not apply'),
        project: (_) async => throw StateError('must not project'),
        discard: (_) async {},
        delay: (duration) async {
          waits.add(duration);
        });
    expect((await execution.execute(_operation()))['status'], 'busy');
    expect(attempts, 3);
    expect(inspections, 4);
    expect(waits,
        [const Duration(milliseconds: 100), const Duration(milliseconds: 250)]);
    attempts = 0;
    final pending = MapEditExecution(
        inspect: (_) async => {'status': 'recovery_required'},
        plan: (_, __) async {
          attempts++;
          throw StateError('must not plan');
        },
        apply: (_, __) async => throw StateError('must not apply'),
        project: (_) async => throw StateError('must not project'),
        discard: (_) async {});
    expect(
        (await pending.execute(_operation()))['status'], 'recovery_required');
    expect(attempts, 0);
  });

  test('cancelled or over-budget preparation cannot start an application',
      () async {
    for (final cancel in [true, false]) {
      var cancelled = false, applies = 0;
      final plan = _plan(DateTime.utc(2026, 10, 30));
      final execution = MapEditExecution(
          inspect: (_) async => null,
          plan: (_, __) async {
            if (cancel) {
              cancelled = true;
            } else {
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }
            return AuthoringMutationPlanResult(
                plan: plan,
                snapshotRevision: _revision,
                receipt: plan.toPlannedReceipt());
          },
          apply: (_, requireActive) async {
            requireActive();
            applies++;
            return {};
          },
          project: (_) async => {},
          discard: (_) async {},
          deadline: cancel
              ? const Duration(seconds: 5)
              : const Duration(milliseconds: 1));
      await expectLater(
          execution.execute(_operation(), isCancelled: () => cancelled),
          throwsA(isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'map_edit.cancelled')));
      expect(applies, 0);
    }
  });

  for (final jsonl in [false, true]) {
    test(
        'classic pending index preparation is exposed through ${jsonl ? 'JSONL' : 'Dart API'}',
        () async {
      final fixture = await ReliabilityMapFixture.create(
          variant: ReliabilityMapVariant.healthy,
          qaRoot:
              '/Users/karim/Library/Caches/AveluneQA/mcp-map-reliability/r2');
      addTearDown(fixture.dispose);
      final gateway = await LocalTransactionFileGateway.open(
          projectRoot: fixture.root.path);
      await expectLater(
          gateway.listPendingJournals(requirePrepared: true),
          throwsA(isA<TransactionFileGatewayException>().having(
              (error) => error.code,
              'code',
              'transaction.pending_index_preparation_required')));
      if (jsonl) {
        final result = await fixture.command('workshop_prepare',
            {'projectHandle': fixture.opened.projectHandle.value});
        expect(result.status, AuthoringResultStatus.success,
            reason: result.error?.toJson().toString());
        expect(result.data['prepared'], isTrue);
      } else {
        final result = await fixture.api
            .prepareWorkshopDocument(fixture.opened.projectHandle);
        expect(result['prepared'], isTrue);
      }
      expect(await gateway.listPendingJournals(requirePrepared: true), isEmpty);
    });
  }

  group('map edit durable metadata boundary', () {
    late Directory root;
    late String ledgerPath;
    final now = DateTime.utc(2026, 10, 30);
    setUp(() async {
      final qa = await Directory(
              '/Users/karim/Library/Caches/AveluneQA/mcp-map-reliability/r2')
          .create(recursive: true);
      root = await qa.createTemp('operation-');
      ledgerPath = '${root.path}/.pokemap/authoring/idempotency.jsonl';
      await File('${root.path}/maps/field.json').parent.create(recursive: true);
      await File('${root.path}/maps/field.json').writeAsString('{"value":1}');
      await (await LocalTransactionFileGateway.open(projectRoot: root.path))
          .preparePendingJournalIndex();
    });
    tearDown(() => root.delete(recursive: true));

    test(
        'a published pending pointer without its scope is recoverable, not expired',
        () async {
      final plan = _plan(now)
        ..bindMapEdit(_binding(_plan(now), unchanged: true));
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      final store = FileIdempotencyStore(filePath: ledgerPath);
      final transaction = JournaledAuthoringTransaction(
          plans: AuthoringPlanStore(clock: () => now)..save(plan),
          gateway: gateway,
          idempotency:
              AuthoringIdempotencyLedger(store: store, clock: () => now),
          clock: () => now,
          faultInjector: (context) {
            if (context.checkpoint ==
                AuthoringTransactionCheckpoint.afterReservation) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      await expectLater(
          transaction.apply(
              planId: plan.planId,
              request: plan.request,
              currentProjectRevision: plan.baseRevision,
              scope: _scope(),
              operationId: 'edit'),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      final scopes =
          await Directory('${root.path}/.pokemap/authoring/idempotency-scopes')
              .list()
              .where((entry) => entry.path.endsWith('.jsonl'))
              .toList();
      expect(scopes.length, 1);
      await scopes.single.delete();
      final lookup = await FileIdempotencyStore(filePath: ledgerPath)
          .lookupOperation(
              actorId: 'actor',
              projectId: 'project',
              operationId: 'edit',
              now: now,
              targetedOnly: true);
      expect(lookup, isNotNull);
      expect(lookup!.expired, isFalse);
      expect(lookup.completed, isNull);
      expect(await gateway.readJournal('edit'), isNotNull);
    });

    test('compensation stays terminal and cannot be presented as applied',
        () async {
      final plan = _plan(now, changed: true);
      plan.bindMapEdit(_binding(plan, unchanged: false));
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      final store = FileIdempotencyStore(filePath: ledgerPath);
      final ledger = AuthoringIdempotencyLedger(store: store, clock: () => now);
      final transaction = JournaledAuthoringTransaction(
          plans: AuthoringPlanStore(clock: () => now)..save(plan),
          gateway: gateway,
          idempotency: ledger,
          clock: () => now,
          faultInjector: (context) {
            if (context.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      await expectLater(
          transaction.apply(
              planId: plan.planId,
              request: plan.request,
              currentProjectRevision: plan.baseRevision,
              scope: _scope(),
              operationId: 'edit'),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      final recovery = AuthoringRecoveryService(
          gateway: gateway, idempotency: ledger, clock: () => now);
      final receipt = await recovery.compensate('edit');
      expect(await File('${root.path}/maps/field.json').readAsString(),
          '{"value":1}');
      expect(
          mapEditReceiptDisposition(receipt, _binding(plan, unchanged: false)),
          'compensated');
      final found = await FileIdempotencyStore(filePath: ledgerPath)
          .lookupOperation(
              actorId: 'actor',
              projectId: 'project',
              operationId: 'edit',
              now: now,
              targetedOnly: true);
      expect(
          mapEditReceiptDisposition(
              found!.completed!.receipt!, _binding(plan, unchanged: false)),
          'compensated');
    });

    test(
        'map edits require explicit pending index preparation before any intent',
        () async {
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      final index = File(
          '${root.path}/.pokemap/authoring/transactions/pending-journals.json');
      await index.delete();
      final plan = _plan(now);
      plan.bindMapEdit(_binding(plan, unchanged: true));
      final transaction = JournaledAuthoringTransaction(
          plans: AuthoringPlanStore(clock: () => now)..save(plan),
          gateway: gateway,
          idempotency: AuthoringIdempotencyLedger(
              store: FileIdempotencyStore(filePath: ledgerPath),
              clock: () => now),
          clock: () => now);
      await expectLater(
          transaction.apply(
              planId: plan.planId,
              request: plan.request,
              currentProjectRevision: plan.baseRevision,
              scope: _scope(),
              operationId: 'edit'),
          throwsA(isA<TransactionFileGatewayException>().having(
              (error) => error.code,
              'code',
              'transaction.pending_index_preparation_required')));
      expect(await gateway.readJournal('edit'), isNull);
      expect(await File(ledgerPath).exists(), isFalse);
      expect(await index.exists(), isFalse);
      await gateway.preparePendingJournalIndex();
      expect(
          (await transaction.apply(
                  planId: plan.planId,
                  request: plan.request,
                  currentProjectRevision: plan.baseRevision,
                  scope: _scope(),
                  operationId: 'edit'))
              .status,
          AuthoringReceiptStatus.applied);
    });

    for (final changed in [false, true]) {
      for (final reserved in [false, true]) {
        test(
            'overlapping other operation blocks changed=$changed reserved=$reserved without reservation',
            () async {
          final gateway =
              await LocalTransactionFileGateway.open(projectRoot: root.path);
          final store = FileIdempotencyStore(filePath: ledgerPath);
          final foreign = _pendingJournal(now);
          await gateway.writeJournal(foreign);
          if (reserved) {
            await store.reserve(AuthoringIdempotencyRecord(
                scope: foreign.scope,
                payloadFingerprint: _revision,
                operationId: foreign.operationId,
                status: AuthoringIdempotencyStatus.pending,
                createdAt: now));
          }
          final plan = _plan(now, changed: changed);
          plan.bindMapEdit(_binding(plan, unchanged: !changed));
          final transaction = JournaledAuthoringTransaction(
              plans: AuthoringPlanStore(clock: () => now)..save(plan),
              gateway: gateway,
              idempotency:
                  AuthoringIdempotencyLedger(store: store, clock: () => now),
              clock: () => now);
          await expectLater(
              transaction.apply(
                  planId: plan.planId,
                  request: plan.request,
                  currentProjectRevision: plan.baseRevision,
                  scope: _scope(),
                  operationId: 'edit'),
              throwsA(isA<JournaledAuthoringTransactionException>().having(
                  (error) => error.code,
                  'code',
                  'map_edit.overlapping_recovery_required')));
          expect(await store.read(_scope()), isNull);
          expect(await gateway.readJournal('edit'), isNull);
          expect(await File('${root.path}/maps/field.json').readAsString(),
              '{"value":1}');
          expect((await gateway.readJournal(foreign.operationId))!.toJson(),
              foreign.toJson());
        });
      }
    }

    test(
        'no-op checks selected read dependencies against foreign pending writes',
        () async {
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      await gateway.writeJournal(_pendingJournal(now,
          mapId: 'other', storageKey: 'data/materials.json'));
      final store = FileIdempotencyStore(filePath: ledgerPath);
      final plan = _plan(now);
      plan.bindMapEdit(_binding(plan, unchanged: true),
          readStorageKeys: ['data/materials.json']);
      final transaction = JournaledAuthoringTransaction(
          plans: AuthoringPlanStore(clock: () => now)..save(plan),
          gateway: gateway,
          idempotency:
              AuthoringIdempotencyLedger(store: store, clock: () => now),
          clock: () => now);
      await expectLater(
          transaction.apply(
              planId: plan.planId,
              request: plan.request,
              currentProjectRevision: plan.baseRevision,
              scope: _scope(),
              operationId: 'edit'),
          throwsA(isA<JournaledAuthoringTransactionException>().having(
              (error) => error.code,
              'code',
              'map_edit.overlapping_recovery_required')));
      expect(await store.read(_scope()), isNull);
    });

    test('unrelated pending map does not block the selected map', () async {
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      final foreign =
          _pendingJournal(now, mapId: 'other', storageKey: 'maps/other.json');
      await gateway.writeJournal(foreign);
      final plan = _plan(now);
      plan.bindMapEdit(_binding(plan, unchanged: true));
      final transaction = JournaledAuthoringTransaction(
          plans: AuthoringPlanStore(clock: () => now)..save(plan),
          gateway: gateway,
          idempotency: AuthoringIdempotencyLedger(
              store: FileIdempotencyStore(filePath: ledgerPath),
              clock: () => now),
          clock: () => now);
      final receipt = await transaction.apply(
          planId: plan.planId,
          request: plan.request,
          currentProjectRevision: plan.baseRevision,
          scope: _scope(),
          operationId: 'edit');
      expect(receipt.receiptId, plan.receiptId);
      expect((await gateway.readJournal(foreign.operationId))!.toJson(),
          foreign.toJson());
    });

    test(
        'unchanged result survives reopen and external edit without map or history write',
        () async {
      final plans = AuthoringPlanStore(clock: () => now);
      final plan = _plan(now);
      plan.bindMapEdit(_binding(plan, unchanged: true));
      plans.save(plan);
      final store = FileIdempotencyStore(filePath: ledgerPath);
      final transaction = JournaledAuthoringTransaction(
          plans: plans,
          gateway:
              await LocalTransactionFileGateway.open(projectRoot: root.path),
          idempotency:
              AuthoringIdempotencyLedger(store: store, clock: () => now),
          clock: () => now,
          commitHook: _RejectHistory());
      final map = File('${root.path}/maps/field.json');
      final modified = (await map.stat()).modified;
      final receipt = await transaction.apply(
          planId: plan.planId,
          request: plan.request,
          currentProjectRevision: plan.baseRevision,
          scope: _scope(),
          operationId: 'edit');
      expect((await map.stat()).modified, modified);
      expect(receipt.extensions['mapEdit'],
          _binding(plan, unchanged: true).toJson());
      await map.writeAsString('{"value":2}');
      final externalModified = (await map.stat()).modified;
      final reopened = FileIdempotencyStore(
          filePath: ledgerPath,
          onFullRead: () => fail('must not read global ledger'));
      final found = await reopened.lookupOperation(
          actorId: 'actor',
          projectId: 'project',
          operationId: 'edit',
          now: now,
          targetedOnly: true);
      expect(found!.completed!.receipt!.toJson(), receipt.toJson());
      expect(await map.readAsString(), '{"value":2}');
      expect((await map.stat()).modified, externalModified);
      expect(
          await Directory('${root.path}/.pokemap/authoring/history').exists(),
          isFalse);
    });

    test(
        'typed binding is persisted before reservation and rejects unbound empty journal',
        () async {
      final plan = _plan(now);
      final plans = AuthoringPlanStore(clock: () => now)..save(plan);
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      final store = FileIdempotencyStore(filePath: ledgerPath);
      final transaction = JournaledAuthoringTransaction(
          plans: plans,
          gateway: gateway,
          idempotency:
              AuthoringIdempotencyLedger(store: store, clock: () => now),
          clock: () => now,
          faultInjector: (context) {
            if (context.checkpoint ==
                AuthoringTransactionCheckpoint.afterJournalPreparing) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      await expectLater(
          transaction.apply(
              planId: plan.planId,
              request: plan.request,
              currentProjectRevision: plan.baseRevision,
              scope: _scope(),
              operationId: 'edit'),
          throwsArgumentError);
      expect(await gateway.readJournal('edit'), isNull);
      plan.bindMapEdit(_binding(plan, unchanged: true));
      await expectLater(
          transaction.apply(
              planId: plan.planId,
              request: plan.request,
              currentProjectRevision: plan.baseRevision,
              scope: _scope(),
              operationId: 'edit'),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      final journal = await gateway.readJournal('edit');
      expect(journal!.entries, isEmpty);
      expect(journal.intendedReceipt.extensions['mapEdit'],
          _binding(plan, unchanged: true).toJson());
      expect(await store.read(_scope()), isNull);
      expect(
          AuthoringTransactionJournal.fromJson(
                  jsonDecode(jsonEncode(journal.toJson()))
                      as Map<String, dynamic>)
              .toJson(),
          journal.toJson());
    });

    test(
        'expired batch identity stays recognized after scoped ledger maintenance',
        () async {
      final plan = _plan(now);
      plan.bindMapEdit(_binding(plan, unchanged: true));
      final store = FileIdempotencyStore(filePath: ledgerPath);
      final transaction = JournaledAuthoringTransaction(
          plans: AuthoringPlanStore(clock: () => now)..save(plan),
          gateway:
              await LocalTransactionFileGateway.open(projectRoot: root.path),
          idempotency:
              AuthoringIdempotencyLedger(store: store, clock: () => now),
          clock: () => now);
      await transaction.apply(
          planId: plan.planId,
          request: plan.request,
          currentProjectRevision: plan.baseRevision,
          scope: _scope(),
          operationId: 'edit');
      final expiredAt = now.add(const Duration(days: 31));
      final targeted = await FileIdempotencyStore.forScope(
          filePath: ledgerPath, scope: _scope());
      expect(await targeted.pruneExpired(expiredAt), 1);
      final reopened = FileIdempotencyStore(filePath: ledgerPath);
      final expired = await reopened.lookupOperation(
          actorId: 'actor',
          projectId: 'project',
          operationId: 'edit',
          now: expiredAt,
          targetedOnly: true);
      expect(expired, isNotNull);
      expect(expired!.expired, isTrue);
      expect(expired.completed, isNull);
    });

    for (final checkpoint in [
      AuthoringTransactionCheckpoint.afterReservation,
      AuthoringTransactionCheckpoint.afterJournalCommitted
    ]) {
      test(
          'no-op recovery after $checkpoint preserves its binding without history',
          () async {
        final plan = _plan(now);
        plan.bindMapEdit(_binding(plan, unchanged: true));
        final gateway =
            await LocalTransactionFileGateway.open(projectRoot: root.path);
        final store = FileIdempotencyStore(filePath: ledgerPath);
        final ledger =
            AuthoringIdempotencyLedger(store: store, clock: () => now);
        final transaction = JournaledAuthoringTransaction(
            plans: AuthoringPlanStore(clock: () => now)..save(plan),
            gateway: gateway,
            idempotency: ledger,
            clock: () => now,
            faultInjector: (context) {
              if (context.checkpoint == checkpoint) {
                throw const AuthoringTransactionSimulatedCrash();
              }
            });
        await expectLater(
            transaction.apply(
                planId: plan.planId,
                request: plan.request,
                currentProjectRevision: plan.baseRevision,
                scope: _scope(),
                operationId: 'edit'),
            throwsA(isA<AuthoringTransactionSimulatedCrash>()));
        final recovery = AuthoringRecoveryService(
            gateway: gateway,
            idempotency: ledger,
            clock: () => now,
            commitHook: _RejectHistory());
        final expectedReceipt =
            (await gateway.readJournal('edit'))!.intendedReceipt;
        final receipt = await recovery.resume('edit');
        expect(receipt.toJson(), expectedReceipt.toJson());
        expect(receipt.extensions['mapEdit'],
            _binding(plan, unchanged: true).toJson());
        expect(
            (await store.lookupOperation(
                    actorId: 'actor',
                    projectId: 'project',
                    operationId: 'edit',
                    now: now,
                    targetedOnly: true))!
                .completed!
                .receipt!
                .receiptId,
            receipt.receiptId);
      });
    }
  });
}

const _revision =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
MapEditOperation _operation({int seed = 0}) => MapEditOperation(
        operationId: 'edit',
        mapId: 'field',
        seed: seed,
        operations: const [
          {
            'actionId': 'smart_tile.cell.erase',
            'actionVersion': 1,
            'parameters': {'layerId': 'ground', 'x': 2, 'y': 3}
          }
        ]);
AuthoringRequest _request() => AuthoringRequest(
        requestId: 'request',
        actionId: 'map3d.edit_batch',
        actionVersion: 1,
        workspaceHandle: 'workspace',
        parameters: _operation().toBatchParameters(),
        expectedRevision: _revision,
        idempotencyKey: 'edit:attempt:0',
        extensions: {
          'mapEdit': {'forged': true}
        });
AuthoringPlan _plan(DateTime now, {bool changed = false}) => AuthoringPlan(
    planId: 'plan',
    receiptId: 'receipt',
    request: _request(),
    baseRevision: _revision,
    seed: 0,
    createdAt: now,
    expiresAt: now.add(const Duration(minutes: 1)),
    changeSet: changed ? _changedSet() : AuthoringChangeSet.noChanges());
MapEditBinding _binding(AuthoringPlan plan, {required bool unchanged}) =>
    MapEditBinding(
        operationId: 'edit',
        fingerprint: _operation().semanticFingerprint,
        mapId: 'field',
        seed: 0,
        snapshotRevision: _revision,
        unchanged: unchanged);
AuthoringIdempotencyScope _scope() => AuthoringIdempotencyScope(
    actorId: 'actor',
    projectId: 'project',
    actionId: 'map3d.edit_batch',
    actionVersion: 1,
    key: 'edit:attempt:0');

final class _RejectHistory implements AuthoringTransactionCommitHook {
  @override
  Future<void> record(AuthoringCommittedMutation mutation) async =>
      fail('no-op must not write history');
}

AuthoringChangeSet _changedSet(
    {String mapId = 'field', String storageKey = 'maps/field.json'}) {
  final resource = AuthoringResourceRef(kind: 'map', id: mapId);
  return AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
            resource: resource,
            storageKey: storageKey,
            beforeBytes: utf8.encode('{"value":1}'),
            afterBytes: utf8.encode('{"value":2}'))
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/value',
            before: 1,
            after: 2)
      ]));
}

AuthoringTransactionJournal _pendingJournal(DateTime now,
    {String mapId = 'field', String storageKey = 'maps/field.json'}) {
  final changes = _changedSet(mapId: mapId, storageKey: storageKey);
  final scope = AuthoringIdempotencyScope(
      actorId: 'other-actor',
      projectId: 'project',
      actionId: 'fixture.edit',
      actionVersion: 1,
      key: 'other');
  final receipt = AuthoringReceipt(
      receiptId: 'foreign-receipt',
      requestId: 'foreign-request',
      actionId: scope.actionId,
      actionVersion: scope.actionVersion,
      status: AuthoringReceiptStatus.applied,
      beforeRevision: AuthoringRevisionSet.beforeChangeSet(changes).fingerprint,
      afterRevision: AuthoringRevisionSet.afterChangeSet(changes).fingerprint,
      createdAtUtc: now.toIso8601String(),
      diff: changes.diff,
      extensions: {'planId': 'foreign-plan', 'operationId': 'other-operation'});
  return AuthoringTransactionJournal(
      operationId: 'other-operation',
      planId: 'foreign-plan',
      scope: scope,
      status: AuthoringTransactionStatus.preparing,
      createdAt: now,
      updatedAt: now,
      intendedReceipt: receipt,
      entries: [
        for (final change in changes.changes)
          AuthoringTransactionJournalEntry(
              resource: change.resource,
              storageKey: change.storageKey,
              beforeRevision: change.beforeRevision,
              afterRevision: change.afterRevision)
      ]);
}
