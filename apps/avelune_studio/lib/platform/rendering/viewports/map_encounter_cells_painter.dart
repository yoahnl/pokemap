import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

void paintPaintedEncounterZone(
  Canvas canvas,
  MapGameplayZone zone, {
  required double cellWidth,
  required double cellHeight,
  required Color color,
  required Color labelColor,
  required bool selected,
  required bool showLabel,
}) {
  final fill = Paint()..color = color.withValues(alpha: selected ? .25 : .12);
  final outline = Paint()
    ..color = color.withValues(alpha: selected ? 1 : .65)
    ..style = PaintingStyle.stroke
    ..strokeWidth = selected ? 2 : 1;
  final clip = canvas.getLocalClipBounds();
  for (final cell in zone.cellMask ?? const <GridPos>[]) {
    final rect = Rect.fromLTWH(
      (zone.area.pos.x + cell.x) * cellWidth,
      (zone.area.pos.y + cell.y) * cellHeight,
      cellWidth,
      cellHeight,
    );
    if (!clip.overlaps(rect)) continue;
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect.deflate(.5), outline);
  }
  if (!showLabel) return;
  final label = TextPainter(
    text: TextSpan(
      text: zone.name.isEmpty ? 'Zone de rencontres' : zone.name,
      style: TextStyle(color: labelColor, fontSize: 12),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: cellWidth * 8);
  label.paint(
    canvas,
    Offset(
      zone.area.pos.x * cellWidth,
      zone.area.pos.y * cellHeight - label.height - 2,
    ),
  );
  label.dispose();
}
