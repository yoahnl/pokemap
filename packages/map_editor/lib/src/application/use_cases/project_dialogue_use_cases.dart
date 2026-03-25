import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

String generateUniqueDialogueId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'dialogue' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = project.dialogues.map((d) => d.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

Future<Set<String>> collectReferencedDialogueIdsFromSavedMaps(
  ProjectWorkspace ws,
  ProjectManifest project,
  MapRepository mapRepo,
) async {
  final all = <String>{};
  for (final mapEntry in project.maps) {
    final path = ws.resolveMapPath(mapEntry.relativePath);
    try {
      final map = await mapRepo.loadMap(path);
      all.addAll(collectDialogueIdsReferencedOnMap(map));
    } catch (_) {
      // Carte illisible : on n’ajoute pas de garde-fou pour cette carte.
    }
  }
  return all;
}

String minimalYarnStub(String titleLine) {
  final t = titleLine.trim().isEmpty ? 'Start' : titleLine.trim();
  return 'title: $t\n---\n(Begin editing your dialogue here.)\n===\n';
}

class CreateProjectDialogueUseCase {
  CreateProjectDialogueUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace ws,
    ProjectManifest project, {
    required String name,
    String? description,
    String? defaultStartNode,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const EditorValidationException('Dialogue name cannot be empty');
    }
    if (!isValidDialogueStartNode(defaultStartNode)) {
      throw const EditorValidationException('Invalid default start node');
    }
    final id = generateUniqueDialogueId(project, trimmed);
    final relativePath = p.posix.join(kProjectDialoguesRelativeDir, '$id.yarn');
    final abs = ws.resolveProjectRelativePath(relativePath);
    await ws.ensureDirectoryExists(abs);
    final file = File(abs);
    if (await file.exists()) {
      throw EditorValidationException(
        'Dialogue file already exists: $relativePath',
      );
    }
    await file.writeAsString(minimalYarnStub(trimmed));
    final sortOrder = project.dialogues.fold<int>(
      0,
      (m, d) => d.sortOrder > m ? d.sortOrder : m,
    );
    final dns = defaultStartNode?.trim();
    final entry = ProjectDialogueEntry(
      id: id,
      name: trimmed,
      relativePath: relativePath,
      description: description?.trim() ?? '',
      defaultStartNode:
          dns == null || dns.isEmpty ? null : dns,
      sortOrder: sortOrder + 1,
    );
    final updated = project.copyWith(dialogues: [...project.dialogues, entry]);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, ws.projectManifestPath);
    return updated;
  }
}

class ImportProjectDialogueUseCase {
  ImportProjectDialogueUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace ws,
    ProjectManifest project, {
    required String absoluteSourcePath,
    required String displayName,
  }) async {
    final src = File(absoluteSourcePath);
    if (!await src.exists()) {
      throw const EditorValidationException('Source file not found');
    }
    final ext = p.extension(absoluteSourcePath).toLowerCase();
    if (ext != '.yarn' && ext != '.txt') {
      throw const EditorValidationException(
        'Unsupported file type (use .yarn or .txt)',
      );
    }
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const EditorValidationException('Dialogue name cannot be empty');
    }
    final id = generateUniqueDialogueId(project, trimmed);
    final fileName = '$id$ext';
    final relativePath = p.posix.join(kProjectDialoguesRelativeDir, fileName);
    final destAbs = ws.resolveProjectRelativePath(relativePath);
    await ws.ensureDirectoryExists(destAbs);
    final dest = File(destAbs);
    if (await dest.exists()) {
      throw EditorValidationException('Target already exists: $relativePath');
    }
    await src.copy(destAbs);
    final sortOrder = project.dialogues.fold<int>(
      0,
      (m, d) => d.sortOrder > m ? d.sortOrder : m,
    );
    final entry = ProjectDialogueEntry(
      id: id,
      name: trimmed,
      relativePath: relativePath,
      sortOrder: sortOrder + 1,
    );
    final updated = project.copyWith(dialogues: [...project.dialogues, entry]);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, ws.projectManifestPath);
    return updated;
  }
}

class UpdateProjectDialogueUseCase {
  UpdateProjectDialogueUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace ws,
    ProjectManifest project, {
    required String dialogueId,
    String? name,
    String? description,
    List<String>? tags,
    String? defaultStartNode,
    bool clearDefaultStartNode = false,
  }) async {
    final index = project.dialogues.indexWhere((d) => d.id == dialogueId);
    if (index < 0) {
      throw EditorNotFoundException('Dialogue not found: $dialogueId');
    }
    final cur = project.dialogues[index];
    final newName = name != null ? name.trim() : cur.name;
    if (newName.isEmpty) {
      throw const EditorValidationException('Dialogue name cannot be empty');
    }
    String? dns;
    if (clearDefaultStartNode) {
      dns = null;
    } else if (defaultStartNode != null) {
      final t = defaultStartNode.trim();
      dns = t.isEmpty ? null : t;
    } else {
      dns = cur.defaultStartNode;
    }
    if (!isValidDialogueStartNode(dns)) {
      throw const EditorValidationException('Invalid default start node');
    }
    final next = cur.copyWith(
      name: newName,
      description: description != null ? description.trim() : cur.description,
      tags: tags ?? cur.tags,
      defaultStartNode: dns,
    );
    final list = List<ProjectDialogueEntry>.from(project.dialogues);
    list[index] = next;
    final updated = project.copyWith(dialogues: list);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, ws.projectManifestPath);
    return updated;
  }
}

class DeleteProjectDialogueUseCase {
  DeleteProjectDialogueUseCase(this._projectRepo, this._mapRepo);

  final ProjectRepository _projectRepo;
  final MapRepository _mapRepo;

  Future<ProjectManifest> execute(
    ProjectWorkspace ws,
    ProjectManifest project, {
    required String dialogueId,
    MapData? alsoScanUnsavedMap,
  }) async {
    final index = project.dialogues.indexWhere((d) => d.id == dialogueId);
    if (index < 0) {
      throw EditorNotFoundException('Dialogue not found: $dialogueId');
    }
    final entry = project.dialogues[index];
    final referenced = await collectReferencedDialogueIdsFromSavedMaps(
      ws,
      project,
      _mapRepo,
    );
    if (alsoScanUnsavedMap != null) {
      referenced.addAll(collectDialogueIdsReferencedOnMap(alsoScanUnsavedMap));
    }
    if (referenced.contains(dialogueId)) {
      throw const EditorValidationException(
        'This dialogue is still assigned to an NPC or sign. Remove those '
        'assignments on every map (including unsaved changes on the active map) '
        'before deleting.',
      );
    }
    await ws.deleteRelativeFile(entry.relativePath);
    final updated = project.copyWith(
      dialogues: project.dialogues.where((d) => d.id != dialogueId).toList(),
    );
    ProjectValidator.validate(updated);
    await _projectRepo.saveProject(updated, ws.projectManifestPath);
    return updated;
  }
}
