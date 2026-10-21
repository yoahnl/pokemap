import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'map_entity_collision_footprint.dart';

bool isSceneActorInitialCollisionOwnerReferenceAvailable(
  ProjectManifest project,
  MapEntity entity,
) {
  if (!isSceneActorEntityReferenceAvailable(project, entity)) return false;
  final footprint = resolveEntityCollisionFootprint(entity);
  return footprint.size.width == 1 &&
      footprint.size.height == 1 &&
      footprint.pos == entity.pos &&
      (entity.presentation?.variants
              .where((variant) => variant.characterId != null)
              .every(
                (variant) =>
                    variant.size.width == 1 && variant.size.height == 1,
              ) ??
          true);
}

bool isSceneActorEntityReferenceAvailable(
  ProjectManifest project,
  MapEntity entity,
) {
  final variants = entity.presentation?.variants;
  if (variants != null) {
    if (entity.kind != MapEntityKind.npc &&
        entity.kind != MapEntityKind.custom) {
      return false;
    }
    final characterIds = variants
        .map((variant) => variant.characterId)
        .whereType<String>()
        .toSet();
    return characterIds.isNotEmpty &&
        characterIds.every(
          (id) =>
              project.characters
                  .where((character) => character.id == id)
                  .length ==
              1,
        );
  }
  if (entity.kind != MapEntityKind.npc || entity.npc == null) return false;
  final npc = entity.npc!;
  final directCharacterId = npc.characterId?.trim() ?? '';
  final String characterId;
  if (directCharacterId.isNotEmpty) {
    characterId = directCharacterId;
  } else {
    final trainerId = npc.trainerId?.trim() ?? '';
    if (trainerId.isEmpty) return false;
    final trainers = project.trainers.where(
      (trainer) => trainer.id == trainerId,
    );
    if (trainers.length != 1) return false;
    characterId = trainers.single.characterId?.trim() ?? '';
  }
  return characterId.isNotEmpty &&
      project.characters
              .where((character) => character.id == characterId)
              .length ==
          1;
}
