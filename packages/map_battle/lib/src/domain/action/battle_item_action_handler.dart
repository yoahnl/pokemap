import '../../psdk/domain/psdk_battle_timeline.dart';
import '../handler/battle_handler_context.dart';
import '../handler/battle_handler_result.dart';
import '../handler/battle_heal_handler.dart';
import '../handler/battle_status_change_handler.dart';
import 'battle_action.dart';

final class BattleItemActionHandler {
  const BattleItemActionHandler();

  BattleHandlerResult useItem({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
  }) {
    _validateTarget(context: context, action: action);

    return switch (action.effect) {
      final PsdkBattleHpHealItemEffect effect => _healHp(
          context: context,
          action: action,
          effect: effect,
        ),
      final PsdkBattleStatusCureItemEffect effect => _cureStatus(
          context: context,
          action: action,
          effect: effect,
        ),
    };
  }

  BattleHandlerResult _healHp({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
    required PsdkBattleHpHealItemEffect effect,
  }) {
    final targetBattler = context.state.battlerAt(action.target);
    final amount = effect.restoreToFull ? targetBattler.maxHp : effect.amount!;
    final healed = const BattleHealHandler().heal(
      context: context,
      target: action.target,
      amount: amount,
    );
    if (!healed.applied) {
      return healed;
    }

    final current = healed.state.battlerAt(action.target);
    return BattleHandlerResult(
      state: healed.state,
      rng: healed.rng,
      amount: healed.amount,
      events: <PsdkBattleEvent>[
        _consumedEvent(context, action),
        PsdkBattleHealEvent(
          user: action.user,
          target: action.target,
          moveId: 'item:${action.itemId}',
          amount: healed.amount,
          remainingHp: current.currentHp,
        ),
      ],
    );
  }

  BattleHandlerResult _cureStatus({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
    required PsdkBattleStatusCureItemEffect effect,
  }) {
    final targetBattler = context.state.battlerAt(action.target);
    final status = targetBattler.majorStatus;
    if (status == null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'no_major_status',
      );
    }
    if (!effect.cures(status)) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'status_not_cured_by_item',
      );
    }

    final cured = const BattleStatusChangeHandler().cureMajorStatus(
      context: context,
      target: action.target,
      moveId: 'item:${action.itemId}',
    );
    if (!cured.applied) {
      return cured;
    }
    return BattleHandlerResult(
      state: cured.state,
      rng: cured.rng,
      events: <PsdkBattleEvent>[
        _consumedEvent(context, action),
        ...cured.events,
      ],
    );
  }

  PsdkBattleItemEvent _consumedEvent(
    BattleHandlerContext context,
    PsdkBattleItemAction action,
  ) {
    return PsdkBattleItemEvent.consumed(
      turn: context.turn,
      user: action.user,
      target: action.target,
      itemId: action.itemId,
    );
  }

  void _validateTarget({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
  }) {
    if (action.target.bank != action.user.bank) {
      throw ArgumentError.value(
        action.target,
        'target',
        'battle bag items can only target the user bank',
      );
    }
    final target = context.state.combatants[action.target];
    if (target == null) {
      throw ArgumentError.value(
        action.target,
        'target',
        'battle bag items can only target an active combatant in this lot',
      );
    }
    if (target.isFainted) {
      throw ArgumentError.value(
        action.target,
        'target',
        'battle bag items cannot target a fainted combatant',
      );
    }
  }
}
