import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('GamePackageBuilder', () {
    const builder = GamePackageBuilder();

    test('builds a deterministic STORE-only data package', () {
      final firstPayload = <String, List<int>>{
        'project/project.json': _validProjectBytes(),
        'presentation/icon.png': _onePixelPngHeader(),
      };
      final secondPayload = <String, List<int>>{
        'presentation/icon.png': _onePixelPngHeader(),
        'project/project.json': _validProjectBytes(),
      };

      final first = builder.build(
        manifest: _draftManifest(),
        payloadFiles: firstPayload,
      );
      final second = builder.build(
        manifest: _draftManifest(),
        payloadFiles: secondPayload,
      );

      expect(first.packageBytes, second.packageBytes);
      expect(
        sha256.convert(first.packageBytes).toString(),
        'b27e896f2fad2537ae421e4c7656f1ceb4719797d5ae19606365ca8bd0b6867d',
      );
      expect(
        first.packageSha256,
        'b27e896f2fad2537ae421e4c7656f1ceb4719797d5ae19606365ca8bd0b6867d',
      );
      expect(first.archiveBytes, first.packageBytes.length);
      expect(first.manifest.content.fileCount, 2);
      expect(
        first.manifest.content.treeSha256,
        second.manifest.content.treeSha256,
      );

      final archive = ZipDecoder().decodeBytes(first.packageBytes);
      expect(
        archive.files.map((file) => file.name),
        <String>[
          'game-manifest.json',
          'presentation/icon.png',
          'project/project.json',
        ],
      );
      expect(
        archive.files.every(
          (file) => file.compression == CompressionType.none,
        ),
        isTrue,
      );
      final manifestFile = archive.findFile('game-manifest.json')!;
      final decoded = const GamePackageManifestCodec().decodeUtf8(
        manifestFile.content as List<int>,
      );
      expect(decoded.toJson(), first.manifest.toJson());
    });

    test('supports a large valid inventory within the v1 entry quota', () {
      final payload = <String, List<int>>{
        'project/project.json': _validProjectBytes(),
        for (var index = 0; index < 11999; index++)
          'project/data/catalog/'
              '${index.toString().padLeft(5, '0')}.json': utf8.encode('{}'),
      };

      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: payload,
      );

      expect(built.manifest.content.fileCount, 12000);
      expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .content
            .fileCount,
        12000,
      );
    });

    test('does not allow a stale signature to cover changed content', () {
      final unsigned = builder.build(
        manifest: _draftManifest(),
        payloadFiles: <String, List<int>>{
          'project/project.json': _validProjectBytes(),
        },
      );
      final signed = unsigned.manifest.copyWith(
        signature: const GamePackageSignature(
          algorithm: 'ed25519',
          keyId: 'publisher:key',
          value:
              'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
        ),
      );

      expect(
        () => builder.build(
          manifest: signed,
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(name: 'Changed'),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'staleSignature'),
        ),
      );
      expect(
        () => const GamePackageBuilder(
          securityPolicy: GamePackageSecurityPolicy(maxFileBytes: 1),
        ).build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'entryTooLarge'),
        ),
      );
    });

    test('snapshots mutable inputs and applies data-only policy at build time',
        () {
      final projectBytes = _validProjectBytes();
      final iconBytes = _onePixelPngHeader();
      final payload = <String, List<int>>{
        'project/project.json': projectBytes,
        'presentation/icon.png': iconBytes,
      };

      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: payload,
        mediaTypeForPath: (path) {
          if (path == 'presentation/icon.png') {
            projectBytes[0] = 0;
          }
          return path.endsWith('.json') ? 'application/json' : 'image/png';
        },
      );

      expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .gameId,
        'games.example.builder',
      );
      expect(
        () => builder.build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
            'project/assets/code.dart': utf8.encode('void main() {}'),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'executableContent'),
        ),
      );
    });

    test('rejects authoring artifacts and validates projection closure', () {
      expect(
        () => builder.build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
            'project/data/catalog.json': utf8.encode('{"items":[]}'),
            'project/data/pokemon/media/creature.png': _onePixelPngHeader(),
          },
        ),
        returnsNormally,
      );
      for (final excludedPath in <String>[
        'project/.dart_tool/cache.json',
        'project/fixtures/debug.json',
        'project/runtime_host_launch_save.json',
        'project/seeds.json',
        'project/editor-state.json',
        'project/editor_state.json',
        'project/save.json',
        'project/diagnostic.json',
      ]) {
        expect(
          () => builder.build(
            manifest: _draftManifest(),
            payloadFiles: <String, List<int>>{
              'project/project.json': _validProjectBytes(),
              excludedPath: utf8.encode('{}'),
            },
          ),
          throwsA(
            isA<GamePackageFormatException>()
                .having((error) => error.code, 'code', 'executableContent'),
          ),
          reason: excludedPath,
        );
      }

      final projectWithMissingMap = utf8.encode(
        jsonEncode(<String, Object?>{
          'name': 'Missing Map',
          'version': 'v6',
          'maps': <Object?>[
            <String, Object?>{
              'id': 'map.start',
              'name': 'Start',
              'relativePath': 'maps/start.json',
            },
          ],
          'tilesets': <Object?>[],
        }),
      );
      expect(
        () => builder.build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': projectWithMissingMap,
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'missingFile'),
        ),
      );

      expect(
        () => builder.build(
          manifest: _draftManifest(projectFormat: 'v5'),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'projectFormatMismatch'),
        ),
      );
    });
  });
}

List<int> _onePixelPngHeader() {
  final bytes = Uint8List(24)
    ..setAll(
      0,
      <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
    )
    ..setAll(12, ascii.encode('IHDR'));
  ByteData.sublistView(bytes)
    ..setUint32(16, 1)
    ..setUint32(20, 1);
  return bytes;
}

List<int> _validProjectBytes({
  String name = 'Builder Test',
  String version = 'v6',
}) =>
    utf8.encode(
      jsonEncode(<String, Object?>{
        'name': name,
        'version': version,
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      }),
    );

GamePackageManifest _draftManifest({String projectFormat = 'v6'}) {
  final valid = const GamePackageManifestCodec().decodeJson(
    <String, Object?>{
      'packageFormat': 1,
      'gameId': 'games.example.builder',
      'gameVersion': '1.0.0',
      'title': 'Builder',
      'author': <String, Object?>{'name': 'Example'},
      'compatibility': <String, Object?>{
        'minHubVersion': '1.0.0',
        'runtimeApi': '>=1.0.0 <2.0.0',
        'projectFormat': projectFormat,
        'saveFormat': 1,
        'compatibilityId': 'main',
        'requiredCapabilities': <String>[],
      },
      'locales': <String, Object?>{
        'default': 'fr',
        'supported': <String>['fr'],
      },
      'content': <String, Object?>{
        'fileCount': 1,
        'totalBytes': 24,
        'treeSha256':
            'e21fddff269f718118bf1bda81c75726b57a9a34a9fd74497b53517069862a3b',
        'files': <Object?>[
          <String, Object?>{
            'path': 'project/project.json',
            'size': 24,
            'sha256':
                '1bcbf797acc5b8dc08dcba7f4da52a7d7b09f97cc5ec1905b8093d6f0faa097a',
          },
        ],
      },
    },
  );
  return valid.copyWith(clearSignature: true);
}
