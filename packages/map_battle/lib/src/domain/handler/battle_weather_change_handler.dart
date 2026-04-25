import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/ability/ability_effect.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleWeatherChangeHandler {
  const BattleWeatherChangeHandler();

  BattleHandlerResult changeWeather({
    required BattleHandlerContext context,
    required PsdkBattleWeatherId weather,
    int remainingTurns = 5,
  }) {
    final current = context.state.field.weather;
    if (current?.id == weather) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'weather_already_active',
      );
    }
    if (context.state.activeAbilityEffects().any(
          (effect) => effect.suppressesWeatherEffects,
        )) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'weather_suppressed',
      );
    }
    if (current?.id.isHardWeather == true && !weather.isHardWeather) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'hard_weather_active',
      );
    }
    return BattleHandlerResult(
      state: context.state.copyWith(
        field: context.state.field.withWeather(
          weather,
          remainingTurns: remainingTurns,
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleWeatherChangedEvent(
          turn: context.turn,
          weather: weather,
          remainingTurns: remainingTurns,
        ),
      ],
    );
  }

  BattleHandlerResult clearWeather({
    required BattleHandlerContext context,
    String reason = 'cleared',
  }) {
    if (context.state.field.weather == null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'weather_already_clear',
      );
    }
    return BattleHandlerResult(
      state: context.state.copyWith(field: context.state.field.clearWeather()),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleWeatherChangedEvent(
          turn: context.turn,
          weather: null,
          reason: reason,
        ),
      ],
    );
  }
}
