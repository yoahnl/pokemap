import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('cinematic palette is disabled without canonical assets',
      (tester) async {
    await _pumpNarrativeShell(
      tester,
      project: _project(cinematics: const [], includeBridge: false),
    );

    final noCanonicalButton = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('scenes-add-node-cinematic-disabled')).first,
    );
    expect(noCanonicalButton.onPressed, isNull);
    expect(
      find.textContaining('Créez d’abord une cinématique'),
      findsWidgets,
    );

    await _pumpNarrativeShell(
      tester,
      project: _project(cinematics: const [], includeBridge: true),
    );

    final bridgeOnlyButton = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('scenes-add-node-cinematic-disabled')).first,
    );
    expect(bridgeOnlyButton.onPressed, isNull);
    expect(
      find.textContaining('bridges legacy existent'),
      findsWidgets,
    );
  });

  testWidgets('canonical picker creates a CinematicNode and connects completed',
      (tester) async {
    final container = await _pumpNarrativeShell(tester, project: _project());

    final button = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('scenes-add-node-cinematic')).first,
    );
    expect(button.onPressed, isNotNull);

    button.onPressed!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('scene-cinematic-picker-dialog')),
      findsOneWidget,
    );
    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('Legacy cutscene'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('scene-cinematic-picker-option-cinematic_intro'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('scene-cinematic-picker-option-scenario_cutscene'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('scene-cinematic-picker-option-cinematic_intro'),
      ),
    );
    await tester.pumpAndSettle();

    final scene = container.read(editorNotifierProvider).project!.scenes.single;
    final node = scene.graph.nodes.singleWhere(
      (node) => node.kind == SceneNodeKind.cinematic,
    );
    expect(node.id, 'node_cinematic');
    expect(node.title, 'Intro cinematic');
    expect(
      node.payload,
      SceneCinematicPayload(cinematicId: 'cinematic_intro'),
    );
    expect(scene.graph.edges, isEmpty);
    expect(
      find.byKey(const ValueKey('scene-graph-node-selected-node_cinematic')),
      findsOneWidget,
    );
    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('cinematic_intro'), findsWidgets);

    await tester
        .tap(find.byKey(const ValueKey('scenes-connect-port-completed')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scene-graph-node-node_end')));
    await tester.pumpAndSettle();

    final connectedScene =
        container.read(editorNotifierProvider).project!.scenes.single;
    final edge = connectedScene.graph.edges.single;
    expect(edge.fromNodeId, 'node_cinematic');
    expect(edge.fromPortId, 'completed');
    expect(edge.kind, SceneEdgeKind.cinematicCompleted);
  });

  testWidgets('inspector changes a cinematic ref to another canonical asset',
      (tester) async {
    final container = await _pumpNarrativeShell(
      tester,
      project: _project(
        cinematics: [
          _cinematic(id: 'cinematic_intro', title: 'Intro cinematic'),
          _cinematic(id: 'cinematic_second', title: 'Second cinematic'),
        ],
        scene: _sceneWithCinematicRef('cinematic_intro'),
      ),
    );

    await tester
        .tap(find.byKey(const ValueKey('scene-graph-node-node_cinematic')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('scene-payload-edit-cinematic-action')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('scene-cinematic-picker-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey('scene-cinematic-picker-option-cinematic_second'),
      ),
    );
    await tester.pumpAndSettle();

    final scene = container.read(editorNotifierProvider).project!.scenes.single;
    final node =
        scene.graph.nodes.singleWhere((node) => node.id == 'node_cinematic');
    expect(
      node.payload,
      SceneCinematicPayload(cinematicId: 'cinematic_second'),
    );
    expect(find.text('Second cinematic'), findsWidgets);
  });

  testWidgets('inspector reports bridge legacy and unknown cinematic refs',
      (tester) async {
    await _pumpNarrativeShell(
      tester,
      project: _project(scene: _sceneWithCinematicRef('scenario_cutscene')),
    );

    await tester
        .tap(find.byKey(const ValueKey('scene-graph-node-node_cinematic')));
    await tester.pumpAndSettle();
    expect(find.text('Bridge legacy'), findsWidgets);
    expect(find.textContaining('Scenario/Cutscene legacy'), findsWidgets);
    expect(
      find.byKey(const ValueKey('scene-payload-edit-cinematic-action')),
      findsOneWidget,
    );

    await _pumpNarrativeShell(
      tester,
      project: _project(scene: _sceneWithCinematicRef('missing_cinematic')),
    );

    await tester
        .tap(find.byKey(const ValueKey('scene-graph-node-node_cinematic')));
    await tester.pumpAndSettle();
    expect(find.text('Référence inconnue'), findsWidgets);
    expect(find.textContaining('missing_cinematic'), findsWidgets);
  });

  testWidgets('writes V1-39 cinematic Scene Builder picker screenshot',
      (tester) async {
    await _pumpNarrativeShell(
      tester,
      project: _project(
        cinematics: [
          _cinematic(id: 'cinematic_intro', title: 'Intro cinematic'),
          _cinematic(id: 'cinematic_second', title: 'Second cinematic'),
        ],
        scene: _sceneWithCinematicFlow(),
      ),
      surfaceSize: const Size(1920, 1080),
    );

    await tester
        .tap(find.byKey(const ValueKey('scene-graph-node-node_cinematic')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('scenes-add-node-cinematic')),
      findsOneWidget,
    );
    expect(find.text('CinematicAsset'), findsWidgets);
    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('cinematic_intro'), findsWidgets);
    expect(
      find.byKey(const ValueKey('scenes-connect-port-completed')),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(const ValueKey('scenes-workspace-shell')),
      matchesGoldenFile(
        '../../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png',
      ),
    );
  });
}

Future<ProviderContainer> _pumpNarrativeShell(
  WidgetTester tester, {
  required ProjectManifest project,
  Size surfaceSize = const Size(1440, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project,
    workspaceMode: EditorWorkspaceMode.scenes,
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: const NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

ProjectManifest _project({
  List<CinematicAsset>? cinematics,
  bool includeBridge = true,
  SceneAsset? scene,
}) {
  return ProjectManifest(
    name: 'Scene cinematic picker test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics ??
        [
          _cinematic(id: 'cinematic_intro', title: 'Intro cinematic'),
        ],
    scenarios: includeBridge ? [_scenarioBridge()] : const [],
    scenes: [scene ?? _baseScene()],
  );
}

CinematicAsset _cinematic({
  required String id,
  required String title,
}) {
  return CinematicAsset(
    id: id,
    title: title,
    mapId: 'map_test',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_test', label: 'Actor test'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera',
          durationMs: 400,
        ),
      ],
    ),
  );
}

ScenarioAsset _scenarioBridge() {
  return const ScenarioAsset(
    id: 'scenario_cutscene',
    name: 'Legacy cutscene',
    entryNodeId: 'scenario_start',
    metadata: {'authoring.cutsceneSchema': 'test'},
  );
}

SceneAsset _baseScene() {
  return SceneAsset(
    id: 'scene_picker',
    name: 'Scene Picker',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'Fin'),
      ],
      edges: const [],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 420, y: 80),
      ],
    ),
  );
}

SceneAsset _sceneWithCinematicRef(String cinematicId) {
  return SceneAsset(
    id: 'scene_picker',
    name: 'Scene Picker',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          title: 'Cinematic node',
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'Fin'),
      ],
      edges: const [],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_cinematic', x: 260, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 560, y: 80),
      ],
    ),
  );
}

SceneAsset _sceneWithCinematicFlow() {
  return SceneAsset(
    id: 'scene_picker',
    name: 'Scene Picker',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          title: 'Intro cinematic',
          payload: SceneCinematicPayload(cinematicId: 'cinematic_intro'),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'Fin'),
      ],
      edges: [
        SceneEdge(
          id: 'edge_node_start_completed_node_cinematic',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_cinematic',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_node_cinematic_completed_node_end',
          fromNodeId: 'node_cinematic',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 100),
        SceneNodeLayout(nodeId: 'node_cinematic', x: 300, y: 100),
        SceneNodeLayout(nodeId: 'node_end', x: 620, y: 100),
      ],
    ),
  );
}
