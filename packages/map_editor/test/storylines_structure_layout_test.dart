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

void main() {
  group('NS-STORYLINES Structure full-width accordion authoring', () {
    testWidgets('Structure uses a full-width vertical chapter accordion',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);

      expect(find.byKey(const ValueKey('storylines-structure-view')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-header-section-compact')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-kpi-strip-compact')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-toolbar')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-accordion-list')),
          findsOneWidget);
      expect(
          tester
              .getSize(
                find.byKey(
                  const ValueKey('storylines-structure-accordion-list'),
                ),
              )
              .width,
          greaterThan(760));
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-accordion-chapter_1_port'),
          ),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-chapter-native-panel-list')),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-accordion-chapter_2_marais'),
          ),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-expanded-chapter_1_port'),
          ),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-collapsed-chapter_2_marais'),
          ),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-search-action')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-filter-action')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-sort-action')),
          findsOneWidget);
      expect(find.text('Nouveau chapitre'), findsOneWidget);
      expect(find.text('Nouvelle étape narrative'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-v1-structure-steps')),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-delete-chapter-action-chapter_1_port'),
          ),
          findsNothing);
      expect(
          find.byKey(
            const ValueKey('storylines-delete-step-action-step_intro_selbrume'),
          ),
          findsNothing);

      expect(
          find.byKey(const ValueKey('storylines-step-row-step_intro_selbrume')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-step-row-step_enter_marais')),
          findsNothing);
      expect(find.textContaining('Aucune scène liée'), findsNothing);
      expect(find.text('1 scène liée'), findsAtLeastNWidgets(2));
      expect(find.text('2 scènes liées'), findsAtLeastNWidgets(1));
      expect(find.text('3 scènes liées'), findsAtLeastNWidgets(1));
    });

    testWidgets('accordion chapter selection opens another without mutation',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();
      final before = project.toJson();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await tester.ensureVisible(
        find.byKey(
          const ValueKey('storylines-chapter-toggle-chapter_2_marais'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-chapter-toggle-chapter_2_marais'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('storylines-step-row-step_enter_marais')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-step-row-step_intro_selbrume')),
          findsNothing);
      expect(find.text('DÉTAILS DU CHAPITRE'), findsOneWidget);
      expect(project.toJson(), before);
      expect(seedFile.readAsStringSync(), seedBefore);
    });

    testWidgets('native chapter accordion can close the open chapter',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);

      expect(
          find.byKey(
            const ValueKey('storylines-chapter-expanded-chapter_1_port'),
          ),
          findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('storylines-chapter-toggle-chapter_1_port'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-v1-structure-steps')),
          findsNothing);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-collapsed-chapter_1_port'),
          ),
          findsOneWidget);
    });

    testWidgets('chapter edit mutates and referenced delete stays protected',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();

      final container = await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-chapter-action-chapter_1_port'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-edit-chapter-title-field')),
        'Port révisé',
      );
      await tester.enterText(
        find.byKey(
          const ValueKey('storylines-edit-chapter-description-field'),
        ),
        'Chapitre ajusté depuis la vue Structure.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('storylines-chapter-notes-field')),
        'Validation auteur du chapitre.',
      );
      final activeStatus = find.byKey(
        const ValueKey('storylines-chapter-status-active'),
      );
      await tester.ensureVisible(activeStatus);
      await tester.tap(activeStatus);
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('storylines-edit-chapter-submit')));
      await tester.pumpAndSettle();

      var updatedProject = container.read(editorNotifierProvider).project!;
      var main = _selbrumeMain(updatedProject);
      expect(main.chapters.first.title, 'Port révisé');
      expect(
        main.chapters.first.description,
        'Chapitre ajusté depuis la vue Structure.',
      );
      expect(main.chapters.first.status, StorylineStatus.active);
      expect(
        main.chapters.first.authorNotes,
        'Validation auteur du chapitre.',
      );

      await tester.ensureVisible(
        find.byKey(
          const ValueKey('storylines-edit-chapter-action-chapter_4_epilogue'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-chapter-action-chapter_4_epilogue'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('storylines-edit-chapter-delete-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('storylines-confirm-delete-submit')),
      );
      await tester.pumpAndSettle();

      updatedProject = container.read(editorNotifierProvider).project!;
      main = _selbrumeMain(updatedProject);
      expect(
        main.chapters.map((chapter) => chapter.id),
        contains('chapter_4_epilogue'),
      );
      expect(find.text('Modification impossible'), findsOneWidget);
      expect(find.textContaining('Consommateurs'), findsOneWidget);
      expect(seedFile.readAsStringSync(), seedBefore);
    });

    testWidgets(
        'step edit drag reorder and referenced delete preserve integrity',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();

      final container = await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);

      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-step-action-step_intro_selbrume'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-edit-step-title-field')),
        'Introduction révisée',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('storylines-edit-step-submit')));
      await tester.pumpAndSettle();

      var updatedProject = container.read(editorNotifierProvider).project!;
      var main = _selbrumeMain(updatedProject);
      expect(main.chapters.first.steps.first.title, 'Introduction révisée');

      await tester.ensureVisible(
        find.byKey(
          const ValueKey('storylines-step-drag-step_receive_mission'),
        ),
      );
      await tester.drag(
        find.byKey(
          const ValueKey('storylines-step-drag-step_receive_mission'),
        ),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();

      updatedProject = container.read(editorNotifierProvider).project!;
      main = _selbrumeMain(updatedProject);
      expect(main.chapters.first.steps.first.id, 'step_receive_mission');
      expect(main.chapters.first.steps.first.order, 0);
      expect(main.chapters.first.steps[1].id, 'step_intro_selbrume');
      expect(main.chapters.first.steps[1].order, 1);

      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-step-action-step_go_to_port'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('storylines-edit-step-delete-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('storylines-confirm-delete-submit')),
      );
      await tester.pumpAndSettle();

      updatedProject = container.read(editorNotifierProvider).project!;
      main = _selbrumeMain(updatedProject);
      expect(
        main.chapters.first.steps.map((step) => step.id),
        contains('step_go_to_port'),
      );
      expect(find.text('Modification impossible'), findsOneWidget);
      expect(find.textContaining('Consommateurs'), findsOneWidget);
      expect(main.chapters[1].steps.map((step) => step.id),
          contains('step_enter_marais'));
      expect(seedFile.readAsStringSync(), seedBefore);
    });

    testWidgets('duplicates and reorders Chapters through domain operations',
        (tester) async {
      final container = await _pumpStorylinesShell(
        tester,
        project: _loadSelbrumeProject(),
      );
      await _openStructureTab(tester);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'storylines-duplicate-chapter-action-chapter_1_port',
          ),
        ),
      );
      await tester.pumpAndSettle();

      var main = _selbrumeMain(container.read(editorNotifierProvider).project!);
      expect(main.chapters, hasLength(5));
      final duplicate = main.chapters.last;
      expect(duplicate.title, contains('(copie)'));
      expect(duplicate.steps, hasLength(main.chapters.first.steps.length));
      expect(
        duplicate.steps.map((step) => step.id).toSet().intersection(
              main.chapters.first.steps.map((step) => step.id).toSet(),
            ),
        isEmpty,
      );

      await tester.ensureVisible(
        find.byKey(
          const ValueKey('storylines-move-chapter-down-chapter_1_port'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-move-chapter-down-chapter_1_port'),
        ),
      );
      await tester.pumpAndSettle();

      main = _selbrumeMain(container.read(editorNotifierProvider).project!);
      expect(main.chapters[1].id, 'chapter_1_port');
      expect(main.chapters.map((chapter) => chapter.order), [0, 1, 2, 3, 4]);
    });

    testWidgets('duplicates and moves a Step between Chapters', (tester) async {
      final container = await _pumpStorylinesShell(
        tester,
        project: _loadSelbrumeProject(),
      );
      await _openStructureTab(tester);

      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-step-action-step_intro_selbrume'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-step-duplicate-action'),
        ),
      );
      await tester.pumpAndSettle();

      var main = _selbrumeMain(container.read(editorNotifierProvider).project!);
      expect(main.chapters.first.steps, hasLength(5));
      expect(main.chapters.first.steps.last.title, contains('(copie)'));

      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-step-action-step_intro_selbrume'),
        ),
      );
      await tester.pumpAndSettle();
      final targetChapter = find.byKey(
        const ValueKey('storylines-step-target-chapter-chapter_2_marais'),
      );
      await tester.ensureVisible(targetChapter);
      await tester.tap(targetChapter);
      await tester.tap(
        find.byKey(const ValueKey('storylines-edit-step-submit')),
      );
      await tester.pumpAndSettle();

      main = _selbrumeMain(container.read(editorNotifierProvider).project!);
      expect(
        main.chapters.first.steps.map((step) => step.id),
        isNot(contains('step_intro_selbrume')),
      );
      expect(
        main.chapters[1].steps.last.id,
        'step_intro_selbrume',
      );
    });

    testWidgets('existing step creation flow remains wired in Structure',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();

      final container = await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await tester
          .tap(find.byKey(const ValueKey('storylines-new-step-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-step-title-field')),
        'Note de structure',
      );
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-step-description-field')),
        'Step créée par le flow auteur existant.',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('storylines-create-step-submit')));
      await tester.pumpAndSettle();

      final updatedProject = container.read(editorNotifierProvider).project!;
      final main = _selbrumeMain(updatedProject);
      final firstChapter = main.chapters.first;
      expect(firstChapter.steps.last.id, 'step_note_de_structure');
      expect(firstChapter.steps.last.order, 4);
      expect(
          find.byKey(
              const ValueKey('storylines-step-row-step_note_de_structure')),
          findsOneWidget);
      expect(seedFile.readAsStringSync(), seedBefore);
    });

    testWidgets('Graph remains accessible with independent sideQuest nodes',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);

      expect(find.byKey(const ValueKey('storylines-graph-canvas')),
          findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'storylines-graph-node-sidequest-story_side_salt_crystals',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'storylines-graph-edge-sidequest-relationship_salt_crystals_available_enter_marais',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('writes Structure accordion bis visual gate screenshots',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_full_width_accordion.png',
        ),
      );

      await expectLater(
        find.byKey(
          const ValueKey('storylines-chapter-expanded-chapter_1_port'),
        ),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_expanded_chapter_steps.png',
        ),
      );

      await expectLater(
        find.byKey(
          const ValueKey('storylines-chapter-collapsed-chapter_2_marais'),
        ),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_collapsed_chapter.png',
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('storylines-new-step-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-step-title-field')),
        'Point de lecture',
      );
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-step-description-field')),
        'Capture de régression Structure.',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('storylines-create-step-submit')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(
          const ValueKey('storylines-chapter-expanded-chapter_1_port'),
        ),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_authoring_actions.png',
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-tabs')),
          matching: find.text('Graph'),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_graph_regression.png',
        ),
      );
    });
  });
}

Future<ProviderContainer> _pumpStorylinesShell(
  WidgetTester tester, {
  required ProjectManifest project,
}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, _) {},
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
  return container;
}

Future<void> _openStructureTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Structure'),
    ),
  );
  await tester.pumpAndSettle();
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
