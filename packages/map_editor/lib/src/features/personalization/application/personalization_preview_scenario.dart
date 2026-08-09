import 'package:map_core/map_core.dart';

import 'personalization_preview_projection.dart';
import 'personalization_preview_surface_descriptor.dart';
import 'project_presentation_presets.dart';

final class PersonalizationPreviewScenario {
  const PersonalizationPreviewScenario({
    required this.draftProfile,
    required this.surface,
    this.baselineProfile,
    this.viewport = PersonalizationPreviewViewport.landscape,
    this.textScale = 1,
    this.reducedMotion = false,
    this.comparisonEnabled = false,
  });

  final ProjectPresentationProfile draftProfile;
  final ProjectPresentationProfile? baselineProfile;
  final PersonalizationPreviewSurface surface;
  final PersonalizationPreviewViewport viewport;
  final double textScale;
  final bool reducedMotion;
  final bool comparisonEnabled;

  bool get canCompare {
    final baseline = baselineProfile;
    return baseline != null &&
        !compareProjectPresentation(baseline, draftProfile).isIdentical;
  }

  bool get showComparison => canCompare && comparisonEnabled;

  PersonalizationPreviewScenario copyWith({
    PersonalizationPreviewSurface? surface,
    PersonalizationPreviewViewport? viewport,
    double? textScale,
    bool? reducedMotion,
    bool? comparisonEnabled,
  }) => PersonalizationPreviewScenario(
    draftProfile: draftProfile,
    baselineProfile: baselineProfile,
    surface: surface ?? this.surface,
    viewport: viewport ?? this.viewport,
    textScale: textScale ?? this.textScale,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    comparisonEnabled: comparisonEnabled ?? this.comparisonEnabled,
  );
}
