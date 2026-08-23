import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('triggers a native Smart Tile encounter without gameplay zones', () {
    final map = _map();
    final project = _project();
    final world = GameplayWorldState.initial(
      map: map,
      playerPos: const GridPos(x: 1, y: 0),
      project: project,
    );

    final result = checkEncounterAtPlayerPosition(
      world: world,
      project: project,
      encounterKind: EncounterKind.walk,
      policy: const GameplayEncounterPolicy(chancePerStep: 1),
      random: Random(1),
    );

    expect(result.status, GameplayEncounterCheckStatus.triggered);
    expect(result.sourceId, 'smart_tile_layer:grass');
    expect(result.sourceKind, EncounterSourceKind.smartTileLayer);
    expect(result.encounter?.sourceId, 'smart_tile_layer:grass');
    expect(result.encounter?.sourceKind, EncounterSourceKind.smartTileLayer);
    expect(result.encounter?.tableId, 'route_grass');
    expect(result.encounter?.speciesId, 'pidgey');
    expect(result.encounter?.toJson(), isNot(contains('zoneId')));
    expect(map.gameplayZones, isEmpty);
  });

  test('painting and erasing change encounter coverage without sync', () {
    final map = _map();
    final layer = map.layers.single as SmartTileLayer;
    final project = _project();
    final painted = map.copyWith(
      layers: <MapLayer>[
        layer.copyWith(
          field: const SmartTileField.cell(
            semanticCells: <int>[1, 1, 0],
          ),
        ),
      ],
    );
    final erased = map.copyWith(
      layers: <MapLayer>[
        layer.copyWith(
          field: const SmartTileField.cell(
            semanticCells: <int>[0, 0, 0],
          ),
        ),
      ],
    );

    GameplayEncounterCheckResult check(MapData candidate) {
      return checkEncounterAtPlayerPosition(
        world: GameplayWorldState.initial(
          map: candidate,
          playerPos: const GridPos(x: 0, y: 0),
          project: project,
        ),
        project: project,
        encounterKind: EncounterKind.walk,
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
        random: Random(1),
      );
    }

    expect(check(map).status, GameplayEncounterCheckStatus.noSource);
    expect(check(painted).status, GameplayEncounterCheckStatus.triggered);
    expect(check(erased).status, GameplayEncounterCheckStatus.noSource);
  });

  test('encounter JSON requires an explicit source kind', () {
    expect(
      () => GameplayEncounter.fromJson(<String, dynamic>{
        'mapId': 'route',
        'sourceId': 'grass',
      }),
      throwsFormatException,
    );
  });
}

MapData _map() {
  return const MapData(
    id: 'route',
    name: 'Route',
    size: GridSize(width: 3, height: 1),
    layers: <MapLayer>[
      SmartTileLayer(
        id: 'grass',
        name: 'Tall grass',
        presetId: 'grass-preset',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'tall_grass'],
        field: SmartTileField.cell(semanticCells: <int>[0, 1, 0]),
        encounterBehavior: SmartTileEncounterBehavior(
          materialId: 'tall_grass',
          encounter: EncounterZonePayload(
            encounterTableId: 'route_grass',
            encounterKind: EncounterKind.walk,
          ),
        ),
      ),
    ],
  );
}

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'route_grass',
        name: 'Route grass',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'pidgey',
            minLevel: 3,
            maxLevel: 3,
          ),
        ],
      ),
    ],
  );
}
