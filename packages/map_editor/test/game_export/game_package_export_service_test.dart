import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  test('persists stable metadata and rejects deriving identity implicitly',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final store = GamePackageExportProfileStore(projectRoot: root);
    final profile = neutralExportProfile();

    await store.save(profile);
    expect(await store.load(), profile);
    expect(
      () => GamePackageExportProfile(
        gameId: '',
        gameVersion: '1.0.0',
        title: 'A title is not an identity',
        authorName: 'Author',
        defaultLocale: 'fr',
        supportedLocales: const <String>['fr'],
      ),
      throwsA(isA<GamePackageExportException>()),
    );
  });

  test('builds, reopens and writes a deterministic certified package',
      () async {
    final root = await createAuthorProject();
    addTearDown(() => root.delete(recursive: true));
    const service = GamePackageExportService();
    final profile = neutralExportProfile();

    final first = await service.build(
      projectRoot: root,
      profile: profile,
    );
    final second = await service.build(
      projectRoot: root,
      profile: profile,
    );

    expect(first.packageBytes, second.packageBytes);
    expect(first.certification.isCertified, isTrue);
    expect(first.manifest.gameId, profile.gameId);
    expect(first.manifest.title, profile.title);
    expect(first.manifest.presentation?.schemaVersion, 1);
    expect(first.manifest.usesLegacyBranding, isFalse);
    expect(first.manifest.branding?.icon, 'presentation/icon.png');
    expect(
      first.manifest.compatibility.requiredCapabilities,
      contains('map@1'),
    );
    expect(first.inspection.manifest.content.treeSha256,
        first.manifest.content.treeSha256);
    expect(
      first.inspection.payloadPaths,
      contains('project/dialogues/dialogue.intro.json'),
    );
    expect(
      first.inspection.payloadPaths,
      isNot(contains('project/dialogues/intro.yarn')),
    );

    final output = File(p.join(root.parent.path, first.suggestedFileName));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });
    final written = await service.exportToFile(
      projectRoot: root,
      profile: profile,
      outputFile: output,
    );
    expect(await output.readAsBytes(), written.packageBytes);
    expect(
      const GamePackageInspector().inspect(await output.readAsBytes()).manifest,
      isA<GamePackageManifest>(),
    );
  });

  test('packages authored intro and typography contracts with their assets',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final video = <int>[
      0,
      0,
      0,
      24,
      ...utf8.encode('ftypisom'),
      0,
      0,
      0,
      0,
      ...utf8.encode('isomavc1mp4a'),
    ];
    await File(p.join(root.path, 'assets', 'intro.mp4'))
        .writeAsBytes(video, flush: true);
    await File(p.join(root.path, 'assets', 'poster.png'))
        .writeAsBytes(onePixelPng, flush: true);
    await File(p.join(root.path, 'assets', 'captions.vtt')).writeAsString(
      'WEBVTT\n\n00:00.000 --> 00:01.000\nBienvenue\n',
      flush: true,
    );
    await File(p.join(root.path, 'assets', 'display.ttf'))
        .writeAsBytes(<int>[0, 1, 0, 0, 0, 0, 0, 0], flush: true);
    await File(p.join(root.path, 'assets', 'display-license.txt'))
        .writeAsString('Redistribution permitted.', flush: true);
    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    project['presentation'] = <String, Object?>{
      'schemaVersion': 1,
      'branding': <String, Object?>{},
      'intro': <String, Object?>{
        'videoPath': 'assets/intro.mp4',
        'posterPath': 'assets/poster.png',
        'captionsPath': 'assets/captions.vtt',
        'durationMilliseconds': 1000,
        'width': 1280,
        'height': 720,
        'bitrateKbps': 128,
        'sizeBytes': video.length,
        'videoCodec': 'h264',
        'audioCodec': 'aac',
        'reducedMotionBehavior': 'poster',
        'allowReplay': true,
      },
      'typography': <String, Object?>{
        'display': <String, Object?>{
          'fontPath': 'assets/display.ttf',
          'family': 'Aube Display',
          'licensePath': 'assets/display-license.txt',
          'redistributable': true,
          'fallbackFamilies': <String>['sans-serif'],
          'glyphCoverage': <String>[
            'latin',
            'latinExtended',
            'digits',
            'punctuation',
          ],
        },
        'body': <String, Object?>{
          'fallbackFamilies': <String>['sans-serif'],
        },
        'dialogue': <String, Object?>{
          'fallbackFamilies': <String>['sans-serif'],
        },
        'numbers': <String, Object?>{
          'fallbackFamilies': <String>['monospace'],
        },
      },
    };
    await projectFile.writeAsString(jsonEncode(project), flush: true);

    final artifact = await const GamePackageExportService().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(
      artifact.manifest.presentation?.intro?.video,
      'presentation/intro/video.mp4',
    );
    expect(
      artifact.inspection.payloadPaths,
      containsAll(<String>[
        'presentation/intro/video.mp4',
        'presentation/intro/poster.png',
        'presentation/intro/captions.vtt',
      ]),
    );
    expect(
      artifact.manifest.presentation?.typography?.display.family,
      'Aube Display',
    );
    expect(
      artifact.inspection.payloadPaths,
      containsAll(<String>[
        'presentation/fonts/display.ttf',
        'presentation/fonts/display-license.txt',
      ]),
    );
  });

  test(
      'falls back to a verified direct write when macOS denies sibling staging',
      () async {
    final root = await createAuthorProject();
    addTearDown(() => root.delete(recursive: true));
    var atomicWriteAttempted = false;
    final service = GamePackageExportService(
      atomicFileWriter: ({
        required outputFile,
        required packageBytes,
        required packageSha256,
      }) async {
        atomicWriteAttempted = true;
        throw FileSystemException(
          'Operation not permitted',
          '${outputFile.path}.sandbox-stage.tmp',
          const OSError('Operation not permitted', 1),
        );
      },
    );
    final output = File(
      p.join(root.parent.path, 'sandbox-selected.pokemapgame'),
    );
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });

    final artifact = await service.exportToFile(
      projectRoot: root,
      profile: neutralExportProfile(),
      outputFile: output,
    );

    expect(atomicWriteAttempted, isTrue);
    expect(await output.readAsBytes(), artifact.packageBytes);
    expect(
      const GamePackageInspector().inspect(await output.readAsBytes()).manifest,
      isA<GamePackageManifest>(),
    );
    expect(await File('${output.path}.backup').exists(), isFalse);
  });

  test('refuses a required capability outside the Phase 0 host contract',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final profile = neutralExportProfile().copyWith(
      requiredCapabilities: const <String>['engine.extension@1'],
    );

    await expectLater(
      const GamePackageExportService().build(
        projectRoot: root,
        profile: profile,
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'capabilityUnsupported',
        ),
      ),
    );
  });
}
