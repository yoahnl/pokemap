import 'package:map_core/map_core.dart';

/// Viewport family used to choose one authored presentation-video variant.
enum RuntimePresentationOrientation { landscape, portrait }

/// One concrete video selected from a responsive project contract.
final class RuntimeSelectedPresentationVideo {
  const RuntimeSelectedPresentationVideo({
    required this.variant,
    required this.orientation,
    required this.usedLandscapeFallback,
  });

  final ProjectVideoVariantProfile variant;
  final RuntimePresentationOrientation orientation;
  final bool usedLandscapeFallback;
}

/// Selects portrait media when available and otherwise uses the mandatory
/// landscape variant. The fallback is explicit so hosts can report it without
/// guessing from dimensions or project paths.
RuntimeSelectedPresentationVideo selectRuntimePresentationVideo(
  ProjectResponsiveVideoProfile media,
  RuntimePresentationOrientation requestedOrientation,
) {
  final portrait = media.portrait;
  if (requestedOrientation == RuntimePresentationOrientation.portrait &&
      portrait != null) {
    return RuntimeSelectedPresentationVideo(
      variant: portrait,
      orientation: RuntimePresentationOrientation.portrait,
      usedLandscapeFallback: false,
    );
  }
  return RuntimeSelectedPresentationVideo(
    variant: media.landscape,
    orientation: RuntimePresentationOrientation.landscape,
    usedLandscapeFallback:
        requestedOrientation == RuntimePresentationOrientation.portrait,
  );
}
