import 'package:map_core/map_core.dart';

/// Returns the first literal frame carried by [candidate].
///
/// Animation sources remain resolved by their dedicated timeline widgets.
SmartTileFrameRef? firstSmartTileFrameOf(SmartTileCandidate candidate) {
  for (final part in candidate.parts) {
    if (part.source case SmartTileFrameSource(frame: final frame)) {
      return frame;
    }
  }
  return null;
}

/// Picks a stable literal frame that visually represents [preset].
SmartTileFrameRef? representativeSmartTileFrameOf(
  ProjectSmartTilePreset preset,
) {
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      final frame = firstSmartTileFrameOf(candidate);
      if (frame != null) return frame;
    }
  }
  return null;
}
