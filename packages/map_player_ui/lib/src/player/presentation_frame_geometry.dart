import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final class PresentationClipGeometry {
  PresentationClipGeometry({
    required this.clipId,
    required this.zIndex,
    required this.visiblePath,
    required this.corners,
  });

  final String clipId;
  final int zIndex;
  final Path visiblePath;
  final List<Offset> corners;
  Rect get bounds => visiblePath.getBounds();
}

final class PresentationFrameGeometryController {
  final Set<_PresentationGeometryBox> _boxes = {};

  _PresentationGeometryBox? get _canvas => _boxes
      .where((box) => box.role == PresentationGeometryRole.canvas)
      .firstOrNull;

  Size? get canvasSize => _canvas?.hasSize == true ? _canvas!.size : null;

  List<PresentationClipGeometry> snapshot() {
    final canvas = _canvas;
    if (canvas == null || !canvas.attached || !canvas.hasSize) return const [];
    final canvasPath = Path()..addRect(Offset.zero & canvas.size);
    final result = <PresentationClipGeometry>[];
    for (final content in _boxes.where(
      (box) => box.role == PresentationGeometryRole.content,
    )) {
      if (!content.attached || !content.hasSize || content.opacity <= 0) {
        continue;
      }
      final crop = _boxes
          .where(
            (box) =>
                box.role == PresentationGeometryRole.crop &&
                box.clipId == content.clipId,
          )
          .firstOrNull;
      if (crop == null || !crop.hasSize || !crop.attached) continue;
      final transform = content.getTransformTo(canvas);
      final corners = [
        Offset.zero,
        Offset(content.size.width, 0),
        content.size.bottomRight(Offset.zero),
        Offset(0, content.size.height),
      ].map((point) => MatrixUtils.transformPoint(transform, point)).toList();
      if (corners.any((point) => !point.dx.isFinite || !point.dy.isFinite)) {
        continue;
      }
      final contentPath = Path()..addPolygon(corners, true);
      final cropPath = (Path()
            ..addRect(
                crop.clipper?.getClip(crop.size) ?? Offset.zero & crop.size))
          .transform(crop.getTransformTo(canvas).storage);
      final visible = Path.combine(
        PathOperation.intersect,
        canvasPath,
        Path.combine(PathOperation.intersect, contentPath, cropPath),
      );
      if (visible.getBounds().isEmpty) continue;
      result.add(PresentationClipGeometry(
        clipId: content.clipId!,
        zIndex: content.zIndex,
        visiblePath: visible,
        corners: List.unmodifiable(corners),
      ));
    }
    result.sort((a, b) {
      final order = a.zIndex.compareTo(b.zIndex);
      return order == 0 ? a.clipId.compareTo(b.clipId) : order;
    });
    return result;
  }

  PresentationClipGeometry? hitTest(Offset canvasPoint) => snapshot()
      .reversed
      .where((item) => item.visiblePath.contains(canvasPoint))
      .firstOrNull;
}

enum PresentationGeometryRole { canvas, crop, content }

class PresentationGeometryProbe extends SingleChildRenderObjectWidget {
  const PresentationGeometryProbe({
    super.key,
    required this.controller,
    required this.role,
    required super.child,
    this.clipId,
    this.zIndex = 0,
    this.opacity = 1,
    this.clipper,
  });

  final PresentationFrameGeometryController controller;
  final PresentationGeometryRole role;
  final String? clipId;
  final int zIndex;
  final double opacity;
  final CustomClipper<Rect>? clipper;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _PresentationGeometryBox(
          controller, role, clipId, zIndex, opacity, clipper);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final box = renderObject as _PresentationGeometryBox;
    box.controller._boxes.remove(box);
    box
      ..controller = controller
      ..role = role
      ..clipId = clipId
      ..zIndex = zIndex
      ..opacity = opacity
      ..clipper = clipper;
    if (box.attached) controller._boxes.add(box);
  }
}

class _PresentationGeometryBox extends RenderProxyBox {
  _PresentationGeometryBox(this.controller, this.role, this.clipId, this.zIndex,
      this.opacity, this.clipper);

  PresentationFrameGeometryController controller;
  PresentationGeometryRole role;
  String? clipId;
  int zIndex;
  double opacity;
  CustomClipper<Rect>? clipper;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    controller._boxes.add(this);
  }

  @override
  void detach() {
    controller._boxes.remove(this);
    super.detach();
  }
}
