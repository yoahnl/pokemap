import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';

bool isSceneActorEntityReferenceAvailable(
  ProjectManifest project,
  MapEntity entity,
) {
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
