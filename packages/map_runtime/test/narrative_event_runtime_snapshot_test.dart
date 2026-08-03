import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';

void main() {
  test('legacyOnly snapshot never loads the project map corpus', () async {
    var loadCalls = 0;
    final project = ProjectManifest(
      name: 'Legacy-only lightweight snapshot',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_a',
          name: 'Map A',
          relativePath: 'maps/map_a.json',
        ),
        ProjectMapEntry(
          id: 'map_b',
          name: 'Map B',
          relativePath: 'maps/map_b.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      ),
    );

    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: project,
      loadMap: (_) async {
        loadCalls++;
        throw StateError('legacyOnly must not load maps');
      },
    );

    expect(loadCalls, 0);
    expect(snapshot.mapsById, isEmpty);
    expect(snapshot.registryResult.registryOrNull?.mode,
        EventSystemMode.legacyOnly);
  });
}
