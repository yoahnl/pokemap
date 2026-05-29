import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('NS-SCENES-V1-06 graph read-only skeleton', () {
    testWidgets('Narrative Studio exposes a real Scenes navigation entry',
        (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _emptyProject(),
        workspaceMode: EditorWorkspaceMode.globalStory,
      );

      final sidebar = find.byKey(const ValueKey('narrative-studio-sidebar'));
      expect(sidebar, findsOneWidget);
      expect(
        find.byKey(const ValueKey('narrative-studio-sidebar-scenes')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sidebar, matching: find.text('Scènes')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-studio-sidebar-scenes')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.scenes,
      );
      expect(
          find.byKey(const ValueKey('scenes-workspace-shell')), findsOneWidget);
    });

    testWidgets(
        'shows an honest empty state when ProjectManifest.scenes is empty',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _emptyProject(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
          find.byKey(const ValueKey('scenes-workspace-shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-panel')), findsOneWidget);
      expect(find.text('Arborescence des scènes'), findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-empty-state')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-summary-empty-state')),
          findsOneWidget);
      expect(find.text('0 scènes'), findsOneWidget);
      expect(find.text('Aucune scène créée'), findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-list-compact')), findsNothing);
    });

    testWidgets('disabled actions do not mutate ProjectManifest',
        (tester) async {
      final project = _projectWithScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      final createButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('scenes-create-scene-disabled')).first,
      );
      final builderButton = tester.widget<PokeMapButton>(
        find
            .byKey(
              const ValueKey(
                'scenes-open-graph-disabled-scene_test_intro',
              ),
            )
            .first,
      );

      expect(createButton.onPressed, isNull);
      expect(builderButton.onPressed, isNull);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('shows real SceneAsset data in the read-only tree and summary',
        (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(find.byKey(const ValueKey('scenes-tree-panel')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scenes-tree-item-scene_test_intro')),
        findsOneWidget,
      );
      expect(find.text('Test Scene Intro'), findsWidgets);
      expect(find.text('3 nodes'), findsWidgets);
      expect(find.text('2 outcomes'), findsWidgets);
      expect(find.text('storyline_test'), findsWidgets);
      expect(find.text('chapter_test'), findsWidgets);
      expect(find.text('Intro done'), findsOneWidget);
      expect(find.text('Branch done'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-graph-read-only-view')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scene-graph-layout-source-real')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_start')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_merge')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-edge-edge_start_merge')),
          findsOneWidget);
      expect(find.text('completed'), findsWidgets);
      expect(find.byKey(const ValueKey('scene-node-inspector')), findsNothing);
    });

    testWidgets('uses a derived layout for scenes with incomplete layout',
        (tester) async {
      final project = _projectWithTwoScenes();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-tree-item-scene_test_branch')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scene-graph-read-only-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-layout-source-derived')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scene-graph-node-node_start')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-node-node_end')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scene-graph-edge-edge_start_end')),
          findsOneWidget);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets(
        'uses bounded derived layout for cyclic and disconnected graph',
        (tester) async {
      final project = _projectWithComplexFallbackScene();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(
        find.byKey(const ValueKey('scene-graph-read-only-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-layout-source-derived')),
        findsOneWidget,
      );
      expect(
          find.byKey(const ValueKey('scene-graph-node-node_a')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('scene-graph-node-node_b')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('scene-graph-node-node_c')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('scene-graph-node-node_d')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-graph-edge-edge_a_b')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-edge-edge_b_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-edge-edge_c_d')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scene-node-inspector')), findsNothing);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets(
        'local scene selection updates summary without mutating project',
        (tester) async {
      final project = _projectWithTwoScenes();
      final container = await _pumpNarrativeShell(
        tester,
        project: project,
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      expect(find.text('Test Scene Intro'), findsWidgets);
      expect(find.text('Second Test Scene'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scenes-selected-summary-scene_test_intro')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('scenes-tree-item-scene_test_branch')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-selected-summary-scene_test_branch')),
        findsOneWidget,
      );
      expect(find.text('Second Test Scene'), findsWidgets);
      expect(find.byKey(const ValueKey('scene-graph-layout-source-derived')),
          findsOneWidget);
      expect(container.read(editorNotifierProvider).project, equals(project));
    });

    testWidgets('Storylines workspace remains selectable', (tester) async {
      final container = await _pumpNarrativeShell(
        tester,
        project: _emptyProject(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-studio-sidebar-storylines')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.globalStory,
      );
      expect(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        findsOneWidget,
      );
    });

    testWidgets('writes V1-06 visual gate screenshot', (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithTwoScenes(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_06_graph_read_only_skeleton.png',
        ),
      );
    });
  });
}

Future<ProviderContainer> _pumpNarrativeShell(
  WidgetTester tester, {
  required ProjectManifest project,
  required EditorWorkspaceMode workspaceMode,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
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
    workspaceMode: workspaceMode,
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 1440,
            height: 900,
            child: NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

ProjectManifest _emptyProject() {
  return const ProjectManifest(
    name: 'Scenes shell test',
    maps: [],
    tilesets: [],
  );
}

ProjectManifest _projectWithScene() {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [_testIntroScene()],
  );
}

ProjectManifest _projectWithTwoScenes() {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [
      _testIntroScene(),
      _testBranchScene(),
    ],
  );
}

ProjectManifest _projectWithComplexFallbackScene() {
  return ProjectManifest(
    name: 'Scenes shell test',
    maps: const [],
    tilesets: const [],
    scenes: [_testComplexFallbackScene()],
  );
}

SceneAsset _testIntroScene() {
  return SceneAsset(
    id: 'scene_test_intro',
    name: 'Test Scene Intro',
    description: 'Fixture locale de test.',
    storylineId: 'storyline_test',
    chapterId: 'chapter_test',
    tags: const ['test', 'intro'],
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_merge',
          kind: SceneNodeKind.merge,
          title: 'Merge test',
          description: 'Node réel de test.',
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'End test'),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_merge',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_merge',
          kind: SceneEdgeKind.defaultFlow,
          label: 'completed',
        ),
        SceneEdge(
          id: 'edge_merge_end',
          fromNodeId: 'node_merge',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
          label: 'done',
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_merge', x: 260, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 500, y: 80),
      ],
    ),
    declaredOutcomes: [
      SceneOutcome(id: 'intro_done', label: 'Intro done'),
      SceneOutcome(id: 'branch_done', label: 'Branch done'),
    ],
  );
}

SceneAsset _testComplexFallbackScene() {
  return SceneAsset(
    id: 'scene_test_complex_fallback',
    name: 'Complex Fallback Test Scene',
    description: 'Fixture locale de test cyclique et déconnectée.',
    graph: SceneGraph(
      startNodeId: 'node_a',
      nodes: [
        SceneNode(id: 'node_a', kind: SceneNodeKind.start, title: 'Node A'),
        SceneNode(id: 'node_b', kind: SceneNodeKind.condition, title: 'Node B'),
        SceneNode(id: 'node_c', kind: SceneNodeKind.merge, title: 'Node C'),
        SceneNode(id: 'node_d', kind: SceneNodeKind.end, title: 'Node D'),
      ],
      edges: [
        SceneEdge(
          id: 'edge_a_b',
          fromNodeId: 'node_a',
          fromPortId: 'completed',
          toNodeId: 'node_b',
          kind: SceneEdgeKind.defaultFlow,
          label: 'a to b',
        ),
        SceneEdge(
          id: 'edge_b_a',
          fromNodeId: 'node_b',
          fromPortId: 'true',
          toNodeId: 'node_a',
          kind: SceneEdgeKind.conditionTrue,
          label: 'b to a',
        ),
        SceneEdge(
          id: 'edge_c_d',
          fromNodeId: 'node_c',
          fromPortId: 'completed',
          toNodeId: 'node_d',
          kind: SceneEdgeKind.actionCompleted,
          label: 'c to d',
        ),
      ],
    ),
  );
}

SceneAsset _testBranchScene() {
  return SceneAsset(
    id: 'scene_test_branch',
    name: 'Second Test Scene',
    description: 'Deuxième fixture locale.',
    tags: const ['test'],
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: [
      SceneOutcome(id: 'second_done', label: 'Second done'),
    ],
  );
}
