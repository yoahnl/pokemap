import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
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
  metronome,
  assist,
  instruct,
  mirrorMove,
  meFirst,
  mimic,
  sketch,
}

final class CopyCallMoveBehavior implements BattleMoveUserPreventionBehavior {
  const CopyCallMoveBehavior.sleepTalk({
    required BattleCalledMoveResolver callMove,
  })  : battleEngineMethod = 's_sleep_talk',
        _kind = _CopyCallMoveKind.sleepTalk,
        _callMove = callMove;

  const CopyCallMoveBehavior.metronome({
    required BattleCalledMoveResolver callMove,
  })  : battleEngineMethod = 's_metronome',
        _kind = _CopyCallMoveKind.metronome,
        _callMove = callMove;

  const CopyCallMoveBehavior.assist({
    required BattleCalledMoveResolver callMove,
  })  : battleEngineMethod = 's_assist',
        _kind = _CopyCallMoveKind.assist,
        _callMove = callMove;

  const CopyCallMoveBehavior.instruct({
    required BattleCalledMoveResolver callMove,
  })  : battleEngineMethod = 's_instruct',
        _kind = _CopyCallMoveKind.instruct,
        _callMove = callMove;

  const CopyCallMoveBehavior.mirrorMove({
    required BattleCalledMoveResolver callMove,
  })  : battleEngineMethod = 's_mirror_move',
        _kind = _CopyCallMoveKind.mirrorMove,
        _callMove = callMove;

  const CopyCallMoveBehavior.meFirst({
    required BattleCalledMoveResolver callMove,
  })  : battleEngineMethod = 's_me_first',
        _kind = _CopyCallMoveKind.meFirst,
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
      _CopyCallMoveKind.metronome => _metronomeUsableMoves().isNotEmpty
          ? null
          : const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            ),
      _CopyCallMoveKind.assist => null,
      _CopyCallMoveKind.instruct => null,
      _CopyCallMoveKind.mirrorMove => null,
      _CopyCallMoveKind.meFirst => null,
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
      _CopyCallMoveKind.metronome => _resolveMetronome(context),
      _CopyCallMoveKind.assist => _resolveAssist(context),
      _CopyCallMoveKind.instruct => _resolveInstruct(context),
      _CopyCallMoveKind.mirrorMove => _resolveMirrorMove(context),
      _CopyCallMoveKind.meFirst => _resolveMeFirst(context),
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
    final calledMove = BattleMoveDefinition.fromPsdk(selection.move);
    final called = resolver(
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
      calledMove,
    );
    return _withCalledMoveEvent(
      context: context,
      called: called,
      calledMove: calledMove,
    );
  }

  BattleMoveBehaviorResolution _resolveMetronome(
    BattleMoveBehaviorContext context,
  ) {
    final selection = _selectMetronomeMove(context);
    if (selection == null) {
      return _failure(context, BattleMoveFailureReason.unusableByUser);
    }

    final resolver = _callMove;
    if (resolver == null) {
      return _failure(context, BattleMoveFailureReason.unusableByUser);
    }
    final calledMove = BattleMoveDefinition.fromPsdk(selection.move);
    final called = resolver(
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
      calledMove,
    );
    return _withCalledMoveEvent(
      context: context,
      called: called,
      calledMove: calledMove,
    );
  }

  BattleMoveBehaviorResolution _resolveAssist(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final selection = _selectAssistMove(context, prepared.rng);
    if (selection == null) {
      return _failureAfterPreparation(
        context: context,
        prepared: prepared,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    final resolver = _callMove;
    if (resolver == null) {
      return _failureAfterPreparation(
        context: context,
        prepared: prepared,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }
    final calledMove = BattleMoveDefinition.fromPsdk(selection.move);
    final called = resolver(
      BattleMoveBehaviorContext(
        state: prepared.state,
        rng: selection.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
      calledMove,
    );
    return _withCalledMoveEvent(
      context: context,
      called: called,
      calledMove: calledMove,
      prefixEvents: prepared.events,
    );
  }

  BattleMoveBehaviorResolution _resolveInstruct(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final instructed = _instructTargetMove(context);
    final resolver = _callMove;
    if (instructed == null || resolver == null) {
      return _failureAfterPreparation(
        context: context,
        prepared: prepared,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    final moveAfterPp = instructed.move.spendPp();
    final stateAfterPp = prepared.state.updateBattler(
      context.target,
      (battler) => battler.replaceMoveAt(instructed.moveSlot, moveAfterPp),
    );
    final calledMove = BattleMoveDefinition.fromPsdk(moveAfterPp);
    final called = resolver(
      BattleMoveBehaviorContext(
        state: stateAfterPp,
        rng: prepared.rng,
        turn: context.turn,
        user: context.target,
        target: instructed.target,
        move: context.move,
        moveSlot: instructed.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
      calledMove,
    );

    return BattleMoveBehaviorResolution(
      state: called.state.updateBattler(
        context.target,
        (battler) => battler.copyWith(
          effects: battler.effects.add('instruct'),
        ),
      ),
      rng: called.rng,
      successful: called.successful,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        PsdkBattleMovePpSpentEvent(
          user: context.target,
          moveId: moveAfterPp.id,
          spent: instructed.move.currentPp - moveAfterPp.currentPp,
          remainingPp: moveAfterPp.currentPp,
        ),
        _calledMoveEvent(
          context: context,
          user: context.target,
          target: instructed.target,
          calledMove: calledMove,
        ),
        ...called.events,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveMirrorMove(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final copiedMove = _mirrorMoveTargetMove(context);
    if (copiedMove == null) {
      return _failureAfterPreparation(
        context: context,
        prepared: prepared,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    final resolver = _callMove;
    if (resolver == null) {
      return _failureAfterPreparation(
        context: context,
        prepared: prepared,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }
    final calledMove = BattleMoveDefinition.fromPsdk(copiedMove);
    final called = resolver(
      BattleMoveBehaviorContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
      calledMove,
    );
    return _withCalledMoveEvent(
      context: context,
      called: called,
      calledMove: calledMove,
      prefixEvents: prepared.events,
    );
  }

  BattleMoveBehaviorResolution _resolveMeFirst(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final announced = context.announcedMoveFor?.call(context.target);
    final resolver = _callMove;
    if (announced == null ||
        _meFirstExcluded(announced.move) ||
        resolver == null) {
      return _failureAfterPreparation(
        context: context,
        prepared: prepared,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    final calledMove = _meFirstBoostedMove(announced.move);
    final called = resolver(
      BattleMoveBehaviorContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
        announcedMoveFor: context.announcedMoveFor,
      ),
      calledMove,
    );

    return BattleMoveBehaviorResolution(
      state: called.state,
      rng: called.rng,
      successful: called.successful,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        _calledMoveEvent(
          context: context,
          calledMove: calledMove,
        ),
        ...called.events,
      ],
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

final class _InstructedMove {
  const _InstructedMove({
    required this.move,
    required this.moveSlot,
    required this.target,
  });

  final PsdkBattleMoveData move;
  final int moveSlot;
  final PsdkBattleSlotRef target;
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

BattleMoveBehaviorResolution _failureAfterPreparation({
  required BattleMoveBehaviorContext context,
  required PreparedBattleMove prepared,
  required BattleMoveFailureReason reason,
}) {
  return BattleMoveBehaviorResolution(
    state: prepared.state,
    rng: prepared.rng,
    successful: false,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      PsdkBattleMoveFailedEvent(
        user: context.user,
        target: context.target,
        moveId: context.move.id,
        reason: reason.jsonName,
      ),
    ],
  );
}

_InstructedMove? _instructTargetMove(BattleMoveBehaviorContext context) {
  final target = context.state.battlerAt(context.target);
  if (target.effects.contains(PsdkBattleEffectIds.forceNextMoveBase) ||
      target.effects.contains(PsdkBattleEffectIds.twoTurnCharge) ||
      target.effects.contains('out_of_reach') ||
      target.effects.contains('out_of_reach_base')) {
    return null;
  }
  if (target.moveHistory.attempts.isEmpty) {
    return null;
  }

  final history = target.moveHistory.attempts.last;
  for (var index = 0; index < target.moves.length; index++) {
    final move = target.moves[index];
    if (_normalizedId(move.id) != _normalizedId(history.moveId) &&
        _normalizedId(move.dbSymbol) != _normalizedId(history.moveId)) {
      continue;
    }
    if (!_canInstructMove(move)) {
      return null;
    }
    return _InstructedMove(
      move: move,
      moveSlot: index,
      target: history.targets.isEmpty ? context.user : history.targets.first,
    );
  }
  return null;
}

bool _canInstructMove(PsdkBattleMoveData move) {
  final moveId = _normalizedId(
    move.dbSymbol.isEmpty ? move.id : move.dbSymbol,
  );
  return move.currentPp > 0 &&
      !_instructExcludedMoveIds.contains(moveId) &&
      !_instructExcludedMoveIds.contains(_normalizedId(move.id)) &&
      !_instructExcludedMethods
          .contains(_normalizedId(move.battleEngineMethod));
}

bool _meFirstExcluded(PsdkBattleMoveData move) {
  final moveId = _normalizedId(
    move.dbSymbol.isEmpty ? move.id : move.dbSymbol,
  );
  return _meFirstExcludedMoveIds.contains(moveId) ||
      _meFirstExcludedMoveIds.contains(_normalizedId(move.id));
}

BattleMoveDefinition _meFirstBoostedMove(PsdkBattleMoveData move) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: (move.power * 1.5).floor(),
    accuracy: move.accuracy,
    pp: 1,
    currentPp: 1,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: BattleMoveFlags(
      protectable: move.protectable,
      sound: move.sound,
      bite: move.bite,
      pulse: move.pulse,
      ballistics: move.ballistics,
    ),
    stageMods: move.stageMods
        .map(
          (mod) => BattleStageMod(
            stat: mod.stat,
            stages: mod.stages,
            chance: mod.chance,
          ),
        )
        .toList(growable: false),
    statuses: move.statuses,
  );
}

BattleMoveBehaviorResolution _withCalledMoveEvent({
  required BattleMoveBehaviorContext context,
  required BattleMoveBehaviorResolution called,
  required BattleMoveDefinition calledMove,
  List<PsdkBattleEvent> prefixEvents = const <PsdkBattleEvent>[],
}) {
  return BattleMoveBehaviorResolution(
    state: called.state,
    rng: called.rng,
    successful: called.successful,
    events: <PsdkBattleEvent>[
      ...prefixEvents,
      _calledMoveEvent(context: context, calledMove: calledMove),
      ...called.events,
    ],
  );
}

PsdkBattleMoveCalledEvent _calledMoveEvent({
  required BattleMoveBehaviorContext context,
  required BattleMoveDefinition calledMove,
  PsdkBattleSlotRef? user,
  PsdkBattleSlotRef? target,
}) {
  return PsdkBattleMoveCalledEvent(
    user: user ?? context.user,
    target: target ?? context.target,
    callerMoveId: context.move.id,
    calledMoveId: calledMove.id,
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

_SelectedMove? _selectMetronomeMove(BattleMoveBehaviorContext context) {
  final moves = _metronomeUsableMoves();
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

List<PsdkBattleMoveData> _metronomeUsableMoves() {
  return _defaultMetronomeMovePool
      .where((move) => !_metronomeExcludedMoveIds.contains(_normalizedId(
            move.dbSymbol.isEmpty ? move.id : move.dbSymbol,
          )))
      .where((move) => !_metronomeExcludedMoveIds.contains(_normalizedId(
            move.id,
          )))
      .toList(growable: false);
}

_SelectedMove? _selectAssistMove(
  BattleMoveBehaviorContext context,
  BattleRngStreams rng,
) {
  final moves = _assistUsableMoves(context);
  if (moves.isEmpty) {
    return null;
  }
  final roll = rng.generic.nextIntInclusive(
    min: 0,
    max: moves.length - 1,
  );
  return _SelectedMove(
    move: moves[roll.value],
    rng: rng.copyWith(generic: roll.next),
  );
}

List<PsdkBattleMoveData> _assistUsableMoves(BattleMoveBehaviorContext context) {
  final uniqueMoves = <String, PsdkBattleMoveData>{};
  for (final entry in context.state.combatants.entries) {
    if (entry.key == context.user ||
        entry.key.bank != context.user.bank ||
        entry.value.isFainted) {
      continue;
    }
    for (final move in entry.value.moves) {
      final moveId = _normalizedId(
        move.dbSymbol.isEmpty ? move.id : move.dbSymbol,
      );
      if (_assistExcludedMoveIds.contains(moveId) ||
          _assistExcludedMoveIds.contains(_normalizedId(move.id)) ||
          uniqueMoves.containsKey(moveId)) {
        continue;
      }
      uniqueMoves[moveId] = move;
    }
  }
  return uniqueMoves.values.toList(growable: false);
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

PsdkBattleMoveData? _mirrorMoveTargetMove(BattleMoveBehaviorContext context) {
  final lastMove = _isMirrorMove(context.move)
      ? _mirrorMoveLastTargetMove(context)
      : _copycatLastMove(context);
  if (lastMove == null || _mirrorMoveExcluded(context.move, lastMove)) {
    return null;
  }
  return lastMove;
}

PsdkBattleMoveData? _mirrorMoveLastTargetMove(
  BattleMoveBehaviorContext context,
) {
  final target = context.state.battlerAt(context.target);
  final history = target.moveHistory.attempts.isEmpty
      ? null
      : target.moveHistory.attempts.last;
  if (history == null || history.turn < context.turn - 1) {
    return null;
  }
  return _moveFromCombatant(target, history.moveId);
}

PsdkBattleMoveData? _copycatLastMove(BattleMoveBehaviorContext context) {
  final candidates = <({PsdkBattleCombatant battler, int turn, String moveId})>[
    for (final entry in context.state.combatants.entries)
      if (entry.key != context.user &&
          !entry.value.isFainted &&
          entry.value.moveHistory.attempts.isNotEmpty)
        (
          battler: entry.value,
          turn: entry.value.moveHistory.attempts.last.turn,
          moveId: entry.value.moveHistory.attempts.last.moveId,
        ),
  ];
  if (candidates.isEmpty) {
    return null;
  }
  candidates.sort((left, right) => left.turn.compareTo(right.turn));
  final candidate = candidates.last;
  return _moveFromCombatant(candidate.battler, candidate.moveId);
}

bool _mirrorMoveExcluded(
  BattleMoveDefinition callingMove,
  PsdkBattleMoveData calledMove,
) {
  final moveId = _normalizedId(
    calledMove.dbSymbol.isEmpty ? calledMove.id : calledMove.dbSymbol,
  );
  if (!_isMirrorMove(callingMove)) {
    return _copycatExcludedMoveIds.contains(moveId) ||
        _copycatExcludedMoveIds.contains(_normalizedId(calledMove.id));
  }
  return _mirrorMoveExcludedMoveIds.contains(moveId) ||
      _mirrorMoveExcludedMoveIds.contains(_normalizedId(calledMove.id));
}

bool _isMirrorMove(BattleMoveDefinition move) {
  return _normalizedId(move.id) == 'mirror_move' ||
      _normalizedId(move.dbSymbol) == 'mirror_move';
}

PsdkBattleMoveData? _moveFromCombatant(
  PsdkBattleCombatant battler,
  String moveId,
) {
  for (final move in battler.moves) {
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

final List<PsdkBattleMoveData> _defaultMetronomeMovePool =
    List<PsdkBattleMoveData>.unmodifiable(<PsdkBattleMoveData>[
  PsdkBattleMoveData(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 1,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  ),
  PsdkBattleMoveData(
    id: 'scratch',
    dbSymbol: 'scratch',
    name: 'Scratch',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 1,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  ),
]);

const _metronomeExcludedMoveIds = <String>{
  'after_you',
  'assist',
  'baneful_bunker',
  'beak_blast',
  'belch',
  'bestow',
  'celebrate',
  'chatter',
  'copycat',
  'counter',
  'covet',
  'crafty_shield',
  'destiny_bound',
  'detect',
  'diamond_storm',
  'endure',
  'feint',
  'fleur_cannon',
  'focus_punch',
  'follow_me',
  'freeze_shock',
  'helping_hand',
  'hold_hands',
  'hyperspace_fury',
  'hyperspace_hole',
  'ice_burn',
  'instruct',
  'king_s_shield',
  'light_of_ruin',
  'mat_block',
  'me_first',
  'metronome',
  'mimic',
  'mind_blown',
  'mirror_coat',
  'mirror_move',
  'nature_power',
  'photon_geyser',
  'plasma_fists',
  'protect',
  'quash',
  'quick_guard',
  'rage_powder',
  'relic_song',
  'secret_sword',
  'shell_trap',
  'sketch',
  'sleep_talk',
  'snarl',
  'snatch',
  'snore',
  'spectral_thief',
  'spiky_shield',
  'spotlight',
  'steam_eruption',
  'struggle',
  'switcheroo',
  'techno_blast',
  'thousand_arrows',
  'thousand_waves',
  'thief',
  'transform',
  'trick',
  'v_create',
  'wide_guard',
};

const _mimicExcludedMoveIds = <String>{
  'chatter',
  'metronome',
  'sketch',
  'struggle',
  'mimic',
};

const _assistExcludedMoveIds = <String>{
  'assist',
  'baneful_bunker',
  'beak_blast',
  'belch',
  'bestow',
  'bounce',
  'celebrate',
  'chatter',
  'circle_throw',
  'copycat',
  'counter',
  'covet',
  'destiny_bound',
  'detect',
  'dig',
  'dive',
  'dragon_tail',
  'endure',
  'feint',
  'fly',
  'focus_punch',
  'follow_me',
  'helping_hand',
  'hold_hands',
  'king_s_shield',
  'mat_block',
  'me_first',
  'metronome',
  'mimic',
  'mirror_coat',
  'mirror_move',
  'nature_power',
  'phantom_force',
  'protect',
  'rage_powder',
  'roar',
  'shadow_force',
  'shell_trap',
  'sketch',
  'sky_drop',
  'sleep_talk',
  'snatch',
  'spiky_shield',
  'spotlight',
  'struggle',
  'switcheroo',
  'thief',
  'transform',
  'trick',
  'whirlwind',
};

const _instructExcludedMoveIds = <String>{
  'sketch',
  'transform',
  'mimic',
  'king_s_shield',
  'struggle',
  'instruct',
  'metronome',
  'assist',
  'me_first',
  'mirror_move',
  'nature_power',
  'sleep_talk',
};

const _instructExcludedMethods = <String>{
  's_2turns',
  's_reload',
  's_thrash',
};

const _meFirstExcludedMoveIds = <String>{
  'me_first',
  'sucker_punch',
  'fake_out',
};

const _copycatExcludedMoveIds = <String>{
  'baneful_bunker',
  'beak_blast',
  'behemoth_blade',
  'bestow',
  'celebrate',
  'chatter',
  'circle_throw',
  'copycat',
  'counter',
  'covet',
  'destiny_bond',
  'detect',
  'dragon_tail',
  'endure',
  'feint',
  'focus_punch',
  'follow_me',
  'helping_hand',
  'hold_hands',
  'king_s_shield',
  'mat_block',
  'assist',
  'me_first',
  'metronome',
  'mimic',
  'mirror_coat',
  'mirror_move',
  'protect',
  'rage_powder',
  'roar',
  'shell_trap',
  'sketch',
  'sleep_talk',
  'snatch',
  'struggle',
  'spiky_shield',
  'spotlight',
  'switcheroo',
  'thief',
  'transform',
  'trick',
  'whirlwind',
};

// PSDK's Mirror Move reads Studio's is_mirror_move flag. The local move DTO
// does not import that flag yet, so this mirrors the non-copyable move family
// conservatively until the Studio import carries the explicit boolean.
const _mirrorMoveExcludedMoveIds = _copycatExcludedMoveIds;

String _normalizedId(String? value) {
  return (value ?? '').trim().toLowerCase();
}
