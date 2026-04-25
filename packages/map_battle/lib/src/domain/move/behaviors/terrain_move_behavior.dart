import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/item/item_effect.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_terrain_change_handler.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

final class TerrainMoveBehavior implements BattleMoveBehavior {
  const TerrainMoveBehavior();

  @override
  String get battleEngineMethod => 's_terrain';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final terrain = _terrainForMove(context.move.dbSymbol);
    final user = prepared.state.battlerAt(context.user);
    final result = const BattleTerrainChangeHandler().changeTerrain(
      context: BattleHandlerContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
      ),
      terrain: terrain,
      remainingTurns: _durationForMove(
        dbSymbol: context.move.dbSymbol,
        itemEffects: user.itemEffects,
      ),
    );

    return BattleMoveBehaviorResolution(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...result.events,
      ],
      successful: result.applied,
    );
  }
}

int _durationForMove({
  required String dbSymbol,
  required Iterable<BattleItemEffect> itemEffects,
}) {
  for (final effect in itemEffects) {
    final duration = effect.terrainDuration(dbSymbol);
    if (duration != null) {
      return duration;
    }
  }
  return 5;
}

PsdkBattleTerrainId _terrainForMove(String dbSymbol) {
  return switch (dbSymbol) {
    'electric_terrain' => PsdkBattleTerrainId.electricTerrain,
    'grassy_terrain' => PsdkBattleTerrainId.grassyTerrain,
    'misty_terrain' => PsdkBattleTerrainId.mistyTerrain,
    'psychic_terrain' => PsdkBattleTerrainId.psychicTerrain,
    _ => throw UnsupportedError(
        'Unsupported PSDK terrain move dbSymbol $dbSymbol.',
      ),
  };
}
