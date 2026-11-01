import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/src/models/battle_move_animation_recipe.dart';
import 'package:test/test.dart';

void main() {
  final texture = <int>[1, 2, 3];

  Map<String, dynamic> definition() => {
    'schemaVersion': 1,
    'emitters': [
      {
        'textureId': 'tex',
        'emissionDurationMs': 100,
        'emissionIntervalMs': 20,
        'particleLifetimeMs': 200,
        'particlesPerEmission': 2,
      },
    ],
  };

  (BattleMoveAnimationRecipe, Map<String, List<int>>) bundle(
    Map<String, dynamic> particle, {
    List<String> dependencies = const ['tex'],
    List<int>? rawBytes,
  }) {
    final particleBytes = rawBytes ?? utf8.encode(jsonEncode(particle));
    Map<String, dynamic> resource(
      String id,
      String role,
      String mediaType,
      List<int> bytes,
    ) => {
      'id': id,
      'role': role,
      'mediaType': mediaType,
      'sizeBytes': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
    };
    final recipe = BattleMoveAnimationRecipe.fromJson({
      'schemaVersion': 1,
      'recipeId': 'synthetic',
      'revision': '1',
      'moveSourceId': 'flamethrower',
      'variant': 'default',
      'requiredCapabilities': ['sequence', 'startParticle', 'waitEffects'],
      'provenance': {
        'source': 'synthetic',
        'sourceRevision': '1',
        'sourcePaths': <String>[],
        'converter': 'test/1',
      },
      'resources': [
        {
          ...resource(
            'particle',
            'particleDefinition',
            'application/vnd.avelune.particle+json',
            particleBytes,
          ),
          'definitionVersion': 1,
          'dependencies': dependencies,
        },
        resource('tex', 'texture', 'image/png', texture),
        resource('unused', 'texture', 'image/png', texture),
      ],
      'program': {
        'kind': 'sequence',
        'steps': [
          {
            'kind': 'startParticle',
            'resourceId': 'particle',
            'from': 'userMouth',
            'to': 'targetImpact',
          },
          {'kind': 'waitEffects'},
        ],
      },
    });
    return (
      recipe,
      {'particle': particleBytes, 'tex': texture, 'unused': texture},
    );
  }

  test('rejects duplicate particle keys even with a matching hash', () {
    final raw = utf8.encode(
      jsonEncode(definition()).replaceFirst(
        '"schemaVersion":1',
        r'"schemaVersion":1,"schema\u0056ersion":1',
      ),
    );
    final (recipe, media) = bundle(definition(), rawBytes: raw);
    expect(
      () => recipe.validateBundle(
        media,
        availableCapabilities: {'sequence', 'startParticle', 'waitEffects'},
      ),
      throwsFormatException,
    );
  });

  test(
    'validates bytes, supported capabilities and exact texture references',
    () {
      final (recipe, media) = bundle(definition());
      expect(
        () => recipe.validateBundle(
          media,
          availableCapabilities: {'sequence', 'startParticle', 'waitEffects'},
        ),
        returnsNormally,
      );
      final verified = recipe.readVerifiedParticleDefinitions(
        media,
        availableCapabilities: {'sequence', 'startParticle', 'waitEffects'},
      );
      final emitter = verified['particle']!.emitters.single;
      expect(
        (
          emitter.textureId,
          emitter.emissionDurationMs,
          emitter.emissionIntervalMs,
          emitter.particleLifetimeMs,
          emitter.particlesPerEmission,
        ),
        ('tex', 100, 20, 200, 2),
      );
      expect(() => verified.clear(), throwsUnsupportedError);
      expect(
        () => verified['particle']!.emitters.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => recipe.validateBundle(
          media,
          availableCapabilities: {'sequence', 'waitEffects'},
        ),
        throwsFormatException,
      );
      expect(
        () => recipe.validateBundle(
          {
            ...media,
            'tex': [9],
          },
          availableCapabilities: {'sequence', 'startParticle', 'waitEffects'},
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'rejects incorrect or extra declared dependencies and unknown fields',
    () {
      for (final value in [
        bundle(definition(), dependencies: ['unused']),
        bundle(definition(), dependencies: ['tex', 'unused']),
        bundle({...definition(), 'unknown': true}),
        bundle({'schemaVersion': 2, 'emitters': definition()['emitters']}),
        bundle({
          'schemaVersion': 1,
          'emitters': [
            {
              'textureId': 'tex',
              'emissionDurationMs': 100,
              'emissionIntervalMs': 0,
              'particleLifetimeMs': 100,
              'particlesPerEmission': 1,
            },
          ],
        }),
        bundle({
          'schemaVersion': 1,
          'emitters': [
            {
              'textureId': 'tex',
              'emissionDurationMs': 60000,
              'emissionIntervalMs': 1,
              'particleLifetimeMs': 100,
              'particlesPerEmission': 2,
            },
          ],
        }),
      ]) {
        expect(
          () => value.$1.validateBundle(
            value.$2,
            availableCapabilities: {'sequence', 'startParticle', 'waitEffects'},
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('rejects excessive JSON nesting before decoding the definition', () {
    Object value = 0;
    for (var i = 0; i < 40; i++) {
      value = [value];
    }
    final input = bundle({
      'schemaVersion': 1,
      'emitters': [value],
    });
    expect(
      () => input.$1.validateBundle(
        input.$2,
        availableCapabilities: {'sequence', 'startParticle', 'waitEffects'},
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Particle JSON too deep',
        ),
      ),
    );
  });

  test(
    'rejects invalid UTF-8, invalid JSON and oversized definitions even with matching hashes',
    () {
      for (final bytes in [
        <int>[255],
        utf8.encode('{'),
        List<int>.filled(262145, 32),
      ]) {
        final input = bundle(definition(), rawBytes: bytes);
        expect(
          () => input.$1.validateBundle(
            input.$2,
            availableCapabilities: {'sequence', 'startParticle', 'waitEffects'},
          ),
          throwsFormatException,
        );
      }
    },
  );
}
