import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'burn_effect.dart';
import 'freeze_effect.dart';
import 'paralysis_effect.dart';
import 'poison_effect.dart';
import 'sleep_effect.dart';
import 'toxic_effect.dart';

abstract class BattleMajorStatusEffect extends BattleEffect {
  const BattleMajorStatusEffect({
    required super.id,
    required super.scope,
    super.remainingTurns,
  });

  PsdkBattleMajorStatus get status;
}

final class StatusEffectRegistry {
  const StatusEffectRegistry();

  BattleMajorStatusEffect create({
    required PsdkBattleMajorStatus status,
    required PsdkBattleSlotRef target,
    int sleepTurns = 0,
    int toxicCounter = 0,
  }) {
    final scope = BattlerBattleEffectScope(target);
    return switch (status) {
      PsdkBattleMajorStatus.burn => BurnEffect(scope: scope),
      PsdkBattleMajorStatus.poison => PoisonEffect(scope: scope),
      PsdkBattleMajorStatus.toxic => ToxicEffect(
          scope: scope,
          toxicCounter: toxicCounter,
        ),
      PsdkBattleMajorStatus.paralysis => ParalysisEffect(scope: scope),
      PsdkBattleMajorStatus.sleep => SleepEffect(
          scope: scope,
          turnsAsleep: sleepTurns,
        ),
      PsdkBattleMajorStatus.freeze => FreezeEffect(scope: scope),
    };
  }
}
