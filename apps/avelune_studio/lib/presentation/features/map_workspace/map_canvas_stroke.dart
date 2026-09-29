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
    this.collision,
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
    final collision =
        view.tool == StudioMapTool.collisionPaint ||
        view.tool == StudioMapTool.collisionErase;
    if (collision) {
      var prepared = map;
      var layer = prepared.layers
          .whereType<CollisionLayer>()
          .where((item) => item.isVisible)
          .lastOrNull;
      if (layer == null && view.tool == StudioMapTool.collisionErase) {
        return null;
      }
      if (layer == null) {
        var id = 'studio-collisions';
        var suffix = 1;
        while (prepared.layers.any((item) => item.id == id)) {
          id = 'studio-collisions-${suffix++}';
        }
        prepared = addMapLayer(
          prepared,
          kind: MapLayerKind.collision,
          id: id,
          name: 'Collisions',
        );
        layer = prepared.layers.whereType<CollisionLayer>().last;
      }
      final stroke = MapCanvasStroke._(
        MapCellStrokeBuffer.collision(sourceMap: prepared, layerId: layer.id),
        project,
        view.tool == StudioMapTool.collisionErase,
        null,
        null,
        false,
        true,
      );
      stroke.paint(origin);
      return stroke;
    }
    if (erase) {
      final layer = map.layers.reversed
          .whereType<SmartTileLayer>()
          .where(
            (item) =>
                item.isVisible &&
                smartTileMaterialIdAt(
                      item,
                      mapSize: map.size,
                      x: origin.x,
                      y: origin.y,
                    ) !=
                    null,
          )
          .firstOrNull;
      if (layer != null) {
        final stroke = MapCanvasStroke._(
          MapCellStrokeBuffer.smartTile(sourceMap: map, layerId: layer.id),
          project,
          true,
          null,
          null,
          true,
          false,
        );
        stroke.paint(origin);
        return stroke;
      }
    }
    final preset = view.terrain;
    if (preset != null && view.tool == StudioMapTool.terrain) {
      final prepared = applyTerrainStroke(
        map: map,
        manifest: project,
        preset: preset,
        cells: [origin],
        erase: false,
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
        false,
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
    if (erase && occupied == null) return null;
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
  final bool collision;
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
    final revision = buffer.revision;
    if (collision) {
      buffer.setCollisions(
        origin: cell,
        patternSize: const GridSize(width: 1, height: 1),
        value: !erase,
      );
    } else if (terrain) {
      buffer.setSmartTileMaterialAt(
        origin: cell,
        materialId: erase ? null : materialId,
      );
    } else {
      buffer.paintTiles(
        origin: cell,
        patternSize: const GridSize(width: 1, height: 1),
        tiles: [erase ? null : tile],
      );
    }
    if (buffer.revision != revision) {
      preview = buffer.commit(project: project, validate: (_) {});
    }
    if (!cells.contains(cell)) cells.add(cell);
  }

  MapData commit() =>
      buffer.commit(project: project, validate: MapDeltaValidator.validate);
}
