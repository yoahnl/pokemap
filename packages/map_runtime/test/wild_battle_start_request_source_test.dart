import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';

void main() {
  test('wild battle request preserves a Smart Tile encounter source', () {
    const encounter = GameplayEncounter(
      mapId: 'route',
      sourceId: 'smart_tile_layer:grass_north',
      sourceKind: EncounterSourceKind.smartTileLayer,
      tableId: 'grass_north',
      encounterKind: EncounterKind.walk,
      speciesId: 'sproutle',
      level: 5,
      minLevel: 4,
      maxLevel: 6,
      weight: 10,
      playerPos: GridPos(x: 2, y: 1),
    );
    final world = GameplayWorldState.initial(
      map: MapData(
        id: 'route',
        name: 'Route',
        size: const GridSize(width: 4, height: 4),
      ),
      playerPos: const GridPos(x: 2, y: 1),
      playerFacing: Direction.south,
    );

    final request = buildBattleStartRequestFromEncounter(
      encounter: encounter,
      world: world,
      createdAtEpochMs: 42,
    );

    expect(request.encounterSourceId, 'smart_tile_layer:grass_north');
    expect(request.encounterSourceKind, EncounterSourceKind.smartTileLayer);
    expect(request.source, RuntimeBattleSourceKind.wildEncounter);
    expect(request.toJson(), containsPair('encounterSourceKind', 'smartTileLayer'));
    expect(request.toJson(), isNot(contains('zoneId')));
  });
}
