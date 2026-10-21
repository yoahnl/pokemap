import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('seen consequence is typed and round-trips without a Pokemon grant', () {
    final consequence = SceneConsequence.markPokemonSeen(
      speciesId: ' bulbasaur ',
    );
    expect(consequence, isA<SceneMarkPokemonSeenConsequence>());
    expect(consequence.toJson(), {
      'kind': 'markPokemonSeen',
      'speciesId': 'bulbasaur',
    });
    expect(SceneConsequence.fromJson(consequence.toJson()), consequence);
    expect(NarrativeCommandIds.forConsequence(consequence), 'markPokemonSeen');
  });
  test('seen consequence refuses missing and blank species identities', () {
    expect(
      () => SceneConsequence.markPokemonSeen(speciesId: ' '),
      throwsFormatException,
    );
    expect(
      () => SceneConsequence.fromJson({'kind': 'markPokemonSeen'}),
      throwsFormatException,
    );
  });
  test(
    'native seen mutation preserves caught, party and storage and is idempotent',
    () {
      const before = GameState(saveId: 'seen-only');
      final once = markSpeciesSeenInGameState(before, 'bulbasaur');
      final twice = markSpeciesSeenInGameState(once, 'bulbasaur');
      expect(once.progression.seenSpeciesIds, ['bulbasaur']);
      expect(once.progression.caughtSpeciesIds, isEmpty);
      expect(once.party, before.party);
      expect(once.pokemonStorage, before.pokemonStorage);
      expect(twice.toJson(), once.toJson());
      expect(GameState.fromJson(twice.toJson()).progression.seenSpeciesIds, [
        'bulbasaur',
      ]);
    },
  );
  test('seen command is discoverable as a species picker consequence', () {
    final command = NarrativeCommandCatalog.canonical().commands.singleWhere(
      (c) => c.id == 'markPokemonSeen',
    );
    expect(command.parameters.single.id, 'speciesId');
    expect(
      command.parameters.single.kind,
      NarrativeCommandParameterKind.species,
    );
  });
}
