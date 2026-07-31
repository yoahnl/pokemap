import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/authoring/evaluation_authoring_job_service.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_event.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';

void main() {
  test('jobs expose ordered events and cooperative bounded cancellation',
      () async {
    final executor = _ControlledExecutor();
    final service = EvaluationAuthoringJobService(
      executor: executor,
      clock: _Clock().call,
      jobIdFactory: _Ids(<String>['job-071']).next,
    );
    addTearDown(service.close);

    final started = await service.start(_request('request-071'));
    await executor.started.future;
    executor.emit(
      EvaluationEvent(
        runId: started.jobId,
        sequence: 7,
        type: 'step.finished',
        payload: const <String, Object?>{'stepId': 'new-game'},
      ),
    );
    final cancellation = await service.cancel(
      started.jobId,
      timeout: const Duration(milliseconds: 200),
    );

    expect(cancellation.bounded, isTrue);
    expect(cancellation.state, AuthoringJobState.cancelled);
    expect(executor.cancelCalls, 1);
    final events = await service.events(started.jobId);
    expect(
      events.map((event) => event.sequence),
      List<int>.generate(events.length, (index) => index + 1),
    );
    expect(
      events.map((event) => event.type),
      containsAllInOrder(<String>[
        'job.queued',
        'job.running',
        'worker.step.finished',
        'job.cancelling',
        'job.cancelled',
      ]),
    );
    expect(
      (events
          .firstWhere((event) => event.type == 'worker.step.finished')
          .payload['workerSequence']),
      7,
    );
  });

  test('cancellation call returns inside its bound when a worker is stuck',
      () async {
    final executor = _ControlledExecutor(ignoreCancellation: true);
    final service = EvaluationAuthoringJobService(
      executor: executor,
      clock: _Clock().call,
      jobIdFactory: _Ids(<String>['job-stuck']).next,
    );
    addTearDown(service.close);
    final started = await service.start(_request('request-stuck'));
    await executor.started.future;
    final stopwatch = Stopwatch()..start();

    final cancellation = await service.cancel(
      started.jobId,
      timeout: const Duration(milliseconds: 40),
    );

    stopwatch.stop();
    expect(cancellation.bounded, isFalse);
    expect(cancellation.state, AuthoringJobState.cancelling);
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 160)));
    executor.completeCancelled();
  });

  test('retry creates a traceable attempt and publishes safe artifacts',
      () async {
    final executor = _SequencedExecutor(<EvaluationWorkerResult>[
      EvaluationWorkerResult.infrastructureFailure(
        runId: 'placeholder',
        message: 'renderer unavailable',
      ),
      EvaluationWorkerResult.completed(
        runId: 'placeholder',
        status: EvaluationRunStatus.succeeded,
        exitCode: 0,
      ),
    ]);
    final service = EvaluationAuthoringJobService(
      executor: executor,
      clock: _Clock().call,
      jobIdFactory: _Ids(<String>['job-failed', 'job-retry']).next,
      artifactCollector: (snapshot, result) async => <AuthoringJobArtifact>[
        AuthoringJobArtifact(
          jobId: snapshot.jobId,
          sequence: 1,
          kind: ArtifactKind.receipt,
          createdAtUtc: '2026-07-31T12:00:09.000Z',
          reference: AuthoringArtifactRef(
            id: 'receipt-${snapshot.jobId}',
            mediaType: 'application/json',
            uri: 'artifact://sha256/${'a' * 64}',
            byteLength: 12,
            sha256: 'a' * 64,
          ),
        ),
      ],
    );
    addTearDown(service.close);

    final failed = await service.start(_request('request-retry'));
    await service.waitForTerminal(failed.jobId);
    final retried = await service.retry(failed.jobId);
    final terminal = await service.waitForTerminal(retried.jobId);
    final artifacts = await service.artifacts(retried.jobId);

    expect(terminal.state, AuthoringJobState.succeeded);
    expect(retried.retryOfJobId, failed.jobId);
    expect(retried.attempt, 2);
    expect(artifacts.artifacts.single.kind, ArtifactKind.receipt);
    expect(artifacts.artifacts.single.reference.uri, startsWith('artifact://'));
  });

  test('file collector converts image, log, and receipt into digest handles',
      () async {
    final root = await Directory.systemTemp.createTemp('pmcp071-artifacts-');
    addTearDown(() => root.delete(recursive: true));
    final output = Directory(p.join(root.path, 'runs', 'job-files'));
    await Directory(p.join(output.path, 'artifacts')).create(recursive: true);
    await File(p.join(output.path, 'events.jsonl')).writeAsString('{}\n');
    await File(p.join(output.path, 'artifacts', 'final.png'))
        .writeAsBytes(<int>[137, 80, 78, 71]);
    final receipt = File(p.join(output.path, 'receipt.json'));
    await receipt.writeAsString(
      jsonEncode(<String, Object?>{
        'artifacts': <String>['events.jsonl', 'artifacts/final.png'],
      }),
    );
    final snapshot = AuthoringJobSnapshot(
      jobId: 'job-files',
      request: _request('request-files'),
      attempt: 1,
      state: AuthoringJobState.succeeded,
      createdAtUtc: '2026-07-31T12:00:00.000Z',
      updatedAtUtc: '2026-07-31T12:00:01.000Z',
      lastEventSequence: 3,
    );

    final artifacts = await EvaluationFileArtifactCollector(
      repositoryRoot: root,
    ).collect(
      snapshot,
      EvaluationWorkerResult.completed(
        runId: snapshot.jobId,
        status: EvaluationRunStatus.succeeded,
        exitCode: 0,
        receiptPath: 'runs/job-files/receipt.json',
      ),
    );

    expect(
      artifacts.map((artifact) => artifact.kind),
      containsAll(ArtifactKind.values),
    );
    expect(
      artifacts.every(
        (artifact) =>
            artifact.reference.uri.startsWith('artifact://sha256/') &&
            !artifact.reference.toJson().toString().contains(root.path),
      ),
      isTrue,
    );
  });
}

AuthoringJobRequest _request(String requestId) {
  return AuthoringJobRequest(
    requestId: requestId,
    kind: 'playtest.run',
    projectId: 'selbrume',
    projectRevision: 'sha256:${'a' * 64}',
    input: const <String, Object?>{'scenarioId': 'golden.slice'},
  );
}

final class _ControlledExecutor implements EvaluationAuthoringJobExecutor {
  _ControlledExecutor({this.ignoreCancellation = false});

  final bool ignoreCancellation;
  final Completer<void> started = Completer<void>();
  final Completer<EvaluationWorkerResult> _result =
      Completer<EvaluationWorkerResult>();
  late void Function(EvaluationEvent event) emit;
  var cancelCalls = 0;

  @override
  Future<EvaluationWorkerResult> run(
    AuthoringJobSnapshot snapshot,
    void Function(EvaluationEvent event) eventSink,
  ) {
    emit = eventSink;
    if (!started.isCompleted) started.complete();
    return _result.future;
  }

  @override
  Future<bool> cancel(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async {
    cancelCalls += 1;
    if (!ignoreCancellation) completeCancelled();
    return !ignoreCancellation;
  }

  @override
  Future<bool> forceStop(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async =>
      false;

  void completeCancelled() {
    if (_result.isCompleted) return;
    _result.complete(
      EvaluationWorkerResult.completed(
        runId: 'placeholder',
        status: EvaluationRunStatus.cancelled,
        exitCode: 130,
      ),
    );
  }
}

final class _SequencedExecutor implements EvaluationAuthoringJobExecutor {
  _SequencedExecutor(this.results);

  final List<EvaluationWorkerResult> results;

  @override
  Future<EvaluationWorkerResult> run(
    AuthoringJobSnapshot snapshot,
    void Function(EvaluationEvent event) eventSink,
  ) async =>
      results.removeAt(0);

  @override
  Future<bool> cancel(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async =>
      true;

  @override
  Future<bool> forceStop(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async =>
      true;
}

final class _Ids {
  _Ids(this.values);

  final List<String> values;

  String next() => values.removeAt(0);
}

final class _Clock {
  var milliseconds = 0;

  DateTime call() => DateTime.utc(2026, 7, 31, 12).add(
        Duration(milliseconds: milliseconds++),
      );
}
