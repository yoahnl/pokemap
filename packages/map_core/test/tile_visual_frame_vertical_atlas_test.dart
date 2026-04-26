// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('createTileVisualFramesFromVerticalAtlas', () {
    group('simple vertical frames', () {
      test('generates frames with correct vertical positions', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 3,
          startRow: 0,
          frameCount: 4,
        );

        expect(frames, hasLength(4));
        
        // Verify each frame has correct source position
        expect(frames[0].source.x, 3);
        expect(frames[0].source.y, 0);
        expect(frames[0].source.width, 1);
        expect(frames[0].source.height, 1);

        expect(frames[1].source.x, 3);
        expect(frames[1].source.y, 1);
        expect(frames[1].source.width, 1);
        expect(frames[1].source.height, 1);

        expect(frames[2].source.x, 3);
        expect(frames[2].source.y, 2);
        expect(frames[2].source.width, 1);
        expect(frames[2].source.height, 1);

        expect(frames[3].source.x, 3);
        expect(frames[3].source.y, 3);
        expect(frames[3].source.width, 1);
        expect(frames[3].source.height, 1);

        // Verify default duration
        expect(frames[0].durationMs, defaultPlacedElementAnimationFrameDurationMs);
        expect(frames[1].durationMs, defaultPlacedElementAnimationFrameDurationMs);
        expect(frames[2].durationMs, defaultPlacedElementAnimationFrameDurationMs);
        expect(frames[3].durationMs, defaultPlacedElementAnimationFrameDurationMs);

        // Verify empty tilesetId
        expect(frames[0].tilesetId, '');
        expect(frames[1].tilesetId, '');
        expect(frames[2].tilesetId, '');
        expect(frames[3].tilesetId, '');
      });

      test('respects startRow parameter', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 2,
          startRow: 10,
          frameCount: 3,
        );

        expect(frames, hasLength(3));
        expect(frames[0].source.y, 10);
        expect(frames[1].source.y, 11);
        expect(frames[2].source.y, 12);
      });

      test('respects sourceWidth and sourceHeight', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 1,
          startRow: 0,
          frameCount: 2,
          sourceWidth: 2,
          sourceHeight: 3,
        );

        expect(frames, hasLength(2));
        expect(frames[0].source.width, 2);
        expect(frames[0].source.height, 3);
        expect(frames[1].source.width, 2);
        expect(frames[1].source.height, 3);
      });

      test('preserves tilesetId', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 0,
          startRow: 0,
          frameCount: 2,
          tilesetId: 'animated-water-atlas',
        );

        expect(frames[0].tilesetId, 'animated-water-atlas');
        expect(frames[1].tilesetId, 'animated-water-atlas');
      });
    });

    group('frame durations', () {
      test('applies common duration to all frames', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 0,
          frameCount: 3,
          defaultDurationMs: 80,
          frameDurationsMs: null,
        );

        expect(frames[0].durationMs, 80);
        expect(frames[1].durationMs, 80);
        expect(frames[2].durationMs, 80);
      });

      test('applies per-frame durations', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 0,
          frameCount: 3,
          frameDurationsMs: [50, 100, 150],
        );

        expect(frames[0].durationMs, 50);
        expect(frames[1].durationMs, 100);
        expect(frames[2].durationMs, 150);
      });

      test('replaces null durations with default', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 0,
          frameCount: 3,
          defaultDurationMs: 90,
          frameDurationsMs: [50, null, 150],
        );

        expect(frames[0].durationMs, 50);
        expect(frames[1].durationMs, 90); // null replaced with default
        expect(frames[2].durationMs, 150);
      });
    });

    group('immutability', () {
      test('returns unmodifiable list', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 0,
          frameCount: 2,
        );

        expect(() => frames.add(frames[0]), throwsUnsupportedError);
      });

      test('does not mutate input frameDurationsMs', () {
        final durations = <int?>[50, null, 150];
        final originalDurations = List.of(durations);

        createTileVisualFramesFromVerticalAtlas(
          column: 0,
          frameCount: 3,
          frameDurationsMs: durations,
        );

        expect(durations, originalDurations);
      });
    });

    group('compatibility with timeline resolver', () {
      test('generated frames work with resolveTileVisualFrameTimeline', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 5,
          frameCount: 3,
          frameDurationsMs: [100, 100, 100],
        );

        final resolution = resolveTileVisualFrameTimeline(
          frames: frames,
          elapsedMs: 100,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        );

        expect(resolution.frameIndex, 1);
        expect(resolution.frame, frames[1]);
        expect(resolution.frame?.source.x, 5);
        expect(resolution.frame?.source.y, 1);
      });

      test('generated frames work with oneShot mode', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 2,
          frameCount: 4,
          frameDurationsMs: [50, 50, 50, 50],
        );

        // At 150ms, should be on frame 3 (0-indexed)
        final resolution = resolveTileVisualFrameTimeline(
          frames: frames,
          elapsedMs: 150,
          mode: TileVisualFrameTimelinePlaybackMode.oneShot,
        );

        expect(resolution.frameIndex, 3);
        expect(resolution.frame, frames[3]);
      });
    });

    group('validation', () {
      test('throws ValidationException for negative column', () {
        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: -1,
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for negative startRow', () {
        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            startRow: -1,
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for non-positive frameCount', () {
        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 0,
          ),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: -1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for non-positive sourceWidth', () {
        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 1,
            sourceWidth: 0,
          ),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 1,
            sourceWidth: -1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for non-positive sourceHeight', () {
        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 1,
            sourceHeight: 0,
          ),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 1,
            sourceHeight: -1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for non-positive defaultDurationMs', () {
        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 1,
            defaultDurationMs: 0,
          ),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 1,
            defaultDurationMs: -10,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException when frameDurationsMs length mismatches', () {
        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 3,
            frameDurationsMs: [100, 100],
          ),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 2,
            frameDurationsMs: [100, 100, 100],
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for non-positive frame durations', () {
        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 3,
            frameDurationsMs: [100, 0, 100],
          ),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => createTileVisualFramesFromVerticalAtlas(
            column: 0,
            frameCount: 3,
            frameDurationsMs: [100, -10, 100],
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('edge cases', () {
      test('handles single frame', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 5,
          frameCount: 1,
        );

        expect(frames, hasLength(1));
        expect(frames[0].source.x, 5);
        expect(frames[0].source.y, 0);
      });

      test('handles large frame counts', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 0,
          frameCount: 100,
        );

        expect(frames, hasLength(100));
        expect(frames[0].source.y, 0);
        expect(frames[99].source.y, 99);
      });

      test('handles custom source dimensions', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 2,
          frameCount: 3,
          sourceWidth: 4,
          sourceHeight: 2,
        );

        expect(frames[0].source.width, 4);
        expect(frames[0].source.height, 2);
        expect(frames[1].source.width, 4);
        expect(frames[1].source.height, 2);
      });

      test('preserves empty tilesetId', () {
        final frames = createTileVisualFramesFromVerticalAtlas(
          column: 0,
          frameCount: 1,
          tilesetId: '',
        );

        expect(frames[0].tilesetId, '');
      });
    });
  });
}
