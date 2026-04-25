import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleTerrainChangeHandler {
  const BattleTerrainChangeHandler();

  BattleHandlerResult changeTerrain({
    required BattleHandlerContext context,
    required PsdkBattleTerrainId terrain,
    int remainingTurns = 5,
  }) {
    if (context.state.field.terrain?.id == terrain) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'terrain_already_active',
      );
    }
    return BattleHandlerResult(
      state: context.state.copyWith(
        field: context.state.field.withTerrain(
          terrain,
          remainingTurns: remainingTurns,
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleTerrainChangedEvent(
          turn: context.turn,
          terrain: terrain,
          remainingTurns: remainingTurns,
        ),
      ],
    );
  }

  BattleHandlerResult clearTerrain({
    required BattleHandlerContext context,
    String reason = 'cleared',
  }) {
    if (context.state.field.terrain == null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'terrain_already_clear',
      );
    }
    return BattleHandlerResult(
      state: context.state.copyWith(field: context.state.field.clearTerrain()),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleTerrainChangedEvent(
          turn: context.turn,
          terrain: null,
          reason: reason,
        ),
      ],
    );
  }
}
