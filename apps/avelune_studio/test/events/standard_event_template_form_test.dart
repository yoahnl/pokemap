import 'dart:async';

import 'package:avelune_studio/features/events/application/standard_event_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

StandardEventEditingSession editing({
  StandardEventTemplateSpec? initial,
  Map<String, String> items = const {'key': 'Clé de démonstration'},
}) => StandardEventEditingSession(
  project: _project(),
  maps: [_map()],
  itemOptions: items,
  initial: initial ?? _spec(),
);

void main() {
  test(
    'busy or disposed template sessions never publish a second request',
    () async {
      final session = editing();
      addTearDown(session.dispose);
      final gate = Completer<bool>();
      var publications = 0;
      final first = session.save(
        publish: (_) {
          publications++;
          return gate.future;
        },
      );
      try {
        expect(session.busy, isTrue);
        expect(
          await session.save(
            publish: (_) async {
              publications++;
              return false;
            },
          ),
          isFalse,
        );
        expect(publications, 1);
      } finally {
        gate.complete(true);
        await first;
      }
      session.dispose();
      expect(
        await session.save(
          publish: (_) async {
            publications++;
            return true;
          },
        ),
        isFalse,
      );
      expect(publications, 1);
    },
  );
  test('guided map selection loads only the chosen map once', () async {
    final requested = <String>[];
    final session = StandardEventEditingSession(
      project: _project().copyWith(
        maps: [
          ..._project().maps,
          const ProjectMapEntry(
            id: 'second',
            name: 'Jardin',
            relativePath: 'maps/second.json',
          ),
          const ProjectMapEntry(
            id: 'unrelated',
            name: 'Autre',
            relativePath: 'maps/unrelated.json',
          ),
        ],
      ),
      maps: [_map()],
      itemOptions: const {},
      loadMapSource: (id) async {
        requested.add(id);
        return _map().copyWith(id: id);
      },
    );
    addTearDown(session.dispose);
    await session.initialize();
    expect(requested, isEmpty);
    await session.selectMap('second');
    expect(requested, ['second']);
    expect(session.selectedMap!.entities.map((entity) => entity.id), [
      'guide',
      'other',
    ]);
    await session.selectMap('room');
    await session.selectMap('second');
    expect(requested, ['second']);
    expect(session.entityId, isNull);
  });

  for (final items in [
    const <String, String>{},
    const {'key': 'Clé'},
  ]) {
    test(
      'unavailable item blocks guided publication catalogue=${items.length}',
      () async {
        final session = editing(
          items: items,
          initial: StandardEventTemplateSpec(
            kind: StandardEventTemplateKind.pickup,
            mapId: 'room',
            entityId: 'guide',
            name: 'Objet',
            parameters: const {
              'itemId': 'removed',
              'quantity': 1,
              'characterId': 'person',
            },
          ),
        );
        addTearDown(session.dispose);
        var publications = 0;
        expect(
          await session.save(
            publish: (_) async {
              publications++;
              return true;
            },
          ),
          isFalse,
        );
        expect(publications, 0);
        expect(session.error, contains('catalogue'));
        expect(session.parameters['itemId'], 'removed');
        expect(session.busy, isFalse);
      },
    );
  }

  for (final kind in StandardEventTemplateKind.values) {
    test('${kind.name} previews both states with selected resources', () {
      final initial = StandardEventTemplateSpec(
        kind: kind,
        mapId: 'room',
        entityId: 'guide',
        name: 'Événement de démonstration',
        parameters: switch (kind) {
          StandardEventTemplateKind.conditionalNpc => _spec().parameters,
          StandardEventTemplateKind.pickup => const {
            'itemId': 'key',
            'quantity': 1,
            'characterId': 'person',
          },
          StandardEventTemplateKind.lockedDoor => const {
            'itemId': 'key',
            'destinationMapId': 'room',
            'destinationWarpId': 'arrival',
            'dialogueId': 'hello',
          },
          StandardEventTemplateKind.trainer => const {
            'trainerId': 'trainer',
            'dialogueId': 'hello',
            'alternateDialogueId': 'after',
            'characterId': 'person',
          },
        },
      );
      final session = editing(initial: initial);
      addTearDown(session.dispose);
      final projection = session.projection;
      final before = projection.preview(
        project: session.project,
        gameState: session.simulation(projection),
      );
      session.simulated = true;
      final after = projection.preview(
        project: session.project,
        gameState: session.simulation(projection),
      );
      expect(before.label, isNotEmpty);
      expect(after.label, isNotEmpty);
      if (kind == StandardEventTemplateKind.lockedDoor ||
          kind == StandardEventTemplateKind.trainer) {
        expect(after.branch, isNot(before.branch));
        expect(after.actions, isNot(before.actions));
      } else {
        expect(after.label, isNot(before.label));
      }
      if (kind == StandardEventTemplateKind.pickup) {
        expect(after.visible, isFalse);
      }
      expect(session.project.eventRegistry!.records, isEmpty);
      expect(session.spec.parameters, initial.parameters);
    });
  }

  test(
    'advanced actions publish the current recipe before navigation',
    () async {
      final session = editing();
      addTearDown(session.dispose);
      final order = <String>[];
      final sceneId = session.projection.scenes.first.id;
      expect(
        await session.save(
          publish: (spec) async {
            expect(spec.entityId, 'guide');
            order.add('saved');
            return true;
          },
          advancedSceneId: sceneId,
          openAdvanced: (id) {
            expect(id, sceneId);
            order.add('advanced');
          },
        ),
        isTrue,
      );
      expect(order, ['saved', 'advanced']);
      expect(session.busy, isFalse);
    },
  );

  test('shared resource selection changes only the recipe', () async {
    final session = editing();
    addTearDown(session.dispose);
    session.parameters['alternateDialogueId'] = 'hello';
    final submitted = <StandardEventTemplateSpec>[];
    expect(
      await session.save(
        publish: (spec) async {
          submitted.add(spec);
          return false;
        },
      ),
      isFalse,
    );
    expect(submitted.single.parameters['alternateDialogueId'], 'hello');
    expect(submitted.single.entityId, 'guide');
    expect(session.project.dialogues.map((dialogue) => dialogue.id), [
      'hello',
      'after',
    ]);
    expect(session.parameters['factId'], 'met');
    expect(session.error, contains('refusé'));
  });

  test('reusing a recipe selects a new owner without altering the first', () {
    final original = _spec();
    final session = editing(initial: original);
    addTearDown(session.dispose);
    session.reuse();
    expect(session.entityId, isNull);
    session.selectEntity('other');
    expect(session.spec.entityId, 'other');
    expect(session.spec.parameters['factId'], 'met');
    expect(session.projection.events, isNotEmpty);
    expect(original.entityId, 'guide');
    expect(session.name, original.name);
  });

  test(
    'invalid references prevent publication and retain the authored input',
    () async {
      final session = editing(
        initial: StandardEventTemplateSpec(
          kind: StandardEventTemplateKind.conditionalNpc,
          mapId: 'room',
          entityId: 'guide',
          name: 'Guide après changement',
          parameters: {..._spec().parameters, 'factId': 'removed'},
        ),
      );
      addTearDown(session.dispose);
      var publications = 0;
      expect(
        await session.save(
          publish: (_) async {
            publications++;
            return true;
          },
        ),
        isFalse,
      );
      expect(publications, 0);
      expect(session.error, isNotEmpty);
      expect(session.parameters['factId'], 'removed');
      expect(session.busy, isFalse);
    },
  );

  test('a failed publication keeps local settings and prevents advanced navigation', () async {
    final session = editing();
    addTearDown(session.dispose);
    expect(
      await session.save(
        publish: (_) async => throw StateError('Conflit de révision'),
        advancedSceneId: session.projection.scenes.first.id,
        openAdvanced: (_) => fail('Rejected publication must never navigate'),
      ),
      isFalse,
    );
    expect(session.error, contains('Conflit de révision'));
    expect(session.parameters['factId'], 'met');
    expect(session.entityId, 'guide');
    expect(session.busy, isFalse);
  });
}

StandardEventTemplateSpec _spec() => StandardEventTemplateSpec(
  kind: StandardEventTemplateKind.conditionalNpc,
  mapId: 'room',
  entityId: 'guide',
  name: 'Guide après changement',
  parameters: const {
    'factId': 'met',
    'dialogueId': 'hello',
    'alternateDialogueId': 'after',
    'characterId': 'person',
  },
);

MapData _map() => MapData(
  id: 'room',
  name: 'Salle',
  size: const GridSize(width: 4, height: 4),
  layers: [TileLayer(id: 'ground', name: 'Sol', cells: List.filled(16, 0))],
  entities: const [
    MapEntity(
      id: 'guide',
      name: 'Guide',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
    ),
    MapEntity(
      id: 'other',
      name: 'Autre personnage',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 2),
    ),
  ],
  warps: const [
    MapWarp(
      id: 'arrival',
      pos: GridPos(x: 0, y: 0),
      targetMapId: 'room',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);

ProjectManifest _project() => ProjectManifest(
  name: 'Monde synthétique',
  tilesets: const [],
  maps: const [
    ProjectMapEntry(id: 'room', name: 'Salle', relativePath: 'maps/room.json'),
  ],
  characters: const [
    ProjectCharacterEntry(
      id: 'person',
      name: 'Personnage',
      tilesetId: 'people',
    ),
  ],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'hello',
      name: 'Bonjour',
      relativePath: 'dialogues/hello.yarn',
    ),
    ProjectDialogueEntry(
      id: 'after',
      name: 'Après la rencontre',
      relativePath: 'dialogues/after.yarn',
    ),
  ],
  facts: [NarrativeFactDefinition(id: 'met', label: 'Rencontre effectuée')],
  trainers: const [
    ProjectTrainerEntry(
      id: 'trainer',
      name: 'Dresseur de démonstration',
      trainerClass: 'Dresseur',
      team: [ProjectTrainerPokemonEntry(speciesId: 'sample', level: 5)],
    ),
  ],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [],
    legacyClaims: [],
  ),
);
