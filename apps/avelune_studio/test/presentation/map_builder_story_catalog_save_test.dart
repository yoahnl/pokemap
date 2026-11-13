import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';

String _event(int index, {int block = 0}) =>
    'evt_019abcde-000$block-7000-8000-${index.toRadixString(16).padLeft(12, '0')}';

final _eventId = _event(0);

SceneAsset _scene(String id) => SceneAsset(
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
_open({
  int guides = 1,
  int unrelated = 0,
  AuthoringTransactionFaultInjector? faultInjector,
}) async {
  final temporary = await Directory.systemTemp.createTemp('story_catalog_');
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
    scenes: [_scene('talk'), _scene('elsewhere')],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        for (var index = 0; index < guides; index++)
          NarrativeEventRecord.fromJson({
            'state': 'configured',
            'enabled': true,
            'definition': {
              'id': _event(index),
              'name': 'Parler au guide $index',
              'source': {
                'kind': 'entityInteract',
                'mapId': 'bourg',
                'entityId': 'guide-$index',
              },
              'conditions': <Object?>[],
              'sceneId': 'talk',
              'reusePolicy': 'oneShot',
              'priority': 0,
              'order': 0,
            },
          }),
        for (var index = 0; index < unrelated; index++)
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: _event(index, block: 1),
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
          npc: MapEntityNpcData(displayName: 'Guide $index'),
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
  final adapter = LocalMapWorkspaceAdapter();
  final maps = MapWorkspaceController(session, adapter);
  addTearDown(maps.dispose);
  await maps.initialize();
  await maps.activate(maps.project!.maps.single);
  final port = LocalEventAdapter(
    session: session,
    mapAdapter: adapter,
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

void main() {
  test(
    'a saved behaviour leaves nothing unsaved on a working catalog',
    () async {
      final opened = await _open();
      final story = opened.story;
      final maps = opened.maps;
      final record = maps.project!.eventRegistry!.records.single;

      expect(story.setAfter(record, BehaviourAfter.eachTime), isTrue);
      expect(story.dirty, isTrue);
      final saved = await story.publish(storyEvents(story, opened.port));
      expect(saved, isTrue, reason: story.error);

      expect(story.dirty, isFalse);
      expect(story.behaviours.changes(maps.project!), isEmpty);
      expect(
        maps
            .project!
            .eventRegistry!
            .records
            .single
            .definitionOrNull
            ?.reusePolicy,
        NarrativeEventReusePolicy.reusable,
      );
      expect(maps.project!.scenes.map((scene) => scene.id).toSet(), {
        'talk',
        'elsewhere',
      });

      final reopened = MapWorkspaceController(
        opened.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(
        reopened
            .project!
            .eventRegistry!
            .records
            .single
            .definitionOrNull
            ?.reusePolicy,
        NarrativeEventReusePolicy.reusable,
      );
    },
  );

  test(
    'saving a behaviour without a scene keeps the scenes in memory',
    () async {
      final opened = await _open();
      final maps = opened.maps;
      final before = maps.project!;
      expect(before.scenes, hasLength(2));
      final draft = NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: 'evt_019abcde-0000-7000-8000-0000000000a2',
          name: 'Brouillon',
          conditions: const [],
          priority: 0,
          order: 1,
        ),
      );

      final receipt = await opened.port.publishEvent(
        id: draft.id,
        base: null,
        current: draft,
      );
      maps.acceptResources(before, receipt.manifest);

      expect(maps.project!.scenes.map((scene) => scene.id).toSet(), {
        'talk',
        'elsewhere',
      });
      expect(
        maps.project!.eventRegistry!.records.map((record) => record.id),
        containsAll([_eventId, draft.id]),
      );
    },
  );

  test(
    'one save publishes every changed behaviour in one transaction',
    () async {
      for (final count in [1, 20]) {
        final operations = <String>{};
        final promoted = <String>[];
        final opened = await _open(
          guides: 20,
          unrelated: 400,
          faultInjector: (context) {
            operations.add(context.operationId);
            if (context.storageKey case final key?) promoted.add(key);
          },
        );
        final story = opened.story;
        final project = opened.maps.project!;
        final records = [
          for (final record in project.eventRegistry!.records)
            if (record.definitionOrNull != null) record,
        ].take(count);
        for (final record in records) {
          expect(story.setAfter(record, BehaviourAfter.eachTime), isTrue);
        }
        expect(story.behaviours.changes(project), hasLength(count));
        final saved = await story.publish(storyEvents(story, opened.port));
        expect(saved, isTrue, reason: story.error);

        expect(story.dirty, isFalse);
        expect(operations, hasLength(1), reason: '$count behaviours');
        expect(promoted.where((key) => key.startsWith('maps/')), isEmpty);
        expect(
          opened.maps.project!.eventRegistry!.records.where(
            (record) =>
                record.definitionOrNull?.reusePolicy ==
                NarrativeEventReusePolicy.reusable,
          ),
          hasLength(count),
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
