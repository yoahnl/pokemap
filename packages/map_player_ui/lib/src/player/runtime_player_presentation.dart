import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_theme.dart';
import 'player_pause_menu.dart';
import 'player_title_screen.dart';

typedef RuntimePresentationImageResolver = ImageProvider? Function(
    RuntimeStartupPresentationAsset? asset);

typedef ProjectPresentationImageResolver = ImageProvider? Function(
    String assetPath);

@immutable
final class RuntimePlayerPresentation {
  const RuntimePlayerPresentation({
    required this.title,
    this.typography = const PokeMapPlayerTypography(),
    this.semanticTheme,
    this.surfacePalettes,
    this.windowProfile,
    this.layoutProfile,
    this.dialogueProfile,
    this.battleProfile,
    this.pauseMenuLabels = const PlayerPauseMenuLabels(),
    this.pausePresentation = const PlayerPausePresentation(),
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
      dialogueProfile: profile?.dialogue,
      battleProfile: profile?.battle,
      pauseMenuLabels: _pauseMenuLabels(profile?.menuLabels),
      pausePresentation: PlayerPausePresentation.fromProfile(
        profile?.effectivePause,
      ),
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
      dialogueProfile: profile.dialogue,
      battleProfile: profile.battle,
      pauseMenuLabels: _pauseMenuLabels(profile.menuLabels),
      pausePresentation: PlayerPausePresentation.fromProfile(
        profile.effectivePause,
      ),
    );
  }

  final RuntimePlayerTitlePresentation title;
  final PokeMapPlayerTypography typography;
  final PokeMapPlayerSemanticTheme? semanticTheme;
  final ProjectPresentationSurfacePalettesProfile? surfacePalettes;
  final ProjectPresentationWindowsProfile? windowProfile;
  final ProjectPresentationLayoutsProfile? layoutProfile;
  final ProjectDialoguePresentationProfile? dialogueProfile;
  final ProjectBattlePresentationProfile? battleProfile;
  final PlayerPauseMenuLabels pauseMenuLabels;
  final PlayerPausePresentation pausePresentation;

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
    if (dialogueProfile case final dialogue?) {
      resolved = PokeMapPlayerTheme.withDialogueProfile(resolved, dialogue);
    }
    if (battleProfile case final battle?) {
      resolved = PokeMapPlayerTheme.withBattleProfile(resolved, battle);
    }
    return resolved;
  }
}

@immutable
final class RuntimePlayerPresentationViewData {
  RuntimePlayerPresentationViewData._(Map<String, Object?> value)
      : value = Map<String, Object?>.unmodifiable(value);

  factory RuntimePlayerPresentationViewData.fromPresentation(
    RuntimePlayerPresentation presentation,
  ) =>
      RuntimePlayerPresentationViewData._(<String, Object?>{
        'title': <String, Object?>{
          'title': presentation.title.title,
          'author': presentation.title.author,
          'description': presentation.title.description,
          'actions': presentation.title.actions
              ?.map((action) => action.toJson())
              .toList(growable: false),
          'accentColor': presentation.title.accentColor?.toARGB32(),
          'layoutVariant': presentation.title.layoutVariant.name,
        },
        'typography': <String, Object?>{
          'displayFamily': presentation.typography.displayFamily,
          'displayFallback': presentation.typography.displayFallback,
          'bodyFamily': presentation.typography.bodyFamily,
          'bodyFallback': presentation.typography.bodyFallback,
          'dialogueFamily': presentation.typography.dialogueFamily,
          'dialogueFallback': presentation.typography.dialogueFallback,
          'combatFamily': presentation.typography.combatFamily,
          'combatFallback': presentation.typography.combatFallback,
          'numbersFamily': presentation.typography.numbersFamily,
          'numbersFallback': presentation.typography.numbersFallback,
          'displayMetrics': presentation.typography.displayMetrics?.toJson(),
          'bodyMetrics': presentation.typography.bodyMetrics?.toJson(),
          'dialogueMetrics': presentation.typography.dialogueMetrics?.toJson(),
          'combatMetrics': presentation.typography.combatMetrics?.toJson(),
          'numbersMetrics': presentation.typography.numbersMetrics?.toJson(),
        },
        'semanticTheme': _semanticThemeViewData(presentation.semanticTheme),
        'surfacePalettes': presentation.surfacePalettes?.toJson(),
        'windows': presentation.windowProfile?.toJson(),
        'layouts': presentation.layoutProfile?.toJson(),
        'dialogue': presentation.dialogueProfile?.toJson(),
        'battle': presentation.battleProfile?.toJson(),
        'pauseMenuLabels': <String, Object?>{
          'pauseTitle': presentation.pauseMenuLabels.pauseTitle,
          'resume': presentation.pauseMenuLabels.resume,
          'party': presentation.pauseMenuLabels.party,
          'bag': presentation.pauseMenuLabels.bag,
          'pokedex': presentation.pauseMenuLabels.pokedex,
          'map': presentation.pauseMenuLabels.map,
          'save': presentation.pauseMenuLabels.save,
          'options': presentation.pauseMenuLabels.options,
          'returnToTitle': presentation.pauseMenuLabels.returnToTitle,
        },
        'pause': <String, Object?>{
          'title': presentation.pausePresentation.title,
          'hint': presentation.pausePresentation.hint,
          'actionOrder': presentation.pausePresentation.actionOrder
              ?.map((action) => action.name)
              .toList(growable: false),
          'actionLabels': <String, String>{
            for (final entry
                in presentation.pausePresentation.actionLabels.entries)
              entry.key.name: entry.value,
          },
          'actionIcons': <String, String>{
            for (final entry
                in presentation.pausePresentation.actionIcons.entries)
              entry.key.name: entry.value.name,
          },
          'hiddenActions': presentation.pausePresentation.hiddenActions
              .map((action) => action.name)
              .toList(growable: false),
          'composition': presentation.pausePresentation.composition?.toJson(),
        },
      });

  final Map<String, Object?> value;
}

Map<String, Object?>? _semanticThemeViewData(
  PokeMapPlayerSemanticTheme? theme,
) =>
    theme == null
        ? null
        : <String, Object?>{
            'primary': theme.primary.toARGB32(),
            'onPrimary': theme.onPrimary.toARGB32(),
            'background': theme.background.toARGB32(),
            'surface': theme.surface.toARGB32(),
            'surfaceElevated': theme.surfaceElevated.toARGB32(),
            'textPrimary': theme.textPrimary.toARGB32(),
            'textSecondary': theme.textSecondary.toARGB32(),
            'outline': theme.outline.toARGB32(),
            'success': theme.success.toARGB32(),
            'warning': theme.warning.toARGB32(),
            'danger': theme.danger.toARGB32(),
            'titleSurface': theme.titleSurface.toARGB32(),
            'dialogueSurface': theme.dialogueSurface.toARGB32(),
            'menuSurface': theme.menuSurface.toARGB32(),
            'overworldHudSurface': theme.overworldHudSurface.toARGB32(),
            'battleHudSurface': theme.battleHudSurface.toARGB32(),
          };

PokeMapPlayerTypography _typography(
  RuntimeLoadedTypography? source,
  ProjectTypographyProfile? profile,
) {
  RuntimeLoadedFontRole role(
    ProjectTypographyRole role,
    List<String> fallback,
  ) =>
      source?.roles[role] ??
      RuntimeLoadedFontRole(registeredFamily: null, fallbackFamilies: fallback);

  final display = role(ProjectTypographyRole.display, const <String>[
    'sans-serif',
  ]);
  final body = role(ProjectTypographyRole.body, const <String>['sans-serif']);
  final dialogue = role(ProjectTypographyRole.dialogue, const <String>[
    'sans-serif',
  ]);
  final combat = source?.roles[ProjectTypographyRole.combat] ?? body;
  final numbers = role(ProjectTypographyRole.numbers, const <String>[
    'monospace',
  ]);
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
