
import '../exceptions/map_exceptions.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';

/// Generates a list of [TilesetVisualFrame] from a vertical atlas layout.
///
/// This helper creates frames for animated surfaces (e.g., water, tall grass)
/// following the vertical atlas convention observed in Pokémon SDK/Pokémon Studio:
///
/// - column = visual variant
/// - row = animation frame
///
/// Each frame becomes a [TilesetVisualFrame] with:
/// - source.x = column
/// - source.y = startRow + frameIndex
/// - source.width = sourceWidth
/// - source.height = sourceHeight
///
/// This is a pure builder: it does not load images, validate against real tileset
/// dimensions, or resolve playback timing. Timing resolution is handled by
/// [resolveTileVisualFrameTimeline] (Lot 2).
///
/// V0 intentionally does not map columns to [TerrainPathVariant] or create persistent
/// [SurfaceDefinition] models. Those are future lots.
List<TilesetVisualFrame> createTileVisualFramesFromVerticalAtlas({
  required int column,
  int startRow = 0,
  required int frameCount,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String tilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
}) {
  // Validate structural parameters
  _validateParameters(
    column: column,
    startRow: startRow,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );

  final frames = <TilesetVisualFrame>[];

  for (var i = 0; i < frameCount; i += 1) {
    // Calculate source position: column stays constant, row increments
    final source = TilesetSourceRect(
      x: column,
      y: startRow + i,
      width: sourceWidth,
      height: sourceHeight,
    );

    // Determine duration for this frame
    final durationMs = _resolveFrameDuration(
      frameIndex: i,
      defaultDurationMs: defaultDurationMs,
      frameDurationsMs: frameDurationsMs,
    );

    // Create the visual frame
    frames.add(
      TilesetVisualFrame(
        tilesetId: tilesetId,
        source: source,
        durationMs: durationMs,
      ),
    );
  }

  // Return an unmodifiable list to preserve immutability
  return List.unmodifiable(frames);
}

void _validateParameters({
  required int column,
  required int startRow,
  required int frameCount,
  required int sourceWidth,
  required int sourceHeight,
  required int defaultDurationMs,
  required List<int?>? frameDurationsMs,
}) {
  if (column < 0) {
    throw const ValidationException('column must be non-negative');
  }

  if (startRow < 0) {
    throw const ValidationException('startRow must be non-negative');
  }

  if (frameCount <= 0) {
    throw const ValidationException('frameCount must be positive');
  }

  if (sourceWidth <= 0) {
    throw const ValidationException('sourceWidth must be positive');
  }

  if (sourceHeight <= 0) {
    throw const ValidationException('sourceHeight must be positive');
  }

  if (defaultDurationMs <= 0) {
    throw const ValidationException('defaultDurationMs must be positive');
  }

  if (frameDurationsMs != null && frameDurationsMs.length != frameCount) {
    throw ValidationException(
      'frameDurationsMs length (${frameDurationsMs.length}) '
      'must equal frameCount ($frameCount)',
    );
  }

  if (frameDurationsMs != null) {
    for (var i = 0; i < frameDurationsMs.length; i += 1) {
      final duration = frameDurationsMs[i];
      if (duration != null && duration <= 0) {
        throw ValidationException(
          'frameDurationsMs[$i] must be positive (got $duration)',
        );
      }
    }
  }
}

int _resolveFrameDuration({
  required int frameIndex,
  required int defaultDurationMs,
  required List<int?>? frameDurationsMs,
}) {
  // If no per-frame durations provided, use default for all frames
  if (frameDurationsMs == null) {
    return defaultDurationMs;
  }

  // Use per-frame duration if provided, otherwise fall back to default
  final customDuration = frameDurationsMs[frameIndex];
  return customDuration ?? defaultDurationMs;
}
