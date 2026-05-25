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
const _saveId = 'p6_06_selbrume_save_load_golden_slice';
const _trainerId = 'grant';
const _trainerDefeatedFlag = 'trainer_defeated:grant';
const _grantNpcId = 'grant';
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
const _capturedHpAfterTrainerWriteBack = 16;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-06 persists the full Selbrume golden slice through real disk save/load',
    () async {
      final repoRoot = _findRepoRoot();
      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
      final projectFilePath = p.join(projectRoot.path, 'project.json');
      final testDirectory =
          await Directory.systemTemp.createTemp('p6_06_selbrume_save_load_');
      final repository = _TempFileGameSaveRepository(testDirectory);
      final saveGame = SaveGameUseCase(repository);
      final loadGame = LoadGameUseCase(repository);

      try {
        expect(await File(projectFilePath).exists(), isTrue);
        expect(p.isWithin(repoRoot.path, testDirectory.path), isFalse);

        final selbrumeBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: _startMapId,
        );
        final routeBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: _routeMapId,
        );

        expect(
          selbrumeBundle.projectRootDirectory,
          p.normalize(projectRoot.path),
        );
        expect(routeBundle.projectRootDirectory, p.normalize(projectRoot.path));
        expect(selbrumeBundle.map.id, _startMapId);
        expect(routeBundle.map.id, _routeMapId);

        var state = createNewGameStateFromMap(
          startMap: selbrumeBundle.map,
          saveId: _saveId,
          playerName: 'P6 Tester',
          tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
          tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
        ).copyWith(
          metadata: const <String, String>{
            'lot': 'p6_06',
            'persistence': 'file_game_save_repository',
          },
        );

        state = _seedP6InitialState(state);
        state = _applyP603NarrativeState(state);
        state = _applyP604CaptureState(state);
        state = await _applyP605TrainerVictoryState(
          state: state,
          routeBundle: routeBundle,
        );

        _expectGoldenSliceState(state);
        expect(await saveGame.execute(state), isTrue);
        expect(await repository.exists(), isTrue);

        final saveFilePath = await repository.exposedSaveFilePath();
        final saveFile = File(saveFilePath);
        expect(await saveFile.exists(), isTrue);
        expect(p.isWithin(repoRoot.path, saveFile.path), isFalse);
        expect(p.isWithin(projectRoot.path, saveFile.path), isFalse);

        final savedJson =
            jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
        expect(savedJson['saveId'], _saveId);
        expect(savedJson['currentMapId'], _routeMapId);
        expect(savedJson['pokemonStorage'], isA<Map<String, dynamic>>());
        expect(
          (savedJson['progression'] as Map<String, dynamic>)['storyFlags'],
          contains(_p603FlagId),
        );

        final loaded = await loadGame.execute();
        expect(loaded, isNotNull);

        final reloaded = normalizeLoadedGameState(loaded!);
        _expectGoldenSliceState(reloaded);
      } finally {
        if (await testDirectory.exists()) {
          await testDirectory.delete(recursive: true);
        }
      }
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

GameState _applyP603NarrativeState(GameState state) {
  const mutations = GameStateMutations();
  var next = mutations.setFlag(state, _p603FlagId);
  next = mutations.completeStep(next, _p603StepId);
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
  expect(captureResult.partyIndex, 1);
  return captureResult.state;
}

Future<GameState> _applyP605TrainerVictoryState({
  required GameState state,
  required RuntimeMapBundle routeBundle,
}) async {
  const mutations = GameStateMutations();
  var next = mutations.warpPlayer(
    state,
    _routeMapId,
    _grantPlayerBattlePos.x,
    _grantPlayerBattlePos.y,
    facing: EntityFacing.north,
  );

  final grantNpc = routeBundle.map.entities.singleWhere(
    (entity) => entity.id == _grantNpcId,
  );
  expect(grantNpc.kind, MapEntityKind.npc);
  expect(grantNpc.npc?.trainerId, _trainerId);

  final world = GameplayWorldState.initial(
    map: routeBundle.map,
    playerPos: next.playerPosition,
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
  expect(request.trainerId, _trainerId);
  expect(request.mapId, _routeMapId);
  expect(request.playerPos, _grantPlayerBattlePos);

  final mapper = RuntimeBattleSetupMapper();
  final lineup = mapper.selectPlayerBattleLineup(next.party);
  final setup = await mapper.map(
    bundle: routeBundle,
    gameState: next,
    request: request,
    playerPartyIndex: lineup.activeIndex,
  );

  expect(setup.isTrainerBattle, isTrue);
  expect(setup.trainerId, _trainerId);
  expect(setup.allowCapture, isFalse);
  expect(setup.playerPokemon.speciesId, _initialSpeciesId);
  expect(setup.enemyPokemon.speciesId, 'bulbasaur');

  final session = createBattleSession(setup);
  expect(session.state.isFinished, isFalse);

  final outcome = _controlledTrainerVictoryOutcome(
    session.state,
    playerCurrentHp: 18,
  );
  expect(outcome.isVictory, isTrue);

  next = applyRuntimeBattleOutcomeToGameState(
    gameState: next,
    context: RuntimeActiveBattleContext(
      request: request,
      playerPartyIndex: lineup.activeIndex,
      playerPartySlotIndicesByLineupIndex: lineup.lineupPartyIndices,
    ),
    outcome: outcome,
  );
  expect(next.storyFlags.activeFlags, contains(_trainerDefeatedFlag));

  next = mutations.applyBattleRewards(
    next,
    moneyReward: _rewardMoney,
    levelUpsByPartyIndex: const <int, int>{0: 1},
  );
  return next;
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

void _expectGoldenSliceState(GameState state) {
  expect(state.saveId, _saveId);
  expect(state.currentMapId, _routeMapId);
  expect(state.playerPosition, _grantPlayerBattlePos);
  expect(state.playerFacing, EntityFacing.north);
  expect(state.party.members, hasLength(2));

  final initialPokemon = state.party.members.first;
  expect(initialPokemon.speciesId, _initialSpeciesId);
  expect(initialPokemon.level, 9);
  expect(initialPokemon.currentHp, 18);
  expect(initialPokemon.knownMoveIds, _initialMoves);

  final capturedPokemon = state.party.members.last;
  expect(capturedPokemon.speciesId, _capturedSpeciesId);
  expect(capturedPokemon.level, 3);
  expect(capturedPokemon.currentHp, _capturedHpAfterTrainerWriteBack);
  expect(capturedPokemon.knownMoveIds, _initialMoves);

  expect(state.pokemonStorage.storedPokemon, isEmpty);
  expect(_bagQuantity(state, _captureItemId), 4);
  expect(_bagQuantity(state, _medicineItemId), 2);
  expect(state.trainerProfile.money, _rewardMoney);
  expect(state.storyFlags.activeFlags, contains(_p603FlagId));
  expect(state.progression.completedStepIds, contains(_p603StepId));
  expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
  expect(state.progression.caughtSpeciesIds, contains(_capturedSpeciesId));
  expect(state.progression.seenSpeciesIds, contains(_capturedSpeciesId));
  expect(
    state.metadata,
    equals(<String, String>{
      'lot': 'p6_06',
      'persistence': 'file_game_save_repository',
    }),
  );
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

class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory(p.join(_testDirectory.path, 'pokemonProject'));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return p.join(saveDir.path, 'game_save.json');
  }
}
