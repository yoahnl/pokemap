import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

String catalogEventId(int index, {int block = 0}) =>
    'evt_019abcde-000$block-7000-8000-${index.toRadixString(16).padLeft(12, '0')}';

final catalogFirstEventId = catalogEventId(0);

SceneAsset catalogScene(String id) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'flow',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

Future<
  ({
    MapWorkspaceController maps,
    MapBuilderStoryBinding story,
    LocalEventAdapter port,
    ProjectSession session,
  })
>
openStoryCatalog({
  int guides = 1,
  int unrelated = 0,
  bool sameSource = false,
  bool withCharacters = false,
  LocalMapWorkspaceAdapter? adapter,
  AuthoringTransactionFaultInjector? faultInjector,
}) async {
  final qa = Directory(
    Platform.environment['AVELUNE_QA_ROOT'] ??
        '${Platform.environment['HOME']}/Library/Caches/AveluneQA/story-catalog-tests',
  );
  await qa.create(recursive: true);
  final temporary = await qa.createTemp('story_catalog_');
  final root = Directory(await temporary.resolveSymbolicLinks());
  addTearDown(() => root.delete(recursive: true));
  final project = ProjectManifest(
    name: 'Bourg',
    maps: const [
      ProjectMapEntry(
        id: 'bourg',
        name: 'Bourg',
        relativePath: 'maps/bourg.json',
      ),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'atlas',
        name: 'Atlas',
        relativePath: 'atlas.png',
      ),
    ],
    scenes: [catalogScene('talk'), catalogScene('elsewhere')],
    characters: withCharacters
        ? const [
            ProjectCharacterEntry(id: 'luth', name: 'Luth', tilesetId: 'atlas'),
            ProjectCharacterEntry(
              id: 'maman',
              name: 'Maman',
              tilesetId: 'atlas',
            ),
          ]
        : const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        for (var index = 0; index < guides; index++)
          NarrativeEventRecord.fromJson({
            'state': 'configured',
            'enabled': true,
            'definition': {
              'id': catalogEventId(index),
              'name': 'Parler au guide $index',
              'source': {
                'kind': 'entityInteract',
                'mapId': 'bourg',
                'entityId': 'guide-${sameSource ? 0 : index}',
              },
              'conditions': <Object?>[],
              'sceneId': 'talk',
              'reusePolicy': 'oneShot',
              'priority': 0,
              'order': sameSource ? index : 0,
            },
          }),
        for (var index = 0; index < unrelated; index++)
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: catalogEventId(index, block: 1),
              name: 'Sans rapport $index',
              conditions: const [],
              priority: 0,
              order: index,
            ),
          ),
      ],
      legacyClaims: const [],
    ),
  );
  await WorkingProjectCatalog.create(
    store: await CatalogStorageStore.open(projectRoot: root.path),
    projectId: 'story-catalog',
    project: project,
  );
  final map = MapData(
    id: 'bourg',
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
    entities: [
      for (var index = 0; index < guides; index++)
        MapEntity(
          id: 'guide-$index',
          name: 'Guide $index',
          kind: MapEntityKind.npc,
          pos: GridPos(x: index % 8, y: index ~/ 8),
          npc: MapEntityNpcData(
            displayName: 'Guide $index',
            characterId: withCharacters
                ? (index == 0 ? 'luth' : 'maman')
                : null,
          ),
        ),
    ],
  );
  final file = File('${root.path}/maps/bourg.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(map.toJson()));
  final session = ProjectSession(
    sessionId: 'story-catalog',
    name: project.name,
    directoryPath: root.path,
    storage: ProjectSessionStorage.workingCatalog,
  );
  final selectedAdapter = adapter ?? LocalMapWorkspaceAdapter();
  final maps = MapWorkspaceController(session, selectedAdapter);
  addTearDown(maps.dispose);
  await maps.initialize();
  await maps.activate(maps.project!.maps.single);
  final port = LocalEventAdapter(
    session: session,
    mapAdapter: selectedAdapter,
    faultInjector: faultInjector,
  );
  final story = MapBuilderStoryBinding(
    maps: maps,
    changed: () {},
    view: () => null,
    loadMedia: port.loadPresentationMediaCatalog,
  );
  await story.prepare();
  expect(story.error, isNull);
  return (maps: maps, story: story, port: port, session: session);
}
