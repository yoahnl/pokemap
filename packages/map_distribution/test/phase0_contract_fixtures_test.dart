import 'dart:convert';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  const codec = GamePackageManifestCodec();
  final contractRoot = Directory(
    '../../reports/product/pokemap_hub/phase_0/contracts/examples',
  );

  test('accepts both committed Phase 0 manifest fixtures', () {
    final fixtures = <File>[
      File('${contractRoot.path}/minimal-valid/game-manifest.json'),
      File('${contractRoot.path}/complete-valid/game-manifest.json'),
    ];

    for (final fixture in fixtures) {
      final json = jsonDecode(fixture.readAsStringSync());
      expect(codec.decodeJson(json).packageFormat, 1, reason: fixture.path);
    }
  });

  test('recomputes payload hashes and builds every valid fixture', () {
    for (final fixtureName in <String>['minimal-valid', 'complete-valid']) {
      final fixtureDirectory = Directory('${contractRoot.path}/$fixtureName');
      final manifest = codec.decodeJson(
        jsonDecode(
          File('${fixtureDirectory.path}/game-manifest.json')
              .readAsStringSync(),
        ),
      );
      final payload = <String, List<int>>{};
      for (final entity
          in Directory('${fixtureDirectory.path}/payload').listSync(
        recursive: true,
      )) {
        if (entity is! File) continue;
        var path = entity.path
            .substring('${fixtureDirectory.path}/payload/'.length)
            .replaceAll(r'\', '/');
        final List<int> bytes;
        if (path.endsWith('.base64')) {
          path = path.substring(0, path.length - '.base64'.length);
          bytes = base64Decode(
            entity.readAsStringSync().replaceAll(RegExp(r'\s'), ''),
          );
        } else {
          bytes = entity.readAsBytesSync();
        }
        payload[path] = bytes;
      }

      var totalBytes = 0;
      for (final entry in manifest.content.files) {
        final bytes = payload[entry.path];
        expect(bytes, isNotNull, reason: '$fixtureName ${entry.path}');
        expect(bytes, hasLength(entry.size), reason: entry.path);
        expect(sha256.convert(bytes!).toString(), entry.sha256);
        totalBytes += bytes.length;
      }
      expect(payload.keys.toSet(),
          manifest.content.files.map((e) => e.path).toSet());
      expect(totalBytes, manifest.content.totalBytes);
      expect(
        ContentTreeHasher.sha256Hex(manifest.content.files),
        manifest.content.treeSha256,
      );

      final built = const GamePackageBuilder().build(
        manifest: manifest,
        payloadFiles: payload,
      );
      expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .gameId,
        manifest.gameId,
      );
    }
  });

  test('rejects every committed invalid Phase 0 manifest fixture', () {
    final fixtures = Directory('${contractRoot.path}/invalid')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));

    expect(fixtures, hasLength(4));
    for (final fixture in fixtures) {
      final json = jsonDecode(fixture.readAsStringSync());
      expect(
        () => codec.decodeJson(json),
        throwsA(isA<GamePackageFormatException>()),
        reason: fixture.path,
      );
    }
  });
}
