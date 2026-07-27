import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_editor/personalization_hub.dart';

void main() {
  group('ProjectBrandingImageImportService', () {
    test('imports every branding image role into project-owned assets',
        () async {
      final root =
          Directory.systemTemp.createTempSync('branding-image-import-');
      addTearDown(() => root.deleteSync(recursive: true));
      final source = File('${root.path}/source.png')
        ..writeAsBytesSync(
          image.encodePng(image.Image(width: 8, height: 6)),
        );
      const service = ProjectBrandingImageImportService();

      for (final role in ProjectBrandingImageRole.values) {
        final imported = await service.importIntoProject(
          projectRoot: root,
          role: role,
          sourceFile: source,
        );

        expect(
          imported.relativePath,
          startsWith('assets/presentation/branding/${role.name}-'),
        );
        expect(imported.relativePath, endsWith('.png'));
        expect(imported.width, 8);
        expect(imported.height, 6);
        expect(
            File('${root.path}/${imported.relativePath}').existsSync(), isTrue);
      }
      expect(
        root
            .listSync(recursive: true)
            .where((entry) => entry.path.contains('.branding-import-')),
        isEmpty,
      );
    });

    test('rejects missing, unsupported, and corrupt image files', () async {
      final root =
          Directory.systemTemp.createTempSync('branding-image-invalid-');
      addTearDown(() => root.deleteSync(recursive: true));
      final unsupported = File('${root.path}/branding.gif')
        ..writeAsBytesSync(
          image.encodePng(image.Image(width: 2, height: 2)),
        );
      final corrupt = File('${root.path}/branding.png')
        ..writeAsStringSync('not an image');
      const service = ProjectBrandingImageImportService();

      await expectLater(
        service.importIntoProject(
          projectRoot: root,
          role: ProjectBrandingImageRole.icon,
          sourceFile: File('${root.path}/missing.png'),
        ),
        throwsA(
          isA<ProjectBrandingImageImportException>().having(
            (error) => error.code,
            'code',
            'brandingImageMissing',
          ),
        ),
      );
      await expectLater(
        service.importIntoProject(
          projectRoot: root,
          role: ProjectBrandingImageRole.cover,
          sourceFile: unsupported,
        ),
        throwsA(
          isA<ProjectBrandingImageImportException>().having(
            (error) => error.code,
            'code',
            'brandingImageFormatUnsupported',
          ),
        ),
      );
      await expectLater(
        service.importIntoProject(
          projectRoot: root,
          role: ProjectBrandingImageRole.hero,
          sourceFile: corrupt,
        ),
        throwsA(
          isA<ProjectBrandingImageImportException>().having(
            (error) => error.code,
            'code',
            'brandingImageCorrupt',
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
