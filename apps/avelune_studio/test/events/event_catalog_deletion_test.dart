import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

String _event(int index) =>
    'evt_019abcde-0000-7000-8000-${index.toRadixString(16).padLeft(12, '0')}';

final _free = _event(1);
final _ruled = _event(2);

NarrativeEventRecord _behaviour(String id, String name) =>
    NarrativeEventRecord.fromJson({
      'state': 'configured',
      'enabled': false,
      'definition': {
        'id': id,
        'name': name,
        'source': {'kind': 'mapEnter', 'mapId': 'bourg'},
        'conditions': <Object?>[],
        'sceneId': 'talk',
        'reusePolicy': 'oneShot',
        'priority': 0,
        'order': 0,
      },
    });

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

Future<({MapWorkspaceController maps, LocalEventAdapter port, ProjectSession session})>
_open({required bool prepared, bool openedByStudio = false}) async {
  final qa = Directory(
    '/Users/karim/Library/Caches/AveluneQA/histoire-a2/studio-deletion',
  );
  await qa.create(recursive: true);
  final root = await qa.createTemp('project-');
  addTearDown(() => root.delete(recursive: true));
  await WorkingProjectCatalog.create(
    store: await CatalogStorageStore.open(projectRoot: root.path),
    projectId: 'story-deletion',
    project: ProjectManifest(
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
      scenes: [_scene('talk')],
      worldRules: [
        WorldRuleDefinition(
          id: 'world_rule_portail',
          label: 'Portail fermé',
          source: WorldRuleSource.civilWeekday(
            weekday: CivilWeekday.friday,
            expectedValue: true,
          ),
          target: WorldRuleTarget(
            kind: WorldRuleTargetKind.narrativeEvent,
            mapId: '',
            eventId: _ruled,
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.eventDisabled,
          ),
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          _behaviour(_free, 'Arrivée'),
          _behaviour(_ruled, 'Portail'),
        ],
        legacyClaims: const [],
      ),
    ),
  );
  final file = File('${root.path}/maps/bourg.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode(
      MapData(
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
      ).toJson(),
    ),
  );
  if (prepared) await _prepare(root.path);
  final session = openedByStudio
      ? await LocalProjectSessionAdapter().open(root.path)
      : ProjectSession(
          sessionId: 'story-deletion',
          name: 'Bourg',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        );
  final adapter = LocalMapWorkspaceAdapter();
  final maps = MapWorkspaceController(session, adapter);
  addTearDown(maps.dispose);
  await maps.initialize();
  await maps.activate(maps.project!.maps.single);
  return (
    maps: maps,
    port: LocalEventAdapter(session: session, mapAdapter: adapter),
    session: session,
  );
}

Future<void> _prepare(String root) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [root],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final opened = await ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
    catalogMetadataFields: const {},
  ).openProject(root);
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
  await api.attachProject(
    projectRootPath: root,
    workspaceHandle: opened.workspaceHandle,
    projectHandle: opened.projectHandle,
  );
  try {
    await api.prepareWorkshopCatalog(
      opened.projectHandle,
      scope: 'narrativeEventConsumers',
    );
  } finally {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}

NarrativeEventRecord _record(MapWorkspaceController maps, String id) =>
    maps.project!.eventRegistry!.records.singleWhere(
      (record) => record.id == id,
    );

void main() {
  test('a project opened by the Studio deletes an unused behaviour', () async {
    final opened = await _open(prepared: false, openedByStudio: true);

    final receipt = await opened.port.publishEvent(
      id: _free,
      base: _record(opened.maps, _free),
      current: null,
    );

    expect(
      receipt.manifest.eventRegistry!.records.map((record) => record.id),
      [_ruled],
    );
  });

  test('an unused behaviour is deleted and stays gone after reopen', () async {
    final opened = await _open(prepared: true);

    final receipt = await opened.port.publishEvent(
      id: _free,
      base: _record(opened.maps, _free),
      current: null,
    );

    expect(
      receipt.manifest.eventRegistry!.records.map((record) => record.id),
      [_ruled],
    );
    final reopened = MapWorkspaceController(
      opened.session,
      LocalMapWorkspaceAdapter(),
    );
    addTearDown(reopened.dispose);
    await reopened.initialize();
    expect(
      reopened.project!.eventRegistry!.records.map((record) => record.id),
      [_ruled],
    );
  });

  test('a behaviour used by a world rule is refused with its user', () async {
    final opened = await _open(prepared: true);

    final refusal = await opened.port
        .publishEvent(
          id: _ruled,
          base: _record(opened.maps, _ruled),
          current: null,
        )
        .then<EventDeletionRefused?>(
          (_) => null,
          onError: (Object error) => error as EventDeletionRefused,
        );

    expect(refusal, isNotNull);
    expect(refusal!.coverageUnknown, isFalse);
    expect(refusal.users.map((user) => (user.kind, user.label)), [
      ('worldRule', 'Portail fermé'),
    ]);
    final parsed = EventDeletionRefused.parse(refusal.message)!;
    expect(parsed.users.single.label, 'Portail fermé');
    expect('$refusal', contains('Portail fermé'));
    expect(
      opened.maps.project!.eventRegistry!.records.map((record) => record.id),
      containsAll([_free, _ruled]),
    );
  });

  test(
    'an unprepared catalog refuses the deletion through the story binding',
    () async {
      final opened = await _open(prepared: false);
      final story = MapBuilderStoryBinding(
        maps: opened.maps,
        changed: () {},
        view: () => null,
        loadMedia: opened.port.loadPresentationMediaCatalog,
      );
      await story.prepare();
      expect(story.error, isNull);

      expect(story.deleteBehaviour(_record(opened.maps, _free)), isTrue);
      expect(await story.publish(opened.port), isFalse);

      final refusal = EventDeletionRefused.parse(story.error!);
      expect(refusal, isNotNull);
      expect(refusal!.coverageUnknown, isTrue);
      final reopened = MapWorkspaceController(
        opened.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(
        reopened.project!.eventRegistry!.records.map((record) => record.id),
        containsAll([_free, _ruled]),
      );
    },
  );
}
