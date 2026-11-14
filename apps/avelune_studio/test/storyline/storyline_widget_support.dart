import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../game_memory/game_memory_fakes.dart';
import '../presentation/story_memory_harness.dart';
import 'storyline_fakes.dart';

SceneAsset trameScene(String id) => SceneAsset(
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

final trameRecords = [
  behaviour(
    1,
    'Parler au guide',
    source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
    enabled: true,
    sceneId: 'talk',
  ),
  behaviour(
    2,
    'Ouvrir la grille',
    source: NarrativeEventSourceRef.mapEnter('a'),
    enabled: true,
    sceneId: 'gate',
  ),
];

final trameProject = memoryProject.copyWith(
  scenes: [trameScene('talk'), trameScene('gate')],
  facts: [memoryFact('met', 'Rencontrer Léo')],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: trameRecords,
    legacyClaims: const [],
  ),
);

FakeStorylineRead trameReads({bool empty = false}) => FakeStorylineRead(
  stories: empty ? [] : [mainStoryline()],
  scenes: trameProject.scenes,
  facts: trameProject.facts,
  proposed: empty
      ? mainStoryline().copyWith(id: 'proposed_main', title: 'Proposée')
      : null,
)..registry = trameProject.eventRegistry;

Future<FakeStorylineRead> openTrameStudio(
  WidgetTester tester, {
  bool empty = false,
}) async {
  final reads = trameReads(empty: empty);
  await openMemoryStudio(
    tester,
    memoryIndex()..addFacts(trameProject.facts),
    project: trameProject,
    storylines: reads,
  );
  await openTrame(tester);
  return reads;
}
