import 'dart:async';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';
import 'resource_pack_transfer_api_test.dart' show waitForJob;

void main() {
  test('a pending bulk transaction blocks a preexisting ordinary plan from another project handle', () async {
    var promotions = 0;
    final fixture = await NativeResourcePackImportFixture.create(
      faultInjector: (checkpoint) {
        if (checkpoint.checkpoint ==
            AuthoringTransactionCheckpoint.afterResourcePromoted) {
          promotions++;
          throw const AuthoringTransactionSimulatedCrash();
        }
      },
    );
    final api = LocalResourcePackTransferApi(
      mutations: fixture.mutations,
      snapshotLoader: fixture.loader,
    );
    final other = await fixture.readApi.openProject(fixture.root.path);
    try {
      await fixture.mutations.attachProject(
        projectRootPath: fixture.root.path,
        workspaceHandle: other.workspaceHandle,
        projectHandle: other.projectHandle,
      );
      final ordinary = await fixture.mutations.planMutation(
        other.projectHandle,
        AuthoringRequest(
          requestId: 'other',
          actionId: 'resource.family.create',
          actionVersion: 1,
          workspaceHandle: other.workspaceHandle.value,
          expectedRevision: (await fixture.loader.load(other.projectHandle))
              .revision,
          idempotencyKey: 'other',
          parameters: {'familyId': 'other', 'name': 'Other'},
        ),
      );
      final bulk = await fixture.plan(await fixture.prepare());
      final failed = await waitForJob(
        api,
        fixture.opened.projectHandle,
        await api.transfer(
          fixture.opened.projectHandle,
          verb: 'start_apply',
          input: {'planId': bulk.planId, 'operationId': 'pending-other'},
        ),
      );
      expect(failed['phase'], 'recoveryRequired');
      expect(promotions, 1);
      await expectLater(
        fixture.mutations.applyMutation(
          other.projectHandle,
          planId: ordinary.planId,
          operationId: 'other',
        ),
        throwsA(
          isA<AuthoringRecoveryException>().having(
            (e) => e.code,
            'code',
            'resource_pack.recovery_required',
          ),
        ),
      );
      expect(promotions, 1);
      await expectLater(
        fixture.mutations.planMutation(
          other.projectHandle,
          AuthoringRequest(
            requestId: 'later',
            actionId: 'resource.family.create',
            actionVersion: 1,
            workspaceHandle: other.workspaceHandle.value,
            expectedRevision: ordinary.plan.baseRevision,
            idempotencyKey: 'later',
            parameters: {'familyId': 'later', 'name': 'Later'},
          ),
        ),
        throwsA(isA<AuthoringRecoveryException>()),
      );
    } finally {
      await api.closeTransferWorkspace(other.workspaceHandle);
      await fixture.mutations.detachWorkspace(other.workspaceHandle);
      fixture.handles.closeWorkspace(other.workspaceHandle);
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  for (final reserved in [false, true]) {
    test(
      reserved
          ? 'cancel refuses after real durable reservation'
          : 'cancel wins immediately before real reservation',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        final fixture = await NativeResourcePackImportFixture.create(
          faultInjector: (checkpoint) async {
            if (checkpoint.checkpoint ==
                (reserved
                    ? AuthoringTransactionCheckpoint.afterReservation
                    : AuthoringTransactionCheckpoint.afterJournalStaged)) {
              entered.complete();
              await release.future;
            }
          },
        );
        final api = LocalResourcePackTransferApi(
          mutations: fixture.mutations,
          snapshotLoader: fixture.loader,
        );
        try {
          final prepared = await fixture.prepare();
          final plan = await fixture.plan(prepared);
          final before = await File('${fixture.root.path}/project.json')
              .readAsBytes();
          final started = await api.transfer(
            fixture.opened.projectHandle,
            verb: 'start_apply',
            input: {'planId': plan.planId, 'operationId': 'barrier-operation'},
          );
          await entered.future.timeout(Duration(seconds: 20));
          expect(
            ((await api.transfer(
                  fixture.opened.projectHandle,
                  verb: 'get',
                  input: {'jobId': started['jobId']},
                ))['snapshot']
                as Map)['state'],
            'running',
          );
          if (reserved) {
            await expectLater(
              api.transfer(
                fixture.opened.projectHandle,
                verb: 'cancel',
                input: {'jobId': started['jobId']},
              ),
              throwsA(
                isA<ResourcePackTransferException>().having(
                  (e) => e.details['cancelAllowed'],
                  'cancelAllowed',
                  false,
                ),
              ),
            );
          } else {
            final cancelled = await api.transfer(
              fixture.opened.projectHandle,
              verb: 'cancel',
              input: {'jobId': started['jobId']},
            );
            expect(cancelled['state'], 'cancelling');
          }
          release.complete();
          final settled = await waitForJob(
            api,
            fixture.opened.projectHandle,
            started,
          );
          expect(
            (settled['snapshot'] as Map)['state'],
            reserved ? 'succeeded' : 'cancelled',
            reason: settled.toString(),
          );
          if (!reserved) {
            expect(
              await File('${fixture.root.path}/project.json').readAsBytes(),
              before,
            );
          }
          expect(
            (await fixture.mutations.resourcePackPending(
              fixture.opened.projectHandle,
            )).where(
              (entry) =>
                  entry.disposition == AuthoringRecoveryDisposition.resumable,
            ),
            isEmpty,
          );
        } finally {
          if (!release.isCompleted) release.complete();
          await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
          await fixture.dispose();
        }
      },
    );
  }

  test('partial promotion reconstructs consultable recovery and readonly cannot resume', () async {
    var crash = true;
    final fixture = await NativeResourcePackImportFixture.create(
      faultInjector: (checkpoint) {
        if (crash &&
            checkpoint.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted &&
            checkpoint.promotionIndex == 1) {
          crash = false;
          throw const AuthoringTransactionSimulatedCrash();
        }
      },
    );
    var api = LocalResourcePackTransferApi(
      mutations: fixture.mutations,
      snapshotLoader: fixture.loader,
    );
    try {
      final prepared = await fixture.prepare();
      final planned = await fixture.plan(prepared);
      final started = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'start_apply',
        input: {'planId': planned.planId, 'operationId': 'recover-operation'},
      );
      final failed = await waitForJob(
        api,
        fixture.opened.projectHandle,
        started,
      );
      expect((failed['snapshot'] as Map)['state'], 'failed');
      expect(failed['phase'], 'recoveryRequired');
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.close();
      await fixture.open(actor: AuthoringActor(actorId: 'local_cli'));
      api = LocalResourcePackTransferApi(
        mutations: fixture.mutations,
        snapshotLoader: fixture.loader,
      );
      final pending = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'recovery_status',
      );
      expect(pending['recoveryRequired'], isTrue);
      final readonly = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'start_recovery',
        input: {'operationId': 'recover-operation'},
      );
      final denied = await waitForJob(
        api,
        fixture.opened.projectHandle,
        readonly,
      );
      expect(
        (denied['snapshot'] as Map)['errorCode'],
        'authorization.permission_denied',
      );
      expect(
        (await api.transfer(
          fixture.opened.projectHandle,
          verb: 'recovery_status',
        ))['recoveryRequired'],
        isTrue,
      );
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.close();
      await fixture.open();
      api = LocalResourcePackTransferApi(
        mutations: fixture.mutations,
        snapshotLoader: fixture.loader,
      );
      final recovery = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'start_recovery',
        input: {'operationId': 'recover-operation'},
      );
      final recovered = await waitForJob(
        api,
        fixture.opened.projectHandle,
        recovery,
      );
      expect(
        (recovered['snapshot'] as Map)['state'],
        'succeeded',
        reason: recovered.toString(),
      );
      expect(
        (await api.transfer(
          fixture.opened.projectHandle,
          verb: 'recovery_status',
        ))['recoveryRequired'],
        isFalse,
      );
      final replay = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'start_apply',
        input: {'planId': planned.planId, 'operationId': 'recover-operation'},
      );
      final replayed = await waitForJob(
        api,
        fixture.opened.projectHandle,
        replay,
      );
      expect(
        (replayed['snapshot'] as Map)['state'],
        'succeeded',
        reason: replayed.toString(),
      );
      expect(
        ((replayed['result'] as Map)['receipt'] as Map)['receiptId'],
        ((recovered['result'] as Map)['receipt'] as Map)['receiptId'],
      );
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });
}
