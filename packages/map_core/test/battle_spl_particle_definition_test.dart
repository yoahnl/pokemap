import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _definition() => {
  'schemaVersion': 2,
  'emitters': [
    {
      'emission': {
        'shape': 'sphereSurface',
        'origin': {'x': 0, 'y': 0, 'z': 0},
        'axis': {'x': 0, 'y': 4096, 'z': 0},
        'radius': 7004,
        'axisVelocity': 533,
        'followEmitter': false,
        'rate': 4096,
        'startDelay': 10,
        'interval': 1,
        'duration': 2,
        'particleLifetime': 63,
        'autoTerminate': true,
        'scaleVariance': 51,
        'randomInitialAngle': false,
        'initialAngle': 0,
      },
      'appearance': {
        'draw': 'directionalBillboard',
        'scaleAxis': 'x',
        'baseScale': 4385,
        'aspectRatio': 4096,
        'baseAlpha': 31,
        'loopTime': 9,
        'scale': {
          'start': 3289,
          'middle': 1949,
          'end': 487,
          'fadeIn': 128,
          'fadeOut': 128,
          'loop': false,
        },
        'color': {
          'start': {'red': 31, 'green': 12, 'blue': 0},
          'middle': {'red': 20, 'green': 0, 'blue': 0},
          'end': {'red': 15, 'green': 0, 'blue': 0},
          'fadeIn': 0,
          'peak': 114,
          'fadeOut': 255,
          'interpolate': true,
          'loop': false,
        },
        'alpha': {
          'start': 7,
          'middle': 31,
          'end': 0,
          'fadeIn': 29,
          'fadeOut': 137,
          'randomRange': 0,
          'loop': false,
        },
        'initialTexture': 'flame',
        'textureAnimation': {
          'textures': ['flame1', 'flame2'],
          'step': 86,
          'loop': true,
        },
      },
      'motion': {
        'gravity': {'x': 0, 'y': 61, 'z': 0},
        'airResistance': 38,
      },
      'child': {
        'velocityRatio': 0,
        'randomVelocityMagnitude': 0,
        'scaleRatio': 79,
        'color': {'red': 15, 'green': 0, 'blue': 0},
        'rotation': 'angleAndVelocity',
        'lifetime': 1,
        'texture': 'spark',
        'emissionCount': 1,
        'emissionDelay': 0,
        'emissionInterval': 1,
        'fadeAlpha': true,
      },
    },
  ],
};

Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    (jsonDecode(jsonEncode(value)) as Map).cast<String, dynamic>();

void main() {
  test('accepts bounded v4 magnets while retaining v2 and v3 semantics', () {
    final v4 = _copy(_definition())..['schemaVersion'] = 4;
    final emitter = (v4['emitters'] as List).single as Map;
    (emitter['emission'] as Map)['positionVelocity'] = 914;
    (emitter['motion'] as Map)['magnet'] = {
      'target': {'x': 0, 'y': -19033, 'z': 0},
      'force': 761,
    };
    (emitter['child'] as Map)['scaleEnd'] = 0;
    (emitter['child'] as Map)['inheritBehaviors'] = true;
    (emitter['child'] as Map)['draw'] = 'directionalBillboard';
    expect(BattleSplParticleDefinition.fromJson(v4).toJson(), v4);
    final v3 = _copy(v4)..['schemaVersion'] = 3;
    expect(() => BattleSplParticleDefinition.fromJson(v3), throwsFormatException);
    ((emitter['motion'] as Map)['magnet'] as Map)['force'] = 32768;
    expect(() => BattleSplParticleDefinition.fromJson(v4), throwsFormatException);
  });

  test('retains v3 radial velocity without changing v2 validation', () {
    final original = _copy(_definition());
    final v3 = _copy(original)..['schemaVersion'] = 3;
    final emission =
        ((v3['emitters'] as List).single as Map)['emission'] as Map;
    emission['positionVelocity'] = 914;
    expect(BattleSplParticleDefinition.fromJson(v3).toJson(), v3);

    final invalidV2 = _copy(original);
    (((invalidV2['emitters'] as List).single as Map)['emission']
            as Map)['positionVelocity'] =
        914;
    expect(
      () => BattleSplParticleDefinition.fromJson(invalidV2),
      throwsFormatException,
    );
    expect(BattleSplParticleDefinition.fromJson(original).toJson(), original);
  });

  test(
    'retains a bounded emitter and every texture without mutable aliases',
    () {
      final json = _copy(_definition());
      final expected = _copy(json);
      final parsed = BattleSplParticleDefinition.fromJson(json);

      expect(parsed.textureIds, {'flame', 'flame1', 'flame2', 'spark'});
      expect(parsed.emitters, hasLength(1));
      expect(parsed.toJson(), expected);

      ((json['emitters'] as List).first as Map)['child'] = null;
      expect(parsed.toJson(), expected);
      final exported = parsed.toJson();
      ((exported['emitters'] as List).first as Map)['child'] = null;
      expect(parsed.toJson(), expected);
      expect(() => parsed.emitters.clear(), throwsUnsupportedError);
      expect(() => parsed.textureIds.clear(), throwsUnsupportedError);
    },
  );

  test('rejects malformed and unsupported emitter definitions', () {
    void reject(void Function(Map<String, dynamic>) change) {
      final json = _copy(_definition());
      final emitter = (json['emitters'] as List).first as Map<String, dynamic>;
      change(emitter);
      expect(
        () => BattleSplParticleDefinition.fromJson(json),
        throwsFormatException,
      );
    }

    reject((emitter) => emitter['unknown'] = true);
    reject((emitter) => (emitter['emission'] as Map)['shape'] = 'ring');
    reject((emitter) => (emitter['emission'] as Map)['interval'] = 0);
    reject((emitter) => (emitter['emission'] as Map)['duration'] = 0);
    reject((emitter) {
      final emission = emitter['emission'] as Map;
      emission['shape'] = 'point';
      emission['radius'] = 1;
    });
    reject((emitter) => (emitter['emission'] as Map)['radius'] = 0);
    reject((emitter) {
      (emitter['emission'] as Map)['scaleVariance'] = 255;
      (emitter['appearance'] as Map)['baseScale'] = 32767;
    });
    reject((emitter) {
      (emitter['appearance'] as Map)['baseScale'] = 32767;
      ((emitter['appearance'] as Map)['scale'] as Map)['start'] = 32767;
      (emitter['child'] as Map)['scaleRatio'] = 255;
    });
    reject((emitter) => (emitter['emission'] as Map)['autoTerminate'] = false);
    reject((emitter) => (emitter['appearance'] as Map)['baseAlpha'] = 32);
    reject(
      (emitter) =>
          ((emitter['appearance'] as Map)['scale'] as Map)['fadeOut'] = 255,
    );
    reject(
      (emitter) =>
          ((emitter['appearance'] as Map)['color'] as Map)['peak'] = 256,
    );
    reject(
      (emitter) =>
          ((emitter['appearance'] as Map)['textureAnimation']
                  as Map)['textures'] =
              <String>[],
    );
    reject((emitter) {
      final animation =
          (emitter['appearance'] as Map)['textureAnimation'] as Map;
      animation['step'] = 0;
    });
    reject((emitter) => (emitter['child'] as Map)['texture'] = '');
    reject((emitter) => (emitter['child'] as Map)['emissionCount'] = 65);
  });

  test('rejects the wrong version or unbounded emitter lists', () {
    for (final json in [
      {..._definition(), 'schemaVersion': 1},
      {..._definition(), 'emitters': <Object>[]},
      {
        ..._definition(),
        'emitters': List.filled(33, (_definition()['emitters'] as List).first),
      },
    ]) {
      expect(
        () => BattleSplParticleDefinition.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test(
    'verifies versioned SPL recipes and their exact texture dependencies',
    () {
      final particle = utf8.encode(jsonEncode(_definition()));
      final image = <int>[1, 2, 3];
      Map<String, dynamic> resource(String id, String role, List<int> bytes) =>
          {
            'id': id,
            'role': role,
            'mediaType': role == 'texture'
                ? 'image/png'
                : 'application/vnd.avelune.particle+json',
            'sizeBytes': bytes.length,
            'sha256': sha256.convert(bytes).toString(),
            if (role == 'particleDefinition') ...{
              'definitionVersion': 2,
              'dependencies': ['flame', 'flame1', 'flame2', 'spark'],
            },
          };
      final json = <String, dynamic>{
        'schemaVersion': 1,
        'recipeId': 'spl-test',
        'revision': '1',
        'moveSourceId': 'test',
        'variant': 'default',
        'requiredCapabilities': ['sequence', 'startParticle', 'splParticleV2'],
        'provenance': {
          'source': 'test',
          'sourceRevision': '1',
          'sourcePaths': <String>[],
          'converter': 'test/1',
        },
        'resources': [
          resource('effect', 'particleDefinition', particle),
          for (final id in ['flame', 'flame1', 'flame2', 'spark'])
            resource(id, 'texture', image),
        ],
        'program': {
          'kind': 'sequence',
          'steps': [
            {
              'kind': 'startParticle',
              'resourceId': 'effect',
              'from': 'userMouth',
              'to': 'targetImpact',
            },
          ],
        },
      };
      final media = <String, List<int>>{
        'effect': particle,
        for (final id in ['flame', 'flame1', 'flame2', 'spark']) id: image,
      };
      const capabilities = {'sequence', 'startParticle', 'splParticleV2'};
      final recipe = BattleMoveAnimationRecipe.fromJson(json);
      recipe.validateBundle(media, availableCapabilities: capabilities);
      final parsed = recipe.readVerifiedSplParticleDefinitions(
        media,
        availableCapabilities: capabilities,
      );
      expect(parsed['effect']!.toJson(), _definition());
      expect(
        () => recipe.readVerifiedParticleDefinitions(
          media,
          availableCapabilities: capabilities,
        ),
        throwsFormatException,
      );
      expect(
        () => recipe.validateBundle(
          media,
          availableCapabilities: {'sequence', 'startParticle'},
        ),
        throwsFormatException,
      );
      expect(
        () => recipe.validateBundle({
          ...media,
          'spark': <int>[9],
        }, availableCapabilities: capabilities),
        throwsFormatException,
      );

      final missingDependency = _copy(json);
      (((missingDependency['resources'] as List).first as Map)['dependencies']
              as List)
          .remove('flame');
      expect(
        () => BattleMoveAnimationRecipe.fromJson(
          missingDependency,
        ).validateBundle(media, availableCapabilities: capabilities),
        throwsFormatException,
      );
      final missingCapability = _copy(json);
      (missingCapability['requiredCapabilities'] as List).remove(
        'splParticleV2',
      );
      expect(
        () => BattleMoveAnimationRecipe.fromJson(missingCapability),
        throwsFormatException,
      );

      final radialDefinition = _copy(_definition())..['schemaVersion'] = 3;
      (((radialDefinition['emitters'] as List).single as Map)['emission']
              as Map)['positionVelocity'] =
          914;
      final radialBytes = utf8.encode(jsonEncode(radialDefinition));
      final radialJson = _copy(json);
      (radialJson['requiredCapabilities'] as List)
        ..remove('splParticleV2')
        ..add('splParticleV3');
      final radialResource = (radialJson['resources'] as List).first as Map;
      radialResource['definitionVersion'] = 3;
      radialResource['sizeBytes'] = radialBytes.length;
      radialResource['sha256'] = sha256.convert(radialBytes).toString();
      final radialRecipe = BattleMoveAnimationRecipe.fromJson(radialJson);
      final radialMedia = {...media, 'effect': radialBytes};
      const radialCapabilities = {'sequence', 'startParticle', 'splParticleV3'};
      expect(
        radialRecipe
            .readVerifiedSplParticleDefinitions(
              radialMedia,
              availableCapabilities: radialCapabilities,
            )['effect']!
            .toJson(),
        radialDefinition,
      );
      expect(
        () => radialRecipe.validateBundle(
          radialMedia,
          availableCapabilities: capabilities,
        ),
        throwsFormatException,
      );

      final legacy = utf8.encode(
        jsonEncode({
          'schemaVersion': 1,
          'emitters': [
            {
              'textureId': 'flame',
              'emissionDurationMs': 10,
              'emissionIntervalMs': 10,
              'particleLifetimeMs': 10,
              'particlesPerEmission': 1,
            },
          ],
        }),
      );
      final mixedJson = _copy(json);
      (mixedJson['resources'] as List).add({
        ...resource('legacy', 'particleDefinition', legacy),
        'definitionVersion': 1,
        'dependencies': ['flame'],
      });
      final mixed = BattleMoveAnimationRecipe.fromJson(mixedJson);
      final mixedMedia = {...media, 'legacy': legacy};
      mixed.validateBundle(mixedMedia, availableCapabilities: capabilities);
      expect(
        mixed
            .readVerifiedSplParticleDefinitions(
              mixedMedia,
              availableCapabilities: capabilities,
            )
            .keys,
        ['effect'],
      );
      expect(
        () => mixed.readVerifiedParticleDefinitions(
          mixedMedia,
          availableCapabilities: capabilities,
        ),
        throwsFormatException,
      );
    },
  );
}
