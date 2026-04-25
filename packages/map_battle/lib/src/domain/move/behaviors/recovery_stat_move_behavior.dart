import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _RecoveryStatKind {
  rest,
  bellyDrum,
  strengthSap,
}

/// Ports small PSDK status moves that combine HP, major status and stat-stage
/// changes without needing a persistent effect object.
///
/// These stay partial in the manifest until item/ability/effect gates such as
/// Chesto Berry, Heal Block, Liquid Ooze, Big Root, Contrary and terrain sleep
/// prevention are represented by first-class hooks.
final class RecoveryStatMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const RecoveryStatMoveBehavior.rest()
      : battleEngineMethod = 's_rest',
        _kind = _RecoveryStatKind.rest;

  const RecoveryStatMoveBehavior.bellyDrum()
      : battleEngineMethod = 's_bellydrum',
        _kind = _RecoveryStatKind.bellyDrum;

  const RecoveryStatMoveBehavior.strengthSap()
      : battleEngineMethod = 's_strength_sap',
        _kind = _RecoveryStatKind.strengthSap;

  @override
  final String battleEngineMethod;
  final _RecoveryStatKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    return switch (_kind) {
      _RecoveryStatKind.rest => user.currentHp >= user.maxHp ||
              _hasAbilityId(
                user.abilityId,
                const <String>{
                  'comatose',
                  'insomnia',
                  'purifying_salt',
                  'sweet_veil',
                  'vital_spirit',
                },
              )
          ? const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            )
          : null,
      _RecoveryStatKind.bellyDrum => user.currentHp * 2 <= user.maxHp ||
              user.statStages.valueOf('attack') >= 6
          ? const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            )
          : null,
      _RecoveryStatKind.strengthSap =>
        context.state.battlerAt(context.target).statStages.valueOf('attack') <=
                -6
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failedBeforeProcedure(context, prevention);
    }

    return switch (_kind) {
      _RecoveryStatKind.rest => _resolveRest(context),
      _RecoveryStatKind.bellyDrum => _resolveBellyDrum(context),
      _RecoveryStatKind.strengthSap => _resolveStrengthSap(context),
    };
  }

  BattleMoveBehaviorResolution _resolveRest(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final target = state.battlerAt(targetSlot);
    if (target.majorStatus != null) {
      final cure = const BattleStatusChangeHandler().cureMajorStatus(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: targetSlot,
        moveId: context.move.id,
      );
      state = cure.state;
      rng = cure.rng;
      if (cure.applied) {
        events.addAll(cure.events);
      }
    }

    final sleep = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
      ),
      target: targetSlot,
      moveId: context.move.id,
      status: PsdkBattleMajorStatus.sleep,
    );
    state = sleep.state;
    rng = sleep.rng;
    if (sleep.applied) {
      events.addAll(sleep.events);
    }

    final healedTarget = state.battlerAt(targetSlot);
    final heal = applyDirectHeal(
      state: state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: healedTarget.maxHp,
    );
    state = heal.state;
    rng = heal.rng;
    if (heal.event != null) {
      events.add(heal.event!);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveBellyDrum(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final target = state.battlerAt(targetSlot);
    final damage = applyDirectDamage(
      state: state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: target.maxHp ~/ 2,
    );
    state = damage.state;
    rng = damage.rng;
    if (damage.event != null) {
      events.add(damage.event!);
    }

    final stat = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
      ),
      target: targetSlot,
      stat: 'attack',
      stages: 12,
    );
    state = stat.state;
    rng = stat.rng;
    if (stat.applied) {
      events.addAll(stat.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveStrengthSap(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final target = state.battlerAt(targetSlot);
    final heal = applyDirectHeal(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: target.effectiveStat('attack'),
    );
    state = heal.state;
    rng = heal.rng;
    if (heal.event != null) {
      events.add(heal.event!);
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

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _failedBeforeProcedure(
    BattleMoveBehaviorContext context,
    BattleMoveUserPreventionResult prevention,
  ) {
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
}

bool _hasAbilityId(String? abilityId, Set<String> expectedIds) {
  if (abilityId == null) {
    return false;
  }
  return expectedIds.contains(abilityId.toLowerCase());
}
