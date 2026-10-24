import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'battle_start_request.dart';

WildBattleStartRequest buildBattleStartRequestFromEncounter({
  required GameplayEncounter encounter,
  required GameplayWorldState world,
  int? createdAtEpochMs,
  EncounterZonePayload? encounterSourceSnapshot,
  String? requestId,
}) {
  final now = createdAtEpochMs ?? DateTime.now().millisecondsSinceEpoch;
  final resolvedRequestId = requestId ??
      'wild:${encounter.mapId}:${encounter.sourceId}:${encounter.speciesId}:$now';
  return WildBattleStartRequest(
    requestId: resolvedRequestId,
    createdAtEpochMs: now,
    returnContext: OverworldReturnContext(
      mapId: world.map.id,
      playerPos: world.player.pos,
      playerFacing: world.player.facing,
    ),
    mapId: encounter.mapId,
    encounterSourceId: encounter.sourceId,
    encounterSourceKind: encounter.sourceKind,
    tableId: encounter.tableId,
    encounterKind: encounter.encounterKind,
    speciesId: encounter.speciesId,
    level: encounter.level,
    minLevel: encounter.minLevel,
    maxLevel: encounter.maxLevel,
    weight: encounter.weight,
    playerPos: encounter.playerPos,
    generationSeed: encounter.generationSeed,
    encounterVariantId: encounter.variantId,
    pokemonOverrides: encounter.pokemonOverrides,
    encounterSourceSnapshot: encounterSourceSnapshot,
  );
}
