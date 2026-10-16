import 'package:map_core/map_core.dart';
import 'movement_block_reason.dart';

enum GameplayMovementTerrain { land, surf, underwater, conflict }

GameplayMovementTerrain movementTerrainAt(MapData map, int x, int y) {
  var surf = false;
  var dive = false;
  for (final zone in map.gameplayZones) {
    final payload = zone.movement;
    if (zone.kind != GameplayZoneKind.movement ||
        payload == null ||
        !gameplayZoneContainsPosition(zone, GridPos(x: x, y: y))) {
      continue;
    }
    surf |= payload.requiredMode == MovementMode.surf ||
        payload.allowedModes.contains(MovementMode.surf);
    dive |= payload.requiredMode == MovementMode.dive;
    if (payload.allowedModes.contains(MovementMode.dive)) {
      return GameplayMovementTerrain.conflict;
    }
  }
  return surf && dive
      ? GameplayMovementTerrain.conflict
      : dive
          ? GameplayMovementTerrain.underwater
          : surf
              ? GameplayMovementTerrain.surf
              : GameplayMovementTerrain.land;
}

GameplayMovementBlockReason? movementTerrainBlockReasonAt(
    {required MapData map,
    required int x,
    required int y,
    required MovementMode mode}) {
  if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
    return GameplayMovementBlockReason.outOfBounds;
  }
  final terrain = movementTerrainAt(map, x, y);
  if (terrain == GameplayMovementTerrain.conflict) {
    return GameplayMovementBlockReason.invalidMovementTerrain;
  }
  if (terrain == GameplayMovementTerrain.underwater) {
    return mode == MovementMode.dive
        ? null
        : GameplayMovementBlockReason.underwaterRequiresDive;
  }
  if (mode == MovementMode.dive) {
    return GameplayMovementBlockReason.diveRequiresUnderwater;
  }
  if (terrain == GameplayMovementTerrain.surf && mode != MovementMode.surf) {
    return GameplayMovementBlockReason.waterRequiresSurf;
  }
  return null;
}

bool movementTerrainAllowsRect(
    {required MapData map,
    required PixelRect rect,
    required int tileWidth,
    required int tileHeight,
    required MovementMode mode,
    bool bypassSurfRequirement = false}) {
  if (tileWidth <= 0 ||
      tileHeight <= 0 ||
      rect.widthPx <= 0 ||
      rect.heightPx <= 0 ||
      rect.leftPx < 0 ||
      rect.topPx < 0 ||
      rect.leftPx + rect.widthPx > map.size.width * tileWidth ||
      rect.topPx + rect.heightPx > map.size.height * tileHeight) {
    return false;
  }
  for (var y = rect.topPx ~/ tileHeight;
      y <= (rect.topPx + rect.heightPx - 1) ~/ tileHeight;
      y++) {
    for (var x = rect.leftPx ~/ tileWidth;
        x <= (rect.leftPx + rect.widthPx - 1) ~/ tileWidth;
        x++) {
      final reason =
          movementTerrainBlockReasonAt(map: map, x: x, y: y, mode: mode);
      if (reason != null &&
          !(bypassSurfRequirement &&
              reason == GameplayMovementBlockReason.waterRequiresSurf)) {
        return false;
      }
    }
  }
  return true;
}
