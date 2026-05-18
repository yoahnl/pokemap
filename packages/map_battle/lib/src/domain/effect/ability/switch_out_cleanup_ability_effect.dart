import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class NaturalCureEffect extends BattleAbilityEffect {
  const NaturalCureEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'natural_cure', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return NaturalCureEffect(scope: scope);
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final battler = context.state.battlerAt(context.owner);
    if (battler.id == context.replacement.id ||
        battler.majorStatus == null ||
        battler.isFainted) {
      return null;
    }

    final result = const BattleStatusChangeHandler().cureMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      moveId: 'ability:natural_cure',
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectSwitchOutResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class RegeneratorEffect extends BattleAbilityEffect {
  const RegeneratorEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'regenerator', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RegeneratorEffect(scope: scope);
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final battler = context.state.battlerAt(context.owner);
    if (battler.id == context.replacement.id ||
        battler.isFainted ||
        battler.currentHp >= battler.maxHp) {
      return null;
    }

    final result = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      amount: battler.maxHp ~/ 3,
    );
    if (!result.applied) {
      return null;
    }
    final healed = result.state.battlerAt(context.owner);
    return BattleEffectSwitchOutResult(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: context.owner,
          target: context.owner,
          moveId: 'ability:regenerator',
          amount: result.amount,
          remainingHp: healed.currentHp,
        ),
      ],
    );
  }
}
