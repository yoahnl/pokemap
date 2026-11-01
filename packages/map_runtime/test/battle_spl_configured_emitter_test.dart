import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_configured_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_pool.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';

void main() {
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
