import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_scenario_parser.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_web_launcher.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';
import 'package:pokemap_loader/src/evaluation/worker/headless_worker_process.dart';

enum PokeMapEvalCommand {
  list,
  run,
  inspect,
  history,
  web,
}

final class PokeMapEvalOptions {
  const PokeMapEvalOptions({
    required this.command,
    this.scenarioId,
    this.projectId,
    this.policy,
    this.checkpointId,
    this.includeFacts = false,
    this.includeParty = false,
    this.includeBag = false,
    this.jsonOnly = false,
    this.port = 0,
    this.openBrowser = true,
  });

  final PokeMapEvalCommand command;
  final String? scenarioId;
  final String? projectId;
  final EvaluationPolicy? policy;
  final String? checkpointId;
  final bool includeFacts;
  final bool includeParty;
  final bool includeBag;
  final bool jsonOnly;
  final int port;
  final bool openBrowser;
}

final class PokeMapEvalCliResult {
  const PokeMapEvalCliResult(this.exitCode);

  final int exitCode;
}

abstract interface class PokeMapEvalWorker {
  Future<EvaluationWorkerResult> run(EvaluationWorkerRequest request);
}

typedef PokeMapEvalOutputSink = void Function(String line);

final class PokeMapEvalCli {
  PokeMapEvalCli({
    required this.repositoryRoot,
    required this.worker,
    required this.stdoutSink,
    required this.stderrSink,
    String Function()? runIdFactory,
  }) : _runIdFactory = runIdFactory ?? _defaultRunId;

  factory PokeMapEvalCli.standard() {
    final root = _discoverRepositoryRoot();
    return PokeMapEvalCli(
      repositoryRoot: root,
      worker: _HeadlessProcessWorker(
        HeadlessWorkerProcess(
          hostRoot: root,
          stderrSink: stderr.write,
        ),
      ),
      stdoutSink: stdout.writeln,
      stderrSink: stderr.writeln,
    );
  }

  final Directory repositoryRoot;
  final PokeMapEvalWorker worker;
  final PokeMapEvalOutputSink stdoutSink;
  final PokeMapEvalOutputSink stderrSink;
  final String Function() _runIdFactory;

  static PokeMapEvalOptions parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const PokeMapEvalUsageException('Missing command.');
    }
    return switch (arguments.first) {
      'list' => _parseList(arguments.skip(1).toList()),
      'run' => _parseRun(arguments.skip(1).toList()),
      'inspect' => _parseInspect(arguments.skip(1).toList()),
      'history' => _parseHistory(arguments.skip(1).toList()),
      'web' => _parseWeb(arguments.skip(1).toList()),
      final command => throw PokeMapEvalUsageException(
          'Unknown command "$command".',
        ),
    };
  }

  Future<PokeMapEvalCliResult> execute(List<String> arguments) async {
    final PokeMapEvalOptions options;
    try {
      options = parse(arguments);
    } on PokeMapEvalUsageException catch (failure) {
      stderrSink('${failure.message}\n${_usage()}');
      return const PokeMapEvalCliResult(2);
    }

    try {
      return switch (options.command) {
        PokeMapEvalCommand.list => await _list(options),
        PokeMapEvalCommand.run => await _run(options),
        PokeMapEvalCommand.inspect => await _inspect(options),
        PokeMapEvalCommand.history => await _history(options),
        PokeMapEvalCommand.web => await _web(options),
      };
    } on PokeMapEvalUsageException catch (failure) {
      stderrSink(failure.message);
      return const PokeMapEvalCliResult(2);
    } on EvaluationScenarioFormatException catch (failure) {
      stderrSink(failure.toString());
      return const PokeMapEvalCliResult(2);
    } on FileSystemException catch (failure) {
      stderrSink('Evaluation infrastructure error: ${failure.message}');
      return const PokeMapEvalCliResult(3);
    } on SocketException catch (failure) {
      stderrSink('Evaluation network error: ${failure.message}');
      return const PokeMapEvalCliResult(3);
    } on StateError catch (failure) {
      stderrSink('Evaluation infrastructure error: $failure');
      return const PokeMapEvalCliResult(3);
    }
  }

  Future<PokeMapEvalCliResult> _web(PokeMapEvalOptions options) async {
    final application = await EvaluationWebApplication.start(
      repositoryRoot: repositoryRoot,
      assetsRoot: evaluationWebAssetsForScript(Platform.script),
      port: options.port,
      projectId: options.projectId,
      stderrSink: stderr.write,
    );
    stdoutSink('PokeMap Eval cockpit: ${application.uri}');
    if (options.openBrowser) {
      final opened = await EvaluationWebLauncher().open(application.uri);
      if (!opened) {
        stderrSink(
          'Unable to open a browser automatically. '
          'Open ${application.uri} manually.',
        );
      }
    }
    return const PokeMapEvalCliResult(0);
  }

  Future<PokeMapEvalCliResult> _list(PokeMapEvalOptions options) async {
    final scenarios = await _discoverScenarios(
      projectId: options.projectId,
    );
    if (scenarios.isEmpty) {
      stdoutSink('No PokeMap Eval scenario found.');
      return const PokeMapEvalCliResult(0);
    }
    for (final discovered in scenarios) {
      stdoutSink(
        '${discovered.scenario.id}\t'
        '${discovered.scenario.policy.name}\t'
        '${discovered.scenario.title}',
      );
    }
    return const PokeMapEvalCliResult(0);
  }

  Future<PokeMapEvalCliResult> _run(PokeMapEvalOptions options) async {
    final scenarioId = options.scenarioId!;
    final matches = (await _discoverScenarios())
        .where((candidate) => candidate.scenario.id == scenarioId)
        .toList(growable: false);
    if (matches.isEmpty) {
      throw PokeMapEvalUsageException(
        'Unknown scenario "$scenarioId".',
      );
    }
    if (matches.length != 1) {
      throw PokeMapEvalUsageException(
        'Scenario id "$scenarioId" is duplicated.',
      );
    }
    return _executeScenario(
      discovered: matches.single,
      policyOverride: options.policy,
      jsonOnly: options.jsonOnly,
    );
  }

  Future<PokeMapEvalCliResult> _inspect(PokeMapEvalOptions options) async {
    final runId = _runIdFactory();
    final outputDirectory = _outputDirectory(runId);
    final selection = <String>[
      if (options.includeFacts) 'facts',
      if (options.includeParty) 'party',
      if (options.includeBag) 'bag',
    ];
    final scenarioJson = <String, Object?>{
      'schemaVersion': 1,
      'id': 'selbrume.inspect.${options.checkpointId}',
      'title': 'Inspect checkpoint ${options.checkpointId}',
      'projectId': 'selbrume',
      'policy': 'probe',
      'start': <String, Object?>{'newGame': true},
      'steps': <Object?>[
        <String, Object?>{
          'id': 'load-checkpoint',
          'command': 'probe.loadCheckpoint',
          'checkpointId': options.checkpointId,
        },
        <String, Object?>{
          'id': 'snapshot',
          'command': 'evidence.snapshot',
          if (selection.isNotEmpty) 'name': selection.join(','),
        },
      ],
    };
    final scenarioFile = File(p.join(
      repositoryRoot.path,
      outputDirectory,
      'inspect-scenario.json',
    ));
    await _writeJsonAtomically(scenarioFile, scenarioJson);
    final scenario = const EvaluationScenarioParser().parseString(
      await scenarioFile.readAsString(),
    );
    return _executeWorker(
      scenario: scenario,
      scenarioPath: _portableRelativePath(scenarioFile),
      outputDirectory: outputDirectory,
      runId: runId,
      jsonOnly: options.jsonOnly,
    );
  }

  Future<PokeMapEvalCliResult> _history(PokeMapEvalOptions options) async {
    final runs = Directory(p.join(
      repositoryRoot.path,
      'build',
      'pokemap-eval',
      'runs',
    ));
    if (!await runs.exists()) {
      stdoutSink('No PokeMap Eval runs found.');
      return const PokeMapEvalCliResult(0);
    }
    final summaries = <_ReceiptSummary>[];
    await for (final entity in runs.list(recursive: true, followLinks: false)) {
      if (entity is! File || p.basename(entity.path) != 'receipt.json') {
        continue;
      }
      try {
        final summary = await _ReceiptSummary.read(
          entity,
          repositoryRoot: repositoryRoot,
        );
        summaries.add(summary);
      } on FormatException catch (failure) {
        stderrSink('Ignoring invalid receipt ${entity.path}: $failure');
      }
    }
    summaries.sort((left, right) => right.runId.compareTo(left.runId));
    if (options.jsonOnly) {
      stdoutSink(
        jsonEncode(
          summaries.map((summary) => summary.toJson()).toList(),
        ),
      );
    } else if (summaries.isEmpty) {
      stdoutSink('No valid PokeMap Eval receipt found.');
    } else {
      for (final summary in summaries) {
        stdoutSink(
          '${summary.runId}\t${summary.scenarioId}\t'
          '${summary.status}\t${summary.durationMilliseconds}ms',
        );
      }
    }
    return const PokeMapEvalCliResult(0);
  }

  Future<PokeMapEvalCliResult> _executeScenario({
    required _DiscoveredScenario discovered,
    required EvaluationPolicy? policyOverride,
    required bool jsonOnly,
  }) async {
    final runId = _runIdFactory();
    final outputDirectory = _outputDirectory(runId);
    var scenario = discovered.scenario;
    var scenarioFile = discovered.file;
    if (policyOverride != null && policyOverride != scenario.policy) {
      final decoded = jsonDecode(await scenarioFile.readAsString());
      if (decoded is! Map) {
        throw const EvaluationScenarioFormatException(
          r'$',
          'Scenario root must be an object.',
        );
      }
      final json = Map<String, Object?>.from(decoded)
        ..['policy'] = policyOverride.name;
      scenarioFile = File(p.join(
        repositoryRoot.path,
        outputDirectory,
        'scenario.json',
      ));
      await _writeJsonAtomically(scenarioFile, json);
      scenario = const EvaluationScenarioParser().parseString(
        await scenarioFile.readAsString(),
      );
    }
    return _executeWorker(
      scenario: scenario,
      scenarioPath: _portableRelativePath(scenarioFile),
      outputDirectory: outputDirectory,
      runId: runId,
      jsonOnly: jsonOnly,
    );
  }

  Future<PokeMapEvalCliResult> _executeWorker({
    required EvaluationScenario scenario,
    required String scenarioPath,
    required String outputDirectory,
    required String runId,
    required bool jsonOnly,
  }) async {
    stderrSink(
      'PokeMap Eval: ${scenario.id} '
      '(${scenario.policy.name}, headless)',
    );
    final result = await worker.run(
      EvaluationWorkerRequest.run(
        runId: runId,
        projectRoot: scenario.projectId,
        scenarioPath: scenarioPath,
        outputDirectory: outputDirectory,
      ),
    );
    _ReceiptSummary? receipt;
    if (result.receiptPath != null) {
      final receiptFile = File(
        p.join(repositoryRoot.path, result.receiptPath),
      );
      try {
        receipt = await _ReceiptSummary.read(
          receiptFile,
          repositoryRoot: repositoryRoot,
        );
      } on Object catch (failure) {
        stderrSink('Worker receipt is missing or invalid: $failure');
        return const PokeMapEvalCliResult(3);
      }
    }

    final summary = receipt?.toJson() ??
        <String, Object?>{
          'runId': result.runId,
          'scenarioId': scenario.id,
          'target': 'headless',
          'status': result.status.name,
          'exitCode': result.exitCode,
          'durationMilliseconds': null,
          'passedSteps': 0,
          'totalSteps': scenario.steps.length,
          'diff': const <Object?>[],
          'receiptPath': result.receiptPath,
          'message': result.message,
        };
    if (jsonOnly) {
      stdoutSink(jsonEncode(summary));
    } else {
      _writeHumanSummary(summary);
    }
    return PokeMapEvalCliResult(result.exitCode);
  }

  void _writeHumanSummary(Map<String, Object?> summary) {
    stdoutSink('Scenario: ${summary['scenarioId']}');
    stdoutSink('Target: ${summary['target']}');
    stdoutSink('Status: ${summary['status']}');
    stdoutSink(
      'Duration: ${summary['durationMilliseconds'] ?? 'unknown'}ms',
    );
    stdoutSink(
      'Steps: ${summary['passedSteps']}/${summary['totalSteps']} passed',
    );
    final diff = summary['diff'];
    if (diff is List && diff.isNotEmpty) {
      stdoutSink('Diff: ${diff.join(', ')}');
    } else {
      stdoutSink('Diff: no state change');
    }
    if (summary['receiptPath'] != null) {
      stdoutSink('Receipt: ${summary['receiptPath']}');
    }
  }

  Future<List<_DiscoveredScenario>> _discoverScenarios({
    String? projectId,
  }) async {
    final root = Directory(p.join(
      repositoryRoot.path,
      'examples',
      'playable_runtime_host',
      'evaluation',
      'scenarios',
    ));
    if (!await root.exists()) return const <_DiscoveredScenario>[];
    final discovered = <_DiscoveredScenario>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || p.extension(entity.path) != '.json') continue;
      final scenario = const EvaluationScenarioParser().parseString(
        await entity.readAsString(),
      );
      if (projectId == null || scenario.projectId == projectId) {
        discovered.add(
          _DiscoveredScenario(file: entity, scenario: scenario),
        );
      }
    }
    discovered.sort(
      (left, right) => left.scenario.id.compareTo(right.scenario.id),
    );
    return discovered;
  }

  String _portableRelativePath(File file) {
    return p
        .relative(file.absolute.path, from: repositoryRoot.absolute.path)
        .replaceAll(r'\', '/');
  }

  String _outputDirectory(String runId) {
    return 'build/pokemap-eval/runs/$runId';
  }
}

final class PokeMapEvalUsageException implements Exception {
  const PokeMapEvalUsageException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class _HeadlessProcessWorker implements PokeMapEvalWorker {
  const _HeadlessProcessWorker(this.process);

  final HeadlessWorkerProcess process;

  @override
  Future<EvaluationWorkerResult> run(EvaluationWorkerRequest request) {
    return process.run(request);
  }
}

final class _DiscoveredScenario {
  const _DiscoveredScenario({
    required this.file,
    required this.scenario,
  });

  final File file;
  final EvaluationScenario scenario;
}

final class _ReceiptSummary {
  const _ReceiptSummary({
    required this.runId,
    required this.scenarioId,
    required this.target,
    required this.status,
    required this.exitCode,
    required this.durationMilliseconds,
    required this.passedSteps,
    required this.totalSteps,
    required this.diff,
    required this.receiptPath,
  });

  final String runId;
  final String scenarioId;
  final String target;
  final String status;
  final int exitCode;
  final int durationMilliseconds;
  final int passedSteps;
  final int totalSteps;
  final List<String> diff;
  final String receiptPath;

  static Future<_ReceiptSummary> read(
    File file, {
    required Directory repositoryRoot,
  }) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Receipt root must be an object.');
    }
    final json = Map<String, Object?>.from(decoded);
    if (json['schemaVersion'] != 1 ||
        json['runId'] is! String ||
        json['scenarioId'] is! String ||
        json['target'] is! String ||
        json['status'] is! String ||
        json['exitCode'] is! int ||
        json['durationMilliseconds'] is! int ||
        json['stepResults'] is! List ||
        json['diff'] is! Map ||
        json['relativeReceiptPath'] is! String) {
      throw const FormatException('Receipt does not match schema V1.');
    }
    final steps = List<Object?>.from(json['stepResults'] as List);
    final passedSteps = steps.where((entry) {
      return entry is Map && entry['passed'] == true;
    }).length;
    final diffObject = Map<String, Object?>.from(json['diff'] as Map);
    final rawChanges = diffObject['changes'];
    if (rawChanges is! List) {
      throw const FormatException('Receipt diff changes must be a list.');
    }
    final changes = rawChanges.map((entry) {
      if (entry is! Map ||
          entry['path'] is! String ||
          entry['kind'] is! String) {
        throw const FormatException('Receipt state change is invalid.');
      }
      return '${entry['path']}:${entry['kind']}';
    }).toList(growable: false);
    final relative = p
        .relative(file.absolute.path, from: repositoryRoot.absolute.path)
        .replaceAll(r'\', '/');
    return _ReceiptSummary(
      runId: json['runId']! as String,
      scenarioId: json['scenarioId']! as String,
      target: json['target']! as String,
      status: json['status']! as String,
      exitCode: json['exitCode']! as int,
      durationMilliseconds: json['durationMilliseconds']! as int,
      passedSteps: passedSteps,
      totalSteps: steps.length,
      diff: changes,
      receiptPath: relative.startsWith('..')
          ? json['relativeReceiptPath']! as String
          : relative,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runId': runId,
      'scenarioId': scenarioId,
      'target': target,
      'status': status,
      'exitCode': exitCode,
      'durationMilliseconds': durationMilliseconds,
      'passedSteps': passedSteps,
      'totalSteps': totalSteps,
      'diff': diff,
      'receiptPath': receiptPath,
    };
  }
}

PokeMapEvalOptions _parseList(List<String> arguments) {
  String? projectId;
  var index = 0;
  while (index < arguments.length) {
    switch (arguments[index]) {
      case '--project':
        projectId = _optionValue(arguments, index, '--project');
        index += 2;
      default:
        throw PokeMapEvalUsageException(
          'Unknown option "${arguments[index]}".',
        );
    }
  }
  return PokeMapEvalOptions(
    command: PokeMapEvalCommand.list,
    projectId: projectId,
  );
}

PokeMapEvalOptions _parseRun(List<String> arguments) {
  if (arguments.isEmpty || arguments.first.startsWith('-')) {
    throw const PokeMapEvalUsageException('run requires a scenario id.');
  }
  final scenarioId = arguments.first;
  EvaluationPolicy? policy;
  var jsonOnly = false;
  var index = 1;
  while (index < arguments.length) {
    switch (arguments[index]) {
      case '--policy':
        final value = _optionValue(arguments, index, '--policy');
        policy = switch (value) {
          'probe' => EvaluationPolicy.probe,
          'certify' => EvaluationPolicy.certify,
          _ => throw PokeMapEvalUsageException(
              'Unknown policy "$value".',
            ),
        };
        index += 2;
      case '--json':
        jsonOnly = true;
        index += 1;
      default:
        throw PokeMapEvalUsageException(
          'Unknown option "${arguments[index]}".',
        );
    }
  }
  return PokeMapEvalOptions(
    command: PokeMapEvalCommand.run,
    scenarioId: scenarioId,
    policy: policy,
    jsonOnly: jsonOnly,
  );
}

PokeMapEvalOptions _parseInspect(List<String> arguments) {
  String? checkpointId;
  var includeFacts = false;
  var includeParty = false;
  var includeBag = false;
  var jsonOnly = false;
  var index = 0;
  while (index < arguments.length) {
    switch (arguments[index]) {
      case '--checkpoint':
        checkpointId = _optionValue(arguments, index, '--checkpoint');
        index += 2;
      case '--facts':
        includeFacts = true;
        index += 1;
      case '--party':
        includeParty = true;
        index += 1;
      case '--bag':
        includeBag = true;
        index += 1;
      case '--json':
        jsonOnly = true;
        index += 1;
      default:
        throw PokeMapEvalUsageException(
          'Unknown option "${arguments[index]}".',
        );
    }
  }
  if (checkpointId == null ||
      !RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(checkpointId)) {
    throw const PokeMapEvalUsageException(
      'inspect requires a portable --checkpoint id.',
    );
  }
  return PokeMapEvalOptions(
    command: PokeMapEvalCommand.inspect,
    checkpointId: checkpointId,
    includeFacts: includeFacts,
    includeParty: includeParty,
    includeBag: includeBag,
    jsonOnly: jsonOnly,
  );
}

PokeMapEvalOptions _parseHistory(List<String> arguments) {
  if (arguments.isEmpty) {
    return const PokeMapEvalOptions(command: PokeMapEvalCommand.history);
  }
  if (arguments.length == 1 && arguments.single == '--json') {
    return const PokeMapEvalOptions(
      command: PokeMapEvalCommand.history,
      jsonOnly: true,
    );
  }
  throw PokeMapEvalUsageException(
    'Unknown option "${arguments.first}".',
  );
}

PokeMapEvalOptions _parseWeb(List<String> arguments) {
  String? projectId;
  var port = 0;
  var openBrowser = true;
  var index = 0;
  while (index < arguments.length) {
    switch (arguments[index]) {
      case '--project':
        projectId = _optionValue(arguments, index, '--project');
        index += 2;
      case '--port':
        final value = _optionValue(arguments, index, '--port');
        port = int.tryParse(value) ?? -1;
        if (port < 0 || port > 65535) {
          throw const PokeMapEvalUsageException(
            '--port must be an integer between 0 and 65535.',
          );
        }
        index += 2;
      case '--no-open':
        openBrowser = false;
        index += 1;
      default:
        throw PokeMapEvalUsageException(
          'Unknown option "${arguments[index]}".',
        );
    }
  }
  if (projectId != null &&
      !RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(projectId)) {
    throw const PokeMapEvalUsageException(
      'web requires a portable --project id.',
    );
  }
  return PokeMapEvalOptions(
    command: PokeMapEvalCommand.web,
    projectId: projectId,
    port: port,
    openBrowser: openBrowser,
  );
}

String _optionValue(List<String> arguments, int index, String option) {
  if (index + 1 >= arguments.length || arguments[index + 1].startsWith('-')) {
    throw PokeMapEvalUsageException('$option requires a value.');
  }
  return arguments[index + 1];
}

Future<void> _writeJsonAtomically(
  File destination,
  Map<String, Object?> json,
) async {
  await destination.parent.create(recursive: true);
  final temporary = File('${destination.path}.tmp');
  await temporary.writeAsString(jsonEncode(json), flush: true);
  if (await destination.exists()) await destination.delete();
  await temporary.rename(destination.path);
}

Directory _discoverRepositoryRoot() {
  var candidate = Directory.current.absolute;
  while (true) {
    if (File(p.join(candidate.path, 'selbrume', 'project.json')).existsSync()) {
      return candidate;
    }
    final parent = candidate.parent;
    if (parent.path == candidate.path) {
      throw StateError('Unable to locate the PokeMap repository root.');
    }
    candidate = parent;
  }
}

String _defaultRunId() {
  return 'run-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}

String _usage() {
  return '''
Usage:
  pokemap eval list [--project <id>]
  pokemap eval run <scenario-id> [--policy probe|certify] [--json]
  pokemap eval inspect --checkpoint <id> [--facts] [--party] [--bag]
  pokemap eval history [--json]
  pokemap eval web [--project <id>] [--port <0..65535>] [--no-open]''';
}
