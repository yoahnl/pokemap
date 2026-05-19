import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowDirection', () {
    test('accepts a valid direction and preserves authored values', () {
      final direction = ProjectedShadowDirection(x: -3, y: 4);

      expect(direction.x, -3);
      expect(direction.y, 4);
      expect(direction.magnitude, 5);
    });

    test('refuses non-finite values', () {
      expect(
        () => ProjectedShadowDirection(x: double.nan, y: 1),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowDirection(x: 1, y: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowDirection(x: double.infinity, y: 1),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowDirection(x: 1, y: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses zero vector', () {
      expect(
        () => ProjectedShadowDirection(x: 0, y: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('exposes a normalized direction without mutating authored values', () {
      final direction = ProjectedShadowDirection(x: -3, y: 4);
      final normalized = direction.normalized;

      expect(direction.x, -3);
      expect(direction.y, 4);
      expect(normalized.x, closeTo(-0.6, 0.000001));
      expect(normalized.y, closeTo(0.8, 0.000001));
      expect(normalized.magnitude, closeTo(1, 0.000001));
    });

    test('uses value equality', () {
      expect(
        ProjectedShadowDirection(x: -1, y: 2),
        ProjectedShadowDirection(x: -1, y: 2),
      );
      expect(
        ProjectedShadowDirection(x: -1, y: 2).hashCode,
        ProjectedShadowDirection(x: -1, y: 2).hashCode,
      );
    });
  });

  group('ProjectedShadowAnchor', () {
    test('accepts boundary and authored anchor ratios', () {
      expect(ProjectedShadowAnchor(xRatio: 0, yRatio: 0).xRatio, 0);
      expect(ProjectedShadowAnchor(xRatio: 1, yRatio: 1).yRatio, 1);

      final anchor = ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98);
      expect(anchor.xRatio, 0.5);
      expect(anchor.yRatio, 0.98);
    });

    test('refuses ratios outside zero to one', () {
      expect(
        () => ProjectedShadowAnchor(xRatio: -0.01, yRatio: 0.5),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAnchor(xRatio: 1.01, yRatio: 0.5),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAnchor(xRatio: 0.5, yRatio: -0.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses non-finite ratios', () {
      expect(
        () => ProjectedShadowAnchor(xRatio: double.nan, yRatio: 0.5),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAnchor(xRatio: 0.5, yRatio: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses value equality', () {
      expect(
        ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
        ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
      );
    });
  });

  group('ProjectedShadowOffset', () {
    test('accepts positive, negative, and zero values', () {
      expect(ProjectedShadowOffset(x: 4, y: -2).x, 4);
      expect(ProjectedShadowOffset(x: 4, y: -2).y, -2);
      expect(
          ProjectedShadowOffset(x: 0, y: 0), ProjectedShadowOffset(x: 0, y: 0));
    });

    test('refuses non-finite values', () {
      expect(
        () => ProjectedShadowOffset(x: double.nan, y: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowOffset(x: 0, y: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses value equality', () {
      expect(
        ProjectedShadowOffset(x: -3, y: 7),
        ProjectedShadowOffset(x: -3, y: 7),
      );
    });
  });

  group('ProjectedShadowShapeTuning', () {
    test('accepts zero and positive length with positive widths', () {
      expect(
        ProjectedShadowShapeTuning(
          lengthRatio: 0,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ).lengthRatio,
        0,
      );
      expect(
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ).nearWidthRatio,
        0.85,
      );
    });

    test('refuses invalid ratios', () {
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: -0.01,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0,
          farWidthRatio: 0.75,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: -0.01,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses non-finite ratios', () {
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: double.infinity,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: double.nan,
          farWidthRatio: 0.75,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: double.negativeInfinity,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses value equality', () {
      expect(
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );
    });
  });

  group('ProjectedShadowAppearance', () {
    test('accepts opacity boundaries and intermediate values', () {
      expect(ProjectedShadowAppearance(opacity: 0).opacity, 0);
      expect(ProjectedShadowAppearance(opacity: 1).opacity, 1);
      expect(ProjectedShadowAppearance(opacity: 0.18).opacity, 0.18);
    });

    test('refuses invalid opacity values', () {
      expect(
        () => ProjectedShadowAppearance(opacity: -0.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(opacity: 1.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(opacity: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(opacity: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts and normalizes RGB hex colors', () {
      expect(ProjectedShadowAppearance(colorHexRgb: '000000').colorHexRgb,
          '000000');
      expect(ProjectedShadowAppearance(colorHexRgb: 'FFFFFF').colorHexRgb,
          'FFFFFF');
      expect(ProjectedShadowAppearance(colorHexRgb: 'abcdef').colorHexRgb,
          'ABCDEF');
    });

    test('refuses invalid RGB hex colors', () {
      expect(
        () => ProjectedShadowAppearance(colorHexRgb: 'FFFFF'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(colorHexRgb: 'FFFFFFF'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(colorHexRgb: '#000000'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(colorHexRgb: 'GGGGGG'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses value equality with normalized color', () {
      expect(
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: 'abcdef'),
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: 'ABCDEF'),
      );
    });
  });

  group('ProjectedShadowTimeOfDayMode', () {
    test('contains only fixed and followsSun placeholders', () {
      expect(
        ProjectedShadowTimeOfDayMode.values,
        <ProjectedShadowTimeOfDayMode>[
          ProjectedShadowTimeOfDayMode.fixed,
          ProjectedShadowTimeOfDayMode.followsSun,
        ],
      );
    });
  });
}
