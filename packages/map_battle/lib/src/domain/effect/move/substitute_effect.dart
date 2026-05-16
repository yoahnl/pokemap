import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class SubstituteEffect extends BattleEffect {
  const SubstituteEffect({
    required BattleEffectScope scope,
    required this.remainingHp,
  }) : super(
          id: 'substitute',
          scope: scope,
        );

  final int remainingHp;

  SubstituteEffect damage(int amount) {
    return SubstituteEffect(
      scope: scope,
      remainingHp: (remainingHp - amount).clamp(0, remainingHp).toInt(),
    );
  }

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SubstituteEffect(scope: scope, remainingHp: remainingHp);
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return SubstituteEffect(
      scope: BattlerBattleEffectScope(context.target),
      remainingHp: remainingHp,
    );
  }
}
