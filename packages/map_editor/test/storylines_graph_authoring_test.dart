import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_model.dart';
import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_view.dart';

void main() {
  group('NSC-23 Storyline semantic graph', () {
    test('adapts nodes and edges exclusively from the core projection', () {
      final project = _project();
      final projection = buildStorylineProgressionProjection(
        project: project,
        storylineId: 'story_main',
      );
      final model = StorylineGraphViewModel.fromProject(
        project,
        storylineId: 'story_main',
      );

      expect(model.nodes.map((node) => node.id),
          orderedEquals(projection.nodes.map((node) => node.id)));
      expect(model.edges.map((edge) => edge.id),
          orderedEquals(projection.edges.map((edge) => edge.id)));
      expect(
        model.edges
            .where((edge) =>
                edge.kind == StorylineGraphEdgeKind.outcomeCompletesStep)
            .single
            .isReversible,
        isTrue,
      );
      expect(
        model.edges
            .where((edge) =>
                edge.kind == StorylineGraphEdgeKind.completionCondition)
            .single
            .isReversible,
        isFalse,
      );
    });

    testWidgets('labels semantic edges and explains read-only semantics',
        (tester) async {
      await _pumpGraph(tester, project: _project());

      expect(find.textContaining('Complète l’étape'), findsOneWidget);
      expect(find.textContaining('Condition de complétion'), findsOneWidget);
      final conditionEdge = find.byKey(
        const ValueKey(
          'storylines-graph-semantic-edge-condition:story_main:chapter_end:step_end:completion',
        ),
      );
      await tester.ensureVisible(conditionEdge);
      await tester.pump();
      await tester.tap(conditionEdge);
      await tester.pump();

      expect(find.textContaining('non ambiguë'), findsOneWidget);
      expect(find.text('Lecture seule'), findsOneWidget);
    });

    testWidgets('disconnects only a reversible projected edge', (tester) async {
      String? disconnectedId;
      await _pumpGraph(
        tester,
        project: _project(),
        onDisconnectEdge: (edgeId) async {
          disconnectedId = edgeId;
          return true;
        },
      );
      final edge = buildStorylineProgressionProjection(
        project: _project(),
        storylineId: 'story_main',
      ).edgesOfKind(StorylineProgressionEdgeKind.outcomeCompletesStep).single;

      await tester.ensureVisible(
        find.byKey(ValueKey('storylines-graph-semantic-edge-${edge.id}')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('storylines-graph-semantic-edge-${edge.id}')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('storylines-graph-disconnect-${edge.id}')),
      );
      await tester.pump();

      expect(disconnectedId, edge.id);
    });

    testWidgets('supports keyboard focus, minimal multi-selection and reset',
        (tester) async {
      final project = _project();
      final before = project.toJson();
      await _pumpGraph(tester, project: project);
      final canvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      final root = find.byKey(
        const ValueKey('storylines-graph-node-storyline-story_main'),
      );
      final chapter = find.byKey(
        const ValueKey('storylines-graph-node-chapter-chapter_intro'),
      );
      final rootBefore = tester.getTopLeft(root) - tester.getTopLeft(canvas);

      await tester.tap(root);
      await tester.pump();
      expect(find.text('1 nœud sélectionné'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('1 nœud sélectionné'), findsOneWidget);
      await tester.longPress(chapter);
      await tester.pump();
      expect(find.text('2 nœuds sélectionnés'), findsOneWidget);

      await tester.drag(root, const Offset(36, 24));
      await tester.pump();
      expect(
        tester.getTopLeft(root) - tester.getTopLeft(canvas),
        isNot(rootBefore),
      );
      await tester.tap(
        find.byKey(const ValueKey('storylines-graph-reset-layout')),
      );
      await tester.pump();
      expect(
        tester.getTopLeft(root) - tester.getTopLeft(canvas),
        rootBefore,
      );
      expect(project.toJson(), before);
    });

    testWidgets('creates a typed relationship through guided controls',
        (tester) async {
      StorylineProgressionConnectRequest? request;
      await _pumpGraph(
        tester,
        project: _project(),
        onConnectEdge: (value) async {
          request = value;
          return true;
        },
      );

      await tester.tap(
        find.byKey(const ValueKey('storylines-graph-connect-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-graph-connect-relationship'),
        ),
      );
      await tester.pump();
      expect(find.text('Storyline cible'), findsOneWidget);
      expect(find.text('Quête annexe'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('storylines-graph-connect-submit')),
      );
      await tester.pumpAndSettle();

      final result = connectStorylineProgressionEdge(_project(), request!);
      expect(
          result.disposition, StorylineProgressionMutationDisposition.applied);
      expect(
        result.after.storylines
            .singleWhere((storyline) => storyline.id == 'story_main')
            .relationships
            .single
            .kind,
        StorylineRelationshipKind.requires,
      );
    });

    testWidgets('drops a stale selected edge after canonical reload',
        (tester) async {
      final project = _project();
      final edge = buildStorylineProgressionProjection(
        project: project,
        storylineId: 'story_main',
      ).edgesOfKind(StorylineProgressionEdgeKind.outcomeCompletesStep).single;
      await _pumpGraph(tester, project: project);
      final edgeFinder =
          find.byKey(ValueKey('storylines-graph-semantic-edge-${edge.id}'));
      await tester.ensureVisible(edgeFinder);
      await tester.tap(edgeFinder);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('storylines-graph-selected-edge-panel')),
        findsOneWidget,
      );
      final disconnected = disconnectStorylineProgressionEdge(
        project,
        storylineId: 'story_main',
        edgeId: edge.id,
      ).after;

      await _pumpGraph(tester, project: disconnected);

      expect(
        find.byKey(const ValueKey('storylines-graph-selected-edge-panel')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey('storylines-graph-semantic-edge-${edge.id}')),
        findsNothing,
      );
    });

    testWidgets('workspace disconnect is journaled, undoable and reload-safe',
        (tester) async {
      final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('storyline-graph-'),
      ))!;
      addTearDown(() => root.delete(recursive: true));
      final project = _project();
      await tester.runAsync(
        () => File('${root.path}/project.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert(project.toJson()),
          flush: true,
        ),
      );
      final harness = await _pumpWorkspace(
        tester,
        root: root,
        project: project,
      );
      final edge = buildStorylineProgressionProjection(
        project: project,
        storylineId: 'story_main',
      ).edgesOfKind(StorylineProgressionEdgeKind.outcomeCompletesStep).single;
      final edgeFinder =
          find.byKey(ValueKey('storylines-graph-semantic-edge-${edge.id}'));
      await tester.ensureVisible(edgeFinder);
      await tester.tap(edgeFinder);
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('storylines-graph-disconnect-${edge.id}')),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final timeout = Stopwatch()..start();
        while (!harness.notifier.canUndoNarrativeDocument &&
            timeout.elapsed < const Duration(seconds: 5)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();

      expect(
        harness.notifier.canUndoNarrativeDocument,
        isTrue,
        reason: 'status=${harness.notifier.narrativeDocumentStatus} '
            'error=${harness.notifier.state.errorMessage} '
            'message=${harness.notifier.state.statusMessage}',
      );
      expect(
        buildStorylineProgressionProjection(
          project: harness.notifier.state.project!,
          storylineId: 'story_main',
        ).edges.where((candidate) => candidate.id == edge.id),
        isEmpty,
      );

      final undone = await tester.runAsync(
        harness.notifier.undoNarrativeDocument,
      );
      expect(undone, isTrue);
      await tester.pump();
      expect(
        buildStorylineProgressionProjection(
          project: harness.notifier.state.project!,
          storylineId: 'story_main',
        ).edges.where((candidate) => candidate.id == edge.id),
        hasLength(1),
      );
      final diskSource = await tester.runAsync(
        () => File('${root.path}/project.json').readAsString(),
      );
      final disk = ProjectManifest.fromJson(
        jsonDecode(diskSource!) as Map<String, dynamic>,
      );
      expect(disk, project);
    });
  });
}

Future<void> _pumpGraph(
  WidgetTester tester, {
  required ProjectManifest project,
  Future<bool> Function(StorylineProgressionConnectRequest request)?
      onConnectEdge,
  Future<bool> Function(String edgeId)? onDisconnectEdge,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final storyline = project.storylines
      .singleWhere((storyline) => storyline.id == 'story_main');
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SizedBox(
          width: 1400,
          height: 900,
          child: StorylinesGraphView(
            project: project,
            storyline: storyline,
            storylines: project.storylines,
            sideQuestCountOutsideSelected: 1,
            onConnectEdge: onConnectEdge,
            onDisconnectEdge: onDisconnectEdge,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<_WorkspaceHarness> _pumpWorkspace(
  WidgetTester tester, {
  required Directory root,
  required ProjectManifest project,
}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final recoveryStore = _MemoryProjectRecoveryStore();
  final container = ProviderContainer(
    overrides: [
      narrativeProjectDocumentSessionFactoryProvider.overrideWithValue(
        ({
          required String projectPath,
          required ProjectManifest initialDocument,
        }) {
          return NarrativeDocumentSession<ProjectManifest>(
            documentId: 'storyline-graph',
            initialDocument: initialDocument,
            gateway: _MemoryProjectGateway(initialDocument),
            recoveryStore: recoveryStore,
          );
        },
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(editorNotifierProvider, (_, __) {});
  final notifier = container.read(editorNotifierProvider.notifier);
  notifier.state = EditorState(
    projectRootPath: root.path,
    project: project,
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  final initialized = await tester.runAsync(
    notifier.initializeNarrativeDocumentSession,
  );
  if (initialized != true) {
    throw StateError('Narrative document session failed to initialize.');
  }
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
        home: const Scaffold(body: NarrativeWorkspaceCanvas()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _WorkspaceHarness(notifier);
}

final class _WorkspaceHarness {
  const _WorkspaceHarness(this.notifier);

  final EditorNotifier notifier;
}

final class _MemoryProjectGateway
    implements NarrativeDocumentGateway<ProjectManifest> {
  _MemoryProjectGateway(this.document);

  ProjectManifest document;
  String revision = 'revision-A';

  @override
  Future<NarrativeDocumentVersion<ProjectManifest>> read() async {
    return NarrativeDocumentVersion(
      revision: revision,
      document: document,
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<ProjectManifest>> save({
    required String expectedRevision,
    required ProjectManifest before,
    required ProjectManifest after,
    required String operationId,
  }) async {
    if (expectedRevision != revision || before != document) {
      return NarrativeDocumentSaveResult.conflicted(
        code: 'staleRevision',
        message: 'Stale revision.',
        external: NarrativeDocumentVersion(
          revision: revision,
          document: document,
        ),
      );
    }
    document = after;
    revision = 'revision-B';
    return NarrativeDocumentSaveResult.saved(
      NarrativeDocumentVersion(revision: revision, document: document),
    );
  }
}

final class _MemoryProjectRecoveryStore
    implements NarrativeDocumentRecoveryStore<ProjectManifest> {
  NarrativeDocumentRecoveryRecord<ProjectManifest>? record;

  @override
  Future<void> clear() async => record = null;

  @override
  Future<NarrativeDocumentRecoveryRecord<ProjectManifest>?> read() async =>
      record;

  @override
  Future<void> write(
    NarrativeDocumentRecoveryRecord<ProjectManifest> value,
  ) async {
    record = value;
  }
}

ProjectManifest _project() {
  final advanced = ScriptConditionFactory.allOf(<ScriptCondition>[
    ScriptConditionFactory.flagIsSet('fact_started'),
    ScriptConditionFactory.flagIsUnset('fact_locked'),
  ]);
  return ProjectManifest(
    name: 'Graph authoring',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: [
      const ScenarioAsset(
        id: 'scenario_intro',
        name: 'Introduction',
        entryNodeId: 'start',
        declaredOutcomes: ['victory'],
      ),
    ],
    facts: [
      NarrativeFactDefinition(id: 'fact_started', label: 'A commencé'),
      NarrativeFactDefinition(id: 'fact_locked', label: 'Verrouillé'),
    ],
    storylines: [
      StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Histoire principale',
        chapters: [
          StorylineChapter(
            id: 'chapter_intro',
            title: 'Introduction',
            order: 0,
            steps: [
              StorylineStep(
                id: 'step_intro',
                title: 'Arrivée',
                order: 0,
                entryCondition:
                    ScriptConditionFactory.flagIsSet('fact_started'),
              ),
            ],
          ),
          StorylineChapter(
            id: 'chapter_end',
            title: 'Conclusion',
            order: 1,
            steps: [
              StorylineStep(
                id: 'step_end',
                title: 'Résolution',
                order: 0,
                completionCondition: advanced,
              ),
            ],
          ),
        ],
        sceneLinks: [
          StorylineSceneLink(
            id: 'link_intro',
            chapterId: 'chapter_intro',
            stepId: 'step_intro',
            label: 'Introduction',
            state: StorylineSceneLinkState.linkedScenario,
            role: StorylineSceneLinkRole.primary,
            sceneRef: StorylineSceneRef(
              kind: StorylineSceneRefKind.scenario,
              targetId: 'scenario_intro',
            ),
            order: 0,
            outcomeLinks: [
              StorylineSceneOutcomeLink(
                id: 'outcome_win',
                outcomeId: 'victory',
                effects: [
                  StorylineEffect(
                    type: StorylineEffectType.completeStep,
                    targetId: 'step_end',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StorylineAsset(
        id: 'story_side',
        type: StorylineType.sideQuest,
        title: 'Quête annexe',
      ),
    ],
  );
}
