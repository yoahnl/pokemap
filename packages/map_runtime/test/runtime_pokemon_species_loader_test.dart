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
    late Directory tempProjectRoot;
    const loader = RuntimePokemonSpeciesLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_species_loader_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('loads a species by declared id even when the filename differs',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/not-the-id.json',
        json: _speciesJson(
          id: 'sproutle',
          baseHp: 45,
          primaryAbilityId: 'overgrow',
          learnsetRef: 'sproutle',
        ),
      );

      final species = await loader.loadById(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesId: 'sproutle',
      );

      expect(species.id, equals('sproutle'));
      expect(species.typing, equals(const <String>['grass']));
      expect(species.baseHp, equals(45));
      expect(species.baseAttack, equals(49));
      expect(species.baseDefense, equals(49));
      expect(species.baseSpecialAttack, equals(65));
      expect(species.baseSpecialDefense, equals(65));
      expect(species.baseSpeed, equals(45));
      expect(species.primaryAbilityId, equals('overgrow'));
      expect(species.learnsetRef, equals('sproutle'));
    });

    test('fails explicitly when the species is absent', () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/other.json',
        json: _speciesJson(
          id: 'aquafi',
          baseHp: 44,
          primaryAbilityId: 'torrent',
          learnsetRef: 'aquafi',
        ),
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('Espèce Pokémon introuvable'),
          ),
        ),
      );
    });

    test('fails explicitly when multiple files declare the same species id',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/001-a.json',
        json: _speciesJson(
          id: 'sproutle',
          baseHp: 45,
          primaryAbilityId: 'overgrow',
          learnsetRef: 'sproutle',
        ),
      );
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/001-b.json',
        json: _speciesJson(
          id: 'sproutle',
          baseHp: 46,
          primaryAbilityId: 'chlorophyll',
          learnsetRef: 'sproutle_alt',
        ),
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('même id'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                contains('speciesId=sproutle'),
              ),
        ),
      );
    });

    test('fails explicitly when a species JSON file is invalid', () async {
      await _writeRawProjectRelativeFile(
        tempProjectRoot,
        'custom/pokemon/species/broken.json',
        '{ not valid json',
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('Pokemon species file parse failed'),
              contains('broken.json'),
            ),
          ),
        ),
      );
    });

    test('loads a dual-typed species honestly', () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/dual.json',
        json: _speciesJson(
          id: 'aquadrake',
          baseHp: 79,
          primaryAbilityId: 'torrent',
          learnsetRef: 'aquadrake',
          typing: const <String>['water', 'dragon'],
        ),
      );

      final species = await loader.loadById(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesId: 'aquadrake',
      );

      expect(species.typing, equals(const <String>['water', 'dragon']));
    });

    test('fails explicitly when a mono-typing uses an unsupported battle type',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/unsupported-mono.json',
        json: _speciesJson(
          id: 'sparkitten',
          baseHp: 39,
          primaryAbilityId: 'static',
          learnsetRef: 'sparkitten',
          typing: const <String>['electrik'],
        ),
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sparkitten',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('données d’espèce Pokémon locales sont invalides'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('speciesId=sparkitten'),
                  contains('unsupported typing.types entry=electrik'),
                  contains('unsupported-mono.json'),
                ),
              ),
        ),
      );
    });

    test(
        'fails explicitly when a dual-typing contains an unsupported battle type',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/unsupported-dual.json',
        json: _speciesJson(
          id: 'tidalwyrm',
          baseHp: 79,
          primaryAbilityId: 'torrent',
          learnsetRef: 'tidalwyrm',
          typing: const <String>['water', 'cosmic'],
        ),
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'tidalwyrm',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('speciesId=tidalwyrm'),
              contains('unsupported typing.types entry=cosmic'),
              contains('unsupported-dual.json'),
            ),
          ),
        ),
      );
    });

    test('fails explicitly when runtime-required species fields are broken',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/broken-fields.json',
        json: <String, dynamic>{
          'id': 'sproutle',
          'baseStats': <String, int>{
            'atk': 49,
          },
        },
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('missing or invalid baseStats.hp'),
          ),
        ),
      );
    });

    test('fails explicitly when typing is missing or invalid', () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/broken-typing.json',
        json: <String, dynamic>{
          'id': 'sproutle',
          'typing': <String, Object>{
            'types': <String>['grass', 'grass'],
          },
          'baseStats': <String, int>{
            'hp': 45,
            'atk': 49,
            'def': 49,
            'spa': 65,
            'spd': 65,
            'spe': 45,
          },
          'abilities': <String, String>{'primary': 'overgrow'},
          'refs': <String, String>{'learnset': 'sproutle'},
        },
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('typing.types contains an empty or duplicate entry'),
          ),
        ),
      );
    });
  });
}

ProjectPokemonConfig _pokemonConfig() {
  return const ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
    },
  );
}

Map<String, dynamic> _speciesJson({
  required String id,
  required int baseHp,
  required String primaryAbilityId,
  required String learnsetRef,
  int baseAttack = 49,
  int baseDefense = 49,
  int baseSpecialAttack = 65,
  int baseSpecialDefense = 65,
  int baseSpeed = 45,
  List<String> typing = const <String>['grass'],
}) {
  return <String, dynamic>{
    'id': id,
    'typing': <String, Object>{
      'types': typing,
    },
    'baseStats': <String, int>{
      'hp': baseHp,
      'atk': baseAttack,
      'def': baseDefense,
      'spa': baseSpecialAttack,
      'spd': baseSpecialDefense,
      'spe': baseSpeed,
    },
    'abilities': <String, String>{
      'primary': primaryAbilityId,
    },
    'refs': <String, String>{
      'learnset': learnsetRef,
    },
  };
}

Future<void> _writeSpeciesFile(
  Directory projectRoot, {
  required String relativePath,
  required Map<String, dynamic> json,
}) {
  return _writeProjectRelativeJson(projectRoot, relativePath, json);
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writeRawProjectRelativeFile(
  Directory projectRoot,
  String relativePath,
  String rawContent,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(rawContent);
}
