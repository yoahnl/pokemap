import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  group('ProjectTitleMusicImportService', () {
    test('imports supported title music into project-owned assets', () async {
      final root = Directory.systemTemp.createTempSync('title-music-import-');
      addTearDown(() => root.deleteSync(recursive: true));
      const service = ProjectTitleMusicImportService();
      final fixtures = <String, List<int>>{
        'ogg': <int>[0x4f, 0x67, 0x67, 0x53, 0, 0, 0, 0],
        'wav': <int>[
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x41,
          0x56,
          0x45,
        ],
        'mp3': <int>[0x49, 0x44, 0x33, 4, 0, 0, 0, 0],
        'flac': <int>[0x66, 0x4c, 0x61, 0x43, 0, 0, 0, 0],
        'm4a': <int>[
          0,
          0,
          0,
          16,
          0x66,
          0x74,
          0x79,
          0x70,
          0x4d,
          0x34,
          0x41,
          0x20
        ],
      };

      for (final entry in fixtures.entries) {
        final source = File('${root.path}/source.${entry.key}')
          ..writeAsBytesSync(entry.value);
        final imported = await service.importIntoProject(
          projectRoot: root,
          sourceFile: source,
        );

        expect(
          imported.relativePath,
          startsWith('assets/presentation/branding/title-music-'),
        );
        expect(imported.relativePath, endsWith('.${entry.key}'));
        expect(imported.sizeBytes, entry.value.length);
        expect(
          File('${root.path}/${imported.relativePath}').readAsBytesSync(),
          entry.value,
        );
      }
      expect(
        root
            .listSync(recursive: true)
            .where((entry) => entry.path.contains('.title-music-import-')),
        isEmpty,
      );
    });

    test('rejects missing, unsupported, and mismatched audio files', () async {
      final root = Directory.systemTemp.createTempSync('title-music-invalid-');
      addTearDown(() => root.deleteSync(recursive: true));
      const service = ProjectTitleMusicImportService();
      final unsupported = File('${root.path}/theme.aac')
        ..writeAsBytesSync(<int>[0x4f, 0x67, 0x67, 0x53]);
      final mismatched = File('${root.path}/theme.ogg')
        ..writeAsBytesSync(<int>[0x49, 0x44, 0x33, 4, 0, 0]);

      await expectLater(
        service.importIntoProject(
          projectRoot: root,
          sourceFile: File('${root.path}/missing.ogg'),
        ),
        throwsA(
          isA<ProjectTitleMusicImportException>().having(
            (error) => error.code,
            'code',
            'titleMusicMissing',
          ),
        ),
      );
      await expectLater(
        service.importIntoProject(
          projectRoot: root,
          sourceFile: unsupported,
        ),
        throwsA(
          isA<ProjectTitleMusicImportException>().having(
            (error) => error.code,
            'code',
            'titleMusicFormatUnsupported',
          ),
        ),
      );
      await expectLater(
        service.importIntoProject(
          projectRoot: root,
          sourceFile: mismatched,
        ),
        throwsA(
          isA<ProjectTitleMusicImportException>().having(
            (error) => error.code,
            'code',
            'titleMusicSignatureInvalid',
          ),
        ),
      );
      expect(
        Directory('${root.path}/assets/presentation/branding').existsSync(),
        isFalse,
      );
    });
  });
}
