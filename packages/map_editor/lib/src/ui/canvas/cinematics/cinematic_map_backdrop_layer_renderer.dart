import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_render_pass.dart';
import 'cinematic_map_backdrop_tile_renderer.dart';

final class CinematicMapBackdropLayerRenderPainter extends CustomPainter {
  CinematicMapBackdropLayerRenderPainter({
    required this.plan,
    required this.palette,
    this.passes,
    this.paintBackground = true,
    this.paintGrid = true,
    this.paintBorder = true,
  });

  final CinematicMapBackdropLayerRenderPlan plan;
  final CinematicMapBackdropTileRenderPalette palette;
  final Set<CinematicMapBackdropRenderPass>? passes;
  final bool paintBackground;
  final bool paintGrid;
  final bool paintBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / plan.pixelWidth;
    final scaleY = size.height / plan.pixelHeight;
    if (paintBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = palette.background);
    }

    for (final instruction in plan.instructions) {
      if (passes != null && !passes!.contains(instruction.renderPass)) {
        continue;
      }
      final image = plan.tilesets[instruction.tilesetId]?.image;
      if (image == null) {
        continue;
      }
      final paint = Paint()
        ..isAntiAlias = false
        ..filterQuality = ui.FilterQuality.none;
      final opacity = instruction.opacity.clamp(0.0, 1.0).toDouble();
      if (opacity < 1) {
        paint.colorFilter = ColorFilter.mode(
          Color.fromRGBO(255, 255, 255, opacity),
          BlendMode.modulate,
        );
      }
      final destination = ui.Rect.fromLTWH(
        instruction.destinationRect.left * scaleX,
        instruction.destinationRect.top * scaleY,
        instruction.destinationRect.width * scaleX,
        instruction.destinationRect.height * scaleY,
      );
      canvas.drawImageRect(
        image,
        instruction.sourceRect,
        destination,
        paint,
      );
    }

    if (paintGrid) {
      _paintGrid(canvas, size);
    }
    if (paintBorder) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = palette.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = palette.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final cellWidth = size.width / plan.mapWidth;
    final cellHeight = size.height / plan.mapHeight;
    for (var x = 1; x < plan.mapWidth; x += 1) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 1; y < plan.mapHeight; y += 1) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CinematicMapBackdropLayerRenderPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.palette != palette ||
        oldDelegate.passes != passes ||
        oldDelegate.paintBackground != paintBackground ||
        oldDelegate.paintGrid != paintGrid ||
        oldDelegate.paintBorder != paintBorder;
  }
}
