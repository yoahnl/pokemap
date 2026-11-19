import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../player/runtime_player_feedback.dart';
import 'dialogue_runtime_models.dart';
import 'field_move_dialogue.dart';

final class RuntimeFieldTraversalInteraction {
  const RuntimeFieldTraversalInteraction(this.session, this.ticket);
  final DialogueSession session;
  final FieldTraversalActionTicket? ticket;
}

RuntimeFieldTraversalInteraction? prepareFieldTraversalInteraction({
  required FieldActionZoneKind kind,
  required MapData map,
  required GameState gameState,
  required int stateRevision,
  required String zoneId,
  GameplayWorldState? world,
  ProjectManifest? project,
  RuntimeOverworldFeedbackFormatter feedback = fallbackRuntimeOverworldFeedback,
}) {
  final configuration = switch (kind) {
    FieldActionZoneKind.waterfall => (FieldAbility.waterfall, 'WaterfallZone'),
    FieldActionZoneKind.whirlpool => (FieldAbility.whirlpool, 'WhirlpoolZone'),
    _ => null,
  };
  if (configuration == null) return null;
  final (ability, nodeName) = configuration;
  final evaluation = evaluateFieldTraversalAttempt(
    ability: ability,
    kind: kind,
    map: map,
    gameState: gameState,
    zoneId: zoneId,
    world: world,
    project: project,
  );
  final reason = evaluation.reason;
  final text = fieldTraversalDialogueMessage(ability, reason, feedback);
  if (text == null) return null;
  FieldTraversalActionTicket? ticket;
  if (reason == null) {
    final fieldAction = FieldActionTicket(
      ability: ability,
      targetCell: gameState.playerPosition,
      issuedAtStateRevision: stateRevision,
    );
    final zone = findGameplayZoneById(map, zoneId)!;
    final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
    ticket = FieldTraversalActionTicket(
      fieldAction: fieldAction,
      zone: zone,
      entryState: gameState,
      instance: instance,
    );
  }
  final node = YarnNode(
    title: nodeName,
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: feedback(.yes),
              steps: const [],
              outcomeId: '${kind.name}-confirmed',
            ),
            YarnChoice(
              text: feedback(.no),
              steps: const [],
              outcomeId: '${kind.name}-declined',
            ),
          ],
          policy: SceneDialogueChoicePolicy(
            nodeName: nodeName,
            cancellation: SceneDialogueChoiceCancellation.choice(
              '${kind.name}-declined',
            ),
          ),
        ),
    ],
  );
  return RuntimeFieldTraversalInteraction(
    DialogueSession.start([node], nodeName)!,
    ticket,
  );
}
