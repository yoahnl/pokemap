import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:path/path.dart' as p;

import '../game_export/game_export_test_fixture.dart';

void main() {
  test(
    'PST-061 saves a Studio profile and exports its installable package',
    () async {
      final projectRoot = await createAuthorProject(
        withDialogue: false,
        name: 'Aube',
      );
      addTearDown(() => projectRoot.delete(recursive: true));
      final profile = await _readGoldenPresentation();
      await _writePresentationAssets(projectRoot);

      final projectFile = File(p.join(projectRoot.path, 'project.json'));
      final projectJson =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
      projectJson['newGame'] = <String, Object?>{
        'enabled': true,
        'startMapId': 'map.start',
        'startSpawnId': 'spawn.start',
        'playerName': 'Joueur',
        'startingMoney': 500,
        'initialBag': <Object?>[],
        'initialParty': <Object?>[
          const PlayerPokemon(
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            currentHp: 20,
          ).toJson(),
        ],
        'initialFacts': <String, Object?>{},
        'starterSelectionSceneId': 'scene.main',
        'starterOptions': <Object?>[],
      };
      await projectFile.writeAsString(jsonEncode(projectJson), flush: true);
      await File(p.join(projectRoot.path, 'maps', 'start.json')).writeAsString(
        jsonEncode(<String, Object?>{
          'id': 'map.start',
          'name': 'Aube',
          'size': <String, Object?>{'width': 5, 'height': 4},
          'version': 'v6',
          'layers': <Object?>[],
          'entities': <Object?>[
            <String, Object?>{
              'id': 'spawn.start',
              'name': 'Départ',
              'kind': 'spawn',
              'pos': <String, Object?>{'x': 1, 'y': 1},
              'blocksMovement': false,
              'spawn': <String, Object?>{
                'role': 'player_start',
                'facing': 'south',
              },
            },
          ],
          'mapMetadata': <String, Object?>{'defaultSpawnId': 'spawn.start'},
        }),
        flush: true,
      );
      final initialProject = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
      );
      final container = ProviderContainer();
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: projectRoot.path,
        project: initialProject,
        workspaceMode: EditorWorkspaceMode.map,
      );

      notifier.selectPersonalizationStudioWorkspace();
      expect(
        notifier.state.workspaceMode,
        EditorWorkspaceMode.personalizationStudio,
      );
      expect(
        await notifier.applyPersonalizationStudioProfile(
          profile,
          label: 'PST-061 golden presentation',
        ),
        isTrue,
      );
      final saved = await notifier.savePersonalizationStudio();
      expect(saved, isTrue, reason: notifier.state.errorMessage);

      final configuredOutput =
          Platform.environment['POKEMAP_PHASE6_PACKAGE_OUTPUT'];
      final packageFile = File(
        configuredOutput ??
            p.join(projectRoot.path, 'build', 'aube.avelunegame'),
      );
      if (configuredOutput != null && await packageFile.exists()) {
        fail('POKEMAP_PHASE6_PACKAGE_OUTPUT must not already exist.');
      }
      final artifact = await const GamePackageExportService().exportToFile(
        projectRoot: projectRoot,
        profile: neutralExportProfile(
          gameId: 'games.example.phase6-golden',
          title: 'Aube',
          version: '1.0.0',
        ),
        outputFile: packageFile,
      );

      expect(await packageFile.exists(), isTrue);
      expect(await packageFile.length(), greaterThan(0));
      expect(artifact.certification.isCertified, isTrue);
      expect(
        artifact.personalizationPreflight.configuredCategories,
        <GamePackagePersonalizationCategory>[
          GamePackagePersonalizationCategory.branding,
          GamePackagePersonalizationCategory.intro,
          GamePackagePersonalizationCategory.titleMotion,
          GamePackagePersonalizationCategory.typography,
          GamePackagePersonalizationCategory.theme,
          GamePackagePersonalizationCategory.menuLabels,
          GamePackagePersonalizationCategory.windows,
          GamePackagePersonalizationCategory.layouts,
        ],
      );
      expect(
        artifact.manifest.presentation?.branding.layoutVariant,
        'cinematic',
      );
      expect(artifact.manifest.presentation?.intro?.allowReplay, isTrue);
      expect(
        artifact.manifest.presentation?.menuLabels?.pokedex,
        'Carnet de route',
      );
      expect(
        artifact.manifest.presentation?.typography?.display.family,
        'Aube Display',
      );
      expect(
        artifact.manifest.presentation?.theme?.titleSurface,
        profile.theme?.titleSurface,
      );
      expect(artifact.manifest.presentation?.schemaVersion, 5);
      expect(
        artifact.manifest.presentation?.windows?.pauseMenuStyleId,
        profile.windows?.pauseMenuStyleId,
      );
      expect(
        artifact.manifest.presentation?.windows?.pauseBackdropOpacity,
        profile.windows?.pauseBackdropOpacity,
      );
      expect(
        artifact.manifest.presentation?.layouts?.title.expanded.slot,
        'bottomLeft',
      );
    },
  );
}

Future<ProjectPresentationProfile> _readGoldenPresentation() async {
  final file = File(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'examples',
      'playable_runtime_host',
      'golden_personalization_slice',
      'presentation.json',
    ),
  );
  final profile = ProjectPresentationProfile.fromJson(
    jsonDecode(await file.readAsString()) as Map<String, dynamic>,
  );
  expect(validateProjectPresentationProfile(profile), isEmpty);
  return profile;
}

Future<void> _writePresentationAssets(Directory projectRoot) async {
  final assets = Directory(p.join(projectRoot.path, 'assets', 'presentation'));
  final intro = Directory(p.join(assets.path, 'intro'));
  final fonts = Directory(p.join(assets.path, 'fonts'));
  await intro.create(recursive: true);
  await fonts.create(recursive: true);
  for (final name in <String>['icon.png', 'cover.png', 'hero.png']) {
    await File(
      p.join(assets.path, name),
    ).writeAsBytes(onePixelPng, flush: true);
  }
  await File(
    p.join(assets.path, 'title.ogg'),
  ).writeAsBytes(utf8.encode('OggS phase-6-title'), flush: true);
  await File(p.join(intro.path, 'intro.mp4')).writeAsBytes(<int>[
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
  ], flush: true);
  await File(
    p.join(intro.path, 'poster.png'),
  ).writeAsBytes(onePixelPng, flush: true);
  await File(p.join(intro.path, 'captions.vtt')).writeAsString(
    'WEBVTT\n\n00:00.000 --> 00:01.000\nBienvenue à Aube.\n',
    flush: true,
  );
  await File(
    p.join(fonts.path, 'display.ttf'),
  ).writeAsBytes(<int>[0, 1, 0, 0, 0, 0, 0, 0], flush: true);
  await File(
    p.join(fonts.path, 'display-license.txt'),
  ).writeAsString('Redistribution permitted.', flush: true);

  final catalog = AssetCatalog(
    records: <AssetRecord>[
      await _catalogAsset(
        projectRoot,
        id: 'phase6-icon',
        logicalPath: 'assets/presentation/icon.png',
        mediaType: 'image/png',
      ),
      await _catalogAsset(
        projectRoot,
        id: 'phase6-cover',
        logicalPath: 'assets/presentation/cover.png',
        mediaType: 'image/png',
      ),
      await _catalogAsset(
        projectRoot,
        id: 'phase6-hero',
        logicalPath: 'assets/presentation/hero.png',
        mediaType: 'image/png',
      ),
      await _catalogAsset(
        projectRoot,
        id: 'phase6-title-music',
        logicalPath: 'assets/presentation/title.ogg',
        mediaType: 'audio/ogg',
      ),
      await _catalogAsset(
        projectRoot,
        id: 'phase6-intro-video',
        logicalPath: 'assets/presentation/intro/intro.mp4',
        mediaType: 'video/mp4',
      ),
      await _catalogAsset(
        projectRoot,
        id: 'phase6-intro-poster',
        logicalPath: 'assets/presentation/intro/poster.png',
        mediaType: 'image/png',
      ),
      await _catalogAsset(
        projectRoot,
        id: 'phase6-intro-captions',
        logicalPath: 'assets/presentation/intro/captions.vtt',
        mediaType: 'text/vtt',
      ),
      await _catalogAsset(
        projectRoot,
        id: 'phase6-display-font',
        logicalPath: 'assets/presentation/fonts/display.ttf',
        mediaType: 'font/ttf',
      ),
      await _catalogAsset(
        projectRoot,
        id: 'phase6-display-license',
        logicalPath: 'assets/presentation/fonts/display-license.txt',
        mediaType: 'text/plain',
      ),
    ],
  );
  final catalogFile = File(p.join(projectRoot.path, assetCatalogStorageKey));
  await catalogFile.create(recursive: true);
  await catalogFile.writeAsString(jsonEncode(catalog.toJson()), flush: true);
}

Future<AssetRecord> _catalogAsset(
  Directory projectRoot, {
  required String id,
  required String logicalPath,
  required String mediaType,
}) async {
  final bytes = await File(p.join(projectRoot.path, logicalPath)).readAsBytes();
  final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: mediaType);
  final blob = File(p.join(projectRoot.path, assetBlobStorageKey(artifact)));
  await blob.create(recursive: true);
  await blob.writeAsBytes(bytes, flush: true);
  return AssetRecord(id: id, logicalPath: logicalPath, artifact: artifact);
}
