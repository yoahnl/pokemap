import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_frame_metrics.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_worker_client.dart';
import 'package:pokemap_loader/src/evaluation/project/evaluation_project_projection.dart';
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

  test('run accepts an attested project projection', () {
    final options = PokeMapEvalCli.parse(<String>[
      'run',
      'selbrume.shop.after-lysa',
      '--project-root',
      'build/pokemap-eval/input/job-1/selbrume',
      '--expected-project-tree-hash',
      'a' * 64,
    ]);

    expect(options.projectRoot, 'build/pokemap-eval/input/job-1/selbrume');
    expect(options.expectedProjectTreeHash, 'a' * 64);
  });

  test('profile run parses an explicit repeatable performance contract', () {
    final options = PokeMapEvalCli.parse(
      <String>[
        'run',
        'selbrume.shop.after-lysa',
        '--target',
        'interactive',
        '--build-mode',
        'profile',
        '--runs',
        '3',
        '--json-output',
        'build/performance/runtime.json',
      ],
    );

    expect(options.buildMode, EvaluationBuildMode.profile);
    expect(options.runs, 3);
    expect(options.jsonOutput, 'build/performance/runtime.json');
  });

  test('profile run writes one V2 aggregate from isolated frame artifacts',
      () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    await fixture.writeScenario();
    var runIndex = 0;
    fixture.interactiveWorker.onRun = (request, buildMode) async {
      runIndex += 1;
      expect(buildMode, EvaluationBuildMode.profile);
      final output =
          Directory(p.join(fixture.root.path, request.outputDirectory));
      final frameFile =
          File(p.join(output.path, 'artifacts', 'frame-metrics.json'));
      await frameFile.create(recursive: true);
      await frameFile.writeAsString(
        jsonEncode(
          InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
            buildMicroseconds: <int>[1000 * runIndex, 2000 * runIndex],
            rasterMicroseconds: <int>[3000 * runIndex, 4000 * runIndex],
            frameSpanMicroseconds: <int>[5000 * runIndex, 20000 * runIndex],
          ).toJson(),
        ),
      );
      final receipt = File(p.join(output.path, 'receipt.json'));
      await receipt.writeAsString(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'runId': request.runId,
          'scenarioId': 'selbrume.test',
          'target': 'interactive',
          'status': 'succeeded',
          'exitCode': 0,
          'durationMilliseconds': 42,
          'stepResults': <Object?>[
            <String, Object?>{'passed': true},
          ],
          'diff': <String, Object?>{'changes': <Object?>[]},
          'relativeReceiptPath': p.posix.join(
            request.outputDirectory,
            'receipt.json',
          ),
        }),
      );
      return EvaluationWorkerResult.completed(
        runId: request.runId,
        status: EvaluationRunStatus.succeeded,
        exitCode: 0,
        receiptPath: p.posix.join(request.outputDirectory, 'receipt.json'),
      );
    };

    final result = await fixture.cli.execute(
      <String>[
        'run',
        'selbrume.test',
        '--target',
        'interactive',
        '--build-mode',
        'profile',
        '--runs',
        '3',
        '--json-output',
        'build/performance/runtime.json',
      ],
    );

    expect(result.exitCode, 0);
    expect(fixture.interactiveWorker.requests, hasLength(3));
    final output = File(p.join(
      fixture.root.path,
      'examples',
      'playable_runtime_host',
      'build',
      'performance',
      'runtime.json',
    ));
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'runtime_interactive_journey');
    expect(payload['executionMode'], 'flutter-profile');
    expect(payload['runCount'], 3);
    expect(payload['runs'], hasLength(3));
    final aggregate = payload['aggregateFrameMetrics']! as Map<String, Object?>;
    expect(aggregate['frameCount'], 6);
    expect(aggregate['framesOver16Point67Milliseconds'], 3);
  });

  test('performance options reject debug mode, zero runs, and output escape',
      () async {
    expect(
      () => PokeMapEvalCli.parse(<String>[
        'run',
        'selbrume.test',
        '--target',
        'interactive',
        '--runs',
        '3',
      ]),
      throwsA(isA<PokeMapEvalUsageException>()),
    );
    expect(
      () => PokeMapEvalCli.parse(<String>[
        'run',
        'selbrume.test',
        '--target',
        'interactive',
        '--build-mode',
        'profile',
        '--runs',
        '0',
      ]),
      throwsA(isA<PokeMapEvalUsageException>()),
    );
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    await fixture.writeScenario();
    final escaped = await fixture.cli.execute(<String>[
      'run',
      'selbrume.test',
      '--target',
      'interactive',
      '--build-mode',
      'profile',
      '--json-output',
      '../runtime.json',
    ]);
    expect(escaped.exitCode, 2);
    expect(fixture.interactiveWorker.requests, isEmpty);
    expect(fixture.stderr.toString(), contains('must stay inside'));
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

  test('direct run consumes and disposes an attested immutable projection',
      () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    await fixture.writeScenario();
    fixture.worker.result = EvaluationWorkerResult.completed(
      runId: 'run-test',
      status: EvaluationRunStatus.succeeded,
      exitCode: 0,
    );

    final result = await fixture.cli.execute(
      <String>['run', 'selbrume.test'],
    );

    expect(result.exitCode, 0);
    final request = fixture.worker.requests.single;
    expect(request.projectRoot, 'build/projected/selbrume');
    expect(request.expectedProjectTreeHash, 'a' * 64);
    expect(fixture.projectProjectionFactory.creations, 1);
    expect(fixture.projectProjectionFactory.disposals, 1);
  });

  test('direct run disposes its projection when the worker throws', () async {
    final fixture = await _CliFixture.create();
    addTearDown(fixture.dispose);
    await fixture.writeScenario();
    fixture.worker.onRun = (_, _) => throw StateError('worker failed');

    final result = await fixture.cli.execute(
      <String>['run', 'selbrume.test'],
    );

    expect(result.exitCode, 3);
    expect(fixture.projectProjectionFactory.creations, 1);
    expect(fixture.projectProjectionFactory.disposals, 1);
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
    required this.projectProjectionFactory,
  });

  final Directory root;
  final _FakeWorker worker;
  final _FakeWorker interactiveWorker;
  final StringBuffer stdout;
  final StringBuffer stderr;
  final PokeMapEvalCli cli;
  final _FakeProjectProjectionFactory projectProjectionFactory;

  static Future<_CliFixture> create() async {
    final root = await Directory.systemTemp.createTemp('pokemap-eval-cli-');
    final worker = _FakeWorker();
    final interactiveWorker = _FakeWorker();
    final stdout = StringBuffer();
    final stderr = StringBuffer();
    final projectProjectionFactory = _FakeProjectProjectionFactory();
    return _CliFixture._(
      root: root,
      worker: worker,
      interactiveWorker: interactiveWorker,
      stdout: stdout,
      stderr: stderr,
      projectProjectionFactory: projectProjectionFactory,
      cli: PokeMapEvalCli(
        repositoryRoot: root,
        worker: worker,
        interactiveWorker: interactiveWorker,
        stdoutSink: stdout.writeln,
        stderrSink: stderr.writeln,
        runIdFactory: () => 'run-test',
        projectProjectionFactory: projectProjectionFactory,
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

final class _FakeProjectProjectionFactory
    implements EvaluationProjectProjectionFactory {
  var creations = 0;
  var disposals = 0;

  @override
  Future<EvaluationProjectProjection> create({
    required Directory repositoryRoot,
    required String projectId,
    required String runId,
  }) async {
    creations += 1;
    final relativeRoot = 'build/projected/$projectId';
    return EvaluationProjectProjection(
      projectRoot: Directory(p.join(repositoryRoot.path, relativeRoot)),
      relativeProjectRoot: relativeRoot,
      projectTreeHash: 'a' * 64,
      dispose: () async {
        disposals += 1;
      },
    );
  }
}

final class _FakeWorker implements PokeMapEvalWorker {
  final List<EvaluationWorkerRequest> requests = <EvaluationWorkerRequest>[];
  Future<EvaluationWorkerResult> Function(
    EvaluationWorkerRequest request,
    EvaluationBuildMode buildMode,
  )? onRun;
  EvaluationWorkerResult result = EvaluationWorkerResult.infrastructureFailure(
    runId: 'run-test',
    message: 'Worker result was not configured.',
  );

  @override
  Future<EvaluationWorkerResult> run(
    EvaluationWorkerRequest request, {
    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
  }) async {
    requests.add(request);
    final handler = onRun;
    if (handler != null) return handler(request, buildMode);
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
