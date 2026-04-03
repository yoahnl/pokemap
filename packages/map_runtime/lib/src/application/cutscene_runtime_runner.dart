import 'package:map_core/map_core.dart';

import 'cutscene_runtime_models.dart';
import 'scripted_entity_movement_models.dart';

typedef CutsceneOpenDialogue = bool Function(
  String dialogueId, {
  String? startNode,
});

typedef CutsceneIsDialogueOpen = bool Function();

typedef CutsceneRequestChoice = bool Function(CutsceneChoiceRequest request);

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
    required this.requestChoice,
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
  final CutsceneRequestChoice requestChoice;
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
    this.maxStepTransitions = 10000,
  }) : _context = context;

  final CutsceneRuntimeContext _context;
  final int maxCallDepth;
  final int maxStepTransitions;

  final List<_CutsceneFrame> _frames = <_CutsceneFrame>[];
  final Map<String, CutsceneChoiceResult> _choiceResultsById =
      <String, CutsceneChoiceResult>{};
  _PendingWait? _pendingWait;
  CutsceneChoiceRequest? _activeChoiceRequest;
  CutsceneChoiceResult? _lastChoiceResult;
  int _transitionCount = 0;
  CutsceneRuntimeStatus _status = const CutsceneRuntimeStatus.idle();
  String? _lastStartError;

  CutsceneRuntimeStatus get status => _status;
  bool get isRunning => _status.isRunning;
  String? get activeCutsceneId => _status.activeCutsceneId;
  String? get lastStartError => _lastStartError;
  bool get hasActiveChoice => _activeChoiceRequest != null;
  CutsceneChoiceRequest? get activeChoiceRequest => _activeChoiceRequest;
  CutsceneChoiceResult? get lastChoiceResult => _lastChoiceResult;

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

    final rootFrame = _tryBuildFrame(cutscene);
    if (rootFrame == null) {
      _lastStartError = _status.failureReason;
      return false;
    }

    _frames
      ..clear()
      ..add(rootFrame);
    _choiceResultsById.clear();
    _pendingWait = null;
    _activeChoiceRequest = null;
    _lastChoiceResult = null;
    _transitionCount = 0;
    _lastStartError = null;
    _setRunningStatus(rootFrame);
    if (cutscene.steps.isEmpty) {
      _complete();
    }
    return true;
  }

  bool resolveActiveChoiceByIndex(int selectedIndex) {
    final request = _activeChoiceRequest;
    if (!isRunning || request == null) {
      return false;
    }
    if (selectedIndex < 0 || selectedIndex >= request.options.length) {
      return false;
    }
    final option = request.options[selectedIndex];
    final result = CutsceneChoiceResult(
      choiceId: request.choiceId,
      selectedIndex: selectedIndex,
      selectedValue: option.value,
      selectedLabel: option.label,
    );
    _onChoiceResolved(result);
    return true;
  }

  bool resolveActiveChoiceByValue(String selectedValue) {
    final request = _activeChoiceRequest;
    if (!isRunning || request == null) {
      return false;
    }
    final normalized = selectedValue.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final index = request.options.indexWhere(
      (option) => option.value == normalized,
    );
    if (index < 0) {
      return false;
    }
    return resolveActiveChoiceByIndex(index);
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

    _setRunningStatus(top);

    if (_activeChoiceRequest != null) {
      return;
    }

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
    if (step is CutsceneChoiceStep) {
      _runChoiceStep(step);
      return;
    }
    if (step is CutsceneLabelStep) {
      _advanceStepOnTopFrame();
      return;
    }
    if (step is CutsceneGotoStep) {
      _jumpToLabelOnTopFrame(step.label);
      return;
    }
    if (step is CutsceneGotoIfChoiceStep) {
      _runGotoIfChoiceStep(step);
      return;
    }
    if (step is CutsceneGotoIfFlagStep) {
      final isSet = _context.isFlagSet(step.flagName);
      if (isSet == step.expectedSet) {
        _jumpToLabelOnTopFrame(step.label);
      } else {
        _advanceStepOnTopFrame();
      }
      return;
    }
    if (step is CutsceneGotoIfOutcomeStep) {
      final isSet = _context.isOutcomeSet(step.outcomeId);
      if (isSet == step.expectedSet) {
        _jumpToLabelOnTopFrame(step.label);
      } else {
        _advanceStepOnTopFrame();
      }
      return;
    }
    if (step is CutsceneMoveNpcToStep) {
      _runMoveNpcStep(step);
      return;
    }
    if (step is CutsceneWaitStep) {
      _pendingWait = _PendingWait.waitMs(remainingMs: step.durationMs);
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

  void _runChoiceStep(CutsceneChoiceStep step) {
    final choiceId = step.choiceId.trim();
    if (choiceId.isEmpty) {
      _fail('Choice step has empty choiceId.');
      return;
    }
    if (step.options.isEmpty) {
      _fail('Choice "$choiceId" has no options.');
      return;
    }
    final options = <CutsceneChoiceOption>[];
    final values = <String>{};
    for (final option in step.options) {
      final value = option.value.trim();
      final label = option.label.trim();
      if (value.isEmpty) {
        _fail('Choice "$choiceId" contains an option with empty value.');
        return;
      }
      if (!values.add(value)) {
        _fail('Choice "$choiceId" contains duplicate option value "$value".');
        return;
      }
      options.add(
        CutsceneChoiceOption(
          value: value,
          label: label.isEmpty ? value : label,
        ),
      );
    }
    final request = CutsceneChoiceRequest(
      choiceId: choiceId,
      prompt: step.prompt.trim(),
      options: options,
    );
    if (!_context.requestChoice(request)) {
      _fail('Failed to request player choice "$choiceId".');
      return;
    }
    _activeChoiceRequest = request;
    final top = _topFrame;
    if (top != null) {
      _setRunningStatus(top);
    }
  }

  void _runGotoIfChoiceStep(CutsceneGotoIfChoiceStep step) {
    final choiceId = step.choiceId.trim();
    if (choiceId.isEmpty) {
      _fail('GotoIfChoice has empty choiceId.');
      return;
    }
    final expected = step.expectedValue.trim();
    if (expected.isEmpty) {
      _fail('GotoIfChoice has empty expectedValue.');
      return;
    }
    final result = _choiceResultsById[choiceId];
    if (result == null) {
      _fail('GotoIfChoice cannot find choice result for "$choiceId".');
      return;
    }
    if (result.selectedValue == expected) {
      _jumpToLabelOnTopFrame(step.label);
    } else {
      _advanceStepOnTopFrame();
    }
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
    if (startStatus.state == ScriptedEntityMovementState.completed) {
      _advanceStepOnTopFrame();
      return;
    }
    if (startStatus.state == ScriptedEntityMovementState.moving) {
      _pendingWait = _PendingWait.npcMoveCompleted(entityId: entityId);
      return;
    }
    if (startStatus.state == ScriptedEntityMovementState.failed) {
      _fail(startStatus.failureReason ?? 'Failed to start movement.');
      return;
    }
    _fail('Move step returned idle for "$entityId".');
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
    final calledFrame = _tryBuildFrame(called);
    if (calledFrame == null) {
      return;
    }

    frame.waitingForCalledCutscene = true;
    _frames.add(calledFrame);
    _setRunningStatus(calledFrame);
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

    if (pending.kind == _PendingWaitKind.waitMs) {
      pending.remainingMs = (pending.remainingMs! - dtMs).clamp(0, 1 << 30);
      if (pending.remainingMs == 0) {
        _pendingWait = null;
        _advanceStepOnTopFrame();
      }
      return;
    }
    if (pending.kind == _PendingWaitKind.dialogueClosed) {
      if (!_context.isDialogueOpen()) {
        _pendingWait = null;
        _advanceStepOnTopFrame();
      }
      return;
    }
    if (pending.kind == _PendingWaitKind.npcMoveCompleted) {
      final entityId = pending.entityId!;
      final status = _context.readNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        return;
      }
      if (status.state == ScriptedEntityMovementState.completed) {
        _pendingWait = null;
        _advanceStepOnTopFrame();
        return;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        _pendingWait = null;
        _fail(status.failureReason ?? 'Movement failed for "$entityId".');
        return;
      }
      _pendingWait = null;
      _fail('Movement idle while waiting completion for "$entityId".');
      return;
    }
    if (pending.kind == _PendingWaitKind.flag) {
      final isSet = _context.isFlagSet(pending.flagName!);
      if (isSet == pending.expectedSet) {
        _pendingWait = null;
        _advanceStepOnTopFrame();
      }
      return;
    }
    final isSet = _context.isOutcomeSet(pending.outcomeId!);
    if (isSet == pending.expectedSet) {
      _pendingWait = null;
      _advanceStepOnTopFrame();
    }
  }

  void _onChoiceResolved(CutsceneChoiceResult result) {
    _choiceResultsById[result.choiceId] = result;
    _lastChoiceResult = result;
    _activeChoiceRequest = null;
    _advanceStepOnTopFrame();
  }

  void _jumpToLabelOnTopFrame(String label) {
    final top = _topFrame;
    if (top == null) {
      _fail('Cannot goto label: no active frame.');
      return;
    }
    final normalized = label.trim();
    if (normalized.isEmpty) {
      _fail('Goto has empty label.');
      return;
    }
    final targetStepIndex = top.labelIndexByName[normalized];
    if (targetStepIndex == null) {
      _fail(
        'Goto target "$normalized" not found in cutscene "${top.cutscene.id}".',
      );
      return;
    }
    _recordTransitionOrFail();
    if (!isRunning) {
      return;
    }
    top.stepIndex = targetStepIndex + 1;
    if (top.stepIndex >= top.cutscene.steps.length) {
      _onFrameCompleted();
      return;
    }
    _setRunningStatus(top);
  }

  void _advanceStepOnTopFrame() {
    final top = _topFrame;
    if (top == null) {
      _fail('Cannot advance: no active frame.');
      return;
    }
    _recordTransitionOrFail();
    if (!isRunning) {
      return;
    }
    top.stepIndex += 1;
    if (top.stepIndex >= top.cutscene.steps.length) {
      _onFrameCompleted();
      return;
    }
    _setRunningStatus(top);
  }

  void _recordTransitionOrFail() {
    _transitionCount += 1;
    if (_transitionCount > maxStepTransitions) {
      _fail(
        'Cutscene exceeded step transition limit ($maxStepTransitions). '
        'Possible infinite loop.',
      );
    }
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
    _setRunningStatus(parent);
  }

  _CutsceneFrame? get _topFrame => _frames.isEmpty ? null : _frames.last;

  _CutsceneFrame? _tryBuildFrame(RuntimeCutsceneAsset cutscene) {
    final labels = <String, int>{};
    for (var index = 0; index < cutscene.steps.length; index++) {
      final step = cutscene.steps[index];
      if (step is! CutsceneLabelStep) {
        continue;
      }
      final label = step.label.trim();
      if (label.isEmpty) {
        _fail('Cutscene "${cutscene.id}" has a label with empty value.');
        return null;
      }
      if (labels.containsKey(label)) {
        _fail('Cutscene "${cutscene.id}" has duplicate label "$label".');
        return null;
      }
      labels[label] = index;
    }
    return _CutsceneFrame(
      cutscene: cutscene,
      labelIndexByName: labels,
    );
  }

  void _setRunningStatus(_CutsceneFrame frame) {
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.running,
      activeCutsceneId: frame.cutscene.id,
      activeStepIndex: frame.stepIndex,
      activeChoiceRequest: _activeChoiceRequest,
      lastChoiceResult: _lastChoiceResult,
    );
  }

  void _complete() {
    final activeId = _status.activeCutsceneId;
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.completed,
      activeCutsceneId: activeId,
      activeChoiceRequest: null,
      lastChoiceResult: _lastChoiceResult,
    );
    _frames.clear();
    _pendingWait = null;
    _activeChoiceRequest = null;
  }

  void _fail(String reason) {
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.failed,
      activeCutsceneId: _topFrame?.cutscene.id ?? _status.activeCutsceneId,
      activeStepIndex: _topFrame?.stepIndex ?? _status.activeStepIndex,
      failureReason: reason,
      activeChoiceRequest: _activeChoiceRequest,
      lastChoiceResult: _lastChoiceResult,
    );
    _frames.clear();
    _pendingWait = null;
    _activeChoiceRequest = null;
  }
}

class _CutsceneFrame {
  _CutsceneFrame({
    required this.cutscene,
    required this.labelIndexByName,
  });

  final RuntimeCutsceneAsset cutscene;
  final Map<String, int> labelIndexByName;
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
