part of 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

// Collision preview rendering stays in one dedicated part so the editor logic
// can reference the same painter and fitting helper without leaving the panel library.

class _ElementCollisionProfilePainter extends CustomPainter {
  _ElementCollisionProfilePainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.padding,
    required this.baseCells,
    required this.manualAddedCells,
    required this.manualRemovedCells,
    required this.finalCells,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final WarpTriggerPadding padding;
  final List<GridPos> baseCells;
  final List<GridPos> manualAddedCells;
  final List<GridPos> manualRemovedCells;
  final List<GridPos> finalCells;

  @override
  void paint(Canvas canvas, Size size) {
    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right > image.width || sourceRect.bottom > image.height) {
      return;
    }

    final targetRect = _fitCollisionPreviewRect(
      size: size,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    final imagePaint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    canvas.drawImageRect(image, sourceRect, targetRect, imagePaint);

    final sourcePixelWidth = source.width * tileWidth.toDouble();
    final sourcePixelHeight = source.height * tileHeight.toDouble();
    final scaleX =
        sourcePixelWidth <= 0 ? 1.0 : targetRect.width / sourcePixelWidth;
    final scaleY =
        sourcePixelHeight <= 0 ? 1.0 : targetRect.height / sourcePixelHeight;
    final leftPad = padding.left * scaleX;
    final rightPad = padding.right * scaleX;
    final topPad = padding.top * scaleY;
    final bottomPad = padding.bottom * scaleY;
    final activeLeft = targetRect.left + leftPad;
    final activeTop = targetRect.top + topPad;
    final activeRight = targetRect.right - rightPad;
    final activeBottom = targetRect.bottom - bottomPad;
    final activeRect = Rect.fromLTRB(
      math.min(activeLeft, activeRight),
      math.min(activeTop, activeBottom),
      math.max(activeLeft, activeRight),
      math.max(activeTop, activeBottom),
    );

    final excludedPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    if (leftPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
            targetRect.left, targetRect.top, leftPad, targetRect.height),
        excludedPaint,
      );
    }
    if (rightPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.right - rightPad,
          targetRect.top,
          rightPad,
          targetRect.height,
        ),
        excludedPaint,
      );
    }
    if (topPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
            targetRect.left, targetRect.top, targetRect.width, topPad),
        excludedPaint,
      );
    }
    if (bottomPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.bottom - bottomPad,
          targetRect.width,
          bottomPad,
        ),
        excludedPaint,
      );
    }
    if (activeRect.width > 0 && activeRect.height > 0) {
      canvas.drawRect(
        activeRect,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    final cellWidth = targetRect.width / source.width;
    final cellHeight = targetRect.height / source.height;
    for (final cell in baseCells) {
      final cellRect = Rect.fromLTWH(
        targetRect.left + cell.x * cellWidth,
        targetRect.top + cell.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(
        cellRect,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
    }

    for (final cell in finalCells) {
      final cellRect = Rect.fromLTWH(
        targetRect.left + cell.x * cellWidth,
        targetRect.top + cell.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(
        cellRect,
        Paint()
          ..color = EditorChrome.inspectorJoyCoral.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        cellRect,
        Paint()
          ..color = EditorChrome.inspectorJoyCoral
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    for (final cell in manualAddedCells) {
      final cellRect = Rect.fromLTWH(
        targetRect.left + cell.x * cellWidth,
        targetRect.top + cell.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(
        cellRect.deflate(1.5),
        Paint()
          ..color = Colors.greenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    for (final cell in manualRemovedCells) {
      final cellRect = Rect.fromLTWH(
        targetRect.left + cell.x * cellWidth,
        targetRect.top + cell.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(
        cellRect,
        Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.14)
          ..style = PaintingStyle.fill,
      );
      final strikePaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      canvas.drawLine(cellRect.topLeft, cellRect.bottomRight, strikePaint);
      canvas.drawLine(cellRect.topRight, cellRect.bottomLeft, strikePaint);
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var x = 0; x <= source.width; x++) {
      final dx = targetRect.left + x * cellWidth;
      canvas.drawLine(
        Offset(dx, targetRect.top),
        Offset(dx, targetRect.bottom),
        gridPaint,
      );
    }
    for (var y = 0; y <= source.height; y++) {
      final dy = targetRect.top + y * cellHeight;
      canvas.drawLine(
        Offset(targetRect.left, dy),
        Offset(targetRect.right, dy),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ElementCollisionProfilePainter oldDelegate) {
    if (oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.padding != padding ||
        !_sameCells(oldDelegate.baseCells, baseCells) ||
        !_sameCells(oldDelegate.manualAddedCells, manualAddedCells) ||
        !_sameCells(oldDelegate.manualRemovedCells, manualRemovedCells) ||
        !_sameCells(oldDelegate.finalCells, finalCells)) {
      return true;
    }
    return false;
  }

  bool _sameCells(List<GridPos> a, List<GridPos> b) {
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
}

Rect _fitCollisionPreviewRect({
  required Size size,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
}) {
  final sourcePixelWidth = source.width * tileWidth.toDouble();
  final sourcePixelHeight = source.height * tileHeight.toDouble();
  if (sourcePixelWidth <= 0 || sourcePixelHeight <= 0) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }
  final sourceAspect = sourcePixelWidth / sourcePixelHeight;
  final targetAspect = size.width <= 0 || size.height <= 0
      ? sourceAspect
      : size.width / size.height;
  if (sourceAspect > targetAspect) {
    final height = size.width / sourceAspect;
    final top = (size.height - height) / 2;
    return Rect.fromLTWH(0, top, size.width, height);
  }
  final width = size.height * sourceAspect;
  final left = (size.width - width) / 2;
  return Rect.fromLTWH(left, 0, width, size.height);
}

