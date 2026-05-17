import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_handler_result.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class StatusImmunityEffect extends BattleAbilityEffect {
  StatusImmunityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required Set<PsdkBattleMajorStatus> preventedStatuses,
  })  : _preventedStatuses = Set<PsdkBattleMajorStatus>.unmodifiable(
          preventedStatuses,
        ),
        super(abilityId: abilityId, scope: scope);

  final Set<PsdkBattleMajorStatus> _preventedStatuses;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatusImmunityEffect(
      abilityId: abilityId,
      scope: scope,
      preventedStatuses: _preventedStatuses,
    );
  }

  @override
  bool preventsStatus(BattleAbilityStatusContext context) {
    return _preventedStatuses.contains(context.status);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!isOwnedBy(context.replacement)) {
      return null;
    }
    final result = _cureIfNeeded(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.replacement,
      ),
      target: context.replacement,
      moveId: 'effect:$abilityId',
    );
    if (result == null) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  @override
  BattleEffectStatusChangeResult? onPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    if (context.cured || !isOwnedBy(context.target)) {
      return null;
    }
    final result = _cureIfNeeded(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: context.target,
      moveId: 'effect:$abilityId',
    );
    if (result == null) {
      return null;
    }
    return BattleEffectStatusChangeResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  BattleHandlerResult? _cureIfNeeded({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String moveId,
  }) {
    final battler = context.state.battlerAt(target);
    final status = battler.majorStatus;
    if (status == null || !_preventedStatuses.contains(status)) {
      return null;
    }

    final result = const BattleStatusChangeHandler().cureMajorStatus(
      context: context,
      target: target,
      moveId: moveId,
    );
    if (!result.applied) {
      return null;
    }
    return result;
  }
}
