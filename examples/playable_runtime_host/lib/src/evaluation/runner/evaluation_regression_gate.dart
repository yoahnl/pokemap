import 'dart:io';

import 'package:path/path.dart' as p;

typedef EvaluationGateExecutor = Future<EvaluationGateCommandResult> Function(
  EvaluationGateCommand command,
);

final class EvaluationGateCommand {
  EvaluationGateCommand({
    required String id,
    required String executable,
    required List<String> arguments,
    required Directory workingDirectory,
  })  : id = _nonBlank(id, 'id'),
        executable = _nonBlank(executable, 'executable'),
        arguments = List<String>.unmodifiable(arguments),
        workingDirectory = workingDirectory.absolute;

  final String id;
  final String executable;
  final List<String> arguments;
  final Directory workingDirectory;

  String get displayCommand => '$executable ${arguments.join(' ')}';
}

final class EvaluationGateCommandResult {
  const EvaluationGateCommandResult({
    required this.command,
    required this.exitCode,
    required this.duration,
    this.stdout = '',
    this.stderr = '',
  });

  final EvaluationGateCommand command;
  final int exitCode;
  final Duration duration;
  final String stdout;
  final String stderr;

  bool get isSuccessful => exitCode == 0;
}

final class EvaluationRegressionGateResult {
  EvaluationRegressionGateResult(List<EvaluationGateCommandResult> results)
      : results = List<EvaluationGateCommandResult>.unmodifiable(results);

  final List<EvaluationGateCommandResult> results;

  bool get isSuccessful =>
      results.isNotEmpty && results.every((result) => result.isSuccessful);

  String? get failedCommandId =>
      results.where((result) => !result.isSuccessful).firstOrNull?.command.id;
}

final class EvaluationRegressionGate {
  EvaluationRegressionGate._({
    required List<EvaluationGateCommand> commands,
    required EvaluationGateExecutor execute,
  })  : _commands = List<EvaluationGateCommand>.unmodifiable(commands),
        _execute = execute;

  factory EvaluationRegressionGate.quick(
    Directory repositoryRoot, {
    EvaluationGateExecutor? execute,
  }) {
    final packageRoot = Directory(
      p.join(
        repositoryRoot.absolute.path,
        'examples',
        'playable_runtime_host',
      ),
    );
    return EvaluationRegressionGate._(
      commands: <EvaluationGateCommand>[
        EvaluationGateCommand(
          id: 'scenario-contracts',
          executable: 'flutter',
          arguments: const <String>[
            'test',
            'test/evaluation/evaluation_scenario_parser_test.dart',
            'test/evaluation/selbrume_evaluation_scenarios_test.dart',
          ],
          workingDirectory: packageRoot,
        ),
        EvaluationGateCommand(
          id: 'policy-contracts',
          executable: 'flutter',
          arguments: const <String>[
            'test',
            'test/evaluation/evaluation_policy_validator_test.dart',
            'test/evaluation/evaluation_evidence_contract_test.dart',
          ],
          workingDirectory: packageRoot,
        ),
        EvaluationGateCommand(
          id: 'headless-worker',
          executable: 'flutter',
          arguments: const <String>[
            'test',
            'test/evaluation/headless_worker_process_test.dart',
          ],
          workingDirectory: packageRoot,
        ),
        EvaluationGateCommand(
          id: 'selbrume-shop-smoke',
          executable: 'dart',
          arguments: const <String>[
            'run',
            'tool/pokemap_eval.dart',
            'run',
            'selbrume.shop.after-lysa',
          ],
          workingDirectory: packageRoot,
        ),
      ],
      execute: execute ?? _executeCommand,
    );
  }

  final List<EvaluationGateCommand> _commands;
  final EvaluationGateExecutor _execute;

  List<String> get commandIds =>
      _commands.map((command) => command.id).toList(growable: false);

  Future<EvaluationRegressionGateResult> run() async {
    final results = <EvaluationGateCommandResult>[];
    for (final command in _commands) {
      final result = await _execute(command);
      results.add(result);
      if (!result.isSuccessful) break;
    }
    return EvaluationRegressionGateResult(results);
  }
}

Future<EvaluationGateCommandResult> _executeCommand(
  EvaluationGateCommand command,
) async {
  final stopwatch = Stopwatch()..start();
  final process = await Process.run(
    command.executable,
    command.arguments,
    workingDirectory: command.workingDirectory.path,
    runInShell: false,
  );
  stopwatch.stop();
  return EvaluationGateCommandResult(
    command: command,
    exitCode: process.exitCode,
    duration: stopwatch.elapsed,
    stdout: process.stdout as String,
    stderr: process.stderr as String,
  );
}

String _nonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Value must not be blank.');
  }
  return value;
}
