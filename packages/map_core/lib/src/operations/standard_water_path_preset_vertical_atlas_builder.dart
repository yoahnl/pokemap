import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'standard_path_preset_vertical_atlas_builder.dart';
import 'terrain_path_variant_vertical_atlas_layout.dart';

/// Builds a legacy animated **water** [ProjectPathPreset] from the standard
/// vertical atlas layout.
///
/// This is a thin, product-oriented wrapper on top of Lot 15. It does not add
/// gameplay rules, surf, encounters, collision, or rendering. The only
/// "water" guarantee here is:
///
/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.water]
///
/// Everything else (columns, frames, tileset override semantics) is inherited
/// from the shared vertical-atlas stack (Lots 11-15).
ProjectPathPreset createStandardWaterPathPresetFromVerticalAtlas({
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
  // owns the behavior contract. This function only pins surfaceKind to water.
  return createStandardProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.water,
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
