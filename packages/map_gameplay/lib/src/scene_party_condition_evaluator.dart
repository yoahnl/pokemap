import 'package:map_core/map_core.dart';

import 'field_ability_gate.dart';
import 'game_state_mutations.dart';

final class ScenePartyConditionContext {
  ScenePartyConditionContext({
    Iterable<String>? availableMoveIds,
    Iterable<FieldAbility> supportedFieldAbilities = const [],
    this.projectSettings,
  })  : availableMoveIds = availableMoveIds == null
            ? null
            : Set.unmodifiable(availableMoveIds),
        supportedFieldAbilities = Set.unmodifiable(supportedFieldAbilities);

  const ScenePartyConditionContext.unavailable()
      : availableMoveIds = null,
        supportedFieldAbilities = const {},
        projectSettings = null;

  final Set<String>? availableMoveIds;
  final Set<FieldAbility> supportedFieldAbilities;
  final ProjectSettings? projectSettings;
}

bool evaluateScenePartyCondition({
  required SceneConditionSource source,
  required GameState gameState,
  ScenePartyConditionContext context =
      const ScenePartyConditionContext.unavailable(),
}) {
  final kind = source.partyConditionKind;
  final expected = source.partyExpected;
  if (kind == null || expected == null) {
    throw ArgumentError.value(source, 'source', 'Invalid party condition.');
  }
  final bool matched;
  switch (kind) {
    case ScenePartyConditionKind.canReceivePokemon:
      matched = const GameStateMutations()
              .planPokemonAcquisitionDestination(gameState)
              .destination !=
          CaptureDestinationKind.none;
    case ScenePartyConditionKind.knowsMove:
    case ScenePartyConditionKind.hasUsableMove:
      final moveId = source.partyMoveId!;
      final ids = context.availableMoveIds;
      if (ids == null) {
        throw StateError(
            'The Scene party condition requires the active move catalog.');
      }
      if (!ids.contains(moveId)) {
        throw StateError('Unknown Scene party move reference: $moveId.');
      }
      final members = gameState.party.members
          .where((member) => !member.isEgg && member.knownMoveIds.contains(moveId));
      if (kind == ScenePartyConditionKind.knowsMove) {
        matched = members.isNotEmpty;
      } else {
        var usable = false;
        for (final member in members.where((member) => !member.isFainted)) {
          final pp = member.currentPpByMoveId?[moveId];
          if (pp == null) {
            throw StateError(
                'Current PP are unavailable for Scene party move $moveId.');
          }
          if (pp > 0) usable = true;
        }
        matched = usable;
      }
    case ScenePartyConditionKind.canUseFieldAbility:
      matched = evaluateFieldAbilityGate(
            ability: source.partyFieldAbility!,
            supportedAbilities: context.supportedFieldAbilities,
            unlockedFieldAbilities:
                gameState.progression.unlockedFieldAbilities.toSet(),
            party: gameState.party,
            projectSettings: context.projectSettings,
          ).status ==
          FieldAbilityGateStatus.usable;
  }
  return matched == expected;
}
