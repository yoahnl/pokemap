import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../player/runtime_player_feedback.dart';
import 'dialogue_runtime_models.dart';
import 'field_move_dialogue.dart';

final class SpatialFieldObstacleInteraction {
  const SpatialFieldObstacleInteraction(this.session, this.ticket);

  final DialogueSession session;
  final SpatialFieldObstacleTicket? ticket;
}

SpatialFieldObstacleInteraction? prepareSpatialFieldObstacleInteraction({
  required MapData map,
  required GameState gameState,
  required Iterable<ProjectModel3dEntry> models,
  required String entityId,
  required double x,
  required double z,
  required EntityFacing facing,
  required int stateRevision,
  bool Function(String)? entityIsPresent,
  SpatialActorRuntimeState? Function(String)? actorStateProvider,
  ProjectSettings? projectSettings,
  RuntimeOverworldFeedbackFormatter feedback = fallbackRuntimeOverworldFeedback,
}) {
  final evaluation = evaluateSpatialFieldObstacleAttempt(
    map: map,
    gameState: gameState,
    models: models,
    entityId: entityId,
    x: x,
    z: z,
    facing: facing,
    actorStateProvider: actorStateProvider,
    entityIsPresent: entityIsPresent,
    projectSettings: projectSettings,
  );
  if (evaluation is FieldObstacleUnavailable &&
      evaluation.reason != FieldObstacleBlockReason.missingMove &&
      evaluation.reason != FieldObstacleBlockReason.locked) {
    return null;
  }
  final ability = map.entities
      .singleWhere((entity) => entity.id == entityId)
      .fieldObstacle!
      .ability!;
  final ticket = issueSpatialFieldObstacleTicket(
    map: map,
    gameState: gameState,
    models: models,
    entityId: entityId,
    x: x,
    z: z,
    facing: facing,
    stateRevision: stateRevision,
    actorStateProvider: actorStateProvider,
    entityIsPresent: entityIsPresent,
    projectSettings: projectSettings,
  );
  final text = fieldObstacleDialogueMessage(
    ability,
    evaluation is FieldObstacleUnavailable ? evaluation.reason : null,
    feedback,
  );
  final node = YarnNode(
    title: 'SpatialFieldObstacle',
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: feedback(.yes),
              steps: const [],
              outcomeId: 'field-obstacle-confirmed',
            ),
            YarnChoice(
              text: feedback(.no),
              steps: const [],
              outcomeId: 'field-obstacle-declined',
            ),
          ],
          policy: const SceneDialogueChoicePolicy(
            nodeName: 'SpatialFieldObstacle',
            cancellation: SceneDialogueChoiceCancellation.choice(
              'field-obstacle-declined',
            ),
          ),
        ),
    ],
  );
  return SpatialFieldObstacleInteraction(
    DialogueSession.start([node], node.title)!,
    ticket,
  );
}
