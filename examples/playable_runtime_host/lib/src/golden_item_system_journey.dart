import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

final class GoldenItemSystemJourneyReceipt {
  const GoldenItemSystemJourneyReceipt({
    required this.schemaVersion,
    required this.projectId,
    required this.sourceRevision,
    required this.rngSeed,
    required this.fixtureSha256,
    required this.finalStateSha256,
    required this.steps,
    required this.observations,
    required this.finalBagQuantities,
    required this.finalMoney,
    required this.finalPartySpeciesIds,
    required this.finalHeldItemIds,
    required this.finalKnownMoveIds,
    required this.completedStepIds,
    required this.storyFlagIds,
  });

  final int schemaVersion;
  final String projectId;
  final String sourceRevision;
  final int rngSeed;
  final String fixtureSha256;
  final String finalStateSha256;
  final List<String> steps;
  final List<String> observations;
  final Map<String, int> finalBagQuantities;
  final int finalMoney;
  final List<String> finalPartySpeciesIds;
  final List<String> finalHeldItemIds;
  final List<List<String>> finalKnownMoveIds;
  final List<String> completedStepIds;
  final List<String> storyFlagIds;

  Map<String, Object> toJson() => <String, Object>{
    'schemaVersion': schemaVersion,
    'projectId': projectId,
    'sourceRevision': sourceRevision,
    'rngSeed': rngSeed,
    'fixtureSha256': fixtureSha256,
    'finalStateSha256': finalStateSha256,
    'steps': steps,
    'observations': observations,
    'finalBagQuantities': finalBagQuantities,
    'finalMoney': finalMoney,
    'finalPartySpeciesIds': finalPartySpeciesIds,
    'finalHeldItemIds': finalHeldItemIds,
    'finalKnownMoveIds': finalKnownMoveIds,
    'completedStepIds': completedStepIds,
    'storyFlagIds': storyFlagIds,
  };
}

final class GoldenItemSystemJourney {
  const GoldenItemSystemJourney._();

  static const _expectedSteps = <String>[
    'new_game',
    'initial_items',
    'pickup',
    'hidden_pickup',
    'overworld_heal',
    'buy',
    'sell',
    'battle_item',
    'capture_attempt',
    'equip_held_item',
    'learn_move_tm',
    'learn_move_hm',
    'battle_reward',
    'save_reload',
  ];

  static Future<GoldenItemSystemJourneyReceipt> run({
    required String projectRootDirectory,
    required String saveRootDirectory,
    required String sourceRevision,
    required int rngSeed,
  }) async {
    _require(
      RegExp(r'^[0-9a-f]{40,64}$').hasMatch(sourceRevision),
      'Invalid source revision.',
    );
    final root = p.normalize(p.absolute(projectRootDirectory));
    final walkthrough = await _loadWalkthrough(root);
    final projectId = _requiredString(walkthrough, 'projectId');
    final steps = _walkthroughStepIds(walkthrough);
    _require(_sameStrings(steps, _expectedSteps), 'Unexpected walkthrough.');

    final project = await loadProjectManifestFromFile(
      p.join(root, 'project.json'),
    );
    final mapEntry = project.maps.singleWhere(
      (entry) => entry.id == project.newGame.startMapId,
    );
    final startMap = await loadMapDataFromFile(
      p.join(root, mapEntry.relativePath),
      projectDialogueContext: project,
    );
    final itemCatalog = await const RuntimeItemCatalogLoader().loadSnapshot(
      projectRootDirectory: root,
      pokemonConfig: project.pokemon,
    );
    _require(itemCatalog.definitions.length == 11, 'Incomplete item catalog.');

    final observations = <String>[];
    var state = createNewGameStateFromProject(
      project: project,
      startMap: startMap,
      saveId: projectId,
    );
    observations.add('new_game_from_project');
    _require(
      _sameIntMap(_bagQuantities(state), const <String, int>{
        'antidote': 1,
        'ether': 1,
        'hm-surf': 1,
        'lab-key': 1,
        'leftovers': 1,
        'lucky-charm': 1,
        'poke-ball': 3,
        'potion': 2,
        'tm-protect': 1,
      }),
      'Initial bag does not match the authored project.',
    );
    observations.add('initial_bag_strict');

    state = _applyPickup(project, state, observations);
    state = _applyHiddenPickup(project, startMap, state, observations);
    final itemUseService = PlayerItemUseService(snapshot: itemCatalog);
    state = _useItem(itemUseService, state, itemId: 'antidote', maxHp: 20);
    _require(state.party.members.first.statusId.isEmpty, 'Antidote failed.');
    observations.add('status_cured_overworld');

    state = _useItem(
      itemUseService,
      state,
      itemId: 'ether',
      maxHp: 20,
      moveId: 'tackle',
      maxPpByMoveId: const <String, int>{'tackle': 35},
    );
    _require(
      state.party.members.first.currentPpByMoveId?['tackle'] == 30,
      'Ether failed.',
    );
    observations.add('pp_restored_overworld');

    state = _useItem(itemUseService, state, itemId: 'potion', maxHp: 20);
    _require(state.party.members.first.currentHp == 20, 'Potion failed.');
    observations.add('hp_healed_overworld');

    final shop = project.shops.singleWhere(
      (candidate) => candidate.id == 'golden_item_shop',
    );
    const mutations = GameStateMutations();
    final purchase = mutations.purchaseFromShop(
      state,
      shop: shop,
      itemId: 'potion',
      quantity: 1,
      itemCatalog: itemCatalog,
    );
    _require(purchase.isSuccess, 'Shop purchase failed.');
    state = purchase.state;
    observations.add('shop_purchase_applied');

    final resolvedShop = const ShopStateResolver().resolve(
      shop: shop,
      gameState: state,
    );
    final sale = mutations.sellToResolvedShop(
      state,
      shop: shop,
      expectedStateId: resolvedShop.stateId,
      itemId: 'potion',
      quantity: 1,
      itemCatalog: itemCatalog,
    );
    _require(sale.isSuccess, 'Shop sale failed.');
    state = sale.state;
    observations.add('shop_sale_applied');

    final wildRequest = _wildRequest(rngSeed);
    final wildContext = RuntimeActiveBattleContext.withLineupMapping(
      request: wildRequest,
      playerPartyIndex: 0,
      playerPartySlotIndicesByLineupIndex: const <int>[0],
    );
    final battle = createBattleSession(
      _wildBattleSetup(state),
      rng: BattleSeededRng(state: rngSeed),
    ).applyChoice(const PlayerBattleChoiceFight(0));
    _require(
      battle.state.player.currentHp < 20 && battle.state.player.currentHp > 0,
      'The authored battle did not damage the player.',
    );
    observations.add('battle_damage_applied');

    final battleItem = tryApplyRuntimeBattleItemUse(
      session: battle,
      gameState: state,
      context: wildContext,
      itemId: 'potion',
      targetLineupIndex: 0,
      itemCatalog: itemCatalog,
    );
    _require(battleItem != null, 'Battle Potion failed.');
    state = battleItem!.updatedGameState;
    _require(
      battleItem.consumptionReceipt?.itemId == 'potion' &&
          state.party.members.first.currentHp ==
              battleItem.updatedSession.state.player.currentHp &&
          !_bagQuantities(state).containsKey('potion'),
      'Battle heal failed.',
    );
    observations.add('battle_item_applied');

    final captureDefinition = itemCatalog.definitionFor('poke-ball')!.capture!;
    final capture = submitRuntimeBattleCaptureAttempt<BattleSession>(
      gameState: state,
      context: wildContext,
      captureAllowed: true,
      itemId: 'poke-ball',
      itemCatalog: itemCatalog,
      submitToEngine: () => battleItem.updatedSession.applyChoice(
        PlayerBattleChoiceCapture(
          itemId: 'poke-ball',
          rateNumerator: captureDefinition.rateNumerator,
          rateDenominator: captureDefinition.rateDenominator,
        ),
      ),
    );
    final captureOutcome = capture.engineResult.state.outcome;
    _require(captureOutcome?.isCaptured ?? false, 'Capture failed.');
    state = applyRuntimeBattleOutcomeToGameState(
      gameState: capture.updatedGameState,
      context: wildContext,
      outcome: captureOutcome!,
      captureAttemptReceipt: capture.receipt,
    );
    _require(
      state.party.members.length == 2,
      'Captured Pokemon was not stored.',
    );
    observations.add('capture_succeeded');

    final heldItem = const HeldItemOperations().equip(
      state,
      partyIndex: 0,
      itemId: 'leftovers',
    );
    _require(heldItem.isSuccess, 'Held item equip failed.');
    state = heldItem.state;
    observations.add('held_item_equipped');

    final machine = await RuntimeMoveMachineLoader().loadCandidate(
      projectRootDirectory: root,
      pokemonConfig: project.pokemon,
      itemId: 'tm-protect',
      speciesRef: state.party.members.first.speciesId,
      fallbackSpeciesId: state.party.members.first.speciesId,
    );
    _require(machine != null, 'TM compatibility was not resolved.');
    final learned = const PokemonMoveMachineService().apply(
      state,
      partyIndex: 0,
      candidate: machine!,
      decision: const PokemonMoveMachineDecision.learn(),
      itemCatalog: itemCatalog,
    );
    _require(learned.isSuccess, 'TM learning failed.');
    state = learned.state;
    observations.add('tm_learned');

    final hm = await RuntimeMoveMachineLoader().loadCandidate(
      projectRootDirectory: root,
      pokemonConfig: project.pokemon,
      itemId: 'hm-surf',
      speciesRef: state.party.members.first.speciesId,
      fallbackSpeciesId: state.party.members.first.speciesId,
    );
    _require(hm != null, 'HM compatibility was not resolved.');
    observations.add('hm_compatible_target_selected');
    final hmQuantityBefore = _bagQuantities(state)['hm-surf'];
    final learnedHm = const PokemonMoveMachineService().apply(
      state,
      partyIndex: 0,
      candidate: hm!,
      decision: const PokemonMoveMachineDecision.replace(
        expectedMoveId: 'growl',
      ),
      itemCatalog: itemCatalog,
    );
    _require(learnedHm.isSuccess, 'HM learning failed.');
    state = learnedHm.state;
    _require(
      _bagQuantities(state)['hm-surf'] == hmQuantityBefore,
      'HM was consumed.',
    );
    observations.add('hm_learned_without_consumption');
    _require(
      !state.progression.unlockedFieldAbilities.contains(FieldAbility.surf),
      'Learning Surf unlocked its field ability implicitly.',
    );
    observations.add('field_ability_still_locked_after_hm');

    final trainer = project.trainers.singleWhere(
      (candidate) => candidate.id == 'golden_item_trainer',
    );
    state = mutations.applyBattleRewards(
      state,
      reward: BattleReward(
        sourceKind: BattleRewardSourceKind.trainer,
        trainerId: trainer.id,
        money: trainer.moneyReward,
        itemGrants: trainer.rewardItemGrants.map(
          (grant) => BattleRewardItemGrant(
            itemId: grant.itemId,
            quantity: grant.quantity,
          ),
        ),
        flagIds: trainer.rewardFlagIds,
        badgeId: trainer.rewardBadgeId,
        fieldAbilityUnlock: trainer.rewardFieldAbilityUnlock,
      ),
      itemCatalog: itemCatalog,
    );
    _require(_bagQuantities(state)['revive'] == 1, 'Trainer reward failed.');
    observations.add('trainer_reward_applied');
    _require(
      state.trainerProfile.badgeIds.contains('tidal-badge') &&
          state.progression.unlockedFieldAbilities.contains(FieldAbility.surf),
      'The authored reward did not unlock Surf explicitly.',
    );
    observations.add('field_ability_unlocked_by_reward');

    state = _faintSecondPartyMember(state, rngSeed);
    _require(state.party.members[1].currentHp == 0, 'Battle faint failed.');
    observations.add('party_member_fainted_in_battle');
    state = _useItem(
      itemUseService,
      state,
      itemId: 'revive',
      partyIndex: 1,
      maxHp: 20,
    );
    _require(state.party.members[1].currentHp == 10, 'Revive failed.');
    observations.add('revived_overworld');

    final keyGate = const ScriptConditionEvaluator().evaluate(
      ScriptConditionFactory.itemQuantityAtLeast('lab-key', 1),
      state,
    );
    _require(
      keyGate && _bagQuantities(state)['lab-key'] == 1,
      'Key gate failed.',
    );
    observations.add('key_item_gate_preserved');
    _require(
      ItemCapabilityResolver(itemCatalog).classifyUse(
            itemId: 'lucky-charm',
            context: ProjectItemUseContext.overworld,
          ) ==
          ItemUsabilityState.passive,
      'Passive item was misclassified.',
    );
    observations.add('passive_item_preserved');

    final repository = _GoldenFileGameSaveRepository(saveRootDirectory);
    await repository.save(state);
    final saveFile = File(p.join(saveRootDirectory, 'game_save.json'));
    final rawSave =
        jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
    validateItemSystemSaveSchema(rawSave);
    _require(_hasStrictBagWire(rawSave), 'Save bag is not strict V1.');
    observations.add('strict_save_wire_written');
    final reloaded = await repository.load();
    _require(reloaded != null, 'Runtime save could not be reloaded.');
    state = reloaded!;
    observations.add('runtime_save_reloaded');
    _require(
      _bagQuantities(state)['hm-surf'] == 1 &&
          _bagQuantities(state)['hidden-tonic'] == 1 &&
          state.party.members.first.knownMoveIds.contains('surf') &&
          state.trainerProfile.badgeIds.contains('tidal-badge') &&
          state.progression.unlockedFieldAbilities.contains(FieldAbility.surf),
      'HM or explicit Surf gate did not survive save/reload.',
    );
    observations.add('hm_and_explicit_surf_gate_persisted');
    _require(
      state.storyFlags.activeFlags.contains(
            'golden_item.hidden_pickup_collected',
          ) &&
          state.progression.completedStepIds.contains(
            'golden_item.hidden_pickup',
          ),
      'Hidden pickup consumption did not survive save/reload.',
    );
    observations.add('hidden_pickup_persisted');

    final finalBag = _bagQuantities(state);
    final storyFlags = state.storyFlags.activeFlags.toList(growable: false)
      ..sort();
    final completedSteps = state.progression.completedStepIds.toList(
      growable: false,
    );
    return GoldenItemSystemJourneyReceipt(
      schemaVersion: 1,
      projectId: projectId,
      sourceRevision: sourceRevision,
      rngSeed: rngSeed,
      fixtureSha256: await _fixtureDigest(root),
      finalStateSha256: _stateDigest(state),
      steps: List<String>.unmodifiable(steps),
      observations: List<String>.unmodifiable(observations),
      finalBagQuantities: Map<String, int>.unmodifiable(finalBag),
      finalMoney: state.trainerProfile.money,
      finalPartySpeciesIds: List<String>.unmodifiable(
        state.party.members.map((member) => member.speciesId),
      ),
      finalHeldItemIds: List<String>.unmodifiable(
        state.party.members.map((member) => member.heldItemId),
      ),
      finalKnownMoveIds: List<List<String>>.unmodifiable(
        state.party.members.map(
          (member) => List<String>.unmodifiable(member.knownMoveIds),
        ),
      ),
      completedStepIds: List<String>.unmodifiable(completedSteps),
      storyFlagIds: List<String>.unmodifiable(storyFlags),
    );
  }

  static GameState _applyPickup(
    ProjectManifest project,
    GameState state,
    List<String> observations,
  ) {
    GameState current = state;
    ScenarioRuntimeExecutionResult dispatch(GameState source) {
      current = source;
      return const ScenarioRuntimeExecutor().dispatch(
        scenarios: project.scenarios,
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'golden_item_lab',
          entityId: 'item_ether_pickup',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: source,
          onGameStateUpdated: (updated) => current = updated,
          openDialogue: (_, {startNode, runtimeSourceId}) => false,
          runScript: (_, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );
    }

    final first = dispatch(state);
    _require(
      first.success && _bagQuantities(current)['ether'] == 2,
      'Pickup failed.',
    );
    observations.add('pickup_scenario_applied');
    final afterFirst = _stateDigest(current);
    final second = dispatch(current);
    _require(
      second.status == ScenarioRuntimeExecutionStatus.noMatchingSource &&
          _stateDigest(current) == afterFirst,
      'Pickup is not idempotent.',
    );
    observations.add('pickup_scenario_idempotent');
    return current;
  }

  static GameState _applyHiddenPickup(
    ProjectManifest project,
    MapData map,
    GameState state,
    List<String> observations,
  ) {
    final hiddenEntity = map.entities.singleWhere(
      (entity) => entity.id == 'item_hidden_tonic',
    );
    _require(
      hiddenEntity.kind == MapEntityKind.item &&
          hiddenEntity.item?.visibility == MapEntityItemVisibility.hidden,
      'Hidden pickup is not authored as a hidden item entity.',
    );
    observations.add('hidden_pickup_authored_hidden');
    GameState current = state;
    final messages = <String>[];

    ScenarioRuntimeExecutionResult dispatch(GameState source) {
      current = source;
      return const ScenarioRuntimeExecutor().dispatch(
        scenarios: project.scenarios,
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'golden_item_lab',
          entityId: 'item_hidden_tonic',
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: source,
          onGameStateUpdated: (updated) => current = updated,
          openDialogue: (_, {startNode, runtimeSourceId}) => false,
          runScript: (_, {startNode, runtimeSourceId}) => false,
          showMessage: messages.add,
        ),
      );
    }

    final first = dispatch(state);
    _require(
      first.status == ScenarioRuntimeExecutionStatus.executedEffect &&
          messages.single == 'You found a Hidden Tonic!' &&
          _bagQuantities(current)['hidden-tonic'] == 1 &&
          current.storyFlags.activeFlags.contains(
            'golden_item.hidden_pickup_collected',
          ) &&
          current.progression.completedStepIds.contains(
            'golden_item.hidden_pickup',
          ),
      'Hidden pickup did not complete its authored flow.',
    );
    observations.add('hidden_pickup_interacted_with_message');
    final afterFirst = _stateDigest(current);
    final second = dispatch(current);
    _require(
      second.status == ScenarioRuntimeExecutionStatus.noMatchingSource &&
          _stateDigest(current) == afterFirst,
      'Hidden pickup is not idempotent.',
    );
    observations.add('hidden_pickup_idempotent');
    return current;
  }

  static GameState _useItem(
    PlayerItemUseService service,
    GameState state, {
    required String itemId,
    required int maxHp,
    int partyIndex = 0,
    String? moveId,
    Map<String, int> maxPpByMoveId = const <String, int>{},
  }) {
    final result = service.use(
      PlayerItemUseRequest(
        state: state,
        itemId: itemId,
        context: ProjectItemUseContext.overworld,
        partyIndex: partyIndex,
        maxHp: maxHp,
        moveId: moveId,
        maxPpByMoveId: maxPpByMoveId,
      ),
    );
    _require(result.isSuccess, '$itemId failed: ${result.failure?.name}.');
    return result.state;
  }

  static GameState _faintSecondPartyMember(GameState state, int rngSeed) {
    final request = _trainerRequest(rngSeed);
    final context = RuntimeActiveBattleContext.withLineupMapping(
      request: request,
      playerPartyIndex: 1,
      playerPartySlotIndicesByLineupIndex: const <int>[1],
    );
    var session = createBattleSession(
      _defeatBattleSetup(state.party.members[1]),
      rng: BattleSeededRng(state: rngSeed + 1),
    );
    for (var turn = 0; turn < 8 && session.state.outcome == null; turn++) {
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
    }
    final outcome = session.state.outcome;
    _require(outcome?.isDefeat ?? false, 'Defeat battle did not finish.');
    return applyRuntimeBattleOutcomeToGameState(
      gameState: state,
      context: context,
      outcome: outcome!,
    );
  }
}

final class _GoldenFileGameSaveRepository extends FileGameSaveRepository {
  _GoldenFileGameSaveRepository(this.saveRootDirectory);

  final String saveRootDirectory;

  @override
  Future<String> getSaveFilePath() async {
    await Directory(saveRootDirectory).create(recursive: true);
    return p.join(saveRootDirectory, 'game_save.json');
  }
}

Future<Map<String, dynamic>> _loadWalkthrough(String root) async {
  return jsonDecode(await File(p.join(root, 'walkthrough.json')).readAsString())
      as Map<String, dynamic>;
}

List<String> _walkthroughStepIds(Map<String, dynamic> walkthrough) {
  _require(
    walkthrough['schemaVersion'] == 1,
    'Unsupported walkthrough schema.',
  );
  final rawSteps = walkthrough['steps'];
  _require(rawSteps is List<dynamic>, 'Walkthrough steps are missing.');
  return rawSteps!
      .map<String>((raw) => _requiredString(raw as Map<String, dynamic>, 'id'))
      .toList(growable: false);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  _require(value is String && value.trim().isNotEmpty, 'Missing $key.');
  return (value as String).trim();
}

WildBattleStartRequest _wildRequest(int rngSeed) {
  return WildBattleStartRequest(
    requestId: 'golden-item-wild-$rngSeed',
    createdAtEpochMs: rngSeed,
    returnContext: const OverworldReturnContext(
      mapId: 'golden_item_lab',
      playerPos: GridPos(x: 1, y: 0),
      playerFacing: Direction.east,
    ),
    mapId: 'golden_item_lab',
    zoneId: 'golden_item_encounter_zone',
    tableId: 'golden_item_encounter',
    encounterKind: EncounterKind.walk,
    speciesId: 'sparkitten',
    level: 4,
    minLevel: 4,
    maxLevel: 4,
    weight: 1,
    playerPos: const GridPos(x: 1, y: 0),
  );
}

TrainerBattleStartRequest _trainerRequest(int rngSeed) {
  return TrainerBattleStartRequest(
    requestId: 'golden-item-defeat-$rngSeed',
    createdAtEpochMs: rngSeed + 1,
    returnContext: const OverworldReturnContext(
      mapId: 'golden_item_lab',
      playerPos: GridPos(x: 4, y: 2),
      playerFacing: Direction.west,
    ),
    trainerId: 'golden_item_trainer',
    npcEntityId: 'npc_item_trainer',
    mapId: 'golden_item_lab',
    playerPos: const GridPos(x: 4, y: 2),
  );
}

const _balancedStats = BattleStatsSnapshot(
  attack: 20,
  defense: 20,
  specialAttack: 20,
  specialDefense: 20,
  speed: 20,
);

const _playerBattleMove = BattleMoveData(
  id: 'tackle',
  name: 'Tackle',
  power: 100,
  type: 'normal',
  category: BattleMoveCategory.physical,
  target: BattleMoveTarget.opponent,
  pp: 35,
);

BattleSetup _wildBattleSetup(GameState state) {
  return BattleSetup.pokeMapBetaV1ForTest(
    playerPokemon: BattleCombatantData(
      speciesId: state.party.members.first.speciesId,
      level: state.party.members.first.level,
      maxHp: 20,
      currentHp: state.party.members.first.currentHp,
      stats: const BattleStatsSnapshot(
        attack: 20,
        defense: 20,
        specialAttack: 20,
        specialDefense: 20,
        speed: 40,
      ),
      abilityId: state.party.members.first.abilityId,
      moves: const <BattleMoveData>[_playerBattleMove],
    ),
    enemyPokemon: const BattleCombatantData(
      speciesId: 'sparkitten',
      level: 4,
      maxHp: 20,
      currentHp: 20,
      stats: _balancedStats,
      abilityId: 'blaze',
      catchRate: 255,
      moves: <BattleMoveData>[
        BattleMoveData(
          id: 'tackle',
          name: 'Tackle',
          power: 5,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
          pp: 35,
        ),
      ],
    ),
    isTrainerBattle: false,
    trainerId: null,
    allowCapture: true,
  );
}

BattleSetup _defeatBattleSetup(PlayerPokemon player) {
  return BattleSetup.pokeMapBetaV1ForTest(
    playerPokemon: BattleCombatantData(
      speciesId: player.speciesId,
      level: player.level,
      maxHp: 20,
      currentHp: player.currentHp,
      stats: const BattleStatsSnapshot(
        attack: 10,
        defense: 10,
        specialAttack: 10,
        specialDefense: 10,
        speed: 1,
      ),
      abilityId: player.abilityId,
      moves: const <BattleMoveData>[_playerBattleMove],
    ),
    enemyPokemon: const BattleCombatantData(
      speciesId: 'trainer-sparkitten',
      level: 50,
      maxHp: 100,
      stats: BattleStatsSnapshot(
        attack: 100,
        defense: 100,
        specialAttack: 100,
        specialDefense: 100,
        speed: 100,
      ),
      moves: <BattleMoveData>[
        BattleMoveData(
          id: 'heavy-tackle',
          name: 'Heavy Tackle',
          power: 100,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
          pp: 35,
        ),
      ],
    ),
    isTrainerBattle: true,
    trainerId: 'golden_item_trainer',
  );
}

Map<String, int> _bagQuantities(GameState state) {
  final entries = state.bag.normalized().entries.toList(growable: false)
    ..sort((left, right) => left.itemId.compareTo(right.itemId));
  return <String, int>{
    for (final entry in entries) entry.itemId: entry.quantity,
  };
}

bool _hasStrictBagWire(Map<String, dynamic> json) {
  final bag = json['bag'];
  if (bag is! Map<String, dynamic>) return false;
  final entries = bag['entries'];
  if (entries is! List<dynamic>) return false;
  return entries.every(
    (entry) =>
        entry is Map<String, dynamic> &&
        entry.keys.toSet().containsAll(const <String>{'itemId', 'quantity'}) &&
        entry.keys.length == 2,
  );
}

Future<String> _fixtureDigest(String root) async {
  final files = await Directory(root)
      .list(recursive: true, followLinks: false)
      .where((entity) => entity is File && p.extension(entity.path) == '.json')
      .cast<File>()
      .toList();
  files.sort((left, right) => left.path.compareTo(right.path));
  final bytes = BytesBuilder(copy: false);
  for (final file in files) {
    bytes
      ..add(utf8.encode(p.relative(file.path, from: root)))
      ..addByte(0)
      ..add(await file.readAsBytes())
      ..addByte(0);
  }
  return sha256.convert(bytes.takeBytes()).toString();
}

String _stateDigest(GameState state) {
  final canonical = _canonicalJson(strictGameStateSaveJson(state));
  return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
}

Object? _canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalJson(value[key]),
    };
  }
  if (value is List) return value.map(_canonicalJson).toList(growable: false);
  return value;
}

bool _sameStrings(List<String> left, List<String> right) =>
    jsonEncode(left) == jsonEncode(right);

bool _sameIntMap(Map<String, int> left, Map<String, int> right) =>
    jsonEncode(left) == jsonEncode(right);

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}
