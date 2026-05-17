import '../../../psdk/domain/psdk_battle_move.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// Bank-scoped protection for PSDK doubles guard moves.
///
/// Pokemon SDK models these as short-lived side effects observed by every
/// incoming target check. The Dart battle lane keeps the same shape by storing
/// the effect on the user while its scope names the protected bank.
sealed class DoublesGuardEffect extends BattleEffect {
  const DoublesGuardEffect({
    required super.id,
    required BankBattleEffectScope super.scope,
  }) : super(remainingTurns: 0);

  @override
  BankBattleEffectScope get scope => super.scope as BankBattleEffectScope;

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (context.user == context.target || context.target.bank != scope.bank) {
      return null;
    }
    return blocks(context.move) ? BattleMoveFailureReason.protected : null;
  }

  bool blocks(BattleMoveDefinition move);
}

final class WideGuardEffect extends DoublesGuardEffect {
  const WideGuardEffect({
    required BankBattleEffectScope scope,
  }) : super(id: 'wide_guard', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WideGuardEffect(scope: scope);
  }

  @override
  bool blocks(BattleMoveDefinition move) {
    return move.flags.protectable && !_isOneTargetMove(move.target);
  }
}

final class QuickGuardEffect extends DoublesGuardEffect {
  const QuickGuardEffect({
    required BankBattleEffectScope scope,
  }) : super(id: 'quick_guard', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return QuickGuardEffect(scope: scope);
  }

  @override
  bool blocks(BattleMoveDefinition move) {
    return move.flags.protectable && move.priority > 0;
  }
}

final class MatBlockEffect extends DoublesGuardEffect {
  const MatBlockEffect({
    required BankBattleEffectScope scope,
  }) : super(id: 'mat_block', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MatBlockEffect(scope: scope);
  }

  @override
  bool blocks(BattleMoveDefinition move) {
    return move.flags.protectable &&
        move.category != PsdkBattleMoveCategory.status;
  }
}

final class CraftyShieldEffect extends DoublesGuardEffect {
  const CraftyShieldEffect({
    required BankBattleEffectScope scope,
  }) : super(id: 'crafty_shield', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CraftyShieldEffect(scope: scope);
  }

  @override
  bool blocks(BattleMoveDefinition move) {
    return move.category == PsdkBattleMoveCategory.status &&
        move.id != 'curse' &&
        move.dbSymbol != 'curse';
  }
}

bool _isOneTargetMove(PsdkBattleMoveTarget target) {
  return target == PsdkBattleMoveTarget.self ||
      target == PsdkBattleMoveTarget.user ||
      target == PsdkBattleMoveTarget.adjacentFoe ||
      target == PsdkBattleMoveTarget.anyFoe ||
      target == PsdkBattleMoveTarget.randomFoe ||
      target == PsdkBattleMoveTarget.adjacentAlly ||
      target == PsdkBattleMoveTarget.adjacentAllyOrSelf;
}
