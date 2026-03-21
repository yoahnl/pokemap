import 'package:map_core/map_core.dart';

abstract class ProjectRepository {
  Future<void> saveProject(ProjectManifest project, String path);
  Future<ProjectManifest> loadProject(String path);
}

abstract class MapRepository {
  Future<void> saveMap(MapData map, String path);
  Future<MapData> loadMap(String path);
}

abstract class TilesetRepository {
  Future<void> saveTileset(TilesetConfig tileset, String path);
  Future<TilesetConfig> loadTileset(String path);
}
