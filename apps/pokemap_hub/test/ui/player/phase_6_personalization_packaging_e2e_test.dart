import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_hub/src/ui/player/hub_title_presentation_loader.dart';
import 'package:pokemap_hub/src/ui/preferences/hub_preferences_store.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../support/runtime_owned_player_package_fixture.dart';

void main() {
  test(
    'Phase 6 golden package exports, installs, presents, and starts gameplay',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'phase-6-personalization-e2e-',
      );
      addTearDown(() => root.delete(recursive: true));
      final profile = await _readGoldenPresentation();
      final payload = <String, List<int>>{
        ...runtimeOwnedPlayerFixturePayload(),
        ..._presentationPayload(),
      };
      final built = const GamePackageBuilder().build(
        manifest: _manifest(profile),
        payloadFiles: payload,
      );
      final compatibility = _hostCompatibility();
      final inspector = GamePackageInspector(
        hostCompatibility: compatibility,
      );
      final inspection = inspector.inspect(built.packageBytes);
      final preflight =
          const GamePackagePersonalizationPreflight().certify(inspection);
      final packageFile = File(
        p.join(root.path, 'golden-personalization.pokemapgame'),
      );
      await packageFile.writeAsBytes(built.packageBytes, flush: true);

      var installSmokePassed = false;
      final supportRoot = Directory(p.join(root.path, 'PokeMap'));
      final installed = await GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: inspector,
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, __) async {
          installSmokePassed = true;
        },
        prepareSavesForUpdate: (_, __) async => const SaveUpdatePreparation(),
        now: () => DateTime.utc(2026, 7, 27, 12),
      ).install(
        packageFile,
        source: GamePackageInstallSource.localFile,
      );
      final launch = await InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: compatibility,
      ).resolve(installed.game);
      final presentation = await HubTitlePresentationLoader(
        manifest: launch.manifest,
        resolveFile: (packagePath) => launch.assets.resolveReference(
          launch.assets.reference(packagePath),
        ),
      ).load();

      expect(installSmokePassed, isTrue);
      expect(preflight.packageSha256, inspection.receipt.packageSha256);
      expect(preflight.assetSha256, hasLength(7));
      expect(
        presentation.title.layoutVariant,
        PlayerTitleLayoutVariant.cinematic,
      );
      expect(presentation.intro, isNotNull);
      expect(
        presentation.typography?.roles[ProjectTypographyRole.display]?.family,
        'Aube Display',
      );
      expect(presentation.semanticTheme, isNotNull);
      expect(presentation.unavailableAssets, isEmpty);

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
      );
      var mounted = false;
      var unmounted = false;
      final adapter = HubInProcessSessionFactory(
        launch: launch,
        saves: HubSaveStore(
          supportRoot: supportRoot,
          identity: launch.identity,
        ),
        mountGame: (_) async {
          mounted = true;
        },
        unmountGame: (_) async {
          unmounted = true;
        },
        saveIdFactory: () => 'phase-6-save',
        now: () => DateTime.utc(2026, 7, 27, 12),
      ).call(descriptor);

      await adapter.prepare(descriptor);
      await adapter.start();
      expect(mounted, isTrue);
      await adapter.stop(GameSessionExitReason.hub);
      await adapter.dispose();
      expect(unmounted, isTrue);

      final installedVideo = await launch.assets.resolveReference(
        launch.assets.reference('presentation/intro/video.mp4'),
      );
      await installedVideo.writeAsBytes(<int>[0, 1, 2, 3], flush: true);
      await expectLater(
        InstalledGameLaunchResolver(
          supportRoot: supportRoot,
          hostCompatibility: compatibility,
        ).resolve(installed.game),
        throwsA(
          isA<InstalledGameLaunchException>().having(
            (error) => error.code,
            'code',
            InstalledGameLaunchErrorCode.installationUnhealthy,
          ),
        ),
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
  if (validateProjectPresentationProfile(profile).isNotEmpty) {
    throw StateError('The Phase 6 golden presentation must remain valid.');
  }
  return profile;
}

GamePackageHostCompatibility _hostCompatibility() =>
    GamePackageHostCompatibility(
      hubVersion: Version(1, 0, 0),
      runtimeApiVersion: Version(1, 0, 0),
      capabilities: const <String>{'map@1'},
      supportedProjectFormats: const <String>{'v1'},
      currentProjectFormat: 'v1',
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
      'presentation/intro/captions.vtt':
          utf8.encode('WEBVTT\n\n00:00.000 --> 00:01.000\nAube\n'),
      'presentation/fonts/display.ttf': <int>[0, 1, 0, 0, 0, 0, 0, 0],
      'presentation/fonts/display-license.txt':
          utf8.encode('Redistribution permitted.'),
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
      projectFormat: 'v1',
      saveFormat: 1,
      compatibilityId: 'main',
      requiredCapabilities: const <String>['map@1'],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr',
      supported: const <String>['fr', 'en'],
    ),
    presentation: GamePackagePresentation(
      branding: GamePackageBranding(
        icon: 'presentation/icon.png',
        accentColor: profile.branding.accentColor,
        titleMusic: 'project/assets/title.ogg',
        layoutVariant: profile.branding.layoutVariant,
      ),
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
        numbers: GamePackageFontRole(
          fallbackFamilies: typography.numbers.fallbackFamilies,
        ),
      ),
      theme: _packageTheme(profile.theme!),
    ),
    content: GamePackageContent(
      fileCount: 0,
      totalBytes: 0,
      treeSha256: '0' * 64,
      files: const <GamePackageFileEntry>[],
    ),
  );
}

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

List<int> _onePixelPngHeader() {
  final bytes = Uint8List(24)
    ..setAll(
      0,
      <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
    )
    ..setAll(12, ascii.encode('IHDR'));
  ByteData.sublistView(bytes)
    ..setUint32(16, 1)
    ..setUint32(20, 1);
  return bytes;
}
