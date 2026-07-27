import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('projects current, discovered and unknown maps without leaking names',
      () {
    final locations = projectRuntimeMapLocations(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'route',
          name: 'Route des Brumes',
          relativePath: 'maps/route.json',
          sortOrder: 20,
        ),
        ProjectMapEntry(
          id: 'town',
          name: 'Bourg Selbrume',
          relativePath: 'maps/town.json',
          sortOrder: 10,
        ),
        ProjectMapEntry(
          id: 'cave',
          name: 'Grotte du Phare',
          relativePath: 'maps/cave.json',
          sortOrder: 30,
        ),
      ],
      gameState: GameState(
        saveId: 'save-1',
        currentMapId: 'route',
        narrativeEventProgress: NarrativeEventProgress(
          visitedNarrativeMapIds: const <String>['town'],
        ),
      ),
    );

    expect(
      locations.map((location) => location.mapId),
      <String>['route', 'town', 'cave'],
    );
    expect(locations[0].status, RuntimeMapLocationStatus.current);
    expect(locations[1].status, RuntimeMapLocationStatus.discovered);
    expect(locations[2].status, RuntimeMapLocationStatus.unknown);
    expect(locations[2].displayName, '???');
  });

  test('keeps the current position visible when manifest data is stale', () {
    final locations = projectRuntimeMapLocations(
      maps: const <ProjectMapEntry>[],
      gameState: const GameState(
        saveId: 'save-1',
        currentMapId: 'missing-current-map',
      ),
    );

    expect(locations, hasLength(1));
    expect(locations.single.status, RuntimeMapLocationStatus.current);
    expect(locations.single.displayName, isEmpty);
  });
}
