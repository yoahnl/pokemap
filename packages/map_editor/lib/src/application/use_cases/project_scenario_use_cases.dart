import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

String generateUniqueProjectScenarioId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'scenario' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = project.scenarios.map((scenario) => scenario.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _generateUniqueScenarioNodeId(
  ScenarioAsset scenario,
  ScenarioNodeType type,
) {
  final base = switch (type) {
    ScenarioNodeType.start => 'start',
    ScenarioNodeType.dialogue => 'dialogue',
    ScenarioNodeType.action => 'action',
    ScenarioNodeType.condition => 'condition',
    ScenarioNodeType.choice => 'choice',
    ScenarioNodeType.reference => 'reference',
    ScenarioNodeType.end => 'end',
  };
  var candidate = base;
  var suffix = 1;
  final existing = scenario.nodes.map((node) => node.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _generateUniqueScenarioEdgeId(ScenarioAsset scenario, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'edge' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = scenario.edges.map((edge) => edge.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

ScenarioAsset _requireScenarioById(ProjectManifest project, String scenarioId) {
  for (final scenario in project.scenarios) {
    if (scenario.id == scenarioId) {
      return scenario;
    }
  }
  throw EditorNotFoundException('Scenario not found: $scenarioId');
}

int _requireScenarioIndex(ProjectManifest project, String scenarioId) {
  final index =
      project.scenarios.indexWhere((scenario) => scenario.id == scenarioId);
  if (index < 0) {
    throw EditorNotFoundException('Scenario not found: $scenarioId');
  }
  return index;
}

ProjectManifest _replaceScenario(
  ProjectManifest project,
  ScenarioAsset updatedScenario,
) {
  final index = _requireScenarioIndex(project, updatedScenario.id);
  final scenarios =
      List<ScenarioAsset>.from(project.scenarios, growable: false);
  scenarios[index] = updatedScenario;
  return project.copyWith(scenarios: scenarios);
}

class CreateProjectScenarioUseCase {
  CreateProjectScenarioUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Scenario name cannot be empty');
    }
    final scenarioId = generateUniqueProjectScenarioId(project, trimmedName);
    const startNode = ScenarioNode(
      id: 'start',
      type: ScenarioNodeType.start,
      title: 'Start',
      position: ScenarioNodePosition(x: 240, y: 220),
    );
    const endNode = ScenarioNode(
      id: 'end',
      type: ScenarioNodeType.end,
      title: 'End',
      position: ScenarioNodePosition(x: 580, y: 220),
    );
    final scenario = ScenarioAsset(
      id: scenarioId,
      name: trimmedName,
      // On privilégie désormais un scénario global par défaut.
      // Les flows locaux (hooks monde) restent possibles via le champ scope
      // éditable dans l'inspecteur scénario.
      scope: ScenarioScope.globalStory,
      entryNodeId: startNode.id,
      nodes: const <ScenarioNode>[startNode, endNode],
      edges: const <ScenarioEdge>[
        ScenarioEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          toNodeId: 'end',
          label: 'next',
        ),
      ],
    );
    final updated = project.copyWith(
      scenarios: <ScenarioAsset>[...project.scenarios, scenario],
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateProjectScenarioMetadataUseCase {
  UpdateProjectScenarioMetadataUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required String name,
    required String description,
    required ScenarioScope scope,
    required List<String> declaredOutcomes,
    ScriptCondition? activationCondition,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const EditorValidationException('Scenario name cannot be empty');
    }
    final normalizedDescription = description.trim();

    // Nettoyage déterministe: trim + suppression des vides + dédoublonnage.
    final dedupOutcomes = <String>{};
    final normalizedOutcomes = <String>[];
    for (final raw in declaredOutcomes) {
      final value = raw.trim();
      if (value.isEmpty) {
        continue;
      }
      if (dedupOutcomes.add(value)) {
        normalizedOutcomes.add(value);
      }
    }

    final updated = _replaceScenario(
      project,
      scenario.copyWith(
        name: normalizedName,
        description: normalizedDescription,
        scope: scope,
        declaredOutcomes: normalizedOutcomes,
        activationCondition: activationCondition,
      ),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class RenameProjectScenarioUseCase {
  RenameProjectScenarioUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required String name,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Scenario name cannot be empty');
    }
    final updated = _replaceScenario(
      project,
      scenario.copyWith(name: trimmedName),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteProjectScenarioUseCase {
  DeleteProjectScenarioUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
  }) async {
    _requireScenarioById(project, scenarioId);
    final updated = project.copyWith(
      scenarios: project.scenarios
          .where((scenario) => scenario.id != scenarioId)
          .toList(growable: false),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class AddScenarioNodeUseCase {
  AddScenarioNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required ScenarioNodeType type,
    String? title,
    ScenarioNodePosition? position,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final nodeId = _generateUniqueScenarioNodeId(scenario, type);
    final resolvedTitle = (title?.trim().isNotEmpty ?? false)
        ? title!.trim()
        : _defaultTitleForType(type);
    final node = ScenarioNode(
      id: nodeId,
      type: type,
      title: resolvedTitle,
      position: position ?? const ScenarioNodePosition(x: 360, y: 280),
    );
    final updatedScenario = scenario.copyWith(
      nodes: <ScenarioNode>[...scenario.nodes, node],
    );
    final updated = _replaceScenario(project, updatedScenario);
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateScenarioNodeUseCase {
  UpdateScenarioNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required ScenarioNode node,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final nodes = List<ScenarioNode>.from(scenario.nodes, growable: false);
    final index = nodes.indexWhere((current) => current.id == node.id);
    if (index < 0) {
      throw EditorNotFoundException('Scenario node not found: ${node.id}');
    }
    nodes[index] = node;
    final updatedScenario = scenario.copyWith(nodes: nodes);
    final updated = _replaceScenario(project, updatedScenario);
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class MoveScenarioNodeUseCase {
  MoveScenarioNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required String nodeId,
    required ScenarioNodePosition position,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final nodes = List<ScenarioNode>.from(scenario.nodes, growable: false);
    final index = nodes.indexWhere((node) => node.id == nodeId);
    if (index < 0) {
      throw EditorNotFoundException('Scenario node not found: $nodeId');
    }
    nodes[index] = nodes[index].copyWith(position: position);
    final updated = _replaceScenario(
      project,
      scenario.copyWith(nodes: nodes),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteScenarioNodeUseCase {
  DeleteScenarioNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required String nodeId,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final filteredNodes = scenario.nodes
        .where((node) => node.id != nodeId)
        .toList(growable: false);
    if (filteredNodes.isEmpty) {
      throw const EditorValidationException(
          'Scenario must keep at least one node');
    }
    final filteredEdges = scenario.edges
        .where((edge) => edge.fromNodeId != nodeId && edge.toNodeId != nodeId)
        .toList(growable: false);
    final fallbackEntryNode = filteredNodes.any(
      (node) => node.id == scenario.entryNodeId,
    )
        ? scenario.entryNodeId
        : filteredNodes.first.id;
    final updated = _replaceScenario(
      project,
      scenario.copyWith(
        entryNodeId: fallbackEntryNode,
        nodes: filteredNodes,
        edges: filteredEdges,
      ),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class SetScenarioEntryNodeUseCase {
  SetScenarioEntryNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required String nodeId,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final normalizedNodeId = nodeId.trim();
    if (normalizedNodeId.isEmpty) {
      throw const EditorValidationException('Entry node cannot be empty');
    }
    if (!scenario.nodes.any((node) => node.id == normalizedNodeId)) {
      throw EditorNotFoundException(
        'Scenario node not found: $normalizedNodeId',
      );
    }
    final updated = _replaceScenario(
      project,
      scenario.copyWith(entryNodeId: normalizedNodeId),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class AddScenarioEdgeUseCase {
  AddScenarioEdgeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required String fromNodeId,
    required String toNodeId,
    String? label,
    ScenarioEdgeKind kind = ScenarioEdgeKind.next,
    int order = 0,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final normalizedFrom = fromNodeId.trim();
    final normalizedTo = toNodeId.trim();
    if (normalizedFrom.isEmpty || normalizedTo.isEmpty) {
      throw const EditorValidationException(
          'Scenario edge nodes cannot be empty');
    }
    if (normalizedFrom == normalizedTo) {
      throw const EditorValidationException(
          'Scenario edge cannot self-connect');
    }
    if (!scenario.nodes.any((node) => node.id == normalizedFrom)) {
      throw EditorNotFoundException('Scenario node not found: $normalizedFrom');
    }
    if (!scenario.nodes.any((node) => node.id == normalizedTo)) {
      throw EditorNotFoundException('Scenario node not found: $normalizedTo');
    }
    final duplicateExists = scenario.edges.any(
      (edge) =>
          edge.fromNodeId == normalizedFrom && edge.toNodeId == normalizedTo,
    );
    if (duplicateExists) {
      throw const EditorValidationException(
        'Scenario edge already exists between these nodes',
      );
    }
    final edgeId = _generateUniqueScenarioEdgeId(
      scenario,
      '${normalizedFrom}_to_$normalizedTo',
    );
    final edge = ScenarioEdge(
      id: edgeId,
      fromNodeId: normalizedFrom,
      toNodeId: normalizedTo,
      label: label?.trim() ?? '',
      kind: kind,
      order: order,
    );
    final updated = _replaceScenario(
      project,
      scenario.copyWith(edges: <ScenarioEdge>[...scenario.edges, edge]),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateScenarioEdgeUseCase {
  UpdateScenarioEdgeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required String edgeId,
    String? label,
    ScenarioEdgeKind? kind,
    int? order,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    final edges = List<ScenarioEdge>.from(scenario.edges, growable: false);
    final index = edges.indexWhere((edge) => edge.id == edgeId);
    if (index < 0) {
      throw EditorNotFoundException('Scenario edge not found: $edgeId');
    }
    final current = edges[index];
    edges[index] = current.copyWith(
      label: label ?? current.label,
      kind: kind ?? current.kind,
      order: order ?? current.order,
    );
    final updated = _replaceScenario(
      project,
      scenario.copyWith(edges: edges),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteScenarioEdgeUseCase {
  DeleteScenarioEdgeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scenarioId,
    required String edgeId,
  }) async {
    final scenario = _requireScenarioById(project, scenarioId);
    if (!scenario.edges.any((edge) => edge.id == edgeId)) {
      throw EditorNotFoundException('Scenario edge not found: $edgeId');
    }
    final updated = _replaceScenario(
      project,
      scenario.copyWith(
        edges: scenario.edges
            .where((edge) => edge.id != edgeId)
            .toList(growable: false),
      ),
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

String _defaultTitleForType(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start => 'Start',
    ScenarioNodeType.dialogue => 'Dialogue',
    ScenarioNodeType.action => 'Action',
    ScenarioNodeType.condition => 'Condition',
    ScenarioNodeType.choice => 'Choice',
    ScenarioNodeType.reference => 'Reference',
    ScenarioNodeType.end => 'End',
  };
}
