import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticShadowFootprintConfig JSON codec', () {
    test('encodes null and empty footprint as null', () {
      expect(encodeStaticShadowFootprintConfig(null), isNull);
      expect(
        encodeStaticShadowFootprintConfig(
          StaticShadowFootprintConfig(),
        ),
        isNull,
      );
    });

    test('encodes non-empty footprints with only non-null fields', () {
      expect(
        encodeStaticShadowFootprintConfig(
          StaticShadowFootprintConfig(
            anchorXRatio: 0.5,
            anchorYRatio: 1,
            footprintWidthRatio: 0.75,
            footprintHeightRatio: 0.25,
          ),
        ),
        <String, Object?>{
          'anchorXRatio': 0.5,
          'anchorYRatio': 1.0,
          'footprintWidthRatio': 0.75,
          'footprintHeightRatio': 0.25,
        },
      );
      expect(
        encodeStaticShadowFootprintConfig(
          StaticShadowFootprintConfig(footprintWidthRatio: 0.5),
        ),
        <String, Object?>{'footprintWidthRatio': 0.5},
      );
    });

    test('decodes null and empty map as null', () {
      expect(decodeStaticShadowFootprintConfig(null), isNull);
      expect(decodeStaticShadowFootprintConfig(<String, Object?>{}), isNull);
    });

    test('decodes full and partial objects', () {
      expect(
        decodeStaticShadowFootprintConfig(<String, Object?>{
          'anchorXRatio': 0.5,
          'anchorYRatio': 1,
          'footprintWidthRatio': 0.75,
          'footprintHeightRatio': 0.25,
        }),
        StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1,
          footprintWidthRatio: 0.75,
          footprintHeightRatio: 0.25,
        ),
      );
      expect(
        decodeStaticShadowFootprintConfig(<String, Object?>{
          'footprintHeightRatio': 0.3,
        }),
        StaticShadowFootprintConfig(footprintHeightRatio: 0.3),
      );
    });

    test('ignores unknown keys', () {
      expect(
        decodeStaticShadowFootprintConfig(<String, Object?>{
          'anchorXRatio': 0.5,
          'unknown': true,
        }),
        StaticShadowFootprintConfig(anchorXRatio: 0.5),
      );
    });

    test('rejects non-map and invalid ratio values', () {
      expect(
        () => decodeStaticShadowFootprintConfig('footprint'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeStaticShadowFootprintConfig(<String, Object?>{
          'anchorXRatio': '0.5',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeStaticShadowFootprintConfig(<String, Object?>{
          'anchorYRatio': 2,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeStaticShadowFootprintConfig(<String, Object?>{
          'footprintWidthRatio': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeStaticShadowFootprintConfig(<String, Object?>{
          'footprintHeightRatio': double.infinity,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
