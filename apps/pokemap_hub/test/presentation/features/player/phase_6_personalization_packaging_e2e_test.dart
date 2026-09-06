import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_adapter.dart';
import 'package:pokemap_hub/features/preferences/data/repositories/hub_preferences_repository_impl.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../support/runtime_owned_player_package_fixture.dart';

void main() {
  testWidgets(
    'illustrated menu installs and decodes from verified files with network disabled',
    (tester) async {
      late RuntimePlayerPresentation installedView;
      await tester.runAsync(
        () => HttpOverrides.runZoned(
          () async {
            final source = await _readGoldenPresentation();
            const background = ProjectPauseBackgroundProfile(
              imagePath: 'presentation/menu-background.png',
              focalX: .75,
              sampling: ProjectMenuImageSampling.pixelArt,
            );
            final profile = source.copyWith(
              pause: source.pause!.copyWith(
                style: ProjectPauseMenuStyle.nightIllustrated,
                background: background,
              ),
            );
            final imageBytes =
                await File(
                  '../../examples/playable_runtime_host/golden_personalization_v3/assets/presentation/hero.png',
                ).readAsBytes();
            final built = const GamePackageBuilder().build(
              manifest: _manifest(profile),
              payloadFiles: {
                'project/project.json': utf8.encode(
                  jsonEncode(
                    const ProjectManifest(
                      name: 'Menu offline',
                      maps: [],
                      tilesets: [],
                      pokemon: ProjectPokemonConfig(
                        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
                      ),
                    ).toJson(),
                  ),
                ),
                ..._presentationPayload(),
                background.imagePath: imageBytes,
              },
            );
            final root = await Directory.systemTemp.createTemp(
              'menu-installed-offline-',
            );
            addTearDown(() => root.delete(recursive: true));
            final archive = await File(
              p.join(root.path, 'menu.avelunegame'),
            ).writeAsBytes(built.packageBytes);
            final support = Directory(p.join(root.path, 'installation'));
            final inspector = GamePackageInspector(
              hostCompatibility: _hostCompatibility(),
            );
            final installed = await GamePackageInstaller(
              supportRoot: support,
              inspector: inspector,
              availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
              loadSmoke: (_, _) async {},
              prepareSavesForUpdate:
                  (_, _) async => const SaveUpdatePreparation(),
            ).install(archive, source: GamePackageInstallSource.localFile);
            await archive.delete();
            final launch = await InstalledGameLaunchResolver(
              supportRoot: support,
              hostCompatibility: _hostCompatibility(),
            ).resolve(installed.game);
            final adapter = HubRuntimeStartupAdapter(
              manifest: launch.manifest,
              assets: launch.assets,
            );
            final installedProfile = (await adapter.loadPresentationProfile())!;
            final resolved =
                (await adapter.resolveImage(
                  installedProfile.pause!.background!.imagePath,
                ))!;
            expect(resolved.resolvedUri.scheme, 'file');
            final bytes =
                await File.fromUri(resolved.resolvedUri).readAsBytes();
            expect(bytes, orderedEquals(imageBytes));
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            expect(frame.image.width, 1672);
            expect(frame.image.height, 941);
            frame.image.dispose();
            codec.dispose();
            final view = RuntimePlayerPresentation.fromRuntime(
              RuntimeStartupResolvedPresentation(
                profile: installedProfile,
                menuBackground: resolved.presentationAsset,
              ),
              imageForAsset:
                  (asset) =>
                      asset?.assetId == resolved.assetId
                          ? FileImage(File.fromUri(resolved.resolvedUri))
                          : null,
            );
            expect(
              view.pausePresentation.style,
              ProjectPauseMenuStyle.nightIllustrated,
            );
            expect(view.pausePresentation.background, background);
            expect(view.pausePresentation.backgroundImage, isA<FileImage>());
            expect(installedProfile.pause!.title, profile.pause!.title);
            expect(installedProfile.pause!.actions, profile.pause!.actions);
            installedView = view;
          },
          createHttpClient:
              (_) => throw StateError('Network disabled for menu proof'),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await HttpOverrides.runZoned(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              theme: installedView.applyTo(PokeMapPlayerTheme.dark()),
              home: RuntimePlayerPauseShell.root(
                gameTitle: 'Menu offline',
                actions: {
                  for (final action in PlayerPauseAction.values)
                    action: PlayerActionAvailability.enabled,
                },
                onSelected: (_) {},
                detail: const SizedBox.shrink(),
                presentation: installedView.pausePresentation,
              ),
            ),
          );
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey('runtime-night-illustrated-frame')),
            findsOneWidget,
          );
          final background = find.descendant(
            of: find.byKey(const ValueKey('runtime-menu-background')),
            matching: find.byType(RawImage),
          );
          for (
            var attempt = 0;
            attempt < 20 && tester.widget<RawImage>(background).image == null;
            attempt++
          ) {
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
            });
            await tester.pump();
          }
          expect(tester.widget<RawImage>(background).image, isNotNull);
          expect(
            find.byKey(const ValueKey('runtime-menu-background-unavailable')),
            findsNothing,
          );
          await tester.pumpWidget(const SizedBox.shrink());
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        },
        createHttpClient:
            (_) => throw StateError('Network disabled for installed widget'),
      );
    },
  );

  test(
    'Phase 6 golden package exports, installs, presents, and starts gameplay',
    () async {
      final repositoryRoot = _findRepositoryRoot();
      final evidenceOutputPath =
          Platform.environment['POKEMAP_PHASE7B_EVIDENCE_OUTPUT'];
      final evidencePackagePath =
          Platform.environment['POKEMAP_PHASE7B_PACKAGE_OUTPUT'];
      final evidenceSupportRootPath =
          Platform.environment['POKEMAP_PHASE7B_SUPPORT_ROOT'];
      final studioPackageInputPath =
          Platform.environment['POKEMAP_PHASE6_PACKAGE_INPUT'];
      final evidenceMode =
          evidenceOutputPath != null ||
          evidencePackagePath != null ||
          evidenceSupportRootPath != null;
      if (evidenceMode &&
          (evidenceOutputPath == null ||
              evidencePackagePath == null ||
              evidenceSupportRootPath == null)) {
        fail('All three POKEMAP_PHASE7B evidence paths must be provided.');
      }
      final releaseCandidateCommit =
          evidenceMode
              ? await _requireCleanReleaseCandidate(repositoryRoot)
              : null;
      final root = await Directory.systemTemp.createTemp(
        'phase-6-personalization-e2e-',
      );
      addTearDown(() => root.delete(recursive: true));
      final compatibility = _hostCompatibility();
      final inspector = GamePackageInspector(hostCompatibility: compatibility);
      late final File packageFile;
      if (studioPackageInputPath != null) {
        packageFile = File(studioPackageInputPath);
        if (!await packageFile.exists()) {
          fail('POKEMAP_PHASE6_PACKAGE_INPUT does not exist.');
        }
      } else {
        final profile = await _readGoldenPresentation();
        final payload = <String, List<int>>{
          ...runtimeOwnedPlayerFixturePayload(),
          ..._presentationPayload(),
        };
        final built = const GamePackageBuilder().build(
          manifest: _manifest(profile),
          payloadFiles: payload,
        );
        packageFile = File(
          evidencePackagePath ??
              p.join(root.path, 'golden-personalization.avelunegame'),
        );
        if (evidenceMode && await packageFile.exists()) {
          fail('The Phase 7B package output must not already exist.');
        }
        await packageFile.parent.create(recursive: true);
        await packageFile.writeAsBytes(built.packageBytes, flush: true);
      }
      final inspection = inspector.inspect(await packageFile.readAsBytes());
      final preflight = const GamePackagePersonalizationPreflight().certify(
        inspection,
      );

      var installSmokePassed = false;
      final supportRoot = Directory(
        evidenceSupportRootPath ?? p.join(root.path, 'PokeMap'),
      );
      if (evidenceMode && await supportRoot.exists()) {
        fail('The Phase 7B support root must not already exist.');
      }
      final installed = await GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: inspector,
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, _) async {
          installSmokePassed = true;
        },
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
        now: () => DateTime.utc(2026, 7, 27, 12),
      ).install(packageFile, source: GamePackageInstallSource.localFile);
      final launch = await InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: compatibility,
      ).resolve(installed.game);
      final startupAdapter = HubRuntimeStartupAdapter(
        manifest: launch.manifest,
        assets: launch.assets,
      );
      final runtimeProfile = (await startupAdapter.loadPresentationProfile())!;
      final packagePresentation = launch.manifest.presentation!;
      final iconPath = packagePresentation.branding.icon!;
      final titleMusicPath = packagePresentation.branding.titleMusic;
      final introVariant = packagePresentation.intro!.responsiveMedia.landscape;
      final displayFont = packagePresentation.typography!.display;
      final resolvedAssets = <String, RuntimeResolvedAsset?>{
        iconPath: await startupAdapter.resolveImage(iconPath),
        if (titleMusicPath != null)
          titleMusicPath: await startupAdapter.resolveMedia(titleMusicPath),
        introVariant.video: await startupAdapter.resolveMedia(
          introVariant.video,
        ),
        introVariant.poster: await startupAdapter.resolveImage(
          introVariant.poster,
        ),
        displayFont.font!: await startupAdapter.resolveMedia(displayFont.font!),
      };
      final unavailableAssets = <String>[
        for (final entry in resolvedAssets.entries)
          if (entry.value == null) entry.key,
      ];
      final resolvedPresentation = RuntimeStartupResolvedPresentation(
        metadata: RuntimeStartupPresentationMetadata(
          author: launch.manifest.author.name,
          description: launch.manifest.description,
        ),
        profile: runtimeProfile,
        titleLogo: resolvedAssets[iconPath]?.presentationAsset,
        titleMusic:
            titleMusicPath == null
                ? null
                : resolvedAssets[titleMusicPath]?.presentationAsset,
        introVideo: resolvedAssets[introVariant.video]?.presentationAsset,
        introPoster: resolvedAssets[introVariant.poster]?.presentationAsset,
        typography: _loadedTypography(runtimeProfile.typography!),
      );
      final presentation = RuntimePlayerPresentation.fromRuntime(
        resolvedPresentation,
        imageForAsset: (asset) {
          final resolved =
              asset == null
                  ? null
                  : startupAdapter.resolvedAsset(asset.assetId);
          return resolved == null
              ? null
              : FileImage(File.fromUri(resolved.resolvedUri));
        },
      );

      expect(installSmokePassed, isTrue);
      expect(preflight.packageSha256, inspection.receipt.packageSha256);
      expect(preflight.assetSha256.length, greaterThanOrEqualTo(7));
      expect(
        preflight.assetSha256.keys,
        containsAll(<String>[
          iconPath,
          introVariant.video,
          introVariant.poster,
          displayFont.font!,
          displayFont.license!,
        ]),
      );
      expect(
        presentation.title.layoutVariant,
        PlayerTitleLayoutVariant.cinematic,
      );
      expect(runtimeProfile.intro, isNotNull);
      expect(presentation.typography.displayFamily, 'Aube Display');
      expect(presentation.semanticTheme, isNotNull);
      expect(
        presentation.windowProfile
            ?.resolve(ProjectWindowRole.pauseMenu)
            .cornerRadius,
        24,
      );
      expect(
        presentation.layoutProfile?.pauseMenu.expanded.slot,
        ProjectPresentationLayoutSlot.leftPane,
      );
      expect(
        runtimeProfile.schemaVersion,
        ProjectPresentationProfile.supportedSchemaVersion,
      );
      expect(
        runtimeProfile.pause?.actions
            ?.firstWhere((action) => action.id == ProjectPauseActionId.pokedex)
            .label,
        'Carnet de route',
      );
      expect(presentation.typography.combatFallback, <String>['monospace']);
      expect(
        presentation.windowProfile
            ?.resolve(ProjectWindowRole.battle)
            .cornerRadius,
        12,
      );
      expect(
        presentation.layoutProfile?.battle?.regular.slot,
        ProjectPresentationLayoutSlot.right,
      );
      final acceptanceProfile = await _readGoldenPresentation();
      expect(runtimeProfile.title, acceptanceProfile.title);
      expect(runtimeProfile.surfacePalettes, isNotNull);
      expect(runtimeProfile.dialogue?.shape, ProjectWindowShape.speech);
      expect(
        runtimeProfile.battle?.commandLayout,
        ProjectBattleCommandLayout.radial,
      );
      expect(unavailableAssets, isEmpty);

      final introSequence =
          RuntimeIntroSequenceController()..start(
            hasVideo: true,
            hasPoster: resolvedPresentation.introPoster != null,
            reducedMotion: false,
            reducedMotionBehavior: RuntimeIntroReducedMotionBehavior.poster,
            allowReplay: runtimeProfile.intro!.allowReplay,
          );
      expect(introSequence.phase, RuntimeIntroPhase.playing);
      introSequence.playbackCompleted();
      expect(introSequence.phase, RuntimeIntroPhase.completed);
      final introFinishedCount =
          introSequence.phase == RuntimeIntroPhase.completed ? 1 : 0;

      final preferences = HubPlayerPreferencesGateway(
        store: HubPreferencesStore(supportRoot: supportRoot),
        fallbackLocale: launch.manifest.locales.defaultLocale,
      );
      final descriptor = await HubRuntimeGameSource(
        launch: launch,
        preferencesGateway: preferences,
        sessionIdFactory: () => 'phase-6-session',
        sessionTokenFactory: () => 'phase-6-secret',
      ).createSessionDescriptor(
        launchMode: GameSessionLaunchMode.newGame,
        profileId: 'golden-player',
        slotId: 'slot-1',
        initialGameState: const GameState(
          saveId: 'slot-1',
          currentMapId: 'runtime_harbor',
          trainerProfile: TrainerProfile(name: 'Phase 6 Player'),
        ),
      );
      var mounted = false;
      var unmounted = false;
      final adapter = HubInProcessSessionFactory(
        launch: launch,
        saves: HubSaveStore(
          supportRoot: supportRoot,
          identity: launch.identity,
        ),
        mountGame: (game) async {
          expect(game.gameStateSnapshot.saveId, 'slot-1');
          expect(game.gameStateSnapshot.trainerProfile.name, 'Phase 6 Player');
          mounted = true;
        },
        unmountGame: (_) async {
          unmounted = true;
        },
        now: () => DateTime.utc(2026, 7, 27, 12),
      ).call(descriptor);

      await adapter.prepare(descriptor);
      await adapter.start();
      expect(mounted, isTrue);
      await adapter.stop(GameSessionExitReason.hub);
      await adapter.dispose();
      expect(unmounted, isTrue);

      final installedVideo = await launch.assets.resolveReference(
        launch.assets.reference(introVariant.video),
      );
      await installedVideo.writeAsBytes(<int>[0, 1, 2, 3], flush: true);
      var corruptionRejected = false;
      try {
        await InstalledGameLaunchResolver(
          supportRoot: supportRoot,
          hostCompatibility: compatibility,
        ).resolve(installed.game);
        fail('Corrupt installed media must invalidate the installation.');
      } on InstalledGameLaunchException catch (error) {
        expect(error.code, InstalledGameLaunchErrorCode.installationUnhealthy);
        corruptionRejected = true;
      }

      if (evidenceMode) {
        final presentationFixtureSha256 =
            await sha256.bind(_goldenPresentationFile().openRead()).first;
        final evidence = <String, Object?>{
          'schemaVersion': 1,
          'capturedAtUtc': DateTime.now().toUtc().toIso8601String(),
          'releaseCandidateCommit': releaseCandidateCommit,
          'workingTreeClean': true,
          'dirtyPaths': const <String>[],
          'acceptanceProject': <String, Object?>{
            'relativePath':
                'examples/playable_runtime_host/golden_personalization_v3/'
                'project.json',
            'sha256': presentationFixtureSha256.toString(),
          },
          'package': <String, Object?>{
            'relativePath': p
                .relative(packageFile.path, from: repositoryRoot.path)
                .replaceAll(r'\', '/'),
            'bytes': await packageFile.length(),
            'inspection': inspection.receipt.toJson(),
            'preflight': preflight.toJson(),
          },
          'installation': <String, Object?>{
            ...installed.receipt.toJson(),
            'alreadyInstalled': installed.alreadyInstalled,
            'loadSmokePassed': installSmokePassed,
            'supportRootRelativePath': p
                .relative(supportRoot.path, from: repositoryRoot.path)
                .replaceAll(r'\', '/'),
            'launchHandle': launch.installedVersionHandle,
          },
          'resolvedPresentation': <String, Object?>{
            'titleLayoutVariant': presentation.title.layoutVariant.name,
            'introAvailable': runtimeProfile.intro != null,
            'displayFontFamily': presentation.typography.displayFamily,
            'semanticThemeAvailable': presentation.semanticTheme != null,
            'windowThemeAvailable': presentation.windowProfile != null,
            'layoutThemeAvailable': presentation.layoutProfile != null,
            'unavailableAssets': unavailableAssets,
          },
          'flow': <String, Object?>{
            'introFinishedCount': introFinishedCount,
            'titlePersonalized':
                presentation.title.layoutVariant ==
                PlayerTitleLayoutVariant.cinematic,
            'gameMounted': mounted,
            'gameUnmounted': unmounted,
          },
          'checks': <String, Object?>{
            'preflightPackageHashMatchesInspection':
                preflight.packageSha256 == inspection.receipt.packageSha256,
            'preflightTreeHashMatchesInspection':
                preflight.treeSha256 == inspection.receipt.treeSha256,
            'allV10CategoriesConfigured':
                preflight.configuredCategories.length == 12,
            'installSmokePassed': installSmokePassed,
            'introCompleted': introFinishedCount == 1,
            'titlePersonalized':
                presentation.title.layoutVariant ==
                PlayerTitleLayoutVariant.cinematic,
            'gameStarted': mounted,
            'gameStopped': unmounted,
            'corruptionRejected': corruptionRejected,
          },
          'status': 'passed',
        };
        final evidenceFile = File(evidenceOutputPath!);
        await evidenceFile.parent.create(recursive: true);
        await evidenceFile.writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
          flush: true,
        );
      }
    },
  );
}

Future<ProjectPresentationProfile> _readGoldenPresentation() async {
  final project =
      jsonDecode(await _goldenPresentationFile().readAsString())
          as Map<String, dynamic>;
  final profile = ProjectPresentationProfile.fromJson(
    Map<String, dynamic>.from(project['presentation'] as Map),
  );
  if (validateProjectPresentationProfile(profile).isNotEmpty) {
    throw StateError('The Phase 6 golden presentation must remain valid.');
  }
  return profile;
}

File _goldenPresentationFile() => File(
  p.join(
    Directory.current.path,
    '..',
    '..',
    'examples',
    'playable_runtime_host',
    'golden_personalization_v3',
    'project.json',
  ),
);

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(
      p.join(current.path, 'pokemap_roadmap_mecaniques_fangame.md'),
    ).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Unable to locate the PokeMap repository root.');
    }
    current = parent;
  }
}

Future<String> _requireCleanReleaseCandidate(Directory repositoryRoot) async {
  final status = await Process.run('git', const <String>[
    'status',
    '--porcelain',
    '--untracked-files=all',
  ], workingDirectory: repositoryRoot.path);
  if (status.exitCode != 0 || (status.stdout as String).trim().isNotEmpty) {
    throw StateError('Phase 7B evidence requires a clean candidate worktree.');
  }
  final head = await Process.run('git', const <String>[
    'rev-parse',
    'HEAD',
  ], workingDirectory: repositoryRoot.path);
  if (head.exitCode != 0) {
    throw StateError('Unable to resolve the Phase 7B candidate commit.');
  }
  return (head.stdout as String).trim();
}

GamePackageHostCompatibility _hostCompatibility() =>
    GamePackageHostCompatibility(
      hubVersion: Version(1, 0, 0),
      runtimeApiVersion: Version(1, 0, 0),
      capabilities: const <String>{'map@1'},
      supportedProjectFormats: <String>{ProjectVersion.v6.name},
      currentProjectFormat: ProjectVersion.v6.name,
      supportedSaveFormats: const <int>{1},
    );

Map<String, List<int>> _presentationPayload() => <String, List<int>>{
  'presentation/icon.png': _onePixelPngHeader(),
  'project/assets/title.ogg': ascii.encode('OggS phase-6-title'),
  'presentation/intro/video.mp4': <int>[
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
  'presentation/intro/poster.png': _onePixelPngHeader(),
  'presentation/intro/captions.vtt': utf8.encode(
    'WEBVTT\n\n00:00.000 --> 00:01.000\nAube\n',
  ),
  'presentation/fonts/display.ttf': <int>[0, 1, 0, 0, 0, 0, 0, 0],
  'presentation/fonts/display-license.txt': utf8.encode(
    'Redistribution permitted.',
  ),
};

GamePackageManifest _manifest(ProjectPresentationProfile profile) {
  final intro = profile.intro!;
  final typography = profile.typography!;
  return GamePackageManifest(
    packageFormat: 1,
    gameId: 'games.example.phase6-golden',
    gameVersion: Version(1, 0, 0),
    title: 'Aube',
    description: 'Golden personalization package',
    author: const GamePackageParty(name: 'Studio Brume'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version(1, 0, 0),
      runtimeApiExpression: '>=1.0.0 <2.0.0',
      projectFormat: ProjectVersion.v6.name,
      saveFormat: 1,
      compatibilityId: 'main',
      requiredCapabilities: const <String>['map@1'],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr',
      supported: const <String>['fr', 'en'],
    ),
    presentation: GamePackagePresentation(
      schemaVersion: profile.schemaVersion,
      branding: GamePackageBranding(
        icon: 'presentation/icon.png',
        accentColor: profile.branding.accentColor,
        titleMusic: 'project/assets/title.ogg',
        layoutVariant: profile.branding.layoutVariant,
      ),
      title: _packageTitle(profile.title!),
      intro: GamePackageIntroVideo(
        video: 'presentation/intro/video.mp4',
        poster: 'presentation/intro/poster.png',
        captions: 'presentation/intro/captions.vtt',
        durationMilliseconds: intro.durationMilliseconds,
        width: intro.width,
        height: intro.height,
        bitrateKbps: intro.bitrateKbps,
        sizeBytes: intro.sizeBytes,
        videoCodec: intro.videoCodec,
        audioCodec: intro.audioCodec,
        reducedMotionBehavior: intro.reducedMotionBehavior,
        allowReplay: intro.allowReplay,
      ),
      typography: GamePackageTypography(
        display: GamePackageFontRole(
          font: 'presentation/fonts/display.ttf',
          family: typography.display.family,
          license: 'presentation/fonts/display-license.txt',
          fallbackFamilies: typography.display.fallbackFamilies,
        ),
        body: GamePackageFontRole(
          fallbackFamilies: typography.body.fallbackFamilies,
        ),
        dialogue: GamePackageFontRole(
          fallbackFamilies: typography.dialogue.fallbackFamilies,
        ),
        combat: GamePackageFontRole(
          fallbackFamilies: typography.combat!.fallbackFamilies,
        ),
        numbers: GamePackageFontRole(
          fallbackFamilies: typography.numbers.fallbackFamilies,
        ),
      ),
      theme: _packageTheme(profile.theme!),
      surfacePalettes: _packageSurfacePalettes(profile.surfacePalettes!),
      dialogue: _packageDialogue(profile.dialogue!),
      battle: _packageBattle(profile.battle!),
      pause: _packagePause(profile.pause!),
      windows: _packageWindows(profile.windows!),
      layouts: _packageLayouts(profile.layouts!),
    ),
    content: GamePackageContent(
      fileCount: 0,
      totalBytes: 0,
      treeSha256: '0' * 64,
      files: const <GamePackageFileEntry>[],
    ),
  );
}

GamePackageTitlePresentation _packageTitle(
  ProjectTitlePresentationProfile title,
) => GamePackageTitlePresentation(
  title: title.title,
  subtitle: title.subtitle,
  prompt: title.prompt,
  actions: title.actions
      ?.map(
        (action) => GamePackageTitleAction(
          id: action.id.name,
          label: action.label,
          icon: action.icon?.name,
          visible: action.visible,
        ),
      )
      .toList(growable: false),
);

GamePackagePresentationSurfacePalettes _packageSurfacePalettes(
  ProjectPresentationSurfacePalettesProfile palettes,
) => GamePackagePresentationSurfacePalettes(
  title: _packageSurfacePalette(palettes.title),
  pauseMenu: _packageSurfacePalette(palettes.pauseMenu),
  dialogue: _packageSurfacePalette(palettes.dialogue),
  battle: _packageSurfacePalette(palettes.battle),
);

GamePackageSurfacePalette? _packageSurfacePalette(
  ProjectSurfacePaletteProfile? palette,
) =>
    palette == null
        ? null
        : GamePackageSurfacePalette(
          background: palette.background,
          surface: palette.surface,
          border: palette.border,
          text: palette.text,
          accent: palette.accent,
          selection: palette.selection,
        );

GamePackageDialoguePresentation _packageDialogue(
  ProjectDialoguePresentationProfile profile,
) => GamePackageDialoguePresentation(
  placement: profile.placement.name,
  maxWidthFactor: profile.maxWidthFactor,
  margin: profile.margin,
  contentPadding: profile.contentPadding,
  shape: profile.shape.name,
  cornerRadius: profile.cornerRadius,
  borderWidth: profile.borderWidth,
  fillOpacity: profile.fillOpacity,
  surfaceColor: profile.surfaceColor,
  borderColor: profile.borderColor,
  textColor: profile.textColor,
  portraitSide: profile.portraitSide.name,
  portraitSize: profile.portraitSize,
  portraitShape: profile.portraitShape.name,
  portraitFrameWidth: profile.portraitFrameWidth,
  portraitFrameColor: profile.portraitFrameColor,
  nameplateStyle: profile.nameplateStyle.name,
  nameplateBorderWidth: profile.nameplateBorderWidth,
  nameplateSurfaceColor: profile.nameplateSurfaceColor,
  nameplateBorderColor: profile.nameplateBorderColor,
  nameplateTextColor: profile.nameplateTextColor,
  choiceSpacing: profile.choiceSpacing,
  choiceShape: profile.choiceShape.name,
  choiceDisabledOpacity: profile.choiceDisabledOpacity,
  choiceSelectedColor: profile.choiceSelectedColor,
  progressIndicator: profile.progressIndicator.name,
  progressIndicatorColor: profile.progressIndicatorColor,
  portraitTransition: profile.portraitTransition.name,
  portraitTransitionMilliseconds: profile.portraitTransitionMilliseconds,
);

GamePackageBattlePresentation _packageBattle(
  ProjectBattlePresentationProfile profile,
) => GamePackageBattlePresentation(
  commandLayout: profile.commandLayout.name,
  commandColumns: profile.commandColumns,
  showCommandIcons: profile.showCommandIcons,
  commandShape: profile.commandShape.name,
  commandPadding: profile.commandPadding.round(),
  commandSurfaceColor: profile.commandSurfaceColor,
  commandBorderColor: profile.commandBorderColor,
  commandTextColor: profile.commandTextColor,
  commandSelectionColor: profile.commandSelectionColor,
  commands: profile.commands
      ?.map(
        (command) => GamePackageBattleCommand(
          id: command.id.name,
          label: command.label,
          icon: command.icon?.name,
        ),
      )
      .toList(growable: false),
  hudShape: profile.hudShape.name,
  enemyHudPosition: profile.enemyHudPosition.name,
  playerHudPosition: profile.playerHudPosition.name,
  showOwnerLabel: profile.showOwnerLabel,
  showLevel: profile.showLevel,
  showExactHp: profile.showExactHp,
  hpBarShape: profile.hpBarShape.name,
  hpHealthyColor: profile.hpHealthyColor,
  hpWarningColor: profile.hpWarningColor,
  hpDangerColor: profile.hpDangerColor,
  statusColor: profile.statusColor,
  moves: _packageBattlePanel(profile.moves),
  target: _packageBattlePanel(profile.target),
  message: _packageBattlePanel(profile.message),
);

GamePackageBattlePanelPresentation _packageBattlePanel(
  ProjectBattlePanelPresentationProfile profile,
) => GamePackageBattlePanelPresentation(
  layout: profile.layout.name,
  columns: profile.columns,
  shape: profile.shape.name,
  padding: profile.padding.round(),
  surfaceColor: profile.surfaceColor,
  borderColor: profile.borderColor,
  textColor: profile.textColor,
  selectionColor: profile.selectionColor,
);

GamePackageSemanticTheme _packageTheme(ProjectSemanticThemeProfile theme) =>
    GamePackageSemanticTheme(
      primary: theme.primary,
      onPrimary: theme.onPrimary,
      background: theme.background,
      surface: theme.surface,
      surfaceElevated: theme.surfaceElevated,
      textPrimary: theme.textPrimary,
      textSecondary: theme.textSecondary,
      outline: theme.outline,
      success: theme.success,
      warning: theme.warning,
      danger: theme.danger,
      titleSurface: theme.titleSurface,
      dialogueSurface: theme.dialogueSurface,
      menuSurface: theme.menuSurface,
      overworldHudSurface: theme.overworldHudSurface,
      battleHudSurface: theme.battleHudSurface,
    );

GamePackagePausePresentation _packagePause(
  ProjectPausePresentationProfile pause,
) => GamePackagePausePresentation(
  style: pause.style,
  background: pause.background,
  title: pause.title,
  hint: pause.hint,
  actions: pause.actions?.map(
    (action) => GamePackagePauseAction(
      id: action.id.name,
      label: action.label,
      icon: action.icon?.name,
      visible: action.visible,
    ),
  ),
  composition:
      pause.composition == null
          ? null
          : GamePackageResponsivePauseComposition(
            compactPortrait: _packagePauseVariant(
              pause.composition!.compactPortrait,
            ),
            compactLandscape: _packagePauseVariant(
              pause.composition!.compactLandscape,
            ),
            expanded: _packagePauseVariant(pause.composition!.expanded),
          ),
);

GamePackagePauseCompositionVariant _packagePauseVariant(
  ProjectPauseCompositionVariantProfile variant,
) => GamePackagePauseCompositionVariant(
  entrySize: variant.entrySize.name,
  entrySpacing: variant.entrySpacing.name,
  showTitle: variant.showTitle,
  showHint: variant.showHint,
  showRootDetailPanel: variant.showRootDetailPanel,
);

GamePackagePresentationWindows _packageWindows(
  ProjectPresentationWindowsProfile windows,
) => GamePackagePresentationWindows(
  styles: <GamePackageWindowStyle>[
    for (final style in windows.styles)
      GamePackageWindowStyle(
        id: style.id,
        fillToken: style.fillToken,
        borderToken: style.borderToken,
        borderWidth: style.borderWidth,
        cornerRadius: style.cornerRadius,
        contentPadding: style.contentPadding,
        shadowElevation: style.shadowElevation,
      ),
  ],
  defaultStyleId: windows.defaultStyleId,
  pauseMenuStyleId: windows.pauseMenuStyleId,
  dialogueStyleId: windows.dialogueStyleId,
  battleStyleId: windows.battleStyleId,
  pauseBackdropOpacity: windows.pauseBackdropOpacity,
);

GamePackagePresentationLayouts _packageLayouts(
  ProjectPresentationLayoutsProfile layouts,
) => GamePackagePresentationLayouts(
  title: _packageResponsiveLayout(layouts.title),
  pauseMenu: _packageResponsiveLayout(layouts.pauseMenu),
  dialogue: _packageResponsiveLayout(layouts.dialogue),
  battle:
      layouts.battle == null ? null : _packageResponsiveLayout(layouts.battle!),
);

GamePackageResponsiveSurfaceLayout _packageResponsiveLayout(
  ProjectResponsiveSurfaceLayoutProfile layout,
) => GamePackageResponsiveSurfaceLayout(
  compact: _packageLayoutVariant(layout.compact),
  regular: _packageLayoutVariant(layout.regular),
  expanded: _packageLayoutVariant(layout.expanded),
);

GamePackageSurfaceLayoutVariant _packageLayoutVariant(
  ProjectSurfaceLayoutVariant variant,
) => GamePackageSurfaceLayoutVariant(
  breakpoint: variant.breakpoint.name,
  slot: variant.slot.name,
  width: variant.width.name,
  spacing: variant.spacing.name,
  screenMargin: variant.screenMargin.name,
  visibleSecondaryElements: <String>[
    for (final element in variant.visibleSecondaryElements) element.name,
  ],
);

RuntimeLoadedTypography _loadedTypography(ProjectTypographyProfile source) =>
    RuntimeLoadedTypography(
      roles: <ProjectTypographyRole, RuntimeLoadedFontRole>{
        ProjectTypographyRole.display: RuntimeLoadedFontRole(
          registeredFamily: source.display.family,
          fallbackFamilies: source.display.fallbackFamilies,
        ),
        ProjectTypographyRole.body: RuntimeLoadedFontRole(
          registeredFamily: source.body.family,
          fallbackFamilies: source.body.fallbackFamilies,
        ),
        ProjectTypographyRole.dialogue: RuntimeLoadedFontRole(
          registeredFamily: source.dialogue.family,
          fallbackFamilies: source.dialogue.fallbackFamilies,
        ),
        ProjectTypographyRole.combat: RuntimeLoadedFontRole(
          registeredFamily: source.combat?.family,
          fallbackFamilies:
              source.combat?.fallbackFamilies ?? source.body.fallbackFamilies,
        ),
        ProjectTypographyRole.numbers: RuntimeLoadedFontRole(
          registeredFamily: source.numbers.family,
          fallbackFamilies: source.numbers.fallbackFamilies,
        ),
      },
      unavailableRoles: const <ProjectTypographyRole>[],
    );

List<int> _onePixelPngHeader() {
  final bytes =
      Uint8List(24)
        ..setAll(0, <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
        ..setAll(12, ascii.encode('IHDR'));
  ByteData.sublistView(bytes)
    ..setUint32(16, 1)
    ..setUint32(20, 1);
  return bytes;
}
