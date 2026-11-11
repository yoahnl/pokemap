import 'package:avelune_studio/features/events/application/event_labels.dart';
import 'package:avelune_studio/features/events/application/event_source_targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  _kindsByDimension();

  test('changing source kind cannot reselect the old entity overlay', () {
    final picking = EventSourcePicking(
      map: _station,
      project: workspaceProject,
      source: NarrativeEventSourceRef.entityInteract('station', 'chief'),
      chooseKind: NarrativeEventSourceKind.triggerEnter,
      selectableSources: {
        NarrativeEventSourceRef.triggerEnter('station', 'platform'),
      },
    );

    expect(_sources(picking), [
      NarrativeEventSourceRef.triggerEnter('station', 'platform'),
    ]);
    expect(
      picking.accept(NarrativeEventSourceRef.entityInteract('station', 'chief')),
      isNull,
    );
    expect(
      picking.accept(NarrativeEventSourceRef.triggerEnter('station', 'platform')),
      NarrativeEventSourceRef.triggerEnter('station', 'platform'),
    );
  });

  test('context does not outline an entity homonym on another map', () {
    final elsewhere = EventSourcePicking(
      map: _station,
      project: workspaceProject,
      source: NarrativeEventSourceRef.entityInteract('other', 'chief'),
    );
    final here = EventSourcePicking(
      map: _station,
      project: workspaceProject,
      source: NarrativeEventSourceRef.entityInteract('station', 'chief'),
    );

    expect(elsewhere.flatTargets, isEmpty);
    expect(_sources(here), [
      NarrativeEventSourceRef.entityInteract('station', 'chief'),
    ]);
  });

  test('map source cannot be chosen when catalog marks it unavailable', () {
    final unavailable = EventSourcePicking(
      map: _station,
      project: workspaceProject,
      chooseKind: NarrativeEventSourceKind.mapEnter,
      selectableSources: const {},
    );
    final available = EventSourcePicking(
      map: _station,
      project: workspaceProject,
      chooseKind: NarrativeEventSourceKind.mapEnter,
    );

    expect(unavailable.accept(NarrativeEventSourceRef.mapEnter('station')), isNull);
    expect(unavailable.spatialCell(1, 1), isNull);
    expect(unavailable.flatTargets, isEmpty);
    expect(
      available.accept(NarrativeEventSourceRef.mapEnter('station')),
      NarrativeEventSourceRef.mapEnter('station'),
    );
    expect(
      available.spatialCell(1, 1),
      NarrativeEventSourceRef.mapEnter('station'),
    );
  });

  test('contact map refuses 3D and incompatible event zones', () {
    final threeD = workspaceProject.copyWith(
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
    );
    for (final (project, map) in [
      (threeD, workspaceMap('a').copyWith(triggers: [_zone])),
      (
        workspaceProject,
        workspaceMap(
          'a',
        ).copyWith(triggers: [_zone.copyWith(type: TriggerType.custom)]),
      ),
      (workspaceProject, workspaceMap('a').copyWith(triggers: [_zone, _zone])),
    ]) {
      final picking = EventSourcePicking(
        map: map,
        project: project,
        chooseKind: NarrativeEventSourceKind.triggerBump,
      );
      expect(picking.flatTargets, isEmpty);
    }
    expect(
      EventSourcePicking(
        map: workspaceMap('a').copyWith(triggers: [_zone]),
        project: threeD,
        chooseKind: NarrativeEventSourceKind.triggerBump,
      ).triggerContactNeedsFlatMap,
      isTrue,
    );
    final flat = EventSourcePicking(
      map: workspaceMap('a').copyWith(triggers: [_zone]),
      project: workspaceProject,
      chooseKind: NarrativeEventSourceKind.triggerBump,
    );
    expect(flat.triggerContactNeedsFlatMap, isFalse);
    expect(_sources(flat), [NarrativeEventSourceRef.triggerBump('a', 'chief')]);
  });

  test('trigger contact target emits its exact kind while interaction remains separate', () {
    final map = workspaceMap('a').copyWith(triggers: [_zone]);
    EventSourcePicking choosing(NarrativeEventSourceKind kind) =>
        EventSourcePicking(map: map, project: workspaceProject, chooseKind: kind);

    expect(_sources(choosing(NarrativeEventSourceKind.triggerBump)), [
      NarrativeEventSourceRef.triggerBump('a', 'chief'),
    ]);
    expect(_sources(choosing(NarrativeEventSourceKind.triggerEnter)), [
      NarrativeEventSourceRef.triggerEnter('a', 'chief'),
    ]);
    expect(
      choosing(
        NarrativeEventSourceKind.triggerEnter,
      ).accept(NarrativeEventSourceRef.triggerBump('a', 'chief')),
      isNull,
    );
  });

  test('automatic target emits its exact kind while interaction remains separate', () {
    final map = workspaceMap('a').copyWith(entities: [_logicalOwner]);
    EventSourcePicking choosing(NarrativeEventSourceKind kind) =>
        EventSourcePicking(map: map, project: workspaceProject, chooseKind: kind);

    expect(_sources(choosing(NarrativeEventSourceKind.entityAutorun)), [
      NarrativeEventSourceRef.entityAutorun('a', 'chief'),
    ]);
    expect(_sources(choosing(NarrativeEventSourceKind.entityInteract)), [
      NarrativeEventSourceRef.entityInteract('a', 'chief'),
    ]);
  });

  for (final invalid in [
    'missing',
    'duplicate',
    'entity-identity',
    'map-duplicate',
    'threeD',
  ]) {
    test('automatic picker refuses $invalid logical owner', () {
      final entities = switch (invalid) {
        'missing' => <MapEntity>[],
        'duplicate' => [_logicalOwner, _logicalOwner],
        'entity-identity' => [_logicalOwner.copyWith(id: ' chief ')],
        _ => [_logicalOwner],
      };
      final project = workspaceProject.copyWith(
        maps: invalid == 'map-duplicate'
            ? [workspaceEntries.first, workspaceEntries.first]
            : workspaceEntries,
        settings: ProjectSettings(
          dimension: invalid == 'threeD'
              ? ProjectDimension.threeD
              : ProjectDimension.twoD,
        ),
      );
      final picking = EventSourcePicking(
        map: workspaceMap('a').copyWith(entities: entities),
        project: project,
        chooseKind: NarrativeEventSourceKind.entityAutorun,
      );
      expect(picking.flatTargets, isEmpty);
    });
  }

  test('contact target emits its exact kind while interaction remains separate', () {
    final map = workspaceMap('a').copyWith(entities: [_npc]);
    EventSourcePicking choosing(NarrativeEventSourceKind kind) =>
        EventSourcePicking(map: map, project: _contactProject, chooseKind: kind);

    expect(_sources(choosing(NarrativeEventSourceKind.entityBump)), [
      NarrativeEventSourceRef.entityBump('a', 'chief'),
    ]);
    expect(_sources(choosing(NarrativeEventSourceKind.entityInteract)), [
      NarrativeEventSourceRef.entityInteract('a', 'chief'),
    ]);
  });

  for (final invalid in [
    'nonblocking',
    'sign',
    'ghost',
    'duplicate',
    'character-duplicate',
    'map-duplicate',
    'threeD',
  ]) {
    test('contact picker refuses $invalid native target', () {
      final entities = switch (invalid) {
        'nonblocking' => [_npc.copyWith(blocksMovement: false)],
        'sign' => [
          const MapEntity(
            id: 'chief',
            kind: MapEntityKind.sign,
            pos: GridPos(x: 3, y: 3),
          ),
        ],
        'ghost' => [
          const MapEntity(
            id: 'chief',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 3),
          ),
        ],
        'duplicate' => [_npc, _npc],
        _ => [_npc],
      };
      final project = _contactProject.copyWith(
        characters: invalid == 'character-duplicate'
            ? [_character, _character]
            : [_character],
        maps: invalid == 'map-duplicate'
            ? [workspaceEntries.first, workspaceEntries.first]
            : workspaceEntries,
        settings: ProjectSettings(
          dimension: invalid == 'threeD'
              ? ProjectDimension.threeD
              : ProjectDimension.twoD,
        ),
      );
      final picking = EventSourcePicking(
        map: workspaceMap('a').copyWith(entities: entities),
        project: project,
        chooseKind: NarrativeEventSourceKind.entityBump,
      );
      expect(picking.flatTargets, isEmpty);
    });
  }

  test('UI08 four real sources preserve exact targets per trigger kind', () {
    EventSourcePicking choosing(
      NarrativeEventSourceKind kind, {
      Set<NarrativeEventSourceRef>? selectable,
    }) => EventSourcePicking(
      map: _station,
      project: workspaceProject,
      source: NarrativeEventSourceRef.entityInteract('station', 'chief'),
      chooseKind: kind,
      selectableSources: selectable,
    );

    expect(_sources(choosing(NarrativeEventSourceKind.triggerEnter)), [
      NarrativeEventSourceRef.triggerEnter('station', 'platform'),
    ]);
    expect(
      _sources(
        choosing(
          NarrativeEventSourceKind.entityInteract,
          selectable: {
            NarrativeEventSourceRef.entityInteract('station', 'spawn'),
          },
        ),
      ),
      [NarrativeEventSourceRef.entityInteract('station', 'spawn')],
    );
    expect(choosing(NarrativeEventSourceKind.mapEnter).flatTargets, isEmpty);
    expect(
      choosing(NarrativeEventSourceKind.outcomeReceived).flatTargets,
      isEmpty,
    );
  });

  test('spatial cells resolve only the chosen kind inside its area', () {
    EventSourcePicking choosing(
      NarrativeEventSourceKind kind, {
      Set<NarrativeEventSourceRef>? selectable,
    }) => EventSourcePicking(
      map: _station,
      project: workspaceProject,
      chooseKind: kind,
      selectableSources: selectable,
    );

    expect(
      choosing(NarrativeEventSourceKind.entityInteract).spatialCell(3.5, 3.5),
      NarrativeEventSourceRef.entityInteract('station', 'chief'),
    );
    expect(
      choosing(NarrativeEventSourceKind.triggerEnter).spatialCell(4.5, 4.5),
      NarrativeEventSourceRef.triggerEnter('station', 'platform'),
    );
    expect(
      choosing(NarrativeEventSourceKind.triggerEnter).spatialCell(5, 5),
      isNull,
    );
    expect(
      choosing(NarrativeEventSourceKind.entityInteract).spatialCell(4.5, 4.5),
      isNull,
    );
    expect(
      choosing(
        NarrativeEventSourceKind.triggerEnter,
        selectable: const {},
      ).spatialCell(3.5, 3.5),
      isNull,
    );
    expect(
      choosing(NarrativeEventSourceKind.triggerBump).spatialCell(3.5, 3.5),
      isNull,
    );
  });

  test('3D models and actors are chosen only through selectable interactions', () {
    final map = workspaceMap('scene').copyWith(
      entities: [_npc],
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          SpatialModelInstance(
            id: 'door-1',
            modelId: 'door',
            position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
          ),
          SpatialModelInstance(
            id: 'door-2',
            modelId: 'missing',
            position: Model3dVector3(x: 1, y: 0, z: 1),
          ),
        ],
      ),
    );
    final project = workspaceProject.copyWith(models3d: [_door]);
    final models = EventSourcePicking(
      map: map,
      project: project,
      chooseKind: NarrativeEventSourceKind.modelInteract,
      selectableSources: {
        NarrativeEventSourceRef.modelInteract('scene', 'door-1'),
      },
    );

    expect(models.modelChoices, {'door-1': 'Porte NB2 · (2.5, 3.5)'});
    expect(
      models.modelHit('door-1'),
      NarrativeEventSourceRef.modelInteract('scene', 'door-1'),
    );
    expect(models.modelHit('door-2'), isNull);
    expect(models.actorHit('npc:chief'), isNull);
    expect(
      EventSourcePicking(map: map, project: project).modelChoices,
      {
        'door-1': 'Porte NB2 · (2.5, 3.5)',
        'door-2': 'Ressource absente · (1.0, 1.0)',
      },
    );

    final actors = EventSourcePicking(
      map: map,
      project: project,
      chooseKind: NarrativeEventSourceKind.entityInteract,
    );
    expect(
      actors.actorHit('npc:chief'),
      NarrativeEventSourceRef.entityInteract('scene', 'chief'),
    );
    expect(actors.actorHit('chief'), isNull);
    expect(actors.modelHit('door-1'), isNull);
  });
}

void _kindsByDimension() {
  test('guided Event source offers contact and automatic kinds only in 2D and 3D decor only in 3D', () {
    expect(eventSourceKindsFor(ProjectDimension.twoD), [
      NarrativeEventSourceKind.entityInteract,
      NarrativeEventSourceKind.entityBump,
      NarrativeEventSourceKind.entityAutorun,
      NarrativeEventSourceKind.triggerBump,
      NarrativeEventSourceKind.triggerEnter,
      NarrativeEventSourceKind.mapEnter,
      NarrativeEventSourceKind.outcomeReceived,
    ]);
    expect(eventSourceKindsFor(ProjectDimension.threeD), [
      NarrativeEventSourceKind.entityInteract,
      NarrativeEventSourceKind.modelInteract,
      NarrativeEventSourceKind.triggerEnter,
      NarrativeEventSourceKind.mapEnter,
      NarrativeEventSourceKind.outcomeReceived,
    ]);
  });
}

List<NarrativeEventSourceRef> _sources(EventSourcePicking picking) => [
  for (final target in picking.flatTargets) target.source,
];

const _station = MapData(
  id: 'station',
  name: 'Gare',
  size: GridSize(width: 8, height: 8),
  layers: [],
  triggers: [
    MapTrigger(
      id: 'platform',
      name: 'Quai',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 3, y: 3),
        size: GridSize(width: 2, height: 2),
      ),
    ),
  ],
  entities: [
    MapEntity(
      id: 'chief',
      name: 'Chef',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 3),
    ),
    MapEntity(
      id: 'spawn',
      name: 'Départ',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 1, y: 1),
    ),
  ],
);

const _zone = MapTrigger(
  id: 'chief',
  name: 'Sortie originale',
  type: TriggerType.event,
  area: MapRect(pos: GridPos(x: 3, y: 3), size: GridSize(width: 1, height: 1)),
);

const _logicalOwner = MapEntity(
  id: 'chief',
  name: 'Source invisible originale',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 3, y: 3),
  blocksMovement: false,
);

const _character = ProjectCharacterEntry(
  id: 'contact-character',
  name: 'Original contact actor',
  tilesetId: 'atlas',
);

const _npc = MapEntity(
  id: 'chief',
  name: 'Chef original',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 3, y: 3),
  npc: MapEntityNpcData(characterId: 'contact-character'),
);

final _contactProject = workspaceProject.copyWith(characters: [_character]);

final _door = ProjectModel3dEntry(
  id: 'door',
  name: 'Porte NB2',
  sourceAssetId: 'door-source',
  relativePath: 'assets/models3d/door.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 2, z: .2),
    ),
    meshCount: 1,
    triangleCount: 4,
  ),
);
