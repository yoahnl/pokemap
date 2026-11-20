import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_sidebar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../scenes/graph/scene_graph_canvas_harness.dart';
import '../scenes/scene_catalog_support.dart';
import '../scenes/steps/scene_step_fixtures.dart';
import 'story_memory_harness.dart';

final _scene = SceneAsset(
  id: 'gate',
  name: 'Ouverture de la porte',
  graph: graphOf(
    [
      startNode(),
      conditionNode('check'),
      waitNode('wait'),
      SceneNode(
        id: 'custom',
        kind: SceneNodeKind.action,
        title: 'Pause du guide',
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.wait(durationMs: 10),
        ),
      ),
      endNode('end'),
    ],
    [
      link('start', 'check'),
      link('check', 'wait', port: 'true'),
      link('wait', 'custom'),
      link('custom', 'end'),
    ],
  ),
);

void main() {
  testWidgets('Command-F finds an existing step after keyboard traversal', (
    tester,
  ) async {
    await _open(tester);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'scene-graph');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await settleMemory(tester);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      isNot('scene-graph'),
    );

    final search = find.descendant(
      of: graphKey('scene-graph-outline-search'),
      matching: find.byType(EditableText),
    );
    final searchFocus = tester.widget<EditableText>(search).focusNode;
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await settleMemory(tester);
    expect(searchFocus.hasPrimaryFocus, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await settleMemory(tester);
    expect(searchFocus.hasPrimaryFocus, isTrue);

    tester.testTextInput.enterText('pause du guide');
    await settleMemory(tester);
    expect(graphKey('scene-graph-outline-custom'), findsOneWidget);
    expect(graphKey('scene-graph-outline-check'), findsNothing);
    expect(_graph(tester), _scene.graph);
  });

  for (final fromPort in [false, true]) {
    testWidgets(
      'the sidebar inserts once with a ${fromPort ? 'port' : 'background'} menu open',
      (tester) async {
        await _open(tester);
        await _tap(tester, 'scene-graph-palette-tab');
        final canvas = tester.getRect(graphKey('scene-graph-canvas'));
        final empty = canvas.bottomRight - const Offset(40, 100);
        if (fromPort) {
          final row = tester.getRect(graphKey('scene-graph-port-check-false'));
          await dragGraph(tester, row.centerRight, empty);
        } else {
          await rightClickGraph(tester, empty);
        }
        expect(graphKey('scene-graph-step-menu'), findsOneWidget);

        final end = find.descendant(
          of: find.byType(SceneGraphSidebar),
          matching: graphKey('scene-graph-step-new-end'),
        );
        await tester.tap(end, kind: PointerDeviceKind.mouse);
        await settleMemory(tester);

        expect(graphKey('scene-graph-step-menu'), findsNothing);
        final graph = _graph(tester);
        expect(graph.nodes, hasLength(_scene.graph.nodes.length + 1));
        expect(graph.nodes.last.kind, SceneNodeKind.end);
        expect(graph.edges, _scene.graph.edges);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await settleMemory(tester);
        expect(_graph(tester), _scene.graph);
      },
    );
  }

  testWidgets('Conditions use the same icon and accent in all three views', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, 'scene-graph-outline-check');
    final card = _firstIcon(tester, 'scene-graph-card-check');
    final details = _firstIcon(tester, 'scene-graph-inspector-check');
    await _tap(tester, 'scene-graph-palette-tab');
    final palette = _firstIcon(tester, 'scene-graph-step-new-conditions');
    expect(card.icon, Icons.call_split);
    expect(card.color, isNotNull);
    expect((palette.icon, palette.color), (card.icon, card.color));
    expect((details.icon, details.color), (card.icon, card.color));
  });

  testWidgets('untitled actions and empty scene usage follow the UI language', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('fr'));
    addTearDown(locale.dispose);
    await _open(tester, locale: locale);
    expect(
      find.text('Aucun déclencheur ne lance cette scène.'),
      findsOneWidget,
    );
    _expectCardTitle('wait', 'Attendre');
    _expectCardTitle('custom', 'Pause du guide');

    locale.value = const Locale('en');
    await settleMemory(tester);
    expect(find.text('No trigger starts this scene.'), findsOneWidget);
    _expectCardTitle('wait', 'Wait');
    _expectCardTitle('custom', 'Pause du guide');
    expect(_graph(tester), _scene.graph);
  });

  testWidgets('the 1280 px workspace gives the graph and its cards room', (
    tester,
  ) async {
    await _open(tester, size: const Size(1280, 720));
    final canvas = find.byType(SceneGraphCanvas).first;
    final state = tester.state<SceneGraphCanvasState>(canvas);
    expect(
      tester.getSize(graphKey('scene-graph-canvas')).width,
      inInclusiveRange(760, 770),
    );
    final cardWidth = tester.getRect(graphKey('scene-graph-card-check')).width;
    expect(cardWidth / state.camera!.scale * .75, inInclusiveRange(188, 192));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _open(
  WidgetTester tester, {
  ValueNotifier<Locale>? locale,
  Size? size,
}) async {
  final index = memoryIndex()..documents[_scene.id] = catalogDocument(_scene);
  await openMemoryStudio(
    tester,
    index,
    project: memoryProject.copyWith(scenes: [_scene]),
    locale: locale,
  );
  if (size != null) {
    tester.view.physicalSize = size;
    await settleMemory(tester);
  }
  await openTrame(tester);
  await _tap(tester, 'story-section-scenes');
  await _tap(tester, 'story-scene-gate');
  await _tap(tester, 'story-scene-open');
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(graphKey(key));
  await settleMemory(tester);
}

SceneGraph _graph(WidgetTester tester) => tester
    .widget<SceneGraphCanvas>(find.byType(SceneGraphCanvas).first)
    .scene
    .graph;

Icon _firstIcon(WidgetTester tester, String key) => tester.widget<Icon>(
  find.descendant(of: graphKey(key), matching: find.byType(Icon)).first,
);

void _expectCardTitle(String id, String text) {
  expect(
    find.descendant(
      of: graphKey('scene-graph-card-$id'),
      matching: find.text(text),
    ),
    findsOneWidget,
  );
}
