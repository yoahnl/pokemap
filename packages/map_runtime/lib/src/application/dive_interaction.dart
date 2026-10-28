import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

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
        ? 'Voulez-vous utiliser Plongée pour descendre sous l’eau ?'
        : 'Voulez-vous utiliser Plongée pour remonter à la surface ?';
  } else {
    ticket = null;
    text = switch ((evaluation as DiveUnavailable).reason) {
      DiveBlockReason.disabled => 'Plongée est désactivée dans ce projet.',
      DiveBlockReason.missingMove =>
        'Un Pokémon apte à utiliser Plongée est nécessaire.',
      DiveBlockReason.locked =>
        'Vous n’avez pas encore l’autorisation d’utiliser Plongée.',
      DiveBlockReason.wrongMode =>
        'Utilisez Surf pour plonger depuis la surface.',
      DiveBlockReason.obstructed =>
        'L’arrivée ou le point de retour de Plongée est occupé.',
      _ => 'Ce point de Plongée n’est pas relié à une arrivée disponible.',
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
              text: 'Oui',
              steps: const [],
              outcomeId: 'dive-confirmed',
            ),
            YarnChoice(
              text: 'Non',
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
