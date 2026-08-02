import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import '../models/smart_tile_field.dart';
import 'smart_tile_cell_context.dart';
import 'smart_tile_layer_operations.dart';

SmartTileCellContext smartTileCellContextForLayerCell({
  required SmartTileLayer layer,
  required MapData map,
  required ProjectSmartTilePreset preset,
  required int x,
  required int y,
}) {
  final width = map.size.width;
  final height = map.size.height;
  if (x < 0 || y < 0 || x >= width || y >= height) {
    throw RangeError('Smart Tile cell ($x, $y) is outside $width x $height');
  }
  if (!isSmartTileFieldCompatibleWithTopology(preset.topology, layer.field)) {
    throw ArgumentError.value(
      layer.field,
      'layer.field',
      'Smart Tile field is incompatible with ${preset.topology.name}',
    );
  }

  String? cellAt(int cellX, int cellY) => smartTileMaterialIdAt(
        layer,
        mapSize: map.size,
        x: cellX,
        y: cellY,
      );

  if (preset.topology == SmartTileTopology.uniform ||
      preset.topology == SmartTileTopology.cardinal4 ||
      preset.topology == SmartTileTopology.blob8) {
    return SmartTileCellContext.fromCellGrid(
      width: width,
      height: height,
      x: x,
      y: y,
      materialAt: cellAt,
    );
  }

  SmartTileObservedSlot horizontal(int edgeX, int edgeY) =>
      SmartTileObservedSlot.inside(
        materialId: smartTileHorizontalEdgeMaterialIdAt(
          layer,
          mapSize: map.size,
          x: edgeX,
          y: edgeY,
        ),
      );
  SmartTileObservedSlot vertical(int edgeX, int edgeY) =>
      SmartTileObservedSlot.inside(
        materialId: smartTileVerticalEdgeMaterialIdAt(
          layer,
          mapSize: map.size,
          x: edgeX,
          y: edgeY,
        ),
      );
  SmartTileObservedSlot corner(int cornerX, int cornerY) =>
      SmartTileObservedSlot.inside(
        materialId: smartTileCornerMaterialIdAt(
          layer,
          mapSize: map.size,
          x: cornerX,
          y: cornerY,
        ),
      );

  final centerMaterialId = cellAt(x, y);
  return switch (preset.topology) {
    SmartTileTopology.wangEdge4 => SmartTileCellContext(
        centerMaterialId: centerMaterialId,
        observed: SmartTileObservedSignature(
          northEdge: horizontal(x, y),
          eastEdge: vertical(x + 1, y),
          southEdge: horizontal(x, y + 1),
          westEdge: vertical(x, y),
        ),
      ),
    SmartTileTopology.wangCorner4 => SmartTileCellContext(
        centerMaterialId: centerMaterialId,
        observed: SmartTileObservedSignature(
          northEastCorner: corner(x + 1, y),
          southEastCorner: corner(x + 1, y + 1),
          southWestCorner: corner(x, y + 1),
          northWestCorner: corner(x, y),
        ),
      ),
    SmartTileTopology.wang8 => SmartTileCellContext(
        centerMaterialId: centerMaterialId,
        observed: SmartTileObservedSignature(
          northEdge: horizontal(x, y),
          northEastCorner: corner(x + 1, y),
          eastEdge: vertical(x + 1, y),
          southEastCorner: corner(x + 1, y + 1),
          southEdge: horizontal(x, y + 1),
          southWestCorner: corner(x, y + 1),
          westEdge: vertical(x, y),
          northWestCorner: corner(x, y),
        ),
      ),
    SmartTileTopology.uniform ||
    SmartTileTopology.cardinal4 ||
    SmartTileTopology.blob8 =>
      throw StateError('Cell topologies are handled before lattice sampling.'),
  };
}
