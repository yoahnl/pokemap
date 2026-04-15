import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_pokemon_learnset_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimePokemonLearnsetLoader', () {
    late Directory tempProjectRoot;
    const loader = RuntimePokemonLearnsetLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_learnset_loader_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('loads a learnset by ref and preserves useful families', () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle_alt.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <Object>['tackle', 123],
          'relearnMoves': <Object>['growl', true],
          'levelUp': <Object>[
            <String, Object>{'moveId': 'vine_whip', 'level': 7},
            <String, Object>{'moveId': '', 'level': 9},
            <String, Object>{'moveId': 'razor_leaf', 'level': 0},
            <String, Object>{'moveId': 'sleep_powder', 'level': 13},
            'not-a-map',
          ],
        },
      );

      final learnset = await loader.loadByRef(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: 'sproutle_alt',
        fallbackSpeciesId: 'sproutle',
      );

      expect(learnset.startingMoves, equals(<String>['tackle']));
      expect(learnset.relearnMoves, equals(<String>['growl']));
      expect(
        learnset.levelUp
            .map((entry) => (entry.moveId, entry.level))
            .toList(growable: false),
        equals(<(String, int)>[
          ('vine_whip', 7),
          ('sleep_powder', 13),
        ]),
      );
    });

    test('falls back to fallbackSpeciesId when the learnset ref is empty',
        () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <String>['tackle'],
          'relearnMoves': <String>['growl'],
          'levelUp': <Map<String, Object>>[
            <String, Object>{'moveId': 'vine_whip', 'level': 7},
          ],
        },
      );

      final learnset = await loader.loadByRef(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: '',
        fallbackSpeciesId: 'sproutle',
      );

      expect(learnset.startingMoves, equals(<String>['tackle']));
      expect(learnset.relearnMoves, equals(<String>['growl']));
      expect(learnset.levelUp.single.moveId, equals('vine_whip'));
    });

    test('fails explicitly when the learnset file is absent', () async {
      await expectLater(
        () => loader.loadByRef(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesRef: 'sproutle',
          fallbackSpeciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('Pokemon learnset "sproutle" file not found'),
          ),
        ),
      );
    });

    test('fails explicitly when the learnset JSON is invalid', () async {
      await _writeRawProjectRelativeFile(
        tempProjectRoot,
        'custom/pokemon/learnsets/sproutle.json',
        '{ invalid json',
      );

      await expectLater(
        () => loader.loadByRef(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesRef: 'sproutle',
          fallbackSpeciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('Pokemon learnset "sproutle" parse failed'),
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

Future<void> _writeLearnsetFile(
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
