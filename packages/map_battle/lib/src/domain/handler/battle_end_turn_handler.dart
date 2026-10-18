import '../../psdk/domain/psdk_battle_field.dart';
import '../battler/battle_grounding_resolver.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/battle_effect.dart';
import '../effect/battle_effect_hooks.dart';
import '../effect/battle_effect_scope.dart';
import '../effect/item/item_effect.dart';
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
    final effects = _tickEndTurnEffects(
      BattleHandlerContext(
        state: statuses.state,
        rng: statuses.rng,
        turn: context.turn,
        user: context.user,
      ),
      where: (effect) =>
          effect is! BattleAbilityEffect && effect is! BattleItemEffect,
    );
    final fieldProgression = tickField(
      BattleHandlerContext(
        state: effects.state,
        rng: effects.rng,
        turn: context.turn,
        user: context.user,
      ),
    );
    final abilities = _tickEndTurnEffects(
      BattleHandlerContext(
        state: fieldProgression.state,
        rng: fieldProgression.rng,
        turn: context.turn,
        user: context.user,
      ),
      where: (effect) => effect is BattleAbilityEffect,
      orderBySpeed: true,
      activeOnly: true,
    );
    final items = _tickEndTurnEffects(
      BattleHandlerContext(
        state: abilities.state,
        rng: abilities.rng,
        turn: context.turn,
        user: context.user,
      ),
      where: (effect) => effect is BattleItemEffect,
      orderBySpeed: true,
      activeOnly: true,
    );
    final applied = cleared.applied ||
        statuses.applied ||
        effects.applied ||
        fieldProgression.applied ||
        abilities.applied ||
        items.applied;
    return BattleHandlerResult(
      state: items.state,
      rng: items.rng,
      events: <PsdkBattleEvent>[
        ...cleared.events,
        ...statuses.events,
        ...effects.events,
        ...fieldProgression.events,
        ...abilities.events,
        ...items.events,
      ],
      applied: applied,
      reason: applied ? null : 'no_end_turn_changes',
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
    return _tickEndTurnEffects(context);
  }

  BattleHandlerResult _tickEndTurnEffects(
    BattleHandlerContext context, {
    bool Function(BattleEffect effect)? where,
    bool orderBySpeed = false,
    bool activeOnly = false,
  }) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    final slots = context.state.combatants.keys.toList(growable: false);
    if (orderBySpeed) {
      slots.sort((a, b) {
        final bySpeed = context.state
            .battlerAt(b)
            .stats
            .speed
            .compareTo(context.state.battlerAt(a).stats.speed);
        if (bySpeed != 0) {
          return bySpeed;
        }
        final byBank = a.bank.compareTo(b.bank);
        return byBank != 0 ? byBank : a.position.compareTo(b.position);
      });
    }
    for (final slot in slots) {
      final battler = nextState.battlerAt(slot);
      final ownerIsFainted = battler.isFainted;
      final abilitySuppressed = battler.effects.contains('ability_suppressed');
      final itemSuppressed = battleItemEffectsSuppressed(
            battler: battler,
            state: nextState,
            slot: slot,
          ) ||
          (!abilitySuppressed &&
              battler.abilityId?.trim().toLowerCase() == 'klutz');
      final result = battler.effects.dispatchEndTurn(
        BattleEffectEndTurnContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: slot,
        ),
        where: (effect) =>
            effect is! BattleMajorStatusEffect &&
            (where == null || where(effect)) &&
            (!activeOnly ||
                ((effect is! BattleAbilityEffect || !abilitySuppressed) &&
                    (effect is! BattleItemEffect || !itemSuppressed))) &&
            (!ownerIsFainted || effect.scope is FieldBattleEffectScope),
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
    var nextRng = context.rng;
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
        nextState = nextState.copyWith(field: nextField);
        final postWeather = _dispatchPostWeatherExpiration(
          context: BattleHandlerContext(
            state: nextState,
            rng: nextRng,
            turn: context.turn,
            user: context.user,
          ),
          lastWeather: weather.id,
        );
        nextState = postWeather.state;
        nextField = nextState.field;
        nextRng = postWeather.rng;
        events.addAll(postWeather.events);
        changed = changed || postWeather.applied;
      } else if (nextWeather.id == PsdkBattleWeatherId.sandstorm) {
        final residual = _damageSandstorm(
          BattleHandlerContext(
            state: nextState.copyWith(field: nextField),
            rng: nextRng,
            turn: context.turn,
            user: context.user,
          ),
        );
        nextState = residual.state;
        events.addAll(residual.events);
        changed = changed || residual.applied;
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
            rng: nextRng,
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
        nextState = nextState.copyWith(field: nextField);
        final postTerrain = _dispatchPostTerrainExpiration(
          context: BattleHandlerContext(
            state: nextState,
            rng: nextRng,
            turn: context.turn,
            user: context.user,
          ),
          lastTerrain: terrain.id,
        );
        nextState = postTerrain.state;
        nextField = nextState.field;
        nextRng = postTerrain.rng;
        events.addAll(postTerrain.events);
        changed = changed || postTerrain.applied;
      }
    }

    return BattleHandlerResult(
      state: changed ? nextState.copyWith(field: nextField) : context.state,
      rng: nextRng,
      events: events,
      applied: changed,
      reason: changed ? null : 'no_field_progression',
    );
  }

  BattleHandlerResult _damageSandstorm(BattleHandlerContext context) {
    var nextState = context.state;
    final events = <PsdkBattleEvent>[];
    for (final slot in context.state.aliveSlots()) {
      final battler = nextState.battlerAt(slot);
      if (!nextState.isWeatherEffectActive(PsdkBattleWeatherId.sandstorm) ||
          battler.isFainted ||
          const <String>{'rock', 'ground', 'steel'}.any(battler.hasType) ||
          battler.effects.contains('out_of_reach_base')) {
        continue;
      }
      final abilityId = battler.effects.contains('ability_suppressed')
          ? null
          : battler.abilityId?.trim().toLowerCase();
      if (const <String>{
        'magic_guard',
        'sand_veil',
        'sand_rush',
        'sand_force',
        'overcoat',
      }.contains(abilityId)) {
        continue;
      }
      if (battler.heldItemId?.trim().toLowerCase() == 'safety_goggles' &&
          !battler.itemConsumed &&
          abilityId != 'klutz' &&
          !battleItemEffectsSuppressed(
            battler: battler,
            state: nextState,
            slot: slot,
          )) {
        continue;
      }
      final damage = (battler.maxHp ~/ 16).clamp(1, battler.currentHp).toInt();
      final remainingHp = battler.currentHp - damage;
      nextState = nextState.replaceBattler(
        slot,
        battler.copyWith(currentHp: remainingHp),
      );
      events.add(
        PsdkBattleWeatherDamageEvent(
          turn: context.turn,
          target: slot,
          weather: PsdkBattleWeatherId.sandstorm,
          damage: damage,
          remainingHp: remainingHp,
        ),
      );
    }
    return BattleHandlerResult(
      state: nextState,
      rng: context.rng,
      events: events,
      applied: events.isNotEmpty,
      reason: events.isEmpty ? 'no_sandstorm_damage' : null,
    );
  }

  BattleHandlerResult _dispatchPostWeatherExpiration({
    required BattleHandlerContext context,
    required PsdkBattleWeatherId lastWeather,
  }) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final owner in context.state.aliveSlots()) {
      // Natural duration expiry is still a Pokemon SDK weather change. Dispatch
      // the same post-change hook surface used by explicit weather clears so
      // abilities such as Protosynthesis can drop field boosts or fall back to
      // Booster Energy instead of leaving stale stat markers behind.
      final result =
          nextState.battlerAt(owner).effects.dispatchPostWeatherChange(
                BattleEffectWeatherChangeContext(
                  state: nextState,
                  rng: nextRng,
                  turn: context.turn,
                  owner: owner,
                  user: context.user,
                  weather: null,
                  lastWeather: lastWeather,
                  remainingTurns: null,
                ),
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
      reason: changed ? null : 'no_post_weather_expiration_hooks',
    );
  }

  BattleHandlerResult _dispatchPostTerrainExpiration({
    required BattleHandlerContext context,
    required PsdkBattleTerrainId lastTerrain,
  }) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final owner in context.state.aliveSlots()) {
      // Keep natural terrain expiry aligned with explicit terrain clears. This
      // protects Quark Drive and future terrain listeners from observing a
      // field that visually expired while their effect state stayed active.
      final result =
          nextState.battlerAt(owner).effects.dispatchPostTerrainChange(
                BattleEffectTerrainChangeContext(
                  state: nextState,
                  rng: nextRng,
                  turn: context.turn,
                  owner: owner,
                  user: context.user,
                  terrain: null,
                  lastTerrain: lastTerrain,
                  remainingTurns: null,
                ),
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
      reason: changed ? null : 'no_post_terrain_expiration_hooks',
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
