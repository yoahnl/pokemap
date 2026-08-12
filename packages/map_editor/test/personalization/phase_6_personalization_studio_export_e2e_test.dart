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
      final durableProject = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
      );
      expect(durableProject.presentation, profile);

      final configuredOutput =
          Platform.environment['POKEMAP_PHASE6_PACKAGE_OUTPUT'];
      final packageFile = File(
        configuredOutput ??
            p.join(projectRoot.path, 'build', 'aube.avelunegame'),
      );
      if (configuredOutput != null && await packageFile.exists()) {
        fail('POKEMAP_PHASE6_PACKAGE_OUTPUT must not already exist.');
      }
      late final GamePackageExportArtifact artifact;
      try {
        artifact = await const GamePackageExportService().exportToFile(
          projectRoot: projectRoot,
          profile: neutralExportProfile(
            gameId: 'games.example.phase6-golden',
            title: 'Aube',
            version: '1.0.0',
          ),
          outputFile: packageFile,
        );
      } on GamePackageExportException catch (error) {
        fail('$error\nCause: ${error.cause}');
      }

      expect(await packageFile.exists(), isTrue);
      expect(await packageFile.length(), greaterThan(0));
      expect(artifact.certification.isCertified, isTrue);
      expect(
        artifact.personalizationPreflight.configuredCategories,
        <GamePackagePersonalizationCategory>[
          GamePackagePersonalizationCategory.branding,
          GamePackagePersonalizationCategory.title,
          GamePackagePersonalizationCategory.intro,
          GamePackagePersonalizationCategory.titleMotion,
          GamePackagePersonalizationCategory.typography,
          GamePackagePersonalizationCategory.theme,
          GamePackagePersonalizationCategory.surfacePalettes,
          GamePackagePersonalizationCategory.pause,
          GamePackagePersonalizationCategory.windows,
          GamePackagePersonalizationCategory.layouts,
          GamePackagePersonalizationCategory.dialogue,
          GamePackagePersonalizationCategory.battle,
        ],
      );
      expect(
        artifact.manifest.presentation?.branding.layoutVariant,
        'cinematic',
      );
      expect(artifact.manifest.presentation?.intro?.allowReplay, isTrue);
      expect(
        artifact.manifest.presentation?.pause?.actions
            ?.firstWhere((action) => action.id == 'pokedex')
            .label,
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
      expect(
        artifact.manifest.presentation?.schemaVersion,
        ProjectPresentationProfile.supportedSchemaVersion,
      );
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
      expect(
        artifact.manifest.presentation?.typography?.combat?.fallbackFamilies,
        <String>['monospace'],
      );
      expect(artifact.manifest.presentation?.windows?.battleStyleId, 'battle');
      expect(
        artifact.manifest.presentation?.layouts?.battle?.regular.slot,
        'right',
      );
      expect(
        artifact.manifest.presentation?.dialogue?.placement,
        profile.dialogue?.placement.name,
      );
      expect(
        artifact.manifest.presentation?.battle?.commandLayout,
        profile.battle?.commandLayout.name,
      );
      for (final entry in artifact.manifest.content.files) {
        expect(p.isAbsolute(entry.path), isFalse);
        expect(p.split(entry.path), isNot(contains('..')));
        expect(entry.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      }
      expect(
        artifact.personalizationPreflight.packageSha256,
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
    },
  );
}

Future<ProjectPresentationProfile> _readGoldenPresentation() async {
  final file = File(p.join(_acceptanceFixture.path, 'project.json'));
  final project = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final profile = ProjectPresentationProfile.fromJson(
    Map<String, dynamic>.from(project['presentation'] as Map),
  );
  expect(validateProjectPresentationProfile(profile), isEmpty);
  return profile;
}

Future<void> _writePresentationAssets(Directory projectRoot) async {
  for (final relativePath in _presentationAssetMediaTypes.keys) {
    final target = File(p.join(projectRoot.path, relativePath));
    await target.parent.create(recursive: true);
    await File(p.join(_acceptanceFixture.path, relativePath)).copy(target.path);
  }

  final catalog = AssetCatalog(
    records: <AssetRecord>[
      for (final entry in _presentationAssetMediaTypes.entries)
        await _catalogAsset(
          projectRoot,
          id: entry.value.id,
          logicalPath: entry.key,
          mediaType: entry.value.mediaType,
        ),
    ],
  );
  final catalogFile = File(p.join(projectRoot.path, assetCatalogStorageKey));
  await catalogFile.create(recursive: true);
  await catalogFile.writeAsString(jsonEncode(catalog.toJson()), flush: true);
}

final _acceptanceFixture = Directory(
  p.join(
    Directory.current.path,
    '..',
    '..',
    'examples',
    'playable_runtime_host',
    'golden_personalization_v3',
  ),
);

const _presentationAssetMediaTypes = <String, ({String id, String mediaType})>{
  'assets/presentation/icon.png': (id: 'phase6-icon', mediaType: 'image/png'),
  'assets/presentation/cover.png': (id: 'phase6-cover', mediaType: 'image/png'),
  'assets/presentation/hero.png': (id: 'phase6-hero', mediaType: 'image/png'),
  'assets/presentation/title-loop.mp4': (
    id: 'phase6-title-loop',
    mediaType: 'video/mp4',
  ),
  'assets/presentation/intro/intro.mp4': (
    id: 'phase6-intro-video',
    mediaType: 'video/mp4',
  ),
  'assets/presentation/intro/poster.png': (
    id: 'phase6-intro-poster',
    mediaType: 'image/png',
  ),
  'assets/presentation/intro/captions.vtt': (
    id: 'phase6-intro-captions',
    mediaType: 'text/vtt',
  ),
  'assets/presentation/fonts/display.ttf': (
    id: 'phase6-display-font',
    mediaType: 'font/ttf',
  ),
  'assets/presentation/fonts/display-license.txt': (
    id: 'phase6-display-license',
    mediaType: 'text/plain',
  ),
};

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
