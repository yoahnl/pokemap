import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../infrastructure/tile_image_loader.dart';

typedef BattleVisualImageLoader = Future<ui.Image> Function(String absolutePath);

final class BattleVisualAssetCache {
  BattleVisualAssetCache({
    BattleVisualImageLoader? imageLoader,
  }) : _imageLoader = imageLoader ?? loadImageFromFilePath;

  final BattleVisualImageLoader _imageLoader;
  final Map<String, Future<ui.Image>> _imageFutureByPath =
      <String, Future<ui.Image>>{};
  final Map<String, Future<ui.Rect?>> _opaqueRectFutureByPath =
      <String, Future<ui.Rect?>>{};
  int _actualImageLoadCount = 0;
  int _actualOpaqueRectComputeCount = 0;

  int get debugActualImageLoadCount => _actualImageLoadCount;

  int get debugActualOpaqueRectComputeCount => _actualOpaqueRectComputeCount;

  Future<ui.Image> loadImage(String absolutePath) async {
    final normalizedPath = absolutePath.trim();
    if (normalizedPath.isEmpty) {
      throw ArgumentError.value(
        absolutePath,
        'absolutePath',
        'must not be empty',
      );
    }

    final cached = _imageFutureByPath[normalizedPath];
    if (cached != null) {
      return await cached;
    }

    Future<ui.Image> load() async {
      final stopwatch = Stopwatch()..start();
      _actualImageLoadCount += 1;
      try {
        return await _imageLoader(normalizedPath);
      } finally {
        stopwatch.stop();
        debugPrint(
          '[perf][battle][real] imageLoad path=$normalizedPath total=${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }

    final future = load();
    _imageFutureByPath[normalizedPath] = future;
    try {
      return await future;
    } catch (_) {
      final current = _imageFutureByPath[normalizedPath];
      if (identical(current, future)) {
        _imageFutureByPath.remove(normalizedPath);
      }
      rethrow;
    }
  }

  Future<ui.Rect?> loadOpaqueSourceRect(
    String absolutePath, {
    ui.Image? image,
  }) async {
    final normalizedPath = absolutePath.trim();
    if (normalizedPath.isEmpty) {
      return null;
    }

    final cached = _opaqueRectFutureByPath[normalizedPath];
    if (cached != null) {
      return await cached;
    }

    Future<ui.Rect?> compute() async {
      final stopwatch = Stopwatch()..start();
      _actualOpaqueRectComputeCount += 1;
      try {
        final resolvedImage = image ?? await loadImage(normalizedPath);
        return await _computeOpaqueSourceRect(resolvedImage);
      } finally {
        stopwatch.stop();
        debugPrint(
          '[perf][battle][real] opaqueRect path=$normalizedPath total=${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }

    final future = compute();
    _opaqueRectFutureByPath[normalizedPath] = future;
    try {
      return await future;
    } catch (_) {
      final current = _opaqueRectFutureByPath[normalizedPath];
      if (identical(current, future)) {
        _opaqueRectFutureByPath.remove(normalizedPath);
      }
      rethrow;
    }
  }

  Future<void> prewarmImage(String absolutePath) async {
    await loadImage(absolutePath);
  }

  Future<void> prewarmSprite(String absolutePath) async {
    final image = await loadImage(absolutePath);
    await loadOpaqueSourceRect(
      absolutePath,
      image: image,
    );
  }
}

Future<ui.Rect?> _computeOpaqueSourceRect(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return null;
  }
  final rgba = byteData.buffer.asUint8List();
  final width = image.width;
  final height = image.height;
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = rgba[((y * width) + x) * 4 + 3];
      if (alpha == 0) {
        continue;
      }
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }
  }
  if (maxX < minX || maxY < minY) {
    return null;
  }
  return ui.Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    (maxX + 1).toDouble(),
    (maxY + 1).toDouble(),
  );
}
