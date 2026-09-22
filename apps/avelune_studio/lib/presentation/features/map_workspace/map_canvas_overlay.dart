import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class MapCanvasOverlay extends CustomPainter {
  MapCanvasOverlay({
    required this.map,
    required this.project,
    required this.selected,
    required this.cellWidth,
    required this.cellHeight,
    required this.grid,
    required this.color,
    this.preview,
    this.strokeCells = const [],
    this.selectedEntity,
    this.entityPreview,
    this.selectedWarpId,
    this.warpPreview,
    this.selectedMarkerId,
    this.markerPreview,
    this.selectedZoneId,
    this.zone,
    this.labelBackground,
    this.labelForeground,
  });
  final MapData map;
  final ProjectManifest project;
  final MapPlacedElement? selected;
  final double cellWidth;
  final double cellHeight;
  final bool grid;
  final Color color;
  final GridPos? preview;
  final List<GridPos> strokeCells;
  final MapEntity? selectedEntity;
  final GridPos? entityPreview;
  final String? selectedWarpId;
  final GridPos? warpPreview;
  final String? selectedMarkerId;
  final GridPos? markerPreview;
  final String? selectedZoneId;
  final MapRect? zone;
  final Color? labelBackground, labelForeground;

  void _paintStoryZones(Canvas canvas) {
    final clip = canvas.getLocalClipBounds();
    final outline = Paint()
      ..color = color.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final trigger in map.triggers) {
      if (trigger.type != TriggerType.event) continue;
      final area = trigger.area;
      final rect = Rect.fromLTWH(
        area.pos.x * cellWidth,
        area.pos.y * cellHeight,
        area.size.width * cellWidth,
        area.size.height * cellHeight,
      );
      if (!clip.overlaps(rect)) continue;
      canvas.drawRect(rect.deflate(.75), outline);
      if (rect.width < 24 || rect.height < 18) continue;
      final label = TextPainter(
        text: TextSpan(
          text: trigger.name.trim().isEmpty ? 'Zone d’histoire' : trigger.name,
          style: TextStyle(
            color: labelForeground ?? color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: rect.width - 8);
      final background = Rect.fromLTWH(
        rect.left + 1,
        rect.top + 1,
        label.width + 6,
        label.height + 4,
      );
      if (labelBackground != null) {
        canvas.drawRect(background, Paint()..color = labelBackground!);
      }
      label.paint(canvas, Offset(rect.left + 4, rect.top + 3));
      label.dispose();
    }
  }

  void _paintBadge(
    Canvas canvas,
    Rect rect,
    String text, {
    required bool chosen,
  }) {
    canvas.drawRect(
      rect.deflate(chosen ? 1 : 1.5),
      Paint()
        ..color = color.withValues(alpha: chosen ? 1 : .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = chosen ? 2 : 1.5,
    );
    final label = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelForeground ?? color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '\u2026',
    )..layout(maxWidth: cellWidth * 6);
    if (labelBackground != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + 1,
          rect.top - label.height - 2,
          label.width + 6,
          label.height + 4,
        ),
        Paint()..color = labelBackground!,
      );
    }
    label.paint(canvas, Offset(rect.left + 4, rect.top - label.height));
    label.dispose();
  }

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
      _paintBadge(
        canvas,
        rect,
        zone.name.trim().isEmpty ? 'Zone de jeu' : zone.name,
        chosen: zone.id == selectedZoneId,
      );
    }
  }

  void _paintMarkers(Canvas canvas) {
    final clip = canvas.getLocalClipBounds();
    for (final entity in map.entities) {
      if (entity.kind != MapEntityKind.spawn &&
          entity.kind != MapEntityKind.sign) {
        continue;
      }
      final chosen = entity.id == selectedMarkerId;
      final pos = chosen ? (markerPreview ?? entity.pos) : entity.pos;
      final rect = Rect.fromLTWH(
        pos.x * cellWidth,
        pos.y * cellHeight,
        entity.size.width * cellWidth,
        entity.size.height * cellHeight,
      );
      if (!clip.overlaps(rect)) continue;
      _paintBadge(canvas, rect, _markerLabel(entity), chosen: chosen);
    }
  }

  String _markerLabel(MapEntity entity) {
    if (entity.kind == MapEntityKind.spawn) {
      return entity.spawn?.role == EntitySpawnRole.playerStart
          ? 'D\u00e9part du joueur'
          : 'Apparition';
    }
    final title = entity.sign?.title.trim() ?? '';
    return title.isEmpty ? 'Panneau' : title;
  }

  void _paintWarps(Canvas canvas) {
    if (map.warps.isEmpty) return;
    final clip = canvas.getLocalClipBounds();
    for (final warp in map.warps) {
      final chosen = warp.id == selectedWarpId;
      final pos = chosen ? (warpPreview ?? warp.pos) : warp.pos;
      final rect = Rect.fromLTWH(
        pos.x * cellWidth,
        pos.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      if (!clip.overlaps(rect)) continue;
      final destination = project.maps
          .where((entry) => entry.id == warp.targetMapId)
          .firstOrNull;
      _paintBadge(
        canvas,
        rect,
        destination == null
            ? 'Destination introuvable'
            : '\u2192 ${destination.name}',
        chosen: chosen,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .18)
      ..strokeWidth = 1;
    if (grid) {
      for (var x = 0; x <= map.size.width; x++) {
        canvas.drawLine(
          Offset(x * cellWidth, 0),
          Offset(x * cellWidth, size.height),
          paint,
        );
      }
      for (var y = 0; y <= map.size.height; y++) {
        canvas.drawLine(
          Offset(0, y * cellHeight),
          Offset(size.width, y * cellHeight),
          paint,
        );
      }
    }
    _paintStoryZones(canvas);
    _paintGameplayZones(canvas);
    _paintMarkers(canvas);
    _paintWarps(canvas);
    paint.color = color.withValues(alpha: .4);
    for (final cell in strokeCells) {
      canvas.drawRect(
        Rect.fromLTWH(
          cell.x * cellWidth,
          cell.y * cellHeight,
          cellWidth,
          cellHeight,
        ),
        paint,
      );
    }
    final instance = selected;
    final area =
        zone ??
        (selectedEntity == null
            ? null
            : MapRect(
                pos: entityPreview ?? selectedEntity!.pos,
                size: selectedEntity!.size,
              ));
    if (area != null) {
      paint
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(
        Rect.fromLTWH(
          area.pos.x * cellWidth,
          area.pos.y * cellHeight,
          area.size.width * cellWidth,
          area.size.height * cellHeight,
        ),
        paint,
      );
    }
    if (instance == null) return;
    final entry = project.elements
        .where((e) => e.id == instance.elementId)
        .firstOrNull;
    final footprint = entry == null
        ? const GridSize(width: 1, height: 1)
        : resolveMapPlacedElementFootprint(
            instance: instance,
            element: entry,
          ).destinationSize;
    final position = preview ?? instance.pos;
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(
        position.x * cellWidth,
        position.y * cellHeight,
        footprint.width * cellWidth,
        footprint.height * cellHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant MapCanvasOverlay oldDelegate) => true;
}
