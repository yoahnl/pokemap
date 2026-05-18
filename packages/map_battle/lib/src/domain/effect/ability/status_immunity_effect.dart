import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_handler_result.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class StatusImmunityEffect extends BattleAbilityEffect {
  StatusImmunityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required Set<PsdkBattleMajorStatus> preventedStatuses,
    bool curesExistingStatus = true,
  })  : _preventedStatuses = Set<PsdkBattleMajorStatus>.unmodifiable(
          preventedStatuses,
        ),
        _curesExistingStatus = curesExistingStatus,
        super(abilityId: abilityId, scope: scope);

  final Set<PsdkBattleMajorStatus> _preventedStatuses;
  final bool _curesExistingStatus;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatusImmunityEffect(
      abilityId: abilityId,
      scope: scope,
      preventedStatuses: _preventedStatuses,
      curesExistingStatus: _curesExistingStatus,
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
    if (!_curesExistingStatus) {
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
    if (!_curesExistingStatus) {
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

enum StatusPreventionScope {
  owner,
  bank,
}

final class StatusPreventionAbilityEffect extends BattleAbilityEffect {
  StatusPreventionAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required Set<PsdkBattleMajorStatus> preventedStatuses,
    this.preventionScope = StatusPreventionScope.owner,
    this.requiresSunnyWeather = false,
    this.curesBankPoisonOnSwitch = false,
  })  : _preventedStatuses = Set<PsdkBattleMajorStatus>.unmodifiable(
          preventedStatuses,
        ),
        super(abilityId: abilityId, scope: scope);

  final Set<PsdkBattleMajorStatus> _preventedStatuses;
  final StatusPreventionScope preventionScope;
  final bool requiresSunnyWeather;
  final bool curesBankPoisonOnSwitch;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatusPreventionAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      preventedStatuses: _preventedStatuses,
      preventionScope: preventionScope,
      requiresSunnyWeather: requiresSunnyWeather,
      curesBankPoisonOnSwitch: curesBankPoisonOnSwitch,
    );
  }

  @override
  String? onStatusPrevention(BattleEffectStatusPreventionContext context) {
    if (!_preventsTarget(context.owner, context.target) ||
        !_preventedStatuses.contains(context.status)) {
      return null;
    }
    if (requiresSunnyWeather &&
        !context.state.field.isWeatherActive(PsdkBattleWeatherId.sunny)) {
      return null;
    }
    return 'ability:$abilityId';
  }

  @override
  bool preventsStatus(BattleAbilityStatusContext context) {
    if (preventionScope != StatusPreventionScope.owner ||
        !_preventedStatuses.contains(context.status)) {
      return false;
    }
    return !requiresSunnyWeather ||
        context.field.isWeatherActive(PsdkBattleWeatherId.sunny);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!curesBankPoisonOnSwitch || !isOwnedBy(context.replacement)) {
      return null;
    }

    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final target in context.state.aliveSlots()) {
      if (target == context.replacement ||
          target.bank != context.replacement.bank) {
        continue;
      }
      final battler = nextState.battlerAt(target);
      if (battler.majorStatus != PsdkBattleMajorStatus.poison &&
          battler.majorStatus != PsdkBattleMajorStatus.toxic) {
        continue;
      }
      final result = const BattleStatusChangeHandler().cureMajorStatus(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.replacement,
        ),
        target: target,
        moveId: 'effect:$abilityId',
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    if (!changed) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }

  bool _preventsTarget(PsdkBattleSlotRef owner, PsdkBattleSlotRef target) {
    return switch (preventionScope) {
      StatusPreventionScope.owner => owner == target,
      StatusPreventionScope.bank => owner.bank == target.bank,
    };
  }
}

final class FlowerVeilEffect extends BattleAbilityEffect {
  const FlowerVeilEffect({required BattleEffectScope scope})
      : super(abilityId: 'flower_veil', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FlowerVeilEffect(scope: scope);
  }

  @override
  String? onStatusPrevention(BattleEffectStatusPreventionContext context) {
    if (!_protectsGrassAlly(context.owner, context.target, context.state) ||
        context.user == context.target ||
        context.move?.dbSymbol == 'rest') {
      return null;
    }
    return 'ability:$abilityId';
  }

  @override
  String? onStatDecreasePrevention(
    BattleEffectStatChangePreventionContext context,
  ) {
    if (!_protectsGrassAlly(context.owner, context.target, context.state) ||
        context.user == context.target) {
      return null;
    }
    return 'ability:$abilityId';
  }

  bool _protectsGrassAlly(
    PsdkBattleSlotRef owner,
    PsdkBattleSlotRef target,
    PsdkBattleState state,
  ) {
    return owner.bank == target.bank &&
        state.battlerAt(target).hasType('grass');
  }
}

final class WaterBubbleEffect extends BattleAbilityEffect {
  const WaterBubbleEffect({required BattleEffectScope scope})
      : super(abilityId: 'water_bubble', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WaterBubbleEffect(scope: scope);
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    return context.user.abilityId == abilityId && context.moveType == 'water'
        ? 2
        : 1;
  }

  @override
  double incomingDamageBasePowerMultiplier(
    BattleAbilityDamageContext context,
  ) {
    return context.target.abilityId == abilityId && context.moveType == 'fire'
        ? 0.5
        : 1;
  }

  @override
  bool preventsStatus(BattleAbilityStatusContext context) {
    return context.target.abilityId == abilityId &&
        context.status == PsdkBattleMajorStatus.burn;
  }

  @override
  String? onStatusPrevention(BattleEffectStatusPreventionContext context) {
    if (!isOwnedBy(context.target) ||
        context.status != PsdkBattleMajorStatus.burn) {
      return null;
    }
    return 'ability:$abilityId';
  }
}

final class PurifyingSaltEffect extends BattleAbilityEffect {
  const PurifyingSaltEffect({required BattleEffectScope scope})
      : super(abilityId: 'purifying_salt', scope: scope);

  static const Set<PsdkBattleMajorStatus> _preventedStatuses =
      <PsdkBattleMajorStatus>{
    PsdkBattleMajorStatus.burn,
    PsdkBattleMajorStatus.freeze,
    PsdkBattleMajorStatus.paralysis,
    PsdkBattleMajorStatus.poison,
    PsdkBattleMajorStatus.sleep,
    PsdkBattleMajorStatus.toxic,
  };

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PurifyingSaltEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!isOwnedBy(PsdkBattleSlotRef(
          bank: context.target.bank,
          position: context.target.position,
        )) ||
        context.move.category != PsdkBattleMoveCategory.status ||
        !context.move.statuses.any((status) => status.majorStatus != null)) {
      return null;
    }
    return BattleMoveFailureReason.immunity;
  }

  @override
  double incomingDamageBasePowerMultiplier(
    BattleAbilityDamageContext context,
  ) {
    return context.target.abilityId == abilityId && context.moveType == 'ghost'
        ? 0.5
        : 1;
  }

  @override
  bool preventsStatus(BattleAbilityStatusContext context) {
    return context.target.abilityId == abilityId &&
        _preventedStatuses.contains(context.status);
  }

  @override
  String? onStatusPrevention(BattleEffectStatusPreventionContext context) {
    if (!isOwnedBy(context.target) ||
        !_preventedStatuses.contains(context.status)) {
      return null;
    }
    return 'ability:$abilityId';
  }
}
