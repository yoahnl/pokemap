import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK handlers', () {
    test('damage handler applies HP damage, records history and emits damage',
        () {
      final result = const BattleDamageHandler().applyDamage(
        context: _context(),
        target: psdkOpponentSlot,
        moveId: 'scratch',
        rawDamage: 18,
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      expect(result.applied, isTrue);
      expect(result.amount, 18);
      expect(target.currentHp, 22);
      expect(target.lastHitByMoveId, 'scratch');
      expect(target.damageHistory.entries.single.damage, 18);
      expect(target.damageHistory.entries.single.turn, 3);
      expect(result.events.single, isA<PsdkBattleDamageEvent>());
    });

    test('damage handler boosts Rage target attack after opposing damage', () {
      final context = _context(
        state: PsdkBattleState.fromSetup(
          _setup(
            playerEffects: const PsdkBattleEffectStack.empty().addEffect(
              GenericBattleEffect(
                id: 'rage',
                scope: BattlerBattleEffectScope(psdkPlayerSlot),
              ),
            ),
          ),
        ),
        user: psdkOpponentSlot,
      );

      final result = const BattleDamageHandler().applyDamage(
        context: context,
        target: psdkPlayerSlot,
        moveId: 'tackle',
        rawDamage: 10,
      );

      final target = result.state.battlerAt(psdkPlayerSlot);
      expect(result.applied, isTrue);
      expect(result.amount, 10);
      expect(target.currentHp, 30);
      expect(target.statStages.valueOf('attack'), 1);
      expect(result.events, hasLength(2));
      expect(result.events.first, isA<PsdkBattleDamageEvent>());
      expect(result.events.last, isA<PsdkBattleStatStageEvent>());
    });

    test('damage handler reports zero damage without mutating state', () {
      final context = _context();
      final result = const BattleDamageHandler().applyDamage(
        context: context,
        target: psdkOpponentSlot,
        moveId: 'splash',
        rawDamage: 0,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'zero_damage');
      expect(result.amount, 0);
      expect(result.state, same(context.state));
      expect(result.events, isEmpty);
    });

    test('status handler applies exclusive major status through one gate', () {
      final first = const BattleStatusChangeHandler().applyMajorStatus(
        context: _context(),
        target: psdkOpponentSlot,
        moveId: 'thunder_wave',
        status: PsdkBattleMajorStatus.paralysis,
      );
      final second = const BattleStatusChangeHandler().applyMajorStatus(
        context: _context(state: first.state),
        target: psdkOpponentSlot,
        moveId: 'will_o_wisp',
        status: PsdkBattleMajorStatus.burn,
      );

      expect(first.applied, isTrue);
      expect(first.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.paralysis);
      expect(first.events.single, isA<PsdkBattleStatusEvent>());
      expect(second.applied, isFalse);
      expect(second.reason, 'already_statused');
      expect(second.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.paralysis);
    });

    test('stat handler applies stages, records history and emits event', () {
      final result = const BattleStatChangeHandler().applyStatChange(
        context: _context(),
        target: psdkOpponentSlot,
        stat: 'defense',
        stages: -1,
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      expect(result.applied, isTrue);
      expect(result.amount, -1);
      expect(target.statStages.valueOf('defense'), -1);
      expect(target.statHistory.entries.single.turn, 3);
      expect(target.statHistory.entries.single.stat, 'defense');
      expect(result.events.single, isA<PsdkBattleStatStageEvent>());
    });
  });
}

BattleHandlerContext _context({
  PsdkBattleState? state,
  PsdkBattleSlotRef user = psdkPlayerSlot,
}) {
  return BattleHandlerContext(
    state: state ?? PsdkBattleState.fromSetup(_setup()),
    rng: BattleRngStreams.fromSeeds(
      moveDamageSeed: 1,
      moveCriticalSeed: 1,
      moveAccuracySeed: 1,
      genericSeed: 1,
    ),
    turn: 3,
    user: user,
  );
}

PsdkBattleSetup _setup({
  PsdkBattleEffectStack? playerEffects,
  PsdkBattleEffectStack? opponentEffects,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant('player', effects: playerEffects),
    opponent: _combatant('opponent', effects: opponentEffects),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 1,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
}

PsdkBattleCombatantSetup _combatant(
  String id, {
  PsdkBattleEffectStack? effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 20,
      defense: 20,
      specialAttack: 20,
      specialDefense: 20,
      speed: 20,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'scratch',
        dbSymbol: 'scratch',
        name: 'Scratch',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
    effects: effects,
  );
}
