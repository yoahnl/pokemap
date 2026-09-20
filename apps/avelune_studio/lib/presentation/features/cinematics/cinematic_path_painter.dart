import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'cinematic_map_model.dart';

class CinematicPathPainter extends CustomPainter {
  CinematicPathPainter(this.model, this.cell, this.color);
  final CinematicMapModel model;
  CinematicAsset get asset => model.asset;
  final Size cell;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final points = {
      for (final p
          in asset.stageContext?.stagePoints ?? <CinematicStagePoint>[])
        p.id: p,
    };
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final positions = {
      for (final a in model.actors.actors)
        if (a.position.isResolved)
          a.actorId: Offset(
            a.position.x! * cell.width,
            a.position.y! * cell.height,
          ),
    };
    for (final step in asset.timeline.steps.where(
      (s) => s.kind == CinematicTimelineStepKind.actorMove,
    )) {
      var origin = positions[step.actorId];
      if (origin == null) continue;
      final binding = asset.stageContext?.movementTargetBindings
          .where((b) => b.targetId == step.targetId)
          .firstOrNull;
      final point =
          binding?.kind == CinematicMovementTargetBindingKind.stagePoint
          ? points[binding?.sourceId]
          : null;
      final external = model.targets[step.targetId];
      final target = point != null
          ? Offset(point.x * cell.width, point.y * cell.height)
          : external == null
          ? null
          : Offset(external.x * cell.width, external.y * cell.height);
      final manual = asset.stageContext?.manualPaths
          .where((p) => p.ownerActorMoveStepId == step.id)
          .firstOrNull;
      for (final id in manual?.waypointStagePointIds ?? <String>[]) {
        final waypoint = points[id];
        if (waypoint == null) continue;
        final next = Offset(waypoint.x * cell.width, waypoint.y * cell.height);
        canvas.drawLine(origin!, next, paint);
        origin = next;
      }
      if (target != null) {
        canvas.drawLine(origin!, target, paint);
        positions[step.actorId!] = target;
      }
    }
    for (final path
        in asset.stageContext?.manualPaths ?? <CinematicManualPath>[]) {
      Offset? previous;
      for (final id in path.waypointStagePointIds) {
        final p = points[id];
        if (p == null) continue;
        final point = Offset(p.x * cell.width, p.y * cell.height);
        if (previous != null) canvas.drawLine(previous, point, paint);
        previous = point;
      }
    }
    for (final p in points.values) {
      final point = Offset(p.x * cell.width, p.y * cell.height);
      canvas.drawCircle(point, 5, paint);
      canvas.drawLine(
        point - const Offset(8, 0),
        point + const Offset(8, 0),
        paint,
      );
      canvas.drawLine(
        point - const Offset(0, 8),
        point + const Offset(0, 8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CinematicPathPainter old) =>
      old.asset != asset || old.cell != cell || old.color != color;
}
