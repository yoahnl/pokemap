import '../models/narrative_event_definition.dart';

final class NarrativeConditionEvaluation {
  const NarrativeConditionEvaluation({
    required this.passed,
    this.unavailable = false,
  });
  final bool passed;
  final bool unavailable;
}

NarrativeConditionEvaluation evaluateNarrativeConditionExpression(
  NarrativeEventConditionExpression expression, {
  required NarrativeConditionEvaluation Function(
    NarrativeEventCondition condition,
  )
  evaluateLeaf,
}) {
  NarrativeConditionEvaluation evaluate(
    NarrativeEventConditionExpression node,
  ) {
    switch (node) {
      case NarrativeEventConditionLeaf(:final condition):
        return evaluateLeaf(condition);
      case NarrativeEventConditionAll(:final children):
        var passed = true;
        var unavailable = false;
        for (final child in children) {
          final result = evaluate(child);
          passed = passed && result.passed;
          unavailable = unavailable || result.unavailable;
        }
        return NarrativeConditionEvaluation(
          passed: passed && !unavailable,
          unavailable: unavailable,
        );
      case NarrativeEventConditionAny(:final children):
        var passed = false;
        var unavailable = false;
        for (final child in children) {
          final result = evaluate(child);
          passed = passed || result.passed;
          unavailable = unavailable || result.unavailable;
        }
        return NarrativeConditionEvaluation(
          passed: passed,
          unavailable: !passed && unavailable,
        );
      case NarrativeEventConditionNot(:final child):
        final result = evaluate(child);
        return NarrativeConditionEvaluation(
          passed: !result.unavailable && !result.passed,
          unavailable: result.unavailable,
        );
    }
  }

  return evaluate(expression);
}
