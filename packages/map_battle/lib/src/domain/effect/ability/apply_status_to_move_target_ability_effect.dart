import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class ApplyStatusToMoveTargetAbilityEffect extends BattleAbilityEffect {
  const ApplyStatusToMoveTargetAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.status,
    this.requiresContact = false,
    this.chanceNumerator = 3,
    this.chanceDenominator = 10,
  }) : super(abilityId: abilityId, scope: scope);

  final PsdkBattleMajorStatus status;
  final bool requiresContact;
  final int chanceNumerator;
  final int chanceDenominator;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ApplyStatusToMoveTargetAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      status: status,
      requiresContact: requiresContact,
      chanceNumerator: chanceNumerator,
      chanceDenominator: chanceDenominator,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.user ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        (requiresContact && !context.move.flags.contact)) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    final target = context.state.battlerAt(context.target);
    if (user.isFainted || !_canReceiveStatus(target, context.move)) {
      return null;
    }

    final roll = context.rng.generic.nextChance(
      numerator: chanceNumerator,
      denominator: chanceDenominator,
    );
    final nextRng = context.rng.copyWith(generic: roll.next);
    if (!roll.didOccur) {
      return BattleEffectPostDamageResult(
        state: context.state,
        rng: nextRng,
        applied: false,
      );
    }

    final result = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: nextRng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.target,
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

  bool _canReceiveStatus(
    PsdkBattleCombatant target,
    BattleMoveDefinition move,
  ) {
    if (target.majorStatus != null) {
      return false;
    }
    final abilityContext = BattleAbilityStatusContext(
      status: status,
      target: target,
      move: move,
    );
    if (target.abilityEffects.any(
      (effect) => effect.preventsStatus(abilityContext),
    )) {
      return false;
    }
    return switch (status) {
      PsdkBattleMajorStatus.poison ||
      PsdkBattleMajorStatus.toxic =>
        !target.hasType('poison') && !target.hasType('steel'),
      PsdkBattleMajorStatus.burn => !target.hasType('fire'),
      PsdkBattleMajorStatus.paralysis => !target.hasType('electric'),
      PsdkBattleMajorStatus.freeze => !target.hasType('ice'),
      PsdkBattleMajorStatus.sleep => true,
    };
  }
}
