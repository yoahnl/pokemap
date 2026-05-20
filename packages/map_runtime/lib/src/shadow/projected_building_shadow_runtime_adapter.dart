import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';

ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
  ProjectedBuildingShadowGeometry geometry,
) {
  final points = geometry.points
      .map(
        (point) => ShadowRuntimePoint(
          worldX: point.x,
          worldY: point.y,
        ),
      )
      .toList(growable: false);
  final bounds = _boundsFromRuntimePoints(points);

  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: geometry.opacity,
    colorHexRgb: geometry.colorHexRgb,
    polygonPoints: points,
  );
}

_ProjectedBuildingShadowRuntimeBounds _boundsFromRuntimePoints(
  List<ShadowRuntimePoint> points,
) {
  var minX = points.first.worldX;
  var maxX = points.first.worldX;
  var minY = points.first.worldY;
  var maxY = points.first.worldY;
  for (final point in points.skip(1)) {
    if (point.worldX < minX) {
      minX = point.worldX;
    }
    if (point.worldX > maxX) {
      maxX = point.worldX;
    }
    if (point.worldY < minY) {
      minY = point.worldY;
    }
    if (point.worldY > maxY) {
      maxY = point.worldY;
    }
  }

  return _ProjectedBuildingShadowRuntimeBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _ProjectedBuildingShadowRuntimeBounds {
  const _ProjectedBuildingShadowRuntimeBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}
