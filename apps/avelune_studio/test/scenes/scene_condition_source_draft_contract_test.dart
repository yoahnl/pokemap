import 'dart:async';
import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_condition_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';

SceneConditionSource _inventory(String quantity, {bool expected = true}) =>
    SceneConditionSource(
      sourceKind: SceneConditionSourceKind.inventoryItem,
      sourceId: 'tonic',
      field: 'minimumQuantity',
      value: quantity,
      operator: expected
          ? SceneConditionOperator.isTrue
          : SceneConditionOperator.isFalse,
    );

ProjectManifest _project({
  String name = 'Guided conditions',
  List<BadgeDefinition>? badges,
  List<NarrativeFactDefinition>? facts,
}) => ProjectManifest(
  name: name,
  tilesets: [],
  maps: [
    const ProjectMapEntry(
      id: 'workshop',
      name: 'Atelier',
      relativePath: 'maps/workshop.json',
    ),
    const ProjectMapEntry(
      id: 'garden',
      name: 'Jardin',
      relativePath: 'maps/garden.json',
    ),
  ],
  badges:
      badges ?? [const BadgeDefinition(id: 'badge-a', label: 'Premier badge')],
  facts:
      facts ??
      [
        NarrativeFactDefinition(
          id: 'door-fact',
          label: 'Porte ouverte',
          legacyFlagName: 'DOOR_OPEN',
        ),
        NarrativeFactDefinition(id: 'gate-open', label: 'Passage ouvert'),
        NarrativeFactDefinition(
          id: 'count',
          label: 'Nombre',
          initialValue: NarrativeValue.integer(0),
        ),
      ],
);

MapData _map(String id, {List<MapEntity>? entities}) => MapData(
  id: id,
  name: id == 'workshop' ? 'Atelier' : 'Jardin',
  size: const GridSize(width: 6, height: 6),
  entities:
      entities ??
      [
        MapEntity(
          id: id == 'workshop' ? 'door' : 'guide',
          kind: MapEntityKind.sign,
          pos: const GridPos(x: 1, y: 1),
        ),
      ],
);

SceneAsset _scene(SceneConditionSource source) => SceneAsset(
  id: 'conditions',
  name: 'Conditions',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'check',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(conditionSource: source),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'check',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'yes',
        fromNodeId: 'check',
        fromPortId: 'true',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: 'no',
        fromNodeId: 'check',
        fromPortId: 'false',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionFalse,
      ),
    ],
  ),
);

SceneConditionSource _conditionSource(SceneAsset scene) =>
    (scene.graph.nodes.singleWhere((node) => node.id == 'check').payload
            as SceneConditionPayload)
        .conditionSource!;

Future<SceneConditionDraft> _ready({
  ProjectManifest? project,
  SceneConditionSource? source,
  Future<MapData> Function(String)? loadMap,
  Future<Map<String, String>> Function()? loadItems,
}) async {
  final ready = Completer<void>();
  late SceneConditionDraft draft;
  draft = SceneConditionDraft(
    project: project ?? _project(),
    current: SceneConditionPayload(conditionSource: source),
    loadMap: loadMap,
    loadItems: loadItems,
    changed: () {
      if (!draft.referencesLoading && !ready.isCompleted) ready.complete();
    },
  );
  if (!draft.referencesLoading) ready.complete();
  addTearDown(draft.dispose);
  await ready.future;
  return draft;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final entry in [
    (SceneConditionSourceKind.badge, 'badge-a', 'Premier badge'),
    (SceneConditionSourceKind.factLikeStoryFlag, 'DOOR_OPEN', 'Porte ouverte'),
    (SceneConditionSourceKind.factLikeStoryFlag, 'gate-open', 'Passage ouvert'),
  ]) {
    test(
      'native ${entry.$1.name} keeps its exact reference negation label and debug source',
      () async {
        final source = SceneConditionSource(
          sourceKind: entry.$1,
          sourceId: entry.$2,
          operator: SceneConditionOperator.isFalse,
          debugTechnicalLabel: 'existing-debug',
        );
        final draft = await _ready(source: source);
        expect(draft.references[entry.$2], entry.$3);
        expect(draft.expected, isFalse);
        for (final expected in [true, false]) {
          draft.expected = expected;
          final result = draft.prepared!;
          expect(result.sourceKind, entry.$1);
          expect(result.sourceId, entry.$2);
          expect(result.label, entry.$3);
          expect(
            result.operator,
            expected
                ? SceneConditionOperator.isTrue
                : SceneConditionOperator.isFalse,
          );
          expect(result.debugTechnicalLabel, 'existing-debug');
          expect(draft.current.conditionSource, same(source));
        }
      },
    );
  }

  test('missing malformed and ambiguous badges cannot replace their preserved source', () async {
    for (final badges in <List<BadgeDefinition>>[
      [],
      [
        const BadgeDefinition(id: 'badge-a', label: 'One'),
        const BadgeDefinition(id: 'badge-a', label: 'Two'),
      ],
      [const BadgeDefinition(id: ' badge-a', label: 'Invalid')],
      [const BadgeDefinition(id: 'badge-a', label: ' ')],
    ]) {
      final source = SceneConditionSource(
        sourceKind: SceneConditionSourceKind.badge,
        sourceId: 'badge-a',
        operator: SceneConditionOperator.isFalse,
      );
      final draft = await _ready(
        project: _project(badges: badges),
        source: source,
      );
      expect(draft.references, isNot(contains('badge-a')));
      expect(draft.prepared, isNull);
      expect(draft.current.conditionSource, same(source));
    }
  });

  test(
    'ambiguous flag aliases and duplicate identities remain unavailable',
    () async {
      for (final facts in <List<NarrativeFactDefinition>>[
        [],
        [
          NarrativeFactDefinition(
            id: 'one',
            label: 'One',
            legacyFlagName: 'DOOR_OPEN',
          ),
          NarrativeFactDefinition(
            id: 'two',
            label: 'Two',
            legacyFlagName: 'DOOR_OPEN',
          ),
        ],
        [
          NarrativeFactDefinition(
            id: 'one',
            label: 'One',
            legacyFlagName: 'DOOR_OPEN',
          ),
          NarrativeFactDefinition(id: 'DOOR_OPEN', label: 'Two'),
        ],
        [
          NarrativeFactDefinition(
            id: 'duplicate',
            label: 'One',
            legacyFlagName: 'DOOR_OPEN',
          ),
          NarrativeFactDefinition(
            id: 'duplicate',
            label: 'Two',
            legacyFlagName: 'OTHER',
          ),
        ],
      ]) {
        final source = SceneConditionSource(
          sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
          sourceId: 'DOOR_OPEN',
          operator: SceneConditionOperator.isFalse,
        );
        final draft = await _ready(
          project: _project(facts: facts),
          source: source,
        );
        expect(draft.references, isNot(contains('DOOR_OPEN')));
        expect(draft.prepared, isNull);
        expect(draft.current.conditionSource, same(source));
      }
    },
  );

  test(
    'inventory keeps exact thresholds and both expectations without coercion',
    () async {
      final source = _inventory('3', expected: false);
      final draft = await _ready(
        source: source,
        loadItems: () async => {'tonic': 'Potion'},
      );
      expect(draft.minimumQuantity, '3');
      for (final expected in [true, false]) {
        draft.expected = expected;
        expect(draft.prepared!.inventoryQuantityThreshold, 3);
        expect(
          draft.prepared!.operator,
          expected
              ? SceneConditionOperator.isTrue
              : SceneConditionOperator.isFalse,
        );
      }
      for (final invalid in ['', '0', '-1', '1.5', '01', ' 2 ']) {
        draft.minimumQuantity = invalid;
        expect(draft.prepared, isNull, reason: invalid);
        expect(draft.current.conditionSource, same(source));
      }
    },
  );

  test(
    'invalid missing or unavailable inventory labels retain the saved item',
    () async {
      for (final loader in <Future<Map<String, String>> Function()>[
        () async => {},
        () async => {'other': 'Autre'},
        () async => {'tonic': ' '},
        () async => throw StateError('Ambiguous'),
      ]) {
        final source = _inventory('3');
        final draft = await _ready(source: source, loadItems: loader);
        expect(draft.prepared, isNull);
        expect(draft.current.conditionSource, same(source));
      }
    },
  );

  test(
    'stale item loads cannot overwrite a new project family or disposed owner',
    () async {
      final old = Completer<Map<String, String>>();
      final current = SceneConditionPayload(conditionSource: _inventory('1'));
      final settled = Completer<void>();
      late SceneConditionDraft draft;
      draft = SceneConditionDraft(
        project: _project(),
        current: current,
        loadItems: () => old.future,
        changed: () {
          if (!draft.itemsLoading && !settled.isCompleted) settled.complete();
        },
      );
      addTearDown(draft.dispose);
      draft.configure(
        project: _project(name: 'New'),
        current: current,
        loadMoves: null,
        loadMap: null,
        loadItems: () async => {'tonic': 'Current'},
      );
      await settled.future;
      old.complete({'old': 'Stale'});
      await Future<void>.delayed(Duration.zero);
      expect(draft.itemOptions, {'tonic': 'Current'});
      final changed = Completer<Map<String, String>>();
      draft.configure(
        project: _project(name: 'Next'),
        current: current,
        loadMoves: null,
        loadMap: null,
        loadItems: () => changed.future,
      );
      draft.selectFamily('badge');
      changed.complete({'tonic': 'Stale family'});
      await Future<void>.delayed(Duration.zero);
      expect(draft.family, 'badge');
      expect(draft.itemOptions, isEmpty);
      final disposed = Completer<Map<String, String>>();
      final abandoned = SceneConditionDraft(
        project: _project(),
        current: current,
        loadItems: () => disposed.future,
        changed: () => fail('Disposed owner updated'),
      );
      abandoned.dispose();
      disposed.complete({'tonic': 'Late'});
      await Future<void>.delayed(Duration.zero);
      expect(abandoned.prepared, isNull);
    },
  );

  test('map anchor and local boolean retain exact owner map keys and explicit negation', () async {
    final source = SceneConditionSource.mapEventInstanceBoolean(
      mapId: 'workshop',
      eventId: 'door',
      key: 'A',
      expected: false,
      debugTechnicalLabel: 'existing-debug',
    );
    final draft = await _ready(source: source, loadMap: (id) async => _map(id));
    expect(draft.prepared!.debugTechnicalLabel, 'existing-debug');
    for (final invalid in ['', ' ', ' A ']) {
      draft.instanceKey = invalid;
      expect(draft.prepared, isNull);
    }
    draft.instanceKey = 'gate-open';
    draft.expected = true;
    final result = draft.prepared!;
    expect(result.mapId, 'workshop');
    expect(result.sourceId, 'door');
    expect(result.key, 'gate-open');
    expect(result.operator, SceneConditionOperator.isTrue);
    expect(result.debugTechnicalLabel, isNull);
    draft.selectedMapId = 'garden';
    draft.referenceId = 'guide';
    await draft.loadReferenceMap();
    expect(draft.prepared!.mapId, 'garden');
    expect(draft.prepared!.sourceId, 'guide');
    final anchor = await _ready(
      source: SceneConditionSource.playerAtEntityAnchor(
        mapId: 'workshop',
        entityId: 'door',
      ),
      loadMap: (id) async => _map(id),
    );
    anchor.expected = false;
    expect(anchor.prepared!.operator, SceneConditionOperator.isFalse);
    expect(anchor.prepared!.mapId, 'workshop');
    expect(anchor.prepared!.sourceId, 'door');
  });

  test('missing ambiguous out-of-bounds wrong-map and spatial owners are never substituted', () async {
    final entity = const MapEntity(
      id: 'door',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 1, y: 1),
    );
    for (final map in [
      _map('workshop', entities: []),
      _map('workshop', entities: [entity, entity]),
      _map(
        'workshop',
        entities: [entity.copyWith(pos: const GridPos(x: 9, y: 1))],
      ),
      _map('garden'),
      _map('workshop')
          .copyWith(spatialScene: MapSpatialScene(width: 6, depth: 6)),
    ]) {
      final source = SceneConditionSource.playerAtEntityAnchor(
        mapId: 'workshop',
        entityId: 'door',
      );
      final draft = await _ready(source: source, loadMap: (_) async => map);
      expect(draft.prepared, isNull);
      expect(draft.current.conditionSource, same(source));
    }
    for (final declarations in <List<ProjectMapEntry>>[
      [],
      [_project().maps.first, _project().maps.first],
    ]) {
      var reads = 0;
      final draft = await _ready(
        project: _project().copyWith(maps: declarations),
        source: SceneConditionSource.playerAtEntityAnchor(
          mapId: 'workshop',
          entityId: 'door',
        ),
        loadMap: (id) async {
          reads++;
          return _map(id);
        },
      );
      expect(draft.mapOptions, isNot(contains('workshop')));
      expect(draft.prepared, isNull);
      expect(reads, 0);
    }
  });

  for (final failure in [false, true]) {
    test(
      'a stale map success or failure cannot replace the selected owner failure=$failure',
      () async {
        final old = Completer<MapData>(), latest = Completer<MapData>();
        final draft = SceneConditionDraft(
          project: _project(),
          current: SceneConditionPayload(),
          changed: () {},
          loadMap: (id) => id == 'workshop' ? old.future : latest.future,
        );
        addTearDown(draft.dispose);
        draft.selectFamily('playerAtEntityAnchor');
        draft.selectedMapId = 'workshop';
        final previous = draft.loadReferenceMap();
        draft.selectedMapId = 'garden';
        final current = draft.loadReferenceMap();
        latest.complete(_map('garden'));
        await current;
        if (failure) {
          old.completeError(StateError('Stale map'));
        } else {
          old.complete(_map('workshop'));
        }
        await previous;
        expect(draft.stageMap!.id, 'garden');
        expect(draft.mapError, isNull);
        draft.selectReference('guide');
        expect(draft.prepared!.mapId, 'garden');
        expect(draft.prepared!.sourceId, 'guide');
      },
    );
  }

  test('malformed imported quantities are retained without rewriting their reference', () async {
    for (final quantity in ['0', '-1', '1.5', '01', ' 2 ']) {
      final source = _inventory(quantity);
      final draft = await _ready(
        source: source,
        loadItems: () async => {'tonic': 'Potion'},
      );
      expect(draft.prepared, isNull, reason: quantity);
      expect(draft.current.conditionSource, same(source));
    }
  });

  test('saved map conditions stay preserved and unavailable in 3D', () async {
    for (final source in [
      SceneConditionSource.playerAtEntityAnchor(
        mapId: 'workshop',
        entityId: 'door',
      ),
      SceneConditionSource.mapEventInstanceBoolean(
        mapId: 'workshop',
        eventId: 'door',
        key: 'A',
      ),
    ]) {
      final draft = await _ready(
        project: _project().copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        ),
        source: source,
        loadMap: (id) async => _map(id),
      );
      expect(draft.unsupported, isTrue);
      expect(draft.prepared, isNull);
      expect(draft.availableFamilies, contains('partyState'));
      expect(draft.current.conditionSource, same(source));
    }
  });

  for (final initial in [
    SceneConditionSource(
      sourceKind: SceneConditionSourceKind.badge,
      sourceId: 'badge-a',
      operator: SceneConditionOperator.isTrue,
    ),
    _inventory('1'),
    SceneConditionSource(
      sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
      sourceId: 'gate-open',
      operator: SceneConditionOperator.isTrue,
    ),
    SceneConditionSource.playerAtEntityAnchor(
      mapId: 'workshop',
      entityId: 'door',
    ),
    SceneConditionSource.mapEventInstanceBoolean(
      mapId: 'workshop',
      eventId: 'door',
      key: 'A',
    ),
  ]) {
    test(
      'native scene publishes ${initial.sourceKind.name} with undo redo cold reopen and protected bytes',
      () async {
        final original = SceneAsset(
          id: 'conditions',
          name: 'Conditions',
          description: 'Condition guidée persistée',
          tags: ['condition-qa'],
          graph: _scene(initial).graph,
          layout: SceneGraphLayout(
            nodeLayouts: [
              SceneNodeLayout(nodeId: 'start', x: 40, y: 80),
              SceneNodeLayout(nodeId: 'check', x: 320, y: 80),
              SceneNodeLayout(nodeId: 'end', x: 600, y: 80),
            ],
            edgeLayouts: [
              SceneEdgeLayout(
                edgeId: 'yes',
                controlPoints: [SceneLayoutPoint(x: 560, y: 40)],
              ),
            ],
          ),
          metadata: {'fixture': 'condition-source-forms'},
        );
        final fixture = await CinematicAdapterFixture.create();
        addTearDown(fixture.dispose);
        final project = _project(name: 'Condition host');
        await fixture.writeManifest(
          project.copyWith(
            scenes: [original],
            pokemon: project.pokemon.copyWith(
              catalogFiles: {
                ...project.pokemon.catalogFiles,
                'items': 'data/items.json',
              },
            ),
          ),
        );
        for (final entry in project.maps) {
          final file = fixture.file(entry.relativePath);
          await file.parent.create(recursive: true);
          await file.writeAsString(
            jsonEncode(
              _map(
                entry.id,
                entities: [
                  MapEntity(
                    id: 'door',
                    kind: MapEntityKind.sign,
                    pos: GridPos(x: entry.id == 'workshop' ? 1 : 2, y: 1),
                  ),
                ],
              ).toJson(),
            ),
          );
        }
        final items = fixture.file('data/items.json');
        await items.parent.create(recursive: true);
        await items.writeAsString(
          jsonEncode(
            encodeProjectItemCatalog(
              const ProjectItemCatalog(
                schemaVersion: 1,
                entries: [
                  ProjectItemDefinition(
                    id: 'tonic',
                    displayName: 'Potion',
                    pocketId: 'custom',
                  ),
                  ProjectItemDefinition(
                    id: 'ether',
                    displayName: 'Éther',
                    pocketId: 'custom',
                  ),
                ],
              ),
            ),
          ),
        );
        final baseline = await fixture.readManifest();
        final projectBytes = await fixture.file('project.json').readAsBytes();
        final protected = {
          for (final path in [
            ...baseline.maps.map((entry) => entry.relativePath),
            'data/items.json',
          ])
            path: await fixture.file(path).readAsBytes(),
        };
        final maps = MapWorkspaceController(fixture.session, fixture.maps);
        addTearDown(maps.dispose);
        await maps.initialize();
        final scenes = SceneWorkspaceController(
          maps,
          LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
          changed: () {},
        );
        addTearDown(scenes.dispose);
        expect(scenes.open(original.id), isTrue);
        final edit = scenes.active!;
        final pokemon = LocalPokemonWorkspaceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        );
        addTearDown(pokemon.dispose);
        final draft = await _ready(
          project: baseline,
          source: initial,
          loadMap: (id) async => (await fixture.maps.loadMap(
            fixture.session,
            baseline.maps.singleWhere((entry) => entry.id == id),
          )).map,
          loadItems: () async {
            final index = await pokemon.loadIndex();
            return {
              for (final item in index.itemCatalog!.entries)
                item.id: item.displayName,
            };
          },
        );
        switch (initial.sourceKind) {
          case SceneConditionSourceKind.badge:
            draft.selectReference('badge-a');
          case SceneConditionSourceKind.inventoryItem:
            expect(draft.itemOptions['ether'], 'Éther');
            draft.selectReference('ether');
            for (final invalid in ['0', '01']) {
              draft.minimumQuantity = invalid;
              expect(draft.prepared, isNull);
              expect(edit.dirty, isFalse);
            }
            draft.minimumQuantity = '3';
          case SceneConditionSourceKind.factLikeStoryFlag:
            expect(draft.references['DOOR_OPEN'], 'Porte ouverte');
            expect(draft.references, isNot(contains('door-fact')));
            draft.selectReference('DOOR_OPEN');
          case SceneConditionSourceKind.playerAtEntityAnchor:
          case SceneConditionSourceKind.mapEventInstanceBoolean:
            draft.selectedMapId = 'garden';
            await draft.loadReferenceMap();
            draft.selectReference('door');
            if (initial.sourceKind ==
                SceneConditionSourceKind.mapEventInstanceBoolean) {
              for (final invalid in ['', ' A ']) {
                draft.instanceKey = invalid;
                expect(draft.prepared, isNull);
                expect(edit.dirty, isFalse);
              }
              draft.instanceKey = 'gate-open';
            }
          default:
            fail('Unsupported fixture condition family');
        }
        draft.expected = false;
        expect(edit.current, original);
        expect(edit.dirty, isFalse);
        expect(await fixture.file('project.json').readAsBytes(), projectBytes);
        final source = draft.prepared!;
        expect(
          edit.mutate(
            (scene) => updateSceneConditionSource(
              scene,
              nodeId: 'check',
              source: source,
            ).updatedScene,
          ),
          isTrue,
        );
        expect(edit.undoCount, 1);
        final edited = edit.current;
        expect(await fixture.file('project.json').readAsBytes(), projectBytes);
        edit.restore(redo: false);
        expect(edit.current, original);
        edit.restore(redo: true);
        expect(edit.current, edited);
        expect(await scenes.saveAll(), isTrue, reason: scenes.error);
        expect(edit.error, isNull);
        expect(edit.dirty, isFalse);
        final cold = await LocalMapWorkspaceAdapter().loadProject(
          fixture.session,
        );
        final reopened = cold.scenes.single;
        expect(reopened, edited);
        expect(_conditionSource(reopened).toJson(), source.toJson());
        expect(reopened.metadata, original.metadata);
        expect(reopened.description, original.description);
        expect(reopened.tags, original.tags);
        expect(reopened.layout, original.layout);
        expect(reopened.graph.edges, original.graph.edges);
        expect(
          reopened.graph.nodes.where((node) => node.id != 'check'),
          original.graph.nodes.where((node) => node.id != 'check'),
        );
        expect(cold, baseline.copyWith(scenes: [edited]));
        for (final entry in protected.entries) {
          expect(
            await fixture.file(entry.key).readAsBytes(),
            entry.value,
            reason: entry.key,
          );
        }
        final restored = await _ready(
          project: cold,
          source: _conditionSource(reopened),
          loadMap: (id) async => (await fixture.maps.loadMap(
            fixture.session,
            cold.maps.singleWhere((entry) => entry.id == id),
          )).map,
          loadItems: () async => {'tonic': 'Potion', 'ether': 'Éther'},
        );
        expect(restored.prepared!.toJson(), source.toJson());
      },
    );
  }
}
