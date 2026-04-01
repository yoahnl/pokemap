import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scenario_conditions.dart';

class RuntimeStoryBranching {
  const RuntimeStoryBranching({
    this.pageResolver = const EventPageResolver(),
    this.conditionEvaluator = const ScriptConditionEvaluator(),
  });

  final EventPageResolver pageResolver;
  final ScriptConditionEvaluator conditionEvaluator;

  ActiveEventPage? resolveEventPage(
    MapEventDefinition event,
    GameState state, {
    ScriptEvaluationContext? context,
  }) {
    return pageResolver.resolve(event, state, context: context);
  }

  bool evaluate(
    ScriptCondition condition,
    GameState state, {
    ScriptEvaluationContext? context,
  }) {
    return conditionEvaluator.evaluate(condition, state, context: context);
  }

  bool isTrainerDefeated(GameState state, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    if (normalizedTrainerId.isEmpty) {
      return false;
    }
    final condition = ScenarioConditions.trainerDefeated(normalizedTrainerId);
    return evaluate(condition, state);
  }

  bool canTriggerTrainerBattle(GameState state, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    if (normalizedTrainerId.isEmpty) {
      return false;
    }
    final condition =
        ScenarioConditions.trainerNotDefeated(normalizedTrainerId);
    return evaluate(condition, state);
  }
}
