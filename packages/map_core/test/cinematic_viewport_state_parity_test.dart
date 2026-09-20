import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  instantCameraTests();
  test('fade-out remains opaque after its block until the next fade-in', () {
    final plan = buildCinematicPreviewPlaybackPlan(cinematic: _asset());
    expect(plan.frameAt(250).fadeState?.opacity, closeTo(.5, .0001));
    expect(plan.frameAt(700).fadeState?.opacity, 1);
    expect(plan.frameAt(1100).fadeState?.opacity, closeTo(.5, .0001));
    expect(plan.frameAt(1400).fadeState?.opacity, 0);
  });

  test(
    'projection keeps camera endpoints, resets and scrubs deterministically',
    () {
      final asset = CinematicAsset(
        id: 'camera',
        title: 'Caméra',
        stageContext: CinematicStageContext(
          stagePoints: [
            CinematicStagePoint(id: 'target', label: 'Cible', x: 5, y: 10),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'focus',
              kind: CinematicTimelineStepKind.camera,
              durationMs: 1000,
              metadata: {
                cinematicTimelineCameraModeMetadataKey: 'focus',
                cinematicTimelineCameraTargetKindMetadataKey: 'stagePoint',
                cinematicTimelineCameraTargetStagePointIdMetadataKey: 'target',
                cinematicTimelineCameraZoomPresetMetadataKey: 'close',
              },
            ),
            CinematicTimelineStep(
              id: 'hold',
              kind: CinematicTimelineStepKind.camera,
              durationMs: 500,
              metadata: {cinematicTimelineCameraModeMetadataKey: 'hold'},
            ),
            CinematicTimelineStep(
              id: 'reset',
              kind: CinematicTimelineStepKind.camera,
              durationMs: 1000,
              metadata: {cinematicTimelineCameraModeMetadataKey: 'reset'},
            ),
            CinematicTimelineStep(
              id: 'last',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 500,
            ),
          ],
        ),
      );
      final before = asset.toJson();
      final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
      final projection = _projection(plan);
      final middle = projection.frameAt(500).camera;
      expect(middle.centerX, 50);
      expect(middle.centerY, 100);
      expect(middle.visibleWidth, 80);
      expect(middle.visibleHeight, 64);
      expect(projection.frameAt(1400).camera.centerX, 100);
      expect(projection.frameAt(1750).camera.centerX, 75);
      expect(projection.frameAt(1750).camera.visibleWidth, 70);
      expect(projection.frameAt(2900).camera.centerX, 0);
      expect(projection.frameAt(2900).camera.visibleWidth, 100);
      expect(projection.frameAt(500).camera.centerY, middle.centerY);
      expect(asset.toJson(), before);
    },
  );

  test(
    'projection shares shake envelope and preserves fade during following wait',
    () {
      final asset = _asset().copyWith(
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'shake',
              kind: CinematicTimelineStepKind.shake,
              durationMs: 1000,
            ),
            ..._asset().timeline.steps,
          ],
        ),
      );
      final projection = _projection(
        buildCinematicPreviewPlaybackPlan(cinematic: asset),
      );
      expect(projection.frameAt(500).shakeOffsetX, closeTo(-6, .0001));
      expect(projection.frameAt(1000).shakeOffsetX, 0);
      expect(projection.frameAt(1700).fadeOpacity, 1);
      expect(projection.frameAt(2100).fadeOpacity, .5);
      expect(projection.frameAt(0).fadeOpacity, isNull);
    },
  );

  test(
    'pixel projection quantizes zoom and snaps origins on physical pixels',
    () {
      final zoom = resolvePixelPerfectCameraZoom(
        viewportWidth: 1000,
        viewportHeight: 700,
        visibleWidth: 480,
        visibleHeight: 352,
        displayScale: 3,
        devicePixelRatio: 2,
      );
      expect(zoom, 2);
      final snapped = snapPixelPerfectCameraPosition(
        centerX: 10.13,
        centerY: 20.21,
        viewportWidth: 1000,
        viewportHeight: 700,
        zoom: zoom,
        devicePixelRatio: 2,
      );
      expect(snapped.originX, 479.5);
      expect(snapped.originY, 309.5);
      expect(snapped.centerX, 10.25);
      expect(snapped.centerY, 20.25);
    },
  );
}

void instantCameraTests() {
  test('instant focus precedes reset starting at the same timestamp', () {
    final plan = buildCinematicPreviewPlaybackPlan(
      cinematic: CinematicAsset(
        id: 'instant',
        title: 'Instant',
        stageContext: CinematicStageContext(
          stagePoints: [
            CinematicStagePoint(id: 'target', label: 'Cible', x: 5, y: 10),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'focus',
              kind: CinematicTimelineStepKind.camera,
              metadata: {
                cinematicTimelineCameraModeMetadataKey: 'focus',
                cinematicTimelineCameraTargetKindMetadataKey: 'stagePoint',
                cinematicTimelineCameraTargetStagePointIdMetadataKey: 'target',
                cinematicTimelineCameraZoomPresetMetadataKey: 'close',
              },
            ),
            CinematicTimelineStep(
              id: 'reset',
              kind: CinematicTimelineStepKind.camera,
              durationMs: 1000,
              metadata: {cinematicTimelineCameraModeMetadataKey: 'reset'},
            ),
          ],
        ),
      ),
    );
    expect(plan.timelineItems[1].startMs, 0);
    final frame = _projection(plan).frameAt(500);
    expect(frame.camera.centerX, 50);
    expect(frame.camera.centerY, 100);
    expect(frame.camera.visibleWidth, 80);
  });
}

CinematicViewportProjection _projection(CinematicPreviewPlaybackPlan plan) =>
    CinematicViewportProjection(
      plan: plan,
      initialCamera: const CinematicViewportCamera(
        centerX: 0,
        centerY: 0,
        visibleWidth: 100,
        visibleHeight: 80,
      ),
      cellWidth: 20,
      cellHeight: 20,
    );

CinematicAsset _asset() => CinematicAsset(
  id: 'fades',
  title: 'Fondu persistant',
  timeline: CinematicTimeline(
    steps: [
      CinematicTimelineStep(
        id: 'out',
        kind: CinematicTimelineStepKind.fade,
        durationMs: 500,
        metadata: {cinematicTimelineFadeModeMetadataKey: 'fadeOut'},
      ),
      CinematicTimelineStep(
        id: 'wait',
        kind: CinematicTimelineStepKind.wait,
        durationMs: 500,
      ),
      CinematicTimelineStep(
        id: 'in',
        kind: CinematicTimelineStepKind.fade,
        durationMs: 200,
        metadata: {cinematicTimelineFadeModeMetadataKey: 'fadeIn'},
      ),
      CinematicTimelineStep(
        id: 'last',
        kind: CinematicTimelineStepKind.wait,
        durationMs: 500,
      ),
    ],
  ),
);
