import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/item/item_effect.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_weather_change_handler.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

final class WeatherMoveBehavior implements BattleMoveBehavior {
  const WeatherMoveBehavior();

  @override
  String get battleEngineMethod => 's_weather';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final weather = _weatherForMove(context.move.dbSymbol);
    final duration = _durationForContext(context);
    final result = const BattleWeatherChangeHandler().changeWeather(
      context: BattleHandlerContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
      ),
      weather: weather,
      remainingTurns: duration,
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

PsdkBattleWeatherId _weatherForMove(String dbSymbol) {
  return switch (dbSymbol) {
    'rain_dance' => PsdkBattleWeatherId.rain,
    'sunny_day' => PsdkBattleWeatherId.sunny,
    'sandstorm' => PsdkBattleWeatherId.sandstorm,
    'hail' => PsdkBattleWeatherId.hail,
    'snowscape' => PsdkBattleWeatherId.snow,
    _ => throw UnsupportedError(
        'Unsupported PSDK weather move dbSymbol $dbSymbol.',
      ),
  };
}

int _durationFromItems({
  required String dbSymbol,
  required Iterable<BattleItemEffect> itemEffects,
}) {
  for (final effect in itemEffects) {
    final duration = effect.weatherDuration(dbSymbol);
    if (duration != null) {
      return duration;
    }
  }
  return 5;
}

int _durationForContext(BattleMoveBehaviorContext context) {
  final user = context.state.battlerAt(context.user);
  return _durationFromItems(
    dbSymbol: context.move.dbSymbol,
    itemEffects: user.itemEffects,
  );
}
