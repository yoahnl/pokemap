import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import '../../move/battle_move_prevention.dart';
import 'status_effect_registry.dart';

final class SleepEffect extends BattleMajorStatusEffect {
  const SleepEffect({
    required BattleEffectScope scope,
    this.turnsAsleep = 0,
  }) : super(id: 'sleep', scope: scope);

  final int turnsAsleep;

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.sleep;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SleepEffect(
      scope: scope,
      turnsAsleep: turnsAsleep,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    final battler = context.state.battlerAt(context.user);
    if (battler.majorStatus != status) {
      return null;
    }
    if (battler.sleepTurns >= 2) {
      return BattleEffectUserMovePreventionResult(
        state: context.state.updateBattler(
          context.user,
          (current) => current.copyWith(
            clearMajorStatus: true,
            sleepTurns: 0,
            effects: current.effects.remove('sleep'),
          ),
        ),
        rng: context.rng,
        prevented: false,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    final nextTurns = battler.sleepTurns + 1;
    final nextState = context.state.updateBattler(
      context.user,
      (current) => current.copyWith(
        sleepTurns: nextTurns,
        effects: current.effects.addEffect(
          SleepEffect(scope: scope, turnsAsleep: nextTurns),
        ),
      ),
    );
    return BattleEffectUserMovePreventionResult(
      state: nextState,
      rng: context.rng,
      prevented: !_isSleepUsableMove(context.move.dbSymbol),
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }
}

bool _isSleepUsableMove(String dbSymbol) {
  return dbSymbol == 'snore' || dbSymbol == 'sleep_talk';
}
