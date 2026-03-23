import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import 'project_use_case_support.dart';

class SaveMapUseCase {
  final MapRepository _repo;

  SaveMapUseCase(this._repo);

  Future<void> execute(MapData map, String path) async {
    await _repo.saveMap(map, path);
  }
}

class CreateMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;

  CreateMapUseCase(this._mapRepo, this._projectRepo);

  Future<MapData> execute(
      ProjectWorkspace fs, ProjectManifest project, String mapId, int w, int h,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    final defaultTilesetId = pickDefaultTilesetId(project, groupId);

    final map = MapData(
      id: mapId,
      name: mapId,
      size: GridSize(width: w, height: h),
      tilesetId: defaultTilesetId ?? '',
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tilesetId: defaultTilesetId,
          tiles: List.filled(w * h, 0),
        ),
        MapLayer.terrain(
          id: 'l_terrain',
          name: 'Terrain',
          terrains: List<TerrainType>.filled(
            w * h,
            TerrainType.none,
            growable: false,
          ),
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

  Future<MapData> execute(ProjectWorkspace fs, String relativePath) async {
    final path = fs.resolveMapPath(relativePath);
    final map = await _repo.loadMap(path);
    return _migrateLegacyLayerTilesets(map);
  }

  MapData _migrateLegacyLayerTilesets(MapData map) {
    final legacyTilesetId = map.tilesetId.trim();
    if (legacyTilesetId.isEmpty) return map;

    var changed = false;
    final updatedLayers = map.layers.map((layer) {
      if (layer is! TileLayer) return layer;
      final layerTilesetId = layer.tilesetId?.trim();
      if (layerTilesetId == null || layerTilesetId.isEmpty) {
        changed = true;
        return layer.copyWith(tilesetId: legacyTilesetId);
      }
      return layer;
    }).toList(growable: false);

    if (!changed) return map;
    return map.copyWith(layers: updatedLayers);
  }
}

class ResizeMapUseCase {
  MapData execute(MapData map, int width, int height) {
    final resized = resizeMapData(map, width: width, height: height);
    MapValidator.validate(resized);
    return resized;
  }
}

class RenameMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;

  RenameMapUseCase(this._mapRepo, this._projectRepo);

  Future<ProjectManifest> execute(ProjectWorkspace fs, ProjectManifest project,
      String oldId, String newId) async {
    if (newId.isEmpty) {
      throw const EditorValidationException('Map ID cannot be empty');
    }
    if (oldId == newId) return project;

    if (project.maps.any((e) => e.id == newId)) {
      throw EditorConflictException(
          'A map with the ID "$newId" already exists');
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
      ProjectWorkspace fs, ProjectManifest project, String mapId) async {
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
      ProjectWorkspace fs, ProjectManifest project, String sourceId) async {
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
