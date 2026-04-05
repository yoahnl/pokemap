import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import 'dialogue_disk_path_support.dart';
import 'project_use_case_support.dart';

class DeleteDialogueLibraryFolderUseCase {
  DeleteDialogueLibraryFolderUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String folderId,
  }) async {
    final id = folderId.trim();
    if (id.isEmpty) {
      throw const EditorValidationException('Folder id cannot be empty');
    }
    final exists = project.dialogueFolders.any((f) => f.id == id);
    if (!exists) {
      throw EditorNotFoundException('Dialogue folder not found: $id');
    }
    final hasChild =
        project.dialogueFolders.any((f) => f.parentFolderId == id);
    if (hasChild) {
      throw const EditorConflictException(
        'Cannot delete folder: it still contains subfolders. Remove or move them first.',
      );
    }
    final hasScript = project.dialogues.any((d) => d.folderId?.trim() == id);
    if (hasScript) {
      throw const EditorConflictException(
        'Cannot delete folder: it still contains scripts. Move them to another folder or to the library root first.',
      );
    }

    final segments = computeDialogueFolderDiskSegments(project);
    final dirRel = dialogueFolderDirectoryRelativePath(project, segments, id);

    final updatedFolders =
        project.dialogueFolders.where((f) => f.id != id).toList();
    final updated = project.copyWith(dialogueFolders: updatedFolders);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    await deleteEmptyProjectRelativeDirectory(workspace, dirRel);
    return updated;
  }
}

class CreateDialogueLibraryFolderUseCase {
  CreateDialogueLibraryFolderUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    String? parentFolderId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const EditorValidationException('Folder name cannot be empty');
    }
    final parent = parentFolderId?.trim();
    if (parent != null && parent.isNotEmpty) {
      final parentOk = project.dialogueFolders.any((f) => f.id == parent);
      if (!parentOk) {
        throw EditorNotFoundException('Parent folder not found: $parent');
      }
    }

    final id = generateUniqueDialogueFolderId(project, trimmed);
    final sortOrder =
        nextDialogueLibraryFolderSortOrder(project, parent);
    final folder = ProjectDialogueFolder(
      id: id,
      name: trimmed,
      parentFolderId: parent == null || parent.isEmpty ? null : parent,
      sortOrder: sortOrder,
    );
    final updated = project.copyWith(
      dialogueFolders: [...project.dialogueFolders, folder],
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);

    final segments = computeDialogueFolderDiskSegments(updated);
    await ensureDialogueFolderDirectoryExists(
      workspace,
      updated,
      segments,
      id,
    );
    return updated;
  }
}

class RenameDialogueLibraryFolderUseCase {
  RenameDialogueLibraryFolderUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String folderId,
    required String name,
  }) async {
    final id = folderId.trim();
    final trimmed = name.trim();
    if (id.isEmpty) {
      throw const EditorValidationException('Folder id cannot be empty');
    }
    if (trimmed.isEmpty) {
      throw const EditorValidationException('Folder name cannot be empty');
    }

    final segmentsBefore = computeDialogueFolderDiskSegments(project);
    final oldDirRel =
        dialogueFolderDirectoryRelativePath(project, segmentsBefore, id);

    var found = false;
    final nextFolders = project.dialogueFolders.map((f) {
      if (f.id != id) return f;
      found = true;
      return f.copyWith(name: trimmed);
    }).toList(growable: false);
    if (!found) {
      throw EditorNotFoundException('Dialogue folder not found: $id');
    }
    var updated = project.copyWith(dialogueFolders: nextFolders);
    final segmentsAfter = computeDialogueFolderDiskSegments(updated);
    final newDirRel =
        dialogueFolderDirectoryRelativePath(updated, segmentsAfter, id);

    if (oldDirRel != newDirRel) {
      final oldAbs = workspace.resolveProjectRelativePath(oldDirRel);
      if (await Directory(oldAbs).exists()) {
        await moveProjectRelativeDirectory(workspace, oldDirRel, newDirRel);
        final nextDialogues = updated.dialogues.map((d) {
          final nextPath =
              rewritePathPrefix(d.relativePath, oldDirRel, newDirRel);
          return nextPath != null ? d.copyWith(relativePath: nextPath) : d;
        }).toList();
        updated = updated.copyWith(dialogues: nextDialogues);
      }
    }

    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class MoveDialogueLibraryFolderUseCase {
  MoveDialogueLibraryFolderUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String folderId,
    String? newParentFolderId,
  }) async {
    final id = folderId.trim();
    if (id.isEmpty) {
      throw const EditorValidationException('Folder id cannot be empty');
    }
    final newParent = newParentFolderId?.trim();
    if (newParent != null && newParent.isNotEmpty) {
      if (newParent == id) {
        throw const EditorInvalidOperationException(
          'A folder cannot be moved into itself',
        );
      }
      final parentExists =
          project.dialogueFolders.any((f) => f.id == newParent);
      if (!parentExists) {
        throw EditorNotFoundException('Parent folder not found: $newParent');
      }
      final blocked = dialogueFolderSubtreeIds(project, id);
      if (blocked.contains(newParent)) {
        throw const EditorInvalidOperationException(
          'Cannot move a folder into one of its descendants',
        );
      }
    }

    final segmentsBefore = computeDialogueFolderDiskSegments(project);
    final oldDirRel =
        dialogueFolderDirectoryRelativePath(project, segmentsBefore, id);

    final others =
        project.dialogueFolders.where((x) => x.id != id).toList();
    final sortOrder = nextDialogueLibraryFolderSortOrder(
      project.copyWith(dialogueFolders: others),
      newParent == null || newParent.isEmpty ? null : newParent,
    );

    var found = false;
    final nextFolders = project.dialogueFolders.map((f) {
      if (f.id != id) return f;
      found = true;
      return f.copyWith(
        parentFolderId:
            newParent == null || newParent.isEmpty ? null : newParent,
        sortOrder: sortOrder,
      );
    }).toList(growable: false);
    if (!found) {
      throw EditorNotFoundException('Dialogue folder not found: $id');
    }
    var updated = project.copyWith(dialogueFolders: nextFolders);
    final segmentsAfter = computeDialogueFolderDiskSegments(updated);
    final newDirRel =
        dialogueFolderDirectoryRelativePath(updated, segmentsAfter, id);

    if (oldDirRel != newDirRel) {
      final oldAbs = workspace.resolveProjectRelativePath(oldDirRel);
      if (await Directory(oldAbs).exists()) {
        await moveProjectRelativeDirectory(workspace, oldDirRel, newDirRel);
        final nextDialogues = updated.dialogues.map((d) {
          final nextPath =
              rewritePathPrefix(d.relativePath, oldDirRel, newDirRel);
          return nextPath != null ? d.copyWith(relativePath: nextPath) : d;
        }).toList();
        updated = updated.copyWith(dialogues: nextDialogues);
      }
    }

    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class AssignDialogueToLibraryFolderUseCase {
  AssignDialogueToLibraryFolderUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String dialogueId,
    required String folderId,
  }) async {
    final did = dialogueId.trim();
    final fid = folderId.trim();
    if (did.isEmpty || fid.isEmpty) {
      throw const EditorValidationException('Invalid dialogue or folder id');
    }
    final folderOk = project.dialogueFolders.any((f) => f.id == fid);
    if (!folderOk) {
      throw EditorNotFoundException('Dialogue folder not found: $fid');
    }

    final index = project.dialogues.indexWhere((d) => d.id == did);
    if (index < 0) {
      throw EditorNotFoundException('Dialogue not found: $did');
    }
    final entry = project.dialogues[index];
    final segments = computeDialogueFolderDiskSegments(project);
    final ext = p.extension(entry.relativePath).toLowerCase();
    if (ext != '.yarn' && ext != '.txt') {
      throw const EditorValidationException(
        'Unsupported dialogue file extension (expected .yarn or .txt)',
      );
    }
    final newRel = expectedDialogueFileRelativePath(
      project,
      segments,
      fid,
      did,
      ext,
    );
    final normOld = entry.relativePath.replaceAll(r'\', '/');
    final currentFolder = entry.folderId?.trim() ?? '';

    if (currentFolder == fid && newRel == normOld) {
      return project;
    }

    if (newRel != normOld) {
      await moveProjectRelativeFile(workspace, entry.relativePath, newRel);
    }

    final sortOrder = currentFolder == fid
        ? entry.sortOrder
        : nextDialogueLibrarySortOrder(project, fid);

    final list = List<ProjectDialogueEntry>.from(project.dialogues);
    list[index] = entry.copyWith(
      folderId: fid,
      sortOrder: sortOrder,
      relativePath: newRel,
    );
    final updated = project.copyWith(dialogues: list);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class MoveDialogueToLibraryRootUseCase {
  MoveDialogueToLibraryRootUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String dialogueId,
  }) async {
    final did = dialogueId.trim();
    if (did.isEmpty) {
      throw const EditorValidationException('Dialogue id cannot be empty');
    }
    final sortOrder = nextDialogueLibrarySortOrder(project, null);

    final index = project.dialogues.indexWhere((d) => d.id == did);
    if (index < 0) {
      throw EditorNotFoundException('Dialogue not found: $did');
    }
    final entry = project.dialogues[index];
    final segments = computeDialogueFolderDiskSegments(project);
    final ext = p.extension(entry.relativePath).toLowerCase();
    if (ext != '.yarn' && ext != '.txt') {
      throw const EditorValidationException(
        'Unsupported dialogue file extension (expected .yarn or .txt)',
      );
    }
    final newRel =
        expectedDialogueFileRelativePath(project, segments, null, did, ext);
    final normOld = entry.relativePath.replaceAll(r'\', '/');
    if (newRel != normOld) {
      await moveProjectRelativeFile(workspace, entry.relativePath, newRel);
    }

    final list = List<ProjectDialogueEntry>.from(project.dialogues);
    list[index] = entry.copyWith(
      folderId: null,
      sortOrder: sortOrder,
      relativePath: newRel,
    );
    final updated = project.copyWith(dialogues: list);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
