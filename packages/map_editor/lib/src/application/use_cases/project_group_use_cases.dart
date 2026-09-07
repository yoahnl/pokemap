import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';

import '../../domain/repositories/repositories.dart';
import '../ports/project_workspace.dart';

class CreateGroupUseCase {
  CreateGroupUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project,
    String name,
    MapGroupType type, {
    String? parentId,
  }) async {
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final newGroup = ProjectMapGroup(
      id: id,
      name: name,
      type: type,
      parentGroupId: parentId,
      sortOrder: project.groups.length,
    );

    final updatedProject = const MapLibraryActions().reorganize(
      project,
      groups: [...project.groups, newGroup],
      assignments: const [],
    );

    await _repo.saveProject(updatedProject, workspace.projectManifestPath);
    return updatedProject;
  }
}

class DeleteGroupUseCase {
  DeleteGroupUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project,
    String groupId,
  ) async {
    final updatedGroups = project.groups
        .where((group) => group.id != groupId)
        .toList();

    final updatedMaps = project.maps.map((mapEntry) {
      if (mapEntry.groupId == groupId) return mapEntry.copyWith(groupId: null);
      return mapEntry;
    }).toList();

    final parentId = project.groups.any((group) => group.id == groupId)
        ? project.groups
              .firstWhere((group) => group.id == groupId)
              .parentGroupId
        : null;

    final finalGroups = updatedGroups.map((group) {
      if (group.parentGroupId == groupId) {
        return group.copyWith(parentGroupId: parentId);
      }
      return group;
    }).toList();

    final updatedProject = const MapLibraryActions().reorganize(
      project,
      groups: finalGroups,
      assignments: [
        for (final entry in updatedMaps)
          {'mapId': entry.id, 'groupId': entry.groupId},
      ],
    );
    await _repo.saveProject(updatedProject, workspace.projectManifestPath);
    return updatedProject;
  }
}

class MoveMapToGroupUseCase {
  MoveMapToGroupUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project,
    String mapId,
    String? groupId,
  ) async {
    final updatedProject = const MapLibraryActions().reorganize(
      project,
      assignments: [
        {'mapId': mapId, 'groupId': groupId},
      ],
    );
    await _repo.saveProject(updatedProject, workspace.projectManifestPath);
    return updatedProject;
  }
}

class RenameGroupUseCase {
  RenameGroupUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project,
    String groupId,
    String newName,
  ) async {
    final updatedGroups = project.groups.map((group) {
      if (group.id == groupId) return group.copyWith(name: newName);
      return group;
    }).toList();

    final updatedProject = const MapLibraryActions().reorganize(
      project,
      groups: updatedGroups,
      assignments: const [],
    );
    await _repo.saveProject(updatedProject, workspace.projectManifestPath);
    return updatedProject;
  }
}
