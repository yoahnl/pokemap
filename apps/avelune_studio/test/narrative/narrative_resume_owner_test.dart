import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_resume.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final stories = [
    for (final id in ['s1', 's2', 's3'])
      StorylineAsset(id: id, type: StorylineType.main, title: 'Histoire $id'),
  ];
  final scenes = [_scene('sc1'), _scene('sc2')];
  const dialogues = [
    ProjectDialogueEntry(id: 'd1', name: 'Accueil', relativePath: 'dialogues/d1.yarn'),
    ProjectDialogueEntry(id: 'd2', name: 'Adieu', relativePath: 'dialogues/d2.yarn'),
  ];
  final events = [_event('evt_00000000-0000-7000-8000-000000000001', 'Arrivée')];

  NarrativeOverview overview({bool dirtyInteraction = false}) => NarrativeOverview(
    stories: stories,
    facts: const [],
    interactions: [_interaction('i1', dirty: dirtyInteraction)],
    stepsById: const {},
    stepLinks: const {},
    factLinks: const {},
    dirtyCount: 0,
  );

  List<NarrativeResumeItem> items({
    NarrativeOverview? source,
    String? story,
    String? scene,
    String? dialogue,
    String? event,
    Set<String> dirtyStories = const {},
    Set<String> dirtyScenes = const {},
    Set<String> dirtyDialogues = const {},
    Set<String> dirtyEvents = const {},
  }) => narrativeResumeItems(
    overview: source ?? overview(),
    scenes: scenes,
    dialogues: dialogues,
    events: events,
    activeStoryId: story,
    activeSceneId: scene,
    activeDialogueId: dialogue,
    activeEventId: event,
    dirtyStoryIds: dirtyStories,
    dirtySceneIds: dirtyScenes,
    dirtyDialogueIds: dirtyDialogues,
    dirtyEventIds: dirtyEvents,
  );

  test('nothing is resumable when no document is open or modified', () {
    expect(items(), isEmpty);
    final split = splitNarrativeResume(items());
    expect(split.shown, isEmpty);
    expect(split.hidden, 0);
  });

  test('an open document and a modified one are both resumable with their own sentence', () {
    final resumed = items(story: 's1', dirtyStories: {'s2'}, dialogue: 'd1');
    expect(resumed.map((i) => (i.kind, i.id, i.subtitle)).toList(), [
      (NarrativeResumeKind.story, 's1', 'Histoire ouverte'),
      (NarrativeResumeKind.story, 's2', 'Histoire · brouillon'),
      (NarrativeResumeKind.dialogue, 'd1', 'Dialogue ouvert'),
    ]);
    expect(resumed.last.title, 'Accueil');
  });

  test('a modified document that is also the active one reads as a draft', () {
    final resumed = items(scene: 'sc1', dirtyScenes: {'sc1'});
    expect(resumed.single.subtitle, 'Scène · brouillon');
  });

  test('a dirty interaction is resumable without being active and events use their name', () {
    final resumed = items(
      source: overview(dirtyInteraction: true),
      event: 'evt_00000000-0000-7000-8000-000000000001',
    );
    expect(resumed.map((i) => i.kind), [
      NarrativeResumeKind.interaction,
      NarrativeResumeKind.event,
    ]);
    expect(resumed.first.subtitle, 'Interaction · brouillon');
    expect(resumed.last.title, 'Arrivée');
    expect(resumed.last.subtitle, 'Événement ouvert');
  });

  test('only five documents are shown and the rest is counted', () {
    final many = items(
      source: overview(dirtyInteraction: true),
      story: 's1',
      dirtyStories: {'s2', 's3'},
      dirtyScenes: {'sc1', 'sc2'},
      dirtyDialogues: {'d1'},
    );
    expect(many, hasLength(7));
    final split = splitNarrativeResume(many);
    expect(narrativeResumeVisibleLimit, 5);
    expect(split.shown, many.take(5).toList());
    expect(split.hidden, 2);
    final exact = splitNarrativeResume(many.take(5).toList());
    expect(exact.shown, hasLength(5));
    expect(exact.hidden, 0);
  });
}

NarrativeOverviewInteraction _interaction(String id, {required bool dirty}) =>
    NarrativeOverviewInteraction(
      id: id,
      name: 'Interaction $id',
      mapId: 'a',
      mapLabel: 'Gare',
      sourceLabel: 'Chef',
      whenText: 'Quand',
      dirty: dirty,
      advanced: false,
      conditions: const [],
      consequences: const [],
      references: const [],
      missingReferences: const [],
    );

NarrativeEventRecord _event(String id, String name) =>
    NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: id,
        name: name,
        source: NarrativeEventSourceRef.mapEnter('a'),
        conditions: const [],
        priority: 0,
        order: 0,
      ),
    );

SceneAsset _scene(String id) => SceneAsset(
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
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
