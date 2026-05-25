import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class FairyLockEffect extends BattleEffect {
  const FairyLockEffect({
    required BattleEffectScope scope,
    int remainingTurns = 2,
  }) : super(
          id: 'fairy_lock',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FairyLockEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    final target = context.state.battlerAt(context.target);
    if (target.hasType('ghost')) {
      return null;
    }
    return id;
  }
}
