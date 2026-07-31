import 'package:flutter/material.dart';

import '../application/smart_tile_grid_detector.dart';
import '../application/smart_tile_guide_placement.dart';

/// Paints every automatically associated atlas cell and its human number.
class SmartTileGuideOverlayPainter extends CustomPainter {
  const SmartTileGuideOverlayPainter({
    required this.geometry,
    required this.placement,
    required this.fillColor,
    required this.borderColor,
    required this.anchorColor,
    required this.textColor,
  });

  final SmartTileGridGeometry geometry;
  final SmartTileGuidePlacementResult placement;
  final Color fillColor;
  final Color borderColor;
  final Color anchorColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (!placement.isValid) return;
    final scaleX = size.width / geometry.imageWidth;
    final scaleY = size.height / geometry.imageHeight;
    final stepX = (geometry.cellWidth + geometry.spacingX) * scaleX;
    final stepY = (geometry.cellHeight + geometry.spacingY) * scaleY;
    final width = geometry.cellWidth * scaleX;
    final height = geometry.cellHeight * scaleY;
    final originX = (geometry.originX + geometry.marginX) * scaleX;
    final originY = (geometry.originY + geometry.marginY) * scaleY;

    for (final frame in placement.frames) {
      final rect = Rect.fromLTWH(
        originX + frame.column * stepX,
        originY + frame.row * stepY,
        width,
        height,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = frame.guideCell.number == 1 ? anchorColor : fillColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = false,
      );
      canvas.drawRect(
        rect.deflate(0.5),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = false,
      );
      final label = TextPainter(
        text: TextSpan(
          text: '${frame.guideCell.number}',
          style: TextStyle(
            color: textColor,
            fontSize: (height * 0.42).clamp(8, 16),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      label.paint(
        canvas,
        Offset(
          rect.center.dx - label.width / 2,
          rect.center.dy - label.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SmartTileGuideOverlayPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.placement != placement ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.anchorColor != anchorColor ||
      oldDelegate.textColor != textColor;
}
