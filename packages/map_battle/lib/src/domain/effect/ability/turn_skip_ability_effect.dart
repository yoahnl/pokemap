import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class TruantEffect extends BattleAbilityEffect {
  const TruantEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'truant', scope: scope);

  static const String _loafNextTurnEffectId = 'truant:loaf_next_turn';

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TruantEffect(scope: scope);
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!isOwnedBy(context.user)) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.effects.contains(_loafNextTurnEffectId)) {
      return BattleEffectUserMovePreventionResult(
        state: context.state.updateBattler(
          context.user,
          (battler) => battler.copyWith(
            effects: battler.effects.remove(_loafNextTurnEffectId),
          ),
        ),
        rng: context.rng,
        prevented: true,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state.updateBattler(
        context.user,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(
            GenericBattleEffect(
              id: _loafNextTurnEffectId,
              scope: BattlerBattleEffectScope(context.user),
            ),
          ),
        ),
      ),
      rng: context.rng,
      prevented: false,
      reason: BattleMoveFailureReason.unusableByUser,
      recordAttempt: false,
    );
  }
}
