import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/environment_editing_commands.dart';

class MapEnvironmentOverlay extends StatelessWidget {
  const MapEnvironmentOverlay({
    super.key,
    required this.document,
    required this.project,
    required this.session,
    required this.tile,
    required this.stroke,
    this.start,
    this.end,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapEnvironmentSession session;
  final Size tile;
  final List<GridPos> stroke;
  final GridPos? start, end;

  @override
  Widget build(BuildContext context) {
    final area = EnvironmentEditingCommands(document, project).area(session);
    if (area == null) return const SizedBox.shrink();
    final cells = <GridPos>{
      for (var y = 0; y < area.mask.height; y++)
        for (var x = 0; x < area.mask.width; x++)
          if (area.mask.isActiveAt(x, y)) GridPos(x: x, y: y),
    };
    if (session.tool == EnvironmentPaintTool.erase) {
      cells.removeAll(stroke);
    } else {
      cells.addAll(stroke);
    }
    if (session.tool == EnvironmentPaintTool.rectangle &&
        start != null &&
        end != null) {
      for (
        var y = math.min(start!.y, end!.y);
        y <= math.max(start!.y, end!.y);
        y++
      ) {
        for (
          var x = math.min(start!.x, end!.x);
          x <= math.max(start!.x, end!.x);
          x++
        ) {
          if (x >= 0 &&
              y >= 0 &&
              x < document.current.size.width &&
              y < document.current.size.height) {
            cells.add(GridPos(x: x, y: y));
          }
        }
      }
    }
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _EnvironmentMaskPainter(
              cells,
              tile,
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EnvironmentMaskPainter extends CustomPainter {
  const _EnvironmentMaskPainter(this.cells, this.tile, this.color);
  final Set<GridPos> cells;
  final Size tile;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color.withValues(alpha: .18);
    final edge = Paint()
      ..color = color.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        cell.x * tile.width,
        cell.y * tile.height,
        tile.width,
        tile.height,
      );
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect.deflate(.5), edge);
    }
  }

  @override
  bool shouldRepaint(_EnvironmentMaskPainter oldDelegate) =>
      oldDelegate.cells != cells ||
      oldDelegate.tile != tile ||
      oldDelegate.color != color;
}
