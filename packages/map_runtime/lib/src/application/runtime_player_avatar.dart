import 'dart:ui';

import 'package:map_core/map_core.dart';

import 'character_animation_source_resolver.dart';
import 'load_runtime_map_bundle.dart';
import 'runtime_map_bundle.dart';

Future<RuntimeMapBundle> prepareRuntimePlayerAvatarBundle(
  RuntimeMapBundle bundle,
  String characterId,
) async {
  final matches = bundle.manifest.characters
      .where((entry) => entry.id == characterId)
      .toList();
  if (matches.length == 1 &&
      runtimePlayerAvatarImageIds(matches.single)
          .every(bundle.runtimeImageAbsolutePathsById.containsKey)) {
    return bundle;
  }
  final catalog = bundle.projectCatalog;
  if (catalog == null) return bundle;
  final project = await catalog.manifestForCharacter(characterId);
  final character = resolveScenePlayerAvatarCharacter(project, characterId);
  final assets = await catalog.loadAssetCatalog();
  final imageIds = runtimePlayerAvatarImageIds(character);
  final tilesets = resolveTilesetAbsolutePaths(
    manifest: project,
    projectRoot: bundle.projectRootDirectory,
    tilesetIds: {
      if (imageIds.contains(character.tilesetId)) character.tilesetId,
    },
    assetCatalog: assets,
  );
  final animations = buildCharacterAnimationSourcePreloadPlan(
    manifest: project,
    projectRootDirectory: bundle.projectRootDirectory,
    assetCatalog: assets,
  );
  final expanded = bundle.copyWith(
    manifest: bundle.manifest.copyWith(
      characters: [
        ...bundle.manifest.characters.where(
          (entry) => entry.id != character.id,
        ),
        character,
      ],
      tilesets: [
        ...bundle.manifest.tilesets.where(
          (entry) => !project.tilesets.any((next) => next.id == entry.id),
        ),
        ...project.tilesets,
      ],
    ),
    tilesetAbsolutePathsById: {...bundle.tilesetAbsolutePathsById, ...tilesets},
    characterAnimationAbsolutePathsByAssetId: {
      ...bundle.characterAnimationAbsolutePathsByAssetId,
      ...animations.absolutePathsByAssetId,
    },
  );
  if (!imageIds.every(expanded.runtimeImageAbsolutePathsById.containsKey)) {
    throw StateError('The selected player avatar media is unavailable.');
  }
  return expanded;
}

Set<String> runtimePlayerAvatarImageIds(ProjectCharacterEntry character) => {
  for (final animation in character.animations)
    if (animation.sourceAssetId case final String id when id.trim().isNotEmpty)
      characterAnimationRuntimeImageId(id)
    else
      character.tilesetId,
  for (final animation in character.customAnimations)
    characterAnimationRuntimeImageId(animation.sourceAssetId),
};

void validateRuntimePlayerAvatarImages({
  required ProjectCharacterEntry character,
  required ProjectSettings settings,
  required Set<String> availableImageIds,
  required bool Function(String imageId, Rect sourceRect) containsSourceRect,
}) {
  final resolver = CharacterAnimationSourceResolver();
  void validate(ResolvedCharacterAnimationFrameSource? source) {
    if (source == null ||
        !containsSourceRect(source.imageId, source.sourceRect)) {
      throw StateError(
        'The player avatar animation media is unavailable or invalid.',
      );
    }
  }

  for (final animation in character.animations) {
    for (final frame in animation.frames) {
      validate(
        resolver.resolveFrame(
          character: character,
          animation: animation,
          frame: frame,
          tileWidth: settings.tileWidth,
          tileHeight: settings.tileHeight,
          availableImageIds: availableImageIds,
        ),
      );
    }
  }
  for (final clip in character.customAnimations) {
    for (final frame in clip.frames) {
      validate(
        resolver.resolveCustomFrame(
          character: character,
          clip: clip,
          frame: frame,
          availableImageIds: availableImageIds,
        ),
      );
    }
  }
}
