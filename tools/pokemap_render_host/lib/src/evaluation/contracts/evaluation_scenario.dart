import 'evaluation_policy.dart';

sealed class EvaluationStart {
  const EvaluationStart();

  const factory EvaluationStart.newGame() = EvaluationNewGameStart;

  const factory EvaluationStart.checkpoint(String checkpointId) =
      EvaluationCheckpointStart;
}

final class EvaluationNewGameStart extends EvaluationStart {
  const EvaluationNewGameStart();
}

final class EvaluationCheckpointStart extends EvaluationStart {
  const EvaluationCheckpointStart(this.checkpointId)
      : assert(checkpointId != '');

  final String checkpointId;
}

sealed class EvaluationStep {
  EvaluationStep({required String id}) : id = _requireNonBlank(id, 'step id');

  final String id;
}

final class EvaluationCommandStep extends EvaluationStep {
  EvaluationCommandStep({
    required super.id,
    required String operation,
    required Map<String, Object?> arguments,
  })  : operation = _requireNonBlank(operation, 'command operation'),
        arguments = _freezeJsonMap(arguments);

  final String operation;
  final Map<String, Object?> arguments;
}

final class EvaluationAssertionStep extends EvaluationStep {
  EvaluationAssertionStep({
    required super.id,
    required String path,
    required String matcher,
    required Object? expected,
  })  : path = _requireNonBlank(path, 'assertion path'),
        matcher = _requireNonBlank(matcher, 'assertion matcher'),
        expected = _freezeJsonValue(expected);

  final String path;
  final String matcher;
  final Object? expected;
}

final class EvaluationCriterionDefinition {
  EvaluationCriterionDefinition({
    required String id,
    required List<String> stepIds,
  })  : id = _requireNonBlank(id, 'criterion id'),
        stepIds = List<String>.unmodifiable(
          stepIds.map(
            (stepId) => _requireNonBlank(stepId, 'criterion step id'),
          ),
        );

  final String id;
  final List<String> stepIds;
}

final class EvaluationScenario {
  EvaluationScenario({
    required this.schemaVersion,
    required String id,
    required String title,
    required String projectId,
    required this.policy,
    required this.start,
    required List<EvaluationStep> steps,
    List<EvaluationCriterionDefinition> criteria =
        const <EvaluationCriterionDefinition>[],
  })  : id = _requireNonBlank(id, 'scenario id'),
        title = _requireNonBlank(title, 'scenario title'),
        projectId = _requireNonBlank(projectId, 'project id'),
        steps = List<EvaluationStep>.unmodifiable(steps),
        criteria = List<EvaluationCriterionDefinition>.unmodifiable(criteria) {
    if (schemaVersion != 1) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'Only PokeMap Eval schema version 1 is supported.',
      );
    }

    final stepIds = <String>{};
    for (final step in this.steps) {
      if (!stepIds.add(step.id)) {
        throw ArgumentError.value(
          step.id,
          'steps',
          'Step ids must be unique.',
        );
      }
    }

    final criterionIds = <String>{};
    for (final criterion in this.criteria) {
      if (!criterionIds.add(criterion.id)) {
        throw ArgumentError.value(
          criterion.id,
          'criteria',
          'Criterion ids must be unique.',
        );
      }
      for (final stepId in criterion.stepIds) {
        if (!stepIds.contains(stepId)) {
          throw ArgumentError.value(
            stepId,
            'criteria',
            'Criterion "${criterion.id}" references an unknown step.',
          );
        }
      }
    }
  }

  final int schemaVersion;
  final String id;
  final String title;
  final String projectId;
  final EvaluationPolicy policy;
  final EvaluationStart start;
  final List<EvaluationStep> steps;
  final List<EvaluationCriterionDefinition> criteria;
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Value must not be blank.');
  }
  return value;
}

Map<String, Object?> _freezeJsonMap(Map<String, Object?> value) {
  return Map<String, Object?>.unmodifiable(
    value.map(
      (key, item) => MapEntry<String, Object?>(
        key,
        _freezeJsonValue(item),
      ),
    ),
  );
}

Object? _freezeJsonValue(Object? value) {
  return switch (value) {
    Map<String, Object?> map => _freezeJsonMap(map),
    List<Object?> list => List<Object?>.unmodifiable(
        list.map(_freezeJsonValue),
      ),
    _ => value,
  };
}
