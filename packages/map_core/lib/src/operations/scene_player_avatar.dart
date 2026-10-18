import '../models/enums.dart';
import '../models/project_manifest.dart';

ProjectCharacterEntry resolveScenePlayerAvatarCharacter(
  ProjectManifest project,
  String characterId,
) {
  final id = characterId.trim();
  final characters = project.characters.where(
    (character) => character.id == id,
  );
  if (id.isEmpty || characters.length != 1) {
    throw FormatException('Player avatar must reference one character: $id.');
  }
  final character = characters.single;
  if (character.frameWidth <= 0 || character.frameHeight <= 0) {
    throw FormatException('Player avatar has invalid frame dimensions: $id.');
  }
  for (final direction in EntityFacing.values) {
    final walk = character.animations.where(
      (animation) =>
          animation.state == CharacterAnimationState.walk &&
          animation.direction == direction,
    );
    if (walk.length != 1 || walk.single.frames.isEmpty) {
      throw FormatException(
        'Player avatar needs one walk animation for ${direction.name}: $id.',
      );
    }
  }
  for (final animation in character.animations) {
    for (final frame in animation.frames) {
      final source = frame.source;
      if (frame.durationMs <= 0 ||
          source.x < 0 ||
          source.y < 0 ||
          source.width <= 0 ||
          source.height <= 0) {
        throw FormatException(
          'Player avatar has an invalid animation frame: $id.',
        );
      }
    }
  }
  if (character.animations.any(
    (animation) => animation.sourceAssetId?.trim().isNotEmpty != true,
  )) {
    final tilesets = project.tilesets.where(
      (tileset) => tileset.id == character.tilesetId,
    );
    if (tilesets.length != 1) {
      throw FormatException('Player avatar needs one animation tileset: $id.');
    }
  }
  return character;
}
