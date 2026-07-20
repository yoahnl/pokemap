import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/canvas/scenes_workspace.dart';
import 'package:map_editor/src/ui/canvas/step_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/storylines_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/event_builder_v2_visual_harness.dart';
import '../../support/narrative_studio_capture_fonts.dart';

const _narrativeStudioArialCaptureFontFamily =
    'NarrativeStudioArialCaptureFont';

Future<void> _loadNarrativeStudioArialCaptureFonts() async {
  await loadNarrativeStudioCaptureFonts(
    textFamilies: const <String>[
      eventBuilderV2PhaseKCaptureFontFamily,
      _narrativeStudioArialCaptureFontFamily,
    ],
  );
}

void main() {
  test('NSC-60 tracks every canonical Cinematics golden at 1672x941', () {
    for (final state in const <String>['library', 'builder', 'legacy']) {
      final golden = File(
        'test/goldens/narrative_studio/cinematics/'
        'cinematics_${state}_full_product_route_1672x941.png',
      );
      expect(golden.existsSync(), isTrue, reason: 'Golden absent: $state');
      final bytes = golden.readAsBytesSync();
      expect(bytes.length, greaterThan(24), reason: 'PNG invalide: $state');
      expect(_pngUint32(bytes, 16), 1672, reason: 'Largeur: $state');
      expect(_pngUint32(bytes, 20), 941, reason: 'Hauteur: $state');
    }
  });

  testWidgets(
    'Storylines full route owns one product shell and one real create action',
    (tester) async {
      final project = _projectWithStorylinesAndStep();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.globalStory,
        ),
        surfaceSize: const Size(1672, 941),
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(StorylinesWorkspace), findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsNothing);
      expect(find.text('Narrative Studio  /  Storylines'), findsOneWidget);

      final createAction =
          find.byKey(const ValueKey('storylines-create-main-cta'));
      expect(
        find.descendant(
          of: find.byKey(narrativeStudioWorkspaceContextKey),
          matching: createAction,
        ),
        findsOneWidget,
      );
      expect(container.read(editorNotifierProvider).project, equals(project));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Step full route stays nested under the selected Storylines destination',
    (tester) async {
      final project = _projectWithStorylinesAndStep();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.step,
        ),
        surfaceSize: const Size(1672, 941),
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(StepStudioWorkspace), findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsNothing);
      expect(
        find.text(
          'Narrative Studio  /  Storylines  /  Étape  /  Aller au port',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-studio-product-nav-storylines'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-studio-product-nav-step')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('step-studio-save-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('step-studio-reset-action')),
        findsOneWidget,
      );
      expect(container.read(editorNotifierProvider).project, equals(project));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Scenes full route owns one shared product shell and one workspace page',
    (tester) async {
      final project = _projectWithScene();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1672, 941),
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(ScenesWorkspace), findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsNothing);
      expect(
        find.byKey(const ValueKey('scenes-create-scene-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-validate-project')),
        findsNothing,
      );
      expect(
        container.read(editorNotifierProvider).project,
        equals(project),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Scenes route action opens the existing draft flow without eager mutation',
    (tester) async {
      final project = _projectWithScene();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1440, 900),
      );

      final contextHeader = find.byKey(narrativeStudioWorkspaceContextKey);
      final createAction = find.byKey(
        const ValueKey('scenes-create-scene-action'),
      );
      expect(
        find.descendant(of: contextHeader, matching: createAction),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('scenes-tree-panel')),
          matching: createAction,
        ),
        findsNothing,
      );

      await tester.tap(createAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-create-scene-dialog')),
        findsOneWidget,
      );
      expect(container.read(editorNotifierProvider).project, equals(project));
    },
  );

  testWidgets(
    'compact Scenes opens its inspector side sheet and Escape restores focus',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(
        tester.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final project = _projectWithScene();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1280, 768),
      );

      final launcher = find.byKey(
        const ValueKey('scenes-open-inspector-action'),
      );
      expect(
          find.byKey(const ValueKey('scenes-inspector-column')), findsNothing);
      expect(launcher, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scene-graph-node-node_end')));
      await tester.pump();
      await tester.tap(launcher);
      await tester.pumpAndSettle();

      final sheet = find.byType(PokeMapDesktopSideSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.byKey(const ValueKey('scenes-inspector-sheet-content')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.byKey(
            const ValueKey('scene-node-read-only-inspector'),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('node_end'), findsWidgets);
      expect(_primaryFocusIsInside(sheet), isTrue);
      expect(container.read(editorNotifierProvider).project, equals(project));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(sheet, findsNothing);
      expect(_primaryFocusIsInside(launcher), isTrue);
      expect(container.read(editorNotifierProvider).project, equals(project));
    },
  );

  testWidgets(
    'compact Scenes inspector side sheet closes through navigator back',
    (tester) async {
      final project = _projectWithScene();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1366, 768),
      );

      final launcher = find.byKey(
        const ValueKey('scenes-open-inspector-action'),
      );
      await tester.tap(launcher);
      await tester.pumpAndSettle();
      expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
      expect(_primaryFocusIsInside(launcher), isTrue);
      expect(container.read(editorNotifierProvider).project, equals(project));
    },
  );

  testWidgets(
    'compact Scenes inspector sheet reacts to a real edge deletion',
    (tester) async {
      final project = _projectWithScene();
      final originalNodes = project.scenes.single.graph.nodes;
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1280, 768),
      );

      await tester.tap(
        find.byKey(
          const ValueKey('scene-graph-edge-hit-target-edge_start_end'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('scenes-open-inspector-action')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-edge-read-only-inspector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-edge-delete-action')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-edge-delete-action')),
      );
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      expect(updatedScene.graph.edges, isEmpty);
      expect(updatedScene.graph.nodes, originalNodes);
      expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-edge-delete-action')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('scene-edge-read-only-inspector')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('scene-node-read-only-inspector')),
        findsOneWidget,
      );
    },
  );

  for (final size in <Size>[
    const Size(1280, 768),
    const Size(1366, 768),
    const Size(1440, 900),
    const Size(1672, 941),
    const Size(1920, 941),
  ]) {
    for (final textScale in <double>[1, 1.25, 1.5]) {
      testWidgets(
        'Scenes full route has no overflow at ${size.width}x${size.height} '
        'and ${textScale * 100}% text',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(
            tester.platformDispatcher.clearTextScaleFactorTestValue,
          );
          await pumpEditorShellPage(
            tester,
            initialState: EditorState(
              project: _projectWithScene(),
              workspaceMode: EditorWorkspaceMode.scenes,
            ),
            surfaceSize: size,
          );

          expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
          expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
          final compact = size.width <= 1366;
          final inspectorColumn = find.byKey(
            const ValueKey('scenes-inspector-column'),
          );
          final inspectorLauncher = find.byKey(
            const ValueKey('scenes-open-inspector-action'),
          );
          final graphSize = tester.getSize(
            find.byKey(const ValueKey('scenes-graph-column')),
          );
          if (compact) {
            expect(inspectorColumn, findsNothing);
            expect(inspectorLauncher, findsOneWidget);
            expect(graphSize.width, greaterThan(800));
          } else {
            expect(inspectorColumn, findsOneWidget);
            expect(inspectorLauncher, findsNothing);
            final inspectorSize = tester.getSize(inspectorColumn);
            expect(inspectorSize.width, closeTo(320, 0.1));
            expect(graphSize.width, greaterThan(inspectorSize.width));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final workspaceMode in <EditorWorkspaceMode>[
    EditorWorkspaceMode.globalStory,
    EditorWorkspaceMode.step,
  ]) {
    for (final size in <Size>[
      const Size(1280, 768),
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1672, 941),
      const Size(1920, 941),
    ]) {
      for (final textScale in <double>[1, 1.25, 1.5]) {
        testWidgets(
          '$workspaceMode has one shell and no overflow at '
          '${size.width}x${size.height}, ${textScale * 100}% text',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = textScale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await pumpEditorShellPage(
              tester,
              initialState: EditorState(
                project: _projectWithStorylinesAndStep(),
                workspaceMode: workspaceMode,
              ),
              surfaceSize: size,
            );

            expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
            expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
            expect(find.byType(ProjectExplorerPanel), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('matches the full Scenes product route at 1672x941',
      (tester) async {
    await loadEventBuilderV2PhaseKCaptureFonts();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        project: _projectWithScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      ),
      surfaceSize: const Size(1672, 941),
      fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    final output = File(
      'test/goldens/narrative_studio/scenes/'
      'scenes_full_product_route_1672x941.png',
    );
    output.parent.createSync(recursive: true);
    await expectLater(
      find.byType(EditorShellPage),
      matchesGoldenFile(output.absolute.path),
    );
  });

  for (final workspaceMode in <EditorWorkspaceMode>[
    EditorWorkspaceMode.globalStory,
    EditorWorkspaceMode.step,
  ]) {
    final routeName = workspaceMode == EditorWorkspaceMode.globalStory
        ? 'storylines'
        : 'step';
    testWidgets('matches the full $routeName product route at 1672x941',
        (tester) async {
      final isStep = workspaceMode == EditorWorkspaceMode.step;
      if (isStep) {
        await _loadNarrativeStudioArialCaptureFonts();
      } else {
        await loadEventBuilderV2PhaseKCaptureFonts();
      }
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: _projectWithStorylinesAndStep(),
          workspaceMode: workspaceMode,
        ),
        surfaceSize: const Size(1672, 941),
        fontFamily: isStep
            ? _narrativeStudioArialCaptureFontFamily
            : eventBuilderV2PhaseKCaptureFontFamily,
        cupertinoFontFamily:
            isStep ? _narrativeStudioArialCaptureFontFamily : null,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      final output = File(
        'test/goldens/narrative_studio/$routeName/'
        '${routeName}_full_product_route_1672x941.png',
      );
      output.parent.createSync(recursive: true);
      await expectLater(
        find.byType(EditorShellPage),
        matchesGoldenFile(output.absolute.path),
      );
    });
  }
}

int _pngUint32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

bool _primaryFocusIsInside(Finder finder) {
  final target = finder.evaluate().single;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;

  var current = focusContext as Element?;
  while (current != null) {
    if (identical(current, target)) return true;
    Element? parent;
    current.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    current = parent;
  }
  return false;
}

ProjectManifest _projectWithScene() {
  return ProjectManifest(
    name: 'Scenes convergence fixture',
    maps: [],
    tilesets: [],
    scenes: [
      SceneAsset(
        id: 'scene_intro',
        name: 'Introduction',
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
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithStorylinesAndStep() {
  const document = StepStudioDocument(
    globalStoryScenarioId: 'global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'step_port',
        name: 'Aller au port',
        description: 'Retrouver le rival sur le quai.',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
      StepStudioStep(
        id: 'step_rival',
        name: 'Affronter le rival',
        description: 'Remporter le premier combat.',
        order: 1,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.afterPreviousStep,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
    ],
  );
  return ProjectManifest(
    name: 'Selbrume Narrative',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    storylines: [
      StorylineAsset(
        id: 'storyline_main',
        type: StorylineType.main,
        title: 'La brume de Selbrume',
        description: 'Le mystère du port et de son ancien phare.',
        chapters: [
          StorylineChapter(
            id: 'chapter_port',
            title: 'Le port',
            description: 'Premiers indices sur les quais.',
            order: 0,
            steps: [
              StorylineStep(
                id: 'story_step_arrival',
                title: 'Arrivée à Selbrume',
                order: 0,
              ),
              StorylineStep(
                id: 'story_step_rival',
                title: 'Rencontre au port',
                order: 1,
              ),
            ],
          ),
          StorylineChapter(
            id: 'chapter_marsh',
            title: 'Les marais',
            order: 1,
          ),
        ],
      ),
      StorylineAsset(
        id: 'storyline_sidequest',
        type: StorylineType.sideQuest,
        title: 'Le pêcheur inquiet',
        description: 'Une quête annexe du port.',
      ),
    ],
    scenarios: [
      ScenarioAsset(
        id: 'global_story',
        name: 'La brume de Selbrume',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        metadata: {
          kStepStudioDocumentMetadataKey: document.toMetadataJson(),
        },
      ),
    ],
  );
}
