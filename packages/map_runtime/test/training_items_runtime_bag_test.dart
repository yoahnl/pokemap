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

void main() {
  test('Contrary refusal at the lower cap keeps inventory and turn intact', () {
    final adapter=_adapter(abilityId:'contrary');
    var state=_state(100).copyWith(bag:const Bag(entries:[BagEntry(itemId:'full-restore',quantity:8)]));
    final catalog=ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(schemaVersion:1,entries:[ProjectItemDefinition(id:'full-restore',displayName:'Attaque +',pocketId:'battle',uses:[ProjectItemUseDefinition(contexts:{ProjectItemUseContext.battle},target:ProjectItemTargetKind.partyMember,consumption:ProjectItemConsumptionPolicy.onApplied,effect:ProjectItemEffectDefinition.battleBoost(stat:ProjectItemBattleStat.attack,stages:1))]) ]));
    RuntimePsdkBattleItemApplyResult? invoke()=>tryApplyRuntimePsdkBattleItemUse(psdkSession:adapter,displaySession:adapter.createLegacyDisplaySession(isTrainerBattle:true),gameState:state,context:_context(),itemId:'full-restore',targetLineupIndex:0,isTrainerBattle:true,itemCatalog:catalog);
    for(var i=0;i<6;i++) {state=invoke()!.updatedGameState;}
    expect(adapter.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),-6);
    expect(invoke(),isNull);
    expect(adapter.state.turnNumber,6);
    expect(state.bag.entries.single.quantity,2);
  });
  for (final effect in [
    const ProjectItemEffectDefinition.battleBoost(
      stat: ProjectItemBattleStat.specialAttack,
      stages: 1,
    ),
    const ProjectItemEffectDefinition.battleBoost(
      stat: ProjectItemBattleStat.accuracy,
      stages: 1,
    ),
    const ProjectItemEffectDefinition.battlePreparation(
      effect: ProjectItemBattlePreparationKind.focusEnergy,
    ),
    const ProjectItemEffectDefinition.battlePreparation(
      effect: ProjectItemBattlePreparationKind.mist,
      turns: 5,
    ),
  ]) {
    test(
      'runtime bag executes ${effect.toJson()} and does not persist battle modifiers',
      () {
        final use = ProjectItemUseDefinition(
          contexts: {ProjectItemUseContext.battle},
          target: ProjectItemTargetKind.partyMember,
          consumption: ProjectItemConsumptionPolicy.onApplied,
          effect: effect,
        );
        final catalog = ItemCatalogSnapshot.fromCatalog(
          ProjectItemCatalog(
            schemaVersion: 1,
            entries: [
              ProjectItemDefinition(
                id: 'full-restore',
                displayName: 'Préparation',
                pocketId: 'battle',
                uses: [use],
              ),
            ],
          ),
        );
        final adapter = _adapter(), initial = _state(100);
        expect(
          classifyBattleBagItem(
            itemId: 'full-restore',
            resolver: ItemCapabilityResolver(catalog),
          ),
          BattleBagItemKind.medicine,
        );
        final menu = buildBattleMedicineTargetMenuModel(
          session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
          itemId: 'full-restore',
          displayName: 'Préparation',
          use: use,
        );
        expect(menu.activeEntry.isSelectable, isTrue);
        RuntimePsdkBattleItemApplyResult? apply() =>
            tryApplyRuntimePsdkBattleItemUse(
              psdkSession: adapter,
              displaySession: adapter.createLegacyDisplaySession(
                isTrainerBattle: true,
              ),
              gameState: initial,
              context: _context(),
              itemId: 'full-restore',
              targetLineupIndex: 0,
              isTrainerBattle: true,
              itemCatalog: catalog,
            );
        final result = apply();
        expect(result, isNotNull);
        expect(result!.consumptionReceipt?.quantity, 1);
        expect(result.updatedGameState.bag.entries.single.quantity, 1);
        expect(
          result.updatedGameState.party.members.single.evs,
          initial.party.members.single.evs,
        );
        expect(adapter.state.turnNumber, 1);
        final battler = adapter.state.battlerAt(psdkPlayerSlot);
        if (effect case ProjectItemBattleBoostEffectDefinition(:final stat)) {
          expect(battler.statStages.valueOf(stat.name), 1);
        } else {
          final id =
              (effect as ProjectItemBattlePreparationEffectDefinition).effect ==
                  ProjectItemBattlePreparationKind.focusEnergy
              ? 'focus_energy'
              : 'mist';
          expect(battler.effects.contains(id), isTrue);
          expect(apply(), isNull);
          expect(adapter.state.turnNumber, 1);
        }
        expect(
          GameState.fromJson(result.updatedGameState.toJson()),
          result.updatedGameState,
        );
        expect(initial.bag.entries.single.quantity, 2);
      },
    );
  }
}

RuntimePsdkBattleSessionAdapter _adapter({
  int hp = 100,
  bool confused = false,
  String abilityId = 'none',
}) => RuntimePsdkBattleSessionAdapter.fromSetup(
  PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _battler('player', hp, confused: confused, abilityId: abilityId),
    opponent: _battler('opponent', 100),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  ),
);
PsdkBattleCombatantSetup _battler(String id, int hp, {bool confused = false, String abilityId='none'}) =>
    PsdkBattleCombatantSetup(
      id: id,
      abilityId: abilityId,
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
