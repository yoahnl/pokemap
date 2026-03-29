import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolvePlacedElementAnimationOneShotFrame', () {
    test('advances one cycle then marks as completed', () {
      final durations = normalizeElementFrameDurationsMs(
        const [100, 100, 100],
      );
      expect(
        resolvePlacedElementAnimationOneShotFrame(
          frameDurationsMs: durations,
          elapsedMs: 0,
        ),
        isA<PlacedElementAnimationOneShotFrame>()
            .having((value) => value.frameIndex, 'frameIndex', 0)
            .having((value) => value.completed, 'completed', false),
      );
      expect(
        resolvePlacedElementAnimationOneShotFrame(
          frameDurationsMs: durations,
          elapsedMs: 120,
        ),
        isA<PlacedElementAnimationOneShotFrame>()
            .having((value) => value.frameIndex, 'frameIndex', 1)
            .having((value) => value.completed, 'completed', false),
      );
      expect(
        resolvePlacedElementAnimationOneShotFrame(
          frameDurationsMs: durations,
          elapsedMs: 299,
        ),
        isA<PlacedElementAnimationOneShotFrame>()
            .having((value) => value.frameIndex, 'frameIndex', 2)
            .having((value) => value.completed, 'completed', false),
      );
      expect(
        resolvePlacedElementAnimationOneShotFrame(
          frameDurationsMs: durations,
          elapsedMs: 300,
        ),
        isA<PlacedElementAnimationOneShotFrame>()
            .having((value) => value.frameIndex, 'frameIndex', 2)
            .having((value) => value.completed, 'completed', true),
      );
    });

    test('applies speed multiplier', () {
      final durations = normalizeElementFrameDurationsMs(const [100, 100, 100]);
      expect(
        resolvePlacedElementAnimationOneShotFrame(
          frameDurationsMs: durations,
          elapsedMs: 70,
          speed: 2,
        ),
        isA<PlacedElementAnimationOneShotFrame>()
            .having((value) => value.frameIndex, 'frameIndex', 1)
            .having((value) => value.completed, 'completed', false),
      );
    });
  });
}
