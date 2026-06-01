import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildCinematicTimelineTimeLayoutReadModel', () {
    test('derives block timing from linear order with fallback durations', () {
      final cinematic = _cinematic();
      final before = cinematic.toJson();

      final readModel = buildCinematicTimelineTimeLayoutReadModel(cinematic);
      final secondReadModel =
          buildCinematicTimelineTimeLayoutReadModel(cinematic);

      expect(cinematic.toJson(), before);
      expect(readModel.stepCount, 5);
      expect(readModel.laneCount, 8);
      expect(readModel.totalDurationMs, 2900);
      expect(
        readModel.ticks.map((tick) => tick.label),
        ['0 ms', '500 ms', '1 s', '1.5 s', '2 s', '2.5 s', '2.9 s'],
      );
      expect(
        secondReadModel.blocks.map((block) => block.stepId),
        readModel.blocks.map((block) => block.stepId),
      );

      expect(
        readModel.blocks.map((block) => (
              block.stepId,
              block.stepIndex,
              block.startMs,
              block.endMs,
              block.visualDurationMs,
              block.durationSource,
              block.laneId,
            )),
        [
          (
            'step_camera',
            0,
            0,
            500,
            500,
            CinematicTimelineVisualDurationSource.explicit,
            'camera',
          ),
          (
            'step_face',
            1,
            500,
            800,
            cinematicTimelineFallbackVisualDurationMs,
            CinematicTimelineVisualDurationSource.fallback,
            'actor:actor_professor',
          ),
          (
            'step_wait',
            2,
            800,
            1100,
            cinematicTimelineFallbackVisualDurationMs,
            CinematicTimelineVisualDurationSource.fallback,
            'time-global',
          ),
          (
            'step_move',
            3,
            1100,
            2600,
            1500,
            CinematicTimelineVisualDurationSource.explicit,
            'actor:actor_professor',
          ),
          (
            'step_marker',
            4,
            2600,
            2900,
            cinematicTimelineFallbackVisualDurationMs,
            CinematicTimelineVisualDurationSource.fallback,
            'time-global',
          ),
        ],
      );

      final actorLane = readModel.laneById('actor:actor_professor')!;
      expect(actorLane.actorId, 'actor_professor');
      expect(actorLane.actorLabel, 'Professor');
      expect(actorLane.blocks.map((block) => block.stepId), [
        'step_face',
        'step_move',
      ]);
      expect(actorLane.blocks.last.label, 'Professor → Centre scène');
      expect(actorLane.blocks.last.targetId, 'target_center');
      expect(actorLane.blocks.last.targetLabel, 'Centre scène');
      expect(actorLane.blocks.last.badges, contains('Cible: Centre scène'));
    });

    test('handles empty timelines deterministically', () {
      final cinematic = CinematicAsset(
        id: 'cinematic_empty',
        title: 'Empty cinematic',
        timeline: CinematicTimeline(),
      );

      final readModel = buildCinematicTimelineTimeLayoutReadModel(cinematic);
      final secondReadModel =
          buildCinematicTimelineTimeLayoutReadModel(cinematic);

      expect(readModel.stepCount, 0);
      expect(readModel.totalDurationMs, 0);
      expect(readModel.blocks, isEmpty);
      expect(readModel.laneCount, 7);
      expect(readModel.ticks.map((tick) => tick.label), ['0 ms']);
      expect(secondReadModel.ticks.map((tick) => tick.label), ['0 ms']);
    });

    test('uses coarse ticks for long timelines', () {
      final readModel = buildCinematicTimelineTimeLayoutReadModel(
        CinematicAsset(
          id: 'cinematic_long',
          title: 'Long cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait_long',
                kind: CinematicTimelineStepKind.wait,
                label: 'Long wait',
                durationMs: 32000,
              ),
            ],
          ),
        ),
      );

      expect(readModel.totalDurationMs, 32000);
      expect(
        readModel.ticks.map((tick) => tick.label),
        ['0 ms', '10 s', '20 s', '30 s', '32 s'],
      );
      expect(readModel.ticks.where((tick) => tick.isMajor), hasLength(5));
    });

    test('keeps unknown actor blocks on derived actor lanes', () {
      final readModel = buildCinematicTimelineTimeLayoutReadModel(
        CinematicAsset(
          id: 'cinematic_unknown_actor',
          title: 'Unknown actor cinematic',
          movementTargets: [
            CinematicMovementTargetRef(
              targetId: 'target_center',
              label: 'Centre scène',
            ),
          ],
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_move_unknown',
                kind: CinematicTimelineStepKind.actorMove,
                label: 'Unknown move',
                actorId: 'actor_missing',
                targetId: 'target_center',
                durationMs: 900,
              ),
            ],
          ),
        ),
      );

      final unknownLane = readModel.laneById('actor:actor_missing')!;

      expect(unknownLane.label, 'Acteur inconnu: actor_missing');
      expect(unknownLane.blocks.single.stepId, 'step_move_unknown');
      expect(unknownLane.blocks.single.actorLabel, 'actor_missing');
      expect(unknownLane.blocks.single.targetLabel, 'Centre scène');
      expect(unknownLane.blocks.single.startMs, 0);
      expect(unknownLane.blocks.single.endMs, 900);
    });
  });
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_time_layout',
    title: 'Time layout cinematic',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
      ),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera reveal',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 0,
        ),
        CinematicTimelineStep(
          id: 'step_move',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Move Professor',
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1500,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
        CinematicTimelineStep(
          id: 'step_marker',
          kind: CinematicTimelineStepKind.marker,
          label: 'Marker',
          durationMs: -10,
        ),
      ],
    ),
  );
}
