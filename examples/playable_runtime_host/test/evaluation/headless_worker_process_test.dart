import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';
import 'package:pokemap_loader/src/evaluation/worker/headless_worker_process.dart';

void main() {
  test('worker request round-trips through JSON', () {
    final request = _requestFixture();

    expect(
      EvaluationWorkerRequest.fromJson(request.toJson()),
      request,
    );
  });

  test('worker result round-trips through JSON', () {
    final result = EvaluationWorkerResult.completed(
      runId: 'run-001',
      status: EvaluationRunStatus.succeeded,
      exitCode: 0,
      receiptPath: 'build/pokemap-eval/runs/run-001/receipt.json',
    );

    expect(
      EvaluationWorkerResult.fromJson(result.toJson()),
      result,
    );
  });

  test('portable worker fields reject absolute and escaping paths', () {
    expect(
      () => EvaluationWorkerRequest.run(
        runId: 'run-absolute',
        projectRoot: '/tmp/selbrume',
        scenarioPath: 'evaluation/scenario.json',
        outputDirectory: 'build/run-absolute',
      ),
      throwsArgumentError,
    );
    expect(
      () => EvaluationWorkerRequest.run(
        runId: 'run-escape',
        projectRoot: 'selbrume',
        scenarioPath: '../scenario.json',
        outputDirectory: 'build/run-escape',
      ),
      throwsArgumentError,
    );
  });

  test('process maps an infrastructure failure to exit code 3', () async {
    final root = _repositoryRoot();
    final result = await HeadlessWorkerProcess(
      flutterExecutable: '/missing/flutter',
      hostRoot: root,
      stderrSink: (_) {},
    ).run(_requestFixture(runId: 'run-missing-flutter'));

    expect(result.exitCode, 3);
    expect(result.status, EvaluationRunStatus.infrastructureFailure);
    expect(result.receiptPath, isNull);
  });

  test(
    'real one-shot worker loads Selbrume without a desktop window',
    () async {
      final root = _repositoryRoot();
      final runId = 'run-worker-${DateTime.now().microsecondsSinceEpoch}';
      final relativeOutput = 'build/pokemap-eval/tests/$runId';
      final output = Directory(p.join(root.path, relativeOutput));
      final scenario = File(p.join(output.path, 'scenario.json'));
      addTearDown(() async {
        if (await output.exists()) await output.delete(recursive: true);
      });
      await output.create(recursive: true);
      await scenario.writeAsString(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'id': 'selbrume.worker-smoke',
          'title': 'Worker smoke',
          'projectId': 'selbrume',
          'policy': 'certify',
          'start': <String, Object?>{'newGame': true},
          'steps': <Object?>[
            <String, Object?>{
              'id': 'initial-map',
              'assert': 'state.currentMapId',
              'equals': 'map_bourg_selbrume',
            },
          ],
          'criteria': <Object?>[
            <String, Object?>{
              'id': 'runtime-loaded',
              'stepIds': <String>['initial-map'],
            },
          ],
        }),
      );
      final scenarioPath =
          p.relative(scenario.path, from: root.path).replaceAll(r'\', '/');
      final workerStderr = StringBuffer();

      final result = await HeadlessWorkerProcess(
        hostRoot: root,
        stderrSink: workerStderr.write,
      ).run(
        EvaluationWorkerRequest.run(
          runId: runId,
          projectRoot: 'selbrume',
          scenarioPath: scenarioPath,
          outputDirectory: relativeOutput,
        ),
      );

      expect(
        result.status,
        EvaluationRunStatus.succeeded,
        reason: '${result.message}\n$workerStderr',
      );
      expect(result.exitCode, 0);
      expect(result.receiptPath, '$relativeOutput/receipt.json');
      expect(
        File(p.join(root.path, relativeOutput, 'events.jsonl')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(root.path, result.receiptPath!)).existsSync(),
        isTrue,
      );
      final receipt = jsonDecode(
        await File(p.join(root.path, result.receiptPath!)).readAsString(),
      ) as Map<String, Object?>;
      expect(
        receipt['checkpointProvenance'],
        isA<Map<String, Object?>>()
            .having(
              (value) => value['projectTreeHashSha256'],
              'project hash',
              matches(RegExp(r'^[0-9a-f]{64}$')),
            )
            .having(
              (value) => value['evaluationCodeDigestSha256'],
              'evaluation code digest',
              matches(RegExp(r'^[0-9a-f]{64}$')),
            ),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

EvaluationWorkerRequest _requestFixture({
  String runId = 'run-001',
}) {
  return EvaluationWorkerRequest.run(
    runId: runId,
    projectRoot: 'selbrume',
    scenarioPath:
        'examples/playable_runtime_host/evaluation/scenarios/selbrume/'
        'shop_after_lysa.json',
    outputDirectory: 'build/pokemap-eval/runs/$runId',
  );
}

Directory _repositoryRoot() {
  return Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
}
