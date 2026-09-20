import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';

void main() {
  test(
    'canonical intermediate movement, backwards scrub and stop never modify author asset',
    () {
      final asset = CinematicAsset(
        id: 'move',
        title: 'Déplacement',
        requiredActors: [CinematicActorRef(actorId: 'hero', label: 'Voyageur')],
        movementTargets: [
          CinematicMovementTargetRef(targetId: 'arrival', label: 'Arrivée'),
        ],
        stageContext: CinematicStageContext(
          initialPlacements: [
            CinematicActorInitialPlacement(
              actorId: 'hero',
              kind: CinematicActorInitialPlacementKind.stagePoint,
              stagePointId: 'start',
            ),
          ],
          stagePoints: [
            CinematicStagePoint(id: 'start', label: 'Départ', x: 0, y: 2),
            CinematicStagePoint(id: 'end', label: 'Arrivée', x: 8, y: 2),
          ],
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'arrival',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'end',
            ),
          ],
        ),
        timeline: CinematicTimeline(),
      );
      final project = ProjectManifest(
        name: 'Test',
        maps: [],
        tilesets: [],
        cinematics: [asset],
      );
      final moving = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: asset.id,
        actorId: 'hero',
        targetId: 'arrival',
        durationMs: 1000,
      ).cinematic;
      final original = moving.toJson();
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: moving,
        stageBounds: const CinematicPreviewPlaybackStageBounds(
          width: 12,
          height: 12,
        ),
      );
      final transport = CinematicPreviewTransport();
      addTearDown(transport.dispose);
      transport.install(plan);
      expect(transport.previewActive, isFalse);
      expect(transport.frame!.actorPoseById('hero')!.x, 0);
      transport.advance(400);
      expect(transport.frame!.actorPoseById('hero')!.x, closeTo(3.2, .001));
      final forward = transport.frame;
      transport.seek(900);
      expect(transport.previewActive, isTrue);
      transport.seek(400);
      expect(transport.frame, forward);
      transport.stop();
      expect(transport.previewActive, isFalse);
      expect(transport.frame!.actorPoseById('hero')!.x, 0);
      expect(moving.toJson(), original);
      transport.play();
      expect(transport.previewActive, isTrue);
      transport.advance(transport.durationMs);
      expect(transport.playing, isFalse);
      expect(transport.previewActive, isFalse);
      transport.seek(transport.durationMs);
      expect(transport.previewActive, isTrue);
    },
  );
  test(
    'eighty sequential actions keep one plan for ticks, pause and scrub',
    () {
      final asset = CinematicAsset(
        id: 'many',
        title: 'Longue séquence',
        timeline: CinematicTimeline(
          steps: [
            for (var i = 0; i < 80; i++)
              CinematicTimelineStep(
                id: 'step_$i',
                kind: CinematicTimelineStepKind.wait,
                durationMs: 100 + i,
              ),
          ],
        ),
      );
      final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
      final transport = CinematicPreviewTransport();
      addTearDown(transport.dispose);
      transport.install(plan);
      for (var i = 0; i < 80; i++) {
        transport.advance(100);
      }
      for (var i = 0; i < 8; i++) {
        transport.seek(i * 160);
      }
      expect(transport.plan, same(plan));
      expect(transport.frameEvaluations, 89);
      expect(plan.timelineItems.last.endMs, plan.totalDurationMs);
      for (var i = 1; i < plan.timelineItems.length; i++) {
        expect(plan.timelineItems[i].startMs, plan.timelineItems[i - 1].endMs);
      }
      expect(asset.timeline.steps.length, 80);
    },
  );
}
