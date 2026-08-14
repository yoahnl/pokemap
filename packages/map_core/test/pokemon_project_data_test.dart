import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonSpeciesFile', () {
    test('round-trips the canonical schema', () {
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

    test('normalizes localized names in the canonical schema', () {
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

  test('all Pokemon project documents require an explicit schema version', () {
    final documents =
        <(String, Map<String, dynamic>, Object Function(Map<String, dynamic>))>[
          (
            'manifest',
            <String, dynamic>{
              'kind': 'pokemon_data_manifest',
              'meta': <String, dynamic>{},
              'catalogFiles': <String, String>{},
              'futureDataFolders': <String, String>{},
            },
            PokemonDataManifest.fromJson,
          ),
          (
            'catalog',
            <String, dynamic>{
              'kind': 'pokemon_catalog',
              'catalog': 'types',
              'meta': <String, dynamic>{},
              'entries': <Map<String, String>>[],
            },
            PokemonCatalogFile.fromJson,
          ),
          (
            'species',
            _speciesJson()..remove('schemaVersion'),
            PokemonSpeciesFile.fromJson,
          ),
          (
            'learnset',
            <String, dynamic>{'speciesId': 'bulbasaur'},
            PokemonLearnsetFile.fromJson,
          ),
          (
            'evolution',
            <String, dynamic>{'speciesId': 'bulbasaur'},
            PokemonEvolutionFile.fromJson,
          ),
          (
            'media',
            <String, dynamic>{
              'speciesId': 'bulbasaur',
              'defaultFormId': 'base',
            },
            PokemonMediaFile.fromJson,
          ),
        ];

    for (final (name, json, decode) in documents) {
      for (final (hasVersion, invalidVersion) in <(bool, Object?)>[
        (false, null),
        (true, null),
        (true, '1'),
        (true, 0),
        (true, 2),
      ]) {
        final document = <String, dynamic>{...json};
        if (hasVersion) {
          document['schemaVersion'] = invalidVersion;
        }
        expect(
          () => decode(document),
          throwsA(
            isA<UnsupportedPokemonDataSchema>().having(
              (error) => error.path,
              '$name path',
              r'$.schemaVersion',
            ),
          ),
          reason:
              '$name must reject ${hasVersion ? 'schemaVersion $invalidVersion' : 'a missing schemaVersion'}',
        );
      }
    }
  });

  test('all Pokemon project documents round-trip the current schema', () {
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
        'schemaVersion': currentPokemonDataSchemaVersion,
        'speciesId': 'bulbasaur',
        'startingMoves': <String>['tackle'],
      }).toJson(),
      PokemonEvolutionFile.fromJson(<String, dynamic>{
        'schemaVersion': currentPokemonDataSchemaVersion,
        'speciesId': 'bulbasaur',
        'evolutions': <Map<String, dynamic>>[],
      }).toJson(),
      PokemonMediaFile.fromJson(<String, dynamic>{
        'schemaVersion': currentPokemonDataSchemaVersion,
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
  'schemaVersion': currentPokemonDataSchemaVersion,
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
