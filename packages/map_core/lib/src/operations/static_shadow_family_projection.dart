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
        lengthRatioScale: 0.38,
        nearWidthMultiplierScale: 0.58,
        farWidthMultiplierScale: 0.44,
      );
    case StaticShadowFamily.tallProp:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.48,
        nearWidthMultiplierScale: 0.32,
        farWidthMultiplierScale: 0.28,
      );
    case StaticShadowFamily.building:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.62,
        nearWidthMultiplierScale: 0.78,
        farWidthMultiplierScale: 0.62,
      );
    case StaticShadowFamily.foliage:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.45,
        nearWidthMultiplierScale: 0.72,
        farWidthMultiplierScale: 0.70,
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
