import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
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
}
