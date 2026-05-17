import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../move/battle_move_prevention.dart';
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

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (context.user.bank == context.target.bank ||
        !_appliesTo(context.target) ||
        _bypassesSubstitute(context)) {
      return null;
    }

    final damage = context.damage.clamp(0, remainingHp).toInt();
    if (damage <= 0) {
      return BattleEffectDamagePreventionResult(
        state: context.state,
        rng: context.rng,
        prevented: true,
        reason: BattleMoveFailureReason.protected,
        applied: false,
      );
    }

    final targetBattler = context.state.battlerAt(context.target);
    final nextEffects = damage >= remainingHp
        ? targetBattler.effects.remove(id)
        : targetBattler.effects.addEffect(this.damage(damage));
    final nextState = context.state.updateBattler(
      context.target,
      (battler) => battler.copyWith(effects: nextEffects),
    );

    return BattleEffectDamagePreventionResult(
      state: nextState,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.protected,
      amount: damage,
      events: <PsdkBattleEvent>[
        PsdkBattleDamageEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          damage: damage,
          remainingHp: targetBattler.currentHp,
        ),
      ],
    );
  }

  bool _appliesTo(PsdkBattleSlotRef target) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == target;
  }

  bool _bypassesSubstitute(BattleEffectDamagePreventionContext context) {
    final user = context.state.battlerAt(context.user);
    return context.move.flags.sound || user.abilityId == 'infiltrator';
  }
}
