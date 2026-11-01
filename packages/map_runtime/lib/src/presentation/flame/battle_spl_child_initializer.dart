import 'battle_spl_color_texture_animation.dart';
import 'battle_spl_particle_motion.dart';
import 'battle_spl_random.dart';

enum BattleSplChildRotation { none, angle, angleAndVelocity }

typedef BattleSplInitialChild = ({
  BattleSplParticleMotion motion,
  BattleSplVector emitterPosition,
  int baseScale4096,
  int baseAlpha5,
  BattleSplRgb5 color,
  int lifetime,
  int texture,
});

abstract final class BattleSplChildInitializer {
  static BattleSplInitialChild create({
    required BattleSplRandom random,
    required BattleSplParticleMotion parentMotion,
    required BattleSplVector parentEmitterPosition,
    required int parentBaseScale,
    required int parentAnimatedScale,
    required int parentBaseAlpha,
    required int parentAnimatedAlpha,
    required BattleSplRgb5 parentColor,
    required int velocityRatio,
    required int randomVelocityMagnitude,
    required int scaleRatio,
    required BattleSplChildRotation rotation,
    required int lifetime,
    required int texture,
    BattleSplRgb5? colorOverride,
  }) {
    if (parentBaseScale < 0 ||
        parentBaseScale > 32767 ||
        parentAnimatedScale < 0 ||
        parentAnimatedScale > 32767 ||
        parentBaseAlpha < 0 ||
        parentBaseAlpha > 31 ||
        parentAnimatedAlpha < 0 ||
        parentAnimatedAlpha > 31 ||
        !_validVector(parentEmitterPosition) ||
        !_validColor(parentColor) ||
        (colorOverride != null && !_validColor(colorOverride)) ||
        velocityRatio < 0 ||
        velocityRatio > 255 ||
        randomVelocityMagnitude < 0 ||
        randomVelocityMagnitude > 32767 ||
        scaleRatio < 0 ||
        scaleRatio > 255 ||
        lifetime < 1 ||
        lifetime > 65534 ||
        texture < 0 ||
        texture > 255) {
      throw const FormatException('Unsupported SPL child parameters');
    }
    final ratio4096 = velocityRatio * 16;
    int velocity(int component) {
      final product = component * ratio4096 + 2048;
      final inherited = _floorDivide(product, 4096);
      return _checked32(inherited + random.range(randomVelocityMagnitude));
    }

    final scale = (parentBaseScale * parentAnimatedScale) ~/ 4096;
    final baseScale = _checked32((scale * (scaleRatio + 1)) ~/ 64);
    final motion = BattleSplParticleMotion(
      position: parentMotion.position,
      velocity: (
        x: velocity(parentMotion.velocity.x),
        y: velocity(parentMotion.velocity.y),
        z: velocity(parentMotion.velocity.z),
      ),
      rotation: rotation == BattleSplChildRotation.none
          ? 0
          : parentMotion.rotation,
      angularVelocity: rotation == BattleSplChildRotation.angleAndVelocity
          ? parentMotion.angularVelocity
          : 0,
    );
    return (
      motion: motion,
      emitterPosition: parentEmitterPosition,
      baseScale4096: baseScale,
      baseAlpha5: (parentBaseAlpha * (parentAnimatedAlpha + 1)) ~/ 32,
      color: colorOverride ?? parentColor,
      lifetime: lifetime,
      texture: texture,
    );
  }

  static int _floorDivide(int value, int divisor) =>
      value >= 0 ? value ~/ divisor : -((-value + divisor - 1) ~/ divisor);

  static int _checked32(int value) {
    if (value < -2147483648 || value > 2147483647) {
      throw const FormatException('SPL child arithmetic exceeds 32 bits');
    }
    return value;
  }

  static bool _validVector(BattleSplVector vector) =>
      vector.x >= -2147483648 &&
      vector.x <= 2147483647 &&
      vector.y >= -2147483648 &&
      vector.y <= 2147483647 &&
      vector.z >= -2147483648 &&
      vector.z <= 2147483647;

  static bool _validColor(BattleSplRgb5 color) =>
      color.red >= 0 &&
      color.red <= 31 &&
      color.green >= 0 &&
      color.green <= 31 &&
      color.blue >= 0 &&
      color.blue <= 31;
}
