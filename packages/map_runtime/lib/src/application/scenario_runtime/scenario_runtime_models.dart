import 'package:map_core/map_core.dart';

/// Types de sources runtime supportées par l'exécuteur MVP du graphe scénario.
///
/// Le but est volontairement limité :
/// - entrée de map,
/// - entrée dans un trigger de map,
/// - interaction avec une entité.
///
/// Chaque source correspond à un preset d'authoring côté éditeur :
/// - `sourceMapEnter`
/// - `sourceTriggerEnter`
/// - `sourceEntityInteract`
/// - `sourceOutcome`
enum ScenarioRuntimeSourceType {
  mapEnter,
  triggerEnter,
  entityInteract,
  outcomeReceived,
}

/// Événement source envoyé au runtime bridge pour tenter une exécution.
///
/// On encode explicitement `mapId` + identifiants contextuels optionnels.
/// Cela permet de matcher précisément les nodes "source*" du Scenario Graph.
/// Pour `outcomeReceived`, seul `outcomeId` est utilisé.
class ScenarioRuntimeSourceEvent {
  const ScenarioRuntimeSourceEvent._({
    required this.type,
    required this.mapId,
    this.triggerId,
    this.entityId,
    this.outcomeId,
  });

  factory ScenarioRuntimeSourceEvent.mapEnter({
    required String mapId,
  }) {
    return ScenarioRuntimeSourceEvent._(
      type: ScenarioRuntimeSourceType.mapEnter,
      mapId: mapId.trim(),
    );
  }

  factory ScenarioRuntimeSourceEvent.triggerEnter({
    required String mapId,
    required String triggerId,
  }) {
    return ScenarioRuntimeSourceEvent._(
      type: ScenarioRuntimeSourceType.triggerEnter,
      mapId: mapId.trim(),
      triggerId: triggerId.trim(),
    );
  }

  factory ScenarioRuntimeSourceEvent.entityInteract({
    required String mapId,
    required String entityId,
  }) {
    return ScenarioRuntimeSourceEvent._(
      type: ScenarioRuntimeSourceType.entityInteract,
      mapId: mapId.trim(),
      entityId: entityId.trim(),
    );
  }

  factory ScenarioRuntimeSourceEvent.outcomeReceived({
    required String outcomeId,
  }) {
    return ScenarioRuntimeSourceEvent._(
      type: ScenarioRuntimeSourceType.outcomeReceived,
      mapId: '',
      outcomeId: outcomeId.trim(),
    );
  }

  final ScenarioRuntimeSourceType type;
  final String mapId;
  final String? triggerId;
  final String? entityId;
  final String? outcomeId;
}

/// Type d'effet réellement déclenché par le bridge runtime.
enum ScenarioRuntimeEffectType {
  dialogue,
  script,
  message,

  /// Le graphe scénario demande un combat trainer.
  ///
  /// Le runtime suspend le traversal et lance le battle handoff existant.
  /// Après `BattleOutcome`, un flag d'outcome déterministe est posé et le
  /// graphe reprend via `dispatchContinuation`.
  battle,
  none,
}

/// Effet déclenché (ou absence d'effet) pour la tentative d'exécution.
class ScenarioRuntimeEffect {
  const ScenarioRuntimeEffect({
    required this.type,
    this.dialogueId,
    this.scriptId,
    this.message,
    this.battleId,
    this.trainerId,
    this.npcEntityId,
  });

  const ScenarioRuntimeEffect.none()
      : this(type: ScenarioRuntimeEffectType.none);

  final ScenarioRuntimeEffectType type;
  final String? dialogueId;
  final String? scriptId;
  final String? message;

  /// Identifiant stable du combat (utilisé pour nommer les flags d'outcome).
  /// Exemple : `battle_rival_port`.
  final String? battleId;

  /// Identifiant du trainer dans le ProjectManifest.
  final String? trainerId;

  /// Identifiant de l'entité NPC sur la map.
  final String? npcEntityId;
}

/// Statut global d'exécution d'un déclenchement scénario.
enum ScenarioRuntimeExecutionStatus {
  /// Aucune source ne correspond à l'événement runtime.
  noMatchingSource,

  /// Une branche a été trouvée et un effet concret a été déclenché.
  executedEffect,

  /// Une branche a été trouvée mais se termine proprement sans effet terminal.
  reachedEnd,

  /// Une branche a été trouvée mais l'exécution a bloqué (node invalide/non supporté).
  blocked,
}

/// Résultat détaillé de l'exécution.
///
/// Ce modèle est utilisé à la fois :
/// - pour logs runtime / debug,
/// - pour tests unitaires du bridge.
class ScenarioRuntimeExecutionResult {
  const ScenarioRuntimeExecutionResult({
    required this.status,
    required this.effect,
    required this.message,
    this.scenarioId,
    this.sourceNodeId,
    this.stopNodeId,
    this.emittedOutcomeId,
  });

  final ScenarioRuntimeExecutionStatus status;
  final ScenarioRuntimeEffect effect;
  final String message;
  final String? scenarioId;
  final String? sourceNodeId;
  final String? stopNodeId;
  final String? emittedOutcomeId;

  bool get handled => status != ScenarioRuntimeExecutionStatus.noMatchingSource;

  bool get success =>
      status == ScenarioRuntimeExecutionStatus.executedEffect ||
      status == ScenarioRuntimeExecutionStatus.reachedEnd;
}

/// Callback pour ouvrir un dialogue projet via son `dialogueId`.
typedef ScenarioRuntimeOpenDialogue = bool Function(
  String dialogueId, {
  String? startNode,
  String? runtimeSourceId,
});

/// Callback pour exécuter un script projet via son `scriptId`.
typedef ScenarioRuntimeRunScript = bool Function(
  String scriptId, {
  String? startNode,
  String? runtimeSourceId,
});

/// Callback pour afficher un message runtime simple.
typedef ScenarioRuntimeShowMessage = void Function(String message);

/// Callback pour démarrer un déplacement de personnage depuis une action
/// scénario (bridge Cutscene Studio -> runtime).
typedef ScenarioRuntimeMoveCharacter = bool Function({
  required String entityId,
  required String targetKind,
  required String targetId,
  required bool waitForCompletion,
  String? runtimeSourceId,
});

/// Callback pour l'action scénario `followCharacter`.
///
/// Le leader est généralement un PNJ. L'implémentation runtime décide comment
/// rapprocher le joueur du leader (pas à pas, snap, etc.) selon les contraintes
/// actuelles du moteur.
typedef ScenarioRuntimeFollowCharacter = bool Function({
  required String leaderEntityId,
});

/// Callback pour l'action scénario `faceCharacter`.
///
/// Oriente une entité vers une direction cardinale (`north/south/east/west`).
typedef ScenarioRuntimeFaceCharacter = bool Function({
  required String entityId,
  required String direction,
});

/// Callback pour l'action scénario `transitionMap`.
///
/// Déclenche une transition de map pour le joueur vers une destination
/// explicite (`mapId` + `warpId` cible dans cette map).
typedef ScenarioRuntimeTransitionMap = bool Function({
  required String mapId,
  required String warpId,
});

/// Callback optionnel : si [true], le scénario candidat est ignoré et la
/// recherche continue (ex. cutscene locale déjà « consommée » par une step
/// Step Studio complétée — voir persistance `completedStepIds`).
typedef ScenarioRuntimeShouldSkipScenario = bool Function(String scenarioId);

/// Contexte mutable d'exécution du bridge.
///
/// Le bridge reste pur sur l'analyse du graphe, mais délègue les effets
/// concrets (UI dialogue/script/message) via callbacks.
class ScenarioRuntimeExecutionContext {
  ScenarioRuntimeExecutionContext({
    required this.gameState,
    required this.onGameStateUpdated,
    required this.openDialogue,
    required this.runScript,
    required this.showMessage,
    this.moveCharacter = _defaultMoveCharacter,
    this.followCharacter = _defaultFollowCharacter,
    this.faceCharacter = _defaultFaceCharacter,
    this.transitionMap = _defaultTransitionMap,
    this.shouldSkipScenario,
  });

  GameState gameState;
  final void Function(GameState) onGameStateUpdated;
  final ScenarioRuntimeOpenDialogue openDialogue;
  final ScenarioRuntimeRunScript runScript;
  final ScenarioRuntimeShowMessage showMessage;
  final ScenarioRuntimeMoveCharacter moveCharacter;
  final ScenarioRuntimeFollowCharacter followCharacter;
  final ScenarioRuntimeFaceCharacter faceCharacter;
  final ScenarioRuntimeTransitionMap transitionMap;

  /// Filtre appliqué **après** match de source et **avant** exécution du flow.
  ///
  /// Uniquement sur [ScenarioRuntimeExecutor.dispatch] (parcours de candidats),
  /// pas sur [ScenarioRuntimeExecutor.dispatchContinuation] (reprise ciblée).
  final ScenarioRuntimeShouldSkipScenario? shouldSkipScenario;

  static bool _defaultMoveCharacter({
    required String entityId,
    required String targetKind,
    required String targetId,
    required bool waitForCompletion,
    String? runtimeSourceId,
  }) {
    return false;
  }

  static bool _defaultFollowCharacter({
    required String leaderEntityId,
  }) {
    return false;
  }

  static bool _defaultFaceCharacter({
    required String entityId,
    required String direction,
  }) {
    return false;
  }

  static bool _defaultTransitionMap({
    required String mapId,
    required String warpId,
  }) {
    return false;
  }
}
