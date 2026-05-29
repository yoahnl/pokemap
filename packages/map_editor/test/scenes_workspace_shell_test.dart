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
  group('NS-SCENES-V1-05 scene tree panel read-only', () {
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
      expect(find.byKey(const ValueKey('scene-graph-canvas')), findsNothing);
      expect(find.byKey(const ValueKey('scene-node-inspector')), findsNothing);
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

    testWidgets('writes V1-05 visual gate screenshot', (tester) async {
      await _pumpNarrativeShell(
        tester,
        project: _projectWithTwoScenes(),
        workspaceMode: EditorWorkspaceMode.scenes,
      );

      await expectLater(
        find.byKey(const ValueKey('scenes-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_05_scene_tree_panel_read_only.png',
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
        SceneNode(id: 'node_merge', kind: SceneNodeKind.merge),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_merge',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_merge',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_merge_end',
          fromNodeId: 'node_merge',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: [
      SceneOutcome(id: 'intro_done', label: 'Intro done'),
      SceneOutcome(id: 'branch_done', label: 'Branch done'),
    ],
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
