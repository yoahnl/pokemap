import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Border V1 enums', () {
    test('templates are exactly the three published V1 templates', () {
      expect(
        BorderBlueprintTemplate.values.map((value) => value.name),
        <String>['organicEdge', 'masonryLine', 'postAndRailLine'],
      );
    });

    test('primitive roles are exactly the eight functional V1 roles', () {
      expect(
        BorderPrimitiveRole.values.map((value) => value.name),
        <String>[
          'structureLarge',
          'structureMedium',
          'filler',
          'accent',
          'post',
          'span',
          'surfacePatch',
          'outerAccent',
        ],
      );
    });
  });

  group('Border pixel value objects', () {
    test('positions and rectangles use integer value semantics', () {
      expect(
        const BorderPixelPos(x: -3, y: 7),
        const BorderPixelPos(x: -3, y: 7),
      );
      expect(
        BorderPixelRect(x: -2, y: 4, width: 12, height: 9),
        BorderPixelRect(x: -2, y: 4, width: 12, height: 9),
      );
    });

    test('rectangles require positive dimensions', () {
      expect(
        () => BorderPixelRect(x: 0, y: 0, width: 0, height: 1),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderPixelRect(x: 0, y: 0, width: 1, height: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rectangles reject signed 64-bit exclusive-edge overflow', () {
      expect(
        () => BorderPixelRect(
          x: 9223372036854775807,
          y: 0,
          width: 1,
          height: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderPixelRect(
          x: 0,
          y: 9223372036854775807,
          width: 1,
          height: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rectangles keep negative positions and safe boundary edges', () {
      final negative = BorderPixelRect(
        x: -9223372036854775808,
        y: -9223372036854775808,
        width: 1,
        height: 1,
      );
      final maximumEdges = BorderPixelRect(
        x: 9223372036854775806,
        y: 9223372036854775806,
        width: 1,
        height: 1,
      );

      expect(negative.right, -9223372036854775807);
      expect(negative.bottom, -9223372036854775807);
      expect(maximumEdges.right, 9223372036854775807);
      expect(maximumEdges.bottom, 9223372036854775807);
    });
  });

  group('BorderTransformPolicy', () {
    test('accepts an empty allowed-quarter-turn set', () {
      final policy = BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: const <int>[],
      );

      expect(policy.allowedQuarterTurns, isEmpty);
      expect(() => policy.allowedQuarterTurns.add(0), throwsUnsupportedError);
    });

    test('canonicalizes and defensively freezes quarter turns', () {
      final input = <int>[3, 0, 2];
      final policy = BorderTransformPolicy(
        allowFlipX: true,
        allowedQuarterTurns: input,
      );

      input
        ..clear()
        ..add(1);

      expect(policy.allowFlipX, isTrue);
      expect(policy.allowedQuarterTurns, <int>[0, 2, 3]);
      expect(
        () => policy.allowedQuarterTurns.add(1),
        throwsUnsupportedError,
      );
      expect(
        policy,
        BorderTransformPolicy(
          allowFlipX: true,
          allowedQuarterTurns: <int>[2, 3, 0],
        ),
      );
    });

    test('rejects duplicate and non-quarter-turn values', () {
      expect(
        () => BorderTransformPolicy(
          allowFlipX: false,
          allowedQuarterTurns: <int>[0, 0],
        ),
        throwsA(isA<ValidationException>()),
      );
      for (final invalid in <int>[-1, 4]) {
        expect(
          () => BorderTransformPolicy(
            allowFlipX: false,
            allowedQuarterTurns: <int>[invalid],
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });
  });

  group('BorderGenerationParams', () {
    test('accepts all documented boundary values', () {
      final params = BorderGenerationParams(
        irregularityPermille: 0,
        detailDensityPermille: 1000,
        variationPermille: 0,
        maxOverlapPx: 0,
        gapTolerancePx: 0,
        depthRows: 1,
      );

      expect(params.irregularityPermille, 0);
      expect(params.detailDensityPermille, 1000);
      expect(params.depthRows, 1);
      expect(
        params,
        BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 1000,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1,
        ),
      );
    });

    test('rejects values outside documented integer ranges', () {
      for (final createInvalid in <BorderGenerationParams Function()>[
        () => _params(irregularityPermille: -1),
        () => _params(irregularityPermille: 1001),
        () => _params(detailDensityPermille: -1),
        () => _params(detailDensityPermille: 1001),
        () => _params(variationPermille: -1),
        () => _params(variationPermille: 1001),
        () => _params(maxOverlapPx: -1),
        () => _params(gapTolerancePx: -1),
        () => _params(depthRows: 0),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });
  });
}

BorderGenerationParams _params({
  int irregularityPermille = 500,
  int detailDensityPermille = 500,
  int variationPermille = 500,
  int maxOverlapPx = 0,
  int gapTolerancePx = 0,
  int depthRows = 1,
}) {
  return BorderGenerationParams(
    irregularityPermille: irregularityPermille,
    detailDensityPermille: detailDensityPermille,
    variationPermille: variationPermille,
    maxOverlapPx: maxOverlapPx,
    gapTolerancePx: gapTolerancePx,
    depthRows: depthRows,
  );
}
