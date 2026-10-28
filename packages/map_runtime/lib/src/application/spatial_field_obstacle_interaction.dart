import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'dialogue_runtime_models.dart';

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
  final name = ability == FieldAbility.cut ? 'Coupe' : 'Éclate-Roc';
  final object = ability == FieldAbility.cut ? 'Cet arbre' : 'Ce rocher';
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
  final text = switch (evaluation) {
    CanUseFieldObstacle() =>
      '$object peut ${ability == FieldAbility.cut ? 'être coupé' : 'être brisé'}. Voulez-vous utiliser $name ?',
    FieldObstacleUnavailable(reason: FieldObstacleBlockReason.missingMove) =>
      '$object bloque le passage. Un Pokémon apte à utiliser $name est nécessaire.',
    _ =>
      'Un Pokémon de votre équipe connaît $name, mais vous n’avez pas encore l’autorisation de l’utiliser.',
  };
  final node = YarnNode(
    title: 'SpatialFieldObstacle',
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
