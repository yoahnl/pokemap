import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/external_pokemon_catalog_normalizer.dart';

void main() {
  const normalizer = ExternalPokemonCatalogNormalizer();

  group('ExternalPokemonCatalogNormalizer', () {
    test('normalizes a Showdown-style catalog payload', () {
      final payload = jsonDecode(_showdownMovesPayload) as Map<String, dynamic>;

      final catalog = normalizer.normalizeShowdownCatalog(
        catalogKey: 'moves',
        payload: payload,
      );

      expect(catalog.catalog, 'moves');
      expect(catalog.kind, 'pokemon_catalog');
      expect(catalog.meta.sourcePriority, contains('showdown'));
      expect(catalog.entries, hasLength(2));
      expect(catalog.entries.first['id'], 'growl');
      expect(catalog.entries.first['name'], 'Growl');
      expect(catalog.entries.last['id'], 'tackle');
    });

    test('normalizes a PokeAPI named resource list payload', () {
      final payload =
          jsonDecode(_pokeApiGrowthRatesPayload) as Map<String, dynamic>;

      final catalog = normalizer.normalizePokeApiNamedResourceCatalog(
        catalogKey: 'growth_rates',
        payload: payload,
      );

      expect(catalog.catalog, 'growth_rates');
      expect(catalog.kind, 'pokemon_catalog');
      expect(catalog.meta.sourcePriority, contains('pokeapi'));
      expect(catalog.entries, hasLength(2));
      expect(catalog.entries.first, <String, dynamic>{
        'id': 'fast',
        'name': 'Fast',
        'sourceUrl': 'https://pokeapi.co/api/v2/growth-rate/2/',
      });
      expect(catalog.entries.last, <String, dynamic>{
        'id': 'medium_slow',
        'name': 'Medium Slow',
        'sourceUrl': 'https://pokeapi.co/api/v2/growth-rate/4/',
      });
    });

    test('fails clearly when the external catalog key is empty', () {
      final payload = jsonDecode(_showdownMovesPayload) as Map<String, dynamic>;

      expect(
        () => normalizer.normalizeShowdownCatalog(
          catalogKey: '   ',
          payload: payload,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'External catalog key cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when the Showdown payload is empty', () {
      expect(
        () => normalizer.normalizeShowdownCatalog(
          catalogKey: 'moves',
          payload: const <String, dynamic>{},
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Showdown catalog payload cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when a Showdown entry is not an object', () {
      expect(
        () => normalizer.normalizeShowdownCatalog(
          catalogKey: 'moves',
          payload: const <String, dynamic>{
            'tackle': 'not-an-object',
          },
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'Showdown catalog entry "tackle" must be an object',
          ),
        ),
      );
    });

    test('fails clearly when PokeAPI results are missing', () {
      expect(
        () => normalizer.normalizePokeApiNamedResourceCatalog(
          catalogKey: 'growth_rates',
          payload: const <String, dynamic>{},
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'PokeAPI catalog payload must contain a results list',
          ),
        ),
      );
    });

    test('fails clearly when a PokeAPI result has no name', () {
      expect(
        () => normalizer.normalizePokeApiNamedResourceCatalog(
          catalogKey: 'growth_rates',
          payload: const <String, dynamic>{
            'results': <Object?>[
              <String, Object?>{'name': ' ', 'url': 'https://pokeapi.co/foo'},
            ],
          },
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'PokeAPI catalog result at index 0 must define a name',
          ),
        ),
      );
    });
  });
}

const String _showdownMovesPayload = '''
{
  "tackle": {
    "name": "Tackle",
    "type": "Normal",
    "category": "Physical",
    "power": 40,
    "accuracy": 100,
    "pp": 35
  },
  "growl": {
    "type": "Normal",
    "category": "Status",
    "power": null,
    "accuracy": 100,
    "pp": 40
  }
}
''';

const String _pokeApiGrowthRatesPayload = '''
{
  "count": 2,
  "results": [
    {
      "name": "medium-slow",
      "url": "https://pokeapi.co/api/v2/growth-rate/4/"
    },
    {
      "name": "fast",
      "url": "https://pokeapi.co/api/v2/growth-rate/2/"
    }
  ]
}
''';
