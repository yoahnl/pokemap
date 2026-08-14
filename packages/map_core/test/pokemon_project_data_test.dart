import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonSpeciesFile', () {
    test('migrates a legacy document to the canonical schema', () {
      final species = PokemonSpeciesFile.fromJson(_speciesJson());

      expect(species.schemaVersion, currentPokemonDataSchemaVersion);
      expect(
        species.toJson()['schemaVersion'],
        currentPokemonDataSchemaVersion,
      );
      expect(species.refs.learnset, 'bulbasaur');
    });

    test('rejects an unsupported schema version', () {
      expect(
        () => PokemonSpeciesFile.fromJson(<String, dynamic>{
          ..._speciesJson(),
          'schemaVersion': currentPokemonDataSchemaVersion + 1,
        }),
        throwsA(
          isA<UnsupportedPokemonDataSchema>()
              .having(
                (error) => error.actualVersion,
                'actualVersion',
                currentPokemonDataSchemaVersion + 1,
              )
              .having((error) => error.path, 'path', r'$.schemaVersion'),
        ),
      );
    });

    test('preserves tolerant legacy localized-name parsing', () {
      final json = _speciesJson()
        ..['names'] = <Object?, Object?>{
          ' fr ': ' Bulbizarre ',
          '': 'ignored',
          'invalid': 7,
        };

      final species = PokemonSpeciesFile.fromJson(json);

      expect(species.names, <String, String>{'fr': 'Bulbizarre'});
    });
  });

  test('all Pokemon project documents use the shared schema policy', () {
    final documents = <Map<String, Object?>>[
      PokemonDataManifest.fromJson(<String, dynamic>{
        'schemaVersion': currentPokemonDataSchemaVersion,
        'kind': 'pokemon_data_manifest',
        'meta': <String, dynamic>{},
        'catalogFiles': <String, String>{'types': 'catalogs/types.json'},
        'futureDataFolders': <String, String>{},
      }).toJson(),
      PokemonCatalogFile.fromJson(<String, dynamic>{
        'schemaVersion': currentPokemonDataSchemaVersion,
        'kind': 'pokemon_catalog',
        'catalog': 'types',
        'meta': <String, dynamic>{},
        'entries': <Map<String, String>>[
          <String, String>{'id': 'grass'},
        ],
      }).toJson(),
      PokemonLearnsetFile.fromJson(<String, dynamic>{
        'speciesId': 'bulbasaur',
        'startingMoves': <String>['tackle'],
      }).toJson(),
      PokemonEvolutionFile.fromJson(<String, dynamic>{
        'speciesId': 'bulbasaur',
        'evolutions': <Map<String, dynamic>>[],
      }).toJson(),
      PokemonMediaFile.fromJson(<String, dynamic>{
        'speciesId': 'bulbasaur',
        'defaultFormId': 'base',
        'variants': <String, dynamic>{},
      }).toJson(),
    ];

    expect(
      documents.map((document) => document['schemaVersion']),
      everyElement(currentPokemonDataSchemaVersion),
    );
  });

  test('PokemonSpeciesIndex is deterministic and rejects duplicate ids', () {
    const bulbasaur = PokemonSpeciesIndexEntry(
      id: 'bulbasaur',
      nationalDex: 1,
      primaryName: 'Bulbizarre',
      types: <String>['grass', 'poison'],
      relativePath: 'species/0001-bulbasaur.json',
    );
    const ivysaur = PokemonSpeciesIndexEntry(
      id: 'ivysaur',
      nationalDex: 2,
      primaryName: 'Herbizarre',
      types: <String>['grass', 'poison'],
      relativePath: 'species/0002-ivysaur.json',
    );

    final index = PokemonSpeciesIndex(<PokemonSpeciesIndexEntry>[
      ivysaur,
      bulbasaur,
    ]);

    expect(index.entries.map((entry) => entry.id), <String>[
      'bulbasaur',
      'ivysaur',
    ]);
    expect(index.byId('ivysaur'), same(ivysaur));
    expect(
      () =>
          PokemonSpeciesIndex(<PokemonSpeciesIndexEntry>[bulbasaur, bulbasaur]),
      throwsStateError,
    );
  });
}

Map<String, dynamic> _speciesJson() => <String, dynamic>{
  'id': 'bulbasaur',
  'slug': 'bulbasaur',
  'nationalDex': 1,
  'names': <String, String>{'fr': 'Bulbizarre'},
  'speciesName': <String, String>{'fr': 'Pokémon Graine'},
  'genIntroduced': 1,
  'typing': <String, dynamic>{
    'types': <String>['grass', 'poison'],
  },
  'baseStats': <String, int>{
    'hp': 45,
    'atk': 49,
    'def': 49,
    'spa': 65,
    'spd': 65,
    'spe': 45,
    'bst': 318,
  },
  'abilities': <String, dynamic>{
    'primary': 'overgrow',
    'hidden': 'chlorophyll',
  },
  'breeding': <String, dynamic>{
    'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
  },
  'progression': <String, dynamic>{
    'growthRateId': 'medium_slow',
    'baseExp': 64,
    'catchRate': 45,
    'baseFriendship': 50,
  },
  'refs': <String, String>{
    'learnset': 'bulbasaur',
    'evolution': 'bulbasaur',
    'media': 'bulbasaur',
  },
};
