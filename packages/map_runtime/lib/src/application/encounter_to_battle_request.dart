import 'package:map_gameplay/map_gameplay.dart';

import 'battle_start_request.dart';

WildBattleStartRequest buildBattleStartRequestFromEncounter({
  required GameplayEncounter encounter,
  required GameplayWorldState world,
  int? createdAtEpochMs,
}) {
  final now = createdAtEpochMs ?? DateTime.now().millisecondsSinceEpoch;
  final requestId =
      'wild:${encounter.mapId}:${encounter.zoneId}:${encounter.speciesId}:$now';
  return WildBattleStartRequest(
    requestId: requestId,
    createdAtEpochMs: now,
    returnContext: OverworldReturnContext(
      mapId: world.map.id,
      playerPos: world.player.pos,
      playerFacing: world.player.facing,
    ),
    mapId: encounter.mapId,
    zoneId: encounter.zoneId,
    tableId: encounter.tableId,
    encounterKind: encounter.encounterKind,
    speciesId: encounter.speciesId,
    level: encounter.level,
    minLevel: encounter.minLevel,
    maxLevel: encounter.maxLevel,
    weight: encounter.weight,
    playerPos: encounter.playerPos,
  );
}
