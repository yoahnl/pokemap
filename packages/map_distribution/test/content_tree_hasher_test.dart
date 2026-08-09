import 'dart:convert';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/game_package_contract_fixtures.dart';

void main() {
  group('ContentTreeHasher', () {
    test('executes every committed content-tree vector', () {
      final fixture = jsonDecode(
        gamePackageContractFixture(
          'contracts/canonicalization-vectors.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final vectors = fixture['contentTrees'] as List;
      final executed = <String>{};

      expect(vectors, hasLength(2));
      expect(
        vectors
            .map((value) => (value as Map<String, dynamic>)['name'] as String)
            .toSet(),
        <String>{'minimal-project', 'order-normalized'},
      );

      for (final rawVector in vectors) {
        final vector = rawVector as Map<String, dynamic>;
        final name = vector['name'] as String;
        expect(vector['files'] as List, isNotEmpty, reason: name);
        final files = (vector['files'] as List)
            .map(
              (raw) => GamePackageFileEntry(
                path: (raw as Map<String, dynamic>)['path'] as String,
                size: raw['size'] as int,
                sha256: raw['sha256'] as String,
              ),
            )
            .toList();

        expect(
          ContentTreeHasher.canonicalPreimage(files),
          vector['canonicalPreimage'],
          reason: name,
        );
        expect(
          ContentTreeHasher.sha256Hex(files),
          vector['treeSha256'],
          reason: name,
        );
        expect(
          ContentTreeHasher.sha256Hex(files.reversed),
          vector['treeSha256'],
          reason: '$name reversed',
        );
        executed.add(name);
      }

      expect(executed, <String>{'minimal-project', 'order-normalized'});
    });
  });
}
