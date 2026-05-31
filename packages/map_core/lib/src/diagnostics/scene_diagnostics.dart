import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/map_data.dart';
import '../read_models/linked_asset_public_contracts.dart';

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
  conditionFactRefUnknown,
  conditionWorldRuleRefUnknown,
  consequenceUnknownFact,
  consequenceUnknownEvent,
  consequenceMissingTarget,
  consequenceWouldApplyWorldRuleDirectly,
  actionPayloadLegacyUnsupported,
  consequenceRuntimeUnsupported,
  edgeFromPortUnsupported,
  edgeKindUnsupportedForPort,
  duplicateOutgoingPortEdge,
  requiredOutputPortMissing,
  unreachableNode,
  unreachableEndNode,
  cycleUnsupported,
  actionNodeUnsupported,
  branchByOutcomeUnsupported,
  dialogueRefUnknown,
  battleTrainerRefUnknown,
  cinematicRefUnknown,
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

  _diagnosePorts(scene, nodeById, diagnostics);
  _diagnoseReachability(scene, nodeById, diagnostics);
  _diagnoseCycles(scene, nodeById, diagnostics);

  for (final node in scene.graph.nodes) {
    if (node.kind == SceneNodeKind.condition) {
      _diagnoseConditionNode(scene, node, diagnostics);
    } else if (node.kind == SceneNodeKind.action) {
      _diagnoseActionNode(scene, node, diagnostics);
    } else if (node.kind == SceneNodeKind.branchByOutcome) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.branchByOutcomeUnsupported,
          severity: SceneDiagnosticSeverity.warning,
          message:
              'BranchByOutcome attend un mapping explicite outcome -> sortie.',
          sceneId: scene.id,
          nodeId: node.id,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel:
              'Garder le nœud en draft ou attendre BranchByOutcome V0.',
        ),
      );
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

SceneDiagnosticsReport diagnoseSceneAgainstProject(
  SceneAsset scene,
  ProjectManifest project, {
  Map<String, MapData> mapsById = const {},
}) {
  final diagnostics = diagnoseScene(scene).diagnostics.toList(growable: true);
  final contracts = buildLinkedAssetContractsSnapshot(project);
  final dialogueIds =
      contracts.dialogues.map((dialogue) => dialogue.id).toSet();
  final trainerIds =
      contracts.battles.map((battle) => battle.trainerId).toSet();
  final cinematicIds =
      contracts.cinematics.map((cinematic) => cinematic.id).toSet();
  final factIds = project.facts.map((fact) => fact.id).toSet();
  final worldRuleIds = project.worldRules.map((rule) => rule.id).toSet();
  final projectMapIds = project.maps.map((map) => map.id).toSet();

  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    switch (payload) {
      case SceneYarnDialoguePayload():
        if (!dialogueIds.contains(payload.dialogueId)) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.dialogueRefUnknown,
              severity: SceneDiagnosticSeverity.error,
              message: 'Le dialogue Yarn référencé est absent du projet.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel: 'Choisir un dialogue existant.',
            ),
          );
        }
      case SceneBattlePayload():
        if (payload.battleKind == 'trainer' &&
            (payload.trainerId == null ||
                !trainerIds.contains(payload.trainerId))) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.battleTrainerRefUnknown,
              severity: SceneDiagnosticSeverity.error,
              message: 'Le combat trainer référence un dresseur absent.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel: 'Choisir un trainer existant.',
            ),
          );
        }
      case SceneCinematicPayload():
        if (!cinematicIds.contains(payload.cinematicId)) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.cinematicRefUnknown,
              severity: SceneDiagnosticSeverity.warning,
              message:
                  'La cinématique référencée n’existe pas comme bridge public.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel:
                  'Choisir un bridge cinematic existant ou attendre CinematicAsset.',
            ),
          );
        }
      case SceneConditionPayload():
        final source = payload.conditionSource;
        if (source == null) {
          continue;
        }
        if (source.sourceKind == SceneConditionSourceKind.fact &&
            !factIds.contains(source.sourceId)) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.conditionFactRefUnknown,
              severity: SceneDiagnosticSeverity.error,
              message: 'La condition référence un Fact absent du projet.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel: 'Choisir un Fact existant dans la registry.',
            ),
          );
        }
        if (source.sourceKind == SceneConditionSourceKind.worldState &&
            !worldRuleIds.contains(source.sourceId)) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.conditionWorldRuleRefUnknown,
              severity: SceneDiagnosticSeverity.warning,
              message:
                  'La condition référence une World Rule ou un état monde absent.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel:
                  'Choisir une World Rule existante quand cette source sera active.',
            ),
          );
        }
      case SceneActionPayload():
        _diagnoseActionConsequenceAgainstProject(
          scene,
          node,
          payload,
          factIds: factIds,
          projectMapIds: projectMapIds,
          mapsById: mapsById,
          diagnostics: diagnostics,
        );
      case SceneStartPayload():
      case SceneEndPayload():
      case SceneBranchByOutcomePayload():
      case SceneMergePayload():
        break;
    }
  }

  return SceneDiagnosticsReport(diagnostics: diagnostics);
}

void _diagnoseActionNode(
  SceneAsset scene,
  SceneNode node,
  List<SceneDiagnostic> diagnostics,
) {
  final payload = node.payload;
  if (payload is! SceneActionPayload) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.actionPayloadLegacyUnsupported,
        severity: SceneDiagnosticSeverity.error,
        message: 'ActionNode doit avoir un payload action.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Reconfigurer le nœud Action.',
      ),
    );
    return;
  }

  final consequence = payload.consequence;
  if (consequence == null) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.actionPayloadLegacyUnsupported,
        severity: SceneDiagnosticSeverity.warning,
        message:
            'ActionNode utilise encore un actionKind libre legacy non exécutable.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Configurer une conséquence typée V0.',
      ),
    );
    return;
  }

  _diagnoseConsequenceShape(scene, node, consequence, diagnostics);
}

void _diagnoseConsequenceShape(
  SceneAsset scene,
  SceneNode node,
  SceneConsequence consequence,
  List<SceneDiagnostic> diagnostics,
) {
  switch (consequence) {
    case SceneSetFactConsequence():
      if (consequence.factId.trim().isEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceMissingTarget,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence setFact doit cibler un Fact.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un Fact dans la registry.',
          ),
        );
      }
    case SceneMarkEventConsumedConsequence():
      if (consequence.mapId.trim().isEmpty ||
          consequence.eventId.trim().isEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceMissingTarget,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence markEventConsumed doit cibler une map et un event.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir une map et un event existants.',
          ),
        );
      }
  }
}

void _diagnoseActionConsequenceAgainstProject(
  SceneAsset scene,
  SceneNode node,
  SceneActionPayload payload, {
  required Set<String> factIds,
  required Set<String> projectMapIds,
  required Map<String, MapData> mapsById,
  required List<SceneDiagnostic> diagnostics,
}) {
  final consequence = payload.consequence;
  if (consequence == null) {
    return;
  }

  switch (consequence) {
    case SceneSetFactConsequence():
      if (consequence.factId.trim().isEmpty) {
        return;
      }
      if (!factIds.contains(consequence.factId)) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownFact,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence setFact référence un Fact absent.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un Fact existant dans la registry.',
          ),
        );
      }
    case SceneMarkEventConsumedConsequence():
      if (consequence.mapId.trim().isEmpty ||
          consequence.eventId.trim().isEmpty) {
        return;
      }
      final mapData = mapsById[consequence.mapId];
      if (!projectMapIds.contains(consequence.mapId) && mapData == null) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownEvent,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence markEventConsumed cible une map absente.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir une map existante.',
          ),
        );
        return;
      }
      if (mapData == null) {
        return;
      }
      final hasEvent =
          mapData.events.any((event) => event.id == consequence.eventId);
      if (!hasEvent) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownEvent,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence markEventConsumed cible un event absent.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un event existant sur la map.',
          ),
        );
      }
  }
}

void _diagnosePorts(
  SceneAsset scene,
  Map<String, SceneNode> nodeById,
  List<SceneDiagnostic> diagnostics,
) {
  final edgeBySourcePort = <String, SceneEdge>{};

  for (final edge in scene.graph.edges) {
    final fromNode = nodeById[edge.fromNodeId];
    if (fromNode == null) {
      continue;
    }
    final portSpecs = _v0OutputPortSpecsForNode(fromNode);
    if (portSpecs == null) {
      continue;
    }
    final matchingPort = _findPortSpec(portSpecs, edge.fromPortId);
    if (matchingPort == null) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.edgeFromPortUnsupported,
          severity: SceneDiagnosticSeverity.error,
          message: 'Un lien part d’un port non supporté pour ce nœud.',
          sceneId: scene.id,
          nodeId: fromNode.id,
          edgeId: edge.id,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Choisir un port de sortie disponible.',
        ),
      );
      continue;
    }
    if (!matchingPort.edgeKinds.contains(edge.kind)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.edgeKindUnsupportedForPort,
          severity: SceneDiagnosticSeverity.error,
          message: 'Le type de lien ne correspond pas au port source.',
          sceneId: scene.id,
          nodeId: fromNode.id,
          edgeId: edge.id,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Recréer le lien depuis le port source attendu.',
        ),
      );
    }

    final sourcePortKey = '${fromNode.id}|${edge.fromPortId}';
    final previousEdge = edgeBySourcePort[sourcePortKey];
    if (previousEdge == null) {
      edgeBySourcePort[sourcePortKey] = edge;
    } else {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.duplicateOutgoingPortEdge,
          severity: SceneDiagnosticSeverity.error,
          message: 'Ce port de sortie possède déjà un lien.',
          sceneId: scene.id,
          nodeId: fromNode.id,
          edgeId: edge.id,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel:
              'Supprimer un des liens ou utiliser un autre port.',
        ),
      );
    }
  }

  for (final node in scene.graph.nodes) {
    final portSpecs = _v0OutputPortSpecsForNode(node);
    if (portSpecs == null) {
      continue;
    }
    for (final port in portSpecs.where((port) => port.required)) {
      final hasPortEdge = scene.graph.edges.any(
        (edge) => edge.fromNodeId == node.id && edge.fromPortId == port.id,
      );
      if (hasPortEdge) {
        continue;
      }
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.requiredOutputPortMissing,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Un port de sortie attendu n’est pas connecté.',
          sceneId: scene.id,
          nodeId: node.id,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Connecter le port ${port.id}.',
        ),
      );
    }
  }
}

void _diagnoseReachability(
  SceneAsset scene,
  Map<String, SceneNode> nodeById,
  List<SceneDiagnostic> diagnostics,
) {
  final startNode = nodeById[scene.graph.startNodeId];
  if (startNode == null) {
    return;
  }

  final outgoingByNode = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    outgoingByNode.putIfAbsent(edge.fromNodeId, () => []).add(edge);
  }

  final reachableNodeIds = <String>{};
  final queue = <String>[startNode.id];
  while (queue.isNotEmpty) {
    final nodeId = queue.removeAt(0);
    if (!reachableNodeIds.add(nodeId)) {
      continue;
    }
    for (final edge in outgoingByNode[nodeId] ?? const <SceneEdge>[]) {
      if (nodeById.containsKey(edge.toNodeId)) {
        queue.add(edge.toNodeId);
      }
    }
  }

  for (final node in scene.graph.nodes) {
    if (reachableNodeIds.contains(node.id)) {
      continue;
    }
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.unreachableNode,
        severity: SceneDiagnosticSeverity.warning,
        message: 'Ce nœud n’est pas atteignable depuis le départ.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Connecter ce nœud au graphe principal.',
      ),
    );
    if (node.kind == SceneNodeKind.end) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.unreachableEndNode,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Cette fin de scène n’est pas atteignable.',
          sceneId: scene.id,
          nodeId: node.id,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Créer un chemin vers cette fin ou la supprimer.',
        ),
      );
    }
  }

  final hasReachableEnd = scene.graph.nodes.any(
    (node) =>
        node.kind == SceneNodeKind.end && reachableNodeIds.contains(node.id),
  );
  if (!hasReachableEnd &&
      scene.graph.nodes.any((node) => node.kind == SceneNodeKind.end)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.unreachableEndNode,
        severity: SceneDiagnosticSeverity.error,
        message: 'Aucune fin de scène n’est atteignable depuis le départ.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Créer au moins un chemin vers une fin.',
      ),
    );
  }
}

void _diagnoseCycles(
  SceneAsset scene,
  Map<String, SceneNode> nodeById,
  List<SceneDiagnostic> diagnostics,
) {
  final startNode = nodeById[scene.graph.startNodeId];
  if (startNode == null) {
    return;
  }
  final outgoingByNode = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    outgoingByNode.putIfAbsent(edge.fromNodeId, () => []).add(edge);
  }
  final visiting = <String>{};
  final visited = <String>{};
  String? cycleNodeId;

  bool visit(String nodeId) {
    if (cycleNodeId != null) {
      return true;
    }
    if (visiting.contains(nodeId)) {
      cycleNodeId = nodeId;
      return true;
    }
    if (visited.contains(nodeId)) {
      return false;
    }
    visiting.add(nodeId);
    for (final edge in outgoingByNode[nodeId] ?? const <SceneEdge>[]) {
      if (!nodeById.containsKey(edge.toNodeId)) {
        continue;
      }
      if (visit(edge.toNodeId)) {
        return true;
      }
    }
    visiting.remove(nodeId);
    visited.add(nodeId);
    return false;
  }

  visit(startNode.id);
  if (cycleNodeId == null) {
    return;
  }
  diagnostics.add(
    SceneDiagnostic(
      code: SceneDiagnosticCode.cycleUnsupported,
      severity: SceneDiagnosticSeverity.warning,
      message: 'La scène contient un cycle non supporté en V0.',
      sceneId: scene.id,
      nodeId: cycleNodeId,
      target: SceneDiagnosticTarget.graph,
      suggestedFixLabel:
          'Supprimer la boucle ou attendre le support runtime des cycles.',
    ),
  );
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

final class _SceneOutputPortSpec {
  const _SceneOutputPortSpec({
    required this.id,
    required this.edgeKinds,
    this.required = false,
  });

  final String id;
  final Set<SceneEdgeKind> edgeKinds;
  final bool required;
}

List<_SceneOutputPortSpec>? _v0OutputPortSpecsForNode(SceneNode node) {
  return switch (node.kind) {
    SceneNodeKind.start => const [
        _SceneOutputPortSpec(
          id: 'completed',
          edgeKinds: {SceneEdgeKind.defaultFlow},
          required: true,
        ),
      ],
    SceneNodeKind.condition => const [
        _SceneOutputPortSpec(
          id: 'true',
          edgeKinds: {SceneEdgeKind.conditionTrue},
          required: true,
        ),
        _SceneOutputPortSpec(
          id: 'false',
          edgeKinds: {SceneEdgeKind.conditionFalse},
          required: true,
        ),
      ],
    SceneNodeKind.merge => const [
        _SceneOutputPortSpec(
          id: 'completed',
          edgeKinds: {SceneEdgeKind.defaultFlow},
          required: true,
        ),
      ],
    SceneNodeKind.yarnDialogue => const [
        _SceneOutputPortSpec(
          id: 'completed',
          edgeKinds: {SceneEdgeKind.defaultFlow},
          required: true,
        ),
      ],
    SceneNodeKind.battle => const [
        _SceneOutputPortSpec(
          id: 'victory',
          edgeKinds: {SceneEdgeKind.battleVictory},
          required: true,
        ),
        _SceneOutputPortSpec(
          id: 'defeat',
          edgeKinds: {SceneEdgeKind.battleDefeat},
          required: true,
        ),
      ],
    SceneNodeKind.action => const [
        _SceneOutputPortSpec(
          id: 'completed',
          edgeKinds: {
            SceneEdgeKind.defaultFlow,
            SceneEdgeKind.actionCompleted,
          },
          required: true,
        ),
      ],
    SceneNodeKind.end => const [],
    SceneNodeKind.cinematic || SceneNodeKind.branchByOutcome => null,
  };
}

_SceneOutputPortSpec? _findPortSpec(
  List<_SceneOutputPortSpec> specs,
  String portId,
) {
  for (final spec in specs) {
    if (spec.id == portId) {
      return spec;
    }
  }
  return null;
}

bool _isConditionSourceKindSupportedV0(SceneConditionSourceKind kind) {
  return switch (kind) {
    SceneConditionSourceKind.fact ||
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
    SceneConditionSourceKind.fact ||
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
