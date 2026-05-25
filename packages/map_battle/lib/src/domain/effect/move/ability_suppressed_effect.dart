import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK `AbilitySuppressed` effect, used by Gastro Acid-like moves.
final class AbilitySuppressedEffect extends BattleEffect {
  const AbilitySuppressedEffect({
    required BattleEffectScope scope,
    required this.origin,
    int? remainingTurns,
  }) : super(
          id: 'ability_suppressed',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final String origin;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AbilitySuppressedEffect(
      scope: scope,
      origin: origin,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return AbilitySuppressedEffect(
      scope: BattlerBattleEffectScope(context.target),
      origin: origin,
      remainingTurns: remainingTurns,
    );
  }
}
