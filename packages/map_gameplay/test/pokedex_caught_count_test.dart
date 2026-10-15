import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final range = PokedexSpeciesRange(firstNationalDex: 1, lastNationalDex: 151);
  final index = PokemonSpeciesIndex([
    for (var n = 1; n <= 21; n++)
      PokemonSpeciesIndexEntry(
          id: 'species_$n',
          nationalDex: n,
          primaryName: 'Species $n',
          types: const ['normal'],
          relativePath: '$n.json'),
    const PokemonSpeciesIndexEntry(
        id: 'species_1_form',
        nationalDex: 1,
        primaryName: 'Form',
        types: ['normal'],
        relativePath: 'form.json'),
    const PokemonSpeciesIndexEntry(
        id: 'species_152',
        nationalDex: 152,
        primaryName: 'Other range',
        types: ['normal'],
        relativePath: '152.json'),
    const PokemonSpeciesIndexEntry(
        id: 'missing_number',
        nationalDex: 0,
        primaryName: 'Missing',
        types: ['normal'],
        relativePath: 'missing.json'),
  ]);
  GameState state(int caught) => GameState(
      saveId: 'dex',
      progression: PlayerProgression(
          caughtSpeciesIds: [for (var n = 1; n <= caught; n++) 'species_$n']));
  int count(GameState value) => countPokedexCaughtSpecies(
      gameState: value, speciesIndex: index, range: range);

  for (final caught in [0, 19, 20, 21]) {
    test(
        'caught $caught resolves the native twenty-species gate and its inverse',
        () {
      final value = state(caught);
      for (final expected in [true, false]) {
        final source = SceneConditionSource.pokedexCaughtAtLeast(
            range: range, minimum: 20, expected: expected);
        expect(
            evaluateScenePokedexCaughtCondition(
                source: SceneConditionSource.fromJson(source.toJson()),
                gameState: value,
                speciesIndex: index),
            expected ? caught >= 20 : caught < 20);
      }
      expect(count(value), caught);
    });
  }
  test('seen species never substitute for caught history', () {
    expect(
        count(state(0).copyWith(
            progression: PlayerProgression(
                seenSpeciesIds: state(20).progression.caughtSpeciesIds))),
        0);
  });
  test('repeated captures and form rows count one canonical national species',
      () {
    expect(
        count(state(0).copyWith(
            progression: const PlayerProgression(caughtSpeciesIds: [
          'species_1',
          'species_1',
          'species_1_form'
        ]))),
        1);
  });
  test('known species outside the national range do not count', () {
    expect(
        count(state(0).copyWith(
            progression:
                const PlayerProgression(caughtSpeciesIds: ['species_152']))),
        0);
  });
  for (final id in ['unknown', 'missing_number']) {
    test(
        'unresolved canonical species $id fails closed without changing history',
        () {
      final value = state(20).copyWith(
          progression: PlayerProgression(caughtSpeciesIds: [
        ...state(20).progression.caughtSpeciesIds,
        id
      ]));
      expect(
          () => count(value),
          throwsA(isA<PokedexCaughtCountUnavailable>()
              .having((error) => error.speciesIds, 'speciesIds', [id])));
      expect(value.progression.caughtSpeciesIds, hasLength(21));
    });
  }
  test(
      'actual PC deposit preserves historical count instead of measuring party or boxes',
      () {
    final value = state(20).copyWith(
        party: PlayerParty(members: [
      for (final id in ['species_1', 'species_2'])
        PlayerPokemon(
            speciesId: id,
            natureId: 'docile',
            abilityId: 'ability',
            currentHp: 10),
    ]));
    final moved =
        const PlayerStorageOperations().deposit(state: value, partyIndex: 1);
    expect(moved.isSuccess, isTrue);
    expect(moved.state.party.members, hasLength(1));
    expect(moved.state.pokemonStorage.storedPokemon, hasLength(1));
    expect(count(value), 20);
    expect(count(moved.state), 20);
    expect(count(GameState.fromJson(moved.state.toJson())), 20);
  });
  test('other condition kinds cannot invoke the caught-count evaluator', () {
    expect(
        () => evaluateScenePokedexCaughtCondition(
            source: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.inventoryItem,
                sourceId: 'everstone',
                operator: SceneConditionOperator.isTrue),
            gameState: state(20),
            speciesIndex: index),
        throwsArgumentError);
  });
}
