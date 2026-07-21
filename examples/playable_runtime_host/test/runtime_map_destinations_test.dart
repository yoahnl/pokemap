import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/runtime_map_destinations.dart';

void main() {
  test('projects deterministic current, known and locked destinations', () {
    final destinations = resolveRuntimeMapDestinations(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'cave',
          name: 'Grotte',
          relativePath: 'maps/cave.json',
          sortOrder: 30,
        ),
        ProjectMapEntry(
          id: 'port',
          name: 'Port',
          relativePath: 'maps/port.json',
          sortOrder: 20,
        ),
        ProjectMapEntry(
          id: 'town',
          name: 'Bourg',
          relativePath: 'maps/town.json',
          sortOrder: 10,
        ),
      ],
      gameState: GameState(
        saveId: 'save',
        currentMapId: 'town',
        narrativeEventProgress: NarrativeEventProgress(
          visitedNarrativeMapIds: const ['port'],
        ),
      ),
    );

    expect(destinations.map((entry) => entry.mapId), ['town', 'port', 'cave']);
    expect(destinations[0].status, RuntimeMapDestinationStatus.current);
    expect(destinations[1].status, RuntimeMapDestinationStatus.known);
    expect(destinations[2].status, RuntimeMapDestinationStatus.locked);
    expect(destinations[2].displayName, '???');
  });

  test('normalizes duplicate and stale manifest entries defensively', () {
    final destinations = resolveRuntimeMapDestinations(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
        ProjectMapEntry(
          id: ' port ',
          name: 'Duplicate',
          relativePath: 'maps/duplicate.json',
        ),
        ProjectMapEntry(
          id: ' ',
          name: 'Invalid',
          relativePath: 'maps/invalid.json',
        ),
      ],
      gameState: const GameState(saveId: 'save', currentMapId: 'port'),
    );

    expect(destinations, hasLength(1));
    expect(destinations.single.displayName, 'Port');
    expect(destinations.single.status, RuntimeMapDestinationStatus.current);
  });
}
