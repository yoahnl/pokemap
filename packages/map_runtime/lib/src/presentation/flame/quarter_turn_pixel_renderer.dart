import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';

typedef QuarterTurnSourcePixelPredicate = bool Function(GridPos sourcePixel);

/// Result of one deterministic quarter-turn draw.
///
/// [drawRunCount] counts calls made to [RuntimeTilesetImage.drawImageRect],
/// before that image splits a run across atlas chunks.
final class QuarterTurnPixelDrawResult {
  const QuarterTurnPixelDrawResult({
    required this.drawRunCount,
    required this.includedDestinationPixelCount,
    this.includedDestinationRunCount = 0,
  });

  static const empty = QuarterTurnPixelDrawResult(
    drawRunCount: 0,
    includedDestinationPixelCount: 0,
  );

  final int drawRunCount;
  final int includedDestinationPixelCount;

  /// Horizontal mask segments encountered during the same sampling pass.
  /// This remains distinct from [drawRunCount], because a pure rotation can
  /// replay many clipped segments with one image draw.
  final int includedDestinationRunCount;
}

/// Component-owned display list for static quarter-turn pixels.
///
/// Recording performs the exact discrete sampling once. Steady-state draws
/// only replay the resulting local [ui.Picture]. The plan never owns or
/// disposes the shared [RuntimeTilesetImage] used while it is recorded.
final class QuarterTurnPixelDrawPlan {
  QuarterTurnPixelDrawPlan._({
    required ui.Picture picture,
    required this.result,
    required this.sourcePixelSampleCount,
  }) : _picture = picture;

  factory QuarterTurnPixelDrawPlan.record({
    required RuntimeTilesetImage image,
    required ui.Rect sourceRect,
    required ui.Rect destinationRect,
    required GridSize sourcePixelSize,
    required GridSize destinationPixelSize,
    required int quarterTurns,
    required ui.Paint paint,
    QuarterTurnSourcePixelPredicate? includeSourcePixel,
    void Function(ui.Picture picture)? debugOnDiscardedPicture,
  }) {
    final recorder = ui.PictureRecorder();
    var sourcePixelSampleCount = 0;
    final trackedPredicate = includeSourcePixel == null
        ? null
        : (GridPos sourcePixel) {
            sourcePixelSampleCount += 1;
            return includeSourcePixel(sourcePixel);
          };
    ui.Picture? picture;
    try {
      final result = drawQuarterTurnPixels(
        ui.Canvas(recorder),
        image: image,
        sourceRect: sourceRect,
        destinationRect: destinationRect,
        sourcePixelSize: sourcePixelSize,
        destinationPixelSize: destinationPixelSize,
        quarterTurns: quarterTurns,
        paint: paint,
        includeSourcePixel: trackedPredicate,
      );
      picture = recorder.endRecording();
      return QuarterTurnPixelDrawPlan._(
        picture: picture,
        result: result,
        sourcePixelSampleCount: sourcePixelSampleCount,
      );
    } catch (_) {
      final discardedPicture = picture ?? recorder.endRecording();
      try {
        debugOnDiscardedPicture?.call(discardedPicture);
      } finally {
        discardedPicture.dispose();
      }
      rethrow;
    }
  }

  final ui.Picture _picture;
  final QuarterTurnPixelDrawResult result;

  /// Number of source-mask predicate calls made during recording.
  ///
  /// Replaying the plan never increments this value.
  final int sourcePixelSampleCount;
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;
  int get approximateBytesUsed => _picture.approximateBytesUsed;

  void draw(ui.Canvas canvas) {
    if (_isDisposed) {
      throw StateError('QuarterTurnPixelDrawPlan is disposed.');
    }
    canvas.drawPicture(_picture);
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _picture.dispose();
  }
}

/// Draws a quarter-turned bitmap with the exact discrete sampling from core.
///
/// Canvas nearest-neighbor transforms do not share the exact rational
/// tie-breaking of [QuarterTurnPixelTransform] for every unequal pixel ratio.
/// This renderer therefore inverse-samples destination pixels through the core
/// transform and batches adjacent pixels only when doing so cannot alter the
/// selected source pixel.
QuarterTurnPixelDrawResult drawQuarterTurnPixels(
  ui.Canvas canvas, {
  required RuntimeTilesetImage image,
  required ui.Rect sourceRect,
  required ui.Rect destinationRect,
  required GridSize sourcePixelSize,
  required GridSize destinationPixelSize,
  required int quarterTurns,
  required ui.Paint paint,
  QuarterTurnSourcePixelPredicate? includeSourcePixel,
}) {
  final transform = QuarterTurnPixelTransform(
    sourcePixelSize: sourcePixelSize,
    destinationPixelSize: destinationPixelSize,
    quarterTurns: quarterTurns,
  );
  if (!image.containsSourceRect(sourceRect) ||
      destinationRect.width <= 0 ||
      destinationRect.height <= 0) {
    return QuarterTurnPixelDrawResult.empty;
  }

  if (quarterTurns == 0 && includeSourcePixel == null) {
    image.drawImageRect(canvas, sourceRect, destinationRect, paint);
    return QuarterTurnPixelDrawResult(
      drawRunCount: 1,
      includedDestinationPixelCount:
          destinationPixelSize.width * destinationPixelSize.height,
      includedDestinationRunCount: 1,
    );
  }

  final isPurePixelRotation = switch (quarterTurns) {
    0 || 2 => destinationPixelSize == sourcePixelSize,
    1 || 3 => destinationPixelSize.width == sourcePixelSize.height &&
        destinationPixelSize.height == sourcePixelSize.width,
    _ => false,
  };
  if (isPurePixelRotation) {
    var includedDestinationPixelCount =
        destinationPixelSize.width * destinationPixelSize.height;
    var includedDestinationRunCount = 1;
    if (includeSourcePixel != null) {
      includedDestinationPixelCount = 0;
      includedDestinationRunCount = 0;
      final destinationPixelWidth =
          destinationRect.width / destinationPixelSize.width;
      final destinationPixelHeight =
          destinationRect.height / destinationPixelSize.height;
      final clipPath = ui.Path();
      for (var y = 0; y < destinationPixelSize.height; y++) {
        int? runStart;
        for (var x = 0; x <= destinationPixelSize.width; x++) {
          var included = false;
          if (x < destinationPixelSize.width) {
            final source = transform.destinationPixelToSourcePixel(
              GridPos(x: x, y: y),
            );
            included = includeSourcePixel(source);
          }
          if (included) {
            includedDestinationPixelCount += 1;
            runStart ??= x;
          } else if (runStart != null) {
            clipPath.addRect(
              ui.Rect.fromLTWH(
                destinationRect.left + runStart * destinationPixelWidth,
                destinationRect.top + y * destinationPixelHeight,
                (x - runStart) * destinationPixelWidth,
                destinationPixelHeight,
              ),
            );
            includedDestinationRunCount += 1;
            runStart = null;
          }
        }
      }
      if (includedDestinationPixelCount == 0) {
        return QuarterTurnPixelDrawResult.empty;
      }
      canvas.save();
      try {
        canvas.clipPath(clipPath, doAntiAlias: false);
        _drawPureQuarterTurn(
          canvas,
          image: image,
          sourceRect: sourceRect,
          destinationRect: destinationRect,
          quarterTurns: quarterTurns,
          paint: paint,
        );
      } finally {
        canvas.restore();
      }
    } else {
      _drawPureQuarterTurn(
        canvas,
        image: image,
        sourceRect: sourceRect,
        destinationRect: destinationRect,
        quarterTurns: quarterTurns,
        paint: paint,
      );
    }
    return QuarterTurnPixelDrawResult(
      drawRunCount: 1,
      includedDestinationPixelCount: includedDestinationPixelCount,
      includedDestinationRunCount: includedDestinationRunCount,
    );
  }

  final sourcePixelWidth = sourceRect.width / sourcePixelSize.width;
  final sourcePixelHeight = sourceRect.height / sourcePixelSize.height;
  final destinationPixelWidth =
      destinationRect.width / destinationPixelSize.width;
  final destinationPixelHeight =
      destinationRect.height / destinationPixelSize.height;
  var drawRunCount = 0;
  var includedDestinationPixelCount = 0;
  var includedDestinationRunCount = 0;

  for (var destinationY = 0;
      destinationY < destinationPixelSize.height;
      destinationY++) {
    var destinationX = 0;
    var previousDestinationPixelIncluded = false;
    while (destinationX < destinationPixelSize.width) {
      final source = transform.destinationPixelToSourcePixel(
        GridPos(x: destinationX, y: destinationY),
      );
      if (includeSourcePixel != null && !includeSourcePixel(source)) {
        previousDestinationPixelIncluded = false;
        destinationX += 1;
        continue;
      }
      if (includeSourcePixel != null && !previousDestinationPixelIncluded) {
        includedDestinationRunCount += 1;
      }
      previousDestinationPixelIncluded = true;

      var runEnd = destinationX + 1;
      while (runEnd < destinationPixelSize.width) {
        final nextSource = transform.destinationPixelToSourcePixel(
          GridPos(x: runEnd, y: destinationY),
        );
        if (nextSource != source ||
            (includeSourcePixel != null && !includeSourcePixel(nextSource))) {
          break;
        }
        runEnd += 1;
      }

      var sourceRunWidth = 1;
      if (quarterTurns == 0 && runEnd == destinationX + 1) {
        while (runEnd < destinationPixelSize.width) {
          final nextSource = transform.destinationPixelToSourcePixel(
            GridPos(x: runEnd, y: destinationY),
          );
          final expectedSourceX = source.x + sourceRunWidth;
          if (nextSource.y != source.y ||
              nextSource.x != expectedSourceX ||
              (includeSourcePixel != null && !includeSourcePixel(nextSource))) {
            break;
          }
          sourceRunWidth += 1;
          runEnd += 1;
        }
      }

      final destinationRunWidth = runEnd - destinationX;
      image.drawImageRect(
        canvas,
        ui.Rect.fromLTWH(
          sourceRect.left + source.x * sourcePixelWidth,
          sourceRect.top + source.y * sourcePixelHeight,
          sourceRunWidth * sourcePixelWidth,
          sourcePixelHeight,
        ),
        ui.Rect.fromLTWH(
          destinationRect.left + destinationX * destinationPixelWidth,
          destinationRect.top + destinationY * destinationPixelHeight,
          destinationRunWidth * destinationPixelWidth,
          destinationPixelHeight,
        ),
        paint,
      );
      drawRunCount += 1;
      includedDestinationPixelCount += destinationRunWidth;
      destinationX = runEnd;
    }
  }

  return QuarterTurnPixelDrawResult(
    drawRunCount: drawRunCount,
    includedDestinationPixelCount: includedDestinationPixelCount,
    includedDestinationRunCount:
        includeSourcePixel == null ? drawRunCount : includedDestinationRunCount,
  );
}

void _drawPureQuarterTurn(
  ui.Canvas canvas, {
  required RuntimeTilesetImage image,
  required ui.Rect sourceRect,
  required ui.Rect destinationRect,
  required int quarterTurns,
  required ui.Paint paint,
}) {
  canvas.save();
  try {
    switch (quarterTurns) {
      case 0:
        image.drawImageRect(canvas, sourceRect, destinationRect, paint);
        break;
      case 1:
        canvas
          ..translate(destinationRect.right, destinationRect.top)
          ..rotate(math.pi / 2);
        image.drawImageRect(
          canvas,
          sourceRect,
          ui.Rect.fromLTWH(
            0,
            0,
            destinationRect.height,
            destinationRect.width,
          ),
          paint,
        );
        break;
      case 2:
        canvas
          ..translate(destinationRect.right, destinationRect.bottom)
          ..rotate(math.pi);
        image.drawImageRect(
          canvas,
          sourceRect,
          ui.Rect.fromLTWH(
            0,
            0,
            destinationRect.width,
            destinationRect.height,
          ),
          paint,
        );
        break;
      case 3:
        canvas
          ..translate(destinationRect.left, destinationRect.bottom)
          ..rotate(-math.pi / 2);
        image.drawImageRect(
          canvas,
          sourceRect,
          ui.Rect.fromLTWH(
            0,
            0,
            destinationRect.height,
            destinationRect.width,
          ),
          paint,
        );
        break;
    }
  } finally {
    canvas.restore();
  }
}
