import '../models/game_state.dart';
import '../models/periodic_reward.dart';
import '../models/periodic_encounter.dart';
import '../models/periodic_reward_reference.dart';
import '../models/scene_asset.dart';
import '../models/scene_interactive_command.dart';
import '../read_models/periodic_reward_availability.dart';
import 'narrative_condition_expression_evaluator.dart';

typedef PeriodicRewardSceneLookup =
    Iterable<SceneAsset> Function(String sceneId);

enum PeriodicRewardReferenceStatus {
  found,
  sceneMissing,
  sceneAmbiguous,
  nodeMissing,
  nodeAmbiguous,
  commandMismatch,
  rewardIdMismatch,
}

final class PeriodicRewardReferenceResolution {
  const PeriodicRewardReferenceResolution(this.status, [this.definition]) : periodicEncounter = null;
  const PeriodicRewardReferenceResolution.encounter(this.periodicEncounter)
      : status = PeriodicRewardReferenceStatus.found, definition = null;
  final PeriodicRewardReferenceStatus status;
  final PeriodicItemRewardDefinition? definition;
  final PeriodicEncounterDefinition? periodicEncounter;
  String? get label => definition?.label ?? periodicEncounter?.label;
  bool get isResolved => status == PeriodicRewardReferenceStatus.found;
}

PeriodicRewardReferenceResolution resolvePeriodicRewardReference({
  required PeriodicRewardReference reference,
  required PeriodicRewardSceneLookup lookupScenes,
}) {
  final scenes = lookupScenes(
    reference.sceneId,
  ).where((scene) => scene.id == reference.sceneId).toList();
  if (scenes.isEmpty) {
    return const PeriodicRewardReferenceResolution(
      PeriodicRewardReferenceStatus.sceneMissing,
    );
  }
  if (scenes.length != 1) {
    return const PeriodicRewardReferenceResolution(
      PeriodicRewardReferenceStatus.sceneAmbiguous,
    );
  }
  final nodes = scenes.single.graph.nodes
      .where((node) => node.id == reference.nodeId)
      .toList();
  if (nodes.isEmpty) {
    return const PeriodicRewardReferenceResolution(
      PeriodicRewardReferenceStatus.nodeMissing,
    );
  }
  if (nodes.length != 1) {
    return const PeriodicRewardReferenceResolution(
      PeriodicRewardReferenceStatus.nodeAmbiguous,
    );
  }
  final payload = nodes.single.payload;
  if (nodes.single.kind == SceneNodeKind.battle && payload is SceneBattlePayload && payload.periodicEncounter != null) {
    if (payload.periodicEncounter!.rewardId != reference.rewardId) {
      return const PeriodicRewardReferenceResolution(PeriodicRewardReferenceStatus.rewardIdMismatch);
    }
    return PeriodicRewardReferenceResolution.encounter(payload.periodicEncounter);
  }
  final command = payload is SceneActionPayload
      ? payload.interactiveCommand
      : null;
  if (nodes.single.kind != SceneNodeKind.action ||
      command is! SceneClaimPeriodicRewardInteractiveCommand) {
    return const PeriodicRewardReferenceResolution(
      PeriodicRewardReferenceStatus.commandMismatch,
    );
  }
  if (command.definition.rewardId != reference.rewardId) {
    return const PeriodicRewardReferenceResolution(
      PeriodicRewardReferenceStatus.rewardIdMismatch,
    );
  }
  return PeriodicRewardReferenceResolution(
    PeriodicRewardReferenceStatus.found,
    command.definition,
  );
}

NarrativeConditionEvaluation evaluatePeriodicRewardCondition({
  required PeriodicRewardReference reference,
  required bool expectedValue,
  required GameState gameState,
  required PeriodicRewardSceneLookup lookupScenes,
}) {
  if (!resolvePeriodicRewardReference(
    reference: reference,
    lookupScenes: lookupScenes,
  ).isResolved) {
    return const NarrativeConditionEvaluation(passed: false, unavailable: true);
  }
  final availability = readPeriodicRewardAvailability(
    calendar: gameState.gameplayCalendarState,
    rewardState: gameState.periodicRewardState,
    rewardId: reference.rewardId,
  );
  return NarrativeConditionEvaluation(
    passed: availability.matches(expectedValue: expectedValue),
    unavailable: availability.value == null,
  );
}
