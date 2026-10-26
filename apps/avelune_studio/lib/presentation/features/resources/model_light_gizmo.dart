import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../shared/widgets/buttons/studio_button.dart';

class ModelLightGizmo extends StatelessWidget {
  const ModelLightGizmo({super.key, required this.controller});
  final ModelPreviewController controller;
  @override
  Widget build(BuildContext context) {
    final light = controller.light;
    if (light == null || !controller.editLight) return const SizedBox.shrink();
    final p = light.localPosition,
        center = controller.projectPoint(light.localPosition);
    if (center == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final axes = [
      for (var i = 0; i < 3; i++)
        controller.projectPoint(
          Model3dVector3(
            x: p.x + (i == 0 ? .7 : 0),
            y: p.y + (i == 1 ? .7 : 0),
            z: p.z + (i == 2 ? .7 : 0),
          ),
        ),
    ];
    final ring = [
      for (var i = 0; i <= 48; i++)
        controller.projectPoint(
          Model3dVector3(
            x: p.x + math.cos(i * math.pi / 24) * light.radius,
            y: p.y,
            z: p.z + math.sin(i * math.pi / 24) * light.radius,
          ),
        ),
    ];
    return LayoutBuilder(
      builder: (context, bounds) => ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LightGuidePainter(
                    center,
                    axes,
                    ring,
                    scheme.primary,
                    scheme.secondary,
                    scheme.tertiary,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < axes.length; i++)
              if (axes[i] case final point?)
                Positioned(
                  left: (point.dx - 18).clamp(
                    0.0,
                    math.max(0.0, bounds.maxWidth - 44),
                  ),
                  top: (point.dy - 18).clamp(
                    0.0,
                    math.max(0.0, bounds.maxHeight - 40),
                  ),
                  child: GestureDetector(
                    key: ValueKey('model-light-handle-${['x', 'y', 'z'][i]}'),
                    onPanUpdate: (event) =>
                        controller.moveLight(i, event.delta),
                    child: StudioButton(
                      label: ['X', 'Y', 'Z'][i],
                      secondary: true,
                      onPressed: () {},
                    ),
                  ),
                ),
            Positioned(
              left: (center.dx - 22).clamp(
                0.0,
                math.max(0.0, bounds.maxWidth - 44),
              ),
              top: (center.dy - 18).clamp(
                0.0,
                math.max(0.0, bounds.maxHeight - 40),
              ),
              child: GestureDetector(
                key: const ValueKey('model-light-handle-bulb'),
                onPanUpdate: (event) =>
                    controller.moveLightOnGround(event.delta),
                child: StudioButton(
                  label: '',
                  icon: Icons.lightbulb,
                  secondary: true,
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightGuidePainter extends CustomPainter {
  _LightGuidePainter(this.center, this.axes, this.ring, this.x, this.y, this.z);
  final Offset center;
  final List<Offset?> axes, ring;
  final Color x, y, z;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < axes.length; i++) {
      if (axes[i] case final point?) {
        canvas.drawLine(
          center,
          point,
          Paint()
            ..color = [x, y, z][i]
            ..strokeWidth = 2,
        );
      }
    }
    final path = Path();
    var started = false;
    for (final point in ring) {
      if (point == null) {
        started = false;
        continue;
      }
      if (started) {
        path.lineTo(point.dx, point.dy);
      } else {
        path.moveTo(point.dx, point.dy);
        started = true;
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = y.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_LightGuidePainter old) => true;
}
