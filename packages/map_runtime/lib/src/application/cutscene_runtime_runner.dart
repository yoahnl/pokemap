import 'package:map_core/map_core.dart';

import 'cutscene_runtime_models.dart';
import 'scripted_entity_movement_models.dart';

typedef CutsceneOpenDialogue = bool Function(
  String dialogueId, {
  String? startNode,
});

typedef CutsceneIsDialogueOpen = bool Function();

typedef CutsceneResolveById = RuntimeCutsceneAsset? Function(String cutsceneId);

typedef CutsceneMoveNpcTo = ScriptedEntityMovementStatus Function({
  required String entityId,
  required GridPos destination,
});

typedef CutsceneReadNpcMovementStatus = ScriptedEntityMovementStatus Function(
  String entityId,
);

typedef CutsceneFaceNpc = bool Function({
  required String entityId,
  required EntityFacing facing,
});

typedef CutsceneEmitOutcome = void Function(String outcomeId);
typedef CutsceneSetFlag = void Function(String flagName);
typedef CutsceneClearFlag = void Function(String flagName);
typedef CutsceneIsFlagSet = bool Function(String flagName);
typedef CutsceneIsOutcomeSet = bool Function(String outcomeId);

class CutsceneRuntimeContext {
  const CutsceneRuntimeContext({
    required this.openDialogue,
    required this.isDialogueOpen,
    required this.resolveCutsceneById,
    required this.moveNpcTo,
    required this.readNpcMovementStatus,
    required this.faceNpc,
    required this.emitOutcome,
    required this.setFlag,
    required this.clearFlag,
    required this.isFlagSet,
    required this.isOutcomeSet,
  });

  final CutsceneOpenDialogue openDialogue;
  final CutsceneIsDialogueOpen isDialogueOpen;
  final CutsceneResolveById resolveCutsceneById;
  final CutsceneMoveNpcTo moveNpcTo;
  final CutsceneReadNpcMovementStatus readNpcMovementStatus;
  final CutsceneFaceNpc faceNpc;
  final CutsceneEmitOutcome emitOutcome;
  final CutsceneSetFlag setFlag;
  final CutsceneClearFlag clearFlag;
  final CutsceneIsFlagSet isFlagSet;
  final CutsceneIsOutcomeSet isOutcomeSet;
}

class CutsceneRuntimeRunner {
  CutsceneRuntimeRunner({
    required CutsceneRuntimeContext context,
    this.maxCallDepth = 8,
  }) : _context = context;

  final CutsceneRuntimeContext _context;
  final int maxCallDepth;

  final List<_CutsceneFrame> _frames = <_CutsceneFrame>[];
  _PendingWait? _pendingWait;
  CutsceneRuntimeStatus _status = const CutsceneRuntimeStatus.idle();
  String? _lastStartError;

  CutsceneRuntimeStatus get status => _status;
  bool get isRunning => _status.isRunning;
  String? get activeCutsceneId => _status.activeCutsceneId;
  String? get lastStartError => _lastStartError;

  bool start(RuntimeCutsceneAsset cutscene) {
    if (isRunning) {
      _lastStartError = 'Cannot start cutscene: runner already running.';
      return false;
    }
    final id = cutscene.id.trim();
    if (id.isEmpty) {
      _status = const CutsceneRuntimeStatus(
        state: CutsceneRunnerState.failed,
        failureReason: 'Cannot start cutscene with empty id.',
      );
      _lastStartError = _status.failureReason;
      return false;
    }
    _frames
      ..clear()
      ..add(_CutsceneFrame(cutscene: cutscene));
    _pendingWait = null;
    _lastStartError = null;
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.running,
      activeCutsceneId: id,
      activeStepIndex: 0,
    );
    if (cutscene.steps.isEmpty) {
      _complete();
    }
    return true;
  }

  void update(double dtSeconds) {
    if (!isRunning) {
      return;
    }
    final dtMs = (dtSeconds * 1000).round();
    final top = _topFrame;
    if (top == null) {
      _complete();
      return;
    }

    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.running,
      activeCutsceneId: top.cutscene.id,
      activeStepIndex: top.stepIndex,
    );

    if (_pendingWait != null) {
      _tickPendingWait(dtMs);
      return;
    }

    if (top.stepIndex >= top.cutscene.steps.length) {
      _onFrameCompleted();
      return;
    }

    final step = top.cutscene.steps[top.stepIndex];
    if (step is CutsceneDialogueStep) {
      _runDialogueStep(top, step);
      return;
    }
    if (step is CutsceneMoveNpcToStep) {
      _runMoveNpcStep(step);
      return;
    }
    if (step is CutsceneWaitStep) {
      _pendingWait = _PendingWait.waitMs(
        remainingMs: step.durationMs,
      );
      _tickPendingWait(dtMs);
      return;
    }
    if (step is CutsceneWaitUntilDialogueClosedStep) {
      _pendingWait = _PendingWait.dialogueClosed(
        timeoutRemainingMs: step.timeoutMs,
      );
      _tickPendingWait(dtMs);
      return;
    }
    if (step is CutsceneWaitUntilNpcMoveCompletedStep) {
      final entityId = step.entityId.trim();
      if (entityId.isEmpty) {
        _fail('waitUntilNpcMoveCompleted has empty entityId.');
        return;
      }
      _pendingWait = _PendingWait.npcMoveCompleted(
        entityId: entityId,
        timeoutRemainingMs: step.timeoutMs,
      );
      _tickPendingWait(dtMs);
      return;
    }
    if (step is CutsceneWaitUntilFlagStep) {
      final flagName = step.flagName.trim();
      if (flagName.isEmpty) {
        _fail('waitUntilFlag has empty flagName.');
        return;
      }
      _pendingWait = _PendingWait.flag(
        flagName: flagName,
        expectedSet: step.expectedSet,
        timeoutRemainingMs: step.timeoutMs,
      );
      _tickPendingWait(dtMs);
      return;
    }
    if (step is CutsceneWaitUntilOutcomeStep) {
      final outcomeId = step.outcomeId.trim();
      if (outcomeId.isEmpty) {
        _fail('waitUntilOutcome has empty outcomeId.');
        return;
      }
      _pendingWait = _PendingWait.outcome(
        outcomeId: outcomeId,
        expectedSet: step.expectedSet,
        timeoutRemainingMs: step.timeoutMs,
      );
      _tickPendingWait(dtMs);
      return;
    }
    if (step is CutsceneCallStep) {
      _runCallCutsceneStep(top, step);
      return;
    }
    if (step is CutsceneFaceNpcStep) {
      _runFaceNpcStep(step);
      return;
    }
    if (step is CutsceneEmitOutcomeStep) {
      _runEmitOutcomeStep(step);
      return;
    }
    if (step is CutsceneSetFlagStep) {
      _runSetFlagStep(step);
      return;
    }
    if (step is CutsceneClearFlagStep) {
      _runClearFlagStep(step);
      return;
    }

    _fail('Unsupported cutscene step type: ${step.runtimeType}.');
  }

  void _runDialogueStep(_CutsceneFrame frame, CutsceneDialogueStep step) {
    if (frame.waitingForCalledCutscene) {
      _fail('Internal error: dialogue step reached while waiting call.');
      return;
    }
    final dialogueId = step.dialogueId.trim();
    if (dialogueId.isEmpty) {
      _fail('Dialogue step has empty dialogueId.');
      return;
    }
    final opened = _context.openDialogue(
      dialogueId,
      startNode: step.startNode,
    );
    if (!opened) {
      _fail('Failed to open dialogue "$dialogueId".');
      return;
    }
    if (!step.waitUntilClosed) {
      _advanceStepOnTopFrame();
      return;
    }
    _pendingWait = _PendingWait.dialogueClosed();
  }

  void _runMoveNpcStep(CutsceneMoveNpcToStep step) {
    final entityId = step.entityId.trim();
    if (entityId.isEmpty) {
      _fail('Move step has empty entityId.');
      return;
    }
    final startStatus = _context.moveNpcTo(
      entityId: entityId,
      destination: step.destination,
    );
    switch (startStatus.state) {
      case ScriptedEntityMovementState.completed:
        _advanceStepOnTopFrame();
      case ScriptedEntityMovementState.moving:
        _pendingWait = _PendingWait.npcMoveCompleted(entityId: entityId);
      case ScriptedEntityMovementState.failed:
        _fail(startStatus.failureReason ?? 'Failed to start movement.');
      case ScriptedEntityMovementState.idle:
        _fail('Move step returned idle for "$entityId".');
    }
  }

  void _runCallCutsceneStep(_CutsceneFrame frame, CutsceneCallStep step) {
    if (frame.waitingForCalledCutscene) {
      frame.waitingForCalledCutscene = false;
      _advanceStepOnTopFrame();
      return;
    }

    final cutsceneId = step.cutsceneId.trim();
    if (cutsceneId.isEmpty) {
      _fail('callCutscene has empty cutsceneId.');
      return;
    }
    final called = _context.resolveCutsceneById(cutsceneId);
    if (called == null) {
      _fail('Called cutscene "$cutsceneId" not found.');
      return;
    }
    if (_frames.length >= maxCallDepth) {
      _fail('Cutscene call depth exceeded (max=$maxCallDepth).');
      return;
    }
    for (final existing in _frames) {
      if (existing.cutscene.id == called.id) {
        _fail('Recursive cutscene call detected for "${called.id}".');
        return;
      }
    }

    frame.waitingForCalledCutscene = true;
    _frames.add(_CutsceneFrame(cutscene: called));
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.running,
      activeCutsceneId: called.id,
      activeStepIndex: 0,
    );
  }

  void _runFaceNpcStep(CutsceneFaceNpcStep step) {
    final entityId = step.entityId.trim();
    if (entityId.isEmpty) {
      _fail('Face step has empty entityId.');
      return;
    }
    final changed = _context.faceNpc(
      entityId: entityId,
      facing: step.facing,
    );
    if (!changed) {
      _fail('Failed to face NPC "$entityId".');
      return;
    }
    _advanceStepOnTopFrame();
  }

  void _runEmitOutcomeStep(CutsceneEmitOutcomeStep step) {
    final outcomeId = step.outcomeId.trim();
    if (outcomeId.isEmpty) {
      _fail('EmitOutcome step has empty outcomeId.');
      return;
    }
    _context.emitOutcome(outcomeId);
    _advanceStepOnTopFrame();
  }

  void _runSetFlagStep(CutsceneSetFlagStep step) {
    final flagName = step.flagName.trim();
    if (flagName.isEmpty) {
      _fail('SetFlag step has empty flagName.');
      return;
    }
    _context.setFlag(flagName);
    _advanceStepOnTopFrame();
  }

  void _runClearFlagStep(CutsceneClearFlagStep step) {
    final flagName = step.flagName.trim();
    if (flagName.isEmpty) {
      _fail('ClearFlag step has empty flagName.');
      return;
    }
    _context.clearFlag(flagName);
    _advanceStepOnTopFrame();
  }

  void _tickPendingWait(int dtMs) {
    final pending = _pendingWait;
    if (pending == null) {
      return;
    }

    if (pending.timeoutRemainingMs != null) {
      pending.timeoutRemainingMs = pending.timeoutRemainingMs! - dtMs;
      if (pending.timeoutRemainingMs! <= 0) {
        _pendingWait = null;
        _fail('Cutscene wait timeout on "${pending.kind.name}".');
        return;
      }
    }

    switch (pending.kind) {
      case _PendingWaitKind.waitMs:
        pending.remainingMs = (pending.remainingMs! - dtMs).clamp(0, 1 << 30);
        if (pending.remainingMs == 0) {
          _pendingWait = null;
          _advanceStepOnTopFrame();
        }

      case _PendingWaitKind.dialogueClosed:
        if (!_context.isDialogueOpen()) {
          _pendingWait = null;
          _advanceStepOnTopFrame();
        }

      case _PendingWaitKind.npcMoveCompleted:
        final entityId = pending.entityId!;
        final status = _context.readNpcMovementStatus(entityId);
        switch (status.state) {
          case ScriptedEntityMovementState.moving:
            return;
          case ScriptedEntityMovementState.completed:
            _pendingWait = null;
            _advanceStepOnTopFrame();
          case ScriptedEntityMovementState.failed:
            _pendingWait = null;
            _fail(status.failureReason ?? 'Movement failed for "$entityId".');
          case ScriptedEntityMovementState.idle:
            _pendingWait = null;
            _fail('Movement idle while waiting completion for "$entityId".');
        }

      case _PendingWaitKind.flag:
        final isSet = _context.isFlagSet(pending.flagName!);
        if (isSet == pending.expectedSet) {
          _pendingWait = null;
          _advanceStepOnTopFrame();
        }

      case _PendingWaitKind.outcome:
        final isSet = _context.isOutcomeSet(pending.outcomeId!);
        if (isSet == pending.expectedSet) {
          _pendingWait = null;
          _advanceStepOnTopFrame();
        }
    }
  }

  void _advanceStepOnTopFrame() {
    final top = _topFrame;
    if (top == null) {
      _fail('Cannot advance: no active frame.');
      return;
    }
    top.stepIndex += 1;
    if (top.stepIndex >= top.cutscene.steps.length) {
      _onFrameCompleted();
      return;
    }
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.running,
      activeCutsceneId: top.cutscene.id,
      activeStepIndex: top.stepIndex,
    );
  }

  void _onFrameCompleted() {
    if (_frames.isEmpty) {
      _complete();
      return;
    }
    _frames.removeLast();
    if (_frames.isEmpty) {
      _complete();
      return;
    }
    final parent = _frames.last;
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.running,
      activeCutsceneId: parent.cutscene.id,
      activeStepIndex: parent.stepIndex,
    );
  }

  _CutsceneFrame? get _topFrame => _frames.isEmpty ? null : _frames.last;

  void _complete() {
    final activeId = _status.activeCutsceneId;
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.completed,
      activeCutsceneId: activeId,
    );
    _frames.clear();
    _pendingWait = null;
  }

  void _fail(String reason) {
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.failed,
      activeCutsceneId: _topFrame?.cutscene.id ?? _status.activeCutsceneId,
      activeStepIndex: _topFrame?.stepIndex ?? _status.activeStepIndex,
      failureReason: reason,
    );
    _frames.clear();
    _pendingWait = null;
  }
}

class _CutsceneFrame {
  _CutsceneFrame({
    required this.cutscene,
  });

  final RuntimeCutsceneAsset cutscene;
  int stepIndex = 0;
  bool waitingForCalledCutscene = false;
}

enum _PendingWaitKind {
  waitMs,
  dialogueClosed,
  npcMoveCompleted,
  flag,
  outcome,
}

class _PendingWait {
  _PendingWait.waitMs({
    required this.remainingMs,
  })  : kind = _PendingWaitKind.waitMs,
        timeoutRemainingMs = null,
        entityId = null,
        flagName = null,
        outcomeId = null,
        expectedSet = true;

  _PendingWait.dialogueClosed({
    this.timeoutRemainingMs,
  })  : kind = _PendingWaitKind.dialogueClosed,
        remainingMs = null,
        entityId = null,
        flagName = null,
        outcomeId = null,
        expectedSet = true;

  _PendingWait.npcMoveCompleted({
    required this.entityId,
    this.timeoutRemainingMs,
  })  : kind = _PendingWaitKind.npcMoveCompleted,
        remainingMs = null,
        flagName = null,
        outcomeId = null,
        expectedSet = true;

  _PendingWait.flag({
    required this.flagName,
    required this.expectedSet,
    this.timeoutRemainingMs,
  })  : kind = _PendingWaitKind.flag,
        remainingMs = null,
        entityId = null,
        outcomeId = null;

  _PendingWait.outcome({
    required this.outcomeId,
    required this.expectedSet,
    this.timeoutRemainingMs,
  })  : kind = _PendingWaitKind.outcome,
        remainingMs = null,
        entityId = null,
        flagName = null;

  final _PendingWaitKind kind;
  int? remainingMs;
  int? timeoutRemainingMs;
  final String? entityId;
  final String? flagName;
  final String? outcomeId;
  final bool expectedSet;
}
