import 'package:map_core/map_core.dart';

import 'personalization_preview_surface_descriptor.dart';

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
    final descriptor = PersonalizationPreviewSurfaceDescriptor.forSurface(
      surface,
    );
    final role = descriptor.typographyProfile(typography);
    return PersonalizationPreviewSurfaceProjection(
      surface: surface,
      backgroundHex: descriptor.backgroundHex(theme),
      textHex: theme.textPrimary,
      fontFamily:
          role?.family ?? role?.fallbackFamilies.firstOrNull ?? 'sans-serif',
    );
  }
}
