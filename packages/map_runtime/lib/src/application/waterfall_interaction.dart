import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'dialogue_runtime_models.dart';

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
}) {
  final configuration = switch (kind) {
    FieldActionZoneKind.waterfall => (
      FieldAbility.waterfall,
      'Cascade',
      'WaterfallZone',
    ),
    FieldActionZoneKind.whirlpool => (
      FieldAbility.whirlpool,
      'Tourbillon',
      'WhirlpoolZone',
    ),
    _ => null,
  };
  if (configuration == null) return null;
  final (ability, name, nodeName) = configuration;
  final evaluation = evaluateFieldTraversalAttempt(
    ability: ability,
    kind: kind,
    map: map,
    gameState: gameState,
    zoneId: zoneId,
    world: world,
    project: project,
  );
  final String text;
  FieldTraversalActionTicket? ticket;
  final reason = evaluation.reason;
  if (reason == null) {
    text = 'Voulez-vous utiliser $name pour traverser ce passage ?';
    final fieldAction = FieldActionTicket(
      ability: ability,
      targetCell: gameState.playerPosition,
      issuedAtStateRevision: stateRevision,
    );
    final zone = findGameplayZoneById(map, zoneId)!;
    final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
    ticket = switch (kind) {
      FieldActionZoneKind.waterfall => WaterfallActionTicket(
        fieldAction: fieldAction,
        zone: zone,
        entryState: gameState,
        instance: instance,
      ),
      FieldActionZoneKind.whirlpool => WhirlpoolActionTicket(
        fieldAction: fieldAction,
        zone: zone,
        entryState: gameState,
        instance: instance,
      ),
      _ => throw StateError('Unsupported field traversal.'),
    };
  } else {
    text = switch (reason) {
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
        'Le passage de Tourbillon doit se trouver sur l’eau.',
      _ => '',
    };
    if (text.isEmpty) return null;
  }
  final node = YarnNode(
    title: nodeName,
    steps: [
      YarnStepLine(text),
      if (ticket != null)
        YarnStepChoiceBlock(
          [
            YarnChoice(
              text: 'Oui',
              steps: const [],
              outcomeId: '${kind.name}-confirmed',
            ),
            YarnChoice(
              text: 'Non',
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
