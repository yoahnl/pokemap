import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/echoed_voice_effect.dart';
import '../../effect/move/rollout_effect.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _ConsecutivePowerKind {
  echoedVoice,
  furyCutter,
  round,
  rollout,
  iceBall,
  trumpCard,
}

/// Ports local power formulas that depend on repeated use or remaining PP.
///
/// Rollout and Ice Ball also keep the PSDK force-next-move counter so misses
/// interrupt the lock and successful hits advance the power stage.
final class ConsecutivePowerMoveBehavior implements BattleMoveBehavior {
  const ConsecutivePowerMoveBehavior.echoedVoice()
      : battleEngineMethod = 's_echo',
        _kind = _ConsecutivePowerKind.echoedVoice;

  const ConsecutivePowerMoveBehavior.furyCutter()
      : battleEngineMethod = 's_fury_cutter',
        _kind = _ConsecutivePowerKind.furyCutter;

  const ConsecutivePowerMoveBehavior.round()
      : battleEngineMethod = 's_round',
        _kind = _ConsecutivePowerKind.round;

  const ConsecutivePowerMoveBehavior.rollout()
      : battleEngineMethod = 's_rollout',
        _kind = _ConsecutivePowerKind.rollout;

  const ConsecutivePowerMoveBehavior.iceBall()
      : battleEngineMethod = 's_ice_ball',
        _kind = _ConsecutivePowerKind.iceBall;

  const ConsecutivePowerMoveBehavior.trumpCard()
      : battleEngineMethod = 's_trump_card',
        _kind = _ConsecutivePowerKind.trumpCard;

  @override
  final String battleEngineMethod;
  final _ConsecutivePowerKind _kind;

  bool get _isRolloutFamily =>
      _kind == _ConsecutivePowerKind.rollout ||
      _kind == _ConsecutivePowerKind.iceBall;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final accuracyBypass = _trumpCardBypassesAccuracy(context);
    final prepared = prepareBattleMove(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: _effectiveMove(context),
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
      forceAccuracyBypass: accuracyBypass,
    );
    final declaredState = _kind == _ConsecutivePowerKind.echoedVoice
        ? _increaseEchoedVoiceEffect(
            state: prepared.state,
            user: context.user,
          )
        : prepared.state;
    if (!prepared.shouldExecuteBehavior) {
      if (_isRolloutFamily) {
        return BattleMoveBehaviorResolution(
          state: _clearRolloutEffect(prepared.state, context.user),
          rng: prepared.rng,
          events: prepared.events,
          successful: false,
        );
      }
      return BattleMoveBehaviorResolution(
        state: declaredState,
        rng: prepared.rng,
        events: prepared.events,
        successful: false,
      );
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = declaredState.battlerAt(context.user);
    final target = declaredState.battlerAt(targetSlot);
    final move = _effectiveMove(
      BattleMoveBehaviorContext(
        state: declaredState,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
        target: targetSlot,
        move: context.move,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: move,
        rng: prepared.rng,
        field: declaredState.field,
        state: declaredState,
        userSlot: context.user,
        targetSlot: targetSlot,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: _isRolloutFamily
            ? _clearRolloutEffect(declaredState, context.user)
            : declaredState,
        rng: damageResult.rng,
        events: prepared.events,
        successful: !_isRolloutFamily,
      );
    }

    final applied = applyMoveTargetDamage(
      state: declaredState,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
      move: move,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: move,
      turn: context.turn,
    );
    final resolvedState = _isRolloutFamily
        ? _advanceRolloutEffect(
            state: secondary.state,
            user: context.user,
            moveId: context.move.id,
          )
        : secondary.state;

    return BattleMoveBehaviorResolution(
      state: resolvedState,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...applied.events,
        ...secondary.events,
      ],
    );
  }

  BattleMoveDefinition _effectiveMove(BattleMoveBehaviorContext context) {
    final user = context.state.battlerAt(context.user);
    final power = switch (_kind) {
      _ConsecutivePowerKind.echoedVoice =>
        (context.move.power + 40 * _echoedVoiceSuccessiveTurns(context.state))
            .clamp(0, 200)
            .toInt(),
      _ConsecutivePowerKind.furyCutter => (context.move.power *
              (1 << _sameSuccessfulAttemptStreak(user, context.move.id)))
          .clamp(0, 160)
          .toInt(),
      _ConsecutivePowerKind.round => _allyUsedRoundThisTurn(context)
          ? context.move.power * 2
          : context.move.power,
      _ConsecutivePowerKind.rollout ||
      _ConsecutivePowerKind.iceBall =>
        context.move.power *
            (1 <<
                (_rolloutSuccessiveUses(user, context.move.id) +
                    (_hasDefenseCurlSuccess(user) ? 1 : 0))),
      _ConsecutivePowerKind.trumpCard => _trumpCardPower(context.move),
    };
    return _copyMove(context.move, power: power);
  }

  bool _allyUsedRoundThisTurn(BattleMoveBehaviorContext context) {
    for (final allySlot in context.state.alliesOf(context.user)) {
      final ally = context.state.battlerAt(allySlot);
      if (ally.moveHistory.attempts.any(
        (entry) =>
            entry.turn == context.turn && entry.moveId == context.move.id,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _trumpCardBypassesAccuracy(BattleMoveBehaviorContext context) {
    if (_kind != _ConsecutivePowerKind.trumpCard) {
      return false;
    }
    final target = context.state.battlerAt(context.target);
    return !target.effects.contains('out_of_reach') &&
        !target.effects.contains('out_of_reach_base');
  }

  int _sameMoveStreak(PsdkBattleCombatant user, String moveId) {
    var streak = 0;
    final successes = user.moveHistory.successes;
    for (var index = successes.length - 1; index >= 0; index--) {
      if (successes[index].moveId != moveId) {
        break;
      }
      streak++;
    }
    return streak;
  }

  int _sameSuccessfulAttemptStreak(PsdkBattleCombatant user, String moveId) {
    var streak = 0;
    final attempts = user.moveHistory.attempts;
    final successes = user.moveHistory.successes;
    for (var index = attempts.length - 1; index >= 0; index--) {
      final attempt = attempts[index];
      if (attempt.moveId != moveId ||
          !_hasMatchingSuccess(successes: successes, attempt: attempt)) {
        break;
      }
      streak++;
    }
    return streak;
  }

  bool _hasMatchingSuccess({
    required List<PsdkBattleMoveHistoryEntry> successes,
    required PsdkBattleMoveHistoryEntry attempt,
  }) {
    return successes.any(
      (success) =>
          success.moveId == attempt.moveId &&
          success.turn == attempt.turn &&
          success.attackOrder == attempt.attackOrder,
    );
  }

  bool _hasDefenseCurlSuccess(PsdkBattleCombatant user) {
    return user.moveHistory.successes.any(
      (entry) => entry.moveId == 'defense_curl',
    );
  }

  int _echoedVoiceSuccessiveTurns(PsdkBattleState state) {
    return _currentEchoedVoiceEffect(state)?.effect.successiveTurns ?? 0;
  }

  ({PsdkBattleSlotRef owner, EchoedVoiceEffect effect})?
      _currentEchoedVoiceEffect(PsdkBattleState state) {
    for (final entry in state.combatants.entries) {
      for (final effect in entry.value.effects.effects) {
        if (effect is EchoedVoiceEffect &&
            effect.scope is FieldBattleEffectScope) {
          return (owner: entry.key, effect: effect);
        }
      }
    }
    return null;
  }

  PsdkBattleState _increaseEchoedVoiceEffect({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
  }) {
    final current = _currentEchoedVoiceEffect(state);
    if (current != null) {
      return state.updateBattler(
        current.owner,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(current.effect.increase()),
        ),
      );
    }

    return state.updateBattler(
      user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          const EchoedVoiceEffect(
            scope: FieldBattleEffectScope(),
            hasIncreased: true,
          ),
        ),
      ),
    );
  }

  int _rolloutSuccessiveUses(PsdkBattleCombatant user, String moveId) {
    final effect = _currentRolloutEffect(user, moveId);
    return effect?.successiveUses ?? _sameMoveStreak(user, moveId);
  }

  RolloutEffect? _currentRolloutEffect(
    PsdkBattleCombatant user,
    String moveId,
  ) {
    for (final effect in user.effects.effects) {
      if (effect is RolloutEffect && _sameMove(effect.forcedMoveId, moveId)) {
        return effect;
      }
    }
    return null;
  }

  PsdkBattleState _advanceRolloutEffect({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required String moveId,
  }) {
    final battler = state.battlerAt(user);
    final current = _currentRolloutEffect(battler, moveId);
    if (current == null) {
      return state.updateBattler(
        user,
        (currentBattler) => currentBattler.copyWith(
          effects: currentBattler.effects.addEffect(
            RolloutEffect(
              scope: BattlerBattleEffectScope(user),
              forcedMoveId: moveId,
              remainingTurns: 4,
              successiveUses: 1,
            ),
          ),
        ),
      );
    }

    final advanced = current.afterSuccessfulUse();
    if (advanced.remainingTurnsAfterCurrent <= 0) {
      return _clearRolloutEffect(state, user);
    }
    return state.updateBattler(
      user,
      (currentBattler) => currentBattler.copyWith(
        effects: currentBattler.effects.addEffect(advanced),
      ),
    );
  }

  PsdkBattleState _clearRolloutEffect(
    PsdkBattleState state,
    PsdkBattleSlotRef user,
  ) {
    final battler = state.battlerAt(user);
    if (!battler.effects.contains('rollout')) {
      return state;
    }
    return state.updateBattler(
      user,
      (current) => current.copyWith(effects: current.effects.remove('rollout')),
    );
  }

  int _trumpCardPower(BattleMoveDefinition move) {
    return switch (move.currentPp) {
      0 => 200,
      1 => 80,
      2 => 60,
      3 => 50,
      _ => 40,
    };
  }
}

bool _sameMove(String left, String right) {
  return _normalizedId(left) == _normalizedId(right);
}

String _normalizedId(String? id) {
  return id?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}

BattleMoveDefinition _copyMove(
  BattleMoveDefinition move, {
  required int power,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}
