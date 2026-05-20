import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _StatusCureMoveKind {
  healBell,
  takeHeart,
  sparklySwirl,
}

/// Ports PSDK move families whose local effect is curing major statuses.
///
/// These entries stay partial until Ruby's party-wide reserve traversal,
/// Soundproof/Heal Block style hooks and full multi-target process callbacks
/// exist in the clean battle lane.
final class StatusCureMoveBehavior implements BattleMoveBehavior {
  const StatusCureMoveBehavior.healBell()
      : battleEngineMethod = 's_heal_bell',
        _kind = _StatusCureMoveKind.healBell;

  const StatusCureMoveBehavior.takeHeart()
      : battleEngineMethod = 's_take_heart',
        _kind = _StatusCureMoveKind.takeHeart;

  const StatusCureMoveBehavior.sparklySwirl()
      : battleEngineMethod = 's_sparkly_swirl',
        _kind = _StatusCureMoveKind.sparklySwirl;

  @override
  final String battleEngineMethod;
  final _StatusCureMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    return switch (_kind) {
      _StatusCureMoveKind.healBell => _resolveHealBell(context),
      _StatusCureMoveKind.takeHeart => _resolveTakeHeart(context),
      _StatusCureMoveKind.sparklySwirl => _resolveSparklySwirl(context),
    };
  }

  BattleMoveBehaviorResolution _resolveHealBell(
    BattleMoveBehaviorContext context,
  ) {
    final procedureContext = _contextWithMove(
      context,
      _moveWithTarget(context.move, target: PsdkBattleMoveTarget.self),
    );
    final prepared = prepareBattleMove(procedureContext);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return _cureSlots(
      state: prepared.state,
      rng: prepared.rng,
      events: prepared.events,
      turn: context.turn,
      user: context.user,
      moveId: context.move.id,
      slots: _aliveSameBankIncludingUser(prepared.state, context.user),
    );
  }

  BattleMoveBehaviorResolution _resolveTakeHeart(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final cured = _cureSlots(
      state: prepared.state,
      rng: prepared.rng,
      events: prepared.events,
      turn: context.turn,
      user: context.user,
      moveId: context.move.id,
      slots: prepared.psdkTargets,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: cured.state,
      rng: cured.rng,
      user: context.user,
      target: context.user,
      move: context.move,
      turn: context.turn,
    );
    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...cured.events,
        ...secondary.events,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveSparklySwirl(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final targetSlot in prepared.psdkTargets) {
      final user = state.battlerAt(context.user);
      final target = state.battlerAt(targetSlot);
      final damageResult = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: user,
          target: target,
          move: context.move,
          rng: rng,
          field: state.field,
          state: state,
          userSlot: context.user,
          targetSlot: targetSlot,
        ),
      );
      rng = damageResult.rng;
      if (damageResult.damage <= 0) {
        continue;
      }

      final damage = applyDirectDamage(
        state: state,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damageResult.damage,
      );
      state = damage.state;
      rng = damage.rng;
      if (damage.event != null) {
        events.add(damage.event!);
      }

      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: context.user,
        target: targetSlot,
        move: context.move,
        turn: context.turn,
      );
      state = secondary.state;
      rng = secondary.rng;
      events.addAll(secondary.events);
    }

    return _cureSlots(
      state: state,
      rng: rng,
      events: events,
      turn: context.turn,
      user: context.user,
      moveId: context.move.id,
      slots: _aliveSameBankIncludingUser(state, context.user),
    );
  }

  BattleMoveBehaviorResolution _cureSlots({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required List<PsdkBattleEvent> events,
    required int turn,
    required PsdkBattleSlotRef user,
    required String moveId,
    required Iterable<PsdkBattleSlotRef> slots,
  }) {
    var nextState = state;
    var nextRng = rng;
    final nextEvents = <PsdkBattleEvent>[...events];

    for (final slot in slots) {
      final result = const BattleStatusChangeHandler().cureMajorStatus(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: turn,
          user: user,
        ),
        target: slot,
        moveId: moveId,
      );
      nextState = result.state;
      nextRng = result.rng;
      if (result.applied) {
        nextEvents.addAll(result.events);
      }
    }

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: nextRng,
      events: nextEvents,
    );
  }
}

List<PsdkBattleSlotRef> _aliveSameBankIncludingUser(
  PsdkBattleState state,
  PsdkBattleSlotRef user,
) {
  return state
      .aliveSlots()
      .where((slot) => slot.bank == user.bank)
      .toList(growable: false);
}

BattleMoveBehaviorContext _contextWithMove(
  BattleMoveBehaviorContext context,
  BattleMoveDefinition move,
) {
  return BattleMoveBehaviorContext(
    state: context.state,
    rng: context.rng,
    turn: context.turn,
    user: context.user,
    target: context.target,
    move: move,
    moveSlot: context.moveSlot,
    isLastActionOfTurn: context.isLastActionOfTurn,
    moveProcedureHooks: context.moveProcedureHooks,
  );
}

BattleMoveDefinition _moveWithTarget(
  BattleMoveDefinition move, {
  required PsdkBattleMoveTarget target,
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
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: target,
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}
