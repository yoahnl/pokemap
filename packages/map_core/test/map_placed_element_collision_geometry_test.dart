import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('inverse sampled rectangles match every destination center', () {
    for (var q = 0; q < 4; q++) {
      for (var width = 1; width <= 7; width++) {
        for (var height = 1; height <= 5; height++) {
          final transform = QuarterTurnPixelTransform(
            sourcePixelSize: const GridSize(width: 5, height: 3),
            destinationPixelSize: GridSize(width: width, height: height),
            quarterTurns: q,
          );
          for (var sy = 0; sy < 3; sy++) {
            for (var sx = 0; sx < 5; sx++) {
              final rect = transform.sourcePixelRectToDestinationPixelRect(
                PixelRect(leftPx: sx, topPx: sy, widthPx: 1, heightPx: 1),
              );
              for (var y = 0; y < height; y++) {
                for (var x = 0; x < width; x++) {
                  final source = transform.destinationPixelToSourcePixel(
                    GridPos(x: x, y: y),
                  );
                  expect(
                    x >= rect.leftPx &&
                        x < rect.leftPx + rect.widthPx &&
                        y >= rect.topPx &&
                        y < rect.topPx + rect.heightPx,
                    source.x == sx && source.y == sy,
                  );
                }
              }
            }
          }
        }
      }
    }
  });

  test('inverse interval handles products above exact web integers', () {
    final transform = QuarterTurnPixelTransform(
      sourcePixelSize: const GridSize(width: 9007199254740000, height: 1),
      destinationPixelSize: const GridSize(width: 9007199254740000, height: 1),
      quarterTurns: 2,
    );
    final rect = transform.sourcePixelRectToDestinationPixelRect(
      const PixelRect(leftPx: 123, topPx: 0, widthPx: 2, heightPx: 1),
    );
    expect(rect.leftPx, 9007199254739875);
    expect(rect.widthPx, 2);
  });
}
