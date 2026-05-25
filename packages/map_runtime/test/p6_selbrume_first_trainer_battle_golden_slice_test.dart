import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _routeMapId = 'route 1';
const _saveId = 'p6_05_selbrume_first_trainer_battle';
const _trainerId = 'grant';
const _trainerDefeatedFlag = 'trainer_defeated:grant';
const _grantNpcId = 'grant';
const _grantCharacterId = 'grant';
const _grantTilesetId = 'grant';
const _grantAssetRelativePath = 'assets/tilesets/grant.png';
const _initialSpeciesId = 'pidgeotto';
const _capturedSpeciesId = 'pidgeotto';
const _initialAbilityId = 'keen_eye';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';
const _p603FlagId = 'p6.selbrume.first_interaction.seen';
const _p603StepId = 'p6.selbrume.first_interaction';
const _rewardMoney = 120;
const _grantPlayerBattlePos = GridPos(x: 24, y: 22);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-05 builds Grant trainer battle setup and persists a controlled victory outcome',
    () async {
      final repoRoot = _findRepoRoot();
      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
      final projectFilePath = p.join(projectRoot.path, 'project.json');

      expect(await File(projectFilePath).exists(), isTrue);

      final selbrumeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _startMapId,
      );
      final routeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _routeMapId,
      );

      expect(
          selbrumeBundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(routeBundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(selbrumeBundle.map.id, _startMapId);
      expect(routeBundle.map.id, _routeMapId);

      final grantTrainer = routeBundle.manifest.trainers.singleWhere(
        (trainer) => trainer.id == _trainerId,
      );
      expect(grantTrainer.name, 'grant');
      expect(grantTrainer.trainerClass, 'grant');
      expect(grantTrainer.battleDifficulty, 10);
      expect(grantTrainer.characterId, _grantCharacterId);
      expect(grantTrainer.team.map((member) => member.speciesId), <String>[
        'bulbasaur',
        'metapod',
        'ivysaur',
      ]);
      expect(grantTrainer.team.map((member) => member.level), <int>[
        1,
        25,
        25,
      ]);

      final grantCharacter = routeBundle.manifest.characters.singleWhere(
        (character) => character.id == _grantCharacterId,
      );
      expect(grantCharacter.tilesetId, _grantTilesetId);

      final grantTileset = routeBundle.manifest.tilesets.singleWhere(
        (tileset) => tileset.id == _grantTilesetId,
      );
      expect(grantTileset.relativePath, _grantAssetRelativePath);
      expect(
        await File(p.join(projectRoot.path, _grantAssetRelativePath)).exists(),
        isTrue,
      );

      final grantNpc = routeBundle.map.entities.singleWhere(
        (entity) => entity.id == _grantNpcId,
      );
      expect(grantNpc.kind, MapEntityKind.npc);
      expect(grantNpc.pos, const GridPos(x: 24, y: 20));
      expect(grantNpc.npc?.trainerId, _trainerId);
      expect(grantNpc.npc?.displayName, 'grant');

      final moveIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: routeBundle.manifest.pokemon.catalogFiles['moves']!,
        expectedCatalog: 'moves',
      );
      for (final member in grantTrainer.team) {
        final speciesJson = await _readSpeciesJsonById(
          projectRoot: projectRoot,
          speciesDir: routeBundle.manifest.pokemon.speciesDir,
          speciesId: member.speciesId,
        );
        expect(speciesJson['id'], member.speciesId);
        expect(member.moves, isNotEmpty);
        expect(moveIds, containsAll(member.moves));
      }

      const mutations = GameStateMutations();
      var state = createNewGameStateFromMap(
        startMap: selbrumeBundle.map,
        saveId: _saveId,
        playerName: 'P6 Tester',
        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
      );
      state = _seedP6InitialState(state);
      state = mutations.setFlag(state, _p603FlagId);
      state = mutations.completeStep(state, _p603StepId);
      state = _applyP604CaptureState(state);
      state = mutations.warpPlayer(
        state,
        _routeMapId,
        _grantPlayerBattlePos.x,
        _grantPlayerBattlePos.y,
        facing: EntityFacing.north,
      );

      expect(state.currentMapId, _routeMapId);
      expect(state.playerPosition, _grantPlayerBattlePos);
      expect(state.playerFacing, EntityFacing.north);
      expect(state.party.members, hasLength(2));
      expect(state.party.members.first.speciesId, _initialSpeciesId);
      expect(state.party.members.last.speciesId, _capturedSpeciesId);
      expect(_bagQuantity(state, _captureItemId), 4);
      expect(_bagQuantity(state, _medicineItemId), 2);
      expect(state.storyFlags.activeFlags, contains(_p603FlagId));
      expect(state.progression.completedStepIds, contains(_p603StepId));

      final world = GameplayWorldState.initial(
        map: routeBundle.map,
        playerPos: state.playerPosition,
        playerFacing: Direction.north,
        project: routeBundle.manifest,
        tileWidth: routeBundle.manifest.settings.tileWidth,
        tileHeight: routeBundle.manifest.settings.tileHeight,
      );
      final request = buildTrainerBattleRequestFromNpc(
        entity: grantNpc,
        manifest: routeBundle.manifest,
        world: world,
        createdAtEpochMs: 1,
      );

      expect(request, isNotNull);
      expect(request!.kind, RuntimeBattleKind.trainer);
      expect(request.source, RuntimeBattleSourceKind.trainerInteraction);
      expect(request.requestId, 'trainer:route 1:grant:grant:1');
      expect(request.trainerId, _trainerId);
      expect(request.npcEntityId, _grantNpcId);
      expect(request.mapId, _routeMapId);
      expect(request.playerPos, _grantPlayerBattlePos);
      expect(request.returnContext.mapId, _routeMapId);
      expect(request.returnContext.playerPos, _grantPlayerBattlePos);
      expect(request.returnContext.playerFacing, Direction.north);

      final mapper = RuntimeBattleSetupMapper();
      final lineup = mapper.selectPlayerBattleLineup(state.party);
      expect(lineup.activeIndex, 0);
      expect(lineup.reserveIndices, <int>[1]);
      expect(lineup.lineupPartyIndices, <int>[0, 1]);

      final setup = await mapper.map(
        bundle: routeBundle,
        gameState: state,
        request: request,
        playerPartyIndex: lineup.activeIndex,
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.trainerId, _trainerId);
      expect(setup.allowCapture, isFalse);
      expect(setup.playerPokemon.speciesId, _initialSpeciesId);
      expect(setup.playerReservePokemon.map((pokemon) => pokemon.speciesId),
          <String>[_capturedSpeciesId]);
      expect(setup.enemyPokemon.speciesId, 'bulbasaur');
      expect(setup.enemyPokemon.level, 1);
      expect(setup.enemyPokemon.moves.map((move) => move.id), <String>[
        'growl',
        'tackle',
      ]);
      expect(setup.enemyReservePokemon.map((pokemon) => pokemon.speciesId),
          <String>['metapod', 'ivysaur']);

      final session = createBattleSession(setup);
      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, _initialSpeciesId);
      expect(session.state.playerReserve.map((pokemon) => pokemon.speciesId),
          <String>[_capturedSpeciesId]);
      expect(session.state.enemy.speciesId, 'bulbasaur');
      expect(session.state.enemyReserve.map((pokemon) => pokemon.speciesId),
          <String>['metapod', 'ivysaur']);

      final outcome = _controlledTrainerVictoryOutcome(
        session.state,
        playerCurrentHp: 18,
      );
      expect(outcome.isVictory, isTrue);

      state = applyRuntimeBattleOutcomeToGameState(
        gameState: state,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: lineup.activeIndex,
          playerPartySlotIndicesByLineupIndex: lineup.lineupPartyIndices,
        ),
        outcome: outcome,
      );

      expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
      expect(state.party.members.first.currentHp, 18);
      expect(state.party.members.first.level, 8);
      expect(state.party.members.last.speciesId, _capturedSpeciesId);
      expect(state.trainerProfile.money, 0);
      expect(_bagQuantity(state, _captureItemId), 4);

      state = mutations.applyBattleRewards(
        state,
        moneyReward: _rewardMoney,
        levelUpsByPartyIndex: const <int, int>{0: 1},
      );

      expect(state.trainerProfile.money, _rewardMoney);
      expect(state.party.members.first.level, 9);
      expect(state.party.members.first.currentHp, 18);
      expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
      expect(state.storyFlags.activeFlags, contains(_p603FlagId));
      expect(state.progression.completedStepIds, contains(_p603StepId));

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, _saveId);
      expect(reloaded.currentMapId, _routeMapId);
      expect(reloaded.playerPosition, _grantPlayerBattlePos);
      expect(reloaded.playerFacing, EntityFacing.north);
      expect(reloaded.party.members, hasLength(2));
      expect(reloaded.party.members.first.speciesId, _initialSpeciesId);
      expect(reloaded.party.members.first.level, 9);
      expect(reloaded.party.members.first.currentHp, 18);
      expect(reloaded.party.members.last.speciesId, _capturedSpeciesId);
      expect(reloaded.party.members.last.level, 3);
      expect(reloaded.trainerProfile.money, _rewardMoney);
      expect(_bagQuantity(reloaded, _captureItemId), 4);
      expect(_bagQuantity(reloaded, _medicineItemId), 2);
      expect(reloaded.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
      expect(reloaded.storyFlags.activeFlags, contains(_p603FlagId));
      expect(reloaded.progression.completedStepIds, contains(_p603StepId));
      expect(
        reloaded.progression.caughtSpeciesIds,
        contains(_capturedSpeciesId),
      );
      expect(
        reloaded.progression.seenSpeciesIds,
        contains(_capturedSpeciesId),
      );
    },
  );
}

GameState _seedP6InitialState(GameState state) {
  const mutations = GameStateMutations();
  var next = mutations.givePokemon(
    state,
    pokemon: const PlayerPokemon(
      speciesId: _initialSpeciesId,
      natureId: 'hardy',
      abilityId: _initialAbilityId,
      level: 8,
      currentHp: 24,
      knownMoveIds: _initialMoves,
    ),
  );
  next = mutations.giveItem(next, _captureItemId, 5);
  next = mutations.giveItem(next, _medicineItemId, 2);
  return next;
}

GameState _applyP604CaptureState(GameState state) {
  const mutations = GameStateMutations();
  var next = markSpeciesSeenInGameState(state, _capturedSpeciesId);
  next = mutations.consumeItem(next, _captureItemId, 1);
  final captureResult = mutations.applyCapturedPokemon(
    next,
    pokemon: const PlayerPokemon(
      speciesId: _capturedSpeciesId,
      natureId: 'hardy',
      abilityId: _initialAbilityId,
      level: 3,
      currentHp: 18,
      knownMoveIds: _initialMoves,
    ),
  );
  expect(captureResult.destination, CaptureDestinationKind.party);
  return captureResult.state;
}

BattleOutcome _controlledTrainerVictoryOutcome(
  BattleState battleState, {
  required int playerCurrentHp,
}) {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _withCurrentHp(battleState.player, playerCurrentHp),
      playerReserve: battleState.playerReserve,
      enemy: _withCurrentHp(battleState.enemy, 0),
      enemyReserve: battleState.enemyReserve
          .map((combatant) => _withCurrentHp(combatant, 0))
          .toList(growable: false),
      field: battleState.field,
      currentTurn: null,
      outcome: null,
    ),
  );
}

BattleCombatant _withCurrentHp(BattleCombatant combatant, int currentHp) {
  final clamped = currentHp.clamp(0, combatant.maxHp).toInt();
  if (clamped == combatant.currentHp) {
    return combatant;
  }
  if (clamped < combatant.currentHp) {
    return combatant.withDamage(combatant.currentHp - clamped);
  }
  return combatant.withHeal(clamped - combatant.currentHp);
}

int _bagQuantity(GameState state, String itemId) {
  final entry = state.bag.normalized().entries.firstWhere(
        (candidate) => candidate.itemId == itemId,
        orElse: () =>
            BagEntry(itemId: itemId, categoryId: 'items', quantity: 0),
      );
  return entry.quantity;
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;

  while (true) {
    final candidate = File(
      p.join(current.path, 'selbrume', 'project.json'),
    );
    if (candidate.existsSync()) {
      return current;
    }

    final parent = current.parent.absolute;
    if (parent.path == current.path) {
      throw StateError('Could not find repo-local selbrume/project.json');
    }
    current = parent;
  }
}

Future<Map<String, dynamic>> _readSpeciesJsonById({
  required Directory projectRoot,
  required String speciesDir,
  required String speciesId,
}) async {
  final directory = Directory(p.join(projectRoot.path, speciesDir));
  await for (final entity in directory.list(recursive: false)) {
    if (entity is! File || p.extension(entity.path) != '.json') {
      continue;
    }
    final json = await _readJsonFile(entity);
    if (json['id'] == speciesId) {
      return json;
    }
  }
  throw StateError('Species id not found in Selbrume data: $speciesId');
}

Future<Set<String>> _readCatalogIds({
  required Directory projectRoot,
  required String relativePath,
  required String expectedCatalog,
}) async {
  final json = await _readProjectJson(projectRoot, relativePath);
  expect(json['catalog'], expectedCatalog);
  return (json['entries'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((entry) => entry['id'] as String)
      .toSet();
}

Future<Map<String, dynamic>> _readProjectJson(
  Directory projectRoot,
  String relativePath,
) {
  return _readJsonFile(File(p.join(projectRoot.path, relativePath)));
}

Future<Map<String, dynamic>> _readJsonFile(File file) async {
  final decoded = jsonDecode(await file.readAsString());
  return decoded as Map<String, dynamic>;
}
