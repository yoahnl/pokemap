import '../battle/battle_slot.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_prevention.dart';

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
