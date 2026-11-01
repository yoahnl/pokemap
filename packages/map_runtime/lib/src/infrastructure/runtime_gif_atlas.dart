import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'runtime_gif_animation.dart';

typedef RuntimeGifAtlasRasterizer = Future<ui.Image> Function(
  ui.Picture picture,
  int width,
  int height,
);

final class RuntimeGifAtlas {
  RuntimeGifAtlas._({
    required this.image,
    required this.timeline,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this._reservation,
  });

  final ui.Image image;
  final RuntimeGifTimeline timeline;
  final int frameWidth;
  final int frameHeight;
  final int columns;
  final RuntimeResourceReservation _reservation;
  bool _disposed = false;

  ui.Rect sourceAt(Duration elapsed) {
    if (_disposed) throw StateError('GIF atlas is disposed');
    final index = timeline.frameIndexAt(elapsed);
    return ui.Rect.fromLTWH(
      ((index % columns) * (frameWidth + 2) + 1).toDouble(),
      ((index ~/ columns) * (frameHeight + 2) + 1).toDouble(),
      frameWidth.toDouble(),
      frameHeight.toDouble(),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      image.dispose();
    } finally {
      _reservation.release();
    }
  }
}

Future<RuntimeGifAtlas?> buildRuntimeGifAtlas(
  RuntimeGifAnimation animation, {
  int maximumDimension = 2048,
  bool Function()? isCurrent,
  RuntimeGifAtlasRasterizer? rasterizer,
}) async {
  if (maximumDimension < 1 || maximumDimension > 4096) {
    throw ArgumentError.value(maximumDimension, 'maximumDimension');
  }
  final first = animation.frameByIndex(0);
  final frameWidth = first.width, frameHeight = first.height;
  final cellWidth = frameWidth + 2, cellHeight = frameHeight + 2;
  final maxColumns = maximumDimension ~/ cellWidth;
  final maxRows = maximumDimension ~/ cellHeight;
  if (maxColumns < 1 ||
      maxRows < 1 ||
      animation.frameCount > maxColumns * maxRows) {
    return null;
  }
  final minColumns = (animation.frameCount + maxRows - 1) ~/ maxRows;
  final limit = math.min(maxColumns, animation.frameCount);
  var columns = minColumns;
  var bestCells = 0x7fffffff;
  var bestSide = 0x7fffffff;
  for (var candidate = minColumns; candidate <= limit; candidate++) {
    final candidateRows = (animation.frameCount + candidate - 1) ~/ candidate;
    final cells = candidate * candidateRows;
    final side = math.max(candidate * cellWidth, candidateRows * cellHeight);
    if (cells < bestCells ||
        (cells == bestCells && side < bestSide) ||
        (cells == bestCells && side == bestSide && candidate > columns)) {
      columns = candidate;
      bestCells = cells;
      bestSide = side;
    }
  }
  final rows = (animation.frameCount + columns - 1) ~/ columns;
  final width = columns * cellWidth, height = rows * cellHeight;
  final budget = animation.resourceBudget;
  int rgba;
  try {
    rgba = runtimeImageRgbaByteLength(
      width,
      height,
      maximumBytes: budget.profile.maximumResidentBytes,
    );
  } on RuntimeResourceAdmissionException {
    return null;
  }
  RuntimeResourceReservation? reservation;
  ui.Image? image;
  ui.Picture? picture;
  final clones = <ui.Image>[];
  var transferred = false;
  try {
    reservation = await budget.acquire(
      residentBytes: rgba,
      transientBytes: rgba * 2,
      isCurrent: () => !animation.isDisposed && (isCurrent?.call() ?? true),
    );
    for (var i = 0; i < animation.frameCount; i++) {
      reservation.ensureCurrent();
      clones.add(animation.frameByIndex(i).clone());
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
    for (var i = 0; i < clones.length; i++) {
      final x = ((i % columns) * cellWidth + 1).toDouble();
      final y = ((i ~/ columns) * cellHeight + 1).toDouble();
      _drawPaddedFrame(canvas, clones[i], x, y, paint);
    }
    picture = recorder.endRecording();
    try {
      image = await (rasterizer ?? _rasterize)(picture, width, height);
    } catch (_) {
      reservation.ensureCurrent();
      return null;
    }
    reservation.ensureCurrent();
    if (image.width != width || image.height != height) return null;
    reservation.commit();
    final result = RuntimeGifAtlas._(
      image: image,
      timeline: animation.timeline,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      columns: columns,
      reservation: reservation,
    );
    transferred = true;
    return result;
  } on RuntimeResourceAdmissionException catch (error) {
    if (error.reason.contains('cancel') || error.reason == 'session_closed') {
      rethrow;
    }
    return null;
  } finally {
    picture?.dispose();
    for (final clone in clones) {
      clone.dispose();
    }
    if (!transferred) {
      image?.dispose();
      reservation?.release();
    }
  }
}

Future<ui.Image> _rasterize(ui.Picture picture, int width, int height) =>
    picture.toImage(width, height);

void _drawPaddedFrame(
  ui.Canvas canvas,
  ui.Image image,
  double x,
  double y,
  ui.Paint paint,
) {
  final width = image.width.toDouble(), height = image.height.toDouble();
  canvas.drawImage(image, ui.Offset(x, y), paint);
  for (final (sx, sy, sw, sh, dx, dy) in [
    (0.0, 0.0, 1.0, height, x - 1, y),
    (width - 1, 0.0, 1.0, height, x + width, y),
    (0.0, 0.0, width, 1.0, x, y - 1),
    (0.0, height - 1, width, 1.0, x, y + height),
    (0.0, 0.0, 1.0, 1.0, x - 1, y - 1),
    (width - 1, 0.0, 1.0, 1.0, x + width, y - 1),
    (0.0, height - 1, 1.0, 1.0, x - 1, y + height),
    (width - 1, height - 1, 1.0, 1.0, x + width, y + height),
  ]) {
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(sx, sy, sw, sh),
      ui.Rect.fromLTWH(dx, dy, sw, sh),
      paint,
    );
  }
}
