import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('projects runtime presentation data into generic player rendering', () {
    const hero = AssetImage('hero.png');
    const logo = AssetImage('logo.png');
    final resolved = RuntimeStartupResolvedPresentation(
      metadata: const RuntimeStartupPresentationMetadata(
        author: 'Studio Brume',
        description: 'Une aventure ferroviaire.',
      ),
      profile: ProjectPresentationProfile(
        branding: const ProjectBrandingProfile(
          accentColor: '#A45F3A',
          layoutVariant: 'cinematic',
        ),
        theme: const ProjectSemanticThemeProfile(
          primary: '#003A44',
          onPrimary: '#FFFFFF',
          background: '#F4F7FB',
          surface: '#FFFFFF',
          surfaceElevated: '#EAF0F8',
          textPrimary: '#101827',
          textSecondary: '#526176',
          outline: '#65758B',
          success: '#16794B',
          warning: '#8A5100',
          danger: '#B4233C',
          titleSurface: '#D9F4F6',
          dialogueSurface: '#FFFFFF',
          menuSurface: '#EAF0F8',
          overworldHudSurface: '#FFFFFF',
          battleHudSurface: '#FFFFFF',
        ),
        menuLabels: const ProjectMenuLabelsProfile(
          pauseTitle: 'Interlude',
          pokedex: 'Carnet',
        ),
        windows: legacyProjectPresentationWindows,
        layouts: suggestedProjectPresentationLayouts('cinematic'),
      ),
      titleHero: const RuntimeStartupPresentationAsset(
        assetId: 'hero',
        mediaType: 'image/png',
      ),
      titleLogo: const RuntimeStartupPresentationAsset(
        assetId: 'logo',
        mediaType: 'image/png',
      ),
      typography: RuntimeLoadedTypography(
        roles: <ProjectTypographyRole, RuntimeLoadedFontRole>{
          ProjectTypographyRole.display: RuntimeLoadedFontRole(
            registeredFamily: 'Aube Display',
            fallbackFamilies: const <String>['serif'],
          ),
          ProjectTypographyRole.body: RuntimeLoadedFontRole(
            registeredFamily: null,
            fallbackFamilies: const <String>['sans-serif'],
          ),
        },
        unavailableRoles: const <ProjectTypographyRole>[],
      ),
    );

    final presentation = RuntimePlayerPresentation.fromRuntime(
      resolved,
      imageForAsset: (asset) => switch (asset?.assetId) {
        'hero' => hero,
        'logo' => logo,
        _ => null,
      },
    );

    expect(presentation.title.author, 'Studio Brume');
    expect(presentation.title.description, 'Une aventure ferroviaire.');
    expect(presentation.title.background, same(hero));
    expect(presentation.title.logo, same(logo));
    expect(presentation.title.accentColor, const Color(0xFFA45F3A));
    expect(
      presentation.title.layoutVariant,
      PlayerTitleLayoutVariant.cinematic,
    );
    expect(presentation.typography.displayFamily, 'Aube Display');
    expect(presentation.typography.displayFallback, <String>['serif']);
    expect(presentation.semanticTheme?.titleSurface, const Color(0xFFD9F4F6));
    expect(
      presentation.windowProfile?.resolve(ProjectWindowRole.pauseMenu),
      legacyProjectPresentationWindows.resolve(ProjectWindowRole.pauseMenu),
    );
    expect(
      presentation
          .applyTo(PokeMapPlayerTheme.light())
          .extension<PokeMapPlayerWindowTheme>()
          ?.profile,
      legacyProjectPresentationWindows,
    );
    expect(
      presentation.layoutProfile?.title.expanded.slot,
      ProjectPresentationLayoutSlot.bottomLeft,
    );
    expect(
      presentation
          .applyTo(PokeMapPlayerTheme.light())
          .extension<PokeMapPlayerLayoutTheme>()
          ?.profile
          .title
          .expanded
          .slot,
      ProjectPresentationLayoutSlot.bottomLeft,
    );
    expect(presentation.pauseMenuLabels.pauseTitle, 'Interlude');
    expect(presentation.pauseMenuLabels.pokedex, 'Carnet');
  });

  test('invalid or absent project presentation uses neutral fallbacks', () {
    final presentation = RuntimePlayerPresentation.fromRuntime(
      const RuntimeStartupResolvedPresentation(
        metadata: RuntimeStartupPresentationMetadata(),
        profile: ProjectPresentationProfile(
          theme: ProjectSemanticThemeProfile(
            primary: 'invalid',
            onPrimary: '#FFFFFF',
            background: '#F4F7FB',
            surface: '#FFFFFF',
            surfaceElevated: '#EAF0F8',
            textPrimary: '#101827',
            textSecondary: '#526176',
            outline: '#65758B',
            success: '#16794B',
            warning: '#8A5100',
            danger: '#B4233C',
            titleSurface: '#D9F4F6',
            dialogueSurface: '#FFFFFF',
            menuSurface: '#EAF0F8',
            overworldHudSurface: '#FFFFFF',
            battleHudSurface: '#FFFFFF',
          ),
        ),
      ),
      imageForAsset: (_) => null,
    );

    expect(presentation.title.author, isEmpty);
    expect(presentation.title.background, isNull);
    expect(presentation.semanticTheme, isNull);
    expect(presentation.windowProfile, isNull);
    expect(presentation.layoutProfile, isNull);
    expect(presentation.typography.displayFamily, isNull);
    expect(presentation.pauseMenuLabels.pauseTitle, isNull);
  });
}
