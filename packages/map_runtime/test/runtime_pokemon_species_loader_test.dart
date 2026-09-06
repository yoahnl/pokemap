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

    test('rejects a disabled species without blocking enabled neighbors',
        () async {
      final file =
          File(p.join(tempRoot.path, 'data/pokemon/species/disabled.json'));
      await _writeValidSpeciesFile(file, declaredId: 'disabled');
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      data['classification'] = {'isEnabledInProject': false};
      await file.writeAsString(jsonEncode(data));
      await _writeValidSpeciesFile(
          File(p.join(file.parent.path, 'enabled.json')),
          declaredId: 'enabled');
      final loader = RuntimePokemonSpeciesLoader();
      const config =
          ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1);
      await expectLater(
          loader.loadById(
            projectRootDirectory: tempRoot.path,
            pokemonConfig: config,
            speciesId: 'disabled',
          ),
          throwsA(isA<RuntimeBattleSetupException>()
              .having((e) => e.message, 'message', contains('désactivée'))));
      expect(
          (await loader.loadById(
            projectRootDirectory: tempRoot.path,
            pokemonConfig: config,
            speciesId: 'enabled',
          ))
              .id,
          'enabled');
    });

    test('reuses one catalog snapshot across species ids', () async {
      final speciesDir = Directory(
        p.join(tempRoot.path, 'data', 'pokemon', 'species'),
      );
      await speciesDir.create(recursive: true);
      await _writeValidSpeciesFile(
        File(p.join(speciesDir.path, 'z-bulbasaur.json')),
        declaredId: 'bulbasaur',
      );
      await _writeValidSpeciesFile(
        File(p.join(speciesDir.path, 'a-ivysaur.json')),
        declaredId: 'ivysaur',
      );

      final metrics = _CountingRuntimePokemonSpeciesSnapshotMetrics();
      final loader = RuntimePokemonSpeciesLoader(snapshotMetrics: metrics);
      final species = await Future.wait(<Future<RuntimePokemonSpecies>>[
        loader.loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'bulbasaur',
        ),
        loader.loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'ivysaur',
        ),
        loader.loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'bulbasaur',
        ),
      ]);

      expect(species.map((entry) => entry.id), <String>[
        'bulbasaur',
        'ivysaur',
        'bulbasaur',
      ]);
      expect(metrics.snapshotBuilds, 1);
      expect(metrics.directoryListings, 1);
      expect(metrics.speciesJsonReads, 2);
      expect(loader.debugActualReadCount, 2);
    });

    test('projects the complete runtime species view from the snapshot',
        () async {
      final speciesDir = Directory(
        p.join(tempRoot.path, 'data', 'pokemon', 'species'),
      );
      await speciesDir.create(recursive: true);
      await File(p.join(speciesDir.path, 'noncanonical-name.json'))
          .writeAsString(
        jsonEncode(<String, dynamic>{
          'schemaVersion': currentPokemonDataSchemaVersion,
          'id': 'targetmon',
          'names': <String, String>{
            'en': 'Targetmon',
            'fr': 'Ciblemon',
          },
          'forms': <String, dynamic>{'formId': 'summer'},
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
            'secondary': 'chlorophyll',
            'hidden': 'leaf_guard',
          },
          'breeding': <String, dynamic>{
            'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
          },
          'refs': <String, dynamic>{'learnset': 'targetmon'},
          'progression': <String, dynamic>{
            'growthRateId': 'medium_slow',
            'baseExp': 64,
            'catchRate': 45,
            'baseFriendship': 70,
          },
        }),
      );

      final species = await RuntimePokemonSpeciesLoader().loadById(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
        speciesId: 'targetmon',
      );

      expect(species.formId, 'summer');
      expect(species.displayName('fr-FR'), 'Ciblemon');
      expect(species.displayName('de'), 'targetmon');
      expect(species.primaryAbilityId, 'overgrow');
      expect(species.standardAbilityIds, <String>['overgrow', 'chlorophyll']);
      expect(
        species.abilityIds,
        <String>['overgrow', 'chlorophyll', 'leaf_guard'],
      );
      expect(species.genderRatio, <String, double>{
        'male': 0.875,
        'female': 0.125,
      });
      expect(species.growthRateId, 'medium_slow');
      expect(species.baseExp, 64);
      expect(species.catchRate, 45);
      expect(species.baseFriendship, 70);
    });

    test('rejects duplicate ids with deterministic file ordering', () async {
      final speciesDir = Directory(
        p.join(tempRoot.path, 'data', 'pokemon', 'species'),
      );
      await _writeValidSpeciesFile(
        File(p.join(speciesDir.path, 'z-copy.json')),
        declaredId: 'bulbasaur',
      );
      await _writeValidSpeciesFile(
        File(p.join(speciesDir.path, 'a-original.json')),
        declaredId: 'bulbasaur',
      );

      await expectLater(
        RuntimePokemonSpeciesLoader().loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(contains('a-original.json'), contains('z-copy.json')),
          ),
        ),
      );
    });

    test('retries catalog snapshot construction after a failure', () async {
      final speciesDir = Directory(
        p.join(tempRoot.path, 'data', 'pokemon', 'species'),
      );
      await speciesDir.create(recursive: true);
      final speciesFile = File(p.join(speciesDir.path, 'bulbasaur.json'));
      await speciesFile.writeAsString('{ invalid json');
      final metrics = _CountingRuntimePokemonSpeciesSnapshotMetrics();
      final loader = RuntimePokemonSpeciesLoader(snapshotMetrics: metrics);

      await expectLater(
        loader.loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'bulbasaur',
        ),
        throwsA(isA<RuntimeBattleSetupException>()),
      );
      await _writeValidSpeciesFile(
        speciesFile,
        declaredId: 'bulbasaur',
      );

      final species = await loader.loadById(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          speciesDir: 'data/pokemon/species',
        ),
        speciesId: 'bulbasaur',
      );

      expect(species.id, 'bulbasaur');
      expect(metrics.snapshotBuilds, 2);
      expect(metrics.directoryListings, 2);
      expect(metrics.speciesJsonReads, 2);
    });

    test('isolates catalog snapshots by project root', () async {
      final otherRoot = await Directory.systemTemp.createTemp(
        'runtime_species_loader_other_',
      );
      addTearDown(() async {
        if (await otherRoot.exists()) {
          await otherRoot.delete(recursive: true);
        }
      });
      await _writeValidSpeciesFile(
        File(
          p.join(
            tempRoot.path,
            'data',
            'pokemon',
            'species',
            'bulbasaur.json',
          ),
        ),
        declaredId: 'bulbasaur',
        baseHp: 45,
      );
      await _writeValidSpeciesFile(
        File(
          p.join(
            otherRoot.path,
            'data',
            'pokemon',
            'species',
            'bulbasaur.json',
          ),
        ),
        declaredId: 'bulbasaur',
        baseHp: 60,
      );
      final metrics = _CountingRuntimePokemonSpeciesSnapshotMetrics();
      final loader = RuntimePokemonSpeciesLoader(snapshotMetrics: metrics);

      final first = await loader.loadById(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
        speciesId: 'bulbasaur',
      );
      final second = await loader.loadById(
        projectRootDirectory: otherRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
        speciesId: 'bulbasaur',
      );

      expect(first.baseHp, 45);
      expect(second.baseHp, 60);
      expect(metrics.snapshotBuilds, 2);
      expect(metrics.directoryListings, 2);
      expect(metrics.speciesJsonReads, 2);
    });

    test('rebuilds a project snapshot after explicit invalidation', () async {
      final speciesFile = File(
        p.join(
          tempRoot.path,
          'data',
          'pokemon',
          'species',
          'bulbasaur.json',
        ),
      );
      await _writeValidSpeciesFile(
        speciesFile,
        declaredId: 'bulbasaur',
        baseHp: 45,
      );
      final metrics = _CountingRuntimePokemonSpeciesSnapshotMetrics();
      final loader = RuntimePokemonSpeciesLoader(snapshotMetrics: metrics);
      final original = await loader.loadById(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
        speciesId: 'bulbasaur',
      );
      await _writeValidSpeciesFile(
        speciesFile,
        declaredId: 'bulbasaur',
        baseHp: 60,
      );

      final cached = await loader.loadById(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
        speciesId: 'bulbasaur',
      );
      loader.invalidateProject(tempRoot.path);
      final refreshed = await loader.loadById(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
        speciesId: 'bulbasaur',
      );

      expect(original.baseHp, 45);
      expect(cached.baseHp, 45);
      expect(refreshed.baseHp, 60);
      expect(metrics.snapshotBuilds, 2);
      expect(metrics.directoryListings, 2);
      expect(metrics.speciesJsonReads, 2);
    });

    test('fails closed when progression data is absent', () async {
      await _writeSpecies(tempRoot, progression: null);

      expect(
        () => RuntimePokemonSpeciesLoader().loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
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
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
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
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
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
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
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
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
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
        const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            speciesDir: '../outside'),
        ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            speciesDir: externalSpeciesDir.path),
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
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
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
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
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

    test('rejects a missing shared species schema explicitly', () async {
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
      );
      final rawJson = jsonDecode(await file.readAsString())
          as Map<String, dynamic>
        ..remove('schemaVersion');
      await file.writeAsString(jsonEncode(rawJson));

      await expectLater(
        () => RuntimePokemonSpeciesLoader().loadById(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            speciesDir: 'data/pokemon/species',
          ),
          speciesId: 'targetmon',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(contains('schemaVersion=null'), contains('expected=1')),
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
      'schemaVersion': currentPokemonDataSchemaVersion,
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
  int schemaVersion = currentPokemonDataSchemaVersion,
  int baseHp = 45,
}) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode(<String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': declaredId,
      'typing': <String, dynamic>{
        'types': <String>['grass'],
      },
      'baseStats': <String, dynamic>{
        'hp': baseHp,
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

final class _CountingRuntimePokemonSpeciesSnapshotMetrics
    extends RuntimePokemonSpeciesSnapshotMetrics {
  int snapshotBuilds = 0;
  int directoryListings = 0;
  int speciesJsonReads = 0;

  @override
  void onSnapshotBuildStarted(String projectRoot, String speciesDirectory) {
    snapshotBuilds++;
  }

  @override
  void onSpeciesDirectoryListed(String projectRoot, String speciesDirectory) {
    directoryListings++;
  }

  @override
  void onSpeciesJsonRead(String projectRoot, String speciesPath) {
    speciesJsonReads++;
  }
}
