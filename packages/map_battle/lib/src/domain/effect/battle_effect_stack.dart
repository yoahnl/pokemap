import 'battle_effect.dart';
import 'battle_effect_hooks.dart';
import '../move/battle_move_prevention.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';

/// Immutable object-backed effect collection for the PSDK lane.
///
/// The older public `PsdkBattleEffectStack` still exposes id helpers for
/// compatibility. This inner stack owns the real effect objects so FIGHT-03 can
/// route Protect through a hook instead of hardcoded string checks.
final class BattleEffectObjectStack {
  BattleEffectObjectStack({
    Iterable<BattleEffect> effects = const <BattleEffect>[],
  }) : _effects = List<BattleEffect>.unmodifiable(effects);

  const BattleEffectObjectStack.empty() : _effects = const <BattleEffect>[];

  final List<BattleEffect> _effects;

  List<BattleEffect> get effects => List<BattleEffect>.unmodifiable(_effects);

  bool contains(String effectId) => _effects.any(
        (effect) => effect.id == effectId,
      );

  BattleEffectObjectStack addOrReplace(BattleEffect effect) {
    final next = <BattleEffect>[
      for (final current in _effects)
        if (current.id != effect.id) current,
      effect,
    ];
    return BattleEffectObjectStack(effects: next);
  }

  BattleEffectObjectStack addAll(Iterable<BattleEffect> effects) {
    var next = this;
    for (final effect in effects) {
      next = next.addOrReplace(effect);
    }
    return next;
  }

  BattleEffectObjectStack remove(String effectId) {
    return BattleEffectObjectStack(
      effects: _effects.where((effect) => effect.id != effectId),
    );
  }

  BattleEffectObjectStack clearTurnScopedEffects() {
    return BattleEffectObjectStack(
      effects: _effects.where((effect) => !effect.isTurnScoped),
    );
  }

  BattleEffectObjectStack batonPassTransferEffects(
    BattleEffectBatonPassContext context,
  ) {
    return BattleEffectObjectStack(
      effects: _effects
          .map((effect) => effect.onBatonPassTransfer(context))
          .whereType<BattleEffect>(),
    );
  }

  BattleEffectObjectStack withoutBatonPassTransferableEffects(
    BattleEffectBatonPassContext context,
  ) {
    return BattleEffectObjectStack(
      effects: _effects.where(
        (effect) => effect.onBatonPassTransfer(context) == null,
      ),
    );
  }

  BattleEffectEndTurnResult dispatchEndTurn(
    BattleEffectEndTurnContext context, {
    bool Function(BattleEffect effect)? where,
  }) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (where != null && !where(effect)) {
        continue;
      }
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onEndTurn(
        BattleEffectEndTurnContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
        ),
      );
      if (result == null) {
        continue;
      }
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectEndTurnResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  BattleEffectDamagePreventionResult? dispatchDamagePrevention(
    BattleEffectDamagePreventionContext context, {
    bool Function(BattleEffect effect)? where,
  }) {
    var nextState = context.state;
    var nextRng = context.rng;
    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      if (where != null && !where(effect)) {
        continue;
      }
      final result = effect.onDamagePrevention(
        BattleEffectDamagePreventionContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          user: context.user,
          target: context.target,
          move: context.move,
          damage: context.damage,
        ),
      );
      if (result == null) {
        continue;
      }
      return result;
    }
    return null;
  }

  BattleEffectPostDamageResult dispatchPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onPostDamage(
        BattleEffectPostDamageContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          user: context.user,
          target: context.target,
          move: context.move,
          damage: context.damage,
          targetFainted: context.targetFainted,
        ),
      );
      if (result == null) {
        continue;
      }
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectPostDamageResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  BattleEffectItemChangeResult dispatchPostItemChange(
    BattleEffectItemChangeContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onPostItemChange(
        BattleEffectItemChangeContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          target: context.target,
          previousItemId: context.previousItemId,
          nextItemId: context.nextItemId,
          consumedItemId: context.consumedItemId,
          reason: context.reason,
        ),
      );
      if (result == null) {
        continue;
      }
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectItemChangeResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  BattleEffectLifecycleResult dispatchLifecycle(
    BattleEffectLifecycleContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onLifecycle(
        BattleEffectLifecycleContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          phase: context.phase,
        ),
      );
      if (result == null) {
        continue;
      }
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectLifecycleResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  BattleMoveFailureReason? targetMovePreventionReason(
    BattleEffectMoveContext context, {
    bool Function(BattleEffect effect)? where,
  }) {
    for (final effect in _effects) {
      if (where != null && !where(effect)) {
        continue;
      }
      final reason = effect.onMovePreventionTarget(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  BattleEffectUserMovePreventionResult? userMovePrevention(
    BattleEffectUserMovePreventionContext context, {
    bool Function(BattleEffect effect)? where,
  }) {
    var nextState = context.state;
    var nextRng = context.rng;
    for (final effect in _effects) {
      if (where != null && !where(effect)) {
        continue;
      }
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.user,
      )) {
        continue;
      }
      final result = effect.onUserMovePrevention(
        BattleEffectUserMovePreventionContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.user,
          target: context.target,
          move: context.move,
        ),
      );
      if (result == null) {
        continue;
      }
      return result;
    }
    return null;
  }

  BattleMoveSelectionPreventionResult? moveSelectionPrevention(
    BattleMoveSelectionPreventionContext context,
  ) {
    for (final effect in _effects) {
      final result = effect.onMoveSelectionPrevention(context);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  String? switchPreventionReason(BattleEffectSwitchPreventionContext context) {
    for (final effect in _effects) {
      final reason = effect.onSwitchPrevention(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  bool switchPassthrough(BattleEffectSwitchPreventionContext context) {
    for (final effect in _effects) {
      if (effect.onSwitchPassthrough(context)) {
        return true;
      }
    }
    return false;
  }

  BattleEffectSwitchEventResult dispatchSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onSwitchEvent(
        BattleEffectSwitchEventContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          who: context.who,
          replacement: context.replacement,
        ),
      );
      if (result == null) {
        continue;
      }
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectSwitchEventResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  BattleEffectSwitchOutResult dispatchSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onSwitchOut(
        BattleEffectSwitchOutContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          replacement: context.replacement,
        ),
      );
      if (result == null) {
        continue;
      }
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectSwitchOutResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  String? statChangePreventionReason(
    BattleEffectStatChangePreventionContext context,
  ) {
    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: context.state,
        owner: context.owner,
      )) {
        continue;
      }
      final reason = context.stages > 0
          ? effect.onStatIncreasePrevention(context)
          : effect.onStatDecreasePrevention(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  int resolveStatChange(BattleEffectStatChangeContext context) {
    var stages = context.stages;
    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: context.state,
        owner: context.owner,
      )) {
        continue;
      }
      final changed = effect.onStatChange(
        BattleEffectStatChangeContext(
          state: context.state,
          rng: context.rng,
          turn: context.turn,
          owner: context.owner,
          user: context.user,
          target: context.target,
          stat: context.stat,
          stages: stages,
          move: context.move,
          sourceAbilityId: context.sourceAbilityId,
        ),
      );
      if (changed != null) {
        stages = changed;
      }
    }
    return stages;
  }

  BattleEffectStatChangePostResult dispatchStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onStatChangePost(
        BattleEffectStatChangeContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          user: context.user,
          target: context.target,
          stat: context.stat,
          stages: context.stages,
          move: context.move,
          sourceAbilityId: context.sourceAbilityId,
        ),
      );
      if (result == null) {
        continue;
      }
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectStatChangePostResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  String? statusPreventionReason(
    BattleEffectStatusPreventionContext context,
  ) {
    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: context.state,
        owner: context.owner,
      )) {
        continue;
      }
      final reason = effect.onStatusPrevention(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  BattleEffectStatusChangeResult dispatchPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onPostStatusChange(
        BattleEffectStatusChangeContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          user: context.user,
          target: context.target,
          status: context.status,
          cured: context.cured,
          moveId: context.moveId,
          move: context.move,
        ),
      );
      if (result == null) {
        continue;
      }
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleEffectStatusChangeResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
    );
  }

  String? weatherPreventionReason(
    BattleEffectWeatherPreventionContext context,
  ) {
    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: context.state,
        owner: context.owner,
      )) {
        continue;
      }
      final reason = effect.onWeatherPrevention(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  BattleEffectFieldChangeResult dispatchPostWeatherChange(
    BattleEffectWeatherChangeContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onPostWeatherChange(
        BattleEffectWeatherChangeContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          user: context.user,
          weather: context.weather,
          lastWeather: context.lastWeather,
          remainingTurns: context.remainingTurns,
        ),
      );
      if (result == null) {
        continue;
      }
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

  String? terrainPreventionReason(
    BattleEffectTerrainPreventionContext context,
  ) {
    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: context.state,
        owner: context.owner,
      )) {
        continue;
      }
      final reason = effect.onTerrainPrevention(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  BattleEffectFieldChangeResult dispatchPostTerrainChange(
    BattleEffectTerrainChangeContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final effect in _effects) {
      if (!_effectIsStillActive(
        effect: effect,
        state: nextState,
        owner: context.owner,
      )) {
        continue;
      }
      final result = effect.onPostTerrainChange(
        BattleEffectTerrainChangeContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: context.owner,
          user: context.user,
          terrain: context.terrain,
          lastTerrain: context.lastTerrain,
          remainingTurns: context.remainingTurns,
        ),
      );
      if (result == null) {
        continue;
      }
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

  bool _effectIsStillActive({
    required BattleEffect effect,
    required PsdkBattleState state,
    required PsdkBattleSlotRef owner,
  }) {
    return state.battlerAt(owner).effects.contains(effect.id);
  }
}
