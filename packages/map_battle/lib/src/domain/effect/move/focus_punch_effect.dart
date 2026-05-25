import '../battle_effect.dart';
import '../battle_effect_scope.dart';

/// PSDK `FocusPunch` marker.
///
/// The Ruby effect only exposes `preparing_attack?` and a one-action lifetime.
/// The Dart lane models that lifetime with the existing turn-scoped cleanup.
final class FocusPunchEffect extends BattleEffect {
  const FocusPunchEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'focus_punch',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  bool get preparingAttack => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FocusPunchEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}
