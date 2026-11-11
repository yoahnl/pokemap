import 'package:map_core/map_core.dart';

import 'committed_movement.dart';

final class PokemonFriendshipWalkService {
  const PokemonFriendshipWalkService();

  static const counterMetadataKey = 'avelune.friendship.walk_steps.v1';

  GameState advance(
    GameState state, {
    required CommittedMovement movement,
    required bool Function() shouldIncrease,
  }) {
    final units = const CommittedMovementStepPolicy(
      forcedMovement: ForcedMovementStepPolicy.include,
    ).unitsFor(movement);
    if (units == 0) return state;

    final saved = state.metadata[counterMetadataKey];
    final current = saved == null ? 0 : int.tryParse(saved);
    if (current == null || current < 0 || current >= 128) {
      throw const FormatException('Invalid friendship walking counter.');
    }
    final next = current + units;
    final members = next < 128
        ? state.party.members
        : [
            for (final pokemon in state.party.members)
              if (!pokemon.isEgg && shouldIncrease())
                pokemon.copyWith(friendship: (pokemon.friendship + 1).clamp(0, 255))
              else
                pokemon,
          ];
    return state.copyWith(
      party: next < 128 ? state.party : state.party.copyWith(members: members),
      metadata: {...state.metadata, counterMetadataKey: '${next % 128}'},
    );
  }
}
