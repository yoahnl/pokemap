import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _AdvancedStatKind {
  growth,
  haze,
  psychUp,
  topsyTurvy,
}

/// Ports PSDK stat-stage moves that need direct stage reset/copy/inversion.
///
/// These stay partial until Crafty Shield, Contrary/Mirror Armor style hooks
/// and richer effect interactions can intercept the same paths as Ruby PSDK.
final class AdvancedStatMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const AdvancedStatMoveBehavior.growth()
      : battleEngineMethod = 's_growth',
        _kind = _AdvancedStatKind.growth;

  const AdvancedStatMoveBehavior.haze()
      : battleEngineMethod = 's_haze',
        _kind = _AdvancedStatKind.haze;

  const AdvancedStatMoveBehavior.psychUp()
      : battleEngineMethod = 's_psych_up',
        _kind = _AdvancedStatKind.psychUp;

  const AdvancedStatMoveBehavior.topsyTurvy()
      : battleEngineMethod = 's_topsy_turvy',
        _kind = _AdvancedStatKind.topsyTurvy;

  @override
  final String battleEngineMethod;
  final _AdvancedStatKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final state = context.state;
    return switch (_kind) {
      _AdvancedStatKind.haze => state.aliveSlots().every(
                (slot) => state.battlerAt(slot).statStages.values.isEmpty,
              )
          ? const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            )
          : null,
      _AdvancedStatKind.topsyTurvy =>
        state.battlerAt(context.target).statStages.values.isEmpty
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _ => null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
        successful: false,
      );
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _AdvancedStatKind.growth => _resolveGrowth(context, prepared),
      _AdvancedStatKind.haze => _resolveHaze(context, prepared),
      _AdvancedStatKind.psychUp => _resolvePsychUp(context, prepared),
      _AdvancedStatKind.topsyTurvy => _resolveTopsyTurvy(context, prepared),
    };
  }

  BattleMoveBehaviorResolution _resolveGrowth(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final stages = _isSunny(state.field) ? 2 : 1;
    for (final stat in context.move.stageMods) {
      final result = _setStageDelta(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: context.user,
        stat: stat.stat,
        delta: stages,
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveHaze(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    for (final slot in state.aliveSlots()) {
      for (final entry in state.battlerAt(slot).statStages.values.entries) {
        final result = _setStageTo(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
          target: slot,
          stat: entry.key,
          desiredStage: 0,
        );
        state = result.state;
        rng = result.rng;
        events.addAll(result.events);
      }
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolvePsychUp(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final userStages = state.battlerAt(context.user).statStages.values;
    final targetStages = state.battlerAt(targetSlot).statStages.values;
    final stats = <String>{...userStages.keys, ...targetStages.keys}.toList()
      ..sort();
    for (final stat in stats) {
      final result = _setStageTo(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: context.user,
        stat: stat,
        desiredStage: targetStages[stat] ?? 0,
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveTopsyTurvy(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final targetStages = state.battlerAt(targetSlot).statStages.values;
    final stats = targetStages.keys.toList()..sort();
    for (final stat in stats) {
      final result = _setStageTo(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: targetSlot,
        stat: stat,
        desiredStage: -(targetStages[stat] ?? 0),
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }
}

_StatStageMutation _setStageDelta({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String stat,
  required int delta,
}) {
  final battler = state.battlerAt(target);
  final desired = (battler.statStages.valueOf(stat) + delta).clamp(-6, 6);
  return _setStageTo(
    state: state,
    rng: rng,
    turn: turn,
    user: user,
    target: target,
    stat: stat,
    desiredStage: desired.toInt(),
  );
}

_StatStageMutation _setStageTo({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String stat,
  required int desiredStage,
}) {
  final battler = state.battlerAt(target);
  final normalized = _normalizeStat(stat);
  final currentStage = battler.statStages.valueOf(normalized);
  final clampedStage = desiredStage.clamp(-6, 6).toInt();
  final delta = clampedStage - currentStage;
  if (delta == 0) {
    return _StatStageMutation(
      state: state,
      rng: rng,
      events: const <PsdkBattleEvent>[],
    );
  }

  final values = Map<String, int>.from(battler.statStages.values);
  if (clampedStage == 0) {
    values.remove(normalized);
  } else {
    values[normalized] = clampedStage;
  }
  final nextBattler = battler
      .copyWith(statStages: PsdkBattleStatStages(values: values))
      .recordStatChange(
        turn: turn,
        stat: normalized,
        delta: delta,
        currentStage: clampedStage,
      );
  return _StatStageMutation(
    state: state.replaceBattler(target, nextBattler),
    rng: rng,
    events: <PsdkBattleEvent>[
      PsdkBattleStatStageEvent(
        target: target,
        stat: normalized,
        amount: delta,
        currentStage: clampedStage,
      ),
    ],
  );
}

bool _isSunny(PsdkBattleFieldState field) {
  return field.isWeatherActive(PsdkBattleWeatherId.sunny) ||
      field.isWeatherActive(PsdkBattleWeatherId.hardsun);
}

String _normalizeStat(String stat) {
  final token = stat.trim();
  final normalized = token.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
  return switch (normalized) {
    'atk' || 'attack' => 'attack',
    'def' || 'dfe' || 'defense' => 'defense',
    'ats' || 'spa' || 'spatk' || 'specialattack' => 'specialAttack',
    'dfs' || 'spdef' || 'specialdefense' => 'specialDefense',
    'spd' || 'spe' || 'speed' => 'speed',
    _ => token,
  };
}

final class _StatStageMutation {
  const _StatStageMutation({
    required this.state,
    required this.rng,
    required this.events,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}
