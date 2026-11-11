import 'package:map_core/map_core_domain.dart';

int regularAtlasLocalTileId({
  required int row,
  required int column,
  required ProjectRegularAtlasTilesetSource source,
}) => row * source.columns + column;

List<TileLayerPaletteEntry>? terrainConnectionExample(
  ProjectManifest project,
  ProjectSmartTilePreset preset,
) {
  final resolver = PreparedSmartTileResolver(
    preset: preset,
    materials: project.smartTileCatalog.materials,
  );
  final result = <TileLayerPaletteEntry>[];
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 3; x++) {
      final resolution = resolver.resolve(
        context: SmartTileCellContext.fromCellGrid(
          width: 3,
          height: 3,
          x: x,
          y: y,
          materialAt: (x, y) => preset.defaultMaterialId,
        ),
        x: x,
        y: y,
      );
      if (resolution.status != SmartTileResolutionStatus.resolved ||
          resolution.parts.length != 1) {
        return null;
      }
      final part = resolution.parts.single;
      final visual = part.source;
      if (visual is! SmartTileFrameSource ||
          part.offsetX != 0 ||
          part.offsetY != 0 ||
          part.anchorX != 0 ||
          part.anchorY != 0 ||
          part.footprintWidth != 1 ||
          part.footprintHeight != 1 ||
          part.frameSampling != SmartTileFrameSampling.fullFrame) {
        return null;
      }
      final frame = visual.frame;
      final atlas = project.smartTileCatalog.atlases
          .where((value) => value.id == frame.atlasId)
          .firstOrNull;
      final source = project.tilesets
          .where((value) => value.id == atlas?.tilesetId)
          .firstOrNull
          ?.source;
      if (atlas == null ||
          source is! ProjectRegularAtlasTilesetSource ||
          frame.columnSpan != 1 ||
          frame.rowSpan != 1 ||
          frame.column >= atlas.columns ||
          frame.row >= atlas.rows ||
          frame.column >= source.columns ||
          frame.row >= source.rows ||
          atlas.originX != 0 ||
          atlas.originY != 0 ||
          atlas.marginX != source.marginX ||
          atlas.marginY != source.marginY ||
          atlas.spacingX != source.spacingX ||
          atlas.spacingY != source.spacingY ||
          atlas.cellWidth != source.tileWidth ||
          atlas.cellHeight != source.tileHeight ||
          atlas.pixelOffsetX != 0 ||
          atlas.pixelOffsetY != 0) {
        return null;
      }
      result.add(
        TileLayerPaletteEntry(
          tilesetId: atlas.tilesetId,
          localTileId: regularAtlasLocalTileId(
          row: frame.row,
          column: frame.column,
          source: source,
        ),
          transform: composeSmartTileSpriteTransforms(
            first: part.transform,
            second: resolution.transform,
          ),
        ),
      );
    }
  }
  return result;
}
