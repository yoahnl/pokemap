import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_model.dart';
import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_view.dart';

void main() {
  group('NS-STORYLINES-SEED-FIX Selbrume graph usability', () {
    test('reads seeded sideQuest relationships and resolves step anchors', () {
      final project = _loadSelbrumeProject();
      final main = _selbrumeMain(project);
      final relationships = _selbrumeAttachmentRelationships(project);

      expect(relationships, hasLength(3));
      expect(
        relationships.map((relationship) => relationship.id),
        containsAll(<String>[
          'relationship_salt_crystals_available_enter_marais',
          'relationship_goelise_port_available_rival_battle',
          'relationship_lighthouse_cabin_available_report_soline',
        ]),
      );

      final anchorTargets = {
        for (final relationship in relationships)
          relationship.id: relationship.availability!.startAnchor.targetId,
      };
      expect(
        anchorTargets,
        containsPair(
          'relationship_salt_crystals_available_enter_marais',
          'step_enter_marais',
        ),
      );
      expect(
        anchorTargets,
        containsPair(
          'relationship_goelise_port_available_rival_battle',
          'step_rival_battle',
        ),
      );
      expect(
        anchorTargets,
        containsPair(
          'relationship_lighthouse_cabin_available_report_soline',
          'step_report_to_soline',
        ),
      );
      for (final targetId in anchorTargets.values) {
        expect(_mainStepIds(main), contains(targetId));
      }

      final model = StorylineGraphViewModel.fromStoryline(
        main,
        storylines: project.storylines,
        sideQuestCountOutsideSelected: 3,
      );

      expect(model.sideQuestAttachments, hasLength(3));
      expect(
        _attachmentBySideQuest(model, 'story_side_salt_crystals').chapterId,
        'chapter_2_marais',
      );
      expect(
        _attachmentBySideQuest(model, 'story_side_goelise_port').chapterId,
        'chapter_1_port',
      );
      expect(
        _attachmentBySideQuest(model, 'story_side_lighthouse_cabin').chapterId,
        'chapter_2_marais',
      );
      expect(
        model.sideQuestAttachments
            .map((attachment) => attachment.anchorKind)
            .toSet(),
        {StorylineAnchorKind.step},
      );
      expect(
        model.nodes
            .where((node) => node.kind == StorylineGraphNodeKind.sideQuest),
        hasLength(3),
      );
      expect(
        model.edges.where(
          (edge) => edge.kind == StorylineGraphEdgeKind.sideQuestAttachment,
        ),
        hasLength(3),
      );
    });

    testWidgets(
      'renders sideQuest nodes outside chapter cards on a larger canvas',
      (tester) async {
        final project = _loadSelbrumeProject();
        await _pumpGraph(tester, project);

        final canvas = find.byKey(const ValueKey('storylines-graph-canvas'));
        expect(canvas, findsOneWidget);
        expect(tester.getSize(canvas).height, greaterThanOrEqualTo(760));

        final portChapter = find.byKey(
            const ValueKey('storylines-graph-node-chapter-chapter_1_port'));
        final maraisChapter = find.byKey(
          const ValueKey('storylines-graph-node-chapter-chapter_2_marais'),
        );
        final saltNode = find.byKey(
          const ValueKey(
              'storylines-graph-node-sidequest-story_side_salt_crystals'),
        );
        final goeliseNode = find.byKey(
          const ValueKey(
              'storylines-graph-node-sidequest-story_side_goelise_port'),
        );
        final cabinNode = find.byKey(
          const ValueKey(
              'storylines-graph-node-sidequest-story_side_lighthouse_cabin'),
        );

        expect(portChapter, findsOneWidget);
        expect(maraisChapter, findsOneWidget);
        expect(saltNode, findsOneWidget);
        expect(goeliseNode, findsOneWidget);
        expect(cabinNode, findsOneWidget);
        expect(
            tester.getRect(goeliseNode).overlaps(tester.getRect(portChapter)),
            isFalse);
        expect(tester.getRect(saltNode).overlaps(tester.getRect(maraisChapter)),
            isFalse);
        expect(
            tester.getRect(cabinNode).overlaps(tester.getRect(maraisChapter)),
            isFalse);

        expect(
          find.byKey(
            const ValueKey(
                'storylines-graph-sidequest-caption-chapter_2_marais'),
          ),
          findsNothing,
        );
        expect(find.textContaining('2 quêtes disponibles'), findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-graph-steps-overflow')),
            findsWidgets);
        expect(
          find.byKey(
            const ValueKey(
              'storylines-graph-edge-sidequest-relationship_salt_crystals_available_enter_marais',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'storylines-graph-edge-sidequest-relationship_goelise_port_available_rival_battle',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'storylines-graph-edge-sidequest-relationship_lighthouse_cabin_available_report_soline',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('graph rendering does not mutate ProjectManifest or seed file',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();
      final before = project.toJson();

      await _pumpGraph(tester, project);
      await tester.tap(find.byKey(const ValueKey('storylines-graph-canvas')));
      await tester.pump();

      expect(project.toJson(), before);
      expect(seedFile.readAsStringSync(), seedBefore);
      expect(_selbrumeMain(project).sceneLinks, isEmpty);
      expect(_selbrumeAttachmentRelationships(project), hasLength(3));
    });

    testWidgets('full Storylines shell prioritizes Graph canvas',
        (tester) async {
      final project = _loadSelbrumeProject();
      await _pumpStorylinesShell(tester, project: project);

      final canvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      final panel = find.byKey(const ValueKey('storylines-main-panel'));
      expect(canvas, findsOneWidget);
      expect(panel, findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-header-section-compact')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-kpi-strip-compact')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-graph-toolbar')),
          findsOneWidget);
      expect(
        tester.getSize(canvas).height / tester.getSize(panel).height,
        greaterThanOrEqualTo(0.62),
      );
    });

    testWidgets('Graph and Structure switching stays non-mutating',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();
      final before = project.toJson();

      await _pumpStorylinesShell(tester, project: project);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-tabs')),
          matching: find.text('Structure'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chapitres'), findsWidgets);
      expect(find.text('Étapes narratives'), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-tabs')),
          matching: find.text('Graph'),
        ),
      );
      await tester.pumpAndSettle();

      expect(project.toJson(), before);
      expect(seedFile.readAsStringSync(), seedBefore);
      expect(_selbrumeAttachmentRelationships(project), hasLength(3));
      expect(_selbrumeMain(project).sceneLinks, isEmpty);
    });

    testWidgets('writes seed fix bis visual gate screenshots', (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_seed_fix_01_bis_graph_full_layout.png',
        ),
      );

      await _pumpGraph(tester, project);
      await expectLater(
        find.byKey(const ValueKey('storylines-graph-canvas')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_seed_fix_01_bis_graph_focus_canvas.png',
        ),
      );

      await _pumpStorylinesShell(tester, project: project);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-tabs')),
          matching: find.text('Structure'),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_seed_fix_01_bis_structure_regression.png',
        ),
      );
    });
  });
}

Future<void> _pumpGraph(
  WidgetTester tester,
  ProjectManifest project,
) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final main = _selbrumeMain(project);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SizedBox(
          width: 1600,
          height: 1000,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StorylinesGraphView(
              storyline: main,
              storylines: project.storylines,
              sideQuestCountOutsideSelected: 3,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpStorylinesShell(
  WidgetTester tester, {
  required ProjectManifest project,
}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
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
            width: 1600,
            height: 1000,
            child: NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

ProjectManifest _loadSelbrumeProject() {
  final file = _selbrumeProjectFile();
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return ProjectManifest.fromJson(json);
}

File _selbrumeProjectFile() {
  final file = File('../../selbrume/project.json');
  if (!file.existsSync()) {
    throw StateError('Missing Selbrume project fixture at ${file.path}');
  }
  return file;
}

StorylineAsset _selbrumeMain(ProjectManifest project) {
  return project.storylines.singleWhere(
    (storyline) => storyline.id == 'story_main_brume_phare',
  );
}

List<StorylineRelationship> _selbrumeAttachmentRelationships(
  ProjectManifest project,
) {
  return [
    for (final storyline in project.storylines)
      for (final relationship in storyline.relationships)
        if (relationship.kind ==
                StorylineRelationshipKind.sideQuestAvailableDuring &&
            relationship.targetStorylineId == 'story_main_brume_phare')
          relationship,
  ];
}

Set<String> _mainStepIds(StorylineAsset main) {
  return {
    for (final chapter in main.chapters)
      for (final step in chapter.steps) step.id,
  };
}

StorylineGraphSideQuestAttachment _attachmentBySideQuest(
  StorylineGraphViewModel model,
  String sideQuestId,
) {
  return model.sideQuestAttachments.singleWhere(
    (attachment) => attachment.sideQuestId == sideQuestId,
  );
}
