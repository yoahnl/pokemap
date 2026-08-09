import 'dart:convert';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'support/game_package_contract_fixtures.dart';

void main() {
  const codec = GamePackageManifestCodec();
  final contractRoot = gamePackageContractFixtureDirectory(
    'contracts/examples',
  );

  const expectedFixturePaths = <String>{
    'compatibility/compatibility-matrix.json',
    'contracts/canonicalization-vectors.json',
    'contracts/examples/complete-valid/game-manifest.json',
    'contracts/examples/complete-valid/payload/legal/CREDITS.txt',
    'contracts/examples/complete-valid/payload/presentation/icon.png.base64',
    'contracts/examples/complete-valid/payload/project/project.json',
    'contracts/examples/invalid/future-package-format.json',
    'contracts/examples/invalid/invalid-game-id.json',
    'contracts/examples/invalid/path-traversal.json',
    'contracts/examples/invalid/unknown-required-field.json',
    'contracts/examples/minimal-valid/game-manifest.json',
    'contracts/examples/minimal-valid/payload/project/project.json',
  };

  test('contains every resource and accepts both valid manifest fixtures', () {
    final fixturePaths = gamePackageContractFixtureRoot
        .listSync(recursive: true)
        .whereType<File>()
        .map(
          (file) => file.uri.path.substring(
            gamePackageContractFixtureRoot.uri.path.length,
          ),
        )
        .toSet();
    expect(fixturePaths, expectedFixturePaths);

    final fixtures = <String, String>{
      'minimal-valid': 'games.example.minimal',
      'complete-valid': 'games.example.complete',
    };

    for (final entry in fixtures.entries) {
      final fixture = File(
        '${contractRoot.path}/${entry.key}/game-manifest.json',
      );
      final json = jsonDecode(fixture.readAsStringSync());
      final manifest = codec.decodeJson(json);
      expect(manifest.packageFormat, 1, reason: fixture.path);
      expect(manifest.gameId, entry.value, reason: fixture.path);
      expect(
        manifest.compatibility.projectFormat,
        'v6',
        reason: fixture.path,
      );
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
        mediaTypeForPath: (path) => manifest.content.files
            .singleWhere((entry) => entry.path == path)
            .mediaType,
      );
      final inspected = const GamePackageInspector().inspect(
        built.packageBytes,
      );
      expect(inspected.manifest.toJson(), manifest.toJson());
      expect(inspected.payloadPaths.toSet(), payload.keys.toSet());
    }
  });

  test('rejects every invalid manifest fixture with its exact diagnostic', () {
    const expectedFailures = <String, ({String code, String path})>{
      'future-package-format.json': (
        code: 'packageFormatUnsupported',
        path: r'$.packageFormat',
      ),
      'invalid-game-id.json': (
        code: 'invalidGameId',
        path: r'$.gameId',
      ),
      'path-traversal.json': (
        code: 'invalidPackagePath',
        path: r'$.content.files[0].path',
      ),
      'unknown-required-field.json': (
        code: 'unknownField',
        path: r'$',
      ),
    };
    final fixtures = Directory('${contractRoot.path}/invalid')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));

    expect(
      fixtures.map((file) => file.uri.pathSegments.last).toSet(),
      expectedFailures.keys.toSet(),
    );
    for (final fixture in fixtures) {
      final expected = expectedFailures[fixture.uri.pathSegments.last]!;
      final json = jsonDecode(fixture.readAsStringSync());
      expect(
        () => codec.decodeJson(json),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', expected.code)
              .having((error) => error.path, 'path', expected.path),
        ),
        reason: fixture.path,
      );
    }
  });
}
