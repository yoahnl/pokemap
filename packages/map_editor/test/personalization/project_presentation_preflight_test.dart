import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('presentation-preflight-');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('certifies real assets, licenses, contrasts, and codecs', () async {
    _writeBytes(root, 'assets/presentation/icon.png', _onePixelPng);
    _writeBytes(
      root,
      'assets/presentation/title.ogg',
      ascii.encode('OggS title music'),
    );
    _writeBytes(
      root,
      'assets/presentation/intro/intro.mp4',
      <int>[
        0,
        0,
        0,
        24,
        ...ascii.encode('ftypisom'),
        0,
        0,
        0,
        0,
        ...ascii.encode('isomavc1mp4a'),
      ],
    );
    _writeBytes(root, 'assets/presentation/intro/poster.png', _onePixelPng);
    _writeText(
      root,
      'assets/presentation/intro/captions.vtt',
      'WEBVTT\n\n00:00.000 --> 00:01.000\nBienvenue.\n',
    );
    _writeBytes(
      root,
      'assets/presentation/fonts/display.ttf',
      <int>[0, 1, 0, 0, 0, 0, 0, 0],
    );
    _writeText(
      root,
      'assets/presentation/fonts/display-license.txt',
      'Redistribution permitted.',
    );
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(
        iconPath: 'assets/presentation/icon.png',
        titleMusicPath: 'assets/presentation/title.ogg',
      ),
      intro: ProjectIntroVideoProfile(
        videoPath: 'assets/presentation/intro/intro.mp4',
        posterPath: 'assets/presentation/intro/poster.png',
        captionsPath: 'assets/presentation/intro/captions.vtt',
        durationMilliseconds: 1000,
        width: 1920,
        height: 1080,
        bitrateKbps: 4000,
        sizeBytes: 32,
        videoCodec: 'h264',
        audioCodec: 'aac',
      ),
      typography: ProjectTypographyProfile(
        display: ProjectTypographyRoleProfile(
          fontPath: 'assets/presentation/fonts/display.ttf',
          family: 'Display',
          licensePath: 'assets/presentation/fonts/display-license.txt',
          redistributable: true,
          glyphCoverage: <String>[
            'latin',
            'latinExtended',
            'digits',
            'punctuation',
          ],
        ),
      ),
      theme: safeProjectSemanticTheme,
    );

    final result = await const FileSystemProjectPresentationPreflight().inspect(
      projectRoot: root,
      profile: profile,
    );

    expect(result.checkedAssetCount, 7);
    expect(result.report.issues, isEmpty);
    expect(result.report.isReadyToExport, isTrue);
  });

  test('reports missing files and never follows symbolic links', () async {
    final outside = File(p.join(root.parent.path, 'outside-presentation.png'))
      ..writeAsBytesSync(_onePixelPng);
    addTearDown(() {
      if (outside.existsSync()) outside.deleteSync();
    });
    final linkPath = p.join(root.path, 'assets', 'linked.png');
    Link(linkPath)
      ..parent.createSync(recursive: true)
      ..createSync(outside.path);
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(
        iconPath: 'assets/missing.png',
        coverPath: 'assets/linked.png',
      ),
    );

    final result = await const FileSystemProjectPresentationPreflight().inspect(
      projectRoot: root,
      profile: profile,
    );

    expect(
      result.report.issues.map((issue) => issue.code),
      containsAll(<String>[
        'presentationAssetMissing',
        'presentationAssetNotRegular',
      ]),
    );
    expect(result.report.blockerCount, 2);
  });

  test('rejects corrupt signatures, blank licenses, and invalid WebVTT',
      () async {
    _writeText(root, 'assets/icon.png', 'not an image');
    _writeText(root, 'assets/title.ogg', 'not ogg');
    _writeText(root, 'assets/intro.mp4', 'ftyp but no supported codec');
    _writeText(root, 'assets/poster.png', 'not an image');
    _writeText(root, 'assets/captions.vtt', 'SRT');
    _writeBytes(root, 'assets/font.ttf', <int>[1, 2, 3, 4]);
    _writeText(root, 'assets/license.txt', '   ');
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(
        iconPath: 'assets/icon.png',
        titleMusicPath: 'assets/title.ogg',
      ),
      intro: ProjectIntroVideoProfile(
        videoPath: 'assets/intro.mp4',
        posterPath: 'assets/poster.png',
        captionsPath: 'assets/captions.vtt',
        durationMilliseconds: 1000,
        width: 1920,
        height: 1080,
        bitrateKbps: 4000,
        sizeBytes: 27,
        videoCodec: 'h264',
        audioCodec: 'none',
      ),
      typography: ProjectTypographyProfile(
        display: ProjectTypographyRoleProfile(
          fontPath: 'assets/font.ttf',
          family: 'Display',
          licensePath: 'assets/license.txt',
          redistributable: true,
          glyphCoverage: <String>[
            'latin',
            'latinExtended',
            'digits',
            'punctuation',
          ],
        ),
      ),
    );

    final result = await const FileSystemProjectPresentationPreflight().inspect(
      projectRoot: root,
      profile: profile,
    );

    expect(
      result.report.issues.map((issue) => issue.code),
      containsAll(<String>[
        'brandingImageCorrupt',
        'titleMusicSignatureInvalid',
        'introCodecSignatureInvalid',
        'introPosterInvalid',
        'introCaptionsInvalid',
        'fontSignatureInvalid',
        'fontLicenseInvalid',
      ]),
    );
    expect(result.report.isReadyToExport, isFalse);
  });

  test('keeps core contrast and declared codec diagnostics authoritative',
      () async {
    final unsafeTheme = safeProjectSemanticTheme.copyWith(
      textPrimary: safeProjectSemanticTheme.background,
    );
    const intro = ProjectIntroVideoProfile(
      videoPath: 'assets/missing.mp4',
      posterPath: 'assets/missing.png',
      durationMilliseconds: 1000,
      width: 1920,
      height: 1080,
      bitrateKbps: 4000,
      sizeBytes: 32,
      videoCodec: 'hevc',
      audioCodec: 'opus',
    );

    final result = await const FileSystemProjectPresentationPreflight().inspect(
      projectRoot: root,
      profile: ProjectPresentationProfile(
        intro: intro,
        theme: unsafeTheme,
      ),
    );

    expect(
      result.report.issues.map((issue) => issue.code),
      containsAll(<String>[
        'introVideoCodecUnsupported',
        'introAudioCodecUnsupported',
        'themeContrastInsufficient',
      ]),
    );
  });
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
