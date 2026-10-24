import 'dart:ui';

final class SpatialPointLight {
  SpatialPointLight({
    required this.position,
    required this.radius,
    this.color = const Color(0xffffd59a),
    this.intensity = 1,
  }) {
    if (![
          position.x,
          position.y,
          position.z,
          radius,
          intensity,
        ].every((v) => v.isFinite) ||
        radius <= 0 ||
        intensity < 0 ||
        intensity > 8) {
      throw ArgumentError('Invalid spatial point light.');
    }
  }

  final ({double x, double y, double z}) position;
  final double radius, intensity;
  final Color color;
}

double spatialPointLightAttenuation(double distanceSquared, double radius) {
  final remaining = (1 - distanceSquared / (radius * radius)).clamp(0.0, 1.0);
  return remaining * remaining;
}
