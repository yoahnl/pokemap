import 'package:flutter/widgets.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioAtlasGridPainter extends CustomPainter {
  const SurfaceStudioAtlasGridPainter({
    required this.columnCount,
    required this.rowCount,
    required this.selectedColumns,
    required this.zoomPercent,
  });

  final int columnCount;
  final int rowCount;
  final List<int> selectedColumns;
  final double zoomPercent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF102E70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bg,
    );

    final columnWidth = size.width / columnCount;
    final stripePaint = Paint();
    for (var i = 0; i < columnCount; i++) {
      final rect = Rect.fromLTWH(i * columnWidth, 0, columnWidth, size.height);
      final hue = i % 4;
      stripePaint.color = switch (hue) {
        0 => const Color(0xFF1C7DFF),
        1 => const Color(0xFF2E8DFF),
        2 => const Color(0xFFE15E91),
        _ => const Color(0xFF2272DD),
      };
      canvas.drawRect(rect, stripePaint);
      if (hue == 2) {
        final shore = Paint()
          ..color = const Color(0xFFE2D6C8).withValues(alpha: 0.72);
        canvas.drawRect(
          Rect.fromLTWH(rect.left + columnWidth * 0.72, 0, columnWidth * 0.16,
              size.height),
          shore,
        );
      }
    }

    final waterLine = Paint()
      ..color = const Color(0xFF7ACDFF).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var y = 14.0; y < size.height; y += 32) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 24) {
        path.quadraticBezierTo(x + 12, y - 8, x + 24, y);
      }
      canvas.drawPath(path, waterLine);
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.42)
      ..strokeWidth = 1;
    for (var i = 0; i <= columnCount; i++) {
      final x = i * columnWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    final rowHeight = size.height / rowCount;
    for (var i = 0; i <= rowCount; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          gridPaint..color = const Color(0xFFFFFFFF).withValues(alpha: 0.13));
    }

    final selectedPaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.17);
    final selectedBorder = Paint()
      ..color = SurfaceStudioDesignTokens.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    for (final column in selectedColumns) {
      final rect = Rect.fromLTWH(
        (column - 1) * columnWidth + 2,
        2,
        columnWidth - 4,
        size.height - 4,
      );
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rr, selectedPaint);
      canvas.drawRRect(rr, selectedBorder);
    }
  }

  @override
  bool shouldRepaint(covariant SurfaceStudioAtlasGridPainter oldDelegate) =>
      oldDelegate.columnCount != columnCount ||
      oldDelegate.rowCount != rowCount ||
      oldDelegate.zoomPercent != zoomPercent ||
      !_listEquals(oldDelegate.selectedColumns, selectedColumns);
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
