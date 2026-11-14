import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

const focusTownEvent = 'evt_019abcde-0003-7000-8000-000000000001';
const focusCaveEvent = 'evt_019abcde-0003-7000-8000-000000000002';

SceneEdge _edge(String id, String from, String port, String to) => SceneEdge(
  id: id,
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: switch (port) {
    'true' => SceneEdgeKind.conditionTrue,
    'false' => SceneEdgeKind.conditionFalse,
    _ => SceneEdgeKind.defaultFlow,
  },
);

final focusGate = SceneAsset(
  id: 'gate',
  name: 'Porte du bourg',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'hello',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_hello'),
      ),
      SceneNode(
        id: 'check',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_met',
            operator: SceneConditionOperator.isTrue,
            label: 'Rencontre',
          ),
        ),
      ),
      SceneNode(
        id: 'open',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'fact_door', value: true),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      _edge('e1', 'start', 'completed', 'hello'),
      _edge('e2', 'hello', 'completed', 'check'),
      _edge('e3', 'check', 'true', 'open'),
      _edge('e4', 'check', 'false', 'end'),
      _edge('e5', 'open', 'completed', 'end'),
    ],
  ),
);

NarrativeEventRecord _talk(String id, String map, String npc, int order) =>
    NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: id,
        name: 'Parler · $map',
        source: NarrativeEventSourceRef.entityInteract(map, npc),
        sceneId: 'gate',
        conditions: const [],
        priority: 0,
        order: order,
      ),
    );

MapData _map(String id, String name, List<MapEntity> entities) => MapData(
  id: id,
  name: name,
  size: const GridSize(width: 4, height: 4),
  layers: [
    MapLayer.tile(
      id: 'ground',
      name: 'Sol',
      palette: [
        const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0),
      ],
      cells: List.filled(16, 0),
    ),
  ],
  entities: entities,
);

MapEntity _npc(String id, String name) => MapEntity(
  id: id,
  name: name,
  kind: MapEntityKind.npc,
  pos: const GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(displayName: name),
);

Future<ProjectSession> openSceneFocusCatalog({int unrelated = 300}) async {
  final temporary = await Directory.systemTemp.createTemp('scene_focus_');
  final root = Directory(await temporary.resolveSymbolicLinks());
  addTearDown(() => root.delete(recursive: true));
  await WorkingProjectCatalog.create(
    store: await CatalogStorageStore.open(projectRoot: root.path),
    projectId: 'scene-focus',
    project: ProjectManifest(
      name: 'Scène',
      maps: [
        const ProjectMapEntry(
          id: 'town',
          name: 'Bourg',
          relativePath: 'maps/town.json',
        ),
        const ProjectMapEntry(
          id: 'cave',
          name: 'Grotte',
          relativePath: 'maps/cave.json',
        ),
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
            id: 'unused-map-$i',
            name: 'Inutile',
            relativePath: 'maps/unused-$i.json',
          ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'atlas',
          name: 'Atlas',
          relativePath: 'assets/atlas.png',
        ),
      ],
      dialogues: const [
        ProjectDialogueEntry(
          id: 'dialogue_hello',
          name: 'Bonjour',
          relativePath: 'dialogues/hello.yarn',
        ),
      ],
      facts: [
        NarrativeFactDefinition(id: 'fact_met', label: 'Rencontre'),
        NarrativeFactDefinition(id: 'fact_door', label: 'Porte ouverte'),
      ],
      scenes: [
        focusGate,
        for (var i = 0; i < unrelated; i++)
          SceneAsset(
            id: 'unused_scene_$i',
            name: 'Inutile $i',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [_edge('flow', 'start', 'completed', 'end')],
            ),
          ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          _talk(focusTownEvent, 'town', 'leo', 0),
          _talk(focusCaveEvent, 'cave', 'miner', 1),
        ],
        legacyClaims: const [],
      ),
    ),
  );
  final files = {
    'maps/town.json': jsonEncode(
      _map('town', 'Bourg', [_npc('leo', 'Léo')]).toJson(),
    ),
    'maps/cave.json': jsonEncode(
      _map('cave', 'Grotte', [_npc('miner', 'Mineur')]).toJson(),
    ),
    'dialogues/hello.yarn': 'title: Start\n---\nLéo: Bonjour !\n===\n',
    for (var i = 0; i < unrelated; i++)
      'maps/unused-$i.json': jsonEncode(
        _map('unused-map-$i', 'Inutile', const []).toJson(),
      ),
  };
  for (final entry in files.entries) {
    final file = File('${root.path}/${entry.key}');
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
  }
  final sessions = LocalProjectSessionAdapter();
  final session = await sessions.open(root.path);
  addTearDown(() => sessions.close(session));
  expect(session.storage, ProjectSessionStorage.workingCatalog);
  return session;
}
