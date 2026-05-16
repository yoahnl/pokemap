import '../../psdk/domain/psdk_battle_field.dart';
import '../battler/battle_grounding_resolver.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_hooks.dart';
import '../effect/status/status_effect_registry.dart';
import 'battle_heal_handler.dart';
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
    final effects = tickEndTurnEffects(
      BattleHandlerContext(
        state: statuses.state,
        rng: statuses.rng,
        turn: context.turn,
        user: context.user,
      ),
    );
    final fieldProgression = tickField(
      BattleHandlerContext(
        state: effects.state,
        rng: effects.rng,
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
        ...effects.events,
        ...fieldProgression.events,
      ],
      applied: cleared.applied ||
          statuses.applied ||
          effects.applied ||
          fieldProgression.applied,
      reason: cleared.applied ||
              statuses.applied ||
              effects.applied ||
              fieldProgression.applied
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

  BattleHandlerResult tickEndTurnEffects(BattleHandlerContext context) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final slot in context.state.aliveSlots()) {
      if (nextState.battlerAt(slot).isFainted) {
        continue;
      }
      final result = nextState.battlerAt(slot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: nextState,
              rng: nextRng,
              turn: context.turn,
              owner: slot,
            ),
            where: (effect) => effect is! BattleMajorStatusEffect,
          );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleHandlerResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
      reason: changed ? null : 'no_effect_progression',
    );
  }

  BattleHandlerResult tickField(BattleHandlerContext context) {
    final field = context.state.field;
    var nextState = context.state;
    var nextField = field;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    final weather = field.weather;
    if (weather != null) {
      final nextWeather = weather.tickEndTurn();
      nextField = nextField.copyWith(weather: nextWeather);
      changed = changed || weather != nextWeather;
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
      if (terrain.id == PsdkBattleTerrainId.grassyTerrain &&
          nextTerrain != null) {
        final grassy = _healGrassyTerrain(
          context: BattleHandlerContext(
            state: nextState,
            rng: context.rng,
            turn: context.turn,
            user: context.user,
          ),
        );
        nextState = grassy.state;
        events.addAll(grassy.events);
        changed = changed || grassy.applied;
      }
      nextField = nextField.copyWith(terrain: nextTerrain);
      changed = changed || terrain != nextTerrain;
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

    return BattleHandlerResult(
      state: changed ? nextState.copyWith(field: nextField) : context.state,
      rng: context.rng,
      events: events,
      applied: changed,
      reason: changed ? null : 'no_field_progression',
    );
  }

  BattleHandlerResult _healGrassyTerrain({
    required BattleHandlerContext context,
  }) {
    var nextState = context.state;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final slot in context.state.aliveSlots()) {
      final battler = nextState.battlerAt(slot);
      if (battler.isFainted ||
          !const BattleGroundingResolver().isGrounded(battler)) {
        continue;
      }
      final amount = battler.maxHp ~/ 16;
      if (amount <= 0 || battler.currentHp >= battler.maxHp) {
        continue;
      }
      final result = const BattleHealHandler().heal(
        context: BattleHandlerContext(
          state: nextState,
          rng: context.rng,
          turn: context.turn,
          user: context.user,
        ),
        target: slot,
        amount: amount,
      );
      if (!result.applied) {
        continue;
      }
      nextState = result.state;
      changed = true;
      events.add(
        PsdkBattleHealEvent(
          user: context.user,
          target: slot,
          moveId: 'terrain:grassy_terrain',
          amount: result.amount,
          remainingHp: nextState.battlerAt(slot).currentHp,
        ),
      );
    }

    return BattleHandlerResult(
      state: nextState,
      rng: context.rng,
      events: events,
      applied: changed,
      reason: changed ? null : 'no_grassy_terrain_heal',
    );
  }
}
