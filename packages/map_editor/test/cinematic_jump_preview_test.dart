import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart';
import '../../map_core/test/fixtures/cinematic_facing_fixture.dart';

void main() {
  testWidgets(
    'jump adapter retains logical XY and overlay applies only the sampled lift',
    (tester) async {
      final base = facingCinematic(destinationX: 8, destinationY: 8).copyWith(
        timeline: CinematicTimeline(steps: [facingStep('face', 'left')]),
      );
      final asset = addCinematicTimelineActorJumpStep(
        facingProject(base),
        cinematicId: base.id,
        actorId: 'actor',
        targetId: 'destination',
        heightCells: 1,
      ).cinematic;
      final project = facingProject(asset);
      final map = MapData(
        id: 'room',
        name: 'Room',
        size: const GridSize(width: 16, height: 16),
      );
      final display = buildCinematicActorDisplayPreviewModel(
        cinematic: asset,
        project: project,
        stageMap: project.maps.single,
        mapData: map,
      );
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: asset,
        actorDisplayPreviewModel: display,
        availableMapIds: ['room'],
      );
      Future<void> mount(int ms) async {
        final overlay = buildCinematicPreviewPlaybackActorOverlayModel(
          displayModel: display,
          playbackFrame: plan.frameAt(ms),
        )!;
        expect(overlay.poseOverrides['actor']!.x, 8);
        expect(overlay.poseOverrides['actor']!.y, 8);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 320,
                child: CinematicActorDisplayPreviewOverlay(
                  model: overlay.displayModel,
                  playbackPoseOverrides: overlay.poseOverrides,
                  mapWidth: 16,
                  mapHeight: 16,
                  compact: false,
                ),
              ),
            ),
          ),
        );
      }

      await mount(0);
      final actor = find.byKey(
        const ValueKey('cinematic-builder-actor-display-actor-actor'),
      );
      final ground = tester.getTopLeft(actor);
      await mount(500);
      final raised = tester.getTopLeft(actor);
      expect(raised.dx, closeTo(ground.dx, .001));
      expect(raised.dy, closeTo(ground.dy - 20, .001));
      await mount(1000);
      expect(tester.getTopLeft(actor), ground);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
