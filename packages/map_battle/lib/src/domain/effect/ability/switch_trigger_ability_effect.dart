import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_terrain_change_handler.dart';
import '../../handler/battle_weather_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../item/item_effect.dart';
import 'ability_effect.dart';

final class SwitchWeatherAbilityEffect extends BattleAbilityEffect {
  const SwitchWeatherAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.weather,
    required this.weatherMoveDbSymbol,
  }) : super(abilityId: abilityId, scope: scope);

  final PsdkBattleWeatherId weather;
  final String weatherMoveDbSymbol;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SwitchWeatherAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      weather: weather,
      weatherMoveDbSymbol: weatherMoveDbSymbol,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    final result = const BattleWeatherChangeHandler().changeWeather(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.replacement,
      ),
      weather: weather,
      remainingTurns: _weatherDuration(context),
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

  int _weatherDuration(BattleEffectSwitchEventContext context) {
    final battler = context.state.battlerAt(context.replacement);
    for (final itemEffect in battler.activeItemEffects) {
      final duration = itemEffect.weatherDuration(weatherMoveDbSymbol);
      if (duration != null) {
        return duration;
      }
    }
    return 5;
  }
}

final class SwitchTerrainAbilityEffect extends BattleAbilityEffect {
  const SwitchTerrainAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.terrain,
    required this.terrainMoveDbSymbol,
  }) : super(abilityId: abilityId, scope: scope);

  final PsdkBattleTerrainId terrain;
  final String terrainMoveDbSymbol;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SwitchTerrainAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      terrain: terrain,
      terrainMoveDbSymbol: terrainMoveDbSymbol,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    final result = const BattleTerrainChangeHandler().changeTerrain(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.replacement,
      ),
      terrain: terrain,
      remainingTurns: _terrainDuration(context),
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

  int _terrainDuration(BattleEffectSwitchEventContext context) {
    final battler = context.state.battlerAt(context.replacement);
    for (final itemEffect in battler.activeItemEffects) {
      final duration = itemEffect.terrainDuration(terrainMoveDbSymbol);
      if (duration != null) {
        return duration;
      }
    }
    return 5;
  }
}

final class IntimidateEffect extends BattleAbilityEffect {
  const IntimidateEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'intimidate', scope: scope);

  static const Set<String> _immuneAbilities = <String>{
    'own_tempo',
    'oblivious',
    'inner_focus',
    'scrappy',
  };

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return IntimidateEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final target in context.state.foesOf(context.replacement)) {
      if (_immuneToIntimidate(nextState, target)) {
        continue;
      }
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.replacement,
        ),
        target: target,
        stat: 'attack',
        stages: -1,
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    if (!changed) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

bool _isEnteringOwner(BattleEffectSwitchEventContext context) {
  return context.owner == context.replacement;
}

bool _immuneToIntimidate(
  PsdkBattleState state,
  PsdkBattleSlotRef target,
) {
  final battler = state.battlerAt(target);
  if (battler.effects.contains('ability_suppressed')) {
    return false;
  }
  final abilityId = battler.abilityId?.trim().toLowerCase();
  return abilityId != null &&
      IntimidateEffect._immuneAbilities.contains(abilityId);
}
