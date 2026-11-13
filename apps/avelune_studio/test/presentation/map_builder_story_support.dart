import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line_draft.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../story_draft/story_fake_ports.dart';
import '../support/map_workspace_fixture.dart';

StoryPublicationGateway? storyEvents(
  MapBuilderStoryBinding story,
  EventPort? port,
) => port == null
    ? null
    : StoryPublicationGateway(
        draft: story.behaviours.draft,
        events: port,
        savedDialogues: story.behaviours.dialogues,
      );

typedef StoryFixture = ({
  MapWorkspaceController maps,
  MapBuilderStoryBinding story,
  StoryFakePorts ports,
  ValueNotifier<int> tick,
});

const storyLuth = MapEntity(
  id: 'luth',
  name: 'Luth',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 3, y: 2),
  npc: MapEntityNpcData(displayName: 'Luth'),
);

String storyEventId(int index) =>
    'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}';

NarrativeEventRecord storyRecord(
  int index, {
  String? sceneId,
  NarrativeEventSourceRef? source,
  NarrativeEventConditionExpression? expression,
  NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.oneShot,
  NarrativeEventResetPolicy reset = const NarrativeEventResetPolicy.never(),
  int priority = 0,
  int order = 0,
  bool enabled = true,
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: storyEventId(index),
    name: 'Cas $index',
    source: source ?? NarrativeEventSourceRef.entityInteract('a', 'luth'),
    conditions: expression?.leaves ?? const [],
    conditionExpression: expression,
    sceneId: sceneId ?? 'scene-plain',
    reusePolicy: reuse,
    resetPolicy: reset,
    priority: priority,
    order: order,
  ),
  enabled: enabled,
);

SceneAsset storyPlainScene(String id) => SceneAsset(
  id: id,
  name: 'Scène $id',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
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

SceneAsset storyLineScene(String id, String dialogueId) => behaviourLineScene(
  sceneId: id,
  name: 'Réplique $id',
  dialogueId: dialogueId,
);

DialogueSourceSnapshot storyLineDialogue(String id, List<String> lines) {
  final written = writeBehaviourLineDialogue(
    entry: ProjectDialogueEntry(
      id: id,
      name: id,
      relativePath: 'dialogues/$id.yarn',
      defaultStartNode: behaviourLineNodeTitle,
    ),
    lines: lines,
  ) as BehaviourLineAccepted<NarrativeDialogueSource>;
  return DialogueSourceSnapshot(
    entry: written.value.entry,
    source: written.value.source,
    revision: 'disk-$id',
  );
}

Future<StoryFixture> openStory({
  List<NarrativeEventRecord> records = const [],
  List<SceneAsset> scenes = const [],
  List<DialogueSourceSnapshot> dialogues = const [],
  List<NarrativeFactDefinition> facts = const [],
  List<WorldRuleDefinition> rules = const [],
  List<MapEntity> entities = const [storyLuth],
}) async {
  final memory = WorkspaceMemoryPort(
    manifest: workspaceProject.copyWith(
      scenes: [storyPlainScene('scene-plain'), ...scenes],
      dialogues: [for (final dialogue in dialogues) dialogue.entry],
      facts: facts,
      worldRules: rules,
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const [],
      ),
    ),
  );
  memory.saved['a'] = workspaceMap('a').copyWith(entities: entities);
  final maps = MapWorkspaceController(workspaceSession, memory);
  addTearDown(maps.dispose);
  await maps.initialize();
  final view = MapEditingViewportSession();
  final tick = ValueNotifier(0);
  addTearDown(tick.dispose);
  final ports = StoryFakePorts(() => maps.project!);
  for (final dialogue in dialogues) {
    ports.sources[dialogue.entry.id] = dialogue;
  }
  final story = MapBuilderStoryBinding(
    maps: maps,
    changed: () => tick.value++,
    view: () => view,
    gateway: (draft, saved) => StoryPublicationGateway(
      draft: draft,
      events: ports,
      scenes: ports,
      dialogues: ports,
      facts: ports,
      savedDialogues: saved,
    ),
    loadDialogue: (id) async {
      final snapshot = await ports.load(id);
      return StoryDialogueSource(
        entry: snapshot.entry,
        source: snapshot.source,
        revision: snapshot.revision,
      );
    },
  );
  return (maps: maps, story: story, ports: ports, tick: tick);
}

MapStoryElement storyElement(
  StoryFixture fixture, [
  String key = 'entity:luth',
]) => fixture.story.elements!.byKey(key)!;

NarrativeEventRecord storyCurrent(StoryFixture fixture, String id) => fixture
    .story
    .behaviours
    .registry(fixture.maps.project!)!
    .records
    .singleWhere((record) => record.id == id);

Future<void> pumpStoryInspector(
  WidgetTester tester,
  StoryFixture fixture, [
  String key = 'entity:luth',
]) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  fixture.story.select(storyElement(fixture, key));
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListenableBuilder(
          listenable: fixture.tick,
          builder: (context, _) => SingleChildScrollView(
            child: MapBuilderStoryInspector(
              binding: fixture.story,
              element: fixture.story.selected!,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
