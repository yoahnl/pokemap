import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'standard_path_preset_vertical_atlas_builder.dart';
import 'terrain_path_variant_vertical_atlas_layout.dart';

/// Builds a legacy animated **tall grass** [ProjectPathPreset] from the
/// standard vertical atlas layout.
///
/// This is a thin, product-oriented wrapper on top of Lot 15 (fourth standard
/// surface in this series: water, lava, ice, then tall grass). It does not add
/// wild encounters, local step rustle, player foreground overlay, passability
/// rules, or rendering. The only "tall grass" guarantee here is:
///
/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.tallGrass]
///
/// Full product behavior for tall grass belongs to future Surface Engine /
/// gameplay lots. Everything else (columns, frames, tileset override
/// semantics) is inherited from the shared vertical-atlas stack (Lots 11-15).
ProjectPathPreset createStandardTallGrassPathPresetFromVerticalAtlas({
  required String id,
  required String name,
  required String tilesetId,
  String? categoryId,
  int sortOrder = 0,
  int firstColumn = 0,
  int startRow = 0,
  List<TerrainPathVariant> variants =
      standardTerrainPathVariantVerticalAtlasOrder,
  required int frameCount,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String frameTilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
}) {
  // Deliberately no duplicated validation. Lot 15 composes Lot 14 + Lot 13 and
  // owns the behavior contract. This function only pins surfaceKind to
  // tallGrass.
  return createStandardProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.tallGrass,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    firstColumn: firstColumn,
    startRow: startRow,
    variants: variants,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    frameTilesetId: frameTilesetId,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );
}
