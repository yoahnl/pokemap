import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK `NoRetreat` self-trapping effect.
final class NoRetreatEffect extends BattleEffect {
  const NoRetreatEffect({
    required BattleEffectScope scope,
    int? remainingTurns,
  }) : super(
          id: 'no_retreat',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return NoRetreatEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return NoRetreatEffect(
      scope: BattlerBattleEffectScope(context.target),
      remainingTurns: remainingTurns,
    );
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    return _appliesTo(context.target) ? id : null;
  }

  bool _appliesTo(PsdkBattleSlotRef target) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == target;
  }
}
