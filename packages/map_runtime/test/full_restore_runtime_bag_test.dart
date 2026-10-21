import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flame/battle_bag_menu_model.dart';
import 'package:map_runtime/src/presentation/flame/battle_medicine_target_menu_model.dart';

const _use = ProjectItemUseDefinition(
  contexts: {ProjectItemUseContext.overworld, ProjectItemUseContext.battle},
  target: ProjectItemTargetKind.partyMember,
  consumption: ProjectItemConsumptionPolicy.onApplied,
  effect: ProjectItemEffectDefinition.fullRestore(),
);
final _catalog = ItemCatalogSnapshot.fromCatalog(
  const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'full-restore',
        displayName: 'Soin Total',
        pocketId: 'medicine',
        uses: [_use],
      ),
    ],
  ),
);
void main() {
  test('bag classifies full restore as medicine', () {
    expect(
      classifyBattleBagItem(
        itemId: 'full-restore',
        resolver: ItemCapabilityResolver(_catalog),
      ),
      BattleBagItemKind.medicine,
    );
  });
  for (final hp in [20, 100]) {
    test(
      'runtime bag restores $hp HP with confusion, one receipt and one turn',
      () {
        final adapter = _adapter(hp: hp, confused: true);
        final initial = _state(hp);
        final result = tryApplyRuntimePsdkBattleItemUse(
          psdkSession: adapter,
          displaySession: adapter.createLegacyDisplaySession(
            isTrainerBattle: true,
          ),
          gameState: initial,
          context: _context(),
          itemId: 'full-restore',
          targetLineupIndex: 0,
          isTrainerBattle: true,
          itemCatalog: _catalog,
        );
        expect(result, isNotNull);
        expect(result!.effectKind.name, 'fullRestore');
        expect(result.updatedGameState.party.members.single.currentHp, 100);
        expect(result.updatedGameState.party.members.single.currentPpByMoveId, {
          'wait': 3,
        });
        expect(result.updatedGameState.bag.entries.single.quantity, 1);
        expect(result.consumptionReceipt!.quantity, 1);
        expect(adapter.state.turnNumber, 1);
        expect(
          adapter.state.battlerAt(psdkPlayerSlot).effects.contains('confusion'),
          isFalse,
        );
        expect(initial.bag.entries.single.quantity, 2);
        expect(initial.party.members.single.currentHp, hp);
      },
    );
  }
  test(
    'no-effect bag request leaves engine, party and inventory unchanged',
    () {
      final adapter = _adapter();
      final initial = _state(100);
      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: adapter,
        displaySession: adapter.createLegacyDisplaySession(
          isTrainerBattle: true,
        ),
        gameState: initial,
        context: _context(),
        itemId: 'full-restore',
        targetLineupIndex: 0,
        isTrainerBattle: true,
        itemCatalog: _catalog,
      );
      expect(result, isNull);
      expect(adapter.state.turnNumber, 0);
      expect(initial.bag.entries.single.quantity, 2);
    },
  );
  test('medicine menu enables a damaged target for full restore', () {
    final adapter = _adapter(hp: 20);
    final menu = buildBattleMedicineTargetMenuModel(
      session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
      itemId: 'full-restore',
      displayName: 'Soin Total',
      use: _use,
    );
    expect(menu.activeEntry.isSelectable, isTrue);
  });
  test(
    'medicine menu reads full-HP confusion from the actual battle state',
    () {
      final adapter = _adapter(confused: true);
      final menu = buildBattleMedicineTargetMenuModel(
        session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        itemId: 'full-restore',
        displayName: 'Soin Total',
        use: _use,
        isConfusedByLineupIndex: adapter.isPlayerLineupConfused,
      );
      expect(menu.activeEntry.isSelectable, isTrue);
      expect(adapter.isPlayerLineupConfused(-1), isFalse);
      expect(adapter.isPlayerLineupConfused(1), isFalse);
    },
  );
}

RuntimePsdkBattleSessionAdapter _adapter({
  int hp = 100,
  bool confused = false,
}) => RuntimePsdkBattleSessionAdapter.fromSetup(
  PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _battler('player', hp, confused: confused),
    opponent: _battler('opponent', 100),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  ),
);
PsdkBattleCombatantSetup _battler(String id, int hp, {bool confused = false}) =>
    PsdkBattleCombatantSetup(
      id: id,
      speciesId: 'eevee',
      displayName: id,
      level: 20,
      maxHp: 100,
      currentHp: hp,
      types: const PsdkBattleTypes(primary: 'normal'),
      stats: const PsdkBattleStats(
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 50,
      ),
      effects: PsdkBattleEffectStack(
        effects: [
          if (confused)
            const ConfusionEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
            ),
        ],
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
          pp: 35,
          currentPp: 3,
          priority: 0,
          battleEngineMethod: 's_basic',
          target: PsdkBattleMoveTarget.user,
        ),
      ],
    );
GameState _state(int hp) => GameState(
  saveId: 'full-restore-runtime',
  bag: const Bag(entries: [BagEntry(itemId: 'full-restore', quantity: 2)]),
  party: PlayerParty(
    members: [
      PlayerPokemon(
        speciesId: 'eevee',
        natureId: 'hardy',
        abilityId: 'run_away',
        level: 20,
        knownMoveIds: ['wait'],
        currentPpByMoveId: {'wait': 3},
        currentHp: hp,
      ),
    ],
  ),
);
RuntimeActiveBattleContext _context() =>
    RuntimeActiveBattleContext.withLineupMapping(
      request: const TrainerBattleStartRequest(
        requestId: 'restore',
        createdAtEpochMs: 1,
        returnContext: OverworldReturnContext(
          mapId: 'field',
          playerPos: GridPos(x: 1, y: 1),
          playerFacing: Direction.north,
        ),
        trainerId: 'trainer',
        npcEntityId: 'npc',
        mapId: 'field',
        playerPos: GridPos(x: 1, y: 1),
      ),
      playerPartyIndex: 0,
      playerPartySlotIndicesByLineupIndex: [0],
    );
