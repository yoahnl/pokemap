import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton, kTertiaryButton;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/map_tool_preview.dart';
import '../../application/models/path_autotile_set.dart';
import '../../application/services/tileset_transparent_color_processor.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../../features/surface_painter/surface_layer_static_preview.dart';
import '../../features/surface_painter/surface_tile_preview_resolver.dart';
import 'entity_editor_element_visual.dart';

// Le shell du canvas garde uniquement le widget, l'interaction et la
// synchronisation des ressources. Le painter et le cache d'images vivent dans
// des part files dédiés pour rendre cette surface re-reviewable.
part 'map_canvas/map_canvas_assets.dart';
part 'map_canvas/map_grid_painter.dart';

class MapCanvas extends ConsumerStatefulWidget {
  const MapCanvas({super.key});

  @override
  ConsumerState<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends ConsumerState<MapCanvas> {
  Map<String, String> _lastTilesetPathsById = const {};
  Map<String, TilesetTransparentColor> _lastTilesetTransparentColorById =
      const {};
  Future<Map<String, ui.Image?>>? _tilesetImagesFuture;
  GridPos? _hoveredTile;

  /// Clic droit + glisser (souris Apple / macOS) ou clic molette + glisser : panoramique.
  int? _rightPanPointerId;
  int? _middlePanPointerId;

  /// Cellule de départ pour le tracé d'une zone par clic+glisser.
  GridPos? _zoneDragStart;

  Timer? _entityEditorAnimTimer;
  bool _entityEditorAnimTimerRunning = false;
  int _editorEntityAnimationMs = 0;

  void _syncEditorEntityAnimationTimer(bool needsAnimation) {
    if (needsAnimation == _entityEditorAnimTimerRunning) {
      return;
    }
    _entityEditorAnimTimerRunning = needsAnimation;
    if (needsAnimation) {
      _entityEditorAnimTimer?.cancel();
      _entityEditorAnimTimer =
          Timer.periodic(const Duration(milliseconds: 110), (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _editorEntityAnimationMs += 110;
          if (_editorEntityAnimationMs > 2000000000) {
            _editorEntityAnimationMs = 0;
          }
        });
      });
    } else {
      _entityEditorAnimTimer?.cancel();
      _entityEditorAnimTimer = null;
    }
  }

  @override
  void dispose() {
    _entityEditorAnimTimer?.cancel();
    super.dispose();
  }

  void _updateTilesetImagesFuture(
    Map<String, String> nextTilesetPathsById,
    Map<String, TilesetTransparentColor> nextTransparentColorByTilesetId,
  ) {
    if (_tilesetImagesFuture != null &&
        mapEquals(_lastTilesetPathsById, nextTilesetPathsById) &&
        mapEquals(
          _lastTilesetTransparentColorById,
          nextTransparentColorByTilesetId,
        )) {
      return;
    }
    _lastTilesetPathsById = Map<String, String>.from(nextTilesetPathsById);
    _lastTilesetTransparentColorById =
        Map<String, TilesetTransparentColor>.from(
      nextTransparentColorByTilesetId,
    );
    _tilesetImagesFuture = _TilesetImageCache.loadMany(
      _lastTilesetPathsById,
      transparentColorByTilesetId: _lastTilesetTransparentColorById,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final activeMap = state.activeMap;
    final settings = state.project?.settings ?? const ProjectSettings();
    final connectionLabelsByDirection =
        _resolveConnectionLabels(activeMap, state.project);
    final selectedPathAutotileSet = notifier.getSelectedPathAutotileSet();
    final pathAutotileSetsByPresetId = notifier.getPathAutotileSetsByPresetId();
    final terrainPresetsByType = notifier.getTerrainPresetByType();
    final tilesetPathsById = _collectLayerTilesetPaths(
      activeMap,
      notifier,
      project: state.project,
      selectedPathAutotileSet: selectedPathAutotileSet,
      pathAutotileSetsByPresetId: pathAutotileSetsByPresetId,
      terrainPresetsByType: terrainPresetsByType,
    );
    final transparentColorByTilesetId = _collectTilesetTransparentColors(
      state.project,
    );
    _updateTilesetImagesFuture(
      tilesetPathsById,
      transparentColorByTilesetId,
    );

    if (activeMap == null) {
      _rightPanPointerId = null;
      _middlePanPointerId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncEditorEntityAnimationTimer(false);
        }
      });
      return const Center(child: Text('No Map Loaded'));
    }

    final tileWidth = settings.tileWidth * settings.displayScale;
    final tileHeight = settings.tileHeight * settings.displayScale;

    return FutureBuilder<Map<String, ui.Image?>>(
      future: _tilesetImagesFuture,
      builder: (context, snapshot) {
        final tilesetImagesById = snapshot.data ?? const <String, ui.Image?>{};
        final tilesPerRowById = <String, int>{};
        if (settings.tileWidth > 0) {
          tilesetImagesById.forEach((tilesetId, image) {
            if (image == null) return;
            final columns = image.width ~/ settings.tileWidth;
            if (columns > 0) {
              tilesPerRowById[tilesetId] = columns;
            }
          });
        }
        final needsEntityAnim = mapEntitiesNeedEditorFrameAnimation(
          activeMap,
          state.project,
        );
        final needsSurfaceAnim = _surfacePresetsNeedEditorFrameAnimation(
          map: activeMap,
          project: state.project,
          pathAutotileSetsByPresetId: pathAutotileSetsByPresetId,
          terrainPresetsByType: terrainPresetsByType,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _syncEditorEntityAnimationTimer(needsEntityAnim || needsSurfaceAnim);
        });

        final toolPreview = notifier.resolveMapToolPreview(
          hoveredTile: _hoveredTile,
          tilesetColumnsById: tilesPerRowById,
        );
        final isStrokeEditingTool =
            state.activeTool == EditorToolType.tilePaint ||
                state.activeTool == EditorToolType.terrainPaint ||
                state.activeTool == EditorToolType.surfacePaint ||
                state.activeTool == EditorToolType.collisionPaint ||
                state.activeTool == EditorToolType.eraser;
        final isNpcWaypointPlacementActive =
            (state.npcWaypointPlacementEntityId?.trim().isNotEmpty ?? false);
        final isTapEditingTool = isStrokeEditingTool ||
            state.activeTool == EditorToolType.entityPlacement ||
            state.activeTool == EditorToolType.eventPlacement ||
            state.activeTool == EditorToolType.warpPlacement ||
            state.activeTool == EditorToolType.triggerPlacement ||
            state.activeTool == EditorToolType.gameplayZonePlacement;

        void applyToolAt(GridPos gridPos) {
          if (state.activeTool == EditorToolType.tilePaint) {
            notifier.paintSelectedBrushAt(
              gridPos,
              tilesetColumnsById: tilesPerRowById,
            );
            return;
          }
          if (state.activeTool == EditorToolType.terrainPaint) {
            notifier.paintTerrainAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.surfacePaint) {
            notifier.paintSurfaceAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.collisionPaint) {
            notifier.paintCollisionAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.eraser) {
            notifier.eraseAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.entityPlacement) {
            notifier.placeOrSelectEntityAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.eventPlacement) {
            notifier.placeOrSelectMapEventAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.warpPlacement) {
            notifier.placeOrSelectWarpAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.triggerPlacement) {
            notifier.placeOrSelectTriggerAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.gameplayZonePlacement) {
            notifier.placeOrSelectGameplayZoneAt(gridPos);
          }
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onMapPointerDown,
          onPointerMove: _onMapPointerMove,
          onPointerUp: _onMapPointerUp,
          onPointerCancel: _onMapPointerCancel,
          onPointerHover: (event) => _onMapPointerHover(event.localPosition),
          child: GestureDetector(
            onTapUp: (details) {
              final gridPos = _screenToGrid(
                details.localPosition,
                state.panOffset,
                state.zoom,
                activeMap.size,
                tileWidth,
                tileHeight,
              );
              if (gridPos == null) return;

              // Mode secondaire explicite: placement visuel de waypoint NPC.
              // Tant qu'il est actif, le clic map est routé vers l'ajout d'un
              // waypoint, avant d'appliquer les outils classiques.
              if (isNpcWaypointPlacementActive) {
                final handled = notifier.addNpcWaypointAt(gridPos);
                if (handled) {
                  return;
                }
              }

              if (!isTapEditingTool) return;
              if (isStrokeEditingTool) {
                notifier.beginMapStroke();
              }
              applyToolAt(gridPos);
              if (isStrokeEditingTool) {
                notifier.endMapStroke();
              }
            },
            onPanStart: (details) {
              if (state.activeTool == EditorToolType.gameplayZonePlacement) {
                final gridPos = _screenToGrid(
                  details.localPosition,
                  state.panOffset,
                  state.zoom,
                  activeMap.size,
                  tileWidth,
                  tileHeight,
                );
                if (gridPos == null) return;
                setState(() => _zoneDragStart = gridPos);
                notifier.setGameplayZoneDraftArea(
                  MapRect(
                    pos: gridPos,
                    size: const GridSize(width: 1, height: 1),
                  ),
                );
                return;
              }
              if (!isStrokeEditingTool) return;
              final gridPos = _screenToGrid(
                details.localPosition,
                state.panOffset,
                state.zoom,
                activeMap.size,
                tileWidth,
                tileHeight,
              );
              if (gridPos == null) return;
              notifier.beginMapStroke();
              applyToolAt(gridPos);
            },
            onPanUpdate: (details) {
              if (state.activeTool == EditorToolType.gameplayZonePlacement &&
                  _zoneDragStart != null) {
                final gridPos = _screenToGrid(
                  details.localPosition,
                  state.panOffset,
                  state.zoom,
                  activeMap.size,
                  tileWidth,
                  tileHeight,
                );
                if (gridPos != null) {
                  notifier.setGameplayZoneDraftArea(
                    _rectFromCorners(_zoneDragStart!, gridPos),
                  );
                }
                return;
              }
              if (!isStrokeEditingTool) return;
              final gridPos = _screenToGrid(
                details.localPosition,
                state.panOffset,
                state.zoom,
                activeMap.size,
                tileWidth,
                tileHeight,
              );
              if (gridPos != null) {
                applyToolAt(gridPos);
              }
            },
            onPanEnd: (_) {
              if (state.activeTool == EditorToolType.gameplayZonePlacement &&
                  _zoneDragStart != null) {
                setState(() => _zoneDragStart = null);
                notifier.commitGameplayZoneDraft();
                return;
              }
              if (isStrokeEditingTool) {
                notifier.endMapStroke();
              }
            },
            onPanCancel: () {
              if (state.activeTool == EditorToolType.gameplayZonePlacement &&
                  _zoneDragStart != null) {
                setState(() => _zoneDragStart = null);
                notifier.cancelGameplayZoneDraft();
                return;
              }
              if (isStrokeEditingTool) {
                notifier.endMapStroke();
              }
            },
            child: MouseRegion(
              onExit: (_) {
                if (_hoveredTile != null) {
                  setState(() {
                    _hoveredTile = null;
                  });
                }
              },
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: MapGridPainter(
                          map: activeMap,
                          zoom: state.zoom,
                          offset: state.panOffset,
                          hoveredTile: _hoveredTile,
                          activeLayerId: state.activeLayerId,
                          tileWidth: tileWidth,
                          tileHeight: tileHeight,
                          tilesetImagesById: tilesetImagesById,
                          sourceTileWidth: settings.tileWidth,
                          sourceTileHeight: settings.tileHeight,
                          tilesPerRowById: tilesPerRowById,
                          toolPreview: toolPreview,
                          warps: activeMap.warps,
                          gameplayZones: activeMap.gameplayZones,
                          gameplayZoneDraftArea: state.gameplayZoneDraftArea,
                          selectedEntityId: state.selectedEntityId,
                          selectedMapEventId: state.selectedMapEventId,
                          selectedWarpId: state.selectedWarpId,
                          selectedTriggerId: state.selectedTriggerId,
                          selectedGameplayZoneId: state.selectedGameplayZoneId,
                          selectedPlacedElementInstanceId:
                              state.selectedPlacedElementInstanceId,
                          connectionLabelsByDirection:
                              connectionLabelsByDirection,
                          selectedPathAutotileSet: selectedPathAutotileSet,
                          pathAutotileSetsByPresetId:
                              pathAutotileSetsByPresetId,
                          terrainPresetsByType: terrainPresetsByType,
                          project: state.project,
                          editorEntityAnimationMs: _editorEntityAnimationMs,
                        ),
                      ),
                    ),
                    if (isNpcWaypointPlacementActive)
                      Positioned(
                        left: 12,
                        top: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xCC1F2434),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF6ED6B5),
                              width: 1,
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              'Waypoint placement active • Click map to add',
                              style: TextStyle(
                                color: Color(0xFFEAF5F2),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onMapPointerDown(PointerDownEvent event) {
    final kind = event.kind;
    if (kind != ui.PointerDeviceKind.mouse &&
        kind != ui.PointerDeviceKind.trackpad) {
      return;
    }
    // Molette / bouton milieu (souris classique).
    if ((event.buttons & kTertiaryButton) != 0) {
      if (_middlePanPointerId != null) return;
      _middlePanPointerId = event.pointer;
      return;
    }
    // Clic droit + glisser : panoramique (comportement attendu macOS / souris Apple).
    if ((event.buttons & kSecondaryButton) != 0) {
      if (_rightPanPointerId != null) return;
      _rightPanPointerId = event.pointer;
    }
  }

  void _onMapPointerMove(PointerMoveEvent event) {
    if (event.pointer != _middlePanPointerId &&
        event.pointer != _rightPanPointerId) {
      return;
    }
    ref.read(editorNotifierProvider.notifier).pan(event.delta);
  }

  void _onMapPointerUp(PointerUpEvent event) {
    if (event.pointer == _middlePanPointerId) {
      _middlePanPointerId = null;
    }
    if (event.pointer == _rightPanPointerId) {
      _rightPanPointerId = null;
    }
  }

  void _onMapPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _middlePanPointerId) {
      _middlePanPointerId = null;
    }
    if (event.pointer == _rightPanPointerId) {
      _rightPanPointerId = null;
    }
  }

  void _onMapPointerHover(Offset localPosition) {
    final s = ref.read(editorNotifierProvider);
    final map = s.activeMap;
    final settings = s.project?.settings ?? const ProjectSettings();
    if (map == null) return;
    final tileW = settings.tileWidth * settings.displayScale;
    final tileH = settings.tileHeight * settings.displayScale;
    final gridPos = _screenToGrid(
      localPosition,
      s.panOffset,
      s.zoom,
      map.size,
      tileW,
      tileH,
    );
    if (_hoveredTile != gridPos) {
      setState(() {
        _hoveredTile = gridPos;
      });
    }
  }

  Map<String, String> _collectLayerTilesetPaths(
    MapData? map,
    EditorNotifier notifier, {
    ProjectManifest? project,
    PathAutotileSet? selectedPathAutotileSet,
    required Map<String, PathAutotileSet> pathAutotileSetsByPresetId,
    required Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType,
  }) {
    final result = <String, String>{};
    if (map != null) {
      collectTilesetIdsForEntityEditorVisuals(
        map: map,
        project: project,
        onTilesetId: (tilesetId) {
          if (result.containsKey(tilesetId)) {
            return;
          }
          final p = notifier.getTilesetAbsolutePathById(tilesetId);
          if (p != null && p.isNotEmpty) {
            result[tilesetId] = p;
          }
        },
      );
      for (final layer in map.layers) {
        if (layer is! TileLayer) continue;
        final tilesetId = layer.tilesetId?.trim();
        if (tilesetId == null || tilesetId.isEmpty) continue;
        final path = notifier.getTilesetAbsolutePathById(tilesetId);
        if (path == null || path.isEmpty) continue;
        result[tilesetId] = path;
      }
      final surfaceCatalog = project?.surfaceCatalog;
      if (surfaceCatalog != null) {
        for (final tilesetId in collectSurfaceTilePreviewTilesetIds(
          map: map,
          catalog: surfaceCatalog,
        )) {
          if (result.containsKey(tilesetId)) {
            continue;
          }
          final path = notifier.getTilesetAbsolutePathById(tilesetId);
          if (path != null && path.isNotEmpty) {
            result[tilesetId] = path;
          }
        }
      }
    }
    final brushTilesetId = notifier.getActiveBrushTilesetId();
    if (brushTilesetId != null && !result.containsKey(brushTilesetId)) {
      final brushPath = notifier.getTilesetAbsolutePathById(brushTilesetId);
      if (brushPath != null && brushPath.isNotEmpty) {
        result[brushTilesetId] = brushPath;
      }
    }
    final pathTilesetId = selectedPathAutotileSet?.tilesetId.trim();
    if (pathTilesetId != null &&
        pathTilesetId.isNotEmpty &&
        !result.containsKey(pathTilesetId)) {
      final pathTilesetPath =
          notifier.getTilesetAbsolutePathById(pathTilesetId);
      if (pathTilesetPath != null && pathTilesetPath.isNotEmpty) {
        result[pathTilesetId] = pathTilesetPath;
      }
    }
    if (selectedPathAutotileSet != null) {
      for (final frames in selectedPathAutotileSet.variants.values) {
        for (final frame in frames) {
          final frameTilesetId = frame.tilesetId.trim();
          if (frameTilesetId.isEmpty || result.containsKey(frameTilesetId)) {
            continue;
          }
          final frameTilesetPath =
              notifier.getTilesetAbsolutePathById(frameTilesetId);
          if (frameTilesetPath != null && frameTilesetPath.isNotEmpty) {
            result[frameTilesetId] = frameTilesetPath;
          }
        }
      }
    }
    for (final preset in terrainPresetsByType.values) {
      final terrainTilesetId = preset.tilesetId.trim();
      if (terrainTilesetId.isNotEmpty &&
          !result.containsKey(terrainTilesetId)) {
        final terrainTilesetPath =
            notifier.getTilesetAbsolutePathById(terrainTilesetId);
        if (terrainTilesetPath != null && terrainTilesetPath.isNotEmpty) {
          result[terrainTilesetId] = terrainTilesetPath;
        }
      }
      for (final variant in preset.variants) {
        for (final frame in variant.frames) {
          final frameTilesetId = frame.tilesetId.trim();
          if (frameTilesetId.isEmpty || result.containsKey(frameTilesetId)) {
            continue;
          }
          final frameTilesetPath =
              notifier.getTilesetAbsolutePathById(frameTilesetId);
          if (frameTilesetPath != null && frameTilesetPath.isNotEmpty) {
            result[frameTilesetId] = frameTilesetPath;
          }
        }
      }
    }
    for (final autotileSet in pathAutotileSetsByPresetId.values) {
      final tilesetId = autotileSet.tilesetId.trim();
      if (tilesetId.isNotEmpty && !result.containsKey(tilesetId)) {
        final pathTilesetPath = notifier.getTilesetAbsolutePathById(tilesetId);
        if (pathTilesetPath != null && pathTilesetPath.isNotEmpty) {
          result[tilesetId] = pathTilesetPath;
        }
      }
      for (final frames in autotileSet.variants.values) {
        for (final frame in frames) {
          final frameTilesetId = frame.tilesetId.trim();
          if (frameTilesetId.isEmpty || result.containsKey(frameTilesetId)) {
            continue;
          }
          final frameTilesetPath =
              notifier.getTilesetAbsolutePathById(frameTilesetId);
          if (frameTilesetPath != null && frameTilesetPath.isNotEmpty) {
            result[frameTilesetId] = frameTilesetPath;
          }
        }
      }
    }
    return result;
  }

  Map<String, TilesetTransparentColor> _collectTilesetTransparentColors(
    ProjectManifest? project,
  ) {
    if (project == null) {
      return const {};
    }
    return <String, TilesetTransparentColor>{
      for (final tileset in project.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
    };
  }

  bool _surfacePresetsNeedEditorFrameAnimation({
    required MapData? map,
    required ProjectManifest? project,
    required Map<String, PathAutotileSet> pathAutotileSetsByPresetId,
    required Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType,
  }) {
    final surfaceCatalog = project?.surfaceCatalog;
    if (map != null &&
        surfaceCatalog != null &&
        surfaceTilePreviewNeedsAnimation(
          map: map,
          catalog: surfaceCatalog,
        )) {
      return true;
    }
    for (final autotileSet in pathAutotileSetsByPresetId.values) {
      for (final frames in autotileSet.variants.values) {
        if (frames.length > 1) {
          return true;
        }
      }
    }
    for (final preset in terrainPresetsByType.values) {
      for (final variant in preset.variants) {
        if (variant.frames.length > 1) {
          return true;
        }
      }
    }
    return false;
  }

  Map<MapConnectionDirection, String> _resolveConnectionLabels(
    MapData? map,
    ProjectManifest? project,
  ) {
    final result = <MapConnectionDirection, String>{};
    if (map == null || project == null) {
      return result;
    }
    final projectMapById = <String, ProjectMapEntry>{
      for (final mapEntry in project.maps) mapEntry.id: mapEntry,
    };
    for (final connection in map.connections) {
      final mapEntry = projectMapById[connection.targetMapId];
      result[connection.direction] = mapEntry?.name ?? connection.targetMapId;
    }
    return result;
  }

  /// Construit un [MapRect] à partir de deux coins opposés (inclusif des deux).
  MapRect _rectFromCorners(GridPos a, GridPos b) {
    final x = math.min(a.x, b.x);
    final y = math.min(a.y, b.y);
    final w = (a.x - b.x).abs() + 1;
    final h = (a.y - b.y).abs() + 1;
    return MapRect(
      pos: GridPos(x: x, y: y),
      size: GridSize(width: w, height: h),
    );
  }

  GridPos? _screenToGrid(
    Offset screenPos,
    Offset pan,
    double zoom,
    GridSize size,
    double tileWidth,
    double tileHeight,
  ) {
    final adjustedX = (screenPos.dx - pan.dx) / zoom;
    final adjustedY = (screenPos.dy - pan.dy) / zoom;

    final tileX = (adjustedX / tileWidth).floor();
    final tileY = (adjustedY / tileHeight).floor();

    if (tileX >= 0 && tileX < size.width && tileY >= 0 && tileY < size.height) {
      return GridPos(x: tileX, y: tileY);
    }
    return null;
  }
}
