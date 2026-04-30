import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'path_center_pattern_preview_compositor.dart';

const _errorPrefix = 'Path center pattern animated preview';

Uint8List renderPathCenterPatternAnimatedPreviewPng({
  required Uint8List tilesetPngBytes,
  required PathCenterPattern pattern,
  required int tileWidthPx,
  required int tileHeightPx,
  required int elapsedMs,
  TilesetTransparentColor? transparentColor,
}) {
  validatePathCenterPatternPreviewTileDimensions(
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
    errorPrefix: _errorPrefix,
  );
  if (elapsedMs < 0) {
    throw ArgumentError.value(
      elapsedMs,
      'elapsedMs',
      '$_errorPrefix elapsedMs must be non-negative.',
    );
  }

  final tileset = decodePathCenterPatternPreviewTilesetPng(
    tilesetPngBytes: tilesetPngBytes,
    transparentColor: transparentColor,
    errorPrefix: _errorPrefix,
  );
  final preview = createPathCenterPatternPreviewImage(
    pattern: pattern,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
  );

  for (final cell in pattern.cells) {
    if (cell.frames.isEmpty) {
      throw ArgumentError.value(
        cell,
        'pattern',
        '$_errorPrefix cell must contain at least one frame.',
      );
    }
    _validateFrameDurations(cell.frames);
    final resolution = resolveTileVisualFrameTimeline(
      frames: cell.frames,
      elapsedMs: elapsedMs.toDouble(),
      mode: TileVisualFrameTimelinePlaybackMode.loop,
    );
    final frame = resolution.frame;
    if (frame == null) {
      throw ArgumentError.value(
        cell,
        'pattern',
        '$_errorPrefix cell must contain at least one frame.',
      );
    }
    copyPathCenterPatternPreviewFrameTile(
      tileset: tileset,
      preview: preview,
      cell: cell,
      frame: frame,
      tileWidthPx: tileWidthPx,
      tileHeightPx: tileHeightPx,
      errorPrefix: _errorPrefix,
    );
  }

  return img.encodePng(preview);
}

void _validateFrameDurations(List<TilesetVisualFrame> frames) {
  for (final frame in frames) {
    final durationMs = frame.durationMs;
    if (durationMs != null && durationMs <= 0) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        '$_errorPrefix frame duration must be positive.',
      );
    }
  }
}
