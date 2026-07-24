import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_policy_validator.dart';

void main() {
  const validator = EvaluationPolicyValidator();

  test('rejects probe operations before a certify run starts', () {
    final scenario = _scenario(
      policy: EvaluationPolicy.certify,
      start: const EvaluationStart.newGame(),
      operation: 'probe.goto',
      arguments: const <String, Object?>{
        'mapId': 'map_port_brisants',
        'x': 12,
        'y': 8,
      },
    );

    expect(
      () => validator.validate(scenario),
      throwsA(
        isA<EvaluationPolicyViolation>()
            .having((error) => error.stepId, 'stepId', 'operation')
            .having((error) => error.operation, 'operation', 'probe.goto'),
      ),
    );
  });

  test('rejects unknown operations fail closed', () {
    final scenario = _scenario(
      policy: EvaluationPolicy.probe,
      start: const EvaluationStart.newGame(),
      operation: 'unknown.command',
    );

    expect(
      () => validator.validate(scenario),
      throwsA(
        isA<EvaluationPolicyViolation>().having(
          (error) => error.operation,
          'operation',
          'unknown.command',
        ),
      ),
    );
  });

  test('calculates release evidence upper bound only from a clean new game',
      () {
    final scenario = _scenario(
      policy: EvaluationPolicy.certify,
      start: const EvaluationStart.newGame(),
      operation: 'game.new',
    );

    expect(
      validator.maximumEvidenceLevelFor(scenario),
      EvaluationEvidenceLevel.releaseEvidence,
    );
  });

  test('a certified checkpoint produces segment evidence', () {
    final scenario = _scenario(
      policy: EvaluationPolicy.certify,
      start: const EvaluationStart.checkpoint('after-lysa'),
      operation: 'service.shop.inspect',
    );

    expect(
      validator.maximumEvidenceLevelFor(scenario),
      EvaluationEvidenceLevel.segmentEvidence,
    );
  });

  test('a probe run can use shortcuts but stays diagnostic only', () {
    final scenario = _scenario(
      policy: EvaluationPolicy.probe,
      start: const EvaluationStart.checkpoint('after-lysa'),
      operation: 'probe.setMoney',
      arguments: const <String, Object?>{'value': 1000},
    );

    expect(() => validator.validate(scenario), returnsNormally);
    expect(
      validator.maximumEvidenceLevelFor(scenario),
      EvaluationEvidenceLevel.diagnosticOnly,
    );
  });
}

EvaluationScenario _scenario({
  required EvaluationPolicy policy,
  required EvaluationStart start,
  required String operation,
  Map<String, Object?> arguments = const <String, Object?>{},
}) {
  return EvaluationScenario(
    schemaVersion: 1,
    id: 'selbrume.policy-test',
    title: 'Policy test',
    projectId: 'selbrume',
    policy: policy,
    start: start,
    steps: <EvaluationStep>[
      EvaluationCommandStep(
        id: 'operation',
        operation: operation,
        arguments: arguments,
      ),
    ],
  );
}
