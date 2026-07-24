import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../contracts/evaluation_policy.dart';
import '../contracts/evaluation_receipt.dart';
import '../contracts/evaluation_scenario.dart';
import '../driver/selbrume_evaluation_driver.dart';
import '../runner/evaluation_scenario_runner.dart';
import '../scenario/evaluation_scenario_parser.dart';
import 'evaluation_worker_protocol.dart';
import 'headless_worker_process.dart';

Future<EvaluationWorkerResult> runHeadlessEvaluationRequest(
  EvaluationWorkerRequest request, {
  Directory? hostRoot,
}) async {
  final root = hostRoot ?? _hostRootFromEnvironment();
  final outputDirectory = Directory(
    p.join(root.path, request.outputDirectory),
  );
  final resultFile = File(
    p.join(outputDirectory.path, evaluationWorkerResultFileName),
  );
  await outputDirectory.create(recursive: true);

  EvaluationWorkerResult result;
  try {
    result = await _executeRequest(
      request,
      hostRoot: root,
      outputDirectory: outputDirectory,
    );
  } on EvaluationScenarioFormatException catch (failure) {
    result = EvaluationWorkerResult.completed(
      runId: request.runId,
      status: EvaluationRunStatus.invalidScenario,
      exitCode: 2,
      message: failure.toString(),
    );
  } on Object catch (failure) {
    result = EvaluationWorkerResult.infrastructureFailure(
      runId: request.runId,
      message: 'Headless worker failed before producing a receipt: $failure',
    );
  }
  await _writeJsonAtomically(resultFile, result.toJson());
  return result;
}

Future<EvaluationWorkerResult> _executeRequest(
  EvaluationWorkerRequest request, {
  required Directory hostRoot,
  required Directory outputDirectory,
}) async {
  final scenarioFile = File(p.join(hostRoot.path, request.scenarioPath));
  final scenarioSource = await scenarioFile.readAsString();
  final scenario = const EvaluationScenarioParser().parseString(scenarioSource);
  final projectRoot = Directory(p.join(hostRoot.path, request.projectRoot));
  final eventsFile = File(p.join(outputDirectory.path, 'events.jsonl'));
  final eventsSink = eventsFile.openWrite(mode: FileMode.writeOnly);
  final startedAt = DateTime.now().toUtc();
  SelbrumeEvaluationDriver? driver;
  EvaluationScenarioRunResult runResult;
  try {
    driver = await SelbrumeEvaluationDriver.start(
      projectRoot: projectRoot,
      runId: request.runId,
    );
    runResult = await EvaluationScenarioRunner(
      driver: driver,
      runIdFactory: () => request.runId,
      eventSink: (event) {
        eventsSink.writeln(jsonEncode(event.toJson()));
      },
    ).run(scenario);
  } finally {
    await eventsSink.flush();
    await eventsSink.close();
    await driver?.dispose();
  }
  final finishedAt = DateTime.now().toUtc();
  final receipt = EvaluationReceipt.validated(
    runId: request.runId,
    projectId: scenario.projectId,
    scenarioId: scenario.id,
    scenarioVersion: scenario.schemaVersion,
    policy: scenario.policy,
    target: EvaluationTarget.headless,
    evidenceLevel: runResult.evidenceLevel,
    commit: null,
    projectTreeHash: await _treeDigest(projectRoot),
    commandDigest: sha256.convert(utf8.encode(scenarioSource)).toString(),
    outputDigest: sha256.convert(await eventsFile.readAsBytes()).toString(),
    startedAt: startedAt,
    finishedAt: finishedAt,
    duration: finishedAt.difference(startedAt),
    status: runResult.status,
    exitCode: _exitCodeFor(runResult.status),
    initialState: runResult.initialState,
    finalState: runResult.finalState,
    diff: runResult.diff,
    stepResults: runResult.stepResults,
    shortcutsUsed: runResult.shortcutsUsed,
    checkpointProvenance: switch (scenario.start) {
      EvaluationCheckpointStart(:final checkpointId) => <String, Object?>{
          'checkpointId': checkpointId
        },
      _ => null,
    },
    artifacts: const <String>['events.jsonl'],
    error: runResult.error,
    relativeReceiptPath: 'receipt.json',
    declaredCriterionIds:
        scenario.criteria.map((criterion) => criterion.id).toList(),
    productCriteria: runResult.productCriteria,
  );
  final receiptFile = File(p.join(outputDirectory.path, 'receipt.json'));
  await _writeJsonAtomically(receiptFile, receipt.toJson());
  final portableReceiptPath = '${request.outputDirectory}/receipt.json';
  return EvaluationWorkerResult.completed(
    runId: request.runId,
    status: runResult.status,
    exitCode: _exitCodeFor(runResult.status),
    receiptPath: portableReceiptPath,
    message: runResult.error?['message'] as String?,
  );
}

Future<String> _treeDigest(Directory root) async {
  final files = await root
      .list(recursive: true, followLinks: false)
      .where((entity) => entity is File)
      .cast<File>()
      .toList();
  files.sort(
    (left, right) => p
        .relative(left.path, from: root.path)
        .compareTo(p.relative(right.path, from: root.path)),
  );
  final entries = <String>[];
  for (final file in files) {
    final relative =
        p.relative(file.path, from: root.path).replaceAll(r'\', '/');
    final digest = await sha256.bind(file.openRead()).first;
    entries.add('$relative\u0000$digest');
  }
  return sha256.convert(utf8.encode(entries.join('\u0000'))).toString();
}

int _exitCodeFor(EvaluationRunStatus status) {
  return switch (status) {
    EvaluationRunStatus.succeeded => 0,
    EvaluationRunStatus.failed => 1,
    EvaluationRunStatus.invalidScenario => 2,
    EvaluationRunStatus.infrastructureFailure => 3,
    EvaluationRunStatus.policyViolation => 4,
    EvaluationRunStatus.cancelled => 130,
  };
}

Future<void> _writeJsonAtomically(
  File destination,
  Map<String, Object?> json,
) async {
  final temporary = File('${destination.path}.tmp');
  await temporary.writeAsString(jsonEncode(json), flush: true);
  if (await destination.exists()) await destination.delete();
  await temporary.rename(destination.path);
}

Directory _hostRootFromEnvironment() {
  final value = Platform.environment[pokeMapEvalHostRootEnvironmentKey];
  if (value == null || value.trim().isEmpty) {
    throw StateError(
      '$pokeMapEvalHostRootEnvironmentKey is missing from the worker.',
    );
  }
  return Directory(value);
}
