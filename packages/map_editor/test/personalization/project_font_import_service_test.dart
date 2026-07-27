import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:path/path.dart' as p;

void main() {
  test('production SFNT probe reads the bundled editor font and glyphs',
      () async {
    final result = await const SfntProjectFontProbe().probe(
      File('assets/fonts/pokemap_capture_sans_regular.ttf'),
    );

    expect(result.family, isNotEmpty);
    expect(
      result.glyphCoverage,
      containsAll(requiredProjectFontGlyphCoverage),
    );
  });

  test('imports a licensed font into project-owned role assets', () async {
    final source = await Directory.systemTemp.createTemp('font-source-');
    final project = await Directory.systemTemp.createTemp('font-project-');
    addTearDown(() => source.delete(recursive: true));
    addTearDown(() => project.delete(recursive: true));
    final font = await File(p.join(source.path, 'aube.otf'))
        .writeAsBytes(<int>[0x4f, 0x54, 0x54, 0x4f, 0, 0, 0, 0]);
    final license = await File(p.join(source.path, 'OFL.txt'))
        .writeAsString('SIL Open Font License 1.1');

    final profile = await const ProjectFontImportService(
      probe: _Probe(
        ProjectFontProbeResult(
          family: 'Aube Display',
          glyphCoverage: <String>{
            'latin',
            'latinExtended',
            'digits',
            'punctuation',
          },
        ),
      ),
    ).importIntoProject(
      projectRoot: project,
      role: ProjectTypographyRole.display,
      fontFile: font,
      licenseFile: license,
      redistributionConfirmed: true,
      fallbackFamilies: const <String>['sans-serif'],
    );

    expect(profile.family, 'Aube Display');
    expect(profile.redistributable, isTrue);
    expect(profile.fontPath, contains('/display-'));
    expect(
        await File(p.join(project.path, profile.fontPath!)).exists(), isTrue);
    expect(
      await File(p.join(project.path, profile.licensePath!)).exists(),
      isTrue,
    );
  });

  test('rejects incomplete glyph coverage before writing project assets',
      () async {
    final source = await Directory.systemTemp.createTemp('font-source-');
    final project = await Directory.systemTemp.createTemp('font-project-');
    addTearDown(() => source.delete(recursive: true));
    addTearDown(() => project.delete(recursive: true));
    final font = await File(p.join(source.path, 'aube.otf'))
        .writeAsBytes(<int>[0x4f, 0x54, 0x54, 0x4f, 0, 0, 0, 0]);
    final license =
        await File(p.join(source.path, 'LICENSE.txt')).writeAsString('License');

    expect(
      () => const ProjectFontImportService(
        probe: _Probe(
          ProjectFontProbeResult(
            family: 'Aube Display',
            glyphCoverage: <String>{'latin', 'digits'},
          ),
        ),
      ).importIntoProject(
        projectRoot: project,
        role: ProjectTypographyRole.display,
        fontFile: font,
        licenseFile: license,
        redistributionConfirmed: true,
        fallbackFamilies: const <String>['sans-serif'],
      ),
      throwsA(
        isA<ProjectFontImportException>().having(
          (error) => error.code,
          'code',
          'fontGlyphCoverageIncomplete',
        ),
      ),
    );
    expect(
      await Directory(p.join(project.path, 'assets')).exists(),
      isFalse,
    );
  });
}

final class _Probe implements ProjectFontProbe {
  const _Probe(this.result);

  final ProjectFontProbeResult result;

  @override
  Future<ProjectFontProbeResult> probe(File file) async => result;
}
