import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('recommendedBorderPrimitiveAnchor', () {
    test('uses the network center for a 32 by 32 connected line', () {
      expect(
        recommendedBorderPrimitiveAnchor(
          template: BorderBlueprintTemplate.connectedLine,
          metrics: _metrics(
            width: 32,
            height: 32,
            defaultAnchor: const BorderPixelPos(x: 22, y: 30),
          ),
        ),
        const BorderPixelPos(x: 16, y: 16),
      );
    });

    test('uses integer center coordinates for odd dimensions', () {
      expect(
        recommendedBorderPrimitiveAnchor(
          template: BorderBlueprintTemplate.connectedLine,
          metrics: _metrics(
            width: 31,
            height: 29,
            defaultAnchor: const BorderPixelPos(x: 15, y: 28),
          ),
        ),
        const BorderPixelPos(x: 15, y: 14),
      );
    });

    test('preserves the default anchor for every other template', () {
      const expected = BorderPixelPos(x: 7, y: 13);
      final metrics = _metrics(
        width: 16,
        height: 16,
        defaultAnchor: expected,
      );

      for (final template in BorderBlueprintTemplate.values) {
        if (template == BorderBlueprintTemplate.connectedLine) continue;
        expect(
          recommendedBorderPrimitiveAnchor(
            template: template,
            metrics: metrics,
          ),
          expected,
          reason: template.name,
        );
      }
    });

    test('keeps the network center inside the image dimensions', () {
      for (var width = 1; width <= 33; width++) {
        for (var height = 1; height <= 33; height++) {
          final anchor = recommendedBorderPrimitiveAnchor(
            template: BorderBlueprintTemplate.connectedLine,
            metrics: _metrics(
              width: width,
              height: height,
              defaultAnchor: const BorderPixelPos(x: 0, y: 0),
            ),
          );

          expect(anchor.x, inInclusiveRange(0, width - 1));
          expect(anchor.y, inInclusiveRange(0, height - 1));
        }
      }
    });
  });
}

BorderPrimitiveAssetMetrics _metrics({
  required int width,
  required int height,
  required BorderPixelPos defaultAnchor,
}) =>
    BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset',
      pixelSize: GridSize(width: width, height: height),
      opaqueBounds: BorderPixelRect(
        x: 0,
        y: 0,
        width: width,
        height: height,
      ),
      defaultAnchorPx: defaultAnchor,
      occupancyMaskRle: '1',
    );
