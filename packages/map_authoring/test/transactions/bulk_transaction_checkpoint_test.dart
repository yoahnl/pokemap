import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:map_authoring/src/security/resource_pack_bulk_capability.dart';
import 'package:test/test.dart';

void main() {
  for (final count in [100, 1000, 10000]) {
    for (final outcome in ['apply', 'resume', 'compensate']) {
      test('$outcome $count changes writes a linear phase journal', () async {
        final fixture = BulkTransactionFixture(count);
        addTearDown(fixture.plans.dispose);
        fixture.certify();
        final stop = count ~/ 2;
        final transaction = fixture.transaction(
          faultInjector: outcome == 'apply'
              ? null
              : (context) {
                  if (context.checkpoint ==
                          AuthoringTransactionCheckpoint
                              .afterResourcePromoted &&
                      context.promotionIndex == stop) {
                    throw const AuthoringTransactionSimulatedCrash();
                  }
                },
        );
        if (outcome == 'apply') {
          await fixture.apply(transaction);
        } else {
          await expectLater(fixture.apply(transaction),
              throwsA(isA<AuthoringTransactionSimulatedCrash>()));
          final recovery = fixture.recovery();
          if (outcome == 'resume') {
            await recovery.resume(fixture.operationId);
          } else {
            await recovery.compensate(fixture.operationId);
          }
        }
        print(jsonEncode({
          'outcome': outcome,
          'resources': count,
          'journalWrites': fixture.gateway.journalWrites,
          'journalBytes': fixture.gateway.journalBytes
        }));
        expect(fixture.gateway.journalWrites, lessThanOrEqualTo(8));
        expect(fixture.gateway.journalBytes, lessThan(count * 30000));
        expect(fixture.gateway.promotions,
            outcome == 'compensate' ? 2 * (stop + 1) : count);
        for (final change in fixture.plan.changeSet.changes) {
          expect(await fixture.gateway.readResourceRevision(change.storageKey),
              outcome == 'compensate' ? null : change.afterRevision);
        }
      });
    }
  }

  for (final checkpoint in [
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    AuthoringTransactionCheckpoint.afterResourcePromoted,
  ]) {
    for (var index = 0; index < 4; index++) {
      test('phase-only crash $checkpoint at $index recovers exact intent',
          () async {
        final fixture = BulkTransactionFixture(4);
        addTearDown(fixture.plans.dispose);
        fixture.certify();
        await expectLater(
            fixture.apply(fixture.transaction(faultInjector: (context) {
          if (context.checkpoint == checkpoint &&
              context.promotionIndex == index) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        })), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
        final journal = await fixture.gateway.readJournal(fixture.operationId);
        expect(journal!.entries.every((entry) => !entry.promoted), isTrue);
        final recovered = await fixture.recovery().resume(fixture.operationId);
        expect(recovered.diff.toJson(), fixture.plan.changeSet.diff.toJson());
        expect(fixture.gateway.promotions, 4);
      });
    }
  }

  test('ordinary transaction retains its resource checkpoints', () async {
    final fixture = BulkTransactionFixture(4);
    addTearDown(fixture.plans.dispose);
    await fixture.apply(fixture.transaction());
    expect(fixture.gateway.journalWrites, 9);
  });

  for (final recovery in [false, true]) {
    test(
        'bulk second CAS rejects an external edit before promotion recovery=$recovery',
        () async {
      final fixture = BulkTransactionFixture(4);
      addTearDown(fixture.plans.dispose);
      fixture.certify();
      if (recovery) {
        await expectLater(
            fixture.apply(fixture.transaction(faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterReservation) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        })), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      }
      fixture.gateway.beforePromotion = (storageKey, kind) async {
        fixture.gateway.files[storageKey] = [99];
      };
      await expectLater(
          recovery
              ? fixture.recovery().resume(fixture.operationId)
              : fixture.apply(fixture.transaction()),
          throwsA(isA<TransactionFileGatewayException>()));
      expect(fixture.gateway.promotions, 0);
    });
  }

  test('journal schema and capability counts fail strict reconstruction',
      () async {
    final fixture = BulkTransactionFixture(4);
    addTearDown(fixture.plans.dispose);
    fixture.certify();
    await expectLater(
        fixture.apply(fixture.transaction(faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterReservation) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    })), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    final json = fixture.gateway.journalJson!;
    expect(
        () =>
            AuthoringTransactionJournal.fromJson({...json, 'schemaVersion': 1}),
        throwsFormatException);
    expect(
        () => AuthoringTransactionJournal.fromJson(
            {...json, 'checkpointProfile': 'perResource'}),
        throwsFormatException);
    expect(
        () => AuthoringTransactionJournal.fromJson(
            {...json, 'bulkCapability': 7}),
        throwsFormatException);
    final capability = Map<String, dynamic>.from(json['bulkCapability'] as Map);
    expect(
        () => AuthoringTransactionJournal.fromJson({
              ...json,
              'bulkCapability': {...capability, 'logicalOutputCount': 9999}
            }),
        throwsFormatException);
    expect(
        () => AuthoringTransactionJournal.fromJson({
              ...json,
              'bulkCapability': {...capability, 'actionVersion': 2}
            }),
        throwsFormatException);
  });

  test('bulk recovery refuses a third hash', () async {
    final fixture = BulkTransactionFixture(4);
    addTearDown(fixture.plans.dispose);
    fixture.certify();
    await expectLater(
        fixture.apply(fixture.transaction(faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterReservation) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    })), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    fixture.gateway.files['resources/000000.json'] = [99];
    await expectLater(fixture.recovery().resume(fixture.operationId),
        throwsA(isA<AuthoringRecoveryException>()));
    await expectLater(fixture.recovery().compensate(fixture.operationId),
        throwsA(isA<AuthoringRecoveryException>()));
    expect(fixture.gateway.promotions, 0);
  });
}

final class BulkTransactionFixture {
  BulkTransactionFixture(int count,
      {String actionId = 'resource_pack.import',
      Map<String, Object?> extensions = const {}}) {
    final changes = [
      for (var i = 0; i < count; i++)
        AuthoringResourceChange(
          resource: AuthoringResourceRef(kind: 'element', id: 'item_$i'),
          storageKey: 'resources/${i.toString().padLeft(6, '0')}.json',
          beforeBytes: null,
          afterBytes: utf8.encode('{"index":$i}'),
        )
    ];
    plan = AuthoringPlan(
      planId: 'plan_bulk',
      receiptId: 'receipt_bulk',
      request: AuthoringRequest(
          requestId: 'request_bulk',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: 'workspace_bulk',
          expectedRevision: revision,
          idempotencyKey: 'key_bulk',
          extensions: extensions),
      baseRevision: revision,
      seed: 1,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 10)),
      changeSet: AuthoringChangeSet(
          changes: changes,
          diff: AuthoringDiff([
            for (final change in changes)
              AuthoringDiffEntry(
                  operation: AuthoringDiffOperation.add,
                  resource: change.resource,
                  path: r'$',
                  after: change.afterRevision)
          ])),
    );
    plans.save(plan);
    scope = AuthoringIdempotencyScope(
        actorId: 'actor_bulk',
        projectId: 'project_bulk',
        actionId: actionId,
        actionVersion: 1,
        key: 'key_bulk');
  }
  static final now = DateTime.utc(2026, 10, 17);
  static final revision = 'sha256:${List.filled(64, '0').join()}';
  final operationId = 'operation_bulk';
  late final AuthoringPlan plan;
  late final AuthoringIdempotencyScope scope;
  final gateway = CountingBulkGateway();
  final plans = AuthoringPlanStore(clock: () => now);
  final ledger = AuthoringIdempotencyLedger(
      store: BulkMemoryIdempotencyStore(), clock: () => now);

  ResourcePackBulkCapability certify() {
    final capability = ResourcePackBulkAuthority.certifyImport(
        plan: plan,
        actorId: scope.actorId,
        projectId: scope.projectId,
        operationId: operationId,
        logicalStorageKeys:
            plan.changeSet.changes.map((change) => change.storageKey),
        contentBlobStorageKeys: const []);
    plan.bindBulkCapability(capability);
    return capability;
  }

  JournaledAuthoringTransaction transaction(
          {AuthoringTransactionFaultInjector? faultInjector}) =>
      JournaledAuthoringTransaction(
          plans: plans,
          gateway: gateway,
          idempotency: ledger,
          clock: () => now,
          faultInjector: faultInjector);

  Future<AuthoringReceipt> apply(JournaledAuthoringTransaction transaction) =>
      transaction.apply(
          planId: plan.planId,
          request: plan.request,
          currentProjectRevision: revision,
          scope: scope,
          operationId: operationId);

  AuthoringRecoveryService recovery() => AuthoringRecoveryService(
      gateway: gateway, idempotency: ledger, clock: () => now);
}

final class CountingBulkGateway
    implements TransactionFileGateway, StreamingTransactionFileGateway {
  final files = <String, List<int>>{};
  final stages = <String, List<int>?>{};
  Map<String, dynamic>? journalJson;
  int journalWrites = 0;
  int journalBytes = 0;
  int promotions = 0;
  int maxJournalWrites = 12;
  Future<void> Function(String, TransactionPayloadKind)? beforePromotion;

  @override
  Future<AuthoringPayload?> captureResourcePayload(String storageKey) async {
    final bytes = files[storageKey];
    return bytes == null
        ? null
        : AuthoringPayload.inline(bytes, storageKey: storageKey);
  }

  @override
  Future<void> stageAuthoringPayload(
      {required String operationId,
      required String storageKey,
      required TransactionPayloadKind kind,
      required AuthoringPayload? payload}) async {
    await stagePayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
        bytes: await payload?.readBytes());
  }

  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) =>
      operation();
  @override
  Future<List<int>?> readResource(String storageKey) async => files[storageKey];
  @override
  Future<String?> readResourceRevision(String storageKey) async =>
      files[storageKey] == null
          ? null
          : computeAuthoringBytesFingerprint(files[storageKey]!,
              logicalName: storageKey);
  @override
  Future<void> stagePayload(
      {required String operationId,
      required String storageKey,
      required TransactionPayloadKind kind,
      required List<int>? bytes}) async {
    stages['$storageKey:${kind.name}'] = bytes;
  }

  @override
  Future<TransactionStagedPayload> readStagedPayload(
          {required String operationId,
          required String storageKey,
          required TransactionPayloadKind kind}) async =>
      TransactionStagedPayload(
          storageKey: storageKey, bytes: stages['$storageKey:${kind.name}']);
  @override
  Future<void> promoteStaged(
      {required String operationId,
      required String storageKey,
      required TransactionPayloadKind kind,
      required String? expectedCurrentRevision}) async {
    await beforePromotion?.call(storageKey, kind);
    if (await readResourceRevision(storageKey) != expectedCurrentRevision) {
      throw const TransactionFileGatewayException(
          'transaction.revision_conflict', 'CAS');
    }
    promotions++;
    final bytes = stages['$storageKey:${kind.name}'];
    if (bytes == null) {
      files.remove(storageKey);
    } else {
      files[storageKey] = bytes;
    }
  }

  @override
  Future<void> writeJournal(AuthoringTransactionJournal journal) async {
    journalWrites++;
    if (journalWrites > maxJournalWrites) {
      throw TestFailure(
          'Quadratic journal aborted after $journalWrites writes.');
    }
    final encoded = utf8.encode(jsonEncode(journal.toJson()));
    journalBytes += encoded.length;
    journalJson = jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;
  }

  @override
  Future<AuthoringTransactionJournal?> readJournal(String operationId) async =>
      journalJson == null
          ? null
          : AuthoringTransactionJournal.fromJson(journalJson!);
  @override
  Future<List<AuthoringTransactionJournal>> listJournals() async => [
        if (journalJson != null)
          AuthoringTransactionJournal.fromJson(journalJson!)
      ];
  @override
  Future<void> deleteTransaction(String operationId) async {
    journalJson = null;
  }
}

final class BulkMemoryIdempotencyStore implements IdempotencyStore {
  final records = <String, AuthoringIdempotencyRecord>{};
  @override
  Future<AuthoringIdempotencyRecord?> read(
          AuthoringIdempotencyScope scope) async =>
      records[scope.storageKey];
  @override
  Future<AuthoringIdempotencyReservation> reserve(
      AuthoringIdempotencyRecord record) async {
    final existing = records[record.scope.storageKey];
    records.putIfAbsent(record.scope.storageKey, () => record);
    return AuthoringIdempotencyReservation(
        acquired: existing == null, record: existing ?? record);
  }

  @override
  Future<AuthoringIdempotencyRecord> complete(
      AuthoringIdempotencyRecord record) async {
    records[record.scope.storageKey] = record;
    return record;
  }

  @override
  Future<int> pruneExpired(DateTime now) async => 0;
}
