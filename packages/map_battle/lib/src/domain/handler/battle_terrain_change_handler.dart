import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_hooks.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleTerrainChangeHandler {
  const BattleTerrainChangeHandler();

  BattleHandlerResult changeTerrain({
    required BattleHandlerContext context,
    required PsdkBattleTerrainId terrain,
    int remainingTurns = 5,
  }) {
    if (context.state.field.terrain?.id == terrain) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'terrain_already_active',
      );
    }
    final lastTerrain = context.state.field.terrain?.id;
    final hookPrevention = _terrainPreventionReason(
      context: context,
      terrain: terrain,
      lastTerrain: lastTerrain,
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
      field: context.state.field.withTerrain(
        terrain,
        remainingTurns: remainingTurns,
      ),
    );
    final post = _dispatchPostTerrainChange(
      context: BattleHandlerContext(
        state: baseState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      terrain: terrain,
      lastTerrain: lastTerrain,
      remainingTurns: remainingTurns,
    );

    return BattleHandlerResult(
      state: post.state,
      rng: post.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleTerrainChangedEvent(
          turn: context.turn,
          terrain: terrain,
          remainingTurns: remainingTurns,
        ),
        ...post.events,
      ],
    );
  }

  BattleHandlerResult clearTerrain({
    required BattleHandlerContext context,
    String reason = 'cleared',
  }) {
    if (context.state.field.terrain == null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'terrain_already_clear',
      );
    }
    final lastTerrain = context.state.field.terrain?.id;
    final hookPrevention = _terrainPreventionReason(
      context: context,
      terrain: null,
      lastTerrain: lastTerrain,
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
      field: context.state.field.clearTerrain(),
    );
    final post = _dispatchPostTerrainChange(
      context: BattleHandlerContext(
        state: baseState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      terrain: null,
      lastTerrain: lastTerrain,
      remainingTurns: null,
    );

    return BattleHandlerResult(
      state: post.state,
      rng: post.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleTerrainChangedEvent(
          turn: context.turn,
          terrain: null,
          reason: reason,
        ),
        ...post.events,
      ],
    );
  }
}

String? _terrainPreventionReason({
  required BattleHandlerContext context,
  required PsdkBattleTerrainId? terrain,
  required PsdkBattleTerrainId? lastTerrain,
}) {
  for (final owner in _orderedSlots(context.state)) {
    final reason =
        context.state.battlerAt(owner).effects.terrainPreventionReason(
              BattleEffectTerrainPreventionContext(
                state: context.state,
                rng: context.rng,
                turn: context.turn,
                owner: owner,
                user: context.user,
                terrain: terrain,
                lastTerrain: lastTerrain,
              ),
            );
    if (reason != null) {
      return reason;
    }
  }
  return null;
}

BattleEffectFieldChangeResult _dispatchPostTerrainChange({
  required BattleHandlerContext context,
  required PsdkBattleTerrainId? terrain,
  required PsdkBattleTerrainId? lastTerrain,
  required int? remainingTurns,
}) {
  var nextState = context.state;
  var nextRng = context.rng;
  final events = <PsdkBattleEvent>[];
  var changed = false;
  for (final owner in _orderedSlots(nextState)) {
    final result = nextState.battlerAt(owner).effects.dispatchPostTerrainChange(
          BattleEffectTerrainChangeContext(
            state: nextState,
            rng: nextRng,
            turn: context.turn,
            owner: owner,
            user: context.user,
            terrain: terrain,
            lastTerrain: lastTerrain,
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
