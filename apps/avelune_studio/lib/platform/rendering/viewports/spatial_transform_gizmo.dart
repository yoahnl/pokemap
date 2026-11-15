import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

enum SpatialGizmoAxis { x, y, z }

typedef SpatialPointProjector = Offset? Function(Model3dVector3 point);

typedef SpatialGizmoHandle = ({Offset start, Offset end, double pixelsPerUnit});

const spatialGizmoLength = 72.0;
const _hitTolerance = 9.0;

Model3dVector3 _along(Model3dVector3 origin, SpatialGizmoAxis axis) =>
    switch (axis) {
      SpatialGizmoAxis.x => Model3dVector3(
        x: origin.x + 1,
        y: origin.y,
        z: origin.z,
      ),
      SpatialGizmoAxis.y => Model3dVector3(
        x: origin.x,
        y: origin.y,
        z: origin.z + 1,
      ),
      SpatialGizmoAxis.z => Model3dVector3(
        x: origin.x,
        y: origin.y + 1,
        z: origin.z,
      ),
    };

SpatialGizmoHandle? spatialGizmoHandle(
  SpatialPointProjector project,
  Model3dVector3 origin,
  SpatialGizmoAxis axis,
) {
  final start = project(origin);
  final unit = project(_along(origin, axis));
  if (start == null || unit == null) return null;
  final direction = unit - start;
  final pixels = direction.distance;
  if (pixels < 2) return null;
  return (
    start: start,
    end: start + direction / pixels * spatialGizmoLength,
    pixelsPerUnit: pixels,
  );
}

double _segmentDistance(Offset point, Offset start, Offset end) {
  final segment = end - start;
  final length = segment.distanceSquared;
  final t = length == 0
      ? 0.0
      : (((point - start).dx * segment.dx + (point - start).dy * segment.dy) /
                length)
            .clamp(0.0, 1.0);
  return (point - (start + segment * t)).distance;
}

SpatialGizmoAxis? spatialGizmoAxisAt(
  SpatialPointProjector project,
  Model3dVector3 origin,
  Offset pointer,
) {
  SpatialGizmoAxis? nearest;
  var best = _hitTolerance;
  for (final axis in SpatialGizmoAxis.values) {
    final handle = spatialGizmoHandle(project, origin, axis);
    if (handle == null) continue;
    final distance = _segmentDistance(pointer, handle.start, handle.end);
    if (distance <= best) {
      best = distance;
      nearest = axis;
    }
  }
  return nearest;
}

double spatialGizmoDistance(SpatialGizmoHandle handle, Offset from, Offset to) {
  final direction = handle.end - handle.start;
  final unit = direction / direction.distance;
  final moved = to - from;
  return (moved.dx * unit.dx + moved.dy * unit.dy) / handle.pixelsPerUnit;
}

double spatialGizmoStep(
  SpatialGizmoAxis axis,
  double distance, {
  required bool fine,
}) {
  if (fine) return (distance * 100).round() / 100;
  return axis == SpatialGizmoAxis.z
      ? (distance * 4).round() / 4
      : distance.roundToDouble();
}

class SpatialTransformGizmo extends StatefulWidget {
  const SpatialTransformGizmo({
    super.key,
    required this.origin,
    required this.project,
    required this.repaint,
    required this.colors,
    required this.onDrag,
    required this.onEnd,
    required this.onCancel,
  });

  final Model3dVector3 origin;
  final SpatialPointProjector project;
  final Listenable repaint;
  final ({Color x, Color y, Color z}) colors;
  final void Function(SpatialGizmoAxis axis, double distance, bool fine) onDrag;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  @override
  State<SpatialTransformGizmo> createState() => _SpatialTransformGizmoState();
}

class _SpatialTransformGizmoState extends State<SpatialTransformGizmo> {
  SpatialGizmoAxis? _axis;
  SpatialGizmoHandle? _handle;
  Offset? _from;

  void _start(DragStartDetails details) {
    final axis = spatialGizmoAxisAt(
      widget.project,
      widget.origin,
      details.localPosition,
    );
    _axis = axis;
    _handle = axis == null
        ? null
        : spatialGizmoHandle(widget.project, widget.origin, axis);
    _from = details.localPosition;
    setState(() {});
  }

  void _update(DragUpdateDetails details) {
    final axis = _axis, handle = _handle, from = _from;
    if (axis == null || handle == null || from == null) return;
    widget.onDrag(
      axis,
      spatialGizmoDistance(handle, from, details.localPosition),
      HardwareKeyboard.instance.isShiftPressed,
    );
  }

  void _finish({required bool cancelled}) {
    if (_axis == null) return;
    _axis = null;
    _handle = null;
    _from = null;
    cancelled ? widget.onCancel() : widget.onEnd();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.deferToChild,
    dragStartBehavior: DragStartBehavior.down,
    onPanStart: _start,
    onPanUpdate: _update,
    onPanEnd: (_) => _finish(cancelled: false),
    onPanCancel: () => _finish(cancelled: true),
    child: CustomPaint(
      size: Size.infinite,
      painter: _GizmoPainter(
        origin: widget.origin,
        project: widget.project,
        colors: widget.colors,
        active: _axis,
        repaint: widget.repaint,
      ),
    ),
  );
}

class _GizmoPainter extends CustomPainter {
  _GizmoPainter({
    required this.origin,
    required this.project,
    required this.colors,
    required this.active,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Model3dVector3 origin;
  final SpatialPointProjector project;
  final ({Color x, Color y, Color z}) colors;
  final SpatialGizmoAxis? active;

  Color _color(SpatialGizmoAxis axis) => switch (axis) {
    SpatialGizmoAxis.x => colors.x,
    SpatialGizmoAxis.y => colors.y,
    SpatialGizmoAxis.z => colors.z,
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final axis in SpatialGizmoAxis.values) {
      final handle = spatialGizmoHandle(project, origin, axis);
      if (handle == null) continue;
      final paint = Paint()
        ..color = _color(axis)
        ..strokeWidth = axis == active ? 5 : 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(handle.start, handle.end, paint);
      final direction = handle.end - handle.start;
      final angle = math.atan2(direction.dy, direction.dx);
      final head = Path()
        ..moveTo(
          handle.end.dx + math.cos(angle) * 12,
          handle.end.dy + math.sin(angle) * 12,
        )
        ..lineTo(
          handle.end.dx + math.cos(angle + math.pi / 2) * 6,
          handle.end.dy + math.sin(angle + math.pi / 2) * 6,
        )
        ..lineTo(
          handle.end.dx + math.cos(angle - math.pi / 2) * 6,
          handle.end.dy + math.sin(angle - math.pi / 2) * 6,
        )
        ..close();
      canvas.drawPath(head, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool hitTest(Offset position) =>
      spatialGizmoAxisAt(project, origin, position) != null;

  @override
  bool shouldRepaint(_GizmoPainter old) =>
      old.origin != origin || old.active != active || old.colors != colors;
}
