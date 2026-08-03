import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('LocalArtifactStore security', () {
    late Directory sandbox;
    late Directory allowed;

    setUp(() async {
      sandbox =
          await Directory.systemTemp.createTemp('pokemap_asset_security_');
      allowed = await Directory('${sandbox.path}/allowed').create();
    });

    tearDown(() async {
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    });

    test('rejects a source symlink that resolves outside the allowed roots',
        () async {
      final outside = File('${sandbox.path}/outside.png');
      await outside.writeAsBytes(_pngBytes);
      final link = Link('${allowed.path}/escape.png');
      await link.create(outside.path);
      final store = LocalArtifactStore(
        allowedSourceRoots: [allowed.path],
        maximumArtifactBytes: 1024,
      );

      await expectLater(
        store.importFile(link.path),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.source_outside_allowed_roots',
          ),
        ),
      );
    });

    test('rejects an oversized source before retaining its bytes', () async {
      final source = File('${allowed.path}/large.bin');
      await source.writeAsBytes(List<int>.filled(9, 1));
      final store = LocalArtifactStore(
        allowedSourceRoots: [allowed.path],
        maximumArtifactBytes: 8,
      );

      await expectLater(
        store.importFile(source.path),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.too_large',
          ),
        ),
      );
      expect(store.list(), isEmpty);
    });

    test('uses sniffed MIME and rejects a conflicting declared type', () async {
      final source = File('${allowed.path}/sprite.png');
      await source.writeAsBytes(_pngBytes);
      final store = LocalArtifactStore(
        allowedSourceRoots: [allowed.path],
        maximumArtifactBytes: 1024,
      );

      await expectLater(
        store.importFile(source.path, declaredMediaType: 'audio/mpeg'),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.mime_mismatch',
          ),
        ),
      );
    });

    test('authorizes exactly one user-selected source outside project roots',
        () async {
      final selected = File('${sandbox.path}/selected.png');
      final sibling = File('${sandbox.path}/sibling.png');
      await selected.writeAsBytes(_pngBytes);
      await sibling.writeAsBytes(_pngBytes);
      final store = LocalArtifactStore(
        allowedSourceRoots: [allowed.path],
        maximumArtifactBytes: 1024,
      );

      await store.authorizeSourceFile(selected.path);

      final staged = await store.importFile(selected.path);
      expect(staged.reference.mediaType, 'image/png');
      await expectLater(
        store.importFile(sibling.path),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.source_outside_allowed_roots',
          ),
        ),
      );
    });
  });
}

const List<int> _pngBytes = [
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
];
