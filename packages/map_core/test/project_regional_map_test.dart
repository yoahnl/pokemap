import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  flyDestinationValidationTests();
  test(
    'regional values preserve equality and hashes across independent decoding',
    () {
      final region = ProjectRegionDefinition(
        id: 'west',
        label: 'West',
        labels: {'fr': 'Ouest', 'en': 'West'},
        imagePath: 'assets/west.png',
        sortOrder: 2,
      );
      final destination = ProjectRegionDestination(
        mapId: 'town',
        spawnId: 'arrival',
      );
      final poi = ProjectRegionPointOfInterest.fromJson({
        ...point().toJson(),
        'description': 'A town',
        'descriptions': {'fr': 'Un village', 'en': 'A town'},
        'thumbnailPath': 'assets/town.png',
        'destination': destination.toJson(),
        'sortOrder': 3,
      });
      final catalog = ProjectRegionalMapCatalog(
        regions: [region],
        pointsOfInterest: [poi],
      );
      final values = <Object, Object>{
        region: ProjectRegionDefinition.fromJson(region.toJson()),
        destination: ProjectRegionDestination.fromJson(destination.toJson()),
        poi: ProjectRegionPointOfInterest.fromJson(poi.toJson()),
        catalog: ProjectRegionalMapCatalog.fromJson(catalog.toJson()),
      };
      for (final entry in values.entries) {
        expect(entry.value, entry.key);
        expect(entry.value.hashCode, entry.key.hashCode);
        expect({entry.key, entry.value}, hasLength(1));
      }
      final project = ProjectManifest(
        name: 'Regional equality',
        maps: [],
        tilesets: [],
        regionalMap: catalog,
      );
      expect(ProjectManifest.fromJson(project.toJson()), project);
      final reordered = ProjectRegionDefinition.fromJson({
        ...region.toJson(),
        'labels': {'en': 'West', 'fr': 'Ouest'},
      });
      expect(reordered, region);
      expect(reordered.hashCode, region.hashCode);
      final reorderedPoi = ProjectRegionPointOfInterest.fromJson({
        ...poi.toJson(),
        'descriptions': {'en': 'A town', 'fr': 'Un village'},
      });
      expect(reorderedPoi, poi);
      expect(reorderedPoi.hashCode, poi.hashCode);
    },
  );

  test('regional definition equality distinguishes every authored field', () {
    final region = ProjectRegionDefinition(id: 'west', label: 'West');
    for (final change in <Map<String, dynamic>>[
      {'id': 'east'},
      {'label': 'East'},
      {
        'labels': {'fr': 'Ouest'},
      },
      {'imagePath': 'assets/region.png'},
      {'sampling': 'pixelArt'},
      {'sortOrder': 1},
    ]) {
      expect(
        ProjectRegionDefinition.fromJson({...region.toJson(), ...change}),
        isNot(region),
        reason: change.keys.single,
      );
    }
  });

  test(
    'regional point equality distinguishes every authored field and destination',
    () {
      final poi = ProjectRegionPointOfInterest.fromJson({
        ...point().toJson(),
        'description': 'A town',
        'descriptions': {'fr': 'Un village'},
      });
      for (final change in <Map<String, dynamic>>[
        {'id': 'other'},
        {'regionId': 'east'},
        {'label': 'Other'},
        {
          'labels': {'fr': 'Autre'},
        },
        {'u': 0.5},
        {'v': 0.5},
        {'visibility': 'hidden'},
        {'discovery': 'always'},
        {
          'mapIds': ['other'],
        },
        {'description': 'Description'},
        {
          'descriptions': {'fr': 'Description'},
        },
        {'thumbnailPath': 'assets/thumbnail.png'},
        {
          'destination': {'mapId': 'town', 'spawnId': 'arrival'},
        },
        {'sortOrder': 1},
      ]) {
        expect(
          ProjectRegionPointOfInterest.fromJson({...poi.toJson(), ...change}),
          isNot(poi),
          reason: change.keys.join(','),
        );
      }
      final destination = ProjectRegionDestination(
        mapId: 'town',
        spawnId: 'arrival',
      );
      expect(
        ProjectRegionDestination(mapId: 'other', spawnId: 'arrival'),
        isNot(destination),
      );
      expect(
        ProjectRegionDestination(mapId: 'town', spawnId: 'other'),
        isNot(destination),
      );
      expect(ProjectRegionDestination(mapId: 'town'), isNot(destination));
    },
  );

  test('regional catalog equality preserves ordered collections', () {
    final west = ProjectRegionDefinition(id: 'west', label: 'West');
    final east = ProjectRegionDefinition(id: 'east', label: 'East');
    final first = point();
    final second = ProjectRegionPointOfInterest.fromJson({
      ...first.toJson(),
      'id': 'second',
    });
    final catalog = ProjectRegionalMapCatalog(
      regions: [west, east],
      pointsOfInterest: [first, second],
    );
    expect(
      ProjectRegionalMapCatalog(
        regions: [east, west],
        pointsOfInterest: [first, second],
      ),
      isNot(catalog),
    );
    expect(
      ProjectRegionalMapCatalog(
        regions: [west, east],
        pointsOfInterest: [second, first],
      ),
      isNot(catalog),
    );
    expect(
      ProjectRegionalMapCatalog(
        regions: [west],
        pointsOfInterest: [first, second],
      ),
      isNot(catalog),
    );
    expect(
      ProjectRegionalMapCatalog(
        regions: [west, east],
        pointsOfInterest: [first],
      ),
      isNot(catalog),
    );
  });

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
        version: ProjectVersion.v8,
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


void flyDestinationValidationTests() {
  test('Fly destinations require a unique explicit native 2D spawn inside the map', () {
    const spawn = MapEntity(id: 'arrival', kind: MapEntityKind.spawn, pos: GridPos(x: 2, y: 2),
      spawn: MapEntitySpawnData(spawnKey: 'gate'));
    const map = MapData(id: 'town', name: 'Town', size: GridSize(width: 5, height: 5), entities: [spawn]);
    List<ProjectRegionalMapDiagnostic> validate(MapData target, String? spawnId) => validateProjectRegionalMap(
      catalog: ProjectRegionalMapCatalog(regions: [ProjectRegionDefinition(id: 'r', label: 'R')],
        pointsOfInterest: [ProjectRegionPointOfInterest(id: 'town', regionId: 'r', label: 'Town', u: .5, v: .5,
          mapIds: ['town'], destination: ProjectRegionDestination(mapId: 'town', spawnId: spawnId))]),
      projectMapIds: ['town'], maps: [target]);
    expect(validate(map, 'arrival'), isEmpty);
    expect(validate(map, 'gate'), isEmpty);
    expect(validate(map, null).single.code, 'regional_map.destination_spawn_missing');
    expect(validate(map.copyWith(entities: [spawn, spawn.copyWith(id: 'other', spawn: const MapEntitySpawnData(spawnKey: 'arrival'))]), 'arrival').single.code,
      'regional_map.destination_spawn_ambiguous');
    expect(validate(map.copyWith(entities: [spawn.copyWith(pos: const GridPos(x: 5, y: 2))]), 'arrival').single.code,
      'regional_map.destination_spawn_outside_map');
    expect(validate(map.copyWith(version: ProjectVersion.v9), 'arrival').single.code,
      'regional_map.destination_map_unsupported');
  });
}
