import 'dart:convert';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('ContentTreeHasher', () {
    test('reproduces every committed Phase 0 tree vector', () {
      final fixture = jsonDecode(
        File(
          '../../reports/product/pokemap_hub/phase_0/contracts/'
          'canonicalization-vectors.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final vectors = fixture['contentTrees'] as List;

      for (final rawVector in vectors) {
        final vector = rawVector as Map<String, dynamic>;
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
          reason: vector['name'] as String,
        );
        expect(
          ContentTreeHasher.sha256Hex(files),
          vector['treeSha256'],
          reason: vector['name'] as String,
        );
        expect(
          ContentTreeHasher.sha256Hex(files.reversed),
          vector['treeSha256'],
          reason: '${vector['name']} reversed',
        );
      }
    });
  });
}
