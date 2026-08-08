import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/pixel_perfect_overworld_camera.dart';

void main() {
  group('PixelPerfectOverworldCameraController', () {
    test('resolves the captured Retina geometry to scale 2 and zoom 0.5', () {
      final fixture = _CameraFixture(devicePixelRatio: 2);

      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(960, 704))
        ..onViewportResize(Vector2(469, 328.5));

      expect(fixture.controller.physicalPixelsPerSourcePixel, 2);
      expect(fixture.controller.resolvedZoom, closeTo(0.5, 1e-12));
      expect(fixture.camera.viewfinder.visibleGameSize, isNull);
      expect(fixture.camera.viewfinder.zoom, closeTo(0.5, 1e-12));
    });

    test('rounds a physical scale of 1.49 down to 1', () {
      final fixture = _CameraFixture(devicePixelRatio: 1);

      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(100, 100))
        ..onViewportResize(Vector2(74.5, 100));

      expect(fixture.controller.physicalPixelsPerSourcePixel, 1);
    });

    test('rounds a physical scale of 1.50 up to 2', () {
      final fixture = _CameraFixture(devicePixelRatio: 1);

      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(100, 100))
        ..onViewportResize(Vector2(75, 100));

      expect(fixture.controller.physicalPixelsPerSourcePixel, 2);
    });

    for (final invalidDpr in <double>[
      0,
      -1,
      double.infinity,
      double.nan,
    ]) {
      test('falls back to DPR 1 for $invalidDpr', () {
        final fixture = _CameraFixture(devicePixelRatio: invalidDpr);

        fixture.controller
          ..setRequestedVisibleGameSize(Vector2(100, 100))
          ..onViewportResize(Vector2(75, 100));

        expect(fixture.controller.physicalPixelsPerSourcePixel, 2);
        expect(fixture.controller.resolvedZoom, closeTo(1, 1e-12));
      });
    }

    test('defers projection while the viewport is empty', () {
      final fixture = _CameraFixture(devicePixelRatio: 2);

      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(960, 704))
        ..onViewportResize(Vector2.zero());

      expect(fixture.controller.physicalPixelsPerSourcePixel, isNull);
      expect(fixture.controller.resolvedZoom, isNull);

      fixture.controller.onViewportResize(Vector2(469, 328.5));

      expect(fixture.controller.physicalPixelsPerSourcePixel, 2);
      expect(fixture.controller.resolvedZoom, closeTo(0.5, 1e-12));
    });

    test('keeps a repeated projection stable', () {
      final fixture = _CameraFixture(devicePixelRatio: 2);
      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(960, 704))
        ..onViewportResize(Vector2(469, 328.5))
        ..setPosition(Vector2(413.25, 177.75));
      final first = fixture.controller.position;

      fixture.controller
        ..onViewportResize(Vector2(469, 328.5))
        ..setPosition(Vector2(413.25, 177.75));

      expect(fixture.controller.position.x, closeTo(first.x, 1e-12));
      expect(fixture.controller.position.y, closeTo(first.y, 1e-12));
    });

    test('recalculates projection after a viewport size change', () {
      final fixture = _CameraFixture(devicePixelRatio: 2);
      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(960, 704))
        ..onViewportResize(Vector2(469, 328.5));
      expect(fixture.controller.physicalPixelsPerSourcePixel, 2);

      fixture.controller.onViewportResize(Vector2(720, 528));

      expect(fixture.controller.physicalPixelsPerSourcePixel, 3);
      expect(fixture.controller.resolvedZoom, closeTo(0.75, 1e-12));
    });

    test('recalculates projection only after a DPR change', () {
      var dprReads = 0;
      var dpr = 1.0;
      final camera = CameraComponent();
      final controller = PixelPerfectOverworldCameraController(
        camera: camera,
        displayScale: 2,
        devicePixelRatioProvider: () {
          dprReads++;
          return dpr;
        },
      )
        ..setRequestedVisibleGameSize(Vector2(960, 704))
        ..onViewportResize(Vector2(469, 328.5));
      final readsAfterProjection = dprReads;

      controller.refreshDevicePixelRatio();

      expect(dprReads, readsAfterProjection + 1);
      expect(controller.physicalPixelsPerSourcePixel, 1);

      dpr = 2;
      controller.refreshDevicePixelRatio();

      expect(controller.physicalPixelsPerSourcePixel, 2);
      expect(controller.resolvedZoom, closeTo(0.5, 1e-12));
    });

    test('aligns an even physical viewport origin to whole pixels', () {
      final fixture = _CameraFixture(devicePixelRatio: 2);
      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(960, 704))
        ..onViewportResize(Vector2(470, 330))
        ..setPosition(Vector2(413.25, 177.75));

      _expectPhysicalOriginAligned(
        controller: fixture.controller,
        logicalViewport: Vector2(470, 330),
        dpr: 2,
      );
    });

    test('aligns an odd physical viewport origin to whole pixels', () {
      final fixture = _CameraFixture(devicePixelRatio: 2);
      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(960, 704))
        ..onViewportResize(Vector2(469.5, 328.5))
        ..setPosition(Vector2(413.25, 177.75));

      _expectPhysicalOriginAligned(
        controller: fixture.controller,
        logicalViewport: Vector2(469.5, 328.5),
        dpr: 2,
      );
    });

    test('preserves physical alignment for negative positions', () {
      final fixture = _CameraFixture(devicePixelRatio: 2);
      fixture.controller
        ..setRequestedVisibleGameSize(Vector2(960, 704))
        ..onViewportResize(Vector2(469, 328.5))
        ..setPosition(Vector2(-127.25, -64.75));

      _expectPhysicalOriginAligned(
        controller: fixture.controller,
        logicalViewport: Vector2(469, 328.5),
        dpr: 2,
      );
    });
  });
}

final class _CameraFixture {
  _CameraFixture({required double devicePixelRatio})
      : camera = CameraComponent() {
    controller = PixelPerfectOverworldCameraController(
      camera: camera,
      displayScale: 2,
      devicePixelRatioProvider: () => devicePixelRatio,
    );
  }

  final CameraComponent camera;
  late final PixelPerfectOverworldCameraController controller;
}

void _expectPhysicalOriginAligned({
  required PixelPerfectOverworldCameraController controller,
  required Vector2 logicalViewport,
  required double dpr,
}) {
  final zoom = controller.resolvedZoom!;
  final position = controller.position;
  final physicalCenter = logicalViewport * (dpr / 2);
  final worldToPhysical = zoom * dpr;
  final origin = physicalCenter - position * worldToPhysical;

  expect(origin.x, closeTo(origin.x.roundToDouble(), 1e-9));
  expect(origin.y, closeTo(origin.y.roundToDouble(), 1e-9));
}
