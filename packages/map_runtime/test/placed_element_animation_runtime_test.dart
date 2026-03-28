import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  group('placed element animation runtime resolution', () {
    test('single frame always resolves to index zero', () {
      const animation = MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: true,
      );
      final durations = normalizeElementFrameDurationsMs(const [120]);
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 0,
          animation: animation,
        ),
        0,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 10000,
          animation: animation,
        ),
        0,
      );
    });

    test('loop mode advances forward and wraps', () {
      const animation = MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: true,
        speed: 1,
      );
      final durations = normalizeElementFrameDurationsMs(
        const [100, 100, 100],
      );

      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 0,
          animation: animation,
        ),
        0,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 120,
          animation: animation,
        ),
        1,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 260,
          animation: animation,
        ),
        2,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 320,
          animation: animation,
        ),
        0,
      );
    });

    test('pingPong mode bounces', () {
      const animation = MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.pingPong,
        autoplay: true,
        speed: 1,
      );
      final durations = normalizeElementFrameDurationsMs(
        const [100, 100, 100],
      );

      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 0,
          animation: animation,
        ),
        0,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 100,
          animation: animation,
        ),
        1,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 200,
          animation: animation,
        ),
        2,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 320,
          animation: animation,
        ),
        1,
      );
    });

    test('autoplay false keeps fixed start frame', () {
      const animation = MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: false,
        speed: 1,
        startOffsetMs: 250,
      );
      final durations = normalizeElementFrameDurationsMs(
        const [100, 100, 100],
      );
      final frameA = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: durations,
        elapsedMs: 0,
        animation: animation,
      );
      final frameB = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: durations,
        elapsedMs: 1800,
        animation: animation,
      );
      expect(frameA, frameB);
    });

    test('randomStart is stable per deterministic seed', () {
      const animation = MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: true,
        speed: 1,
        randomStart: true,
      );
      final durations = normalizeElementFrameDurationsMs(
        const [100, 100, 100, 100],
      );
      final seedA = stableHash32('instance_a');
      final seedB = stableHash32('instance_b');

      final a1 = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: durations,
        elapsedMs: 0,
        animation: animation,
        deterministicSeed: seedA,
      );
      final a2 = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: durations,
        elapsedMs: 0,
        animation: animation,
        deterministicSeed: seedA,
      );
      final b = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: durations,
        elapsedMs: 0,
        animation: animation,
        deterministicSeed: seedB,
      );

      expect(a1, a2);
      expect(b, inInclusiveRange(0, 3));
    });

    test('respects different frame durations in loop mode', () {
      const animation = MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: true,
        speed: 1,
      );
      final durations = normalizeElementFrameDurationsMs(
        const [100, 300, 100],
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 90,
          animation: animation,
        ),
        0,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 200,
          animation: animation,
        ),
        1,
      );
      expect(
        resolvePlacedElementAnimationFrameIndex(
          frameDurationsMs: durations,
          elapsedMs: 480,
          animation: animation,
        ),
        2,
      );
    });
  });
}
