import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'dialogue_runtime_models.dart';

final class RuntimeCutObstacleInteraction {
  const RuntimeCutObstacleInteraction._({required this.session, this.ticket});

  final DialogueSession session;
  final CutObstacleTicket? ticket;

  CutObstacleCommit? complete({
    required String? outcomeId,
    required MapData map,
    required GameState gameState,
    required int currentStateRevision,
  }) {
    final currentTicket = ticket;
    if (outcomeId != 'cut-confirmed' || currentTicket == null) return null;
    return commitCutObstacleAction(
      ticket: currentTicket,
      map: map,
      gameState: gameState,
      currentStateRevision: currentStateRevision,
      confirmedEntityId: currentTicket.entityId,
    );
  }
}

RuntimeCutObstacleInteraction? prepareCutObstacleInteraction({
  required MapData map,
  required GameState gameState,
  required int stateRevision,
  required String entityId,
}) {
  final evaluation = evaluateCutObstacleAttempt(
    map: map,
    gameState: gameState,
    entityId: entityId,
  );
  final String text;
  CutObstacleTicket? ticket;
  switch (evaluation) {
    case CanPromptCutObstacle():
      text = 'Cet arbre peut être coupé. Voulez-vous utiliser Coupe ?';
      final entity = map.entities.singleWhere(
        (entity) => entity.id == entityId,
      );
      ticket = CutObstacleTicket(
        fieldAction: FieldActionTicket(
          ability: FieldAbility.cut,
          targetCell: entity.pos,
          issuedAtStateRevision: stateRevision,
        ),
        instance: gameState.mapInstanceWorldState.instanceRef(map.id)!,
        entityId: entityId,
        playerPosition: gameState.playerPosition,
        playerFacing: gameState.playerFacing,
      );
    case CutObstacleUnavailable(reason: CutObstacleBlockReason.missingMove):
      text = 'Cet arbre semble pouvoir être coupé. Un Pokémon apte à utiliser Coupe est nécessaire.';
    case CutObstacleUnavailable(reason: CutObstacleBlockReason.locked):
      text = "Un Pokémon de votre équipe connaît Coupe, mais vous n’avez pas encore l’autorisation de l’utiliser.";
    case CutObstacleUnavailable():
      return null;
  }
  final node = YarnNode(
    title: 'Cut',
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: 'Oui',
              steps: const [],
              outcomeId: 'cut-confirmed',
            ),
            YarnChoice(text: 'Non', steps: const [], outcomeId: 'cut-declined'),
          ],
          policy: const SceneDialogueChoicePolicy(
            nodeName: 'Cut',
            cancellation: SceneDialogueChoiceCancellation.choice(
              'cut-declined',
            ),
          ),
        ),
    ],
  );
  return RuntimeCutObstacleInteraction._(
    session: DialogueSession.start([node], 'Cut')!,
    ticket: ticket,
  );
}
