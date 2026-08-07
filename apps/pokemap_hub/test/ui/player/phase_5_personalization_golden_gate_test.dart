import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/session/application/services/hub_title_presentation_loader.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('Phase 5 golden fixture reaches installed Hub presentation', () async {
    final profile = await _readGoldenPresentation();
    final root = await Directory.systemTemp.createTemp('phase-5-hub-golden-');
    addTearDown(() => root.delete(recursive: true));
    final files = <String, File>{};
    for (final packagePath in <String>[
      'presentation/icon.png',
      'presentation/hero.png',
      'project/assets/title.ogg',
      'presentation/intro/video.mp4',
      'presentation/intro/poster.png',
      'presentation/intro/captions.vtt',
      'presentation/fonts/display.ttf',
    ]) {
      files[packagePath] =
          await File(p.join(root.path, packagePath.replaceAll('/', '-')))
              .writeAsBytes(<int>[1]);
    }

    final loaded = await HubTitlePresentationLoader(
      manifest: _manifest(profile),
      resolveFile: (path) async => files[path]!,
    ).load();

    expect(loaded.title.layoutVariant, PlayerTitleLayoutVariant.cinematic);
    expect(loaded.title.logo, isA<FileImage>());
    expect(
        loaded.intro?.videoPath, files['presentation/intro/video.mp4']!.path);
    expect(
      loaded.typography?.roles[ProjectTypographyRole.display]?.family,
      'Aube Display',
    );
    expect(loaded.semanticTheme?.titleSurface, const Color(0xFFD9F4F6));
    expect(loaded.unavailableAssets, isEmpty);
  });

  testWidgets(
      'Phase 5 golden tokens drive title, dialogue, menu and both HUD roles',
      (tester) async {
    final profile = await tester.runAsync(_readGoldenPresentation);
    final semantic = _playerTheme(profile!.theme!);
    final theme = PokeMapPlayerTheme.withSemanticTheme(
      PokeMapPlayerTheme.withTypography(
        PokeMapPlayerTheme.light(),
        PokeMapPlayerTypography(
          displayFamily: profile.typography!.display.family,
          displayFallback: profile.typography!.display.fallbackFamilies,
        ),
      ),
      semantic,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _panel('golden-title', PlayerPanelRole.title, 'Aube'),
                _panel(
                  'golden-dialogue',
                  PlayerPanelRole.dialogue,
                  'Bienvenue',
                ),
                _panel('golden-menu', PlayerPanelRole.menu, 'Continuer'),
                _panel(
                  'golden-overworld-hud',
                  PlayerPanelRole.overworldHud,
                  'Action A',
                ),
                _panel(
                  'golden-battle-hud',
                  PlayerPanelRole.battleHud,
                  'PV 20 / 20',
                ),
                const PlayerBadge(
                  label: 'Poison',
                  icon: Icons.warning_amber_rounded,
                  tone: PlayerBadgeTone.danger,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(_materialColor(tester, 'golden-title'), semantic.titleSurface);
    expect(
      _materialColor(tester, 'golden-dialogue'),
      semantic.dialogueSurface,
    );
    expect(_materialColor(tester, 'golden-menu'), semantic.menuSurface);
    expect(
      _materialColor(tester, 'golden-overworld-hud'),
      semantic.overworldHudSurface,
    );
    expect(
      _materialColor(tester, 'golden-battle-hud'),
      semantic.battleHudSurface,
    );
    expect(find.text('Poison'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}

Widget _panel(String key, PlayerPanelRole role, String label) => PlayerPanel(
      key: ValueKey<String>(key),
      role: role,
      child: Text(label),
    );

Color? _materialColor(WidgetTester tester, String key) => tester
    .widget<Material>(
      find.descendant(
        of: find.byKey(ValueKey<String>(key)),
        matching: find.byType(Material),
      ),
    )
    .color;

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
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final profile = ProjectPresentationProfile.fromJson(json);
  if (validateProjectPresentationProfile(profile).isNotEmpty) {
    throw StateError('The Phase 5 golden presentation must remain valid.');
  }
  return profile;
}

PokeMapPlayerSemanticTheme _playerTheme(ProjectSemanticThemeProfile theme) =>
    PokeMapPlayerSemanticTheme.tryFromHex(
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
    )!;

GamePackageManifest _manifest(ProjectPresentationProfile profile) {
  final intro = profile.intro!;
  final typography = profile.typography!;
  return GamePackageManifest(
    packageFormat: 1,
    gameId: 'games.example.phase5-golden',
    gameVersion: Version(1, 0, 0),
    title: 'Aube',
    description: 'Golden personalization slice',
    author: const GamePackageParty(name: 'Studio Brume'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version(0, 1, 0),
      runtimeApiExpression: '>=1.0.0 <2.0.0',
      projectFormat: 'v2',
      saveFormat: 1,
      compatibilityId: 'main',
      requiredCapabilities: const <String>[],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr',
      supported: const <String>['fr'],
    ),
    presentation: GamePackagePresentation(
      branding: GamePackageBranding(
        icon: 'presentation/icon.png',
        hero: 'presentation/hero.png',
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
