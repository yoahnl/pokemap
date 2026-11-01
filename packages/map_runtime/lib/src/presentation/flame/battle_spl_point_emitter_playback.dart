import 'battle_spl_child_initializer.dart';
import 'battle_spl_color_texture_animation.dart';
import 'battle_spl_emitter_lifecycle.dart';
import 'battle_spl_particle_motion.dart';
import 'battle_spl_scalar_animation.dart';

typedef BattleSplInitialParent = ({
  BattleSplParticleMotion motion,
  BattleSplVector emitterPosition,
  int baseScale4096,
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
        baseAlpha > 31) {
      throw const FormatException('Unsupported SPL point emitter playback');
    }
  }

  final BattleSplEmitterLifecycle _lifecycle;
  final int loopTime;
  final BattleSplVector gravity;
  final BattleSplVector emitterVelocity;
  final int airResistance;
  final int initialTexture;
  final BattleSplInitialParent Function(int id) initializeParent;
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

  void step({
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

      final result = _lifecycle.step(
        managerFrame: managerFrame,
        paused: paused,
        stopEmission: stopEmission,
        terminate: terminate,
      );
      final updatedIds = <int>[];
      for (final event in result.events) {
        switch (event.kind) {
          case BattleSplParticleEventKind.parentEmitted:
            final initial = initializeParent(event.particleId);
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
              color: color.start,
              alpha5: baseAlpha,
              texture: initialTexture,
            );
          case BattleSplParticleEventKind.parentUpdated:
            final previous = _particles[event.particleId];
            if (previous == null) {
              throw StateError('SPL particle was not emitted by this playback');
            }
            final phase = BattleSplParticlePhase(
              age: event.age,
              lifetime: _lifecycle.particleLifetime,
              loopTime: loopTime,
            );
            final animatedAlpha = alpha.valueAt(
              lifeRate: alphaLoops ? phase.loop : phase.life,
              randomByte: nextAlphaByte(),
            );
            _particles[event.particleId] = BattleSplPointParticle(
              id: event.particleId,
              motion: previous.motion.advanceWithGravity(
                gravity: gravity,
                emitterVelocity: currentVelocity,
                airResistance: airResistance,
              ),
              emitterPosition: followEmitter
                  ? followingPosition()
                  : previous.emitterPosition,
              baseScale4096: previous.baseScale4096,
              baseAlpha5: previous.baseAlpha5,
              animatedAlpha5: animatedAlpha,
              scale4096: scale.valueAt(scaleLoops ? phase.loop : phase.life),
              color: color.valueAt(colorLoops ? phase.loop : phase.life),
              alpha5: (baseAlpha * (animatedAlpha + 1)) >> 5,
              texture: texture.valueAt(
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
            _particles[event.particleId] = BattleSplPointParticle(
              id: event.particleId,
              parentId: previous.parentId,
              motion: previous.motion.advanceWithGravity(
                gravity: (x: 0, y: 0, z: 0),
                emitterVelocity: currentVelocity,
                airResistance: airResistance,
              ),
              emitterPosition: childFollowsEmitter
                  ? followingPosition()
                  : previous.emitterPosition,
              baseScale4096: previous.baseScale4096,
              baseAlpha5: previous.baseAlpha5,
              animatedAlpha5: animatedAlpha,
              scale4096: 4096,
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
        _drawOrder = List.unmodifiable(
          updatedIds.where(_particles.containsKey).map((id) => _particles[id]!),
        );
      }
      if (result.complete) {
        _particles.clear();
        _drawOrder = const [];
      }
      _complete = result.complete;
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
