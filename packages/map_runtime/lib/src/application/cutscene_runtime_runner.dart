import 'package:map_core/map_core.dart';

import 'cutscene_runtime_models.dart';
import 'scripted_entity_movement_models.dart';

/// Callback d'ouverture de dialogue pour une étape [CutsceneDialogueStep].
typedef CutsceneOpenDialogue = bool Function(
  String dialogueId, {
  String? startNode,
});

/// Callback de démarrage de déplacement PNJ.
typedef CutsceneMoveNpcTo = ScriptedEntityMovementStatus Function({
  required String entityId,
  required GridPos destination,
});

/// Callback de lecture d'état de mouvement PNJ.
typedef CutsceneReadNpcMovementStatus = ScriptedEntityMovementStatus Function(
  String entityId,
);

/// Callback d'orientation PNJ.
typedef CutsceneFaceNpc = bool Function({
  required String entityId,
  required EntityFacing facing,
});

/// Callback d'émission d'outcome.
typedef CutsceneEmitOutcome = void Function(String outcomeId);

/// Callback mutation flag set.
typedef CutsceneSetFlag = void Function(String flagName);

/// Callback mutation flag clear.
typedef CutsceneClearFlag = void Function(String flagName);

/// Contexte runtime injectable du runner cutscene.
///
/// Le runner ne connaît pas `PlayableMapGame` ni Flame:
/// - il orchestre uniquement la séquence,
/// - les effets concrets sont délégués par callbacks.
class CutsceneRuntimeContext {
  const CutsceneRuntimeContext({
    required this.openDialogue,
    required this.moveNpcTo,
    required this.readNpcMovementStatus,
    required this.faceNpc,
    required this.emitOutcome,
    required this.setFlag,
    required this.clearFlag,
  });

  final CutsceneOpenDialogue openDialogue;
  final CutsceneMoveNpcTo moveNpcTo;
  final CutsceneReadNpcMovementStatus readNpcMovementStatus;
  final CutsceneFaceNpc faceNpc;
  final CutsceneEmitOutcome emitOutcome;
  final CutsceneSetFlag setFlag;
  final CutsceneClearFlag clearFlag;
}

/// Runner séquentiel minimal pour runtime cutscene.
///
/// Contrat:
/// - une seule cutscene active à la fois;
/// - progression étape par étape;
/// - une étape ne passe à la suivante que lorsqu'elle est terminée;
/// - `moveNpcTo` attend explicitement `completed`/`failed`.
class CutsceneRuntimeRunner {
  CutsceneRuntimeRunner({
    required CutsceneRuntimeContext context,
  }) : _context = context;

  final CutsceneRuntimeContext _context;

  RuntimeCutsceneAsset? _activeCutscene;
  int _stepIndex = 0;
  CutsceneRuntimeStatus _status = const CutsceneRuntimeStatus.idle();

  // État transitoire pour les étapes asynchrones (wait / move).
  String? _activeMovementEntityId;
  int? _waitRemainingMs;

  CutsceneRuntimeStatus get status => _status;
  bool get isRunning => _status.isRunning;
  String? get activeCutsceneId => _status.activeCutsceneId;

  /// Démarre une nouvelle cutscene.
  ///
  /// Retourne `false` si un run est déjà actif ou si l'asset est invalide.
  bool start(RuntimeCutsceneAsset cutscene) {
    if (isRunning) {
      return false;
    }
    final id = cutscene.id.trim();
    if (id.isEmpty) {
      _status = const CutsceneRuntimeStatus(
        state: CutsceneRunnerState.failed,
        failureReason: 'Cannot start cutscene with empty id.',
      );
      return false;
    }

    _activeCutscene = cutscene;
    _stepIndex = 0;
    _activeMovementEntityId = null;
    _waitRemainingMs = null;
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.running,
      activeCutsceneId: id,
      activeStepIndex: 0,
    );

    // Cas edge: cutscene vide => completed immédiat.
    if (cutscene.steps.isEmpty) {
      _complete();
    }
    return true;
  }

  /// Tick runner.
  ///
  /// - `dtSeconds` est converti en ms pour l'étape wait;
  /// - une seule étape est évaluée par tick pour garder une progression
  ///   prévisible et facile à déboguer.
  void update(double dtSeconds) {
    if (!isRunning) {
      return;
    }
    final cutscene = _activeCutscene;
    if (cutscene == null) {
      _fail('Runner is running without active cutscene.');
      return;
    }
    if (_stepIndex >= cutscene.steps.length) {
      _complete();
      return;
    }

    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.running,
      activeCutsceneId: cutscene.id,
      activeStepIndex: _stepIndex,
    );

    final step = cutscene.steps[_stepIndex];
    if (step is CutsceneDialogueStep) {
      _runDialogueStep(step);
      return;
    }
    if (step is CutsceneMoveNpcToStep) {
      _runMoveNpcStep(step);
      return;
    }
    if (step is CutsceneWaitStep) {
      _runWaitStep(step, dtSeconds);
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

    // Garde-fou futur: si un nouveau type de step est ajouté sans logique.
    _fail('Unsupported cutscene step type: ${step.runtimeType}.');
  }

  void _runDialogueStep(CutsceneDialogueStep step) {
    final dialogueId = step.dialogueId.trim();
    if (dialogueId.isEmpty) {
      _fail('Dialogue step has empty dialogueId.');
      return;
    }

    // Règle MVP demandée: l'étape est terminée dès que l'ouverture a été
    // lancée avec succès (pas d'attente de fin de dialogue dans ce lot).
    final opened = _context.openDialogue(
      dialogueId,
      startNode: step.startNode,
    );
    if (!opened) {
      _fail('Failed to open dialogue "$dialogueId".');
      return;
    }
    _advanceStep();
  }

  void _runMoveNpcStep(CutsceneMoveNpcToStep step) {
    final entityId = step.entityId.trim();
    if (entityId.isEmpty) {
      _fail('Move step has empty entityId.');
      return;
    }

    // Premier tick de l'étape: on déclenche la commande de mouvement.
    if (_activeMovementEntityId == null) {
      final startStatus = _context.moveNpcTo(
        entityId: entityId,
        destination: step.destination,
      );
      if (startStatus.state == ScriptedEntityMovementState.failed) {
        _fail(startStatus.failureReason ?? 'Failed to start movement.');
        return;
      }
      if (startStatus.state == ScriptedEntityMovementState.completed) {
        _advanceStep();
        return;
      }
      _activeMovementEntityId = entityId;
      return;
    }

    // Ticks suivants: on attend explicitement la fin du déplacement.
    final status = _context.readNpcMovementStatus(_activeMovementEntityId!);
    switch (status.state) {
      case ScriptedEntityMovementState.idle:
        // Idle inattendu alors qu'on attend un move actif => erreur explicite.
        _fail('Movement became idle before completion for "$entityId".');
      case ScriptedEntityMovementState.moving:
        // On attend le prochain tick.
        return;
      case ScriptedEntityMovementState.completed:
        _activeMovementEntityId = null;
        _advanceStep();
      case ScriptedEntityMovementState.failed:
        _activeMovementEntityId = null;
        _fail(status.failureReason ?? 'Movement failed for "$entityId".');
    }
  }

  void _runWaitStep(CutsceneWaitStep step, double dtSeconds) {
    if (step.durationMs < 0) {
      _fail('Wait step has negative duration.');
      return;
    }
    _waitRemainingMs ??= step.durationMs;
    _waitRemainingMs = (_waitRemainingMs! - (dtSeconds * 1000).round()).clamp(
      0,
      1 << 30,
    );
    if (_waitRemainingMs == 0) {
      _waitRemainingMs = null;
      _advanceStep();
    }
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
    _advanceStep();
  }

  void _runEmitOutcomeStep(CutsceneEmitOutcomeStep step) {
    final outcomeId = step.outcomeId.trim();
    if (outcomeId.isEmpty) {
      _fail('EmitOutcome step has empty outcomeId.');
      return;
    }
    _context.emitOutcome(outcomeId);
    _advanceStep();
  }

  void _runSetFlagStep(CutsceneSetFlagStep step) {
    final flagName = step.flagName.trim();
    if (flagName.isEmpty) {
      _fail('SetFlag step has empty flagName.');
      return;
    }
    _context.setFlag(flagName);
    _advanceStep();
  }

  void _runClearFlagStep(CutsceneClearFlagStep step) {
    final flagName = step.flagName.trim();
    if (flagName.isEmpty) {
      _fail('ClearFlag step has empty flagName.');
      return;
    }
    _context.clearFlag(flagName);
    _advanceStep();
  }

  void _advanceStep() {
    final cutscene = _activeCutscene;
    if (cutscene == null) {
      _fail('Cannot advance: no active cutscene.');
      return;
    }
    _stepIndex += 1;
    _activeMovementEntityId = null;
    _waitRemainingMs = null;
    if (_stepIndex >= cutscene.steps.length) {
      _complete();
    } else {
      _status = CutsceneRuntimeStatus(
        state: CutsceneRunnerState.running,
        activeCutsceneId: cutscene.id,
        activeStepIndex: _stepIndex,
      );
    }
  }

  void _complete() {
    final activeId = _activeCutscene?.id;
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.completed,
      activeCutsceneId: activeId,
      activeStepIndex: _stepIndex,
    );
    _activeCutscene = null;
    _activeMovementEntityId = null;
    _waitRemainingMs = null;
  }

  void _fail(String reason) {
    _status = CutsceneRuntimeStatus(
      state: CutsceneRunnerState.failed,
      activeCutsceneId: _activeCutscene?.id,
      activeStepIndex: _stepIndex,
      failureReason: reason,
    );
    _activeCutscene = null;
    _activeMovementEntityId = null;
    _waitRemainingMs = null;
  }
}
