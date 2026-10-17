import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test(
      'rejected result cleanup is awaited before settlement and cannot retain an undisclosed owner',
      () async {
    final cleanupEntered = Completer<void>();
    final allowCleanup = Completer<void>();
    var ownsResult = true;
    var settled = false;
    final jobs = ResourcePackJobService(requireActive: () {});
    try {
      await jobs.startWork(
          AuthoringJobRequest(
              requestId: 'rejected',
              kind: 'resource_pack.prepare',
              projectId: 'p',
              projectRevision: 'sha256:${'0' * 64}'), (context) async {
        context.onResultRejected(() async {
          cleanupEntered.complete();
          await allowCleanup.future;
          ownsResult = false;
        });
        return {'unserializable': Object()};
      }, onSettled: () async {
        settled = true;
      });
      await cleanupEntered.future;
      var completed = false;
      final closing = jobs.close().then((value) {
        completed = true;
        return value;
      });
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(settled, isFalse);
      expect(ownsResult, isTrue);
      allowCleanup.complete();
      await closing;
      expect(ownsResult, isFalse);
      expect(settled, isTrue);
    } finally {
      if (!allowCleanup.isCompleted) allowCleanup.complete();
      await jobs.close();
    }
  });

  test(
      'rejected result cleanup failure preserves diagnostics and still releases job pins',
      () async {
    final jobs = ResourcePackJobService(requireActive: () {});
    var settled = false;
    final started = await jobs.startWork(
        AuthoringJobRequest(
            requestId: 'cleanup-failure',
            kind: 'resource_pack.export',
            projectId: 'p',
            projectRevision: 'sha256:${'0' * 64}'), (context) async {
      context.onResultRejected(() async {
        throw StateError('Cannot release owner');
      });
      return {'tooLarge': 'x' * (240 * 1024)};
    }, onSettled: () async {
      settled = true;
    });
    while (!settled) {
      await Future<void>.delayed(Duration.zero);
    }
    final result = jobs.result(started.jobId);
    expect((result['snapshot'] as Map)['state'], 'failed');
    expect((result['snapshot'] as Map)['errorCode'],
        'resource_pack.result_too_large');
    expect((result['result'] as Map)['cleanupDiagnostic'],
        {'code': 'resource_pack.cleanup_required'});
    expect(settled, isTrue);
    await jobs.close();
  });

  test('accepted result keeps its result owner and settles only the job pins',
      () async {
    final jobs = ResourcePackJobService(requireActive: () {});
    var discarded = false;
    var settled = false;
    final started = await jobs.startWork(
        AuthoringJobRequest(
            requestId: 'accepted',
            kind: 'resource_pack.license.stage',
            projectId: 'p',
            projectRevision: 'sha256:${'0' * 64}'), (context) async {
      context.onResultRejected(() async {
        discarded = true;
      });
      return {'licenseHandle': 'delivered'};
    }, onSettled: () async {
      settled = true;
    });
    while (!settled) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(
        (jobs.result(started.jobId)['snapshot'] as Map)['state'], 'succeeded');
    expect(discarded, isFalse);
    await jobs.close();
    expect(discarded, isFalse);
  });

  test(
      'licence staging uses a canonical dotted kind and queued cancellation settles cleanup',
      () async {
    final jobs = ResourcePackJobService(requireActive: () {});
    var entered = false;
    var cleaned = 0;
    final start = await jobs.startWork(
        AuthoringJobRequest(
            requestId: 'license',
            kind: 'resource_pack.license.stage',
            projectId: 'project',
            projectRevision: 'sha256:${'0' * 64}'), (job) async {
      entered = true;
      return {};
    }, onSettled: () async {
      cleaned++;
    });
    await jobs.cancel(start.jobId, timeout: const Duration(seconds: 1));
    final result = await jobs.close();
    expect(result.single.state, AuthoringJobState.cancelled);
    expect(entered, isFalse);
    expect(cleaned, 1);
  });

  test('a returned result cannot mutate canonical receipt data in a later poll',
      () async {
    final jobs = ResourcePackJobService(requireActive: () {});
    final started = await jobs.startWork(
        AuthoringJobRequest(
            requestId: 'immutable',
            kind: 'resource_pack.import',
            projectId: 'p',
            projectRevision: 'sha256:${'0' * 64}'),
        (context) async => {
              'receipt': {
                'receiptId': 'canonical',
                'resources': ['owned']
              }
            });
    while (!(await jobs.get(started.jobId)).state.isTerminal) {
      await Future<void>.delayed(Duration.zero);
    }
    final receipt = (jobs.result(started.jobId)['result'] as Map)['receipt'] as Map;
    expect(() => receipt['receiptId'] = 'forged', throwsUnsupportedError);
    expect(() => (receipt['resources'] as List).clear(), throwsUnsupportedError);
    final later = (jobs.result(started.jobId)['result'] as Map)['receipt'] as Map;
    expect(later['receiptId'], 'canonical');
    expect(later['resources'], ['owned']);
    await jobs.close();
  });
  test(
    'queued cancellation always releases the job pin without entering work',
    () async {
      final jobs = ResourcePackJobService(requireActive: () {});
      var entered = false;
      var released = false;
      final started = await jobs.startWork(
        AuthoringJobRequest(
          requestId: 'queued',
          kind: 'resource_pack.inspect',
          projectId: 'p',
          projectRevision: 'sha256:${'0' * 64}',
        ),
        (context) async {
          entered = true;
          return {};
        },
        onSettled: () async {
          released = true;
        },
      );
      await jobs.cancel(started.jobId, timeout: Duration(seconds: 1));
      final closed = await jobs.close();
      expect(closed.single.state, AuthoringJobState.cancelled);
      expect(entered, false);
      expect(released, true);
    },
  );
  test(
    'start returns while controlled work is suspended and cancellation wins',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final jobs = ResourcePackJobService(requireActive: () {});
      final started = await jobs.startWork(
        AuthoringJobRequest(
          requestId: 'r',
          kind: 'resource_pack.stage',
          projectId: 'p',
          projectRevision: 'sha256:${'0' * 64}',
        ),
        (context) async {
          entered.complete();
          await release.future;
          context.checkCancelled();
          return {'archiveHandle': 'never'};
        },
      );
      expect(started.state, AuthoringJobState.queued);
      await entered.future;
      expect((await jobs.get(started.jobId)).state, AuthoringJobState.running);
      expect(
        (await jobs.cancel(started.jobId, timeout: Duration(seconds: 1))).state,
        AuthoringJobState.cancelling,
      );
      release.complete();
      await jobs.close();
    },
  );
  test(
    'canonical finalization barrier rejects cancellation without a running DTO',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final jobs = ResourcePackJobService(requireActive: () {});
      final started = await jobs.startWork(
        AuthoringJobRequest(
          requestId: 'r',
          kind: 'resource_pack.import',
          projectId: 'p',
          projectRevision: 'sha256:${'0' * 64}',
        ),
        (context) async {
          context.enterFinalization();
          entered.complete();
          await release.future;
          return {'receipt': 'canonical'};
        },
      );
      await entered.future;
      await expectLater(
        jobs.cancel(started.jobId, timeout: Duration(seconds: 1)),
        throwsA(
          isA<ResourcePackTransferException>().having(
            (e) => e.code,
            'code',
            'resource_pack.cancel_not_allowed',
          ),
        ),
      );
      release.complete();
      while (!(await jobs.get(started.jobId)).state.isTerminal) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(jobs.result(started.jobId)['result'], {'receipt': 'canonical'});
      await jobs.close();
    },
  );

  test('close during finalization preserves the committed outcome', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final jobs = ResourcePackJobService(requireActive: () {});
    final started = await jobs.startWork(
      AuthoringJobRequest(
        requestId: 'r',
        kind: 'resource_pack.import',
        projectId: 'p',
        projectRevision: 'sha256:${'0' * 64}',
      ),
      (context) async {
        context.enterFinalization();
        entered.complete();
        await release.future;
        context.checkCancelled();
        context.progress('promoting');
        return {'receipt': 'committed'};
      },
    );
    await entered.future;
    final closing = jobs.close();
    var secondClosed = false;
    final second = jobs.close().then((value) {
      secondClosed = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(secondClosed, isFalse);
    release.complete();
    final snapshots = await closing;
    expect((await second).single.state, AuthoringJobState.succeeded);
    expect(snapshots.single.state, AuthoringJobState.succeeded);
    expect(started.state, AuthoringJobState.queued);
  });
  test('resource pack kinds are valid dotted job names', () {
    final request = AuthoringJobRequest(
      requestId: 'stage',
      kind: 'resource_pack.stage',
      projectId: 'project',
      projectRevision: 'sha256:${'0' * 64}',
    );
    expect(request.kind, 'resource_pack.stage');
    expect(
      () => AuthoringJobRequest(
        requestId: 'bad',
        kind: 'unrelated_name.stage',
        projectId: 'project',
        projectRevision: 'sha256:${'0' * 64}',
      ),
      throwsArgumentError,
    );
  });
}
