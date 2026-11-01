import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_child_initializer.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_motion.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';

void main() {
  test('creates source 218 children from their updated parent', () {
    final random = BattleSplRandom(seed: 0);
    final child = BattleSplChildInitializer.create(
      random: random,
      parentMotion: _motion(),
      parentEmitterPosition: (x: 10, y: -20, z: 30),
      parentBaseScale: 4096,
      parentAnimatedScale: 2048,
      parentBaseAlpha: 31,
      parentAnimatedAlpha: 15,
      parentColor: (red: 31, green: 8, blue: 2),
      velocityRatio: 0,
      randomVelocityMagnitude: 0,
      scaleRatio: 79,
      colorOverride: (red: 15, green: 0, blue: 0),
      rotation: BattleSplChildRotation.angleAndVelocity,
      lifetime: 1,
      texture: 5,
    );

    expect(child.motion.position, (x: 4096, y: -2048, z: 0));
    expect(child.emitterPosition, (x: 10, y: -20, z: 30));
    expect(child.motion.velocity, (x: 0, y: 0, z: 0));
    expect(child.motion.rotation, 65530);
    expect(child.motion.angularVelocity, 10);
    expect(child.baseScale4096, 2560);
    expect(child.baseAlpha5, 15);
    expect(child.color, (red: 15, green: 0, blue: 0));
    expect(child.lifetime, 1);
    expect(child.texture, 5);
    expect(random.state, 0xfa6515fd);
  });

  test('inherits a fraction of signed velocity and can reset rotation', () {
    final child = BattleSplChildInitializer.create(
      random: BattleSplRandom(seed: 0),
      parentMotion: _motion(),
      parentEmitterPosition: (x: 0, y: 0, z: 0),
      parentBaseScale: 4096,
      parentAnimatedScale: 4096,
      parentBaseAlpha: 31,
      parentAnimatedAlpha: 31,
      parentColor: (red: 31, green: 8, blue: 2),
      velocityRatio: 128,
      randomVelocityMagnitude: 0,
      scaleRatio: 63,
      rotation: BattleSplChildRotation.none,
      lifetime: 2,
      texture: 0,
    );

    expect(child.motion.velocity, (x: 256, y: -128, z: 64));
    expect(child.motion.rotation, 0);
    expect(child.motion.angularVelocity, 0);
    expect(child.baseScale4096, 4096);
    expect(child.baseAlpha5, 31);
    expect(child.color, (red: 31, green: 8, blue: 2));
  });

  test('adds three nonzero source random velocity samples', () {
    final random = BattleSplRandom(seed: 0);
    final child = BattleSplChildInitializer.create(
      random: random,
      parentMotion: _motion(),
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
      lifetime: 2,
      texture: 0,
    );

    expect(child.motion.velocity, (x: -2976, y: -3600, z: 3968));
    expect(random.state, 0xfa6515fd);
  });

  test('rejects unsupported ratios before consuming random values', () {
    final random = BattleSplRandom(seed: 0);
    expect(
      () => BattleSplChildInitializer.create(
        random: random,
        parentMotion: _motion(),
        parentEmitterPosition: (x: 0, y: 0, z: 0),
        parentBaseScale: 4096,
        parentAnimatedScale: 4096,
        parentBaseAlpha: 31,
        parentAnimatedAlpha: 31,
        parentColor: (red: 31, green: 8, blue: 2),
        velocityRatio: 256,
        randomVelocityMagnitude: 0,
        scaleRatio: 63,
        rotation: BattleSplChildRotation.none,
        lifetime: 2,
        texture: 0,
      ),
      throwsFormatException,
    );
    expect(random.state, 0);
  });

  test('bounds the child random velocity magnitude to signed fx16', () {
    BattleSplInitialChild create(int magnitude) =>
        BattleSplChildInitializer.create(
          random: BattleSplRandom(seed: 0),
          parentMotion: _motion(),
          parentEmitterPosition: (x: 0, y: 0, z: 0),
          parentBaseScale: 4096,
          parentAnimatedScale: 4096,
          parentBaseAlpha: 31,
          parentAnimatedAlpha: 31,
          parentColor: (red: 31, green: 8, blue: 2),
          velocityRatio: 0,
          randomVelocityMagnitude: magnitude,
          scaleRatio: 63,
          rotation: BattleSplChildRotation.none,
          lifetime: 1,
          texture: 0,
        );

    expect(() => create(32767), returnsNormally);
    expect(() => create(32768), throwsFormatException);
  });
}

BattleSplParticleMotion _motion() => BattleSplParticleMotion(
  position: (x: 4096, y: -2048, z: 0),
  velocity: (x: 512, y: -256, z: 128),
  rotation: 65530,
  angularVelocity: 10,
);
