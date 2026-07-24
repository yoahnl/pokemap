import '../contracts/evaluation_policy.dart';
import '../contracts/evaluation_scenario.dart';
import 'evaluation_command_catalog.dart';

final class EvaluationPolicyValidator {
  const EvaluationPolicyValidator();

  void validate(EvaluationScenario scenario) {
    for (final step in scenario.steps.whereType<EvaluationCommandStep>()) {
      final definition = evaluationCommandCatalog[step.operation];
      if (definition == null) {
        throw EvaluationPolicyViolation(
          stepId: step.id,
          operation: step.operation,
          reason: 'Command is not present in the V1 allowlist.',
        );
      }
      if (scenario.policy == EvaluationPolicy.certify && definition.probeOnly) {
        throw EvaluationPolicyViolation(
          stepId: step.id,
          operation: step.operation,
          reason: 'Probe-only commands are forbidden in certification runs.',
        );
      }
    }
  }

  EvaluationEvidenceLevel maximumEvidenceLevelFor(
    EvaluationScenario scenario,
  ) {
    validate(scenario);
    if (scenario.policy == EvaluationPolicy.probe) {
      return EvaluationEvidenceLevel.diagnosticOnly;
    }
    return scenario.start is EvaluationNewGameStart
        ? EvaluationEvidenceLevel.releaseEvidence
        : EvaluationEvidenceLevel.segmentEvidence;
  }
}

final class EvaluationPolicyViolation implements Exception {
  const EvaluationPolicyViolation({
    required this.stepId,
    required this.operation,
    required this.reason,
  });

  final String stepId;
  final String operation;
  final String reason;

  @override
  String toString() {
    return 'Evaluation policy rejected "$operation" at step "$stepId": '
        '$reason';
  }
}
