import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_grid_edge_snapping.dart';

void main() {
  group('snapBorderGridVertex', () {
    const mapSize = GridSize(width: 5, height: 4);

    test('snaps to the nearest grid vertex after pan and zoom', () {
      final snapped = snapBorderGridVertex(
        localPosition: const Offset(85, 71),
        pan: const Offset(10, 7),
        zoom: 0.5,
        mapSize: mapSize,
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(snapped, const GridPos(x: 5, y: 4));
    });

    test('accepts the inclusive right and bottom canvas vertices', () {
      final snapped = snapBorderGridVertex(
        localPosition: const Offset(340, 212),
        pan: const Offset(20, 20),
        zoom: 2,
        mapSize: mapSize,
        tileWidth: 32,
        tileHeight: 24,
      );

      expect(snapped, const GridPos(x: 5, y: 4));
    });

    test('rejects positions outside the canvas before rounding', () {
      GridPos? snap(Offset position) => snapBorderGridVertex(
            localPosition: position,
            pan: const Offset(10, 20),
            zoom: 1,
            mapSize: mapSize,
            tileWidth: 32,
            tileHeight: 32,
          );

      expect(snap(const Offset(9.9, 20)), isNull);
      expect(snap(const Offset(10, 19.9)), isNull);
      expect(snap(const Offset(170.1, 20)), isNull);
      expect(snap(const Offset(10, 148.1)), isNull);
    });

    test('keeps the same vertex at 30, 50 and 100 percent zoom', () {
      const pan = Offset(13, 17);
      const worldPosition = Offset(68, 91);

      for (final zoom in <double>[0.3, 0.5, 1]) {
        final snapped = snapBorderGridVertex(
          localPosition: Offset(
            pan.dx + (worldPosition.dx * zoom),
            pan.dy + (worldPosition.dy * zoom),
          ),
          pan: pan,
          zoom: zoom,
          mapSize: mapSize,
          tileWidth: 32,
          tileHeight: 32,
        );

        expect(snapped, const GridPos(x: 2, y: 3), reason: 'zoom=$zoom');
      }
    });

    test('keeps inclusive right and bottom vertices at every tested zoom', () {
      const pan = Offset(13, 17);
      const worldBoundary = Offset(160, 128);

      for (final zoom in <double>[0.3, 0.5, 1]) {
        final snapped = snapBorderGridVertex(
          localPosition: Offset(
            pan.dx + worldBoundary.dx * zoom,
            pan.dy + worldBoundary.dy * zoom,
          ),
          pan: pan,
          zoom: zoom,
          mapSize: mapSize,
          tileWidth: 32,
          tileHeight: 32,
        );

        expect(snapped, const GridPos(x: 5, y: 4), reason: 'zoom=$zoom');
      }
    });

    test('rejects invalid transform and tile dimensions', () {
      GridPos? snap({required double zoom, double tileWidth = 32}) =>
          snapBorderGridVertex(
            localPosition: Offset.zero,
            pan: Offset.zero,
            zoom: zoom,
            mapSize: mapSize,
            tileWidth: tileWidth,
            tileHeight: 32,
          );

      expect(snap(zoom: 0), isNull);
      expect(snap(zoom: -1), isNull);
      expect(snap(zoom: 1, tileWidth: 0), isNull);
    });
  });
}
