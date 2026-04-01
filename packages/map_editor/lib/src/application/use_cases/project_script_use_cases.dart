import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

String generateUniqueProjectScriptId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'script' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = project.scripts.map((script) => script.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _generateUniqueScriptNodeId(
  ProjectScriptEntry script,
  String seed,
) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'node' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = script.asset.nodes.map((node) => node.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

Set<String> collectScriptIdsReferencedOnMap(MapData map) {
  final ids = <String>{};
  for (final event in map.events) {
    for (final page in event.pages) {
      final script = page.script;
      if (script == null) continue;
      final id = script.scriptId.trim();
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }
  }
  return ids;
}

Future<Set<String>> collectReferencedScriptIdsFromSavedMaps(
  ProjectWorkspace workspace,
  ProjectManifest project,
  MapRepository mapRepository,
) async {
  final all = <String>{};
  for (final mapEntry in project.maps) {
    final path = workspace.resolveMapPath(mapEntry.relativePath);
    try {
      final map = await mapRepository.loadMap(path);
      all.addAll(collectScriptIdsReferencedOnMap(map));
    } catch (_) {}
  }
  return all;
}

ProjectScriptEntry _requireScriptById(
    ProjectManifest project, String scriptId) {
  for (final script in project.scripts) {
    if (script.id == scriptId) {
      return script;
    }
  }
  throw EditorNotFoundException('Script not found: $scriptId');
}

int _requireScriptIndex(ProjectManifest project, String scriptId) {
  final index = project.scripts.indexWhere((script) => script.id == scriptId);
  if (index < 0) {
    throw EditorNotFoundException('Script not found: $scriptId');
  }
  return index;
}

ScriptNode _requireScriptNodeById(ProjectScriptEntry script, String nodeId) {
  for (final node in script.asset.nodes) {
    if (node.id == nodeId) {
      return node;
    }
  }
  throw EditorNotFoundException('Node not found: $nodeId');
}

ProjectManifest _replaceScript(
  ProjectManifest project,
  ProjectScriptEntry updatedScript,
) {
  final index = _requireScriptIndex(project, updatedScript.id);
  final scripts =
      List<ProjectScriptEntry>.from(project.scripts, growable: false);
  scripts[index] = updatedScript;
  return project.copyWith(scripts: scripts);
}

class CreateProjectScriptUseCase {
  CreateProjectScriptUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Script name cannot be empty');
    }
    final scriptId = generateUniqueProjectScriptId(project, trimmedName);
    const startNode = ScriptNode(id: 'start', title: 'Start');
    final script = ProjectScriptEntry(
      id: scriptId,
      name: trimmedName,
      asset: ScriptAsset(
        id: scriptId,
        nodes: <ScriptNode>[startNode],
        defaultStartNode: startNode.id,
      ),
    );
    final updated = project.copyWith(
      scripts: <ProjectScriptEntry>[...project.scripts, script],
    );
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class RenameProjectScriptUseCase {
  RenameProjectScriptUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scriptId,
    required String name,
  }) async {
    final script = _requireScriptById(project, scriptId);
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Script name cannot be empty');
    }
    final updatedScript = script.copyWith(name: trimmedName);
    final updated = _replaceScript(project, updatedScript);
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteProjectScriptUseCase {
  DeleteProjectScriptUseCase(this._projectRepository, this._mapRepository);

  final ProjectRepository _projectRepository;
  final MapRepository _mapRepository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scriptId,
    MapData? alsoScanUnsavedMap,
  }) async {
    _requireScriptById(project, scriptId);
    final referencedIds = await collectReferencedScriptIdsFromSavedMaps(
      workspace,
      project,
      _mapRepository,
    );
    if (alsoScanUnsavedMap != null) {
      referencedIds.addAll(collectScriptIdsReferencedOnMap(alsoScanUnsavedMap));
    }
    if (referencedIds.contains(scriptId)) {
      throw const EditorValidationException(
        'This script is still referenced by map events. Remove those references on every map (including unsaved changes on the active map) before deleting.',
      );
    }
    final updated = project.copyWith(
      scripts:
          project.scripts.where((script) => script.id != scriptId).toList(),
    );
    ProjectValidator.validate(updated);
    await _projectRepository.saveProject(
        updated, workspace.projectManifestPath);
    return updated;
  }
}

class SetProjectScriptDefaultStartNodeUseCase {
  SetProjectScriptDefaultStartNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scriptId,
    required String nodeId,
  }) async {
    final script = _requireScriptById(project, scriptId);
    final normalizedNodeId = nodeId.trim();
    if (normalizedNodeId.isEmpty) {
      throw const EditorValidationException(
          'Default start node cannot be empty');
    }
    _requireScriptNodeById(script, normalizedNodeId);
    final updatedScript = script.copyWith(
      asset: script.asset.copyWith(defaultStartNode: normalizedNodeId),
    );
    final updated = _replaceScript(project, updatedScript);
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class AddProjectScriptNodeUseCase {
  AddProjectScriptNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scriptId,
    required String title,
  }) async {
    final script = _requireScriptById(project, scriptId);
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const EditorValidationException('Node title cannot be empty');
    }
    final nodeId = _generateUniqueScriptNodeId(script, trimmedTitle);
    final node = ScriptNode(id: nodeId, title: trimmedTitle);
    final updatedAsset = script.asset.copyWith(
      nodes: <ScriptNode>[...script.asset.nodes, node],
      defaultStartNode: script.asset.defaultStartNode.trim().isEmpty
          ? nodeId
          : script.asset.defaultStartNode,
    );
    final updated =
        _replaceScript(project, script.copyWith(asset: updatedAsset));
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class RenameProjectScriptNodeUseCase {
  RenameProjectScriptNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scriptId,
    required String nodeId,
    required String title,
  }) async {
    final script = _requireScriptById(project, scriptId);
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const EditorValidationException('Node title cannot be empty');
    }
    final nodes = List<ScriptNode>.from(script.asset.nodes, growable: false);
    final index = nodes.indexWhere((node) => node.id == nodeId);
    if (index < 0) {
      throw EditorNotFoundException('Node not found: $nodeId');
    }
    nodes[index] = nodes[index].copyWith(title: trimmedTitle);
    final updatedScript = script.copyWith(
      asset: script.asset.copyWith(nodes: nodes),
    );
    final updated = _replaceScript(project, updatedScript);
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteProjectScriptNodeUseCase {
  DeleteProjectScriptNodeUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String scriptId,
    required String nodeId,
  }) async {
    final script = _requireScriptById(project, scriptId);
    final normalizedNodeId = nodeId.trim();
    if (normalizedNodeId.isEmpty) {
      throw const EditorValidationException('Node id cannot be empty');
    }
    final nodes = List<ScriptNode>.from(script.asset.nodes, growable: false);
    final index = nodes.indexWhere((node) => node.id == normalizedNodeId);
    if (index < 0) {
      throw EditorNotFoundException('Node not found: $normalizedNodeId');
    }
    if (nodes.length <= 1) {
      throw const EditorValidationException(
          'Cannot delete the last script node');
    }
    if (script.asset.defaultStartNode == normalizedNodeId) {
      throw const EditorValidationException(
        'Cannot delete the default start node',
      );
    }
    for (final node in nodes) {
      if (node.nextNodeId == normalizedNodeId) {
        throw EditorValidationException(
          'Cannot delete node "$normalizedNodeId": referenced by nextNodeId of "${node.id}"',
        );
      }
      for (final command in node.commands) {
        if (command.type != ScriptCommandType.goto) continue;
        final targetNodeId = command.params['nodeId']?.trim();
        if (targetNodeId == normalizedNodeId) {
          throw EditorValidationException(
            'Cannot delete node "$normalizedNodeId": referenced by goto command in "${node.id}"',
          );
        }
      }
    }
    final nextNodes = List<ScriptNode>.from(nodes)..removeAt(index);
    final updatedScript = script.copyWith(
      asset: script.asset.copyWith(nodes: nextNodes),
    );
    final updated = _replaceScript(project, updatedScript);
    ProjectValidator.validate(updated);
    await _repository.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
