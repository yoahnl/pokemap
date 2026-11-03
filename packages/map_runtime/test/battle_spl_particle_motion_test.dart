import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_motion.dart';

void main() {
  test('applies BW2 convergence to position after sampling magnet force', () {
    final initial = BattleSplParticleMotion(
      position: (x: 100, y: -200, z: 300),
      velocity: (x: 512, y: -512, z: 1024),
      rotation: 0,
      angularVelocity: 0,
    );
    final next = initial.advanceWithGravity(
      gravity: (x: 0, y: 0, z: 0),
      emitterVelocity: (x: 0, y: 0, z: 0),
      airResistance: 128,
      magnetTarget: (x: 4096, y: -4096, z: 0),
      magnetForce: 512,
      convergenceTarget: (x: 0, y: 0, z: 0),
      convergenceForce: 274,
    );
    expect(next.velocity, (x: 947, y: -935, z: 858));
    expect(next.position, (x: 1040, y: -1122, z: 1138));
  });

  test('applies BW2 magnet force using the pre-drag position and velocity', () {
    final initial = BattleSplParticleMotion(
      position: (x: 100, y: -200, z: 300),
      velocity: (x: 512, y: -512, z: 1024),
      rotation: 0,
      angularVelocity: 0,
    );
    final next = initial.advanceWithGravity(
      gravity: (x: 0, y: 0, z: 0),
      emitterVelocity: (x: 0, y: 0, z: 0),
      airResistance: 128,
      magnetTarget: (x: 4096, y: -4096, z: 0),
      magnetForce: 512,
    );
    expect(next.velocity, (x: 947, y: -935, z: 858));
    expect(next.position, (x: 1047, y: -1135, z: 1158));
  });

  test('rejects incomplete and overflowing magnet parameters', () {
    final initial = BattleSplParticleMotion(
      position: (x: -2147483648, y: 0, z: 0),
      velocity: (x: 0, y: 0, z: 0),
      rotation: 0,
      angularVelocity: 0,
    );
    expect(
      () => initial.advanceWithGravity(
        gravity: (x: 0, y: 0, z: 0),
        emitterVelocity: (x: 0, y: 0, z: 0),
        airResistance: 128,
        magnetForce: 1,
      ),
      throwsFormatException,
    );
    expect(
      () => initial.advanceWithGravity(
        gravity: (x: 0, y: 0, z: 0),
        emitterVelocity: (x: 0, y: 0, z: 0),
        airResistance: 128,
        magnetTarget: (x: 2147483647, y: 0, z: 0),
        magnetForce: 1,
      ),
      throwsFormatException,
    );
  });

  test('applies resistance before gravity and emitter velocity', () {
    final initial = BattleSplParticleMotion(
      position: (x: 100, y: -200, z: 300),
      velocity: (x: 512, y: -512, z: 1024),
      rotation: 65000,
      angularVelocity: 1000,
    );
    final next = initial.advanceWithGravity(
      gravity: (x: 0, y: 2, z: -2),
      emitterVelocity: (x: 5, y: 6, z: 7),
      airResistance: 128,
    );

    expect(next.velocity, (x: 512, y: -510, z: 1022));
    expect(next.position, (x: 617, y: -704, z: 1329));
    expect(next.rotation, 464);
    expect(initial.position, (x: 100, y: -200, z: 300));
  });

  test('uses an arithmetic shift for negative velocity', () {
    final state =
        BattleSplParticleMotion(
          position: (x: 0, y: 0, z: 0),
          velocity: (x: -1, y: 1, z: 0),
          rotation: 0,
          angularVelocity: -1,
        ).advanceWithGravity(
          gravity: (x: 0, y: 0, z: 0),
          emitterVelocity: (x: 0, y: 0, z: 0),
          airResistance: 0,
        );
    expect(state.velocity, (x: -1, y: 0, z: 0));
    expect(state.position, (x: -1, y: 0, z: 0));
    expect(state.rotation, 65535);
  });

  test('rejects invalid vectors and overflowing intermediate arithmetic', () {
    expect(
      () => BattleSplParticleMotion(
        position: (x: 2147483648, y: 0, z: 0),
        velocity: (x: 0, y: 0, z: 0),
        rotation: 0,
        angularVelocity: 0,
      ),
      throwsFormatException,
    );
    final state = BattleSplParticleMotion(
      position: (x: 0, y: 0, z: 0),
      velocity: (x: 10000000, y: 0, z: 0),
      rotation: 0,
      angularVelocity: 0,
    );
    expect(
      () => state.advanceWithGravity(
        gravity: (x: 0, y: 0, z: 0),
        emitterVelocity: (x: 0, y: 0, z: 0),
        airResistance: 128,
      ),
      throwsFormatException,
    );
    expect(
      () => state.advanceWithGravity(
        gravity: (x: 0, y: 32768, z: 0),
        emitterVelocity: (x: 0, y: 0, z: 0),
        airResistance: 128,
      ),
      throwsFormatException,
    );
  });

  test(
    'advances synthetic initial states using source 218 gravity and drag',
    () async {
      const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
      final client = HttpClient();
      try {
        final request = await client
            .getUrl(
              Uri.https(
                'raw.githubusercontent.com',
                '/fuddlesworth/pokebw2/$revision/res/particles/'
                    'btlv_effvm_particles/218/particles.json',
              ),
            )
            .timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
        expect(response.statusCode, HttpStatus.ok);
        final data = BytesBuilder(copy: false);
        await for (final bytes in response.timeout(
          const Duration(seconds: 20),
        )) {
          if (data.length + bytes.length > 64 * 1024) {
            throw const FormatException('Particle source exceeds test limit');
          }
          data.add(bytes);
        }
        final bytes = data.takeBytes();
        expect(
          sha256.convert(bytes).toString(),
          'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9',
        );
        final source = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final traces = <List<(int, int)>>[];
        for (final raw in source['emitters'] as List<dynamic>) {
          final emitter = raw as Map<String, dynamic>;
          expect(emitter.keys.where((key) => key.endsWith('Behavior')), [
            'gravityBehavior',
          ]);
          final behavior = emitter['gravityBehavior'] as Map<String, dynamic>;
          final magnitude = behavior['magnitude'] as Map<String, dynamic>;
          final gravity = (
            x: magnitude['x'] as int,
            y: magnitude['y'] as int,
            z: magnitude['z'] as int,
          );
          var motion = BattleSplParticleMotion(
            position: (x: 0, y: 0, z: 0),
            velocity: (x: 0, y: 0, z: 0),
            rotation: 0,
            angularVelocity: 0,
          );
          final trace = <(int, int)>[];
          for (var tick = 0; tick < 5; tick++) {
            motion = motion.advanceWithGravity(
              gravity: gravity,
              emitterVelocity: (x: 0, y: 0, z: 0),
              airResistance: emitter['airResistance'] as int,
            );
            trace.add((motion.position.y, motion.velocity.y));
          }
          traces.add(trace);
        }
        expect(traces, [
          [(2, 2), (5, 3), (9, 4), (14, 5), (20, 6)],
          [(2, 2), (6, 4), (12, 6), (20, 8), (30, 10)],
          [(61, 61), (172, 111), (324, 152), (510, 186), (724, 214)],
          [(45, 45), (127, 82), (239, 112), (376, 137), (533, 157)],
        ]);
      } finally {
        client.close(force: true);
      }
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] == '1'
        ? false
        : 'Requires network access to the pinned source',
  );
}
