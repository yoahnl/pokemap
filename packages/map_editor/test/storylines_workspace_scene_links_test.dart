import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('StorylineStep scene links authoring', () {
    testWidgets('shows linked scenes section and links a real project scene',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester, project: _project());

      await _openStepEditor(tester);

      expect(find.byKey(const ValueKey('storylines-step-scene-links-section')),
          findsOneWidget);
      expect(
        find.textContaining('authoring/progression uniquement'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('storylines-step-scene-link-empty')),
          findsOneWidget);
      expect(
        find.byKey(const ValueKey('storylines-step-link-scene-scene_intro')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('storylines-step-link-scene-scene_intro')),
      );
      await tester.tap(
        find.byKey(const ValueKey('storylines-step-link-scene-scene_intro')),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('storylines-step-scene-link-row-scene_intro'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('storylines-edit-step-submit')),
      );
      await tester.pumpAndSettle();

      expect(
        harness.project.storylines.single.chapters.single.steps.single
            .sceneLinkIds,
        ['scene_intro'],
      );
      expect(harness.project.scenes.map((scene) => scene.id),
          ['scene_intro', 'scene_resolution']);
      expect(harness.project.maps, isEmpty);
    });

    testWidgets('prevents duplicates and removes a linked scene',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _project(sceneLinkIds: const ['scene_intro']),
      );

      await _openStepEditor(tester);

      final linkButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-step-link-scene-scene_intro')),
      );
      expect(linkButton.onPressed, isNull);

      await tester.ensureVisible(
        find.byKey(
          const ValueKey('storylines-step-unlink-scene-scene_intro'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-step-unlink-scene-scene_intro'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('storylines-edit-step-submit')),
      );
      await tester.pumpAndSettle();

      expect(
        harness.project.storylines.single.chapters.single.steps.single
            .sceneLinkIds,
        isEmpty,
      );
      expect(harness.project.scenes, hasLength(2));
    });

    testWidgets('shows an unknown linked scene diagnostic', (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _project(sceneLinkIds: const ['missing_scene']),
      );

      await _openStepEditor(tester);

      expect(find.text('Scene introuvable'), findsOneWidget);
      expect(find.textContaining('introuvable'), findsWidgets);
    });

    testWidgets('writes the V1-29 visual gate screenshot', (tester) async {
      await _pumpStorylinesShell(tester, project: _project());

      await _openStepEditor(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('storylines-step-link-scene-scene_intro')),
      );
      await tester.tap(
        find.byKey(const ValueKey('storylines-step-link-scene-scene_intro')),
      );
      await tester.pump();

      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/scenes/screenshots/'
          'ns_scenes_v1_29_storyline_step_scene_link_v0.png',
        ),
      );
    });

    testWidgets(
        'authors facts outcomes status notes and moves the Step between Chapters',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _project(withAuthoringReferences: true),
      );

      await _openStepEditor(tester);
      final entry = find.byKey(
        const ValueKey(
          'storylines-step-entry-fact-set-fact_port_open',
        ),
      );
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      final completion = find.byKey(
        const ValueKey(
          'storylines-step-completion-fact-set-fact_intro_complete',
        ),
      );
      await tester.ensureVisible(completion);
      await tester.tap(completion);
      final outcome = find.byKey(
        const ValueKey(
          'storylines-step-outcome-scene_intro-victory',
        ),
      );
      await tester.ensureVisible(outcome);
      await tester.tap(outcome);
      final status = find.byKey(
        const ValueKey('storylines-step-status-active'),
      );
      await tester.ensureVisible(status);
      await tester.tap(status);
      final targetChapter = find.byKey(
        const ValueKey('storylines-step-target-chapter-chapter_resolution'),
      );
      await tester.ensureVisible(targetChapter);
      await tester.tap(targetChapter);
      await tester.enterText(
        find.byKey(const ValueKey('storylines-step-notes-field')),
        'Étape bloquée avant le port.',
      );
      await tester.tap(
        find.byKey(const ValueKey('storylines-edit-step-submit')),
      );
      await tester.pumpAndSettle();

      final chapters = harness.project.storylines.single.chapters;
      expect(chapters.first.steps, isEmpty);
      final step = chapters.last.steps.single;
      expect(step.entryCondition,
          ScriptConditionFactory.flagIsSet('fact_port_open'));
      expect(step.completionCondition,
          ScriptConditionFactory.flagIsSet('fact_intro_complete'));
      expect(step.expectedOutcomeIds, ['victory']);
      expect(step.status, StorylineStatus.active);
      expect(step.authorNotes, 'Étape bloquée avant le port.');
    });

    testWidgets('keeps broken Fact and Outcome references visible',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _project(
          entryCondition: ScriptConditionFactory.flagIsSet('missing_fact'),
          expectedOutcomeIds: const ['missing_outcome'],
        ),
      );

      await _openStepEditor(tester);
      await tester.ensureVisible(
        find.byKey(
          const ValueKey(
            'storylines-step-entry-missing-fact-missing_fact',
          ),
        ),
      );

      expect(find.text('Fact introuvable · missing_fact'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'storylines-step-missing-outcome-missing_outcome',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('preserves an optional side quest Step lifecycle status',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _project(
          storylineType: StorylineType.sideQuest,
          stepStatus: StorylineStatus.archived,
        ),
      );

      await _openStepEditor(tester);
      final completed = find.byKey(
        const ValueKey('storylines-step-status-archived'),
      );
      await tester.ensureVisible(completed);
      await tester.tap(
        find.byKey(const ValueKey('storylines-edit-step-submit')),
      );
      await tester.pumpAndSettle();

      final storyline = harness.project.storylines.single;
      expect(storyline.type, StorylineType.sideQuest);
      expect(
        storyline.chapters.single.steps.single.status,
        StorylineStatus.archived,
      );
    });
  });
}

Future<void> _openStepEditor(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Structure'),
    ),
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey('storylines-edit-step-action-step_intro')),
  );
  await tester.pumpAndSettle();
}

Future<_StorylinesHarness> _pumpStorylinesShell(
  WidgetTester tester, {
  ProjectManifest? project,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, _) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project ?? _project(),
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 1400,
            height: 900,
            child: NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  return _StorylinesHarness(container);
}

ProjectManifest _project({
  List<String> sceneLinkIds = const <String>[],
  ScriptCondition? entryCondition,
  List<String> expectedOutcomeIds = const <String>[],
  bool withAuthoringReferences = false,
  StorylineType storylineType = StorylineType.main,
  StorylineStatus? stepStatus,
}) {
  return ProjectManifest(
    name: 'Storylines Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: [
      _scene(
        'scene_intro',
        'Intro Scene',
        outcomes: withAuthoringReferences
            ? [SceneOutcome(id: 'victory', label: 'Victoire')]
            : const [],
      ),
      _scene('scene_resolution', 'Resolution Scene'),
    ],
    storylines: [
      StorylineAsset(
        id: 'story_main',
        type: storylineType,
        title: 'Main story',
        chapters: [
          StorylineChapter(
            id: 'chapter_intro',
            title: 'Intro',
            order: 0,
            steps: [
              StorylineStep(
                id: 'step_intro',
                title: 'Intro',
                order: 0,
                entryCondition: entryCondition,
                sceneLinkIds: sceneLinkIds,
                expectedOutcomeIds: expectedOutcomeIds,
                status: stepStatus,
              ),
            ],
          ),
          if (withAuthoringReferences)
            StorylineChapter(
              id: 'chapter_resolution',
              title: 'Résolution',
              order: 1,
            ),
        ],
      ),
    ],
    facts: withAuthoringReferences
        ? [
            NarrativeFactDefinition(
              id: 'fact_port_open',
              label: 'Port ouvert',
            ),
            NarrativeFactDefinition(
              id: 'fact_intro_complete',
              label: 'Introduction terminée',
            ),
          ]
        : const [],
  );
}

SceneAsset _scene(
  String id,
  String name, {
  List<SceneOutcome> outcomes = const [],
}) {
  return SceneAsset(
    id: id,
    name: name,
    declaredOutcomes: outcomes,
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
  );
}

class _StorylinesHarness {
  const _StorylinesHarness(this.container);

  final ProviderContainer container;

  EditorState get editorState => container.read(editorNotifierProvider);

  ProjectManifest get project => editorState.project!;
}
