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
      const service = ProjectBrandingImageImportService();
      final dimensions = <ProjectBrandingImageRole, (int, int)>{
        ProjectBrandingImageRole.icon: (64, 64),
        ProjectBrandingImageRole.cover: (640, 360),
        ProjectBrandingImageRole.hero: (256, 128),
      };

      for (final role in ProjectBrandingImageRole.values) {
        final size = dimensions[role]!;
        final source = File('${root.path}/${role.name}.png')
          ..writeAsBytesSync(
            image.encodePng(image.Image(width: size.$1, height: size.$2)),
          );
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
        expect(imported.width, size.$1);
        expect(imported.height, size.$2);
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

    test('enforces image byte and role-specific dimension limits', () async {
      final root =
          Directory.systemTemp.createTempSync('branding-image-limits-');
      addTearDown(() => root.deleteSync(recursive: true));

      Future<void> expectRejected({
        required String name,
        required ProjectBrandingImageRole role,
        required int width,
        required int height,
        required String code,
      }) async {
        final source = File('${root.path}/$name.png')
          ..writeAsBytesSync(
            image.encodePng(image.Image(width: width, height: height)),
          );
        await expectLater(
          const ProjectBrandingImageImportService().importIntoProject(
            projectRoot: root,
            role: role,
            sourceFile: source,
          ),
          throwsA(
            isA<ProjectBrandingImageImportException>().having(
              (error) => error.code,
              'code',
              code,
            ),
          ),
        );
      }

      final validIconBytes = image.encodePng(
        image.Image(width: 64, height: 64),
      );
      final validIcon = File('${root.path}/too-large.png')
        ..writeAsBytesSync(validIconBytes);
      await expectLater(
        ProjectBrandingImageImportService(
          maxSizeBytes: validIconBytes.length - 1,
        ).importIntoProject(
          projectRoot: root,
          role: ProjectBrandingImageRole.icon,
          sourceFile: validIcon,
        ),
        throwsA(
          isA<ProjectBrandingImageImportException>().having(
            (error) => error.code,
            'code',
            'brandingImageSizeExceeded',
          ),
        ),
      );
      await expectRejected(
        name: 'icon-not-square',
        role: ProjectBrandingImageRole.icon,
        width: 64,
        height: 65,
        code: 'brandingIconMustBeSquare',
      );
      await expectRejected(
        name: 'icon-too-small',
        role: ProjectBrandingImageRole.icon,
        width: 63,
        height: 63,
        code: 'brandingIconDimensionsUnsupported',
      );
      await expectRejected(
        name: 'icon-too-large',
        role: ProjectBrandingImageRole.icon,
        width: 1025,
        height: 1025,
        code: 'brandingIconDimensionsUnsupported',
      );
      await expectRejected(
        name: 'cover-too-small',
        role: ProjectBrandingImageRole.cover,
        width: 639,
        height: 360,
        code: 'brandingCoverDimensionsUnsupported',
      );
      await expectRejected(
        name: 'hero-too-small',
        role: ProjectBrandingImageRole.hero,
        width: 256,
        height: 127,
        code: 'brandingHeroDimensionsUnsupported',
      );
      await expectRejected(
        name: 'dimensions-too-large',
        role: ProjectBrandingImageRole.cover,
        width: 4097,
        height: 360,
        code: 'brandingImageDimensionsExceeded',
      );
    });
  });
}
