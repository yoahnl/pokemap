import 'package:map_core/map_core.dart';

import '../battle_start_request.dart';
import 'scene_battle_runtime_outcome_adapter.dart';

WildBattleStartRequest buildSceneWildBattleRequest({
  required SceneBattleRuntimeBattleRequest request,
  required ProjectManifest manifest,
  required OverworldReturnContext returnContext,
}) {
  final matches = manifest.encounterTables.where(
    (table) => table.id == request.battleTemplateId,
  );
  if (matches.length != 1 || matches.single.entries.length != 1) {
    throw StateError('A scripted wild battle requires a single-entry encounter table.');
  }
  final table = matches.single;
  final entry = table.entries.single;
  if (entry.minLevel < 1 || entry.minLevel != entry.maxLevel || entry.weight < 1) {
    throw StateError('A scripted wild battle requires a positive fixed level and weight.');
  }
  return WildBattleStartRequest(
    requestId: request.requestId,
    createdAtEpochMs: request.createdAtEpochMs,
    returnContext: returnContext,
    mapId: returnContext.mapId,
    encounterSourceId: request.npcEntityId,
    encounterSourceKind: EncounterSourceKind.gameplayZone,
    tableId: table.id,
    encounterKind: table.encounterKind,
    speciesId: entry.speciesId,
    level: entry.minLevel,
    minLevel: entry.minLevel,
    maxLevel: entry.maxLevel,
    weight: entry.weight,
    playerPos: returnContext.playerPos,
    generationSeed: request.createdAtEpochMs,
    pokemonOverrides: entry.pokemonOverrides,
  );
}
