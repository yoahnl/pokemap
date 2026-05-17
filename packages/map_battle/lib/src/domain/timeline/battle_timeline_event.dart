import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_outcome.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../battle/battle_slot.dart';

/// Clean, runtime-agnostic event emitted by the PSDK battle lane.
///
/// Events carry stable ids and bank/position refs. They never carry Flutter,
/// Flame, sprite or scene objects, which keeps the battle package pure Dart and
/// lets runtime animation consume the stream later.
sealed class BattleTimelineEvent {
  const BattleTimelineEvent({
    required this.kind,
    this.turn,
  });

  final String kind;
  final int? turn;

  Map<String, Object?> toJson();

  PsdkBattleEvent? toPsdkEvent();

  static BattleTimelineEvent fromPsdk(PsdkBattleEvent event) {
    if (event is PsdkBattleTurnStartedEvent) {
      return BattleTurnStartedTimelineEvent(turn: event.turn);
    }
    if (event is PsdkBattleMoveDeclaredEvent) {
      return BattleMoveDeclaredTimelineEvent(
        user: _fromPsdkSlot(event.user),
        targets: <BattlePositionRef>[_fromPsdkSlot(event.target)],
        moveId: event.moveId,
        moveName: event.moveName,
      );
    }
    if (event is PsdkBattleMovePpSpentEvent) {
      return BattleMovePpSpentTimelineEvent(
        user: _fromPsdkSlot(event.user),
        moveId: event.moveId,
        spent: event.spent,
        remainingPp: event.remainingPp,
      );
    }
    if (event is PsdkBattleMoveFailedEvent) {
      return BattleMoveFailedTimelineEvent(
        user: _fromPsdkSlot(event.user),
        target: event.target == null ? null : _fromPsdkSlot(event.target!),
        moveId: event.moveId,
        reason: event.reason,
      );
    }
    if (event is PsdkBattleAnimationCueEvent) {
      return BattleAnimationCueTimelineEvent(
        user: _fromPsdkSlot(event.user),
        targets: <BattlePositionRef>[_fromPsdkSlot(event.target)],
        moveId: event.moveId,
      );
    }
    if (event is PsdkBattleDamageEvent) {
      return BattleDamageTimelineEvent(
        user: _fromPsdkSlot(event.user),
        target: _fromPsdkSlot(event.target),
        moveId: event.moveId,
        damage: event.damage,
        remainingHp: event.remainingHp,
      );
    }
    if (event is PsdkBattleHealEvent) {
      return BattleHealTimelineEvent(
        user: _fromPsdkSlot(event.user),
        target: _fromPsdkSlot(event.target),
        moveId: event.moveId,
        amount: event.amount,
        remainingHp: event.remainingHp,
      );
    }
    if (event is PsdkBattleStatusEvent) {
      return BattleStatusChangeTimelineEvent(
        user: _fromPsdkSlot(event.user),
        target: _fromPsdkSlot(event.target),
        moveId: event.moveId,
        status: event.status,
      );
    }
    if (event is PsdkBattleStatusCureEvent) {
      return BattleStatusCureTimelineEvent(
        user: _fromPsdkSlot(event.user),
        target: _fromPsdkSlot(event.target),
        moveId: event.moveId,
        status: event.status,
      );
    }
    if (event is PsdkBattleStatStageEvent) {
      return BattleStatStageChangeTimelineEvent(
        target: _fromPsdkSlot(event.target),
        stat: event.stat,
        amount: event.amount,
        currentStage: event.currentStage,
      );
    }
    if (event is PsdkBattleEffectEvent) {
      return switch (event.kind) {
        'effect_added' => BattleEffectTimelineEvent.added(
            turn: event.turn,
            target: _fromPsdkSlot(event.target),
            effectId: event.effectId,
            remainingTurns: event.remainingTurns,
            reason: event.reason,
          ),
        'effect_removed' => BattleEffectTimelineEvent.removed(
            turn: event.turn,
            target: _fromPsdkSlot(event.target),
            effectId: event.effectId,
            remainingTurns: event.remainingTurns,
            reason: event.reason,
          ),
        'effect_ticked' => BattleEffectTimelineEvent.ticked(
            turn: event.turn,
            target: _fromPsdkSlot(event.target),
            effectId: event.effectId,
            remainingTurns: event.remainingTurns,
            reason: event.reason,
          ),
        _ => throw UnsupportedError(
            'Unsupported PSDK battle effect event ${event.kind}.',
          ),
      };
    }
    if (event is PsdkBattleMissEvent) {
      return BattleMoveMissedTimelineEvent(
        user: _fromPsdkSlot(event.user),
        target: _fromPsdkSlot(event.target),
        moveId: event.moveId,
      );
    }
    if (event is PsdkBattleImmuneEvent) {
      return BattleMoveImmuneTimelineEvent(
        user: _fromPsdkSlot(event.user),
        target: _fromPsdkSlot(event.target),
        moveId: event.moveId,
      );
    }
    if (event is PsdkBattleWeatherChangedEvent) {
      return BattleWeatherChangedTimelineEvent(
        turn: event.turn,
        weatherId: event.weather?.jsonName,
        remainingTurns: event.remainingTurns,
        reason: event.reason,
      );
    }
    if (event is PsdkBattleTerrainChangedEvent) {
      return BattleTerrainChangedTimelineEvent(
        turn: event.turn,
        terrainId: event.terrain?.jsonName,
        remainingTurns: event.remainingTurns,
        reason: event.reason,
      );
    }
    if (event is PsdkBattleItemEvent) {
      return BattleItemTimelineEvent.consumed(
        turn: event.turn,
        user: _fromPsdkSlot(event.user),
        target: event.target == null ? null : _fromPsdkSlot(event.target!),
        itemId: event.itemId,
      );
    }
    if (event is PsdkBattleEndedEvent) {
      return BattleEndedTimelineEvent(outcome: event.outcome);
    }
    throw UnsupportedError('Unsupported PSDK battle timeline event $event.');
  }

  Map<String, Object?> baseJson() {
    return <String, Object?>{
      'kind': kind,
      if (turn != null) 'turn': turn,
    };
  }
}

enum BattleMoveProcedureStage {
  userAlive,
  resolveTargets,
  usableByUser,
  usage,
  preAccuracy,
  noTarget,
  accuracy,
  remap,
  immunity,
  postAccuracy,
  postAccuracyMove,
  animation,
  damage,
  effectBody,
  status,
  stats,
  effects,
  history,
  cleanup,
}

/// Optional trace event for validating the Dart order against Pokemon SDK.
///
/// The event deliberately does not convert to a PSDK event. It is a diagnostic
/// guardrail for tests and future ports, not an animation/runtime contract.
final class BattleMoveProcedureTraceEvent extends BattleTimelineEvent {
  const BattleMoveProcedureTraceEvent({
    required int turn,
    required this.moveId,
    required this.stage,
  }) : super(kind: 'move_procedure_stage', turn: turn);

  final String moveId;
  final BattleMoveProcedureStage stage;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'moveId': moveId,
      'stage': stage.name,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleTurnStartedTimelineEvent extends BattleTimelineEvent {
  const BattleTurnStartedTimelineEvent({
    required int turn,
  }) : super(kind: 'turn_started', turn: turn);

  @override
  Map<String, Object?> toJson() => baseJson();

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleTurnStartedEvent(turn: turn!);
  }
}

final class BattleTurnEndedTimelineEvent extends BattleTimelineEvent {
  const BattleTurnEndedTimelineEvent({
    required int turn,
  }) : super(kind: 'turn_ended', turn: turn);

  @override
  Map<String, Object?> toJson() => baseJson();

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleDecisionRequestedTimelineEvent extends BattleTimelineEvent {
  BattleDecisionRequestedTimelineEvent({
    required int turn,
    required this.actor,
    List<String> allowedDecisions = const <String>[],
  })  : allowedDecisions = List<String>.unmodifiable(allowedDecisions),
        super(kind: 'decision_requested', turn: turn);

  final BattlePositionRef actor;
  final List<String> allowedDecisions;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'actor': _slotJson(actor),
      'allowedDecisions': allowedDecisions,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleActionStartedTimelineEvent extends BattleTimelineEvent {
  const BattleActionStartedTimelineEvent({
    required int turn,
    required this.actor,
    required this.actionKind,
  }) : super(kind: 'action_started', turn: turn);

  final BattlePositionRef actor;
  final String actionKind;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'actor': _slotJson(actor),
      'actionKind': actionKind,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleActionEndedTimelineEvent extends BattleTimelineEvent {
  const BattleActionEndedTimelineEvent({
    required int turn,
    required this.actor,
    required this.actionKind,
  }) : super(kind: 'action_ended', turn: turn);

  final BattlePositionRef actor;
  final String actionKind;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'actor': _slotJson(actor),
      'actionKind': actionKind,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleMoveDeclaredTimelineEvent extends BattleTimelineEvent {
  BattleMoveDeclaredTimelineEvent({
    int? turn,
    required this.user,
    required List<BattlePositionRef> targets,
    required this.moveId,
    required this.moveName,
    this.moveDbSymbol,
  })  : targets = List<BattlePositionRef>.unmodifiable(targets),
        super(kind: 'move_declared', turn: turn);

  final BattlePositionRef user;
  final List<BattlePositionRef> targets;
  final String moveId;
  final String moveName;
  final String? moveDbSymbol;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      if (targets.length == 1) 'target': _slotJson(targets.single),
      if (targets.length != 1) 'targets': _slotsJson(targets),
      'moveId': moveId,
      'moveName': moveName,
      if (moveDbSymbol != null) 'moveDbSymbol': moveDbSymbol,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() {
    if (targets.isEmpty) {
      return null;
    }
    return PsdkBattleMoveDeclaredEvent(
      user: _toPsdkSlot(user),
      target: _toPsdkSlot(targets.first),
      moveId: moveId,
      moveName: moveName,
    );
  }
}

final class BattleMovePpSpentTimelineEvent extends BattleTimelineEvent {
  const BattleMovePpSpentTimelineEvent({
    int? turn,
    required this.user,
    required this.moveId,
    required this.spent,
    required this.remainingPp,
  }) : super(kind: 'move_pp_spent', turn: turn);

  final BattlePositionRef user;
  final String moveId;
  final int spent;
  final int remainingPp;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      'moveId': moveId,
      'spent': spent,
      'remainingPp': remainingPp,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleMovePpSpentEvent(
      user: _toPsdkSlot(user),
      moveId: moveId,
      spent: spent,
      remainingPp: remainingPp,
    );
  }
}

final class BattleMoveFailedTimelineEvent extends BattleTimelineEvent {
  const BattleMoveFailedTimelineEvent({
    int? turn,
    required this.user,
    this.target,
    required this.moveId,
    required this.reason,
  }) : super(kind: 'move_failed', turn: turn);

  final BattlePositionRef user;
  final BattlePositionRef? target;
  final String moveId;
  final String reason;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      if (target != null) 'target': _slotJson(target!),
      'moveId': moveId,
      'reason': reason,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleMoveFailedEvent(
      user: _toPsdkSlot(user),
      target: target == null ? null : _toPsdkSlot(target!),
      moveId: moveId,
      reason: reason,
    );
  }
}

final class BattleMoveMissedTimelineEvent extends BattleTimelineEvent {
  const BattleMoveMissedTimelineEvent({
    int? turn,
    required this.user,
    required this.target,
    required this.moveId,
  }) : super(kind: 'miss', turn: turn);

  final BattlePositionRef user;
  final BattlePositionRef target;
  final String moveId;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      'target': _slotJson(target),
      'moveId': moveId,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleMissEvent(
      user: _toPsdkSlot(user),
      target: _toPsdkSlot(target),
      moveId: moveId,
    );
  }
}

final class BattleMoveImmuneTimelineEvent extends BattleTimelineEvent {
  const BattleMoveImmuneTimelineEvent({
    int? turn,
    required this.user,
    required this.target,
    required this.moveId,
  }) : super(kind: 'move_immune', turn: turn);

  final BattlePositionRef user;
  final BattlePositionRef target;
  final String moveId;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      'target': _slotJson(target),
      'moveId': moveId,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleImmuneEvent(
      user: _toPsdkSlot(user),
      target: _toPsdkSlot(target),
      moveId: moveId,
    );
  }
}

final class BattleAnimationCueTimelineEvent extends BattleTimelineEvent {
  BattleAnimationCueTimelineEvent({
    int? turn,
    required this.user,
    required List<BattlePositionRef> targets,
    required this.moveId,
    this.animationId,
  })  : targets = List<BattlePositionRef>.unmodifiable(targets),
        super(kind: 'animation_cue', turn: turn);

  final BattlePositionRef user;
  final List<BattlePositionRef> targets;
  final String moveId;
  final String? animationId;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      if (targets.length == 1) 'target': _slotJson(targets.single),
      if (targets.length != 1) 'targets': _slotsJson(targets),
      'moveId': moveId,
      if (animationId != null) 'animationId': animationId,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() {
    if (targets.isEmpty) {
      return null;
    }
    return PsdkBattleAnimationCueEvent(
      user: _toPsdkSlot(user),
      target: _toPsdkSlot(targets.first),
      moveId: moveId,
    );
  }
}

final class BattleDamageTimelineEvent extends BattleTimelineEvent {
  const BattleDamageTimelineEvent({
    int? turn,
    required this.user,
    required this.target,
    required this.moveId,
    required this.damage,
    required this.remainingHp,
    this.maxHp,
    this.effectiveness,
    this.critical,
  }) : super(kind: 'damage', turn: turn);

  final BattlePositionRef user;
  final BattlePositionRef target;
  final String moveId;
  final int damage;
  final int remainingHp;
  final int? maxHp;
  final double? effectiveness;
  final bool? critical;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      'target': _slotJson(target),
      'moveId': moveId,
      'damage': damage,
      'remainingHp': remainingHp,
      if (maxHp != null) 'maxHp': maxHp,
      if (effectiveness != null) 'effectiveness': effectiveness,
      if (critical != null) 'critical': critical,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleDamageEvent(
      user: _toPsdkSlot(user),
      target: _toPsdkSlot(target),
      moveId: moveId,
      damage: damage,
      remainingHp: remainingHp,
    );
  }
}

final class BattleHealTimelineEvent extends BattleTimelineEvent {
  const BattleHealTimelineEvent({
    int? turn,
    this.user,
    required this.target,
    this.moveId,
    required this.amount,
    required this.remainingHp,
    this.maxHp,
    this.source,
  }) : super(kind: 'heal', turn: turn);

  final BattlePositionRef? user;
  final BattlePositionRef target;
  final String? moveId;
  final int amount;
  final int remainingHp;
  final int? maxHp;
  final String? source;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      if (user != null) 'user': _slotJson(user!),
      'target': _slotJson(target),
      if (moveId != null) 'moveId': moveId,
      'amount': amount,
      'remainingHp': remainingHp,
      if (maxHp != null) 'maxHp': maxHp,
      if (source != null) 'source': source,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() {
    final user = this.user;
    final moveId = this.moveId;
    if (user == null || moveId == null) {
      return null;
    }
    return PsdkBattleHealEvent(
      user: _toPsdkSlot(user),
      target: _toPsdkSlot(target),
      moveId: moveId,
      amount: amount,
      remainingHp: remainingHp,
    );
  }
}

final class BattleStatusChangeTimelineEvent extends BattleTimelineEvent {
  const BattleStatusChangeTimelineEvent({
    int? turn,
    required this.user,
    required this.target,
    required this.moveId,
    required this.status,
  }) : super(kind: 'status', turn: turn);

  final BattlePositionRef user;
  final BattlePositionRef target;
  final String moveId;
  final PsdkBattleMajorStatus status;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      'target': _slotJson(target),
      'moveId': moveId,
      'status': status.name,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleStatusEvent(
      user: _toPsdkSlot(user),
      target: _toPsdkSlot(target),
      moveId: moveId,
      status: status,
    );
  }
}

final class BattleStatusCureTimelineEvent extends BattleTimelineEvent {
  const BattleStatusCureTimelineEvent({
    int? turn,
    required this.user,
    required this.target,
    required this.moveId,
    required this.status,
  }) : super(kind: 'status_cure', turn: turn);

  final BattlePositionRef user;
  final BattlePositionRef target;
  final String moveId;
  final PsdkBattleMajorStatus status;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      'target': _slotJson(target),
      'moveId': moveId,
      'status': status.name,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleStatusCureEvent(
      user: _toPsdkSlot(user),
      target: _toPsdkSlot(target),
      moveId: moveId,
      status: status,
    );
  }
}

final class BattleStatStageChangeTimelineEvent extends BattleTimelineEvent {
  const BattleStatStageChangeTimelineEvent({
    int? turn,
    required this.target,
    required this.stat,
    required this.amount,
    required this.currentStage,
  }) : super(kind: 'stat_stage_change', turn: turn);

  final BattlePositionRef target;
  final String stat;
  final int amount;
  final int currentStage;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'target': _slotJson(target),
      'stat': stat,
      'amount': amount,
      'currentStage': currentStage,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleStatStageEvent(
      target: _toPsdkSlot(target),
      stat: stat,
      amount: amount,
      currentStage: currentStage,
    );
  }
}

final class BattleEffectTimelineEvent extends BattleTimelineEvent {
  const BattleEffectTimelineEvent.added({
    int? turn,
    required this.target,
    required this.effectId,
    this.remainingTurns,
    this.reason = 'set',
  }) : super(kind: 'effect_added', turn: turn);

  const BattleEffectTimelineEvent.removed({
    int? turn,
    required this.target,
    required this.effectId,
    this.remainingTurns,
    this.reason = 'removed',
  }) : super(kind: 'effect_removed', turn: turn);

  const BattleEffectTimelineEvent.ticked({
    int? turn,
    required this.target,
    required this.effectId,
    this.remainingTurns,
    this.reason = 'duration_tick',
  }) : super(kind: 'effect_ticked', turn: turn);

  final BattlePositionRef target;
  final String effectId;
  final int? remainingTurns;
  final String reason;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'target': _slotJson(target),
      'effectId': effectId,
      if (remainingTurns != null) 'remainingTurns': remainingTurns,
      'reason': reason,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    final psdkTarget = _toPsdkSlot(target);
    return switch (kind) {
      'effect_added' => PsdkBattleEffectEvent.added(
          turn: turn,
          target: psdkTarget,
          effectId: effectId,
          remainingTurns: remainingTurns,
          reason: reason,
        ),
      'effect_removed' => PsdkBattleEffectEvent.removed(
          turn: turn,
          target: psdkTarget,
          effectId: effectId,
          remainingTurns: remainingTurns,
          reason: reason,
        ),
      'effect_ticked' => PsdkBattleEffectEvent.ticked(
          turn: turn,
          target: psdkTarget,
          effectId: effectId,
          remainingTurns: remainingTurns,
          reason: reason,
        ),
      _ => throw UnsupportedError('Unsupported effect timeline event $kind.'),
    };
  }
}

final class BattleSwitchOutTimelineEvent extends BattleTimelineEvent {
  const BattleSwitchOutTimelineEvent({
    int? turn,
    required this.battler,
  }) : super(kind: 'switch_out', turn: turn);

  final BattlePositionRef battler;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'battler': _slotJson(battler),
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleSwitchInTimelineEvent extends BattleTimelineEvent {
  const BattleSwitchInTimelineEvent({
    int? turn,
    required this.battler,
  }) : super(kind: 'switch_in', turn: turn);

  final BattlePositionRef battler;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'battler': _slotJson(battler),
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleItemTimelineEvent extends BattleTimelineEvent {
  const BattleItemTimelineEvent.used({
    int? turn,
    required this.itemId,
    required this.user,
    this.target,
  }) : super(kind: 'item_used', turn: turn);

  const BattleItemTimelineEvent.consumed({
    int? turn,
    required this.itemId,
    required this.user,
    this.target,
  }) : super(kind: 'item_consumed', turn: turn);

  final String itemId;
  final BattlePositionRef user;
  final BattlePositionRef? target;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'itemId': itemId,
      'user': _slotJson(user),
      if (target != null) 'target': _slotJson(target!),
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() {
    if (kind != 'item_consumed') {
      return null;
    }
    return PsdkBattleItemEvent.consumed(
      turn: turn,
      user: _toPsdkSlot(user),
      itemId: itemId,
    );
  }
}

final class BattleAbilityTriggeredTimelineEvent extends BattleTimelineEvent {
  const BattleAbilityTriggeredTimelineEvent({
    int? turn,
    required this.user,
    required this.abilityId,
  }) : super(kind: 'ability_triggered', turn: turn);

  final BattlePositionRef user;
  final String abilityId;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'user': _slotJson(user),
      'abilityId': abilityId,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleWeatherChangedTimelineEvent extends BattleTimelineEvent {
  const BattleWeatherChangedTimelineEvent({
    int? turn,
    required this.weatherId,
    this.remainingTurns,
    this.reason = 'set',
  }) : super(kind: 'weather_changed', turn: turn);

  final String? weatherId;
  final int? remainingTurns;
  final String reason;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'weatherId': weatherId,
      if (remainingTurns != null) 'remainingTurns': remainingTurns,
      'reason': reason,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleWeatherChangedEvent(
      turn: turn,
      weather: _weatherFromJsonName(weatherId),
      remainingTurns: remainingTurns,
      reason: reason,
    );
  }
}

final class BattleTerrainChangedTimelineEvent extends BattleTimelineEvent {
  const BattleTerrainChangedTimelineEvent({
    int? turn,
    required this.terrainId,
    this.remainingTurns,
    this.reason = 'set',
  }) : super(kind: 'terrain_changed', turn: turn);

  final String? terrainId;
  final int? remainingTurns;
  final String reason;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'terrainId': terrainId,
      if (remainingTurns != null) 'remainingTurns': remainingTurns,
      'reason': reason,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleTerrainChangedEvent(
      turn: turn,
      terrain: _terrainFromJsonName(terrainId),
      remainingTurns: remainingTurns,
      reason: reason,
    );
  }
}

final class BattleCaptureAttemptTimelineEvent extends BattleTimelineEvent {
  const BattleCaptureAttemptTimelineEvent({
    int? turn,
    required this.target,
    required this.ballId,
    required this.shakes,
    required this.caught,
  }) : super(kind: 'capture_attempt', turn: turn);

  final BattlePositionRef target;
  final String ballId;
  final int shakes;
  final bool caught;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'target': _slotJson(target),
      'ballId': ballId,
      'shakes': shakes,
      'caught': caught,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleFleeAttemptTimelineEvent extends BattleTimelineEvent {
  const BattleFleeAttemptTimelineEvent({
    int? turn,
    required this.actor,
    required this.succeeded,
  }) : super(kind: 'flee_attempt', turn: turn);

  final BattlePositionRef actor;
  final bool succeeded;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'actor': _slotJson(actor),
      'succeeded': succeeded,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}

final class BattleEndedTimelineEvent extends BattleTimelineEvent {
  const BattleEndedTimelineEvent({
    int? turn,
    required this.outcome,
  }) : super(kind: 'battle_ended', turn: turn);

  final PsdkBattleOutcome outcome;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'outcome': outcome.kind.name,
    };
  }

  @override
  PsdkBattleEvent toPsdkEvent() {
    return PsdkBattleEndedEvent(outcome: outcome);
  }
}

BattlePositionRef _fromPsdkSlot(PsdkBattleSlotRef slot) {
  return BattlePositionRef(bank: slot.bank, position: slot.position);
}

PsdkBattleSlotRef _toPsdkSlot(BattlePositionRef slot) {
  return PsdkBattleSlotRef(bank: slot.bank, position: slot.position);
}

Map<String, Object?> _slotJson(BattlePositionRef slot) {
  return <String, Object?>{
    'bank': slot.bank,
    'position': slot.position,
  };
}

List<Map<String, Object?>> _slotsJson(Iterable<BattlePositionRef> slots) {
  return slots.map(_slotJson).toList(growable: false);
}

PsdkBattleWeatherId? _weatherFromJsonName(String? value) {
  if (value == null) {
    return null;
  }
  for (final weather in PsdkBattleWeatherId.values) {
    if (weather.jsonName == value) {
      return weather;
    }
  }
  return null;
}

PsdkBattleTerrainId? _terrainFromJsonName(String? value) {
  if (value == null) {
    return null;
  }
  for (final terrain in PsdkBattleTerrainId.values) {
    if (terrain.jsonName == value) {
      return terrain;
    }
  }
  return null;
}
