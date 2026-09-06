import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('profile preview owns explicit demonstration data', () {
    final preview = PlayerPausePreviewDetailData.demonstrationProfile();
    expect(preview.action, PlayerPauseAction.profile);
    expect(preview.profile?.playerName, 'Camille');
    expect(preview.profile?.playtimeSeconds, 1800);
    expect(preview.entries.single.title, preview.profile?.playerName);
  });

  test('projects quests and profile labels icons and visibility consistently',
      () {
    const labels =
        ProjectMenuLabelsProfile(quests: 'Journal', profile: 'Dresseur');
    final presentation = RuntimePlayerPresentation.fromProfile(
      const ProjectPresentationProfile(menuLabels: labels),
    );
    final l10n = PokeMapPlayerLocalizations.lookup(const Locale('fr'));
    expect(presentation.pauseMenuLabels.quests, 'Journal');
    expect(presentation.pauseMenuLabels.profile, 'Dresseur');
    expect(presentation.pausePresentation.label(PlayerPauseAction.quests, l10n),
        'Journal');
    expect(
        presentation.pausePresentation.label(PlayerPauseAction.profile, l10n),
        'Dresseur');
    expect(presentation.pausePresentation.icon(PlayerPauseAction.profile),
        Icons.person_rounded);
    final hidden = PlayerPausePresentation.fromProfile(
      const ProjectPausePresentationProfile(
          actions: <ProjectPauseActionProfile>[
            ProjectPauseActionProfile(id: ProjectPauseActionId.resume),
            ProjectPauseActionProfile(
                id: ProjectPauseActionId.quests, visible: false),
            ProjectPauseActionProfile(id: ProjectPauseActionId.profile),
          ]),
    );
    expect(hidden.visibleActions, <PlayerPauseAction>[
      PlayerPauseAction.resume,
      PlayerPauseAction.profile
    ]);
  });

  test('V10 acceptance profile has identical runtime view-data', () async {
    final project = ProjectManifest.fromJson(
      jsonDecode(
        await File(
          '../../examples/playable_runtime_host/'
          'golden_personalization_v3/project.json',
        ).readAsString(),
      ) as Map<String, Object?>,
    );
    final profile = project.presentation!;
    final typography = profile.typography!;
    RuntimeLoadedFontRole role(ProjectTypographyRoleProfile source) =>
        RuntimeLoadedFontRole(
          registeredFamily: source.fontPath == null ? null : source.family,
          fallbackFamilies: source.fallbackFamilies,
        );
    final roles = <ProjectTypographyRole, RuntimeLoadedFontRole>{
      ProjectTypographyRole.display: role(typography.display),
      ProjectTypographyRole.body: role(typography.body),
      ProjectTypographyRole.dialogue: role(typography.dialogue),
      ProjectTypographyRole.combat: role(
        typography.combat ?? typography.body,
      ),
      ProjectTypographyRole.numbers: role(typography.numbers),
    };
    final hub = RuntimePlayerPresentation.fromRuntime(
      RuntimeStartupResolvedPresentation(
        metadata: const RuntimeStartupPresentationMetadata(
          author: 'PokeMap',
          description: 'Fixture V10',
        ),
        profile: profile,
        typography: RuntimeLoadedTypography(
          roles: roles,
          unavailableRoles: const <ProjectTypographyRole>[],
        ),
      ),
      imageForAsset: (_) => null,
    );
    final standalone = RuntimePlayerPresentation.fromProfile(
      profile,
      author: 'PokeMap',
      description: 'Fixture V10',
    );

    expect(
      RuntimePlayerPresentationViewData.fromPresentation(hub).value,
      RuntimePlayerPresentationViewData.fromPresentation(standalone).value,
    );
  });

  test('projects V7 title copy with project metadata fallbacks', () {
    final presentation = RuntimePlayerPresentation.fromProfile(
      const ProjectPresentationProfile(
        title: ProjectTitlePresentationProfile(
          title: 'Pokémon Aurore',
          subtitle: '',
          prompt: 'Appuyez pour commencer',
        ),
      ),
      author: 'Studio Brume',
      description: 'Description du projet',
    );

    expect(presentation.title.resolveTitle('Nom du projet'), 'Pokémon Aurore');
    expect(presentation.title.author, isEmpty);
    expect(presentation.title.description, 'Appuyez pour commencer');
    expect(
      RuntimePlayerPresentation.fromProfile(
        const ProjectPresentationProfile(),
        author: 'Studio Brume',
        description: 'Description du projet',
      ).title.resolveTitle('Nom du projet'),
      'Nom du projet',
    );
  });

  test('projects V7 title actions without changing gameplay availability', () {
    final presentation = RuntimePlayerPresentation.fromProfile(
      const ProjectPresentationProfile(
        title: ProjectTitlePresentationProfile(
          actions: <ProjectTitleActionProfile>[
            ProjectTitleActionProfile(
              id: ProjectTitleActionId.newGame,
              label: 'Commencer',
              icon: ProjectTitleActionIcon.sparkles,
            ),
            ProjectTitleActionProfile(
              id: ProjectTitleActionId.continueGame,
              label: 'Reprendre',
              icon: ProjectTitleActionIcon.play,
            ),
            ProjectTitleActionProfile(
              id: ProjectTitleActionId.options,
              visible: false,
            ),
          ],
        ),
      ),
    );
    const disabledContinue = PlayerActionAvailability.disabled(
      'Aucune sauvegarde',
    );

    final actions = presentation.title
        .projectActions(<PlayerTitleMenuAction, PlayerActionAvailability>{
      PlayerTitleMenuAction.continueGame: disabledContinue,
      PlayerTitleMenuAction.newGame: PlayerActionAvailability.enabled,
      PlayerTitleMenuAction.options: PlayerActionAvailability.enabled,
    });

    expect(actions.keys, <PlayerTitleMenuAction>[
      PlayerTitleMenuAction.newGame,
      PlayerTitleMenuAction.continueGame,
    ]);
    expect(actions[PlayerTitleMenuAction.continueGame], disabledContinue);
    expect(
      presentation.title.labelFor(PlayerTitleMenuAction.newGame),
      'Commencer',
    );
    expect(
      presentation.title.iconFor(PlayerTitleMenuAction.newGame),
      ProjectTitleActionIcon.sparkles,
    );
  });

  test('projects every V6 typography metric into measurable text styles', () {
    final presentation = RuntimePlayerPresentation.fromProfile(
      const ProjectPresentationProfile(
        typography: ProjectTypographyProfile(
          display: ProjectTypographyRoleProfile(
            metrics: ProjectTypographyMetricsProfile(
              sizeScale: 1.25,
              weight: 700,
              lineHeight: 1.1,
              letterSpacing: .5,
            ),
          ),
          dialogue: ProjectTypographyRoleProfile(
            metrics: ProjectTypographyMetricsProfile(sizeScale: .9),
          ),
          combat: ProjectTypographyRoleProfile(
            metrics: ProjectTypographyMetricsProfile(sizeScale: 1.1),
          ),
          numbers: ProjectTypographyRoleProfile(
            metrics: ProjectTypographyMetricsProfile(weight: 600),
          ),
        ),
      ),
    );

    final display = presentation.typography.displayStyle(
      const TextStyle(fontSize: 20),
    );
    final dialogue = presentation.typography.dialogueStyle(
      const TextStyle(fontSize: 20),
    );
    final combat = presentation.typography.combatStyle(
      const TextStyle(fontSize: 20),
    );
    final numbers = presentation.typography.numbersStyle(
      const TextStyle(fontSize: 20),
    );

    expect(display.fontSize, 25);
    expect(display.fontWeight, FontWeight.w700);
    expect(display.height, 1.1);
    expect(display.letterSpacing, .5);
    expect(dialogue.fontSize, 18);
    expect(combat.fontSize, 22);
    expect(numbers.fontWeight, FontWeight.w600);
  });

  testWidgets('projects a V6 scene palette into the owned player panel', (
    tester,
  ) async {
    final presentation = RuntimePlayerPresentation.fromProfile(
      const ProjectPresentationProfile(
        surfacePalettes: ProjectPresentationSurfacePalettesProfile(
          title: ProjectSurfacePaletteProfile(
            surface: '#102030',
            border: '#63E6FF',
            text: '#FFFFFF',
            accent: '#63E6FF',
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: presentation.applyTo(PokeMapPlayerTheme.light()),
        home: const Scaffold(
          body: PlayerPanel(
            key: ValueKey<String>('v6-title-panel'),
            surfaceRole: ProjectPresentationSurfaceRole.title,
            child: Text('Titre'),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('v6-title-panel')),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;

    expect(material.color, const Color(0xFF102030));
    expect(shape.side.color, const Color(0xFF63E6FF));
    expect(
      DefaultTextStyle.of(tester.element(find.text('Titre'))).style.color,
      const Color(0xFFFFFFFF),
    );
  });

  testWidgets('scopes background, accent and focus to one player scene', (
    tester,
  ) async {
    final presentation = RuntimePlayerPresentation.fromProfile(
      const ProjectPresentationProfile(
        surfacePalettes: ProjectPresentationSurfacePalettesProfile(
          battle: ProjectSurfacePaletteProfile(
            background: '#081018',
            surface: '#102030',
            border: '#63E6FF',
            text: '#FFFFFF',
            accent: '#63E6FF',
            selection: '#FFD166',
          ),
        ),
      ),
    );
    PokeMapPlayerColors? scopedColors;
    Color? scopedFocus;

    await tester.pumpWidget(
      MaterialApp(
        theme: presentation.applyTo(PokeMapPlayerTheme.light()),
        home: PlayerSurfacePaletteScope(
          role: ProjectPresentationSurfaceRole.battleHud,
          paintBackground: true,
          child: Builder(
            builder: (context) {
              scopedColors = context.playerColors;
              scopedFocus = Theme.of(context).focusColor;
              return const SizedBox.expand(
                key: ValueKey<String>('surface-palette-probe'),
              );
            },
          ),
        ),
      ),
    );

    final background = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.byKey(const ValueKey<String>('surface-palette-probe')),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(background.color, const Color(0xFF081018));
    expect(scopedColors?.surface, const Color(0xFF102030));
    expect(scopedColors?.primary, const Color(0xFF63E6FF));
    expect(scopedColors?.textPrimary, const Color(0xFFFFFFFF));
    expect(scopedColors?.focus, const Color(0xFFFFD166));
    expect(scopedFocus, const Color(0xFFFFD166));
  });

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
        pause: const ProjectPausePresentationProfile(
          title: 'Interlude',
          actions: <ProjectPauseActionProfile>[
            ProjectPauseActionProfile(
              id: ProjectPauseActionId.resume,
              icon: ProjectPauseActionIcon.play,
            ),
            ProjectPauseActionProfile(
              id: ProjectPauseActionId.pokedex,
              label: 'Carnet',
              icon: ProjectPauseActionIcon.book,
            ),
          ],
          composition: ProjectResponsivePauseCompositionProfile(
            expanded: ProjectPauseCompositionVariantProfile(
              entrySize: ProjectPauseEntrySize.large,
            ),
          ),
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
          ProjectTypographyRole.combat: RuntimeLoadedFontRole(
            registeredFamily: 'Aube Combat',
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
    expect(presentation.typography.combatFamily, 'Aube Combat');
    expect(presentation.typography.bodyFamily, isNull);
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
    expect(presentation.pausePresentation.title, 'Interlude');
    expect(
      presentation.pausePresentation.actionLabels[PlayerPauseAction.pokedex],
      'Carnet',
    );
    expect(
      presentation.pausePresentation.composition?.expanded.entrySize,
      ProjectPauseEntrySize.large,
    );
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
    expect(
      presentation.pausePresentation.visibleActions,
      PlayerPauseAction.values,
    );
  });
}
