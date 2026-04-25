import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK effect kernel', () {
    test('stores effect objects while preserving id-based compatibility', () {
      final stack = PsdkBattleEffectStack(
        values: const <String>[PsdkBattleEffectIds.protect],
      );

      expect(stack.contains(PsdkBattleEffectIds.protect), isTrue);
      expect(stack.values, <String>[PsdkBattleEffectIds.protect]);
      expect(stack.effects.single, isA<ProtectEffect>());
      expect(stack.clearTurnScopedEffects().values, isEmpty);
    });

    test('addEffect replaces an existing effect with the same id', () {
      final stack = const PsdkBattleEffectStack.empty()
          .addEffect(const GenericBattleEffect(id: 'gravity'))
          .addEffect(const GenericBattleEffect(id: 'gravity'));

      expect(stack.values, <String>['gravity']);
    });

    test(
        'Protect effect blocks target moves but not self or non-protectable moves',
        () {
      final stack = const PsdkBattleEffectStack.empty().addEffect(
        const ProtectEffect(scope: LocalBattleEffectScope()),
      );
      const user = BattlePositionRef(bank: 1, position: 0);
      const target = BattlePositionRef(bank: 0, position: 0);

      expect(
        stack.targetMovePreventionReason(
          user: user,
          target: target,
          move: _move(protectable: true),
        ),
        BattleMoveFailureReason.protected,
      );
      expect(
        stack.targetMovePreventionReason(
          user: target,
          target: target,
          move: _move(protectable: true),
        ),
        isNull,
      );
      expect(
        stack.targetMovePreventionReason(
          user: user,
          target: target,
          move: _move(protectable: false),
        ),
        isNull,
      );
    });

    test('end-turn move effects damage cursed battlers and heal Aqua Ring', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'aqua_ring_target',
              currentHp: 60,
              effects: const PsdkBattleEffectStack.empty().addEffect(
                const AquaRingEffect(
                  scope: BattlerBattleEffectScope(psdkPlayerSlot),
                ),
              ),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'cursed_target',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                const CurseEffect(
                  scope: BattlerBattleEffectScope(psdkOpponentSlot),
                ),
              ),
            ),
          ),
        },
      );

      final result = const BattleEndTurnHandler().resolveEndTurn(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 2,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 66);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 75);
      expect(_heal(result.events, moveId: 'effect:aqua_ring').amount, 6);
      expect(_damage(result.events, moveId: 'effect:curse').damage, 25);
    });
  });
}

BattleMoveDefinition _move({required bool protectable}) {
  return BattleMoveDefinition(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    flags: BattleMoveFlags(protectable: protectable),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  int currentHp = 100,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[_psdkMove(id: 'splash')],
    effects: effects,
  );
}

PsdkBattleMoveData _psdkMove({required String id}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 0,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_splash',
    target: PsdkBattleMoveTarget.none,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}

PsdkBattleHealEvent _heal(
  List<PsdkBattleEvent> events, {
  required String moveId,
}) {
  return events
      .whereType<PsdkBattleHealEvent>()
      .singleWhere((event) => event.moveId == moveId);
}

PsdkBattleDamageEvent _damage(
  List<PsdkBattleEvent> events, {
  required String moveId,
}) {
  return events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId);
}
