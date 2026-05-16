import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK generic end-turn effects', () {
    test('skips later owner effects after an earlier end-turn KO', () {
      final log = <String>[];
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'source',
              effects: const PsdkBattleEffectStack.empty().addEffect(
                _EndTurnKnockOutFixtureEffect(
                  scope: BattlerBattleEffectScope(psdkPlayerSlot),
                  target: psdkOpponentSlot,
                ),
              ),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'target',
              effects: PsdkBattleEffectStack.empty().addEffect(
                _EndTurnLogFixtureEffect(
                  scope: BattlerBattleEffectScope(psdkOpponentSlot),
                  logLabel: 'opponent_effect_ran',
                  log: log,
                ),
              ),
            ),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 6,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 0);
      expect(log, isEmpty);
      expect(
        result.events.whereType<PsdkBattleDamageEvent>().single.moveId,
        'effect:end_turn_ko_fixture',
      );
    });
  });
}

final class _EndTurnKnockOutFixtureEffect extends BattleEffect {
  const _EndTurnKnockOutFixtureEffect({
    required BattleEffectScope scope,
    required this.target,
  }) : super(id: 'end_turn_ko_fixture', scope: scope);

  final PsdkBattleSlotRef target;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return _EndTurnKnockOutFixtureEffect(scope: scope, target: target);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final targetBattler = context.state.battlerAt(target);
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: target,
      moveId: 'effect:end_turn_ko_fixture',
      rawDamage: targetBattler.currentHp,
    );
    return BattleEffectEndTurnResult(
      state: damaged.state,
      rng: damaged.rng,
      events: damaged.events,
      applied: damaged.applied,
    );
  }
}

final class _EndTurnLogFixtureEffect extends BattleEffect {
  const _EndTurnLogFixtureEffect({
    required BattleEffectScope scope,
    required this.logLabel,
    required this.log,
  }) : super(id: 'end_turn_log_fixture', scope: scope);

  final String logLabel;
  final List<String> log;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return _EndTurnLogFixtureEffect(
      scope: scope,
      logLabel: logLabel,
      log: log,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final scope = this.scope;
    if (scope is BattlerBattleEffectScope && scope.slot != context.owner) {
      return null;
    }
    log.add(logLabel);
    return BattleEffectEndTurnResult(state: context.state, rng: context.rng);
  }
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'splash',
        dbSymbol: 'splash',
        name: 'Splash',
        type: 'normal',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        pp: 40,
        priority: 0,
        criticalRate: 1,
        battleEngineMethod: 's_splash',
        target: PsdkBattleMoveTarget.none,
      ),
    ],
    effects: effects,
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
