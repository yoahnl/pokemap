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
    test('capture and medicine support depend on canonical capabilities', () {
      final resolver = ItemCapabilityResolver(
        ItemCatalogSnapshot.fromCatalog(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: <ProjectItemDefinition>[
              ProjectItemDefinition(
                id: 'aurora-orb',
                displayName: 'Aurora Orb',
                pocketId: 'relics',
                capture: ProjectCaptureItemDefinition(
                  rateNumerator: 1,
                  rateDenominator: 1,
                  allowedEncounterKinds: <EncounterKind>{EncounterKind.walk},
                ),
              ),
              ProjectItemDefinition(
                id: 'decorative-orb',
                displayName: 'Decorative Orb',
                pocketId: 'balls',
              ),
              ProjectItemDefinition(
                id: 'field-tonic',
                displayName: 'Field Tonic',
                pocketId: 'relics',
                uses: <ProjectItemUseDefinition>[
                  ProjectItemUseDefinition(
                    contexts: <ProjectItemUseContext>{
                      ProjectItemUseContext.battle,
                    },
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
                id: 'souvenir-tonic',
                displayName: 'Souvenir Tonic',
                pocketId: 'medicine',
              ),
            ],
          ),
        ),
      );
      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          entries: const <BagEntry>[
            BagEntry(itemId: 'aurora-orb', quantity: 2),
            BagEntry(itemId: 'decorative-orb', quantity: 2),
            BagEntry(itemId: 'field-tonic', quantity: 2),
            BagEntry(itemId: 'souvenir-tonic', quantity: 2),
          ],
        ),
        session: _battleSession(allowCapture: true),
        resolver: resolver,
      );

      final captureItem = _entry(model, itemId: 'aurora-orb');
      final inertBallPocketItem = _entry(model, itemId: 'decorative-orb');
      final medicine = _entry(model, itemId: 'field-tonic');
      final inertMedicinePocketItem = _entry(model, itemId: 'souvenir-tonic');

      expect(captureItem.kind, BattleBagItemKind.captureBall);
      expect(captureItem.isSelectable, isTrue);
      expect(inertBallPocketItem.kind, BattleBagItemKind.unsupported);
      expect(inertBallPocketItem.disabledReason,
          BattleBagMenuDisabledReason.passive);
      expect(medicine.kind, BattleBagItemKind.medicine);
      expect(medicine.isSelectable, isTrue);
      expect(inertMedicinePocketItem.kind, BattleBagItemKind.unsupported);
      expect(
        inertMedicinePocketItem.disabledReason,
        BattleBagMenuDisabledReason.passive,
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
        expectedHealedAmount: 120,
        expectedHp: 130,
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
}) {
  return model.entries.singleWhere(
    (entry) => entry.itemId == itemId,
  );
}

RuntimeBattleBagHpHealItemApplyResult? _applyLegacyHeal(String itemId) {
  final session = _battleSession(currentHp: 10, maxHp: 500);
  final state = _gameState(
    entries: <BagEntry>[
      BagEntry(itemId: itemId, quantity: 2),
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
        itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
      ),
    'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
        session: session,
        gameState: state,
        context: context,
        targetLineupIndex: 0,
        itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
      ),
    'hyper-potion' => tryApplyRuntimeBattleHyperPotionUse(
        session: session,
        gameState: state,
        context: context,
        targetLineupIndex: 0,
        itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
      ),
    'max-potion' => tryApplyRuntimeBattleMaxPotionUse(
        session: session,
        gameState: state,
        context: context,
        targetLineupIndex: 0,
        itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
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
