import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../theme/studio_tokens.dart';
import 'map_decor_transform_draft.dart';

Rect decorLogicalRect(
  MapPlacedElement instance,
  ProjectElementEntry element,
  ProjectManifest project,
) {
  final rect = resolveMapPlacedElementGeometry(
    instance: instance,
    element: element,
    tileSize: PixelSize(
      width: project.settings.tileWidth,
      height: project.settings.tileHeight,
    ),
  ).logicalRect;
  final scale = project.settings.displayScale.toDouble();
  return Rect.fromLTWH(
    rect.leftPx * scale,
    rect.topPx * scale,
    rect.widthPx * scale,
    rect.heightPx * scale,
  );
}

class MapDecorTransformOverlay extends StatelessWidget {
  const MapDecorTransformOverlay({
    super.key,
    required this.instance,
    required this.element,
    required this.project,
    required this.transform,
    required this.resizable,
    this.invalid = false,
  });
  final MapPlacedElement instance;
  final ProjectElementEntry element;
  final ProjectManifest project;
  final TransformationController transform;
  final bool resizable, invalid;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: transform,
    builder: (context, _) {
      final rect = decorLogicalRect(instance, element, project);
      final zoom = transform.value.getMaxScaleOnAxis();
      final size = 10 / zoom;
      final color = invalid
          ? Theme.of(context).colorScheme.error
          : StudioColors.of(context).canvasSelection;
      final visual = resolveMapPlacedElementVisualBounds(
        instance: instance,
        element: element,
        manifest: project,
      );
      final scale = project.settings.displayScale.toDouble();
      final visualRect = Rect.fromLTWH(
        visual.leftPx * scale,
        visual.topPx * scale,
        visual.widthPx * scale,
        visual.heightPx * scale,
      );
      return IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (visualRect != rect)
              Positioned.fromRect(
                rect: visualRect,
                child: CustomPaint(
                  painter: _DecorBoundsPainter(
                    color.withValues(alpha: .5),
                    1 / zoom,
                  ),
                ),
              ),
            Positioned.fromRect(
              rect: rect,
              child: CustomPaint(painter: _DecorBoundsPainter(color, 2 / zoom)),
            ),
            if (resizable)
              for (final handle in DecorResizeHandle.values)
                Positioned(
                  left: handle.point(rect).dx - size / 2,
                  top: handle.point(rect).dy - size / 2,
                  child: SizedBox(
                    key: ValueKey('decor-handle-${handle.name}'),
                    width: size,
                    height: size,
                    child: CustomPaint(
                      painter: _DecorBoundsPainter(
                        color,
                        2 / zoom,
                        fill: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      );
    },
  );
}

class _DecorBoundsPainter extends CustomPainter {
  _DecorBoundsPainter(this.color, this.stroke, {this.fill});
  final Color color;
  final Color? fill;
  final double stroke;
  @override
  void paint(Canvas canvas, Size size) {
    if (fill != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = fill!);
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_DecorBoundsPainter oldDelegate) =>
      color != oldDelegate.color ||
      fill != oldDelegate.fill ||
      stroke != oldDelegate.stroke;
}
