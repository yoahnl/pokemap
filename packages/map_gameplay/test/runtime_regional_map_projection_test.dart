import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('one town remains current across its pension village and station maps',
      () {
    final catalog = ProjectRegionalMapCatalog(regions: [
      ProjectRegionDefinition(id: 'r', label: 'Region')
    ], pointsOfInterest: [
      ProjectRegionPointOfInterest(
          id: 'town',
          regionId: 'r',
          label: 'Hanazuki',
          u: 0.5,
          v: 0.5,
          mapIds: const ['pension', 'village', 'station'])
    ]);
    for (final mapId in ['pension', 'village', 'station']) {
      final projected = projectRuntimeRegionalMap(
          catalog: catalog,
          gameState: GameState(saveId: 's', currentMapId: mapId),
          locale: 'fr');
      expect(projected.single.points.single.status,
          RuntimeMapLocationStatus.current);
    }
    final saved = GameState(
        saveId: 's',
        currentMapId: 'route',
        narrativeEventProgress:
            NarrativeEventProgress(visitedNarrativeMapIds: const ['pension']));
    expect(
        projectRuntimeRegionalMap(
                catalog: catalog, gameState: saved, locale: 'fr')
            .single
            .points
            .single
            .status,
        RuntimeMapLocationStatus.discovered);
  });
  test('one projection excludes hidden places and masks all unknown details',
      () {
    final result = projectRuntimeRegionalMap(
      catalog: ProjectRegionalMapCatalog(
        regions: [
          ProjectRegionDefinition(id: 'r', label: 'Region'),
          ProjectRegionDefinition(id: 'secret', label: 'Secret region')
        ],
        pointsOfInterest: [
          point('known', map: 'old'),
          point('current', map: 'here'),
          point('unknown'),
          point('hidden',
              visibility: ProjectRegionPointVisibility.hidden, map: 'here'),
          point('later',
              visibility: ProjectRegionPointVisibility.discoveredOnly),
          point('secret-place',
              region: 'secret',
              visibility: ProjectRegionPointVisibility.hidden),
        ],
      ),
      gameState: GameState(
          saveId: 'save',
          currentMapId: 'here',
          narrativeEventProgress:
              NarrativeEventProgress(visitedNarrativeMapIds: const ['old'])),
      locale: 'fr-FR',
    );
    expect(result, hasLength(1));
    expect(
        result.single.points.map((p) => p.id), ['current', 'known', 'unknown']);
    final current = result.single.points.first;
    expect(current.status, RuntimeMapLocationStatus.current);
    expect(current.u, 0.2);
    expect(current.displayName, 'Lieu connu');
    final unknown = result.single.points.last;
    expect(unknown.displayName, '???');
    expect(unknown.description, isNull);
    expect(unknown.thumbnailPath, isNull);
    expect(unknown.destination, isNull);
    expect(result.single.points[1].description, 'Description FR');
  });

  test('an authored empty catalog never fabricates current map POIs', () {
    expect(
        projectRuntimeRegionalMap(
            catalog: ProjectRegionalMapCatalog(regions: [
              ProjectRegionDefinition(id: 'empty', label: 'Empty')
            ]),
            gameState: const GameState(saveId: 's', currentMapId: 'here'),
            locale: 'fr'),
        isEmpty);
  });

  test('always discovered points do not require a map visit or a destination',
      () {
    final result = projectRuntimeRegionalMap(
        catalog: ProjectRegionalMapCatalog(regions: [
          ProjectRegionDefinition(id: 'r', label: 'Region')
        ], pointsOfInterest: [
          ProjectRegionPointOfInterest(
              id: 'p',
              regionId: 'r',
              label: 'Public',
              u: 0,
              v: 1,
              discovery: ProjectRegionPointDiscovery.always)
        ]),
        gameState: const GameState(saveId: 's', currentMapId: 'here'),
        locale: 'en');
    expect(result.single.imagePath, isNull);
    expect(result.single.points.single.status,
        RuntimeMapLocationStatus.discovered);
    expect(result.single.points.single.destination, isNull);
  });
}

ProjectRegionPointOfInterest point(String id,
        {String region = 'r',
        String map = 'unvisited',
        ProjectRegionPointVisibility visibility =
            ProjectRegionPointVisibility.always}) =>
    ProjectRegionPointOfInterest(
        id: id,
        regionId: region,
        label: 'Secret name',
        labels: const {'fr': 'Lieu connu'},
        u: 0.2,
        v: 0.8,
        mapIds: [map],
        visibility: visibility,
        description: 'Secret detail',
        descriptions: const {'fr': 'Description FR'},
        thumbnailPath: 'assets/secret.png',
        destination: ProjectRegionDestination(mapId: map));
