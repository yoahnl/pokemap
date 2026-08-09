import 'package:map_core/map_core.dart';

/// Returns the first frame that can visually represent [candidate].
SmartTileFrameRef? firstSmartTileFrameOf(
  SmartTileCandidate candidate, {
  required Iterable<ProjectSmartTileAnimation> animations,
}) {
  for (final part in candidate.parts) {
    switch (part.source) {
      case SmartTileFrameSource(frame: final frame):
        return frame;
      case SmartTileAnimationSource(animationId: final animationId):
        for (final animation in animations) {
          if (animation.id == animationId && animation.frames.isNotEmpty) {
            return animation.frames.first.frame;
          }
        }
    }
  }
  return null;
}

/// Picks a stable frame that visually represents [preset].
SmartTileFrameRef? representativeSmartTileFrameOf(
  ProjectSmartTilePreset preset, {
  required Iterable<ProjectSmartTileAnimation> animations,
}) {
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      final frame = firstSmartTileFrameOf(
        candidate,
        animations: animations,
      );
      if (frame != null) return frame;
    }
  }
  return null;
}
