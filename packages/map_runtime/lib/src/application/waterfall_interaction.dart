import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'dialogue_runtime_models.dart';

final class RuntimeWaterfallInteraction {
  const RuntimeWaterfallInteraction(this.session, this.ticket);
  final DialogueSession session;
  final WaterfallActionTicket? ticket;
}

RuntimeWaterfallInteraction? prepareWaterfallInteraction({
  required MapData map,
  required GameState gameState,
  required int stateRevision,
  required String zoneId,
  GameplayWorldState? world,
  ProjectManifest? project,
}) {
  final evaluation = evaluateWaterfallAttempt(
    map: map,
    gameState: gameState,
    zoneId: zoneId,
    world: world,
    project: project,
  );
  final String text;
  WaterfallActionTicket? ticket;
  switch (evaluation) {
    case CanUseWaterfall():
      text = 'Voulez-vous utiliser Cascade pour traverser ce passage ?';
      ticket = WaterfallActionTicket(
        fieldAction: FieldActionTicket(
          ability: FieldAbility.waterfall,
          targetCell: gameState.playerPosition,
          issuedAtStateRevision: stateRevision,
        ),
        zone: findGameplayZoneById(map, zoneId)!,
        entryState: gameState,
        instance: gameState.mapInstanceWorldState.instanceRef(map.id),
      );
    case WaterfallUnavailable(:final reason):
      text = switch (reason) {
        WaterfallBlockReason.missingMove =>
          'Un Pokémon apte à utiliser Cascade est nécessaire.',
        WaterfallBlockReason.locked =>
          'Vous n’avez pas encore l’autorisation d’utiliser Cascade.',
        WaterfallBlockReason.requiresSurf =>
          'Vous devez utiliser Surf avant de traverser cette cascade.',
        WaterfallBlockReason.wrongDirection =>
          'Placez-vous dans le sens de la cascade pour la traverser.',
        WaterfallBlockReason.obstructed =>
          'Le passage ou la sortie de la cascade est occupé.',
        _ => '',
      };
      if (text.isEmpty) return null;
  }
  final node = YarnNode(
    title: 'WaterfallZone',
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: 'Oui',
              steps: const [],
              outcomeId: 'waterfall-confirmed',
            ),
            YarnChoice(
              text: 'Non',
              steps: const [],
              outcomeId: 'waterfall-declined',
            ),
          ],
          policy: const SceneDialogueChoicePolicy(
            nodeName: 'WaterfallZone',
            cancellation: SceneDialogueChoiceCancellation.choice(
              'waterfall-declined',
            ),
          ),
        ),
    ],
  );
  return RuntimeWaterfallInteraction(
    DialogueSession.start([node], 'WaterfallZone')!,
    ticket,
  );
}
