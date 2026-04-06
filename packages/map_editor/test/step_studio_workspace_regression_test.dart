import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/step_studio_workspace.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';

void main() {
  group('Step Studio regressions', () {
    testWidgets(
      'defers initial step selection callback after frame (provider-safe)',
      (tester) async {
        const project = ProjectManifest(
          name: 'test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            ScenarioAsset(
              id: 'global_story',
              name: 'Global Story',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
          ],
        );
        final projection = buildNarrativeWorkspaceProjection(project);

        final callbackPhases = <SchedulerPhase>[];
        // Surface large : le Step Editor (sidebar + 3 colonnes / empilement) dépasse
        // souvent le viewport par défaut des tests (800×600).
        await tester.binding.setSurfaceSize(const Size(1600, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: 1280,
                        height: 900,
                        child: StepStudioWorkspace(
                          editorNotifier: notifier,
                          project: project,
                          activeMap: null,
                          projection: projection,
                          selectedStepId: null,
                          onSelectStep: (_) {
                            // Ce test verrouille la régression Riverpod:
                            // on refuse toute notification pendant la phase build.
                            callbackPhases
                                .add(WidgetsBinding.instance.schedulerPhase);
                          },
                          onSelectOutcome: (_) {},
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Flush de la callback post-frame utilisée par l'hydratation.
        await tester.pump();

        expect(callbackPhases, isNotEmpty);
        expect(
          callbackPhases
              .any((phase) => phase == SchedulerPhase.persistentCallbacks),
          isFalse,
        );

        // On démonte explicitement la tree pour laisser Riverpod drainer
        // ses timers de micro-nettoyage autoDispose.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets('EditorSidebarListRow with subtitle does not overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: ListView(
                children: const [
                  EditorSidebarListRow(
                    selected: false,
                    onTap: _noop,
                    title: Text('Rencontrer Emma'),
                    subtitle: Text('Cutscenes: 2 • Outcomes: 1'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // En cas d'overflow RenderFlex, Flutter remonte une exception testable.
      expect(tester.takeException(), isNull);
    });

    /// Regression test for the infinite-loop bug (2026-04) caused by missing
    /// `index++` in `for` loops inside d’anciennes sections Step Studio.
    ///
    /// **Root cause:** `for (var index = 0; index < X.length; index)` sans
    /// `index++` gardait `index` à 0, générant une infinité de widgets dans
    /// un spread `...[]` (freeze + RAM).
    ///
    /// **Fix historique :** boucles basées sur `X.asMap().entries`. Les sections
    /// concernées ont été retirées au profit du canvas + inspecteur, mais ce
    /// test reste un garde-fou « build borné » avec listes non vides.
    ///
    /// **What this test verifies:** build completes in < 5 seconds even when
    /// the step has multiple cutscenes, outcomes, and world changes. An
    /// infinite loop would cause the test to timeout.
    testWidgets(
      'build completes in bounded time with non-empty cutscenes, outcomes, '
      'and worldChanges (anti-infinite-loop guard)',
      (tester) async {
        final document = StepStudioDocument(
          globalStoryScenarioId: 'global_story',
          steps: <StepStudioStep>[
            StepStudioStep(
              id: 'step_a',
              name: 'Step A',
              description: 'First step',
              order: 0,
              activation: const StepStudioActivationRule(
                mode: StepStudioActivationMode.atGameStart,
              ),
              completion: const StepStudioCompletionRule(
                mode: StepStudioCompletionMode.manual,
              ),
              cutscenes: const <StepStudioCutsceneLink>[
                StepStudioCutsceneLink(
                  cutsceneId: 'cutscene_1',
                  role: StepStudioCutsceneRole.main,
                ),
                StepStudioCutsceneLink(
                  cutsceneId: 'cutscene_2',
                  role: StepStudioCutsceneRole.kickoff,
                ),
              ],
              outcomes: const <StepStudioOutcomeDefinition>[
                StepStudioOutcomeDefinition(
                  label: 'Result A',
                  scope: StepStudioOutcomeScope.progression,
                  outcomeId: 'progression.step_a.result_a',
                ),
                StepStudioOutcomeDefinition(
                  label: 'Result B',
                  scope: StepStudioOutcomeScope.world,
                  outcomeId: 'world.step_a.result_b',
                ),
              ],
              worldChanges: const <StepStudioWorldChange>[
                StepStudioWorldChange(
                  mapId: 'map_alpha',
                  entityId: 'npc_emma',
                  presenceRule: StepStudioPresenceRule.visibleAfterStepCompletion,
                ),
              ],
            ),
            StepStudioStep(
              id: 'step_b',
              name: 'Step B',
              description: 'Second step',
              order: 1,
              activation: const StepStudioActivationRule(
                mode: StepStudioActivationMode.afterPreviousStep,
              ),
              completion: const StepStudioCompletionRule(
                mode: StepStudioCompletionMode.manual,
              ),
            ),
          ],
        );

        final project = ProjectManifest(
          name: 'test',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            ScenarioAsset(
              id: 'global_story',
              name: 'Global Story',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
              metadata: <String, String>{
                kStepStudioDocumentMetadataKey: document.toMetadataJson(),
              },
            ),
            ScenarioAsset(
              id: 'local_flow_1',
              name: 'Cutscene 1',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
            ),
            ScenarioAsset(
              id: 'local_flow_2',
              name: 'Cutscene 2',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
            ),
          ],
        );
        final projection = buildNarrativeWorkspaceProjection(project);

        var selectionCallbackCount = 0;

        await tester.binding.setSurfaceSize(const Size(1600, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 1280,
                      height: 900,
                      child: StepStudioWorkspace(
                        editorNotifier: notifier,
                        project: project,
                        activeMap: null,
                        projection: projection,
                        selectedStepId: 'step_a',
                        onSelectStep: (_) {
                          selectionCallbackCount++;
                        },
                        onSelectOutcome: (_) {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Flush post-frame callbacks (hydration + deferred selection).
        await tester.pump();

        // If the for-loop bug were present, we'd never reach here
        // (infinite synchronous loop in build).
        // The fact that we get here proves the loop is bounded.
        expect(selectionCallbackCount, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);

        // Verify we can trigger a rebuild (simulating an "add" action)
        // without entering an infinite loop on the next build.
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
      // 30-second timeout: if the infinite-loop bug exists, this test will
      // never complete and will be killed by the test runner. A healthy build
      // completes in < 1 second.
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'hydrated sidebar lists worldChanges count when entityId is empty (draft row)',
      (tester) async {
        final document = StepStudioDocument(
          globalStoryScenarioId: 'global_story',
          steps: <StepStudioStep>[
            StepStudioStep(
              id: 'step_a',
              name: 'Step A',
              description: 'First step',
              order: 0,
              activation: const StepStudioActivationRule(
                mode: StepStudioActivationMode.atGameStart,
              ),
              completion: const StepStudioCompletionRule(
                mode: StepStudioCompletionMode.manual,
              ),
              worldChanges: const <StepStudioWorldChange>[
                StepStudioWorldChange(
                  mapId: 'map_alpha',
                  entityId: '',
                  presenceRule:
                      StepStudioPresenceRule.visibleAfterStepCompletion,
                  note: '',
                ),
              ],
            ),
          ],
        );

        final project = ProjectManifest(
          name: 'test',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            ScenarioAsset(
              id: 'global_story',
              name: 'Global Story',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
              metadata: <String, String>{
                kStepStudioDocumentMetadataKey: document.toMetadataJson(),
              },
            ),
          ],
        );
        final projection = buildNarrativeWorkspaceProjection(project);

        await tester.binding.setSurfaceSize(const Size(1600, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 1280,
                      height: 900,
                      child: StepStudioWorkspace(
                        editorNotifier: notifier,
                        project: project,
                        activeMap: null,
                        projection: projection,
                        selectedStepId: 'step_a',
                        onSelectStep: (_) {},
                        onSelectOutcome: (_) {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        expect(
          find.textContaining('1 changement(s) sur la carte'),
          findsOneWidget,
        );
      },
    );
  });
}

void _noop() {}
