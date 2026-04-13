import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileGameSaveRepository E2E', () {
    late _TestFileGameSaveRepository repository;
    late Directory testDirectory;

    setUp(() async {
      testDirectory = await Directory.systemTemp.createTemp('game_save_test_');
      repository = _TestFileGameSaveRepository(testDirectory);
    });

    tearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });

    test('save → load → GameState identical', () async {
      const originalState = GameState(
        saveId: 'test_save_001',
        currentMapId: 'pallet_town',
        playerPosition: GridPos(x: 5, y: 3),
        playerFacing: EntityFacing.north,
        playerMovementMode: MovementMode.walk,
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'squirtle',
            natureId: 'bold',
            abilityId: 'torrent',
            level: 12,
            ivs: PokemonStatSpread(
              hp: 31,
              attack: 30,
              defense: 29,
              specialAttack: 28,
              specialDefense: 27,
              speed: 26,
            ),
            knownMoveIds: ['surf', 'water_gun'],
            currentHp: 30,
            heldItemId: 'mystic-water',
          ),
        ]),
        trainerProfile: TrainerProfile(
          name: 'Leaf',
          badgeIds: ['boulder', 'cascade'],
          money: 2500,
          playtimeSeconds: 1800,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 10),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['intro_done'],
          seenSpeciesIds: ['pidgey'],
          caughtSpeciesIds: ['pidgey'],
        ),
        scriptVariables: ScriptVariables(values: {
          'rival_battles_won': ScriptVariableValue.int(3),
        }),
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:gym_leader_1',
          'badge_cascade',
        }),
        consumedEventIds: {'item_potion_route1', 'npc_trainer_route22'},
        metadata: {'testKey': 'testValue'},
      );

      await repository.save(originalState);
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.saveId, equals(originalState.saveId));
      expect(loadedState.currentMapId, equals(originalState.currentMapId));
      expect(loadedState.playerPosition, equals(originalState.playerPosition));
      expect(loadedState.playerFacing, equals(originalState.playerFacing));
      expect(loadedState.playerMovementMode,
          equals(originalState.playerMovementMode));
      expect(loadedState.party.members.length,
          equals(originalState.party.members.length));
      expect(loadedState.trainerProfile, equals(originalState.trainerProfile));
      expect(loadedState.bag, equals(originalState.bag));
      expect(loadedState.progression.unlockedFieldAbilities,
          equals(originalState.progression.unlockedFieldAbilities));
      expect(
        loadedState.progression.seenSpeciesIds,
        containsAll(<String>['pidgey', 'squirtle']),
      );
      expect(
        loadedState.progression.caughtSpeciesIds,
        containsAll(<String>['pidgey', 'squirtle']),
      );
      expect(loadedState.storyFlags.activeFlags,
          equals(originalState.storyFlags.activeFlags));
      expect(
          loadedState.consumedEventIds, equals(originalState.consumedEventIds));
    });

    test('save → load → storyFlags contains trainer_defeated:{id}', () async {
      const trainerId = 'gym_leader_1';
      const originalState = GameState(
        saveId: 'test_save_002',
        currentMapId: 'pallet_town',
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:$trainerId',
          'intro_done',
        }),
      );

      await repository.save(originalState);
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.storyFlags.activeFlags,
          contains('trainer_defeated:$trainerId'));
    });

    test(
        'save → load preserves a captured wild pokemon in party and progression',
        () async {
      const originalState = GameState(
        saveId: 'test_save_capture_001',
        currentMapId: 'field_map',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 20,
            ),
            PlayerPokemon(
              speciesId: 'sparkitten',
              natureId: 'hardy',
              abilityId: 'blaze',
              level: 6,
              knownMoveIds: <String>['scratch'],
              currentHp: 17,
            ),
          ],
        ),
        progression: PlayerProgression(
          seenSpeciesIds: <String>['sparkitten'],
          caughtSpeciesIds: <String>['sparkitten'],
        ),
      );

      await repository.save(originalState);
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.party.members, hasLength(2));
      expect(loadedState.party.members.last.speciesId, equals('sparkitten'));
      expect(loadedState.party.members.last.abilityId, equals('blaze'));
      expect(
        loadedState.progression.caughtSpeciesIds,
        contains('sparkitten'),
      );
      expect(
        loadedState.progression.seenSpeciesIds,
        contains('sparkitten'),
      );
    });

    test(
        'load migrates legacy progression.storyFlags into storyFlags.activeFlags',
        () async {
      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final legacyJson = <String, dynamic>{
        'saveId': 'legacy_save',
        'currentMapId': 'vova_center',
        'progression': <String, dynamic>{
          'unlockedFieldAbilities': <String>[],
          'storyFlags': <String>[
            'met_professor',
            'trainer_defeated:jean_michel'
          ],
        },
        'storyFlags': <String, dynamic>{
          'activeFlags': <String>[],
        },
      };
      await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(legacyJson));

      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.storyFlags.activeFlags, contains('met_professor'));
      expect(
        loadedState.storyFlags.activeFlags,
        contains('trainer_defeated:jean_michel'),
      );
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
        trainerProfile: TrainerProfile(
          name: 'Red',
          badgeIds: ['boulder'],
          money: 500,
          playtimeSeconds: 90,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:$trainerId',
        }),
      );

      await repository.save(state);

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      expect(json['saveId'], equals('test_save_005'));
      expect(json['currentMapId'], equals('test_map'));
      expect(json['playerPosition'], isA<Map<String, dynamic>>());
      expect(json['playerFacing'], equals('east'));
      expect(json['playerMovementMode'], equals('walk'));
      expect(json['trainerProfile'], isA<Map<String, dynamic>>());
      expect(json['bag'], isA<Map<String, dynamic>>());
      expect(json['progression'], isA<Map<String, dynamic>>());
      expect(json['storyFlags'], isA<Map<String, dynamic>>());

      final storyFlags = json['storyFlags'] as Map<String, dynamic>;
      expect(storyFlags['activeFlags'], isA<List>());
      expect(
          (storyFlags['activeFlags'] as List)
              .contains('trainer_defeated:$trainerId'),
          isTrue);
    });

    test(
        'load migrates legacy party members and save rewrites normalized phase 9 data',
        () async {
      const originalState = GameState(
        saveId: 'legacy_phase_9',
        currentMapId: 'vova_center',
        playerPosition: GridPos(x: 4, y: 7),
        playerFacing: EntityFacing.west,
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            level: 30,
            knownMoveIds: ['surf', 'ice_beam'],
            currentHp: 22,
          ),
        ]),
        trainerProfile: TrainerProfile(
          name: 'Leaf',
          badgeIds: ['cascade'],
          money: 1200,
          playtimeSeconds: 600,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['intro_done'],
        ),
        scriptVariables: ScriptVariables(values: {
          'rival_battles_won': ScriptVariableValue.int(3),
        }),
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:gym_leader_1',
          'badge_cascade',
        }),
        consumedEventIds: {'item_potion_route1', 'npc_trainer_route22'},
        metadata: {'testKey': 'testValue'},
      );
      final legacyJson = originalState.toJson();
      final party = legacyJson['party'] as Map<String, dynamic>;
      final members = party['members'] as List<dynamic>;
      final member = members.single as Map<String, dynamic>;
      member
        ..remove('natureId')
        ..remove('abilityId')
        ..remove('ivs')
        ..remove('evs')
        ..remove('currentHp')
        ..remove('statusId')
        ..remove('isShiny')
        ..remove('heldItemId')
        ..['id'] = 'party_1'
        ..['nickname'] = 'Ferry'
        ..['isFainted'] = false;

      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(legacyJson),
      );

      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.party.members.single.speciesId, 'lapras');
      expect(loadedState.party.members.single.natureId, 'hardy');
      expect(loadedState.party.members.single.abilityId, 'unknown');
      expect(loadedState.party.members.single.currentHp, 1);
      expect(loadedState.progression.caughtSpeciesIds, contains('lapras'));
      expect(loadedState.progression.seenSpeciesIds, contains('lapras'));
      expect(
        loadedState.scriptVariables.values['rival_battles_won'],
        const ScriptVariableValue.int(3),
      );
      expect(
        loadedState.storyFlags.activeFlags,
        equals(originalState.storyFlags.activeFlags),
      );
      expect(
        loadedState.consumedEventIds,
        equals(originalState.consumedEventIds),
      );
      expect(loadedState.metadata, equals(originalState.metadata));

      await repository.save(loadedState);

      final normalizedJson =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final normalizedParty = normalizedJson['party'] as Map<String, dynamic>;
      final normalizedMembers = normalizedParty['members'] as List<dynamic>;
      final normalizedMember = normalizedMembers.single as Map<String, dynamic>;

      expect(normalizedMember['speciesId'], 'lapras');
      expect(normalizedMember['natureId'], 'hardy');
      expect(normalizedMember['abilityId'], 'unknown');
      expect(normalizedMember['currentHp'], 1);
      expect(normalizedMember.containsKey('id'), isFalse);
      expect(normalizedMember.containsKey('nickname'), isFalse);
      expect(normalizedMember.containsKey('isFainted'), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test('save writes normalized phase 9 data', () async {
      const state = GameState(
        saveId: ' test_save_005b ',
        currentMapId: ' test_map ',
        trainerProfile: TrainerProfile(
          name: ' Red ',
          badgeIds: ['cascade', 'boulder', 'cascade'],
          money: 500,
          playtimeSeconds: 90,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: ' potion ', categoryId: ' medicine ', quantity: 2),
            BagEntry(itemId: ' poke-ball ', categoryId: ' items ', quantity: 5),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );

      await repository.save(state);

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final trainerProfile = json['trainerProfile'] as Map<String, dynamic>;
      final bag = json['bag'] as Map<String, dynamic>;
      final entries = bag['entries'] as List<dynamic>;

      expect(json['saveId'], equals('test_save_005b'));
      expect(json['currentMapId'], equals('test_map'));
      expect(trainerProfile['name'], equals('Red'));
      expect(trainerProfile['badgeIds'], equals(['boulder', 'cascade']));
      expect(entries, [
        {
          'itemId': 'poke-ball',
          'categoryId': 'items',
          'quantity': 5,
        },
        {
          'itemId': 'potion',
          'categoryId': 'medicine',
          'quantity': 5,
        },
      ]);
    });

    test('save keeps project.json unchanged', () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const state = GameState(
        saveId: 'test_save_006',
        trainerProfile: TrainerProfile(name: 'Blue'),
      );

      await repository.save(state);

      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test('invalid save does not write and keeps project.json unchanged',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const invalidState = GameState(saveId: '');

      await expectLater(
        () => repository.save(invalidState),
        throwsA(isA<GameSaveException>()),
      );

      expect(await repository.exists(), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test('corrupt load fails and does not rewrite save or project.json',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      const corruptContent = '''
{
  "saveId": "broken_save",
  "currentMapId": "vova_center",
  "party": {
    "members": [
      {
        "speciesId": "lapras",
        "knownMoveIds": ["surf"]
      }
    ]
  }
}
''';
      await file.writeAsString(corruptContent);

      await expectLater(
        () => repository.load(),
        throwsA(isA<GameSaveException>()),
      );

      expect(await file.readAsString(), corruptContent);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test(
        'invalid nested phase 9 data does not write and keeps project.json unchanged',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const invalidState = GameState(
        saveId: 'test_save_007',
        trainerProfile: TrainerProfile(name: '   '),
      );

      await expectLater(
        () => repository.save(invalidState),
        throwsA(isA<GameSaveException>()),
      );

      expect(await repository.exists(), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });
  });
}

class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory('${_testDirectory.path}/pokemonProject');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/game_save.json';
  }
}
