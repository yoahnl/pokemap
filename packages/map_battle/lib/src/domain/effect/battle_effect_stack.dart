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
    BattleEffectEndTurnContext context,
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
    BattleEffectDamagePreventionContext context,
  ) {
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
    BattleEffectMoveContext context,
  ) {
    for (final effect in _effects) {
      final reason = effect.onMovePreventionTarget(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  BattleEffectUserMovePreventionResult? userMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    var nextState = context.state;
    var nextRng = context.rng;
    for (final effect in _effects) {
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

  bool _effectIsStillActive({
    required BattleEffect effect,
    required PsdkBattleState state,
    required PsdkBattleSlotRef owner,
  }) {
    return state.battlerAt(owner).effects.contains(effect.id);
  }
}
