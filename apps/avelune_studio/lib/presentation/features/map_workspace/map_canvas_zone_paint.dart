part of 'map_canvas_overlay.dart';

extension _MapCanvasZonePaint on MapCanvasOverlay {
  void _paintGameplayZones(Canvas canvas) {
    if (map.gameplayZones.isEmpty) return;
    final clip = canvas.getLocalClipBounds();
    for (final zone in map.gameplayZones) {
      final rect = Rect.fromLTWH(
        zone.area.pos.x * cellWidth,
        zone.area.pos.y * cellHeight,
        zone.area.size.width * cellWidth,
        zone.area.size.height * cellHeight,
      );
      if (!clip.overlaps(rect)) continue;
      if (zone.cellMask != null) {
        paintPaintedEncounterZone(
          canvas,
          zone,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: color,
          labelColor: labelForeground ?? color,
          showLabel: _showLabels,
          selected: zone.id == selectedZoneId,
        );
        continue;
      }
      if (zone.fieldAction?.waterfall != null) {
        _paintWaterfallRoute(canvas, zone);
      }
      _paintBadge(
        canvas,
        rect,
        zone.name.trim().isEmpty ? 'Zone de jeu' : zone.name,
        chosen: zone.id == selectedZoneId,
      );
    }
  }

  void _paintWaterfallRoute(Canvas canvas, MapGameplayZone zone) {
    final route = zone.fieldAction!.waterfall!;
    Offset center(GridPos cell) => Offset(
      (zone.area.pos.x + cell.x + .5) * cellWidth,
      (zone.area.pos.y + cell.y + .5) * cellHeight,
    );
    final entry = center(route.entry), exit = center(route.exit);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(entry, exit, paint);
    for (final cell in route.path) {
      canvas.drawCircle(center(cell), 3, Paint()..color = color);
    }
    canvas.drawCircle(entry, cellWidth * .18, paint);
    final (dx, dy) = switch (route.direction) {
      MapConnectionDirection.north => (0.0, -1.0),
      MapConnectionDirection.south => (0.0, 1.0),
      MapConnectionDirection.east => (1.0, 0.0),
      MapConnectionDirection.west => (-1.0, 0.0),
    };
    final size = cellWidth * .22;
    final tip = exit + Offset(dx * size, dy * size);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          exit.dx - dx * size + dy * size,
          exit.dy - dy * size - dx * size,
        )
        ..lineTo(
          exit.dx - dx * size - dy * size,
          exit.dy - dy * size + dx * size,
        )
        ..close(),
      Paint()..color = color,
    );
    if (_showLabels) {
      for (final label in [(entry, 'Entrée'), (exit, 'Sortie')]) {
        final text = TextPainter(
          text: TextSpan(
            text: label.$2,
            style: TextStyle(color: labelForeground ?? color, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, label.$1 + Offset(cellWidth * .3, -text.height / 2));
        text.dispose();
      }
    }
  }
}
