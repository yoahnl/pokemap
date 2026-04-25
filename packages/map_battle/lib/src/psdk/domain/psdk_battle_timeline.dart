import 'psdk_battle_field.dart';
import 'psdk_battle_move.dart';
import 'psdk_battle_outcome.dart';
import 'psdk_battle_slots.dart';

class PsdkBattleTimeline {
  PsdkBattleTimeline({
    required List<PsdkBattleEvent> events,
  }) : _events = List<PsdkBattleEvent>.unmodifiable(events);

  final List<PsdkBattleEvent> _events;

  /// Immutable event stream consumed by tests and, later, runtime animation.
  List<PsdkBattleEvent> get events =>
      List<PsdkBattleEvent>.unmodifiable(_events);

  List<Map<String, Object?>> toJson() {
    return events.map((event) => event.toJson()).toList(growable: false);
  }
}

abstract class PsdkBattleEvent {
  const PsdkBattleEvent({
    required this.kind,
  });

  final String kind;

  Map<String, Object?> toJson();
}

class PsdkBattleTurnStartedEvent extends PsdkBattleEvent {
  const PsdkBattleTurnStartedEvent({
    required this.turn,
  }) : super(kind: 'turn_started');

  final int turn;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'turn': turn,
      };
}

class PsdkBattleMoveDeclaredEvent extends PsdkBattleEvent {
  const PsdkBattleMoveDeclaredEvent({
    required this.user,
    required this.target,
    required this.moveId,
    required this.moveName,
  }) : super(kind: 'move_declared');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;
  final String moveName;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'target': target.toJson(),
        'moveId': moveId,
        'moveName': moveName,
      };
}

class PsdkBattleMovePpSpentEvent extends PsdkBattleEvent {
  const PsdkBattleMovePpSpentEvent({
    required this.user,
    required this.moveId,
    required this.spent,
    required this.remainingPp,
  }) : super(kind: 'move_pp_spent');

  final PsdkBattleSlotRef user;
  final String moveId;
  final int spent;
  final int remainingPp;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'moveId': moveId,
        'spent': spent,
        'remainingPp': remainingPp,
      };
}

class PsdkBattleMoveFailedEvent extends PsdkBattleEvent {
  const PsdkBattleMoveFailedEvent({
    required this.user,
    this.target,
    required this.moveId,
    required this.reason,
  }) : super(kind: 'move_failed');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef? target;
  final String moveId;
  final String reason;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        if (target != null) 'target': target!.toJson(),
        'moveId': moveId,
        'reason': reason,
      };
}

class PsdkBattleAnimationCueEvent extends PsdkBattleEvent {
  const PsdkBattleAnimationCueEvent({
    required this.user,
    required this.target,
    required this.moveId,
  }) : super(kind: 'animation_cue');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'target': target.toJson(),
        'moveId': moveId,
      };
}

class PsdkBattleDamageEvent extends PsdkBattleEvent {
  const PsdkBattleDamageEvent({
    required this.user,
    required this.target,
    required this.moveId,
    required this.damage,
    required this.remainingHp,
  }) : super(kind: 'damage');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;
  final int damage;
  final int remainingHp;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'target': target.toJson(),
        'moveId': moveId,
        'damage': damage,
        'remainingHp': remainingHp,
      };
}

class PsdkBattleHealEvent extends PsdkBattleEvent {
  const PsdkBattleHealEvent({
    required this.user,
    required this.target,
    required this.moveId,
    required this.amount,
    required this.remainingHp,
  }) : super(kind: 'heal');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;
  final int amount;
  final int remainingHp;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'target': target.toJson(),
        'moveId': moveId,
        'amount': amount,
        'remainingHp': remainingHp,
      };
}

class PsdkBattleStatusEvent extends PsdkBattleEvent {
  const PsdkBattleStatusEvent({
    required this.user,
    required this.target,
    required this.moveId,
    required this.status,
  }) : super(kind: 'status');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;
  final PsdkBattleMajorStatus status;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'target': target.toJson(),
        'moveId': moveId,
        'status': status.name,
      };
}

class PsdkBattleStatusCureEvent extends PsdkBattleEvent {
  const PsdkBattleStatusCureEvent({
    required this.user,
    required this.target,
    required this.moveId,
    required this.status,
  }) : super(kind: 'status_cure');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;
  final PsdkBattleMajorStatus status;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'target': target.toJson(),
        'moveId': moveId,
        'status': status.name,
      };
}

class PsdkBattleStatStageEvent extends PsdkBattleEvent {
  const PsdkBattleStatStageEvent({
    required this.target,
    required this.stat,
    required this.amount,
    required this.currentStage,
  }) : super(kind: 'stat_stage_change');

  final PsdkBattleSlotRef target;
  final String stat;
  final int amount;
  final int currentStage;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'target': target.toJson(),
        'stat': stat,
        'amount': amount,
        'currentStage': currentStage,
      };
}

class PsdkBattleMissEvent extends PsdkBattleEvent {
  const PsdkBattleMissEvent({
    required this.user,
    required this.target,
    required this.moveId,
  }) : super(kind: 'miss');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'target': target.toJson(),
        'moveId': moveId,
      };
}

class PsdkBattleImmuneEvent extends PsdkBattleEvent {
  const PsdkBattleImmuneEvent({
    required this.user,
    required this.target,
    required this.moveId,
  }) : super(kind: 'move_immune');

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String moveId;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'user': user.toJson(),
        'target': target.toJson(),
        'moveId': moveId,
      };
}

class PsdkBattleWeatherChangedEvent extends PsdkBattleEvent {
  const PsdkBattleWeatherChangedEvent({
    this.turn,
    required this.weather,
    this.remainingTurns,
    this.reason = 'set',
  }) : super(kind: 'weather_changed');

  final int? turn;
  final PsdkBattleWeatherId? weather;
  final int? remainingTurns;
  final String reason;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        if (turn != null) 'turn': turn,
        'weather': weather?.jsonName,
        if (remainingTurns != null) 'remainingTurns': remainingTurns,
        'reason': reason,
      };
}

class PsdkBattleTerrainChangedEvent extends PsdkBattleEvent {
  const PsdkBattleTerrainChangedEvent({
    this.turn,
    required this.terrain,
    this.remainingTurns,
    this.reason = 'set',
  }) : super(kind: 'terrain_changed');

  final int? turn;
  final PsdkBattleTerrainId? terrain;
  final int? remainingTurns;
  final String reason;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        if (turn != null) 'turn': turn,
        'terrain': terrain?.jsonName,
        if (remainingTurns != null) 'remainingTurns': remainingTurns,
        'reason': reason,
      };
}

class PsdkBattleItemEvent extends PsdkBattleEvent {
  const PsdkBattleItemEvent.consumed({
    this.turn,
    required this.user,
    required this.itemId,
  })  : action = 'consumed',
        super(kind: 'item_consumed');

  final int? turn;
  final PsdkBattleSlotRef user;
  final String itemId;
  final String action;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        if (turn != null) 'turn': turn,
        'user': user.toJson(),
        'itemId': itemId,
        'action': action,
      };
}

class PsdkBattleEndedEvent extends PsdkBattleEvent {
  const PsdkBattleEndedEvent({
    required this.outcome,
  }) : super(kind: 'battle_ended');

  final PsdkBattleOutcome outcome;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind,
        'outcome': outcome.kind.name,
      };
}
