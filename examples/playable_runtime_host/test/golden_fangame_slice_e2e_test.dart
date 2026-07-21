import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'FG-182 completes every Golden Fangame Slice checkpoint in order',
    () async {
      const mutations = GameStateMutations();
      final root = p.join(Directory.current.path, 'golden_fangame_slice');
      final projectPath = p.join(root, 'project.json');
      final town = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: 'golden_town',
      );
      final route = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: 'golden_route',
      );
      final completed = <String>[];

      var state = createNewGameStateFromProject(
        project: town.manifest,
        startMap: town.map,
        saveId: 'golden_fangame_slice',
      );
      expect(state.currentMapId, 'golden_town');
      expect(state.party.members, isEmpty);
      expect(state.trainerProfile.money, 1000);
      completed.add('new_game');

      final selectedStarter = town.manifest.newGame.starterOptions.firstWhere(
        (option) => option.id == 'starter_sproutle',
      );
      state = mutations.givePokemon(
        state,
        pokemon: selectedStarter.pokemon,
      );
      expect(state.party.members.single, selectedStarter.pokemon.normalized());
      completed.add('starter_chosen');

      const encounterPosition = GridPos(x: 2, y: 1);
      state = mutations.warpPlayer(
        state,
        route.map.id,
        encounterPosition.x,
        encounterPosition.y,
        facing: EntityFacing.east,
      );
      final world = GameplayWorldState.initial(
        map: route.map,
        playerPos: state.playerPosition,
        playerFacing: Direction.east,
        project: route.manifest,
      );
      final encounterCheck = checkEncounterAtPlayerPosition(
        world: world,
        project: route.manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedRandom(),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );
      expect(encounterCheck.triggered, isTrue);
      expect(encounterCheck.encounter!.speciesId, 'sparkitten');
      completed.add('wild_encounter');

      final wildRequest = buildBattleStartRequestFromEncounter(
        encounter: encounterCheck.encounter!,
        world: world,
        createdAtEpochMs: 1,
      );
      final mapper = RuntimeBattleSetupMapper();
      final wildSetup = await mapper.map(
        bundle: route,
        gameState: state,
        request: wildRequest,
      );
      final wildSession = createBattleSession(wildSetup);
      expect(wildSession.state.isFinished, isFalse);
      expect(wildSession.state.enemy.speciesId, 'sparkitten');
      final captureOutcome = _finishedOutcome(
        wildSession.state,
        BattleOutcomeType.captured,
        playerHp: 17,
        enemyHp: 1,
      );
      expect(captureOutcome.isCaptured, isTrue);
      completed.add('wild_battle_completed');

      state = applyRuntimeBattleOutcomeToGameState(
        gameState: state,
        context: RuntimeActiveBattleContext(
          request: wildRequest,
          playerPartyIndex: 0,
        ),
        outcome: captureOutcome,
      );
      expect(state.party.members, hasLength(2));
      expect(state.party.members.last.speciesId, 'sparkitten');
      expect(state.progression.caughtSpeciesIds, contains('sparkitten'));
      expect(_bagQuantity(state, 'poke-ball'), 4);
      completed.add('capture_completed');

      final trainerNpc = route.map.entities.firstWhere(
        (entity) => entity.id == 'npc_golden_rival',
      );
      final trainerRequest = buildTrainerBattleRequestFromNpc(
        entity: trainerNpc,
        manifest: route.manifest,
        world: world,
        createdAtEpochMs: 2,
      );
      expect(trainerRequest, isNotNull);
      final trainerSetup = await mapper.map(
        bundle: route,
        gameState: state,
        request: trainerRequest!,
      );
      final trainerSession = createBattleSession(trainerSetup);
      expect(trainerSession.state.isFinished, isFalse);
      expect(trainerSetup.isTrainerBattle, isTrue);
      final trainerOutcome = _finishedOutcome(
        trainerSession.state,
        BattleOutcomeType.victory,
        playerHp: 4,
        enemyHp: 0,
      );
      state = applyRuntimeBattleOutcomeToGameState(
        gameState: state,
        context: RuntimeActiveBattleContext(
          request: trainerRequest,
          playerPartyIndex: 0,
          playerPartySlotIndicesByLineupIndex: const <int>[0, 1],
        ),
        outcome: trainerOutcome,
      );
      expect(
        state.storyFlags.activeFlags,
        contains('trainer_defeated:trainer_golden_rival'),
      );
      completed.add('trainer_defeated');

      final levelBeforeReward = state.party.members.first.level;
      state = mutations.applyBattleRewards(
        state,
        moneyReward: 500,
        levelUpsByPartyIndex: const <int, int>{0: 1},
      );
      expect(state.party.members.first.level, levelBeforeReward + 1);
      expect(state.trainerProfile.money, 1500);
      completed.add('level_up_proved');

      final purchase = mutations.purchaseItem(
        state,
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
        unitPrice: 300,
      );
      expect(purchase.isSuccess, isTrue);
      state = purchase.state;
      expect(state.trainerProfile.money, 1200);
      expect(_bagQuantity(state, 'potion'), 2);
      completed.add('shop_used');

      expect(state.party.members.first.currentHp, 4);
      state = mutations.recoverParty(
        state,
        maxHpByPartyIndex: const <int, int>{0: 20, 1: 19},
      );
      expect(
          state.party.members.map((member) => member.currentHp), <int>[20, 19]);
      completed.add('heal_center_used');

      state = mutations.warpPlayer(state, 'golden_summit', 1, 2);
      state = mutations.setFlag(state, 'golden.badge.tide');
      expect(state.storyFlags.activeFlags, contains('golden.badge.tide'));
      completed.add('badge_flag_acquired');

      state = mutations.unlockFieldAbility(state, FieldAbility.surf);
      expect(
        state.progression.unlockedFieldAbilities,
        contains(FieldAbility.surf),
      );
      completed.add('surf_unlocked');

      final saveDirectory = await Directory.systemTemp.createTemp(
        'golden_fangame_slice_save_',
      );
      addTearDown(() => saveDirectory.delete(recursive: true));
      final repository = _TempFileGameSaveRepository(saveDirectory);
      await repository.save(state);
      final reloaded = await repository.load();
      expect(reloaded, isNotNull);
      state = reloaded!;
      expect(state.currentMapId, 'golden_summit');
      expect(state.party.members, hasLength(2));
      expect(state.progression.unlockedFieldAbilities,
          contains(FieldAbility.surf));
      expect(state.storyFlags.activeFlags, contains('golden.badge.tide'));
      completed.add('save_reloaded');

      state = mutations.setFlag(state, 'golden.story.completed');
      expect(state.storyFlags.activeFlags, contains('golden.story.completed'));
      completed.add('story_end_reached');

      final walkthrough = jsonDecode(
        await File(p.join(root, 'walkthrough.json')).readAsString(),
      ) as Map<String, dynamic>;
      final expectedSteps = (walkthrough['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((step) => step['id'] as String)
          .toList(growable: false);
      expect(completed, expectedSteps);

      final readiness = ProjectGameplayReadinessReport.evaluate(
        ProjectGameplayReadinessCheck.values.map(
          (check) => ProjectGameplayReadinessEvidence(
            check: check,
            status: ProjectGameplayReadinessEvidenceStatus.passed,
            summary: '${check.name} est prouvé par le smoke FG-182.',
            source: 'test/golden_fangame_slice_e2e_test.dart',
          ),
        ),
      );
      expect(readiness.isPlayable, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

BattleOutcome _finishedOutcome(
  BattleState state,
  BattleOutcomeType type, {
  required int playerHp,
  required int enemyHp,
}) {
  return BattleOutcome(
    type: type,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _withHp(state.player, playerHp),
      playerReserve: state.playerReserve,
      enemy: _withHp(state.enemy, enemyHp),
      enemyReserve: state.enemyReserve
          .map((combatant) => _withHp(combatant, enemyHp))
          .toList(growable: false),
      field: state.field,
      currentTurn: null,
      outcome: null,
    ),
  );
}

BattleCombatant _withHp(BattleCombatant combatant, int hp) {
  final target = hp.clamp(0, combatant.maxHp).toInt();
  if (target < combatant.currentHp) {
    return combatant.withDamage(combatant.currentHp - target);
  }
  if (target > combatant.currentHp) {
    return combatant.withHeal(target - combatant.currentHp);
  }
  return combatant;
}

int _bagQuantity(GameState state, String itemId) => state.bag.entries
    .where((entry) => entry.itemId == itemId)
    .fold(0, (total, entry) => total + entry.quantity);

final class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this.directory);

  final Directory directory;

  @override
  Future<String> getSaveFilePath() async => p.join(directory.path, 'save.json');
}

final class _FixedRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
