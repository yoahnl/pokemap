import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../move/confusion_effect.dart';
import 'ability_effect.dart';

final class SynchronizeEffect extends BattleAbilityEffect {
  const SynchronizeEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'synchronize', scope: scope);

  static const _synchronizedStatuses = <PsdkBattleMajorStatus>{
    PsdkBattleMajorStatus.burn,
    PsdkBattleMajorStatus.paralysis,
    PsdkBattleMajorStatus.poison,
    PsdkBattleMajorStatus.toxic,
  };

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SynchronizeEffect(scope: scope);
  }

  @override
  BattleEffectStatusChangeResult? onPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    if (context.cured ||
        context.owner != context.target ||
        context.user == context.target ||
        !_synchronizedStatuses.contains(context.status)) {
      return null;
    }
    final user = context.state.battlerAt(context.user);
    if (user.isFainted || user.majorStatus == context.status) {
      return null;
    }

    final result = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      moveId: 'ability:synchronize',
      status: context.status,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectStatusChangeResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class PoisonPuppeteerEffect extends BattleAbilityEffect {
  const PoisonPuppeteerEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'poison_puppeteer', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PoisonPuppeteerEffect(scope: scope);
  }

  @override
  BattleEffectStatusChangeResult? onPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    if (!isOwnedBy(context.user) ||
        context.user == context.target ||
        context.move == null ||
        context.cured ||
        (context.status != PsdkBattleMajorStatus.poison &&
            context.status != PsdkBattleMajorStatus.toxic)) {
      return null;
    }

    final target = context.state.battlerAt(context.target);
    if (target.isFainted || target.effects.contains('confusion')) {
      return null;
    }

    final nextState = context.state.updateBattler(
      context.target,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          ConfusionEffect(scope: BattlerBattleEffectScope(context.target)),
        ),
      ),
    );
    return BattleEffectStatusChangeResult(
      state: nextState,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.target,
          effectId: 'confusion',
          remainingTurns: 2,
          reason: 'ability:poison_puppeteer',
        ),
      ],
    );
  }
}
