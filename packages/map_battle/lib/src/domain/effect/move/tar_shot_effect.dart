import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class TarShotEffect extends BattleEffect {
  const TarShotEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'tar_shot',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TarShotEffect(scope: scope);
  }
}
