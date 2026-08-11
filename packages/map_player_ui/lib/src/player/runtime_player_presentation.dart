import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_theme.dart';
import 'player_pause_menu.dart';
import 'player_title_screen.dart';

typedef RuntimePresentationImageResolver = ImageProvider? Function(
  RuntimeStartupPresentationAsset? asset,
);

typedef ProjectPresentationImageResolver = ImageProvider? Function(
  String assetPath,
);

@immutable
final class RuntimePlayerPresentation {
  const RuntimePlayerPresentation({
    required this.title,
    this.typography = const PokeMapPlayerTypography(),
    this.semanticTheme,
    this.surfacePalettes,
    this.windowProfile,
    this.layoutProfile,
    this.pauseMenuLabels = const PlayerPauseMenuLabels(),
  });

  factory RuntimePlayerPresentation.fromRuntime(
    RuntimeStartupResolvedPresentation source, {
    required RuntimePresentationImageResolver imageForAsset,
  }) {
    final profile = source.profile;
    final titleCopy = profile?.title;
    return RuntimePlayerPresentation(
      title: RuntimePlayerTitlePresentation(
        title: titleCopy?.title,
        author: titleCopy == null
            ? source.metadata.author
            : titleCopy.resolveSubtitle(source.metadata.author) ?? '',
        description: titleCopy == null
            ? source.metadata.description
            : titleCopy.resolvePrompt(source.metadata.description),
        actions: titleCopy?.actions,
        background: imageForAsset(source.titleHero),
        logo: imageForAsset(source.titleLogo),
        accentColor: PokeMapPlayerProjectColorResolver.tryHex(
          profile?.branding.accentColor,
        ),
        layoutVariant: PlayerTitleLayoutVariant.fromManifest(
          profile?.branding.layoutVariant,
        ),
      ),
      typography: _typography(source.typography, profile?.typography),
      semanticTheme: _semanticTheme(profile?.theme),
      surfacePalettes: profile?.surfacePalettes,
      windowProfile: profile?.windows,
      layoutProfile: profile?.layouts,
      pauseMenuLabels: _pauseMenuLabels(profile?.menuLabels),
    );
  }

  factory RuntimePlayerPresentation.fromProfile(
    ProjectPresentationProfile profile, {
    String author = '',
    String? description,
    ProjectPresentationImageResolver? imageForPath,
  }) {
    final branding = profile.branding;
    final titleCopy = profile.title;
    final heroPath = branding.heroPath ?? branding.coverPath;
    return RuntimePlayerPresentation(
      title: RuntimePlayerTitlePresentation(
        title: titleCopy?.title,
        author: titleCopy == null
            ? author
            : titleCopy.resolveSubtitle(author) ?? '',
        description: titleCopy == null
            ? description
            : titleCopy.resolvePrompt(description),
        actions: titleCopy?.actions,
        background: heroPath == null ? null : imageForPath?.call(heroPath),
        logo: branding.iconPath == null
            ? null
            : imageForPath?.call(branding.iconPath!),
        accentColor: PokeMapPlayerProjectColorResolver.tryHex(
          branding.accentColor,
        ),
        layoutVariant: PlayerTitleLayoutVariant.fromManifest(
          branding.layoutVariant,
        ),
      ),
      typography: _typographyFromProfile(profile.typography),
      semanticTheme: _semanticTheme(profile.theme),
      surfacePalettes: profile.surfacePalettes,
      windowProfile: profile.windows,
      layoutProfile: profile.layouts,
      pauseMenuLabels: _pauseMenuLabels(profile.menuLabels),
    );
  }

  final RuntimePlayerTitlePresentation title;
  final PokeMapPlayerTypography typography;
  final PokeMapPlayerSemanticTheme? semanticTheme;
  final ProjectPresentationSurfacePalettesProfile? surfacePalettes;
  final ProjectPresentationWindowsProfile? windowProfile;
  final ProjectPresentationLayoutsProfile? layoutProfile;
  final PlayerPauseMenuLabels pauseMenuLabels;

  ThemeData applyTo(ThemeData theme) {
    var resolved = PokeMapPlayerTheme.withTypography(theme, typography);
    final semantic = semanticTheme;
    if (semantic != null) {
      resolved = PokeMapPlayerTheme.withSemanticTheme(resolved, semantic);
    }
    if (surfacePalettes case final palettes?) {
      resolved = PokeMapPlayerTheme.withSurfacePalettes(resolved, palettes);
    }
    if (windowProfile case final windows?) {
      resolved = PokeMapPlayerTheme.withWindowProfile(resolved, windows);
    }
    if (layoutProfile case final layouts?) {
      resolved = PokeMapPlayerTheme.withLayoutProfile(resolved, layouts);
    }
    return resolved;
  }
}

PokeMapPlayerTypography _typography(
  RuntimeLoadedTypography? source,
  ProjectTypographyProfile? profile,
) {
  RuntimeLoadedFontRole role(
    ProjectTypographyRole role,
    List<String> fallback,
  ) =>
      source?.roles[role] ??
      RuntimeLoadedFontRole(
        registeredFamily: null,
        fallbackFamilies: fallback,
      );

  final display = role(
    ProjectTypographyRole.display,
    const <String>['sans-serif'],
  );
  final body = role(
    ProjectTypographyRole.body,
    const <String>['sans-serif'],
  );
  final dialogue = role(
    ProjectTypographyRole.dialogue,
    const <String>['sans-serif'],
  );
  final combat = source?.roles[ProjectTypographyRole.combat] ?? body;
  final numbers = role(
    ProjectTypographyRole.numbers,
    const <String>['monospace'],
  );
  return PokeMapPlayerTypography(
    displayFamily: display.registeredFamily,
    displayFallback: display.fallbackFamilies,
    bodyFamily: body.registeredFamily,
    bodyFallback: body.fallbackFamilies,
    dialogueFamily: dialogue.registeredFamily,
    dialogueFallback: dialogue.fallbackFamilies,
    combatFamily: combat.registeredFamily,
    combatFallback: combat.fallbackFamilies,
    numbersFamily: numbers.registeredFamily,
    numbersFallback: numbers.fallbackFamilies,
    displayMetrics: profile?.display.metrics,
    bodyMetrics: profile?.body.metrics,
    dialogueMetrics: profile?.dialogue.metrics,
    combatMetrics: profile?.combat?.metrics ?? profile?.body.metrics,
    numbersMetrics: profile?.numbers.metrics,
  );
}

PokeMapPlayerTypography _typographyFromProfile(
  ProjectTypographyProfile? source,
) =>
    PokeMapPlayerTypography(
      displayFamily: source?.display.family,
      displayFallback:
          source?.display.fallbackFamilies ?? const <String>['sans-serif'],
      bodyFamily: source?.body.family,
      bodyFallback:
          source?.body.fallbackFamilies ?? const <String>['sans-serif'],
      dialogueFamily: source?.dialogue.family,
      dialogueFallback:
          source?.dialogue.fallbackFamilies ?? const <String>['sans-serif'],
      combatFamily: source?.combat?.family ?? source?.body.family,
      combatFallback: source?.combat?.fallbackFamilies ??
          source?.body.fallbackFamilies ??
          const <String>['sans-serif'],
      numbersFamily: source?.numbers.family,
      numbersFallback:
          source?.numbers.fallbackFamilies ?? const <String>['monospace'],
      displayMetrics: source?.display.metrics,
      bodyMetrics: source?.body.metrics,
      dialogueMetrics: source?.dialogue.metrics,
      combatMetrics: source?.combat?.metrics ?? source?.body.metrics,
      numbersMetrics: source?.numbers.metrics,
    );

PokeMapPlayerSemanticTheme? _semanticTheme(
  ProjectSemanticThemeProfile? source,
) {
  if (source == null) return null;
  return PokeMapPlayerSemanticTheme.tryFromHex(
    primary: source.primary,
    onPrimary: source.onPrimary,
    background: source.background,
    surface: source.surface,
    surfaceElevated: source.surfaceElevated,
    textPrimary: source.textPrimary,
    textSecondary: source.textSecondary,
    outline: source.outline,
    success: source.success,
    warning: source.warning,
    danger: source.danger,
    titleSurface: source.titleSurface,
    dialogueSurface: source.dialogueSurface,
    menuSurface: source.menuSurface,
    overworldHudSurface: source.overworldHudSurface,
    battleHudSurface: source.battleHudSurface,
  );
}

PlayerPauseMenuLabels _pauseMenuLabels(ProjectMenuLabelsProfile? source) =>
    PlayerPauseMenuLabels(
      pauseTitle: source?.pauseTitle,
      resume: source?.resume,
      party: source?.party,
      bag: source?.bag,
      pokedex: source?.pokedex,
      map: source?.map,
      save: source?.save,
      options: source?.options,
      returnToTitle: source?.returnToTitle,
    );
