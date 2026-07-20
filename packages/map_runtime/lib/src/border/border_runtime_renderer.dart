import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'border_runtime_asset_cache.dart';
import 'border_runtime_draw_instruction.dart';

/// Paints only persisted Border materialization using immutable snapshots.
///
/// This renderer contains no contour, neighbor, seed, blueprint, source
/// element, or Surface-preset resolution.
final class BorderRuntimeRenderer {
  const BorderRuntimeRenderer();

  void renderCollection(
    ui.Canvas canvas, {
    required BorderRuntimeDrawInstructionCollection collection,
    required BorderRuntimeAssetBundle assets,
    required int elapsedMs,
    required double displayScale,
    ui.Rect? viewport,
  }) {
    if (!collection.isVisible || collection.opacity <= 0) {
      return;
    }

    final paint = ui.Paint()
      ..isAntiAlias = false
      ..filterQuality = ui.FilterQuality.none
      ..color = ui.Color.fromRGBO(255, 255, 255, collection.opacity);
    for (final instruction in collection.instructions) {
      if (viewport != null &&
          !_intersects(
            instruction.cullingBoundsPx,
            viewport,
            displayScale: displayScale,
          )) {
        continue;
      }
      final snapshot = assets.snapshotById(instruction.snapshotId);
      final frame = _animationFrame(snapshot, elapsedMs);
      final sourceRect = _sourceRect(frame.request.sourceRectPx);
      if (!frame.image.containsSourceRect(sourceRect)) {
        throw AssetNotFoundException(
          'Border snapshot source rectangle is outside its loaded image: '
          '${instruction.snapshotId} frame ${frame.request.frameIndex}',
        );
      }

      switch (instruction) {
        case BorderRuntimeGroundInstruction():
          frame.image.drawImageRect(
            canvas,
            sourceRect,
            _scaledRect(instruction.worldBoundsPx, displayScale),
            paint,
          );
        case BorderRuntimePlacementInstruction():
          _drawPlacement(
            canvas: canvas,
            instruction: instruction,
            frame: frame,
            sourceRect: sourceRect,
            paint: paint,
            displayScale: displayScale,
          );
      }
    }
  }
}

BorderRuntimeLoadedFrame _animationFrame(
  BorderRuntimeLoadedSnapshot snapshot,
  int elapsedMs,
) {
  var totalDurationMs = 0;
  for (final frame in snapshot.frames) {
    if (frame.request.durationMs <= 0) {
      throw AssetNotFoundException(
        'Border snapshot has a non-positive frame duration: '
        '${snapshot.snapshotId} frame ${frame.request.frameIndex}',
      );
    }
    totalDurationMs += frame.request.durationMs;
  }
  final localMs = (elapsedMs < 0 ? 0 : elapsedMs) % totalDurationMs;
  var boundaryMs = 0;
  for (final frame in snapshot.frames) {
    boundaryMs += frame.request.durationMs;
    if (localMs < boundaryMs) {
      return frame;
    }
  }
  return snapshot.frames.last;
}

void _drawPlacement({
  required ui.Canvas canvas,
  required BorderRuntimePlacementInstruction instruction,
  required BorderRuntimeLoadedFrame frame,
  required ui.Rect sourceRect,
  required ui.Paint paint,
  required double displayScale,
}) {
  final sourceWidth = sourceRect.width;
  final sourceHeight = sourceRect.height;
  canvas.save();
  try {
    canvas.translate(
      instruction.topLeftWorldPx.x * displayScale,
      instruction.topLeftWorldPx.y * displayScale,
    );
    canvas.scale(displayScale, displayScale);
    _applyPositiveBoundsClockwiseRotation(
      canvas,
      quarterTurns: instruction.transform.quarterTurns,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
    );
    if (instruction.transform.flipX) {
      canvas.translate(sourceWidth, 0);
      canvas.scale(-1, 1);
    }
    frame.image.drawImageRect(
      canvas,
      sourceRect,
      ui.Rect.fromLTWH(0, 0, sourceWidth, sourceHeight),
      paint,
    );
  } finally {
    canvas.restore();
  }
}

void _applyPositiveBoundsClockwiseRotation(
  ui.Canvas canvas, {
  required int quarterTurns,
  required double sourceWidth,
  required double sourceHeight,
}) {
  switch (quarterTurns) {
    case 0:
      return;
    case 1:
      canvas.translate(sourceHeight, 0);
      canvas.rotate(math.pi / 2);
    case 2:
      canvas.translate(sourceWidth, sourceHeight);
      canvas.rotate(math.pi);
    case 3:
      canvas.translate(0, sourceWidth);
      canvas.rotate(3 * math.pi / 2);
    default:
      throw ArgumentError.value(
        quarterTurns,
        'quarterTurns',
        'must be between 0 and 3',
      );
  }
}

bool _intersects(
  BorderPixelRect bounds,
  ui.Rect viewport, {
  required double displayScale,
}) {
  final scaled = _scaledRect(bounds, displayScale);
  return scaled.left < viewport.right &&
      scaled.right > viewport.left &&
      scaled.top < viewport.bottom &&
      scaled.bottom > viewport.top;
}

ui.Rect _sourceRect(BorderPixelRect rect) => ui.Rect.fromLTWH(
      rect.x.toDouble(),
      rect.y.toDouble(),
      rect.width.toDouble(),
      rect.height.toDouble(),
    );

ui.Rect _scaledRect(BorderPixelRect rect, double displayScale) =>
    ui.Rect.fromLTWH(
      rect.x * displayScale,
      rect.y * displayScale,
      rect.width * displayScale,
      rect.height * displayScale,
    );
