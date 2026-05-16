import '../models/shadow.dart';
import 'static_shadow_projection_geometry.dart';

const _compactPropLengthRatio = 0.0704;
const _compactPropNearWidthMultiplier = 0.3312;
const _compactPropFarWidthMultiplier = 0.2832;

const _tallPropLengthRatio = 0.0704;
const _tallPropNearWidthMultiplier = 0.2208;
const _tallPropFarWidthMultiplier = 0.1770;

const _buildingLengthRatio = 0.0832;
const _buildingNearWidthMultiplier = 0.4416;
const _buildingFarWidthMultiplier = 0.3422;

const _foliageLengthRatio = 0.0960;
const _foliageNearWidthMultiplier = 0.5060;
const _foliageFarWidthMultiplier = 0.4720;

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
      return _calibratedProjectionSpec(
        baseProjectionSpec,
        defaultLengthRatio: _compactPropLengthRatio,
        defaultNearWidthMultiplier: _compactPropNearWidthMultiplier,
        defaultFarWidthMultiplier: _compactPropFarWidthMultiplier,
      );
    case StaticShadowFamily.tallProp:
      return _calibratedProjectionSpec(
        baseProjectionSpec,
        defaultLengthRatio: _tallPropLengthRatio,
        defaultNearWidthMultiplier: _tallPropNearWidthMultiplier,
        defaultFarWidthMultiplier: _tallPropFarWidthMultiplier,
      );
    case StaticShadowFamily.building:
      return _calibratedProjectionSpec(
        baseProjectionSpec,
        defaultLengthRatio: _buildingLengthRatio,
        defaultNearWidthMultiplier: _buildingNearWidthMultiplier,
        defaultFarWidthMultiplier: _buildingFarWidthMultiplier,
      );
    case StaticShadowFamily.foliage:
      return _calibratedProjectionSpec(
        baseProjectionSpec,
        defaultLengthRatio: _foliageLengthRatio,
        defaultNearWidthMultiplier: _foliageNearWidthMultiplier,
        defaultFarWidthMultiplier: _foliageFarWidthMultiplier,
      );
  }
}

StaticShadowProjectionSpec _calibratedProjectionSpec(
  StaticShadowProjectionSpec baseProjectionSpec, {
  required double defaultLengthRatio,
  required double defaultNearWidthMultiplier,
  required double defaultFarWidthMultiplier,
}) {
  return StaticShadowProjectionSpec(
    directionX: baseProjectionSpec.directionX,
    directionY: baseProjectionSpec.directionY,
    lengthRatio: baseProjectionSpec.lengthRatio *
        defaultLengthRatio /
        defaultStaticShadowProjectionLengthRatio,
    nearWidthMultiplier: baseProjectionSpec.nearWidthMultiplier *
        defaultNearWidthMultiplier /
        defaultStaticShadowProjectionNearWidthMultiplier,
    farWidthMultiplier: baseProjectionSpec.farWidthMultiplier *
        defaultFarWidthMultiplier /
        defaultStaticShadowProjectionFarWidthMultiplier,
  );
}
