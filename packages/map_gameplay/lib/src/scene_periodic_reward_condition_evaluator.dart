import 'package:map_core/map_core.dart';

NarrativeConditionEvaluation evaluateScenePeriodicRewardCondition({
  required SceneConditionSource source,
  required GameState gameState,
  required PeriodicRewardSceneLookup lookupScenes,
}) {
  if (source.sourceKind != SceneConditionSourceKind.periodicRewardAvailable ||
      source.rewardReference == null ||
      source.sourceId != source.rewardReference!.rewardId ||
      source.operator == SceneConditionOperator.equals) {
    return const NarrativeConditionEvaluation(passed: false, unavailable: true);
  }
  return evaluatePeriodicRewardCondition(
      reference: source.rewardReference!,
      expectedValue: source.operator == SceneConditionOperator.isTrue,
      gameState: gameState,
      lookupScenes: lookupScenes);
}
