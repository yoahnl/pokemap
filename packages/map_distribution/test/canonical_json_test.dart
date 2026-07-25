import 'dart:convert';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalJson', () {
    test('sorts object keys recursively and reproduces the Phase 0 vector', () {
      final fixture = jsonDecode(
        File(
          '../../reports/product/pokemap_hub/phase_0/contracts/'
          'canonicalization-vectors.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final vector = (fixture['jsonCanonicalization'] as List).single
          as Map<String, dynamic>;
      final input = Map<String, Object?>.from(vector['input'] as Map);

      final canonical = CanonicalJson.encode(input);

      expect(canonical, vector['canonicalUtf8']);
      expect(CanonicalJson.sha256Hex(input), vector['sha256']);
      expect(utf8.decode(CanonicalJson.encodeUtf8(input)), canonical);
    });

    test('rejects non-finite and non-integral numbers', () {
      expect(
        () => CanonicalJson.encode(<String, Object?>{'value': double.nan}),
        throwsA(isA<CanonicalJsonException>()),
      );
      expect(
        () => CanonicalJson.encode(<String, Object?>{'value': 1.5}),
        throwsA(isA<CanonicalJsonException>()),
      );
    });

    test('rejects integers outside the interoperable JCS range', () {
      expect(
        CanonicalJson.encode(CanonicalJson.maxSafeInteger),
        '9007199254740991',
      );
      expect(
        () => CanonicalJson.encode(CanonicalJson.maxSafeInteger + 1),
        throwsA(isA<CanonicalJsonException>()),
      );
      expect(
        () => CanonicalJson.encode(-CanonicalJson.maxSafeInteger - 1),
        throwsA(isA<CanonicalJsonException>()),
      );
    });

    test('sorts astral keys by UTF-16 code units', () {
      final canonical = CanonicalJson.encode(<String, Object?>{
        '\u{1F600}': 1,
        '\uE000': 2,
      });

      expect(canonical, '{"😀":1,"":2}');
    });

    test('rejects isolated UTF-16 surrogates', () {
      expect(
        () => CanonicalJson.encode(<String, Object?>{
          'value': String.fromCharCode(0xd800),
        }),
        throwsA(isA<CanonicalJsonException>()),
      );
      expect(
        () => CanonicalJson.encode(<String, Object?>{
          String.fromCharCode(0xdc00): 'value',
        }),
        throwsA(isA<CanonicalJsonException>()),
      );
    });
  });
}
