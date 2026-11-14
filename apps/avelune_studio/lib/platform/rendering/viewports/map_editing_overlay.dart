import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';

import 'package:avelune_studio/platform/rendering/viewports/map_encounter_cells_painter.dart';

part 'map_editing_overlay_zones.dart';
part 'map_editing_overlay_borders.dart';
part 'map_editing_overlay_collisions.dart';
part 'map_editing_overlay_markers.dart';

class MapEditingOverlay extends CustomPainter {
  MapEditingOverlay({
    required this.map,
    required this.project,
    required this.selected,
    required this.cellWidth,
    required this.cellHeight,
    required this.grid,
    required this.color,
    this.transform,
    this.preview,
    this.strokeCells = const [],
    this.borderDraft,
    this.borderCursor,
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
    this.collisionColor,
    this.isHidden,
    this.extraSelected = const [],
  }) : super(repaint: transform);
  final MapData map;
  final ProjectManifest project;
  final MapPlacedElement? selected;
  final double cellWidth;
  final double cellHeight;
  final bool grid;
  final Color color;
  final TransformationController? transform;
  final GridPos? preview;
  final List<GridPos> strokeCells;
  final MapBorderDrawingDraft? borderDraft;
  final GridPos? borderCursor;
  final MapEntity? selectedEntity;
  final GridPos? entityPreview;
  final String? selectedWarpId;
  final GridPos? warpPreview;
  final String? selectedMarkerId;
  final GridPos? markerPreview;
  final String? selectedZoneId;
  final MapRect? zone;
  final Color? labelBackground, labelForeground;
  final Color? collisionColor;
  final bool Function(String kind, String id)? isHidden;
  final List<MapPlacedElement> extraSelected;
  bool get _showLabels =>
      cellWidth * (transform?.value.entry(0, 0).abs() ?? 1) >= 28;

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
    _paintCollisionCells(canvas);
    _paintGameplayZones(canvas);
    _paintMarkers(canvas);
    _paintWarps(canvas);
    _paintBorderDraft(canvas);
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
    final instance =
        selected == null || (isHidden?.call('decor', selected!.id) ?? false)
        ? null
        : selected;
    final area =
        zone ??
        (selectedEntity == null ||
                (isHidden?.call('entity', selectedEntity!.id) ?? false)
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
    for (final extra in extraSelected) {
      if (isHidden?.call('decor', extra.id) ?? false) continue;
      final element = project.elements
          .where((e) => e.id == extra.elementId)
          .firstOrNull;
      final size = element == null
          ? const GridSize(width: 1, height: 1)
          : resolveMapPlacedElementFootprint(
              instance: extra,
              element: element,
            ).destinationSize;
      paint
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(
        Rect.fromLTWH(
          extra.pos.x * cellWidth,
          extra.pos.y * cellHeight,
          size.width * cellWidth,
          size.height * cellHeight,
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
  bool shouldRepaint(covariant MapEditingOverlay oldDelegate) => true;
}
