import '../models/enums.dart';
import '../models/project_manifest.dart';
import '../models/project_path_pattern_preset.dart';
import 'path_center_pattern_resolver.dart';

enum PathPatternVisualResolutionKind {
  centerPattern,
  legacyVariant,
}

final class PathPatternVisualResolution {
  PathPatternVisualResolution({
    required this.kind,
    required this.resolvedVariant,
    required this.mapX,
    required this.mapY,
    required this.centerLocalX,
    required this.centerLocalY,
    required List<TilesetVisualFrame> frames,
  }) : frames = List<TilesetVisualFrame>.unmodifiable(frames);

  final PathPatternVisualResolutionKind kind;
  final TerrainPathVariant resolvedVariant;
  final int mapX;
  final int mapY;
  final int? centerLocalX;
  final int? centerLocalY;
  final List<TilesetVisualFrame> frames;

  bool get usesCenterPattern =>
      kind == PathPatternVisualResolutionKind.centerPattern;
  bool get usesLegacyVariant =>
      kind == PathPatternVisualResolutionKind.legacyVariant;
}

PathPatternVisualResolution resolvePathPatternVisual({
  required ProjectPathPatternPreset pathPatternPreset,
  required ProjectPathPreset basePathPreset,
  required TerrainPathVariant resolvedVariant,
  required int mapX,
  required int mapY,
}) {
  if (mapX < 0) {
    throw ArgumentError.value(
      mapX,
      'mapX',
      'PathPattern mapX must be non-negative.',
    );
  }
  if (mapY < 0) {
    throw ArgumentError.value(
      mapY,
      'mapY',
      'PathPattern mapY must be non-negative.',
    );
  }

  if (resolvedVariant != TerrainPathVariant.cross) {
    final legacyMapping = _findVariantMapping(
      basePathPreset: basePathPreset,
      variant: resolvedVariant,
    );
    if (legacyMapping != null && legacyMapping.frames.isNotEmpty) {
      return PathPatternVisualResolution(
        kind: PathPatternVisualResolutionKind.legacyVariant,
        resolvedVariant: resolvedVariant,
        mapX: mapX,
        mapY: mapY,
        centerLocalX: null,
        centerLocalY: null,
        frames: legacyMapping.frames,
      );
    }
  }

  final centerResolution = resolvePathCenterPatternCell(
    pattern: pathPatternPreset.centerPattern,
    mapX: mapX,
    mapY: mapY,
  );
  return PathPatternVisualResolution(
    kind: PathPatternVisualResolutionKind.centerPattern,
    resolvedVariant: resolvedVariant,
    mapX: mapX,
    mapY: mapY,
    centerLocalX: centerResolution.localX,
    centerLocalY: centerResolution.localY,
    frames: centerResolution.cell.frames,
  );
}

PathPresetVariantMapping? _findVariantMapping({
  required ProjectPathPreset basePathPreset,
  required TerrainPathVariant variant,
}) {
  for (final mapping in basePathPreset.variants) {
    if (mapping.variant == variant) {
      return mapping;
    }
  }
  return null;
}
