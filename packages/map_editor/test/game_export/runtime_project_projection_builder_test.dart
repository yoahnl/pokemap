import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  test('projects a clean data-only runtime tree without mutating the author',
      () async {
    final root = await createAuthorProject(withCanonicalPokemon: false);
    addTearDown(() => root.delete(recursive: true));

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(result.payloadFiles, contains('project/project.json'));
    expect(
      result.payloadFiles,
      contains('project/dialogues/dialogue.intro.json'),
    );
    expect(
      result.payloadFiles,
      contains('project/data/pokemon/media/creature.png'),
    );
    expect(result.payloadFiles, contains('presentation/icon.png'));
    expect(result.payloadFiles, contains('presentation/cover.png'));
    expect(result.payloadFiles, contains('legal/LICENSE.txt'));
    expect(result.payloadFiles, contains('legal/CREDITS.txt'));
    expect(
      result.payloadFiles.keys,
      isNot(contains('project/dialogues/intro.yarn')),
    );
    expect(
      result.payloadFiles.keys,
      isNot(contains('project/runtime_host_launch_save.json')),
    );
    expect(
      result.payloadFiles.keys.any((path) => path.contains('/saves/')),
      isFalse,
    );
    expect(result.compiledDialogueCount, 1);
    expect(result.scrubbedSecretFieldCount, 2);

    final projectedProject = jsonDecode(
      utf8.decode(result.payloadFiles['project/project.json']!),
    ) as Map<String, dynamic>;
    expect(
      projectedProject['settings'] as Map<String, dynamic>,
      isNot(contains('mistralApiKey')),
    );
    expect(
      projectedProject['globalProperties'] as Map<String, dynamic>,
      isNot(contains('apiKey')),
    );
    expect(
      (projectedProject['dialogues'] as List).single['relativePath'],
      'dialogues/dialogue.intro.json',
    );

    final projectedMap = jsonDecode(
      utf8.decode(result.payloadFiles['project/maps/start.json']!),
    ) as Map<String, dynamic>;
    expect(
      (projectedMap['dialogue'] as Map<String, dynamic>)['scriptPathRelative'],
      '',
    );
    final compiled = const RuntimeDialogueDocumentCodec().decodeUtf8(
      result.payloadFiles['project/dialogues/dialogue.intro.json']!,
    );
    expect(compiled.nodes.single.title, 'Start');

    final authorProject =
        await File(p.join(root.path, 'project.json')).readAsString();
    expect(
      authorProject,
      contains('fixture-secret-that-must-not-ship'),
    );
    expect(
      await File(p.join(root.path, 'dialogues', 'intro.yarn')).exists(),
      isTrue,
    );
  });

  test('project presentation overrides legacy export-profile branding',
      () async {
    final root = await createAuthorProject(
      withDialogue: false,
      withCanonicalPokemon: false,
    );
    addTearDown(() => root.delete(recursive: true));
    final authoredIcon = File(p.join(root.path, 'assets', 'authored-icon.png'));
    await authoredIcon.writeAsBytes(<int>[1, 2, 3, 4], flush: true);
    final introVideo = File(p.join(root.path, 'assets', 'intro.mp4'));
    await introVideo.writeAsBytes(_h264Mp4Fixture, flush: true);
    final introPoster = File(p.join(root.path, 'assets', 'intro-poster.png'));
    await introPoster.writeAsBytes(onePixelPng, flush: true);
    final introCaptions = File(p.join(root.path, 'assets', 'intro.vtt'));
    await introCaptions.writeAsString(
      'WEBVTT\n\n00:00.000 --> 00:01.000\nBienvenue\n',
      flush: true,
    );
    final displayFont = File(p.join(root.path, 'assets', 'display.ttf'));
    await displayFont.writeAsBytes(<int>[0, 1, 0, 0, 0, 0, 0, 0]);
    final displayLicense =
        File(p.join(root.path, 'assets', 'display-license.txt'));
    await displayLicense.writeAsString('Redistribution permitted.');
    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    Map<String, Object?> videoVariant({
      required int width,
      required int height,
      required String audioCodec,
    }) =>
        <String, Object?>{
          'videoPath': 'assets/intro.mp4',
          'posterPath': 'assets/intro-poster.png',
          'captionsPath': 'assets/intro.vtt',
          'durationMilliseconds': 1000,
          'width': width,
          'height': height,
          'bitrateKbps': 128,
          'sizeBytes': _h264Mp4Fixture.length,
          'videoCodec': 'h264',
          'audioCodec': audioCodec,
        };
    project['presentation'] = <String, Object?>{
      'schemaVersion': 2,
      'branding': <String, Object?>{
        'iconPath': 'assets/authored-icon.png',
        'accentColor': '#123456',
        'layoutVariant': 'centered',
      },
      'intro': <String, Object?>{
        'media': <String, Object?>{
          'landscape': videoVariant(
            width: 1280,
            height: 720,
            audioCodec: 'aac',
          ),
        },
        'reducedMotionBehavior': 'poster',
        'allowReplay': true,
      },
      'titleMotion': <String, Object?>{
        'promptLoop': <String, Object?>{
          'landscape': videoVariant(
            width: 1280,
            height: 720,
            audioCodec: 'none',
          ),
          'portrait': videoVariant(
            width: 720,
            height: 1280,
            audioCodec: 'none',
          ),
        },
        'menuLoop': <String, Object?>{
          'landscape': videoVariant(
            width: 1280,
            height: 720,
            audioCodec: 'none',
          ),
          'portrait': videoVariant(
            width: 720,
            height: 1280,
            audioCodec: 'none',
          ),
        },
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

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(result.presentation.branding.iconPath, 'assets/authored-icon.png');
    expect(result.presentation.branding.accentColor, '#123456');
    expect(result.payloadFiles['presentation/icon.png'], <int>[1, 2, 3, 4]);
    expect(
      result.payloadFiles['presentation/intro/landscape/video.mp4'],
      _h264Mp4Fixture,
    );
    expect(
      result.introVideoPackagePath,
      'presentation/intro/landscape/video.mp4',
    );
    expect(
      result.introPosterPackagePath,
      'presentation/intro/landscape/poster.png',
    );
    expect(
      result.introCaptionsPackagePath,
      'presentation/intro/landscape/captions.vtt',
    );
    expect(
      result.titlePromptMedia?.landscape.videoPackagePath,
      'presentation/title/prompt/landscape/video.mp4',
    );
    expect(
      result.titlePromptMedia?.portrait?.videoPackagePath,
      'presentation/title/prompt/portrait/video.mp4',
    );
    expect(
      result.titleMenuMedia?.landscape.videoPackagePath,
      'presentation/title/menu/landscape/video.mp4',
    );
    expect(
      result.titleMenuMedia?.portrait?.videoPackagePath,
      'presentation/title/menu/portrait/video.mp4',
    );
    expect(
      result.payloadFiles.keys,
      containsAll(<String>[
        'presentation/title/prompt/landscape/video.mp4',
        'presentation/title/prompt/portrait/video.mp4',
        'presentation/title/menu/landscape/video.mp4',
        'presentation/title/menu/portrait/video.mp4',
      ]),
    );
    expect(
      result.payloadFiles,
      contains('presentation/fonts/display.ttf'),
    );
    expect(
      result.payloadFiles,
      contains('presentation/fonts/display-license.txt'),
    );
    final projectedProject = jsonDecode(
      utf8.decode(result.payloadFiles['project/project.json']!),
    ) as Map<String, dynamic>;
    expect(
      ((projectedProject['presentation'] as Map)['branding']
          as Map)['accentColor'],
      '#123456',
    );
  });

  test('projects presentation media stored only in the canonical asset store',
      () async {
    final root = await createAuthorProject(
      withDialogue: false,
      withCanonicalPokemon: false,
    );
    addTearDown(() => root.delete(recursive: true));
    await _configureCatalogOnlyIntro(root);

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(
      result.payloadFiles['presentation/intro/landscape/video.mp4'],
      _h264Mp4Fixture,
    );
    expect(
      result.payloadFiles['presentation/intro/landscape/poster.png'],
      onePixelPng,
    );
  });

  test('rejects a canonical presentation blob with mismatched content',
      () async {
    final root = await createAuthorProject(
      withDialogue: false,
      withCanonicalPokemon: false,
    );
    addTearDown(() => root.delete(recursive: true));
    await _configureCatalogOnlyIntro(root, corruptVideo: true);

    expect(
      () => const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile(),
      ),
      throwsA(
        isA<GamePackageExportException>()
            .having(
              (error) => error.code,
              'code',
              'assetBlobIntegrityMismatch',
            )
            .having(
              (error) => error.path,
              'path',
              'assets/presentation/intro.mp4',
            ),
      ),
    );
  });

  test('rejects symlinks and branding paths outside the project root',
      () async {
    final root = await createAuthorProject(
      withDialogue: false,
      withCanonicalPokemon: false,
    );
    addTearDown(() => root.delete(recursive: true));
    final outside = await File(
      p.join(root.parent.path, 'pokemap-export-outside.png'),
    ).writeAsBytes(onePixelPng);
    addTearDown(() async {
      if (await outside.exists()) await outside.delete();
    });
    final link = Link(p.join(root.path, 'assets', 'linked.png'));
    await link.create(outside.path);

    expect(
      () => const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile(),
      ),
      throwsA(isA<GamePackageExportException>()),
    );
    expect(
      () => const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile().copyWith(iconPath: '../outside.png'),
      ),
      throwsA(isA<GamePackageExportException>()),
    );
  });

  test('enforces filesystem and file-size budgets before materializing bytes',
      () async {
    final root = await createAuthorProject(
      withDialogue: false,
      withCanonicalPokemon: false,
    );
    addTearDown(() => root.delete(recursive: true));

    expect(
      () => const RuntimeProjectProjectionBuilder(
        maxWorkspaceEntries: 1,
      ).build(
        projectRoot: root,
        profile: neutralExportProfile(),
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'workspaceEntryQuotaExceeded',
        ),
      ),
    );
    await File(p.join(root.path, 'assets', 'oversized.png')).writeAsBytes(
      List<int>.filled(4097, 0),
      flush: true,
    );
    expect(
      () => const RuntimeProjectProjectionBuilder(
        maxFileBytes: 4096,
      ).build(
        projectRoot: root,
        profile: neutralExportProfile(),
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'authoringFileTooLarge',
        ),
      ),
    );
  });

  test('rejects an image used as title music with a precise diagnostic',
      () async {
    final root = await createAuthorProject(withCanonicalPokemon: false);
    addTearDown(() => root.delete(recursive: true));

    expect(
      () => const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile().copyWith(
          titleMusicPath: 'assets/icon.png',
        ),
      ),
      throwsA(
        isA<GamePackageExportException>()
            .having((error) => error.code, 'code', 'invalidTitleMusic')
            .having(
              (error) => error.path,
              'path',
              'assets/icon.png',
            ),
      ),
    );
  });

  test('title music prefers the canonical blob over a stale physical file',
      () async {
    final root = await createAuthorProject(withCanonicalPokemon: false);
    addTearDown(() => root.delete(recursive: true));
    const logicalPath = 'assets/title.ogg';
    final physical = File(p.join(root.path, logicalPath));
    await physical.writeAsBytes(<int>[...utf8.encode('OggS'), 1]);
    final canonicalBytes = <int>[...utf8.encode('OggS'), 2];
    final artifact = ContentArtifactRef.fromBytes(
      canonicalBytes,
      mediaType: 'audio/ogg',
    );
    final catalog = AssetCatalog(
      records: <AssetRecord>[
        AssetRecord(
          id: 'presentation-title-music',
          logicalPath: logicalPath,
          artifact: artifact,
        ),
      ],
    );
    final catalogFile = File(p.join(root.path, assetCatalogStorageKey));
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(jsonEncode(catalog.toJson()), flush: true);
    final blob = File(p.join(root.path, assetBlobStorageKey(artifact)));
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(canonicalBytes, flush: true);

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile().copyWith(titleMusicPath: logicalPath),
    );

    expect(result.payloadFiles['project/$logicalPath'], canonicalBytes);
  });

  test('normalizes decomposed macOS filenames and JSON references to NFC',
      () async {
    final root = await createAuthorProject(
      withDialogue: false,
      withCanonicalPokemon: false,
    );
    addTearDown(() => root.delete(recursive: true));
    const decomposedName = 'poke\u0301mon center.json';
    const composedName = 'pokémon center.json';
    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    (project['maps'] as List<Object?>)[0] = <String, Object?>{
      'id': 'map.start',
      'name': 'Centre Pokémon',
      'relativePath': 'maps/$decomposedName',
    };
    await projectFile.writeAsString(jsonEncode(project), flush: true);
    await File(p.join(root.path, 'maps', 'start.json')).rename(
      p.join(root.path, 'maps', decomposedName),
    );

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(
      result.payloadFiles,
      contains('project/maps/$composedName'),
    );
    expect(
      result.payloadFiles,
      isNot(contains('project/maps/$decomposedName')),
    );
    final projectedProject = jsonDecode(
      utf8.decode(result.payloadFiles['project/project.json']!),
    ) as Map<String, dynamic>;
    expect(
      (projectedProject['maps'] as List<Object?>)
          .cast<Map<String, dynamic>>()
          .single['relativePath'],
      'maps/$composedName',
    );
  });

  test('removes author-time remote asset URLs while keeping local assets',
      () async {
    final root = await createAuthorProject(
      withDialogue: false,
      withCanonicalPokemon: false,
    );
    addTearDown(() => root.delete(recursive: true));
    final catalog = File(p.join(root.path, 'data', 'items.json'));
    await catalog.writeAsString(
      jsonEncode(<String, Object?>{
        'entries': <Object?>[
          <String, Object?>{
            'id': 'potion',
            'spriteUrl': 'https://example.invalid/potion.png',
            'localSpritePath': 'assets/icon.png',
          },
        ],
      }),
      flush: true,
    );

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );
    final projectedCatalog = jsonDecode(
      utf8.decode(result.payloadFiles['project/data/items.json']!),
    ) as Map<String, dynamic>;
    final item = (projectedCatalog['entries'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .single;

    expect(item, isNot(contains('spriteUrl')));
    expect(item['localSpritePath'], 'assets/icon.png');
  });
}

final List<int> _h264Mp4Fixture = <int>[
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

Future<void> _configureCatalogOnlyIntro(
  Directory root, {
  bool corruptVideo = false,
}) async {
  const videoPath = 'assets/presentation/intro.mp4';
  const posterPath = 'assets/presentation/intro-poster.png';
  final projectFile = File(p.join(root.path, 'project.json'));
  final project = jsonDecode(await projectFile.readAsString())
      as Map<String, dynamic>;
  project['presentation'] = <String, Object?>{
    'schemaVersion': 2,
    'branding': <String, Object?>{
      'accentColor': '#123456',
      'layoutVariant': 'cinematic',
    },
    'intro': <String, Object?>{
      'media': <String, Object?>{
        'landscape': <String, Object?>{
          'videoPath': videoPath,
          'posterPath': posterPath,
          'durationMilliseconds': 1000,
          'width': 1280,
          'height': 720,
          'bitrateKbps': 128,
          'sizeBytes': _h264Mp4Fixture.length,
          'videoCodec': 'h264',
          'audioCodec': 'aac',
        },
      },
      'reducedMotionBehavior': 'poster',
      'allowReplay': true,
    },
  };
  await projectFile.writeAsString(jsonEncode(project), flush: true);

  final videoArtifact = ContentArtifactRef.fromBytes(
    _h264Mp4Fixture,
    mediaType: 'video/mp4',
  );
  final posterArtifact = ContentArtifactRef.fromBytes(
    onePixelPng,
    mediaType: 'image/png',
  );
  final catalog = AssetCatalog(
    records: <AssetRecord>[
      AssetRecord(
        id: 'presentation-intro-video',
        logicalPath: videoPath,
        artifact: videoArtifact,
      ),
      AssetRecord(
        id: 'presentation-intro-poster',
        logicalPath: posterPath,
        artifact: posterArtifact,
      ),
    ],
  );
  final catalogFile = File(p.join(root.path, assetCatalogStorageKey));
  await catalogFile.parent.create(recursive: true);
  await catalogFile.writeAsString(jsonEncode(catalog.toJson()), flush: true);

  final videoBytes = List<int>.of(_h264Mp4Fixture);
  if (corruptVideo) videoBytes[0] ^= 0xff;
  final videoBlob = File(p.join(root.path, assetBlobStorageKey(videoArtifact)));
  await videoBlob.parent.create(recursive: true);
  await videoBlob.writeAsBytes(videoBytes, flush: true);
  final posterBlob = File(
    p.join(root.path, assetBlobStorageKey(posterArtifact)),
  );
  await posterBlob.writeAsBytes(onePixelPng, flush: true);
}
