import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

late MapWorkspaceController maps;
late MapEditingViewportSession view;
late MapBuilderStoryBinding story;

Future<void> open(
  WidgetTester tester, {
  ProjectManifest? project,
  Future<ProjectMediaCatalog?> Function(ProjectManifest project)? loadMedia,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final port = WorkspaceMemoryPort(manifest: project ?? storyProject);
  port.saved['a'] = _map();
  maps = MapWorkspaceController(workspaceSession, port);
  addTearDown(maps.dispose);
  await maps.initialize();
  view = MapEditingViewportSession();
  final tick = ValueNotifier(0);
  addTearDown(tick.dispose);
  story = MapBuilderStoryBinding(
    maps: maps,
    changed: () => tick.value++,
    view: () => view,
    zoneName: () => 'Nouvelle zone',
    loadMedia: loadMedia,
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
              Expanded(
                child: SingleChildScrollView(
                  child: switch (story.selected) {
                    final element? => MapBuilderStoryInspector(
                      binding: story,
                      element: element,
                    ),
                    null => const Text('rien'),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

String subtitle(WidgetTester tester, String key) => tester
    .widget<StudioChoice>(find.byKey(ValueKey('map-story-element-$key')))
    .subtitle!;

var _events = 0;

SceneAsset _scene(String id) => SceneAsset(
  id: id,
  name: 'Scène $id',
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

NarrativeEventRecord storyEvent(
  String name,
  NarrativeEventSourceRef source, {
  NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.oneShot,
  NarrativeEventResetPolicy reset = const NarrativeEventResetPolicy.never(),
  int order = 0,
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-${(++_events).toString().padLeft(12, '0')}',
    name: name,
    source: source,
    conditions: const [],
    sceneId: 'scene-$name',
    reusePolicy: reuse,
    resetPolicy: reset,
    priority: 0,
    order: order,
  ),
  enabled: true,
);

final storyProject = workspaceProject.copyWith(
  scenes: [
    for (final id in [
      'meeting',
      'after-starter',
      'leaving',
      'arrival',
      'elsewhere',
      'greeting',
    ])
      _scene('scene-$id'),
  ],
  characters: const [
    ProjectCharacterEntry(id: 'rival', name: 'Silver', tilesetId: 'atlas'),
    ProjectCharacterEntry(
      id: 'elm',
      name: 'Professeur Orme',
      tilesetId: 'atlas',
    ),
  ],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: [
      storyEvent(
        'meeting',
        NarrativeEventSourceRef.entityInteract('a', 'luth'),
      ),
      storyEvent(
        'after-starter',
        NarrativeEventSourceRef.entityInteract('a', 'luth'),
        reuse: NarrativeEventReusePolicy.reusable,
        order: 1,
      ),
      storyEvent(
        'leaving',
        NarrativeEventSourceRef.triggerEnter('a', 'departure'),
        reset: const NarrativeEventResetPolicy.onMapReentry(),
      ),
      storyEvent('arrival', NarrativeEventSourceRef.mapEnter('a')),
      storyEvent('elsewhere', NarrativeEventSourceRef.mapEnter('b')),
    ],
    legacyClaims: [],
  ),
);

MapData _map() => workspaceMap('a').copyWith(
  entities: const [
    MapEntity(
      id: 'luth',
      name: 'Luth',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 2),
      npc: MapEntityNpcData(facing: EntityFacing.east, characterId: 'rival'),
    ),
    MapEntity(
      id: 'rival',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 6, y: 4),
      npc: MapEntityNpcData(displayName: 'Rival'),
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
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 2, height: 3),
      ),
    ),
    MapTrigger(
      id: 'camera',
      name: 'Caméra',
      type: TriggerType.camera,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
);
