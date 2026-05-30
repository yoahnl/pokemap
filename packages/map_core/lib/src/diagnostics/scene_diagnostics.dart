import '../models/scene_asset.dart';

enum SceneDiagnosticSeverity {
  error,
  warning,
  info,
}

enum SceneDiagnosticCode {
  missingStartNode,
  startNodeNotFound,
  startNodeNotStartKind,
  missingEndNode,
  unknownFromNode,
  unknownToNode,
  layoutUnknownNode,
  layoutMissingNode,
  declaredOutcomeUnused,
  endOutcomeUndeclared,
  conditionSourceMissing,
  conditionSourceUnknown,
  conditionOperatorMissing,
  conditionOperatorUnsupported,
  conditionValueMissing,
  conditionSourceRequiresPicker,
  conditionUsesFutureSource,
  conditionUsesRawTechnicalId,
  conditionSourceMigratesToFactRegistry,
  emptyGraph,
  legacyScenarioLeak,
}

enum SceneDiagnosticTarget {
  scene,
  graph,
  node,
  edge,
  layout,
  outcome,
}

final class SceneDiagnostic {
  const SceneDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.sceneId,
    required this.target,
    this.nodeId,
    this.edgeId,
    this.outcomeId,
    this.suggestedFixLabel,
  });

  final SceneDiagnosticCode code;
  final SceneDiagnosticSeverity severity;
  final String message;
  final String sceneId;
  final SceneDiagnosticTarget target;
  final String? nodeId;
  final String? edgeId;
  final String? outcomeId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.sceneId == sceneId &&
          other.target == target &&
          other.nodeId == nodeId &&
          other.edgeId == edgeId &&
          other.outcomeId == outcomeId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        sceneId,
        target,
        nodeId,
        edgeId,
        outcomeId,
        suggestedFixLabel,
      );
}

final class SceneDiagnosticsReport {
  SceneDiagnosticsReport({
    required List<SceneDiagnostic> diagnostics,
  }) : _diagnostics = List<SceneDiagnostic>.unmodifiable(diagnostics);

  final List<SceneDiagnostic> _diagnostics;

  List<SceneDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where(
          (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where(
        (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.warning,
      )
      .length;

  int get infoCount => _diagnostics
      .where(
          (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<SceneDiagnostic> byCode(SceneDiagnosticCode code) {
    return List<SceneDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }
}

SceneDiagnosticsReport diagnoseScene(SceneAsset scene) {
  final diagnostics = <SceneDiagnostic>[];
  final nodeById = {
    for (final node in scene.graph.nodes) node.id: node,
  };
  final nodeIds = nodeById.keys.toSet();

  if (scene.graph.nodes.isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.emptyGraph,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène ne contient aucun nœud.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Créer un nœud de début et un nœud de fin.',
      ),
    );
  }

  if (scene.graph.startNodeId.trim().isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.missingStartNode,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène n’a pas de nœud de départ.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Définir un nœud de départ.',
      ),
    );
  } else {
    final startNode = nodeById[scene.graph.startNodeId];
    if (startNode == null) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.startNodeNotFound,
          severity: SceneDiagnosticSeverity.error,
          message: 'Le nœud de départ est introuvable.',
          sceneId: scene.id,
          nodeId: scene.graph.startNodeId,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Choisir un nœud de départ existant.',
        ),
      );
    } else if (startNode.kind != SceneNodeKind.start) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.startNodeNotStartKind,
          severity: SceneDiagnosticSeverity.error,
          message: 'Le nœud de départ doit être de type début.',
          sceneId: scene.id,
          nodeId: startNode.id,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Utiliser un nœud de type début.',
        ),
      );
    }
  }

  if (!scene.graph.nodes.any((node) => node.kind == SceneNodeKind.end)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.missingEndNode,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène n’a pas de fin.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Ajouter un nœud de fin.',
      ),
    );
  }

  if (scene.graph.nodes.length == 1 && scene.graph.edges.isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.emptyGraph,
        severity: SceneDiagnosticSeverity.info,
        message: 'La scène contient seulement un nœud isolé.',
        sceneId: scene.id,
        nodeId: scene.graph.nodes.single.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Ajouter au moins un chemin vers une fin.',
      ),
    );
  }

  for (final edge in scene.graph.edges) {
    if (!nodeIds.contains(edge.fromNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.unknownFromNode,
          severity: SceneDiagnosticSeverity.error,
          message: 'Un lien part d’un nœud inconnu.',
          sceneId: scene.id,
          edgeId: edge.id,
          nodeId: edge.fromNodeId,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Reconnecter le lien depuis un nœud existant.',
        ),
      );
    }
    if (!nodeIds.contains(edge.toNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.unknownToNode,
          severity: SceneDiagnosticSeverity.error,
          message: 'Un lien pointe vers un nœud inconnu.',
          sceneId: scene.id,
          edgeId: edge.id,
          nodeId: edge.toNodeId,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Reconnecter le lien vers un nœud existant.',
        ),
      );
    }
  }

  for (final node in scene.graph.nodes) {
    if (node.kind == SceneNodeKind.condition) {
      _diagnoseConditionNode(scene, node, diagnostics);
    }
  }

  final layoutNodeIds = {
    for (final layout in scene.layout.nodeLayouts) layout.nodeId,
  };
  for (final layoutNodeId in layoutNodeIds) {
    if (!nodeIds.contains(layoutNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.layoutUnknownNode,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Le layout référence un nœud inconnu.',
          sceneId: scene.id,
          nodeId: layoutNodeId,
          target: SceneDiagnosticTarget.layout,
          suggestedFixLabel: 'Retirer cette position de layout.',
        ),
      );
    }
  }
  for (final node in scene.graph.nodes) {
    if (!layoutNodeIds.contains(node.id)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.layoutMissingNode,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Un nœud n’a pas de position sauvegardée.',
          sceneId: scene.id,
          nodeId: node.id,
          target: SceneDiagnosticTarget.layout,
          suggestedFixLabel: 'Sauvegarder une position de layout.',
        ),
      );
    }
  }

  final declaredOutcomeIds = {
    for (final outcome in scene.declaredOutcomes) outcome.id,
  };
  final emittedSceneOutcomeIds = <String>{};
  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    if (payload is! SceneEndPayload) {
      continue;
    }
    final outcomeId = payload.sceneOutcomeId;
    if (outcomeId == null) {
      continue;
    }
    emittedSceneOutcomeIds.add(outcomeId);
    if (!declaredOutcomeIds.contains(outcomeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.endOutcomeUndeclared,
          severity: SceneDiagnosticSeverity.error,
          message: 'Une fin émet un outcome non déclaré.',
          sceneId: scene.id,
          nodeId: node.id,
          outcomeId: outcomeId,
          target: SceneDiagnosticTarget.outcome,
          suggestedFixLabel: 'Déclarer cet outcome de scène.',
        ),
      );
    }
  }
  for (final outcome in scene.declaredOutcomes) {
    if (!emittedSceneOutcomeIds.contains(outcome.id)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.declaredOutcomeUnused,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Un outcome déclaré n’est émis par aucune fin.',
          sceneId: scene.id,
          outcomeId: outcome.id,
          target: SceneDiagnosticTarget.outcome,
          suggestedFixLabel: 'Utiliser cet outcome dans un nœud de fin.',
        ),
      );
    }
  }

  return SceneDiagnosticsReport(diagnostics: diagnostics);
}

void _diagnoseConditionNode(
  SceneAsset scene,
  SceneNode node,
  List<SceneDiagnostic> diagnostics,
) {
  final payload = node.payload;
  if (payload is! SceneConditionPayload) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionSourceMissing,
        severity: SceneDiagnosticSeverity.error,
        message: 'La condition doit avoir un payload condition.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Reconfigurer le nœud Condition.',
      ),
    );
    return;
  }

  final source = payload.conditionSource;
  if (source == null) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionSourceMissing,
        severity: SceneDiagnosticSeverity.error,
        message: 'La condition doit choisir une source métier V0.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir Fact-like, Story Step ou Event consommé.',
      ),
    );
    return;
  }

  if (!_isConditionSourceKindSupportedV0(source.sourceKind)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionUsesFutureSource,
        severity: SceneDiagnosticSeverity.error,
        message: 'Cette source de condition est prévue pour un lot futur.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Utiliser une source V0 existante.',
      ),
    );
    return;
  }

  if (!_isConditionOperatorSupportedV0(source)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionOperatorUnsupported,
        severity: SceneDiagnosticSeverity.error,
        message: 'Cet opérateur n’est pas compatible avec la source V0.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir un opérateur supporté pour cette source.',
      ),
    );
  }

  if (source.sourceKind == SceneConditionSourceKind.storyStepCompletion &&
      !_isStoryStepCompletionValue(source.value)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionValueMissing,
        severity: SceneDiagnosticSeverity.error,
        message: 'La condition Story Step doit choisir completed/notCompleted.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir la valeur de complétion attendue.',
      ),
    );
  }

  final label = source.label?.trim();
  if (label == null || label.isEmpty || label == source.sourceId) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionUsesRawTechnicalId,
        severity: SceneDiagnosticSeverity.warning,
        message: 'La condition affiche encore un identifiant technique.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir un label lisible via le picker.',
      ),
    );
  }
}

bool _isConditionSourceKindSupportedV0(SceneConditionSourceKind kind) {
  return switch (kind) {
    SceneConditionSourceKind.factLikeStoryFlag ||
    SceneConditionSourceKind.storyStepCompletion ||
    SceneConditionSourceKind.consumedEvent =>
      true,
    SceneConditionSourceKind.storyStepActive ||
    SceneConditionSourceKind.inventoryItem ||
    SceneConditionSourceKind.partyState ||
    SceneConditionSourceKind.trainerDefeated ||
    SceneConditionSourceKind.dialogueOutcome ||
    SceneConditionSourceKind.battleOutcome ||
    SceneConditionSourceKind.scriptVariable ||
    SceneConditionSourceKind.worldState =>
      false,
  };
}

bool _isConditionOperatorSupportedV0(SceneConditionSource source) {
  return switch (source.sourceKind) {
    SceneConditionSourceKind.factLikeStoryFlag ||
    SceneConditionSourceKind.consumedEvent =>
      source.operator == SceneConditionOperator.isTrue ||
          source.operator == SceneConditionOperator.isFalse,
    SceneConditionSourceKind.storyStepCompletion =>
      source.operator == SceneConditionOperator.equals,
    SceneConditionSourceKind.storyStepActive ||
    SceneConditionSourceKind.inventoryItem ||
    SceneConditionSourceKind.partyState ||
    SceneConditionSourceKind.trainerDefeated ||
    SceneConditionSourceKind.dialogueOutcome ||
    SceneConditionSourceKind.battleOutcome ||
    SceneConditionSourceKind.scriptVariable ||
    SceneConditionSourceKind.worldState =>
      false,
  };
}

bool _isStoryStepCompletionValue(String? value) {
  return value == SceneConditionValues.completed ||
      value == SceneConditionValues.notCompleted;
}
