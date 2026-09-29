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
      _paintBadge(
        canvas,
        rect,
        zone.name.trim().isEmpty ? 'Zone de jeu' : zone.name,
        chosen: zone.id == selectedZoneId,
      );
    }
  }
}
