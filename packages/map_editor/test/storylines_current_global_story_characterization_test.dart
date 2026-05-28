import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';

void main() {
  group('NS-STORYLINES-02 current Global Story characterization', () {
    testWidgets(
      'renders the current Storylines shell from manifest and authoring metadata',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final project = _auditProject();

        await _pumpGlobalStoryCanvas(tester, project);

        expect(find.byType(NarrativeWorkspaceCanvas), findsOneWidget);
        expect(find.byKey(const ValueKey('narrative-studio-sidebar')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('narrative-studio-header')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-workspace-shell')),
            findsOneWidget);

        expect(find.text('Storylines'), findsWidgets);
        expect(find.text('Audit Story From Scenario'), findsWidgets);
        expect(find.text('Audit description from scenario'), findsWidgets);
        expect(find.text('Étapes réelles'), findsOneWidget);
        expect(find.text('1'), findsWidgets);

        expect(find.text('Mode lecture seule'), findsOneWidget);
        expect(find.text('Graph — à venir'), findsOneWidget);
        expect(find.text('Chapitres — à venir'), findsOneWidget);
        expect(find.text('Valider'), findsWidgets);

        // Future Storylines action exists in the internal header shell, but is
        // disabled by the widget contract.
        expect(find.text('Nouvelle storyline'), findsOneWidget);

        // NS-HOME guardrail: Maps is not an internal Narrative Studio entry.
        expect(find.text('Maps'), findsNothing);
        expect(find.text('Facts'), findsOneWidget);
        expect(find.text('Règles du monde'), findsWidgets);
        expect(find.text('Validateur'), findsOneWidget);

        // localEventFlow is available to the projection, but is not displayed
        // as a side quest/storyline in the legacy Global Story workspace.
        expect(find.text('Audit Local Event Flow'), findsNothing);

        for (final forbidden in _targetOnlyStrings) {
          expect(
            find.text(forbidden),
            findsNothing,
            reason: '$forbidden must not be injected from target imagery.',
          );
        }
      },
    );

    test(
      'keeps globalStory and localEventFlow separated in the current projection',
      () {
        final project = _auditProject();

        final projection = buildNarrativeWorkspaceProjection(project);

        expect(projection.globalStories, hasLength(1));
        expect(projection.globalStories.single.id, 'audit_global_story');
        expect(
          projection.globalStories.single.name,
          'Audit Story From Scenario',
        );
        expect(
          projection.globalStories.single.description,
          'Audit description from scenario',
        );

        expect(projection.localEventFlows, hasLength(1));
        expect(projection.localEventFlows.single.id, 'audit_local_event_flow');
        expect(
          projection.localEventFlows.single.name,
          'Audit Local Event Flow',
        );

        expect(projection.steps, hasLength(1));
        expect(projection.steps.single.id, 'audit_step');
        expect(projection.steps.single.name, 'Audit Step From Metadata');
        expect(
          projection.steps.single.description,
          'Audit Step Detail From Metadata',
        );
      },
    );
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

Future<void> _pumpGlobalStoryCanvas(
  WidgetTester tester,
  ProjectManifest project,
) async {
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
      .openGlobalStory(scenarioId: 'audit_global_story');
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .selectStep('audit_step');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
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
