import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_painter/surface_animation_frame_resolver.dart';

void main() {
  group('resolveSurfaceAnimationFrameAtElapsedMs', () {
    test('selects the first frame at elapsed zero', () {
      final timeline = _timeline();

      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 0,
        ),
        same(timeline.frames[0]),
      );
    });

    test('selects frames by cumulative duration boundaries', () {
      final timeline = _timeline();

      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 99,
        ),
        same(timeline.frames[0]),
      );
      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 100,
        ),
        same(timeline.frames[1]),
      );
      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 199,
        ),
        same(timeline.frames[1]),
      );
      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 200,
        ),
        same(timeline.frames[2]),
      );
      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 399,
        ),
        same(timeline.frames[2]),
      );
    });

    test('loops after the total duration', () {
      final timeline = _timeline();

      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 400,
        ),
        same(timeline.frames[0]),
      );
      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 550,
        ),
        same(timeline.frames[1]),
      );
      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: 1000,
        ),
        same(timeline.frames[2]),
      );
    });

    test('normalizes negative elapsed time to the first frame', () {
      final timeline = _timeline();

      expect(
        resolveSurfaceAnimationFrameAtElapsedMs(
          timeline: timeline,
          elapsedMs: -50,
        ),
        same(timeline.frames[0]),
      );
    });
  });
}

SurfaceAnimationTimeline _timeline() {
  return SurfaceAnimationTimeline(
    frames: [
      _frame(column: 0, durationMs: 100),
      _frame(column: 1, durationMs: 100),
      _frame(column: 2, durationMs: 200),
    ],
  );
}

SurfaceAnimationFrame _frame({
  required int column,
  required int durationMs,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: 'water-atlas',
      column: column,
      row: 0,
    ),
    durationMs: durationMs,
  );
}
