import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_card_tile.dart';
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
    expect(_key('scene-focus-graph-gate'), findsOneWidget);
    for (final id in ['start', 'check', 'meet', 'end']) {
      expect(_key('scene-graph-card-$id'), findsOneWidget);
    }
    expect(_key('scene-graph-checks'), findsOneWidget);
    expect(_key('scene-focus-shared'), findsOneWidget);
    expect(_key('scene-focus-launcher-${behaviourId(1)}'), findsOneWidget);
    expect(_key('scene-focus-launcher-${behaviourId(2)}'), findsOneWidget);
    expect(_key('scene-focus-fact-met'), findsOneWidget);

    await tester.tapAt(tester.getCenter(_key('scene-graph-card-meet')));
    await settleMemory(tester);
    expect(_key('scene-graph-inspector-meet'), findsOneWidget);
    expect(_key('scene-graph-checks'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settleMemory(tester);
    expect(_key('scene-graph-card-meet'), findsNothing);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await settleMemory(tester);
    expect(_key('scene-graph-card-meet'), findsOneWidget);

    await _tap(tester, 'scene-focus-preview');
    expect(_key('scene-focus-path-check'), findsOneWidget);
    expect(_key('scene-focus-exit-true'), findsOneWidget);
    await _tap(tester, 'scene-focus-exit-true');
    expect(_key('scene-focus-path-meet'), findsOneWidget);
    expect(_key('scene-focus-path-end'), findsOneWidget);
    expect(_key('scene-focus-exit-true'), findsNothing);
    expect(
      tester.widget<SceneGraphCardTile>(_key('scene-graph-card-meet')).onPath,
      isTrue,
    );
    await _tap(tester, 'scene-focus-preview');

    await _tap(tester, 'scene-focus-detach');
    expect(_key('scene-focus-graph-gate'), findsNothing);
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
    await tester.scrollUntilVisible(
      _key('trame-scene-open-talk'),
      200,
      scrollable: find
          .descendant(
            of: _key('story-inspector'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await _tap(tester, 'trame-scene-open-talk');
    expect(_key('scene-focus'), findsOneWidget);
    expect(_key('scene-focus-graph-talk'), findsOneWidget);
    expect(_key('scene-focus-shared'), findsNothing);
    await _tap(tester, 'scene-focus-close');
    expect(_key('scene-focus'), findsNothing);

    await tester.tap(find.text('Parler au guide'));
    await settleMemory(tester);
    expect(_key('map-story-inspector-entity:guide'), findsOneWidget);
    await _tap(tester, 'map-story-scene-open');
    expect(_key('scene-focus-graph-talk'), findsOneWidget);
    expect(index.documentRequests, ['talk', 'talk']);
  });

  testWidgets('undo in a scene never reaches the edits of another scene', (
    tester,
  ) async {
    final talk = trameScene('talk');
    final records = [
      ..._records,
      behaviour(
        3,
        'Parler au facteur',
        source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
        enabled: true,
        sceneId: 'talk',
      ),
    ];
    final project = trameProject.copyWith(
      scenes: [_gate, talk],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const [],
      ),
    );
    SceneDocument document(
      SceneAsset scene,
      List<NarrativeEventRecord> events,
    ) => SceneDocument(
      scene: scene,
      dialogues: const [],
      missingDialogueIds: const [],
      events: events,
      maps: const {},
      mapReads: 0,
    );
    final index = memoryIndex()
      ..addFacts(trameProject.facts)
      ..titlesByKind[NarrativeTitleKind.events] = [
        for (final record in records)
          NarrativeTitle(id: record.id, title: record.id),
      ]
      ..documents['gate'] = document(_gate, _records)
      ..documents['talk'] = document(talk, [records.last]);
    await openMemoryStudio(tester, index, project: project);
    await openWholeGame(tester);
    Future<void> undo() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await settleMemory(tester);
    }

    await _tap(tester, 'behaviour-scene-${behaviourId(1)}');
    await tester.tapAt(tester.getCenter(_key('scene-graph-card-meet')));
    await settleMemory(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settleMemory(tester);
    expect(_key('scene-graph-card-meet'), findsNothing);
    await _tap(tester, 'scene-focus-close');

    await _tap(tester, 'behaviour-scene-${behaviourId(3)}');
    expect(_key('scene-focus-graph-talk'), findsOneWidget);
    await undo();
    await _tap(tester, 'scene-focus-close');

    await _tap(tester, 'behaviour-scene-${behaviourId(1)}');
    expect(_key('scene-graph-card-meet'), findsNothing);
    await undo();
    expect(_key('scene-graph-card-meet'), findsOneWidget);
  });
}
