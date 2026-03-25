import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import 'project_use_case_support.dart';

/// Dossiers vides uniquement : évite suppressions implicites dangereuses pour l’utilisateur.
class DeleteTilesetLibraryFolderUseCase {
  DeleteTilesetLibraryFolderUseCase(this._repo);

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
    final exists = project.tilesetFolders.any((f) => f.id == id);
    if (!exists) {
      throw EditorNotFoundException('Tileset folder not found: $id');
    }
    final hasChildFolder =
        project.tilesetFolders.any((f) => f.parentFolderId == id);
    if (hasChildFolder) {
      throw const EditorConflictException(
        'Cannot delete folder: it still contains subfolders. Remove or move them first.',
      );
    }
    final hasTileset = project.tilesets.any((t) => t.folderId?.trim() == id);
    if (hasTileset) {
      throw const EditorConflictException(
        'Cannot delete folder: it still contains tilesets. Move them to another folder or to the library root first.',
      );
    }
    final updatedFolders =
        project.tilesetFolders.where((f) => f.id != id).toList();
    final updated = project.copyWith(tilesetFolders: updatedFolders);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class CreateTilesetLibraryFolderUseCase {
  CreateTilesetLibraryFolderUseCase(this._repo);

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
      final parentOk =
          project.tilesetFolders.any((f) => f.id == parent);
      if (!parentOk) {
        throw EditorNotFoundException('Parent folder not found: $parent');
      }
    }

    final id = generateUniqueTilesetFolderId(project, trimmed);
    final sortOrder =
        nextTilesetLibraryFolderSortOrder(project, parent);
    final folder = ProjectTilesetFolder(
      id: id,
      name: trimmed,
      parentFolderId: parent == null || parent.isEmpty ? null : parent,
      sortOrder: sortOrder,
    );
    final updated = project.copyWith(
      tilesetFolders: [...project.tilesetFolders, folder],
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class RenameTilesetLibraryFolderUseCase {
  RenameTilesetLibraryFolderUseCase(this._repo);

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
    final nextFolders = project.tilesetFolders.map((f) {
      if (f.id != id) return f;
      found = true;
      return f.copyWith(name: trimmed);
    }).toList(growable: false);
    if (!found) {
      throw EditorNotFoundException('Tileset folder not found: $id');
    }
    final updated = project.copyWith(tilesetFolders: nextFolders);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class MoveTilesetLibraryFolderUseCase {
  MoveTilesetLibraryFolderUseCase(this._repo);

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
          project.tilesetFolders.any((f) => f.id == newParent);
      if (!parentExists) {
        throw EditorNotFoundException('Parent folder not found: $newParent');
      }
      final blocked = tilesetFolderSubtreeIds(project, id);
      if (blocked.contains(newParent)) {
        throw const EditorInvalidOperationException(
          'Cannot move a folder into one of its descendants',
        );
      }
    }

    final others =
        project.tilesetFolders.where((x) => x.id != id).toList();
    final sortOrder = nextTilesetLibraryFolderSortOrder(
      project.copyWith(tilesetFolders: others),
      newParent == null || newParent.isEmpty ? null : newParent,
    );

    var found = false;
    final nextFolders = project.tilesetFolders.map((f) {
      if (f.id != id) return f;
      found = true;
      return f.copyWith(
        parentFolderId:
            newParent == null || newParent.isEmpty ? null : newParent,
        sortOrder: sortOrder,
      );
    }).toList(growable: false);
    if (!found) {
      throw EditorNotFoundException('Tileset folder not found: $id');
    }
    final updated = project.copyWith(tilesetFolders: nextFolders);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class AssignTilesetToLibraryFolderUseCase {
  AssignTilesetToLibraryFolderUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
    required String folderId,
  }) async {
    final tid = tilesetId.trim();
    final fid = folderId.trim();
    if (tid.isEmpty || fid.isEmpty) {
      throw const EditorValidationException('Invalid tileset or folder id');
    }
    final folderOk = project.tilesetFolders.any((f) => f.id == fid);
    if (!folderOk) {
      throw EditorNotFoundException('Tileset folder not found: $fid');
    }

    final current = project.tilesets.firstWhere(
      (t) => t.id == tid,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tid'),
    );

    final sortOrder = nextTilesetSortOrder(
      project,
      current.scope,
      current.groupId,
      libraryFolderId: fid,
    );

    final updatedTilesets = project.tilesets.map((t) {
      if (t.id != tid) return t;
      return t.copyWith(folderId: fid, sortOrder: sortOrder);
    }).toList(growable: false);

    final updated = project.copyWith(tilesets: updatedTilesets);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class MoveTilesetToLibraryRootUseCase {
  MoveTilesetToLibraryRootUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tilesetId,
  }) async {
    final tid = tilesetId.trim();
    if (tid.isEmpty) {
      throw const EditorValidationException('Tileset id cannot be empty');
    }
    final current = project.tilesets.firstWhere(
      (t) => t.id == tid,
      orElse: () =>
          throw EditorNotFoundException('Tileset not found: $tid'),
    );

    final sortOrder = nextTilesetSortOrder(
      project,
      current.scope,
      current.groupId,
      libraryFolderId: null,
    );

    final updatedTilesets = project.tilesets.map((t) {
      if (t.id != tid) return t;
      return t.copyWith(folderId: null, sortOrder: sortOrder);
    }).toList(growable: false);

    final updated = project.copyWith(tilesets: updatedTilesets);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
