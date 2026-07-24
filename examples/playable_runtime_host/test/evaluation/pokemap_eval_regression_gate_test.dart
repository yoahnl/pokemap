import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_regression_gate.dart';

void main() {
  test('quick gate covers contracts, worker, and Selbrume smoke', () async {
    final executed = <String>[];
    final gate = EvaluationRegressionGate.quick(
      _repositoryRoot(),
      execute: (command) async {
        executed.add(command.id);
        return EvaluationGateCommandResult(
          command: command,
          exitCode: 0,
          duration: const Duration(milliseconds: 10),
        );
      },
    );

    expect(gate.commandIds, <String>[
      'scenario-contracts',
      'policy-contracts',
      'headless-worker',
      'selbrume-shop-smoke',
    ]);

    final result = await gate.run();

    expect(result.isSuccessful, isTrue);
    expect(executed, gate.commandIds);
  });

  test('quick gate stops at the first failed command', () async {
    final executed = <String>[];
    final gate = EvaluationRegressionGate.quick(
      _repositoryRoot(),
      execute: (command) async {
        executed.add(command.id);
        return EvaluationGateCommandResult(
          command: command,
          exitCode: command.id == 'policy-contracts' ? 1 : 0,
          duration: const Duration(milliseconds: 10),
        );
      },
    );

    final result = await gate.run();

    expect(result.isSuccessful, isFalse);
    expect(result.failedCommandId, 'policy-contracts');
    expect(executed, <String>['scenario-contracts', 'policy-contracts']);
  });
}

Directory _repositoryRoot() {
  return Directory(Directory.current.path).parent.parent;
}
