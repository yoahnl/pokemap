import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Smart Tile gameplay-zone provenance survives JSON round-trip', () {
    const zone = MapGameplayZone(
      id: 'grass',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 1, y: 2),
        size: GridSize(width: 2, height: 1),
      ),
      encounter: EncounterZonePayload(encounterTableId: 'route-grass'),
      smartTileProvenance: SmartTileGameplayZoneProvenance(
        smartTileLayerId: 'paths',
        smartTilePresetId: 'tall-grass',
        materialId: 'grass',
        behaviorKey: 'encounter.walk',
      ),
    );

    expect(
      MapGameplayZone.fromJson(
        jsonDecode(jsonEncode(zone.toJson())) as Map<String, dynamic>,
      ),
      zone,
    );
  });

  test('manual gameplay-zone JSON remains free of provenance metadata', () {
    const zone = MapGameplayZone(
      id: 'manual',
      kind: GameplayZoneKind.custom,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 1, height: 1),
      ),
    );

    expect(zone.toJson(), isNot(contains('smartTileProvenance')));
  });

  test('synchronization replaces its binding and preserves manual zones', () {
    const provenance = SmartTileGameplayZoneProvenance(
      smartTileLayerId: 'paths',
      smartTilePresetId: 'tall-grass',
      materialId: 'grass',
      behaviorKey: 'encounter.walk',
    );
    const previous = MapGameplayZone(
      id: 'tall-grass',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 3, height: 1),
      ),
      encounter: EncounterZonePayload(encounterTableId: 'old-table'),
      smartTileProvenance: provenance,
    );
    const manual = MapGameplayZone(
      id: 'manual-zone',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 4, y: 4),
        size: GridSize(width: 1, height: 1),
      ),
      encounter: EncounterZonePayload(encounterTableId: 'manual-table'),
    );
    const replacement = MapGameplayZone(
      id: 'tall-grass',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 2, height: 2),
      ),
      encounter: EncounterZonePayload(encounterTableId: 'new-table'),
      smartTileProvenance: provenance,
    );
    final map = _map(gameplayZones: const [previous, manual]);

    final result = synchronizeSmartTileGameplayZones(
      map,
      generatedZones: const [replacement],
    );

    expect(result.removedZones, const [previous]);
    expect(result.generatedZones, const [replacement]);
    expect(result.map.gameplayZones, const [replacement, manual]);
    expect(result.changed, isTrue);
  });

  test('synchronization keeps generated zones from another binding', () {
    const grass = SmartTileGameplayZoneProvenance(
      smartTileLayerId: 'paths',
      smartTilePresetId: 'tall-grass',
      materialId: 'grass',
      behaviorKey: 'encounter.walk',
    );
    const water = SmartTileGameplayZoneProvenance(
      smartTileLayerId: 'water',
      smartTilePresetId: 'water',
      materialId: 'water',
      behaviorKey: 'movement.surf',
    );
    const previousGrass = MapGameplayZone(
      id: 'grass-old',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 1, height: 1),
      ),
      smartTileProvenance: grass,
    );
    const waterZone = MapGameplayZone(
      id: 'water-zone',
      kind: GameplayZoneKind.movement,
      area: MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
      movement: MovementZonePayload(requiredMode: MovementMode.surf),
      smartTileProvenance: water,
    );
    const replacementGrass = MapGameplayZone(
      id: 'grass-new',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 1, height: 1),
      ),
      smartTileProvenance: grass,
    );

    final result = synchronizeSmartTileGameplayZones(
      _map(gameplayZones: const [previousGrass, waterZone]),
      generatedZones: const [replacementGrass],
    );

    expect(result.map.gameplayZones, const [replacementGrass, waterZone]);
  });

  test('synchronization rejects zones from multiple bindings', () {
    const first = MapGameplayZone(
      id: 'first',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 1, height: 1),
      ),
      smartTileProvenance: SmartTileGameplayZoneProvenance(
        smartTileLayerId: 'first-layer',
        smartTilePresetId: 'grass',
        materialId: 'grass',
        behaviorKey: 'encounter.walk',
      ),
    );
    const second = MapGameplayZone(
      id: 'second',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 1, y: 0),
        size: GridSize(width: 1, height: 1),
      ),
      smartTileProvenance: SmartTileGameplayZoneProvenance(
        smartTileLayerId: 'second-layer',
        smartTilePresetId: 'grass',
        materialId: 'grass',
        behaviorKey: 'encounter.walk',
      ),
    );

    expect(
      () => synchronizeSmartTileGameplayZones(
        _map(),
        generatedZones: const [first, second],
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}

MapData _map({List<MapGameplayZone> gameplayZones = const []}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 8, height: 8),
    gameplayZones: gameplayZones,
  );
}
