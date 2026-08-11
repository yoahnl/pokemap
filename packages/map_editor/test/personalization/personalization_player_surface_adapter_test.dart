import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_player_surface_adapter.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_title_preview_controls.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('mounts the shared widget for every player scene', (
    tester,
  ) async {
    const expectedTypes = <PersonalizationStudioScene, Type>{
      PersonalizationStudioScene.title: PlayerTitleSurface,
      PersonalizationStudioScene.intro: PlayerIntroVideoSurface,
      PersonalizationStudioScene.pause: PlayerPauseSurface,
      PersonalizationStudioScene.dialogue: PlayerDialogueSurface,
      PersonalizationStudioScene.battle: PlayerBattleSurface,
    };

    for (final entry in expectedTypes.entries) {
      await tester.pumpWidget(_app(_adapter(entry.key)));
      await tester.pump();
      expect(find.byType(entry.value), findsOneWidget, reason: entry.key.name);
      if (entry.key == PersonalizationStudioScene.pause) {
        expect(find.byType(RuntimePlayerPauseShell), findsOneWidget);
      }
    }
  });

  testWidgets('applies the runtime player theme built from the draft', (
    tester,
  ) async {
    const profile = ProjectPresentationProfile(
      theme: ProjectSemanticThemeProfile(
        primary: '#123456',
        onPrimary: '#FFFFFF',
        background: '#08111F',
        surface: '#102033',
        surfaceElevated: '#19304A',
        textPrimary: '#F6F8FA',
        textSecondary: '#AAB8C5',
        outline: '#64748B',
        success: '#22C55E',
        warning: '#F59E0B',
        danger: '#EF4444',
        titleSurface: '#102033',
        dialogueSurface: '#F6F0E4',
        menuSurface: '#102033',
        overworldHudSurface: '#102033',
        battleHudSurface: '#19304A',
      ),
      typography: ProjectTypographyProfile(
        dialogue: ProjectTypographyRoleProfile(family: 'Studio Dialogue'),
        combat: ProjectTypographyRoleProfile(family: 'Studio Combat'),
      ),
    );
    await tester.pumpWidget(
      _app(
        const PersonalizationPlayerSurfaceAdapter(
          profile: profile,
          projectName: 'Aube',
          projectRootPath: '',
          scene: PersonalizationStudioScene.dialogue,
        ),
      ),
    );

    final context = tester.element(find.byType(PlayerDialogueSurface));
    expect(context.playerColors.primary, const Color(0xFF123456));
    expect(context.playerTypography.dialogueFamily, 'Studio Dialogue');

    await tester.pumpWidget(
      _app(
        const PersonalizationPlayerSurfaceAdapter(
          profile: profile,
          projectName: 'Aube',
          projectRootPath: '',
          scene: PersonalizationStudioScene.battle,
        ),
      ),
    );
    final battleContext = tester.element(find.byType(PlayerBattleSurface));
    expect(battleContext.playerTypography.combatFamily, 'Studio Combat');
  });

  testWidgets('labels every runtime surface in the global style collage', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_adapter(PersonalizationStudioScene.globalStyle)),
    );
    await tester.pump();

    for (final scene in <String>[
      'Écran titre',
      'Dialogue',
      'Menu Pause',
      'Combat',
    ]) {
      expect(find.text(scene), findsOneWidget);
    }
    expect(find.byType(PlayerTitleSurface), findsOneWidget);
    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
    expect(find.byType(RuntimePlayerPauseShell), findsOneWidget);
    expect(find.byType(PlayerBattleSurface), findsOneWidget);
  });

  testWidgets(
    'uses the authored prompt and menu loops in their real surfaces',
    (tester) async {
      final root = Directory.systemTemp.createTempSync('title-motion-preview-');
      addTearDown(() => root.deleteSync(recursive: true));
      for (final path in <String>[
        'prompt-landscape.mp4',
        'prompt-portrait.mp4',
        'menu-landscape.mp4',
        'menu-portrait.mp4',
      ]) {
        File('${root.path}/$path').writeAsBytesSync(<int>[0]);
      }
      final sources = <PlayerIntroVideoSource>[];
      final drivers = <_PlaybackDriver>[];
      PlayerIntroPlaybackDriver createDriver(PlayerIntroVideoSource source) {
        sources.add(source);
        final driver = _PlaybackDriver();
        drivers.add(driver);
        return driver;
      }

      const profile = ProjectPresentationProfile(
        titleMotion: ProjectTitleMotionProfile(
          promptLoop: ProjectResponsiveVideoProfile(
            landscape: ProjectVideoVariantProfile(
              videoPath: 'prompt-landscape.mp4',
              posterPath: 'prompt-landscape.png',
              durationMilliseconds: 1000,
              width: 1600,
              height: 900,
              bitrateKbps: 1200,
              sizeBytes: 1,
              videoCodec: 'h264',
            ),
            portrait: ProjectVideoVariantProfile(
              videoPath: 'prompt-portrait.mp4',
              posterPath: 'prompt-portrait.png',
              durationMilliseconds: 1000,
              width: 900,
              height: 1600,
              bitrateKbps: 1200,
              sizeBytes: 1,
              videoCodec: 'h264',
            ),
          ),
          menuLoop: ProjectResponsiveVideoProfile(
            landscape: ProjectVideoVariantProfile(
              videoPath: 'menu-landscape.mp4',
              posterPath: 'menu-landscape.png',
              durationMilliseconds: 1000,
              width: 1600,
              height: 900,
              bitrateKbps: 1200,
              sizeBytes: 1,
              videoCodec: 'h264',
            ),
            portrait: ProjectVideoVariantProfile(
              videoPath: 'menu-portrait.mp4',
              posterPath: 'menu-portrait.png',
              durationMilliseconds: 1000,
              width: 900,
              height: 1600,
              bitrateKbps: 1200,
              sizeBytes: 1,
              videoCodec: 'h264',
            ),
          ),
        ),
        theme: safeProjectSemanticTheme,
      );

      Widget preview(PersonalizationTitlePreviewStage stage, double ratio) =>
          _app(
            PersonalizationPlayerSurfaceAdapter(
              profile: profile,
              projectName: 'Aube',
              projectRootPath: root.path,
              scene: PersonalizationStudioScene.title,
              titleStage: stage,
              aspectRatio: ratio,
              titleMotionDriverFactory: createDriver,
            ),
          );

      await tester.pumpWidget(
        preview(PersonalizationTitlePreviewStage.prompt, 16 / 9),
      );
      await tester.pump();
      expect(find.byType(PlayerTitlePromptSurface), findsOneWidget);
      expect(sources.single.videoUri.path, endsWith('prompt-landscape.mp4'));

      await tester.pumpWidget(
        preview(PersonalizationTitlePreviewStage.menu, 16 / 9),
      );
      await tester.pump();
      expect(find.byType(PlayerTitleSurface), findsOneWidget);
      expect(drivers.first.disposeCalls, 1);
      expect(sources.last.videoUri.path, endsWith('menu-landscape.mp4'));

      await tester.pumpWidget(
        preview(PersonalizationTitlePreviewStage.prompt, 9 / 16),
      );
      await tester.pump();
      expect(sources.last.videoUri.path, endsWith('prompt-portrait.mp4'));

      await tester.pumpWidget(
        _app(_adapter(PersonalizationStudioScene.dialogue)),
      );
      await tester.pump();
      expect(drivers.last.disposeCalls, 1);
    },
  );

  testWidgets('plays the responsive intro with real captions and focal point', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('intro-preview-');
    addTearDown(() => root.deleteSync(recursive: true));
    for (final path in <String>[
      'intro-landscape.mp4',
      'intro-landscape.png',
      'intro-portrait.mp4',
      'intro-portrait.png',
    ]) {
      File('${root.path}/$path').writeAsBytesSync(<int>[0]);
    }
    File(
      '${root.path}/captions.vtt',
    ).writeAsStringSync('WEBVTT\n\n00:00.000 --> 00:02.000\nBienvenue à Aube.');
    final sources = <PlayerIntroVideoSource>[];
    final drivers = <_PlaybackDriver>[];
    PlayerIntroPlaybackDriver createDriver(PlayerIntroVideoSource source) {
      sources.add(source);
      final driver = _PlaybackDriver();
      drivers.add(driver);
      return driver;
    }

    const profile = ProjectPresentationProfile(
      intro: ProjectIntroVideoProfile(
        media: ProjectResponsiveVideoProfile(
          landscape: ProjectVideoVariantProfile(
            videoPath: 'intro-landscape.mp4',
            posterPath: 'intro-landscape.png',
            captionsPath: 'captions.vtt',
            durationMilliseconds: 2000,
            width: 1600,
            height: 900,
            bitrateKbps: 1200,
            sizeBytes: 1,
            videoCodec: 'h264',
            focalX: .25,
            focalY: .75,
          ),
          portrait: ProjectVideoVariantProfile(
            videoPath: 'intro-portrait.mp4',
            posterPath: 'intro-portrait.png',
            captionsPath: 'captions.vtt',
            durationMilliseconds: 2000,
            width: 900,
            height: 1600,
            bitrateKbps: 1200,
            sizeBytes: 1,
            videoCodec: 'h264',
            focalX: .6,
            focalY: .3,
          ),
        ),
      ),
      theme: safeProjectSemanticTheme,
    );

    Widget preview(double ratio) => _app(
      PersonalizationPlayerSurfaceAdapter(
        profile: profile,
        projectName: 'Aube',
        projectRootPath: root.path,
        scene: PersonalizationStudioScene.intro,
        aspectRatio: ratio,
        introDriverFactory: createDriver,
      ),
    );

    await tester.pumpWidget(preview(16 / 9));
    await tester.pump();
    expect(find.byType(PlayerIntroVideoPreview), findsOneWidget);
    expect(sources.single.videoUri.path, endsWith('intro-landscape.mp4'));
    final captions = await tester.runAsync(sources.single.captionsLoader!);
    expect(captions, contains('Bienvenue à Aube.'));
    drivers.single.snapshot.value = const PlayerIntroPlaybackSnapshot(
      isInitialized: true,
      caption: 'Bienvenue à Aube.',
    );
    await tester.pump();
    expect(find.text('Bienvenue à Aube.'), findsOneWidget);
    expect(
      tester.widget<FittedBox>(find.byType(FittedBox)).alignment,
      const Alignment(-.5, .5),
    );

    await tester.pumpWidget(preview(9 / 16));
    await tester.pump();
    expect(drivers.first.disposeCalls, 1);
    expect(sources.last.videoUri.path, endsWith('intro-portrait.mp4'));

    await tester.pumpWidget(
      _app(_adapter(PersonalizationStudioScene.dialogue)),
    );
    await tester.pump();
    expect(drivers.last.disposeCalls, 1);
  });
}

final class _PlaybackDriver implements PlayerIntroPlaybackDriver {
  final snapshot = ValueNotifier<PlayerIntroPlaybackSnapshot>(
    const PlayerIntroPlaybackSnapshot(),
  );
  int disposeCalls = 0;

  @override
  ValueListenable<PlayerIntroPlaybackSnapshot> get snapshots => snapshot;

  @override
  Widget buildVideo() => const ColoredBox(color: Colors.black);

  @override
  Future<void> initialize() async {
    snapshot.value = const PlayerIntroPlaybackSnapshot(isInitialized: true);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    snapshot.dispose();
  }
}

PersonalizationPlayerSurfaceAdapter _adapter(
  PersonalizationStudioScene scene,
) => PersonalizationPlayerSurfaceAdapter(
  profile: const ProjectPresentationProfile(theme: safeProjectSemanticTheme),
  projectName: 'Aube',
  projectRootPath: '',
  scene: scene,
);

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: SizedBox(width: 960, height: 640, child: child)),
);
