import '../models/enums.dart';
import '../models/path_center_pattern.dart';
import '../models/project_manifest.dart';

/// Non-persistent view of a legacy path preset as a center pattern.
final class LegacyProjectPathPresetCenterPatternView {
  const LegacyProjectPathPresetCenterPatternView({
    required this.presetId,
    required this.presetName,
    required this.defaultTilesetId,
    required this.surfaceKind,
    required this.sourceVariant,
    required this.centerPattern,
    this.categoryId,
    required this.sortOrder,
  });

  final String presetId;
  final String presetName;
  final String defaultTilesetId;
  final PathSurfaceKind surfaceKind;
  final TerrainPathVariant sourceVariant;
  final PathCenterPattern centerPattern;
  final String? categoryId;
  final int sortOrder;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LegacyProjectPathPresetCenterPatternView &&
            presetId == other.presetId &&
            presetName == other.presetName &&
            defaultTilesetId == other.defaultTilesetId &&
            surfaceKind == other.surfaceKind &&
            sourceVariant == other.sourceVariant &&
            centerPattern == other.centerPattern &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(
      presetId,
      presetName,
      defaultTilesetId,
      surfaceKind,
      sourceVariant,
      centerPattern,
      categoryId,
      sortOrder,
    );
  }
}

/// Adapts a legacy [ProjectPathPreset] center mapping to a local 1x1 pattern.
LegacyProjectPathPresetCenterPatternView
    createLegacyProjectPathPresetCenterPatternView({
  required ProjectPathPreset preset,
  TerrainPathVariant centerVariant = TerrainPathVariant.cross,
}) {
  final mapping = _findVariantMapping(preset, centerVariant);
  if (mapping == null) {
    throw ArgumentError.value(
      centerVariant,
      'centerVariant',
      'ProjectPathPreset does not contain center variant $centerVariant.',
    );
  }
  if (mapping.frames.isEmpty) {
    throw ArgumentError.value(
      centerVariant,
      'centerVariant',
      'ProjectPathPreset center variant $centerVariant has no frames.',
    );
  }

  return LegacyProjectPathPresetCenterPatternView(
    presetId: preset.id,
    presetName: preset.name,
    defaultTilesetId: preset.tilesetId,
    surfaceKind: preset.surfaceKind,
    sourceVariant: centerVariant,
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: mapping.frames,
        ),
      ],
    ),
    categoryId: preset.categoryId,
    sortOrder: preset.sortOrder,
  );
}

PathPresetVariantMapping? _findVariantMapping(
  ProjectPathPreset preset,
  TerrainPathVariant variant,
) {
  for (final mapping in preset.variants) {
    if (mapping.variant == variant) {
      return mapping;
    }
  }
  return null;
}
