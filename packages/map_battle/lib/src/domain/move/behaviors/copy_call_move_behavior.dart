import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_data.dart';
import '../battle_move_prevention.dart';
import '../../rng/battle_rng_streams.dart';

typedef BattleCalledMoveResolver = BattleMoveBehaviorResolution Function(
  BattleMoveBehaviorContext context,
  BattleMoveDefinition move,
);

enum _CopyCallMoveKind {
  sleepTalk,
}

final class CopyCallMoveBehavior implements BattleMoveUserPreventionBehavior {
  const CopyCallMoveBehavior.sleepTalk({
    required BattleCalledMoveResolver callMove,
  })  : battleEngineMethod = 's_sleep_talk',
        _kind = _CopyCallMoveKind.sleepTalk,
        _callMove = callMove;

  @override
  final String battleEngineMethod;
  final _CopyCallMoveKind _kind;
  final BattleCalledMoveResolver _callMove;

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
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failure(context, prevention.reason);
    }

    final selection = switch (_kind) {
      _CopyCallMoveKind.sleepTalk => _selectSleepTalkMove(context),
    };
    if (selection == null) {
      return _failure(context, BattleMoveFailureReason.unusableByUser);
    }

    return _callMove(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: selection.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
      BattleMoveDefinition.fromPsdk(selection.move),
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

String _normalizedId(String? value) {
  return (value ?? '').trim().toLowerCase();
}
