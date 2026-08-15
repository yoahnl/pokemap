import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_species_enricher.dart';

void main() {
  test('accepts PokeAPI punctuation for a Showdown species id', () {
    final enriched = const PokeApiPokemonSpeciesEnricher().enrich(
      species: _nidoranFemale,
      pokemonSpeciesPayload: <String, dynamic>{
        'name': 'nidoran-f',
        'generation': <String, dynamic>{'name': 'generation-i'},
        'growth_rate': <String, dynamic>{'name': 'medium'},
        'color': <String, dynamic>{'name': 'blue'},
      },
    );

    expect(enriched.id, 'nidoranf');
  });
}

const PokemonSpeciesFile _nidoranFemale = PokemonSpeciesFile(
  id: 'nidoranf',
  slug: 'nidoranf',
  nationalDex: 29,
  names: <String, String>{'en': 'Nidoran-F'},
  speciesName: <String, String>{},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: <String>['poison']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 55,
    atk: 47,
    def: 52,
    spa: 40,
    spd: 40,
    spe: 41,
    bst: 275,
  ),
  abilities: PokemonSpeciesAbilities(primary: 'poisonpoint'),
  breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
  progression: PokemonSpeciesProgression(
    growthRateId: 'medium_slow',
    baseExp: 55,
    catchRate: 235,
    baseFriendship: 50,
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'nidoranf',
    evolution: 'nidoranf',
    media: 'nidoranf',
  ),
  dexContent: PokemonSpeciesDexContent(),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(),
);
