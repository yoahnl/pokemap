import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderSignedInt64', () {
    test('accepts both inclusive bounds with exact BigInt value semantics', () {
      final minimum = BorderSignedInt64(
        BigInt.parse('-9223372036854775808'),
      );
      final maximum = BorderSignedInt64(
        BigInt.parse('9223372036854775807'),
      );

      expect(minimum.value, BigInt.parse('-9223372036854775808'));
      expect(maximum.value, BigInt.parse('9223372036854775807'));
      expect(
        BorderSignedInt64(BigInt.parse('-9223372036854775808')),
        minimum,
      );
      expect(minimum.hashCode,
          BorderSignedInt64.parse(minimum.toString()).hashCode);
    });

    test('offers an ergonomic exact constructor for ordinary Dart ints', () {
      expect(BorderSignedInt64.fromInt(-7).value, BigInt.from(-7));
      expect(BorderSignedInt64.zero, BorderSignedInt64.fromInt(0));
    });

    test('rejects values outside the signed 64-bit range', () {
      for (final value in <BigInt>[
        BigInt.parse('-9223372036854775809'),
        BigInt.parse('9223372036854775808'),
      ]) {
        expect(() => BorderSignedInt64(value), throwsArgumentError);
      }
    });

    test('parse accepts only canonical decimal strings', () {
      expect(BorderSignedInt64.parse('-1'), BorderSignedInt64.fromInt(-1));
      for (final value in <String>[
        '-0',
        '+1',
        '01',
        '-01',
        ' 1',
        '1 ',
        '1\n',
        '9223372036854775808',
      ]) {
        expect(
          () => BorderSignedInt64.parse(value),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });

  group('BorderSignedInt64 JSON codec', () {
    test('round-trips exact canonical decimal strings through public API', () {
      for (final value in <BorderSignedInt64>[
        BorderSignedInt64.minimum,
        BorderSignedInt64.fromInt(-1),
        BorderSignedInt64.zero,
        BorderSignedInt64.fromInt(1),
        BorderSignedInt64.maximum,
      ]) {
        final encoded = encodeBorderSignedInt64Json(value);

        expect(encoded, value.toString());
        expect(decodeBorderSignedInt64Json(encoded), value);
      }
    });

    test('rejects aliases, JSON numbers, and overflow at the supplied path',
        () {
      for (final value in <Object?>[
        '-0',
        '+1',
        '01',
        '-01',
        ' 1',
        '1 ',
        '1\n',
        '9223372036854775808',
        '-9223372036854775809',
        1,
        1.0,
        null,
      ]) {
        expect(
          () => decodeBorderSignedInt64Json(value, path: r'$.seed'),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              startsWith(r'$.seed:'),
            ),
          ),
          reason: '$value',
        );
      }
    });
  });
}
