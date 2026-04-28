import 'package:map_core/map_core.dart';

/// Editor-only summary of whether the Surface Painter has paintable presets.
///
/// The painter places `surfacePresetId` values in a SurfaceLayer. Atlases and
/// animations can exist before a preset is authored, so this small value object
/// makes that intermediate Surface Studio state explicit instead of showing a
/// vague empty palette.
final class SurfaceCatalogAvailability {
  const SurfaceCatalogAvailability({
    required this.atlasCount,
    required this.animationCount,
    required this.presetCount,
  });

  factory SurfaceCatalogAvailability.fromCatalog(
    ProjectSurfaceCatalog catalog,
  ) {
    return SurfaceCatalogAvailability(
      atlasCount: catalog.atlasCount,
      animationCount: catalog.animationCount,
      presetCount: catalog.presetCount,
    );
  }

  final int atlasCount;
  final int animationCount;
  final int presetCount;

  bool get hasAnyAtlas => atlasCount > 0;
  bool get hasAnyAnimation => animationCount > 0;
  bool get hasAnyPreset => presetCount > 0;

  bool get canPaint => hasAnyPreset;

  String get primaryMessage {
    if (hasAnyPreset) {
      return 'Sélectionnez une surface à peindre.';
    }
    if (hasAnyAnimation) {
      return 'Animations Surface trouvées, mais aucun preset peignable.';
    }
    if (hasAnyAtlas) {
      return 'Atlas Surface trouvé, mais aucune animation ni preset peignable.';
    }
    return 'Aucun preset Surface disponible';
  }

  String get secondaryMessage {
    if (hasAnyPreset) {
      return 'Les presets sont les surfaces que vous pouvez peindre sur la map.';
    }
    if (hasAnyAnimation) {
      return 'Créez un preset Surface dans Surface Studio, puis appliquez/sauvegardez le catalogue.';
    }
    if (hasAnyAtlas) {
      return 'Générez les animations puis créez un preset Surface dans Surface Studio.';
    }
    return 'Créez d’abord un atlas, des animations et un preset dans Surface Studio.';
  }

  String get recommendedActionLabel {
    if (hasAnyPreset) {
      return 'Sélectionner une surface';
    }
    return 'Ouvrir Surface Studio';
  }
}
