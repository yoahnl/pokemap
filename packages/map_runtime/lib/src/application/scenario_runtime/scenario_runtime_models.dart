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
enum ScenarioRuntimeSourceType {
  mapEnter,
  triggerEnter,
  entityInteract,
}

/// Événement source envoyé au runtime bridge pour tenter une exécution.
///
/// On encode explicitement `mapId` + identifiants contextuels optionnels.
/// Cela permet de matcher précisément les nodes "source*" du Scenario Graph.
class ScenarioRuntimeSourceEvent {
  const ScenarioRuntimeSourceEvent._({
    required this.type,
    required this.mapId,
    this.triggerId,
    this.entityId,
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

  final ScenarioRuntimeSourceType type;
  final String mapId;
  final String? triggerId;
  final String? entityId;
}

/// Type d'effet réellement déclenché par le bridge runtime.
enum ScenarioRuntimeEffectType {
  dialogue,
  script,
  message,
  none,
}

/// Effet déclenché (ou absence d'effet) pour la tentative d'exécution.
class ScenarioRuntimeEffect {
  const ScenarioRuntimeEffect({
    required this.type,
    this.dialogueId,
    this.scriptId,
    this.message,
  });

  const ScenarioRuntimeEffect.none()
      : this(type: ScenarioRuntimeEffectType.none);

  final ScenarioRuntimeEffectType type;
  final String? dialogueId;
  final String? scriptId;
  final String? message;
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
  });

  final ScenarioRuntimeExecutionStatus status;
  final ScenarioRuntimeEffect effect;
  final String message;
  final String? scenarioId;
  final String? sourceNodeId;
  final String? stopNodeId;

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
  });

  GameState gameState;
  final void Function(GameState) onGameStateUpdated;
  final ScenarioRuntimeOpenDialogue openDialogue;
  final ScenarioRuntimeRunScript runScript;
  final ScenarioRuntimeShowMessage showMessage;
}
