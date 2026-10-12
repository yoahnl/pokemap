import 'package:map_core/map_core.dart';

List<ProjectSmartTilePattern> availableTerrainPatterns({
  required ProjectManifest project,
  required MapData map,
  required ProjectSmartTilePreset preset,
}) {
  final patterns = project.smartTileCatalog.patterns.where((pattern) {
    if (pattern.usage != preset.usage ||
        pattern.width > 8 ||
        pattern.height > 8) {
      return false;
    }
    if (map.spatialScene != null &&
        pattern.repeatMode == SmartTilePatternRepeatMode.stamp) {
      final occupied = pattern.cells.where((cell) => cell.parts.isNotEmpty);
      if (!occupied.any((cell) => cell.x == 0) ||
          !occupied.any((cell) => cell.y == 0)) {
        return false;
      }
    }
    return pattern.cells.every(
      (cell) => cell.parts.every((part) {
        if (map.spatialScene != null &&
            part.source is! SmartTileModel3dSource &&
            part.channel != SmartTileRenderChannel.ground &&
            part.channel != SmartTileRenderChannel.understory) {
          return false;
        }
        return switch (part.source) {
          SmartTileModel3dSource(:final modelId, :final followTerrain) =>
            map.spatialScene != null &&
                followTerrain &&
                project.models3d.any((model) => model.id == modelId) &&
                project.resourceLibraryCatalog.availableForMap(
                  'model3d',
                  modelId,
                  map.id,
                ),
          SmartTileFrameSource(:final frame) => _frameAvailable(
            project,
            map.id,
            frame,
          ),
          SmartTileAnimationSource(:final animationId) =>
            project.smartTileCatalog.animations.any(
              (animation) =>
                  animation.id == animationId &&
                  animation.frames.every(
                    (frame) => _frameAvailable(project, map.id, frame.frame),
                  ),
            ),
        };
      }),
    );
  }).toList();
  patterns.sort((left, right) {
    final order = left.sortOrder.compareTo(right.sortOrder);
    return order != 0 ? order : left.name.compareTo(right.name);
  });
  return patterns;
}

bool _frameAvailable(
  ProjectManifest project,
  String mapId,
  SmartTileFrameRef frame,
) {
  final atlas = project.smartTileCatalog.atlases
      .where((atlas) => atlas.id == frame.atlasId)
      .firstOrNull;
  return atlas != null &&
      project.tilesets.any((tileset) => tileset.id == atlas.tilesetId) &&
      project.resourceLibraryCatalog.availableForMap(
        'tileset',
        atlas.tilesetId,
        mapId,
      );
}
