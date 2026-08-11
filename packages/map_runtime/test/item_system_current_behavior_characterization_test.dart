import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/presentation/flame/battle_bag_menu_model.dart';

void main() {
  group('current runtime item classification', () {
    test('capture and medicine support depend on exact legacy categories', () {
      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          entries: const <BagEntry>[
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'items',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'synthetic-balls',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'potion',
              categoryId: 'medicine',
              quantity: 2,
            ),
            BagEntry(
              itemId: 'potion',
              categoryId: 'synthetic-heals',
              quantity: 2,
            ),
          ],
        ),
        session: _battleSession(allowCapture: true),
      );

      final canonicalBall = _entry(
        model,
        itemId: 'poke-ball',
        categoryId: 'items',
      );
      final customBall = _entry(
        model,
        itemId: 'poke-ball',
        categoryId: 'synthetic-balls',
      );
      final canonicalMedicine = _entry(
        model,
        itemId: 'potion',
        categoryId: 'medicine',
      );
      final customMedicine = _entry(
        model,
        itemId: 'potion',
        categoryId: 'synthetic-heals',
      );

      expect(canonicalBall.kind, BattleBagItemKind.captureBall);
      expect(canonicalBall.isSelectable, isTrue);
      expect(customBall.kind, BattleBagItemKind.unsupported);
      expect(customBall.disabledReason,
          BattleBagMenuDisabledReason.unsupportedItem);
      expect(canonicalMedicine.kind, BattleBagItemKind.medicine);
      expect(canonicalMedicine.isSelectable, isTrue);
      expect(customMedicine.kind, BattleBagItemKind.unsupported);
      expect(
        customMedicine.disabledReason,
        BattleBagMenuDisabledReason.unsupportedItem,
      );
    });
  });

  group('current legacy battle HP item behavior', () {
    const cases = <_RuntimeHealCase>[
      _RuntimeHealCase(
        itemId: 'potion',
        expectedHealedAmount: 20,
        expectedHp: 30,
      ),
      _RuntimeHealCase(
        itemId: 'super-potion',
        expectedHealedAmount: 50,
        expectedHp: 60,
      ),
      _RuntimeHealCase(
        itemId: 'hyper-potion',
        expectedHealedAmount: 200,
        expectedHp: 210,
      ),
      _RuntimeHealCase(
        itemId: 'max-potion',
        expectedHealedAmount: 490,
        expectedHp: 500,
      ),
    ];

    for (final itemCase in cases) {
      test('${itemCase.itemId} preserves its runtime delta and consumption',
          () {
        final result = _applyLegacyHeal(itemCase.itemId);

        expect(result, isNotNull);
        expect(result!.healedAmount, itemCase.expectedHealedAmount);
        expect(
            result.updatedSession.state.player.currentHp, itemCase.expectedHp);
        expect(
          result.updatedGameState.party.members.single.currentHp,
          itemCase.expectedHp,
        );
        expect(result.updatedGameState.bag.entries.single.quantity, 1);
      });
    }
  });
}

BattleBagMenuEntry _entry(
  BattleBagMenuModel model, {
  required String itemId,
  required String categoryId,
}) {
  return model.entries.singleWhere(
    (entry) => entry.itemId == itemId && entry.categoryId == categoryId,
  );
}

RuntimeBattleBagHpHealItemApplyResult? _applyLegacyHeal(String itemId) {
  final session = _battleSession(currentHp: 10, maxHp: 500);
  final state = _gameState(
    entries: <BagEntry>[
      BagEntry(itemId: itemId, categoryId: 'medicine', quantity: 2),
    ],
    currentHp: 10,
  );
  final context = RuntimeActiveBattleContext.withLineupMapping(
    request: const TrainerBattleStartRequest(
      requestId: 'itm-001-trainer-request',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'itm-001-map',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.north,
      ),
      trainerId: 'itm-001-trainer',
      npcEntityId: 'itm-001-npc',
      mapId: 'itm-001-map',
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: const <int>[0],
  );

  return switch (itemId) {
    'potion' => tryApplyRuntimeBattlePotionUse(
        session: session,
        gameState: state,
        context: context,
        targetLineupIndex: 0,
      ),
    'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
        session: session,
        gameState: state,
        context: context,
        targetLineupIndex: 0,
      ),
    'hyper-potion' => tryApplyRuntimeBattleHyperPotionUse(
        session: session,
        gameState: state,
        context: context,
        targetLineupIndex: 0,
      ),
    'max-potion' => tryApplyRuntimeBattleMaxPotionUse(
        session: session,
        gameState: state,
        context: context,
        targetLineupIndex: 0,
      ),
    _ => throw ArgumentError.value(itemId, 'itemId'),
  };
}

BattleSession _battleSession({
  int currentHp = 40,
  int maxHp = 40,
  bool allowCapture = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: _combatant(
        speciesId: 'itm-001-player-species',
        lineupIndex: 0,
        currentHp: currentHp,
        maxHp: maxHp,
      ),
      enemyPokemon: _combatant(
        speciesId: 'itm-001-opponent-species',
        lineupIndex: 0,
        catchRate: allowCapture ? 45 : null,
      ),
      allowCapture: allowCapture,
      isTrainerBattle: !allowCapture,
      trainerId: allowCapture ? null : 'itm-001-trainer',
    ),
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int currentHp = 40,
  int maxHp = 40,
  int? catchRate,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 20,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: const BattleStatsSnapshot(
      attack: 60,
      defense: 60,
      specialAttack: 60,
      specialDefense: 60,
      speed: 60,
    ),
    catchRate: catchRate,
    moves: <BattleMoveData>[
      BattleMoveData(
        id: '$speciesId-wait',
        name: 'Wait',
        power: 0,
        type: 'normal',
        category: BattleMoveCategory.status,
        target: BattleMoveTarget.self,
      ),
    ],
  );
}

GameState _gameState({
  required List<BagEntry> entries,
  int currentHp = 40,
}) {
  return GameState(
    saveId: 'itm-001-runtime-characterization-save',
    bag: Bag(entries: entries),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'itm-001-player-species',
          level: 20,
          natureId: 'hardy',
          abilityId: 'pressure',
          knownMoveIds: const <String>['wait'],
          currentHp: currentHp,
        ),
      ],
    ),
  );
}

final class _RuntimeHealCase {
  const _RuntimeHealCase({
    required this.itemId,
    required this.expectedHealedAmount,
    required this.expectedHp,
  });

  final String itemId;
  final int expectedHealedAmount;
  final int expectedHp;
}
