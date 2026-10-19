import 'package:map_core/map_core.dart';

import 'direction.dart';

enum GameplayMovementEffectKind {
  slide,
  movementCost,
}

GameplayMovementEffect? resolveGameplaySlideEffectAt(
  MapData map,
  GridPos position,
  Direction direction,
) {
  if (map.spatialScene != null || map.version == ProjectVersion.v9) {
    return null;
  }
  MapGameplayZone? best;
  for (final zone in map.gameplayZones) {
    if (zone.kind != GameplayZoneKind.movementEffect ||
        !gameplayZoneContainsPosition(zone, position)) {
      continue;
    }
    if (best == null || zone.priority >= best.priority) {
      best = zone;
    }
  }
  final payload = best?.movementEffect;
  if (best == null ||
      payload?.effectKind != MovementEffectZoneKind.slide ||
      payload!.movementCost <= 0 ||
      payload.directedJump != null ||
      best.cellMask != null ||
      best.id.trim().isEmpty) {
    return null;
  }
  return GameplayMovementEffect.slide(
    zoneId: best.id,
    zoneName: best.name.trim().isEmpty ? best.id : best.name,
    position: position,
    priority: best.priority,
    direction: direction,
  );
}

final class GameplayMovementEffect {
  factory GameplayMovementEffect.slide({
    required String zoneId,
    required String zoneName,
    required GridPos position,
    required int priority,
    required Direction direction,
  }) {
    _validateZoneIdentity(zoneId: zoneId, zoneName: zoneName);
    return GameplayMovementEffect._(
      kind: GameplayMovementEffectKind.slide,
      zoneId: zoneId,
      zoneName: zoneName,
      position: position,
      priority: priority,
      direction: direction,
    );
  }

  factory GameplayMovementEffect.movementCost({
    required String zoneId,
    required String zoneName,
    required GridPos position,
    required int priority,
    required int movementCost,
  }) {
    _validateZoneIdentity(zoneId: zoneId, zoneName: zoneName);
    if (movementCost <= 0) {
      throw ArgumentError.value(
        movementCost,
        'movementCost',
        'must be positive',
      );
    }
    return GameplayMovementEffect._(
      kind: GameplayMovementEffectKind.movementCost,
      zoneId: zoneId,
      zoneName: zoneName,
      position: position,
      priority: priority,
      movementCost: movementCost,
    );
  }

  const GameplayMovementEffect._({
    required this.kind,
    required this.zoneId,
    required this.zoneName,
    required this.position,
    required this.priority,
    this.direction,
    this.movementCost,
  });

  final GameplayMovementEffectKind kind;
  final String zoneId;
  final String zoneName;
  final GridPos position;
  final int priority;
  final Direction? direction;
  final int? movementCost;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GameplayMovementEffect &&
            other.kind == kind &&
            other.zoneId == zoneId &&
            other.zoneName == zoneName &&
            other.position == position &&
            other.priority == priority &&
            other.direction == direction &&
            other.movementCost == movementCost;
  }

  @override
  int get hashCode {
    return Object.hash(
      kind,
      zoneId,
      zoneName,
      position,
      priority,
      direction,
      movementCost,
    );
  }
}

void _validateZoneIdentity({
  required String zoneId,
  required String zoneName,
}) {
  if (zoneId.trim().isEmpty) {
    throw ArgumentError.value(zoneId, 'zoneId', 'must not be empty');
  }
  if (zoneName.trim().isEmpty) {
    throw ArgumentError.value(zoneName, 'zoneName', 'must not be empty');
  }
}
