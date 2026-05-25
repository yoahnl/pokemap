import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _saveId = 'p5_roundtrip_save';
const _mapId = 'p5_roundtrip_map';
const _spawnId = 'p5_roundtrip_spawn';
const _starterSpeciesId = 'p5_roundtrip_starter';
const _capturedPartySpeciesId = 'p5_roundtrip_captured_party';
const _capturedStorageSpeciesId = 'p5_roundtrip_captured_storage';
const _medicineItemId = 'p5_roundtrip_medicine';
const _flagId = 'p5.roundtrip.flag.ready';
const _eventId = 'p5.roundtrip.event.consumed';
const _trainerDefeatedFlag = 'trainer_defeated:p5_roundtrip_trainer';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P5-07 roundtrips beta gameplay state through FileGameSaveRepository',
    () async {
      final testDirectory =
          await Directory.systemTemp.createTemp('p5_roundtrip_save_');
      final repository = _TempFileGameSaveRepository(testDirectory);
      final saveGame = SaveGameUseCase(repository);
      final loadGame = LoadGameUseCase(repository);

      try {
        final state = _buildBetaGameplayState();

        expect(await saveGame.execute(state), isTrue);
        expect(await repository.exists(), isTrue);

        final saveFilePath = await repository.exposedSaveFilePath();
        final saveFile = File(saveFilePath);
        expect(await saveFile.exists(), isTrue);

        final savedJson =
            jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
        expect(savedJson['saveId'], _saveId);
        expect(savedJson['currentMapId'], _mapId);
        expect(savedJson['pokemonStorage'], isA<Map<String, dynamic>>());

        final loaded = await loadGame.execute();
        expect(loaded, isNotNull);

        final reloaded = normalizeLoadedGameState(loaded!);

        expect(reloaded.saveId, _saveId);
        expect(reloaded.currentMapId, _mapId);
        expect(reloaded.playerPosition, const GridPos(x: 4, y: 6));
        expect(reloaded.playerFacing, EntityFacing.east);

        expect(reloaded.party.members, hasLength(6));
        expect(
          reloaded.party.members.map((pokemon) => pokemon.speciesId),
          equals(<String>[
            _starterSpeciesId,
            'p5_roundtrip_party_0',
            'p5_roundtrip_party_1',
            'p5_roundtrip_party_2',
            'p5_roundtrip_party_3',
            _capturedPartySpeciesId,
          ]),
        );
        expect(reloaded.party.members.first.level, 7);
        expect(reloaded.party.members.first.currentHp, 20);
        expect(reloaded.party.members.first.statusId, isEmpty);

        expect(reloaded.pokemonStorage.storedPokemon, hasLength(1));
        expect(
          reloaded.pokemonStorage.storedPokemon.single.speciesId,
          _capturedStorageSpeciesId,
        );

        expect(
          reloaded.bag.entries,
          equals(<BagEntry>[
            const BagEntry(
              itemId: _medicineItemId,
              categoryId: 'items',
              quantity: 1,
            ),
          ]),
        );
        expect(reloaded.trainerProfile.money, 275);

        expect(reloaded.storyFlags.activeFlags, contains(_flagId));
        expect(reloaded.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(reloaded.consumedEventIds, contains(_eventId));
        expect(
          reloaded.metadata,
          equals(<String, String>{
            'lot': 'p5_07',
            'persistence': 'file_game_save_repository',
          }),
        );

        expect(
          reloaded.progression.caughtSpeciesIds,
          containsAll(<String>[
            _starterSpeciesId,
            _capturedPartySpeciesId,
            _capturedStorageSpeciesId,
          ]),
        );
        expect(
          reloaded.progression.seenSpeciesIds,
          containsAll(<String>[
            _starterSpeciesId,
            _capturedPartySpeciesId,
            _capturedStorageSpeciesId,
          ]),
        );

        expect(_containsSelbrumeId(reloaded), isFalse);
      } finally {
        if (await testDirectory.exists()) {
          await testDirectory.delete(recursive: true);
        }
      }
    },
  );
}

GameState _buildBetaGameplayState() {
  const mutations = GameStateMutations();
  var state = createNewGameStateFromMap(
    startMap: _roundtripMap(),
    saveId: _saveId,
    playerName: 'P5 Tester',
  ).copyWith(
    metadata: const <String, String>{
      'lot': 'p5_07',
      'persistence': 'file_game_save_repository',
    },
  );

  state = mutations.givePokemon(
    state,
    pokemon: _pokemon(
      _starterSpeciesId,
      level: 5,
      currentHp: 4,
      statusId: 'poison',
      knownMoveIds: const <String>['p5_roundtrip_tackle'],
    ),
  );
  state = mutations.giveItem(state, _medicineItemId, 2);
  state = mutations.applyHpMedicineToPartyMember(
    state,
    partyIndex: 0,
    itemId: _medicineItemId,
    healAmount: 8,
    maxHp: 20,
  );
  state = mutations.recoverParty(
    state,
    maxHpByPartyIndex: const <int, int>{0: 20},
  );
  state = mutations.applyBattleRewards(
    state,
    moneyReward: 275,
    levelUpsByPartyIndex: const <int, int>{0: 2},
  );
  state = mutations.setFlag(state, _flagId);
  state = mutations.setFlag(state, _trainerDefeatedFlag);
  state = mutations.markEventConsumed(state, _eventId);

  for (var index = 0; index < 4; index++) {
    state = mutations.givePokemon(
      state,
      pokemon: _pokemon(
        'p5_roundtrip_party_$index',
        level: 3 + index,
        currentHp: 10 + index,
      ),
    );
  }

  final partyCapture = mutations.applyCapturedPokemon(
    state,
    pokemon: _pokemon(_capturedPartySpeciesId, level: 4, currentHp: 14),
  );
  expect(partyCapture.destination, CaptureDestinationKind.party);
  expect(partyCapture.partyIndex, 5);

  final storageCapture = mutations.applyCapturedPokemon(
    partyCapture.state,
    pokemon: _pokemon(_capturedStorageSpeciesId, level: 6, currentHp: 18),
  );
  expect(storageCapture.destination, CaptureDestinationKind.storage);
  expect(storageCapture.storageIndex, 0);

  return storageCapture.state;
}

MapData _roundtripMap() {
  return const MapData(
    id: _mapId,
    name: 'P5 Roundtrip Field',
    size: GridSize(width: 12, height: 10),
    mapMetadata: MapMetadata(defaultSpawnId: _spawnId),
    entities: <MapEntity>[
      MapEntity(
        id: _spawnId,
        name: 'P5 Roundtrip Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 4, y: 6),
        spawn: MapEntitySpawnData(
          spawnKey: _spawnId,
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
  );
}

PlayerPokemon _pokemon(
  String speciesId, {
  int level = 5,
  int currentHp = 20,
  String statusId = '',
  List<String> knownMoveIds = const <String>['p5_roundtrip_move'],
}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'p5_roundtrip_ability',
    level: level,
    currentHp: currentHp,
    statusId: statusId,
    knownMoveIds: knownMoveIds,
  );
}

bool _containsSelbrumeId(GameState state) {
  final values = <String>[
    state.saveId,
    state.currentMapId,
    state.trainerProfile.name,
    ...state.party.members.map((pokemon) => pokemon.speciesId),
    ...state.pokemonStorage.storedPokemon.map((pokemon) => pokemon.speciesId),
    ...state.bag.entries.map((entry) => entry.itemId),
    ...state.storyFlags.activeFlags,
    ...state.consumedEventIds,
    ...state.metadata.keys,
    ...state.metadata.values,
  ];
  return values.any((value) => value.toLowerCase().contains('selbrume'));
}

class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this._testDirectory);

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
