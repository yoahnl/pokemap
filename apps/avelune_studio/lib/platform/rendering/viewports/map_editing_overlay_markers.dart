part of 'map_editing_overlay.dart';

extension _MapCanvasMarkerPaint on MapEditingOverlay {
  void _paintStoryZones(Canvas canvas) {
    final clip = canvas.getLocalClipBounds();
    final outline = Paint()
      ..color = color.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final trigger in map.triggers) {
      if (isHidden?.call('trigger', trigger.id) ?? false) continue;
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
      if (!_showLabels || rect.width < 24 || rect.height < 18) continue;
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
    if (!_showLabels) return;
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

  void _paintMarkers(Canvas canvas) {
    final clip = canvas.getLocalClipBounds();
    for (final entity in map.entities) {
      if (isHidden?.call('entity', entity.id) ?? false) continue;
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
      if (isHidden?.call('warp', warp.id) ?? false) continue;
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
        warp.triggerMode == MapWarpTriggerMode.sceneOnly
            ? 'Point d’arrivée'
            : destination == null
            ? 'Destination introuvable'
            : '\u2192 ${destination.name}',
        chosen: chosen,
      );
    }
  }
}
