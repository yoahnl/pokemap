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
  });

  static const empty = QuarterTurnPixelDrawResult(
    drawRunCount: 0,
    includedDestinationPixelCount: 0,
  );

  final int drawRunCount;
  final int includedDestinationPixelCount;
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
    if (includeSourcePixel != null) {
      includedDestinationPixelCount = 0;
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

  for (var destinationY = 0;
      destinationY < destinationPixelSize.height;
      destinationY++) {
    var destinationX = 0;
    while (destinationX < destinationPixelSize.width) {
      final source = transform.destinationPixelToSourcePixel(
        GridPos(x: destinationX, y: destinationY),
      );
      if (includeSourcePixel != null && !includeSourcePixel(source)) {
        destinationX += 1;
        continue;
      }

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
