import 'package:flutter/material.dart';

import '../../theme/studio_tokens.dart';

class TerrainPatternGuide extends StatelessWidget {
  const TerrainPatternGuide({super.key, required this.rule});

  final int rule;

  @override
  Widget build(BuildContext context) {
    final colors = StudioColors.of(context);
    return SizedBox.square(
      dimension: 55,
      child: CustomPaint(
        painter: _TerrainPatternPainter(rule, colors.warning, colors.success),
      ),
    );
  }
}

class _TerrainPatternPainter extends CustomPainter {
  const _TerrainPatternPainter(this.rule, this.pathColor, this.groundColor);

  final int rule;
  final Color pathColor, groundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & Size.square(side),
        Radius.circular(side * .1),
      ),
      Paint()..color = groundColor.withValues(alpha: .35),
    );
    if (rule >= 16) {
      canvas.drawRect(
        Offset.zero & Size.square(side),
        Paint()..color = pathColor.withValues(alpha: .86),
      );
      canvas.save();
      canvas.translate(side / 2, side / 2);
      canvas.rotate((const [0, 1, 3, 2][rule - 16]) * 1.5707963267948966);
      canvas.translate(-side / 2, -side / 2);
      final corner = Path()
        ..moveTo(0, 0)
        ..lineTo(side * .62, 0)
        ..quadraticBezierTo(side * .58, side * .58, 0, side * .62)
        ..close();
      canvas.drawPath(corner, Paint()..color = groundColor);
      canvas.drawPath(
        corner,
        Paint()
          ..color = pathColor.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * .07,
      );
      canvas.restore();
      return;
    }
    final padding = side * .26;
    final center = Rect.fromLTWH(
      padding,
      padding,
      side - padding * 2,
      side - padding * 2,
    );
    var shape = Path()..addRect(center);
    if (rule & 1 != 0) {
      shape = Path.combine(
        PathOperation.union,
        shape,
        Path()..addRect(Rect.fromLTWH(padding, 0, side - padding * 2, padding)),
      );
    }
    if (rule & 2 != 0) {
      shape = Path.combine(
        PathOperation.union,
        shape,
        Path()..addRect(
          Rect.fromLTWH(side - padding, padding, padding, side - padding * 2),
        ),
      );
    }
    if (rule & 4 != 0) {
      shape = Path.combine(
        PathOperation.union,
        shape,
        Path()..addRect(
          Rect.fromLTWH(padding, side - padding, side - padding * 2, padding),
        ),
      );
    }
    if (rule & 8 != 0) {
      shape = Path.combine(
        PathOperation.union,
        shape,
        Path()..addRect(Rect.fromLTWH(0, padding, padding, side - padding * 2)),
      );
    }
    canvas.drawPath(
      shape,
      Paint()
        ..color = pathColor.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * .06,
    );
    canvas.drawPath(shape, Paint()..color = pathColor.withValues(alpha: .8));
  }

  @override
  bool shouldRepaint(_TerrainPatternPainter oldDelegate) =>
      oldDelegate.rule != rule ||
      oldDelegate.pathColor != pathColor ||
      oldDelegate.groundColor != groundColor;
}
