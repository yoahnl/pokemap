import '../../psdk/domain/psdk_battle_timeline.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';
import 'battle_status_change_handler.dart';

final class BattleEndTurnHandler {
  const BattleEndTurnHandler();

  BattleHandlerResult resolveEndTurn(BattleHandlerContext context) {
    final cleared = clearTurnScopedEffects(context);
    final statuses = const BattleStatusChangeHandler().tickEndTurnStatuses(
      BattleHandlerContext(
        state: cleared.state,
        rng: cleared.rng,
        turn: context.turn,
        user: context.user,
      ),
    );
    final fieldProgression = tickField(
      BattleHandlerContext(
        state: statuses.state,
        rng: statuses.rng,
        turn: context.turn,
        user: context.user,
      ),
    );
    return BattleHandlerResult(
      state: fieldProgression.state,
      rng: fieldProgression.rng,
      events: <PsdkBattleEvent>[
        ...cleared.events,
        ...statuses.events,
        ...fieldProgression.events,
      ],
      applied: cleared.applied || statuses.applied || fieldProgression.applied,
      reason: cleared.applied || statuses.applied || fieldProgression.applied
          ? null
          : 'no_end_turn_changes',
    );
  }

  BattleHandlerResult clearTurnScopedEffects(BattleHandlerContext context) {
    var nextState = context.state;
    var changed = false;
    for (final entry in context.state.combatants.entries) {
      final battler = entry.value;
      final clearedEffects = battler.effects.clearTurnScopedEffects();
      if (identical(clearedEffects, battler.effects)) {
        continue;
      }
      nextState = nextState.replaceBattler(
        entry.key,
        battler.copyWith(effects: clearedEffects),
      );
      changed = true;
    }
    return BattleHandlerResult(
      state: nextState,
      rng: context.rng,
      applied: changed,
      reason: changed ? null : 'no_turn_scoped_effects',
    );
  }

  BattleHandlerResult tickField(BattleHandlerContext context) {
    final field = context.state.field;
    var nextField = field;
    final events = <PsdkBattleEvent>[];

    final weather = field.weather;
    if (weather != null) {
      final nextWeather = weather.tickEndTurn();
      nextField = nextField.copyWith(weather: nextWeather);
      if (nextWeather == null) {
        events.add(
          PsdkBattleWeatherChangedEvent(
            turn: context.turn,
            weather: null,
            reason: 'expired',
          ),
        );
      }
    }

    final terrain = field.terrain;
    if (terrain != null) {
      final nextTerrain = terrain.tickEndTurn();
      nextField = nextField.copyWith(terrain: nextTerrain);
      if (nextTerrain == null) {
        events.add(
          PsdkBattleTerrainChangedEvent(
            turn: context.turn,
            terrain: null,
            reason: 'expired',
          ),
        );
      }
    }

    final changed =
        weather != nextField.weather || terrain != nextField.terrain;
    return BattleHandlerResult(
      state: changed ? context.state.copyWith(field: nextField) : context.state,
      rng: context.rng,
      events: events,
      applied: changed,
      reason: changed ? null : 'no_field_progression',
    );
  }
}
