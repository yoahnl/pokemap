import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

class CinematicMapBackdropPrimitivePalette {
  const CinematicMapBackdropPrimitivePalette({
    required this.background,
    required this.border,
    required this.grid,
    required this.tile,
    required this.terrain,
    required this.path,
    required this.surface,
    required this.object,
    required this.environment,
    required this.summary,
  });

  final Color background;
  final Color border;
  final Color grid;
  final Color tile;
  final Color terrain;
  final Color path;
  final Color surface;
  final Color object;
  final Color environment;
  final Color summary;
}

class CinematicMapBackdropVisualPrimitivesPainter extends CustomPainter {
  const CinematicMapBackdropVisualPrimitivesPainter({
    required this.mapWidth,
    required this.mapHeight,
    required this.primitives,
    required this.palette,
  });

  final int mapWidth;
  final int mapHeight;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final CinematicMapBackdropPrimitivePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (mapWidth <= 0 || mapHeight <= 0 || size.isEmpty) {
      return;
    }

    final frame = _fittedMapRect(size);
    final background = Paint()
      ..color = palette.background
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = palette.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas
      ..drawRect(frame, background)
      ..drawRect(frame, border);

    _paintGrid(canvas, frame);
    for (final primitive
        in primitives.where((primitive) => primitive.visible)) {
      _paintPrimitive(canvas, frame, primitive);
    }
  }

  Rect _fittedMapRect(Size size) {
    final horizontalScale = size.width / mapWidth;
    final verticalScale = size.height / mapHeight;
    final scale = math.min(horizontalScale, verticalScale);
    final width = mapWidth * scale;
    final height = mapHeight * scale;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );
  }

  void _paintGrid(Canvas canvas, Rect frame) {
    final cellWidth = frame.width / mapWidth;
    final cellHeight = frame.height / mapHeight;
    final cellSize = math.min(cellWidth, cellHeight);
    final grid = Paint()
      ..color = palette.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final majorGrid = Paint()
      ..color = palette.border.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    if (cellSize >= 7) {
      for (var x = 1; x < mapWidth; x++) {
        final dx = frame.left + x * cellWidth;
        canvas.drawLine(
          Offset(dx, frame.top),
          Offset(dx, frame.bottom),
          x % 5 == 0 ? majorGrid : grid,
        );
      }
      for (var y = 1; y < mapHeight; y++) {
        final dy = frame.top + y * cellHeight;
        canvas.drawLine(
          Offset(frame.left, dy),
          Offset(frame.right, dy),
          y % 5 == 0 ? majorGrid : grid,
        );
      }
    }
  }

  void _paintPrimitive(
    Canvas canvas,
    Rect frame,
    CinematicMapBackdropVisualPrimitive primitive,
  ) {
    final rect = _primitiveRect(frame, primitive);
    final opacity = primitive.opacity.clamp(0.16, 1.0).toDouble();
    final baseColor = _colorFor(primitive.kind);
    final fillPaint = Paint()
      ..color =
          baseColor.withValues(alpha: _fillAlpha(primitive.kind) * opacity)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color =
          baseColor.withValues(alpha: _strokeAlpha(primitive.kind) * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(2.2, math.max(0.8, rect.shortestSide * 0.08));

    switch (primitive.kind) {
      case CinematicMapBackdropVisualPrimitiveKind.objectAnchor:
      case CinematicMapBackdropVisualPrimitiveKind.environmentAnchor:
        final halo = rect.deflate(math.min(rect.width, rect.height) * 0.08);
        final core = rect.deflate(math.min(rect.width, rect.height) * 0.28);
        canvas
          ..drawOval(
            halo,
            Paint()
              ..color = baseColor.withValues(alpha: 0.2 * opacity)
              ..style = PaintingStyle.fill,
          )
          ..drawOval(core, fillPaint)
          ..drawOval(core, strokePaint);
      case CinematicMapBackdropVisualPrimitiveKind.layerSummary:
      case CinematicMapBackdropVisualPrimitiveKind.unsupportedLayer:
        final summaryPaint = Paint()
          ..color = _colorFor(primitive.kind).withValues(alpha: 0.16 * opacity)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, summaryPaint);
        final outlinePaint = Paint()
          ..color = _colorFor(primitive.kind).withValues(alpha: 0.5 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRect(rect.deflate(1), outlinePaint);
      case CinematicMapBackdropVisualPrimitiveKind.terrainCell:
      case CinematicMapBackdropVisualPrimitiveKind.surfaceCell:
        final inset = _cellInset(rect);
        final cellRect = rect.deflate(inset);
        canvas
          ..drawRect(cellRect, fillPaint)
          ..drawRect(cellRect, strokePaint);
      case CinematicMapBackdropVisualPrimitiveKind.tileCell:
        canvas.drawRect(rect.deflate(_cellInset(rect)), fillPaint);
      case CinematicMapBackdropVisualPrimitiveKind.pathCell:
        final inset = _cellInset(rect);
        final ribbonRect =
            rect.deflate(inset).deflate(rect.shortestSide * 0.14);
        final radius =
            Radius.circular(math.max(1, ribbonRect.shortestSide * 0.2));
        canvas
          ..drawRRect(RRect.fromRectAndRadius(ribbonRect, radius), fillPaint)
          ..drawRRect(RRect.fromRectAndRadius(ribbonRect, radius), strokePaint);
    }
  }

  Rect _primitiveRect(
    Rect frame,
    CinematicMapBackdropVisualPrimitive primitive,
  ) {
    final cellWidth = frame.width / mapWidth;
    final cellHeight = frame.height / mapHeight;
    return Rect.fromLTWH(
      frame.left + primitive.x * cellWidth,
      frame.top + primitive.y * cellHeight,
      math.max(cellWidth, cellWidth * primitive.width),
      math.max(cellHeight, cellHeight * primitive.height),
    );
  }

  Color _colorFor(CinematicMapBackdropVisualPrimitiveKind kind) {
    return switch (kind) {
      CinematicMapBackdropVisualPrimitiveKind.tileCell => palette.tile,
      CinematicMapBackdropVisualPrimitiveKind.terrainCell => palette.terrain,
      CinematicMapBackdropVisualPrimitiveKind.pathCell => palette.path,
      CinematicMapBackdropVisualPrimitiveKind.surfaceCell => palette.surface,
      CinematicMapBackdropVisualPrimitiveKind.objectAnchor => palette.object,
      CinematicMapBackdropVisualPrimitiveKind.environmentAnchor =>
        palette.environment,
      CinematicMapBackdropVisualPrimitiveKind.layerSummary ||
      CinematicMapBackdropVisualPrimitiveKind.unsupportedLayer =>
        palette.summary,
    };
  }

  double _cellInset(Rect rect) {
    final cellSize = rect.shortestSide;
    if (cellSize < 3) {
      return 0;
    }
    if (cellSize < 7) {
      return 0.4;
    }
    return math.min(1.5, cellSize * 0.12);
  }

  double _fillAlpha(CinematicMapBackdropVisualPrimitiveKind kind) {
    return switch (kind) {
      CinematicMapBackdropVisualPrimitiveKind.tileCell => 0.48,
      CinematicMapBackdropVisualPrimitiveKind.terrainCell => 0.58,
      CinematicMapBackdropVisualPrimitiveKind.pathCell => 0.78,
      CinematicMapBackdropVisualPrimitiveKind.surfaceCell => 0.7,
      CinematicMapBackdropVisualPrimitiveKind.objectAnchor ||
      CinematicMapBackdropVisualPrimitiveKind.environmentAnchor =>
        0.82,
      CinematicMapBackdropVisualPrimitiveKind.layerSummary ||
      CinematicMapBackdropVisualPrimitiveKind.unsupportedLayer =>
        0.22,
    };
  }

  double _strokeAlpha(CinematicMapBackdropVisualPrimitiveKind kind) {
    return switch (kind) {
      CinematicMapBackdropVisualPrimitiveKind.tileCell => 0.0,
      CinematicMapBackdropVisualPrimitiveKind.terrainCell => 0.54,
      CinematicMapBackdropVisualPrimitiveKind.pathCell => 0.9,
      CinematicMapBackdropVisualPrimitiveKind.surfaceCell => 0.78,
      CinematicMapBackdropVisualPrimitiveKind.objectAnchor ||
      CinematicMapBackdropVisualPrimitiveKind.environmentAnchor =>
        0.9,
      CinematicMapBackdropVisualPrimitiveKind.layerSummary ||
      CinematicMapBackdropVisualPrimitiveKind.unsupportedLayer =>
        0.5,
    };
  }

  @override
  bool shouldRepaint(
    covariant CinematicMapBackdropVisualPrimitivesPainter oldDelegate,
  ) {
    return oldDelegate.mapWidth != mapWidth ||
        oldDelegate.mapHeight != mapHeight ||
        oldDelegate.primitives != primitives ||
        oldDelegate.palette != palette;
  }
}
