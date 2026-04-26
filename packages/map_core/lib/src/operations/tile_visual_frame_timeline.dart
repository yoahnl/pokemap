import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';

/// Playback modes for resolving a visual tile frame from a timeline.
///
/// This is intentionally smaller than [MapPlacedElementAnimationMode]. Tile
/// timelines are a neutral primitive for paths, terrain previews, and future
/// Surface Engine work. Ping-pong, random starts, authored start offsets, and
/// trigger orchestration stay outside this V1 API until a concrete surface use
/// case needs them.
enum TileVisualFrameTimelinePlaybackMode {
  /// Always resolve the first frame.
  ///
  /// This mode is useful for static previews and legacy code paths that only
  /// want the primary sprite, even when additional frames are present.
  staticFrame,

  /// Resolve frames in a looping forward sequence.
  ///
  /// The index semantics are delegated to the existing placed-element
  /// animation resolver so tile timelines do not fork animation behavior.
  loop,

  /// Resolve frames once, clamp on the last frame, and report completion.
  ///
  /// This is meant for local one-shot surface effects such as future tall-grass
  /// rustles, while preserving the current one-shot semantics used elsewhere.
  oneShot,
}

/// Result of resolving a [TilesetVisualFrame] timeline at a point in time.
class TileVisualFrameTimelineResolution {
  const TileVisualFrameTimelineResolution({
    required this.frame,
    required this.frameIndex,
    required this.completed,
  });

  /// The selected frame, or null when the timeline has no frames.
  final TilesetVisualFrame? frame;

  /// Index of [frame] in the original input list.
  ///
  /// Empty timelines resolve to zero so callers can keep simple fallback code
  /// without special negative-index handling.
  final int frameIndex;

  /// Whether playback is complete.
  ///
  /// Static timelines are considered complete immediately. Loop timelines with
  /// at least one frame never complete. One-shot timelines follow
  /// [resolvePlacedElementAnimationOneShotFrame].
  final bool completed;
}

/// Resolves a visual tile frame from [frames] using the existing animation
/// timing semantics shared by placed elements and legacy path autotiles.
///
/// V1 deliberately does not own persistence, rendering, surface rules, or
/// trigger state. It is a pure map_core helper whose job is only:
///
/// - normalize frame durations with the current engine fallback;
/// - select a frame index for static, loop, or one-shot playback;
/// - return the exact [TilesetVisualFrame] object from [frames].
///
/// Invalid or absent [TilesetVisualFrame.durationMs] values are normalized by
/// [normalizeElementFrameDurationsMs], which currently uses
/// [defaultPlacedElementAnimationFrameDurationMs]. Non-positive [speed] values
/// follow the existing placed animation fallback and behave as speed 1.0.
TileVisualFrameTimelineResolution resolveTileVisualFrameTimeline({
  required List<TilesetVisualFrame> frames,
  required double elapsedMs,
  required TileVisualFrameTimelinePlaybackMode mode,
  double speed = 1.0,
}) {
  if (frames.isEmpty) {
    return const TileVisualFrameTimelineResolution(
      frame: null,
      frameIndex: 0,
      completed: true,
    );
  }

  switch (mode) {
    case TileVisualFrameTimelinePlaybackMode.staticFrame:
      return TileVisualFrameTimelineResolution(
        frame: frames.first,
        frameIndex: 0,
        completed: true,
      );
    case TileVisualFrameTimelinePlaybackMode.loop:
      final index = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: _normalizedFrameDurations(frames),
        elapsedMs: elapsedMs,
        animation: MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          speed: speed,
        ),
      ).clamp(0, frames.length - 1);
      return TileVisualFrameTimelineResolution(
        frame: frames[index],
        frameIndex: index,
        completed: false,
      );
    case TileVisualFrameTimelinePlaybackMode.oneShot:
      final resolution = resolvePlacedElementAnimationOneShotFrame(
        frameDurationsMs: _normalizedFrameDurations(frames),
        elapsedMs: elapsedMs,
        speed: speed,
      );
      final index = resolution.frameIndex.clamp(0, frames.length - 1);
      return TileVisualFrameTimelineResolution(
        frame: frames[index],
        frameIndex: index,
        completed: resolution.completed,
      );
  }
}

List<int> _normalizedFrameDurations(List<TilesetVisualFrame> frames) {
  return normalizeElementFrameDurationsMs(
    frames.map((frame) => frame.durationMs).toList(growable: false),
  );
}
