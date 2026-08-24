import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  test('preserves empty projected directories for catalog validation',
      () async {
    final root = await createAuthorProject(withCanonicalPokemon: false);
    addTearDown(() => root.delete(recursive: true));
    final emptyDirectory = Directory(
      p.join(root.path, 'data', 'pokemon', 'empty-catalog'),
    );
    await emptyDirectory.create(recursive: true);

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );
    final reader = RuntimeProjectProjectionFileReader(result);

    expect(
      result.payloadDirectories,
      contains('project/data/pokemon/empty-catalog'),
    );
    expect(
      await reader.listFiles(
        projectRoot: RuntimeProjectProjectionFileReader.projectRoot,
        relativeDirectory: 'data/pokemon/empty-catalog',
      ),
      isEmpty,
    );
  });

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
    final projectedParty =
        ((projectedProject['newGame'] as Map<String, dynamic>)['initialParty']
                as List<Object?>)
            .cast<Map<String, dynamic>>();
    expect(projectedParty.single['formId'], 'partner');

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
  test(
    'packages only the referenced Presentation media closure with its receipt',
    () async {
      final root = await createAuthorProject(
        withDialogue: false,
        withCanonicalPokemon: true,
        projectVersion: ProjectVersion.v7,
      );
      addTearDown(() => root.delete(recursive: true));
      final fixture = await _configurePresentationCinematicMedia(root);

      final result = await const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile(),
      );

      expect(
        result.payloadFiles,
        contains('project/$projectMediaCatalogStorageKey'),
      );
      expect(
        result.payloadFiles,
        contains('presentation/cinematics/publication.json'),
      );
      final packagedMedia = decodeProjectMediaCatalogBytes(
        result.payloadFiles['project/$projectMediaCatalogStorageKey']!,
      );
      expect(packagedMedia.entries.map((entry) => entry.id), <String>[
        'captions.fr',
        'opening.poster',
        'opening.video',
      ]);
      final packagedAssets = AssetCatalog.fromJson(
        jsonDecode(
              utf8.decode(
                result.payloadFiles['project/$assetCatalogStorageKey']!,
              ),
            )
            as Map<String, dynamic>,
      );
      expect(
        packagedAssets.records.map((record) => record.id),
        containsAll(fixture.referencedAssetIds),
      );
      expect(
        packagedAssets.records.map((record) => record.id),
        isNot(contains(fixture.unreferencedAssetId)),
      );
      expect(
        result.payloadFiles.keys,
        containsAll(fixture.referencedBlobPackagePaths),
      );
      expect(
        result.payloadFiles.keys,
        isNot(contains(fixture.unreferencedBlobPackagePath)),
      );
      expect(
        result.payloadFiles.keys,
        isNot(contains(fixture.unreferencedLogicalPackagePath)),
      );
      final publication =
          jsonDecode(
                utf8.decode(
                  result
                      .payloadFiles['presentation/cinematics/publication.json']!,
                ),
              )
              as Map<String, dynamic>;
      expect(publication['canPublish'], isTrue);
      expect(publication['totalPayloadBytes'], fixture.totalPayloadBytes);
      expect(
        (publication['media'] as List<Object?>)
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['id']),
        <String>['captions.fr', 'opening.poster', 'opening.video'],
      );
      expect(
        ((publication['media'] as List<Object?>).last
            as Map<String, dynamic>)['license'],
        containsPair('identifier', 'LicenseRef-Opening'),
      );
      expect(jsonEncode(publication), isNot(contains(root.path)));

      final first = await const GamePackageExportService().build(
        projectRoot: root,
        profile: neutralExportProfile(),
      );
      final second = await const GamePackageExportService().build(
        projectRoot: root,
        profile: neutralExportProfile(),
      );
      expect(first.packageBytes, second.packageBytes);
      expect(
        first.manifest.content.files.map((entry) => entry.path),
        containsAll(<String>[
          'project/$projectMediaCatalogStorageKey',
          'presentation/cinematics/publication.json',
          ...fixture.referencedBlobPackagePaths,
        ]),
      );
      expect(
        first.manifest.content.files.map((entry) => entry.path),
        isNot(contains(fixture.unreferencedBlobPackagePath)),
      );
      expect(
        first.manifest.content.files.map((entry) => entry.path),
        isNot(contains(fixture.unreferencedLogicalPackagePath)),
      );
    },
  );

  test(
    'rejects a Presentation media source missing from the asset catalog',
    () async {
      final root = await createAuthorProject(
        withDialogue: false,
        withCanonicalPokemon: false,
        projectVersion: ProjectVersion.v7,
      );
      addTearDown(() => root.delete(recursive: true));
      await _configurePresentationCinematicMedia(root);
      final catalogFile = File(p.join(root.path, assetCatalogStorageKey));
      final catalog = AssetCatalog.fromJson(
        jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>,
      );
      await catalogFile.writeAsString(
        jsonEncode(
          AssetCatalog(
            records: catalog.records.where(
              (record) => record.id != 'asset.opening.video',
            ),
          ).toJson(),
        ),
        flush: true,
      );

      await expectLater(
        const RuntimeProjectProjectionBuilder().build(
          projectRoot: root,
          profile: neutralExportProfile(),
        ),
        throwsA(
          isA<GamePackageExportException>()
              .having(
                (error) => error.code,
                'code',
                'presentationMediaSourceMissing',
              )
              .having(
                (error) => error.path,
                'path',
                'media[opening.video].sourceAssetId',
              ),
        ),
      );
    },
  );

  test('rejects an altered Presentation media blob before packaging', () async {
    final root = await createAuthorProject(
      withDialogue: false,
      withCanonicalPokemon: false,
      projectVersion: ProjectVersion.v7,
    );
    addTearDown(() => root.delete(recursive: true));
    await _configurePresentationCinematicMedia(root);
    final catalogFile = File(p.join(root.path, assetCatalogStorageKey));
    final catalog = AssetCatalog.fromJson(
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>,
    );
    final video = catalog.require('asset.opening.video');
    final blob = File(p.join(root.path, assetBlobStorageKey(video.artifact)));
    final altered = await blob.readAsBytes();
    altered[0] ^= 0xff;
    await blob.writeAsBytes(altered, flush: true);

    await expectLater(
      const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile(),
      ),
      throwsA(
        isA<GamePackageExportException>()
            .having((error) => error.code, 'code', 'assetBlobIntegrityMismatch')
            .having(
              (error) => error.path,
              'path',
              'assets/presentation/asset.opening.video.bin',
            ),
      ),
    );
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

Future<
  ({
    Set<String> referencedAssetIds,
    String unreferencedAssetId,
    Set<String> referencedBlobPackagePaths,
    String unreferencedBlobPackagePath,
    String unreferencedLogicalPackagePath,
    int totalPayloadBytes,
  })
>
_configurePresentationCinematicMedia(Directory root) async {
  final captionBytes = utf8.encode(
    'WEBVTT\n\n00:00.000 --> 00:01.000\nBienvenue\n',
  );
  final unusedBytes = <int>[...onePixelPng, 0];
  final sources = <String, ({List<int> bytes, String mediaType})>{
    'asset.opening.video': (bytes: _h264Mp4Fixture, mediaType: 'video/mp4'),
    'asset.opening.poster': (bytes: onePixelPng, mediaType: 'image/png'),
    'asset.captions.fr': (bytes: captionBytes, mediaType: 'text/vtt'),
    'asset.unused.image': (bytes: unusedBytes, mediaType: 'image/png'),
  };
  final records = <AssetRecord>[];
  final blobPaths = <String, String>{};
  for (final source in sources.entries) {
    final logicalPath = 'assets/presentation/${source.key}.bin';
    final artifact = ContentArtifactRef.fromBytes(
      source.value.bytes,
      mediaType: source.value.mediaType,
    );
    records.add(
      AssetRecord(
        id: source.key,
        logicalPath: logicalPath,
        artifact: artifact,
      ),
    );
    final logicalFile = File(p.join(root.path, logicalPath));
    await logicalFile.parent.create(recursive: true);
    await logicalFile.writeAsBytes(source.value.bytes, flush: true);
    final storageKey = assetBlobStorageKey(artifact);
    blobPaths[source.key] = 'project/$storageKey';
    final blob = File(p.join(root.path, storageKey));
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(source.value.bytes, flush: true);
  }
  final assetCatalog = AssetCatalog(records: records);
  final assetCatalogFile = File(p.join(root.path, assetCatalogStorageKey));
  await assetCatalogFile.parent.create(recursive: true);
  await assetCatalogFile.writeAsString(
    jsonEncode(assetCatalog.toJson()),
    flush: true,
  );

  final mediaCatalog = ProjectMediaCatalog(
    entries: <ProjectMediaAsset>[
      ProjectMediaAsset(
        id: 'opening.video',
        label: 'Ouverture',
        kind: ProjectMediaKind.video,
        sourceAssetId: 'asset.opening.video',
        posterMediaId: 'opening.poster',
        captions: <ProjectMediaCaption>[
          ProjectMediaCaption(locale: 'fr', mediaId: 'captions.fr'),
        ],
        fallbackMediaId: 'opening.poster',
        provenance: ProjectMediaProvenance(
          source: 'Avelune Studio',
          creator: 'Studio Brume',
        ),
        license: ProjectMediaLicense(
          identifier: 'LicenseRef-Opening',
          name: 'Opening redistribution grant',
          notice: 'Redistribution permitted.',
        ),
        technicalMetadata: ProjectMediaTechnicalMetadata(
          mediaType: 'video/mp4',
          container: 'mp4',
          codec: 'h264',
          audioCodec: 'aac',
          sizeBytes: _h264Mp4Fixture.length,
          width: 1280,
          height: 720,
          durationMilliseconds: 1000,
        ),
      ),
      ProjectMediaAsset(
        id: 'opening.poster',
        label: 'Poster ouverture',
        kind: ProjectMediaKind.poster,
        sourceAssetId: 'asset.opening.poster',
        provenance: ProjectMediaProvenance(source: 'Avelune Studio'),
        license: ProjectMediaLicense(
          identifier: 'LicenseRef-Poster',
          name: 'Poster redistribution grant',
        ),
        technicalMetadata: ProjectMediaTechnicalMetadata(
          mediaType: 'image/png',
          container: 'png',
          codec: 'png',
          sizeBytes: onePixelPng.length,
          width: 1,
          height: 1,
        ),
      ),
      ProjectMediaAsset(
        id: 'captions.fr',
        label: 'Sous-titres français',
        kind: ProjectMediaKind.captions,
        sourceAssetId: 'asset.captions.fr',
        provenance: ProjectMediaProvenance(source: 'Avelune Studio'),
        license: ProjectMediaLicense(
          identifier: 'LicenseRef-Captions',
          name: 'Caption redistribution grant',
        ),
        technicalMetadata: ProjectMediaTechnicalMetadata(
          mediaType: 'text/vtt',
          container: 'vtt',
          codec: 'webvtt',
          sizeBytes: captionBytes.length,
        ),
      ),
      ProjectMediaAsset(
        id: 'unused.image',
        label: 'Média non utilisé',
        kind: ProjectMediaKind.image,
        sourceAssetId: 'asset.unused.image',
        provenance: ProjectMediaProvenance(source: 'Avelune Studio'),
        license: ProjectMediaLicense(
          identifier: 'LicenseRef-Unused',
          name: 'Unused redistribution grant',
        ),
        technicalMetadata: ProjectMediaTechnicalMetadata(
          mediaType: 'image/png',
          container: 'png',
          codec: 'png',
          sizeBytes: unusedBytes.length,
          width: 1,
          height: 1,
        ),
      ),
    ],
  );
  await File(
    p.join(root.path, projectMediaCatalogStorageKey),
  ).writeAsBytes(encodeProjectMediaCatalogBytes(mediaCatalog), flush: true);

  final cinematic = PresentationCinematicAsset(
    id: 'opening',
    title: 'Ouverture',
    durationUs: 2000000,
    layers: <PresentationLayer>[
      PresentationLayer(id: 'background', label: 'Fond', zIndex: 0),
    ],
    tracks: <PresentationTrack>[
      PresentationTrack(
        id: 'visual',
        label: 'Visuel',
        kind: PresentationTrackKind.visual,
        clips: <PresentationClip>[
          PresentationVisualClip(
            id: 'opening-video',
            startUs: 0,
            durationUs: 2000000,
            layerId: 'background',
            resourceId: 'opening.video',
          ),
        ],
      ),
      PresentationTrack(
        id: 'captions',
        label: 'Sous-titres',
        kind: PresentationTrackKind.caption,
        clips: <PresentationClip>[
          PresentationCaptionClip(
            id: 'opening-caption',
            startUs: 0,
            durationUs: 1000000,
            captionId: 'captions.fr',
            locale: 'fr',
          ),
        ],
      ),
    ],
  );
  final projectFile = File(p.join(root.path, 'project.json'));
  final project =
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
  project['presentationCinematics'] = <Object?>[
    encodePresentationCinematicAsset(cinematic),
  ];
  await projectFile.writeAsString(jsonEncode(project), flush: true);

  return (
    referencedAssetIds: <String>{
      'asset.opening.video',
      'asset.opening.poster',
      'asset.captions.fr',
    },
    unreferencedAssetId: 'asset.unused.image',
    referencedBlobPackagePaths: <String>{
      blobPaths['asset.opening.video']!,
      blobPaths['asset.opening.poster']!,
      blobPaths['asset.captions.fr']!,
    },
    unreferencedBlobPackagePath: blobPaths['asset.unused.image']!,
    unreferencedLogicalPackagePath:
        'project/assets/presentation/asset.unused.image.bin',
    totalPayloadBytes:
        _h264Mp4Fixture.length + onePixelPng.length + captionBytes.length,
  );
}
