import '../battle_effect.dart';
import '../battle_effect_scope.dart';

sealed class PsdkMechanicsEffect extends BattleEffect {
  const PsdkMechanicsEffect({
    required super.id,
    super.scope = const FieldBattleEffectScope(),
    super.remainingTurns,
  });
}

final class PsdkEffectBaseEffect extends PsdkMechanicsEffect {
  const PsdkEffectBaseEffect()
      : super(
          id: 'effect_base',
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return const PsdkEffectBaseEffect();
  }
}

final class PsdkEffectsHandlerEffect extends PsdkMechanicsEffect {
  const PsdkEffectsHandlerEffect()
      : super(
          id: 'effects_handler',
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return const PsdkEffectsHandlerEffect();
  }
}

final class PsdkPokemonTiedEffectBaseEffect extends PsdkMechanicsEffect {
  const PsdkPokemonTiedEffectBaseEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'pokemon_tied_effect_base',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PsdkPokemonTiedEffectBaseEffect(scope: scope);
  }
}

final class PsdkPositionTiedEffectBaseEffect extends PsdkMechanicsEffect {
  const PsdkPositionTiedEffectBaseEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'position_tied_effect_base',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PsdkPositionTiedEffectBaseEffect(scope: scope);
  }
}
