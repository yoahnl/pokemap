import '../../psdk/domain/psdk_battle_move.dart';

final class PsdkMoveScore {
  const PsdkMoveScore({
    required this.moveSlot,
    required this.move,
    required this.value,
    required this.isUsable,
    required this.estimatedDamage,
    required this.effectiveness,
    required this.utilityScore,
    this.preventedReason,
  });

  final int moveSlot;
  final PsdkBattleMoveData move;
  final double value;
  final bool isUsable;
  final int estimatedDamage;
  final double effectiveness;
  final double utilityScore;
  final String? preventedReason;

  bool get isImmune => effectiveness == 0.0;
  bool get isKo => isUsable && estimatedDamage > 0 && value >= 10000;
}

final class PsdkBattleAiMoveChoice {
  const PsdkBattleAiMoveChoice({
    required this.moveSlot,
    required this.move,
    required this.score,
  });

  final int moveSlot;
  final PsdkBattleMoveData move;
  final PsdkMoveScore score;
}
