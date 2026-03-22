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
        final activeBrushTilesetId = notifier.getActiveBrushTilesetId();
        final activeBrushTilesetColumns = activeBrushTilesetId == null
            ? 0
            : (tilesPerRowById[activeBrushTilesetId] ?? 0);

        return GestureDetector(
          onTapDown: (details) {
            if (state.activeTool != EditorToolType.tilePaint) return;
            final gridPos = _screenToGrid(
              details.localPosition,
              state.panOffset,
              state.zoom,
              activeMap.size,
              tileWidth,
              tileHeight,
            );
            if (gridPos != null) {
              notifier.paintSelectedBrushAt(
                gridPos,
                tilesetColumns: activeBrushTilesetColumns,
              );
            }
          },
          onPanUpdate: (details) {
            if (state.activeTool == EditorToolType.tilePaint) {
              final gridPos = _screenToGrid(
                details.localPosition,
                state.panOffset,
                state.zoom,
                activeMap.size,
                tileWidth,
                tileHeight,
              );
              if (gridPos != null) {
                notifier.paintSelectedBrushAt(
                  gridPos,
                  tilesetColumns: activeBrushTilesetColumns,
                );
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    final gridWidth = map.size.width * tileWidth;
    final gridHeight = map.size.height * tileHeight;

    for (final layer in map.layers) {
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

    canvas.drawRect(
      Rect.fromLTWH(0, 0, gridWidth, gridHeight),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
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
        !mapEquals(oldDelegate.tilesetImagesById, tilesetImagesById) ||
        oldDelegate.sourceTileWidth != sourceTileWidth ||
        oldDelegate.sourceTileHeight != sourceTileHeight ||
        !mapEquals(oldDelegate.tilesPerRowById, tilesPerRowById);
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
