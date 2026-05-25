import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:path/path.dart' as p;

const _projectName = 'P5 Beta Runtime Smoke';
const _mapId = 'p5_beta_runtime_map';
const _spawnId = 'p5_beta_runtime_spawn';
const _trainerNpcId = 'p5_beta_runtime_trainer_npc';
const _saveId = 'p5_beta_runtime_save';
const _playerSpeciesId = 'p5_beta_player_species';
const _enemySpeciesId = 'p5_beta_enemy_species';
const _playerMoveId = 'p5_beta_player_strike';
const _enemyMoveId = 'p5_beta_enemy_tap';
const _trainerId = 'p5_beta_trainer';
const _battleId = 'p5_beta_battle';
const _flagId = 'p5.beta.runtime.flag.ready';
const _trainerDefeatedFlag = 'trainer_defeated:p5_beta_trainer';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P5-08 runtime smoke boots New Game, wins battle, applies reward, and save-loads',
    () async {
      final projectRoot =
          await Directory.systemTemp.createTemp('p5_beta_runtime_smoke_');
      final repository = _TempFileGameSaveRepository(projectRoot);
      final saveGame = SaveGameUseCase(repository);
      final loadGame = LoadGameUseCase(repository);

      try {
        final projectFilePath = await _writeRuntimeSmokeProject(projectRoot);
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: _mapId,
        );

        var gameState = _buildNewGameWithStarter(bundle.map);
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: projectFilePath,
          saveData: saveDataFromGameState(gameState),
          saveRepository: repository,
        );

        expect(game.saveLoadInfo.mapId, _mapId);
        expect(game.gameStateSnapshot.party.members.single.speciesId,
            _playerSpeciesId);

        game.onGameResize(Vector2(320, 240));
        await game.onLoad();
        game.update(0);

        final runtimeState = game.gameStateSnapshot;
        expect(runtimeState.currentMapId, _mapId);
        expect(runtimeState.playerPosition, const GridPos(x: 2, y: 2));
        expect(runtimeState.playerFacing, EntityFacing.east);
        expect(runtimeState.party.members.single.speciesId, _playerSpeciesId);

        final world = GameplayWorldState.initial(
          map: bundle.map,
          playerPos: runtimeState.playerPosition,
          playerFacing: Direction.east,
          project: bundle.manifest,
        );
        final trainerNpc = bundle.map.entities.firstWhere(
          (entity) => entity.id == _trainerNpcId,
        );
        final request = buildTrainerBattleRequestFromNpc(
          entity: trainerNpc,
          manifest: bundle.manifest,
          world: world,
          createdAtEpochMs: 1,
        );
        expect(request, isNotNull);
        expect(
            request!.requestId, 'trainer:$_mapId:$_trainerNpcId:$_trainerId:1');

        final mapper = RuntimeBattleSetupMapper();
        final lineup = mapper.selectPlayerBattleLineup(runtimeState.party);
        final setup = await mapper.map(
          bundle: bundle,
          gameState: runtimeState,
          request: request,
          playerPartyIndex: lineup.activeIndex,
        );
        expect(setup.isTrainerBattle, isTrue);
        expect(setup.trainerId, _trainerId);
        expect(setup.playerPokemon.speciesId, _playerSpeciesId);
        expect(setup.enemyPokemon.speciesId, _enemySpeciesId);

        final battleSession = _playBattleToVictory(setup);
        final outcome = battleSession.state.outcome!;
        expect(outcome.isVictory, isTrue);

        gameState = applyRuntimeBattleOutcomeToGameState(
          gameState: runtimeState,
          context: RuntimeActiveBattleContext(
            request: request,
            playerPartyIndex: lineup.activeIndex,
            playerPartySlotIndicesByLineupIndex: lineup.lineupPartyIndices,
          ),
          outcome: outcome,
        );
        gameState = const GameStateMutations().applyBattleRewards(
          gameState,
          moneyReward: 120,
          levelUpsByPartyIndex: const <int, int>{0: 1},
        );

        expect(
            gameState.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(gameState.trainerProfile.money, 120);
        expect(gameState.party.members.single.level, 9);

        expect(await saveGame.execute(gameState), isTrue);
        final saveFilePath = await repository.exposedSaveFilePath();
        final saveFile = File(saveFilePath);
        expect(await saveFile.exists(), isTrue);

        final savedJson =
            jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
        expect(savedJson['saveId'], _saveId);
        expect(savedJson['currentMapId'], _mapId);
        expect(savedJson['trainerProfile'],
            containsPair('money', gameState.trainerProfile.money));

        final loaded = await loadGame.execute();
        expect(loaded, isNotNull);
        final reloaded = normalizeLoadedGameState(loaded!);

        expect(reloaded.saveId, _saveId);
        expect(reloaded.currentMapId, _mapId);
        expect(reloaded.playerPosition, const GridPos(x: 2, y: 2));
        expect(reloaded.playerFacing, EntityFacing.east);
        expect(reloaded.party.members, hasLength(1));
        expect(reloaded.party.members.single.speciesId, _playerSpeciesId);
        expect(reloaded.party.members.single.level, 9);
        expect(reloaded.party.members.single.currentHp, greaterThan(0));
        expect(reloaded.trainerProfile.money, 120);
        expect(reloaded.storyFlags.activeFlags, contains(_flagId));
        expect(reloaded.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(
          reloaded.metadata,
          containsPair('lot', 'p5_08_beta_runtime_smoke'),
        );
        expect(
          reloaded.progression.caughtSpeciesIds,
          contains(_playerSpeciesId),
        );
        expect(reloaded.progression.seenSpeciesIds, contains(_playerSpeciesId));
        await expectLater(
          _containsForbiddenFixtureContent(projectRoot),
          completion(false),
        );
        expect(_containsSelbrumeId(reloaded), isFalse);
      } finally {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      }
    },
  );
}

GameState _buildNewGameWithStarter(MapData map) {
  const mutations = GameStateMutations();
  var state = createNewGameStateFromMap(
    startMap: map,
    saveId: _saveId,
    playerName: 'P5 Beta Tester',
  ).copyWith(
    metadata: const <String, String>{
      'lot': 'p5_08_beta_runtime_smoke',
      'battle': _battleId,
      'runtime': 'playable_map_game_and_battle_outcome',
    },
  );
  state = mutations.setFlag(state, _flagId);
  return mutations.givePokemon(
    state,
    pokemon: const PlayerPokemon(
      speciesId: _playerSpeciesId,
      natureId: 'hardy',
      abilityId: 'p5_beta_power',
      level: 8,
      currentHp: 40,
      knownMoveIds: <String>[_playerMoveId],
    ),
  );
}

BattleSession _playBattleToVictory(BattleSetup setup) {
  var session = createBattleSession(setup);
  for (var turn = 0; turn < 8 && !session.state.isFinished; turn++) {
    session = session.applyChoice(const PlayerBattleChoiceFight(0));
  }
  expect(session.state.isFinished, isTrue);
  expect(session.state.outcome, isNotNull);
  return session;
}

Future<String> _writeRuntimeSmokeProject(Directory projectRoot) async {
  final projectFilePath = p.join(projectRoot.path, 'project.json');
  final manifest = _runtimeSmokeManifest();
  final map = _runtimeSmokeMap();

  ProjectValidator.validate(manifest);
  MapValidator.validate(map, projectDialogueContext: manifest);

  await _writeJson(File(projectFilePath), manifest.toJson());
  await _writeJson(
    File(p.join(projectRoot.path, 'maps', 'p5_beta_runtime_map.json')),
    map.toJson(),
  );
  await _writePokemonProjectData(projectRoot);
  return projectFilePath;
}

ProjectManifest _runtimeSmokeManifest() {
  return const ProjectManifest(
    name: _projectName,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'P5 Beta Runtime Field',
        relativePath: 'maps/p5_beta_runtime_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    trainers: <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'P5 Beta Trainer',
        trainerClass: 'Runtime Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: _enemySpeciesId,
            level: 2,
            moves: <String>[_enemyMoveId],
          ),
        ],
      ),
    ],
    settings: ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
      defaultMapWidth: 6,
      defaultMapHeight: 6,
    ),
  );
}

MapData _runtimeSmokeMap() {
  return const MapData(
    id: _mapId,
    name: 'P5 Beta Runtime Field',
    size: GridSize(width: 6, height: 6),
    layers: <MapLayer>[
      MapLayer.object(id: 'p5_beta_runtime_objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: _spawnId,
        name: 'P5 Beta Runtime Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 2),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          spawnKey: _spawnId,
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: _trainerNpcId,
        name: 'P5 Beta Runtime Trainer NPC',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 3, y: 2),
        blocksMovement: true,
        npc: MapEntityNpcData(
          displayName: 'P5 Beta Trainer',
          facing: EntityFacing.west,
          trainerId: _trainerId,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: _spawnId),
  );
}

Future<void> _writePokemonProjectData(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/001-p5-beta-player.json',
    _speciesJson(
      id: _playerSpeciesId,
      name: 'P5 Beta Player Species',
      type: 'normal',
      baseHp: 92,
      baseAttack: 125,
      baseDefense: 70,
      baseSpecialAttack: 60,
      baseSpecialDefense: 70,
      baseSpeed: 95,
      abilityId: 'p5_beta_power',
      learnsetRef: _playerSpeciesId,
      nationalDex: 501,
    ),
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/002-p5-beta-enemy.json',
    _speciesJson(
      id: _enemySpeciesId,
      name: 'P5 Beta Enemy Species',
      type: 'normal',
      baseHp: 22,
      baseAttack: 20,
      baseDefense: 15,
      baseSpecialAttack: 15,
      baseSpecialDefense: 15,
      baseSpeed: 10,
      abilityId: 'p5_beta_soft',
      learnsetRef: _enemySpeciesId,
      nationalDex: 502,
    ),
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/$_playerSpeciesId.json',
    <String, dynamic>{
      'startingMoves': <String>[_playerMoveId],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/$_enemySpeciesId.json',
    <String, dynamic>{
      'startingMoves': <String>[_enemyMoveId],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'P5 beta runtime smoke move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry(_playerMoveId, 'P5 Beta Strike', 140),
        _moveEntry(_enemyMoveId, 'P5 Beta Tap', 1),
      ],
    },
  );
}

Map<String, Object> _speciesJson({
  required String id,
  required String name,
  required String type,
  required int baseHp,
  required int baseAttack,
  required int baseDefense,
  required int baseSpecialAttack,
  required int baseSpecialDefense,
  required int baseSpeed,
  required String abilityId,
  required String learnsetRef,
  required int nationalDex,
}) {
  return <String, Object>{
    'id': id,
    'slug': id,
    'nationalDex': nationalDex,
    'names': <String, String>{'en': name},
    'speciesName': <String, String>{'en': name},
    'genIntroduced': 1,
    'typing': <String, Object>{
      'types': <String>[type],
    },
    'baseStats': <String, int>{
      'hp': baseHp,
      'atk': baseAttack,
      'def': baseDefense,
      'spa': baseSpecialAttack,
      'spd': baseSpecialDefense,
      'spe': baseSpeed,
      'bst': baseHp +
          baseAttack +
          baseDefense +
          baseSpecialAttack +
          baseSpecialDefense +
          baseSpeed,
    },
    'abilities': <String, String>{'primary': abilityId},
    'breeding': <String, Object>{
      'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
      'eggGroups': <String>['field'],
      'hatchCycles': 20,
    },
    'progression': <String, Object>{
      'growthRateId': 'medium_fast',
      'baseExp': 50,
      'catchRate': 45,
      'baseFriendship': 50,
    },
    'refs': <String, String>{
      'learnset': learnsetRef,
      'evolution': id,
      'media': id,
    },
    'dexContent': <String, Object>{
      'heightM': 1.0,
      'weightKg': 10.0,
    },
    'sourceMeta': <String, Object>{
      'seededBy': 'p5_beta_runtime_smoke_test',
      'seedVersion': 1,
    },
  };
}

Map<String, Object?> _moveEntry(String id, String name, int power) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'p5_beta_runtime_smoke_test',
    type: 'normal',
    category: PokemonMoveCategory.physical,
    target: PokemonMoveTarget.normal,
    basePower: power,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
  ).toJson();
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  await _writeJson(File(p.join(projectRoot.path, relativePath)), json);
}

Future<void> _writeJson(File file, Map<String, dynamic> json) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<bool> _containsForbiddenFixtureContent(Directory root) async {
  const forbiddenFragments = <String>{
    'selbrume',
    'lysa',
    'mado',
    'port des brisants',
    'phare',
    'brume',
    'rival',
  };

  await for (final entity in root.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final normalizedContent = (await entity.readAsString()).toLowerCase();
    for (final fragment in forbiddenFragments) {
      if (normalizedContent.contains(fragment)) {
        return true;
      }
    }
  }
  return false;
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
    final saveDir = Directory(p.join(_testDirectory.path, 'runtime_save'));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return p.join(saveDir.path, 'game_save.json');
  }
}
