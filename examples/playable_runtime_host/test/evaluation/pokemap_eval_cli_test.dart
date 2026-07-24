import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_scenario_parser.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';

import '../../tool/src/pokemap_eval_cli.dart';

void main() {
  test('run command resolves a scenario by ID', () {
    final options = PokeMapEvalCli.parse(
      <String>['run', 'selbrume.shop.after-lysa', '--json'],
    );

    expect(options.command, PokeMapEvalCommand.run);
    expect(options.scenarioId, 'selbrume.shop.after-lysa');
    expect(options.jsonOnly, isTrue);
    expect(options.target, EvaluationTarget.headless);
  });

  test('run target selects the interactive worker without changing policy',
      () async {
    final options = PokeMapEvalCli.parse(
      <String>[
        'run',
        'selbrume.shop.after-lysa',
        '--target',
        'interactive',
      ],
    );
    expect(options.target, EvaluationTarget.interactive);
    expect(options.policy, isNull);

    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    await fixture.writeScenario();
    fixture.interactiveWorker.result = EvaluationWorkerResult.completed(
      runId: 'run-test',
      status: EvaluationRunStatus.succeeded,
      exitCode: 0,
    );

    final result = await fixture.cli.execute(
      <String>[
        'run',
        'selbrume.test',
        '--target',
        'interactive',
      ],
    );

    expect(result.exitCode, 0);
    expect(fixture.worker.requests, isEmpty);
    expect(fixture.interactiveWorker.requests, hasLength(1));
    expect(fixture.stderr.toString(), contains('(probe, interactive)'));
  });

  test('functional failure maps to exit code 1', () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    await fixture.writeScenario();
    fixture.worker.result = EvaluationWorkerResult.completed(
      runId: 'run-failed',
      status: EvaluationRunStatus.failed,
      exitCode: 1,
      message: 'Assertion failed.',
    );

    final result = await fixture.cli.execute(
      <String>['run', 'selbrume.test'],
    );

    expect(result.exitCode, 1);
  });

  test('list discovers strict scenarios without launching Flutter', () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    await fixture.writeScenario();

    final result = await fixture.cli.execute(
      <String>['list', '--project', 'selbrume'],
    );

    expect(result.exitCode, 0);
    expect(fixture.stdout.toString(), contains('selbrume.test'));
    expect(fixture.worker.requests, isEmpty);
  });

  test('json mode writes exactly one machine-readable summary', () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    await fixture.writeScenario();
    fixture.worker.result = EvaluationWorkerResult.completed(
      runId: 'run-json',
      status: EvaluationRunStatus.failed,
      exitCode: 1,
      message: 'Expected failure.',
    );

    await fixture.cli.execute(
      <String>['run', 'selbrume.test', '--json'],
    );

    final decoded = jsonDecode(fixture.stdout.toString());
    expect(decoded, isA<Map<String, Object?>>());
    expect((decoded as Map<String, Object?>)['status'], 'failed');
    expect(fixture.stdout.toString().trim().split('\n'), hasLength(1));
  });

  test('inspect creates a probe scenario through the worker path', () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    fixture.worker.result = EvaluationWorkerResult.infrastructureFailure(
      runId: 'inspect',
      message: 'Stop after request capture.',
    );

    await fixture.cli.execute(
      <String>[
        'inspect',
        '--checkpoint',
        'after-lysa',
        '--facts',
        '--party',
      ],
    );

    final request = fixture.worker.requests.single;
    final scenarioFile = File(p.join(
      fixture.root.path,
      request.scenarioPath,
    ));
    final scenario = const EvaluationScenarioParser().parseString(
      await scenarioFile.readAsString(),
    );
    expect(scenario.policy.name, 'probe');
    expect(
      scenario.steps
          .whereType<EvaluationCommandStep>()
          .map((step) => step.operation),
      <String>['probe.loadCheckpoint', 'evidence.snapshot'],
    );
    final snapshot = scenario.steps.last as EvaluationCommandStep;
    expect(snapshot.arguments['name'], 'facts,party');
  });

  test('unknown options return usage exit code 2 without a worker', () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);

    final result = await fixture.cli.execute(
      <String>['run', 'selbrume.test', '--unknown'],
    );

    expect(result.exitCode, 2);
    expect(fixture.worker.requests, isEmpty);
    expect(fixture.stderr.toString(), contains('Unknown option'));
  });

  test('history renders validated receipts and ignores malformed files',
      () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    final valid = File(p.join(
      fixture.root.path,
      'build',
      'pokemap-eval',
      'runs',
      'run-valid',
      'receipt.json',
    ));
    await valid.create(recursive: true);
    await valid.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'runId': 'run-valid',
        'scenarioId': 'selbrume.valid',
        'target': 'headless',
        'status': 'succeeded',
        'exitCode': 0,
        'durationMilliseconds': 42,
        'stepResults': <Object?>[
          <String, Object?>{'passed': true},
        ],
        'diff': <String, Object?>{'changes': <Object?>[]},
        'relativeReceiptPath': 'receipt.json',
      }),
    );
    final malformed = File(p.join(
      fixture.root.path,
      'build',
      'pokemap-eval',
      'runs',
      'run-invalid',
      'receipt.json',
    ));
    await malformed.create(recursive: true);
    await malformed.writeAsString('{"status":"succeeded"}');

    final result = await fixture.cli.execute(<String>['history']);

    expect(result.exitCode, 0);
    expect(fixture.stdout.toString(), contains('selbrume.valid'));
    expect(fixture.stdout.toString(), isNot(contains('run-invalid')));
    expect(fixture.stderr.toString(), contains('Ignoring invalid receipt'));
  });
}

final class _CliFixture {
  _CliFixture._({
    required this.root,
    required this.worker,
    required this.interactiveWorker,
    required this.stdout,
    required this.stderr,
    required this.cli,
  });

  final Directory root;
  final _FakeWorker worker;
  final _FakeWorker interactiveWorker;
  final StringBuffer stdout;
  final StringBuffer stderr;
  final PokeMapEvalCli cli;

  static Future<_CliFixture> create() async {
    final root = await Directory.systemTemp.createTemp('pokemap-eval-cli-');
    final worker = _FakeWorker();
    final interactiveWorker = _FakeWorker();
    final stdout = StringBuffer();
    final stderr = StringBuffer();
    return _CliFixture._(
      root: root,
      worker: worker,
      interactiveWorker: interactiveWorker,
      stdout: stdout,
      stderr: stderr,
      cli: PokeMapEvalCli(
        repositoryRoot: root,
        worker: worker,
        interactiveWorker: interactiveWorker,
        stdoutSink: stdout.writeln,
        stderrSink: stderr.writeln,
        runIdFactory: () => 'run-test',
      ),
    );
  }

  Future<void> writeScenario() async {
    final file = File(p.join(
      root.path,
      'examples',
      'playable_runtime_host',
      'evaluation',
      'scenarios',
      'selbrume',
      'test.json',
    ));
    await file.create(recursive: true);
    await file.writeAsString('''
    {
      "schemaVersion": 1,
      "id": "selbrume.test",
      "title": "Test scenario",
      "projectId": "selbrume",
      "policy": "probe",
      "start": {"newGame": true},
      "steps": [
        {"id": "snapshot", "command": "evidence.snapshot"}
      ]
    }
    ''');
  }

  Future<void> dispose() => root.delete(recursive: true);
}

final class _FakeWorker implements PokeMapEvalWorker {
  final List<EvaluationWorkerRequest> requests = <EvaluationWorkerRequest>[];
  EvaluationWorkerResult result = EvaluationWorkerResult.infrastructureFailure(
    runId: 'run-test',
    message: 'Worker result was not configured.',
  );

  @override
  Future<EvaluationWorkerResult> run(EvaluationWorkerRequest request) async {
    requests.add(request);
    if (result.runId == request.runId) return result;
    return switch (result.status) {
      EvaluationRunStatus.infrastructureFailure =>
        EvaluationWorkerResult.infrastructureFailure(
          runId: request.runId,
          message: result.message!,
        ),
      _ => EvaluationWorkerResult.completed(
          runId: request.runId,
          status: result.status,
          exitCode: result.exitCode,
          receiptPath: result.receiptPath,
          message: result.message,
        ),
    };
  }
}
