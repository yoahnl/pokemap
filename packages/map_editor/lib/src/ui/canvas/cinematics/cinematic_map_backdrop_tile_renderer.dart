import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'cinematic_map_backdrop_viewport_transform.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';

final class CinematicMapBackdropTileRenderPalette {
  const CinematicMapBackdropTileRenderPalette({
    required this.background,
    required this.border,
    required this.grid,
  });

  final Color background;
  final Color border;
  final Color grid;
}

class CinematicMapBackdropTileRenderPainter extends CustomPainter {
  const CinematicMapBackdropTileRenderPainter({
    required this.plan,
    required this.palette,
    this.paintGrid = true,
    this.paintBorder = true,
  });

  final CinematicMapBackdropTileRenderPlan plan;
  final CinematicMapBackdropTileRenderPalette palette;
  final bool paintGrid;
  final bool paintBorder;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty ||
        plan.mapWidth <= 0 ||
        plan.mapHeight <= 0 ||
        plan.pixelWidth <= 0 ||
        plan.pixelHeight <= 0) {
      return;
    }

    final frame = _fittedMapRect(size);
    canvas.save();
    canvas.clipRect(frame);
    canvas.drawRect(
      frame,
      Paint()
        ..color = palette.background
        ..style = PaintingStyle.fill,
    );

    for (final instruction in plan.instructions) {
      final tileset = plan.tilesets[instruction.tilesetId];
      final image = tileset?.image;
      if (image == null) {
        continue;
      }
      final paint = Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false;
      final opacity = instruction.opacity.clamp(0.0, 1.0).toDouble();
      if (opacity < 1) {
        paint.colorFilter = ColorFilter.mode(
          Color.fromRGBO(255, 255, 255, opacity),
          BlendMode.modulate,
        );
      }
      canvas.drawImageRect(
        image,
        instruction.sourceRect,
        _destinationRect(frame, instruction.destinationRect),
        paint,
      );
    }

    if (paintGrid) {
      _paintGrid(canvas, frame);
    }
    if (paintBorder) {
      canvas.drawRect(
        frame.deflate(0.5),
        Paint()
          ..color = palette.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();
  }

  Rect _fittedMapRect(Size size) {
    return fittedCinematicMapBackdropRect(
      availableSize: size,
      mapPixelSize: Size(plan.pixelWidth, plan.pixelHeight),
    );
  }

  Rect _destinationRect(Rect frame, Rect destinationRect) {
    final scaleX = frame.width / plan.pixelWidth;
    final scaleY = frame.height / plan.pixelHeight;
    return Rect.fromLTWH(
      frame.left + destinationRect.left * scaleX,
      frame.top + destinationRect.top * scaleY,
      destinationRect.width * scaleX,
      destinationRect.height * scaleY,
    );
  }

  void _paintGrid(Canvas canvas, Rect frame) {
    final cellWidth = frame.width / plan.mapWidth;
    final cellHeight = frame.height / plan.mapHeight;
    if (math.min(cellWidth, cellHeight) < 10) {
      return;
    }
    final gridPaint = Paint()
      ..color = palette.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (var x = 1; x < plan.mapWidth; x += 1) {
      final dx = frame.left + x * cellWidth;
      canvas.drawLine(
          Offset(dx, frame.top), Offset(dx, frame.bottom), gridPaint);
    }
    for (var y = 1; y < plan.mapHeight; y += 1) {
      final dy = frame.top + y * cellHeight;
      canvas.drawLine(
          Offset(frame.left, dy), Offset(frame.right, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CinematicMapBackdropTileRenderPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.palette != palette ||
        oldDelegate.paintGrid != paintGrid ||
        oldDelegate.paintBorder != paintBorder;
  }
}
