import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_combatant_ball_resolver.dart';

void main() {
  test('maps each lineup slot through the selected party indices', () {
    final resolver = BattleCombatantBallResolver.fromParty(
      gameState: GameState(
        saveId: 'ball-provenance',
        party: PlayerParty(members: [
          _pokemon('poke-ball'),
          _pokemon(null),
          _pokemon('aurora-orb'),
        ]),
      ),
      lineupPartyIndices: [2, 0, 1],
    );

    expect(resolver.resolve(isPlayerSide: true, lineupIndex: 0), 'aurora-orb');
    expect(resolver.resolve(isPlayerSide: true, lineupIndex: 1), 'poke-ball');
    expect(resolver.resolve(isPlayerSide: true, lineupIndex: 2), isNull);
  });

  test('missing and blank provenance never invents a capture item', () {
    final resolver = BattleCombatantBallResolver.fromParty(
      gameState: GameState(
        saveId: 'missing-ball-provenance',
        party: PlayerParty(members: [
          _pokemon(null),
          _pokemon(''),
          _pokemon('   '),
        ]),
      ),
      lineupPartyIndices: [0, 1, 2, -1, 10],
    );

    for (final index in [-1, 0, 1, 2, 3, 4, 10]) {
      expect(resolver.resolve(isPlayerSide: true, lineupIndex: index), isNull);
    }
    expect(resolver.resolve(isPlayerSide: false, lineupIndex: 0), isNull);
  });

  test('enemy items require an explicit map and stay separate from the player',
      () {
    final resolver = BattleCombatantBallResolver.fromParty(
      gameState: GameState(
        saveId: 'enemy-ball-provenance',
        party: PlayerParty(members: [_pokemon(' poke-ball ')]),
      ),
      lineupPartyIndices: [0],
      enemyLineupBallItemIdsByIndex: {0: ' enemy-orb ', 1: '   '},
    );

    expect(resolver.resolve(isPlayerSide: true, lineupIndex: 0), 'poke-ball');
    expect(resolver.resolve(isPlayerSide: false, lineupIndex: 0), 'enemy-orb');
    expect(resolver.resolve(isPlayerSide: false, lineupIndex: 1), isNull);
    expect(resolver.resolve(isPlayerSide: false, lineupIndex: 2), isNull);
  });

  test('copies supplied maps so another battle cannot alter its provenance',
      () {
    final player = {0: 'poke-ball'};
    final enemy = {0: 'enemy-orb'};
    final resolver = BattleCombatantBallResolver(
      playerLineupBallItemIdsByIndex: player,
      enemyLineupBallItemIdsByIndex: enemy,
    );
    player[0] = 'changed-player';
    enemy.clear();

    expect(resolver.resolve(isPlayerSide: true, lineupIndex: 0), 'poke-ball');
    expect(resolver.resolve(isPlayerSide: false, lineupIndex: 0), 'enemy-orb');
  });
}

PlayerPokemon _pokemon(String? itemId) => PlayerPokemon(
      speciesId: 'same-species',
      natureId: 'hardy',
      abilityId: 'overgrow',
      provenance:
          itemId == null ? null : PlayerPokemonProvenance(ballItemId: itemId),
    );
