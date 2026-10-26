import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  for (final budget in [1000, 20000]) {
    test('generic transaction checks $budget byte undo budget before staging',
        () async {
      final task = Directory(
          '/Users/karim/Library/Caches/AveluneQA/studio-project-lifecycle/transaction-preflight-tests');
      await task.create(recursive: true);
      final project = await task.createTemp('fixture-');
      addTearDown(() => project.delete(recursive: true));
      await Directory('${project.path}/data').create();
      final file = File('${project.path}/data/document.json');
      final before = utf8.encode('{"value":"before"}');
      await file.writeAsBytes(before);
      final history = await FileAuthoringHistoryStore.open(
          projectRoot: project.path, incrementalWrites: true);
      await history.expireEntries(
          projectId: 'game', entryFingerprints: {}, maxBytes: budget);
      final blobs =
          await FileAuthoringContentBlobStore.open(projectRoot: project.path);
      final now = DateTime.utc(2026, 10, 26);
      final request = AuthoringRequest(
          requestId: 'request',
          actionId: 'fixture.sidecar',
          actionVersion: 1,
          workspaceHandle: 'workspace',
          idempotencyKey: 'budget');
      final resource = AuthoringResourceRef(kind: 'fixture', id: 'document');
      final plan = AuthoringPlan(
          planId: 'plan',
          receiptId: 'receipt_document_${'1' * 32}',
          request: request,
          baseRevision: 'sha256:${'0' * 64}',
          seed: 0,
          createdAt: now,
          expiresAt: now.add(const Duration(minutes: 10)),
          changeSet: AuthoringChangeSet(
              changes: [
                AuthoringResourceChange(
                    resource: resource,
                    storageKey: 'data/document.json',
                    beforeBytes: before,
                    afterBytes: utf8.encode(jsonEncode({'value': 'x' * 4000})))
              ],
              diff: AuthoringDiff([
                AuthoringDiffEntry(
                    operation: AuthoringDiffOperation.replace,
                    resource: resource,
                    path: r'$',
                    before: 'before',
                    after: 'after')
              ])));
      final plans = AuthoringPlanStore(clock: () => now)..save(plan);
      final scope = AuthoringIdempotencyScope(
          actorId: 'editor',
          projectId: 'game',
          actionId: request.actionId,
          actionVersion: 1,
          key: 'budget');
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: project.path);
      final ledger = AuthoringIdempotencyLedger(
          store: FileIdempotencyStore(
              filePath: '${project.path}/.pokemap/authoring/idempotency.jsonl'),
          clock: () => now);
      var checkpoints = 0;
      final transaction = JournaledAuthoringTransaction(
          plans: plans,
          gateway: gateway,
          idempotency: ledger,
          clock: () => now,
          commitHook: AuthoringHistoryRecorder(store: history, blobs: blobs),
          faultInjector: (_) => checkpoints++);
      Future<AuthoringReceipt> apply() => transaction.apply(
          planId: plan.planId,
          request: request,
          currentProjectRevision: plan.baseRevision,
          scope: scope,
          operationId: 'operation');
      if (budget == 1000) {
        await expectLater(
            apply(),
            throwsA(isA<AuthoringHistoryException>().having(
                (error) => error.code,
                'code',
                'history.operation_exceeds_budget')));
        expect(await file.readAsBytes(), before);
        expect(await gateway.listJournals(), isEmpty);
        expect(await ledger.recordForRecovery(scope), isNull);
        expect(await blobs.listIds(), isEmpty);
        expect(checkpoints, 0);
        expect((await history.localWindow('game'))!.entryIds, isEmpty);
      } else {
        final receipt = await apply();
        final checkpointCount = checkpoints;
        expect((await apply()).toJson(), receipt.toJson());
        expect(checkpoints, checkpointCount);
        expect(checkpoints, greaterThan(0));
        expect((jsonDecode(await file.readAsString()) as Map)['value'],
            'x' * 4000);
        expect(await gateway.listJournals(), isEmpty);
        expect((await ledger.recordForRecovery(scope))!.status,
            AuthoringIdempotencyStatus.completed);
        expect(
            (await history.localWindow('game'))!.entryIds, [receipt.receiptId]);
        expect((await history.localWindow('game'))!.logicalBytes,
            lessThanOrEqualTo(budget));
      }
    });
  }
}
