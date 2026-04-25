import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../handler/battle_handler_context.dart';
import '../handler/battle_stat_change_handler.dart';
import '../handler/battle_status_change_handler.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_move_data.dart';

final class BattleMoveSecondaryEffectResolver {
  const BattleMoveSecondaryEffectResolver();

  BattleMoveSecondaryEffectResult resolve({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
    required int turn,
  }) {
    if (move.statuses.isEmpty && move.stageMods.isEmpty) {
      return BattleMoveSecondaryEffectResult(
        state: state,
        rng: rng,
        events: const <PsdkBattleEvent>[],
      );
    }

    var nextState = state;
    var nextRng = rng;
    final events = <PsdkBattleEvent>[];

    final globalChance = move.effectChance;
    if (globalChance != null && globalChance < 100) {
      final roll = nextRng.generic.nextPercent();
      nextRng = nextRng.copyWith(generic: roll.next);
      if (roll.value > globalChance) {
        return BattleMoveSecondaryEffectResult(
          state: nextState,
          rng: nextRng,
          events: events,
        );
      }
    }

    for (final status in move.statuses) {
      if (globalChance == null && status.chance < 100) {
        final roll = nextRng.generic.nextPercent();
        nextRng = nextRng.copyWith(generic: roll.next);
        if (roll.value > status.chance) {
          continue;
        }
      }

      final result = const BattleStatusChangeHandler().applyMajorStatus(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: turn,
          user: user,
        ),
        target: target,
        moveId: move.id,
        status: status.status,
      );
      nextState = result.state;
      nextRng = result.rng;
      if (result.applied) {
        events.addAll(result.events);
      }
    }

    for (final mod in move.stageMods) {
      if (mod.stages == 0) {
        continue;
      }
      if (globalChance == null && mod.chance != null && mod.chance! < 100) {
        final roll = nextRng.generic.nextPercent();
        nextRng = nextRng.copyWith(generic: roll.next);
        if (roll.value > mod.chance!) {
          continue;
        }
      }

      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: turn,
          user: user,
        ),
        target: target,
        stat: mod.stat,
        stages: mod.stages,
      );
      nextState = result.state;
      nextRng = result.rng;
      if (result.applied) {
        events.addAll(result.events);
      }
    }

    return BattleMoveSecondaryEffectResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

final class BattleMoveSecondaryEffectResult {
  BattleMoveSecondaryEffectResult({
    required this.state,
    required this.rng,
    required List<PsdkBattleEvent> events,
  }) : events = List<PsdkBattleEvent>.unmodifiable(events);

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}
