@Tags(['performance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';

import 'shell_chrome_test_harness.dart';

/// NSC-60 records intentionally generous regression budgets around the
/// current monolithic builder. The measured values are emitted by the test;
/// the limits protect NSC-61 from catastrophic regressions without pretending
/// that wall-clock timings are deterministic across developer machines.
void main() {
  testWidgets('characterizes cold load, builder open and settled rebuilds', (
    tester,
  ) async {
    var firstBuilds = 0;
    var rebuilds = 0;
    final previousRebuildObserver = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce) {
        rebuilds += 1;
      } else {
        firstBuilds += 1;
      }
      previousRebuildObserver?.call(element, builtOnce);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previousRebuildObserver);

    final coldLoad = Stopwatch()..start();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        project: _characterizationProject(),
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1672, 941),
    );
    coldLoad.stop();

    firstBuilds = 0;
    rebuilds = 0;
    final builderOpen = Stopwatch()..start();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_baseline')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await tester.pumpAndSettle();
    builderOpen.stop();

    expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
    final openFirstBuilds = firstBuilds;
    final openRebuilds = rebuilds;

    firstBuilds = 0;
    rebuilds = 0;
    await tester.pump(const Duration(milliseconds: 16));
    final settledFirstBuilds = firstBuilds;
    final settledRebuilds = rebuilds;

    debugPrint(
      'NSC-60 cinematic baseline: '
      'coldLoadMs=${coldLoad.elapsedMilliseconds}, '
      'builderOpenMs=${builderOpen.elapsedMilliseconds}, '
      'openFirstBuilds=$openFirstBuilds, openRebuilds=$openRebuilds, '
      'settledFirstBuilds=$settledFirstBuilds, '
      'settledRebuilds=$settledRebuilds',
    );

    expect(coldLoad.elapsed, lessThan(const Duration(seconds: 5)));
    expect(builderOpen.elapsed, lessThan(const Duration(seconds: 5)));
    expect(openFirstBuilds, inInclusiveRange(1, 10000));
    expect(openRebuilds, lessThan(5000));
    expect(settledFirstBuilds, 0);
    expect(settledRebuilds, lessThanOrEqualTo(10));
    expect(tester.takeException(), isNull);
  });
}

ProjectManifest _characterizationProject() {
  return ProjectManifest(
    name: 'Cinematic characterization',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    cinematics: <CinematicAsset>[
      CinematicAsset(
        id: 'cinematic_baseline',
        title: 'Baseline cinématique',
        requiredActors: <CinematicActorRef>[
          CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
        ],
        timeline: CinematicTimeline(
          steps: <CinematicTimelineStep>[
            for (var index = 0; index < 120; index++)
              CinematicTimelineStep(
                id: 'step_$index',
                kind: switch (index % 4) {
                  0 => CinematicTimelineStepKind.camera,
                  1 => CinematicTimelineStepKind.actorMove,
                  2 => CinematicTimelineStepKind.dialogueLine,
                  _ => CinematicTimelineStepKind.wait,
                },
                label: 'Bloc $index',
                durationMs: 250 + (index % 5) * 100,
                actorId: index % 4 == 1 || index % 4 == 2 ? 'actor_lysa' : null,
              ),
          ],
        ),
      ),
    ],
  );
}
