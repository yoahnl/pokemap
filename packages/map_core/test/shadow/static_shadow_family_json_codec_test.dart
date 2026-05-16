import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticShadowFamily JSON codec', () {
    test('encodes null as null', () {
      expect(encodeStaticShadowFamily(null), isNull);
    });

    test('encodes family by stable enum name', () {
      expect(
        encodeStaticShadowFamily(StaticShadowFamily.building),
        'building',
      );
      expect(
        encodeStaticShadowFamily(StaticShadowFamily.tallProp),
        'tallProp',
      );
    });

    test('decodes null as null', () {
      expect(decodeStaticShadowFamily(null), isNull);
    });

    test('decodes valid family names', () {
      expect(
        decodeStaticShadowFamily('genericProjection'),
        StaticShadowFamily.genericProjection,
      );
      expect(
        decodeStaticShadowFamily('compactProp'),
        StaticShadowFamily.compactProp,
      );
      expect(
        decodeStaticShadowFamily('tallProp'),
        StaticShadowFamily.tallProp,
      );
      expect(
        decodeStaticShadowFamily('building'),
        StaticShadowFamily.building,
      );
      expect(
        decodeStaticShadowFamily('foliage'),
        StaticShadowFamily.foliage,
      );
    });

    test('rejects non-string values', () {
      expect(
        () => decodeStaticShadowFamily(42),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unknown family values', () {
      expect(
        () => decodeStaticShadowFamily('houseButMaybeLater'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
