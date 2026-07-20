import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/selbrume_two_tier_stone_chain_v4_fixture.dart';

void main() {
  test('V4 fixture captures the 24 compact two-tier stone primitives', () {
    final primitives = selbrumeTwoTierV4PublishedPrimitives();

    expect(primitives, hasLength(24));
    expect(primitives.map((primitive) => primitive.id).toSet(), hasLength(24));
    expect(
      primitives
          .where(
            (primitive) => primitive.role == BorderPrimitiveRole.structureLarge,
          )
          .length,
      12,
    );
    expect(
      primitives
          .where(
            (primitive) =>
                primitive.role == BorderPrimitiveRole.structureMedium,
          )
          .length,
      12,
    );

    for (final primitive in primitives) {
      final metrics = primitive.publishedMetrics;
      final horizontal =
          primitive.authoredOrientation == BorderPrimitiveOrientation.north ||
              primitive.authoredOrientation == BorderPrimitiveOrientation.south;
      final tangentSpan =
          horizontal ? metrics.opaqueBounds.width : metrics.opaqueBounds.height;
      final normalSpan =
          horizontal ? metrics.opaqueBounds.height : metrics.opaqueBounds.width;

      if (primitive.role == BorderPrimitiveRole.structureLarge) {
        expect(tangentSpan, isIn(const <int>[12, 14, 16]),
            reason: primitive.id);
        expect(normalSpan, isIn(const <int>[10, 12, 14]), reason: primitive.id);
      } else {
        expect(tangentSpan, isIn(const <int>[10, 12, 14]),
            reason: primitive.id);
        expect(normalSpan, 27, reason: primitive.id);
      }

      expect(metrics.defaultAnchorPx, primitive.anchorPx, reason: primitive.id);
      expect(
        metrics.assetFingerprint,
        matches(RegExp(r'^sha256:[0-9a-f]{64}$')),
        reason: primitive.id,
      );
      expect(
        () => decodeBorderRleMask(
          metrics.occupancyMaskRle,
          expectedLength: 32 * 32,
        ),
        returnsNormally,
        reason: primitive.id,
      );
      final mask = decodeBorderRleMask(
        metrics.occupancyMaskRle,
        expectedLength: 32 * 32,
      );
      expect(mask, hasLength(32 * 32), reason: primitive.id);
      expect(_opaqueBounds(mask), metrics.opaqueBounds, reason: primitive.id);
    }
  });
}

BorderPixelRect _opaqueBounds(List<bool> mask) {
  var left = 32;
  var top = 32;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < 32; y += 1) {
    for (var x = 0; x < 32; x += 1) {
      if (!mask[y * 32 + x]) continue;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }
  return BorderPixelRect(
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
}
