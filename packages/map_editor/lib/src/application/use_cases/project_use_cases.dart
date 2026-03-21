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
    );
    final fs = ProjectFileSystem(directory);
    await _repo.saveProject(manifest, fs.projectManifestPath);
    return manifest;
  }
}

class CreateMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;

  CreateMapUseCase(this._mapRepo, this._projectRepo);

  Future<MapData> execute(ProjectFileSystem fs, ProjectManifest project, String mapId, int w, int h) async {
    debugPrint('CreateMapUseCase: Creating map $mapId (${w}x${h})');
    
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

    final mapPath = 'maps/$mapId.json';
    final absPath = fs.resolveMapPath(mapPath);
    await fs.ensureDirectoryExists(absPath);
    
    debugPrint('CreateMapUseCase: Saving map file to $absPath');
    await _mapRepo.saveMap(map, absPath);

    final updatedProject = project.copyWith(
      maps: [...project.maps, ProjectMapEntry(id: mapId, name: mapId, relativePath: mapPath)]
    );
    
    debugPrint('CreateMapUseCase: Updating project manifest');
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
