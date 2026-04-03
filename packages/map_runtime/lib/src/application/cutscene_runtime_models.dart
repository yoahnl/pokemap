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
    this.activeChoiceRequest,
    this.lastChoiceResult,
  });

  const CutsceneRuntimeStatus.idle()
      : this(
          state: CutsceneRunnerState.idle,
        );

  final CutsceneRunnerState state;
  final String? activeCutsceneId;
  final int? activeStepIndex;
  final String? failureReason;
  final CutsceneChoiceRequest? activeChoiceRequest;
  final CutsceneChoiceResult? lastChoiceResult;

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

class CutsceneChoiceOption {
  const CutsceneChoiceOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class CutsceneChoiceRequest {
  const CutsceneChoiceRequest({
    required this.choiceId,
    required this.prompt,
    required this.options,
  });

  final String choiceId;
  final String prompt;
  final List<CutsceneChoiceOption> options;
}

class CutsceneChoiceResult {
  const CutsceneChoiceResult({
    required this.choiceId,
    required this.selectedIndex,
    required this.selectedValue,
    required this.selectedLabel,
  });

  final String choiceId;
  final int selectedIndex;
  final String selectedValue;
  final String selectedLabel;
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

/// Étape: demander un choix joueur.
///
/// Le runner:
/// - émet une requête de choix via le host runtime,
/// - attend la résolution explicite du choix,
/// - stocke le résultat pour les étapes de branchement suivantes.
class CutsceneChoiceStep extends RuntimeCutsceneStep {
  const CutsceneChoiceStep({
    required this.choiceId,
    required this.prompt,
    required this.options,
  });

  final String choiceId;
  final String prompt;
  final List<CutsceneChoiceOption> options;
}

/// Étape de marquage de position dans la cutscene.
///
/// No-op à l'exécution, utilisée comme cible de goto.
class CutsceneLabelStep extends RuntimeCutsceneStep {
  const CutsceneLabelStep({
    required this.label,
  });

  final String label;
}

/// Étape de saut inconditionnel vers un label.
class CutsceneGotoStep extends RuntimeCutsceneStep {
  const CutsceneGotoStep({
    required this.label,
  });

  final String label;
}

/// Saut vers label si le résultat du choix est égal à une valeur.
class CutsceneGotoIfChoiceStep extends RuntimeCutsceneStep {
  const CutsceneGotoIfChoiceStep({
    required this.choiceId,
    required this.expectedValue,
    required this.label,
  });

  final String choiceId;
  final String expectedValue;
  final String label;
}

/// Saut vers label si un flag est dans l'état attendu.
class CutsceneGotoIfFlagStep extends RuntimeCutsceneStep {
  const CutsceneGotoIfFlagStep({
    required this.flagName,
    required this.label,
    this.expectedSet = true,
  });

  final String flagName;
  final String label;
  final bool expectedSet;
}

/// Saut vers label si un outcome est dans l'état attendu.
class CutsceneGotoIfOutcomeStep extends RuntimeCutsceneStep {
  const CutsceneGotoIfOutcomeStep({
    required this.outcomeId,
    required this.label,
    this.expectedSet = true,
  });

  final String outcomeId;
  final String label;
  final bool expectedSet;
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
