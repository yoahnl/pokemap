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

    final topRight = find.byKey(
      const ValueKey<String>('intro-focal-topRight'),
    );
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
      await tester.pumpWidget(
        _app(
          PersonalizationLivePreview(
            profile: ProjectPresentationProfile(intro: _intro()),
            projectName: 'Pokémon Aurore',
            projectRootPath: '',
            scene: PersonalizationStudioScene.intro,
          ),
        ),
      );

      expect(find.byType(PlayerIntroVideoSurface), findsOneWidget);
      var surface = tester.widget<PlayerIntroVideoSurface>(
        find.byType(PlayerIntroVideoSurface),
      );
      expect(surface.caption, 'Exemple de sous-titre');
      expect(surface.onReplay, isNotNull);
      expect(surface.isPoster, isTrue);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('personalization-preview-reduced-motion'),
        ),
      );
      await tester.pump();

      surface = tester.widget<PlayerIntroVideoSurface>(
        find.byType(PlayerIntroVideoSurface),
      );
      expect(
        surface.failureMessage,
        'Intro ignorée avec les animations réduites',
      );
    },
  );
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
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
