import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimePokemonSpeciesLoader', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp(
        'runtime_species_loader_',
      );
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test(
        'loads the requested species without failing on unrelated invalid files',
        () async {
      final speciesDir = Directory(
        p.join(tempRoot.path, 'data', 'pokemon', 'species'),
      );
      await speciesDir.create(recursive: true);

      await File(p.join(speciesDir.path, 'targetmon.json')).writeAsString(
        jsonEncode(<String, dynamic>{
          'id': 'targetmon',
          'typing': <String, dynamic>{
            'types': <String>['grass'],
          },
          'baseStats': <String, dynamic>{
            'hp': 45,
            'atk': 49,
            'def': 49,
            'spa': 65,
            'spd': 65,
            'spe': 45,
          },
          'abilities': <String, dynamic>{
            'primary': 'overgrow',
          },
          'refs': <String, dynamic>{
            'learnset': 'targetmon',
          },
          'progression': <String, dynamic>{
            'growthRateId': 'medium_slow',
            'baseExp': 64,
            'catchRate': 45,
          },
        }),
      );
      await File(p.join(speciesDir.path, 'broken.json')).writeAsString(
        '{this is not valid json',
      );

      final loader = RuntimePokemonSpeciesLoader();
      final species = await loader.loadById(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          speciesDir: 'data/pokemon/species',
        ),
        speciesId: 'targetmon',
      );

      expect(species.id, 'targetmon');
      expect(species.primaryAbilityId, 'overgrow');
      expect(species.growthRateId, 'medium_slow');
      expect(species.baseExp, 64);
      expect(species.catchRate, 45);
    });

    test('fails closed when progression data is absent', () async {
      await _writeSpecies(tempRoot, progression: null);

      expect(
        () => RuntimePokemonSpeciesLoader().loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'targetmon',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('progression'),
          ),
        ),
      );
    });

    test('fails closed when progression data is not an object', () async {
      await _writeSpecies(tempRoot, progression: <String>[]);

      expect(
        () => RuntimePokemonSpeciesLoader().loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'targetmon',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('progression'),
          ),
        ),
      );
    });

    final invalidProgressionCases = <String, Map<String, dynamic>>{
      'unsupported growth rate': <String, dynamic>{
        'growthRateId': 'unknown',
        'baseExp': 64,
        'catchRate': 45,
      },
      'missing base experience': <String, dynamic>{
        'growthRateId': 'medium_slow',
        'catchRate': 45,
      },
      'non-integer base experience': <String, dynamic>{
        'growthRateId': 'medium_slow',
        'baseExp': 64.5,
        'catchRate': 45,
      },
      'non-positive base experience': <String, dynamic>{
        'growthRateId': 'medium_slow',
        'baseExp': 0,
        'catchRate': 45,
      },
      'catch rate below range': <String, dynamic>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 0,
      },
      'catch rate above range': <String, dynamic>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 256,
      },
    };
    for (final invalidCase in invalidProgressionCases.entries) {
      test('fails closed for ${invalidCase.key}', () async {
        await _writeSpecies(tempRoot, progression: invalidCase.value);

        expect(
          () => RuntimePokemonSpeciesLoader().loadById(
            projectRootDirectory: tempRoot.path,
            pokemonConfig: const ProjectPokemonConfig(
              speciesDir: 'data/pokemon/species',
            ),
            speciesId: 'targetmon',
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('progression'),
            ),
          ),
        );
      });
    }

    for (final growthRateId in <String>[
      'fast',
      'fast_then_very_slow',
      'medium',
      'medium_fast',
      'medium_slow',
      'slow',
      'slow_then_very_fast',
    ]) {
      test('accepts canonical growth profile $growthRateId', () async {
        await _writeSpecies(
          tempRoot,
          progression: <String, dynamic>{
            'growthRateId': growthRateId,
            'baseExp': 64,
            'catchRate': 45,
          },
        );

        final species = await RuntimePokemonSpeciesLoader().loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'targetmon',
        );

        expect(species.growthRateId, growthRateId);
      });
    }

    test('rejects traversal, slash, and backslash species ids', () async {
      final speciesDir = Directory(
        p.join(tempRoot.path, 'data', 'pokemon', 'species'),
      );
      await speciesDir.create(recursive: true);
      for (final unsafeSpeciesId in <String>[
        '../targetmon',
        'nested/targetmon',
        r'nested\targetmon',
        '.',
        '..',
        ' targetmon',
      ]) {
        await _writeValidSpeciesFile(
          File(p.join(speciesDir.path, '$unsafeSpeciesId.json')),
          declaredId: unsafeSpeciesId,
        );

        await expectLater(
          () => RuntimePokemonSpeciesLoader().loadById(
            projectRootDirectory: tempRoot.path,
            pokemonConfig: const ProjectPokemonConfig(
              speciesDir: 'data/pokemon/species',
            ),
            speciesId: unsafeSpeciesId,
          ),
          throwsA(isA<RuntimeBattleSetupException>()),
        );
      }
    });

    test('cannot load a species file outside the project root', () async {
      final projectRoot = Directory(p.join(tempRoot.path, 'project'));
      final externalSpeciesDir = Directory(p.join(tempRoot.path, 'outside'));
      await projectRoot.create(recursive: true);
      await _writeValidSpeciesFile(
        File(p.join(externalSpeciesDir.path, 'targetmon.json')),
        declaredId: 'targetmon',
      );

      for (final config in <ProjectPokemonConfig>[
        const ProjectPokemonConfig(speciesDir: '../outside'),
        ProjectPokemonConfig(speciesDir: externalSpeciesDir.path),
      ]) {
        await expectLater(
          () => RuntimePokemonSpeciesLoader().loadById(
            projectRootDirectory: projectRoot.path,
            pokemonConfig: config,
            speciesId: 'targetmon',
          ),
          throwsA(isA<RuntimeBattleSetupException>()),
        );
      }
    });

    test('fails with a typed setup error when abilities is not an object',
        () async {
      final file = File(
        p.join(
          tempRoot.path,
          'data',
          'pokemon',
          'species',
          'targetmon.json',
        ),
      );
      for (final rawAbilities in <Object>[
        <Object?>[],
        'overgrow',
      ]) {
        await _writeValidSpeciesFile(
          file,
          declaredId: 'targetmon',
          abilities: rawAbilities,
        );

        await expectLater(
          () => RuntimePokemonSpeciesLoader().loadById(
            projectRootDirectory: tempRoot.path,
            pokemonConfig: const ProjectPokemonConfig(
              speciesDir: 'data/pokemon/species',
            ),
            speciesId: 'targetmon',
          ),
          throwsA(
            isA<RuntimeBattleSetupException>().having(
              (error) => error.debugDetails,
              'debugDetails',
              contains('abilities'),
            ),
          ),
        );
      }
    });

    test('rejects a future shared species schema explicitly', () async {
      final file = File(
        p.join(
          tempRoot.path,
          'data',
          'pokemon',
          'species',
          'targetmon.json',
        ),
      );
      await _writeValidSpeciesFile(
        file,
        declaredId: 'targetmon',
        schemaVersion: currentPokemonDataSchemaVersion + 1,
      );

      await expectLater(
        () => RuntimePokemonSpeciesLoader().loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'targetmon',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('schemaVersion'),
          ),
        ),
      );
    });
  });
}

Future<void> _writeSpecies(
  Directory root, {
  required Object? progression,
}) async {
  final speciesDir = Directory(
    p.join(root.path, 'data', 'pokemon', 'species'),
  );
  await speciesDir.create(recursive: true);
  final file = File(p.join(speciesDir.path, 'targetmon.json'));
  await file.writeAsString(
    jsonEncode(<String, dynamic>{
      'id': 'targetmon',
      'typing': <String, dynamic>{
        'types': <String>['grass']
      },
      'baseStats': <String, dynamic>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, dynamic>{'primary': 'overgrow'},
      'refs': <String, dynamic>{'learnset': 'targetmon'},
      if (progression != null) 'progression': progression,
    }),
  );
}

Future<void> _writeValidSpeciesFile(
  File file, {
  required String declaredId,
  Object abilities = const <String, dynamic>{'primary': 'overgrow'},
  int? schemaVersion,
}) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode(<String, dynamic>{
      if (schemaVersion != null) 'schemaVersion': schemaVersion,
      'id': declaredId,
      'typing': <String, dynamic>{
        'types': <String>['grass'],
      },
      'baseStats': <String, dynamic>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': abilities,
      'refs': <String, dynamic>{'learnset': declaredId},
      'progression': <String, dynamic>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
      },
    }),
  );
}
