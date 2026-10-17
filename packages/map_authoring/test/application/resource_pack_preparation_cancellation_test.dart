import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/security/resource_pack_bulk_capability.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:test/test.dart';

import '../transactions/bulk_transaction_checkpoint_test.dart';

void main() {
  test('cancel during canonical chunk staging cleans unreserved intent and borrows payload ownership', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    var staging = false;
    var chunks = 0;
    var releases = 0;
    Stream<List<int>> source() async* {
      for (var i = 0; i < 3; i++) {
        if (staging && i == 1) {
          entered.complete();
          await release.future;
        }
        if (staging) chunks++;
        yield List.filled(64 * 1024, i);
      }
    }

    final bytes = [for (var i = 0; i < 3; i++) ...List.filled(64 * 1024, i)];
    final payload = await AuthoringPayload.verifiedSource(
      storageKey: 'assets/chunk.bin',
      byteLength: bytes.length,
      rawSha256: sha256.convert(bytes).toString(),
      openRead: source,
      release: () async {
        releases++;
      },
    );
    final fixture = BulkTransactionFixture(1);
    final plan = AuthoringPlan(
      planId: 'chunk-plan',
      receiptId: 'chunk-receipt',
      request: fixture.plan.request,
      baseRevision: fixture.plan.baseRevision,
      seed: 1,
      createdAt: BulkTransactionFixture.now,
      expiresAt: fixture.plan.expiresAt,
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange.withPayloads(
            resource: AuthoringResourceRef(kind: 'asset', id: 'chunk'),
            storageKey: payload.storageKey,
            beforePayload: null,
            afterPayload: payload,
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: AuthoringResourceRef(kind: 'asset', id: 'chunk'),
            path: r'$',
            after: payload.resourceRevision,
          ),
        ]),
      ),
    );
    plan.bindBulkCapability(
      ResourcePackBulkAuthority.certifyImport(
        plan: plan,
        actorId: fixture.scope.actorId,
        projectId: fixture.scope.projectId,
        operationId: fixture.operationId,
        logicalStorageKeys: [payload.storageKey],
        contentBlobStorageKeys: [],
      ),
    );
    fixture.plans.save(plan);
    final jobs = ResourcePackJobService(requireActive: () {});
    try {
      staging = true;
      final started = await jobs.startWork(
        AuthoringJobRequest(
          requestId: 'chunk',
          kind: 'resource_pack.import',
          projectId: fixture.scope.projectId,
          projectRevision: fixture.plan.baseRevision,
        ),
        (context) async {
          final receipt = await fixture.transaction().apply(
            planId: plan.planId,
            request: plan.request,
            currentProjectRevision: fixture.plan.baseRevision,
            scope: fixture.scope,
            operationId: fixture.operationId,
            beforeReservation: context.enterFinalization,
            preparationCheck: context.checkCancelled,
          );
          return {'receipt': receipt.toJson()};
        },
      );
      await entered.future.timeout(Duration(seconds: 10));
      expect((await jobs.get(started.jobId)).state, AuthoringJobState.running);
      expect(
        (await jobs.cancel(
          started.jobId,
          timeout: Duration(seconds: 1),
        )).bounded,
        false,
      );
      release.complete();
      final terminal = await jobs.close();
      expect(terminal.single.state, AuthoringJobState.cancelled);
      expect(chunks, 2);
      expect(fixture.gateway.promotions, 0);
      expect(fixture.gateway.journalJson, isNull);
      expect(releases, 0);
      expect(plan.changeSet.changes.single.afterPayload, same(payload));
      await plan.releasePayloads();
      expect(releases, 1);
    } finally {
      if (!release.isCompleted) release.complete();
      await jobs.close();
      await fixture.plans.dispose();
    }
  });
}
