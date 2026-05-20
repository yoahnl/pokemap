import '../../../domain/effect/battle_effect.dart';
import '../../../domain/effect/battle_effect_scope.dart';
import '../../../domain/effect/move/confusion_effect.dart';
import '../../../domain/effect/move/force_next_move_base_effect.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
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

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
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
      user: context.user,
      moveId: context.move.id,
    );

    return BattleMoveBehaviorResolution(
      state: forcedAction.state,
      rng: forcedAction.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  _ForcedActionEffectResult _applyForcedActionEffect({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef user,
    required String moveId,
  }) {
    return switch (_kind) {
      _ForcedActionMoveKind.gigatonHammer =>
        _ForcedActionEffectResult(state: state, rng: rng),
      _ForcedActionMoveKind.thrash ||
      _ForcedActionMoveKind.outrage =>
        _applyRepeatedMoveLock(
            state: state, rng: rng, user: user, moveId: moveId),
      _ForcedActionMoveKind.uproar => _ForcedActionEffectResult(
          state: state.updateBattler(
            user,
            (battler) => battler.copyWith(
              effects: battler.effects.addEffect(
                GenericBattleEffect(
                  id: 'uproar',
                  scope: BattlerBattleEffectScope(user),
                  remainingTurns: 3,
                ),
              ),
            ),
          ),
          rng: rng,
        ),
    };
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
          (current) => current.copyWith(
            effects: current.effects.remove(lock.id).addEffect(
                  ConfusionEffect(scope: BattlerBattleEffectScope(user)),
                ),
          ),
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

final class _ForcedActionEffectResult {
  const _ForcedActionEffectResult({
    required this.state,
    required this.rng,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
}
