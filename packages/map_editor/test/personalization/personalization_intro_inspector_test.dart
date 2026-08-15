import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_intro_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('groups intro media and edits its focal point without paths', (
    tester,
  ) async {
    ProjectIntroVideoProfile? changed;
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: PersonalizationIntroInspector(
            profile: _intro(),
            onImportPressed: () {},
            onChanged: (intro) => changed = intro,
            onRemove: () {},
          ),
        ),
      ),
    );

    expect(find.byType(ProjectIntroVideoEditor), findsOneWidget);
    expect(find.text('Poster de secours'), findsOneWidget);
    expect(find.text('Sous-titres'), findsOneWidget);
    expect(find.textContaining('assets/presentation'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('intro-focal-topRight')),
      findsOneWidget,
    );

    final topRight = find.byKey(const ValueKey<String>('intro-focal-topRight'));
    await tester.ensureVisible(topRight);
    await tester.pumpAndSettle();
    expect(topRight.hitTestable(), findsOneWidget);
    await tester.tap(topRight);

    expect(changed?.media.landscape.focalX, 1);
    expect(changed?.media.landscape.focalY, 0);
    expect(changed?.media.portrait?.focalX, 1);
    expect(changed?.media.portrait?.focalY, 0);
  });

  testWidgets(
    'runtime intro preview exposes captions replay and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final root = Directory.systemTemp.createTempSync('real-intro-preview-');
      addTearDown(() => root.deleteSync(recursive: true));
      for (final path in <String>[
        'assets/presentation/intro/landscape.mp4',
        'assets/presentation/intro/landscape.png',
        'assets/presentation/intro/portrait.mp4',
        'assets/presentation/intro/portrait.png',
      ]) {
        File('${root.path}/$path')
          ..createSync(recursive: true)
          ..writeAsBytesSync(<int>[0]);
      }
      for (final path in <String>[
        'assets/presentation/intro/landscape.vtt',
        'assets/presentation/intro/portrait.vtt',
      ]) {
        File('${root.path}/$path')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            'WEBVTT\n\n00:00.000 --> 00:02.000\nBienvenue à Aube.',
          );
      }
      final drivers = <_PlaybackDriver>[];
      await tester.pumpWidget(
        _app(
          PersonalizationLivePreview(
            profile: ProjectPresentationProfile(intro: _intro()),
            projectName: 'Pokémon Aurore',
            projectRootPath: root.path,
            scene: PersonalizationStudioScene.intro,
            introDriverFactory: (source) {
              final driver = _PlaybackDriver();
              drivers.add(driver);
              return driver;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PlayerIntroVideoPreview), findsOneWidget);
      expect(find.byType(PlayerIntroVideoSurface), findsOneWidget);
      drivers.single.snapshot.value = const PlayerIntroPlaybackSnapshot(
        isInitialized: true,
        caption: 'Bienvenue à Aube.',
      );
      await tester.pump();
      expect(find.text('Bienvenue à Aube.'), findsOneWidget);

      drivers.single.snapshot.value = const PlayerIntroPlaybackSnapshot(
        isInitialized: true,
        isCompleted: true,
      );
      await tester.pump();
      final completedSurface = tester.widget<PlayerIntroVideoSurface>(
        find.byType(PlayerIntroVideoSurface),
      );
      expect(completedSurface.isPoster, isTrue);
      expect(completedSurface.onReplay, isNotNull);
      expect(find.text('Rejouer'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('personalization-preview-secondary-toggle'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey<String>('personalization-preview-reduced-motion'),
        ),
      );
      await tester.pump();

      final surface = tester.widget<PlayerIntroVideoSurface>(
        find.byType(PlayerIntroVideoSurface),
      );
      expect(
        surface.failureMessage,
        'Intro ignorée avec les animations réduites',
      );
    },
  );
}

final class _PlaybackDriver implements PlayerIntroPlaybackDriver {
  final snapshot = ValueNotifier<PlayerIntroPlaybackSnapshot>(
    const PlayerIntroPlaybackSnapshot(),
  );

  @override
  ValueListenable<PlayerIntroPlaybackSnapshot> get snapshots => snapshot;

  @override
  Widget buildVideo() => const ColoredBox(color: Colors.black);

  @override
  Future<void> initialize() async {
    snapshot.value = const PlayerIntroPlaybackSnapshot(isInitialized: true);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> dispose() async => snapshot.dispose();
}

ProjectIntroVideoProfile _intro() => const ProjectIntroVideoProfile(
  media: ProjectResponsiveVideoProfile(
    landscape: ProjectVideoVariantProfile(
      videoPath: 'assets/presentation/intro/landscape.mp4',
      posterPath: 'assets/presentation/intro/landscape.png',
      captionsPath: 'assets/presentation/intro/landscape.vtt',
      durationMilliseconds: 5000,
      width: 1920,
      height: 1080,
      bitrateKbps: 1200,
      sizeBytes: 1024,
      videoCodec: 'h264',
    ),
    portrait: ProjectVideoVariantProfile(
      videoPath: 'assets/presentation/intro/portrait.mp4',
      posterPath: 'assets/presentation/intro/portrait.png',
      captionsPath: 'assets/presentation/intro/portrait.vtt',
      durationMilliseconds: 5000,
      width: 1080,
      height: 1920,
      bitrateKbps: 1200,
      sizeBytes: 1024,
      videoCodec: 'h264',
    ),
  ),
  reducedMotionBehavior: 'skip',
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
