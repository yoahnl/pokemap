import '../move/battle_move_prevention.dart';
import 'battle_effect_hooks.dart';
import 'battle_effect_scope.dart';

/// Base class for PSDK-lane effects.
///
/// The default implementation is intentionally inert. That lets the engine
/// carry effects such as `gravity` before their dedicated FIGHT-07/FIGHT-09
/// behavior exists, while still making any active hook opt-in and testable.
abstract class BattleEffect {
  const BattleEffect({
    required this.id,
    required this.scope,
    this.remainingTurns,
  });

  final String id;
  final BattleEffectScope scope;

  /// `0` means "clear at the end of the current turn".
  ///
  /// PSDK Protect initializes with one counter turn. The Dart lane models the
  /// same one-turn lifetime as a turn-scoped effect because cleanup happens
  /// after all actions in the turn have observed it.
  final int? remainingTurns;

  bool get isTurnScoped => remainingTurns == 0;

  BattleEffect copyWithRemainingTurns(int remainingTurns);

  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    return null;
  }

  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    return null;
  }
}

/// Passive effect used when legacy/setup code only knows an effect id.
///
/// It preserves state and future dependency checks without inventing behavior.
final class GenericBattleEffect extends BattleEffect {
  const GenericBattleEffect({
    required String id,
    BattleEffectScope scope = const LocalBattleEffectScope(),
    int? remainingTurns,
  }) : super(id: id, scope: scope, remainingTurns: remainingTurns);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return GenericBattleEffect(
      id: id,
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}
