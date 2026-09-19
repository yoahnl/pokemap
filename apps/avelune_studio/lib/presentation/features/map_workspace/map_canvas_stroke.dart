import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../../features/terrains/application/terrain_brush.dart';
import 'map_workspace_view_state.dart';

class MapCanvasStroke {
  MapCanvasStroke._(
    this.buffer,
    this.project,
    this.erase,
    this.tile,
    this.materialId,
    this.terrain,
  ) : preview = buffer.sourceMap;

  static MapCanvasStroke? start({
    required MapData map,
    required ProjectManifest project,
    required MapWorkspaceViewState view,
    required MapEditingCommands commands,
    required GridPos origin,
  }) {
    if (origin.x < 0 ||
        origin.y < 0 ||
        origin.x >= map.size.width ||
        origin.y >= map.size.height) {
      return null;
    }
    final erase = view.tool == StudioMapTool.erase;
    final preset = view.terrain;
    if (preset != null && (view.tool == StudioMapTool.terrain || erase)) {
      final prepared = applyTerrainStroke(
        map: map,
        manifest: project,
        preset: preset,
        cells: [origin],
        erase: erase,
      );
      final layer = prepared.layers
          .whereType<SmartTileLayer>()
          .where((layer) => layer.presetId == preset.id && layer.isVisible)
          .firstOrNull;
      if (layer == null) return null;
      final stroke = MapCanvasStroke._(
        MapCellStrokeBuffer.smartTile(sourceMap: prepared, layerId: layer.id),
        project,
        erase,
        null,
        preset.defaultMaterialId,
        true,
      );
      stroke.paint(origin);
      return stroke;
    }
    if (view.tool != StudioMapTool.paint && !erase) return null;
    if (!erase && view.tile == null) return null;
    final plan = buildMapVisualCompositionPlan(map).plan;
    final occupied = plan?.visibleTileLayersInPaintOrder.reversed
        .where(
          (layer) =>
              resolveTileLayerCell(
                layer,
                origin.y * map.size.width + origin.x,
              ) !=
              null,
        )
        .firstOrNull;
    final layer = erase && occupied != null
        ? occupied
        : commands.supportLayer(map);
    if (!map.layers.any((entry) => entry.id == layer.id)) {
      final layers = [...map.layers];
      layers.insert(
        resolveAuthoredLayerInsertIndex(map, activeLayerId: null),
        layer,
      );
      map = map.copyWith(layers: layers);
    }
    final stroke = MapCanvasStroke._(
      MapCellStrokeBuffer.tile(sourceMap: map, layerId: layer.id),
      project,
      erase,
      view.tile,
      null,
      false,
    );
    stroke.paint(origin);
    return stroke;
  }

  final MapCellStrokeBuffer buffer;
  final ProjectManifest project;
  final bool erase;
  final TileLayerPaletteEntry? tile;
  final String? materialId;
  final bool terrain;
  MapData preview;
  final List<GridPos> cells = [];

  void paint(GridPos cell) {
    final size = buffer.sourceMap.size;
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= size.width ||
        cell.y >= size.height) {
      buffer.breakInterpolation();
      return;
    }
    if (terrain) {
      final changed = buffer.setSmartTileMaterialAt(
        origin: cell,
        materialId: erase ? null : materialId,
      );
      if (changed) preview = buffer.commit(project: project, validate: (_) {});
    } else {
      buffer.paintTiles(
        origin: cell,
        patternSize: const GridSize(width: 1, height: 1),
        tiles: [erase ? null : tile],
      );
    }
    if (!cells.contains(cell)) cells.add(cell);
  }

  MapData commit() =>
      buffer.commit(project: project, validate: MapDeltaValidator.validate);
}
