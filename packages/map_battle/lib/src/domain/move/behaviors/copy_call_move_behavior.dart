import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_data.dart';
import '../battle_move_prevention.dart';
import '../../rng/battle_rng_streams.dart';
import 'battle_move_behavior_support.dart';

typedef BattleCalledMoveResolver = BattleMoveBehaviorResolution Function(
  BattleMoveBehaviorContext context,
  BattleMoveDefinition move,
);

enum _CopyCallMoveKind {
  sleepTalk,
  mimic,
  sketch,
}

final class CopyCallMoveBehavior implements BattleMoveUserPreventionBehavior {
  const CopyCallMoveBehavior.sleepTalk({
    required BattleCalledMoveResolver callMove,
  })  : battleEngineMethod = 's_sleep_talk',
        _kind = _CopyCallMoveKind.sleepTalk,
        _callMove = callMove;

  const CopyCallMoveBehavior.mimic()
      : battleEngineMethod = 's_mimic',
        _kind = _CopyCallMoveKind.mimic,
        _callMove = null;

  const CopyCallMoveBehavior.sketch()
      : battleEngineMethod = 's_sketch',
        _kind = _CopyCallMoveKind.sketch,
        _callMove = null;

  @override
  final String battleEngineMethod;
  final _CopyCallMoveKind _kind;
  final BattleCalledMoveResolver? _callMove;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    return switch (_kind) {
      _CopyCallMoveKind.sleepTalk => _canUseSleepTalk(user)
          ? null
          : const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            ),
      _CopyCallMoveKind.mimic => _canUseMimic(context)
          ? null
          : const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            ),
      _CopyCallMoveKind.sketch => _canUseSketch(context)
          ? null
          : const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            ),
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failure(context, prevention.reason);
    }

    return switch (_kind) {
      _CopyCallMoveKind.sleepTalk => _resolveSleepTalk(context),
      _CopyCallMoveKind.mimic => _resolveMimic(context),
      _CopyCallMoveKind.sketch => _resolveSketch(context),
    };
  }

  BattleMoveBehaviorResolution _resolveSleepTalk(
    BattleMoveBehaviorContext context,
  ) {
    final selection = _selectSleepTalkMove(context);
    if (selection == null) {
      return _failure(context, BattleMoveFailureReason.unusableByUser);
    }

    final resolver = _callMove;
    if (resolver == null) {
      return _failure(context, BattleMoveFailureReason.unusableByUser);
    }
    return resolver(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: selection.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
      BattleMoveDefinition.fromPsdk(selection.move),
    );
  }

  BattleMoveBehaviorResolution _resolveMimic(
    BattleMoveBehaviorContext context,
  ) {
    final moveSlot = context.moveSlot;
    final copiedMove = _mimicTargetMove(context);
    if (moveSlot == null || copiedMove == null) {
      return _failure(context, BattleMoveFailureReason.unusableByUser);
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final copied = copiedMove.copyWith(pp: 5, currentPp: 5);
    return BattleMoveBehaviorResolution(
      state: prepared.state.updateBattler(
        context.user,
        (battler) => battler.replaceMoveAt(moveSlot, copied),
      ),
      rng: prepared.rng,
      events: prepared.events,
    );
  }

  BattleMoveBehaviorResolution _resolveSketch(
    BattleMoveBehaviorContext context,
  ) {
    final moveSlot = context.moveSlot;
    final copiedMove = _sketchTargetMove(context);
    if (moveSlot == null || copiedMove == null) {
      return _failure(context, BattleMoveFailureReason.unusableByUser);
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final copied = copiedMove.copyWith(currentPp: copiedMove.pp);
    return BattleMoveBehaviorResolution(
      state: prepared.state.updateBattler(
        context.user,
        (battler) => battler.replaceMoveAt(moveSlot, copied),
      ),
      rng: prepared.rng,
      events: prepared.events,
    );
  }
}

final class _SelectedMove {
  const _SelectedMove({
    required this.move,
    required this.rng,
  });

  final PsdkBattleMoveData move;
  final BattleRngStreams rng;
}

BattleMoveBehaviorResolution _failure(
  BattleMoveBehaviorContext context,
  BattleMoveFailureReason reason,
) {
  return BattleMoveBehaviorResolution(
    state: context.state,
    rng: context.rng,
    successful: false,
    events: <PsdkBattleEvent>[
      PsdkBattleMoveFailedEvent(
        user: context.user,
        target: context.target,
        moveId: context.move.id,
        reason: reason.jsonName,
      ),
    ],
  );
}

bool _canUseSleepTalk(PsdkBattleCombatant user) {
  final canActWhileAwake = _normalizedId(user.abilityId) == 'comatose';
  return (user.majorStatus == PsdkBattleMajorStatus.sleep ||
          canActWhileAwake) &&
      _sleepTalkUsableMoves(user).isNotEmpty;
}

_SelectedMove? _selectSleepTalkMove(BattleMoveBehaviorContext context) {
  final moves = _sleepTalkUsableMoves(context.state.battlerAt(context.user));
  if (moves.isEmpty) {
    return null;
  }
  final roll = context.rng.generic.nextIntInclusive(
    min: 0,
    max: moves.length - 1,
  );
  return _SelectedMove(
    move: moves[roll.value],
    rng: context.rng.copyWith(generic: roll.next),
  );
}

List<PsdkBattleMoveData> _sleepTalkUsableMoves(PsdkBattleCombatant user) {
  return user.moves
      .where((move) => !_sleepTalkExcludedMoveIds.contains(_normalizedId(
            move.dbSymbol.isEmpty ? move.id : move.dbSymbol,
          )))
      .where((move) => !_sleepTalkExcludedMoveIds.contains(_normalizedId(
            move.id,
          )))
      .toList(growable: false);
}

bool _canUseMimic(BattleMoveBehaviorContext context) {
  return context.moveSlot != null && _mimicTargetMove(context) != null;
}

bool _canUseSketch(BattleMoveBehaviorContext context) {
  final moveSlot = context.moveSlot;
  if (moveSlot == null) {
    return false;
  }
  final user = context.state.battlerAt(context.user);
  if (user.transformState.isTransformed ||
      moveSlot < 0 ||
      moveSlot >= user.moves.length) {
    return false;
  }
  final selectedMove = user.moves[moveSlot];
  if (_normalizedId(selectedMove.battleEngineMethod) != 's_sketch') {
    return false;
  }
  return _sketchTargetMove(context) != null;
}

PsdkBattleMoveData? _mimicTargetMove(BattleMoveBehaviorContext context) {
  final target = context.state.battlerAt(context.target);
  final moveId = target.moveHistory.lastSuccessfulMoveId;
  if (moveId == null || _mimicExcludedMoveIds.contains(_normalizedId(moveId))) {
    return null;
  }
  for (final move in target.moves) {
    if (_normalizedId(move.id) == _normalizedId(moveId) ||
        _normalizedId(move.dbSymbol) == _normalizedId(moveId)) {
      return move;
    }
  }
  return null;
}

PsdkBattleMoveData? _sketchTargetMove(BattleMoveBehaviorContext context) {
  final target = context.state.battlerAt(context.target);
  final moveId = target.moveHistory.lastMoveId;
  if (moveId == null) {
    return null;
  }
  for (final move in target.moves) {
    if (_normalizedId(move.id) == _normalizedId(moveId) ||
        _normalizedId(move.dbSymbol) == _normalizedId(moveId)) {
      return move;
    }
  }
  return null;
}

const _sleepTalkExcludedMoveIds = <String>{
  'assist',
  'belch',
  'bide',
  'bounce',
  'copycat',
  'dig',
  'dive',
  'freeze_shock',
  'fly',
  'focus_punch',
  'geomancy',
  'ice_burn',
  'me_first',
  'metronome',
  'sleep_talk',
  'mirror_move',
  'mimic',
  'phantom_force',
  'razor_wind',
  'shadow_force',
  'sketch',
  'skull_bash',
  'sky_attack',
  'sky_drop',
  'solar_beam',
  'uproar',
  'electro_shot',
};

const _mimicExcludedMoveIds = <String>{
  'chatter',
  'metronome',
  'sketch',
  'struggle',
  'mimic',
};

String _normalizedId(String? value) {
  return (value ?? '').trim().toLowerCase();
}
