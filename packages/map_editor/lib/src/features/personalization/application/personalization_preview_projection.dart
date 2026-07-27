import 'package:map_core/map_core.dart';

enum PersonalizationPreviewSurface {
  intro,
  title,
  dialogue,
  menu,
  overworldHud,
  battleHud,
}

enum PersonalizationPreviewViewport {
  landscape,
  portrait,
  square;

  double get aspectRatio => switch (this) {
        PersonalizationPreviewViewport.landscape => 16 / 9,
        PersonalizationPreviewViewport.portrait => 9 / 16,
        PersonalizationPreviewViewport.square => 1,
      };
}

final class PersonalizationPreviewSimulation {
  const PersonalizationPreviewSimulation({
    this.viewport = PersonalizationPreviewViewport.landscape,
    this.textScale = 1,
    this.reducedMotion = false,
  });

  final PersonalizationPreviewViewport viewport;
  final double textScale;
  final bool reducedMotion;

  PersonalizationPreviewSimulation copyWith({
    PersonalizationPreviewViewport? viewport,
    double? textScale,
    bool? reducedMotion,
  }) =>
      PersonalizationPreviewSimulation(
        viewport: viewport ?? this.viewport,
        textScale: textScale ?? this.textScale,
        reducedMotion: reducedMotion ?? this.reducedMotion,
      );
}

final class PersonalizationPreviewSurfaceProjection {
  const PersonalizationPreviewSurfaceProjection({
    required this.surface,
    required this.backgroundHex,
    required this.textHex,
    required this.fontFamily,
  });

  final PersonalizationPreviewSurface surface;
  final String backgroundHex;
  final String textHex;
  final String fontFamily;
}

/// Editor preview derived directly from the runtime-owned project contract.
final class PersonalizationPreviewProjection {
  PersonalizationPreviewProjection(this.profile);

  final ProjectPresentationProfile profile;

  String get titleLayoutVariant => profile.branding.layoutVariant;

  PersonalizationPreviewSurfaceProjection surface(
    PersonalizationPreviewSurface surface,
  ) {
    final theme = profile.theme ?? safeProjectSemanticTheme;
    final typography = profile.typography;
    final background = switch (surface) {
      PersonalizationPreviewSurface.intro => theme.titleSurface,
      PersonalizationPreviewSurface.title => theme.titleSurface,
      PersonalizationPreviewSurface.dialogue => theme.dialogueSurface,
      PersonalizationPreviewSurface.menu => theme.menuSurface,
      PersonalizationPreviewSurface.overworldHud => theme.overworldHudSurface,
      PersonalizationPreviewSurface.battleHud => theme.battleHudSurface,
    };
    final role = switch (surface) {
      PersonalizationPreviewSurface.intro => typography?.display,
      PersonalizationPreviewSurface.title => typography?.display,
      PersonalizationPreviewSurface.dialogue => typography?.dialogue,
      PersonalizationPreviewSurface.menu ||
      PersonalizationPreviewSurface.overworldHud =>
        typography?.body,
      PersonalizationPreviewSurface.battleHud => typography?.numbers,
    };
    return PersonalizationPreviewSurfaceProjection(
      surface: surface,
      backgroundHex: background,
      textHex: theme.textPrimary,
      fontFamily:
          role?.family ?? role?.fallbackFamilies.firstOrNull ?? 'sans-serif',
    );
  }
}
