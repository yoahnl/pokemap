import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticShadowFootprintConfig', () {
    test('constructor all null is empty', () {
      final config = StaticShadowFootprintConfig();

      expect(config.anchorXRatio, isNull);
      expect(config.anchorYRatio, isNull);
      expect(config.footprintWidthRatio, isNull);
      expect(config.footprintHeightRatio, isNull);
      expect(config.isEmpty, isTrue);
      expect(config.isNotEmpty, isFalse);
    });

    test('accepts anchor ratios at bounds', () {
      final config = StaticShadowFootprintConfig(
        anchorXRatio: 0,
        anchorYRatio: 1,
      );

      expect(config.anchorXRatio, 0);
      expect(config.anchorYRatio, 1);
      expect(config.isEmpty, isFalse);
      expect(config.isNotEmpty, isTrue);
    });

    test('rejects anchor ratios outside 0 to 1 or non-finite', () {
      for (final value in <double>[
        -0.01,
        1.01,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowFootprintConfig(anchorXRatio: value),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowFootprintConfig(anchorYRatio: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('accepts positive footprint ratios', () {
      final config = StaticShadowFootprintConfig(
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );

      expect(config.footprintWidthRatio, 0.75);
      expect(config.footprintHeightRatio, 0.25);
      expect(config.isEmpty, isFalse);
      expect(config.isNotEmpty, isTrue);
    });

    test('rejects footprint ratios that are not positive finite values', () {
      for (final value in <double>[
        0,
        -0.01,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowFootprintConfig(footprintWidthRatio: value),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowFootprintConfig(footprintHeightRatio: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('equality and hashCode include all fields', () {
      final first = StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );
      final same = StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );
      final differentAnchor = StaticShadowFootprintConfig(
        anchorXRatio: 0.4,
        anchorYRatio: 1,
        footprintWidthRatio: 0.75,
        footprintHeightRatio: 0.25,
      );
      final differentFootprint = StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.8,
        footprintHeightRatio: 0.25,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(differentAnchor));
      expect(first, isNot(differentFootprint));
    });
  });
}
