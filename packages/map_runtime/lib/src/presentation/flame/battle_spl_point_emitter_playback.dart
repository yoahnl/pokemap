import 'battle_spl_child_initializer.dart';
import 'battle_spl_color_texture_animation.dart';
import 'battle_spl_emitter_lifecycle.dart';
import 'battle_spl_particle_motion.dart';
import 'battle_spl_random.dart';
import 'battle_spl_scalar_animation.dart';

typedef BattleSplInitialParent = ({
  BattleSplParticleMotion motion,
  BattleSplVector emitterPosition,
  int baseScale4096,
  BattleSplRgb5? color,
  int? texture,
  int? lifetime,
});

final class BattleSplPointParticle {
  const BattleSplPointParticle({
    required this.id,
    required this.motion,
    required this.emitterPosition,
    required this.baseScale4096,
    required this.baseAlpha5,
    required this.animatedAlpha5,
    required this.scale4096,
    required this.color,
    required this.alpha5,
    required this.texture,
    this.parentId,
  });

  final int id;
  final BattleSplParticleMotion motion;
  final BattleSplVector emitterPosition;
  final int baseScale4096;
  final int baseAlpha5;
  final int animatedAlpha5;
  final int scale4096;
  final BattleSplRgb5 color;
  final int alpha5;
  final int texture;
  final int? parentId;
}

final class BattleSplPointEmitterPlayback {
  BattleSplPointEmitterPlayback({
    required BattleSplEmitterLifecycle lifecycle,
    required this.loopTime,
    required this.gravity,
    required this.emitterVelocity,
    required this.airResistance,
    required this.initialTexture,
    required this.initializeParent,
    required this.scale,
    required this.color,
    required this.alpha,
    required this.texture,
    required this.nextAlphaByte,
    this.magnet,
    this.convergence,
    this.spin,
    this.collisionPlane,
    this.randomForce,
    this.random,
    this.childScaleEnd,
    this.childInheritsBehaviors = false,
    this.drawChildrenFirst = false,
    this.alphaAnimationEnabled = true,
    this.randomColorStart = false,
    this.randomTextureStart = false,
    this.childInitializer,
    this.childFadeAlpha = false,
    this.followEmitter = false,
    this.childFollowsEmitter = false,
    this.baseAlpha = 31,
    this.scaleLoops = false,
    this.colorLoops = false,
    this.alphaLoops = false,
    this.textureLoops = false,
  }) : _lifecycle = lifecycle {
    if (!lifecycle.captureEvents ||
        (lifecycle.child == null) != (childInitializer == null) ||
        loopTime < 1 ||
        loopTime > 65535 ||
        initialTexture < 0 ||
        initialTexture > 255 ||
        baseAlpha < 0 ||
        baseAlpha > 31 ||
        (childScaleEnd != null && (childScaleEnd! < 0 || childScaleEnd! > 32767)) ||
        (randomForce == null) != (random == null) ||
        (randomForce != null && (randomForce!.interval < 1 ||
            randomForce!.interval > 65535 ||
            [randomForce!.magnitude.x, randomForce!.magnitude.y, randomForce!.magnitude.z]
                .any((value) => value < 0 || value > 32767)))) {
      throw const FormatException('Unsupported SPL point emitter playback');
    }
  }

  final BattleSplEmitterLifecycle _lifecycle;
  final int loopTime;
  final BattleSplVector gravity;
  final ({BattleSplVector target, int force})? magnet;
  final ({BattleSplVector target, int force})? convergence;
  final ({String axis, int sine, int cosine})? spin;
  final ({int height, int elasticity})? collisionPlane;
  final ({BattleSplVector magnitude, int interval})? randomForce;
  final BattleSplRandom? random;
  final int? childScaleEnd;
  final bool childInheritsBehaviors;
  final bool drawChildrenFirst;
  final bool alphaAnimationEnabled;
  final bool randomColorStart;
  final bool randomTextureStart;
  final BattleSplVector emitterVelocity;
  final int airResistance;
  final int initialTexture;
  final BattleSplInitialParent Function(int id, int emissionIndex, int emissionCount)
      initializeParent;
  final BattleSplInitialChild Function(int id, BattleSplPointParticle parent)?
  childInitializer;
  final bool childFadeAlpha;
  final bool followEmitter;
  final bool childFollowsEmitter;
  final BattleSplScalarAnimation scale;
  final BattleSplColorAnimation color;
  final BattleSplAlphaAnimation alpha;
  final BattleSplTextureAnimation texture;
  final int Function() nextAlphaByte;
  final int baseAlpha;
  final bool scaleLoops;
  final bool colorLoops;
  final bool alphaLoops;
  final bool textureLoops;

  final Map<int, BattleSplPointParticle> _particles = {};
  List<BattleSplPointParticle> _drawOrder = const [];
  bool _complete = false;
  bool _failed = false;

  List<BattleSplPointParticle> get particles => _drawOrder;
  bool get isComplete => _complete;

  void cancel() {
    _lifecycle.cancel();
    _particles.clear();
    _drawOrder = const [];
    _complete = true;
  }

  BattleSplEmitterStep step({
    required int managerFrame,
    BattleSplVector? emitterPosition,
    BattleSplVector? emitterVelocity,
    bool paused = false,
    bool stopEmission = false,
    bool terminate = false,
  }) {
    if (_failed) throw StateError('SPL playback has failed');
    try {
      final currentVelocity = emitterVelocity ?? this.emitterVelocity;
      BattleSplVector followingPosition() {
        if (emitterPosition == null || !_validVector(emitterPosition)) {
          throw const FormatException('Invalid SPL emitter position');
        }
        return emitterPosition;
      }
      BattleSplVector randomAcceleration(int age, bool enabled) {
        final force = randomForce;
        if (!enabled || force == null || age % force.interval != 0) {
          return (x: 0, y: 0, z: 0);
        }
        return (
          x: random!.range(force.magnitude.x),
          y: random!.range(force.magnitude.y),
          z: random!.range(force.magnitude.z),
        );
      }

      final initializedParents = <int, BattleSplInitialParent>{};
      final result = _lifecycle.step(
        managerFrame: managerFrame,
        paused: paused,
        stopEmission: stopEmission,
        terminate: terminate,
        initializeLifetime: _lifecycle.particleLifetimeVariance == 0
            ? null
            : (id, index, count) {
                final initial = initializeParent(id, index, count);
                initializedParents[id] = initial;
                return initial.lifetime ??
                    (throw const FormatException('Missing SPL particle lifetime'));
              },
      );
      final updatedIds = <int>[];
      var emissionIndex = 0;
      for (final event in result.events) {
        switch (event.kind) {
          case BattleSplParticleEventKind.parentEmitted:
            final initial = initializedParents.remove(event.particleId) ??
                initializeParent(event.particleId, emissionIndex,
                    result.emittedParents + result.droppedParents);
            emissionIndex++;
            if (initial.baseScale4096 < 0 ||
                initial.baseScale4096 > 32767 ||
                !_validVector(initial.emitterPosition)) {
              throw const FormatException('Invalid SPL parent state');
            }
            _particles[event.particleId] = BattleSplPointParticle(
              id: event.particleId,
              motion: initial.motion,
              emitterPosition: initial.emitterPosition,
              baseScale4096: initial.baseScale4096,
              baseAlpha5: baseAlpha,
              animatedAlpha5: 31,
              scale4096: 4096,
              color: initial.color ?? color.start,
              alpha5: baseAlpha,
              texture: initial.texture ?? initialTexture,
            );
          case BattleSplParticleEventKind.parentUpdated:
            final previous = _particles[event.particleId];
            if (previous == null) {
              throw StateError('SPL particle was not emitted by this playback');
            }
            final phase = BattleSplParticlePhase(
              age: event.age,
              lifetime: event.lifetime,
              loopTime: loopTime,
            );
            final animatedAlpha = alphaAnimationEnabled
                ? alpha.valueAt(
                    lifeRate: alphaLoops ? phase.loop : phase.life,
                    randomByte: nextAlphaByte(),
                  )
                : 31;
            final particleEmitterPosition = followEmitter
                ? followingPosition()
                : previous.emitterPosition;
            _particles[event.particleId] = BattleSplPointParticle(
              id: event.particleId,
              motion: previous.motion.advanceWithGravity(
                gravity: gravity,
                randomAcceleration: randomAcceleration(event.age, true),
                emitterVelocity: currentVelocity,
                airResistance: airResistance,
                magnetTarget: magnet?.target,
                magnetForce: magnet?.force,
                convergenceTarget: convergence?.target,
                convergenceForce: convergence?.force,
                spin: spin,
                collisionPlane: collisionPlane == null ? null : (
                  height: collisionPlane!.height,
                  elasticity: collisionPlane!.elasticity,
                  emitterY: particleEmitterPosition.y,
                ),
              ),
              emitterPosition: particleEmitterPosition,
              baseScale4096: previous.baseScale4096,
              baseAlpha5: previous.baseAlpha5,
              animatedAlpha5: animatedAlpha,
              scale4096: scale.valueAt(scaleLoops ? phase.loop : phase.life),
              color: randomColorStart
                  ? previous.color
                  : color.valueAt(colorLoops ? phase.loop : phase.life),
              alpha5: (baseAlpha * (animatedAlpha + 1)) >> 5,
              texture: randomTextureStart
                  ? previous.texture
                  : texture.valueAt(
                      lifeRate: textureLoops ? phase.loop : phase.life,
                      previousTexture: previous.texture,
                    ),
            );
            updatedIds.add(event.particleId);
          case BattleSplParticleEventKind.parentExpired:
            _particles.remove(event.particleId);
          case BattleSplParticleEventKind.childEmitted:
            final parent = _particles[event.parentId];
            if (parent == null || childInitializer == null) {
              throw StateError('SPL child has no live parent');
            }
            final initial = childInitializer!(event.particleId, parent);
            if (initial.lifetime != _lifecycle.child!.lifetime) {
              throw const FormatException('SPL child lifetime mismatch');
            }
            _particles[event.particleId] = BattleSplPointParticle(
              id: event.particleId,
              parentId: event.parentId,
              motion: initial.motion,
              emitterPosition: initial.emitterPosition,
              baseScale4096: initial.baseScale4096,
              baseAlpha5: initial.baseAlpha5,
              animatedAlpha5: 31,
              scale4096: 4096,
              color: initial.color,
              alpha5: initial.baseAlpha5,
              texture: initial.texture,
            );
          case BattleSplParticleEventKind.childUpdated:
            final previous = _particles[event.particleId];
            if (previous == null || previous.parentId != event.parentId) {
              throw StateError('SPL child was not emitted by this playback');
            }
            final lifeRate =
                ((event.age * 256) ~/ _lifecycle.child!.lifetime) & 255;
            final animatedAlpha = childFadeAlpha
                ? ((255 - lifeRate) * 31) ~/ 255
                : 31;
            final animatedScale = childScaleEnd == null
                ? 4096
                : childScaleEnd! + ((childScaleEnd! - 4096) * (lifeRate - 255)) ~/ 255;
            final particleEmitterPosition = childFollowsEmitter
                ? followingPosition()
                : previous.emitterPosition;
            _particles[event.particleId] = BattleSplPointParticle(
              id: event.particleId,
              parentId: previous.parentId,
              motion: previous.motion.advanceWithGravity(
                gravity: childInheritsBehaviors ? gravity : (x: 0, y: 0, z: 0),
                randomAcceleration: randomAcceleration(event.age, childInheritsBehaviors),
                emitterVelocity: currentVelocity,
                airResistance: airResistance,
                magnetTarget: childInheritsBehaviors ? magnet?.target : null,
                magnetForce: childInheritsBehaviors ? magnet?.force : null,
                convergenceTarget: childInheritsBehaviors ? convergence?.target : null,
                convergenceForce: childInheritsBehaviors ? convergence?.force : null,
                spin: childInheritsBehaviors ? spin : null,
                collisionPlane: !childInheritsBehaviors || collisionPlane == null
                    ? null
                    : (
                        height: collisionPlane!.height,
                        elasticity: collisionPlane!.elasticity,
                        emitterY: particleEmitterPosition.y,
                      ),
              ),
              emitterPosition: particleEmitterPosition,
              baseScale4096: previous.baseScale4096,
              baseAlpha5: previous.baseAlpha5,
              animatedAlpha5: animatedAlpha,
              scale4096: animatedScale,
              color: previous.color,
              alpha5: (previous.baseAlpha5 * (animatedAlpha + 1)) >> 5,
              texture: previous.texture,
            );
            updatedIds.add(event.particleId);
          case BattleSplParticleEventKind.childExpired:
            _particles.remove(event.particleId);
        }
      }
      if (updatedIds.isNotEmpty) {
        final particles = updatedIds
            .where(_particles.containsKey)
            .map((id) => _particles[id]!)
            .toList();
        _drawOrder = List.unmodifiable(
          drawChildrenFirst
              ? [
                  ...particles.where((particle) => particle.parentId != null),
                  ...particles.where((particle) => particle.parentId == null),
                ]
              : particles,
        );
      }
      if (result.complete) {
        _particles.clear();
        _drawOrder = const [];
      }
      _complete = result.complete;
      return result;
    } catch (_) {
      _failed = true;
      cancel();
      rethrow;
    }
  }

  static bool _validVector(BattleSplVector vector) =>
      vector.x >= -2147483648 &&
      vector.x <= 2147483647 &&
      vector.y >= -2147483648 &&
      vector.y <= 2147483647 &&
      vector.z >= -2147483648 &&
      vector.z <= 2147483647;
}
