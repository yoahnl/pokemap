import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

const memoryTalkEvent = 'evt_019abcde-0000-7000-8000-000000000001';

String _unrelatedEvent(int index) =>
    'evt_019abcde-0001-7000-8000-${index.toRadixString(16).padLeft(12, '0')}';

SceneEdge _edge(
  String id,
  String from,
  String port,
  String to,
  SceneEdgeKind kind,
) => SceneEdge(
  id: id,
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: kind,
);

SceneAsset _scene(String id, {String? read, String? written}) => SceneAsset(
  id: id,
  name: 'Scène $id',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      if (read != null)
        SceneNode(
          id: 'check',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: read,
              operator: SceneConditionOperator.isTrue,
              label: 'Test',
            ),
          ),
        ),
      if (written != null)
        SceneNode(
          id: 'open',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: written, value: true),
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: read == null || written == null
        ? [
            _edge(
              'flow',
              'start',
              'completed',
              'end',
              SceneEdgeKind.defaultFlow,
            ),
          ]
        : [
            _edge(
              'enter',
              'start',
              'completed',
              'check',
              SceneEdgeKind.defaultFlow,
            ),
            _edge('yes', 'check', 'true', 'open', SceneEdgeKind.conditionTrue),
            _edge('no', 'check', 'false', 'end', SceneEdgeKind.conditionFalse),
            _edge(
              'done',
              'open',
              'completed',
              'end',
              SceneEdgeKind.defaultFlow,
            ),
          ],
  ),
);

final memoryDoorRule = WorldRuleDefinition(
  id: 'world_rule_door',
  label: 'Porte du bourg',
  source: const WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: 'fact_met',
    predicate: WorldRuleSourcePredicate.isTrue,
  ),
  target: const WorldRuleTarget(
    kind: WorldRuleTargetKind.mapEntity,
    mapId: 'town',
    entityId: 'npc',
  ),
  effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
);

ProjectManifest _project(int unrelated, {bool character = false}) =>
    ProjectManifest(
      name: 'Mémoire',
      characters: [
        if (character)
          const ProjectCharacterEntry(
            id: 'leo',
            name: 'Léo',
            tilesetId: 'atlas',
            frameHeight: 1,
          ),
      ],
      maps: [
        const ProjectMapEntry(
          id: 'town',
          name: 'Bourg',
          relativePath: 'maps/town.json',
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
      facts: [
        NarrativeFactDefinition(id: 'fact_met', label: 'Rencontre'),
        NarrativeFactDefinition(id: 'fact_door', label: 'Porte ouverte'),
        NarrativeFactDefinition(
          id: 'fact_coins',
          label: 'Pièces',
          initialValue: NarrativeValue.integer(3),
        ),
        for (var i = 0; i < unrelated; i++)
          NarrativeFactDefinition(id: 'fact_unused_$i', label: 'Inutile $i'),
      ],
      scenes: [
        _scene('gate', read: 'fact_met', written: 'fact_door'),
        for (var i = 0; i < unrelated; i++) _scene('unused_scene_$i'),
      ],
      worldRules: [memoryDoorRule],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: memoryTalkEvent,
              name: 'Parler à Léo',
              source: NarrativeEventSourceRef.entityInteract('town', 'npc'),
              conditions: [NarrativeEventCondition.fact('fact_met', true)],
              priority: 0,
              order: 0,
            ),
          ),
          for (var i = 0; i < unrelated; i++)
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: _unrelatedEvent(i),
                name: 'Sans rapport $i',
                conditions: const [],
                priority: 0,
                order: i + 1,
              ),
            ),
        ],
        legacyClaims: const [],
      ),
    );

Future<ProjectSession> openGameMemoryCatalog({
  int unrelated = 0,
  bool prepared = true,
  bool catalog = true,
  bool character = false,
}) async {
  final temporary = await Directory.systemTemp.createTemp('game_memory_');
  final root = Directory(await temporary.resolveSymbolicLinks());
  addTearDown(() => root.delete(recursive: true));
  if (catalog) {
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'game-memory',
      project: _project(unrelated, character: character),
    );
  } else {
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(_project(unrelated, character: character).toJson()),
    );
  }
  final map = MapData(
    id: 'town',
    name: 'Bourg',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        palette: [
          const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0),
        ],
        cells: List.filled(64, 0),
      ),
    ],
    entities: const [
      MapEntity(
        id: 'npc',
        name: 'Léo',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 2),
        npc: MapEntityNpcData(displayName: 'Léo'),
      ),
    ],
  );
  final file = File('${root.path}/maps/town.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(map.toJson()));
  for (var i = 0; i < unrelated; i++) {
    await File('${root.path}/maps/unused-$i.json').writeAsString(
      jsonEncode(
        MapData(
          id: 'unused-map-$i',
          name: 'Inutile',
          size: const GridSize(width: 2, height: 2),
          layers: const [],
          entities: [
            if (character && i == 0)
              const MapEntity(
                id: 'passer',
                name: 'Passant',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 0, y: 0),
                npc: MapEntityNpcData(displayName: 'Léo', characterId: 'leo'),
              ),
          ],
        ).toJson(),
      ),
    );
  }
  if (!prepared) {
    return ProjectSession(
      sessionId: root.path,
      name: 'Mémoire',
      directoryPath: root.path,
      storage: catalog
          ? ProjectSessionStorage.workingCatalog
          : ProjectSessionStorage.manifest,
    );
  }
  final sessions = LocalProjectSessionAdapter();
  final session = await sessions.open(root.path);
  addTearDown(() => sessions.close(session));
  expect(session.storage, ProjectSessionStorage.workingCatalog);
  return session;
}
