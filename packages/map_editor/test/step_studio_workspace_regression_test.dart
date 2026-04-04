import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
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
  });
}

void _noop() {}
