import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_evolution_converter.dart';

void main() {
  const converter = PokeApiPokemonEvolutionConverter();

  group('PokeApiPokemonEvolutionConverter', () {
    test('converts a direct evolution chain slice for a species', () {
      final payload =
          jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>;

      final evolution = converter.convert(
        speciesId: 'bulbasaur',
        payload: payload,
      );

      expect(evolution.speciesId, 'bulbasaur');
      expect(evolution.preEvolution, isNull);
      expect(evolution.evolutions, hasLength(1));
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(evolution.evolutions.single.method, 'level_up');
      expect(evolution.evolutions.single.minLevel, 16);
    });

    test('captures preEvolution and textual conditions for child species', () {
      final payload =
          jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>;

      final evolution = converter.convert(
        speciesId: 'ivysaur',
        payload: payload,
      );

      expect(evolution.preEvolution, 'bulbasaur');
      expect(evolution.evolutions.single.targetSpeciesId, 'venusaur');
      expect(evolution.evolutions.single.method, 'use_item');
      expect(evolution.evolutions.single.itemId, 'leaf-stone');
      expect(
        evolution.evolutions.single.conditionText['en'],
        contains('Location: special-garden'),
      );
    });

    test('fails clearly when the chain object is missing', () {
      expect(
        () => converter.convert(
          speciesId: 'bulbasaur',
          payload: const <String, dynamic>{},
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'PokeAPI evolution payload must contain a chain object',
          ),
        ),
      );
    });

    test('fails clearly when the species is absent from the chain', () {
      final payload =
          jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>;

      expect(
        () => converter.convert(
          speciesId: 'charmander',
          payload: payload,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'PokeAPI evolution chain does not include species "charmander"',
          ),
        ),
      );
    });
  });
}

const String _bulbasaurEvolutionChainPayload = '''
{
  "chain": {
    "species": {"name": "bulbasaur"},
    "evolution_details": [],
    "evolves_to": [
      {
        "species": {"name": "ivysaur"},
        "evolution_details": [
          {
            "trigger": {"name": "level-up"},
            "min_level": 16
          }
        ],
        "evolves_to": [
          {
            "species": {"name": "venusaur"},
            "evolution_details": [
              {
                "trigger": {"name": "use-item"},
                "item": {"name": "leaf-stone"},
                "location": {"name": "special-garden"}
              }
            ],
            "evolves_to": []
          }
        ]
      }
    ]
  }
}
''';
