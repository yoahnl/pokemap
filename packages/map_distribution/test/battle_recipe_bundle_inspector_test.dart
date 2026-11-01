import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/src/battle_recipe_bundle_inspector.dart';
import 'package:test/test.dart';

void main() {
  Uint8List png(int width, int height) => Uint8List.fromList(
      img.encodePng(img.Image(width: width, height: height)));
  ({
    BattleMoveRecipeBinding binding,
    Uint8List recipe,
    Map<String, Uint8List> media
  }) fixture(Uint8List texture, {Uint8List? second, Uint8List? sound}) {
    final definition = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'emitters': [
        {
          'textureId': 'tex',
          'emissionDurationMs': 100,
          'emissionIntervalMs': 20,
          'particleLifetimeMs': 200,
          'particlesPerEmission': 1
        },
        if (second != null)
          {
            'textureId': 'tex2',
            'emissionDurationMs': 100,
            'emissionIntervalMs': 20,
            'particleLifetimeMs': 200,
            'particlesPerEmission': 1
          },
      ],
    })));
    Map<String, dynamic> resource(
            String id, String role, String mime, Uint8List bytes) =>
        {
          'id': id,
          'role': role,
          'mediaType': mime,
          'sizeBytes': bytes.length,
          'sha256': sha256.convert(bytes).toString(),
        };
    final recipe = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'recipeId': 'fire',
      'revision': '1',
      'moveSourceId': 'flamethrower',
      'variant': 'default',
      'requiredCapabilities': [
        'sequence',
        'startParticle',
        'waitEffects',
        if (sound != null) 'sound'
      ],
      'provenance': {
        'source': 'synthetic',
        'sourceRevision': '1',
        'sourcePaths': <String>[],
        'converter': 'test/1'
      },
      'resources': [
        {
          ...resource('particle', 'particleDefinition',
              'application/vnd.avelune.particle+json', definition),
          'definitionVersion': 1,
          'dependencies': ['tex', if (second != null) 'tex2']
        },
        resource('tex', 'texture', 'image/png', texture),
        if (second != null) resource('tex2', 'texture', 'image/png', second),
        if (sound != null) resource('sound', 'sound', 'audio/ogg', sound),
      ],
      'program': {
        'kind': 'sequence',
        'steps': [
          {
            'kind': 'startParticle',
            'resourceId': 'particle',
            'from': 'userMouth',
            'to': 'targetImpact'
          },
          {'kind': 'waitEffects'},
        ]
      },
    })));
    return (
      binding: BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': 'local-fire',
        'sourceMoveId': 'flamethrower',
        'catalogReleaseId': 'test',
        'recipeId': 'fire',
        'variant': 'default',
        'revision': '1',
        'recipeSha256': sha256.convert(recipe).toString(),
      }),
      recipe: recipe,
      media: {
        'particle': definition,
        'tex': texture,
        if (second != null) 'tex2': second,
        if (sound != null) 'sound': sound
      }
    );
  }

  BattleRecipeBundleLimits limits(
          {int maxTextures = 2,
          int maxTextureBytes = 10000,
          int maxBundleBytes = 20000,
          int maxDimension = 16,
          int maxTexturePixels = 256,
          int maxTotalPixels = 256}) =>
      BattleRecipeBundleLimits(
        maxTextures: maxTextures,
        maxTextureBytes: maxTextureBytes,
        maxBundleBytes: maxBundleBytes,
        maxDimension: maxDimension,
        maxTexturePixels: maxTexturePixels,
        maxTotalPixels: maxTotalPixels,
      );
  const inspector = BattleRecipeBundleInspector();
  const capabilities = {'sequence', 'startParticle', 'waitEffects'};
  InspectedBattleRecipeBundle inspect(
          ({
            BattleMoveRecipeBinding binding,
            Uint8List recipe,
            Map<String, Uint8List> media
          }) sample,
          BattleRecipeBundleLimits policy) =>
      inspector.inspect(
        sample.binding,
        sample.recipe,
        sample.media,
        limits: policy,
        availableCapabilities: capabilities,
        expectedProjectMoveId: 'local-fire',
        expectedCatalogReleaseId: 'test',
      );

  test('checks complete PNG and returns immutable verified snapshots', () {
    final sample = fixture(png(2, 3));
    final result = inspect(sample, limits());
    final original = List<int>.of(result.media['tex']!);
    sample.media['tex']![0] = 0;
    sample.recipe[0] = 0;
    expect(result.media['tex'], original);
    expect(() => result.media['tex']![0] = 0, throwsUnsupportedError);
    expect(() => result.recipeBytes[0] = 0, throwsUnsupportedError);
  });

  test('rejects invalid or changed PNG bytes and per-bundle limits', () {
    final sample = fixture(png(4, 4));
    for (final policy in [
      limits(maxTextures: 0),
      limits(maxTextureBytes: 1),
      limits(maxBundleBytes: 10),
      limits(maxDimension: 3),
      limits(maxTexturePixels: 15),
      limits(maxTotalPixels: 15)
    ]) {
      expect(() => inspect(sample, policy), throwsFormatException);
    }
    expect(
        () => inspect((
              binding: sample.binding,
              recipe: sample.recipe,
              media: {
                ...sample.media,
                'tex': Uint8List.fromList([0, 1])
              }
            ), limits()),
        throwsFormatException);
    final invalid = fixture(Uint8List.fromList([0, 1, 2, 3]));
    expect(() => inspect(invalid, limits()), throwsFormatException);
    final corrupted = png(4, 4);
    corrupted[corrupted.length - 1] ^= 1;
    final matchingHashButBadPng = fixture(corrupted);
    expect(
        () => inspect(matchingHashButBadPng, limits()), throwsFormatException);
  });

  test('bounds the sum of pixels and the number of distinct textures', () {
    final sample = fixture(png(4, 4), second: png(4, 4));
    expect(
        () => inspect(sample, limits(maxTexturePixels: 16, maxTotalPixels: 32)),
        returnsNormally);
    expect(
        () => inspect(sample, limits(maxTexturePixels: 16, maxTotalPixels: 31)),
        throwsFormatException);
    expect(
        () => inspect(sample, limits(maxTextures: 1)), throwsFormatException);
  });

  test('refuses sound even when the caller lists the sound capability', () {
    final sample = fixture(png(2, 2), sound: Uint8List.fromList([1, 2]));
    expect(
      () => inspector.inspect(sample.binding, sample.recipe, sample.media,
          limits: limits(),
          availableCapabilities: {...capabilities, 'sound'},
          expectedProjectMoveId: 'local-fire',
          expectedCatalogReleaseId: 'test'),
      throwsFormatException,
    );
  });

  test('refuses foreign bindings and unexpected extra media', () {
    final sample = fixture(png(2, 2));
    expect(
      () => inspector.inspect(sample.binding, sample.recipe, sample.media,
          limits: limits(),
          availableCapabilities: capabilities,
          expectedProjectMoveId: 'other',
          expectedCatalogReleaseId: 'test'),
      throwsFormatException,
    );
    expect(
      () => inspect((
        binding: sample.binding,
        recipe: sample.recipe,
        media: {
          ...sample.media,
          'extra': Uint8List.fromList([1])
        }
      ), limits()),
      throwsFormatException,
    );
    expect(
      () => inspector.inspect(sample.binding, sample.recipe, sample.media,
          limits: limits(),
          availableCapabilities: {'sequence'},
          expectedProjectMoveId: 'local-fire',
          expectedCatalogReleaseId: 'test'),
      throwsFormatException,
    );
  });
}
