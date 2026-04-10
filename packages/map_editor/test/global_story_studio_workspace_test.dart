import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/global_story_studio_workspace.dart';

void main() {
  group('GlobalStoryStudioWorkspace', () {
    testWidgets(
      'defers global/step selection callbacks after frame (provider-safe)',
      (tester) async {
        const stepDocument = StepStudioDocument(
          globalStoryScenarioId: 'global_story',
          steps: <StepStudioStep>[
            StepStudioStep(
              id: 'step_intro',
              name: 'Introduction',
              description: '',
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
          globalStoryScenarioId: 'global_story',
          entryStepId: 'step_intro',
          nodes: <GlobalStoryStepNode>[
            GlobalStoryStepNode(stepId: 'step_intro'),
          ],
        );

        final scenario = applyGlobalStoryStudioDocumentToGlobalScenario(
          applyStepStudioDocumentToGlobalScenario(
            const ScenarioAsset(
              id: 'global_story',
              name: 'Global Story',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
            stepDocument,
          ),
          globalDocument,
          stepDocument: stepDocument,
        );
        final project = ProjectManifest(
          name: 'test',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            scenario,
          ],
        );
        final projection = buildNarrativeWorkspaceProjection(project);

        final globalCallbackPhases = <SchedulerPhase>[];
        final stepCallbackPhases = <SchedulerPhase>[];

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: 1400,
                        height: 900,
                        child: GlobalStoryStudioWorkspace(
                          editorNotifier: notifier,
                          project: project,
                          projection: projection,
                          selectedGlobalStoryId: null,
                          selectedStepId: null,
                          onSelectGlobalStory: (_) {
                            globalCallbackPhases
                                .add(WidgetsBinding.instance.schedulerPhase);
                          },
                          onSelectStep: (_) {
                            stepCallbackPhases
                                .add(WidgetsBinding.instance.schedulerPhase);
                          },
                          onOpenStepStudio: (_) {},
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Flush post-frame callbacks queued during hydration.
        await tester.pump();

        expect(globalCallbackPhases, isNotEmpty);
        expect(stepCallbackPhases, isNotEmpty);
        expect(
          globalCallbackPhases.any(
            (phase) => phase == SchedulerPhase.persistentCallbacks,
          ),
          isFalse,
        );
        expect(
          stepCallbackPhases.any(
            (phase) => phase == SchedulerPhase.persistentCallbacks,
          ),
          isFalse,
        );
      },
    );

    testWidgets(
      'can create a step from the shell without exceptions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const stepDocument = StepStudioDocument(
          globalStoryScenarioId: 'global_story',
          steps: <StepStudioStep>[
            StepStudioStep(
              id: 'step_intro',
              name: 'Introduction',
              description: '',
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
          globalStoryScenarioId: 'global_story',
          entryStepId: 'step_intro',
          nodes: <GlobalStoryStepNode>[
            GlobalStoryStepNode(stepId: 'step_intro'),
          ],
        );
        final scenario = applyGlobalStoryStudioDocumentToGlobalScenario(
          applyStepStudioDocumentToGlobalScenario(
            const ScenarioAsset(
              id: 'global_story',
              name: 'Global Story',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
            stepDocument,
          ),
          globalDocument,
          stepDocument: stepDocument,
        );
        final project = ProjectManifest(
          name: 'test',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            scenario,
          ],
        );
        final projection = buildNarrativeWorkspaceProjection(project);

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 1400,
                      height: 900,
                      child: GlobalStoryStudioWorkspace(
                        editorNotifier: notifier,
                        project: project,
                        projection: projection,
                        selectedGlobalStoryId: 'global_story',
                        selectedStepId: 'step_intro',
                        onSelectGlobalStory: (_) {},
                        onSelectStep: (_) {},
                        onOpenStepStudio: (_) {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('+ Nouvelle étape').first);
        await tester.pump();

        expect(find.text('Nouvelle step 2'), findsWidgets);

        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
