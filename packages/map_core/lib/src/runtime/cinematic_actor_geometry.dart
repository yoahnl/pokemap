import 'dart:math' as math;

import '../models/map_data.dart';
import '../models/geometry.dart';
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

GridPos? cinematicEntityGridPositionForFocus({
  required MapEntity entity,
  required ProjectManifest project,
  required double focusX,
  required double focusY,
}) {
  if (!focusX.isFinite || !focusY.isFinite) return null;
  final current = cinematicEntityFocusPoint(entity: entity, project: project);
  final x = focusX - (current.x - entity.pos.x);
  final y = focusY - (current.y - entity.pos.y);
  if (!x.isFinite || !y.isFinite || x < 0 || y < 0 ||
      x != x.truncateToDouble() || y != y.truncateToDouble()) {
    return null;
  }
  return GridPos(x: x.toInt(), y: y.toInt());
}
