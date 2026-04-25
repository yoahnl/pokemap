import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
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

      final battler = nextState.battlerAt(target);
      if (battler.majorStatus != null) {
        continue;
      }
      nextState = nextState.replaceBattler(
        target,
        battler.copyWith(majorStatus: status.status),
      );
      events.add(
        PsdkBattleStatusEvent(
          user: user,
          target: target,
          moveId: move.id,
          status: status.status,
        ),
      );
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

      final battler = nextState.battlerAt(target);
      final statStages = battler.statStages.apply(
        stat: mod.stat,
        stages: mod.stages,
      );
      final nextBattler = battler.copyWith(statStages: statStages);
      nextState = nextState.replaceBattler(target, nextBattler);
      events.add(
        PsdkBattleStatStageEvent(
          target: target,
          stat: mod.stat,
          amount: mod.stages,
          currentStage: statStages.valueOf(mod.stat),
        ),
      );
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
