import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'border_runtime_asset_cache.dart';
import 'border_runtime_draw_instruction.dart';

/// Paints only persisted Border materialization using immutable snapshots.
///
/// This renderer contains no contour, neighbor, seed, blueprint, source
/// element, or historical ground-preset resolution.
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
    // `elapsedMs` is constant during the call, so the active frame of a
    // snapshot is resolved once per snapshot instead of once per instruction.
    final resolvedBySnapshotId = <String, _ResolvedSnapshotFrame>{};
    for (final instruction in collection.instructions) {
      switch (instruction) {
        case BorderRuntimeGroundInstruction():
          // Ground culling bounds equal the destination bounds: compute the
          // scaled rect once and reuse it for both the test and the draw.
          final destinationRect =
              _scaledRect(instruction.worldBoundsPx, displayScale);
          if (viewport != null && !_rectsIntersect(destinationRect, viewport)) {
            continue;
          }
          final resolved = resolvedBySnapshotId[instruction.snapshotId] ??=
              _resolveSnapshotFrame(assets, instruction.snapshotId, elapsedMs);
          resolved.frame.image.drawImageRect(
            canvas,
            resolved.sourceRect,
            destinationRect,
            paint,
          );
        case BorderRuntimePlacementInstruction():
          if (viewport != null &&
              !_intersects(
                instruction.cullingBoundsPx,
                viewport,
                displayScale: displayScale,
              )) {
            continue;
          }
          final resolved = resolvedBySnapshotId[instruction.snapshotId] ??=
              _resolveSnapshotFrame(assets, instruction.snapshotId, elapsedMs);
          _drawPlacement(
            canvas: canvas,
            instruction: instruction,
            frame: resolved.frame,
            sourceRect: resolved.sourceRect,
            paint: paint,
            displayScale: displayScale,
          );
      }
    }
  }
}

final class _ResolvedSnapshotFrame {
  const _ResolvedSnapshotFrame({
    required this.frame,
    required this.sourceRect,
  });

  final BorderRuntimeLoadedFrame frame;
  final ui.Rect sourceRect;
}

_ResolvedSnapshotFrame _resolveSnapshotFrame(
  BorderRuntimeAssetBundle assets,
  String snapshotId,
  int elapsedMs,
) {
  final snapshot = assets.snapshotById(snapshotId);
  final frame = _animationFrame(snapshot, elapsedMs);
  final sourceRect = _sourceRect(frame.request.sourceRectPx);
  if (!frame.image.containsSourceRect(sourceRect)) {
    throw AssetNotFoundException(
      'Border snapshot source rectangle is outside its loaded image: '
      '$snapshotId frame ${frame.request.frameIndex}',
    );
  }
  return _ResolvedSnapshotFrame(frame: frame, sourceRect: sourceRect);
}

BorderRuntimeLoadedFrame _animationFrame(
  BorderRuntimeLoadedSnapshot snapshot,
  int elapsedMs,
) {
  final localMs = (elapsedMs < 0 ? 0 : elapsedMs) % snapshot.totalDurationMs;
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
  return bounds.x * displayScale < viewport.right &&
      (bounds.x + bounds.width) * displayScale > viewport.left &&
      bounds.y * displayScale < viewport.bottom &&
      (bounds.y + bounds.height) * displayScale > viewport.top;
}

bool _rectsIntersect(ui.Rect a, ui.Rect b) {
  return a.left < b.right &&
      a.right > b.left &&
      a.top < b.bottom &&
      a.bottom > b.top;
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
