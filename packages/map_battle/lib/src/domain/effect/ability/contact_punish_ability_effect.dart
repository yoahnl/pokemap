import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class ContactPunishAbilityEffect extends BattleAbilityEffect {
  const ContactPunishAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ContactPunishAbilityEffect(abilityId: abilityId, scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user.bank == context.target.bank ||
        !context.move.flags.contact ||
        context.damage <= 0) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.currentHp <= 0) {
      return null;
    }

    final damage = (user.maxHp ~/ 8).clamp(1, user.currentHp).toInt();
    final remainingHp = user.currentHp - damage;
    final nextState = context.state.replaceBattler(
      context.user,
      user.copyWith(currentHp: remainingHp),
    );

    return BattleEffectPostDamageResult(
      state: nextState,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleDamageEvent(
          user: context.owner,
          target: context.user,
          moveId: 'effect:$abilityId',
          damage: damage,
          remainingHp: remainingHp,
        ),
      ],
    );
  }
}

final class AftermathEffect extends BattleAbilityEffect {
  const AftermathEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'aftermath', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AftermathEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        !context.targetFainted ||
        !context.move.flags.contact ||
        context.damage <= 0) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.currentHp <= 0 || _hasAliveDampBattler(context)) {
      return null;
    }

    final damage = (user.maxHp ~/ 4).clamp(1, user.currentHp).toInt();
    final remainingHp = user.currentHp - damage;
    final nextState = context.state.replaceBattler(
      context.user,
      user.copyWith(currentHp: remainingHp),
    );

    return BattleEffectPostDamageResult(
      state: nextState,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleDamageEvent(
          user: context.owner,
          target: context.user,
          moveId: 'effect:$abilityId',
          damage: damage,
          remainingHp: remainingHp,
        ),
      ],
    );
  }

  bool _hasAliveDampBattler(BattleEffectPostDamageContext context) {
    return context.state.aliveSlots().any((slot) {
      return context.state.battlerAt(slot).abilityId == 'damp';
    });
  }
}
