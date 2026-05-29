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
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('NS-STORYLINES-V1-12 visual graph enrichment', () {
    testWidgets('shows only Graph and Structure tabs', (tester) async {
      await _pumpStorylinesShell(tester);

      final tabs = find.byKey(const ValueKey('storylines-tabs'));
      expect(find.descendant(of: tabs, matching: find.text('Graph')),
          findsOneWidget);
      expect(find.descendant(of: tabs, matching: find.text('Structure')),
          findsOneWidget);
      expect(find.descendant(of: tabs, matching: find.text('Étapes')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Scènes')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Statistiques')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Tests')),
          findsNothing);
    });

    testWidgets('shows V1 empty state without importing legacy globalStory',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _legacyOnlyProject(),
      );

      expect(find.text('Aucune storyline auteur'), findsWidgets);
      expect(find.byKey(const ValueKey('storylines-create-main-cta')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-graph-canvas')), findsNothing);
      expect(
          find.byKey(const ValueKey('storylines-graph-node-chapter-anything')),
          findsNothing);
      expect(find.textContaining('ne sera pas importée automatiquement'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-v1-legacy-preview-card')),
          findsOneWidget);
      expect(find.text('Legacy Global Story'), findsWidgets);
      expect(harness.project.storylines, isEmpty);
      expect(harness.project.scenarios.single.scope, ScenarioScope.globalStory);
    });

    testWidgets(
        'opens and cancels create main storyline dialog without mutation',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);
      final before = harness.project.toJson();

      await _openCreateDialog(tester);
      expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
          findsOneWidget);
      expect(find.text('Histoire principale'), findsOneWidget);
      expect(find.text('Quête annexe'), findsOneWidget);
      expect(
        find.text(
          'Créez d’abord une histoire principale pour organiser les quêtes annexes.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sélectionné'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-title-field')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-description-field')),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
          findsNothing);
      expect(harness.project.storylines, isEmpty);
      expect(harness.project.toJson(), before);
    });

    testWidgets('requires title before create', (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _openCreateDialog(tester);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-submit')),
      );
      expect(submit.onPressed, isNull);
      expect(find.text('Titre obligatoire.'), findsOneWidget);
      expect(harness.project.storylines, isEmpty);
    });

    testWidgets('does not create sideQuest before a main storyline exists',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _openCreateDialog(tester);
      await tester
          .tap(find.byKey(const ValueKey('storylines-create-type-sidequest')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-title-field')),
        'Early side quest',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
      await tester.pumpAndSettle();

      expect(harness.project.storylines, hasLength(1));
      expect(harness.project.storylines.single.type, StorylineType.main);
      expect(
        harness.project.storylines
            .where((storyline) => storyline.type == StorylineType.sideQuest),
        isEmpty,
      );
    });

    testWidgets('dialog selects sideQuest when a main storyline exists',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();

      await _openCreateDialog(tester);

      final dialog =
          find.byKey(const ValueKey('storylines-create-main-dialog'));
      expect(find.text('Une histoire principale existe déjà.'), findsWidgets);
      expect(
        find.descendant(of: dialog, matching: find.text('Quête annexe')),
        findsOneWidget,
      );
      expect(find.text('Sélectionné'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-title-field')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-description-field')),
          findsOneWidget);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-submit')),
      );
      expect(submit.onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
      await tester.pumpAndSettle();
      expect(harness.project.toJson(), before);
    });

    testWidgets('creates a main StorylineAsset and syncs Graph and Structure',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(
        tester,
        title: 'Ma grande histoire',
        description: 'Une structure auteur propre.',
      );

      final storylines = harness.project.storylines;
      expect(storylines, hasLength(1));
      final storyline = storylines.single;
      expect(storyline.id, 'storyline_ma_grande_histoire');
      expect(storyline.type, StorylineType.main);
      expect(storyline.status, StorylineStatus.draft);
      expect(storyline.title, 'Ma grande histoire');
      expect(storyline.description, 'Une structure auteur propre.');
      expect(storyline.chapters, isEmpty);
      expect(storyline.sceneLinks, isEmpty);
      expect(storyline.relationships, isEmpty);

      expect(find.text('Ma grande histoire'), findsWidgets);
      expect(
        find.text('Ajoutez un chapitre dans Structure'),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'storylines-graph-node-storyline-storyline_ma_grande_histoire',
          ),
        ),
        findsOneWidget,
      );

      await _openStructureTab(tester);
      expect(find.byKey(const ValueKey('storylines-structure-read-only')),
          findsOneWidget);
      expect(find.text('Chapitres'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-v1-structure-steps')),
          matching: find.text('Étapes narratives'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-v1-structure-scenes')),
          matching: find.text('Scènes liées'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('storylines-new-chapter-action')),
          findsOneWidget);
      expect(find.text('Nouveau chapitre'), findsOneWidget);
    });

    testWidgets('creates a sideQuest StorylineAsset and selects it',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(
        tester,
        title: 'Missing Bell',
        description: 'Optional story arc.',
      );

      final storylines = harness.project.storylines;
      expect(storylines, hasLength(2));
      final sideQuest = storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.sideQuest,
      );
      expect(sideQuest.id, 'sidequest_missing_bell');
      expect(sideQuest.status, StorylineStatus.draft);
      expect(sideQuest.title, 'Missing Bell');
      expect(sideQuest.description, 'Optional story arc.');
      expect(sideQuest.chapters, isEmpty);
      expect(sideQuest.sceneLinks, isEmpty);
      expect(sideQuest.relationships, isEmpty);

      expect(find.text('Missing Bell'), findsWidgets);
      expect(find.text('Quête annexe'), findsWidgets);
      expect(find.text('HISTOIRE PRINCIPALE'), findsOneWidget);
      expect(find.text('QUÊTES ANNEXES'), findsOneWidget);
      expect(find.text('Non reliée au graph principal'), findsWidgets);
      expect(find.byKey(const ValueKey('storylines-structure-read-only')),
          findsOneWidget);
    });

    testWidgets('Structure without storyline has no chapter or step action',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);
      final before = harness.project.toJson();

      await _openStructureTab(tester);

      expect(find.text('Créez une storyline pour commencer.'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-new-chapter-action')),
          findsNothing);
      expect(find.byKey(const ValueKey('storylines-new-step-action')),
          findsNothing);
      expect(harness.project.toJson(), before);
    });

    testWidgets('opens and cancels create chapter without mutation',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();

      await _openCreateChapterDialog(tester);
      expect(find.byKey(const ValueKey('storylines-create-chapter-dialog')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-create-chapter-title-field')),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-create-chapter-description-field'),
          ),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('storylines-create-chapter-cancel')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-create-chapter-dialog')),
          findsNothing);
      expect(harness.project.toJson(), before);
    });

    testWidgets('requires chapter title before create', (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _openCreateChapterDialog(tester);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-chapter-submit')),
      );
      expect(submit.onPressed, isNull);
      expect(find.text('Titre obligatoire.'), findsOneWidget);
      expect(harness.project.storylines.single.chapters, isEmpty);
    });

    testWidgets('creates chapters with stable ids, order and selection',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createChapter(
        tester,
        title: 'Intro',
        description: 'Premier arc auteur.',
      );
      await _createChapter(tester, title: 'Intro');

      final chapters = harness.project.storylines.single.chapters;
      expect(chapters, hasLength(2));
      expect(chapters.map((chapter) => chapter.id), [
        'chapter_intro',
        'chapter_intro_2',
      ]);
      expect(chapters.map((chapter) => chapter.order), [0, 1]);
      expect(chapters.first.title, 'Intro');
      expect(chapters.first.description, 'Premier arc auteur.');
      expect(chapters.first.steps, isEmpty);
      expect(find.byKey(const ValueKey('storylines-chapter-row-chapter_intro')),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-row-chapter_intro_2'),
          ),
          findsOneWidget);
      expect(find.text('Détail du chapitre'), findsOneWidget);
    });

    testWidgets('step action requires a selected chapter', (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();

      await _openStructureTab(tester);

      expect(find.byKey(const ValueKey('storylines-new-step-action')),
          findsNothing);
      expect(harness.project.toJson(), before);
    });

    testWidgets('opens and cancels create step without mutation',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
            chapters: [
              StorylineChapter(
                id: 'chapter_intro',
                title: 'Intro',
                order: 0,
              ),
            ],
          ),
        ]),
      );
      final before = harness.project.toJson();

      await _openCreateStepDialog(tester);
      expect(find.byKey(const ValueKey('storylines-create-step-dialog')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('storylines-create-step-cancel')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-create-step-dialog')),
          findsNothing);
      expect(harness.project.toJson(), before);
    });

    testWidgets('requires step title before create', (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
            chapters: [
              StorylineChapter(
                id: 'chapter_intro',
                title: 'Intro',
                order: 0,
              ),
            ],
          ),
        ]),
      );

      await _openCreateStepDialog(tester);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-step-submit')),
      );
      expect(submit.onPressed, isNull);
      expect(find.text('Titre obligatoire.'), findsOneWidget);
      expect(harness.project.storylines.single.chapters.single.steps, isEmpty);
    });

    testWidgets('creates steps with global unique ids and order',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createChapter(tester, title: 'Intro');
      await _createStep(
        tester,
        title: 'Premier jalon',
        description: 'Définir la progression.',
      );
      await _createStep(tester, title: 'Premier jalon');
      await _createChapter(tester, title: 'Second arc');
      await _createStep(tester, title: 'Premier jalon');

      final chapters = harness.project.storylines.single.chapters;
      final allSteps = [
        for (final chapter in chapters) ...chapter.steps,
      ];
      expect(allSteps.map((step) => step.id), [
        'step_premier_jalon',
        'step_premier_jalon_2',
        'step_premier_jalon_3',
      ]);
      expect(chapters.first.steps.map((step) => step.order), [0, 1]);
      expect(chapters.last.steps.single.order, 0);
      expect(chapters.first.steps.first.title, 'Premier jalon');
      expect(chapters.first.steps.first.description, 'Définir la progression.');
      expect(chapters.first.steps.first.sceneLinkIds, isEmpty);
      expect(chapters.first.steps.first.expectedOutcomeIds, isEmpty);
      expect(
          find.byKey(
            const ValueKey('storylines-step-row-step_premier_jalon_3'),
          ),
          findsOneWidget);
    });

    testWidgets('Structure authoring works on sideQuest without mutating main',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(tester, title: 'Missing Bell');
      await _createChapter(tester, title: 'Side intro');
      await _createStep(tester, title: 'Find clue');

      final main = harness.project.storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.main,
      );
      final sideQuest = harness.project.storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.sideQuest,
      );
      expect(main.chapters, isEmpty);
      expect(sideQuest.chapters, hasLength(1));
      expect(sideQuest.chapters.single.id, 'chapter_side_intro');
      expect(sideQuest.chapters.single.steps, hasLength(1));
      expect(sideQuest.chapters.single.steps.single.id, 'step_find_clue');
      expect(sideQuest.chapters.single.steps.single.sceneLinkIds, isEmpty);
      expect(sideQuest.sceneLinks, isEmpty);
      expect(sideQuest.relationships, isEmpty);
      expect(find.text('Missing Bell'), findsWidgets);
      expect(find.byKey(const ValueKey('storylines-step-row-step_find_clue')),
          findsOneWidget);
    });

    testWidgets('Graph summarizes created structure without fake edges',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createChapter(tester, title: 'Intro');
      await _createStep(tester, title: 'Premier jalon');
      await _openGraphTab(tester);

      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey(
              'storylines-graph-node-storyline-storyline_existing_main',
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey('storylines-graph-node-chapter-chapter_intro'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey('storylines-graph-node-step-step_premier_jalon'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('storylines-graph-edge-root-chapter_intro')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('storylines-graph-legend-author-order')),
        findsOneWidget,
      );
      expect(find.text('Ordre auteur'), findsOneWidget);
      expect(find.text('Aucune scène liée'), findsOneWidget);
      expect(find.text('Ajoutez un chapitre dans Structure'), findsNothing);
      expect(find.text('Quête annexe fake'), findsNothing);
    });

    testWidgets('Graph orders chapters and steps by author order',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_ordered_main',
            type: StorylineType.main,
            title: 'Ordered main',
            chapters: [
              StorylineChapter(
                id: 'chapter_second',
                title: 'Second',
                order: 2,
              ),
              StorylineChapter(
                id: 'chapter_tie_b',
                title: 'Tie B',
                order: 1,
              ),
              StorylineChapter(
                id: 'chapter_first',
                title: 'First',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step_second',
                    title: 'Second step',
                    order: 2,
                  ),
                  StorylineStep(
                    id: 'step_first',
                    title: 'First step',
                    order: 0,
                    sceneLinkIds: const ['scenario_scene_ref'],
                  ),
                ],
              ),
              StorylineChapter(
                id: 'chapter_tie_a',
                title: 'Tie A',
                order: 1,
              ),
            ],
          ),
        ]),
      );

      await _openGraphTab(tester);

      final firstX = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('storylines-graph-node-chapter-chapter_first'),
            ),
          )
          .dx;
      final tieAX = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('storylines-graph-node-chapter-chapter_tie_a'),
            ),
          )
          .dx;
      final tieBX = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('storylines-graph-node-chapter-chapter_tie_b'),
            ),
          )
          .dx;
      final secondX = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('storylines-graph-node-chapter-chapter_second'),
            ),
          )
          .dx;
      expect(firstX, lessThan(tieAX));
      expect(tieAX, lessThan(tieBX));
      expect(tieBX, lessThan(secondX));

      final firstStepY = tester
          .getTopLeft(
            find.byKey(const ValueKey('storylines-graph-node-step-step_first')),
          )
          .dy;
      final secondStepY = tester
          .getTopLeft(
            find.byKey(
                const ValueKey('storylines-graph-node-step-step_second')),
          )
          .dy;
      expect(firstStepY, lessThan(secondStepY));
      expect(find.text('1 scène liée'), findsOneWidget);
    });

    testWidgets('Graph explains sideQuest is not linked to main graph yet',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(tester, title: 'Missing Bell');
      await _createChapter(tester, title: 'Side intro');
      await _createStep(tester, title: 'Find clue');
      await _openGraphTab(tester);

      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Missing Bell')),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: graphCanvas, matching: find.text('1 chapitre · 1 étape')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey('storylines-graph-node-chapter-chapter_side_intro'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey('storylines-graph-node-step-step_find_clue'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Quête annexe indépendante'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Existing main')),
        findsNothing,
      );
      expect(find.textContaining('availability'), findsNothing);
    });

    testWidgets('main graph does not show sideQuest as a branch yet',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(tester, title: 'Missing Bell');
      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-storyline_existing_main')),
      );
      await tester.pump();
      await _openGraphTab(tester);

      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Existing main')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Missing Bell')),
        findsNothing,
      );
      expect(
        find.text(
          'Quêtes annexes créées : 1 — attachement explicite requis',
        ),
        findsOneWidget,
      );
    });

    testWidgets('attaches sideQuest to an explicit main step anchor',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(tester, title: 'Main Path');
      await _createChapter(tester, title: 'Opening');
      await _createStep(tester, title: 'Signal');
      await _createSideQuest(tester, title: 'Lost Charm');

      final beforeScenarios = harness.project.scenarios;
      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('storylines-attach-sidequest-action')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-attach-sidequest-dialog')),
          findsOneWidget);
      expect(find.text('Attacher la quête annexe'), findsOneWidget);
      expect(find.text('Main Path'), findsWidgets);
      expect(find.text('Chapitre · Opening'), findsOneWidget);
      expect(find.text('Étape · Signal'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('storylines-attach-anchor-step-step_signal')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('storylines-attach-submit')));
      await tester.pumpAndSettle();

      final main = harness.project.storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.main,
      );
      final sideQuest = harness.project.storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.sideQuest,
      );
      expect(main.relationships, isEmpty);
      expect(sideQuest.relationships, hasLength(1));
      final relationship = sideQuest.relationships.single;
      expect(relationship.kind,
          StorylineRelationshipKind.sideQuestAvailableDuring);
      expect(relationship.sourceStorylineId, sideQuest.id);
      expect(relationship.targetStorylineId, main.id);
      expect(relationship.anchor?.kind, StorylineAnchorKind.step);
      expect(relationship.anchor?.targetId, 'step_signal');
      expect(relationship.availability?.startAnchor.kind,
          StorylineAnchorKind.step);
      expect(relationship.availability?.startAnchor.targetId, 'step_signal');
      expect(sideQuest.sceneLinks, isEmpty);
      expect(harness.project.scenarios, beforeScenarios);
      expect(find.text('Reliée au graph principal'), findsWidgets);
    });

    testWidgets('attached sideQuest appears in main graph from relation only',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(tester, title: 'Main Path');
      await _createChapter(tester, title: 'Opening');
      await _createStep(tester, title: 'Signal');
      await _createSideQuest(tester, title: 'Lost Charm');
      await _attachSideQuestToAnchor(
        tester,
        anchorKey: 'storylines-attach-anchor-step-step_signal',
      );

      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-storyline_main_path')),
      );
      await tester.pump();
      await _openGraphTab(tester);

      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Main Path')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Lost Charm')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey(
                'storylines-graph-node-sidequest-sidequest_lost_charm'),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Quêtes annexes attachées : 1'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'storylines-graph-legend-sidequest-availability',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Disponibilité quête annexe'), findsOneWidget);
      expect(find.textContaining('Disponible depuis Étape · Signal'),
          findsOneWidget);
      expect(find.textContaining('Quête annexe · 0 chapitres · 0 étapes'),
          findsOneWidget);
      expect(
        find.byKey(
          ValueKey(
            'storylines-graph-edge-sidequest-'
            '${harness.project.storylines.singleWhere((s) => s.type == StorylineType.sideQuest).relationships.single.id}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        harness.project.storylines
            .singleWhere((s) => s.type == StorylineType.sideQuest)
            .relationships,
        hasLength(1),
      );
    });

    testWidgets('canceling sideQuest attachment does not mutate project',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(tester, title: 'Main Path');
      await _createChapter(tester, title: 'Opening');
      await _createSideQuest(tester, title: 'Lost Charm');
      final before = harness.project.toJson();

      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('storylines-attach-sidequest-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('storylines-attach-cancel')));
      await tester.pumpAndSettle();

      expect(harness.project.toJson(), before);
      expect(
        harness.project.storylines
            .singleWhere((s) => s.type == StorylineType.sideQuest)
            .relationships,
        isEmpty,
      );
    });

    testWidgets('generates stable unique main ids on collision',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_main_story',
            type: StorylineType.sideQuest,
            title: 'Existing secondary',
          ),
        ]),
      );

      await _createMainStoryline(tester, title: 'Main Story');

      final ids = harness.project.storylines.map((s) => s.id).toList();
      expect(ids, contains('storyline_main_story'));
      expect(ids, contains('storyline_main_story_2'));
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        harness.project.storylines
            .where((s) => s.type == StorylineType.sideQuest),
        hasLength(1),
      );
    });

    testWidgets('generates stable unique sideQuest ids on collision',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(tester, title: 'Lost Key');
      await _createSideQuest(tester, title: 'Lost Key');

      final ids = harness.project.storylines.map((s) => s.id).toList();
      expect(ids, contains('sidequest_lost_key'));
      expect(ids, contains('sidequest_lost_key_2'));
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        harness.project.storylines.where(
          (storyline) => storyline.type == StorylineType.sideQuest,
        ),
        hasLength(2),
      );
    });

    testWidgets('does not allow creating a second main storyline',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _openCreateDialog(tester);
      expect(find.text('Une histoire principale existe déjà.'), findsWidgets);
      await tester
          .tap(find.byKey(const ValueKey('storylines-create-type-main')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-title-field')),
        'Second main',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
      await tester.pumpAndSettle();

      expect(
        harness.project.storylines
            .where((storyline) => storyline.type == StorylineType.main),
        hasLength(1),
      );
      expect(
        harness.project.storylines
            .where((storyline) => storyline.type == StorylineType.sideQuest),
        hasLength(1),
      );
    });

    testWidgets('creation does not import legacy or promote localEventFlow',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _legacyAndLocalEventProject(),
      );

      await _createMainStoryline(tester, title: 'Fresh Main Story');

      expect(harness.project.storylines, hasLength(1));
      expect(harness.project.storylines.single.title, 'Fresh Main Story');
      expect(harness.project.storylines.single.legacySource, isNull);
      expect(
        harness.project.storylines
            .where((s) => s.type == StorylineType.sideQuest),
        isEmpty,
      );
      expect(harness.project.scenarios, hasLength(2));
      expect(
        harness.project.scenarios.map((scenario) => scenario.scope),
        containsAll([ScenarioScope.globalStory, ScenarioScope.localEventFlow]),
      );
      expect(find.text('Legacy Global Story'), findsNothing);
      expect(find.text('Local Event Flow'), findsNothing);
    });

    testWidgets('sideQuest creation never imports legacy or localEventFlow',
        (tester) async {
      final base = _legacyAndLocalEventProject();
      final project = ProjectManifest(
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        name: 'Legacy With Main',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenarios: base.scenarios,
        storylines: [
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ],
      );
      final harness = await _pumpStorylinesShell(tester, project: project);
      final beforeScenarios = harness.project.scenarios;

      await _createSideQuest(tester, title: 'Missing Bell');

      expect(harness.project.scenarios, beforeScenarios);
      expect(harness.project.storylines, hasLength(2));
      expect(
        harness.project.storylines
            .singleWhere(
                (storyline) => storyline.type == StorylineType.sideQuest)
            .legacySource,
        isNull,
      );
      expect(find.text('Legacy Global Story'), findsNothing);
      expect(find.text('Local Event Flow'), findsNothing);
    });

    testWidgets('Graph, Structure and disabled future actions do not mutate',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();
      final beforeMode = harness.editorState.workspaceMode;

      await _openStructureTab(tester);
      final linkSceneButton = find.byKey(
        const ValueKey('storylines-link-scene-disabled'),
      );
      expect(linkSceneButton, findsOneWidget);
      expect(tester.widget<PokeMapButton>(linkSceneButton).onPressed, isNull);

      await _openGraphTab(tester);

      expect(harness.project.toJson(), before);
      expect(harness.editorState.workspaceMode, beforeMode);
    });

    testWidgets('Structure authoring does not import legacy or localEventFlow',
        (tester) async {
      final project = ProjectManifest(
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        name: 'Legacy With Authoring',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenarios: _legacyAndLocalEventProject().scenarios,
        storylines: [
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ],
      );
      final harness = await _pumpStorylinesShell(tester, project: project);
      final beforeScenarios = harness.project.scenarios;

      await _createChapter(tester, title: 'Intro');
      await _createStep(tester, title: 'Premier jalon');

      expect(harness.project.scenarios, beforeScenarios);
      expect(harness.project.storylines, hasLength(1));
      expect(harness.project.storylines.single.legacySource, isNull);
      expect(
        harness.project.storylines
            .where((s) => s.type == StorylineType.sideQuest),
        isEmpty,
      );
      expect(harness.project.storylines.single.sceneLinks, isEmpty);
      expect(find.text('Local Event Flow'), findsNothing);
      expect(find.text('Legacy Global Story'), findsNothing);
    });

    testWidgets('keeps target fake data and Maps out of the V1 UI',
        (tester) async {
      await _pumpStorylinesShell(tester,
          project: _legacyAndLocalEventProject());

      for (final value in _targetOnlyStrings) {
        expect(find.text(value), findsNothing, reason: value);
      }
      expect(find.text('Maps'), findsNothing);
    });

    test('storylines UI source keeps raw colors out of the feature', () {
      final sources = [
        File('lib/src/ui/canvas/storylines_workspace.dart'),
        File('lib/src/ui/canvas/storylines/storylines_graph_model.dart'),
        File('lib/src/ui/canvas/storylines/storylines_graph_painter.dart'),
        File('lib/src/ui/canvas/storylines/storylines_graph_view.dart'),
      ];
      const rawColorPattern = 'Color' '(0x';
      const materialColorsPattern = 'Colors' '.';

      for (final source in sources) {
        expect(source.existsSync(), isTrue, reason: source.path);

        final contents = source.readAsStringSync();
        expect(contents, isNot(contains(rawColorPattern)), reason: source.path);
        expect(contents, isNot(contains(materialColorsPattern)),
            reason: source.path);
      }
    });

    test('storylines shell test keeps raw colors out', () {
      final source = File('test/storylines_workspace_shell_test.dart');
      expect(source.existsSync(), isTrue);

      final contents = source.readAsStringSync();
      const rawColorPattern = 'Color' '(0x';
      const materialColorsPattern = 'Colors' '.';
      expect(contents, isNot(contains(rawColorPattern)));
      expect(contents, isNot(contains(materialColorsPattern)));
    });

    testWidgets('uses PokeMap dark theme in the Visual Gate harness',
        (tester) async {
      await _pumpStorylinesShell(tester);

      final shellContext = tester.element(
        find.byKey(const ValueKey('storylines-workspace-shell')),
      );
      expect(Theme.of(shellContext).brightness, Brightness.dark);
    });

    testWidgets('writes V1-12 polished graph screenshots', (tester) async {
      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 1000),
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_empty_visual',
            type: StorylineType.main,
            title: 'Empty Visual Main',
          ),
        ]),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_12_graph_empty_polished.png',
        ),
      );

      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 1000),
        project: _visualGraphProject(),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_12_graph_main_polished.png',
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-sidequest_visual')),
      );
      await tester.pump();
      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('storylines-attach-sidequest-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'storylines-attach-anchor-step-step_visual_choice',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('storylines-attach-submit')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-storyline_visual_main')),
      );
      await tester.pump();
      await _openGraphTab(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_12_graph_sidequest_attached_polished.png',
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-sidequest_visual')),
      );
      await tester.pump();
      await _openGraphTab(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_12_graph_sidequest_standalone_polished.png',
        ),
      );
    });
  });
}

const _targetOnlyStrings = <String>[
  'Histoire globale',
  'La brume du phare',
  'Le port',
  'Les marais',
  'Le phare',
  'Les cristaux de sel',
  'Le Goélise du port',
  'La cabane du phare',
  'Mystère',
  'Exploration',
  'Phare',
  'Côtiers',
  '5 chapitres',
  '27 scènes',
  '412 dialogues',
  '18 facts',
  '3 problèmes',
  'Active',
  'Haute',
  'Validé',
  'Défini',
  'En cours',
  'Quête annexe fake',
];

Future<void> _openCreateDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('storylines-create-main-cta')));
  await tester.pumpAndSettle();
}

Future<void> _createMainStoryline(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateDialog(tester);
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
  await tester.pumpAndSettle();
}

Future<void> _createSideQuest(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateDialog(tester);
  await tester
      .tap(find.byKey(const ValueKey('storylines-create-type-sidequest')));
  await tester.pump();
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
  await tester.pumpAndSettle();
}

Future<void> _attachSideQuestToAnchor(
  WidgetTester tester, {
  required String anchorKey,
}) async {
  await _openStructureTab(tester);
  await tester.tap(
    find.byKey(const ValueKey('storylines-attach-sidequest-action')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(anchorKey)));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-attach-submit')));
  await tester.pumpAndSettle();
}

Future<void> _openCreateChapterDialog(WidgetTester tester) async {
  await _openStructureTab(tester);
  await tester.tap(find.byKey(const ValueKey('storylines-new-chapter-action')));
  await tester.pumpAndSettle();
}

Future<void> _createChapter(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateChapterDialog(tester);
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-chapter-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-chapter-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester
      .tap(find.byKey(const ValueKey('storylines-create-chapter-submit')));
  await tester.pumpAndSettle();
}

Future<void> _openCreateStepDialog(WidgetTester tester) async {
  await _openStructureTab(tester);
  await tester.tap(find.byKey(const ValueKey('storylines-new-step-action')));
  await tester.pumpAndSettle();
}

Future<void> _createStep(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateStepDialog(tester);
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-step-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-step-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-create-step-submit')));
  await tester.pumpAndSettle();
}

Future<void> _openStructureTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Structure'),
    ),
  );
  await tester.pump();
}

Future<void> _openGraphTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Graph'),
    ),
  );
  await tester.pump();
}

Future<_StorylinesHarness> _pumpStorylinesShell(
  WidgetTester tester, {
  Size surfaceSize = const Size(1600, 1000),
  ProjectManifest? project,
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
    project: project ?? _emptyStorylinesProject(),
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

  return _StorylinesHarness(container);
}

ProjectManifest _emptyStorylinesProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Audit Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );
}

ProjectManifest _legacyOnlyProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Legacy Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_global_story',
        name: 'Legacy Global Story',
        description: 'Legacy description',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
    ],
  );
}

ProjectManifest _legacyAndLocalEventProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Legacy Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_global_story',
        name: 'Legacy Global Story',
        description: 'Legacy description',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
      ScenarioAsset(
        id: 'local_event_flow',
        name: 'Local Event Flow',
        description: 'Must not become side quest',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'local_start',
      ),
    ],
  );
}

ProjectManifest _projectWithStorylines(List<StorylineAsset> storylines) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Storylines Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    storylines: storylines,
  );
}

ProjectManifest _visualGraphProject() {
  return _projectWithStorylines([
    StorylineAsset(
      id: 'storyline_visual_main',
      type: StorylineType.main,
      title: 'Visual Main',
      description: 'Graph generated from authoring structure.',
      chapters: [
        StorylineChapter(
          id: 'chapter_visual_start',
          title: 'Opening',
          description: 'First authoring beat.',
          order: 0,
          steps: [
            StorylineStep(
              id: 'step_visual_arrival',
              title: 'Arrival',
              description: 'Introduce the player goal.',
              order: 0,
            ),
            StorylineStep(
              id: 'step_visual_choice',
              title: 'First choice',
              order: 1,
            ),
          ],
        ),
        StorylineChapter(
          id: 'chapter_visual_followup',
          title: 'Follow-up',
          order: 1,
          steps: [
            StorylineStep(
              id: 'step_visual_resolution',
              title: 'Resolution',
              order: 0,
            ),
          ],
        ),
      ],
    ),
    StorylineAsset(
      id: 'sidequest_visual',
      type: StorylineType.sideQuest,
      title: 'Visual Side Quest',
      description: 'Standalone optional storyline.',
      chapters: [
        StorylineChapter(
          id: 'chapter_visual_side',
          title: 'Side opening',
          order: 0,
          steps: [
            StorylineStep(
              id: 'step_visual_side_clue',
              title: 'Find clue',
              order: 0,
            ),
          ],
        ),
      ],
    ),
  ]);
}

class _StorylinesHarness {
  const _StorylinesHarness(this.container);

  final ProviderContainer container;

  EditorState get editorState => container.read(editorNotifierProvider);

  ProjectManifest get project => editorState.project!;
}
