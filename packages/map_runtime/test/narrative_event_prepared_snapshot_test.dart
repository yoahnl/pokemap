import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const maps = [
    MapData(id: 'field', name: 'Field', size: GridSize(width: 4, height: 4)),
    MapData(
      id: 'house',
      name: 'House',
      size: GridSize(width: 4, height: 4),
      entities: [
        MapEntity(
          id: 'keeper',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(),
        ),
      ],
    ),
  ];
  final project = ProjectManifest(
    name: 'Global prepared authority',
    maps: const [
      ProjectMapEntry(
        id: 'field',
        name: 'Field',
        relativePath: 'maps/field.json',
      ),
      ProjectMapEntry(
        id: 'house',
        name: 'House',
        relativePath: 'maps/house.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: const [],
      legacyClaims: const [],
    ),
  );

  test(
    'prepared global corpus matches full authority and never opens a map file',
    () async {
      final full = await NarrativeEventRuntimeSnapshot.build(
        project: project,
        loadMap: (id) async =>
            (project: project, map: maps.singleWhere((map) => map.id == id)),
      );
      final prepared = await NarrativeEventRuntimeSnapshot.build(
        project: project,
        preparedMaps: maps.map(NarrativeMapProjection.fromMapData).toList(),
        loadMap: (_) async =>
            throw StateError('Prepared maps must not load render data.'),
      );
      expect(
        prepared.projectCatalog.toDebugJson(),
        full.projectCatalog.toDebugJson(),
      );
      expect(
        prepared.projectCatalog
            .resolveMapEventInstanceOwner('house', 'keeper')
            .valueOrNull
            ?.id,
        'keeper',
      );
      expect(prepared.matchesProject(project), isTrue);
      expect(
        prepared.mapsById.values.every((map) => map is NarrativeMapProjection),
        isTrue,
      );
    },
  );

  test(
    'a partial index cannot silently remove a distant map from authority',
    () async {
      await expectLater(
        NarrativeEventRuntimeSnapshot.build(
          project: project,
          preparedMaps: [NarrativeMapProjection.fromMapData(maps.first)],
          loadMap: (_) async =>
              throw StateError('No fallback during index validation.'),
        ),
        throwsStateError,
      );
    },
  );

  test('duplicate prepared identities cannot hide a missing map', () async {
    await expectLater(
      NarrativeEventRuntimeSnapshot.build(
        project: project,
        preparedMaps: [
          NarrativeMapProjection.fromMapData(maps.first),
          NarrativeMapProjection.fromMapData(maps.first),
        ],
        loadMap: (_) async =>
            throw StateError('No fallback during index validation.'),
      ),
      throwsStateError,
    );
  });
}
