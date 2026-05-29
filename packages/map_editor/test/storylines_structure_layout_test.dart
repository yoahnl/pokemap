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
  group('NS-STORYLINES-V1.1-00 Structure layout readability', () {
    testWidgets(
        'Structure shows expanded selected chapter and collapsed others',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);

      expect(find.byKey(const ValueKey('storylines-structure-view')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-action-bar')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-chapters-zone')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-selected-chapter-expanded')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-collapsed-chapters')),
          findsOneWidget);
      expect(find.text('Détail du chapitre'), findsOneWidget);
      expect(find.text('Nouveau chapitre'), findsOneWidget);
      expect(find.text('Nouvelle étape narrative'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-v1-structure-steps')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-v1-structure-scenes')),
          findsOneWidget);

      expect(
          find.byKey(const ValueKey('storylines-step-row-step_intro_selbrume')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-step-row-step_enter_marais')),
          findsNothing);
      expect(find.textContaining('Aucune scène liée'), findsWidgets);
    });

    testWidgets('collapsed chapter selection changes focus without mutation',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();
      final before = project.toJson();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('storylines-chapter-row-chapter_2_marais')),
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

    testWidgets('writes V1.1-00 Structure visual gate screenshots',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_1_00_structure_full_layout.png',
        ),
      );

      await expectLater(
        find.byKey(const ValueKey('storylines-selected-chapter-expanded')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_1_00_structure_selected_chapter.png',
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
        find.byKey(const ValueKey('storylines-selected-chapter-expanded')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_1_00_structure_created_step.png',
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
          'ns_storylines_v1_1_00_graph_regression.png',
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
