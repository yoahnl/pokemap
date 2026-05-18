import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class ContactStatusAbilityEffect extends BattleAbilityEffect {
  const ContactStatusAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.status,
  })  : effectSpore = false,
        super(abilityId: abilityId, scope: scope);

  const ContactStatusAbilityEffect.effectSpore({
    required BattleEffectScope scope,
  })  : status = null,
        effectSpore = true,
        super(abilityId: 'effect_spore', scope: scope);

  final PsdkBattleMajorStatus? status;
  final bool effectSpore;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return effectSpore
        ? ContactStatusAbilityEffect.effectSpore(scope: scope)
        : ContactStatusAbilityEffect(
            abilityId: abilityId,
            scope: scope,
            status: status!,
          );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        !context.move.flags.contact) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.isFainted || _effectSporeBlocked(user)) {
      return null;
    }

    if (effectSpore) {
      return _rollEffectSporeStatus(context, context.rng);
    }
    if (!_canReceiveFixedStatus(user, status!)) {
      return null;
    }
    final roll = context.rng.generic.nextChance(numerator: 3, denominator: 10);
    final nextRng = context.rng.copyWith(generic: roll.next);
    if (!roll.didOccur) {
      return BattleEffectPostDamageResult(
        state: context.state,
        rng: nextRng,
        applied: false,
      );
    }
    return _applyStatus(context, nextRng, status!);
  }

  BattleEffectPostDamageResult? _rollEffectSporeStatus(
    BattleEffectPostDamageContext context,
    BattleRngStreams rng,
  ) {
    final roll = rng.generic.nextIntInclusive(min: 0, max: 9);
    final nextRng = rng.copyWith(generic: roll.next);
    final rolledStatus = switch (roll.value) {
      0 => PsdkBattleMajorStatus.poison,
      1 => PsdkBattleMajorStatus.sleep,
      2 => PsdkBattleMajorStatus.paralysis,
      _ => null,
    };
    if (rolledStatus == null) {
      return BattleEffectPostDamageResult(
        state: context.state,
        rng: nextRng,
        applied: false,
      );
    }
    return _applyStatus(context, nextRng, rolledStatus);
  }

  bool _effectSporeBlocked(PsdkBattleCombatant user) {
    return effectSpore &&
        (user.abilityId == 'overcoat' ||
            user.hasType('grass') ||
            user.heldItemId == 'safety_goggles');
  }

  bool _canReceiveFixedStatus(
    PsdkBattleCombatant user,
    PsdkBattleMajorStatus status,
  ) {
    if (user.majorStatus != null) {
      return false;
    }
    final abilityContext = BattleAbilityStatusContext(
      status: status,
      target: user,
    );
    if (user.abilityEffects.any(
      (effect) => effect.preventsStatus(abilityContext),
    )) {
      return false;
    }
    return switch (status) {
      PsdkBattleMajorStatus.burn => !user.hasType('fire'),
      PsdkBattleMajorStatus.poison ||
      PsdkBattleMajorStatus.toxic =>
        !user.hasType('poison') && !user.hasType('steel'),
      PsdkBattleMajorStatus.paralysis => !user.hasType('electric'),
      PsdkBattleMajorStatus.freeze => !user.hasType('ice'),
      PsdkBattleMajorStatus.sleep => true,
    };
  }

  BattleEffectPostDamageResult _applyStatus(
    BattleEffectPostDamageContext context,
    BattleRngStreams rng,
    PsdkBattleMajorStatus status,
  ) {
    final result = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      moveId: 'effect:$abilityId',
      status: status,
      move: context.move,
    );
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
      applied: result.applied,
    );
  }
}
