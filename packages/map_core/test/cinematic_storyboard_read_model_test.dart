import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildCinematicStoryboardReadModel', () {
    test('derives ordered shots from markers and camera cuts', () {
      final cinematic = CinematicAsset(
        id: 'arrival',
        title: 'Arrivée au port',
        mapId: 'port_selbrume',
        requiredActors: [
          CinematicActorRef(actorId: 'lysa', label: 'Lysa'),
        ],
        timeline: CinematicTimeline(steps: [
          CinematicTimelineStep(
            id: 'marker_1',
            kind: CinematicTimelineStepKind.marker,
            label: 'Quai désert',
          ),
          CinematicTimelineStep(
            id: 'wait_1',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 500,
          ),
          CinematicTimelineStep(
            id: 'camera_1',
            kind: CinematicTimelineStepKind.camera,
            label: 'Gros plan Lysa',
            durationMs: 300,
            metadata: const {
              cinematicTimelineCameraModeMetadataKey: 'focus',
              cinematicTimelineCameraTargetKindMetadataKey: 'actor',
              cinematicTimelineCameraTargetActorIdMetadataKey: 'lysa',
              cinematicTimelineCameraZoomPresetMetadataKey: 'close',
            },
          ),
          CinematicTimelineStep(
            id: 'line_1',
            kind: CinematicTimelineStepKind.dialogueLine,
            actorId: 'lysa',
            dialogueText: 'Enfin.',
            durationMs: 1200,
          ),
        ]),
      );

      final model = buildCinematicStoryboardReadModel(cinematic);

      expect(model.locationLabel, 'port_selbrume');
      expect(model.totalDurationMs, 2000);
      expect(model.shots, hasLength(2));
      expect(model.shots.first.label, 'Quai désert');
      expect(model.shots.first.startMs, 0);
      expect(model.shots.first.durationMs, 500);
      expect(model.shots.last.label, 'Gros plan Lysa');
      expect(model.shots.last.startMs, 500);
      expect(model.shots.last.durationMs, 1500);
      expect(model.shots.last.cameraFraming, 'Lysa · Rapproché');
      expect(model.shots.last.actorLabels, ['Lysa']);
      expect(model.shots.last.diagnostics, isEmpty);
    });

    test('reports deleted actor, point and missing map without throwing', () {
      final cinematic = CinematicAsset(
        id: 'broken',
        title: 'Broken blocking',
        timeline: CinematicTimeline(steps: [
          CinematicTimelineStep(
            id: 'camera',
            kind: CinematicTimelineStepKind.camera,
            metadata: const {
              cinematicTimelineCameraModeMetadataKey: 'focus',
              cinematicTimelineCameraTargetKindMetadataKey: 'stagePoint',
              cinematicTimelineCameraTargetStagePointIdMetadataKey:
                  'deleted_point',
            },
          ),
          CinematicTimelineStep(
            id: 'move',
            kind: CinematicTimelineStepKind.actorMove,
            actorId: 'deleted_actor',
            targetId: 'deleted_target',
          ),
        ]),
      );

      final model = buildCinematicStoryboardReadModel(cinematic);

      expect(model.hasDiagnostics, isTrue);
      expect(
          model.shots.single.diagnostics,
          containsAll([
            CinematicStoryboardDiagnostic.missingMap,
            CinematicStoryboardDiagnostic.missingActor,
            CinematicStoryboardDiagnostic.missingMovementTarget,
            CinematicStoryboardDiagnostic.missingStagePoint,
          ]));
    });

    test('keeps an empty cinematic readable as one setup shot', () {
      final model = buildCinematicStoryboardReadModel(
        CinematicAsset(
          id: 'empty',
          title: 'Empty',
          timeline: CinematicTimeline(),
        ),
      );

      expect(model.shots, hasLength(1));
      expect(model.shots.single.label, 'Mise en place');
      expect(model.shots.single.stepIds, isEmpty);
      expect(model.shots.single.diagnostics,
          contains(CinematicStoryboardDiagnostic.emptyShot));
    });
  });
}
