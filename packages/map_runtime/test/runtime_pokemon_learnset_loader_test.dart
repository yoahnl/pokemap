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
    final loader = RuntimePokemonLearnsetLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_learnset_loader_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('loads a valid learnset by ref and preserves useful families',
        () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle_alt.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <String>['tackle'],
          'relearnMoves': <String>['growl'],
          'levelUp': <Object>[
            <String, Object>{'moveId': 'vine_whip', 'level': 7},
            <String, Object>{'moveId': 'sleep_powder', 'level': 13},
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

    test('resolves TM and HM compatibility against the canonical move catalog',
        () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <String>['tackle'],
          'relearnMoves': <String>[],
          'levelUp': <Object>[],
          'tm': <Object>[
            <String, Object>{'moveId': 'protect'},
          ],
          'hm': <Object>[
            <String, Object>{'moveId': 'surf'},
          ],
        },
      );
      await _writeMovesCatalog(
        tempProjectRoot,
        moves: const <(String, int)>[
          ('protect', 10),
          ('surf', 15),
        ],
      );

      final tm = await loader.loadMoveMachineCandidate(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: 'sproutle',
        fallbackSpeciesId: 'sproutle',
        itemId: 'tm-protect',
        moveId: 'protect',
        machineKind: 'tm',
        consumable: true,
      );
      final hm = await loader.loadMoveMachineCandidate(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: 'sproutle',
        fallbackSpeciesId: 'sproutle',
        itemId: 'hm-surf',
        moveId: 'surf',
        machineKind: 'hm',
        consumable: false,
      );
      final incompatible = await loader.loadMoveMachineCandidate(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: 'sproutle',
        fallbackSpeciesId: 'sproutle',
        itemId: 'tm-surf',
        moveId: 'surf',
        machineKind: 'tm',
        consumable: true,
      );

      expect(tm?.moveId, 'protect');
      expect(tm?.maxPp, 10);
      expect(tm?.consumable, isTrue);
      expect(hm?.moveId, 'surf');
      expect(hm?.consumable, isFalse);
      expect(incompatible, isNull);
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

    test(
        'loads crossed moves with deterministic unique tokens and preserves strict duplicates',
        () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <String>['tackle'],
          'relearnMoves': <String>[],
          'levelUp': <Map<String, Object>>[
            <String, Object>{'moveId': 'late_move', 'level': 9},
            <String, Object>{'moveId': 'same_level_first', 'level': 7},
            <String, Object>{'moveId': 'same_level_first', 'level': 7},
            <String, Object>{'moveId': 'too_early', 'level': 5},
            <String, Object>{'moveId': 'same_level_second', 'level': 7},
            <String, Object>{'moveId': 'upper_bound', 'level': 10},
            <String, Object>{'moveId': 'too_late', 'level': 11},
          ],
        },
      );
      await _writeMovesCatalog(
        tempProjectRoot,
        moves: const <(String, int)>[
          ('late_move', 5),
          ('same_level_first', 10),
          ('too_early', 15),
          ('same_level_second', 20),
          ('upper_bound', 25),
          ('too_late', 30),
        ],
      );

      final candidates = await loader.loadLevelUpCandidates(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: 'sproutle',
        fallbackSpeciesId: 'sproutle',
        oldLevel: 5,
        newLevel: 10,
      );
      final reloadedCandidates = await loader.loadLevelUpCandidates(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: 'sproutle',
        fallbackSpeciesId: 'sproutle',
        oldLevel: 5,
        newLevel: 10,
      );

      expect(
        candidates
            .map((candidate) => (
                  candidate.opportunityId,
                  candidate.moveId,
                  candidate.learnedAtLevel,
                  candidate.maxPp,
                ))
            .toList(growable: false),
        <(String, String, int, int)>[
          ('sproutle:levelUp:1:7:same_level_first', 'same_level_first', 7, 10),
          ('sproutle:levelUp:2:7:same_level_first', 'same_level_first', 7, 10),
          (
            'sproutle:levelUp:4:7:same_level_second',
            'same_level_second',
            7,
            20
          ),
          ('sproutle:levelUp:0:9:late_move', 'late_move', 9, 5),
          ('sproutle:levelUp:5:10:upper_bound', 'upper_bound', 10, 25),
        ],
      );
      expect(
        reloadedCandidates.map((candidate) => candidate.opportunityId),
        candidates.map((candidate) => candidate.opportunityId),
      );
      expect(
        candidates.map((candidate) => candidate.opportunityId).toSet(),
        hasLength(candidates.length),
      );
    });

    test('fails closed when a crossed learnset move is missing from catalog',
        () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <String>[],
          'relearnMoves': <String>[],
          'levelUp': <Map<String, Object>>[
            <String, Object>{'moveId': 'missing_move', 'level': 6},
          ],
        },
      );
      await _writeMovesCatalog(
        tempProjectRoot,
        moves: const <(String, int)>[('other_move', 10)],
      );

      await expectLater(
        () => loader.loadLevelUpCandidates(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesRef: 'sproutle',
          fallbackSpeciesId: 'sproutle',
          oldLevel: 5,
          newLevel: 6,
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('moveId=missing_move'),
          ),
        ),
      );
    });

    test('fails closed when a crossed move has no usable max PP', () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <String>[],
          'relearnMoves': <String>[],
          'levelUp': <Map<String, Object>>[
            <String, Object>{'moveId': 'empty_move', 'level': 6},
          ],
        },
      );
      await _writeMovesCatalog(
        tempProjectRoot,
        moves: const <(String, int)>[('empty_move', 0)],
      );

      await expectLater(
        () => loader.loadLevelUpCandidates(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesRef: 'sproutle',
          fallbackSpeciesId: 'sproutle',
          oldLevel: 5,
          newLevel: 6,
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('pp=0'),
          ),
        ),
      );
    });

    test('fails closed on an invalid level-up entry', () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <String>[],
          'relearnMoves': <String>[],
          'levelUp': <Object>[
            <String, Object>{'moveId': 'broken_move', 'level': 0},
          ],
        },
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
            contains('levelUp[0]'),
          ),
        ),
      );
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

Future<void> _writeMovesCatalog(
  Directory projectRoot, {
  required List<(String, int)> moves,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'entries': <Map<String, dynamic>>[
        for (final (moveId, pp) in moves)
          PokemonMove(
            id: moveId,
            name: moveId,
            source: 'move_learning_test',
            type: 'normal',
            category: PokemonMoveCategory.physical,
            basePower: 40,
            accuracy: const PokemonMoveAccuracy.percent(value: 100),
            pp: pp,
            engineSupportLevel:
                PokemonMoveEngineSupportLevel.structuredSupported,
          ).toJson(),
      ],
    },
  );
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
