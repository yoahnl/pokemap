import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Tall grass model characterization', () {
    test('uses terrain visuals and encounter zones as separate contracts', () {
      const visualPreset = ProjectTerrainPreset(
        id: 'tall_grass',
        name: 'Hautes herbes',
        terrainType: TerrainType.grass,
        tilesetId: 'nature',
        variants: [
          TerrainPresetVariant(
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 3, y: 2),
              ),
            ],
          ),
        ],
      );

      final map = MapData(
        id: 'route_1',
        name: 'Route 1',
        size: const GridSize(width: 4, height: 3),
        layers: const [
          MapLayer.terrain(
            id: 'terrain',
            name: 'Terrain',
            terrains: [
              TerrainType.none,
              TerrainType.none,
              TerrainType.none,
              TerrainType.none,
              TerrainType.none,
              TerrainType.grass,
              TerrainType.grass,
              TerrainType.none,
              TerrainType.none,
              TerrainType.none,
              TerrainType.none,
              TerrainType.none,
            ],
          ),
        ],
        gameplayZones: const [
          MapGameplayZone(
            id: 'route_1_tall_grass_encounters',
            name: 'Rencontres hautes herbes',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 2, height: 1),
            ),
            encounter: EncounterZonePayload(
              encounterTableId: 'route_1_grass',
              encounterKind: EncounterKind.walk,
            ),
          ),
        ],
      );

      final terrainLayer = map.layers.single as TerrainLayer;
      expect(visualPreset.terrainType, TerrainType.grass);
      expect(visualPreset.variants.single.frames.single.durationMs, isNull);
      expect(terrainLayer.terrains.where((cell) => cell == TerrainType.grass),
          hasLength(2));

      final zone = map.gameplayZones.single;
      expect(zone.kind, GameplayZoneKind.encounter);
      expect(zone.encounter, isNotNull);
      expect(zone.encounter!.encounterTableId, 'route_1_grass');
      expect(zone.encounter!.encounterKind, EncounterKind.walk);
      expect(zone.movement, isNull);
      expect(zone.movementEffect, isNull);
      expect(zone.hazard, isNull);

      final presetRoundTrip =
          ProjectTerrainPreset.fromJson(_jsonObject(visualPreset.toJson()));
      final mapRoundTrip = MapData.fromJson(_jsonObject(map.toJson()));
      final terrainRoundTrip = mapRoundTrip.layers.single as TerrainLayer;
      final zoneRoundTrip = mapRoundTrip.gameplayZones.single;

      expect(presetRoundTrip.terrainType, TerrainType.grass);
      expect(
        presetRoundTrip.variants.single.frames.single.durationMs,
        isNull,
      );
      expect(terrainRoundTrip.terrains, terrainLayer.terrains);
      expect(zoneRoundTrip.kind, GameplayZoneKind.encounter);
      expect(zoneRoundTrip.encounter!.encounterKind, EncounterKind.walk);
      expect(zoneRoundTrip.encounter!.encounterTableId, 'route_1_grass');
    });
  });
}

Map<String, dynamic> _jsonObject(Map<String, dynamic> json) {
  return jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
}
