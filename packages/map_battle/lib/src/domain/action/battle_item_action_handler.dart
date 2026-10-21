import '../../psdk/domain/psdk_battle_timeline.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';
import '../handler/battle_handler_context.dart';
import '../handler/battle_handler_result.dart';
import 'battle_action.dart';

final class BattleItemActionHandler {
  const BattleItemActionHandler();

  BattleHandlerResult useItem({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
  }) {
    _validateTarget(context: context, action: action);

    return switch (action.effect) {
      PsdkBattleFullRestoreItemEffect() => _fullRestore(
          context: context,
          action: action,
        ),
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
      final PsdkBattleReviveItemEffect effect => _revive(
          context: context,
          action: action,
          effect: effect,
        ),
      final PsdkBattlePpRestoreItemEffect effect => _restorePp(
          context: context,
          action: action,
          effect: effect,
        ),
    };
  }

  BattleHandlerResult _fullRestore({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
  }) {
    final partyIndex = _targetPartyIndex(context: context, action: action);
    final target = context.state.partyForBank(action.target.bank)[partyIndex];
    final status = target.majorStatus;
    final confused = target.effects.contains(PsdkBattleEffectIds.confusion);
    final amount = (target.maxHp - target.currentHp).clamp(0, target.maxHp);
    if (amount == 0 && status == null && !confused) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'no_effect',
      );
    }
    var effects = target.effects;
    if (status != null) effects = effects.remove(status.name);
    if (confused) effects = effects.remove(PsdkBattleEffectIds.confusion);
    final restored = target.copyWith(
      currentHp: target.maxHp,
      clearMajorStatus: true,
      sleepTurns: 0,
      toxicCounter: 0,
      effects: effects,
    );
    return BattleHandlerResult(
      state: context.state.replacePartyBattler(
        bank: action.target.bank,
        partyIndex: partyIndex,
        battler: restored,
      ),
      rng: context.rng,
      amount: amount,
      events: <PsdkBattleEvent>[
        _itemEvent(context, action, partyIndex),
        if (amount > 0)
          PsdkBattleHealEvent(
            user: action.user,
            target: action.target,
            moveId: 'item:${action.itemId}',
            amount: amount,
            remainingHp: restored.currentHp,
          ),
        if (status != null)
          PsdkBattleStatusCureEvent(
            user: action.user,
            target: action.target,
            moveId: 'item:${action.itemId}',
            status: status,
          ),
        if (confused)
          PsdkBattleEffectEvent.removed(
            turn: context.turn,
            target: action.target,
            effectId: PsdkBattleEffectIds.confusion,
            reason: 'item:${action.itemId}',
          ),
      ],
    );
  }

  BattleHandlerResult _restorePp({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
    required PsdkBattlePpRestoreItemEffect effect,
  }) {
    final partyIndex = _targetPartyIndex(context: context, action: action);
    final target = context.state.partyForBank(action.target.bank)[partyIndex];
    if (effect.moveSlot < 0 || effect.moveSlot >= target.moves.length) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'invalid_move_slot',
      );
    }
    final move = target.moves[effect.moveSlot];
    if (move.currentPp >= move.pp) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'pp_full',
      );
    }
    final requested = effect.restoreToFull ? move.pp : effect.amount!;
    if (requested <= 0) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'invalid_pp_amount',
      );
    }
    final amount = requested.clamp(0, move.pp - move.currentPp);
    final remainingPp = move.currentPp + amount;
    final restored = target.replaceMoveAt(
      effect.moveSlot,
      move.copyWith(currentPp: remainingPp),
    );
    return BattleHandlerResult(
      state: context.state.replacePartyBattler(
        bank: action.target.bank,
        partyIndex: partyIndex,
        battler: restored,
      ),
      rng: context.rng,
      amount: amount,
      events: <PsdkBattleEvent>[
        _itemEvent(context, action, partyIndex),
        PsdkBattleMovePpRestoredEvent(
          turn: context.turn,
          user: action.user,
          target: action.target,
          partyIndex: partyIndex,
          itemId: action.itemId,
          moveSlot: effect.moveSlot,
          moveId: move.id,
          beforePp: move.currentPp,
          remainingPp: remainingPp,
          amount: amount,
        ),
      ],
    );
  }

  BattleHandlerResult _healHp({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
    required PsdkBattleHpHealItemEffect effect,
  }) {
    final partyIndex = _targetPartyIndex(context: context, action: action);
    final targetBattler =
        context.state.partyForBank(action.target.bank)[partyIndex];
    if (targetBattler.currentHp >= targetBattler.maxHp) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'hp_full',
      );
    }
    final requested =
        effect.restoreToFull ? targetBattler.maxHp : effect.amount!;
    final amount =
        requested.clamp(0, targetBattler.maxHp - targetBattler.currentHp);
    final current = targetBattler.copyWith(
      currentHp: targetBattler.currentHp + amount,
    );
    final state = context.state.replacePartyBattler(
      bank: action.target.bank,
      partyIndex: partyIndex,
      battler: current,
    );
    return BattleHandlerResult(
      state: state,
      rng: context.rng,
      amount: amount,
      events: <PsdkBattleEvent>[
        _itemEvent(context, action, partyIndex),
        PsdkBattleHealEvent(
          user: action.user,
          target: action.target,
          moveId: 'item:${action.itemId}',
          amount: amount,
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
    final partyIndex = _targetPartyIndex(context: context, action: action);
    final targetBattler =
        context.state.partyForBank(action.target.bank)[partyIndex];
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

    final curedBattler = targetBattler.copyWith(
      clearMajorStatus: true,
      sleepTurns:
          status == PsdkBattleMajorStatus.sleep ? 0 : targetBattler.sleepTurns,
      toxicCounter: status == PsdkBattleMajorStatus.toxic
          ? 0
          : targetBattler.toxicCounter,
      effects: targetBattler.effects.remove(status.name),
    );
    final state = context.state.replacePartyBattler(
      bank: action.target.bank,
      partyIndex: partyIndex,
      battler: curedBattler,
    );
    return BattleHandlerResult(
      state: state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        _itemEvent(context, action, partyIndex),
        PsdkBattleStatusCureEvent(
          user: action.user,
          target: action.target,
          moveId: 'item:${action.itemId}',
          status: status,
        ),
      ],
    );
  }

  BattleHandlerResult _revive({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
    required PsdkBattleReviveItemEffect effect,
  }) {
    final partyIndex = _targetPartyIndex(context: context, action: action);
    final target = context.state.partyForBank(action.target.bank)[partyIndex];
    if (!target.isFainted) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'target_not_fainted',
      );
    }
    final revivedHp = (target.maxHp * effect.percent + 99) ~/ 100;
    final revived =
        target.copyWith(currentHp: revivedHp.clamp(1, target.maxHp));
    return BattleHandlerResult(
      state: context.state.replacePartyBattler(
        bank: action.target.bank,
        partyIndex: partyIndex,
        battler: revived,
      ),
      rng: context.rng,
      amount: revived.currentHp,
      events: <PsdkBattleEvent>[
        _itemEvent(context, action, partyIndex),
      ],
    );
  }

  PsdkBattleItemEvent _itemEvent(
    BattleHandlerContext context,
    PsdkBattleItemAction action,
    int partyIndex,
  ) {
    return action.consumeItem
        ? PsdkBattleItemEvent.consumed(
            turn: context.turn,
            user: action.user,
            target: action.target,
            partyIndex: partyIndex,
            itemId: action.itemId,
          )
        : PsdkBattleItemEvent.used(
            turn: context.turn,
            user: action.user,
            target: action.target,
            partyIndex: partyIndex,
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
    final partyIndex = _targetPartyIndex(context: context, action: action);
    final target = context.state.partyForBank(action.target.bank)[partyIndex];
    if (target.isFainted &&
        action.effect is! PsdkBattleReviveItemEffect &&
        action.effect is! PsdkBattlePpRestoreItemEffect) {
      throw ArgumentError.value(
        action.target,
        'target',
        'only revive and PP-restore items can target a fainted combatant',
      );
    }
  }

  int _targetPartyIndex({
    required BattleHandlerContext context,
    required PsdkBattleItemAction action,
  }) {
    final party = context.state.partyForBank(action.target.bank);
    final explicit = action.targetPartyIndex;
    if (explicit != null) {
      if (explicit < 0 || explicit >= party.length) {
        throw RangeError.range(explicit, 0, party.length - 1, 'partyIndex');
      }
      return explicit;
    }
    final active = context.state.battlerAt(action.target);
    final index = party.indexWhere((candidate) => candidate.id == active.id);
    if (index < 0) {
      throw StateError('Active battle item target is absent from its party.');
    }
    return index;
  }
}
