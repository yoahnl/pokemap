import 'package:map_core/map_core.dart';

List<ProjectSmartTilePattern> availableTerrainPatterns({
  required ProjectManifest project,
  required MapData map,
  required ProjectSmartTilePreset preset,
}) {
  final patterns = project.smartTileCatalog.patterns.where((pattern) {
    if (pattern.usage != preset.usage ||
        pattern.construction == null && (pattern.width > 8 || pattern.height > 8) ||
        pattern.construction != null && map.spatialScene != null) {
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
                (followTerrain ||
                    const {
                          SmartTileRenderChannel.ground,
                          SmartTileRenderChannel.understory,
                          SmartTileRenderChannel.canopy,
                        }.contains(part.channel)) &&
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
  if (preset.categoryId.isNotEmpty && patterns.any(
    (pattern) => pattern.construction != null && pattern.categoryId == preset.categoryId,
  )) {
    patterns.removeWhere((pattern) => pattern.categoryId != preset.categoryId);
  }
  patterns.sort((left, right) {
    final order = left.sortOrder.compareTo(right.sortOrder);
    return order != 0 ? order : left.name.compareTo(right.name);
  });
  return patterns;
}

SmartTilePatternSelectionKind defaultTerrainPatternSelection(
  ProjectSmartTilePattern pattern,
) {
  final construction = pattern.construction;
  if (construction == null) return SmartTilePatternSelectionKind.stamp;
  return construction.x == null || construction.y == null
      ? SmartTilePatternSelectionKind.line
      : SmartTilePatternSelectionKind.rectangle;
}

String terrainPatternConstructionHint(ProjectSmartTilePattern pattern) {
  final construction = pattern.construction!;
  String dimension(String label, int source, SmartTilePatternRepeatAxis? axis) {
    if (axis == null) return '$label fixe : $source cases';
    final minimum = axis.minimumLength(source);
    final maximum = axis.maximumRepeats;
    final limit = maximum == null
        ? ''
        : ', ${source - axis.repeatLength + maximum * axis.repeatLength} maximum';
    return '$label : $minimum minimum$limit, par ${axis.repeatLength}';
  }
  return '${dimension('Largeur', pattern.width, construction.x)} · '
      '${dimension('Hauteur', pattern.height, construction.y)}';
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
