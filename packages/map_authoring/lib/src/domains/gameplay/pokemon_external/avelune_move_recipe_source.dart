import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'avelune_pokemon_media_source.dart';

final class AveluneMoveRecipeSource {
  const AveluneMoveRecipeSource(this._media);

  final AvelunePokemonMediaSource _media;

  Future<
      ({
        BattleMoveRecipeBinding binding,
        InspectedBattleRecipeBundle bundle,
        String catalogMoveId,
        String recipeMediaId
      })> fetch({
    required String catalogMoveId,
    required String sourceMoveId,
    required String projectMoveId,
    required String mediaId,
    required BattleRecipeBundleLimits limits,
    required Set<String> availableCapabilities,
    void Function()? check,
  }) async {
    if (limits.maxTextures < 0 ||
        limits.maxTextureBytes < 0 ||
        limits.maxBundleBytes < 1 ||
        limits.maxDimension < 1 ||
        limits.maxTexturePixels < 1 ||
        limits.maxTotalPixels < 1) {
      throw const FormatException('Invalid bundle limits');
    }
    final entries = await _media.listMoveMedia(catalogMoveId, check: check);
    final byId = {for (final entry in entries) entry.id: entry};
    final record = byId[mediaId];
    if (record == null ||
        record.usage != 'battle' ||
        record.representation != 'recipe' ||
        record.contentType != 'application/vnd.avelune.battle-recipe+json') {
      throw const FormatException('Move recipe is unavailable');
    }
    final metadata = record.metadata;
    final bindings = metadata['bindings'];
    if (metadata['moveSourceId'] != sourceMoveId ||
        bindings is! Map ||
        bindings.length > 256 ||
        bindings.entries
            .any((entry) => entry.key is! String || entry.value is! String)) {
      throw const FormatException('Invalid move recipe metadata');
    }
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1,
      'projectMoveId': projectMoveId,
      'sourceMoveId': sourceMoveId,
      'catalogReleaseId': _media.release,
      'recipeId': metadata['recipeId'],
      'variant': metadata['variant'],
      'revision': metadata['revision'],
      'recipeSha256': record.sha256,
    });
    final recipeLimit =
        limits.maxBundleBytes < 1048576 ? limits.maxBundleBytes : 1048576;
    if (recipeLimit < 1) throw const FormatException('Invalid bundle limit');
    final recipeBytes =
        await _media.readMedia(record, maximumBytes: recipeLimit, check: check);
    var remaining = limits.maxBundleBytes - recipeBytes.length;
    final resources = <String, Uint8List>{};
    for (final entry in bindings.entries) {
      final item = byId[entry.value];
      if (item == null || item.usage != 'battle' || remaining < 1) {
        throw const FormatException('Move recipe resource is unavailable');
      }
      var maximum = remaining < 64 * 1024 * 1024 ? remaining : 64 * 1024 * 1024;
      if (item.contentType == 'image/png' && limits.maxTextureBytes < maximum) {
        maximum = limits.maxTextureBytes;
      }
      if (const {'audio/wav', 'audio/ogg', 'audio/mpeg'}
              .contains(item.contentType) &&
          BattleRecipeBundleInspector.maxSoundBytes < maximum) {
        maximum = BattleRecipeBundleInspector.maxSoundBytes;
      }
      if (maximum < 1) {
        throw const FormatException('Move recipe resource exceeds limit');
      }
      final bytes =
          await _media.readMedia(item, maximumBytes: maximum, check: check);
      remaining -= bytes.length;
      resources[entry.key as String] = bytes;
    }
    final bundle = const BattleRecipeBundleInspector().inspect(
      binding,
      recipeBytes,
      resources,
      limits: limits,
      availableCapabilities: availableCapabilities,
      expectedProjectMoveId: projectMoveId,
      expectedCatalogReleaseId: _media.release,
    );
    for (final resource in bundle.recipe.resources) {
      final media = byId[bindings[resource.id]];
      final representation = switch (resource.role) {
        'texture' => 'sprite2d',
        'particleDefinition' => 'particle',
        'sound' => 'audio',
        _ => null,
      };
      if (media == null ||
          media.contentType != resource.mediaType ||
          media.representation != representation) {
        throw const FormatException('Move recipe media type mismatch');
      }
    }
    return (
      binding: binding,
      bundle: bundle,
      catalogMoveId: catalogMoveId,
      recipeMediaId: mediaId,
    );
  }
}
