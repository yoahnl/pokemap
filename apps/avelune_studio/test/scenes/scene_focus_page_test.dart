import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../presentation/story_memory_harness.dart';
import '../storyline/storyline_widget_support.dart';

SceneEdge _edge(String id, String from, String port, String to) => SceneEdge(
  id: id,
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: switch (port) {
    'true' => SceneEdgeKind.conditionTrue,
    'false' => SceneEdgeKind.conditionFalse,
    _ => SceneEdgeKind.defaultFlow,
  },
);

final _gate = SceneAsset(
  id: 'gate',
  name: 'Porte du bourg',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'check',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'met',
            operator: SceneConditionOperator.isFalse,
            label: 'Pas encore rencontré',
          ),
        ),
      ),
      SceneNode(
        id: 'meet',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'met', value: true),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      _edge('e1', 'start', 'completed', 'check'),
      _edge('e2', 'check', 'true', 'meet'),
      _edge('e3', 'check', 'false', 'end'),
      _edge('e4', 'meet', 'completed', 'end'),
    ],
  ),
);

final _records = [
  behaviour(
    1,
    'Parler au guide',
    source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
    enabled: true,
    sceneId: 'gate',
  ),
  behaviour(
    2,
    'Entrer dans la clairière',
    source: NarrativeEventSourceRef.mapEnter('a'),
    enabled: true,
    sceneId: 'gate',
  ),
];

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await settleMemory(tester);
  await tester.tap(_key(key));
  await settleMemory(tester);
}

void main() {
  testWidgets('a scene opens full screen from the whole game, previews a '
      'path and detaches a copy', (tester) async {
    final project = trameProject.copyWith(
      scenes: [_gate, trameScene('talk')],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: _records,
        legacyClaims: const [],
      ),
    );
    final index = memoryIndex()
      ..addFacts(trameProject.facts)
      ..titlesByKind[NarrativeTitleKind.events] = [
        for (final record in _records)
          NarrativeTitle(id: record.id, title: record.id),
      ]
      ..documents['gate'] = SceneDocument(
        scene: _gate,
        dialogues: const [],
        missingDialogueIds: const [],
        events: _records,
        maps: const {},
        mapReads: 0,
      );
    await openMemoryStudio(tester, index, project: project);
    await openWholeGame(tester);

    await _tap(tester, 'behaviour-scene-${behaviourId(1)}');

    expect(_key('scene-focus'), findsOneWidget);
    expect(index.documentRequests, ['gate']);
    expect(_key('scene-focus-steps-gate'), findsOneWidget);
    expect(_key('scene-focus-shared'), findsOneWidget);
    expect(_key('scene-focus-launcher-${behaviourId(1)}'), findsOneWidget);
    expect(_key('scene-focus-launcher-${behaviourId(2)}'), findsOneWidget);
    expect(_key('scene-focus-fact-met'), findsOneWidget);

    await _tap(tester, 'scene-focus-preview');
    expect(_key('scene-focus-path-check'), findsOneWidget);
    expect(_key('scene-focus-exit-true'), findsOneWidget);
    await _tap(tester, 'scene-focus-exit-true');
    expect(_key('scene-focus-path-meet'), findsOneWidget);
    expect(_key('scene-focus-path-end'), findsOneWidget);
    expect(_key('scene-focus-exit-true'), findsNothing);
    expect(
      tester.widget<Container>(_key('story-step-meet')).foregroundDecoration,
      isNull,
    );
    await _tap(tester, 'scene-focus-preview');

    await _tap(tester, 'scene-focus-detach');
    expect(_key('scene-focus-steps-gate'), findsNothing);
    expect(_key('scene-focus-shared'), findsNothing);
    expect(_key('scene-focus-launcher-${behaviourId(1)}'), findsOneWidget);
    expect(_key('scene-focus-launcher-${behaviourId(2)}'), findsNothing);
    expect(find.text('Porte du bourg (copie)'), findsOneWidget);
    expect(index.documentRequests, ['gate']);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleMemory(tester);
    expect(_key('scene-focus'), findsNothing);
  });

  testWidgets('the scene opens from a Trame milestone and from the Carte', (
    tester,
  ) async {
    final talk = trameScene('talk');
    final index = memoryIndex()
      ..documents['talk'] = SceneDocument(
        scene: talk,
        dialogues: const [],
        missingDialogueIds: const [],
        events: [trameRecords.first],
        maps: const {},
        mapReads: 0,
      );
    await openTrameStudio(tester, index: index);

    await _tap(tester, 'trame-milestone-meet');
    await _tap(tester, 'trame-scene-open-talk');
    expect(_key('scene-focus'), findsOneWidget);
    expect(_key('scene-focus-steps-talk'), findsOneWidget);
    expect(_key('scene-focus-shared'), findsNothing);
    await _tap(tester, 'scene-focus-close');
    expect(_key('scene-focus'), findsNothing);

    await tester.tap(find.text('Parler au guide'));
    await settleMemory(tester);
    expect(_key('map-story-inspector-entity:guide'), findsOneWidget);
    await _tap(tester, 'map-story-scene-open');
    expect(_key('scene-focus-steps-talk'), findsOneWidget);
    expect(index.documentRequests, ['talk', 'talk']);
  });
}
