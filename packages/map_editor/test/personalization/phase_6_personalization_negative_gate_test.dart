import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PST-062 fail-closed publication gate', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync(
        'personalization-phase-6-negative-',
      );
    });

    tearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    test('blocks a corrupt intro video', () async {
      _writeBytes(root, 'assets/intro.mp4', utf8.encode('not an mp4'));
      _writeBytes(root, 'assets/poster.png', _onePixelPng);

      final result = await _inspect(
        root,
        ProjectPresentationProfile(
          intro: ProjectIntroVideoProfile.fromLandscape(
            videoPath: 'assets/intro.mp4',
            posterPath: 'assets/poster.png',
            durationMilliseconds: 1000,
            width: 1280,
            height: 720,
            bitrateKbps: 128,
            sizeBytes: 10,
            videoCodec: 'h264',
            audioCodec: 'none',
          ),
        ),
      );

      _expectBlockedBy(result, 'introCodecSignatureInvalid');
    });

    test('blocks an invalid embedded font', () async {
      _writeBytes(root, 'assets/display.ttf', <int>[1, 2, 3, 4]);
      _writeText(
        root,
        'assets/display-license.txt',
        'Redistribution permitted.',
      );

      final result = await _inspect(
        root,
        ProjectPresentationProfile(
          typography: _typography(licensePath: 'assets/display-license.txt'),
        ),
      );

      _expectBlockedBy(result, 'fontSignatureInvalid');
    });

    test('blocks an embedded font without a license', () async {
      _writeBytes(root, 'assets/display.ttf', <int>[0, 1, 0, 0, 0, 0, 0, 0]);

      final result = await _inspect(
        root,
        ProjectPresentationProfile(typography: _typography()),
      );

      _expectBlockedBy(result, 'typographyLicenseRequired');
    });

    test('blocks an insufficient semantic contrast', () async {
      final unsafeTheme = safeProjectSemanticTheme.copyWith(
        textPrimary: safeProjectSemanticTheme.background,
      );

      final result = await _inspect(
        root,
        ProjectPresentationProfile(theme: unsafeTheme),
      );

      _expectBlockedBy(result, 'themeContrastInsufficient');
      expect(
        result.report.issues
            .firstWhere((issue) => issue.code == 'themeContrastInsufficient')
            .correctionKind,
        PersonalizationCorrectionKind.useSafeTheme,
      );
    });
  });
}

Future<ProjectPresentationPreflightResult> _inspect(
  Directory root,
  ProjectPresentationProfile profile,
) => const FileSystemProjectPresentationPreflight().inspect(
  projectRoot: root,
  profile: profile,
);

ProjectTypographyProfile _typography({String? licensePath}) =>
    ProjectTypographyProfile(
      display: ProjectTypographyRoleProfile(
        fontPath: 'assets/display.ttf',
        family: 'Aube Display',
        licensePath: licensePath,
        redistributable: true,
        glyphCoverage: const <String>[
          'latin',
          'latinExtended',
          'digits',
          'punctuation',
        ],
      ),
    );

void _expectBlockedBy(
  ProjectPresentationPreflightResult result,
  String expectedCode,
) {
  final issue = result.report.issues.firstWhere(
    (candidate) => candidate.code == expectedCode,
  );
  expect(issue.isBlocker, isTrue);
  expect(issue.correctionLabel, isNotEmpty);
  expect(result.report.status, PersonalizationReadinessStatus.blocked);
  expect(result.report.isReadyToExport, isFalse);
}

void _writeBytes(Directory root, String relativePath, List<int> bytes) {
  final file = File(p.join(root.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes, flush: true);
}

void _writeText(Directory root, String relativePath, String content) {
  final file = File(p.join(root.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content, flush: true);
}

final List<int> _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
