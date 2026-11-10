import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

class CharacterMovementInputs {
  String? problem;

  MapEntityNpcMovementConfig? timing(
    MapEntityNpcMovementConfig movement,
    String raw, {
    required bool pause,
  }) {
    final value = int.tryParse(raw);
    if (value == null ||
        value < (pause ? 0 : 1) ||
        value > (pause ? 3600000 : 60000)) {
      problem = pause
          ? 'L’attente doit être comprise entre 0 et 3 600 000 ms.'
          : 'La durée du pas doit être comprise entre 1 et 60 000 ms.';
      return null;
    }
    problem = null;
    return pause
        ? movement.copyWith(pauseDurationMs: value)
        : movement.copyWith(stepDurationMs: value);
  }

  MapEntityNpcMovementConfig? pauseChoice(
    MapEntityNpcMovementConfig movement,
    int index,
    String raw,
  ) {
    final value = int.tryParse(raw);
    if (value == null || value < 0 || value > 3600000) {
      problem = 'Chaque attente doit être comprise entre 0 et 3 600 000 ms.';
      return null;
    }
    final values = movement.pauseDurationsMs.toList()..[index] = value;
    problem = null;
    return movement.copyWith(pauseDurationsMs: values);
  }

  MapEntityNpcMovementConfig? area(
    MapEntityNpcMovementConfig movement,
    MapData map,
    String field,
    String raw,
  ) {
    final value = int.tryParse(raw);
    final area = movement.movementArea!;
    if (value == null) return null;
    final next = MapRect(
      pos: GridPos(
        x: field == 'x' ? value : area.pos.x,
        y: field == 'y' ? value : area.pos.y,
      ),
      size: GridSize(
        width: field == 'width' ? value : area.size.width,
        height: field == 'height' ? value : area.size.height,
      ),
    );
    if (next.pos.x < 0 ||
        next.pos.y < 0 ||
        next.size.width < 1 ||
        next.size.height < 1 ||
        next.pos.x + next.size.width > map.size.width ||
        next.pos.y + next.size.height > map.size.height) {
      problem = 'La zone doit rester dans les limites de la carte.';
      return null;
    }
    problem = null;
    return movement.copyWith(movementArea: next);
  }

  MapEntityNpcMovementConfig toggleArea(
    MapEntityNpcMovementConfig movement,
    MapData map,
    MapEntity entity,
  ) {
    final width = math.min(3, map.size.width),
        height = math.min(3, map.size.height);
    return movement.copyWith(
      movementArea: movement.movementArea == null
          ? MapRect(
              pos: GridPos(
                x: (entity.pos.x - 1).clamp(0, map.size.width - width),
                y: (entity.pos.y - 1).clamp(0, map.size.height - height),
              ),
              size: GridSize(width: width, height: height),
            )
          : null,
    );
  }
}
