import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

final _catalog = ItemCatalogSnapshot.fromCatalog(
  const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(id: 'powder', displayName: 'Powder', pocketId: 'medicine', uses: [
        ProjectItemUseDefinition(contexts: {ProjectItemUseContext.battle}, target: ProjectItemTargetKind.partyMember,
          consumption: ProjectItemConsumptionPolicy.onApplied,
          friendshipLoss: ProjectItemFriendshipLoss(low: 5, medium: 5, high: 10),
          effect: ProjectItemEffectDefinition.healHp(mode: ProjectItemAmountMode.flat, amount: 50)),
      ]),
      ProjectItemDefinition(id: 'elixir', displayName: 'Élixir', pocketId: 'medicine', uses: [
        ProjectItemUseDefinition(contexts: {ProjectItemUseContext.battle}, target: ProjectItemTargetKind.partyMember,
          consumption: ProjectItemConsumptionPolicy.onApplied,
          effect: ProjectItemEffectDefinition.restorePp(mode: ProjectItemAmountMode.flat, amount: 10,
            scope: ProjectItemPpScope.allMoves)),
      ]),
      ProjectItemDefinition(
        id: 'potion',
        displayName: 'Potion',
        pocketId: 'medicine',
        uses: [
          ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 20,
            ),
          ),
        ],
      ),
      ProjectItemDefinition(
        id: 'ether',
        displayName: 'Ether',
        pocketId: 'medicine',
        uses: [
          ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMove,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.restorePp(
              mode: ProjectItemAmountMode.flat,
              amount: 3,
            ),
          ),
        ],
      ),
    ],
  ),
);

void main() {
  test('bitter double items charge friendship only after resolution and only once per applied item', () {
    final fixture = _fixture(2, itemId: 'powder', initialHp: 50);
    final initial = fixture.state.copyWith(party: fixture.state.party.copyWith(members: [
      for (final member in fixture.state.party.members) member.copyWith(friendship: 200),
    ]));
    final first = _apply(fixture.session, initial, 0, itemId: 'powder')!;
    expect(first.updatedGameState, initial);
    final second = _apply(fixture.session, first.updatedGameState, 0, itemId: 'powder')!;
    expect(second.updatedGameState.party.members.map((p) => p.friendship), [190, 200]);
    expect(second.updatedGameState.bag.entries.single.quantity, 1);
    final replay = commitRuntimeResolvedBattleItems(session: fixture.session, gameState: second.updatedGameState, itemCatalog: _catalog, context: _context);
    expect(replay.state, second.updatedGameState);
    expect(replay.receipts, isEmpty);
  });
  test('bitter medicine follows individual identity after party reordering', () {
    final fixture = _fixture(2, itemId: 'powder', initialHp: 50);
    final initial = fixture.state.copyWith(party: fixture.state.party.copyWith(members: [
      for (final member in fixture.state.party.members.reversed) member.copyWith(friendship: 200),
    ]));
    final context = RuntimeActiveBattleContext.withLineupMapping(request: _context.request, playerPartyIndex: 0, playerIndividualId: 'l32-item-0',
      playerPartySlotIndicesByLineupIndex: [0, 1], playerIndividualIdsByLineupIndex: ['l32-item-0', 'l32-item-1']);
    final first = _apply(fixture.session, initial, 0, itemId: 'powder', context: context)!;
    expect(first.updatedGameState, initial);
    final second = _apply(fixture.session, first.updatedGameState, 0, itemId: 'powder', context: context)!;
    expect(second.updatedGameState.party.members.map((p) => p.friendship), [200, 190]);
    expect(second.updatedGameState.party.members.map((p) => p.currentHp), [50, 100]);
    expect(second.updatedGameState.bag.entries.single.quantity, 1);
  });
  test('all-PP double item releases the second reservation when the first fills every move', () {
    final fixture = _fixture(2, itemId: 'elixir', initialPp: 0);
    final first = _apply(fixture.session, fixture.state, 0, itemId: 'elixir')!;
    expect(first.updatedGameState.bag.entries.single.quantity, 2);
    final second = _apply(fixture.session, first.updatedGameState, 0, itemId: 'elixir')!;
    expect(second.updatedGameState.bag.entries.single.quantity, 1);
    expect(fixture.session.state.partyForBank(0)[0].moves.single.currentPp, 10);
    expect(second.updatedGameState.party.members[0].currentPpByMoveId!['wait'], 10);
    expect(second.consumptionReceipt, isNull);
    expect(fixture.session.pendingItemQuantities, isEmpty);
  });
  test(
    'L32 reserves the only item during collection without charging the save',
    () {
      final fixture = _fixture(1);
      final before = fixture.session.state;
      final first = _apply(fixture.session, fixture.state, 0)!;

      expect(first.updatedGameState.toJson(), fixture.state.toJson());
      expect(fixture.session.state.turnNumber, before.turnNumber);
      expect(
        [
          fixture.session.state.rngSeeds.moveDamage,
          fixture.session.state.rngSeeds.moveCritical,
          fixture.session.state.rngSeeds.moveAccuracy,
          fixture.session.state.rngSeeds.generic,
        ],
        [
          before.rngSeeds.moveDamage,
          before.rngSeeds.moveCritical,
          before.rngSeeds.moveAccuracy,
          before.rngSeeds.generic,
        ],
      );
      expect(fixture.session.state.battlerAt(psdkPlayerSlot).currentHp, 20);
      final request = fixture.session.decisionRequest;
      expect(request.actor, const PsdkBattleSlotRef(bank: 0, position: 1));
      expect(_apply(fixture.session, first.updatedGameState, 1), isNull);
      expect(identical(fixture.session.decisionRequest, request), isTrue);
      expect(
        const BagOperations().quantityOf(first.updatedGameState.bag, 'potion'),
        1,
      );
    },
  );

  test(
    'L32 commits two available items exactly once when the turn resolves',
    () {
      final fixture = _fixture(2);
      final first = _apply(fixture.session, fixture.state, 0)!;
      final second = _apply(fixture.session, first.updatedGameState, 1)!;

      expect(
        const BagOperations().quantityOf(second.updatedGameState.bag, 'potion'),
        0,
      );
      expect(fixture.session.state.battlerAt(psdkPlayerSlot).currentHp, 40);
      expect(
        fixture.session.state
            .battlerAt(const PsdkBattleSlotRef(bank: 0, position: 1))
            .currentHp,
        40,
      );
      expect(
        second.updatedGameState.party.members.map((member) => member.currentHp),
        [40, 40],
      );
      expect(second.consumptionReceipt?.quantity, 1);
    },
  );

  test(
    'L32 resolves an item followed by a move and acknowledges its debit once',
    () {
      final fixture = _fixture(1);
      final first = _apply(fixture.session, fixture.state, 0)!;
      fixture.session.submitDecision(
        const BattleDecision.fight(moveSlot: 0),
        request: fixture.session.decisionRequest,
      );
      final committed = commitRuntimeResolvedBattleItems(
        session: fixture.session,
        gameState: first.updatedGameState,
        itemCatalog: _catalog,
      );
      expect(
        const BagOperations().quantityOf(committed.state.bag, 'potion'),
        0,
      );
      expect(committed.receipts, hasLength(1));
      final replay = commitRuntimeResolvedBattleItems(
        session: fixture.session,
        gameState: committed.state,
        itemCatalog: _catalog,
      );
      expect(replay.state.toJson(), committed.state.toJson());
      expect(replay.receipts, isEmpty);
    },
  );

  test('L32 releases an onApplied reservation when the second effect becomes useless', () {
    final fixture = _fixture(2, initialHp: 90);
    final first = _apply(fixture.session, fixture.state, 0)!;
    final second = _apply(fixture.session, first.updatedGameState, 0)!;
    expect(
      const BagOperations().quantityOf(second.updatedGameState.bag, 'potion'),
      1,
    );
    expect(fixture.session.pendingItemQuantities, isEmpty);
    expect(fixture.session.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    expect(second.consumptionReceipt, isNull);
  });

  test(
    'L32 two Ether users on one move keep separate receipts and PP events',
    () {
      final fixture = _fixture(2, itemId: 'ether', initialPp: 0);
      final first = _apply(fixture.session, fixture.state, 0, itemId: 'ether')!;
      final second = _apply(
        fixture.session,
        first.updatedGameState,
        0,
        itemId: 'ether',
      )!;
      expect(second.appliedAmount, 3);
      expect(second.consumptionReceipt?.quantity, 1);
      expect(
        const BagOperations().quantityOf(second.updatedGameState.bag, 'ether'),
        0,
      );
      expect(
        fixture.session.state.partyForBank(0)[0].moves.single.currentPp,
        6,
      );
      expect(
        second.updatedGameState.party.members[0].currentPpByMoveId?['wait'],
        6,
      );
    },
  );

  test('L32 rejected second request keeps the accepted first reservation', () {
    final fixture = _fixture(1);
    final firstRequest = fixture.session.decisionRequest;
    final first = _apply(fixture.session, fixture.state, 0)!;
    final secondRequest = fixture.session.decisionRequest;

    expect(
      () => fixture.session.submitDecision(
        const BattleDecision.fight(moveSlot: 0),
        request: firstRequest,
      ),
      throwsA(isA<BattleDecisionRejectedError>()),
    );
    expect(identical(fixture.session.decisionRequest, secondRequest), isTrue);
    expect(
      _apply(fixture.session, first.updatedGameState, 1, request: firstRequest),
      isNull,
    );
    expect(identical(fixture.session.decisionRequest, secondRequest), isTrue);
    expect(_apply(fixture.session, first.updatedGameState, 1), isNull);
    expect(first.updatedGameState.toJson(), fixture.state.toJson());
  });
}

RuntimePsdkBattleItemApplyResult? _apply(
  RuntimePsdkBattleSessionAdapter session,
  GameState state,
  int target, {
  String itemId = 'potion',
  BattleEngineDecisionRequest? request,
  RuntimeActiveBattleContext? context,
}) => tryApplyRuntimePsdkBattleItemUse(
  psdkSession: session,
  displaySession: session.createLegacyDisplaySession(isTrainerBattle: true),
  gameState: state,
  context: context ?? _context,
  itemId: itemId,
  targetLineupIndex: target,
  targetMoveIndex: itemId == 'ether' ? 0 : null,
  isTrainerBattle: true,
  itemCatalog: _catalog,
  request: request ?? session.decisionRequest,
);

({RuntimePsdkBattleSessionAdapter session, GameState state}) _fixture(
  int quantity, {
  int initialHp = 20,
  String itemId = 'potion',
  int initialPp = 10,
}) {
  PsdkBattleCombatantSetup combatant(String id) => PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: initialHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: [
      PsdkBattleMoveData(
        id: 'wait',
        dbSymbol: 'wait',
        name: 'Wait',
        type: 'normal',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 100,
        pp: 10,
        currentPp: id.startsWith('player') ? initialPp : 10,
        priority: 0,
        battleEngineMethod: 's_status',
        target: PsdkBattleMoveTarget.self,
      ),
    ],
  );
  return (
    session: RuntimePsdkBattleSessionAdapter.fromSetup(
      PsdkBattleSetup.doubles(
        ruleset: PokemonRulesetProfile.standardV1,
        player: [combatant('player_0'), combatant('player_1')],
        opponent: [combatant('opponent_0'), combatant('opponent_1')],
        rngSeeds: const PsdkBattleRngSeeds(
          moveDamage: 1,
          moveCritical: 2,
          moveAccuracy: 3,
          generic: 4,
        ),
      ),
    ),
    state: GameState(
      saveId: 'l32-items',
      bag: Bag(
        entries: [BagEntry(itemId: itemId, quantity: quantity)],
      ),
      party: PlayerParty(
        members: [
          for (var index = 0; index < 2; index++)
            PlayerPokemon(
              individualId: 'l32-item-$index',
              speciesId: 'player_$index',
              natureId: 'hardy',
              abilityId: 'unknown',
              level: 20,
              currentHp: initialHp,
              knownMoveIds: const ['wait'],
              currentPpByMoveId: {'wait': initialPp},
            ),
        ],
      ),
    ),
  );
}

final _context = RuntimeActiveBattleContext.withLineupMapping(
  request: const TrainerBattleStartRequest(
    requestId: 'l32-item-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: 'trainer',
    npcEntityId: 'npc',
    mapId: 'field',
    playerPos: GridPos(x: 1, y: 1),
  ),
  playerPartyIndex: 0,
  playerPartySlotIndicesByLineupIndex: const [0, 1],
  playerIndividualId: 'l32-item-0',
  playerIndividualIdsByLineupIndex: const ['l32-item-0', 'l32-item-1'],
);
