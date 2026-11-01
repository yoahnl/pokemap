import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_color_texture_animation.dart';

void main() {
  test('interpolates RGB5 channels in each source interval', () {
    final animation = BattleSplColorAnimation(
      start: (red: 2, green: 31, blue: 10),
      middle: (red: 31, green: 1, blue: 10),
      end: (red: 0, green: 0, blue: 20),
      fadeIn: 10,
      peak: 20,
      fadeOut: 30,
      interpolate: true,
    );
    expect([0, 10, 15, 20, 25, 30].map(animation.valueAt), [
      (red: 2, green: 31, blue: 10),
      (red: 2, green: 31, blue: 10),
      (red: 16, green: 16, blue: 10),
      (red: 31, green: 1, blue: 10),
      (red: 16, green: 1, blue: 15),
      (red: 0, green: 0, blue: 20),
    ]);
  });

  test('switches immediately when color interpolation is disabled', () {
    final animation = BattleSplColorAnimation(
      start: (red: 1, green: 2, blue: 3),
      middle: (red: 4, green: 5, blue: 6),
      end: (red: 7, green: 8, blue: 9),
      fadeIn: 10,
      peak: 20,
      fadeOut: 30,
      interpolate: false,
    );
    expect(animation.valueAt(9), (red: 1, green: 2, blue: 3));
    expect(animation.valueAt(10), (red: 4, green: 5, blue: 6));
    expect(animation.valueAt(20), (red: 7, green: 8, blue: 9));
  });

  test('retains the prior texture after the declared steps', () {
    final textures = [5, 6];
    final animation = BattleSplTextureAnimation(textures: textures, step: 40);
    textures[0] = 99;
    expect(animation.valueAt(lifeRate: 0, previousTexture: 7), 5);
    expect(animation.valueAt(lifeRate: 39, previousTexture: 7), 5);
    expect(animation.valueAt(lifeRate: 40, previousTexture: 7), 6);
    expect(animation.valueAt(lifeRate: 79, previousTexture: 7), 6);
    expect(animation.valueAt(lifeRate: 80, previousTexture: 7), 7);
    expect(() => animation.textures.clear(), throwsUnsupportedError);
  });

  test('rejects invalid RGB, phase and texture data', () {
    expect(
      () => BattleSplColorAnimation(
        start: (red: 32, green: 0, blue: 0),
        middle: (red: 0, green: 0, blue: 0),
        end: (red: 0, green: 0, blue: 0),
        fadeIn: 0,
        peak: 1,
        fadeOut: 2,
        interpolate: true,
      ),
      throwsFormatException,
    );
    expect(
      () => BattleSplTextureAnimation(textures: List.filled(9, 0), step: 1),
      throwsFormatException,
    );
    expect(
      () => BattleSplTextureAnimation(textures: [256], step: 1),
      throwsFormatException,
    );
    final valid = BattleSplTextureAnimation(textures: [0], step: 1);
    expect(
      () => valid.valueAt(lifeRate: 256, previousTexture: 0),
      throwsArgumentError,
    );
  });

  test(
    'samples pinned source 218 colors and the looping texture sequence',
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
        final colors = <List<BattleSplRgb5>>[];
        for (final raw in emitters) {
          final emitter = raw as Map<String, dynamic>;
          final color = emitter['colorAnim'] as Map<String, dynamic>;
          expect(color['randomStart'], isFalse);
          expect(color['loop'], isFalse);
          BattleSplRgb5 rgb(dynamic value) {
            final map = value as Map<String, dynamic>;
            return (
              red: map['red'] as int,
              green: map['green'] as int,
              blue: map['blue'] as int,
            );
          }

          final animation = BattleSplColorAnimation(
            start: rgb(color['start']),
            middle: rgb(emitter['color']),
            end: rgb(color['end']),
            fadeIn: color['in'] as int,
            peak: color['peak'] as int,
            fadeOut: color['out'] as int,
            interpolate: color['interpolate'] as bool,
          );
          final lifetime = emitter['particleLifeTime'] as int;
          colors.add([
            for (final age in [0, lifetime ~/ 2, lifetime])
              animation.valueAt((((65535 ~/ lifetime) * age) >> 8) & 255),
          ]);
        }
        expect(colors, [
          [
            (red: 31, green: 23, blue: 13),
            (red: 31, green: 16, blue: 13),
            (red: 31, green: 13, blue: 13),
          ],
          [
            (red: 31, green: 0, blue: 0),
            (red: 23, green: 0, blue: 0),
            (red: 4, green: 0, blue: 0),
          ],
          [
            (red: 31, green: 12, blue: 0),
            (red: 20, green: 0, blue: 0),
            (red: 15, green: 0, blue: 0),
          ],
          [
            (red: 31, green: 31, blue: 31),
            (red: 31, green: 14, blue: 0),
            (red: 31, green: 0, blue: 0),
          ],
        ]);

        final emitter = emitters.first as Map<String, dynamic>;
        final texture = emitter['textureAnim'] as Map<String, dynamic>;
        expect(texture['loop'], isTrue);
        expect(texture['randomStart'], isFalse);
        final names = (source['textures'] as List<dynamic>)
            .map((item) => (item as Map<String, dynamic>)['name'])
            .toList();
        final indices = (texture['textures'] as List<dynamic>)
            .map((name) => names.indexOf(name))
            .toList();
        final animation = BattleSplTextureAnimation(
          textures: indices,
          step: texture['step'] as int,
        );
        var previous = indices.first;
        final sequence = <int>[];
        final loopTime = emitter['loopTime'] as int;
        for (var age = 0; age <= 10; age++) {
          final phase = (((65535 ~/ loopTime) * age) >> 8) & 255;
          previous = animation.valueAt(
            lifeRate: phase,
            previousTexture: previous,
          );
          sequence.add(previous);
        }
        expect(sequence, [1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 1]);
      } finally {
        client.close(force: true);
      }
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] == '1'
        ? false
        : 'Requires network access to the pinned source',
  );
}
