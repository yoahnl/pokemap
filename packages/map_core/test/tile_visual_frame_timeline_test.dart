import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('TileVisualFrameTimeline', () {
    group('empty frames', () {
      test('staticFrame resolves to a completed empty result', () {
        final resolution = resolveTileVisualFrameTimeline(
          frames: const [],
          elapsedMs: 1000,
          mode: TileVisualFrameTimelinePlaybackMode.staticFrame,
        );

        expect(resolution.frame, isNull);
        expect(resolution.frameIndex, 0);
        expect(resolution.completed, isTrue);
      });

      test('loop resolves to a completed empty result', () {
        final resolution = resolveTileVisualFrameTimeline(
          frames: const [],
          elapsedMs: 1000,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        );

        expect(resolution.frame, isNull);
        expect(resolution.frameIndex, 0);
        expect(resolution.completed, isTrue);
      });

      test('oneShot resolves to a completed empty result', () {
        final resolution = resolveTileVisualFrameTimeline(
          frames: const [],
          elapsedMs: 1000,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        );

        expect(resolution.frame, isNull);
        expect(resolution.frameIndex, 0);
        expect(resolution.completed, isTrue);
      });
    });

    group('single frame', () {
      test('staticFrame returns the frame and is completed', () {
        final frame = visualFrame(0, durationMs: 100);

        final resolution = resolveTileVisualFrameTimeline(
          frames: [frame],
          elapsedMs: 999,
          mode: TileVisualFrameTimelinePlaybackMode.staticFrame,
        );

        expect(resolution.frame, same(frame));
        expect(resolution.frameIndex, 0);
        expect(resolution.completed, isTrue);
      });

      test('loop returns the frame and remains non-completing', () {
        final frame = visualFrame(0, durationMs: 100);

        final resolution = resolveTileVisualFrameTimeline(
          frames: [frame],
          elapsedMs: 999,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        );

        expect(resolution.frame, same(frame));
        expect(resolution.frameIndex, 0);
        expect(resolution.completed, isFalse);
      });

      test('oneShot returns the frame and is completed', () {
        final frame = visualFrame(0, durationMs: 100);

        final resolution = resolveTileVisualFrameTimeline(
          frames: [frame],
          elapsedMs: 999,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        );

        expect(resolution.frame, same(frame));
        expect(resolution.frameIndex, 0);
        expect(resolution.completed, isTrue);
      });
    });

    test('staticFrame with multiple frames always returns the first frame', () {
      final frames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 100),
        visualFrame(2, durationMs: 100),
      ];

      for (final elapsedMs in const [0.0, 100.0, 250.0, 9999.0]) {
        final resolution = resolveTileVisualFrameTimeline(
          frames: frames,
          elapsedMs: elapsedMs,
          mode: TileVisualFrameTimelinePlaybackMode.staticFrame,
          speed: 10,
        );

        expect(resolution.frame, same(frames.first));
        expect(resolution.frameIndex, 0);
        expect(resolution.completed, isTrue);
      }
    });

    test('loop with two equal frames follows frame boundaries', () {
      final frames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 100),
      ];

      expect(
        resolveIndex(
          frames,
          elapsedMs: 0,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        0,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 99,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        0,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 100,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        1,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 199,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        1,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 200,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        0,
      );
    });

    test('loop with uneven frame durations follows cumulative boundaries', () {
      final frames = [
        visualFrame(0, durationMs: 50),
        visualFrame(1, durationMs: 150),
        visualFrame(2, durationMs: 300),
      ];

      expect(
        resolveIndex(
          frames,
          elapsedMs: 0,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        0,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 49,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        0,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 50,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        1,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 199,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        1,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 200,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        2,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 499,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        2,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 500,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        0,
      );
    });

    test('oneShot advances once, clamps at the last frame, and completes', () {
      final frames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 100),
        visualFrame(2, durationMs: 100),
      ];

      expect(
        resolveTimeline(
          frames,
          elapsedMs: 0,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        ),
        isA<TileVisualFrameTimelineResolution>()
            .having((value) => value.frame, 'frame', same(frames[0]))
            .having((value) => value.frameIndex, 'frameIndex', 0)
            .having((value) => value.completed, 'completed', false),
      );
      expect(
        resolveTimeline(
          frames,
          elapsedMs: 150,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        ),
        isA<TileVisualFrameTimelineResolution>()
            .having((value) => value.frame, 'frame', same(frames[1]))
            .having((value) => value.frameIndex, 'frameIndex', 1)
            .having((value) => value.completed, 'completed', false),
      );
      expect(
        resolveTimeline(
          frames,
          elapsedMs: 299,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        ),
        isA<TileVisualFrameTimelineResolution>()
            .having((value) => value.frame, 'frame', same(frames[2]))
            .having((value) => value.frameIndex, 'frameIndex', 2)
            .having((value) => value.completed, 'completed', false),
      );
      expect(
        resolveTimeline(
          frames,
          elapsedMs: 300,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        ),
        isA<TileVisualFrameTimelineResolution>()
            .having((value) => value.frame, 'frame', same(frames[2]))
            .having((value) => value.frameIndex, 'frameIndex', 2)
            .having((value) => value.completed, 'completed', true),
      );
      expect(
        resolveTimeline(
          frames,
          elapsedMs: 999,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        ),
        isA<TileVisualFrameTimelineResolution>()
            .having((value) => value.frame, 'frame', same(frames[2]))
            .having((value) => value.frameIndex, 'frameIndex', 2)
            .having((value) => value.completed, 'completed', true),
      );
    });

    test('invalid and null durations use the existing default duration', () {
      final frames = [
        visualFrame(0, durationMs: 0),
        visualFrame(1, durationMs: -10),
        visualFrame(2),
      ];

      expect(defaultPlacedElementAnimationFrameDurationMs, 200);
      expect(
        resolveIndex(
          frames,
          elapsedMs: 199,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        0,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 200,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        1,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 399,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        1,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 400,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        2,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 599,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        2,
      );
      expect(
        resolveIndex(
          frames,
          elapsedMs: 600,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        ),
        0,
      );
    });

    test('speed less than or equal to zero follows placed animation fallback',
        () {
      final frames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 100),
        visualFrame(2, durationMs: 100),
      ];

      final loopResolution = resolveTileVisualFrameTimeline(
        frames: frames,
        elapsedMs: 120,
        mode: TileVisualFrameTimelinePlaybackMode.loop,
        speed: 0,
      );
      final loopExistingIndex = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: normalizeElementFrameDurationsMs(
          frames.map((frame) => frame.durationMs).toList(growable: false),
        ),
        elapsedMs: 120,
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          speed: 0,
        ),
      );

      expect(loopResolution.frameIndex, loopExistingIndex);
      expect(loopResolution.frameIndex, 1);

      final oneShotResolution = resolveTileVisualFrameTimeline(
        frames: frames,
        elapsedMs: 120,
        mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        speed: -1,
      );
      final oneShotExisting = resolvePlacedElementAnimationOneShotFrame(
        frameDurationsMs: normalizeElementFrameDurationsMs(
          frames.map((frame) => frame.durationMs).toList(growable: false),
        ),
        elapsedMs: 120,
        speed: -1,
      );

      expect(oneShotResolution.frameIndex, oneShotExisting.frameIndex);
      expect(oneShotResolution.completed, oneShotExisting.completed);
      expect(oneShotResolution.frameIndex, 1);
    });

    test('preserves the exact selected TilesetVisualFrame object', () {
      const frame = TilesetVisualFrame(
        tilesetId: 'water_fx_tileset',
        source: TilesetSourceRect(x: 7, y: 9, width: 2, height: 3),
        durationMs: 120,
      );
      final frames = [
        visualFrame(0, durationMs: 100),
        frame,
      ];

      final resolution = resolveTileVisualFrameTimeline(
        frames: frames,
        elapsedMs: 100,
        mode: TileVisualFrameTimelinePlaybackMode.loop,
      );

      expect(resolution.frame, same(frame));
      expect(resolution.frame?.tilesetId, 'water_fx_tileset');
      expect(
        resolution.frame?.source,
        const TilesetSourceRect(x: 7, y: 9, width: 2, height: 3),
      );
      expect(resolution.frame?.durationMs, 120);
    });

    test('does not mutate the received frames list', () {
      final frames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 100),
      ];
      final before = List<TilesetVisualFrame>.from(frames);

      resolveTileVisualFrameTimeline(
        frames: frames,
        elapsedMs: 100,
        mode: TileVisualFrameTimelinePlaybackMode.loop,
      );

      expect(frames, before);
    });

    test('loop index stays coherent with placed element animation helper', () {
      final frames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 300),
        visualFrame(2, durationMs: 100),
      ];
      final durations = normalizeElementFrameDurationsMs(
        frames.map((frame) => frame.durationMs).toList(growable: false),
      );

      for (final elapsedMs in const [0.0, 90.0, 100.0, 250.0, 499.0, 500.0]) {
        final timeline = resolveTileVisualFrameTimeline(
          frames: frames,
          elapsedMs: elapsedMs,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
          speed: 1.5,
        );
        final existing = resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: elapsedMs,
          animation: const MapPlacedElementAnimation(
            enabled: true,
            mode: MapPlacedElementAnimationMode.loop,
            speed: 1.5,
          ),
        );

        expect(timeline.frameIndex, existing);
        expect(timeline.frame, same(frames[existing]));
      }
    });

    test('oneShot result stays coherent with placed one-shot helper', () {
      final frames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 100),
        visualFrame(2, durationMs: 100),
      ];
      final durations = normalizeElementFrameDurationsMs(
        frames.map((frame) => frame.durationMs).toList(growable: false),
      );

      for (final elapsedMs in const [0.0, 99.0, 100.0, 250.0, 300.0, 999.0]) {
        final timeline = resolveTileVisualFrameTimeline(
          frames: frames,
          elapsedMs: elapsedMs,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
          speed: 2,
        );
        final existing = resolvePlacedElementAnimationOneShotFrame(
          frameDurationsMs: durations,
          elapsedMs: elapsedMs,
          speed: 2,
        );

        expect(timeline.frameIndex, existing.frameIndex);
        expect(timeline.completed, existing.completed);
        expect(timeline.frame, same(frames[existing.frameIndex]));
      }
    });
  });
}

TilesetVisualFrame visualFrame(int x, {int? durationMs}) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: x, y: 0),
    durationMs: durationMs,
  );
}

TileVisualFrameTimelineResolution resolveTimeline(
  List<TilesetVisualFrame> frames, {
  required double elapsedMs,
  required TileVisualFrameTimelinePlaybackMode mode,
  double speed = 1.0,
}) {
  return resolveTileVisualFrameTimeline(
    frames: frames,
    elapsedMs: elapsedMs,
    mode: mode,
    speed: speed,
  );
}

int resolveIndex(
  List<TilesetVisualFrame> frames, {
  required double elapsedMs,
  required TileVisualFrameTimelinePlaybackMode mode,
  double speed = 1.0,
}) {
  return resolveTimeline(
    frames,
    elapsedMs: elapsedMs,
    mode: mode,
    speed: speed,
  ).frameIndex;
}
