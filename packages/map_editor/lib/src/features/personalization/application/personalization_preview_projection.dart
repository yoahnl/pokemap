import 'package:map_core/map_core.dart';

enum PersonalizationPreviewSurface {
  intro,
  title,
  dialogue,
  menu,
  overworldHud,
  battleHud,
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
