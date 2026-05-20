import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/battle_effect_hooks.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleWeatherChangeHandler {
  const BattleWeatherChangeHandler();

  BattleHandlerResult changeWeather({
    required BattleHandlerContext context,
    required PsdkBattleWeatherId weather,
    int? remainingTurns = 5,
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
    final hookPrevention = _weatherPreventionReason(
      context: context,
      weather: weather,
      lastWeather: current?.id,
    );
    if (hookPrevention != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: hookPrevention,
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
    final baseState = context.state.copyWith(
      field: context.state.field.withWeather(
        weather,
        remainingTurns: remainingTurns,
      ),
    );
    final post = _dispatchPostWeatherChange(
      context: BattleHandlerContext(
        state: baseState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      weather: weather,
      lastWeather: current?.id,
      remainingTurns: remainingTurns,
    );

    return BattleHandlerResult(
      state: post.state,
      rng: post.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleWeatherChangedEvent(
          turn: context.turn,
          weather: weather,
          remainingTurns: remainingTurns,
        ),
        ...post.events,
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
    final lastWeather = context.state.field.weather?.id;
    final hookPrevention = _weatherPreventionReason(
      context: context,
      weather: null,
      lastWeather: lastWeather,
    );
    if (hookPrevention != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: hookPrevention,
      );
    }
    final baseState = context.state.copyWith(
      field: context.state.field.clearWeather(),
    );
    final post = _dispatchPostWeatherChange(
      context: BattleHandlerContext(
        state: baseState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      weather: null,
      lastWeather: lastWeather,
      remainingTurns: null,
    );

    return BattleHandlerResult(
      state: post.state,
      rng: post.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleWeatherChangedEvent(
          turn: context.turn,
          weather: null,
          reason: reason,
        ),
        ...post.events,
      ],
    );
  }
}

String? _weatherPreventionReason({
  required BattleHandlerContext context,
  required PsdkBattleWeatherId? weather,
  required PsdkBattleWeatherId? lastWeather,
}) {
  for (final owner in _orderedSlots(context.state)) {
    final reason =
        context.state.battlerAt(owner).effects.weatherPreventionReason(
              BattleEffectWeatherPreventionContext(
                state: context.state,
                rng: context.rng,
                turn: context.turn,
                owner: owner,
                user: context.user,
                weather: weather,
                lastWeather: lastWeather,
              ),
            );
    if (reason != null) {
      return reason;
    }
  }
  return null;
}

BattleEffectFieldChangeResult _dispatchPostWeatherChange({
  required BattleHandlerContext context,
  required PsdkBattleWeatherId? weather,
  required PsdkBattleWeatherId? lastWeather,
  required int? remainingTurns,
}) {
  var nextState = context.state;
  var nextRng = context.rng;
  final events = <PsdkBattleEvent>[];
  var changed = false;
  for (final owner in _orderedSlots(nextState)) {
    final result = nextState.battlerAt(owner).effects.dispatchPostWeatherChange(
          BattleEffectWeatherChangeContext(
            state: nextState,
            rng: nextRng,
            turn: context.turn,
            owner: owner,
            user: context.user,
            weather: weather,
            lastWeather: lastWeather,
            remainingTurns: remainingTurns,
          ),
        );
    nextState = result.state;
    nextRng = result.rng;
    events.addAll(result.events);
    changed = changed || result.applied || result.events.isNotEmpty;
  }
  return BattleEffectFieldChangeResult(
    state: nextState,
    rng: nextRng,
    events: events,
    applied: changed,
  );
}

List<PsdkBattleSlotRef> _orderedSlots(PsdkBattleState state) {
  final slots = state.combatants.keys.toList();
  slots.sort(_compareSlots);
  return slots;
}

int _compareSlots(PsdkBattleSlotRef a, PsdkBattleSlotRef b) {
  final bank = a.bank.compareTo(b.bank);
  return bank != 0 ? bank : a.position.compareTo(b.position);
}
