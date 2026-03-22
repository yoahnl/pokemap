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

        return GestureDetector(
          onTapDown: (details) {
            final gridPos = _screenToGrid(
              details.localPosition,
              state.panOffset,
              state.zoom,
              activeMap.size,
              tileWidth,
              tileHeight,
            );
            if (gridPos == null) return;
            if (state.activeTool == EditorToolType.tilePaint) {
              notifier.paintSelectedBrushAt(
                gridPos,
                tilesetColumnsById: tilesPerRowById,
              );
              return;
            }
            if (state.activeTool == EditorToolType.eraser) {
              notifier.eraseAt(
                gridPos,
                tilesetColumnsById: tilesPerRowById,
              );
            }
          },
          onPanUpdate: (details) {
            if (state.activeTool == EditorToolType.tilePaint ||
                state.activeTool == EditorToolType.eraser) {
              final gridPos = _screenToGrid(
                details.localPosition,
                state.panOffset,
                state.zoom,
                activeMap.size,
                tileWidth,
                tileHeight,
              );
              if (gridPos != null) {
                if (state.activeTool == EditorToolType.tilePaint) {
                  notifier.paintSelectedBrushAt(
                    gridPos,
                    tilesetColumnsById: tilesPerRowById,
                  );
                } else {
                  notifier.eraseAt(
                    gridPos,
                    tilesetColumnsById: tilesPerRowById,
                  );
                }
              }
              return;
            }
            notifier.pan(details.delta);
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
      if (!layer.isVisible) continue;
      layer.map(
        tile: (tileLayer) {
          _paintTileLayer(canvas, tileLayer);
        },
        collision: (_) {},
        object: (_) {},
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

    canvas.drawRect(
      Rect.fromLTWH(0, 0, gridWidth, gridHeight),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  void _paintToolPreview(Canvas canvas) {
    final preview = toolPreview;
    if (preview == null) return;
    if (preview.mode == MapToolPreviewMode.paint) {
      _paintPaintPreview(canvas, preview);
      return;
    }
    _paintErasePreview(canvas, preview);
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
