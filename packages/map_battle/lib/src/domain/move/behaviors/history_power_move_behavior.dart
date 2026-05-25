import '../../battler/battle_combatant_history.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _HistoryPowerKind {
  assurance,
  avalanche,
  fishiousRend,
  lashOut,
  payback,
  rageFist,
  retaliate,
  revenge,
  stompingTantrum,
}

/// Ports PSDK damage-history base-power rules.
///
/// The registry keeps methods with broader party/faint/action-history
/// dependencies partial until those surrounding semantics are covered too.
final class HistoryPowerMoveBehavior implements BattleMoveBehavior {
  const HistoryPowerMoveBehavior.assurance()
      : battleEngineMethod = 's_assurance',
        _kind = _HistoryPowerKind.assurance;

  const HistoryPowerMoveBehavior.avalanche()
      : battleEngineMethod = 's_avalanche',
        _kind = _HistoryPowerKind.avalanche;

  const HistoryPowerMoveBehavior.fishiousRend()
      : battleEngineMethod = 's_fishious_rend',
        _kind = _HistoryPowerKind.fishiousRend;

  const HistoryPowerMoveBehavior.lashOut()
      : battleEngineMethod = 's_lash_out',
        _kind = _HistoryPowerKind.lashOut;

  const HistoryPowerMoveBehavior.payback()
      : battleEngineMethod = 's_payback',
        _kind = _HistoryPowerKind.payback;

  const HistoryPowerMoveBehavior.rageFist()
      : battleEngineMethod = 's_rage_fist',
        _kind = _HistoryPowerKind.rageFist;

  const HistoryPowerMoveBehavior.retaliate()
      : battleEngineMethod = 's_retaliate',
        _kind = _HistoryPowerKind.retaliate;

  const HistoryPowerMoveBehavior.revenge()
      : battleEngineMethod = 's_revenge',
        _kind = _HistoryPowerKind.revenge;

  const HistoryPowerMoveBehavior.stompingTantrum()
      : battleEngineMethod = 's_stomping_tantrum',
        _kind = _HistoryPowerKind.stompingTantrum;

  @override
  final String battleEngineMethod;
  final _HistoryPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = _resolvePower(
      movePower: context.move.power,
      state: prepared.state,
      userSlot: context.user,
      user: user,
      target: targetSlot,
      targetCombatant: target,
      turn: context.turn,
    );
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
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
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

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...applied.events,
        ...secondary.events,
      ],
    );
  }

  int _resolvePower({
    required int movePower,
    required PsdkBattleState state,
    required PsdkBattleSlotRef userSlot,
    required PsdkBattleCombatant user,
    required PsdkBattleSlotRef target,
    required PsdkBattleCombatant targetCombatant,
    required int turn,
  }) {
    return switch (_kind) {
      _HistoryPowerKind.assurance =>
        _wasDamagedThisTurn(targetCombatant, turn) ? movePower * 2 : movePower,
      _HistoryPowerKind.avalanche ||
      _HistoryPowerKind.revenge =>
        _wasDamagedByTargetThisTurn(user, target, turn)
            ? movePower * 2
            : movePower,
      _HistoryPowerKind.fishiousRend =>
        _targetHasNotAttemptedThisTurn(targetCombatant, turn) ||
                targetCombatant.switching
            ? movePower * 2
            : movePower,
      _HistoryPowerKind.lashOut =>
        _hadNegativeStatChangeThisTurn(user, turn) ? movePower * 2 : movePower,
      _HistoryPowerKind.payback =>
        _wasDamagedThisTurn(user, turn) ? movePower * 2 : movePower,
      _HistoryPowerKind.rageFist => (movePower +
              user.damageHistory.entries.where(_isMoveDamageEntry).length * 50)
          .clamp(1, 350)
          .toInt(),
      _HistoryPowerKind.retaliate => _sameBankBattlerFaintedLastTurn(
          state: state,
          userSlot: userSlot,
          turn: turn,
        )
            ? movePower * 2
            : movePower,
      _HistoryPowerKind.stompingTantrum =>
        _previousMoveFailed(user) ? movePower * 2 : movePower,
    };
  }

  bool _wasDamagedByTargetThisTurn(
    PsdkBattleCombatant user,
    PsdkBattleSlotRef target,
    int turn,
  ) {
    return user.damageHistory.entries.any(
      (entry) => entry.turn == turn && entry.source == target,
    );
  }

  bool _wasDamagedThisTurn(PsdkBattleCombatant user, int turn) {
    return user.damageHistory.entries.any((entry) => entry.turn == turn);
  }

  bool _isMoveDamageEntry(PsdkBattleDamageHistoryEntry entry) {
    return !entry.moveId.startsWith('effect:') &&
        !entry.moveId.startsWith('item:') &&
        !entry.moveId.startsWith('status:');
  }

  bool _targetHasNotAttemptedThisTurn(PsdkBattleCombatant target, int turn) {
    return target.moveHistory.attempts.every((entry) => entry.turn != turn);
  }

  bool _hadNegativeStatChangeThisTurn(PsdkBattleCombatant user, int turn) {
    final entries = user.statHistory.entries;
    if (entries.isEmpty) {
      return false;
    }
    final last = entries.last;
    return last.turn == turn && last.delta < 0;
  }

  bool _previousMoveFailed(PsdkBattleCombatant user) {
    final attempts = user.moveHistory.attempts;
    if (attempts.isEmpty) {
      return false;
    }
    final lastAttempt = attempts.last;
    final successes = user.moveHistory.successes;
    return successes.isEmpty || successes.last.turn != lastAttempt.turn;
  }

  bool _sameBankBattlerFaintedLastTurn({
    required PsdkBattleState state,
    required PsdkBattleSlotRef userSlot,
    required int turn,
  }) {
    return state.combatants.entries.any((entry) {
      final slot = entry.key;
      if (slot.bank != userSlot.bank || slot == userSlot) {
        return false;
      }
      return entry.value.damageHistory.entries.any(
        (damage) => damage.turn == turn - 1 && damage.remainingHp <= 0,
      );
    });
  }
}
