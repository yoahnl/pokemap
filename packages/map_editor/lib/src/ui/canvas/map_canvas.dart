import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';

class MapCanvas extends ConsumerWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final activeMap = state.activeMap;
    final settings = state.project?.settings ?? const ProjectSettings();
    final tilesetPathsById = _collectLayerTilesetPaths(activeMap, notifier);

    if (activeMap == null) {
      return const Center(child: Text('No Map Loaded'));
    }

    final tileWidth = settings.tileWidth * settings.displayScale;
    final tileHeight = settings.tileHeight * settings.displayScale;

    return FutureBuilder<Map<String, ui.Image?>>(
      future: _TilesetImageCache.loadMany(tilesetPathsById),
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
          tilesetColumnsById: tilesPerRowById,
        );
        final isStrokeEditingTool =
            state.activeTool == EditorToolType.tilePaint ||
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
              notifier.updateHoveredTile(gridPos);
            },
            child: ClipRect(
              child: CustomPaint(
                size: Size.infinite,
                painter: MapGridPainter(
                  map: activeMap,
                  zoom: state.zoom,
                  offset: state.panOffset,
                  hoveredTile: state.hoveredTile,
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
    EditorNotifier notifier,
  ) {
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    final gridWidth = map.size.width * tileWidth;
    final gridHeight = map.size.height * tileHeight;

    for (var index = map.layers.length - 1; index >= 0; index--) {
      final layer = map.layers[index];
      if (!layer.isVisible || layer is! TileLayer) continue;
      _paintTileLayer(canvas, layer);
    }
    for (var index = map.layers.length - 1; index >= 0; index--) {
      final layer = map.layers[index];
      if (!layer.isVisible || layer is! CollisionLayer) continue;
      _paintCollisionLayer(
        canvas,
        layer,
        isActive: layer.id == activeLayerId,
      );
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
    final needsOpacityLayer = layer.opacity < 1.0;
    if (needsOpacityLayer) {
      final bounds = Rect.fromLTWH(
        0,
        0,
        map.size.width * tileWidth,
        map.size.height * tileHeight,
      );
      canvas.saveLayer(
        bounds,
        Paint()..color = Colors.white.withValues(alpha: layer.opacity),
      );
    }

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

    if (needsOpacityLayer) {
      canvas.restore();
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
        previous.validity == next.validity &&
        previous.reason == next.reason &&
        listEquals(previous.tiles, next.tiles);
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
