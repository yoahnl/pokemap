import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_overview_landing.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_node_finder.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_readable_summary.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scene_canvas_test_harness.dart';

List<String> _captureAnnouncements(WidgetTester tester) {
  final messages = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
    SystemChannels.accessibility,
    (message) async {
      final data = (message as Map)['data'] as Map?;
      if (message['type'] == 'announce') messages.add('${data?['message']}');
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return messages;
}

void main() {
  testWidgets('a keyboard link makes the pointer link and undoes at once', (
    tester,
  ) async {
    final announcements = _captureAnnouncements(tester);
    final harness = SceneCanvasTestHarness();
    await harness.mount(tester);
    await tester.tap(find.text('Autoriser le départ'));
    await tester.pump();
    harness.refresh(() => harness.selected = 'start');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.pump();
    expect(announcements.last, startsWith('Liaison depuis « Début »'));
    expect(announcements.last, contains('vers « Autoriser le départ »'));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(announcements.last, 'Cible « Fin ».');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(announcements.last, 'Cible « Autoriser le départ ».');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final edge = harness.scene.graph.edges.single;
    expect(edge.fromNodeId, 'start');
    expect(edge.fromPortId, 'completed');
    expect(edge.toNodeId, 'action');
    expect(edge.kind, SceneEdgeKind.defaultFlow);
    expect(harness.commits, 1);
    expect(
      announcements.last,
      '« Début », sortie Continuer, relié à « Autoriser le départ ».',
    );

    harness.undo();
    await tester.pump();
    expect(harness.scene.graph.edges, isEmpty);
  });

  testWidgets('escape cancels a keyboard link and says so', (tester) async {
    final announcements = _captureAnnouncements(tester);
    final harness = SceneCanvasTestHarness();
    await harness.mount(tester);
    await tester.tap(find.text('Autoriser le départ'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.pump();
    expect(
      announcements.last,
      startsWith('Liaison depuis « Autoriser le départ »'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(announcements, contains('Liaison annulée.'));
    expect(harness.scene.graph.edges, isEmpty);
    expect(harness.commits, 0);
  });

  testWidgets('ports keep a 28 point target at every zoom', (tester) async {
    final harness = SceneCanvasTestHarness();
    await harness.mount(tester);
    final port = find.byKey(
      const ValueKey('scene-graph-output-port-start-completed'),
    );
    for (final zoom in [.4, 1.0, 1.8]) {
      harness.view.zoomAt(zoom, const Offset(300, 200));
      await tester.pump();
      expect(tester.getSize(port), const Size(28, 28));
    }
  });

  testWidgets('a block lists where it comes from and where it leads', (
    tester,
  ) async {
    final harness = SceneCanvasTestHarness();
    final linked = addSceneEdgeDraft(
      harness.scene,
      fromNodeId: 'start',
      fromPortId: 'completed',
      toNodeId: 'action',
    ).updatedScene;
    final focused = <String>[];
    Future<void> show(String nodeId) => tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SceneNodeLinks(
            scene: linked,
            node: linked.graph.nodes.firstWhere((node) => node.id == nodeId),
            onFocusNode: focused.add,
          ),
        ),
      ),
    );
    await show('start');
    expect(find.text('Point d’entrée de la scène.'), findsOneWidget);
    await tester.tap(find.text('Continuer → Autoriser le départ'));
    await show('action');
    await tester.tap(find.text('Début · Continuer'));
    expect(find.text('Continuer · non reliée'), findsOneWidget);
    await show('end');
    expect(find.textContaining('ne sera jamais atteint'), findsOneWidget);
    expect(focused, ['action', 'start']);
  });

  test('blocks are found by title or by kind', () {
    final scene = SceneCanvasTestHarness().scene;
    expect(sceneNodeMatches(scene, 'autoriser').map((node) => node.id), [
      'action',
    ]);
    expect(sceneNodeMatches(scene, 'fin').map((node) => node.id), ['end']);
    expect(sceneNodeMatches(scene, ''), hasLength(3));
  });

  testWidgets('history keeps « Reprendre » for a real resumption', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final search = TextEditingController();
    final scroll = ScrollController();
    addTearDown(search.dispose);
    addTearDown(scroll.dispose);
    final scene = SceneCanvasTestHarness().scene;
    Future<void> show({String? active}) => tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: NarrativeOverviewLanding(
            overview: NarrativeOverview(
              stories: [],
              facts: [],
              interactions: [],
              stepsById: {},
              stepLinks: {},
              factLinks: {},
              dirtyCount: 0,
            ),
            project: ProjectManifest(
              name: 'Recette',
              tilesets: const [],
              maps: const [],
            ),
            scenes: [scene],
            dialogues: const [],
            events: const [],
            search: search,
            onSearch: (_) {},
            resultsScroll: scroll,
            onLibrary: () {},
            onCreateStory: null,
            onCreateScene: null,
            onCreateEvent: null,
            onProgression: null,
            onScenes: null,
            onEvents: null,
            onVerification: null,
            onOpenStory: (_) {},
            onOpenStep: (_, _) {},
            onOpenScene: (_) {},
            onOpenInteraction: (_) {},
            onOpenDialogue: null,
            onOpenEvent: null,
            onOpenMap: null,
            activeSceneId: active,
          ),
        ),
      ),
    );
    final resume = find.byKey(const ValueKey('narrative-landing-resume'));
    await show();
    await tester.pumpAndSettle();
    expect(find.text('Rien à reprendre'), findsOneWidget);
    expect(find.text('Reprendre votre travail'), findsNothing);
    expect(
      find.descendant(of: resume, matching: find.text('Recette')),
      findsNothing,
    );
    await show(active: scene.id);
    await tester.pumpAndSettle();
    expect(find.text('Reprendre votre travail'), findsOneWidget);
    expect(
      find.descendant(of: resume, matching: find.text('Scène ouverte')),
      findsOneWidget,
    );
  });

  test('the readable summary follows the graph from the start', () {
    var scene = SceneCanvasTestHarness().scene;
    for (final (from, to) in [('start', 'action'), ('action', 'end')]) {
      scene = addSceneEdgeDraft(
        scene,
        fromNodeId: from,
        fromPortId: 'completed',
        toNodeId: to,
      ).updatedScene;
    }
    final summary = sceneReadableSummary(
      scene,
      (node) => node.title ?? node.kind.name,
    );
    expect(summary.conditions, isEmpty);
    expect(summary.steps, ['Action · Autoriser le départ', 'Fin · end']);
    expect(summary.unreached, 0);
    final empty = sceneReadableSummary(
      SceneCanvasTestHarness().scene,
      (node) => node.kind.name,
    );
    expect(empty.steps, isEmpty);
    expect(empty.unreached, 2);
  });
}
