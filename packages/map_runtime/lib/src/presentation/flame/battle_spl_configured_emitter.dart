import 'package:map_core/map_core.dart';

import 'battle_spl_child_initializer.dart';
import 'battle_spl_color_texture_animation.dart';
import 'battle_spl_emitter_lifecycle.dart';
import 'battle_spl_particle_motion.dart';
import 'battle_spl_particle_pool.dart';
import 'battle_spl_point_emitter_playback.dart';
import 'battle_spl_random.dart';
import 'battle_spl_scalar_animation.dart';
import 'battle_spl_vector.dart';

final class BattleSplConfiguredEmitter {
  BattleSplConfiguredEmitter._(
    this.playback,
    this._frame,
    this._origin,
    this.aspectRatio4096,
    this.directional,
    this.scaleAxis,
  );

  factory BattleSplConfiguredEmitter({
    required BattleSplEmitterDefinition definition,
    required Map<String, int> textureIndices,
    required BattleSplRandom random,
    required BattleSplParticlePool pool,
  }) {
    final json = definition.toJson();
    final emission = json['emission'] as Map<String, dynamic>;
    final appearance = json['appearance'] as Map<String, dynamic>;
    final motion = json['motion'] as Map<String, dynamic>;
    final scale = appearance['scale'] as Map<String, dynamic>;
    final color = appearance['color'] as Map<String, dynamic>;
    final alpha = appearance['alpha'] as Map<String, dynamic>;
    final textureAnimation =
        appearance['textureAnimation'] as Map<String, dynamic>?;
    final child = json['child'] as Map<String, dynamic>?;
    final names = <String>{
      appearance['initialTexture'] as String,
      if (textureAnimation != null)
        ...(textureAnimation['textures'] as List).cast<String>(),
      if (child != null) child['texture'] as String,
    };
    final indices = <int>{};
    for (final name in names) {
      final index = textureIndices[name];
      if (index == null || index < 0 || index > 255 || !indices.add(index)) {
        throw const FormatException('Invalid SPL texture mapping');
      }
    }
    int textureIndex(Object? name) => textureIndices[name as String]!;
    final initialTexture = textureIndex(appearance['initialTexture']);
    final frames = textureAnimation == null
        ? [initialTexture]
        : (textureAnimation['textures'] as List).map(textureIndex).toList();
    final childTexture = child == null ? null : textureIndex(child['texture']);
    final childTiming = child == null
        ? null
        : BattleSplChildTiming(
            emissionCount: child['emissionCount'] as int,
            emissionDelay256: child['emissionDelay'] as int,
            emissionInterval: child['emissionInterval'] as int,
            lifetime: child['lifetime'] as int,
          );
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: emission['duration'] as int,
      emissionInterval: emission['interval'] as int,
      emissionRate4096: emission['rate'] as int,
      particleLifetime: emission['particleLifetime'] as int,
      particleLifetimeVariance: 0,
      maxParticles: pool.capacity,
      particlePool: pool,
      startDelay: emission['startDelay'] as int,
      autoTerminate: emission['autoTerminate'] as bool,
      captureEvents: true,
      child: childTiming,
    );
    final frame = _EmitterFrame();
    final axis = _vector(emission['axis']);
    final spherical = emission['shape'] == 'sphereSurface';
    final playback = BattleSplPointEmitterPlayback(
      lifecycle: lifecycle,
      loopTime: appearance['loopTime'] as int,
      gravity: _vector(motion['gravity']),
      emitterVelocity: (x: 0, y: 0, z: 0),
      airResistance: motion['airResistance'] as int,
      initialTexture: initialTexture,
      followEmitter: emission['followEmitter'] as bool,
      initializeParent: (_) {
        final position = spherical
            ? BattleSplVectorMath.sphereSurface(
                random,
                radius: emission['radius'] as int,
              )
            : (x: 0, y: 0, z: 0);
        random.vary(0, variance: 0);
        final speed = random.vary(emission['axisVelocity'] as int, variance: 0);
        if (!spherical) BattleSplVectorMath.randomUnitVector(random);
        final baseScale = random.vary(
          appearance['baseScale'] as int,
          variance: emission['scaleVariance'] as int,
        );
        final angle = emission['randomInitialAngle'] as bool
            ? random.next() & 65535
            : emission['initialAngle'] as int;
        random.next();
        return (
          motion: BattleSplParticleMotion(
            position: position,
            velocity: (
              x: (axis.x * speed + 2048) >> 12,
              y: (axis.y * speed + 2048) >> 12,
              z: (axis.z * speed + 2048) >> 12,
            ),
            rotation: angle,
            angularVelocity: 0,
          ),
          emitterPosition: frame.position,
          baseScale4096: baseScale,
        );
      },
      childFadeAlpha: child?['fadeAlpha'] as bool? ?? false,
      childInitializer: child == null
          ? null
          : (_, parent) => BattleSplChildInitializer.create(
              random: random,
              parentMotion: parent.motion,
              parentEmitterPosition: parent.emitterPosition,
              parentBaseScale: parent.baseScale4096,
              parentAnimatedScale: parent.scale4096,
              parentBaseAlpha: parent.baseAlpha5,
              parentAnimatedAlpha: parent.animatedAlpha5,
              parentColor: parent.color,
              velocityRatio: child['velocityRatio'] as int,
              randomVelocityMagnitude: child['randomVelocityMagnitude'] as int,
              scaleRatio: child['scaleRatio'] as int,
              colorOverride: _color(child['color']),
              rotation: switch (child['rotation']) {
                'none' => BattleSplChildRotation.none,
                'angle' => BattleSplChildRotation.angle,
                'angleAndVelocity' => BattleSplChildRotation.angleAndVelocity,
                _ => throw const FormatException('Invalid SPL child rotation'),
              },
              lifetime: child['lifetime'] as int,
              texture: childTexture!,
            ),
      scale: BattleSplScalarAnimation(
        start: scale['start'] as int,
        middle: scale['middle'] as int,
        end: scale['end'] as int,
        fadeIn: scale['fadeIn'] as int,
        fadeOut: scale['fadeOut'] as int,
      ),
      color: BattleSplColorAnimation(
        start: _color(color['start']),
        middle: _color(color['middle']),
        end: _color(color['end']),
        fadeIn: color['fadeIn'] as int,
        peak: color['peak'] as int,
        fadeOut: color['fadeOut'] as int,
        interpolate: color['interpolate'] as bool,
      ),
      alpha: BattleSplAlphaAnimation(
        start: alpha['start'] as int,
        middle: alpha['middle'] as int,
        end: alpha['end'] as int,
        fadeIn: alpha['fadeIn'] as int,
        fadeOut: alpha['fadeOut'] as int,
        randomRange: alpha['randomRange'] as int,
      ),
      texture: BattleSplTextureAnimation(
        textures: frames,
        step: textureAnimation == null ? 255 : textureAnimation['step'] as int,
      ),
      nextAlphaByte: () => random.next() >> 24,
      baseAlpha: appearance['baseAlpha'] as int,
      scaleLoops: scale['loop'] as bool,
      colorLoops: color['loop'] as bool,
      alphaLoops: alpha['loop'] as bool,
      textureLoops: textureAnimation == null
          ? false
          : textureAnimation['loop'] as bool,
    );
    return BattleSplConfiguredEmitter._(
      playback,
      frame,
      _vector(emission['origin']),
      appearance['aspectRatio'] as int,
      appearance['draw'] == 'directionalBillboard',
      appearance['scaleAxis'] as String,
    );
  }

  final BattleSplPointEmitterPlayback playback;
  final _EmitterFrame _frame;
  final BattleSplVector _origin;
  final int aspectRatio4096;
  final bool directional;
  final String scaleAxis;

  void step({
    required int managerFrame,
    required BattleSplVector position,
    BattleSplVector velocity = (x: 0, y: 0, z: 0),
    bool paused = false,
    bool stopEmission = false,
    bool terminate = false,
  }) {
    try {
      int sum(int first, int second) {
        final value = first + second;
        if (value < -2147483648 || value > 2147483647) {
          throw const FormatException('SPL emitter position overflow');
        }
        return value;
      }

      _frame.position = (
        x: sum(position.x, _origin.x),
        y: sum(position.y, _origin.y),
        z: sum(position.z, _origin.z),
      );
      playback.step(
        managerFrame: managerFrame,
        emitterPosition: _frame.position,
        emitterVelocity: velocity,
        paused: paused,
        stopEmission: stopEmission,
        terminate: terminate,
      );
    } catch (_) {
      playback.cancel();
      rethrow;
    }
  }

  void cancel() => playback.cancel();
}

final class _EmitterFrame {
  BattleSplVector position = (x: 0, y: 0, z: 0);
}

BattleSplVector _vector(Object? value) {
  final vector = value as Map<String, dynamic>;
  return (x: vector['x'] as int, y: vector['y'] as int, z: vector['z'] as int);
}

BattleSplRgb5 _color(Object? value) {
  final color = value as Map<String, dynamic>;
  return (
    red: color['red'] as int,
    green: color['green'] as int,
    blue: color['blue'] as int,
  );
}
