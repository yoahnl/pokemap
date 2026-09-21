import 'package:map_core/map_core_domain.dart';
import 'presentation_view_state.dart';

PresentationVisualComposition presentationPose(
  PresentationClip clip,
  String key,
) {
  return switch (clip) {
    PresentationTextClip() => switch (key) {
      'to' => clip.to,
      'portraitCompositionOverride' =>
        clip.portraitCompositionOverride ?? clip.from,
      'landscapeCompositionOverride' =>
        clip.landscapeCompositionOverride ?? clip.from,
      _ => clip.from,
    },
    PresentationVisualClip() => switch (key) {
      'to' => clip.to,
      'portraitCompositionOverride' =>
        clip.portraitCompositionOverride ?? clip.from,
      'landscapeCompositionOverride' =>
        clip.landscapeCompositionOverride ?? clip.from,
      _ => clip.from,
    },
    _ => PresentationVisualComposition.identity,
  };
}

String presentationPoseKey(PresentationViewState view) =>
    view.orientationOverride
    ? view.portrait
          ? 'portraitCompositionOverride'
          : 'landscapeCompositionOverride'
    : view.pose == PresentationPose.end
    ? 'to'
    : 'from';

Map<String, Object?> presentationPosePatch(
  PresentationClip clip,
  PresentationViewState view,
  Map<String, double> changes,
) {
  final encoded = encodePresentationClip(clip);
  final key = presentationPoseKey(view);
  return {
    key: {...Map<String, Object?>.from(encoded[key] as Map? ?? {}), ...changes},
    if (!view.orientationOverride && view.pose == PresentationPose.trajectory)
      'to': {
        ...Map<String, Object?>.from(encoded['to'] as Map? ?? {}),
        ...changes,
      },
  };
}
