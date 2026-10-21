import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/move/heal_block_effect.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_trainer_battle_items.dart';

void main() {
  test(
    'one player item restores HP, major status and confusion in one turn',
    () {
      final engine = _engine(
        playerHp: 20,
        status: PsdkBattleMajorStatus.toxic,
        confused: true,
      );
      final result = engine.submit(_decision());
      final target = result.state.battlerAt(psdkPlayerSlot);
      expect(target.currentHp, 100);
      expect(target.majorStatus, isNull);
      expect(target.effects.contains('confusion'), isFalse);
      expect(target.sleepTurns, 0);
      expect(target.toxicCounter, 0);
      expect(target.moves.single.currentPp, 40);
      expect(result.state.turnNumber, 1);
      expect(
        result.timeline.events.whereType<BattleItemTimelineEvent>(),
        hasLength(1),
      );
      expect(
        result.timeline.events
            .whereType<BattleHealTimelineEvent>()
            .single
            .amount,
        80,
      );
      expect(
        result.timeline.events.whereType<BattleStatusCureTimelineEvent>(),
        hasLength(1),
      );
    },
  );

  for (final input in [(PsdkBattleMajorStatus.sleep, false), (null, true)]) {
    test(
      'full HP with status ${input.$1} and confusion ${input.$2} is usable',
      () {
        final engine = _engine(status: input.$1, confused: input.$2);
        final result = engine.submit(_decision());
        final target = result.state.battlerAt(psdkPlayerSlot);
        expect(target.currentHp, 100);
        expect(target.majorStatus, isNull);
        expect(target.effects.contains('confusion'), isFalse);
        expect(target.sleepTurns, 0);
        expect(target.toxicCounter, 0);
        expect(
          result.timeline.events.whereType<BattleHealTimelineEvent>(),
          isEmpty,
        );
        expect(
          result.timeline.events.whereType<BattleItemTimelineEvent>(),
          hasLength(1),
        );
        expect(result.state.turnNumber, 1);
      },
    );
  }

  for (final status in PsdkBattleMajorStatus.values) {
    test('full restore cures $status without restoring PP', () {
      final engine = _engine(status: status);
      final result = engine.submit(_decision());
      final target = result.state.battlerAt(psdkPlayerSlot);
      expect(target.majorStatus, isNull);
      expect(target.sleepTurns, 0);
      expect(target.toxicCounter, 0);
      expect(target.moves.single.currentPp, 40);
      expect(result.state.turnNumber, 1);
    });
  }

  test('item healing bypasses Heal Block and preserves unrelated effects', () {
    final engine = _engine(playerHp: 20, protectedEffects: true);
    final result = engine.submit(_decision());
    final target = result.state.battlerAt(psdkPlayerSlot);
    expect(target.currentHp, 100);
    expect(target.effects.contains('heal_block'), isTrue);
    expect(target.effects.contains('substitute'), isTrue);
    expect(
      target.effects.effects.whereType<SubstituteEffect>().single.remainingHp,
      25,
    );
    expect(result.state.turnNumber, 1);
  });

  test('healthy target is rejected without spending a turn or item', () {
    final engine = _engine();
    expect(
      () => engine.submit(_decision()),
      throwsA(isA<BattleDecisionRejectedError>()),
    );
    expect(engine.snapshot().turnNumber, 0);
    expect(engine.snapshot().battlerAt(psdkPlayerSlot).currentHp, 100);
  });

  test('fainted reserve is rejected without spending a turn or item', () {
    final engine = _engine(reserveHp: 0);
    expect(() => engine.submit(_decision(partyIndex: 1)), throwsArgumentError);
    expect(engine.snapshot().turnNumber, 0);
    expect(engine.snapshot().partyForBank(0)[1].currentHp, 0);
  });

  test('living reserve is restored without changing the active Pokemon', () {
    final engine = _engine(reserveHp: 5);
    final result = engine.submit(_decision(partyIndex: 1));
    expect(result.state.partyForBank(0)[1].currentHp, 100);
    expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    expect(
      result.timeline.events
          .whereType<BattleItemTimelineEvent>()
          .single
          .partyIndex,
      1,
    );
  });

  for (final quantity in [1, 2]) {
    test('trainer consumes exactly $quantity items across committed turns', () {
      final options = _options(quantity: quantity);
      final engine = BattleEngine(
        setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
          player: _battler('player', 100, power: 1),
          opponent: _battler(
            'opponent',
            20,
            status: PsdkBattleMajorStatus.burn,
            confused: true,
            slot: psdkOpponentSlot,
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
        opponentAi: PsdkBattleAi(
          canUseItem: true,
          canSwitch: false,
          itemOptions: options,
        ),
      );
      final counts = <int>[];
      for (var i = 0; i < quantity + 1; i++) {
        final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
        counts.add(
          result.timeline.events
              .whereType<BattleItemTimelineEvent>()
              .where((e) => e.user.bank == 1)
              .length,
        );
        expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
        expect(
          result.state
              .battlerAt(psdkOpponentSlot)
              .effects
              .contains('confusion'),
          isFalse,
        );
      }
      expect(counts, [for (var i = 0; i < quantity; i++) 1, 0]);
    });
  }
}

List<PsdkBattleAiItemOption> _options({int quantity = 1}) =>
    resolveRuntimeTrainerBattleItems(
      trainer: ProjectTrainerEntry(
        id: 'pryce',
        name: 'Frédo',
        trainerClass: 'Champion',
        battleItems: {'full-restore': quantity},
      ),
      itemCatalog: ItemCatalogSnapshot.fromCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'full-restore',
              displayName: 'Soin Total',
              pocketId: 'medicine',
              uses: [
                ProjectItemUseDefinition(
                  contexts: {ProjectItemUseContext.battle},
                  target: ProjectItemTargetKind.partyMember,
                  consumption: ProjectItemConsumptionPolicy.onApplied,
                  effect: const ProjectItemEffectDefinition.fullRestore(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
BattleDecision _decision({int? partyIndex}) => BattleDecision.item(
  itemId: 'full-restore',
  target: psdkPlayerSlot,
  targetPartyIndex: partyIndex,
  effect: _options().single.effect,
  highPriority: true,
);
BattleEngine _engine({
  int playerHp = 100,
  PsdkBattleMajorStatus? status,
  bool confused = false,
  int? reserveHp,
  bool protectedEffects = false,
}) => BattleEngine(
  setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: _battler(
      'player',
      playerHp,
      status: status,
      confused: confused,
      protectedEffects: protectedEffects,
    ),
    playerReserves: [if (reserveHp != null) _battler('reserve', reserveHp)],
    opponent: _battler('opponent', 100),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  ),
);
PsdkBattleCombatantSetup _battler(
  String id,
  int hp, {
  PsdkBattleMajorStatus? status,
  bool confused = false,
  int power = 0,
  bool protectedEffects = false,
  PsdkBattleSlotRef slot = psdkPlayerSlot,
}) => PsdkBattleCombatantSetup(
  id: id,
  speciesId: 'test_species',
  displayName: id,
  level: 5,
  maxHp: 100,
  currentHp: hp,
  types: const PsdkBattleTypes(primary: 'normal'),
  stats: const PsdkBattleStats(
    attack: 10,
    defense: 10,
    specialAttack: 10,
    specialDefense: 10,
    speed: 10,
  ),
  majorStatus: status,
  sleepTurns: status == PsdkBattleMajorStatus.sleep ? 3 : 0,
  toxicCounter: status == PsdkBattleMajorStatus.toxic ? 3 : 0,
  effects: PsdkBattleEffectStack(
    effects: [
      if (confused) ConfusionEffect(scope: BattlerBattleEffectScope(slot)),
      if (protectedEffects) ...[
        HealBlockEffect(scope: BattlerBattleEffectScope(slot)),
        SubstituteEffect(
          scope: BattlerBattleEffectScope(slot),
          remainingHp: 25,
        ),
      ],
    ],
  ),
  moves: [
    PsdkBattleMoveData(
      id: 'test_move',
      dbSymbol: 'test_move',
      name: 'Test move',
      type: 'normal',
      category: power == 0
          ? PsdkBattleMoveCategory.status
          : PsdkBattleMoveCategory.physical,
      power: power,
      accuracy: 100,
      pp: 40,
      priority: 0,
      battleEngineMethod: power == 0 ? 's_splash' : 's_basic',
      target: power == 0
          ? PsdkBattleMoveTarget.user
          : PsdkBattleMoveTarget.adjacentFoe,
    ),
  ],
);
