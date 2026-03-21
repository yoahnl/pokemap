import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

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
      settings: const ProjectSettings(),
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

class UpdateProjectSettingsUseCase {
  final ProjectRepository _repo;

  UpdateProjectSettingsUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectFileSystem fs,
    ProjectManifest project, {
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('UpdateProjectSettingsUseCase: Updating project settings');
    final updated = project.copyWith(name: name, settings: settings);
    await _repo.saveProject(updated, fs.projectManifestPath);
    return updated;
  }
}

class ImportProjectTilesetUseCase {
  final ProjectRepository _repo;

  ImportProjectTilesetUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectFileSystem fs,
    ProjectManifest project, {
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Tileset name cannot be empty');
    }
    if (scope == TilesetScope.global) {
      groupId = null;
    } else if (groupId == null) {
      throw Exception('A group-scoped tileset must target a group');
    }
    if (scope != TilesetScope.global && isWorldTileset) {
      throw Exception('World tileset must be global');
    }

    final sourceExt = p.extension(sourcePath).toLowerCase();
    const allowedExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.bmp'};
    if (!allowedExtensions.contains(sourceExt)) {
      throw Exception('Unsupported tileset image format: $sourceExt');
    }

    final id = _generateUniqueTilesetId(project, trimmedName);
    final relativePath = await fs.importTilesetImage(
      sourcePath,
      preferredName: id,
    );

    final sortOrder = _nextTilesetSortOrder(project, scope, groupId);
    final entry = ProjectTilesetEntry(
      id: id,
      name: trimmedName,
      relativePath: relativePath,
      scope: scope,
      groupId: groupId,
      sortOrder: sortOrder,
      isWorldTileset: isWorldTileset,
    );

    final updatedProject = project.copyWith(
      tilesets: [...project.tilesets, entry],
    );

    try {
      await _repo.saveProject(updatedProject, fs.projectManifestPath);
      return updatedProject;
    } catch (e) {
      await fs.deleteRelativeFile(relativePath);
      rethrow;
    }
  }
}

class UpdateProjectTilesetUseCase {
  final ProjectRepository _repo;

  UpdateProjectTilesetUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectFileSystem fs,
    ProjectManifest project, {
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
  }) async {
    final current = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );

    var nextScope = scope ?? current.scope;
    var nextGroupId = groupId ?? current.groupId;
    var nextWorld = isWorldTileset ?? current.isWorldTileset;

    if (nextScope == TilesetScope.global) {
      nextGroupId = null;
    } else if (nextGroupId == null) {
      throw Exception('A group-scoped tileset must target a group');
    }
    if (nextScope != TilesetScope.global) {
      nextWorld = false;
    }

    final updatedTilesets = project.tilesets.map((tileset) {
      if (tileset.id != tilesetId) return tileset;
      return tileset.copyWith(
        name: name?.trim().isNotEmpty == true ? name!.trim() : tileset.name,
        scope: nextScope,
        groupId: nextGroupId,
        isWorldTileset: nextWorld,
        sortOrder: sortOrder ?? tileset.sortOrder,
      );
    }).toList();

    final updatedProject = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class DeleteProjectTilesetUseCase {
  final ProjectRepository _projectRepo;
  final MapRepository _mapRepo;

  DeleteProjectTilesetUseCase(this._projectRepo, this._mapRepo);

  Future<ProjectManifest> execute(
    ProjectFileSystem fs,
    ProjectManifest project,
    String tilesetId,
  ) async {
    final target = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );

    for (final mapEntry in project.maps) {
      final mapPath = fs.resolveMapPath(mapEntry.relativePath);
      final map = await _mapRepo.loadMap(mapPath);
      if (map.tilesetId == tilesetId) {
        throw Exception(
            'Tileset "$tilesetId" is still used by map "${map.id}"');
      }
    }

    final remainingTilesets =
        project.tilesets.where((t) => t.id != tilesetId).toList();
    final updatedProject = project.copyWith(tilesets: remainingTilesets);
    await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);

    final stillUsedPath =
        remainingTilesets.any((t) => t.relativePath == target.relativePath);
    if (!stillUsedPath) {
      await fs.deleteRelativeFile(target.relativePath);
    }

    return updatedProject;
  }
}

class ReorderProjectTilesetUseCase {
  final ProjectRepository _repo;

  ReorderProjectTilesetUseCase(this._repo);

  Future<ProjectManifest> execute(
    ProjectFileSystem fs,
    ProjectManifest project, {
    required String tilesetId,
    required int direction,
  }) async {
    if (direction == 0) return project;
    final target = project.tilesets.firstWhere(
      (t) => t.id == tilesetId,
      orElse: () => throw Exception('Tileset not found: $tilesetId'),
    );

    final bucket = project.tilesets.where((t) {
      if (t.scope != target.scope) return false;
      if (target.scope == TilesetScope.global) return true;
      return t.groupId == target.groupId;
    }).toList()
      ..sort(_tilesetSort);

    final index = bucket.indexWhere((t) => t.id == tilesetId);
    if (index < 0) return project;
    final nextIndex = (index + direction).clamp(0, bucket.length - 1);
    if (nextIndex == index) return project;

    final moving = bucket.removeAt(index);
    bucket.insert(nextIndex, moving);

    final orderById = <String, int>{};
    for (var i = 0; i < bucket.length; i++) {
      orderById[bucket[i].id] = i;
    }

    final updatedTilesets = project.tilesets.map((t) {
      final nextSort = orderById[t.id];
      if (nextSort == null) return t;
      return t.copyWith(sortOrder: nextSort);
    }).toList();

    final updatedProject = project.copyWith(tilesets: updatedTilesets);
    await _repo.saveProject(updatedProject, fs.projectManifestPath);
    return updatedProject;
  }
}

class ResolveAssignableTilesetsForMapUseCase {
  List<ProjectTilesetEntry> execute(ProjectManifest project, String mapId) {
    final mapEntry = project.maps.firstWhere(
      (m) => m.id == mapId,
      orElse: () => throw Exception('Map not found in manifest: $mapId'),
    );

    final allowedGroupIds = <String>{};
    String? cursor = mapEntry.groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      allowedGroupIds.add(cursor);
      final nextGroup = project.groups.firstWhere(
        (g) => g.id == cursor,
        orElse: () =>
            throw Exception('Unknown group referenced by map: $cursor'),
      );
      cursor = nextGroup.parentGroupId;
    }

    final global = project.tilesets
        .where((t) => t.scope == TilesetScope.global)
        .toList(growable: false)
      ..sort(_tilesetSort);
    final grouped = project.tilesets
        .where((t) =>
            t.scope == TilesetScope.group &&
            t.groupId != null &&
            allowedGroupIds.contains(t.groupId))
        .toList(growable: false)
      ..sort(_tilesetSort);

    final result = <ProjectTilesetEntry>[];
    final added = <String>{};
    for (final tileset in [...global, ...grouped]) {
      if (added.add(tileset.id)) {
        result.add(tileset);
      }
    }
    return result;
  }
}

class AssignTilesetToMapUseCase {
  final MapRepository _mapRepo;
  final ResolveAssignableTilesetsForMapUseCase _resolver;

  AssignTilesetToMapUseCase(this._mapRepo, this._resolver);

  Future<MapData> execute(
    ProjectManifest project,
    MapData map,
    String mapPath,
    String tilesetId,
  ) async {
    final assignable = _resolver.execute(project, map.id);
    final isAllowed = assignable.any((t) => t.id == tilesetId);
    if (!isAllowed) {
      throw Exception(
          'Tileset "$tilesetId" is not assignable to map "${map.id}"');
    }

    final updatedMap = map.copyWith(tilesetId: tilesetId);
    MapValidator.validate(updatedMap);
    await _mapRepo.saveMap(updatedMap, mapPath);
    return updatedMap;
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
    final defaultTilesetId = _pickDefaultTilesetId(project, groupId);

    final map = MapData(
      id: mapId,
      name: mapId,
      size: GridSize(width: w, height: h),
      tilesetId: defaultTilesetId,
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

String _generateUniqueTilesetId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'tileset' : normalized;

  var candidate = base;
  var suffix = 1;
  final existingIds = project.tilesets.map((t) => t.id).toSet();
  while (existingIds.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

int _nextTilesetSortOrder(
  ProjectManifest project,
  TilesetScope scope,
  String? groupId,
) {
  final filtered = project.tilesets.where((t) {
    if (t.scope != scope) return false;
    if (scope == TilesetScope.global) return true;
    return t.groupId == groupId;
  });
  if (filtered.isEmpty) return 0;
  return filtered.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
}

int _tilesetSort(ProjectTilesetEntry a, ProjectTilesetEntry b) {
  if (a.isWorldTileset != b.isWorldTileset) {
    return a.isWorldTileset ? -1 : 1;
  }
  final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
  if (sortOrderCompare != 0) return sortOrderCompare;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

String _pickDefaultTilesetId(ProjectManifest project, String? groupId) {
  if (project.tilesets.isEmpty) return 'default';

  if (groupId != null) {
    final ancestors = <String>{};
    String? cursor = groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      ancestors.add(cursor);
      ProjectMapGroup? group;
      for (final candidate in project.groups) {
        if (candidate.id == cursor) {
          group = candidate;
          break;
        }
      }
      cursor = group?.parentGroupId;
    }

    final grouped = project.tilesets
        .where((t) =>
            t.scope == TilesetScope.group &&
            t.groupId != null &&
            ancestors.contains(t.groupId))
        .toList()
      ..sort(_tilesetSort);
    if (grouped.isNotEmpty) return grouped.first.id;
  }

  final world = project.tilesets.where((t) => t.isWorldTileset).toList()
    ..sort(_tilesetSort);
  if (world.isNotEmpty) return world.first.id;

  final global = project.tilesets
      .where((t) => t.scope == TilesetScope.global)
      .toList()
    ..sort(_tilesetSort);
  if (global.isNotEmpty) return global.first.id;

  return project.tilesets.first.id;
}
