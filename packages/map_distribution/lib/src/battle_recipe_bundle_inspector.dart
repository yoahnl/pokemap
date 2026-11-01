import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'raster_image_dimensions.dart';
import 'static_png_validation.dart';

final class BattleRecipeBundleLimits {
  const BattleRecipeBundleLimits({
    required this.maxTextures,
    required this.maxTextureBytes,
    required this.maxBundleBytes,
    required this.maxDimension,
    required this.maxTexturePixels,
    required this.maxTotalPixels,
  });

  final int maxTextures;
  final int maxTextureBytes;
  final int maxBundleBytes;
  final int maxDimension;
  final int maxTexturePixels;
  final int maxTotalPixels;
}

final class InspectedBattleRecipeBundle {
  const InspectedBattleRecipeBundle._(
      this.recipe, this.recipeBytes, this.media);

  final BattleMoveAnimationRecipe recipe;
  final Uint8List recipeBytes;
  final Map<String, Uint8List> media;
}

final class BattleRecipeBundleInspector {
  const BattleRecipeBundleInspector();

  InspectedBattleRecipeBundle inspect(
    BattleMoveRecipeBinding binding,
    Uint8List recipeBytes,
    Map<String, Uint8List> media, {
    required BattleRecipeBundleLimits limits,
    required Set<String> availableCapabilities,
    required String expectedProjectMoveId,
    required String expectedCatalogReleaseId,
  }) {
    if (limits.maxTextures < 0 ||
        limits.maxTextureBytes < 0 ||
        limits.maxBundleBytes < 1 ||
        limits.maxDimension < 1 ||
        limits.maxTexturePixels < 1 ||
        limits.maxTotalPixels < 1) {
      throw const FormatException('Invalid bundle limits');
    }
    if (binding.projectMoveId != expectedProjectMoveId ||
        binding.catalogReleaseId != expectedCatalogReleaseId) {
      throw const FormatException('Recipe binding does not match project');
    }
    if (media.length > 256 || recipeBytes.length > 1048576) {
      throw const FormatException('Recipe bundle too large');
    }
    var bytesCount = recipeBytes.length;
    for (final bytes in media.values) {
      bytesCount += bytes.length;
      if (bytesCount > limits.maxBundleBytes) {
        throw const FormatException('Recipe bundle exceeds byte limit');
      }
    }
    if (bytesCount > limits.maxBundleBytes) {
      throw const FormatException('Recipe bundle exceeds byte limit');
    }
    final recipe = binding.resolve(recipeBytes, media,
        availableCapabilities: availableCapabilities);
    final declared = recipe.resources.map((resource) => resource.id).toSet();
    if (declared.length != media.length || !declared.containsAll(media.keys)) {
      throw const FormatException('Unexpected recipe media');
    }
    final textures = recipe.resources
        .where((resource) => resource.role == 'texture')
        .toList();
    if (recipe.resources.any((resource) => resource.role == 'sound')) {
      throw const FormatException('Sound inspection is not available');
    }
    if (textures.length > limits.maxTextures) {
      throw const FormatException('Texture count exceeds limit');
    }
    var totalPixels = 0;
    for (final texture in textures) {
      final bytes = media[texture.id]!;
      if (bytes.length > limits.maxTextureBytes) {
        throw const FormatException('Texture exceeds byte limit');
      }
      final dimensions =
          decodeRasterImageDimensions(bytes, mediaType: 'image/png');
      if (dimensions == null ||
          dimensions.width < 1 ||
          dimensions.height < 1 ||
          dimensions.width > limits.maxDimension ||
          dimensions.height > limits.maxDimension ||
          dimensions.width * dimensions.height > limits.maxTexturePixels) {
        throw const FormatException('Texture dimensions exceed limits');
      }
      totalPixels += dimensions.width * dimensions.height;
      if (totalPixels > limits.maxTotalPixels) {
        throw const FormatException('Texture pixel budget exceeded');
      }
    }
    final recipeSnapshot = Uint8List.fromList(recipeBytes).asUnmodifiableView();
    final mediaSnapshot = <String, Uint8List>{
      for (final entry in media.entries)
        entry.key: Uint8List.fromList(entry.value).asUnmodifiableView(),
    };
    final verifiedRecipe = binding.resolve(recipeSnapshot, mediaSnapshot,
        availableCapabilities: availableCapabilities);
    final snapshotIds =
        verifiedRecipe.resources.map((resource) => resource.id).toSet();
    if (snapshotIds.length != mediaSnapshot.length ||
        !snapshotIds.containsAll(mediaSnapshot.keys)) {
      throw const FormatException('Unexpected recipe media');
    }
    for (final texture in textures) {
      final bytes = mediaSnapshot[texture.id]!;
      try {
        final decoder = validatedStaticPngDecoder(bytes,
            maxDimension: limits.maxDimension,
            maxPixels: limits.maxTexturePixels);
        final decoded = decoder.decodeFrame(0);
        final dimensions =
            decodeRasterImageDimensions(bytes, mediaType: 'image/png')!;
        if (decoded == null ||
            decoded.width != dimensions.width ||
            decoded.height != dimensions.height) {
          throw const FormatException('Texture is incomplete');
        }
      } on FormatException {
        rethrow;
      } on Object {
        throw const FormatException('Texture cannot be decoded');
      }
    }
    return InspectedBattleRecipeBundle._(
      verifiedRecipe,
      recipeSnapshot,
      Map.unmodifiable(mediaSnapshot),
    );
  }
}
