import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../player/runtime_player_feedback.dart';
import 'dialogue_runtime_models.dart';
import 'field_move_dialogue.dart';

final class SpatialFieldTraversalInteraction {
  const SpatialFieldTraversalInteraction(this.session, this.ticket);
  final DialogueSession session;
  final SpatialFieldTraversalTicket? ticket;
}

SpatialFieldTraversalInteraction? prepareSpatialFieldTraversalInteraction({
  required FieldAbility ability,
  required MapData map,
  required GameState gameState,
  required Iterable<ProjectModel3dEntry> models,
  required String zoneId,
  required int stateRevision,
  ProjectSettings? projectSettings,
  bool Function(String)? entityIsPresent,
  SpatialActorRuntimeState? Function(String)? actorStateProvider,
  RuntimeOverworldFeedbackFormatter feedback = fallbackRuntimeOverworldFeedback,
}) {
  if (ability != FieldAbility.waterfall && ability != FieldAbility.whirlpool) {
    return null;
  }
  final evaluation = evaluateSpatialFieldTraversalAttempt(
    ability: ability,
    map: map,
    gameState: gameState,
    models: models,
    zoneId: zoneId,
    projectSettings: projectSettings,
    entityIsPresent: entityIsPresent,
    actorStateProvider: actorStateProvider,
  );
  final text = fieldTraversalDialogueMessage(
    ability,
    evaluation.reason,
    feedback,
  );
  if (text == null) return null;
  final ticket = evaluation.reason != null
      ? null
      : issueSpatialFieldTraversalTicket(
          ability: ability,
          map: map,
          gameState: gameState,
          models: models,
          zoneId: zoneId,
          stateRevision: stateRevision,
          projectSettings: projectSettings,
          entityIsPresent: entityIsPresent,
          actorStateProvider: actorStateProvider,
        );
  final node = YarnNode(
    title: 'SpatialFieldTraversal',
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: feedback(.yes),
              steps: const [],
              outcomeId: 'field-traversal-confirmed',
            ),
            YarnChoice(
              text: feedback(.no),
              steps: const [],
              outcomeId: 'field-traversal-declined',
            ),
          ],
          policy: const SceneDialogueChoicePolicy(
            nodeName: 'SpatialFieldTraversal',
            cancellation: SceneDialogueChoiceCancellation.choice(
              'field-traversal-declined',
            ),
          ),
        ),
    ],
  );
  return SpatialFieldTraversalInteraction(
    DialogueSession.start([node], node.title)!,
    ticket,
  );
}
