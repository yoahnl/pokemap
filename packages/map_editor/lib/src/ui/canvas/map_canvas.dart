import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/map_tool_preview.dart';
import '../../application/models/path_autotile_set.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';

class MapCanvas extends ConsumerStatefulWidget {
  const MapCanvas({super.key});

  @override
  ConsumerState<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends ConsumerState<MapCanvas> {
  Map<String, String> _lastTilesetPathsById = const {};
  Future<Map<String, ui.Image?>>? _tilesetImagesFuture;
  GridPos? _hoveredTile;

  void _updateTilesetImagesFuture(Map<String, String> nextTilesetPathsById) {
    if (_tilesetImagesFuture != null &&
        mapEquals(_lastTilesetPathsById, nextTilesetPathsById)) {
      return;
    }
    _lastTilesetPathsById = Map<String, String>.from(nextTilesetPathsById);
    _tilesetImagesFuture = _TilesetImageCache.loadMany(_lastTilesetPathsById);
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
      selectedPathAutotileSet: selectedPathAutotileSet,
      pathAutotileSetsByPresetId: pathAutotileSetsByPresetId,
      terrainPresetsByType: terrainPresetsByType,
    );
    _updateTilesetImagesFuture(tilesetPathsById);

    if (activeMap == null) {
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
        final toolPreview = notifier.resolveMapToolPreview(
          hoveredTile: _hoveredTile,
          tilesetColumnsById: tilesPerRowById,
        );
        final isStrokeEditingTool =
            state.activeTool == EditorToolType.tilePaint ||
                state.activeTool == EditorToolType.terrainPaint ||
                state.activeTool == EditorToolType.collisionPaint ||
                state.activeTool == EditorToolType.eraser;
        final isTapEditingTool = isStrokeEditingTool ||
            state.activeTool == EditorToolType.warpPlacement;

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
          if (state.activeTool == EditorToolType.collisionPaint) {
            notifier.paintCollisionAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.eraser) {
            notifier.eraseAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.warpPlacement) {
            notifier.placeOrSelectWarpAt(gridPos);
          }
        }

        return GestureDetector(
          onTapUp: (details) {
            if (!isTapEditingTool) return;
            final gridPos = _screenToGrid(
              details.localPosition,
              state.panOffset,
              state.zoom,
              activeMap.size,
              tileWidth,
              tileHeight,
            );
            if (gridPos == null) return;
            if (isStrokeEditingTool) {
              notifier.beginMapStroke();
            }
            applyToolAt(gridPos);
            if (isStrokeEditingTool) {
              notifier.endMapStroke();
            }
          },
          onPanStart: (details) {
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
            if (isStrokeEditingTool) {
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
              return;
            }
            notifier.pan(details.delta);
          },
          onPanEnd: (_) {
            if (isStrokeEditingTool) {
              notifier.endMapStroke();
            }
          },
          onPanCancel: () {
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
            child: Listener(
              onPointerHover: (event) {
                final gridPos = _screenToGrid(
                  event.localPosition,
                  state.panOffset,
                  state.zoom,
                  activeMap.size,
                  tileWidth,
                  tileHeight,
                );
                if (_hoveredTile != gridPos) {
                  setState(() {
                    _hoveredTile = gridPos;
                  });
                }
              },
              child: ClipRect(
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
                    selectedWarpId: state.selectedWarpId,
                    connectionLabelsByDirection: connectionLabelsByDirection,
                    selectedPathAutotileSet: selectedPathAutotileSet,
                    pathAutotileSetsByPresetId: pathAutotileSetsByPresetId,
                    terrainPresetsByType: terrainPresetsByType,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, String> _collectLayerTilesetPaths(
    MapData? map,
    EditorNotifier notifier, {
    PathAutotileSet? selectedPathAutotileSet,
    required Map<String, PathAutotileSet> pathAutotileSetsByPresetId,
    required Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType,
  }) {
    final result = <String, String>{};
    if (map != null) {
      for (final layer in map.layers) {
        if (layer is! TileLayer) continue;
        final tilesetId = layer.tilesetId?.trim();
        if (tilesetId == null || tilesetId.isEmpty) continue;
        final path = notifier.getTilesetAbsolutePathById(tilesetId);
        if (path == null || path.isEmpty) continue;
        result[tilesetId] = path;
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
    for (final preset in terrainPresetsByType.values) {
      final terrainTilesetId = preset.tilesetId.trim();
      if (terrainTilesetId.isEmpty || result.containsKey(terrainTilesetId)) {
        continue;
      }
      final terrainTilesetPath =
          notifier.getTilesetAbsolutePathById(terrainTilesetId);
      if (terrainTilesetPath != null && terrainTilesetPath.isNotEmpty) {
        result[terrainTilesetId] = terrainTilesetPath;
      }
    }
    for (final autotileSet in pathAutotileSetsByPresetId.values) {
      final tilesetId = autotileSet.tilesetId.trim();
      if (tilesetId.isEmpty || result.containsKey(tilesetId)) {
        continue;
      }
      final pathTilesetPath = notifier.getTilesetAbsolutePathById(tilesetId);
      if (pathTilesetPath != null && pathTilesetPath.isNotEmpty) {
        result[tilesetId] = pathTilesetPath;
      }
    }
    return result;
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

class MapGridPainter extends CustomPainter {
  final MapData map;
  final double zoom;
  final Offset offset;
  final GridPos? hoveredTile;
  final String? activeLayerId;
  final double tileWidth;
  final double tileHeight;
  final Map<String, ui.Image?> tilesetImagesById;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final Map<String, int> tilesPerRowById;
  final MapToolPreview? toolPreview;
  final List<MapWarp> warps;
  final String? selectedWarpId;
  final Map<MapConnectionDirection, String> connectionLabelsByDirection;
  final PathAutotileSet? selectedPathAutotileSet;
  final Map<String, PathAutotileSet> pathAutotileSetsByPresetId;
  final Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType;

  MapGridPainter({
    required this.map,
    required this.zoom,
    required this.offset,
    this.hoveredTile,
    this.activeLayerId,
    required this.tileWidth,
    required this.tileHeight,
    required this.tilesetImagesById,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.tilesPerRowById,
    this.toolPreview,
    required this.warps,
    this.selectedWarpId,
    required this.connectionLabelsByDirection,
    this.selectedPathAutotileSet,
    required this.pathAutotileSetsByPresetId,
    required this.terrainPresetsByType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    final gridWidth = map.size.width * tileWidth;
    final gridHeight = map.size.height * tileHeight;

    final visibleLayers = map.layers.where((layer) => layer.isVisible).toList();

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TerrainLayer) {
        _paintTerrainLayer(canvas, layer);
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is PathLayer) {
        _paintPathLayer(canvas, layer);
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TileLayer) {
        _paintTileLayer(canvas, layer);
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is CollisionLayer) {
        _paintCollisionLayer(canvas, layer,
            isActive: layer.id == activeLayerId);
      }
    }

    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0 / zoom
      ..style = PaintingStyle.stroke;

    for (int x = 0; x <= map.size.width; x++) {
      canvas.drawLine(
        Offset(x * tileWidth, 0),
        Offset(x * tileWidth, gridHeight),
        gridPaint,
      );
    }
    for (int y = 0; y <= map.size.height; y++) {
      canvas.drawLine(
        Offset(0, y * tileHeight),
        Offset(gridWidth, y * tileHeight),
        gridPaint,
      );
    }

    if (hoveredTile != null) {
      final hoverPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          hoveredTile!.x * tileWidth,
          hoveredTile!.y * tileHeight,
          tileWidth,
          tileHeight,
        ),
        hoverPaint,
      );

      final cursorBorder = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom;

      canvas.drawRect(
        Rect.fromLTWH(
          hoveredTile!.x * tileWidth,
          hoveredTile!.y * tileHeight,
          tileWidth,
          tileHeight,
        ),
        cursorBorder,
      );
    }

    _paintToolPreview(canvas);
    _paintWarps(canvas);
    _paintConnections(canvas, gridWidth, gridHeight);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, gridWidth, gridHeight),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  void _paintWarps(Canvas canvas) {
    if (warps.isEmpty) return;
    for (final warp in warps) {
      if (warp.pos.x < 0 ||
          warp.pos.y < 0 ||
          warp.pos.x >= map.size.width ||
          warp.pos.y >= map.size.height) {
        continue;
      }
      final isSelected = warp.id == selectedWarpId;
      final rect = Rect.fromLTWH(
        warp.pos.x * tileWidth,
        warp.pos.y * tileHeight,
        tileWidth,
        tileHeight,
      );
      final fillPaint = Paint()
        ..color = (isSelected ? Colors.cyanAccent : Colors.purpleAccent)
            .withValues(alpha: isSelected ? 0.42 : 0.34)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.purpleAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 / zoom : 1.4 / zoom;
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
      final center = Offset(rect.center.dx, rect.center.dy);
      canvas.drawCircle(
        center,
        (tileWidth < tileHeight ? tileWidth : tileHeight) * 0.14,
        Paint()..color = isSelected ? Colors.white : Colors.purple.shade100,
      );
    }
  }

  void _paintConnections(
    Canvas canvas,
    double gridWidth,
    double gridHeight,
  ) {
    if (map.connections.isEmpty) {
      return;
    }
    for (final connection in map.connections) {
      final badgeRect = _connectionBadgeRect(
        connection.direction,
        gridWidth,
        gridHeight,
      );
      final fillPaint = Paint()
        ..color = const Color(0xFF13212D).withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 / zoom;
      final badge = RRect.fromRectAndRadius(
        badgeRect,
        Radius.circular(6 / zoom),
      );
      canvas.drawRRect(badge, fillPaint);
      canvas.drawRRect(badge, borderPaint);

      final label = connectionLabelsByDirection[connection.direction] ??
          connection.targetMapId;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${_directionShortLabel(connection.direction)}  $label',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: badgeRect.width - (12 / zoom));
      final textOffset = Offset(
        badgeRect.left + ((badgeRect.width - textPainter.width) / 2),
        badgeRect.top + ((badgeRect.height - textPainter.height) / 2),
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  Rect _connectionBadgeRect(
    MapConnectionDirection direction,
    double gridWidth,
    double gridHeight,
  ) {
    final inset = 8 / zoom;
    final shortSide = 22 / zoom;
    final badgeWidth = math.max(
      52 / zoom,
      math.min(gridWidth - (inset * 2), 168 / zoom),
    );
    return switch (direction) {
      MapConnectionDirection.north => Rect.fromLTWH(
          (gridWidth - badgeWidth) / 2,
          inset,
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.south => Rect.fromLTWH(
          (gridWidth - badgeWidth) / 2,
          gridHeight - inset - shortSide,
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.east => Rect.fromLTWH(
          gridWidth - inset - badgeWidth,
          (gridHeight / 2) - shortSide - (2 / zoom),
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.west => Rect.fromLTWH(
          inset,
          (gridHeight / 2) - shortSide - (2 / zoom),
          badgeWidth,
          shortSide,
        ),
    };
  }

  String _directionShortLabel(MapConnectionDirection direction) {
    return switch (direction) {
      MapConnectionDirection.north => 'N',
      MapConnectionDirection.south => 'S',
      MapConnectionDirection.east => 'E',
      MapConnectionDirection.west => 'W',
    };
  }

  void _paintToolPreview(Canvas canvas) {
    final preview = toolPreview;
    if (preview == null) return;
    if (preview.mode == MapToolPreviewMode.paint) {
      _paintPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.erase) {
      _paintErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.terrainPaint) {
      _paintTerrainPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.terrainErase) {
      _paintTerrainErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.pathPaint) {
      _paintPathPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.pathErase) {
      _paintPathErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.collisionPaint) {
      _paintCollisionPaintPreview(canvas, preview);
      return;
    }
    _paintCollisionErasePreview(canvas, preview);
  }

  void _paintPaintPreview(Canvas canvas, MapToolPreview preview) {
    final tiles = preview.tiles;
    final tilesetId = preview.tilesetId;
    if (tiles == null || tilesetId == null) return;
    final tilesetImage = tilesetImagesById[tilesetId];
    final tilesPerRow = tilesPerRowById[tilesetId] ?? 0;
    if (tilesetImage != null &&
        tilesPerRow > 0 &&
        sourceTileWidth > 0 &&
        sourceTileHeight > 0) {
      final alpha =
          preview.validity == MapToolPreviewValidity.valid ? 0.6 : 0.3;
      final tilePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
      for (var y = 0; y < preview.size.height; y++) {
        for (var x = 0; x < preview.size.width; x++) {
          final mapX = preview.origin.x + x;
          final mapY = preview.origin.y + y;
          if (mapX < 0 ||
              mapY < 0 ||
              mapX >= map.size.width ||
              mapY >= map.size.height) {
            continue;
          }
          final patternIndex = y * preview.size.width + x;
          if (patternIndex < 0 || patternIndex >= tiles.length) continue;
          final tileId = tiles[patternIndex];
          if (tileId <= 0) continue;
          final sourceIndex = tileId - 1;
          final sourceX = (sourceIndex % tilesPerRow) * sourceTileWidth;
          final sourceY = (sourceIndex ~/ tilesPerRow) * sourceTileHeight;
          if (sourceX < 0 ||
              sourceY < 0 ||
              sourceX + sourceTileWidth > tilesetImage.width ||
              sourceY + sourceTileHeight > tilesetImage.height) {
            continue;
          }
          final srcRect = Rect.fromLTWH(
            sourceX.toDouble(),
            sourceY.toDouble(),
            sourceTileWidth.toDouble(),
            sourceTileHeight.toDouble(),
          );
          final dstRect = Rect.fromLTWH(
            mapX * tileWidth,
            mapY * tileHeight,
            tileWidth,
            tileHeight,
          );
          canvas.drawImageRect(tilesetImage, srcRect, dstRect, tilePaint);
        }
      }
    }

    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    if (preview.validity == MapToolPreviewValidity.invalid) {
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / zoom,
      );
      return;
    }
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / zoom,
    );
  }

  void _paintErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintCollisionPaintPreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.orangeAccent.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.orangeAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintTerrainPaintPreview(Canvas canvas, MapToolPreview preview) {
    final terrainPresetPreviewPainted =
        _paintTerrainPresetPreview(canvas, preview);
    if (terrainPresetPreviewPainted) {
      return;
    }
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    final terrainColor = _terrainColor(preview.terrain ?? TerrainType.grass);
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = terrainColor.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = terrainColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintPathPaintPreview(Canvas canvas, MapToolPreview preview) {
    final pathPreviewPainted = _paintPathLayerPreview(canvas, preview);
    if (pathPreviewPainted) {
      return;
    }
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.tealAccent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.tealAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  bool _paintPathLayerPreview(Canvas canvas, MapToolPreview preview) {
    if (preview.size.width != 1 || preview.size.height != 1) {
      return false;
    }
    final origin = preview.origin;
    if (origin.x < 0 ||
        origin.y < 0 ||
        origin.x >= map.size.width ||
        origin.y >= map.size.height) {
      return false;
    }
    final activePathLayer = _resolveActivePathLayer();
    if (activePathLayer == null) {
      return false;
    }
    final autotileSet = _resolvePreviewPathAutotileSet(activePathLayer);
    if (autotileSet == null) {
      return false;
    }
    final tilesetId = autotileSet.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null || sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }

    final expectedLength = map.size.width * map.size.height;
    final simulatedCells = List<bool>.filled(
      expectedLength,
      false,
      growable: false,
    );
    final sourceCells = activePathLayer.cells;
    final copyLength = sourceCells.length < expectedLength
        ? sourceCells.length
        : expectedLength;
    for (var index = 0; index < copyLength; index++) {
      simulatedCells[index] = sourceCells[index];
    }
    final previewIndex = origin.y * map.size.width + origin.x;
    if (previewIndex < 0 || previewIndex >= simulatedCells.length) {
      return false;
    }
    simulatedCells[previewIndex] = true;

    final variant = resolvePathVariantAt(
      cells: simulatedCells,
      mapSize: map.size,
      pos: origin,
    );
    final dstRect = Rect.fromLTWH(
      origin.x * tileWidth,
      origin.y * tileHeight,
      tileWidth,
      tileHeight,
    );
    final painted = _paintAutotileVariantCell(
      canvas,
      autotileSet: autotileSet,
      tilesetImage: tilesetImage,
      variant: variant,
      dstRect: dstRect,
      alpha: 0.66,
    );
    if (!painted) {
      return false;
    }
    canvas.drawRect(
      dstRect,
      Paint()
        ..color = Colors.tealAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
    return true;
  }

  bool _paintTerrainPresetPreview(Canvas canvas, MapToolPreview preview) {
    final terrain = preview.terrain;
    if (terrain == null || terrain == TerrainType.none) {
      return false;
    }
    final preset = terrainPresetsByType[terrain];
    if (preset == null || preset.variants.isEmpty) {
      return false;
    }
    final tilesetId = preset.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null || sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.62);
    var rendered = false;
    for (var y = 0; y < preview.size.height; y++) {
      for (var x = 0; x < preview.size.width; x++) {
        final mapX = preview.origin.x + x;
        final mapY = preview.origin.y + y;
        if (mapX < 0 ||
            mapY < 0 ||
            mapX >= map.size.width ||
            mapY >= map.size.height) {
          continue;
        }
        final sourceTile = _resolveTerrainPresetSourceTile(
          preset: preset,
          x: mapX,
          y: mapY,
        );
        if (sourceTile == null) continue;
        final sourceX = sourceTile.dx * sourceTileWidth;
        final sourceY = sourceTile.dy * sourceTileHeight;
        if (sourceX < 0 ||
            sourceY < 0 ||
            sourceX + sourceTileWidth > tilesetImage.width ||
            sourceY + sourceTileHeight > tilesetImage.height) {
          continue;
        }
        canvas.drawImageRect(
          tilesetImage,
          Rect.fromLTWH(
            sourceX.toDouble(),
            sourceY.toDouble(),
            sourceTileWidth.toDouble(),
            sourceTileHeight.toDouble(),
          ),
          Rect.fromLTWH(
            mapX * tileWidth,
            mapY * tileHeight,
            tileWidth,
            tileHeight,
          ),
          paint,
        );
        rendered = true;
      }
    }
    if (!rendered) return false;
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect != null) {
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 / zoom,
      );
    }
    return true;
  }

  void _paintTerrainErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.blueGrey.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.blueGrey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintPathErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintCollisionErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.lightBlueAccent.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.lightBlueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  Rect? _computePreviewRect(GridPos origin, GridSize size) {
    final left = origin.x.clamp(0, map.size.width);
    final top = origin.y.clamp(0, map.size.height);
    final right = (origin.x + size.width).clamp(0, map.size.width);
    final bottom = (origin.y + size.height).clamp(0, map.size.height);
    if (right <= left || bottom <= top) return null;
    return Rect.fromLTWH(
      left * tileWidth,
      top * tileHeight,
      (right - left) * tileWidth,
      (bottom - top) * tileHeight,
    );
  }

  void _paintTileLayer(Canvas canvas, TileLayer layer) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return;
    }
    final layerTilesetId = layer.tilesetId?.trim();
    if (layerTilesetId == null || layerTilesetId.isEmpty) {
      return;
    }
    final tilesetImage = tilesetImagesById[layerTilesetId];
    final tilesPerRow = tilesPerRowById[layerTilesetId] ?? 0;
    if (tilesetImage == null || tilesPerRow <= 0) {
      return;
    }

    final layerPaint = Paint();

    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final tileIndex = rowStart + x;
        if (tileIndex < 0 || tileIndex >= layer.tiles.length) continue;
        final tileId = layer.tiles[tileIndex];
        if (tileId <= 0) continue;

        final sourceIndex = tileId - 1;
        final sourceX = (sourceIndex % tilesPerRow) * sourceTileWidth;
        final sourceY = (sourceIndex ~/ tilesPerRow) * sourceTileHeight;

        if (sourceX < 0 ||
            sourceY < 0 ||
            sourceX + sourceTileWidth > tilesetImage.width ||
            sourceY + sourceTileHeight > tilesetImage.height) {
          continue;
        }

        final srcRect = Rect.fromLTWH(
          sourceX.toDouble(),
          sourceY.toDouble(),
          sourceTileWidth.toDouble(),
          sourceTileHeight.toDouble(),
        );
        final dstRect = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawImageRect(tilesetImage, srcRect, dstRect, layerPaint);
      }
    }
  }

  void _paintCollisionLayer(
    Canvas canvas,
    CollisionLayer layer, {
    required bool isActive,
  }) {
    if (layer.collisions.isEmpty) return;
    final fillAlpha = (isActive ? 0.34 : 0.24) * layer.opacity;
    final borderAlpha = (isActive ? 0.75 : 0.5) * layer.opacity;
    final fillPaint = Paint()
      ..color = Colors.deepOrange.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.deepOrangeAccent.withValues(alpha: borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / zoom;

    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.collisions.length) continue;
        if (!layer.collisions[index]) continue;
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawRect(cell, fillPaint);
        canvas.drawRect(cell, borderPaint);
      }
    }
  }

  void _paintTerrainLayer(Canvas canvas, TerrainLayer layer) {
    if (layer.terrains.isEmpty) return;
    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.terrains.length) continue;
        final terrain = layer.terrains[index];
        if (terrain == TerrainType.none) {
          continue;
        }
        final terrainPresetDrawn = _paintTerrainPresetCell(
          canvas,
          terrain,
          x: x,
          y: y,
          alpha: 1.0,
        );
        if (terrainPresetDrawn) {
          continue;
        }
        final fillColor = _terrainColor(terrain);
        final borderColor = _terrainBorderColor(terrain);
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = fillColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 / zoom,
        );
      }
    }
  }

  void _paintPathLayer(Canvas canvas, PathLayer layer) {
    if (layer.cells.isEmpty) return;
    const pathCellAlpha = 1.0;
    final autotileSet = _resolvePathAutotileSetForLayer(layer);
    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.cells.length) continue;
        if (!layer.cells[index]) continue;
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        final pathDrawn = autotileSet == null
            ? false
            : _paintPathLayerCell(
                canvas,
                layer,
                autotileSet: autotileSet,
                x: x,
                y: y,
                alpha: pathCellAlpha,
              );
        if (pathDrawn) {
          continue;
        }
        canvas.drawRect(
          cell,
          Paint()
            ..color = Colors.teal
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = Colors.tealAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 / zoom,
        );
      }
    }
  }

  bool _paintPathLayerCell(
    Canvas canvas,
    PathLayer layer, {
    required PathAutotileSet autotileSet,
    required int x,
    required int y,
    required double alpha,
  }) {
    final tilesetId = autotileSet.tilesetId.trim();
    if (tilesetId.isEmpty) return false;
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null || sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }

    final variant = resolvePathVariantAt(
      cells: layer.cells,
      mapSize: map.size,
      pos: GridPos(x: x, y: y),
    );
    final dstRect = Rect.fromLTWH(
      x * tileWidth,
      y * tileHeight,
      tileWidth,
      tileHeight,
    );
    return _paintAutotileVariantCell(
      canvas,
      autotileSet: autotileSet,
      tilesetImage: tilesetImage,
      variant: variant,
      dstRect: dstRect,
      alpha: alpha,
    );
  }

  bool _paintAutotileVariantCell(
    Canvas canvas, {
    required PathAutotileSet autotileSet,
    required ui.Image tilesetImage,
    required TerrainPathVariant variant,
    required Rect dstRect,
    required double alpha,
  }) {
    final source = autotileSet.sourceForVariant(variant);
    if (source == null) return false;

    final sourceX = source.x * sourceTileWidth;
    final sourceY = source.y * sourceTileHeight;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceX + sourceTileWidth > tilesetImage.width ||
        sourceY + sourceTileHeight > tilesetImage.height) {
      return false;
    }

    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      sourceTileWidth.toDouble(),
      sourceTileHeight.toDouble(),
    );
    canvas.drawImageRect(
      tilesetImage,
      srcRect,
      dstRect,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  bool _paintTerrainPresetCell(
    Canvas canvas,
    TerrainType terrain, {
    required int x,
    required int y,
    required double alpha,
  }) {
    final preset = terrainPresetsByType[terrain];
    if (preset == null || preset.variants.isEmpty) {
      return false;
    }
    final tilesetId = preset.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null || sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }
    final sourceTile = _resolveTerrainPresetSourceTile(
      preset: preset,
      x: x,
      y: y,
    );
    if (sourceTile == null) return false;
    final sourceX = sourceTile.dx * sourceTileWidth;
    final sourceY = sourceTile.dy * sourceTileHeight;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceX + sourceTileWidth > tilesetImage.width ||
        sourceY + sourceTileHeight > tilesetImage.height) {
      return false;
    }

    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      sourceTileWidth.toDouble(),
      sourceTileHeight.toDouble(),
    );
    final dstRect = Rect.fromLTWH(
      x * tileWidth,
      y * tileHeight,
      tileWidth,
      tileHeight,
    );
    canvas.drawImageRect(
      tilesetImage,
      srcRect,
      dstRect,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  Offset? _resolveTerrainPresetSourceTile({
    required ProjectTerrainPreset preset,
    required int x,
    required int y,
  }) {
    final variants = preset.variants;
    if (variants.isEmpty) return null;
    var totalWeight = 0;
    for (final variant in variants) {
      totalWeight += variant.weight <= 0 ? 1 : variant.weight;
    }
    if (totalWeight <= 0) return null;

    final seed = _stableCellSeed(x: x, y: y, salt: preset.id.hashCode);
    var selectedWeight = seed % totalWeight;
    TerrainPresetVariant chosen = variants.first;
    for (final variant in variants) {
      final weight = variant.weight <= 0 ? 1 : variant.weight;
      if (selectedWeight < weight) {
        chosen = variant;
        break;
      }
      selectedWeight -= weight;
    }

    final width = chosen.source.width <= 0 ? 1 : chosen.source.width;
    final height = chosen.source.height <= 0 ? 1 : chosen.source.height;
    final cellSeed = _stableCellSeed(
      x: x,
      y: y,
      salt: chosen.source.x * 73856093 + chosen.source.y * 19349663,
    );
    final tileIndex = cellSeed % (width * height);
    final offsetX = tileIndex % width;
    final offsetY = tileIndex ~/ width;
    return Offset(
      (chosen.source.x + offsetX).toDouble(),
      (chosen.source.y + offsetY).toDouble(),
    );
  }

  int _stableCellSeed({
    required int x,
    required int y,
    required int salt,
  }) {
    final raw = ((x + 1) * 73856093) ^ ((y + 1) * 19349663) ^ salt;
    return raw & 0x7fffffff;
  }

  PathLayer? _resolveActivePathLayer() {
    final id = activeLayerId;
    if (id == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == id && layer is PathLayer) {
        return layer;
      }
    }
    return null;
  }

  PathAutotileSet? _resolvePathAutotileSetForLayer(PathLayer layer) {
    final presetId = layer.presetId.trim();
    if (presetId.isEmpty) {
      return null;
    }
    return pathAutotileSetsByPresetId[presetId];
  }

  PathAutotileSet? _resolvePreviewPathAutotileSet(PathLayer layer) {
    final assigned = _resolvePathAutotileSetForLayer(layer);
    if (assigned != null) {
      return assigned;
    }
    return selectedPathAutotileSet;
  }

  Color _terrainColor(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => Colors.transparent,
      TerrainType.grass => Colors.lightGreenAccent,
      TerrainType.dirt => const Color(0xFFA46E3D),
      TerrainType.sand => Colors.amberAccent,
      TerrainType.rock => Colors.blueGrey,
      TerrainType.stone => Colors.grey,
      TerrainType.indoor => const Color(0xFFD8C3A5),
    };
  }

  Color _terrainBorderColor(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.grass:
        return Colors.green.shade900;
      case TerrainType.dirt:
        return const Color(0xFF6D4524);
      case TerrainType.sand:
        return Colors.orange.shade900;
      case TerrainType.rock:
        return Colors.blueGrey.shade900;
      case TerrainType.stone:
        return Colors.grey.shade800;
      case TerrainType.indoor:
        return const Color(0xFF8D6E63);
      case TerrainType.none:
        return Colors.transparent;
    }
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.hoveredTile != hoveredTile ||
        oldDelegate.activeLayerId != activeLayerId ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        !_sameToolPreview(oldDelegate.toolPreview, toolPreview) ||
        oldDelegate.selectedWarpId != selectedWarpId ||
        !listEquals(oldDelegate.warps, warps) ||
        !_samePathAutotileSet(
          oldDelegate.selectedPathAutotileSet,
          selectedPathAutotileSet,
        ) ||
        !mapEquals(
          oldDelegate.connectionLabelsByDirection,
          connectionLabelsByDirection,
        ) ||
        !_samePathAutotileSetsByPresetId(
          oldDelegate.pathAutotileSetsByPresetId,
          pathAutotileSetsByPresetId,
        ) ||
        !mapEquals(oldDelegate.terrainPresetsByType, terrainPresetsByType) ||
        !mapEquals(oldDelegate.tilesetImagesById, tilesetImagesById) ||
        oldDelegate.sourceTileWidth != sourceTileWidth ||
        oldDelegate.sourceTileHeight != sourceTileHeight ||
        !mapEquals(oldDelegate.tilesPerRowById, tilesPerRowById);
  }

  bool _sameToolPreview(MapToolPreview? previous, MapToolPreview? next) {
    if (identical(previous, next)) return true;
    if (previous == null || next == null) return previous == next;
    return previous.mode == next.mode &&
        previous.origin == next.origin &&
        previous.size == next.size &&
        previous.tilesetId == next.tilesetId &&
        previous.terrain == next.terrain &&
        previous.validity == next.validity &&
        previous.reason == next.reason &&
        listEquals(previous.tiles, next.tiles);
  }

  bool _samePathAutotileSet(PathAutotileSet? previous, PathAutotileSet? next) {
    if (identical(previous, next)) return true;
    if (previous == null || next == null) return previous == next;
    if (previous.id != next.id) return false;
    if (previous.tilesetId != next.tilesetId) return false;
    if (previous.variants.length != next.variants.length) return false;
    for (final entry in previous.variants.entries) {
      final other = next.variants[entry.key];
      if (other != entry.value) return false;
    }
    return true;
  }

  bool _samePathAutotileSetsByPresetId(
    Map<String, PathAutotileSet> previous,
    Map<String, PathAutotileSet> next,
  ) {
    if (previous.length != next.length) {
      return false;
    }
    for (final entry in previous.entries) {
      if (!_samePathAutotileSet(entry.value, next[entry.key])) {
        return false;
      }
    }
    return true;
  }
}

class _TilesetImageCache {
  static final Map<String, Future<ui.Image?>> _cache = {};

  static Future<ui.Image?> load(String? path) {
    if (path == null || path.isEmpty) return Future.value(null);
    return _cache.putIfAbsent(path, () async {
      try {
        final file = File(path);
        if (!await file.exists()) return null;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return null;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        return null;
      }
    });
  }

  static Future<Map<String, ui.Image?>> loadMany(Map<String, String> paths) {
    final futures = <Future<MapEntry<String, ui.Image?>>>[];
    paths.forEach((tilesetId, path) {
      futures.add(
        load(path).then((image) => MapEntry(tilesetId, image)),
      );
    });
    return Future.wait(futures).then((entries) {
      final result = <String, ui.Image?>{};
      for (final entry in entries) {
        result[entry.key] = entry.value;
      }
      return result;
    });
  }
}
