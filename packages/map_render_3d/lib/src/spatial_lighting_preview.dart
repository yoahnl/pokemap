import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'spatial_shadow_profile.dart';

@immutable
final class SpatialLightingProfile {
  const SpatialLightingProfile._({
    required this.enabled,
    required this.ambientColor,
    required this.sunColor,
    required this.ambientStrength,
    required this.sunStrength,
    required this.sunDirection,
    required this.actorStrength,
    required this.groundStrength,
    required this.surfaceStrength,
    required this.unlitMaterialNames,
    required this.hiddenMaterialsByInstance,
    required this.shadow,
  });

  static const disabled = SpatialLightingProfile._(
    enabled: false,
    ambientColor: Color(0xffffffff),
    sunColor: Color(0xffffffff),
    ambientStrength: 1,
    sunStrength: 0,
    sunDirection: (x: 0, y: 1, z: 0),
    actorStrength: 0,
    groundStrength: 0,
    surfaceStrength: 1,
    unlitMaterialNames: {},
    hiddenMaterialsByInstance: {},
    shadow: null,
  );

  factory SpatialLightingProfile.stylized({
    Color ambientColor = const Color(0xffd3e1ff),
    Color sunColor = const Color(0xffffe0bc),
    double ambientStrength = .82,
    double sunStrength = .4,
    ({double x, double y, double z}) sunDirection = (x: -.65, y: .8, z: .45),
    double actorStrength = .25,
    double groundStrength = .7,
    double surfaceStrength = 1,
    Set<String> unlitMaterialNames = const {},
    Map<String, Set<String>> hiddenMaterialsByInstance = const {},
    SpatialShadowProfile? shadow,
  }) {
    final (x: x, y: y, z: z) = sunDirection;
    final length = math.sqrt(x * x + y * y + z * z);
    if (!length.isFinite ||
        length < .000001 ||
        !ambientStrength.isFinite ||
        ambientStrength < 0 ||
        ambientStrength > 2 ||
        !sunStrength.isFinite ||
        sunStrength < 0 ||
        sunStrength > 2 ||
        !actorStrength.isFinite ||
        actorStrength < 0 ||
        actorStrength > 1 ||
        !groundStrength.isFinite ||
        groundStrength < 0 ||
        groundStrength > 1) {
      throw ArgumentError('Invalid experimental spatial lighting profile.');
    }
    if (!surfaceStrength.isFinite ||
        surfaceStrength < 0 ||
        surfaceStrength > 1) {
      throw ArgumentError('Invalid experimental surface lighting strength.');
    }
    return SpatialLightingProfile._(
      enabled: true,
      ambientColor: ambientColor,
      sunColor: sunColor,
      ambientStrength: ambientStrength,
      sunStrength: sunStrength,
      sunDirection: (x: x / length, y: y / length, z: z / length),
      actorStrength: actorStrength,
      groundStrength: groundStrength,
      surfaceStrength: surfaceStrength,
      unlitMaterialNames: Set.unmodifiable(unlitMaterialNames),
      hiddenMaterialsByInstance: Map.unmodifiable({
        for (final entry in hiddenMaterialsByInstance.entries)
          entry.key: Set<String>.unmodifiable(entry.value),
      }),
      shadow: shadow,
    );
  }

  final bool enabled;
  final Color ambientColor, sunColor;
  final double ambientStrength,
      sunStrength,
      actorStrength,
      groundStrength,
      surfaceStrength;
  final ({double x, double y, double z}) sunDirection;
  final Set<String> unlitMaterialNames;
  final Map<String, Set<String>> hiddenMaterialsByInstance;
  final SpatialShadowProfile? shadow;
}

abstract interface class SpatialLightingContext {
  SpatialLightingProfile get lighting;
  SpatialShadowFrame? get shadowFrame;
}

class SpatialLightingPreview
    extends InheritedNotifier<ValueNotifier<SpatialLightingProfile>> {
  const SpatialLightingPreview({
    super.key,
    required ValueNotifier<SpatialLightingProfile> controller,
    required super.child,
  }) : super(notifier: controller);

  static SpatialLightingProfile of(BuildContext context) =>
      maybeOf(context) ?? SpatialLightingProfile.disabled;

  static SpatialLightingProfile? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SpatialLightingPreview>()
      ?.notifier
      ?.value;
}
