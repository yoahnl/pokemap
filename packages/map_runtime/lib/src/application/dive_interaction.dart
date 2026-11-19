import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../player/runtime_player_feedback.dart';
import 'dialogue_runtime_models.dart';

final class RuntimeDiveInteraction {
  const RuntimeDiveInteraction(this.session, this.ticket);
  final DialogueSession session;
  final DiveActionTicket? ticket;
}

RuntimeDiveInteraction prepareDiveInteraction({
  required MapData sourceMap,
  required MapData? targetMap,
  required GameState gameState,
  required int stateRevision,
  required String zoneId,
  ProjectManifest? project,
  GameplayWorldState? world,
  RuntimeOverworldFeedbackFormatter feedback = fallbackRuntimeOverworldFeedback,
}) {
  final evaluation = evaluateDiveAttempt(
    sourceMap: sourceMap,
    targetMap: targetMap,
    gameState: gameState,
    zoneId: zoneId,
    project: project,
    sourceWorld: world,
  );
  final DiveActionTicket? ticket;
  final String text;
  if (evaluation is CanUseDive) {
    ticket = DiveActionTicket(
      evaluation: evaluation,
      gameState: gameState,
      sourceMap: sourceMap,
      targetMap: targetMap!,
      issuedAtStateRevision: stateRevision,
    );
    text = evaluation.arrivalMovementMode == MovementMode.dive
        ? feedback(.fieldDiveConfirmDown)
        : feedback(.fieldDiveConfirmUp);
  } else {
    ticket = null;
    text = switch ((evaluation as DiveUnavailable).reason) {
      DiveBlockReason.disabled => feedback(.fieldDiveDisabled),
      DiveBlockReason.missingMove => feedback(.fieldDiveMoveMissing),
      DiveBlockReason.locked => feedback(.fieldDiveMoveLocked),
      DiveBlockReason.wrongMode => feedback(.fieldDiveSurfRequired),
      DiveBlockReason.obstructed => feedback(.fieldDiveObstructed),
      _ => feedback(.fieldDiveDestinationUnavailable),
    };
  }
  final node = YarnNode(
    title: 'DiveZone',
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: feedback(.yes),
              steps: const [],
              outcomeId: 'dive-confirmed',
            ),
            YarnChoice(
              text: feedback(.no),
              steps: const [],
              outcomeId: 'dive-declined',
            ),
          ],
          policy: const SceneDialogueChoicePolicy(
            nodeName: 'DiveZone',
            cancellation: SceneDialogueChoiceCancellation.choice(
              'dive-declined',
            ),
          ),
        ),
    ],
  );
  return RuntimeDiveInteraction(
    DialogueSession.start([node], 'DiveZone')!,
    ticket,
  );
}
