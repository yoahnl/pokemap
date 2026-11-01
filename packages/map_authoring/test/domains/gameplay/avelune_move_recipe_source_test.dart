import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

final class _Transport implements PokemonBoundedExternalHttpTransport {
  final png = Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));
  late final particle = Uint8List.fromList(utf8.encode(jsonEncode({
    'schemaVersion': 1,
    'emitters': [
      {
        'textureId': 'tex',
        'emissionDurationMs': 1,
        'emissionIntervalMs': 1,
        'particleLifetimeMs': 1,
        'particlesPerEmission': 1
      }
    ],
  })));
  late final recipe = Uint8List.fromList(utf8.encode(jsonEncode({
    'schemaVersion': 1,
    'recipeId': 'recipe.source',
    'revision': 'r1',
    'moveSourceId': 'source-fire',
    'variant': 'default',
    'requiredCapabilities': ['startParticle'],
    'provenance': {
      'source': 'synthetic',
      'sourceRevision': '1',
      'sourcePaths': <String>[],
      'converter': 'test'
    },
    'resources': [
      {
        'id': 'tex',
        'role': 'texture',
        'mediaType': 'image/png',
        'sizeBytes': png.length,
        'sha256': sha256.convert(png).toString()
      },
      {
        'id': 'particle',
        'role': 'particleDefinition',
        'mediaType': 'application/vnd.avelune.particle+json',
        'sizeBytes': particle.length,
        'sha256': sha256.convert(particle).toString(),
        'definitionVersion': 1,
        'dependencies': ['tex']
      },
    ],
    'program': {
      'kind': 'startParticle',
      'resourceId': 'particle',
      'from': 'userMouth',
      'to': 'targetImpact'
    },
  })));
  bool corrupt = false;
  bool missing = false;
  bool wrongType = false;
  final requests = <Uri>[];

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    requests.add(uri);
    Map<String, Object> item(String id, Uint8List data, String type, String rep,
            Map<String, Object> metadata) =>
        {
          'id': id,
          'sha256': sha256.convert(data).toString(),
          'contentType': type,
          'usage': 'battle',
          'representation': rep,
          'style': 'gen5',
          'metadata': metadata
        };
    final data = uri.path.contains('/owners/move/')
        ? Uint8List.fromList(utf8.encode(jsonEncode([
            item('recipe-file', recipe,
                'application/vnd.avelune.battle-recipe+json', 'recipe', {
              'recipeId': 'recipe.source',
              'revision': 'r1',
              'moveSourceId': 'source-fire',
              'variant': 'default',
              'bindings': {'tex': 'texture-file', 'particle': 'particle-file'},
            }),
            if (!missing)
              item('texture-file', png, 'image/png',
                  wrongType ? 'audio' : 'sprite2d', {}),
            item('particle-file', particle,
                'application/vnd.avelune.particle+json', 'particle', {}),
          ])))
        : uri.path.endsWith('/recipe-file')
            ? recipe
            : uri.path.endsWith('/particle-file')
                ? particle
                : corrupt
                    ? Uint8List.fromList([1])
                    : png;
    return PokemonExternalHttpResponse(
        statusCode: 200,
        headers: const {},
        body: utf8.decode(uri.path.contains('/owners/move/') ? data : [],
            allowMalformed: false),
        bodyBytes: data);
  }
}

void main() {
  const limits = BattleRecipeBundleLimits(
      maxTextures: 4,
      maxTextureBytes: 10000,
      maxBundleBytes: 30000,
      maxDimension: 16,
      maxTexturePixels: 256,
      maxTotalPixels: 256);
  test(
      'binds a same-move API bundle to the distinct local move and verifies it',
      () async {
    final transport = _Transport();
    final source =
        AveluneMoveRecipeSource(AvelunePokemonMediaSource(client: transport));
    final result = await source.fetch(
        catalogMoveId: 'catalog-fire',
        sourceMoveId: 'source-fire',
        projectMoveId: 'local-fire',
        mediaId: 'recipe-file',
        limits: limits,
        availableCapabilities: {'startParticle'});
    expect(result.binding.projectMoveId, 'local-fire');
    expect(result.binding.sourceMoveId, 'source-fire');
    expect(result.catalogMoveId, 'catalog-fire');
    expect(result.recipeMediaId, 'recipe-file');
    expect(transport.requests.first.path,
        '/v1/media/public-2026-10/owners/move/catalog-fire');
    expect(result.bundle.media.keys, containsAll(['tex', 'particle']));
    transport.corrupt = true;
    await expectLater(
        source.fetch(
            catalogMoveId: 'catalog-fire',
            sourceMoveId: 'source-fire',
            projectMoveId: 'local-fire',
            mediaId: 'recipe-file',
            limits: limits,
            availableCapabilities: {'startParticle'}),
        throwsFormatException);
  });

  test('rejects unavailable capabilities and missing owner resources',
      () async {
    final transport = _Transport();
    final source =
        AveluneMoveRecipeSource(AvelunePokemonMediaSource(client: transport));
    await expectLater(
        source.fetch(
            catalogMoveId: 'catalog-fire',
            sourceMoveId: 'source-fire',
            projectMoveId: 'local-fire',
            mediaId: 'recipe-file',
            limits: limits,
            availableCapabilities: {}),
        throwsFormatException);
    transport.missing = true;
    await expectLater(
        source.fetch(
            catalogMoveId: 'catalog-fire',
            sourceMoveId: 'source-fire',
            projectMoveId: 'local-fire',
            mediaId: 'recipe-file',
            limits: limits,
            availableCapabilities: {'startParticle'}),
        throwsFormatException);
    transport.missing = false;
    transport.wrongType = true;
    await expectLater(
        source.fetch(
            catalogMoveId: 'catalog-fire',
            sourceMoveId: 'source-fire',
            projectMoveId: 'local-fire',
            mediaId: 'recipe-file',
            limits: limits,
            availableCapabilities: {'startParticle'}),
        throwsFormatException);
    await expectLater(
        source.fetch(
            catalogMoveId: 'catalog-fire',
            sourceMoveId: 'wrong-source',
            projectMoveId: 'local-fire',
            mediaId: 'recipe-file',
            limits: limits,
            availableCapabilities: {'startParticle'}),
        throwsFormatException);
  });

  test('enforces the total bundle budget before admitting resources', () async {
    final source = AveluneMoveRecipeSource(
        AvelunePokemonMediaSource(client: _Transport()));
    await expectLater(
        source.fetch(
            catalogMoveId: 'catalog-fire',
            sourceMoveId: 'source-fire',
            projectMoveId: 'local-fire',
            mediaId: 'recipe-file',
            limits: const BattleRecipeBundleLimits(
                maxTextures: 4,
                maxTextureBytes: 10000,
                maxBundleBytes: 20,
                maxDimension: 16,
                maxTexturePixels: 256,
                maxTotalPixels: 256),
            availableCapabilities: {'startParticle'}),
        throwsFormatException);
  });
}
