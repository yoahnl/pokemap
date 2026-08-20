import 'dart:ui' show Locale;

import 'package:map_core/map_core.dart';

import 'presentation_frame_renderer.dart';

/// Interpolates Presentation caption text against the CURRENT narrative
/// scope at render time — BETA-CIN-071.
///
/// Presentation never owns the draft: the scope is provided by the Scene
/// side through [currentScope], and captions are interpolated only once
/// their text is resolved for the viewer's locale. Rendering always reads
/// the freshest scope, so a caption evaluated after a validated response
/// shows the new value and a stale scope can never be displayed.
final class PresentationInterpolatingFrameContentPort
    implements PresentationFrameContentPort {
  const PresentationInterpolatingFrameContentPort({
    required this.delegate,
    required this.currentScope,
  });

  final PresentationFrameContentPort delegate;
  final PresentationInterpolationScope Function() currentScope;

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) =>
      delegate.resolveVisual(clip: clip, orientation: orientation);

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) {
    final resolution = delegate.resolveCaption(clip: clip, locale: locale);
    if (resolution is! PresentationCaptionReady) return resolution;
    final rendered =
        interpolatePresentationText(resolution.text, currentScope()).text;
    if (rendered == resolution.text) return resolution;
    return PresentationCaptionReady(text: rendered);
  }
}
