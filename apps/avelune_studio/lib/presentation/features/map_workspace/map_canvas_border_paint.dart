part of 'map_canvas_overlay.dart';

extension _MapCanvasBorderPaint on MapCanvasOverlay {
  void _paintBorderDraft(Canvas canvas) {
    final draft = borderDraft;
    final committed = draft?.anchoredCells ?? const <GridPos>[];
    final preview =
        draft?.previewCells ??
        (borderCursor == null ? const <GridPos>[] : <GridPos>[borderCursor!]);
    if (preview.isEmpty) return;
    if (draft?.alignment == BorderStrokeAlignment.gridEdges) {
      void drawPath(List<GridPos> points, double opacity, double width) {
        if (points.length < 2) return;
        final path = Path()
          ..moveTo(points.first.x * cellWidth, points.first.y * cellHeight);
        for (final point in points.skip(1)) {
          path.lineTo(point.x * cellWidth, point.y * cellHeight);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      drawPath(preview, .35, 8);
      drawPath(committed, .95, 4);
      for (final anchor in draft!.anchors) {
        canvas.drawCircle(
          Offset(anchor.x * cellWidth, anchor.y * cellHeight),
          5,
          Paint()..color = color,
        );
      }
      return;
    }
    final committedSet = committed.toSet();
    final fill = Paint()..style = PaintingStyle.fill;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final cell in preview) {
      final anchored = committedSet.contains(cell);
      final rect = Rect.fromLTWH(
        cell.x * cellWidth,
        cell.y * cellHeight,
        cellWidth,
        cellHeight,
      ).deflate(2);
      fill.color = color.withValues(alpha: anchored ? .48 : .26);
      outline.color = color.withValues(alpha: anchored ? .95 : .65);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        outline,
      );
    }
    for (final anchor in draft?.anchors ?? const <GridPos>[]) {
      canvas.drawCircle(
        Offset((anchor.x + .5) * cellWidth, (anchor.y + .5) * cellHeight),
        4,
        Paint()..color = color,
      );
    }
  }
}
