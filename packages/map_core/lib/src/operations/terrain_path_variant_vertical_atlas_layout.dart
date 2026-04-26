import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import 'path_variant_vertical_atlas_mapping.dart';

/// Standard V0 order for path variants in a vertical animation atlas.
///
/// This is deliberately an explicit list instead of [TerrainPathVariant.values].
/// The enum order is a Dart source detail, while an atlas layout is an asset
/// contract: if the enum is reordered later, existing atlas columns should not
/// silently move.
///
/// V0 keeps the current legacy variant vocabulary and uses a readable authoring
/// order: isolated tile, cardinal ends, straight segments, outer corners, inner
/// corners, tees, then cross.
const List<TerrainPathVariant> standardTerrainPathVariantVerticalAtlasOrder = [
  TerrainPathVariant.isolated,
  TerrainPathVariant.endNorth,
  TerrainPathVariant.endEast,
  TerrainPathVariant.endSouth,
  TerrainPathVariant.endWest,
  TerrainPathVariant.horizontal,
  TerrainPathVariant.vertical,
  TerrainPathVariant.cornerNE,
  TerrainPathVariant.cornerSE,
  TerrainPathVariant.cornerSW,
  TerrainPathVariant.cornerNW,
  TerrainPathVariant.innerCornerNE,
  TerrainPathVariant.innerCornerSE,
  TerrainPathVariant.innerCornerSW,
  TerrainPathVariant.innerCornerNW,
  TerrainPathVariant.teeNorth,
  TerrainPathVariant.teeEast,
  TerrainPathVariant.teeSouth,
  TerrainPathVariant.teeWest,
  TerrainPathVariant.cross,
];

/// Creates a standard column layout for [TerrainPathVariant] vertical atlases.
///
/// Each returned [PathVariantVerticalAtlasColumn] maps one variant to:
///
/// ```text
/// column = firstColumn + variantIndex
/// row    = startRow
/// ```
///
/// This helper only describes where variants live in an atlas. It intentionally
/// does not create frames, path mappings, presets, JSON, or persistent Surface
/// models. Callers can pass its result to
/// [createPathVariantMappingsFromVerticalAtlas] or
/// [createProjectPathPresetFromVerticalAtlas] when they want to build the next
/// legacy layer.
List<PathVariantVerticalAtlasColumn>
    createStandardTerrainPathVariantVerticalAtlasColumns({
  int firstColumn = 0,
  int startRow = 0,
  List<TerrainPathVariant> variants =
      standardTerrainPathVariantVerticalAtlasOrder,
}) {
  _validateStandardTerrainPathVariantVerticalAtlasLayoutParameters(
    firstColumn: firstColumn,
    startRow: startRow,
    variants: variants,
  );

  final columns = <PathVariantVerticalAtlasColumn>[];
  for (var i = 0; i < variants.length; i += 1) {
    columns.add(
      PathVariantVerticalAtlasColumn(
        variant: variants[i],
        column: firstColumn + i,
        startRow: startRow,
      ),
    );
  }

  return List.unmodifiable(columns);
}

void _validateStandardTerrainPathVariantVerticalAtlasLayoutParameters({
  required int firstColumn,
  required int startRow,
  required List<TerrainPathVariant> variants,
}) {
  if (firstColumn < 0) {
    throw const ValidationException('firstColumn must be non-negative');
  }
  if (startRow < 0) {
    throw const ValidationException('startRow must be non-negative');
  }
  if (variants.isEmpty) {
    throw const ValidationException('variants must not be empty');
  }

  final seenVariants = <TerrainPathVariant>{};
  for (final variant in variants) {
    if (!seenVariants.add(variant)) {
      throw ValidationException('Duplicate TerrainPathVariant: $variant');
    }
  }
}
