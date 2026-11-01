import 'package:map_runtime/src/presentation/flame/battle_spl_child_initializer.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_motion.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_vector.dart';

void main() {
  final random = BattleSplRandom(seed: 0xffffffff);
  final actual = List.generate(3, (_) => random.next());
  final expected = [0xbc1eba5e, 0x3c68ad29, 0x6baa74d0];
  if (actual.toString() != expected.toString()) {
    throw StateError('Incorrect 32-bit sequence: $actual');
  }
  final fixed = BattleSplRandom(seed: 0);
  final values = List.generate(3, (_) => fixed.fixedPoint(bits: 24));
  if (values.toString() != [1772721, 1295412, -367339].toString()) {
    throw StateError('Incorrect signed values: $values');
  }
  final range = BattleSplRandom(seed: 0).range(4096);
  if (range != -3232) throw StateError('Incorrect range: $range');
  final varied = BattleSplRandom(seed: 0).vary(-1, variance: 0);
  if (varied != -1) throw StateError('Incorrect variance: $varied');
  final motion =
      BattleSplParticleMotion(
        position: (x: 0, y: 0, z: 0),
        velocity: (x: -1, y: 1, z: 0),
        rotation: 0,
        angularVelocity: 0,
      ).advanceWithGravity(
        gravity: (x: 0, y: 0, z: 0),
        emitterVelocity: (x: 0, y: 0, z: 0),
        airResistance: 0,
      );
  if (motion.velocity.x != -1) {
    throw StateError('Incorrect motion: ${motion.velocity.x}');
  }
  final vector = BattleSplVectorMath.randomUnitVector(BattleSplRandom(seed: 0));
  if (vector != (x: 3262, y: 2383, z: -676)) {
    throw StateError('Incorrect vector: $vector');
  }
  final sphere = BattleSplVectorMath.sphereSurface(
    BattleSplRandom(seed: 0),
    radius: 7004,
  );
  if (sphere != (x: 5578, y: 4075, z: -1156)) {
    throw StateError('Incorrect spherical emission: $sphere');
  }
  final child = BattleSplChildInitializer.create(
    random: BattleSplRandom(seed: 0),
    parentMotion: BattleSplParticleMotion(
      position: (x: 0, y: 0, z: 0),
      velocity: (x: 512, y: -256, z: 128),
      rotation: 0,
      angularVelocity: 0,
    ),
    parentEmitterPosition: (x: 10, y: -20, z: 30),
    parentBaseScale: 4096,
    parentAnimatedScale: 4096,
    parentBaseAlpha: 31,
    parentAnimatedAlpha: 31,
    parentColor: (red: 31, green: 8, blue: 2),
    velocityRatio: 128,
    randomVelocityMagnitude: 4096,
    scaleRatio: 63,
    rotation: BattleSplChildRotation.none,
    lifetime: 1,
    texture: 5,
  );
  if (child.motion.velocity != (x: -2976, y: -3600, z: 3968)) {
    throw StateError('Incorrect child velocity: ${child.motion.velocity}');
  }
  if (child.emitterPosition != (x: 10, y: -20, z: 30)) {
    throw StateError('Incorrect child emitter position');
  }
}
