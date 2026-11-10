import 'package:map_core/map_core_domain.dart';

import 'map_canvas_stroke.dart';
import 'map_workspace_editing_state.dart';

class MapTerrainHighlight {
  MapTerrainHighlight._(this.layer, this.size, this.cells, this.original);

  static MapTerrainHighlight? resolve(
    MapData map,
    MapWorkspaceEditingState view, {
    MapCanvasStroke? stroke,
  }) {
    if (!view.highlightTerrain ||
        (view.tool != StudioMapTool.terrain &&
            view.tool != StudioMapTool.erase)) {
      return null;
    }
    final painting = stroke?.terrain == true;
    final preview = painting ? stroke!.preview : map;
    final layer = preview.layers
        .whereType<SmartTileLayer>()
        .where(
          (layer) =>
              layer.isVisible &&
              (painting
                  ? layer.id == stroke!.buffer.layerId
                  : view.terrain != null && layer.presetId == view.terrain!.id),
        )
        .firstOrNull;
    if (layer == null) return null;
    final original = map.layers
        .whereType<SmartTileLayer>()
        .where((item) => item.id == layer.id)
        .firstOrNull;
    return MapTerrainHighlight._(
      layer,
      preview.size,
      smartTileSemanticCells(layer),
      painting && original != null
          ? smartTileSemanticCells(original)
          : painting
          ? const []
          : null,
    );
  }

  final SmartTileLayer layer;
  final GridSize size;
  final List<int> cells;
  final List<int>? original;

  bool contains(int x, int y) =>
      x >= 0 &&
      y >= 0 &&
      x < size.width &&
      y < size.height &&
      cells[y * size.width + x] != 0;

  int changeAt(int x, int y) {
    final before = original;
    if (before == null) return 0;
    final index = y * size.width + x;
    final old = index < before.length ? before[index] : 0;
    final next = cells[index];
    return next == old
        ? 0
        : next == 0
        ? -1
        : 1;
  }
}
