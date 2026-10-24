import 'dart:math' as math;

import 'package:flutter/widgets.dart';

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
    required this.unlitMaterialNames,
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
    unlitMaterialNames: {},
  );

  factory SpatialLightingProfile.stylized({
    Color ambientColor = const Color(0xffd3e1ff),
    Color sunColor = const Color(0xffffe0bc),
    double ambientStrength = .82,
    double sunStrength = .4,
    ({double x, double y, double z}) sunDirection = (x: -.65, y: .8, z: .45),
    double actorStrength = .25,
    double groundStrength = .7,
    Set<String> unlitMaterialNames = const {},
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
    return SpatialLightingProfile._(
      enabled: true,
      ambientColor: ambientColor,
      sunColor: sunColor,
      ambientStrength: ambientStrength,
      sunStrength: sunStrength,
      sunDirection: (x: x / length, y: y / length, z: z / length),
      actorStrength: actorStrength,
      groundStrength: groundStrength,
      unlitMaterialNames: Set.unmodifiable(unlitMaterialNames),
    );
  }

  final bool enabled;
  final Color ambientColor, sunColor;
  final double ambientStrength, sunStrength, actorStrength, groundStrength;
  final ({double x, double y, double z}) sunDirection;
  final Set<String> unlitMaterialNames;
}

abstract interface class SpatialLightingContext {
  SpatialLightingProfile get lighting;
}

class SpatialLightingPreview
    extends InheritedNotifier<ValueNotifier<SpatialLightingProfile>> {
  const SpatialLightingPreview({
    super.key,
    required ValueNotifier<SpatialLightingProfile> controller,
    required super.child,
  }) : super(notifier: controller);

  static SpatialLightingProfile of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SpatialLightingPreview>()
          ?.notifier
          ?.value ??
      SpatialLightingProfile.disabled;
}
