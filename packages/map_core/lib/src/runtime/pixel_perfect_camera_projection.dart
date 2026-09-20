import 'dart:math' as math;

double resolvePixelPerfectCameraZoom({
  required double viewportWidth,
  required double viewportHeight,
  required double visibleWidth,
  required double visibleHeight,
  required double displayScale,
  required double devicePixelRatio,
}) {
  final ideal = math.min(
    viewportWidth / visibleWidth,
    viewportHeight / visibleHeight,
  );
  final physicalScale = math.max(
    1,
    (displayScale * ideal * devicePixelRatio).round(),
  );
  return physicalScale / (displayScale * devicePixelRatio);
}

({double centerX, double centerY, double originX, double originY})
snapPixelPerfectCameraPosition({
  required double centerX,
  required double centerY,
  required double viewportWidth,
  required double viewportHeight,
  required double zoom,
  required double devicePixelRatio,
}) {
  final physicalCenterX = viewportWidth * devicePixelRatio / 2;
  final physicalCenterY = viewportHeight * devicePixelRatio / 2;
  final worldToPhysical = zoom * devicePixelRatio;
  final originX = (physicalCenterX - centerX * worldToPhysical).roundToDouble();
  final originY = (physicalCenterY - centerY * worldToPhysical).roundToDouble();
  return (
    centerX: (physicalCenterX - originX) / worldToPhysical,
    centerY: (physicalCenterY - originY) / worldToPhysical,
    originX: originX / devicePixelRatio,
    originY: originY / devicePixelRatio,
  );
}
