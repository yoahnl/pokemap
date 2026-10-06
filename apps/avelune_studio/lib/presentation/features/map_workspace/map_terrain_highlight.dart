import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'map_canvas_stroke.dart';
import 'map_workspace_view_state.dart';

class MapTerrainHighlight {
  MapTerrainHighlight._(this.layer, this.size, this.cells, this.original);

  static MapTerrainHighlight? resolve(
    MapData map,
    MapWorkspaceViewState view, {
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

class MapTerrainHighlightPainter extends CustomPainter {
  MapTerrainHighlightPainter({
    required this.highlight,
    required this.tile,
    required this.color,
    required this.addition,
    required this.removal,
    required this.background,
    required this.dimOthers,
    required this.transform,
  }) : super(repaint: transform);

  final MapTerrainHighlight highlight;
  final Size tile;
  final Color color, addition, removal, background;
  final bool dimOthers;
  final TransformationController transform;

  @override
  void paint(Canvas canvas, Size size) {
    final clip = canvas.getLocalClipBounds();
    final left = math.max(0, (clip.left / tile.width).floor());
    final top = math.max(0, (clip.top / tile.height).floor());
    final right = math.min(
      highlight.size.width,
      (clip.right / tile.width).ceil(),
    );
    final bottom = math.min(
      highlight.size.height,
      (clip.bottom / tile.height).ceil(),
    );
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / transform.value.entry(0, 0).abs().clamp(.15, 8);
    final fill = Paint()..color = color.withValues(alpha: .09);
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final rect = Rect.fromLTWH(
          x * tile.width,
          y * tile.height,
          tile.width,
          tile.height,
        );
        if (highlight.contains(x, y)) {
          canvas.drawRect(rect, fill);
          if (!highlight.contains(x, y - 1)) {
            canvas.drawLine(rect.topLeft, rect.topRight, line);
          }
          if (!highlight.contains(x + 1, y)) {
            canvas.drawLine(rect.topRight, rect.bottomRight, line);
          }
          if (!highlight.contains(x, y + 1)) {
            canvas.drawLine(rect.bottomRight, rect.bottomLeft, line);
          }
          if (!highlight.contains(x - 1, y)) {
            canvas.drawLine(rect.bottomLeft, rect.topLeft, line);
          }
        } else if (dimOthers) {
          canvas.drawRect(
            rect,
            Paint()..color = background.withValues(alpha: .4),
          );
        }
        final change = highlight.changeAt(x, y);
        if (change != 0) {
          _paintChange(
            canvas,
            rect,
            change > 0 ? addition : removal,
            change > 0,
          );
        }
      }
    }
  }

  void _paintChange(Canvas canvas, Rect rect, Color color, bool adding) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: .2));
    for (double offset = -rect.height; offset < rect.width; offset += 8) {
      canvas.drawLine(
        Offset(rect.left + offset, rect.bottom),
        Offset(rect.left + offset + rect.height, rect.top),
        paint,
      );
    }
    if (!adding) {
      canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
      canvas.drawLine(rect.topRight, rect.bottomLeft, paint);
    }
    canvas.restore();
    canvas.drawRect(rect.deflate(.75), paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(MapTerrainHighlightPainter oldDelegate) =>
      highlight != oldDelegate.highlight ||
      dimOthers != oldDelegate.dimOthers ||
      tile != oldDelegate.tile ||
      color != oldDelegate.color ||
      addition != oldDelegate.addition ||
      removal != oldDelegate.removal ||
      background != oldDelegate.background;
}
