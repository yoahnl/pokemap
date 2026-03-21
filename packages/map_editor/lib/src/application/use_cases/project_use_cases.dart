import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../../infrastructure/filesystem/project_filesystem.dart';

class CreateProjectUseCase {
  final ProjectRepository _repo;

  CreateProjectUseCase(this._repo);

  Future<ProjectManifest> execute(String name, String directory) async {
    debugPrint('CreateProjectUseCase: Executing for $name in $directory');
    final manifest = ProjectManifest(
      name: name,
      maps: [],
      tilesets: [],
      groups: [],
    );
    final fs = ProjectFileSystem(directory);
    final projectFile = fs.projectManifestPath;
    await fs.ensureDirectoryExists(projectFile);

    await _repo.saveProject(manifest, projectFile);
    return manifest;
  }
}

class LoadProjectUseCase {
  final ProjectRepository _repo;

  LoadProjectUseCase(this._repo);

  Future<ProjectManifest> execute(String manifestPath) async {
    debugPrint('LoadProjectUseCase: Loading project from $manifestPath');
    return await _repo.loadProject(manifestPath);
  }
}

class SaveMapUseCase {
  final MapRepository _repo;

  SaveMapUseCase(this._repo);

  Future<void> execute(MapData map, String path) async {
    debugPrint('SaveMapUseCase: Saving map to $path');
    await _repo.saveMap(map, path);
  }
}

class CreateMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;

  CreateMapUseCase(this._mapRepo, this._projectRepo);

  Future<MapData> execute(
      ProjectFileSystem fs, ProjectManifest project, String mapId, int w, int h,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'CreateMapUseCase: Creating map $mapId (${w}x${h}) in group $groupId');

    final map = MapData(
      id: mapId,
      name: mapId,
      size: GridSize(width: w, height: h),
      tilesetId: 'default',
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tiles: List.filled(w * h, 0),
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: List.filled(w * h, false),
        ),
      ],
    );

    final mapPath = fs.getMapRelativePath(mapId);
    final absPath = fs.resolveMapPath(mapPath);
    await fs.ensureDirectoryExists(absPath);

    await _mapRepo.saveMap(map, absPath);

    final updatedProject = project.copyWith(maps: [
      ...project.maps,
      ProjectMapEntry(
        id: mapId,
        name: mapId,
        relativePath: mapPath,
        groupId: groupId,
        role: role,
      )
    ]);

    await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);

    return map;
  }
}

class LoadMapUseCase {
  final MapRepository _repo;

  LoadMapUseCase(this._repo);

  Future<MapData> execute(ProjectFileSystem fs, String relativePath) async {
    final path = fs.resolveMapPath(relativePath);
    debugPrint('LoadMapUseCase: Loading map from $path');
    return await _repo.loadMap(path);
  }
}

class ResizeMapUseCase {
  MapData execute(MapData map, int width, int height) {
    debugPrint('ResizeMapUseCase: Resizing map ${map.id} to ${width}x$height');

    final resized = resizeMapData(map, width: width, height: height);
    MapValidator.validate(resized);
    return resized;
  }
}

class RenameMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;

  RenameMapUseCase(this._mapRepo, this._projectRepo);

  Future<ProjectManifest> execute(ProjectFileSystem fs, ProjectManifest project,
      String oldId, String newId) async {
    debugPrint('RenameMapUseCase: Renaming $oldId to $newId');

    if (newId.isEmpty) throw Exception('Map ID cannot be empty');
    if (oldId == newId) return project;

    if (project.maps.any((e) => e.id == newId)) {
      throw Exception('A map with the ID "$newId" already exists');
    }

    final oldPath = fs.getMapPath(oldId);
    final newPath = fs.getMapPath(newId);
    final newRelativePath = fs.getMapRelativePath(newId);

    final mapData = await _mapRepo.loadMap(oldPath);
    final updatedMap = mapData.copyWith(id: newId, name: newId);

    await _mapRepo.saveMap(updatedMap, newPath);

    try {
      final updatedMaps = project.maps.map((entry) {
        if (entry.id == oldId) {
          return entry.copyWith(
              id: newId, name: newId, relativePath: newRelativePath);
        }
        return entry;
      }).toList();

      final updatedProject = project.copyWith(maps: updatedMaps);
      await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);

      if (oldPath.toLowerCase() != newPath.toLowerCase()) {
        await _mapRepo.deleteMap(oldPath);
      }

      return updatedProject;
    } catch (e) {
      await _mapRepo.deleteMap(newPath);
      rethrow;
    }
  }
}

class DeleteMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;

  DeleteMapUseCase(this._mapRepo, this._projectRepo);

  Future<ProjectManifest> execute(
      ProjectFileSystem fs, ProjectManifest project, String mapId) async {
    debugPrint('DeleteMapUseCase: Deleting map $mapId');

    final mapPath = fs.getMapPath(mapId);
    await _mapRepo.deleteMap(mapPath);

    final updatedMaps =
        project.maps.where((entry) => entry.id != mapId).toList();
    final updatedProject = project.copyWith(maps: updatedMaps);
    await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);

    return updatedProject;
  }
}

class DuplicateMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;

  DuplicateMapUseCase(this._mapRepo, this._projectRepo);

  Future<ProjectManifest> execute(
      ProjectFileSystem fs, ProjectManifest project, String sourceId) async {
    debugPrint('DuplicateMapUseCase: Duplicating map $sourceId');

    String targetId = '${sourceId}_copy';
    int suffix = 1;
    while (project.maps.any((e) => e.id == targetId)) {
      targetId = '${sourceId}_copy_$suffix';
      suffix++;
    }

    final sourcePath = fs.getMapPath(sourceId);
    final targetPath = fs.getMapPath(targetId);
    final targetRelativePath = fs.getMapRelativePath(targetId);

    final mapData = await _mapRepo.loadMap(sourcePath);
    final duplicatedMap = mapData.copyWith(id: targetId, name: targetId);
    await _mapRepo.saveMap(duplicatedMap, targetPath);

    final sourceEntry = project.maps.firstWhere((e) => e.id == sourceId);

    final updatedProject = project.copyWith(maps: [
      ...project.maps,
      ProjectMapEntry(
        id: targetId,
        name: targetId,
        relativePath: targetRelativePath,
        groupId: sourceEntry.groupId,
        role: sourceEntry.role,
      )
    ]);
    await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);

    return updatedProject;
  }
}

class CreateGroupUseCase {
  final ProjectRepository _repo;

  CreateGroupUseCase(this._repo);

  Future<ProjectManifest> execute(ProjectFileSystem fs, ProjectManifest project,
      String name, MapGroupType type,
      {String? parentId}) async {
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final newGroup = ProjectMapGroup(
      id: id,
      name: name,
      type: type,
      parentGroupId: parentId,
      sortOrder: project.groups.length,
    );

    final updatedProject = project.copyWith(
      groups: [...project.groups, newGroup],
    );

    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class DeleteGroupUseCase {
  final ProjectRepository _repo;

  DeleteGroupUseCase(this._repo);

  Future<ProjectManifest> execute(
      ProjectFileSystem fs, ProjectManifest project, String groupId) async {
    debugPrint('DeleteGroupUseCase: Deleting group $groupId');

    // 1. Remove the group
    final updatedGroups = project.groups.where((g) => g.id != groupId).toList();

    // 2. Detach maps from this group
    final updatedMaps = project.maps.map((m) {
      if (m.groupId == groupId) return m.copyWith(groupId: null);
      return m;
    }).toList();

    // 3. Move child groups up one level (or to the same level as the deleted group)
    final parentId = project.groups.any((g) => g.id == groupId)
        ? project.groups.firstWhere((g) => g.id == groupId).parentGroupId
        : null;

    final finalGroups = updatedGroups.map((g) {
      if (g.parentGroupId == groupId)
        return g.copyWith(parentGroupId: parentId);
      return g;
    }).toList();

    final updatedProject =
        project.copyWith(groups: finalGroups, maps: updatedMaps);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class MoveMapToGroupUseCase {
  final ProjectRepository _repo;

  MoveMapToGroupUseCase(this._repo);

  Future<ProjectManifest> execute(ProjectFileSystem fs, ProjectManifest project,
      String mapId, String? groupId) async {
    final updatedMaps = project.maps.map((m) {
      if (m.id == mapId) return m.copyWith(groupId: groupId);
      return m;
    }).toList();

    final updatedProject = project.copyWith(maps: updatedMaps);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class RenameGroupUseCase {
  final ProjectRepository _repo;

  RenameGroupUseCase(this._repo);

  Future<ProjectManifest> execute(ProjectFileSystem fs, ProjectManifest project,
      String groupId, String newName) async {
    final updatedGroups = project.groups.map((g) {
      if (g.id == groupId) return g.copyWith(name: newName);
      return g;
    }).toList();

    final updatedProject = project.copyWith(groups: updatedGroups);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}
