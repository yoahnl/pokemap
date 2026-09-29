import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';

typedef QuarterTurnSourcePixelPredicate = bool Function(GridPos sourcePixel);
typedef _DrawPlanKey = (
  RuntimeTilesetImage,
  ui.Rect,
  GridSize,
  GridSize,
  int,
  Object?
);

final class QuarterTurnPixelPlanCache {
  QuarterTurnPixelPlanCache(
      {this.maxEntries = 64, this.maxBytes = 32 * 1024 * 1024}) {
    if (maxEntries < 1 || maxBytes < 4) {
      throw ArgumentError('Invalid draw plan cache budget');
    }
  }
  final int maxEntries;
  final int maxBytes;
  final _entries = <_DrawPlanKey, QuarterTurnPixelDrawPlan>{};
  int bytes = 0;
  int preparationCount = 0;

  QuarterTurnPixelDrawPlan obtain(
      {required RuntimeTilesetImage image,
      required ui.Rect sourceRect,
      required GridSize sourceSize,
      required GridSize destinationSize,
      required int quarterTurns,
      Object? maskKey,
      QuarterTurnSourcePixelPredicate? includeSourcePixel}) {
    _entries.removeWhere((key, plan) {
      if (!key.$1.isDisposed) return false;
      bytes -= plan.approximateBytesUsed;
      plan.dispose();
      return true;
    });
    final key =
        (image, sourceRect, sourceSize, destinationSize, quarterTurns, maskKey);
    final found = _entries.remove(key);
    if (found != null) {
      _entries[key] = found;
      return found;
    }
    final rotatedWidth =
        quarterTurns.isEven ? sourceSize.width : sourceSize.height;
    final rotatedHeight =
        quarterTurns.isEven ? sourceSize.height : sourceSize.width;
    final deferRaster =
        destinationSize.width * destinationSize.height * 4 > maxBytes &&
            math.min(rotatedWidth, destinationSize.width) *
                    math.min(rotatedHeight, destinationSize.height) >
                maxBytes ~/ 64 &&
            (includeSourcePixel != null || sourceSize != destinationSize);
    final plan = QuarterTurnPixelDrawPlan.record(
        image: image,
        sourceRect: sourceRect,
        destinationRect: ui.Rect.fromLTWH(
            0,
            0,
            destinationSize.width.toDouble(),
            destinationSize.height.toDouble()),
        sourcePixelSize: sourceSize,
        destinationPixelSize: destinationSize,
        quarterTurns: quarterTurns,
        paint: ui.Paint()
          ..isAntiAlias = false
          ..filterQuality = ui.FilterQuality.none,
        includeSourcePixel: includeSourcePixel,
        deferRaster: deferRaster);
    preparationCount++;
    try {
      if (deferRaster || plan.approximateBytesUsed > maxBytes) {
        plan.rasterize(destinationSize, maxBytes: maxBytes);
      }
    } catch (_) {
      plan.dispose();
      rethrow;
    }
    while (_entries.isNotEmpty &&
        (_entries.length >= maxEntries ||
            bytes + plan.approximateBytesUsed > maxBytes)) {
      final old = _entries.remove(_entries.keys.first)!;
      bytes -= old.approximateBytesUsed;
      old.dispose();
    }
    _entries[key] = plan;
    bytes += plan.approximateBytesUsed;
    return plan;
  }

  void dispose() {
    for (final plan in _entries.values) {
      plan.dispose();
    }
    _entries.clear();
    bytes = 0;
  }
}

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
    bool deferRaster = false,
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
        destinationPixelClip: deferRaster ? ui.Rect.zero : null,
      );
      picture = recorder.endRecording();
      return QuarterTurnPixelDrawPlan._(
        picture: picture,
        result: result,
        sourcePixelSampleCount: sourcePixelSampleCount,
      ).._tilePainter = ((canvas, clip) => drawQuarterTurnPixels(canvas,
          image: image,
          sourceRect: sourceRect,
          destinationRect: destinationRect,
          sourcePixelSize: sourcePixelSize,
          destinationPixelSize: destinationPixelSize,
          quarterTurns: quarterTurns,
          paint: paint,
          includeSourcePixel: includeSourcePixel,
          destinationPixelClip: clip));
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

  ui.Picture? _picture;
  final List<({ui.Image image, ui.Offset offset})> _raster = [];
  final _visibleTiles = <(int, int), ui.Image>{};
  void Function(ui.Canvas, ui.Rect)? _tilePainter;
  GridSize? _tiledSize;
  int _tileEdge = 256;
  int _tileBudget = 0;
  int _tileBytes = 0;
  final QuarterTurnPixelDrawResult result;

  /// Number of source-mask predicate calls made during recording.
  ///
  /// Replaying the plan never increments this value.
  final int sourcePixelSampleCount;
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;
  bool get isTiled => _tiledSize != null;
  int get approximateBytesUsed => _tiledSize != null
      ? _tileBudget
      : _picture?.approximateBytesUsed ??
          _raster.fold(
              0, (sum, tile) => sum + tile.image.width * tile.image.height * 4);

  void rasterize(GridSize size, {int maxBytes = 32 * 1024 * 1024}) {
    final picture = _picture;
    if (picture == null) return;
    if (size.width * size.height * 4 > maxBytes) {
      _tiledSize = size;
      _tileBudget = maxBytes;
      _tileEdge = math.min(256, math.sqrt(maxBytes ~/ 4).floor());
      picture.dispose();
      _picture = null;
      return;
    }
    try {
      for (var top = 0; top < size.height; top += 1024) {
        for (var left = 0; left < size.width; left += 1024) {
          final width = math.min(1024, size.width - left);
          final height = math.min(1024, size.height - top);
          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder)
            ..translate(-left.toDouble(), -top.toDouble())
            ..drawPicture(picture);
          final tilePicture = recorder.endRecording();
          try {
            _raster.add((
              image: tilePicture.toImageSync(width, height),
              offset: ui.Offset(left.toDouble(), top.toDouble())
            ));
          } finally {
            tilePicture.dispose();
          }
        }
      }
    } catch (_) {
      for (final tile in _raster) {
        tile.image.dispose();
      }
      _raster.clear();
      rethrow;
    }
    picture.dispose();
    _picture = null;
  }

  void draw(ui.Canvas canvas) {
    if (_isDisposed) {
      throw StateError('QuarterTurnPixelDrawPlan is disposed.');
    }
    final picture = _picture;
    final tiledSize = _tiledSize;
    if (tiledSize != null) {
      final clip = canvas.getLocalClipBounds().intersect(ui.Rect.fromLTWH(
          0, 0, tiledSize.width.toDouble(), tiledSize.height.toDouble()));
      if (clip.isEmpty) return;
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
      for (var top = (clip.top.floor() ~/ _tileEdge) * _tileEdge;
          top < clip.bottom;
          top += _tileEdge) {
        for (var left = (clip.left.floor() ~/ _tileEdge) * _tileEdge;
            left < clip.right;
            left += _tileEdge) {
          final key = (left, top);
          var tile = _visibleTiles.remove(key);
          if (tile == null) {
            final width = math.min(_tileEdge, tiledSize.width - left);
            final height = math.min(_tileEdge, tiledSize.height - top);
            final needed = width * height * 4;
            while (
                _visibleTiles.isNotEmpty && _tileBytes + needed > _tileBudget) {
              final old = _visibleTiles.remove(_visibleTiles.keys.first)!;
              _tileBytes -= old.width * old.height * 4;
              old.dispose();
            }
            final recorder = ui.PictureRecorder();
            final tileCanvas = ui.Canvas(recorder)
              ..translate(-left.toDouble(), -top.toDouble());
            ui.Picture? tilePicture;
            try {
              _tilePainter!(
                  tileCanvas,
                  ui.Rect.fromLTWH(left.toDouble(), top.toDouble(),
                      width.toDouble(), height.toDouble()));
              tilePicture = recorder.endRecording();
              tile = tilePicture.toImageSync(width, height);
            } finally {
              (tilePicture ?? recorder.endRecording()).dispose();
            }
            _tileBytes += needed;
          }
          _visibleTiles[key] = tile;
          canvas.drawImage(
              tile, ui.Offset(left.toDouble(), top.toDouble()), paint);
        }
      }
    } else if (picture != null) {
      canvas.drawPicture(picture);
    } else {
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
      for (final tile in _raster) {
        canvas.drawImage(tile.image, tile.offset, paint);
      }
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _picture?.dispose();
    _picture = null;
    for (final tile in _raster) {
      tile.image.dispose();
    }
    _raster.clear();
    for (final tile in _visibleTiles.values) {
      tile.dispose();
    }
    _visibleTiles.clear();
    _tilePainter = null;
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
  ui.Rect? destinationPixelClip,
}) {
  final transform = QuarterTurnPixelTransform(
    sourcePixelSize: sourcePixelSize,
    destinationPixelSize: destinationPixelSize,
    quarterTurns: quarterTurns,
  );
  if (!image.containsSourceRect(sourceRect) ||
      destinationPixelClip?.isEmpty == true ||
      destinationRect.width <= 0 ||
      destinationRect.height <= 0) {
    return QuarterTurnPixelDrawResult.empty;
  }

  if (quarterTurns == 0 &&
      includeSourcePixel == null &&
      sourcePixelSize == destinationPixelSize) {
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
  if (isPurePixelRotation && destinationPixelClip == null) {
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

  final rotatedWidth =
      quarterTurns.isEven ? sourcePixelSize.width : sourcePixelSize.height;
  final rotatedHeight =
      quarterTurns.isEven ? sourcePixelSize.height : sourcePixelSize.width;
  final xs = _sampleBands(
      rotatedWidth,
      destinationPixelSize.width,
      quarterTurns == 1 || quarterTurns == 2,
      destinationPixelClip?.left.floor() ?? 0,
      destinationPixelClip?.right.ceil() ?? destinationPixelSize.width);
  final ys = _sampleBands(
      rotatedHeight,
      destinationPixelSize.height,
      quarterTurns == 2 || quarterTurns == 3,
      destinationPixelClip?.top.floor() ?? 0,
      destinationPixelClip?.bottom.ceil() ?? destinationPixelSize.height);
  for (final bandY in ys) {
    var previousDestinationPixelIncluded = false;
    GridPos? firstSource;
    GridPos? lastSource;
    var runStart = 0;
    var runEnd = 0;
    var bandWidth = 0;
    void flush() {
      final first = firstSource;
      final last = lastSource;
      if (first == null || last == null) return;
      final src = ui.Rect.fromLTWH(
          sourceRect.left + math.min(first.x, last.x) * sourcePixelWidth,
          sourceRect.top + math.min(first.y, last.y) * sourcePixelHeight,
          ((last.x - first.x).abs() + 1) * sourcePixelWidth,
          ((last.y - first.y).abs() + 1) * sourcePixelHeight);
      final dst = ui.Rect.fromLTWH(
          destinationRect.left + runStart * destinationPixelWidth,
          destinationRect.top + bandY.$1 * destinationPixelHeight,
          (runEnd - runStart) * destinationPixelWidth,
          (bandY.$2 - bandY.$1) * destinationPixelHeight);
      if (first == last) {
        image.drawImageRect(canvas, src, dst, paint);
      } else {
        _drawPureQuarterTurn(canvas,
            image: image,
            sourceRect: src,
            destinationRect: dst,
            quarterTurns: quarterTurns,
            paint: paint);
      }
      drawRunCount++;
      firstSource = null;
      lastSource = null;
    }

    for (final bandX in xs) {
      final source = transform.destinationPixelToSourcePixel(
        GridPos(x: bandX.$1, y: bandY.$1),
      );
      if (includeSourcePixel != null && !includeSourcePixel(source)) {
        flush();
        previousDestinationPixelIncluded = false;
        continue;
      }
      if (includeSourcePixel != null && !previousDestinationPixelIncluded) {
        includedDestinationRunCount += bandY.$2 - bandY.$1;
      }
      previousDestinationPixelIncluded = true;
      final destinationRunWidth = bandX.$2 - bandX.$1;
      final destinationRunHeight = bandY.$2 - bandY.$1;
      final last = lastSource;
      final contiguous = last != null &&
          switch (quarterTurns) {
            0 => source.x == last.x + 1 && source.y == last.y,
            1 => source.x == last.x && source.y == last.y - 1,
            2 => source.x == last.x - 1 && source.y == last.y,
            _ => source.x == last.x && source.y == last.y + 1,
          };
      if (!contiguous || destinationRunWidth != bandWidth) flush();
      if (firstSource == null) {
        firstSource = source;
        runStart = bandX.$1;
        bandWidth = destinationRunWidth;
      }
      lastSource = source;
      runEnd = bandX.$2;
      includedDestinationPixelCount +=
          destinationRunWidth * destinationRunHeight;
    }
    flush();
  }

  return QuarterTurnPixelDrawResult(
    drawRunCount: drawRunCount,
    includedDestinationPixelCount: includedDestinationPixelCount,
    includedDestinationRunCount:
        includeSourcePixel == null ? drawRunCount : includedDestinationRunCount,
  );
}

List<(int, int)> _sampleBands(
    int source, int destination, bool inverted, int start, int end) {
  if (source >= destination) {
    return [for (var i = start; i < end; i++) (i, i + 1)];
  }
  final transform = QuarterTurnPixelTransform(
    sourcePixelSize: GridSize(width: source, height: 1),
    destinationPixelSize: GridSize(width: destination, height: 1),
    quarterTurns: 0,
  );
  final sampleStart = inverted ? destination - end : start;
  final sampleEnd = inverted ? destination - start : end;
  final sourceStart = ((2 * sampleStart + 1) * source) ~/ (2 * destination);
  final sourceEnd = ((2 * (sampleEnd - 1) + 1) * source) ~/ (2 * destination);
  final bands = [
    for (var i = sourceStart; i <= sourceEnd; i++)
      (() {
        final rect = transform.sourcePixelRectToDestinationPixelRect(
            PixelRect(leftPx: i, topPx: 0, widthPx: 1, heightPx: 1));
        return inverted
            ? (
                destination - rect.leftPx - rect.widthPx,
                destination - rect.leftPx
              )
            : (rect.leftPx, rect.leftPx + rect.widthPx);
      })(),
  ];
  return inverted ? bands.reversed.toList(growable: false) : bands;
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
