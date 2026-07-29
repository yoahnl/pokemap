import 'package:map_core/map_core.dart';

const int kProjectElementFrameDurationFallbackMs = 200;

int projectElementFrameDurationMs(TilesetVisualFrame frame) {
  final duration = frame.durationMs;
  if (duration == null || duration <= 0) {
    return kProjectElementFrameDurationFallbackMs;
  }
  return duration;
}

TilesetVisualFrame pickProjectElementFrame(
  List<TilesetVisualFrame> frames,
  int elapsedMs,
) {
  if (frames.isEmpty) {
    throw StateError('ProjectElementEntry.frames must not be empty');
  }
  if (frames.length == 1) {
    return frames.first;
  }
  var total = 0;
  for (final frame in frames) {
    total += projectElementFrameDurationMs(frame);
  }
  if (total <= 0) {
    return frames.first;
  }
  var remaining = elapsedMs % total;
  if (remaining < 0) {
    remaining = (remaining % total + total) % total;
  }
  for (final frame in frames) {
    final duration = projectElementFrameDurationMs(frame);
    if (remaining < duration) {
      return frame;
    }
    remaining -= duration;
  }
  return frames.last;
}
