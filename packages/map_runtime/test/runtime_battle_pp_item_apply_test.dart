import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';

import 'support/load_flame_component.dart';

final _catalog = ItemCatalogSnapshot.fromCatalog(
  ProjectItemCatalog(
    schemaVersion: 1,
    entries: const [
      ProjectItemDefinition(
        id: 'custom-full-pp',
        displayName: 'Full PP Tonic',
        pocketId: 'medicine',
        uses: [
          ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMove,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.restorePp(
              mode: ProjectItemAmountMode.full,
            ),
          ),
        ],
      ),
      ProjectItemDefinition(
        id: 'custom-pp',
        displayName: 'PP Tonic',
        pocketId: 'medicine',
        uses: [
          ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMove,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.restorePp(
              mode: ProjectItemAmountMode.flat,
              amount: 10,
            ),
          ),
        ],
      ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'PP target flow shows real move slots and cancels without using a turn',
    () async {
      final session = _session([_move('wait', 35), _move('wait', 0)]);
      final before = session.state.psdkState;
      var submitted = 0;
      final overlay = BattleOverlayComponent(
        session: session.createLegacyDisplaySession(isTrainerBattle: true),
        gameState: const GameState(
          saveId: 'ui',
          bag: Bag(entries: [BagEntry(itemId: 'custom-pp', quantity: 1)]),
        ),
        itemCapabilityResolver: ItemCapabilityResolver(_catalog),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) => submitted++,
      );
      await loadFlameComponent(overlay);
      expect(overlay.selectRootEntry(1), isTrue);
      expect(overlay.selectBagEntry(0), isTrue);
      expect(overlay.selectMedicineTargetEntry(0), isTrue);
      expect(overlay.currentMenuMode.name, 'bagMedicineMoveTarget');
      final entries = overlay.currentCommandOverlaySnapshot!.entries;
      expect(entries.map((entry) => entry.trailingLabel), [
        'PP 35/35',
        'PP 0/35',
      ]);
      expect(entries.map((entry) => entry.enabled), [false, true]);
      expect(overlay.validateSelectedChoice(), isFalse);
      expect(overlay.handleEscape(), isTrue);
      expect(overlay.currentMenuMode.name, 'bagMedicineTarget');
      expect(overlay.handleEscape(), isTrue);
      expect(overlay.currentMenuMode.name, 'bag');
      expect(overlay.handleEscape(), isTrue);
      expect(overlay.currentMenuMode.name, 'root');
      expect(submitted, 0);
      expect(session.state.psdkState, same(before));
    },
  );

  test('restores the selected battle slot and consumes exactly once', () {
    final session = _session([_move('wait', 34), _move('guard', 2)]);
    final result = _apply(session, moveIndex: 0);
    expect(result, isNotNull);
    expect(result!.appliedAmount, 1);
    expect(result.updatedGameState.bag.entries, isEmpty);
    expect(result.consumptionReceipt!.quantity, 1);
    expect(
      session.state.psdkState.battlerAt(psdkPlayerSlot).moves[0].currentPp,
      35,
    );
    expect(
      result.updatedGameState.party.members.single.currentPpByMoveId!['wait'],
      35,
    );
    expect(
      result.updatedGameState.party.members.single.currentPpByMoveId!['guard'],
      2,
    );
    expect(
      buildBattleTurnLinesForOverlay(
        result.updatedDisplaySession.state.currentTurn!,
      ),
      contains('Wait récupère 1 PP'),
    );
    final catalog = RuntimeMoveCatalog.fromEntries(
      const <String, PokemonMove>{},
    );
    final plan = BattleTurnAnimationPlanner().build(
      previousSession: _session([_move('wait', 34), _move('guard', 2)])
          .createLegacyDisplaySession(isTrainerBattle: true),
      newSession: result.updatedDisplaySession,
      moveCatalog: catalog,
      resolver: BattleMoveVisualResolver(catalog),
    );
    expect(plan.steps.whereType<HudHpTweenStep>(), isEmpty);
    expect(
      plan.steps.whereType<ShowMessageStep>().map((step) => step.message),
      contains('Wait récupère 1 PP.'),
    );
  });

  test('full restoration clamps to the move maximum', () {
    final session = _session([_move('wait', 2)]);
    final result = _apply(session, moveIndex: 0, itemId: 'custom-full-pp');
    expect(result, isNotNull);
    expect(result!.appliedAmount, 33);
    expect(
      result.updatedGameState.party.members.single.currentPpByMoveId!['wait'],
      35,
    );
  });

  test('Transform restores temporary battle PP and preserves the original save moves', () {
    final session = _session([_move('transform', 35, method: 's_transform')]);
    session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
    session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
    final target = session.state.psdkState.battlerAt(psdkPlayerSlot);
    expect(target.transformState.isTransformed, isTrue);
    final originalPp = target.writeBackMoves.single.currentPp;
    final result = _apply(
      session,
      moveIndex: 0,
      knownMoveIds: const ['transform'],
    );
    expect(result, isNotNull);
    final saved = result!.updatedGameState.party.members.single;
    expect(saved.knownMoveIds, ['transform']);
    expect(saved.currentPpByMoveId!['transform'], originalPp);
    expect(saved.currentPpByMoveId!.containsKey('wait'), isFalse);
    expect(
      session.state.psdkState.battlerAt(psdkPlayerSlot).moves.single.currentPp,
      5,
    );
  });

  test(
    'PP move targeting excludes synthetic Struggle and sends the numeric slot',
    () async {
      final session = _session([_move('wait', 0), _move('wait', 0)]);
      int? selected;
      final overlay = BattleOverlayComponent(
        session: session.createLegacyDisplaySession(isTrainerBattle: true),
        medicineBattleState: session.createLegacyWriteBackState,
        gameState: const GameState(
          saveId: 'ui',
          bag: Bag(entries: [BagEntry(itemId: 'custom-pp', quantity: 1)]),
        ),
        itemCapabilityResolver: ItemCapabilityResolver(_catalog),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) => fail('PP selection must not choose an attack'),
        onBagMovePpItemUseRequested: (_, _, slot) {
          selected = slot;
          return true;
        },
      );
      await loadFlameComponent(overlay);
      overlay.selectRootEntry(1);
      overlay.selectBagEntry(0);
      overlay.selectMedicineTargetEntry(0);
      expect(overlay.currentCommandOverlaySnapshot!.entries, hasLength(2));
      expect(overlay.selectMedicineMoveTargetEntry(1), isTrue);
      expect(selected, 1);
    },
  );

  test('Mimic duplicate slots restore independently and keep original persistent PP', () {
    final session = _session([
      _move('wait', 35),
      _move('mimic', 35, method: 's_mimic'),
    ]);
    session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
    session.submitPlayerChoice(const PlayerBattleChoiceFight(1));
    session.submitPlayerChoice(const PlayerBattleChoiceFight(1));
    final before = session.state.psdkState.battlerAt(psdkPlayerSlot);
    expect(before.moves.map((move) => move.id), ['wait', 'wait']);
    expect(before.moves.map((move) => move.currentPp), [34, 4]);
    final result = _apply(
      session,
      moveIndex: 1,
      knownMoveIds: const ['wait', 'mimic'],
    );
    expect(result, isNotNull);
    expect(result!.appliedAmount, 1);
    final saved = result.updatedGameState.party.members.single;
    expect(saved.knownMoveIds, ['wait', 'mimic']);
    expect(saved.currentPpByMoveId, {'wait': 34, 'mimic': 34});
    expect(
      session.state.psdkState
          .battlerAt(psdkPlayerSlot)
          .moves
          .map((move) => move.currentPp),
      [34, 5],
    );
  });

  test(
    'rejects missing, negative, oversized and full move slots atomically',
    () {
      for (final index in <int?>[null, -1, 2, 0]) {
        final session = _session([_move('wait', 35), _move('guard', 2)]);
        final before = session.state.psdkState;
        expect(_apply(session, moveIndex: index), isNull);
        expect(session.state.psdkState, same(before));
      }
    },
  );

  test(
    'restores numeric duplicate move slots without persisting temporary ids',
    () {
      final session = _session([_move('wait', 35), _move('wait', 0)]);
      final result = _apply(session, moveIndex: 1);
      expect(result, isNotNull);
      expect(
        session.state.psdkState.battlerAt(psdkPlayerSlot).moves[0].currentPp,
        35,
      );
      expect(
        session.state.psdkState.battlerAt(psdkPlayerSlot).moves[1].currentPp,
        10,
      );
      expect(result!.appliedAmount, 10);
    },
  );

  test('restores a fainted reserve without reviving it', () {
    final session = _session([_move('wait', 35)], reserveHp: 0);
    final result = _apply(session, moveIndex: 0, lineupIndex: 1);
    expect(result, isNotNull);
    expect(result!.updatedGameState.party.members[1].currentHp, 0);
    expect(
      result.updatedGameState.party.members[1].currentPpByMoveId!['wait'],
      10,
    );
  });

  test('an empty bag rejects before the engine advances', () {
    final session = _session([_move('wait', 0)]);
    final before = session.state.psdkState;
    expect(_apply(session, moveIndex: 0, quantity: 0), isNull);
    expect(session.state.psdkState, same(before));
  });
}

RuntimePsdkBattleItemApplyResult? _apply(
  RuntimePsdkBattleSessionAdapter session, {
  int? moveIndex,
  int lineupIndex = 0,
  int quantity = 1,
  String itemId = 'custom-pp',
  List<String> knownMoveIds = const ['wait', 'guard'],
}) {
  final partySize = session.state.psdkState
      .partyForBank(psdkPlayerSlot.bank)
      .length;
  return tryApplyRuntimePsdkBattleItemUse(
    psdkSession: session,
    displaySession: session.createLegacyDisplaySession(isTrainerBattle: true),
    gameState: GameState(
      saveId: 'pp',
      bag: Bag(
        entries: [
          if (quantity > 0) BagEntry(itemId: itemId, quantity: quantity),
        ],
      ),
      party: PlayerParty(
        members: [
          for (var index = 0; index < partySize; index++)
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 20,
              knownMoveIds: knownMoveIds,
              currentPpByMoveId: {for (final id in knownMoveIds) id: 1},
              currentHp: index == 1 ? 0 : 80,
            ),
        ],
      ),
    ),
    context: RuntimeActiveBattleContext.withLineupMapping(
      request: const TrainerBattleStartRequest(
        requestId: 'pp',
        createdAtEpochMs: 1,
        returnContext: OverworldReturnContext(
          mapId: 'map',
          playerPos: GridPos(x: 0, y: 0),
          playerFacing: Direction.south,
        ),
        trainerId: 'trainer',
        npcEntityId: 'npc',
        mapId: 'map',
        playerPos: GridPos(x: 0, y: 0),
      ),
      playerPartyIndex: 0,
      playerPartySlotIndicesByLineupIndex: List.generate(
        partySize,
        (index) => index,
      ),
    ),
    itemId: itemId,
    targetLineupIndex: lineupIndex,
    targetMoveIndex: moveIndex,
    isTrainerBattle: true,
    itemCatalog: _catalog,
  );
}

RuntimePsdkBattleSessionAdapter _session(
  List<PsdkBattleMoveData> moves, {
  int? reserveHp,
}) {
  PsdkBattleCombatantSetup combatant(
    String id,
    List<PsdkBattleMoveData> moves,
    int hp,
  ) => PsdkBattleCombatantSetup(
    id: id,
    speciesId: 'sproutle',
    displayName: 'Sproutle',
    level: 20,
    maxHp: 80,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves,
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: combatant('player_0', moves, 80),
      playerReserves: [
        if (reserveHp != null)
          combatant('player_1', [_move('wait', 0)], reserveHp),
      ],
      opponent: combatant('opponent_0', [_move('wait', 35)], 80),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 17,
        moveCritical: 23,
        moveAccuracy: 31,
        generic: 47,
      ),
    ),
  );
}

PsdkBattleMoveData _move(String id, int pp, {String method = 's_basic'}) =>
    PsdkBattleMoveData(
      id: id,
      dbSymbol: id,
      name: id == 'wait' ? 'Wait' : 'Guard',
      type: 'normal',
      category: PsdkBattleMoveCategory.status,
      power: 0,
      accuracy: 100,
      pp: 35,
      currentPp: pp,
      priority: 0,
      battleEngineMethod: method,
      target: method == 's_transform' || method == 's_mimic'
          ? PsdkBattleMoveTarget.adjacentFoe
          : PsdkBattleMoveTarget.user,
    );
