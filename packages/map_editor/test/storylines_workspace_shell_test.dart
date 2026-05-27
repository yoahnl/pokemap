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
  group('NS-STORYLINES-03 Storylines shell V0', () {
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
        expect(find.byKey(const ValueKey('storylines-inspector-placeholder')),
            findsOneWidget);

        expect(find.text('Audit Story From Scenario'), findsWidgets);
        expect(find.text('Audit description from scenario'), findsOneWidget);
        expect(find.text('Mode lecture seule'), findsOneWidget);
        expect(find.text('Storylines V0'), findsWidgets);
        expect(find.text('Graph — à venir'), findsOneWidget);
        expect(find.text('Chapitres — à venir'), findsOneWidget);
        expect(find.text('Inspecteur Storyline — à venir'), findsOneWidget);
        expect(find.text('Audit Local Event Flow'), findsNothing);

        for (final forbidden in _targetOnlyStrings) {
          expect(
            find.text(forbidden),
            findsNothing,
            reason: '$forbidden must not be injected in Storylines shell V0.',
          );
        }

        expect(find.text('Maps'), findsNothing);
        expect(find.text('Facts'), findsOneWidget);
        expect(find.text('Règles du monde'), findsWidgets);
        expect(find.text('Validateur'), findsOneWidget);

        expect(
          harness.container.read(editorNotifierProvider).workspaceMode,
          EditorWorkspaceMode.globalStory,
        );
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
        final newStorylineButton = find.descendant(
          of: newStorylineAction,
          matching: find.byType(PokeMapButton),
        );
        final validateButton = find.descendant(
          of: validateAction,
          matching: find.byType(PokeMapButton),
        );

        expect(newStorylineAction, findsOneWidget);
        expect(validateAction, findsOneWidget);
        expect(newStorylineButton, findsOneWidget);
        expect(validateButton, findsOneWidget);
        expect(
          tester.widget<PokeMapButton>(newStorylineButton).onPressed,
          isNull,
        );
        expect(tester.widget<PokeMapButton>(validateButton).onPressed, isNull);

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
        expect(find.text('Audit description from scenario'), findsOneWidget);

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

      final shellContext =
          tester.element(find.byKey(const ValueKey('storylines-workspace-shell')));

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
          'ns_storylines_03_shell_desktop.png',
        ),
      );

      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 700),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_03_shell_focus.png',
        ),
      );

      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1180, 1000),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_03_shell_panels.png',
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
  'Mystère',
  'Exploration',
  'Phare',
  'Côtiers',
  '412',
  '18',
  'RÈGLES DU MONDE AFFECTÉES',
  'DERNIÈRE ACTIVITÉ',
];

Future<_StorylinesHarness> _pumpStorylinesShell(
  WidgetTester tester, {
  Size surfaceSize = const Size(1600, 1000),
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
    project: _auditProject(),
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory(scenarioId: 'audit_global_story');

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
    ],
  );
  const globalDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'audit_global_story',
    entryStepId: 'audit_step',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(stepId: 'audit_step'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'audit_chapter',
        name: 'Audit Chapter From Metadata',
        description: 'Audit chapter description from metadata',
        stepIds: <String>['audit_step'],
        order: 0,
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

  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Audit Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      globalScenario,
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

class _StorylinesHarness {
  const _StorylinesHarness(this.container);

  final ProviderContainer container;
}
