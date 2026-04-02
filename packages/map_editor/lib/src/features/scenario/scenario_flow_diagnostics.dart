import 'package:map_core/map_core.dart';

import 'scenario_authoring_ux.dart';

/// Gravité d’un diagnostic de flow affiché dans l’éditeur.
enum ScenarioFlowIssueSeverity {
  error,
  warning,
  info,
}

/// Un diagnostic ponctuel détecté sur le graphe scénario.
///
/// On garde ce modèle volontairement simple pour rester lisible côté UI
/// (panneau de diagnostic global + détail node sélectionné).
class ScenarioFlowIssue {
  const ScenarioFlowIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.nodeId,
    this.edgeId,
  });

  final String code;
  final ScenarioFlowIssueSeverity severity;
  final String message;
  final String? nodeId;
  final String? edgeId;
}

/// Synthèse quantitative du graphe.
class ScenarioFlowSummary {
  const ScenarioFlowSummary({
    required this.totalNodes,
    required this.totalEdges,
    required this.reachableNodes,
    required this.unreachableNodes,
    required this.incompleteNodes,
    required this.deadEndNodes,
    required this.isolatedNodes,
    required this.runtimeConnectedNodes,
    required this.runtimeCapableNodes,
    required this.authoringBridgeNodes,
    required this.plannedNodes,
    required this.graphRuntimeConnected,
  });

  final int totalNodes;
  final int totalEdges;
  final int reachableNodes;
  final int unreachableNodes;
  final int incompleteNodes;
  final int deadEndNodes;
  final int isolatedNodes;
  final int runtimeConnectedNodes;
  final int runtimeCapableNodes;
  final int authoringBridgeNodes;
  final int plannedNodes;
  final bool graphRuntimeConnected;
}

/// Rapport complet utilisé par l’UI.
class ScenarioFlowReport {
  const ScenarioFlowReport({
    required this.summary,
    required this.issues,
  });

  final ScenarioFlowSummary summary;
  final List<ScenarioFlowIssue> issues;

  List<ScenarioFlowIssue> issuesForNode(String nodeId) {
    return issues
        .where((issue) => issue.nodeId != null && issue.nodeId == nodeId)
        .toList(growable: false);
  }
}

/// Analyse pure du graphe scénario.
///
/// Cette fonction est volontairement indépendante de Flutter pour permettre
/// des tests unitaires rapides et robustes.
ScenarioFlowReport analyzeScenarioFlow(
  ScenarioAsset scenario, {
  bool graphRuntimeConnected = kScenarioGraphRuntimeExecutionConnected,
}) {
  final issues = <ScenarioFlowIssue>[];
  final nodeById = <String, ScenarioNode>{
    for (final node in scenario.nodes) node.id: node,
  };
  final incomingByNode = <String, int>{};
  final outgoingByNode = <String, int>{};
  final adjacency = <String, List<String>>{};

  // Contrôles d’edges et construction des index de connectivité.
  final edgeEndpoints = <String>{};
  for (final edge in scenario.edges) {
    final key = '${edge.fromNodeId}::${edge.toNodeId}';
    if (!edgeEndpoints.add(key)) {
      issues.add(
        ScenarioFlowIssue(
          code: 'duplicate_edge_endpoint',
          severity: ScenarioFlowIssueSeverity.warning,
          message:
              'Connexion dupliquée entre "${edge.fromNodeId}" et "${edge.toNodeId}".',
          edgeId: edge.id,
        ),
      );
    }
    final from = nodeById[edge.fromNodeId];
    final to = nodeById[edge.toNodeId];
    if (from == null || to == null) {
      issues.add(
        ScenarioFlowIssue(
          code: 'edge_missing_node',
          severity: ScenarioFlowIssueSeverity.error,
          message:
              'La connexion "${edge.id}" référence un node manquant (${edge.fromNodeId} -> ${edge.toNodeId}).',
          edgeId: edge.id,
        ),
      );
      continue;
    }
    outgoingByNode[from.id] = (outgoingByNode[from.id] ?? 0) + 1;
    incomingByNode[to.id] = (incomingByNode[to.id] ?? 0) + 1;
    adjacency.putIfAbsent(from.id, () => <String>[]).add(to.id);
  }

  // Atteignabilité à partir de l’entry node.
  final reachable = <String>{};
  if (nodeById.containsKey(scenario.entryNodeId)) {
    final queue = <String>[scenario.entryNodeId];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!reachable.add(current)) {
        continue;
      }
      final neighbors = adjacency[current] ?? const <String>[];
      queue.addAll(neighbors);
    }
  } else {
    issues.add(
      ScenarioFlowIssue(
        code: 'missing_entry_node',
        severity: ScenarioFlowIssueSeverity.error,
        message:
            'Entry node "${scenario.entryNodeId}" introuvable dans le graphe.',
      ),
    );
  }

  var runtimeConnectedNodes = 0;
  var runtimeCapableNodes = 0;
  var authoringBridgeNodes = 0;
  var plannedNodes = 0;

  final incompleteNodeIds = <String>{};
  final deadEndNodeIds = <String>{};
  final isolatedNodeIds = <String>{};

  var startNodes = 0;
  for (final node in scenario.nodes) {
    final incoming = incomingByNode[node.id] ?? 0;
    final outgoing = outgoingByNode[node.id] ?? 0;

    // Statut runtime/authoring de chaque node.
    final preset = scenarioActionPresetById(
      node.payload.actionKind,
      referenceMode: node.type == ScenarioNodeType.reference,
    );
    final executionState = scenarioNodeExecutionState(
      node,
      actionPreset: preset,
      graphRuntimeConnected: graphRuntimeConnected,
    );
    switch (executionState) {
      case ScenarioNodeExecutionState.runtimeConnected:
        runtimeConnectedNodes++;
      case ScenarioNodeExecutionState.runtimeCapableNotConnected:
        runtimeCapableNodes++;
      case ScenarioNodeExecutionState.authoringBridge:
        authoringBridgeNodes++;
      case ScenarioNodeExecutionState.planned:
        plannedNodes++;
    }

    // Nouveau diagnostic: exécution partielle réelle.
    //
    // Quand le bridge runtime est branché, on signale explicitement les nodes
    // atteignables mais non exécutables par le runtime MVP.
    if (graphRuntimeConnected &&
        reachable.contains(node.id) &&
        executionState != ScenarioNodeExecutionState.runtimeConnected) {
      issues.add(
        ScenarioFlowIssue(
          code: 'runtime_not_executable_node',
          severity: ScenarioFlowIssueSeverity.warning,
          message:
              'Le node "${node.id}" est atteignable mais non exécuté par le runtime MVP.',
          nodeId: node.id,
        ),
      );
    }

    if (graphRuntimeConnected &&
        reachable.contains(node.id) &&
        node.type == ScenarioNodeType.choice) {
      issues.add(
        ScenarioFlowIssue(
          code: 'runtime_choice_not_supported',
          severity: ScenarioFlowIssueSeverity.warning,
          message:
              'Le node Choice "${node.id}" n’est pas encore supporté par l’exécuteur runtime MVP.',
          nodeId: node.id,
        ),
      );
    }

    if (node.type == ScenarioNodeType.start) {
      startNodes++;
      if (incoming > 0) {
        issues.add(
          ScenarioFlowIssue(
            code: 'start_has_incoming',
            severity: ScenarioFlowIssueSeverity.warning,
            message:
                'Le node Start "${node.id}" reçoit des entrées. Un Start devrait être une source.',
            nodeId: node.id,
          ),
        );
      }
    }

    if (node.id != scenario.entryNodeId && incoming == 0) {
      isolatedNodeIds.add(node.id);
      issues.add(
        ScenarioFlowIssue(
          code: 'isolated_node',
          severity: ScenarioFlowIssueSeverity.warning,
          message:
              'Le node "${node.id}" n’a aucune entrée (non connecté depuis une source).',
          nodeId: node.id,
        ),
      );
    }

    if (!reachable.contains(node.id)) {
      issues.add(
        ScenarioFlowIssue(
          code: 'unreachable_node',
          severity: ScenarioFlowIssueSeverity.warning,
          message:
              'Le node "${node.id}" n’est pas atteignable depuis l’entry node.',
          nodeId: node.id,
        ),
      );
    }

    if (_nodeShouldHaveOutgoing(node.type) && outgoing == 0) {
      deadEndNodeIds.add(node.id);
      issues.add(
        ScenarioFlowIssue(
          code: 'dead_end_node',
          severity: ScenarioFlowIssueSeverity.warning,
          message:
              'Le node "${node.id}" n’a pas de sortie. La branche s’arrête ici.',
          nodeId: node.id,
        ),
      );
    }

    if (node.type == ScenarioNodeType.choice && outgoing < 2) {
      issues.add(
        ScenarioFlowIssue(
          code: 'choice_missing_branches',
          severity: ScenarioFlowIssueSeverity.error,
          message: 'Le node Choice "${node.id}" doit avoir au moins 2 sorties.',
          nodeId: node.id,
        ),
      );
    }
    if (node.type == ScenarioNodeType.condition && outgoing < 2) {
      issues.add(
        ScenarioFlowIssue(
          code: 'condition_missing_branches',
          severity: ScenarioFlowIssueSeverity.error,
          message:
              'Le node Condition "${node.id}" doit avoir au moins 2 sorties.',
          nodeId: node.id,
        ),
      );
    }
    if (node.type == ScenarioNodeType.end && outgoing > 0) {
      issues.add(
        ScenarioFlowIssue(
          code: 'end_has_outgoing',
          severity: ScenarioFlowIssueSeverity.error,
          message: 'Le node End "${node.id}" ne doit pas avoir de sorties.',
          nodeId: node.id,
        ),
      );
    }

    final missing = _missingNodeRequirements(node, preset);
    if (missing.isNotEmpty) {
      incompleteNodeIds.add(node.id);
      issues.add(
        ScenarioFlowIssue(
          code: 'node_incomplete',
          severity: ScenarioFlowIssueSeverity.error,
          message: 'Le node "${node.id}" est incomplet: ${missing.join(', ')}.',
          nodeId: node.id,
        ),
      );
    }
  }

  if (startNodes != 1) {
    issues.add(
      const ScenarioFlowIssue(
        code: 'start_nodes_count',
        severity: ScenarioFlowIssueSeverity.error,
        message: 'Le scénario doit contenir exactement 1 node Start.',
      ),
    );
  }

  final summary = ScenarioFlowSummary(
    totalNodes: scenario.nodes.length,
    totalEdges: scenario.edges.length,
    reachableNodes: reachable.length,
    unreachableNodes: scenario.nodes.length - reachable.length,
    incompleteNodes: incompleteNodeIds.length,
    deadEndNodes: deadEndNodeIds.length,
    isolatedNodes: isolatedNodeIds.length,
    runtimeConnectedNodes: runtimeConnectedNodes,
    runtimeCapableNodes: runtimeCapableNodes,
    authoringBridgeNodes: authoringBridgeNodes,
    plannedNodes: plannedNodes,
    graphRuntimeConnected: graphRuntimeConnected,
  );
  return ScenarioFlowReport(summary: summary, issues: issues);
}

bool _nodeShouldHaveOutgoing(ScenarioNodeType type) {
  switch (type) {
    case ScenarioNodeType.end:
      return false;
    case ScenarioNodeType.choice:
    case ScenarioNodeType.condition:
    case ScenarioNodeType.start:
    case ScenarioNodeType.dialogue:
    case ScenarioNodeType.action:
    case ScenarioNodeType.reference:
      return true;
  }
}

List<String> _missingNodeRequirements(
  ScenarioNode node,
  ScenarioActionPreset? preset,
) {
  final missing = <String>[];
  switch (node.type) {
    case ScenarioNodeType.start:
    case ScenarioNodeType.end:
    case ScenarioNodeType.choice:
      return missing;
    case ScenarioNodeType.dialogue:
      final hasDialogue = _hasText(node.binding.dialogueId);
      final hasScript = _hasText(node.binding.scriptId);
      final hasMessage = _hasText(node.payload.message);
      if (!hasDialogue && !hasScript && !hasMessage) {
        missing.add('dialogue/script/message');
      }
      return missing;
    case ScenarioNodeType.condition:
      if (node.payload.condition == null) {
        missing.add('condition');
      }
      return missing;
    case ScenarioNodeType.action:
    case ScenarioNodeType.reference:
      final actionKind = node.payload.actionKind?.trim() ?? '';
      if (actionKind.isEmpty) {
        missing.add('action kind');
        return missing;
      }
      if (preset == null) {
        // On laisse possible un actionKind custom, mais on signale qu’aucun
        // preset connu ne peut valider les champs attendus.
        missing.add('preset reconnu (ou config custom complète)');
        return missing;
      }
      for (final field in preset.fields) {
        switch (field) {
          case ScenarioActionField.message:
            if (!_hasText(node.payload.message)) missing.add('message');
          case ScenarioActionField.script:
            if (!_hasText(node.binding.scriptId)) missing.add('script');
          case ScenarioActionField.dialogue:
            if (!_hasText(node.binding.dialogueId)) missing.add('dialogue');
          case ScenarioActionField.map:
            if (!_hasText(node.binding.mapId)) missing.add('map');
          case ScenarioActionField.event:
            if (!_hasText(node.binding.eventId)) missing.add('event');
          case ScenarioActionField.entity:
            if (!_hasText(node.binding.entityId)) missing.add('entity');
          case ScenarioActionField.warp:
            if (!_hasText(node.binding.warpId)) missing.add('warp');
          case ScenarioActionField.trigger:
            if (!_hasText(node.binding.triggerId)) missing.add('trigger');
          case ScenarioActionField.trainer:
            if (!_hasText(node.binding.trainerId)) missing.add('trainer');
          case ScenarioActionField.flagName:
            if (!_hasText(node.binding.flagName)) missing.add('flag name');
          case ScenarioActionField.variableName:
            if (!_hasText(node.binding.variableName)) {
              missing.add('variable name');
            }
          case ScenarioActionField.variableValue:
            final value = node.payload.params[ScriptConditionParams.value];
            if (!_hasText(value)) missing.add('variable value');
        }
      }
      return missing;
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
