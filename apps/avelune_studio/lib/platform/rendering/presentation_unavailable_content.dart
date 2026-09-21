import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';

class PresentationUnavailableContent implements PresentationFrameContentPort {
  const PresentationUnavailableContent();
  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) => const PresentationVisualUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Média en cours de chargement',
  );
  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Sous-titres en cours de chargement',
  );
}
