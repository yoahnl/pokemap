import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const service = PokemonFriendshipWalkService();
  const walk = CommittedMovement(
    kind: CommittedMovementKind.walk,
    fromCell: GridPos(x: 0, y: 0),
    toCell: GridPos(x: 1, y: 0),
  );

  test('checks each non-egg every 128 steps and persists the counter', () {
    var state = GameState(
      saveId: 'friendship',
      metadata: const {'unrelated': 'kept'},
      party: const PlayerParty(members: [
        PlayerPokemon(speciesId: 'riolu', natureId: 'hardy', abilityId: 'steadfast', friendship: 70),
        PlayerPokemon(speciesId: 'pikachu', natureId: 'hardy', abilityId: 'static', friendship: 254),
        PlayerPokemon(speciesId: 'egg', natureId: 'hardy', abilityId: 'none', isEgg: true, friendship: 5),
      ]),
    );
    var draws = 0;
    bool draw() => ++draws == 1;

    for (var i = 0; i < 127; i++) {
      state = service.advance(state, movement: walk, shouldIncrease: draw);
    }
    expect(draws, 0);
    expect(state.party.members.first.friendship, 70);
    state = gameStateFromSaveData(SaveData.fromJson(saveDataFromGameState(state).toJson()));
    state = service.advance(state, movement: walk, shouldIncrease: draw);

    expect(draws, 2);
    expect(state.party.members.map((pokemon) => pokemon.friendship), [71, 254, 5]);
    expect(state.metadata['unrelated'], 'kept');
    for (var i = 0; i < 128; i++) {
      state = service.advance(state, movement: walk, shouldIncrease: () => true);
    }
    expect(state.party.members.map((pokemon) => pokemon.friendship), [72, 255, 5]);
  });

  test('ignores blocked movement, transfers and non-adjacent jumps', () {
    const state = GameState(saveId: 'friendship');
    for (final movement in [
      const CommittedMovement(kind: CommittedMovementKind.blocked,
          fromCell: GridPos(x: 0, y: 0), toCell: GridPos(x: 1, y: 0)),
      const CommittedMovement(kind: CommittedMovementKind.warp,
          fromCell: GridPos(x: 0, y: 0), toCell: GridPos(x: 1, y: 0)),
      const CommittedMovement(kind: CommittedMovementKind.walk,
          fromCell: GridPos(x: 0, y: 0), toCell: GridPos(x: 2, y: 0)),
    ]) {
      expect(service.advance(state, movement: movement,
          shouldIncrease: () => throw StateError('unexpected draw')), same(state));
    }
  });
}
