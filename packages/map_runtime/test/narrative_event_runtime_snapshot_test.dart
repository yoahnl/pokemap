import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';

void main() {
  const map =
      MapData(id: 'field', name: 'Field', size: GridSize(width: 4, height: 4));
  ProjectManifest projectWithCells(List<GridPos> cells) => ProjectManifest(
        name: 'Snapshot',
        maps: const [
          ProjectMapEntry(
              id: 'field', name: 'Field', relativePath: 'maps/field.json')
        ],
        tilesets: const [],
        elements: [
          ProjectElementEntry(
            id: 'bench',
            name: 'Bench',
            tilesetId: 'props',
            categoryId: 'props',
            frames: const [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1))
            ],
            collisionProfile: ElementCollisionProfile(
                source: ElementCollisionProfileSource.manual, cells: cells),
          )
        ],
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.dualRead,
            records: const [],
            legacyClaims: const []),
      );

  test('collision cell ordering does not change a narrative snapshot',
      () async {
    final project =
        projectWithCells(const [GridPos(x: 1, y: 0), GridPos(x: 0, y: 0)]);
    final loaded =
        projectWithCells(const [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)]);
    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: project,
      loadMap: (_) async => (project: loaded, map: map),
    );
    expect(snapshot.mapsById.keys, ['field']);
    expect(project.elements.single.collisionProfile!.cells.first.x, 1);
  });

  test('changed collision geometry is still rejected', () async {
    final project = projectWithCells(const [GridPos(x: 0, y: 0)]);
    final loaded = projectWithCells(const [GridPos(x: 1, y: 0)]);
    await expectLater(
        NarrativeEventRuntimeSnapshot.build(
          project: project,
          loadMap: (_) async => (project: loaded, map: map),
        ),
        throwsStateError);
  });

  test('other project changes are still rejected', () async {
    final project = projectWithCells(const [GridPos(x: 0, y: 0)]);
    await expectLater(
        NarrativeEventRuntimeSnapshot.build(
          project: project,
          loadMap: (_) async =>
              (project: project.copyWith(name: 'Changed'), map: map),
        ),
        throwsStateError);
  });

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
