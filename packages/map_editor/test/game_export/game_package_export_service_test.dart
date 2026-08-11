import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  test(
    'persists stable metadata and rejects deriving identity implicitly',
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
    },
  );

  test('rejects a destination carrying the legacy package suffix', () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final output = File(
      p.join(root.parent.path, 'legacy.pokemapgame.avelunegame'),
    );
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });

    await expectLater(
      const GamePackageExportService().exportToFile(
        projectRoot: root,
        profile: neutralExportProfile(),
        outputFile: output,
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'invalidExportDestination',
        ),
      ),
    );
  });

  test(
    'builds, reopens and writes a deterministic certified package',
    () async {
      final root = await createAuthorProject();
      addTearDown(() => root.delete(recursive: true));
      final projectFile = File(p.join(root.path, 'project.json'));
      final project =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
      project['presentation'] = ProjectPresentationProfile(
        branding: const ProjectBrandingProfile(
          iconPath: 'assets/icon.png',
          accentColor: '#126E78',
        ),
        menuLabels: const ProjectMenuLabelsProfile(pokedex: 'Carnet'),
        typography: const ProjectTypographyProfile(
          combat: ProjectTypographyRoleProfile(
            fallbackFamilies: <String>['monospace'],
          ),
        ),
        windows: legacyProjectPresentationWindows.copyWith(
          battleStyleId: 'default',
        ),
        layouts: suggestedProjectPresentationLayouts('cinematic'),
      ).toJson();
      await projectFile.writeAsString(jsonEncode(project), flush: true);
      const service = GamePackageExportService();
      final profile = neutralExportProfile();

      final first = await service.build(projectRoot: root, profile: profile);
      final second = await service.build(projectRoot: root, profile: profile);

      expect(first.packageBytes, second.packageBytes);
      expect(first.certification.isCertified, isTrue);
      expect(first.certification.gameplayReadinessReport.isPlayable, isTrue);
      expect(first.manifest.gameId, profile.gameId);
      expect(first.manifest.title, profile.title);
      expect(first.manifest.presentation?.schemaVersion, 6);
      expect(first.manifest.usesLegacyBranding, isFalse);
      expect(first.manifest.branding?.icon, 'presentation/icon.png');
      expect(first.manifest.branding?.accentColor, '#126E78');
      expect(first.manifest.presentation?.menuLabels?.pokedex, 'Carnet');
      expect(
        first.manifest.presentation?.windows?.pauseMenuStyleId,
        'pause-menu',
      );
      expect(first.manifest.presentation?.windows?.dialogueStyleId, 'dialogue');
      expect(first.manifest.presentation?.windows?.battleStyleId, 'default');
      expect(first.manifest.presentation?.windows?.pauseBackdropOpacity, .7);
      expect(
        first.manifest.presentation?.layouts?.title.expanded.slot,
        'bottomLeft',
      );
      expect(
        first.manifest.presentation?.layouts?.battle?.expanded.slot,
        'bottomCenter',
      );
      expect(
        first.manifest.presentation?.typography?.combat?.fallbackFamilies,
        <String>['monospace'],
      );
      expect(
        first.manifest.compatibility.requiredCapabilities,
        contains('map@1'),
      );
      expect(
        first.inspection.manifest.content.treeSha256,
        first.manifest.content.treeSha256,
      );
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
        const GamePackageInspector()
            .inspect(await output.readAsBytes())
            .manifest,
        isA<GamePackageManifest>(),
      );
    },
  );

  test('exports a manifest-referenced PokeMap store blob', () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    const storePath =
        'assets/.pokemap-store/'
        '0079d95b54750e42a7b369b8610cd7d87ad4e09edc1c239c8079dc3235a8e5b2.blob';
    final blob = File(p.joinAll(<String>[root.path, ...storePath.split('/')]));
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(onePixelPng, flush: true);

    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    project['tilesets'] = <Object?>[
      const ProjectTilesetEntry(
        id: 'smart-tile-tileset-0079d95b54750e42',
        name: 'Stored smart tileset',
        relativePath: storePath,
      ).toJson(),
    ];
    await projectFile.writeAsString(jsonEncode(project), flush: true);

    final artifact = await const GamePackageExportService().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(artifact.inspection.payloadPaths, contains('project/$storePath'));
  });

  group('gameplay publication readiness gate', () {
    test('rejects a Finish Game reachable only through the non-runtime '
        'starterSelectionSceneId hint', () async {
      final root = await createAuthorProject(withDialogue: false);
      addTearDown(() => root.delete(recursive: true));
      final projectFile = File(p.join(root.path, 'project.json'));
      final project =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
      project.remove('eventRegistry');
      (project['newGame'] as Map<String, dynamic>)['starterSelectionSceneId'] =
          'scene.main';
      await projectFile.writeAsString(jsonEncode(project), flush: true);

      await _expectReadinessFailure(
        root,
        diagnosticCode: 'exportStoryEndUnreachable',
      );
    });

    test(
      'rejects a new game without an initial party or starter path',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        final projectFile = File(p.join(root.path, 'project.json'));
        final project =
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>;
        final newGame = project['newGame'] as Map<String, dynamic>;
        newGame['initialParty'] = <Object?>[];
        newGame['starterOptions'] = <Object?>[];
        newGame.remove('starterSelectionSceneId');
        await projectFile.writeAsString(jsonEncode(project), flush: true);

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'exportPlayablePartyUnavailable',
        );
      },
    );

    test(
      'rejects an initial party when the Pokemon feature is disabled',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        final projectFile = File(p.join(root.path, 'project.json'));
        final project =
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>;
        (project['pokemon'] as Map<String, dynamic>)['enabled'] = false;
        await projectFile.writeAsString(jsonEncode(project), flush: true);

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'exportPlayablePartyPokemonUnavailable',
        );
      },
    );

    test(
      'rejects an initial party species missing from the projected catalog',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        final projectFile = File(p.join(root.path, 'project.json'));
        final project =
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>;
        final newGame = project['newGame'] as Map<String, dynamic>;
        final party = (newGame['initialParty'] as List<Object?>)
            .cast<Map<String, dynamic>>();
        party.single['speciesId'] = 'species.missing';
        await projectFile.writeAsString(jsonEncode(project), flush: true);

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'runtimeMissingPokemonSpecies',
        );
      },
    );

    test(
      'rejects an initial party when its species catalog is unavailable',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        await Directory(
          p.join(root.path, 'data', 'pokemon', 'species'),
        ).delete(recursive: true);

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'pokemon.species.directory_unreadable',
        );
      },
    );

    test(
      'rejects canonical Pokemon data rejected by PokemonProjectValidator',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        final typesFile = File(
          p.join(root.path, 'data', 'pokemon', 'catalogs', 'types.json'),
        );
        final types =
            jsonDecode(await typesFile.readAsString()) as Map<String, dynamic>;
        types['entries'] = <Object?>[];
        await typesFile.writeAsString(jsonEncode(types), flush: true);

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'pokemon.species.type_missing_in_catalog',
        );
      },
    );

    test('rejects a missing authored reference before packaging', () async {
      final root = await createAuthorProject(withDialogue: false);
      addTearDown(() => root.delete(recursive: true));
      await _replaceFinishPayload(
        root,
        SceneYarnDialoguePayload(dialogueId: 'dialogue.missing').toJson(),
      );

      await _expectReadinessFailure(root, diagnosticCode: 'dialogueRefUnknown');
    });

    test(
      'rejects a projected map whose id differs from the manifest',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        final mapFile = File(p.join(root.path, 'maps', 'start.json'));
        final map =
            jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>;
        map['id'] = 'map.other';
        await mapFile.writeAsString(jsonEncode(map), flush: true);

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'exportMapIdMismatch',
        );
      },
    );

    test(
      'rejects a missing configured player spawn before packaging',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        final projectFile = File(p.join(root.path, 'project.json'));
        final project =
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>;
        (project['newGame'] as Map<String, dynamic>)['startSpawnId'] =
            'spawn.missing';
        await projectFile.writeAsString(jsonEncode(project), flush: true);

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'runtimeNewGameStartSpawnMissing',
        );
      },
    );

    test(
      'rejects a project without a reachable Finish Game consequence',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        await _replaceFinishPayload(
          root,
          SceneActionPayload.consequence(SceneConsequence.healParty()).toJson(),
        );

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'exportStoryEndUnreachable',
        );
      },
    );

    test(
      'rejects an invalid static encounter reference before packaging',
      () async {
        final root = await createAuthorProject(withDialogue: false);
        addTearDown(() => root.delete(recursive: true));
        await _replaceFinishPayload(
          root,
          SceneBattlePayload(
            battleKind: 'static',
            trainerId: 'static.missing',
            battleTemplateId: 'static:static.missing',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ).toJson(),
        );

        await _expectReadinessFailure(
          root,
          diagnosticCode: 'battleTrainerRefUnknown',
        );
      },
    );
  });

  test('packages authored responsive motion, typography and theme contracts '
      'with their assets', () async {
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
    await File(
      p.join(root.path, 'assets', 'intro.mp4'),
    ).writeAsBytes(video, flush: true);
    await File(
      p.join(root.path, 'assets', 'poster.png'),
    ).writeAsBytes(onePixelPng, flush: true);
    await File(p.join(root.path, 'assets', 'captions.vtt')).writeAsString(
      'WEBVTT\n\n00:00.000 --> 00:01.000\nBienvenue\n',
      flush: true,
    );
    await File(
      p.join(root.path, 'assets', 'display.ttf'),
    ).writeAsBytes(<int>[0, 1, 0, 0, 0, 0, 0, 0], flush: true);
    await File(
      p.join(root.path, 'assets', 'display-license.txt'),
    ).writeAsString('Redistribution permitted.', flush: true);
    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    Map<String, Object?> videoVariant({
      required int width,
      required int height,
      required String audioCodec,
    }) => <String, Object?>{
      'videoPath': 'assets/intro.mp4',
      'posterPath': 'assets/poster.png',
      'durationMilliseconds': 1000,
      'width': width,
      'height': height,
      'bitrateKbps': 128,
      'sizeBytes': video.length,
      'videoCodec': 'h264',
      'audioCodec': audioCodec,
    };
    project['presentation'] = <String, Object?>{
      'schemaVersion': 2,
      'branding': <String, Object?>{},
      'intro': <String, Object?>{
        'media': <String, Object?>{
          'landscape': <String, Object?>{
            ...videoVariant(width: 1280, height: 720, audioCodec: 'aac'),
            'captionsPath': 'assets/captions.vtt',
          },
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
      'theme': <String, Object?>{
        'primary': '#003A44',
        'onPrimary': '#FFFFFF',
        'background': '#F4F7FB',
        'surface': '#FFFFFF',
        'surfaceElevated': '#EAF0F8',
        'textPrimary': '#101827',
        'textSecondary': '#526176',
        'outline': '#65758B',
        'success': '#16794B',
        'warning': '#8A5100',
        'danger': '#B4233C',
        'titleSurface': '#D9F4F6',
        'dialogueSurface': '#FFFFFF',
        'menuSurface': '#EAF0F8',
        'overworldHudSurface': '#FFFFFF',
        'battleHudSurface': '#FFFFFF',
      },
    };
    await projectFile.writeAsString(jsonEncode(project), flush: true);

    final artifact = await const GamePackageExportService().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(
      artifact.manifest.presentation?.intro?.video,
      'presentation/intro/landscape/video.mp4',
    );
    expect(
      artifact.inspection.payloadPaths,
      containsAll(<String>[
        'presentation/intro/landscape/video.mp4',
        'presentation/intro/landscape/poster.png',
        'presentation/intro/landscape/captions.vtt',
        'presentation/title/prompt/landscape/video.mp4',
        'presentation/title/prompt/portrait/video.mp4',
        'presentation/title/menu/landscape/video.mp4',
        'presentation/title/menu/portrait/video.mp4',
      ]),
    );
    expect(
      artifact.manifest.presentation?.titleMotion?.promptLoop?.portrait?.video,
      'presentation/title/prompt/portrait/video.mp4',
    );
    expect(
      artifact.manifest.presentation?.titleMotion?.menuLoop?.landscape.video,
      'presentation/title/menu/landscape/video.mp4',
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
    expect(artifact.manifest.presentation?.theme?.titleSurface, '#D9F4F6');
  });

  test(
    'falls back to a verified direct write when macOS denies sibling staging',
    () async {
      final root = await createAuthorProject();
      addTearDown(() => root.delete(recursive: true));
      var atomicWriteAttempted = false;
      final service = GamePackageExportService(
        atomicFileWriter:
            ({
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
        p.join(root.parent.path, 'sandbox-selected.avelunegame'),
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
        const GamePackageInspector()
            .inspect(await output.readAsBytes())
            .manifest,
        isA<GamePackageManifest>(),
      );
      expect(await File('${output.path}.backup').exists(), isFalse);
    },
  );

  test(
    'blocks publication when semantic theme contrast is inaccessible',
    () async {
      final root = await createAuthorProject(withDialogue: false);
      addTearDown(() => root.delete(recursive: true));
      final projectFile = File(p.join(root.path, 'project.json'));
      final project =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
      project['presentation'] = <String, Object?>{
        'schemaVersion': 1,
        'branding': <String, Object?>{},
        'theme': <String, Object?>{
          'primary': '#EEEEEE',
          'onPrimary': '#FFFFFF',
          'background': '#F4F7FB',
          'surface': '#FFFFFF',
          'surfaceElevated': '#EAF0F8',
          'textPrimary': '#101827',
          'textSecondary': '#526176',
          'outline': '#65758B',
          'success': '#16794B',
          'warning': '#8A5100',
          'danger': '#B4233C',
          'titleSurface': '#D9F4F6',
          'dialogueSurface': '#FFFFFF',
          'menuSurface': '#EAF0F8',
          'overworldHudSurface': '#FFFFFF',
          'battleHudSurface': '#FFFFFF',
        },
      };
      await projectFile.writeAsString(jsonEncode(project), flush: true);

      await expectLater(
        const GamePackageExportService().build(
          projectRoot: root,
          profile: neutralExportProfile(),
        ),
        throwsA(
          isA<GamePackageExportException>().having(
            (error) => error.code,
            'code',
            'themeContrastInsufficient',
          ),
        ),
      );
    },
  );

  test(
    'refuses a required capability outside the Phase 0 host contract',
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
    },
  );
}

Future<void> _replaceFinishPayload(
  Directory root,
  Map<String, dynamic> payload,
) async {
  final projectFile = File(p.join(root.path, 'project.json'));
  final project =
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
  final scene = (project['scenes'] as List<Object?>)
      .cast<Map<String, dynamic>>()
      .single;
  final graph = scene['graph'] as Map<String, dynamic>;
  final finishNode = (graph['nodes'] as List<Object?>)
      .cast<Map<String, dynamic>>()
      .singleWhere((node) => node['id'] == 'finish');
  finishNode['kind'] = payload['kind'];
  finishNode['payload'] = payload;
  await projectFile.writeAsString(jsonEncode(project), flush: true);
}

Future<void> _expectReadinessFailure(
  Directory root, {
  required String diagnosticCode,
}) async {
  await expectLater(
    const GamePackageExportService().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    ),
    throwsA(
      isA<GamePackageExportException>()
          .having((error) => error.code, 'code', 'gameplayReadinessFailed')
          .having(
            (error) => error.message,
            'creator diagnostics',
            contains(diagnosticCode),
          ),
    ),
  );
}
