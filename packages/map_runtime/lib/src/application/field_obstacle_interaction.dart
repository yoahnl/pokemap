import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'dialogue_runtime_models.dart';

final class RuntimeFieldObstacleInteraction {
  const RuntimeFieldObstacleInteraction._({required this.session, this.ticket});

  final DialogueSession session;
  final FieldObstacleTicket? ticket;

  FieldObstacleCommit? complete({
    required String? outcomeId,
    required MapData map,
    required GameState gameState,
    required int currentStateRevision,
    MapData? authoringMap,
    ProjectManifest? project,
    GameplayWorldState? collisionWorld,
  }) {
    final currentTicket = ticket;
    if (outcomeId != 'field-obstacle-confirmed' || currentTicket == null) {
      return null;
    }
    return (currentTicket.fieldAction.ability == FieldAbility.strength
        ? commitStrengthActivation
        : commitDestructibleFieldObstacleAction)(
      ticket: currentTicket,
      authoringMap: authoringMap,
      project: project,
      collisionWorld: collisionWorld,
      map: map,
      gameState: gameState,
      currentStateRevision: currentStateRevision,
      confirmedEntityId: currentTicket.entityId,
    );
  }
}

RuntimeFieldObstacleInteraction? prepareFieldObstacleInteraction({
  required MapData map,
  required GameState gameState,
  required int stateRevision,
  required String entityId,
  ProjectSettings? projectSettings,
}) {
  final evaluation = evaluateFieldObstacleAttempt(
    map: map,
    gameState: gameState,
    entityId: entityId,
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
      .ability;
  if (ability == null) return null;
  final name = switch (ability) {
    FieldAbility.cut => 'Coupe',
    FieldAbility.strength => 'Force',
    FieldAbility.rockSmash => 'Éclate-Roc',
    _ => throw StateError('Unsupported obstacle ability.'),
  };
  final object = ability == FieldAbility.cut ? 'Cet arbre' : 'Ce rocher';
  final String text;
  FieldObstacleTicket? ticket;
  switch (evaluation) {
    case CanUseFieldObstacle():
      if (ability == FieldAbility.strength &&
          gameState.mapInstanceWorldState.isStrengthActive(
            gameState.mapInstanceWorldState.instanceRef(map.id)!,
          )) {
        text = 'Force est active. Avancez vers ce rocher pour le pousser.';
        break;
      }
      text =
          '$object peut ${ability == FieldAbility.cut
              ? 'être coupé'
              : ability == FieldAbility.strength
              ? 'être poussé'
              : 'être brisé'}. Voulez-vous utiliser $name ?';
      final entity = map.entities.singleWhere(
        (entity) => entity.id == entityId,
      );
      ticket = FieldObstacleTicket(
        fieldAction: FieldActionTicket(
          ability: ability,
          targetCell: entity.pos,
          issuedAtStateRevision: stateRevision,
        ),
        instance: gameState.mapInstanceWorldState.instanceRef(map.id)!,
        entityId: entityId,
        playerPosition: gameState.playerPosition,
        playerPixelPosition: gameState.playerPixelPosition,
        playerFacing: gameState.playerFacing,
      );
    case FieldObstacleUnavailable(reason: FieldObstacleBlockReason.missingMove):
      text =
          '$object bloque le passage. Un Pokémon apte à utiliser $name est nécessaire.';
    case FieldObstacleUnavailable(reason: FieldObstacleBlockReason.locked):
      text =
          "Un Pokémon de votre équipe connaît $name, mais vous n’avez pas encore l’autorisation de l’utiliser.";
    case FieldObstacleUnavailable():
      return null;
  }
  final node = YarnNode(
    title: 'FieldObstacle',
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: 'Oui',
              steps: const [],
              outcomeId: 'field-obstacle-confirmed',
            ),
            YarnChoice(
              text: 'Non',
              steps: const [],
              outcomeId: 'field-obstacle-declined',
            ),
          ],
          policy: const SceneDialogueChoicePolicy(
            nodeName: 'FieldObstacle',
            cancellation: SceneDialogueChoiceCancellation.choice(
              'field-obstacle-declined',
            ),
          ),
        ),
    ],
  );
  return RuntimeFieldObstacleInteraction._(
    session: DialogueSession.start([node], 'FieldObstacle')!,
    ticket: ticket,
  );
}
