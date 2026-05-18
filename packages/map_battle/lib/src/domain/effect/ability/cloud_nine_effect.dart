import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_weather_change_handler.dart';
import 'ability_effect.dart';

final class CloudNineEffect extends BattleAbilityEffect {
  const CloudNineEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'cloud_nine', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CloudNineEffect(scope: scope);
  }

  @override
  bool get suppressesWeatherEffects => true;

  @override
  String? onWeatherPrevention(BattleEffectWeatherPreventionContext context) {
    return context.weather == null ? null : 'weather_suppressed';
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!isOwnedBy(context.replacement) ||
        context.state.field.weather == null) {
      return null;
    }

    final result = const BattleWeatherChangeHandler().clearWeather(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.replacement,
      ),
      reason: 'ability:cloud_nine',
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}
