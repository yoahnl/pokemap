import 'package:map_core/map_core.dart';

ProjectCharacterEntry? resolveDefaultPlayerCharacter(ProjectManifest manifest) {
  final charId = manifest.settings.defaultPlayerCharacterId?.trim();
  if (charId == null || charId.isEmpty) {
    return null;
  }
  for (final character in manifest.characters) {
    if (character.id == charId) {
      return character;
    }
  }
  return null;
}

String? resolveNpcCharacterId(
  MapEntity entity,
  ProjectManifest manifest,
) {
  if (entity.kind != MapEntityKind.npc) {
    return null;
  }
  final directCharacterId = entity.npc?.characterId?.trim();
  if (directCharacterId != null && directCharacterId.isNotEmpty) {
    return directCharacterId;
  }
  final trainerId = entity.npc?.trainerId?.trim();
  if (trainerId == null || trainerId.isEmpty) {
    return null;
  }
  for (final trainer in manifest.trainers) {
    if (trainer.id == trainerId) {
      final trainerCharacterId = trainer.characterId?.trim();
      if (trainerCharacterId != null && trainerCharacterId.isNotEmpty) {
        return trainerCharacterId;
      }
      break;
    }
  }
  return null;
}

ProjectCharacterEntry? resolveNpcCharacterEntry(
  MapEntity entity,
  ProjectManifest manifest,
) {
  final charId = resolveNpcCharacterId(entity, manifest);
  if (charId == null) {
    return null;
  }
  for (final character in manifest.characters) {
    if (character.id == charId) {
      return character;
    }
  }
  return null;
}
