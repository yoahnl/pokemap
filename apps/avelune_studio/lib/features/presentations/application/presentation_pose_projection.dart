import 'package:map_core/map_core_domain.dart';

enum PresentationPose { start, end, trajectory }

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

String presentationPoseKey({
  required PresentationPose pose,
  required bool orientationOverride,
  required bool portrait,
}) => orientationOverride
    ? portrait
          ? 'portraitCompositionOverride'
          : 'landscapeCompositionOverride'
    : pose == PresentationPose.end
    ? 'to'
    : 'from';

Map<String, Object?> presentationPosePatch(
  PresentationClip clip,
  Map<String, double> changes, {
  required PresentationPose pose,
  required bool orientationOverride,
  required bool portrait,
  bool preserveTrajectoryDelta = false,
}) {
  final encoded = encodePresentationClip(clip);
  final key = presentationPoseKey(
    pose: pose,
    orientationOverride: orientationOverride,
    portrait: portrait,
  );
  final patch = <String, Object?>{
    key: {...Map<String, Object?>.from(encoded[key] as Map? ?? {}), ...changes},
    if (!orientationOverride && pose == PresentationPose.trajectory)
      'to': {
        ...Map<String, Object?>.from(encoded['to'] as Map? ?? {}),
        ...changes,
      },
  };
  if (preserveTrajectoryDelta &&
      !orientationOverride &&
      pose == PresentationPose.trajectory) {
    final first = presentationPose(clip, 'from');
    final last = presentationPose(clip, 'to');
    final firstValues = {
      'translateX': first.translateX,
      'translateY': first.translateY,
      'rotationTurns': first.rotationTurns,
      'scaleX': first.scaleX,
      'scaleY': first.scaleY,
    };
    final lastValues = {
      'translateX': last.translateX,
      'translateY': last.translateY,
      'rotationTurns': last.rotationTurns,
      'scaleX': last.scaleX,
      'scaleY': last.scaleY,
    };
    patch['to'] = {
      ...Map<String, Object?>.from(encoded['to'] as Map? ?? {}),
      for (final entry in changes.entries)
        entry.key: entry.key.startsWith('scale')
            ? lastValues[entry.key]! * entry.value / firstValues[entry.key]!
            : lastValues[entry.key]! + entry.value - firstValues[entry.key]!,
    };
  }
  return patch;
}
