import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _ConsecutivePowerKind {
  echoedVoice,
  furyCutter,
  rollout,
  iceBall,
  trumpCard,
}

/// Ports local power formulas that depend on repeated use or remaining PP.
///
/// This slice intentionally reads the existing clean move history instead of
/// introducing full PSDK force-next-move effects for Rollout/Ice Ball.
final class ConsecutivePowerMoveBehavior implements BattleMoveBehavior {
  const ConsecutivePowerMoveBehavior.echoedVoice()
      : battleEngineMethod = 's_echo',
        _kind = _ConsecutivePowerKind.echoedVoice;

  const ConsecutivePowerMoveBehavior.furyCutter()
      : battleEngineMethod = 's_fury_cutter',
        _kind = _ConsecutivePowerKind.furyCutter;

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
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
      forceAccuracyBypass: accuracyBypass,
    );
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final move = _effectiveMove(
      BattleMoveBehaviorContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
        target: targetSlot,
        move: context.move,
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
        field: prepared.state.field,
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
      move: move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  BattleMoveDefinition _effectiveMove(BattleMoveBehaviorContext context) {
    final user = context.state.battlerAt(context.user);
    final power = switch (_kind) {
      _ConsecutivePowerKind.echoedVoice =>
        (context.move.power + 40 * _sameMoveStreak(user, context.move.id))
            .clamp(0, 200)
            .toInt(),
      _ConsecutivePowerKind.furyCutter =>
        (context.move.power * (1 << _sameMoveStreak(user, context.move.id)))
            .clamp(0, 160)
            .toInt(),
      _ConsecutivePowerKind.rollout ||
      _ConsecutivePowerKind.iceBall =>
        context.move.power *
            (1 <<
                (_sameMoveStreak(user, context.move.id) +
                    (_hasDefenseCurlSuccess(user) ? 1 : 0))),
      _ConsecutivePowerKind.trumpCard => _trumpCardPower(context.move),
    };
    return _copyMove(context.move, power: power);
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

  bool _hasDefenseCurlSuccess(PsdkBattleCombatant user) {
    return user.moveHistory.successes.any(
      (entry) => entry.moveId == 'defense_curl',
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
