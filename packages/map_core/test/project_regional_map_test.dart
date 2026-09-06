import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final spawnId in ['arrival-entity', 'arrival-key']) {
    test('map validation preserves the regional destination $spawnId', () {
      const spawn = MapEntity(
        id: 'arrival-entity',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        spawn: MapEntitySpawnData(spawnKey: 'arrival-key'),
      );
      const map = MapData(
        id: 'town',
        name: 'Town',
        version: ProjectVersion.v6,
        visualStack: MapVisualStackConfig.canonicalV1,
        size: GridSize(width: 3, height: 3),
        layers: [],
        entities: [spawn],
      );
      final project = ProjectManifest(
        name: 'Destination fixture',
        maps: const [
          ProjectMapEntry(
            id: 'town',
            name: 'Town',
            relativePath: 'maps/town.json',
          ),
        ],
        tilesets: const [],
        regionalMap: ProjectRegionalMapCatalog(
          regions: [ProjectRegionDefinition(id: 'west', label: 'West')],
          pointsOfInterest: [
            ProjectRegionPointOfInterest.fromJson({
              ...point().toJson(),
              'destination': {'mapId': 'town', 'spawnId': spawnId},
            }),
          ],
        ),
      );
      MapValidator.validate(map, projectDialogueContext: project);
      MapValidator.validate(
        map.copyWith(
          entities: [spawn.copyWith(pos: const GridPos(x: 1, y: 1))],
        ),
        projectDialogueContext: project,
      );
      MapValidator.validate(
        map.copyWith(
          entities: [
            spawnId == spawn.id
                ? spawn.copyWith(
                    spawn: const MapEntitySpawnData(spawnKey: 'other-key'),
                  )
                : spawn.copyWith(id: 'other-entity'),
          ],
        ),
        projectDialogueContext: project,
      );
      for (final entities in <List<MapEntity>>[
        [],
        [
          spawn.copyWith(
            id: 'renamed',
            spawn: const MapEntitySpawnData(spawnKey: 'renamed-key'),
          ),
        ],
        [spawn.copyWith(kind: MapEntityKind.custom, spawn: null)],
      ]) {
        expect(
          () => MapValidator.validate(
            map.copyWith(entities: entities),
            projectDialogueContext: project,
          ),
          throwsA(
            isA<ValidationException>()
                .having(
                  (error) => error.code,
                  'code',
                  'regional_map.destination_spawn_missing',
                )
                .having(
                  (error) => error.details['path'],
                  'path',
                  r'$.regionalMap.pointsOfInterest[town-poi].destination.spawnId',
                ),
          ),
        );
      }
    });
  }

  test('catalog round trips through the project without tile coordinates', () {
    final catalog = ProjectRegionalMapCatalog(
      regions: [ProjectRegionDefinition(id: 'west', label: 'West')],
      pointsOfInterest: [point()],
    );
    final project = ProjectManifest(
      name: 'Region fixture',
      maps: const [
        ProjectMapEntry(
          id: 'town',
          name: 'Town',
          relativePath: 'maps/town.json',
        ),
      ],
      tilesets: const [],
      regionalMap: catalog,
    );
    expect(
      ProjectManifest.fromJson(project.toJson()).regionalMap!.toJson(),
      catalog.toJson(),
    );
    expect(catalog.pointsOfInterest.single.labelFor('fr-FR'), 'Village');
    expect(
      catalog.pointsOfInterest.single.toJson(),
      isNot(contains('position')),
    );
  });

  test('rejects malformed coordinates, identities and unsupported schemas', () {
    for (final coordinate in [double.nan, double.infinity, -0.01, 1.01]) {
      expect(() => point(u: coordinate), throwsFormatException);
    }
    expect(
      () => ProjectRegionDefinition(id: ' ', label: 'West'),
      throwsFormatException,
    );
    expect(
      () => ProjectRegionDefinition(id: 'west', label: ''),
      throwsFormatException,
    );
    expect(
      () => ProjectRegionDefinition(
        id: 'west',
        label: 'West',
        imagePath: '../secret.png',
      ),
      throwsFormatException,
    );
    expect(
      () => ProjectRegionalMapCatalog.fromJson({
        'schemaVersion': 2,
        'regions': [],
        'pointsOfInterest': [],
      }),
      throwsFormatException,
    );
    expect(
      () => ProjectRegionalMapCatalog(
        regions: [
          ProjectRegionDefinition(id: 'west', label: 'West'),
          ProjectRegionDefinition(id: 'west', label: 'Other'),
        ],
      ),
      throwsFormatException,
    );
  });

  test('validates region and map references before runtime', () {
    final catalog = ProjectRegionalMapCatalog(pointsOfInterest: [point()]);
    final diagnostics = validateProjectRegionalMap(
      catalog: catalog,
      projectMapIds: const [],
    );
    expect(
      diagnostics.map((d) => d.code),
      containsAll([
        'regional_map.region_missing',
        'regional_map.discovery_map_missing',
      ]),
    );
    expect(
      () => ProjectRegionPointOfInterest(
        id: 'p',
        regionId: 'r',
        label: 'P',
        u: 0,
        v: 1,
      ),
      throwsFormatException,
    );
  });
  test(
    'map membership is explicit unique and has no singular legacy alias',
    () {
      final json = point().toJson();
      expect(
        () => ProjectRegionPointOfInterest.fromJson({
          ...json,
          'mapIds': ['town', 'town'],
        }),
        throwsFormatException,
      );
      expect(
        () => ProjectRegionPointOfInterest.fromJson({
          ...json,
          'discoveryMapId': 'town',
        }),
        throwsFormatException,
      );
      final catalog = ProjectRegionalMapCatalog(
        regions: [ProjectRegionDefinition(id: 'west', label: 'West')],
        pointsOfInterest: [
          ProjectRegionPointOfInterest.fromJson({
            ...json,
            'destination': {'mapId': 'town', 'spawnId': 'absent'},
          }),
        ],
      );
      expect(
        validateProjectRegionalMap(
          catalog: catalog,
          projectMapIds: const ['town'],
          maps: const [
            MapData(
              id: 'town',
              name: 'Town',
              size: GridSize(width: 2, height: 2),
              layers: [],
            ),
          ],
        ).single.code,
        'regional_map.destination_spawn_missing',
      );
    },
  );
}

ProjectRegionPointOfInterest point({double u = 0.25}) =>
    ProjectRegionPointOfInterest(
      id: 'town-poi',
      regionId: 'west',
      label: 'Town',
      labels: const {'fr': 'Village'},
      u: u,
      v: 0.75,
      mapIds: const ['town'],
    );
