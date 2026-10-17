import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../../features/map_workspace/application/spatial_terrain_stroke.dart';
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
    this.collision, {
    this.pattern,
    this.patternMode = SmartTilePatternSelectionKind.stamp,
    this.patternOrigin,
    this.patternStrokeId,
    this.patternErase = false,
    this.erasePatternId,
    this.atomicPatternErase = false,
  }) : preview = buffer.sourceMap;

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
    final erasingPattern =
        view.terrain != null && view.terrainPatternId != null;
    final collision =
        view.tool == StudioMapTool.collisionPaint ||
        view.tool == StudioMapTool.collisionErase;
    if (erase && map.spatialScene != null && erasingPattern) {
      final selected = view.terrainPatternFor(project, map);
      if (selected != null && _isSmallModelStamp(selected)) {
        final layers = mapPaintsFirstLayerInFront(map)
            ? map.layers
            : map.layers.reversed;
        SmartTileLayer? layer;
        for (final candidate in layers.whereType<SmartTileLayer>()) {
          if (!candidate.isVisible || candidate.presetId != view.terrain?.id) {
            continue;
          }
          final owner = _spatialPatternOwnerAt(
            layer: candidate,
            project: project,
            cell: origin,
          );
          if (owner == null) continue;
          if (owner.pattern.id != selected.id ||
              !_isSmallStampStroke(owner.pattern, owner.stroke)) {
            return null;
          }
          layer = candidate;
          break;
        }
        if (layer == null) return null;
        final stroke = MapCanvasStroke._(
          MapCellStrokeBuffer.smartTile(sourceMap: map, layerId: layer.id),
          project,
          true,
          null,
          null,
          true,
          false,
          patternErase: true,
          erasePatternId: selected.id,
          atomicPatternErase: true,
        );
        stroke.paint(origin);
        return stroke;
      }
    }
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
      final selectedSpatialPresetId = map.spatialScene != null
          ? view.terrain?.id
          : null;
      final layers = mapPaintsFirstLayerInFront(map)
          ? map.layers
          : map.layers.reversed;
      final layer = layers
          .whereType<SmartTileLayer>()
          .where(
            (item) =>
                item.isVisible &&
                (selectedSpatialPresetId == null ||
                    item.presetId == selectedSpatialPresetId) &&
                (map.spatialScene != null ||
                    !erasingPattern ||
                    item.presetId == view.terrain?.id) &&
                (smartTileMaterialIdAt(
                          item,
                          mapSize: map.size,
                          x: origin.x,
                          y: origin.y,
                        ) !=
                        null ||
                    (map.spatialScene != null || erasingPattern) &&
                        (map.spatialScene != null
                            ? _hasSpatialPatternPartAt(
                                layer: item,
                                project: project,
                                cell: origin,
                              )
                            : item.patternStrokes.any(
                                (stroke) => stroke.cells.contains(origin),
                              ))),
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
          patternErase: erasingPattern && layer.presetId == view.terrain?.id,
          erasePatternId: erasingPattern ? view.terrainPatternId : null,
        );
        stroke.paint(origin);
        return stroke;
      }
      if (selectedSpatialPresetId != null ||
          map.spatialScene == null && erasingPattern) {
        return null;
      }
    }
    final preset = view.terrain;
    if (preset != null && view.tool == StudioMapTool.terrain) {
      if (view.terrainPatternId != null) {
        final pattern = view.terrainPatternFor(project, map);
        if (pattern == null) {
          throw StateError('Ce motif n’est plus disponible pour ce terrain.');
        }
        final prepared = prepareTerrainStrokeLayer(
          map: map,
          manifest: project,
          preset: preset,
        )!;
        var suffix = 1;
        var id = 'studio-pattern-${pattern.id}-$suffix';
        while (prepared.layer.patternStrokes.any((stroke) => stroke.id == id)) {
          id = 'studio-pattern-${pattern.id}-${++suffix}';
        }
        final stroke = MapCanvasStroke._(
          MapCellStrokeBuffer.smartTile(
            sourceMap: prepared.map,
            layerId: prepared.layer.id,
          ),
          project,
          false,
          null,
          view.terrainMaterialId ?? preset.defaultMaterialId,
          true,
          false,
          pattern: pattern,
          patternMode: view.terrainPatternMode,
          patternOrigin: origin,
          patternStrokeId: id,
        );
        stroke.paint(origin);
        return stroke;
      }
      final prepared = applyTerrainStroke(
        map: map,
        manifest: project,
        preset: preset,
        cells: [origin],
        erase: false,
        materialId: view.terrainMaterialId,
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
        view.terrainMaterialId ?? preset.defaultMaterialId,
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

  static bool _hasSpatialPatternPartAt({
    required SmartTileLayer layer,
    required ProjectManifest project,
    required GridPos cell,
  }) {
    final owner = _spatialPatternOwnerAt(
      layer: layer,
      project: project,
      cell: cell,
    );
    return owner != null &&
        (smartTilePatternCellAt(
              pattern: owner.pattern,
              stroke: owner.stroke,
              cell: cell,
            )?.parts.isNotEmpty ??
            false);
  }

  static ({ProjectSmartTilePattern pattern, SmartTilePatternStroke stroke})?
  _spatialPatternOwnerAt({
    required SmartTileLayer layer,
    required ProjectManifest project,
    required GridPos cell,
  }) {
    for (final stroke in layer.patternStrokes.reversed) {
      if (!stroke.cells.contains(cell)) continue;
      final pattern = project.smartTileCatalog.patterns
          .where((pattern) => pattern.id == stroke.patternId)
          .firstOrNull;
      if (pattern == null || pattern.usage != layer.usage) continue;
      return (pattern: pattern, stroke: stroke);
    }
    return null;
  }

  static bool _isSmallModelStamp(ProjectSmartTilePattern pattern) {
    final parts = pattern.cells.expand((cell) => cell.parts);
    return pattern.repeatMode == SmartTilePatternRepeatMode.stamp &&
        pattern.width <= 8 &&
        pattern.height <= 8 &&
        pattern.width * pattern.height > 1 &&
        parts.isNotEmpty &&
        parts.every((part) => part.source is SmartTileModel3dSource);
  }

  static bool _isSmallStampStroke(
    ProjectSmartTilePattern pattern,
    SmartTilePatternStroke stroke,
  ) {
    if (stroke.cells.isEmpty ||
        stroke.cells.length > pattern.width * pattern.height) {
      return false;
    }
    var minX = stroke.cells.first.x, maxX = minX;
    var minY = stroke.cells.first.y, maxY = minY;
    for (final cell in stroke.cells) {
      if (cell.x < minX) minX = cell.x;
      if (cell.x > maxX) maxX = cell.x;
      if (cell.y < minY) minY = cell.y;
      if (cell.y > maxY) maxY = cell.y;
    }
    return maxX - minX + 1 <= pattern.width &&
        maxY - minY + 1 <= pattern.height;
  }

  final MapCellStrokeBuffer buffer;
  final ProjectManifest project;
  final bool erase;
  final TileLayerPaletteEntry? tile;
  final String? materialId;
  final bool terrain;
  final bool collision;
  final ProjectSmartTilePattern? pattern;
  final SmartTilePatternSelectionKind patternMode;
  final GridPos? patternOrigin;
  final String? patternStrokeId;
  final bool patternErase;
  final String? erasePatternId;
  final bool atomicPatternErase;
  GridPos? _patternEnd;
  MapData preview;
  final List<GridPos> cells = [];
  final Set<GridPos> _terrainCells = {};
  GridPos? _lastTerrainCell;

  void paint(GridPos cell) {
    final size = buffer.sourceMap.size;
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= size.width ||
        cell.y >= size.height) {
      buffer.breakInterpolation();
      _lastTerrainCell = null;
      return;
    }
    final revision = buffer.revision;
    if (pattern != null) {
      _patternEnd = cell;
      preview = materialize(validate: false);
      return;
    }
    if (collision) {
      buffer.setCollisions(
        origin: cell,
        patternSize: const GridSize(width: 1, height: 1),
        value: !erase,
      );
    } else if (terrain) {
      if (spatialTerrainPaint || patternErase) {
        final layer = buffer.sourceMap.layers
            .whereType<SmartTileLayer>()
            .firstWhere((layer) => layer.id == buffer.layerId);
        _terrainCells.addAll(
          compileSmartTileGestureSelection(
            layer,
            mapSize: size,
            selection: SmartTileGestureSelection.line(
              start: _lastTerrainCell ?? cell,
              end: cell,
            ),
          ),
        );
        if (_terrainCells.length > smartTileMaximumCellsPerGesture) {
          throw const SmartTileGestureLimitException(
            maximumCellCount: smartTileMaximumCellsPerGesture,
          );
        }
        _lastTerrainCell = cell;
      }
      if (!spatialTerrainPaint && !patternErase) {
        buffer.setSmartTileMaterialAt(
          origin: cell,
          materialId: erase ? null : materialId,
        );
      }
    } else {
      buffer.paintTiles(
        origin: cell,
        patternSize: const GridSize(width: 1, height: 1),
        tiles: [erase ? null : tile],
      );
    }
    if (buffer.revision != revision || spatialTerrainPaint || patternErase) {
      preview = materialize(validate: false);
    }
    if (!cells.contains(cell)) cells.add(cell);
  }

  bool get spatialTerrainPaint =>
      terrain && buffer.sourceMap.spatialScene != null;

  MapData materialize({required bool validate}) {
    if (patternErase) {
      final source = buffer.sourceMap;
      final layer = source.layers.whereType<SmartTileLayer>().firstWhere(
        (layer) => layer.id == buffer.layerId,
      );
      final next = replaceSmartTileLayer(source, layer: _erasePatterns(layer));
      if (validate) {
        MapValidator.validate(next, projectDialogueContext: project);
      }
      return next;
    }
    final selectedPattern = pattern;
    if (selectedPattern != null) {
      final source = buffer.sourceMap;
      final layer = source.layers.whereType<SmartTileLayer>().firstWhere(
        (layer) => layer.id == buffer.layerId,
      );
      final applied = applySmartTilePatternGesture(
        layer,
        pattern: selectedPattern,
        mapSize: source.size,
        selection: switch (patternMode) {
          SmartTilePatternSelectionKind.stamp =>
            SmartTilePatternSelection.stamp(anchor: patternOrigin!),
          SmartTilePatternSelectionKind.line => SmartTilePatternSelection.line(
            start: patternOrigin!,
            end: _patternEnd!,
          ),
          SmartTilePatternSelectionKind.rectangle =>
            SmartTilePatternSelection.rectangle(
              start: patternOrigin!,
              end: _patternEnd!,
            ),
        },
        strokeId: patternStrokeId!,
        materialId: layer.usage == SmartTileUsage.path &&
                (layer.encounterBehavior != null ||
                    layer.animationActivation == SmartTileAnimationActivation.onEnter)
            ? materialId : null,
      );
      cells
        ..clear()
        ..addAll(applied.affectedCells);
      final next = replaceSmartTileLayer(source, layer: applied.layer);
      if (validate) {
        MapValidator.validate(next, projectDialogueContext: project);
      }
      return next;
    }
    if (spatialTerrainPaint) {
      final source = buffer.sourceMap;
      final layer = source.layers.whereType<SmartTileLayer>().firstWhere(
        (layer) => layer.id == buffer.layerId,
      );
      final painted = applySmartTileMapMaterialGesture(
        source,
        layer: layer,
        catalog: project.smartTileCatalog,
        cells: _terrainCells,
        materialId: erase ? null : materialId,
      );
      if (validate) {
        MapValidator.validate(painted, projectDialogueContext: project);
      }
      return painted;
    }
    return buffer.commit(
      project: project,
      validate: validate ? MapDeltaValidator.validate : (_) {},
    );
  }

  MapData commit() => materialize(validate: true);

  SmartTileLayer _erasePatterns(SmartTileLayer layer) {
    if (!atomicPatternErase) {
      return eraseSmartTilePatternCells(
        layer,
        mapSize: buffer.sourceMap.size,
        cells: _terrainCells,
        clearMaterial: layer.usage == SmartTileUsage.path &&
            (layer.encounterBehavior != null ||
                layer.animationActivation == SmartTileAnimationActivation.onEnter),
      );
    }
    final strokeIds = <String>{};
    final cells = <GridPos>{};
    for (final cell in _terrainCells) {
      final owner = _spatialPatternOwnerAt(
        layer: layer,
        project: project,
        cell: cell,
      );
      if (owner == null ||
          owner.pattern.id != erasePatternId ||
          !_isSmallStampStroke(owner.pattern, owner.stroke)) {
        continue;
      }
      strokeIds.add(owner.stroke.id);
      cells.addAll(owner.stroke.cells);
      if (cells.length > smartTileMaximumCellsPerGesture) {
        throw const SmartTileGestureLimitException(
          maximumCellCount: smartTileMaximumCellsPerGesture,
        );
      }
    }
    if (strokeIds.isEmpty) return layer;
    return eraseSmartTilePatternCells(
      layer,
      mapSize: buffer.sourceMap.size,
      cells: cells,
      strokeIds: strokeIds,
      clearMaterial: layer.usage == SmartTileUsage.path &&
          (layer.encounterBehavior != null ||
              layer.animationActivation == SmartTileAnimationActivation.onEnter),
    );
  }

  bool matches(MapWorkspaceViewState view) {
    if (!terrain) return true;
    if (buffer.sourceMap.spatialScene != null &&
        view.spatialTerrainMode != SpatialTerrainMode.ground) {
      return false;
    }
    if (erase) {
      return view.tool == StudioMapTool.erase &&
          (!patternErase ||
              view.terrainPatternId == erasePatternId &&
                  view.terrain?.id ==
                      buffer.sourceMap.layers
                          .whereType<SmartTileLayer>()
                          .firstWhere((layer) => layer.id == buffer.layerId)
                          .presetId);
    }
    if (view.tool != StudioMapTool.terrain) return false;
    final preset = view.terrain;
    return preset != null &&
        preset.id ==
            buffer.sourceMap.layers
                .whereType<SmartTileLayer>()
                .firstWhere((layer) => layer.id == buffer.layerId)
                .presetId &&
        materialId == (view.terrainMaterialId ?? preset.defaultMaterialId) &&
        pattern?.id == view.terrainPatternId &&
        (pattern == null || patternMode == view.terrainPatternMode);
  }
}
