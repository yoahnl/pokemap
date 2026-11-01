import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'support/loopback_recipe_transport.dart';

void main() {
  final endpoint = Platform.environment['AVELUNE_RECIPE_TEST_ENDPOINT'];
  final release = Platform.environment['AVELUNE_RECIPE_TEST_RELEASE'];
  final owner = Platform.environment['AVELUNE_RECIPE_TEST_OWNER'];
  final source = Platform.environment['AVELUNE_RECIPE_TEST_SOURCE'];
  final media = Platform.environment['AVELUNE_RECIPE_TEST_MEDIA'];
  final recipeHash = Platform.environment['AVELUNE_RECIPE_TEST_RECIPE_SHA256'];
  final particleHash =
      Platform.environment['AVELUNE_RECIPE_TEST_PARTICLE_SHA256'];
  final textureHash =
      Platform.environment['AVELUNE_RECIPE_TEST_TEXTURE_SHA256'];
  final configured = [
    endpoint,
    release,
    owner,
    source,
    media,
    recipeHash,
    particleHash,
    textureHash,
  ].every((value) => value != null && value.isNotEmpty);

  test(
    'fetches a paginated recipe and verifies a real loopback API bundle',
    () async {
      final transport = LoopbackRecipeTransport(endpoint!);
      addTearDown(transport.close);
      final result =
          await AveluneMoveRecipeSource(
            AvelunePokemonMediaSource(
              client: transport,
              baseUri: 'https://recipe-test.invalid/v1/media',
              release: release!,
            ),
          ).fetch(
            catalogMoveId: owner!,
            sourceMoveId: source!,
            projectMoveId: 'local-tackle',
            mediaId: media!,
            limits: const BattleRecipeBundleLimits(
              maxTextures: 16,
              maxTextureBytes: 8 * 1024 * 1024,
              maxBundleBytes: 32 * 1024 * 1024,
              maxDimension: 2048,
              maxTexturePixels: 4000000,
              maxTotalPixels: 16000000,
            ),
            availableCapabilities:
                BattleMoveAnimationRecipe.recognizedCapabilities,
          );
      expect(result.binding.recipeSha256, recipeHash);
      expect(result.binding.projectMoveId, 'local-tackle');
      expect(result.binding.sourceMoveId, source);
      expect(result.catalogMoveId, owner);
      expect(result.recipeMediaId, media);
      final resources = result.bundle.recipe.resources;
      expect(
        resources
            .where((item) => item.role == 'particleDefinition')
            .single
            .sha256Hex,
        particleHash,
      );
      expect(
        resources.where((item) => item.role == 'texture').single.sha256Hex,
        textureHash,
      );
      expect(
        resources
            .where((item) => item.role == 'particleDefinition')
            .single
            .mediaType,
        'application/vnd.avelune.particle+json',
      );
      expect(
        resources.where((item) => item.role == 'texture').single.mediaType,
        'image/png',
      );
      final ownerRequests = transport.requests
          .where((uri) => uri.path.endsWith('/owners/move/$owner'))
          .toList();
      expect(ownerRequests.length, greaterThanOrEqualTo(2));
      expect(ownerRequests.first.queryParameters['limit'], '100');
      expect(ownerRequests.skip(1).first.queryParameters['after'], isNotEmpty);
    },
    skip: configured ? false : 'Requires an isolated local recipe API fixture',
  );
}
