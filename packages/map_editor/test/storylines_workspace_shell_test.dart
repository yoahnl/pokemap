import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('NS-STORYLINES-08-bis Graph target alignment V0', () {
    testWidgets(
      'renders a read-only three-pane shell from real global story data',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final harness = await _pumpStorylinesShell(tester);

        expect(find.byKey(const ValueKey('storylines-workspace-shell')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-secondary-panel')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-main-panel')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-inspector-read-only')),
            findsOneWidget);
        final inspector =
            find.byKey(const ValueKey('storylines-inspector-read-only'));
        expect(find.byKey(const ValueKey('storylines-header-section')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-tabs')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('storylines-kpi-strip')),
          findsOneWidget,
        );

        expect(find.text('Audit Story From Scenario'), findsWidgets);
        expect(find.text('Audit description from scenario'), findsWidgets);
        expect(find.text('Mode lecture seule'), findsOneWidget);
        expect(find.text('Storylines V0'), findsWidgets);
        final graph =
            find.byKey(const ValueKey('storylines-graph-target-read-only'));
        expect(graph, findsOneWidget);
        expect(
          find.byKey(const ValueKey('storylines-graph-canvas')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-graph-main-flow')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-graph-node-audit_chapter')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('storylines-graph-node-audit_second_chapter'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-graph-legend')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-chapters-read-only')),
          findsNothing,
        );
        expect(find.text('Graph read-only'), findsOneWidget);
        expect(find.text('Audit Chapter From Metadata'), findsOneWidget);
        expect(find.text('Audit Second Chapter From Metadata'), findsOneWidget);
        expect(find.text('Audit Step From Metadata'), findsOneWidget);
        expect(find.text('Audit Second Step From Metadata'), findsOneWidget);
        expect(find.text('Audit Step Detail From Metadata'), findsOneWidget);
        expect(
          find.descendant(
            of: graph,
            matching: find.textContaining('Global Story Studio'),
          ),
          findsOneWidget,
        );
        expect(find.text('Relations détaillées à venir'), findsOneWidget);
        expect(find.text('Graph — à venir'), findsNothing);
        expect(find.text('Chapitres — à venir'), findsNothing);
        expect(find.text('Inspecteur Storyline — à venir'), findsNothing);
        expect(
          find.descendant(
            of: inspector,
            matching: find.text('Détails de la storyline'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: inspector,
            matching: find.text('Audit Story From Scenario'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: inspector,
            matching: find.text('Audit description from scenario'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: inspector,
            matching: find.text('ScenarioAsset globalStory'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
              of: inspector, matching: find.text('2 étapes narratives')),
          findsOneWidget,
        );
        expect(
          find.descendant(
              of: inspector, matching: find.text('0 cutscene liée')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: inspector, matching: find.text('Tags')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: inspector, matching: find.text('Facts')),
          findsOneWidget,
        );
        expect(
          find.descendant(
              of: inspector, matching: find.text('Activité récente')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: inspector, matching: find.text('Quêtes liées')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: inspector, matching: find.text('Non branché')),
          findsWidgets,
        );
        expect(
          find.descendant(of: inspector, matching: find.text('À venir')),
          findsWidgets,
        );
        expect(find.text('Audit Local Event Flow'), findsNothing);
        expect(find.text('Histoire principale'), findsOneWidget);
        expect(find.text('Audit Second Story From Scenario'), findsOneWidget);
        expect(find.text('Audit second description from scenario'),
            findsOneWidget);
        expect(find.text('Storyline principale'), findsWidgets);
        expect(find.textContaining('1 étape narrative'), findsWidgets);
        expect(find.textContaining('2 étapes narratives'), findsWidgets);
        expect(find.text('Recherche à venir'), findsOneWidget);
        expect(find.text('Quêtes annexes'), findsWidgets);
        expect(find.textContaining('aucun modèle de quête annexe'),
            findsOneWidget);
        expect(find.text('Lecture seule'), findsWidgets);
        expect(find.text('Source réelle'), findsWidgets);
        expect(find.text('Graph'), findsOneWidget);
        expect(find.text('Chapitres'), findsWidgets);
        expect(find.text('Étapes'), findsWidgets);
        expect(find.text('Scènes'), findsWidgets);
        expect(find.text('Statistiques'), findsOneWidget);
        expect(find.text('Tests'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('storylines-kpi-global-stories')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('storylines-kpi-global-stories')),
            matching: find.text('2'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-kpi-steps')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('storylines-kpi-steps')),
            matching: find.text('2'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-kpi-cutscenes')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('storylines-kpi-cutscenes')),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-kpi-chapters')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-kpi-diagnostics')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-secondary-create-action')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('storylines-secondary-search-disabled')),
          findsOneWidget,
        );
        expect(
          find.byKey(
              const ValueKey('storylines-secondary-row-audit_global_story')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
                'storylines-secondary-row-audit_second_global_story'),
          ),
          findsOneWidget,
        );

        for (final forbidden in _targetOnlyStrings) {
          expect(
            find.text(forbidden),
            findsNothing,
            reason: '$forbidden must not be injected in Storylines shell V0.',
          );
        }

        expect(find.text('Maps'), findsNothing);
        expect(find.text('Facts'), findsWidgets);
        expect(find.text('Règles du monde'), findsWidgets);
        expect(find.text('Validateur'), findsOneWidget);

        expect(
          harness.container.read(editorNotifierProvider).workspaceMode,
          EditorWorkspaceMode.globalStory,
        );
      },
    );

    testWidgets(
      'renders an honest empty state when the selected global story has no steps',
      (tester) async {
        await _pumpStorylinesShell(
          tester,
          project: _emptyGraphProject(),
          selectedGlobalStoryId: 'audit_empty_global_story',
        );

        expect(
          find.byKey(const ValueKey('storylines-graph-target-read-only')),
          findsOneWidget,
        );
        expect(find.text('Graph read-only'), findsOneWidget);
        expect(
          find.textContaining('Aucune étape narrative disponible'),
          findsOneWidget,
        );
        expect(find.text('Audit Step From Metadata'), findsNothing);
        expect(find.text('Audit Local Event Flow'), findsNothing);
      },
    );

    testWidgets(
      'shows the Chapters tab from Global Story Studio metadata read-only',
      (tester) async {
        final harness = await _pumpStorylinesShell(tester);
        final beforeEditorState =
            harness.container.read(editorNotifierProvider);
        final beforeNarrativeState =
            harness.container.read(narrativeWorkspaceControllerProvider);
        final beforeProject = beforeEditorState.project!;
        final beforeScenarioIds = beforeProject.scenarios
            .map((scenario) => scenario.id)
            .toList(growable: false);

        await _openChaptersTab(tester);

        final chapters =
            find.byKey(const ValueKey('storylines-chapters-read-only'));
        final createAction =
            find.byKey(const ValueKey('storylines-chapters-create-action'));

        expect(chapters, findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
            findsNothing);
        expect(
          find.descendant(of: chapters, matching: find.text('Chapitres')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: chapters,
            matching: find.textContaining('Global Story Studio'),
          ),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: chapters,
            matching: find.text('Audit Chapter From Metadata'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: chapters,
            matching: find.text('Audit chapter description from metadata'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
              of: chapters, matching: find.text('1 étape narrative')),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: chapters,
            matching: find.text('Audit Step From Metadata'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: chapters,
            matching: find.text('Audit Step Detail From Metadata'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: chapters, matching: find.text('Lecture seule')),
          findsWidgets,
        );
        expect(createAction, findsOneWidget);
        expect(tester.widget<PokeMapButton>(createAction).onPressed, isNull);

        await tester.tap(createAction);
        await tester.pump();

        final afterEditorState = harness.container.read(editorNotifierProvider);
        final afterNarrativeState =
            harness.container.read(narrativeWorkspaceControllerProvider);

        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
        expect(afterEditorState.workspaceMode, EditorWorkspaceMode.globalStory);
        expect(afterEditorState.project, same(beforeProject));
        expect(
          afterEditorState.project!.scenarios
              .map((scenario) => scenario.id)
              .toList(growable: false),
          beforeScenarioIds,
        );
        expect(
          afterNarrativeState.selectedGlobalStoryId,
          beforeNarrativeState.selectedGlobalStoryId,
        );
        expect(
          afterNarrativeState.selectedStepId,
          beforeNarrativeState.selectedStepId,
        );
        expect(find.text('Audit Local Event Flow'), findsNothing);
        expect(find.text('Scènes du chapitre'), findsNothing);
        expect(find.text('Brouillon'), findsNothing);
        expect(find.text('En cours'), findsNothing);
      },
    );

    testWidgets('shows an honest Chapters empty state', (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _emptyGraphProject(),
        selectedGlobalStoryId: 'audit_empty_global_story',
      );

      await _openChaptersTab(tester);

      expect(
        find.byKey(const ValueKey('storylines-chapters-read-only')),
        findsOneWidget,
      );
      expect(
        find.text('Aucun chapitre disponible pour cette storyline.'),
        findsOneWidget,
      );
      expect(find.text('Audit Step From Metadata'), findsNothing);
      expect(find.text('Audit Local Event Flow'), findsNothing);
    });

    testWidgets('renders an honest inspector empty state without global story',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _noGlobalStoryProject(),
        selectedGlobalStoryId: 'missing_global_story',
      );

      final inspector =
          find.byKey(const ValueKey('storylines-inspector-read-only'));

      expect(inspector, findsOneWidget);
      expect(
        find.descendant(
          of: inspector,
          matching: find.text('Aucune storyline sélectionnée.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: inspector,
          matching: find.text('ScenarioAsset globalStory'),
        ),
        findsNothing,
      );
      expect(find.text('Audit Local Event Flow'), findsNothing);
    });

    testWidgets(
      'keeps future Storyline tabs read-only and non-mutating',
      (tester) async {
        final harness = await _pumpStorylinesShell(tester);
        final tabs = find.byKey(const ValueKey('storylines-tabs'));

        expect(tabs, findsOneWidget);
        expect(
          find.descendant(of: tabs, matching: find.text('Graph')),
          findsOneWidget,
        );

        final beforeEditorState =
            harness.container.read(editorNotifierProvider);
        final beforeNarrativeState =
            harness.container.read(narrativeWorkspaceControllerProvider);
        final beforeProject = beforeEditorState.project!;
        final beforeScenarioIds = beforeProject.scenarios
            .map((scenario) => scenario.id)
            .toList(growable: false);

        for (final label in <String>[
          'Étapes',
          'Scènes',
          'Statistiques',
          'Tests',
        ]) {
          await tester
              .tap(find.descendant(of: tabs, matching: find.text(label)));
          await tester.pump();
        }

        final afterEditorState = harness.container.read(editorNotifierProvider);
        final afterNarrativeState =
            harness.container.read(narrativeWorkspaceControllerProvider);

        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
        expect(afterEditorState.workspaceMode, EditorWorkspaceMode.globalStory);
        expect(afterEditorState.project, same(beforeProject));
        expect(
          afterEditorState.project!.scenarios
              .map((scenario) => scenario.id)
              .toList(growable: false),
          beforeScenarioIds,
        );
        expect(
          afterNarrativeState.selectedGlobalStoryId,
          beforeNarrativeState.selectedGlobalStoryId,
        );
        expect(
          afterNarrativeState.selectedStepId,
          beforeNarrativeState.selectedStepId,
        );
        expect(find.text('Graph read-only'), findsOneWidget);
        expect(find.text('Audit Local Event Flow'), findsNothing);
      },
    );

    testWidgets(
      'keeps future header actions disabled and non-mutating',
      (tester) async {
        final harness = await _pumpStorylinesShell(tester);
        final newStorylineAction = find.byKey(
          const ValueKey('narrative-studio-header-action-new-storyline'),
        );
        final validateAction = find.byKey(
          const ValueKey('narrative-studio-header-action-validate'),
        );
        final secondaryCreateAction = find.byKey(
          const ValueKey('storylines-secondary-create-action'),
        );
        final newStorylineButton = find.descendant(
          of: newStorylineAction,
          matching: find.byType(PokeMapButton),
        );
        final validateButton = find.descendant(
          of: validateAction,
          matching: find.byType(PokeMapButton),
        );
        final secondaryCreateButton = find.descendant(
          of: secondaryCreateAction,
          matching: find.byType(PokeMapButton),
        );

        expect(newStorylineAction, findsOneWidget);
        expect(validateAction, findsOneWidget);
        expect(secondaryCreateAction, findsOneWidget);
        expect(newStorylineButton, findsOneWidget);
        expect(validateButton, findsOneWidget);
        expect(secondaryCreateButton, findsOneWidget);
        expect(
          tester.widget<PokeMapButton>(newStorylineButton).onPressed,
          isNull,
        );
        expect(tester.widget<PokeMapButton>(validateButton).onPressed, isNull);
        expect(
          tester.widget<PokeMapButton>(secondaryCreateButton).onPressed,
          isNull,
        );

        final beforeEditorState =
            harness.container.read(editorNotifierProvider);
        final beforeNarrativeState =
            harness.container.read(narrativeWorkspaceControllerProvider);
        final beforeProject = beforeEditorState.project!;
        final beforeScenarioIds = beforeProject.scenarios
            .map((scenario) => scenario.id)
            .toList(growable: false);
        final beforeScenarioCount = beforeProject.scenarios.length;

        await tester.tap(newStorylineAction);
        await tester.pump();

        await tester.tap(validateAction);
        await tester.pump();

        await tester.tap(secondaryCreateAction);
        await tester.pump();

        final afterEditorState = harness.container.read(editorNotifierProvider);
        final afterNarrativeState =
            harness.container.read(narrativeWorkspaceControllerProvider);

        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
        expect(afterEditorState.workspaceMode, EditorWorkspaceMode.globalStory);
        expect(afterEditorState.project, same(beforeProject));
        expect(afterEditorState.project!.scenarios.length, beforeScenarioCount);
        expect(
          afterEditorState.project!.scenarios
              .map((scenario) => scenario.id)
              .toList(growable: false),
          beforeScenarioIds,
        );
        expect(
          afterNarrativeState.selectedGlobalStoryId,
          beforeNarrativeState.selectedGlobalStoryId,
        );
        expect(
          afterNarrativeState.selectedStepId,
          beforeNarrativeState.selectedStepId,
        );
        expect(find.text('Audit Story From Scenario'), findsWidgets);
        expect(find.text('Audit description from scenario'), findsWidgets);

        for (final forbidden in _targetOnlyStrings) {
          expect(
            find.text(forbidden),
            findsNothing,
            reason: '$forbidden must not appear after disabled interactions.',
          );
        }
      },
    );

    test('storylines UI source keeps raw colors out of the feature', () {
      final source = File('lib/src/ui/canvas/storylines_workspace.dart');
      expect(source.existsSync(), isTrue);

      final contents = source.readAsStringSync();
      const rawColorConstructor = 'Color' '(0x';
      const materialColorAccessor = 'Colors' '.';

      expect(contents.contains(rawColorConstructor), isFalse);
      expect(contents.contains(materialColorAccessor), isFalse);
    });

    test('storylines action test does not use silent taps', () {
      final source = File('test/storylines_workspace_shell_test.dart');
      expect(source.existsSync(), isTrue);

      final contents = source.readAsStringSync();
      const silentTapArgument = 'warnIfMissed' ': false';

      expect(contents.contains(silentTapArgument), isFalse);
    });

    testWidgets('uses PokeMap dark theme in the Visual Gate harness',
        (tester) async {
      await _pumpStorylinesShell(tester);

      final shellContext = tester
          .element(find.byKey(const ValueKey('storylines-workspace-shell')));

      expect(Theme.of(shellContext).brightness, Brightness.dark);
    });

    testWidgets('writes Visual Gate screenshots', (tester) async {
      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 1000),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_08_bis_graph_target_desktop.png',
        ),
      );

      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 700),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-graph-target-read-only')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_08_bis_graph_target_focus.png',
        ),
      );

      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1180, 1000),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-graph-target-read-only')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_08_bis_graph_target_center.png',
        ),
      );
    });
  });
}

const _targetOnlyStrings = <String>[
  'La brume du phare',
  'Les cristaux de sel',
  'Le Goélise du port',
  'La cabane du phare',
  'Souvenirs oubliés',
  'Tutoriel : Premiers pas',
  'Épilogue : Le phare rallumé',
  'Mystère',
  'Exploration',
  'Phare',
  'Côtiers',
  '5 chapitres',
  '27 scènes',
  '412 dialogues',
  '18 facts',
  '3 problèmes',
  '412',
  '18',
  'RÈGLES DU MONDE AFFECTÉES',
  'DERNIÈRE ACTIVITÉ',
  'Active',
  'Haute',
  'Validé',
  'À jour',
  'Défini',
  'Brouillon',
  'En cours',
  'Scènes du chapitre',
  'Quête annexe',
];

Future<void> _openChaptersTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Chapitres'),
    ),
  );
  await tester.pump();
}

Future<_StorylinesHarness> _pumpStorylinesShell(
  WidgetTester tester, {
  Size surfaceSize = const Size(1600, 1000),
  ProjectManifest? project,
  String selectedGlobalStoryId = 'audit_global_story',
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
    project: project ?? _auditProject(),
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory(scenarioId: selectedGlobalStoryId);

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

ProjectManifest _auditProject() {
  const stepDocument = StepStudioDocument(
    globalStoryScenarioId: 'audit_global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'audit_step',
        name: 'Audit Step From Metadata',
        description: 'Audit Step Detail From Metadata',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
      StepStudioStep(
        id: 'audit_followup_step',
        name: 'Audit Second Step From Metadata',
        description: 'Audit second step detail from metadata',
        order: 1,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.afterStep,
          stepId: 'audit_step',
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
    ],
  );
  const globalDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'audit_global_story',
    entryStepId: 'audit_step',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(stepId: 'audit_step'),
      GlobalStoryStepNode(stepId: 'audit_followup_step'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'audit_chapter',
        name: 'Audit Chapter From Metadata',
        description: 'Audit chapter description from metadata',
        stepIds: <String>['audit_step'],
        order: 0,
      ),
      GlobalStoryChapter(
        id: 'audit_second_chapter',
        name: 'Audit Second Chapter From Metadata',
        description: 'Audit second chapter description from metadata',
        stepIds: <String>['audit_followup_step'],
        order: 1,
      ),
    ],
  );

  final globalScenario = applyGlobalStoryStudioDocumentToGlobalScenario(
    applyStepStudioDocumentToGlobalScenario(
      const ScenarioAsset(
        id: 'audit_global_story',
        name: 'Audit Story From Scenario',
        description: 'Audit description from scenario',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
      stepDocument,
    ),
    globalDocument,
    stepDocument: stepDocument,
  );
  const secondStepDocument = StepStudioDocument(
    globalStoryScenarioId: 'audit_second_global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'audit_second_step',
        name: 'Audit Second Step From Metadata',
        description: 'Audit second step detail from metadata',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
    ],
  );
  const secondGlobalDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'audit_second_global_story',
    entryStepId: 'audit_second_step',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(stepId: 'audit_second_step'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'audit_second_chapter',
        name: 'Audit Second Chapter From Metadata',
        description: 'Audit second chapter description from metadata',
        stepIds: <String>['audit_second_step'],
        order: 0,
      ),
    ],
  );
  final secondGlobalScenario = applyGlobalStoryStudioDocumentToGlobalScenario(
    applyStepStudioDocumentToGlobalScenario(
      const ScenarioAsset(
        id: 'audit_second_global_story',
        name: 'Audit Second Story From Scenario',
        description: 'Audit second description from scenario',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'second_start',
      ),
      secondStepDocument,
    ),
    secondGlobalDocument,
    stepDocument: secondStepDocument,
  );

  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Audit Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      globalScenario,
      secondGlobalScenario,
      const ScenarioAsset(
        id: 'audit_local_event_flow',
        name: 'Audit Local Event Flow',
        description: 'Audit local flow must not become a side quest',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'local_start',
      ),
    ],
  );
}

ProjectManifest _emptyGraphProject() {
  final emptyGlobalScenario = applyStepStudioDocumentToGlobalScenario(
    const ScenarioAsset(
      id: 'audit_empty_global_story',
      name: 'Audit Empty Story From Scenario',
      description: 'Audit empty description from scenario',
      scope: ScenarioScope.globalStory,
      entryNodeId: 'empty_start',
    ),
    const StepStudioDocument(
      globalStoryScenarioId: 'audit_empty_global_story',
      steps: <StepStudioStep>[],
    ),
  );

  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Audit Empty Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      emptyGlobalScenario,
      const ScenarioAsset(
        id: 'audit_local_event_flow',
        name: 'Audit Local Event Flow',
        description: 'Audit local flow must not become a side quest',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'local_start',
      ),
    ],
  );
}

ProjectManifest _noGlobalStoryProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Audit No Story Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'audit_local_event_flow',
        name: 'Audit Local Event Flow',
        description: 'Audit local flow must not become a side quest',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'local_start',
      ),
    ],
  );
}

class _StorylinesHarness {
  const _StorylinesHarness(this.container);

  final ProviderContainer container;
}
