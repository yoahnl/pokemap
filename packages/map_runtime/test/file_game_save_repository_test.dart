import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileGameSaveRepository E2E', () {
    late FileGameSaveRepository repository;
    late Directory testDirectory;

    setUp(() async {
      // Override the application support directory for testing
      testDirectory = await Directory.systemTemp.createTemp('game_save_test_');
      repository = _TestFileGameSaveRepository(testDirectory);
    });

    tearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });

    test('save → load → GameState identical', () async {
      final originalState = GameState(
        saveId: 'test_save_001',
        currentMapId: 'pallet_town',
        playerPosition: const GridPos(x: 5, y: 3),
        playerFacing: EntityFacing.north,
        playerMovementMode: MovementMode.walk,
        party: const PlayerParty(members: [
          PlayerPokemon(
            id: 'p1',
            speciesId: 'squirtle',
            level: 12,
            knownMoveIds: ['surf', 'water_gun'],
          ),
        ]),
        progression: const PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['intro_done'],
        ),
        scriptVariables: ScriptVariables(values: {
          'rival_battles_won': const ScriptVariableValue.int(3),
        }),
        storyFlags: const StoryFlags(activeFlags: {
          'trainer_defeated:gym_leader_1',
          'badge_cascade',
        }),
        consumedEventIds: {'item_potion_route1', 'npc_trainer_route22'},
        metadata: {'testKey': 'testValue'},
      );

      // Save
      await repository.save(originalState);

      // Load
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.saveId, equals(originalState.saveId));
      expect(loadedState.currentMapId, equals(originalState.currentMapId));
      expect(loadedState.playerPosition, equals(originalState.playerPosition));
      expect(loadedState.playerFacing, equals(originalState.playerFacing));
      expect(loadedState.playerMovementMode, equals(originalState.playerMovementMode));
      expect(loadedState.party.members.length, equals(originalState.party.members.length));
      expect(loadedState.progression.unlockedFieldAbilities, equals(originalState.progression.unlockedFieldAbilities));
      expect(loadedState.storyFlags.activeFlags, equals(originalState.storyFlags.activeFlags));
      expect(loadedState.consumedEventIds, equals(originalState.consumedEventIds));
    });

    test('save → load → storyFlags contains trainer_defeated:{id}', () async {
      const trainerId = 'gym_leader_1';
      final originalState = GameState(
        saveId: 'test_save_002',
        currentMapId: 'pallet_town',
        storyFlags: const StoryFlags(activeFlags: {
          'trainer_defeated:$trainerId',
          'intro_done',
        }),
      );

      // Save
      await repository.save(originalState);

      // Load
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.storyFlags.activeFlags, contains('trainer_defeated:$trainerId'));
    });

    test('load when no save exists → returns null', () async {
      final loadedState = await repository.load();
      expect(loadedState, isNull);
    });

    test('exists() returns true after save', () async {
      const state = GameState(
        saveId: 'test_save_003',
        currentMapId: 'pallet_town',
      );

      expect(await repository.exists(), isFalse);

      await repository.save(state);

      expect(await repository.exists(), isTrue);
    });

    test('delete → load → returns null', () async {
      const state = GameState(
        saveId: 'test_save_004',
        currentMapId: 'pallet_town',
      );

      await repository.save(state);
      expect(await repository.exists(), isTrue);

      await repository.delete();
      expect(await repository.exists(), isFalse);

      final loadedState = await repository.load();
      expect(loadedState, isNull);
    });

    test('JSON file structure is valid', () async {
      const trainerId = 'test_trainer';
      const state = GameState(
        saveId: 'test_save_005',
        currentMapId: 'test_map',
        playerPosition: GridPos(x: 10, y: 5),
        playerFacing: EntityFacing.east,
        playerMovementMode: MovementMode.walk,
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:$trainerId',
        }),
      );

      await repository.save(state);

      // Read raw JSON file
      final filePath = await repository.getSaveFilePath();
      final file = File(filePath);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Verify structure
      expect(json['saveId'], equals('test_save_005'));
      expect(json['currentMapId'], equals('test_map'));
      expect(json['playerPosition'], isA<Map<String, dynamic>>());
      expect(json['playerFacing'], equals('east'));
      expect(json['playerMovementMode'], equals('walk'));
      expect(json['storyFlags'], isA<Map<String, dynamic>>());
      
      final storyFlags = json['storyFlags'] as Map<String, dynamic>;
      expect(storyFlags['activeFlags'], isA<List>());
      expect((storyFlags['activeFlags'] as List).contains('trainer_defeated:$trainerId'), isTrue);
    });
  });
}

/// Test repository that uses a custom test directory
class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory('${_testDirectory.path}/pokemonProject');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/game_save.json';
  }
}
