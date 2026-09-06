import 'package:flutter/widgets.dart';

final class RegionMapGeometry {
  factory RegionMapGeometry({
    required Size viewport,
    required Size imageSize,
    double scale = 1,
    Offset center = const Offset(.5, .5),
  }) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, viewport);
    final imageRect = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & viewport,
    );
    final zoom = scale.clamp(1.0, 3.0);
    final sceneCenter = Offset(
      imageRect.left + center.dx * imageRect.width,
      imageRect.top + center.dy * imageRect.height,
    );
    return RegionMapGeometry._bounded(
      viewport,
      imageRect,
      zoom,
      viewport.center(Offset.zero) - sceneCenter * zoom,
    );
  }

  factory RegionMapGeometry._bounded(
    Size viewport,
    Rect imageRect,
    double scale,
    Offset translation,
  ) {
    double bound(double requested, double start, double end, double extent) {
      if ((end - start) * scale <= extent) {
        return (extent - (start + end) * scale) / 2;
      }
      return requested.clamp(extent - end * scale, -start * scale);
    }

    return RegionMapGeometry._(
      viewport,
      imageRect,
      scale,
      Offset(
        bound(translation.dx, imageRect.left, imageRect.right, viewport.width),
        bound(translation.dy, imageRect.top, imageRect.bottom, viewport.height),
      ),
    );
  }

  const RegionMapGeometry._(
    this.viewport,
    this.imageRect,
    this.scale,
    this.translation,
  );

  final Size viewport;
  final Rect imageRect;
  final double scale;
  final Offset translation;

  Offset get center => unproject(viewport.center(Offset.zero));

  Rect get transformedImageRect => Rect.fromLTWH(
        translation.dx + imageRect.left * scale,
        translation.dy + imageRect.top * scale,
        imageRect.width * scale,
        imageRect.height * scale,
      );

  Offset project(Offset normalized) =>
      translation +
      Offset(imageRect.left + normalized.dx * imageRect.width,
              imageRect.top + normalized.dy * imageRect.height) *
          scale;

  Offset unproject(Offset position) {
    final scene = (position - translation) / scale;
    return Offset((scene.dx - imageRect.left) / imageRect.width,
        (scene.dy - imageRect.top) / imageRect.height);
  }

  RegionMapGeometry pan(Offset delta) => RegionMapGeometry._bounded(
      viewport, imageRect, scale, translation + delta);

  RegionMapGeometry zoom(double value, Offset focalPoint) {
    final nextScale = value.clamp(1.0, 3.0);
    final scenePoint = (focalPoint - translation) / scale;
    return RegionMapGeometry._bounded(
      viewport,
      imageRect,
      nextScale,
      focalPoint - scenePoint * nextScale,
    );
  }
}
