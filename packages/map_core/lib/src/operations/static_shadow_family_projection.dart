import '../models/shadow.dart';
import 'static_shadow_projection_geometry.dart';

const _compactPropLengthRatio = 0.1120;
const _compactPropNearWidthMultiplier = 0.5200;
const _compactPropFarWidthMultiplier = 0.4300;

const _tallPropLengthRatio = 0.1280;
const _tallPropNearWidthMultiplier = 0.5400;
const _tallPropFarWidthMultiplier = 0.4000;

const _buildingLengthRatio = 0.1120;
const _buildingNearWidthMultiplier = 0.6400;
const _buildingFarWidthMultiplier = 0.5400;

const _foliageLengthRatio = 0.1300;
const _foliageNearWidthMultiplier = 0.7000;
const _foliageFarWidthMultiplier = 0.6400;

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
