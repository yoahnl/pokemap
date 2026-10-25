import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/src/player/region_map_geometry.dart';

void main() {
  test('letterboxing uses the occupied image rectangle', () {
    final geometry = RegionMapGeometry(
      viewport: const Size(800, 600),
      imageSize: const Size(1600, 800),
    );
    expect(geometry.imageRect, const Rect.fromLTWH(0, 100, 800, 400));
    expect(geometry.project(const Offset(.25, .75)), const Offset(200, 400));
    expect(geometry.unproject(const Offset(200, 400)), const Offset(.25, .75));
  });

  test(
    'cover keeps the full image aspect and crops with an inverse projection',
    () {
      final geometry = RegionMapGeometry(
        viewport: const Size(800, 600),
        imageSize: const Size(1600, 800),
        fit: BoxFit.cover,
      );
      expect(geometry.imageRect, const Rect.fromLTWH(-200, 0, 1200, 600));
      expect(geometry.project(const Offset(.25, .75)), const Offset(100, 450));
      expect(
        geometry.unproject(const Offset(100, 450)),
        const Offset(.25, .75),
      );
    },
  );

  test('cover can reveal cropped points through centering and bounded pan', () {
    const viewport = Size(324, 364);
    const point = Offset(.05, .5);
    RegionMapGeometry geometry({Offset center = const Offset(.5, .5)}) =>
        RegionMapGeometry(
          viewport: viewport,
          imageSize: const Size(800, 400),
          fit: BoxFit.cover,
          center: center,
        );
    final initial = geometry();
    expect(initial.project(point).dx, lessThan(0));
    final centered = geometry(center: point);
    expect((Offset.zero & viewport).contains(centered.project(point)), isTrue);
    final panned = initial.pan(const Offset(100000, 0));
    expect((Offset.zero & viewport).contains(panned.project(point)), isTrue);
    expect(panned.transformedImageRect.left, 0);
    final inverse = centered.unproject(centered.project(point));
    expect(inverse.dx, closeTo(point.dx, 1e-9));
    expect(inverse.dy, closeTo(point.dy, 1e-9));
  });

  test('zoom and bounded pan share an invertible transform', () {
    final geometry = RegionMapGeometry(
      viewport: const Size(800, 600),
      imageSize: const Size(1600, 800),
      scale: 3,
      center: const Offset(.8, .2),
    );
    const point = Offset(.82, .26);
    final inverse = geometry.unproject(geometry.project(point));
    expect(inverse.dx, closeTo(point.dx, 1e-9));
    expect(inverse.dy, closeTo(point.dy, 1e-9));
    expect(
      geometry.transformedImageRect.contains(const Offset(400, 300)),
      isTrue,
    );
    final panned = geometry.pan(const Offset(100000, -100000));
    expect(panned.transformedImageRect.left, closeTo(0, 1e-9));
    expect(panned.transformedImageRect.bottom, closeTo(600, 1e-9));
  });

  test('extreme aspect ratios cannot pan the whole image off screen', () {
    for (final size in [const Size(10000, 1), const Size(1, 10000)]) {
      final geometry = RegionMapGeometry(
        viewport: const Size(800, 600),
        imageSize: size,
        scale: 3,
        center: const Offset(-100, 100),
      ).pan(const Offset(999999, 999999));
      expect(
        geometry.transformedImageRect.overlaps(
          const Rect.fromLTWH(0, 0, 800, 600),
        ),
        isTrue,
      );
    }
  });

  test('zoom is bounded and preserves the focal point away from an edge', () {
    final geometry = RegionMapGeometry(
      viewport: const Size(800, 600),
      imageSize: const Size(800, 600),
    );
    const focal = Offset(300, 250);
    final zoomed = geometry.zoom(2, focal);
    expect(zoomed.project(geometry.unproject(focal)), focal);
    expect(zoomed.zoom(99, focal).scale, 3);
    expect(zoomed.zoom(.01, focal).scale, 1);
  });
}
