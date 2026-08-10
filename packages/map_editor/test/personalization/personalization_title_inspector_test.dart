import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_title_inspector.dart';
import 'package:map_editor/src/features/personalization/presentation/project_title_motion_editor.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('offers three guided title compositions', (tester) async {
    ProjectPresentationProfile? changed;
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: PersonalizationTitleInspector(
            profile: const ProjectPresentationProfile(),
            projectName: 'Pokémon Aurore',
            projectRootPath: '',
            onChanged: (profile) => changed = profile,
            onImportImage: (_) {},
            onRemoveImage: (_) {},
            onEditAccent: () {},
            onResetAccent: () {},
            onImportTitleMusic: () {},
            onToggleTitleMusicPreview: () {},
            onRemoveTitleMusic: () {},
            onImportMotion: (_) {},
            onRemoveMotion: (_) {},
          ),
        ),
      ),
    );

    for (final preset in <String>['centered', 'left', 'cinematic']) {
      expect(
        find.byKey(ValueKey<String>('title-preset-$preset')),
        findsOneWidget,
      );
    }
    expect(find.byType(ProjectBrandingEditor), findsOneWidget);
    expect(find.byType(ProjectTitleMotionEditor), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('title-preset-left')));
    expect(changed?.branding.layoutVariant, 'standard');
    expect(
      changed?.layouts?.title.regular.slot,
      ProjectPresentationLayoutSlot.leftPane,
    );
    expect(
      changed?.layouts?.title.expanded.slot,
      ProjectPresentationLayoutSlot.leftPane,
    );
  });

  testWidgets('title preview shows runtime content and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const media = ProjectResponsiveVideoProfile(
      landscape: ProjectVideoVariantProfile(
        videoPath: 'assets/title/menu.mp4',
        posterPath: 'assets/title/menu.png',
        durationMilliseconds: 5000,
        width: 1920,
        height: 1080,
        bitrateKbps: 1200,
        sizeBytes: 1024,
        videoCodec: 'h264',
      ),
    );
    await tester.pumpWidget(
      _app(
        const PersonalizationLivePreview(
          profile: ProjectPresentationProfile(
            titleMotion: ProjectTitleMotionProfile(menuLoop: media),
          ),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.title,
        ),
      ),
    );

    expect(find.byType(PlayerTitleSurface), findsOneWidget);
    expect(find.text('Pokémon Aurore'), findsOneWidget);
    expect(find.text('Créé avec PokeMap'), findsOneWidget);
    expect(find.text('Votre aventure commence ici.'), findsOneWidget);
    expect(
      tester
          .widgetList<PlayerActionButton>(find.byType(PlayerActionButton))
          .map((button) => button.label),
      contains('New game'),
    );
    expect(find.byType(PlayerTitleMotion), findsOneWidget);
    expect(
      tester
          .widget<PlayerTitleMotion>(find.byType(PlayerTitleMotion))
          .reducedMotion,
      isFalse,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-reduced-motion'),
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<PlayerTitleMotion>(find.byType(PlayerTitleMotion))
          .reducedMotion,
      isTrue,
    );
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
