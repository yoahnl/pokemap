import '../battle_effect.dart';
import 'ability_effect.dart';

final class DancerEffect extends BattleAbilityEffect {
  const DancerEffect({
    required super.scope,
    this.activated = false,
  }) : super(abilityId: 'dancer');

  final bool activated;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DancerEffect(scope: scope, activated: activated);
  }

  DancerEffect copyWithActivated(bool value) {
    return DancerEffect(scope: scope, activated: value);
  }
}
