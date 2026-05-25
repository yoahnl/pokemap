import '../../../domain/effect/ability/ability_effect.dart';
import '../../../domain/effect/ability/mental_immunity_ability_effect.dart';
import '../../../domain/effect/ability/dancer_effect.dart';
import '../../../domain/effect/battle_effect_scope.dart';
import '../../../domain/effect/move/confusion_effect.dart';
import '../../../domain/effect/move/force_next_move_base_effect.dart';
import '../../../domain/effect/move/uproar_effect.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _ForcedActionMoveKind {
  gigatonHammer,
  thrash,
  outrage,
  uproar,
}

/// Ports local PSDK forced-action and repeated-action restrictions.
final class ForcedActionMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const ForcedActionMoveBehavior.gigatonHammer()
      : battleEngineMethod = 's_gigaton_hammer',
        _kind = _ForcedActionMoveKind.gigatonHammer;

  const ForcedActionMoveBehavior.thrash()
      : battleEngineMethod = 's_thrash',
        _kind = _ForcedActionMoveKind.thrash;

  const ForcedActionMoveBehavior.outrage()
      : battleEngineMethod = 's_outrage',
        _kind = _ForcedActionMoveKind.outrage;

  const ForcedActionMoveBehavior.uproar()
      : battleEngineMethod = 's_uproar',
        _kind = _ForcedActionMoveKind.uproar;

  @override
  final String battleEngineMethod;
  final _ForcedActionMoveKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    return switch (_kind) {
      _ForcedActionMoveKind.gigatonHammer =>
        _wasPreviousMove(user, context.move.id)
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _ForcedActionMoveKind.thrash ||
      _ForcedActionMoveKind.outrage ||
      _ForcedActionMoveKind.uproar =>
        null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final dancerReplay = _isDancerReplay(context.state.battlerAt(context.user));
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        successful: false,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
      );
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        field: prepared.state.field,
        state: prepared.state,
        userSlot: context.user,
        targetSlot: targetSlot,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyMoveTargetDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
      move: context.move,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    final forcedAction = _applyForcedActionEffect(
      state: secondary.state,
      rng: secondary.rng,
      turn: context.turn,
      user: context.user,
      moveId: context.move.id,
      dancerReplay: dancerReplay,
    );

    return BattleMoveBehaviorResolution(
      state: forcedAction.state,
      rng: forcedAction.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...applied.events,
        ...secondary.events,
        ...forcedAction.events,
      ],
    );
  }

  _ForcedActionEffectResult _applyForcedActionEffect({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef user,
    required String moveId,
    required bool dancerReplay,
  }) {
    return switch (_kind) {
      _ForcedActionMoveKind.gigatonHammer =>
        _ForcedActionEffectResult(state: state, rng: rng),
      _ForcedActionMoveKind.thrash ||
      _ForcedActionMoveKind.outrage =>
        dancerReplay
            ? _ForcedActionEffectResult(state: state, rng: rng)
            : _applyRepeatedMoveLock(
                state: state,
                rng: rng,
                user: user,
                moveId: moveId,
              ),
      _ForcedActionMoveKind.uproar => _applyUproarEffect(
          state: state,
          rng: rng,
          turn: turn,
          user: user,
          moveId: moveId,
        ),
    };
  }

  _ForcedActionEffectResult _applyUproarEffect({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef user,
    required String moveId,
  }) {
    var nextState = state.updateBattler(
      user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          UproarEffect(scope: BattlerBattleEffectScope(user)),
        ),
      ),
    );
    var nextRng = rng;
    final events = <PsdkBattleEvent>[];

    for (final slot in nextState.aliveSlots()) {
      if (nextState.battlerAt(slot).majorStatus !=
          PsdkBattleMajorStatus.sleep) {
        continue;
      }
      final cured = const BattleStatusChangeHandler().cureMajorStatus(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: turn,
          user: user,
        ),
        target: slot,
        moveId: moveId,
      );
      nextState = cured.state;
      nextRng = cured.rng;
      if (cured.applied) {
        events.addAll(cured.events);
      }
    }

    return _ForcedActionEffectResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }

  _ForcedActionEffectResult _applyRepeatedMoveLock({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef user,
    required String moveId,
  }) {
    final battler = state.battlerAt(user);
    final lock = _currentLock(battler, moveId);
    if (lock == null) {
      final durationRoll = rng.generic.nextIntInclusive(min: 2, max: 3);
      final nextState = state.updateBattler(
        user,
        (current) => current.copyWith(
          effects: current.effects.addEffect(
            ForceNextMoveBaseEffect.locked(
              scope: BattlerBattleEffectScope(user),
              forcedMoveId: moveId,
              remainingTurns: durationRoll.value - 1,
            ),
          ),
        ),
      );
      return _ForcedActionEffectResult(
        state: nextState,
        rng: rng.copyWith(generic: durationRoll.next),
      );
    }

    final remainingTurns = lock.remainingTurns ?? 1;
    if (remainingTurns <= 1) {
      return _ForcedActionEffectResult(
        state: state.updateBattler(
          user,
          (current) {
            final clearedEffects = current.effects.remove(lock.id);
            if (battleMentalAbilityBlocksEffect(
              state: state,
              user: user,
              target: user,
              effectId: PsdkBattleEffectIds.confusion,
            )) {
              return current.copyWith(effects: clearedEffects);
            }
            return current.copyWith(
              effects: clearedEffects.addEffect(
                ConfusionEffect(scope: BattlerBattleEffectScope(user)),
              ),
            );
          },
        ),
        rng: rng,
      );
    }

    return _ForcedActionEffectResult(
      state: state.updateBattler(
        user,
        (current) => current.copyWith(
          effects: current.effects.addEffect(
            lock.copyWithRemainingTurns(remainingTurns - 1),
          ),
        ),
      ),
      rng: rng,
    );
  }

  ForceNextMoveBaseEffect? _currentLock(
    PsdkBattleCombatant user,
    String moveId,
  ) {
    for (final effect in user.effects.effects) {
      if (effect is ForceNextMoveBaseEffect && effect.forcedMoveId == moveId) {
        return effect;
      }
    }
    return null;
  }

  bool _wasPreviousMove(PsdkBattleCombatant user, String moveId) {
    return user.moveHistory.lastSuccessfulMoveId == moveId ||
        user.moveHistory.lastMoveId == moveId;
  }
}

bool _isDancerReplay(PsdkBattleCombatant user) {
  return user.effects.contains(_dancerReplayActivatedEffectId) ||
      user.abilityEffects.any(
        (effect) => effect is DancerEffect && effect.activated,
      );
}

const _dancerReplayActivatedEffectId = 'dancer_replay_activated';

final class _ForcedActionEffectResult {
  const _ForcedActionEffectResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}
