import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK `LockOn` / `MindReader` marker.
final class LockOnEffect extends BattleEffect {
  const LockOnEffect({
    required BattleEffectScope scope,
    required this.target,
    int remainingTurns = 2,
  }) : super(
          id: 'lock_on',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final PsdkBattleSlotRef target;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return LockOnEffect(
      scope: scope,
      target: target,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return LockOnEffect(
      scope: BattlerBattleEffectScope(context.target),
      target: target,
      remainingTurns: (remainingTurns ?? 2) + 1,
    );
  }
}
