import '../../../psdk/domain/psdk_battle_field.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class TerrainEffect extends BattleEffect {
  const TerrainEffect({
    required this.terrain,
    int? remainingTurns,
  }) : super(
          id: 'terrain',
          scope: const FieldBattleEffectScope(),
          remainingTurns: remainingTurns,
        );

  final PsdkBattleTerrainId terrain;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TerrainEffect(
      terrain: terrain,
      remainingTurns: remainingTurns,
    );
  }

  @override
  String? onTerrainPrevention(BattleEffectTerrainPreventionContext context) {
    return context.terrain == terrain ? 'terrain_already_active' : null;
  }
}
