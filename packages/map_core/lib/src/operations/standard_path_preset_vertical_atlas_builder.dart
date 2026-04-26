import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'path_preset_vertical_atlas_builder.dart';
import 'terrain_path_variant_vertical_atlas_layout.dart';

/// Builds a legacy [ProjectPathPreset] from the standard vertical atlas layout.
///
/// This is the thin composition layer for Lot 15:
///
/// 1. Lot 14 creates the standard [TerrainPathVariant] -> column layout.
/// 2. Lot 13 turns those columns into a complete legacy [ProjectPathPreset].
///
/// The helper deliberately stays boring and explicit. It does not duplicate the
/// validations owned by Lot 14 or Lot 13, and it does not introduce a new
/// persistent Surface model. It only removes repetitive boilerplate for the
/// common case where an atlas follows the standard V0 column order.
ProjectPathPreset createStandardProjectPathPresetFromVerticalAtlas({
  required String id,
  required String name,
  required PathSurfaceKind surfaceKind,
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
  // Lot 14 owns layout validation: firstColumn/startRow bounds, non-empty
  // variant lists, and duplicate variant detection. Keeping that validation in
  // one place avoids this standard preset helper drifting from the layout helper.
  final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
    firstColumn: firstColumn,
    startRow: startRow,
    variants: variants,
  );

  // Lot 13 owns preset/frame validation and the important tileset distinction:
  // tilesetId is stored on ProjectPathPreset, while frameTilesetId is propagated
  // to each TilesetVisualFrame. This helper only forwards the caller intent.
  return createProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    columns: columns,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    frameTilesetId: frameTilesetId,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );
}
