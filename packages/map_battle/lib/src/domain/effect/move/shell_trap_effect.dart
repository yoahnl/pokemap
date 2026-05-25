import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK `ShellTrap` preparation effect.
///
/// The effect is deliberately tiny: while it remains on the user, Shell Trap is
/// considered unopened and the later move use fails. Receiving physical damage
/// from an opposing attacker removes the marker, which lets the queued Shell
/// Trap action continue when its turn arrives.
final class ShellTrapEffect extends BattleEffect {
  const ShellTrapEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'shell_trap',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  bool get preparingAttack => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ShellTrapEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!_appliesTo(context.owner) ||
        context.owner != context.target ||
        context.user == context.owner ||
        context.user.bank == context.owner.bank ||
        context.damage <= 0 ||
        context.move.category != PsdkBattleMoveCategory.physical ||
        _sheerForceAlreadyActivated(context)) {
      return null;
    }

    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(
          effects: battler.effects.remove(id),
        ),
      ),
      rng: context.rng,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef owner) {
    final effectScope = scope;
    return effectScope is! BattlerBattleEffectScope ||
        effectScope.slot == owner;
  }

  bool _sheerForceAlreadyActivated(BattleEffectPostDamageContext context) {
    final attacker = context.state.battlerAt(context.user);
    if (attacker.abilityId != 'sheer_force' ||
        attacker.effects.contains('ability_suppressed') ||
        context.move.category == PsdkBattleMoveCategory.status) {
      return false;
    }
    if (context.move.statuses.any(
          (status) =>
              status.majorStatus != null || status.volatileStatus != null,
        ) ||
        context.move.effectChance != null) {
      return true;
    }
    if (context.move.stageMods.isEmpty) {
      return false;
    }
    final onlyPositive = context.move.stageMods.every((mod) => mod.stages > 0);
    final onlyNegative = context.move.stageMods.every((mod) => mod.stages < 0);
    return switch (context.move.target) {
      PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => onlyPositive,
      _ => onlyNegative,
    };
  }
}
