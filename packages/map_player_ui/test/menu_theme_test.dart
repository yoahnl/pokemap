import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  Future<PokeMapPlayerMenuTheme> resolve(
    WidgetTester tester, {
    ThemeData? theme,
    MediaQueryData media = const MediaQueryData(),
    bool opaque = false,
  }) async {
    late PokeMapPlayerMenuTheme result;
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? PokeMapPlayerTheme.dark(),
      home: MediaQuery(
        data: media,
        child: PlayerMenuThemeScope(
          opaque: opaque,
          child: Builder(builder: (context) {
            result = context.playerMenuTheme;
            return const SizedBox();
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets(
      'menu preset is scoped and leaves the ambient player theme intact',
      (tester) async {
    final ambient = PokeMapPlayerTheme.light();
    final menu = await resolve(tester, theme: ambient);
    expect(menu.panel, const PokeMapPlayerMenuTheme().panel);
    expect(
        ambient.extension<PokeMapPlayerColors>()!.surface, isNot(menu.panel));
    expect(menu.body.fontFamily, 'packages/map_player_ui/PokeMapSplashDMSans');
    expect(menu.body.fontSize, 18);
    expect(menu.body.height, 26 / 18);
    expect(menu.title.fontSize, 26);
    expect(menu.numbers.fontFeatures,
        contains(const FontFeature.tabularFigures()));
  });

  testWidgets(
      'explicit authored surface palette and typography win over preset',
      (tester) async {
    final source = PokeMapPlayerTheme.withTypography(
      PokeMapPlayerTheme.dark(),
      const PokeMapPlayerTypography(
          bodyFamily: 'Author Body',
          displayFamily: 'Author Display',
          numbersFamily: 'Author Numbers'),
    );
    final palette = const ProjectSurfacePaletteProfile(
        background: '#28221A',
        surface: '#463721',
        border: '#EDC685',
        text: '#FFF2D1',
        accent: '#E2AF64',
        selection: '#483127');
    final theme = source.copyWith(extensions: [
      ...source.extensions.values,
      PokeMapPlayerSurfacePaletteTheme(
          ProjectPresentationSurfacePalettesProfile(pauseMenu: palette)),
    ]);
    final menu = await resolve(tester, theme: theme);
    expect(menu.base,
        PokeMapPlayerProjectColorResolver.tryOpaqueHex(palette.background));
    expect(menu.panel,
        PokeMapPlayerProjectColorResolver.tryOpaqueHex(palette.surface));
    expect(menu.selectionTop,
        PokeMapPlayerProjectColorResolver.tryOpaqueHex(palette.selection));
    expect(menu.selectionBottom, menu.selectionTop);
    expect(menu.body.fontFamily, 'Author Body');
    expect(menu.title.fontFamily, 'Author Display');
    expect(menu.numbers.fontFamily, 'Author Numbers');
    expect(_contrast(menu.selectionText, menu.selectionTop),
        greaterThanOrEqualTo(4.5));
  });

  testWidgets('user accessibility wins over authored palette and motion',
      (tester) async {
    final source = PokeMapPlayerTheme.dark();
    final theme = source.copyWith(extensions: [
      ...source.extensions.values,
      const PokeMapPlayerSurfacePaletteTheme(
          ProjectPresentationSurfacePalettesProfile(
              pauseMenu: ProjectSurfacePaletteProfile(
                  surface: '#FFFF00',
                  text: '#FFFF00',
                  border: '#FFFF00',
                  selection: '#FFFF00'))),
    ]);
    final menu = await resolve(tester,
        theme: theme,
        media:
            const MediaQueryData(highContrast: true, disableAnimations: true));
    expect(menu.opaque, isTrue);
    expect(menu.highContrast, isTrue);
    expect(_contrast(menu.text, menu.panel), greaterThanOrEqualTo(7));
    expect(_contrast(menu.text, menu.header), greaterThanOrEqualTo(7));
    expect(menu.hoverDuration, Duration.zero);
    expect(menu.selectionDuration, Duration.zero);
    expect(menu.openDuration.inMilliseconds, lessThanOrEqualTo(80));
    expect(menu.openTranslation, 0);
  });

  testWidgets(
      'runtime preference motion reduction survives palette application',
      (tester) async {
    final source = PokeMapPlayerTheme.withAccessibility(
        PokeMapPlayerTheme.dark(),
        highContrast: false,
        reducedMotion: true);
    final theme = PokeMapPlayerTheme.withSurfacePalette(
        source, const ProjectSurfacePaletteProfile(surface: '#193040'));
    final menu = await resolve(tester, theme: theme);
    expect(menu.reducedMotion, isTrue);
    expect(menu.pressDuration, Duration.zero);
  });

  testWidgets(
      'normal preset remains readable over composed bright and dark captures',
      (tester) async {
    final menu = await resolve(tester);
    for (final capture in [
      menu.backdropLight,
      menu.backdropContrast,
      menu.backdropPattern
    ]) {
      final veil = Color.alphaBlend(
          menu.backdrop.withValues(alpha: menu.backdropOpacity), capture);
      for (final panel in [menu.panel, menu.base]) {
        final composed =
            Color.alphaBlend(panel.withValues(alpha: menu.panelOpacity), veil);
        expect(_contrast(menu.text, composed), greaterThanOrEqualTo(7));
        expect(_contrast(menu.secondary, composed), greaterThanOrEqualTo(4.5));
        expect(_contrast(menu.disabled, composed), greaterThanOrEqualTo(3));
        expect(_contrast(menu.focus, composed), greaterThanOrEqualTo(3));
      }
    }
    expect(_contrast(menu.selectionText, menu.selectionTop),
        greaterThanOrEqualTo(4.5));
    expect(_contrast(menu.selectionText, menu.selectionBottom),
        greaterThanOrEqualTo(4.5));
  });
  testWidgets(
      'themes and palettes inside the opt-in scope resolve at consumption',
      (tester) async {
    late PokeMapPlayerMenuTheme menu;
    final source = PokeMapPlayerTheme.withAccessibility(
        PokeMapPlayerTheme.dark(),
        highContrast: true,
        reducedMotion: true);
    await tester.pumpWidget(MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      home: PlayerMenuThemeScope(
        child: Theme(
            data: source,
            child: Builder(builder: (context) {
              menu = context.playerMenuTheme;
              return const SizedBox();
            })),
      ),
    ));
    expect(menu.highContrast, isTrue);
    expect(menu.reducedMotion, isTrue);
    final authored = PokeMapPlayerTheme.dark().copyWith(extensions: [
      ...PokeMapPlayerTheme.dark().extensions.values,
      const PokeMapPlayerSurfacePaletteTheme(
          ProjectPresentationSurfacePalettesProfile(
              pauseMenu: ProjectSurfacePaletteProfile(surface: '#543210'))),
    ]);
    await tester.pumpWidget(MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      home: PlayerMenuThemeScope(
        child: Theme(
            data: authored,
            child: PlayerSurfacePaletteScope(
              role: ProjectPresentationSurfaceRole.pauseMenu,
              child: Builder(builder: (context) {
                menu = context.playerMenuTheme;
                return const SizedBox();
              }),
            )),
      ),
    ));
    expect(
        menu.panel, PokeMapPlayerProjectColorResolver.tryOpaqueHex('#543210'));
  });

  testWidgets('metrics-only author settings retain the embedded default family',
      (tester) async {
    final menu = await resolve(tester,
        theme: PokeMapPlayerTheme.withTypography(
          PokeMapPlayerTheme.dark(),
          const PokeMapPlayerTypography(
              bodyMetrics: ProjectTypographyMetricsProfile(sizeScale: 1.2)),
        ));
    expect(menu.body.fontFamily, 'packages/map_player_ui/PokeMapSplashDMSans');
    expect(menu.body.fontSize, closeTo(21.6, .001));
  });
  testWidgets(
      'explicit project semantic theme survives opt-in and local palette projection',
      (tester) async {
    final base = PokeMapPlayerTheme.dark();
    final authored = base.extension<PokeMapPlayerSemanticTheme>()!.copyWith(
          menuSurface:
              PokeMapPlayerProjectColorResolver.tryOpaqueHex('#3F3020'),
          textPrimary:
              PokeMapPlayerProjectColorResolver.tryOpaqueHex('#FFF9DE'),
          primary: PokeMapPlayerProjectColorResolver.tryOpaqueHex('#FFD980'),
          success: PokeMapPlayerProjectColorResolver.tryOpaqueHex('#72DD99'),
        );
    final presentation = RuntimePlayerPresentation(
        title:
            const RuntimePlayerTitlePresentation(author: '', description: ''),
        semanticTheme: authored);
    final projected = presentation.applyTo(base);
    final menu = await resolve(tester, theme: projected);
    expect(menu.panel, authored.menuSurface);
    expect(menu.text, authored.textPrimary);
    expect(menu.accent, authored.primary);
    expect(menu.health, authored.success);
    final withPalette = projected.copyWith(extensions: [
      ...projected.extensions.values,
      const PokeMapPlayerSurfacePaletteTheme(
          ProjectPresentationSurfacePalettesProfile(
              pauseMenu: ProjectSurfacePaletteProfile(surface: '#214333'))),
    ]);
    final local = await resolve(tester,
        theme: PokeMapPlayerTheme.withSurfacePalette(withPalette,
            const ProjectSurfacePaletteProfile(surface: '#214333')));
    expect(
        local.panel, PokeMapPlayerProjectColorResolver.tryOpaqueHex('#214333'));
    expect(local.accent, authored.primary);
    expect(local.health, authored.success);
    final accessible = await resolve(tester,
        theme: PokeMapPlayerTheme.withAccessibility(withPalette,
            highContrast: true, reducedMotion: true));
    expect(accessible.panel, const PokeMapPlayerMenuTheme().shadow);
    expect(accessible.health, accessible.text);
  });

  testWidgets('intermediate authored selection retains AA text contrast',
      (tester) async {
    final base = PokeMapPlayerTheme.dark();
    final theme = base.copyWith(extensions: [
      ...base.extensions.values,
      const PokeMapPlayerSurfacePaletteTheme(
          ProjectPresentationSurfacePalettesProfile(
              pauseMenu: ProjectSurfacePaletteProfile(selection: '#808080'))),
    ]);
    final menu = await resolve(tester, theme: theme);
    expect(_contrast(menu.selectionText, menu.selectionTop),
        greaterThanOrEqualTo(4.5));
    expect(_contrast(menu.selectionText, menu.selectionBottom),
        greaterThanOrEqualTo(4.5));
  });
}

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
}
