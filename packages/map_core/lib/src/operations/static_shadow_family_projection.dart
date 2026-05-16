import '../models/shadow.dart';
import 'static_shadow_projection_geometry.dart';

StaticShadowFamily resolveStaticShadowFamily({
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
}) {
  return overrideFamily ??
      elementFamily ??
      StaticShadowFamily.genericProjection;
}

StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
  required StaticShadowFamily family,
  StaticShadowProjectionSpec baseProjectionSpec =
      defaultStaticShadowProjectionSpec,
}) {
  switch (family) {
    case StaticShadowFamily.genericProjection:
      return baseProjectionSpec;
    case StaticShadowFamily.compactProp:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.72,
        nearWidthMultiplierScale: 0.82,
        farWidthMultiplierScale: 0.78,
      );
    case StaticShadowFamily.tallProp:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.18,
        nearWidthMultiplierScale: 0.52,
        farWidthMultiplierScale: 0.58,
      );
    case StaticShadowFamily.building:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.25,
        nearWidthMultiplierScale: 1.05,
        farWidthMultiplierScale: 0.98,
      );
    case StaticShadowFamily.foliage:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.05,
        nearWidthMultiplierScale: 1.15,
        farWidthMultiplierScale: 1.28,
      );
  }
}

StaticShadowProjectionSpec _scaledProjectionSpec(
  StaticShadowProjectionSpec baseProjectionSpec, {
  required double lengthRatioScale,
  required double nearWidthMultiplierScale,
  required double farWidthMultiplierScale,
}) {
  return StaticShadowProjectionSpec(
    directionX: baseProjectionSpec.directionX,
    directionY: baseProjectionSpec.directionY,
    lengthRatio: baseProjectionSpec.lengthRatio * lengthRatioScale,
    nearWidthMultiplier:
        baseProjectionSpec.nearWidthMultiplier * nearWidthMultiplierScale,
    farWidthMultiplier:
        baseProjectionSpec.farWidthMultiplier * farWidthMultiplierScale,
  );
}
