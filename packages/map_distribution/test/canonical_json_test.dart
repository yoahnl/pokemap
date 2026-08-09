import 'dart:convert';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/game_package_contract_fixtures.dart';

void main() {
  group('CanonicalJson', () {
    test('executes every committed JSON canonicalization vector', () {
      final fixture = jsonDecode(
        gamePackageContractFixture(
          'contracts/canonicalization-vectors.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final vectors = fixture['jsonCanonicalization'] as List;
      final executed = <String>{};

      expect(vectors, hasLength(1));
      expect(
        vectors
            .map((value) => (value as Map<String, dynamic>)['name'] as String)
            .toSet(),
        <String>{'utf8-key-order'},
      );

      for (final rawVector in vectors) {
        final vector = rawVector as Map<String, dynamic>;
        final name = vector['name'] as String;
        final input = Map<String, Object?>.from(vector['input'] as Map);

        final canonical = CanonicalJson.encode(input);

        expect(canonical, vector['canonicalUtf8'], reason: name);
        expect(CanonicalJson.sha256Hex(input), vector['sha256'], reason: name);
        expect(
          utf8.decode(CanonicalJson.encodeUtf8(input)),
          canonical,
          reason: name,
        );
        executed.add(name);
      }

      expect(executed, <String>{'utf8-key-order'});
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
