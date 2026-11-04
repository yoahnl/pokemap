import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_child_initializer.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_color_texture_animation.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_emitter_lifecycle.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_motion.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_pool.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_point_emitter_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_scalar_animation.dart';

void main() {
  test('alpha randomness is consumed before the BW2 random force', () {
    final random = BattleSplRandom(seed: 0);
    final playback = _playback(
      _lifecycle(),
      nextAlphaByte: () => random.next() >> 24,
      randomForce: (magnitude: (x: 100, y: 0, z: 0), interval: 1),
      random: random,
    );
    final expected = BattleSplRandom(seed: 0);
    expected.next();
    final x = expected.range(100);
    expected.range(0);
    expected.range(0);
    playback.step(managerFrame: 0);
    expect(playback.particles.single.motion.velocity.x, 100 + x);
    expect(random.state, expected.state);
    playback.cancel();
  });

  test('random behavior affects children only when they inherit behaviors', () {
    ({BattleSplPointEmitterPlayback playback, BattleSplRandom random}) create(bool inherit) {
      final random = BattleSplRandom(seed: 0);
      final playback = _playback(
        _lifecycle(child: const BattleSplChildTiming(
          emissionCount: 1, emissionDelay256: 0, emissionInterval: 1, lifetime: 4,
        )),
        alphaAnimationEnabled: false,
        childInheritsBehaviors: inherit,
        randomForce: (magnitude: (x: 100, y: 0, z: 0), interval: 1),
        random: random,
        childInitializer: (_, parent) => (
          motion: BattleSplParticleMotion(position: (x: 0, y: 0, z: 0),
              velocity: (x: 0, y: 0, z: 0), rotation: 0, angularVelocity: 0),
          emitterPosition: parent.emitterPosition, baseScale4096: 4096,
          baseAlpha5: 31, color: parent.color, lifetime: 4, texture: 10,
        ),
      );
      return (playback: playback, random: random);
    }
    final inherited = create(true);
    final independent = create(false);
    inherited.playback.step(managerFrame: 0);
    independent.playback.step(managerFrame: 0);
    final expected = BattleSplRandom(seed: 0);
    final parentForce = expected.range(100);
    expected.range(0);
    expected.range(0);
    expect(independent.random.state, expected.state);
    final childForce = expected.range(100);
    expected.range(0);
    expected.range(0);
    expect(inherited.random.state, expected.state);
    expect(inherited.playback.particles.singleWhere((p) => p.parentId == null)
        .motion.velocity.x, 100 + parentForce);
    expect(inherited.playback.particles.singleWhere((p) => p.parentId != null)
        .motion.velocity.x, childForce);
    expect(independent.playback.particles.singleWhere((p) => p.parentId != null)
        .motion.velocity.x, 0);
    inherited.playback.cancel();
    independent.playback.cancel();
  });

  test('does not consume alpha randomness when there is no alpha animation', () {
    var calls = 0;
    final playback = _playback(
      _lifecycle(),
      alphaAnimationEnabled: false,
      nextAlphaByte: () {
        calls++;
        return 0;
      },
    );
    playback.step(managerFrame: 0);
    playback.step(managerFrame: 1);
    expect(calls, 0);
    expect(playback.particles.every((particle) => particle.animatedAlpha5 == 31), isTrue);
    playback.cancel();
  });

  test('applies parent forces to children only when configured', () {
    BattleSplPointEmitterPlayback create(bool inherit) => _playback(
      _lifecycle(child: const BattleSplChildTiming(
        emissionCount: 1, emissionDelay256: 0, emissionInterval: 1, lifetime: 4,
      )),
      magnet: (target: (x: 4096, y: 0, z: 0), force: 512),
      childInheritsBehaviors: inherit,
      childInitializer: (_, parent) => (
        motion: BattleSplParticleMotion(position: (x: 0, y: 0, z: 0),
          velocity: (x: 0, y: 0, z: 0), rotation: 0, angularVelocity: 0),
        emitterPosition: parent.emitterPosition, baseScale4096: 4096,
        baseAlpha5: 31, color: parent.color, lifetime: 4, texture: 10,
      ),
    );
    final inherited = create(true)..step(managerFrame: 0);
    final independent = create(false)..step(managerFrame: 0);
    expect(inherited.particles.firstWhere((p) => p.parentId != null).motion.velocity.x, 512);
    expect(independent.particles.firstWhere((p) => p.parentId != null).motion.velocity.x, 0);
    inherited.cancel();
    independent.cancel();
  });
  test('animates child scale toward the configured BW2 end scale', () {
    final lifecycle = _lifecycle(
      child: const BattleSplChildTiming(
        emissionCount: 1,
        emissionDelay256: 0,
        emissionInterval: 1,
        lifetime: 4,
      ),
    );
    final playback = _playback(
      lifecycle,
      childScaleEnd: 0,
      childInitializer: (_, parent) => (
        motion: parent.motion,
        emitterPosition: parent.emitterPosition,
        baseScale4096: parent.baseScale4096,
        baseAlpha5: 31,
        color: parent.color,
        lifetime: 4,
        texture: 10,
      ),
    );
    playback.step(managerFrame: 0);
    final child = playback.particles.firstWhere((p) => p.parentId != null);
    expect(child.scale4096, 4096);
    playback.step(managerFrame: 1);
    final updated = playback.particles.firstWhere((p) => p.id == child.id);
    expect(updated.scale4096, lessThan(4096));
    playback.cancel();
  });
  test('tracks each point particle through emission, motion and expiry', () {
    final playback = _playback(_lifecycle());

    playback.step(managerFrame: 0);
    expect(playback.particles.map((particle) => particle.id), [1]);
    expect(playback.particles.single.motion.position.x, 100);
    expect(playback.particles.single.scale4096, 4096);
    expect(playback.particles.single.texture, 10);

    playback.step(managerFrame: 1);
    expect(playback.particles.map((particle) => particle.id), [2, 1]);
    expect(playback.particles.map((particle) => particle.motion.position.x), [
      100,
      200,
    ]);
    expect(playback.particles.last.scale4096, 6816);
    expect(playback.particles.last.texture, 11);
    expect(playback.particles.last.alpha5, 30);

    playback.step(managerFrame: 0);
    expect(playback.particles.map((particle) => particle.id), [2, 1]);
    playback.step(managerFrame: 1);
    expect(playback.particles.map((particle) => particle.id), [2]);
    expect(playback.isComplete, isFalse);
    playback.step(managerFrame: 0);
    expect(playback.particles, isEmpty);
    expect(playback.isComplete, isTrue);
  });

  test('pause preserves the last frame without emitting or advancing', () {
    final playback = _playback(_lifecycle());
    playback.step(managerFrame: 0);
    final before = playback.particles.single;

    playback.step(managerFrame: 1, paused: true);

    expect(playback.particles.single.id, before.id);
    expect(playback.particles.single.motion.position, before.motion.position);
    expect(playback.particles.single.texture, before.texture);
    expect(playback.isComplete, isFalse);
  });

  test('preserves each parent’s initial scale and emitter position', () {
    final playback = _playback(
      _lifecycle(),
      initializeParent: (id) => (
        motion: BattleSplParticleMotion(
          position: (x: 0, y: 0, z: 0),
          velocity: (x: 0, y: 0, z: 0),
          rotation: 0,
          angularVelocity: 0,
        ),
        emitterPosition: (x: id * 10, y: 0, z: 0),
        baseScale4096: id * 2048,
        color: null,
        texture: null,
        lifetime: null,
      ),
    );

    playback.step(managerFrame: 0);
    playback.step(managerFrame: 1);

    expect(playback.particles.map((particle) => particle.baseScale4096), [
      4096,
      2048,
    ]);
    expect(playback.particles.map((particle) => particle.emitterPosition.x), [
      20,
      10,
    ]);
  });

  test(
    'updates following parents with the current emitter position and velocity',
    () {
      final playback = _playback(_lifecycle(), followEmitter: true);

      playback.step(
        managerFrame: 0,
        emitterPosition: (x: 10, y: 0, z: 0),
        emitterVelocity: (x: 20, y: 0, z: 0),
      );
      expect(playback.particles.single.emitterPosition.x, 10);
      expect(playback.particles.single.motion.position.x, 120);

      playback.step(
        managerFrame: 1,
        emitterPosition: (x: 30, y: 0, z: 0),
        emitterVelocity: (x: -30, y: 0, z: 0),
      );
      expect(playback.particles.map((particle) => particle.emitterPosition.x), [
        30,
        30,
      ]);
      expect(playback.particles.map((particle) => particle.motion.position.x), [
        70,
        190,
      ]);
    },
  );

  test('keeps detached parent origins while applying emitter velocity', () {
    final playback = _playback(
      _lifecycle(),
      emitterPosition: (x: 7, y: 0, z: 0),
    );
    playback.step(
      managerFrame: 0,
      emitterPosition: (x: 10, y: 0, z: 0),
      emitterVelocity: (x: 20, y: 0, z: 0),
    );
    playback.step(
      managerFrame: 1,
      emitterPosition: (x: 30, y: 0, z: 0),
      emitterVelocity: (x: -30, y: 0, z: 0),
    );
    expect(playback.particles.map((particle) => particle.emitterPosition.x), [
      7,
      7,
    ]);
    expect(playback.particles.map((particle) => particle.motion.position.x), [
      70,
      190,
    ]);
  });

  test(
    'rejects an invalid following origin and releases allocated particles',
    () {
      final pool = BattleSplParticlePool(capacity: 8);
      final playback = _playback(
        _lifecycle(particlePool: pool),
        followEmitter: true,
      );
      expect(
        () => playback.step(
          managerFrame: 0,
          emitterPosition: (x: 2147483648, y: 0, z: 0),
        ),
        throwsFormatException,
      );
      expect(pool.inUse, 0);
      expect(playback.particles, isEmpty);
    },
  );

  test('applies child follow independently of parent follow', () {
    for (final follows in [false, true]) {
      final lifecycle = BattleSplEmitterLifecycle(
        emitterLifetime: 1,
        emissionInterval: 1,
        emissionRate4096: 4096,
        particleLifetime: 3,
        particleLifetimeVariance: 0,
        maxParticles: 8,
        captureEvents: true,
        child: const BattleSplChildTiming(
          emissionCount: 1,
          emissionDelay256: 0,
          emissionInterval: 1,
          lifetime: 3,
        ),
      );
      final playback = _playback(
        lifecycle,
        followEmitter: true,
        childFollowsEmitter: follows,
        childInitializer: (_, parent) => (
          motion: BattleSplParticleMotion(
            position: (x: 0, y: 0, z: 0),
            velocity: (x: 0, y: 0, z: 0),
            rotation: 0,
            angularVelocity: 0,
          ),
          emitterPosition: parent.emitterPosition,
          baseScale4096: 4096,
          baseAlpha5: 31,
          color: (red: 31, green: 0, blue: 0),
          lifetime: 3,
          texture: 5,
        ),
      );
      playback.step(managerFrame: 0, emitterPosition: (x: 10, y: 0, z: 0));
      playback.step(managerFrame: 1, emitterPosition: (x: 30, y: 0, z: 0));
      expect(
        playback.particles
            .singleWhere((particle) => particle.id == 2)
            .emitterPosition
            .x,
        follows ? 30 : 10,
      );
      playback.cancel();
    }
  });

  test('rejects lifecycles that cannot provide point-particle events', () {
    expect(
      () => _playback(_lifecycle(captureEvents: false)),
      throwsFormatException,
    );
    expect(
      () => _playback(
        _lifecycle(
          child: const BattleSplChildTiming(
            emissionCount: 1,
            emissionDelay256: 0,
            emissionInterval: 1,
            lifetime: 2,
          ),
        ),
      ),
      throwsFormatException,
    );
  });

  test('returns allocated particles when initialization fails', () {
    final pool = BattleSplParticlePool(capacity: 8);
    final playback = _playback(
      _lifecycle(particlePool: pool),
      initialMotion: (_) => throw StateError('bad particle'),
    );

    expect(() => playback.step(managerFrame: 0), throwsStateError);
    expect(pool.inUse, 0);
    expect(playback.particles, isEmpty);
    expect(() => playback.step(managerFrame: 1), throwsStateError);
  });

  test('returns the shared pool when a varied lifetime is invalid', () {
    final pool = BattleSplParticlePool(capacity: 8);
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 1,
      emissionInterval: 1,
      emissionRate4096: 8192,
      particleLifetime: 10,
      particleLifetimeVariance: 255,
      maxParticles: 8,
      particlePool: pool,
      captureEvents: true,
    );
    final playback = _playback(
      lifecycle,
      initializeParent: (_) => (
        motion: BattleSplParticleMotion(
          position: (x: 0, y: 0, z: 0),
          velocity: (x: 0, y: 0, z: 0),
          rotation: 0,
          angularVelocity: 0,
        ),
        emitterPosition: (x: 0, y: 0, z: 0),
        baseScale4096: 4096,
        color: null,
        texture: null,
        lifetime: 0,
      ),
    );

    expect(() => playback.step(managerFrame: 0), throwsFormatException);
    expect(pool.inUse, 0);
    expect(playback.particles, isEmpty);
  });

  test('cancelling a playback releases its shared particles once', () {
    final pool = BattleSplParticlePool(capacity: 8);
    final playback = _playback(_lifecycle(particlePool: pool));
    playback.step(managerFrame: 0);
    expect(pool.inUse, 1);

    playback.cancel();
    playback.cancel();

    expect(pool.inUse, 0);
    expect(playback.particles, isEmpty);
    expect(playback.isComplete, isTrue);
    playback.step(managerFrame: 1);
    expect(pool.inUse, 0);
  });

  test('clears the preview when its lifecycle is cancelled externally', () {
    final lifecycle = _lifecycle();
    final playback = _playback(lifecycle);
    playback.step(managerFrame: 0);
    expect(playback.particles, hasLength(1));

    lifecycle.cancel();
    playback.step(managerFrame: 1);

    expect(playback.isComplete, isTrue);
    expect(playback.particles, isEmpty);
  });

  test('creates and updates children from the live parent state', () {
    final pool = BattleSplParticlePool(capacity: 8);
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 1,
      emissionInterval: 1,
      emissionRate4096: 4096,
      particleLifetime: 3,
      particleLifetimeVariance: 0,
      maxParticles: 8,
      particlePool: pool,
      captureEvents: true,
      child: const BattleSplChildTiming(
        emissionCount: 1,
        emissionDelay256: 0,
        emissionInterval: 1,
        lifetime: 1,
      ),
    );
    final random = BattleSplRandom(seed: 0);
    final playback = _playback(
      lifecycle,
      emitterPosition: (x: 10, y: -20, z: 30),
      childFadeAlpha: true,
      childInitializer: (_, parent) => BattleSplChildInitializer.create(
        random: random,
        parentMotion: parent.motion,
        parentEmitterPosition: parent.emitterPosition,
        parentBaseScale: parent.baseScale4096,
        parentAnimatedScale: parent.scale4096,
        parentBaseAlpha: parent.baseAlpha5,
        parentAnimatedAlpha: parent.animatedAlpha5,
        parentColor: parent.color,
        velocityRatio: 0,
        randomVelocityMagnitude: 0,
        scaleRatio: 79,
        rotation: BattleSplChildRotation.angleAndVelocity,
        lifetime: 1,
        texture: 5,
      ),
    );

    playback.step(managerFrame: 0);
    expect(playback.particles.map((particle) => particle.id), [1, 2]);
    final firstChild = playback.particles.last;
    expect(firstChild.parentId, 1);
    expect(firstChild.motion.position.x, 100);
    expect(firstChild.emitterPosition, (x: 10, y: -20, z: 30));
    expect(firstChild.baseScale4096, 5120);
    expect(firstChild.alpha5, 30);
    expect(firstChild.texture, 5);
    expect(pool.inUse, 2);

    playback.step(managerFrame: 1);
    expect(playback.particles.map((particle) => particle.id), [1, 3]);
    expect(playback.particles.last.motion.position.x, 200);
    expect(pool.inUse, 2);
    playback.cancel();
    expect(pool.inUse, 0);
  });

  test('keeps children after their parent expires', () {
    final pool = BattleSplParticlePool(capacity: 8);
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 1,
      emissionInterval: 1,
      emissionRate4096: 4096,
      particleLifetime: 2,
      particleLifetimeVariance: 0,
      maxParticles: 8,
      particlePool: pool,
      captureEvents: true,
      child: const BattleSplChildTiming(
        emissionCount: 1,
        emissionDelay256: 0,
        emissionInterval: 1,
        lifetime: 5,
      ),
    );
    final random = BattleSplRandom(seed: 0);
    final playback = _playback(
      lifecycle,
      childInitializer: (_, parent) => BattleSplChildInitializer.create(
        random: random,
        parentMotion: parent.motion,
        parentEmitterPosition: parent.emitterPosition,
        parentBaseScale: parent.baseScale4096,
        parentAnimatedScale: parent.scale4096,
        parentBaseAlpha: parent.baseAlpha5,
        parentAnimatedAlpha: parent.animatedAlpha5,
        parentColor: parent.color,
        velocityRatio: 0,
        randomVelocityMagnitude: 0,
        scaleRatio: 63,
        rotation: BattleSplChildRotation.none,
        lifetime: 5,
        texture: 5,
      ),
    );

    playback.step(managerFrame: 0);
    playback.step(managerFrame: 1);
    playback.step(managerFrame: 0);

    expect(playback.particles.map((particle) => particle.id), [4, 3, 2]);
    expect(
      playback.particles.every((particle) => particle.parentId == 1),
      isTrue,
    );
    expect(pool.inUse, 3);
    playback.cancel();
    expect(pool.inUse, 0);
  });

  test('requests alpha randomness in particle update order', () {
    final samples = [0, 255, 128];
    var calls = 0;
    final playback = _playback(
      _lifecycle(),
      alphaRandomRange: 255,
      nextAlphaByte: () => samples[calls++],
    );

    playback.step(managerFrame: 0);
    expect(playback.particles.single.alpha5, 30);
    playback.step(managerFrame: 1);
    expect(calls, 3);
    expect(playback.particles.map((particle) => particle.alpha5), [0, 15]);
  });

  test('consumes alpha draws even when its random range is zero', () {
    final random = BattleSplRandom(seed: 0);
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 4,
      emissionInterval: 2,
      emissionRate4096: 4096,
      particleLifetime: 46,
      particleLifetimeVariance: 0,
      maxParticles: 8,
      captureEvents: true,
    );
    final playback = _playback(
      lifecycle,
      initialMotion: (_) {
        for (var index = 0; index < 6; index++) {
          random.next();
        }
        final rotation = random.next() & 65535;
        random.next();
        return BattleSplParticleMotion(
          position: (x: 0, y: 0, z: 0),
          velocity: (x: 0, y: 0, z: 0),
          rotation: rotation,
          angularVelocity: 0,
        );
      },
      nextAlphaByte: () => random.next() >> 24,
    );

    playback.step(managerFrame: 0);
    playback.step(managerFrame: 1);
    playback.step(managerFrame: 0);

    expect(playback.particles.map((particle) => particle.motion.rotation), [
      27395,
      58657,
    ]);
  });
}

BattleSplEmitterLifecycle _lifecycle({
  bool captureEvents = true,
  BattleSplChildTiming? child,
  BattleSplParticlePool? particlePool,
}) => BattleSplEmitterLifecycle(
  emitterLifetime: 2,
  emissionInterval: 1,
  emissionRate4096: 4096,
  particleLifetime: 3,
  particleLifetimeVariance: 0,
  maxParticles: 8,
  captureEvents: captureEvents,
  child: child,
  particlePool: particlePool,
);

BattleSplPointEmitterPlayback _playback(
  BattleSplEmitterLifecycle lifecycle, {
  BattleSplParticleMotion Function(int id)? initialMotion,
  BattleSplInitialParent Function(int id)? initializeParent,
  int alphaRandomRange = 0,
  int Function()? nextAlphaByte,
  BattleSplVector emitterPosition = (x: 0, y: 0, z: 0),
  bool followEmitter = false,
  bool childFollowsEmitter = false,
  bool childFadeAlpha = false,
  bool alphaAnimationEnabled = true,
  int? childScaleEnd,
  ({BattleSplVector target, int force})? magnet,
  ({BattleSplVector magnitude, int interval})? randomForce,
  BattleSplRandom? random,
  bool childInheritsBehaviors = false,
  BattleSplInitialChild Function(int, BattleSplPointParticle)? childInitializer,
}) => BattleSplPointEmitterPlayback(
  lifecycle: lifecycle,
  loopTime: 2,
  gravity: (x: 0, y: 0, z: 0),
  emitterVelocity: (x: 0, y: 0, z: 0),
  followEmitter: followEmitter,
  childFollowsEmitter: childFollowsEmitter,
  airResistance: 128,
  childFadeAlpha: childFadeAlpha,
  alphaAnimationEnabled: alphaAnimationEnabled,
  childScaleEnd: childScaleEnd,
  magnet: magnet,
  randomForce: randomForce,
  random: random,
  childInheritsBehaviors: childInheritsBehaviors,
  childInitializer: childInitializer,
  initialTexture: 10,
  initializeParent: (id, _, _) =>
      (initializeParent ??
      (id) => (
        motion: initialMotion == null
            ? BattleSplParticleMotion(
                position: (x: 0, y: 0, z: 0),
                velocity: (x: 100, y: 0, z: 0),
                rotation: 0,
                angularVelocity: 0,
              )
            : initialMotion(id),
        emitterPosition: emitterPosition,
        baseScale4096: 4096,
        color: null,
        texture: null,
        lifetime: null,
      ))(id),
  scale: BattleSplScalarAnimation(
    start: 4096,
    middle: 8192,
    end: 4096,
    fadeIn: 128,
    fadeOut: 128,
  ),
  color: BattleSplColorAnimation(
    start: (red: 31, green: 31, blue: 0),
    middle: (red: 31, green: 0, blue: 0),
    end: (red: 0, green: 0, blue: 0),
    fadeIn: 0,
    peak: 128,
    fadeOut: 255,
    interpolate: true,
  ),
  alpha: BattleSplAlphaAnimation(
    start: 31,
    middle: 31,
    end: 31,
    fadeIn: 0,
    fadeOut: 254,
    randomRange: alphaRandomRange,
  ),
  nextAlphaByte: nextAlphaByte ?? () => 0,
  texture: BattleSplTextureAnimation(textures: [10, 11, 12], step: 86),
  textureLoops: true,
);
