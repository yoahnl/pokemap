import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum AbilityMovePowerShape {
  contact,
  punch,
  slicing,
  sound,
  technician,
}

final class MoveShapePowerAbilityEffect extends BattleAbilityEffect {
  const MoveShapePowerAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.shape,
    required this.multiplier,
  }) : super(abilityId: abilityId, scope: scope);

  final AbilityMovePowerShape shape;
  final double multiplier;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MoveShapePowerAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      shape: shape,
      multiplier: multiplier,
    );
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    return _matches(context) ? multiplier : 1;
  }

  bool _matches(BattleAbilityDamageContext context) {
    final flags = context.move.flags;
    return switch (shape) {
      AbilityMovePowerShape.contact => flags.contact,
      AbilityMovePowerShape.punch => flags.punch,
      AbilityMovePowerShape.slicing => flags.slicing,
      AbilityMovePowerShape.sound => flags.sound,
      AbilityMovePowerShape.technician => context.move.power <= 60,
    };
  }
}
