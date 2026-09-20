import 'dart:math' as math;

import '../models/map_data.dart';
import '../models/project_manifest.dart';

({double x, double y}) cinematicEntityFocusPoint({
  required MapEntity entity,
  required ProjectManifest project,
}) {
  var characterId = entity.npc?.characterId;
  if (characterId == null || characterId.trim().isEmpty) {
    for (final trainer in project.trainers) {
      if (trainer.id == entity.npc?.trainerId) {
        characterId = trainer.characterId;
        break;
      }
    }
  }
  for (final character in project.characters) {
    if (character.id != characterId) continue;
    final width = math.max(2, character.frameWidth);
    final height = math.max(2, character.frameHeight);
    return (
      x: entity.pos.x - math.max(0, width - entity.size.width) / 2 + width / 2,
      y: entity.pos.y + entity.size.height - height / 2,
    );
  }
  return (
    x: entity.pos.x + entity.size.width / 2,
    y: entity.pos.y + entity.size.height / 2,
  );
}
