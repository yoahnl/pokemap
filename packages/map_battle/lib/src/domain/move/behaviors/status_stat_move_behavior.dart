import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _StatusStatKind {
  target,
  selfStat,
  selfStatus,
}

/// Ports PSDK's generic `StatusStat`, `SelfStat` and `SelfStatus` families.
///
/// These are intentionally small wrappers around the common move procedure:
/// `StatusStat` skips damage and applies status/stat payloads to the selected
/// target, while the self variants keep Basic damage but redirect either stats
/// or statuses to the user.
final class StatusStatMoveBehavior implements BattleMoveBehavior {
  const StatusStatMoveBehavior.status()
      : battleEngineMethod = 's_status',
        _kind = _StatusStatKind.target;

  const StatusStatMoveBehavior.stat()
      : battleEngineMethod = 's_stat',
        _kind = _StatusStatKind.target;

  const StatusStatMoveBehavior.selfStat()
      : battleEngineMethod = 's_self_stat',
        _kind = _StatusStatKind.selfStat;

  const StatusStatMoveBehavior.selfStatus()
      : battleEngineMethod = 's_self_status',
        _kind = _StatusStatKind.selfStatus;

  @override
  final String battleEngineMethod;
  final _StatusStatKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _StatusStatKind.target => _resolveTargetStatusStat(
          context: context,
          prepared: prepared,
        ),
      _StatusStatKind.selfStat => _resolveSelfStat(
          context: context,
          prepared: prepared,
        ),
      _StatusStatKind.selfStatus => _resolveSelfStatus(
          context: context,
          prepared: prepared,
        ),
    };
  }

  BattleMoveBehaviorResolution _resolveTargetStatusStat({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: prepared.state,
      rng: prepared.rng,
      user: context.user,
      target: prepared.psdkTargets.single,
      move: _secondaryMove(context.move, effectChance: null),
      turn: context.turn,
    );
    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...secondary.events,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveSelfStat({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    if (_isPureStatusMove(context.move) &&
        !_hasApplicableStageMod(
          state: prepared.state,
          target: context.user,
          move: context.move,
        )) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.user,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
        successful: false,
      );
    }

    final damaged = _applyBasicDamage(
      context: context,
      prepared: prepared,
    );
    final withStatuses = _resolveSecondary(
      state: damaged.state,
      rng: damaged.rng,
      user: context.user,
      target: prepared.psdkTargets.single,
      move: _secondaryMove(
        context.move,
        stageMods: const <BattleStageMod>[],
      ),
      turn: context.turn,
    );
    final withStats = _resolveSecondary(
      state: withStatuses.state,
      rng: withStatuses.rng,
      user: context.user,
      target: context.user,
      move: _secondaryMove(
        context.move,
        statuses: const <PsdkBattleMoveStatus>[],
      ),
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: withStats.state,
      rng: withStats.rng,
      events: <PsdkBattleEvent>[
        ...damaged.events,
        ...withStatuses.events,
        ...withStats.events,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveSelfStatus({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final damaged = _applyBasicDamage(
      context: context,
      prepared: prepared,
    );
    final withStatuses = _resolveSecondary(
      state: damaged.state,
      rng: damaged.rng,
      user: context.user,
      target: context.user,
      move: _secondaryMove(
        context.move,
        stageMods: const <BattleStageMod>[],
      ),
      turn: context.turn,
    );
    final withStats = _resolveSecondary(
      state: withStatuses.state,
      rng: withStatuses.rng,
      user: context.user,
      target: prepared.psdkTargets.single,
      move: _secondaryMove(
        context.move,
        statuses: const <PsdkBattleMoveStatus>[],
      ),
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: withStats.state,
      rng: withStats.rng,
      events: <PsdkBattleEvent>[
        ...damaged.events,
        ...withStatuses.events,
        ...withStats.events,
      ],
    );
  }

  _DamageResolution _applyBasicDamage({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final events = <PsdkBattleEvent>[...prepared.events];
    if (context.move.category == PsdkBattleMoveCategory.status ||
        context.move.power <= 0) {
      return _DamageResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: events,
      );
    }

    final targetSlot = prepared.psdkTargets.single;
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: prepared.state.battlerAt(context.user),
        target: prepared.state.battlerAt(targetSlot),
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return _DamageResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    if (applied.event != null) {
      events.add(applied.event!);
    }
    return _DamageResolution(
      state: applied.state,
      rng: applied.rng,
      events: events,
    );
  }

  BattleMoveSecondaryEffectResult _resolveSecondary({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
    required int turn,
  }) {
    return const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: rng,
      user: user,
      target: target,
      move: move,
      turn: turn,
    );
  }
}

bool _isPureStatusMove(BattleMoveDefinition move) {
  return move.category == PsdkBattleMoveCategory.status && move.power <= 0;
}

bool _hasApplicableStageMod({
  required PsdkBattleState state,
  required PsdkBattleSlotRef target,
  required BattleMoveDefinition move,
}) {
  if (move.stageMods.isEmpty) {
    return false;
  }
  final stages = state.battlerAt(target).statStages;
  return move.stageMods.any((mod) {
    if (mod.stages == 0) {
      return false;
    }
    final currentStage = stages.valueOf(mod.stat);
    if (mod.stages > 0) {
      return currentStage < 6;
    }
    return currentStage > -6;
  });
}

BattleMoveDefinition _secondaryMove(
  BattleMoveDefinition move, {
  int? effectChance = _keepEffectChance,
  List<BattleStageMod>? stageMods,
  List<PsdkBattleMoveStatus>? statuses,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: move.power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance:
        effectChance == _keepEffectChance ? move.effectChance : effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: stageMods ?? move.stageMods,
    statuses: statuses ?? move.statuses,
  );
}

const int _keepEffectChance = -1;

final class _DamageResolution {
  const _DamageResolution({
    required this.state,
    required this.rng,
    required this.events,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}
