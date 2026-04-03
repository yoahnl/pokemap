import 'package:map_core/map_core.dart';

/// Définition runtime minimale d'une cutscene.
///
/// Ce modèle est volontairement simple:
/// - un identifiant stable,
/// - un nom lisible,
/// - une liste ordonnée d'étapes séquentielles.
///
/// Aucune dépendance UI/editor n'est introduite ici.
class RuntimeCutsceneAsset {
  const RuntimeCutsceneAsset({
    required this.id,
    required this.name,
    required this.steps,
  });

  final String id;
  final String name;
  final List<RuntimeCutsceneStep> steps;
}

/// États globaux du runner de cutscene.
enum CutsceneRunnerState {
  idle,
  running,
  completed,
  failed,
}

/// Snapshot public du runner.
///
/// Sert à:
/// - savoir si une cutscene est active,
/// - exposer un état lisible au runtime hôte,
/// - diagnostiquer une failure explicite.
class CutsceneRuntimeStatus {
  const CutsceneRuntimeStatus({
    required this.state,
    this.activeCutsceneId,
    this.activeStepIndex,
    this.failureReason,
  });

  const CutsceneRuntimeStatus.idle()
      : this(
          state: CutsceneRunnerState.idle,
        );

  final CutsceneRunnerState state;
  final String? activeCutsceneId;
  final int? activeStepIndex;
  final String? failureReason;

  bool get isRunning => state == CutsceneRunnerState.running;
  bool get isTerminal =>
      state == CutsceneRunnerState.completed ||
      state == CutsceneRunnerState.failed;
}

/// Type racine d'étape cutscene.
///
/// On garde des classes concrètes (au lieu d'un payload dynamique) pour:
/// - lisibilité,
/// - sécurité de type,
/// - facilité de test.
abstract class RuntimeCutsceneStep {
  const RuntimeCutsceneStep();
}

/// Étape: ouvrir un dialogue projet.
class CutsceneDialogueStep extends RuntimeCutsceneStep {
  const CutsceneDialogueStep({
    required this.dialogueId,
    this.startNode,
    this.waitUntilClosed = true,
  });

  final String dialogueId;
  final String? startNode;
  final bool waitUntilClosed;
}

/// Étape: déplacer un PNJ vers une destination grille.
class CutsceneMoveNpcToStep extends RuntimeCutsceneStep {
  const CutsceneMoveNpcToStep({
    required this.entityId,
    required this.destination,
  });

  final String entityId;
  final GridPos destination;
}

/// Étape: attendre une durée fixe.
class CutsceneWaitStep extends RuntimeCutsceneStep {
  const CutsceneWaitStep({
    required this.durationMs,
  });

  final int durationMs;
}

/// Étape: attendre explicitement la fermeture du dialogue actif.
class CutsceneWaitUntilDialogueClosedStep extends RuntimeCutsceneStep {
  const CutsceneWaitUntilDialogueClosedStep({
    this.timeoutMs,
  });

  final int? timeoutMs;
}

/// Étape: attendre explicitement qu'un PNJ termine son mouvement.
class CutsceneWaitUntilNpcMoveCompletedStep extends RuntimeCutsceneStep {
  const CutsceneWaitUntilNpcMoveCompletedStep({
    required this.entityId,
    this.timeoutMs,
  });

  final String entityId;
  final int? timeoutMs;
}

/// Étape: orienter un PNJ.
class CutsceneFaceNpcStep extends RuntimeCutsceneStep {
  const CutsceneFaceNpcStep({
    required this.entityId,
    required this.facing,
  });

  final String entityId;
  final EntityFacing facing;
}

/// Étape: émettre un outcome runtime.
class CutsceneEmitOutcomeStep extends RuntimeCutsceneStep {
  const CutsceneEmitOutcomeStep({
    required this.outcomeId,
  });

  final String outcomeId;
}

/// Étape: attendre qu'un flag soit dans un état donné.
class CutsceneWaitUntilFlagStep extends RuntimeCutsceneStep {
  const CutsceneWaitUntilFlagStep({
    required this.flagName,
    this.expectedSet = true,
    this.timeoutMs,
  });

  final String flagName;
  final bool expectedSet;
  final int? timeoutMs;
}

/// Étape: attendre qu'un outcome soit émis (persisté) ou non.
class CutsceneWaitUntilOutcomeStep extends RuntimeCutsceneStep {
  const CutsceneWaitUntilOutcomeStep({
    required this.outcomeId,
    this.expectedSet = true,
    this.timeoutMs,
  });

  final String outcomeId;
  final bool expectedSet;
  final int? timeoutMs;
}

/// Étape: activer un flag runtime.
class CutsceneSetFlagStep extends RuntimeCutsceneStep {
  const CutsceneSetFlagStep({
    required this.flagName,
  });

  final String flagName;
}

/// Étape: désactiver un flag runtime.
class CutsceneClearFlagStep extends RuntimeCutsceneStep {
  const CutsceneClearFlagStep({
    required this.flagName,
  });

  final String flagName;
}

/// Étape: appeler une autre cutscene par ID.
class CutsceneCallStep extends RuntimeCutsceneStep {
  const CutsceneCallStep({
    required this.cutsceneId,
  });

  final String cutsceneId;
}
