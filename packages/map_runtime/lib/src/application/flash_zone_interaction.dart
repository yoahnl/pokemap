import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'dialogue_runtime_models.dart';

final class RuntimeFlashInteraction {
  const RuntimeFlashInteraction._({required this.session, this.ticket});
  final DialogueSession session;
  final FlashActionTicket? ticket;

  FlashCommit? complete({
    required String? outcomeId,
    required MapData map,
    required GameState gameState,
    required int currentStateRevision,
  }) {
    final current = ticket;
    if (outcomeId != 'flash-confirmed' || current == null) return null;
    return commitFlashAction(
      ticket: current,
      map: map,
      gameState: gameState,
      currentStateRevision: currentStateRevision,
    );
  }
}

RuntimeFlashInteraction? prepareFlashInteraction({
  required MapData map,
  required GameState gameState,
  required int stateRevision,
  required String zoneId,
}) {
  final evaluation = evaluateFlashAttempt(
    map: map,
    gameState: gameState,
    zoneId: zoneId,
  );
  FlashActionTicket? ticket;
  final String text;
  switch (evaluation) {
    case CanUseFlash():
      text =
          'Cette zone est sombre. Voulez-vous utiliser Flash pour l’éclairer ?';
      ticket = FlashActionTicket(
        fieldAction: FieldActionTicket(
          ability: FieldAbility.flash,
          targetCell: gameState.playerPosition,
          issuedAtStateRevision: stateRevision,
        ),
        instance: gameState.mapInstanceWorldState.instanceRef(map.id)!,
        zone: findGameplayZoneById(map, zoneId)!,
        playerPixelPosition: gameState.playerPixelPosition,
      );
    case FlashUnavailable(reason: FlashBlockReason.missingMove):
      text = 'Cette zone est sombre. Un Pokémon apte à utiliser Flash est nécessaire.';
    case FlashUnavailable(reason: FlashBlockReason.locked):
      text = 'Un Pokémon connaît Flash, mais vous n’avez pas encore l’autorisation de l’utiliser.';
    case FlashUnavailable():
      return null;
  }
  final node = YarnNode(
    title: 'FlashZone',
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: 'Oui',
              steps: const [],
              outcomeId: 'flash-confirmed',
            ),
            YarnChoice(
              text: 'Non',
              steps: const [],
              outcomeId: 'flash-declined',
            ),
          ],
          policy: const SceneDialogueChoicePolicy(
            nodeName: 'FlashZone',
            cancellation: SceneDialogueChoiceCancellation.choice(
              'flash-declined',
            ),
          ),
        ),
    ],
  );
  return RuntimeFlashInteraction._(
    session: DialogueSession.start([node], 'FlashZone')!,
    ticket: ticket,
  );
}
