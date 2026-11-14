import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

late MapWorkspaceController maps;
late MapEditingViewportSession view;
late MapBuilderStoryBinding story;
late MapBuilderInputSession input;

Future<void> open(ProjectManifest project, MapData map) async {
  final port = WorkspaceMemoryPort(manifest: project);
  port.saved[map.id] = map;
  maps = MapWorkspaceController(workspaceSession, port);
  addTearDown(maps.dispose);
  await maps.initialize();
  view = MapEditingViewportSession();
  addTearDown(view.dispose);
  story = MapBuilderStoryBinding(maps: maps, changed: () {}, view: () => view);
  input = MapBuilderInputSession(
    controller: maps,
    view: () => view,
    story: story,
  );
  addTearDown(input.dispose);
}

Future<void> openVillage({List<NarrativeEventRecord> more = const []}) => open(
  workspaceProject.copyWith(
    scenes: [guardScene],
    eventRegistry: guardRegistry([_meeting, _greeting, ...more]),
  ),
  _map(),
);

void pressDelete({LogicalKeyboardKey key = LogicalKeyboardKey.delete}) =>
    mapEditingShortcuts(
          maps,
          view,
          (action) => action(),
          contextAt: input.contextAt,
        ).entries
        .firstWhere((entry) => entry.key.triggers?.contains(key) == true)
        .value();

void menuDelete(GridPos cell, MapContextFamily family) {
  input.open(cell);
  input.select(input.targets.singleWhere((item) => item.family == family));
  input.run(MapContextCommand.delete);
}

MapStoryElement element(String key) => story.elements!.byKey(key)!;

List<String> entityIds() => [
  for (final entity in maps.active!.current.entities) entity.id,
];

NarrativeEventRegistry guardRegistry(List<NarrativeEventRecord> records) =>
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: records,
      legacyClaims: const [],
    );

NarrativeEventRecord guardEvent(
  int index,
  String name,
  NarrativeEventSourceRef source,
) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}',
    name: name,
    source: source,
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: index,
  ),
  enabled: true,
);

final guardScene = SceneAsset(
  id: 'scene',
  name: 'Scène',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'start-end',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

final _meeting = guardEvent(
  1,
  'meeting',
  NarrativeEventSourceRef.entityInteract('a', 'luth'),
);

final _greeting = guardEvent(
  2,
  'greeting',
  NarrativeEventSourceRef.entityInteract('a', 'luth'),
);

final guardedEvent = guardEvent(
  3,
  'guarded',
  NarrativeEventSourceRef.entityInteract('a', 'start'),
);

MapData _map() => workspaceMap('a').copyWith(
  entities: const [
    MapEntity(
      id: 'luth',
      name: 'Luth',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 2),
      npc: MapEntityNpcData(displayName: 'Luth'),
    ),
    MapEntity(
      id: 'board',
      name: 'Panneau du village',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 8, y: 1),
      sign: MapEntitySignData(plainText: 'Bourg Geon'),
    ),
    MapEntity(
      id: 'start',
      name: 'Arrivée',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 12, y: 3),
      blocksMovement: false,
      spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
    ),
    MapEntity(
      id: 'other-start',
      name: 'Autre arrivée',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 14, y: 3),
      blocksMovement: false,
      spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
    ),
  ],
  triggers: const [
    MapTrigger(
      id: 'departure',
      name: 'Départ vers la route',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 1, y: 6),
        size: GridSize(width: 2, height: 2),
      ),
    ),
  ],
);
