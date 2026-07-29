import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/map_viewport_navigation.dart';

void main() {
  group('MapViewportNavigation pure geometry', () {
    test('pans without changing zoom', () {
      const initial = MapViewport(
        zoom: 1.5,
        panOffset: Offset(10, 20),
      );

      final result = MapViewportNavigation.panBy(
        viewport: initial,
        delta: const Offset(12, -8),
      );

      expect(result.zoom, 1.5);
      expect(result.panOffset, const Offset(22, 12));
    });

    test('zooms around the pointer without moving its world anchor', () {
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(10, 20),
      );
      const pointer = Offset(110, 220);

      final result = MapViewportNavigation.zoomAt(
        viewport: initial,
        focalPoint: pointer,
        targetZoom: 4,
      );

      expect(result.zoom, 4);
      expect(result.panOffset, const Offset(-90, -180));
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: result,
          viewportPoint: pointer,
        ),
        const Offset(50, 100),
      );
    });

    test('clamps zoom while preserving the pointer anchor', () {
      const initial = MapViewport(
        zoom: 1,
        panOffset: Offset(-50, 25),
      );
      const pointer = Offset(75, 125);
      final worldBefore = MapViewportNavigation.worldPointAt(
        viewport: initial,
        viewportPoint: pointer,
      );

      final result = MapViewportNavigation.zoomAt(
        viewport: initial,
        focalPoint: pointer,
        targetZoom: 99,
      );

      expect(result.zoom, MapViewportNavigation.maxZoom);
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: result,
          viewportPoint: pointer,
        ),
        worldBefore,
      );
    });

    test('converts command wheel deltas to multiplicative anchored zoom', () {
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(30, 40),
      );
      const pointer = Offset(330, 240);
      final worldBefore = MapViewportNavigation.worldPointAt(
        viewport: initial,
        viewportPoint: pointer,
      );

      final zoomIn = MapViewportNavigation.zoomFromScroll(
        viewport: initial,
        focalPoint: pointer,
        scrollDeltaY: -120,
      );
      final zoomOut = MapViewportNavigation.zoomFromScroll(
        viewport: initial,
        focalPoint: pointer,
        scrollDeltaY: 120,
      );

      expect(zoomIn.zoom, greaterThan(initial.zoom));
      expect(zoomOut.zoom, lessThan(initial.zoom));
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: zoomIn,
          viewportPoint: pointer,
        ),
        worldBefore,
      );
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: zoomOut,
          viewportPoint: pointer,
        ),
        worldBefore,
      );
    });

    test('resolves cumulative native pan and pinch from one start snapshot',
        () {
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(10, 20),
      );
      const focalPoint = Offset(110, 220);

      final result = MapViewportNavigation.panZoomFromStart(
        startViewport: initial,
        startFocalPoint: focalPoint,
        cumulativePan: const Offset(20, -10),
        scale: 1.5,
      );

      expect(result.zoom, 3);
      expect(result.panOffset, const Offset(-20, -90));
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: result,
          viewportPoint: focalPoint + const Offset(20, -10),
        ),
        const Offset(50, 100),
      );
    });

    test('repeated absolute pan zoom updates cannot accumulate drift', () {
      const initial = MapViewport(
        zoom: 1.25,
        panOffset: Offset(-30, 45),
      );
      const focalPoint = Offset(280, 190);

      MapViewport resolve(Offset pan, double scale) {
        return MapViewportNavigation.panZoomFromStart(
          startViewport: initial,
          startFocalPoint: focalPoint,
          cumulativePan: pan,
          scale: scale,
        );
      }

      final first = resolve(const Offset(12, -4), 1.2);
      final repeated = resolve(const Offset(12, -4), 1.2);
      final directFinal = resolve(const Offset(40, 18), 0.75);
      final finalAfterIntermediate = resolve(const Offset(40, 18), 0.75);

      expect(repeated.zoom, first.zoom);
      expect(repeated.panOffset, first.panOffset);
      expect(finalAfterIntermediate.zoom, directFinal.zoom);
      expect(finalAfterIntermediate.panOffset, directFinal.panOffset);
    });

    test('fits and centers the complete map with a safe margin', () {
      final result = MapViewportNavigation.fitMap(
        mapPixelSize: const Size(640, 320),
        viewportSize: const Size(1000, 700),
        margin: 40,
      );

      expect(result.zoom, 1.4375);
      expect(result.panOffset, const Offset(40, 120));
    });

    test('fit clamps tiny maps to the maximum zoom', () {
      final result = MapViewportNavigation.fitMap(
        mapPixelSize: const Size(8, 8),
        viewportSize: const Size(1000, 700),
      );

      expect(result.zoom, MapViewportNavigation.maxZoom);
      expect(result.panOffset, const Offset(480, 330));
    });

    test('fit clamps huge maps to the minimum zoom', () {
      final result = MapViewportNavigation.fitMap(
        mapPixelSize: const Size(20000, 10000),
        viewportSize: const Size(1000, 700),
      );

      expect(result.zoom, MapViewportNavigation.minZoom);
      expect(result.panOffset, const Offset(-500, -150));
    });

    test('centers the map without changing the current zoom', () {
      final result = MapViewportNavigation.centerMap(
        mapPixelSize: const Size(640, 320),
        viewportSize: const Size(1000, 700),
        zoom: 2,
      );

      expect(result.zoom, 2);
      expect(result.panOffset, const Offset(-140, 30));
    });

    test('sets 100 percent around the viewport center', () {
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(-300, -100),
      );
      const viewportSize = Size(1000, 700);
      final center = viewportSize.center(Offset.zero);
      final worldBefore = MapViewportNavigation.worldPointAt(
        viewport: initial,
        viewportPoint: center,
      );

      final result = MapViewportNavigation.actualSize(
        viewport: initial,
        viewportSize: viewportSize,
      );

      expect(result.zoom, 1);
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: result,
          viewportPoint: center,
        ),
        worldBefore,
      );
    });
  });
}
