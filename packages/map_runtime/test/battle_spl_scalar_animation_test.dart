import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_scalar_animation.dart';

void main() {
  test('evaluates the three scalar segments at their boundaries', () {
    final animation = BattleSplScalarAnimation(
      start: 1000,
      middle: 2000,
      end: 3000,
      fadeIn: 64,
      fadeOut: 192,
    );
    expect([0, 32, 64, 191, 192, 223, 255].map(animation.valueAt), [
      1000,
      1500,
      2000,
      2000,
      2000,
      2493,
      3000,
    ]);
  });

  test('uses truncation toward zero when a scalar decreases', () {
    final animation = BattleSplScalarAnimation(
      start: 5,
      middle: 2,
      end: 2,
      fadeIn: 2,
      fadeOut: 2,
    );
    expect(animation.valueAt(1), 4);
  });

  test('applies the source 8-bit alpha factor even without random loss', () {
    final animation = BattleSplAlphaAnimation(
      start: 31,
      middle: 31,
      end: 31,
      fadeIn: 0,
      fadeOut: 1,
      randomRange: 0,
    );
    final flicker = BattleSplAlphaAnimation(
      start: 31,
      middle: 31,
      end: 31,
      fadeIn: 0,
      fadeOut: 1,
      randomRange: 128,
    );
    expect(animation.valueAt(lifeRate: 0, randomByte: 255), 30);
    expect(flicker.valueAt(lifeRate: 0, randomByte: 255), 15);
  });

  test('derives independent 8-bit life and loop phases from particle age', () {
    final middle = BattleSplParticlePhase(age: 23, lifetime: 46, loopTime: 9);
    expect(middle.life, 127);
    expect(BattleSplParticlePhase(age: 9, lifetime: 46, loopTime: 9).loop, 255);
    expect(BattleSplParticlePhase(age: 10, lifetime: 46, loopTime: 9).loop, 28);
    expect(
      BattleSplParticlePhase(
        age: 10,
        lifetime: 46,
        loopTime: 9,
        loopOffset: 240,
      ).loop,
      12,
    );
  });

  test('rejects unsupported ranges and division by zero', () {
    expect(
      () => BattleSplScalarAnimation(
        start: 0,
        middle: 1,
        end: 2,
        fadeIn: 1,
        fadeOut: 255,
      ),
      throwsFormatException,
    );
    expect(
      () => BattleSplAlphaAnimation(
        start: 32,
        middle: 0,
        end: 0,
        fadeIn: 0,
        fadeOut: 1,
        randomRange: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => BattleSplParticlePhase(age: 1, lifetime: 1, loopTime: 0),
      throwsFormatException,
    );
    final valid = BattleSplScalarAnimation(
      start: 0,
      middle: 1,
      end: 2,
      fadeIn: 1,
      fadeOut: 2,
    );
    expect(() => valid.valueAt(256), throwsArgumentError);
  });

  test(
    'samples scale and alpha of the four pinned source 218 emitters',
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
        final emitters = source['emitters'] as List<dynamic>;
        final samples = <List<(int, int)>>[];
        for (final raw in emitters) {
          final emitter = raw as Map<String, dynamic>;
          final scale = emitter['scaleAnim'] as Map<String, dynamic>;
          final alpha = emitter['alphaAnim'] as Map<String, dynamic>;
          expect(scale['loop'], isFalse);
          expect(alpha['loop'], isFalse);
          expect(alpha['randomRange'], 0);
          final scaleAnimation = BattleSplScalarAnimation(
            start: scale['start'] as int,
            middle: scale['mid'] as int,
            end: scale['end'] as int,
            fadeIn: scale['in'] as int,
            fadeOut: scale['out'] as int,
          );
          final alphaAnimation = BattleSplAlphaAnimation(
            start: alpha['start'] as int,
            middle: alpha['mid'] as int,
            end: alpha['end'] as int,
            fadeIn: alpha['in'] as int,
            fadeOut: alpha['out'] as int,
            randomRange: alpha['randomRange'] as int,
          );
          final lifetime = emitter['particleLifeTime'] as int;
          samples.add([
            for (final age in [0, lifetime ~/ 2, lifetime])
              (
                scaleAnimation.valueAt(
                  BattleSplParticlePhase(
                    age: age,
                    lifetime: lifetime,
                    loopTime: emitter['loopTime'] as int,
                  ).life,
                ),
                alphaAnimation.valueAt(
                  lifeRate: BattleSplParticlePhase(
                    age: age,
                    lifetime: lifetime,
                    loopTime: emitter['loopTime'] as int,
                  ).life,
                  randomByte: 0,
                ),
              ),
          ]);
        }
        expect(samples, [
          [(2680, 30), (5943, 28), (8283, 1)],
          [(1462, 30), (2911, 28), (6091, 1)],
          [(3289, 6), (1981, 30), (487, 0)],
          [(4629, 6), (3542, 30), (974, 0)],
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
