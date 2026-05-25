import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
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
    final user = prepared.psdkUser;
    if (context.move.battleEngineMethod == 's_status' &&
        _isPureStatusMove(context.move) &&
        context.move.stageMods.isEmpty &&
        _majorStatuses(context.move).isNotEmpty &&
        !prepared.psdkTargets.any((target) {
          return _hasApplicableMajorStatus(
            state: prepared.state,
            rng: prepared.rng,
            turn: context.turn,
            user: user,
            target: target,
            move: context.move,
          );
        })) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: user,
            target: prepared.psdkTargets.isEmpty
                ? context.target
                : prepared.psdkTargets.first,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
        successful: false,
      );
    }

    if (context.move.battleEngineMethod == 's_stat' &&
        _isPureStatusMove(context.move) &&
        context.move.statuses.isEmpty &&
        !prepared.psdkTargets.any((target) {
          return _hasApplicableStageMod(
            state: prepared.state,
            user: user,
            target: target,
            move: context.move,
          );
        })) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: user,
            target: prepared.psdkTargets.isEmpty
                ? context.target
                : prepared.psdkTargets.first,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
        successful: false,
      );
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final move = _secondaryMove(context.move, effectChance: null);
    for (final target in prepared.psdkTargets) {
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: user,
        target: target,
        move: move,
        turn: context.turn,
      );
      state = secondary.state;
      rng = secondary.rng;
      events.addAll(secondary.events);
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveSelfStat({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final user = prepared.psdkUser;
    if (_isPureStatusMove(context.move) &&
        !_hasApplicableStageMod(
          state: prepared.state,
          user: user,
          target: user,
          move: context.move,
        )) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: user,
            target: user,
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
    var state = damaged.state;
    var rng = damaged.rng;
    final events = <PsdkBattleEvent>[...damaged.events];
    if (context.move.statuses.isNotEmpty) {
      final statusMove = _secondaryMove(
        context.move,
        stageMods: const <BattleStageMod>[],
      );
      for (final target in prepared.psdkTargets) {
        final withStatuses = _resolveSecondary(
          state: state,
          rng: rng,
          user: user,
          target: target,
          move: statusMove,
          turn: context.turn,
        );
        state = withStatuses.state;
        rng = withStatuses.rng;
        events.addAll(withStatuses.events);
      }
    }
    final withStats = _resolveSecondary(
      state: state,
      rng: rng,
      user: user,
      target: user,
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
        ...events,
        ...withStats.events,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveSelfStatus({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final user = prepared.psdkUser;
    if (_isPureStatusMove(context.move) &&
        context.move.stageMods.isEmpty &&
        context.move.statuses.isNotEmpty &&
        !_hasApplicableMoveStatus(
          state: prepared.state,
          rng: prepared.rng,
          turn: context.turn,
          user: user,
          target: user,
          move: context.move,
        )) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: user,
            target: user,
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
    var state = damaged.state;
    var rng = damaged.rng;
    final events = <PsdkBattleEvent>[...damaged.events];
    if (context.move.statuses.isNotEmpty) {
      final withStatuses = _resolveSecondary(
        state: state,
        rng: rng,
        user: user,
        target: user,
        move: _secondaryMove(
          context.move,
          stageMods: const <BattleStageMod>[],
        ),
        turn: context.turn,
      );
      state = withStatuses.state;
      rng = withStatuses.rng;
      events.addAll(withStatuses.events);
    }
    if (context.move.stageMods.isNotEmpty) {
      final statMove = _secondaryMove(
        context.move,
        statuses: const <PsdkBattleMoveStatus>[],
      );
      for (final target in prepared.psdkTargets) {
        final withStats = _resolveSecondary(
          state: state,
          rng: rng,
          user: user,
          target: target,
          move: statMove,
          turn: context.turn,
        );
        state = withStats.state;
        rng = withStats.rng;
        events.addAll(withStats.events);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
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

    var state = prepared.state;
    var rng = prepared.rng;
    final user = prepared.psdkUser;
    for (final targetSlot in prepared.psdkTargets) {
      final damageResult = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: state.battlerAt(user),
          target: state.battlerAt(targetSlot),
          move: context.move,
          rng: rng,
          field: state.field,
          state: state,
          userSlot: user,
          targetSlot: targetSlot,
        ),
      );
      rng = damageResult.rng;
      if (damageResult.damage <= 0) {
        continue;
      }

      final applied = applyMoveTargetDamage(
        state: state,
        user: user,
        target: targetSlot,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damageResult.damage,
        moveCategory: context.move.category,
        move: context.move,
        targetCount: prepared.psdkTargets.length,
      );
      state = applied.state;
      rng = applied.rng;
      events.addAll(applied.events);
    }
    return _DamageResolution(
      state: state,
      rng: rng,
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
  required PsdkBattleSlotRef user,
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
    if (mod.stages < 0 &&
        user.bank != target.bank &&
        state.battlerAt(target).effects.contains('mist')) {
      return false;
    }
    final currentStage = stages.valueOf(mod.stat);
    if (mod.stages > 0) {
      return currentStage < 6;
    }
    return currentStage > -6;
  });
}

bool _hasApplicableMajorStatus({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required BattleMoveDefinition move,
}) {
  final context = BattleHandlerContext(
    state: state,
    rng: rng,
    turn: turn,
    user: user,
  );
  return _majorStatuses(move).any(
    (status) => const BattleStatusChangeHandler().canApplyMajorStatus(
      context: context,
      target: target,
      status: status,
      move: move,
    ),
  );
}

bool _hasApplicableMoveStatus({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required BattleMoveDefinition move,
}) {
  final context = BattleHandlerContext(
    state: state,
    rng: rng,
    turn: turn,
    user: user,
  );
  final targetBattler = state.battlerAt(target);
  return move.statuses.any((status) {
    final majorStatus = status.majorStatus;
    if (majorStatus != null) {
      return const BattleStatusChangeHandler().canApplyMajorStatus(
        context: context,
        target: target,
        status: majorStatus,
        move: move,
      );
    }
    return switch (status.volatileStatus) {
      PsdkBattleVolatileStatus.confusion =>
        !targetBattler.effects.contains(PsdkBattleEffectIds.confusion),
      PsdkBattleVolatileStatus.flinch =>
        !targetBattler.effects.contains(PsdkBattleEffectIds.flinch),
      null => false,
    };
  });
}

List<PsdkBattleMajorStatus> _majorStatuses(BattleMoveDefinition move) {
  return move.statuses
      .map((status) => status.majorStatus)
      .whereType<PsdkBattleMajorStatus>()
      .toList(growable: false);
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
