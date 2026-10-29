import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'dialogue_runtime_models.dart';

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
  final name = ability == FieldAbility.waterfall ? 'Cascade' : 'Tourbillon';
  final text = switch (evaluation.reason) {
    null => 'Voulez-vous utiliser $name pour traverser ce passage ?',
    FieldTraversalBlockReason.missingMove =>
      'Un Pokémon apte à utiliser $name est nécessaire.',
    FieldTraversalBlockReason.locked =>
      'Vous n’avez pas encore l’autorisation d’utiliser $name.',
    FieldTraversalBlockReason.requiresSurf =>
      'Vous devez utiliser Surf avant de traverser ce passage.',
    FieldTraversalBlockReason.wrongDirection =>
      'Placez-vous dans le sens du passage pour le traverser.',
    FieldTraversalBlockReason.obstructed =>
      'Le passage ou sa sortie est occupé.',
    FieldTraversalBlockReason.requiresWater =>
      'Ce passage doit se trouver sur l’eau.',
    _ => '',
  };
  if (text.isEmpty) return null;
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
              text: 'Oui',
              steps: const [],
              outcomeId: 'field-traversal-confirmed',
            ),
            YarnChoice(
              text: 'Non',
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
