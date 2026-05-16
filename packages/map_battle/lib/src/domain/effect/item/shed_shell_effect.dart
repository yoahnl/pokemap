import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class ShedShellEffect extends BattleItemEffect {
  const ShedShellEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'shed_shell', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ShedShellEffect(scope: scope);
  }

  @override
  bool onSwitchPassthrough(BattleEffectSwitchPreventionContext context) {
    if (!isOwnedBy(context.target)) {
      return false;
    }
    final battler = context.state.battlerAt(context.target);
    if (battler.heldItemId != itemId ||
        battler.itemConsumed ||
        battler.itemEffectsSuppressed) {
      return false;
    }
    return context.move?.battleEngineMethod != 's_teleport';
  }
}
