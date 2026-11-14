import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

late MapWorkspaceController maps;
late MapBuilderStoryBinding story;

Future<void> open(
  WidgetTester tester,
  List<NarrativeEventRecord> records,
) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final port = WorkspaceMemoryPort(manifest: _project(records));
  port.saved['a'] = _map();
  maps = MapWorkspaceController(workspaceSession, port);
  addTearDown(maps.dispose);
  await maps.initialize();
  final view = MapEditingViewportSession();
  addTearDown(view.dispose);
  final tick = ValueNotifier(0);
  addTearDown(tick.dispose);
  story = MapBuilderStoryBinding(
    maps: maps,
    changed: () => tick.value++,
    view: () => view,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListenableBuilder(
          listenable: tick,
          builder: (context, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MapBuilderStoryPanel(
                outline: mapBuilderSpaceOutline(
                  MapBuilderSpace.story,
                  AppLocalizations.of(context),
                )!,
                binding: story,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder key(String value) => find.byKey(ValueKey(value));
Finder orphan(NarrativeEventRecord record) =>
    key('map-story-orphan-${record.id}');

NarrativeEventRecord? draft(NarrativeEventRecord record) => story.behaviours
    .registry(maps.project!)!
    .records
    .where((item) => item.id == record.id)
    .firstOrNull;

NarrativeEventRecord saved(NarrativeEventRecord record) => maps
    .project!
    .eventRegistry!
    .records
    .singleWhere((item) => item.id == record.id);

final _scene = SceneAsset(
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

NarrativeEventRecord _event(
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

final orphanMeeting = _event(
  1,
  'meeting',
  NarrativeEventSourceRef.entityInteract('a', 'luth'),
);

final orphanGhost = _event(
  2,
  'ghost',
  NarrativeEventSourceRef.entityInteract('a', 'gone'),
);

final orphanLostZone = _event(
  3,
  'lost zone',
  NarrativeEventSourceRef.triggerEnter('a', 'old-zone'),
);

final orphanElsewhere = _event(
  4,
  'elsewhere',
  NarrativeEventSourceRef.entityInteract('b', 'gone'),
);

ProjectManifest _project(List<NarrativeEventRecord> records) =>
    workspaceProject.copyWith(
      scenes: [_scene],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: records,
        legacyClaims: const [],
      ),
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
