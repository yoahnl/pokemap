typedef BattleSplVector = ({int x, int y, int z});

final class BattleSplParticleMotion {
  BattleSplParticleMotion({
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.angularVelocity,
  }) {
    if (!_fitsVector(position, _minimum32, _maximum32) ||
        !_fitsVector(velocity, _minimum32, _maximum32) ||
        rotation < 0 ||
        rotation > 65535 ||
        angularVelocity < -32768 ||
        angularVelocity > 32767) {
      throw const FormatException('Invalid SPL particle motion');
    }
  }

  static const _minimum32 = -2147483648;
  static const _maximum32 = 2147483647;

  final BattleSplVector position;
  final BattleSplVector velocity;
  final int rotation;
  final int angularVelocity;

  BattleSplParticleMotion advanceWithGravity({
    required BattleSplVector gravity,
    required BattleSplVector emitterVelocity,
    required int airResistance,
    BattleSplVector? magnetTarget,
    int? magnetForce,
  }) {
    if (!_fitsVector(gravity, -32768, 32767) ||
        !_fitsVector(emitterVelocity, _minimum32, _maximum32) ||
        airResistance < 0 ||
        airResistance > 255 ||
        (magnetTarget == null) != (magnetForce == null) ||
        (magnetTarget != null && !_fitsVector(magnetTarget, _minimum32, _maximum32)) ||
        (magnetForce != null && (magnetForce < -32768 || magnetForce > 32767))) {
      throw const FormatException('Invalid SPL gravity or resistance');
    }
    final x = _advanceAxis(
      position.x,
      velocity.x,
      gravity.x,
      emitterVelocity.x,
      airResistance,
      magnetTarget?.x,
      magnetForce,
    );
    final y = _advanceAxis(
      position.y,
      velocity.y,
      gravity.y,
      emitterVelocity.y,
      airResistance,
      magnetTarget?.y,
      magnetForce,
    );
    final z = _advanceAxis(
      position.z,
      velocity.z,
      gravity.z,
      emitterVelocity.z,
      airResistance,
      magnetTarget?.z,
      magnetForce,
    );
    return BattleSplParticleMotion(
      position: (x: x.position, y: y.position, z: z.position),
      velocity: (x: x.velocity, y: y.velocity, z: z.velocity),
      rotation: (rotation + angularVelocity) & 65535,
      angularVelocity: angularVelocity,
    );
  }

  static ({int position, int velocity}) _advanceAxis(
    int position,
    int velocity,
    int gravity,
    int emitterVelocity,
    int resistance,
    int? magnetTarget,
    int? magnetForce,
  ) {
    final magneticProduct = magnetTarget == null
        ? 0
        : _checked(_checked(_checked(magnetTarget - position) - velocity) * magnetForce!);
    final magneticAcceleration = magneticProduct >= 0
        ? magneticProduct ~/ 4096
        : -((-magneticProduct + 4095) ~/ 4096);
    final product = _checked(velocity * (resistance + 384));
    final damped = product >= 0 ? product ~/ 512 : -((-product + 511) ~/ 512);
    final nextVelocity = _checked(_checked(damped + gravity) + magneticAcceleration);
    final displacement = _checked(nextVelocity + emitterVelocity);
    return (
      position: _checked(position + displacement),
      velocity: nextVelocity,
    );
  }

  static int _checked(int value) {
    if (value < _minimum32 || value > _maximum32) {
      throw FormatException('SPL motion arithmetic exceeds 32 bits: $value');
    }
    return value;
  }

  static bool _fitsVector(BattleSplVector value, int minimum, int maximum) =>
      value.x >= minimum &&
      value.x <= maximum &&
      value.y >= minimum &&
      value.y <= maximum &&
      value.z >= minimum &&
      value.z <= maximum;
}
