import '../battle/battle_slot.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_prevention.dart';
import '../rng/battle_rng_streams.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
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
