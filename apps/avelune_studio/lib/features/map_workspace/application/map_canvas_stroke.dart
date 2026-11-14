import 'package:map_authoring/map_authoring_editing_core.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/map_terrain_patterns.dart';

part 'map_canvas_stroke_start.dart';
part 'map_canvas_stroke_patterns.dart';

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
    required MapWorkspaceEditingState view,
    required MapEditingCommands commands,
    required GridPos origin,
  }) => _startMapCanvasStroke(
    map: map,
    project: project,
    view: view,
    commands: commands,
    origin: origin,
  );

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
      late final SmartTilePatternApplication applied;
      try {
        applied = applySmartTilePatternGesture(
          layer,
          pattern: selectedPattern,
          mapSize: source.size,
          selection: switch (patternMode) {
            SmartTilePatternSelectionKind.stamp =>
              SmartTilePatternSelection.stamp(anchor: patternOrigin!),
            SmartTilePatternSelectionKind.line =>
              SmartTilePatternSelection.line(
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
          materialId:
              layer.usage == SmartTileUsage.path &&
                  (layer.encounterBehavior != null ||
                      layer.animationActivation ==
                          SmartTileAnimationActivation.onEnter)
              ? materialId
              : null,
        );
      } on ValidationException catch (error) {
        if (selectedPattern.construction == null &&
            selectedPattern.clippingPolicy !=
                SmartTilePatternClippingPolicy.reject) {
          rethrow;
        }
        cells.clear();
        if (!validate) return source;
        throw ValidationException(
          selectedPattern.construction == null
              ? 'Le motif entier doit tenir dans la carte.'
              : error.code == 'smart_tile.pattern.construction_out_of_bounds'
              ? 'La construction entière doit tenir dans la carte.'
              : 'Dimensions incompatibles. ${terrainPatternConstructionHint(selectedPattern)}.',
          code: error.code,
        );
      } on SmartTileGestureLimitException {
        if ((selectedPattern.construction == null &&
                selectedPattern.clippingPolicy !=
                    SmartTilePatternClippingPolicy.reject) ||
            validate) {
          rethrow;
        }
        cells.clear();
        return source;
      }
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

  bool matches(MapWorkspaceEditingState view) {
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
