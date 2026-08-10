import 'package:map_core/map_core.dart';

int characterStudioSystemAnimationCount(ProjectCharacterEntry character) {
  return character.animations
      .where((animation) => animation.frames.isNotEmpty)
      .map((animation) => animation.state)
      .toSet()
      .length;
}

int characterStudioCustomAnimationCount(ProjectCharacterEntry character) {
  return character.customAnimations
      .where((animation) => animation.frames.isNotEmpty)
      .map((animation) => animation.definitionId)
      .toSet()
      .length;
}

int characterStudioAnimationCount(ProjectCharacterEntry character) {
  return characterStudioSystemAnimationCount(character) +
      characterStudioCustomAnimationCount(character);
}

typedef CharacterStudioThumbnailSelection = ({
  TilesetSourceRect source,
  String? sourceAssetId,
});

CharacterStudioThumbnailSelection characterStudioThumbnailSelection(
  ProjectCharacterEntry character,
) {
  final animation = character.animations
      .where(
        (entry) =>
            entry.state == CharacterAnimationState.idle &&
            entry.direction == EntityFacing.south &&
            entry.frames.isNotEmpty,
      )
      .firstOrNull;
  if (animation != null) {
    return (
      source: animation.frames.first.source,
      sourceAssetId: _normalizedAssetId(animation.sourceAssetId),
    );
  }
  for (final entry in character.animations) {
    if (entry.frames.isNotEmpty) {
      return (
        source: entry.frames.first.source,
        sourceAssetId: _normalizedAssetId(entry.sourceAssetId),
      );
    }
  }
  return (source: const TilesetSourceRect(x: 0, y: 0), sourceAssetId: null);
}

String? _normalizedAssetId(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
