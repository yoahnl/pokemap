import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_configured_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_emitter_lifecycle.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_pool.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_point_preview_painter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';

void main() {
  test('keeps directional stretch through the experimental emitter frame', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 18;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['positionVelocity'] = 0;
    emission['emissionAxis'] = 'z';
    emission['velocityVariance'] = 0;
    emission['particleLifetimeVariance'] = 0;
    final appearance = source['appearance'] as Map;
    appearance['draw'] = 'directionalBillboard';
    appearance['directionStretch'] = 15714;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['drawChildrenFirst'] = false;
    (source['motion'] as Map)['magnet'] = null;
    source['child'] = null;
    final prepared = BattleSplStaticAdmission.prepare(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw),
      textureIndices: const {'tex': 0},
      emitters: const [BattleSplStaticEmitter(
        emitterIndex: 0, startTick: 0, position: (x: 0, y: 0, z: 0),
      )],
      seed: 0, poolCapacity: 64, maxTicks: 120,
    );
    expect(prepared.failure, isNull);
    final playback = prepared.playback!;
    expect(playback.frames.single.directionStretch4096, 15714);
    playback.cancel();
  });

  test('emits the source ring perpendicular to a tilted emitter axis', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 17;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['shape'] = 'circleBorderUniform';
    emission['radius'] = 4096;
    emission['axis'] = {'x': -2896, 'y': 2896, 'z': 0};
    emission['rate'] = 4 * 4096;
    emission['startDelay'] = 0;
    emission['duration'] = 1;
    emission['axisVelocity'] = 0;
    emission['positionVelocity'] = 0;
    emission['emissionAxis'] = 'emitter';
    emission['velocityVariance'] = 0;
    emission['particleLifetimeVariance'] = 0;
    final appearance = source['appearance'] as Map;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['drawChildrenFirst'] = false;
    final motion = source['motion'] as Map;
    motion['magnet'] = null;
    motion['gravity'] = {'x': 0, 'y': 0, 'z': 0};
    motion['airResistance'] = 128;
    source['child'] = null;
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw).emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: BattleSplParticlePool(capacity: 4),
    );
    emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final particles = [...emitter.playback.particles]..sort((a, b) => a.id.compareTo(b.id));
    expect(particles.map((particle) => particle.motion.position), [
      (x: -2896, y: -2896, z: 0),
      (x: 0, y: 0, z: -4096),
      (x: 2896, y: 2896, z: 0),
      (x: 0, y: 0, z: 4096),
    ]);
    emitter.cancel();
  });

  test('applies BW2 random forces and consumes all three random values', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 14;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['shape'] = 'point';
    emission['radius'] = 0;
    emission['axisVelocity'] = 0;
    emission['positionVelocity'] = 0;
    emission['emissionAxis'] = 'z';
    emission['velocityVariance'] = 0;
    emission['particleLifetimeVariance'] = 0;
    emission['duration'] = 1;
    emission['particleLifetime'] = 3;
    final appearance = source['appearance'] as Map;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['drawChildrenFirst'] = false;
    appearance['hasAlphaAnimation'] = false;
    final motion = source['motion'] as Map;
    motion['magnet'] = null;
    motion['gravity'] = {'x': 0, 'y': 0, 'z': 0};
    motion['airResistance'] = 128;
    source['child'] = null;
    ({BattleSplConfiguredEmitter emitter, BattleSplRandom random}) create(int? magnitude) {
      if (magnitude == null) {
        motion.remove('random');
      } else {
        motion['random'] = {
          'magnitude': {'x': magnitude, 'y': 0, 'z': 0},
          'applyInterval': 2,
        };
      }
      final random = BattleSplRandom(seed: 0);
      return (
        emitter: BattleSplConfiguredEmitter(
          definition: BattleSplParticleDefinition.fromExperimentalJson(raw).emitters.single,
          textureIndices: const {'tex': 0}, random: random,
          pool: BattleSplParticlePool(capacity: 64),
        ),
        random: random,
      );
    }
    final baseline = create(null);
    final zero = create(0);
    final moving = create(1000);
    for (final item in [baseline, zero, moving]) {
      item.emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    }
    final expected = BattleSplRandom(seed: baseline.random.state);
    final x = expected.range(1000);
    expected.range(0);
    expected.range(0);
    expect(moving.emitter.playback.particles.single.motion.position.x, x);
    expect(moving.random.state, expected.state);
    expect(zero.random.state, expected.state);
    final afterFirst = expected.state;
    for (final item in [baseline, zero, moving]) {
      item.emitter.step(managerFrame: 1, position: (x: 0, y: 0, z: 0));
    }
    expect(moving.random.state, afterFirst);
    expect(zero.random.state, afterFirst);
    final nextX = expected.range(1000);
    expected.range(0);
    expected.range(0);
    for (final item in [baseline, zero, moving]) {
      item.emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    }
    expect(moving.random.state, expected.state);
    expect(zero.random.state, expected.state);
    expect(moving.emitter.playback.particles.single.motion.position.x,
        3 * x + nextX);
    for (final item in [baseline, zero, moving]) { item.emitter.cancel(); }
  });

  test('applies parsed BW2 child following independently of the parent', () async {
    final fixture = await File('../map_core/test/fixtures/spl_particle_v2.json')
        .readAsString();
    for (final follows in [false, true]) {
      final raw = jsonDecode(fixture) as Map<String, dynamic>;
      raw['schemaVersion'] = 11;
      final source = (raw['emitters'] as List).single as Map<String, dynamic>;
      final emission = source['emission'] as Map;
      emission['positionVelocity'] = 0;
      emission['emissionAxis'] = 'z';
      emission['velocityVariance'] = 0;
      emission['particleLifetimeVariance'] = 0;
      emission['duration'] = 1;
      emission['particleLifetime'] = 3;
      emission['followEmitter'] = false;
      final appearance = source['appearance'] as Map;
      appearance['hasRotation'] = false;
      appearance['minRotation'] = 0;
      appearance['maxRotation'] = 0;
      appearance['dirFromPosition'] = false;
      appearance['drawChildrenFirst'] = false;
      (source['motion'] as Map)['magnet'] = null;
      source['child'] = {
        'velocityRatio': 0,
        'randomVelocityMagnitude': 0,
        'scaleRatio': 16,
        'color': {'red': 19, 'green': 23, 'blue': 27},
        'rotation': 'none',
        'lifetime': 3,
        'texture': 'tex',
        'emissionCount': 1,
        'emissionDelay': 0,
        'emissionInterval': 1,
        'fadeAlpha': false,
        'scaleEnd': null,
        'inheritBehaviors': false,
        'draw': 'billboard',
        'inheritColor': false,
        'followEmitter': follows,
      };
      final emitter = BattleSplConfiguredEmitter(
        definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
            .emitters.single,
        textureIndices: const {'tex': 0},
        random: BattleSplRandom(seed: 0),
        pool: BattleSplParticlePool(capacity: 64),
      );
      emitter.step(managerFrame: 0, position: (x: 10, y: 0, z: 0));
      final childId = emitter.playback.particles.firstWhere(
        (particle) => particle.parentId != null,
      ).id;
      emitter.step(managerFrame: 1, position: (x: 30, y: 0, z: 0));
      final child = emitter.playback.particles.singleWhere(
        (particle) => particle.id == childId,
      );
      expect(child.emitterPosition.x, follows ? 30 : 10);
      emitter.cancel();
    }
  });

  test('places BW2 volume emitters and directs cylinder particles from their full position', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 9;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['radius'] = 4096;
    emission['positionVelocity'] = 0;
    emission['axisVelocity'] = 0;
    emission['emissionAxis'] = 'y';
    emission['velocityVariance'] = 0;
    emission['particleLifetimeVariance'] = 0;
    emission['duration'] = 1;
    final appearance = source['appearance'] as Map;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['drawChildrenFirst'] = false;
    appearance['hasAlphaAnimation'] = false;
    (source['motion'] as Map)['magnet'] = null;

    for (final entry in {
      'circleDisk': (x: 330, y: 0, z: -3152),
      'sphereVolume': (x: -446, y: 614, z: -510),
      'hemisphereVolume': (x: 1408, y: 1499, z: -593),
      'cylinderVolume': (x: 330, y: 1056, z: -3152),
    }.entries) {
      emission['shape'] = entry.key;
      if (entry.key == 'cylinderVolume') emission['length'] = 4096;
      final emitter = BattleSplConfiguredEmitter(
        definition: BattleSplParticleDefinition.fromExperimentalJson(raw).emitters.single,
        textureIndices: const {'tex': 0},
        random: BattleSplRandom(seed: 0),
        pool: BattleSplParticlePool(capacity: 64),
      );
      emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
      expect(emitter.playback.particles.single.motion.position, entry.value);
      emitter.cancel();
    }

    emission['positionVelocity'] = 4096;
    final moving = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw).emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: BattleSplParticlePool(capacity: 64),
    );
    moving.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    expect(moving.playback.particles.single.motion.velocity.y, greaterThan(0));
    moving.cancel();
  });

  test('places BW2 cylinder particles with a deterministic radial direction', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 8;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['shape'] = 'cylinderSurface';
    emission['radius'] = 4096;
    emission['length'] = 4096;
    emission['positionVelocity'] = 0;
    emission['axisVelocity'] = 0;
    emission['emissionAxis'] = 'y';
    emission['velocityVariance'] = 0;
    emission['particleLifetimeVariance'] = 0;
    emission['duration'] = 1;
    final appearance = source['appearance'] as Map;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['drawChildrenFirst'] = false;
    appearance['hasAlphaAnimation'] = false;
    (source['motion'] as Map)['magnet'] = null;
    final random = BattleSplRandom(seed: 0);
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
          .emitters.single,
      textureIndices: const {'tex': 0},
      random: random,
      pool: BattleSplParticlePool(capacity: 64),
    );
    emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    expect(emitter.playback.particles.single.motion.position,
        (x: -2417, y: 3904, z: -3307));
    expect(random.state, 0xdd3de521);
    emitter.cancel();

    emission['radius'] = 0;
    emission['length'] = 0;
    emission['positionVelocity'] = 4096;
    final zeroRadius = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
          .emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: BattleSplParticlePool(capacity: 64),
    );
    zeroRadius.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final moved = zeroRadius.playback.particles.single.motion.position;
    expect(moved.y, 0);
    expect(moved.x.abs(), greaterThan(0));
    expect(moved.z.abs(), greaterThan(0));
    zeroRadius.cancel();
  });

  test('uses each BW2 particle lifetime for animation and child timing', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 7;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['positionVelocity'] = 0;
    emission['emissionAxis'] = 'z';
    emission['velocityVariance'] = 0;
    emission['particleLifetimeVariance'] = 255;
    emission['particleLifetime'] = 12;
    emission['rate'] = 8192;
    emission['duration'] = 1;
    final appearance = source['appearance'] as Map;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['drawChildrenFirst'] = false;
    appearance['hasAlphaAnimation'] = false;
    appearance['randomTextureStart'] = true;
    appearance['textureAnimation'] = {
      'textures': ['tex', 'tex2', 'tex3'],
      'step': 64,
      'loop': true,
    };
    appearance['scale'] = {
      'start': 0,
      'middle': 4096,
      'end': 4096,
      'fadeIn': 128,
      'fadeOut': 128,
      'loop': false,
    };
    (source['motion'] as Map)['magnet'] = null;
    source['child'] = {
      'velocityRatio': 0,
      'randomVelocityMagnitude': 0,
      'scaleRatio': 64,
      'color': {'red': 31, 'green': 0, 'blue': 0},
      'rotation': 'none',
      'lifetime': 1,
      'texture': 'tex',
      'emissionCount': 1,
      'emissionDelay': 128,
      'emissionInterval': 20,
      'fadeAlpha': false,
      'scaleEnd': null,
      'inheritBehaviors': false,
      'draw': 'billboard',
      'inheritColor': false,
    };
    final random = BattleSplRandom(seed: 0);
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
          .emitters.single,
      textureIndices: const {'tex': 0, 'tex2': 1, 'tex3': 2},
      random: random,
      pool: BattleSplParticlePool(capacity: 64),
    );
    final expired = <int, int>{};
    final childFrames = <int, int>{};
    for (var frame = 0; frame <= 9; frame++) {
      final result = emitter.step(
        managerFrame: frame % 2,
        position: (x: 0, y: 0, z: 0),
      );
      if (frame == 0) {
        expect(
          {for (final p in emitter.playback.particles) p.id: p.texture},
          {1: 0, 2: 2},
        );
        expect(random.state, 0x1df33750);
      }
      if (frame == 1) {
        final parents = emitter.playback.particles.where((p) => p.parentId == null);
        expect({for (final p in parents) p.id: p.scale4096}, {1: 4064, 2: 896});
      }
      for (final event in result.events) {
        if (event.kind == BattleSplParticleEventKind.parentExpired) {
          expired[event.particleId] = frame;
        }
        if (event.kind == BattleSplParticleEventKind.childEmitted) {
          childFrames[event.parentId!] = frame;
        }
      }
    }
    expect(expired, {1: 2, 2: 9});
    expect(childFrames, {1: 1, 2: 5});
    emitter.cancel();
  });

  test('keeps each randomly selected BW2 texture for the particle lifetime', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 6;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['positionVelocity'] = 0;
    emission['emissionAxis'] = 'z';
    emission['velocityVariance'] = 0;
    emission['duration'] = 1;
    final appearance = source['appearance'] as Map;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['drawChildrenFirst'] = false;
    appearance['randomTextureStart'] = true;
    appearance['textureAnimation'] = {
      'textures': ['tex', 'tex2', 'tex3'],
      'step': 64,
      'loop': true,
    };
    (source['motion'] as Map)['magnet'] = null;
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
          .emitters.single,
      textureIndices: const {'tex': 0, 'tex2': 1, 'tex3': 2},
      random: BattleSplRandom(seed: 0),
      pool: BattleSplParticlePool(capacity: 64),
    );
    emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final initialTexture = emitter.playback.particles.single.texture;
    expect([0, 1, 2], contains(initialTexture));
    emitter.step(managerFrame: 1, position: (x: 0, y: 0, z: 0));
    expect(emitter.playback.particles.single.texture, initialTexture);
    emitter.cancel();
  });

  test('keeps each randomly selected BW2 color for the particle lifetime', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 6;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['positionVelocity'] = 0;
    emission['emissionAxis'] = 'z';
    emission['velocityVariance'] = 0;
    emission['duration'] = 1;
    final appearance = source['appearance'] as Map;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['drawChildrenFirst'] = false;
    appearance['randomColorStart'] = true;
    (source['motion'] as Map)['magnet'] = null;
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
          .emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: BattleSplParticlePool(capacity: 64),
    );
    emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final particle = emitter.playback.particles.single;
    final initialColor = particle.color;
    expect(
      [
        (red: 31, green: 16, blue: 0),
        (red: 31, green: 8, blue: 0),
        (red: 0, green: 0, blue: 0),
      ],
      contains(initialColor),
    );
    emitter.step(managerFrame: 1, position: (x: 0, y: 0, z: 0));
    expect(emitter.playback.particles.single.color, initialColor);
    emitter.cancel();
  });

  test('leaves alpha unchanged when the BW2 source has no alpha animation', () async {
    final fixture = await File('../map_core/test/fixtures/spl_particle_v2.json')
        .readAsString();
    BattleSplConfiguredEmitter create({required bool animate}) {
      final raw = jsonDecode(fixture) as Map<String, dynamic>;
      raw['schemaVersion'] = 6;
      final source = (raw['emitters'] as List).single as Map<String, dynamic>;
      final emission = source['emission'] as Map;
      emission['positionVelocity'] = 0;
      emission['emissionAxis'] = 'z';
      emission['velocityVariance'] = 0;
      final appearance = source['appearance'] as Map;
      appearance['hasRotation'] = false;
      appearance['minRotation'] = 0;
      appearance['maxRotation'] = 0;
      appearance['dirFromPosition'] = false;
      appearance['drawChildrenFirst'] = false;
      appearance['hasAlphaAnimation'] = animate;
      (source['motion'] as Map)['magnet'] = null;
      return BattleSplConfiguredEmitter(
        definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
            .emitters.single,
        textureIndices: const {'tex': 0},
        random: BattleSplRandom(seed: 0),
        pool: BattleSplParticlePool(capacity: 64),
      );
    }

    final noAnimation = create(animate: false);
    final animated = create(animate: true);
    noAnimation.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    animated.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    expect(noAnimation.playback.particles.single.alpha5, 31);
    expect(animated.playback.particles.single.alpha5, 30);
    noAnimation.cancel();
    animated.cancel();
  });

  test('rotates BW2 particles around the declared axis', () async {
    final fixture = await File('../map_core/test/fixtures/spl_particle_v2.json')
        .readAsString();
    BattleSplConfiguredEmitter create({required bool spinning}) {
      final raw = jsonDecode(fixture) as Map<String, dynamic>;
      raw['schemaVersion'] = 6;
      final source = (raw['emitters'] as List).single as Map<String, dynamic>;
      final emission = source['emission'] as Map;
      emission['shape'] = 'sphereSurface';
      emission['radius'] = 4096;
      emission['axisVelocity'] = 0;
      emission['positionVelocity'] = 0;
      emission['emissionAxis'] = 'z';
      emission['velocityVariance'] = 0;
      emission['duration'] = 1;
      final appearance = source['appearance'] as Map;
      appearance['hasRotation'] = false;
      appearance['minRotation'] = 0;
      appearance['maxRotation'] = 0;
      appearance['dirFromPosition'] = false;
      appearance['drawChildrenFirst'] = false;
      final motion = source['motion'] as Map;
      motion['magnet'] = null;
      if (spinning) motion['spin'] = {'axis': 'y', 'angle': 16384};
      return BattleSplConfiguredEmitter(
        definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
            .emitters.single,
        textureIndices: const {'tex': 0},
        random: BattleSplRandom(seed: 0),
        pool: BattleSplParticlePool(capacity: 64),
      );
    }

    final original = create(spinning: false);
    final spinning = create(spinning: true);
    original.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    spinning.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final before = original.playback.particles.single.motion.position;
    final after = spinning.playback.particles.single.motion.position;
    expect(after, (x: before.z, y: before.y, z: -before.x));
    original.cancel();
    spinning.cancel();
  });

  test('preserves BW2 child color inheritance and particle draw order', () async {
    final fixture = await File('../map_core/test/fixtures/spl_particle_v2.json')
        .readAsString();
    for (final drawChildrenFirst in [false, true]) {
      for (final inheritColor in [false, true]) {
        final raw = jsonDecode(fixture) as Map<String, dynamic>;
        raw['schemaVersion'] = 6;
        final source = (raw['emitters'] as List).single as Map<String, dynamic>;
        final emission = source['emission'] as Map;
        emission['positionVelocity'] = 0;
        emission['emissionAxis'] = 'z';
        emission['velocityVariance'] = 0;
        emission['duration'] = 1;
        final appearance = source['appearance'] as Map;
        appearance['hasRotation'] = false;
        appearance['minRotation'] = 0;
        appearance['maxRotation'] = 0;
        appearance['dirFromPosition'] = false;
        appearance['drawChildrenFirst'] = drawChildrenFirst;
        final color = appearance['color'] as Map;
        for (final key in ['start', 'middle', 'end']) {
          color[key] = {'red': 3, 'green': 7, 'blue': 11};
        }
        (source['motion'] as Map)['magnet'] = null;
        source['child'] = {
          'velocityRatio': 0,
          'randomVelocityMagnitude': 0,
          'scaleRatio': 16,
          'color': {'red': 19, 'green': 23, 'blue': 27},
          'rotation': 'none',
          'lifetime': 3,
          'texture': 'tex',
          'emissionCount': 1,
          'emissionDelay': 0,
          'emissionInterval': 1,
          'fadeAlpha': false,
          'scaleEnd': null,
          'inheritBehaviors': false,
          'draw': 'billboard',
          'inheritColor': inheritColor,
        };
        final emitter = BattleSplConfiguredEmitter(
          definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
              .emitters.single,
          textureIndices: const {'tex': 0},
          random: BattleSplRandom(seed: 0),
          pool: BattleSplParticlePool(capacity: 64),
        );
        emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
        final particles = emitter.playback.particles;
        expect(particles, hasLength(2));
        final parent = particles.singleWhere((particle) => particle.parentId == null);
        final child = particles.singleWhere((particle) => particle.parentId != null);
        expect(particles.first.parentId != null, drawChildrenFirst);
        expect(
          child.color,
          inheritColor ? parent.color : (red: 19, green: 23, blue: 27),
        );
        emitter.cancel();
      }
    }
  });

  test('emits a uniform BW2 ring even if the particle pool is exhausted', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 5;
    final definition = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = definition['emission'] as Map;
    emission['shape'] = 'circleBorderUniform';
    emission['radius'] = 4096;
    emission['axis'] = {'x': 0, 'y': 4096, 'z': 0};
    emission['rate'] = 4 * 4096;
    emission['duration'] = 1;
    emission['axisVelocity'] = 0;
    emission['positionVelocity'] = 0;
    emission['emissionAxis'] = 'y';
    emission['velocityVariance'] = 0;
    emission['origin'] = {'x': 0, 'y': -3350, 'z': 0};
    final appearance = definition['appearance'] as Map;
    appearance['hasRotation'] = false;
    appearance['minRotation'] = 0;
    appearance['maxRotation'] = 0;
    appearance['dirFromPosition'] = false;
    appearance['relativeToBasePos'] = true;
    (definition['motion'] as Map)['magnet'] = null;
    final parsed = BattleSplParticleDefinition.fromExperimentalJson(raw);
    BattleSplConfiguredEmitter make(int capacity) => BattleSplConfiguredEmitter(
      definition: parsed.emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: BattleSplParticlePool(capacity: capacity),
    );
    final full = make(4);
    expect(full.relativeBasePosition, (x: 0, y: -3350, z: 0));
    full.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final positions = [...full.playback.particles]..sort((a, b) => a.id.compareTo(b.id));
    expect(positions.map((p) => p.motion.position), [
      (x: -4096, y: 0, z: 0),
      (x: 0, y: 0, z: -4096),
      (x: 4096, y: 0, z: 0),
      (x: 0, y: 0, z: 4096),
    ]);
    full.cancel();

    final limited = make(2);
    final step = limited.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    expect(step.droppedParents, 2);
    final partial = [...limited.playback.particles]..sort((a, b) => a.id.compareTo(b.id));
    expect(partial.map((p) => p.motion.position), [
      (x: -4096, y: 0, z: 0),
      (x: 0, y: 0, z: -4096),
    ]);
    limited.cancel();
  });

  test(
    'plays and paints BW2 source emitter 222/2 with its original texture',
    () async {
      const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
      const path = 'res/particles/btlv_effvm_particles/222';
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      Future<Uint8List> source(String name, String hash) async {
        final request = await client
            .getUrl(
              Uri.https(
                'raw.githubusercontent.com',
                '/fuddlesworth/pokebw2/$revision/$path/$name',
              ),
            )
            .timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
        expect(response.statusCode, HttpStatus.ok);
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.timeout(
          const Duration(seconds: 20),
        )) {
          if (bytes.length + chunk.length > 262144) {
            throw const FormatException('Particle source too large');
          }
          bytes.add(chunk);
        }
        final result = bytes.takeBytes();
        expect(sha256.convert(result).toString(), hash);
        return result;
      }

      final original = await source(
        'particles.json',
        '3e191c2e53d6eb9ff35b21e232c3ff8371516d09d4a55e8d0595cd43c149b8cc',
      );
      final png = await source(
        'texture00.png',
        '93949a859e9770ad42aa1c728d157cf9d48f55b12bfad45264db1f0989575cae',
      );
      final converted = Gen5SplParticleConverter.convert(
        original,
        particleId: 222,
        sourceRevision: revision,
        sourcePath: '$path/particles.json',
        expectedSha256:
            '3e191c2e53d6eb9ff35b21e232c3ff8371516d09d4a55e8d0595cd43c149b8cc',
        textureResourceIds: const {
          'texture00': 'texture00',
          'texture01': 'texture01',
          'texture02': 'texture02',
          'texture03': 'texture03',
        },
        experimentalSourceEmitterIndices: const [2],
      );
      expect(converted.sourceEmitterIndices, [2]);
      final prepared = BattleSplStaticAdmission.prepare(
        definition: converted.definition,
        textureIndices: const {'texture00': 0},
        emitters: const [
          BattleSplStaticEmitter(
            emitterIndex: 0,
            startTick: 0,
            position: (x: 0, y: 0, z: 0),
          ),
        ],
        seed: 0,
        poolCapacity: 64,
        maxTicks: 100,
      );
      expect(prepared.failure, isNull);
      final playback = prepared.playback!;
      for (var tick = 0; tick < 6; tick++) {
        expect(playback.advance(), isNull);
      }
      final frame = playback.frames.single;
      expect(frame.particles, isNotEmpty);
      final codec = await ui.instantiateImageCodec(png);
      final texture = (await codec.getNextFrame()).image;
      codec.dispose();
      final recorder = ui.PictureRecorder();
      BattleSplPointPreviewPainter(
        textures: {0: texture},
        pixelsPerUnit: 16,
        aspectRatio4096: frame.aspectRatio4096,
        directionalParents: frame.directional,
        directionalChildren: frame.childDirectional,
      ).paint(
        ui.Canvas(recorder),
        origin: const ui.Offset(64, 64),
        particles: frame.particles,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(128, 128);
      try {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba, isNotNull);
        final pixelBytes = rgba!.buffer.asUint8List();
        expect(
          [for (var i = 3; i < pixelBytes.length; i += 4) pixelBytes[i]]
              .any((alpha) => alpha != 0),
          isTrue,
        );
      } finally {
        image.dispose();
        picture.dispose();
        texture.dispose();
      }
      while (!playback.isComplete) {
        expect(playback.advance(), isNull);
      }
      playback.cancel();
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1',
  );

  test(
    'samples the BW2 circle border in the declared emission plane',
    () async {
      final raw = jsonDecode(
        await File('../map_core/test/fixtures/spl_particle_v2.json')
            .readAsString(),
      ) as Map<String, dynamic>;
      raw['schemaVersion'] = 5;
      final source = (raw['emitters'] as List).single as Map<String, dynamic>;
      final emission = source['emission'] as Map;
      emission['shape'] = 'circleBorder';
      emission['radius'] = 4096;
      emission['axisVelocity'] = 0;
      emission['positionVelocity'] = 0;
      emission['emissionAxis'] = 'y';
      emission['velocityVariance'] = 0;
      final appearance = source['appearance'] as Map;
      appearance['hasRotation'] = false;
      appearance['minRotation'] = 0;
      appearance['maxRotation'] = 0;
      appearance['dirFromPosition'] = false;
      (source['motion'] as Map)['magnet'] = null;
      final emitter = BattleSplConfiguredEmitter(
        definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
            .emitters
            .single,
        textureIndices: const {'tex': 0},
        random: BattleSplRandom(seed: 0),
        pool: BattleSplParticlePool(capacity: 64),
      );
      emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
      expect(emitter.playback.particles.single.motion.position, (
        x: -2417,
        y: 0,
        z: -3307,
      ));
      emitter.cancel();
    },
  );

  test('plays the two selected BW2 220 emitters with deterministic source parameters', () async {
    const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
    const path = 'res/particles/btlv_effvm_particles/220/particles.json';
    const hash =
        'c50300370f0a622a514d45bea7cce595d4794d2197122cdc8ee90cb6c8a0afb1';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client
        .getUrl(
          Uri.https(
            'raw.githubusercontent.com',
            '/fuddlesworth/pokebw2/$revision/$path',
          ),
        )
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 20));
    expect(response.statusCode, HttpStatus.ok);
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (bytes.length + chunk.length > 262144) {
        throw const FormatException('Particle source too large');
      }
      bytes.add(chunk);
    }
    final result = Gen5SplParticleConverter.convert(
      bytes.takeBytes(),
      particleId: 220,
      sourceRevision: revision,
      sourcePath: path,
      expectedSha256: hash,
      textureResourceIds: const {
        'texture00': 'texture00',
        'texture01': 'texture01',
        'texture02': 'texture02',
      },
      experimentalSourceEmitterIndices: const [0, 1],
    );
    expect(result.sourceEmitterIndices, [0, 1]);
    final admission = BattleSplStaticAdmission.prepare(
      definition: result.definition,
      textureIndices: const {'texture00': 0, 'texture01': 1},
      emitters: const [
        BattleSplStaticEmitter(
          emitterIndex: 0,
          startTick: 0,
          position: (x: 0, y: 0, z: 0),
        ),
        BattleSplStaticEmitter(
          emitterIndex: 1,
          startTick: 0,
          position: (x: 0, y: 0, z: 0),
        ),
      ],
      seed: 0,
      poolCapacity: 128,
      maxTicks: 150,
    );
    expect(admission.failure, isNull);
    final playback = admission.playback!;
    final textures = <int, ui.Image>{};
    addTearDown(() {
      for (final image in textures.values) {
        image.dispose();
      }
    });
    const textureHashes = {
      0: '435763858fb1c993fab93f50bad385f6fcc54e28387df7dcc6763190ed1e64c0',
      1: 'ebce49dd55ea712ac46fa7032218fce2e8109062ff6380c55257172d6e0d44f0',
    };
    for (final entry in textureHashes.entries) {
      final textureRequest = await client
          .getUrl(
            Uri.https(
              'raw.githubusercontent.com',
              '/fuddlesworth/pokebw2/$revision/res/particles/btlv_effvm_particles/220/texture0${entry.key}.png',
            ),
          )
          .timeout(const Duration(seconds: 20));
      textureRequest.followRedirects = false;
      final textureResponse = await textureRequest.close().timeout(
        const Duration(seconds: 20),
      );
      expect(textureResponse.statusCode, HttpStatus.ok);
      final input = BytesBuilder(copy: false);
      await for (final chunk in textureResponse.timeout(
        const Duration(seconds: 20),
      )) {
        if (input.length + chunk.length > 1024 * 1024) {
          throw const FormatException('Particle texture too large');
        }
        input.add(chunk);
      }
      final textureBytes = input.takeBytes();
      expect(sha256.convert(textureBytes).toString(), entry.value);
      final codec = await ui.instantiateImageCodec(textureBytes);
      try {
        textures[entry.key] = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    }
    for (var tick = 0; tick < 10; tick++) {
      expect(playback.advance(), isNull);
    }
    for (final frame in playback.frames) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      BattleSplPointPreviewPainter(
        textures: textures,
        pixelsPerUnit: 16,
        aspectRatio4096: frame.aspectRatio4096,
        directionalParents: frame.directional,
        directionalChildren: frame.childDirectional,
      ).paint(
        canvas,
        origin: const ui.Offset(64, 64),
        particles: frame.particles,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(128, 128);
      try {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba, isNotNull);
        final pixelBytes = rgba!.buffer.asUint8List();
        expect(
          [for (var i = 3; i < pixelBytes.length; i += 4) pixelBytes[i]]
              .any((alpha) => alpha != 0),
          isTrue,
          reason: 'source emitter ${frame.emitterIndex}',
        );
      } finally {
        image.dispose();
        picture.dispose();
      }
    }
    final seen = <int>{};
    while (!playback.isComplete) {
      expect(playback.advance(), isNull);
      for (final frame in playback.frames) {
        if (frame.particles.isNotEmpty) seen.add(frame.emitterIndex);
      }
    }
    expect(seen, {0, 1});
    playback.cancel();
    final pool = BattleSplParticlePool(capacity: 128);
    final first = BattleSplConfiguredEmitter(
      definition: result.definition.emitters[0],
      textureIndices: const {'texture00': 0, 'texture01': 1},
      random: BattleSplRandom(seed: 0),
      pool: pool,
    );
    first.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final firstParticle = first.playback.particles.single;
    expect(firstParticle.motion.velocity, (x: -98, y: -110, z: 173));
    expect(firstParticle.motion.angularVelocity, -2004);
    expect(firstParticle.motion.rotation, 5622);
    first.cancel();
    final second = BattleSplConfiguredEmitter(
      definition: result.definition.emitters[1],
      textureIndices: const {'texture00': 0, 'texture01': 1},
      random: BattleSplRandom(seed: 0),
      pool: pool,
    );
    final emitted = second.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    expect(emitted.droppedParents, 0);
    expect(
      second.playback.particles.where((item) => item.parentId == null),
      hasLength(2),
    );
    second.cancel();
    expect(pool.inUse, 0);
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');

  test('applies BW2 hemisphere sampling, velocity variance, and rotation in source order', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 5;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = source['emission'] as Map;
    emission['shape'] = 'hemisphereSurface';
    emission['radius'] = 0;
    emission['positionVelocity'] = 0;
    emission['emissionAxis'] = 'x';
    emission['velocityVariance'] = 27;
    emission['duration'] = 1;
    emission['particleLifetime'] = 10;
    final appearance = source['appearance'] as Map;
    appearance['draw'] = 'directionalBillboard';
    appearance['hasRotation'] = true;
    appearance['minRotation'] = 2558;
    appearance['maxRotation'] = -2559;
    appearance['dirFromPosition'] = true;
    (source['motion'] as Map)['magnet'] = null;
    final pool = BattleSplParticlePool(capacity: 64);
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromExperimentalJson(raw)
          .emitters
          .single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: pool,
    );
    emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final particle = emitter.playback.particles.single;
    expect(particle.motion.velocity, (x: 996, y: 0, z: 0));
    expect(particle.motion.angularVelocity, -387);
    expect(particle.motion.rotation, 65149);
    emitter.cancel();
    expect(pool.inUse, 0);
  });

  test('applies a v4 magnet to configured parent particles', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    raw['schemaVersion'] = 4;
    final source = (raw['emitters'] as List).single as Map<String, dynamic>;
    (source['emission'] as Map)['positionVelocity'] = 0;
    (source['motion'] as Map)['magnet'] = {
      'target': {'x': 4096, 'y': 0, 'z': 0},
      'force': 512,
    };
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromJson(raw).emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: BattleSplParticlePool(capacity: 64),
    );
    emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final withMagnet = emitter.playback.particles.single.motion;
    (source['motion'] as Map)['magnet'] = null;
    final without = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromJson(raw).emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: BattleSplParticlePool(capacity: 64),
    );
    without.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    final base = without.playback.particles.single.motion;
    expect(withMagnet.position.x, greaterThan(base.position.x));
    emitter.cancel();
    without.cancel();
  });

  test(
    'applies source radial and axial velocities to a sphere emission',
    () async {
      final raw = jsonDecode(
        await File('../map_core/test/fixtures/spl_particle_v2.json')
            .readAsString(),
      ) as Map<String, dynamic>;
      raw['schemaVersion'] = 3;
      final data = (raw['emitters'] as List).single as Map<String, dynamic>;
      final emission = data['emission'] as Map<String, dynamic>;
      emission['shape'] = 'sphereSurface';
      emission['radius'] = 1218;
      emission['axis'] = {'x': 0, 'y': 4096, 'z': 0};
      emission['axisVelocity'] = 609;
      emission['positionVelocity'] = 914;
      final pool = BattleSplParticlePool(capacity: 64);
      final emitter = BattleSplConfiguredEmitter(
        definition: BattleSplParticleDefinition.fromJson(raw).emitters.single,
        textureIndices: const {'tex': 0},
        random: BattleSplRandom(seed: 0),
        pool: pool,
      );
      emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
      final particle = emitter.playback.particles.single;
      expect(particle.motion.position, (x: 1694, y: 1845, z: -351));
      expect(particle.motion.velocity, (x: 724, y: 1136, z: -150));
      emitter.cancel();
      expect(pool.inUse, 0);
    },
  );

  test('keeps v2 sphere emission random state unchanged', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final data = (raw['emitters'] as List).single as Map<String, dynamic>;
    final emission = data['emission'] as Map<String, dynamic>;
    emission['shape'] = 'sphereSurface';
    emission['radius'] = 1;
    emission['axisVelocity'] = 0;
    final random = BattleSplRandom(seed: 0);
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromJson(raw).emitters.single,
      textureIndices: const {'tex': 0},
      random: random,
      pool: BattleSplParticlePool(capacity: 64),
    );
    emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    expect(emitter.playback.particles.single.motion.position, (
      x: 1,
      y: 1,
      z: 0,
    ));
    final expected = BattleSplRandom(seed: 0);
    for (var i = 0; i < 8; i++) {
      expected.next();
    }
    expect(random.state, expected.state);
    emitter.cancel();
  });

  test('reports dropped particles to the caller', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final emission =
        ((raw['emitters'] as List).single as Map)['emission'] as Map;
    emission['rate'] = 2 * 4096;
    final pool = BattleSplParticlePool(capacity: 1);
    final emitter = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromJson(raw).emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: pool,
    );
    final result = emitter.step(managerFrame: 0, position: (x: 0, y: 0, z: 0));
    expect(result.droppedParents, 1);
    emitter.cancel();
    expect(pool.inUse, 0);
  });

  test('plays a verified definition with live emitter coordinates', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final definition = BattleSplParticleDefinition.fromJson(raw);
    final pool = BattleSplParticlePool(capacity: 64);
    final emitter = BattleSplConfiguredEmitter(
      definition: definition.emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: pool,
    );
    emitter.step(managerFrame: 0, position: (x: 10, y: 20, z: 30));
    expect(emitter.playback.particles, hasLength(1));
    expect(emitter.playback.particles.single.emitterPosition, (
      x: 10,
      y: 20,
      z: 30,
    ));
    expect(emitter.playback.particles.single.texture, 0);
    emitter.step(managerFrame: 1, position: (x: 40, y: 50, z: 60));
    expect(
      emitter.playback.particles.every(
        (particle) => particle.emitterPosition == (x: 40, y: 50, z: 60),
      ),
      isTrue,
    );
    emitter.cancel();
    expect(pool.inUse, 0);
  });

  test('rejects missing or ambiguous texture indices', () async {
    final raw = jsonDecode(
      await File('../map_core/test/fixtures/spl_particle_v2.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final emitter = (raw['emitters'] as List).single as Map<String, dynamic>;
    final appearance = emitter['appearance'] as Map<String, dynamic>;
    appearance['textureAnimation'] = {
      'textures': ['other'],
      'step': 128,
      'loop': false,
    };
    final definition = BattleSplParticleDefinition.fromJson(raw);
    for (final indices in <Map<String, int>>[
      {'tex': 0},
      {'tex': 0, 'other': 0},
      {'tex': 256, 'other': 1},
    ]) {
      expect(
        () => BattleSplConfiguredEmitter(
          definition: definition.emitters.single,
          textureIndices: indices,
          random: BattleSplRandom(seed: 0),
          pool: BattleSplParticlePool(capacity: 64),
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'releases the pool when motion overflows after several frames',
    () async {
      final raw = jsonDecode(
        await File('../map_core/test/fixtures/spl_particle_v2.json')
            .readAsString(),
      ) as Map<String, dynamic>;
      final definition =
          (raw['emitters'] as List).single as Map<String, dynamic>;
      final emission = definition['emission'] as Map<String, dynamic>;
      emission['duration'] = 1;
      emission['particleLifetime'] = 20;
      emission['axisVelocity'] = 0;
      final motion = definition['motion'] as Map;
      (motion['gravity'] as Map)['x'] = 32767;
      motion['airResistance'] = 255;
      final pool = BattleSplParticlePool(capacity: 64);
      final emitter = BattleSplConfiguredEmitter(
        definition: BattleSplParticleDefinition.fromJson(raw).emitters.single,
        textureIndices: const {'tex': 0},
        random: BattleSplRandom(seed: 0),
        pool: pool,
      );
      var failed = false;
      for (var tick = 0; tick < 100; tick++) {
        try {
          emitter.step(managerFrame: tick & 1, position: (x: 0, y: 0, z: 0));
        } on FormatException {
          failed = true;
          expect(tick, 15);
          break;
        }
      }
      expect(failed, isTrue);
      expect(emitter.playback.isComplete, isTrue);
      expect(pool.inUse, 0);
    },
  );

  test('plays all four converted source emitters and their children', () async {
    const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
    const path = 'res/particles/btlv_effvm_particles/218/particles.json';
    const hash =
        'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client
        .getUrl(
          Uri.https(
            'raw.githubusercontent.com',
            '/fuddlesworth/pokebw2/$revision/$path',
          ),
        )
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 20));
    expect(response.statusCode, HttpStatus.ok);
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (bytes.length + chunk.length > 262144) {
        throw const FormatException('SPL source too large');
      }
      bytes.add(chunk);
    }
    final source = bytes.takeBytes();
    expect(sha256.convert(source).toString(), hash);
    final converted = Gen5SplParticleConverter.convert(
      source,
      particleId: 218,
      sourceRevision: revision,
      sourcePath: path,
      expectedSha256: hash,
      textureResourceIds: {
        for (var i = 0; i < 6; i++) 'texture0$i': 'texture0$i',
      },
    );
    final pool = BattleSplParticlePool(capacity: 64);
    final random = BattleSplRandom(seed: 0);
    final emitters = [
      for (final definition in converted.definition.emitters)
        BattleSplConfiguredEmitter(
          definition: definition,
          textureIndices: {for (var i = 0; i < 6; i++) 'texture0$i': i},
          random: random,
          pool: pool,
        ),
    ];
    final seen = <int>{};
    var sawChild = false;
    for (var tick = 0; tick < 125; tick++) {
      for (var i = 0; i < emitters.length; i++) {
        if (i >= 2 && tick < 46) continue;
        emitters[i].step(
          managerFrame: tick & 1,
          position: (x: i * 4096, y: 0, z: 0),
        );
        final particles = emitters[i].playback.particles;
        if (particles.isNotEmpty) seen.add(i);
        if (particles.any((particle) => particle.parentId != null)) {
          sawChild = true;
        }
      }
    }
    expect(seen, {0, 1, 2, 3});
    expect(sawChild, isTrue);
    for (final emitter in emitters) {
      emitter.cancel();
    }
    expect(pool.inUse, 0);
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');
}
