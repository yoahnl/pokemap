import 'dart:convert';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('GamePackageInventoryBuilder', () {
    const builder = GamePackageInventoryBuilder();

    test('builds a sorted immutable inventory and all hashes', () {
      final files = <String, List<int>>{
        'presentation/icon.png': <int>[1, 2, 3],
        'project/project.json': utf8.encode('{"format":"v2"}'),
      };

      final content = builder.build(
        files,
        mediaTypeForPath: (path) =>
            path.endsWith('.json') ? 'application/json' : 'image/png',
      );

      expect(
        content.files.map((entry) => entry.path),
        <String>['presentation/icon.png', 'project/project.json'],
      );
      expect(content.fileCount, 2);
      expect(content.totalBytes, 18);
      expect(
        content.files.last.sha256,
        '3dfb0f6cca458e65be168fb3e3c103f4df86f413c3334670543a822bcfbd9591',
      );
      expect(content.treeSha256, ContentTreeHasher.sha256Hex(content.files));

      files['project/project.json']![0] = 0;
      expect(content.files.last.sha256, isNotEmpty);
      expect(
          () => content.files.add(content.files.first), throwsUnsupportedError);
    });

    test('rejects missing project manifest, collisions, and quotas', () {
      _expectCode(
        () => builder.build(<String, List<int>>{
          'presentation/icon.png': <int>[1],
        }),
        'projectManifestMissing',
      );
      _expectCode(
        () => builder.build(<String, List<int>>{
          'project/project.json': <int>[1],
          'presentation/Icon.png': <int>[1],
          'presentation/icon.png': <int>[1],
        }),
        'pathCollision',
      );
      _expectCode(
        () => const GamePackageInventoryBuilder(
          maxFileBytes: 2,
        ).build(<String, List<int>>{
          'project/project.json': <int>[1, 2, 3],
        }),
        'fileTooLarge',
      );
      _expectCode(
        () => const GamePackageInventoryBuilder(
          maxTotalBytes: 2,
        ).build(<String, List<int>>{
          'project/project.json': <int>[1, 2, 3],
        }),
        'payloadTooLarge',
      );
      _expectCode(
        () => builder.build(<String, List<int>>{
          'project/project.json': <int>[],
        }),
        'invalidTotalBytes',
      );
      _expectCode(
        () => builder.build(
          <String, List<int>>{
            'project/project.json': <int>[1],
          },
          mediaTypeForPath: (_) => 'not a media type',
        ),
        'invalidMediaType',
      );
      expect(
        () => builder.build(<String, List<int>>{
          'project/project.json': <int>[1],
          'project/data/invalid?.json': <int>[1],
        }),
        throwsA(
          isA<GamePackageFormatException>()
              .having(
                (error) => error.code,
                'code',
                'invalidPackagePath',
              )
              .having(
                (error) => error.path,
                'path',
                'project/data/invalid?.json',
              ),
        ),
      );
    });
  });
}

void _expectCode(void Function() operation, String code) {
  expect(
    operation,
    throwsA(
      isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', code),
    ),
  );
}
