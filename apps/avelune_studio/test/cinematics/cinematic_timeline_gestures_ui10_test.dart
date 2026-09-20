import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_preview_transport.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_timeline_editor.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';

void main() {
  testWidgets(
    'timeline empty lane, reorder, resize once and Escape preserve authored time',
    (tester) async {
      final view = CinematicViewState()..timelineScale = .12;
      final transport = CinematicPreviewTransport();
      var asset = CinematicAsset(
        id: 'c',
        title: 'Séquence',
        requiredActors: [
          CinematicActorRef(actorId: 'unused', label: 'Sans action'),
        ],
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'one',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 1000,
            ),
            CinematicTimelineStep(
              id: 'two',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 2000,
            ),
            CinematicTimelineStep(
              id: 'three',
              kind: CinematicTimelineStepKind.marker,
              label: 'Repère',
            ),
          ],
        ),
      );
      var moves = 0, changes = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return CinematicTimelineEditor(
                  asset: asset,
                  view: view,
                  transport: transport,
                  changed: () => rebuild(() {}),
                  onPlay: () {},
                  onSelect: (id) => rebuild(() {
                    view.selection
                      ..clear()
                      ..add(id);
                  }),
                  onMove: (index) => rebuild(() {
                    moves++;
                    asset = moveCinematicTimelineSteps(
                      asset,
                      stepIds: view.selection,
                      insertionIndex: index,
                    ).cinematic;
                  }),
                  onDuration: (id, ms) => rebuild(() {
                    changes++;
                    asset = asset.copyWith(
                      timeline: CinematicTimeline(
                        steps: [
                          for (final s in asset.timeline.steps)
                            s.id == id
                                ? CinematicTimelineStep.fromJson({
                                    ...s.toJson(),
                                    'durationMs': ms,
                                  })
                                : s,
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Sans action'), findsOneWidget);
      final handle = find.byKey(const ValueKey('cinematic-duration-one'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(24, 0));
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(3, 0));
      }
      await tester.pump();
      expect(changes, 0);
      await gesture.up();
      await tester.pump();
      expect(changes, 1);
      expect(asset.timeline.steps.first.durationMs, greaterThan(1000));
      final saved = asset;
      final cancelled = await tester.startGesture(tester.getCenter(handle));
      await cancelled.moveBy(const Offset(50, 0));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await cancelled.up();
      await tester.pump();
      expect(asset, saved);
      expect(changes, 1);
      final clip = find.byKey(const ValueKey('cinematic-clip-one'));
      final drag = await tester.startGesture(
        tester.getTopLeft(clip) + const Offset(25, 15),
      );
      await drag.moveBy(const Offset(24, 0));
      await drag.moveBy(const Offset(400, 0));
      await tester.pump();
      expect(moves, 0);
      await drag.up();
      await tester.pump();
      expect(moves, 1);
      expect(asset.timeline.steps.first.id, 'two');
      expect(
        asset.timeline.steps.firstWhere((s) => s.id == 'three').durationMs,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      view.dispose();
      transport.dispose();
    },
  );
}
