import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
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
    final updatedFolders =
        project.dialogueFolders.where((f) => f.id != id).toList();
    final updated = project.copyWith(dialogueFolders: updatedFolders);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
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
    var found = false;
    final nextFolders = project.dialogueFolders.map((f) {
      if (f.id != id) return f;
      found = true;
      return f.copyWith(name: trimmed);
    }).toList(growable: false);
    if (!found) {
      throw EditorNotFoundException('Dialogue folder not found: $id');
    }
    final updated = project.copyWith(dialogueFolders: nextFolders);
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
    final updated = project.copyWith(dialogueFolders: nextFolders);
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

    final sortOrder = nextDialogueLibrarySortOrder(project, fid);

    var found = false;
    final next = project.dialogues.map((d) {
      if (d.id != did) return d;
      found = true;
      return d.copyWith(folderId: fid, sortOrder: sortOrder);
    }).toList(growable: false);
    if (!found) {
      throw EditorNotFoundException('Dialogue not found: $did');
    }
    final updated = project.copyWith(dialogues: next);
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

    var found = false;
    final next = project.dialogues.map((d) {
      if (d.id != did) return d;
      found = true;
      return d.copyWith(folderId: null, sortOrder: sortOrder);
    }).toList(growable: false);
    if (!found) {
      throw EditorNotFoundException('Dialogue not found: $did');
    }
    final updated = project.copyWith(dialogues: next);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
