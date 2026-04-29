import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_view_geometry.dart';

void main() {
  test('computeContainedImageRect preserves ratio and exposes letterbox', () {
    final rect = computeSurfaceStudioContainedImageRect(
      viewportSize: const Size(600, 400),
      imagePixelSize: const Size(736, 1024),
    );

    expect(rect.left, closeTo(156.25, 0.001));
    expect(rect.top, closeTo(0, 0.001));
    expect(rect.width, closeTo(287.5, 0.001));
    expect(rect.height, closeTo(400, 0.001));
  });

  test('hit testing ignores letterbox and maps fitted rect columns', () {
    final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
      viewportSize: const Size(600, 400),
      imagePixelSize: const Size(736, 1024),
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 23,
      frameCount: 32,
    );

    expect(
      surfaceStudioColumnAtViewportOffset(
        localPosition: const Offset(120, 200),
        geometry: geometry,
      ),
      isNull,
    );
    expect(
      surfaceStudioColumnAtViewportOffset(
        localPosition: const Offset(200, 200),
        geometry: geometry,
      ),
      4,
    );
    expect(
      surfaceStudioFrameAtViewportOffset(
        localPosition: const Offset(200, 7),
        geometry: geometry,
      ),
      1,
    );
  });

  test('column viewport rect and tile source rect share 1-based column rules',
      () {
    final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
      viewportSize: const Size(600, 400),
      imagePixelSize: const Size(736, 1024),
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 23,
      frameCount: 32,
    );

    final column4 = surfaceStudioColumnViewportRect(
      uiColumn: 4,
      geometry: geometry,
    );
    expect(column4.left, closeTo(193.75, 0.001));
    expect(column4.width, closeTo(12.5, 0.001));
    expect(geometry.fittedImageRect.contains(column4.center), isTrue);

    final source = surfaceStudioTileSourceRect(
      uiColumn: 4,
      frameIndex: 1,
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 23,
      frameCount: 32,
    );
    expect(source, const Rect.fromLTWH(96, 32, 32, 32));
  });

  test('fitWidth fills usable width and can exceed viewport height', () {
    final fitWidth = SurfaceStudioAtlasViewGeometry.fromFitWidth(
      viewportSize: const Size(600, 400),
      imagePixelSize: const Size(480, 1024),
      tileWidth: 40,
      tileHeight: 32,
      columnCount: 12,
      frameCount: 32,
    );
    final fitWhole = SurfaceStudioAtlasViewGeometry.fromMode(
      mode: SurfaceStudioAtlasViewMode.fitWhole,
      viewportSize: const Size(600, 400),
      imagePixelSize: const Size(480, 1024),
      tileWidth: 40,
      tileHeight: 32,
      columnCount: 12,
      frameCount: 32,
    );

    expect(fitWidth.fittedImageRect.left, closeTo(0, 0.001));
    expect(fitWidth.fittedImageRect.top, closeTo(0, 0.001));
    expect(fitWidth.fittedImageRect.width, closeTo(600, 0.001));
    expect(fitWidth.fittedImageRect.height, greaterThan(400));
    expect(fitWhole.fittedImageRect.height, lessThanOrEqualTo(400));

    expect(
      surfaceStudioColumnAtViewportOffset(
        localPosition: const Offset(175, 640),
        geometry: fitWidth,
      ),
      4,
    );
    expect(
      surfaceStudioFrameAtViewportOffset(
        localPosition: const Offset(175, 640),
        geometry: fitWidth,
      ),
      17,
    );
  });
}
