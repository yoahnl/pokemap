import '../../../psdk/domain/psdk_battle_field.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class WeatherEffect extends BattleEffect {
  const WeatherEffect({
    required this.weather,
    int? remainingTurns,
  }) : super(
          id: 'weather',
          scope: const FieldBattleEffectScope(),
          remainingTurns: remainingTurns,
        );

  final PsdkBattleWeatherId weather;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WeatherEffect(
      weather: weather,
      remainingTurns: remainingTurns,
    );
  }

  @override
  String? onWeatherPrevention(BattleEffectWeatherPreventionContext context) {
    final nextWeather = context.weather;
    if (!weather.isHardWeather ||
        nextWeather == null ||
        nextWeather.isHardWeather) {
      return null;
    }
    return 'hard_weather_active';
  }
}
