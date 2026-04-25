import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'status_effect_registry.dart';

final class ToxicEffect extends BattleMajorStatusEffect {
  const ToxicEffect({
    required BattleEffectScope scope,
    this.toxicCounter = 0,
  }) : super(id: 'toxic', scope: scope);

  final int toxicCounter;

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.toxic;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ToxicEffect(
      scope: scope,
      toxicCounter: toxicCounter,
    );
  }
}
