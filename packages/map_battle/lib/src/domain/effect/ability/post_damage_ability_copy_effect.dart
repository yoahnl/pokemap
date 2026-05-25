import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_ability_change_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class ReceiverPowerOfAlchemyEffect extends BattleAbilityEffect {
  const ReceiverPowerOfAlchemyEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  bool get affectsAlliesPostDamage => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ReceiverPowerOfAlchemyEffect(
      abilityId: abilityId,
      scope: scope,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner == context.target ||
        context.owner.bank != context.target.bank ||
        context.user == context.target ||
        context.damage <= 0 ||
        !context.targetFainted ||
        context.state.battlerAt(context.owner).isFainted) {
      return null;
    }

    final copiedAbilityId =
        context.state.battlerAt(context.target).abilityId?.trim().toLowerCase();
    if (copiedAbilityId == null || copiedAbilityId.isEmpty) {
      return null;
    }

    const handler = BattleAbilityChangeHandler();
    if (!handler.canChangeAbility(
      state: context.state,
      target: context.owner,
      launcher: context.target,
    )) {
      return null;
    }

    final result = handler.changeAbility(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      abilityId: copiedAbilityId,
      triggerSwitchEvent: true,
    );
    if (result.state == context.state && result.events.isEmpty) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        ...result.events,
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.owner,
          effectId: 'ability_copy:$copiedAbilityId',
          reason: 'ability:$abilityId',
        ),
      ],
      applied: true,
    );
  }
}
