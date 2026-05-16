import '../battle/battle_slot.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_prevention.dart';
import '../rng/battle_rng_streams.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';

/// Minimal hook context for move-target prevention.
///
/// The full Pokemon SDK effect surface is much larger. FIGHT-03 introduces the
/// smallest hook shape needed to move Protect out of string-only checks without
/// pretending that damage/status/weather handlers already exist.
final class BattleEffectMoveContext {
  const BattleEffectMoveContext({
    required this.user,
    required this.target,
    required this.move,
  });

  final BattlePositionRef user;
  final BattlePositionRef target;
  final BattleMoveDefinition move;
}

final class BattleEffectPreventionResult {
  const BattleEffectPreventionResult({
    required this.reason,
  });

  final BattleMoveFailureReason reason;
}

/// Hook result for effects that can stop their owner before a move executes.
final class BattleEffectUserMovePreventionResult {
  const BattleEffectUserMovePreventionResult({
    required this.state,
    required this.rng,
    required this.prevented,
    required this.reason,
    this.recordAttempt = true,
    this.events = const <PsdkBattleEvent>[],
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final bool prevented;
  final BattleMoveFailureReason reason;
  final bool recordAttempt;
  final List<PsdkBattleEvent> events;
}

/// Hook context for effects tied to the move user.
final class BattleEffectUserMovePreventionContext {
  const BattleEffectUserMovePreventionContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
    required this.target,
    required this.move,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final BattleMoveDefinition move;
}

/// Hook context for effects that tick during the PSDK end-turn phase.
final class BattleEffectEndTurnContext {
  const BattleEffectEndTurnContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
}

final class BattleEffectEndTurnResult {
  const BattleEffectEndTurnResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
    this.applied = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
}

final class BattleEffectDamagePreventionContext {
  const BattleEffectDamagePreventionContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
    required this.user,
    required this.target,
    required this.move,
    required this.damage,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final BattleMoveDefinition move;
  final int damage;
}

final class BattleEffectDamagePreventionResult {
  const BattleEffectDamagePreventionResult({
    required this.state,
    required this.rng,
    required this.prevented,
    required this.reason,
    this.events = const <PsdkBattleEvent>[],
    this.applied = true,
    this.amount = 0,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final bool prevented;
  final BattleMoveFailureReason reason;
  final List<PsdkBattleEvent> events;
  final bool applied;
  final int amount;
}

final class BattleEffectPostDamageContext {
  const BattleEffectPostDamageContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
    required this.user,
    required this.target,
    required this.move,
    required this.damage,
    this.targetFainted = false,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final BattleMoveDefinition move;
  final int damage;
  final bool targetFainted;
}

final class BattleEffectPostDamageResult {
  const BattleEffectPostDamageResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
    this.applied = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
}

enum BattleEffectLifecyclePhase {
  added,
  removed,
  refreshed,
}

final class BattleEffectLifecycleContext {
  const BattleEffectLifecycleContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
    required this.phase,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
  final BattleEffectLifecyclePhase phase;
}

final class BattleEffectLifecycleResult {
  const BattleEffectLifecycleResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
    this.applied = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
}

final class BattleEffectBatonPassContext {
  const BattleEffectBatonPassContext({
    required this.source,
    required this.target,
  });

  final PsdkBattleSlotRef source;
  final PsdkBattleSlotRef target;
}

final class BattleEffectSwitchPreventionContext {
  const BattleEffectSwitchPreventionContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.target,
    this.move,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef target;
  final BattleMoveDefinition? move;
}

final class BattleEffectSwitchEventContext {
  const BattleEffectSwitchEventContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
    required this.who,
    required this.replacement,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
  final PsdkBattleSlotRef who;
  final PsdkBattleSlotRef replacement;
}

final class BattleEffectSwitchEventResult {
  const BattleEffectSwitchEventResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
    this.applied = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
}

final class BattleEffectStatChangePreventionContext {
  const BattleEffectStatChangePreventionContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
    required this.user,
    required this.target,
    required this.stat,
    required this.stages,
    this.move,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String stat;
  final int stages;
  final BattleMoveDefinition? move;
}

final class BattleEffectStatChangeContext {
  const BattleEffectStatChangeContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
    required this.user,
    required this.target,
    required this.stat,
    required this.stages,
    this.move,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final String stat;
  final int stages;
  final BattleMoveDefinition? move;
}

final class BattleEffectStatChangePostResult {
  const BattleEffectStatChangePostResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
    this.applied = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
}

final class BattleEffectStatusPreventionContext {
  const BattleEffectStatusPreventionContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
    required this.user,
    required this.target,
    required this.status,
    this.move,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final PsdkBattleMajorStatus status;
  final BattleMoveDefinition? move;
}

final class BattleEffectStatusChangeContext {
  const BattleEffectStatusChangeContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.owner,
    required this.user,
    required this.target,
    required this.status,
    required this.cured,
    this.move,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef owner;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final PsdkBattleMajorStatus status;
  final bool cured;
  final BattleMoveDefinition? move;
}

final class BattleEffectStatusChangeResult {
  const BattleEffectStatusChangeResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
    this.applied = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
}
