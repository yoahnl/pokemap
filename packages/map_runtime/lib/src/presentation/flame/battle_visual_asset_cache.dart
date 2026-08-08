import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../infrastructure/tile_image_loader.dart';

typedef BattleVisualImageLoader = Future<ui.Image> Function(String absolutePath);

final class BattleVisualAssetCache {
  BattleVisualAssetCache({
    BattleVisualImageLoader? imageLoader,
    int capacity = 96,
  })  : _imageLoader = imageLoader ?? loadImageFromFilePath,
        _capacity = capacity;

  final BattleVisualImageLoader _imageLoader;

  /// Borne LRU : ce cache vit toute la session de jeu et retenait chaque
  /// sprite/backdrop/icône jamais vus. L'éviction se contente de lâcher la
  /// référence — une image évincée peut encore être affichée par un
  /// composant vivant, c'est donc le GC qui libère le natif ; la libération
  /// déterministe passe par [dispose] au teardown.
  final int _capacity;
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

    final cached = _imageFutureByPath.remove(normalizedPath);
    if (cached != null) {
      _imageFutureByPath[normalizedPath] = cached;
      return await cached;
    }

    Future<ui.Image> load() async {
      final stopwatch = Stopwatch()..start();
      _actualImageLoadCount += 1;
      try {
        return await _imageLoader(normalizedPath);
      } finally {
        stopwatch.stop();
        if (kDebugMode) {
          debugPrint(
            '[perf][battle][real] imageLoad path=$normalizedPath total=${stopwatch.elapsedMilliseconds}ms',
          );
        }
      }
    }

    final future = load();
    _imageFutureByPath[normalizedPath] = future;
    while (_imageFutureByPath.length > _capacity) {
      _imageFutureByPath.remove(_imageFutureByPath.keys.first);
    }
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

    final cached = _opaqueRectFutureByPath.remove(normalizedPath);
    if (cached != null) {
      _opaqueRectFutureByPath[normalizedPath] = cached;
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
        if (kDebugMode) {
          debugPrint(
            '[perf][battle][real] opaqueRect path=$normalizedPath total=${stopwatch.elapsedMilliseconds}ms',
          );
        }
      }
    }

    final future = compute();
    _opaqueRectFutureByPath[normalizedPath] = future;
    while (_opaqueRectFutureByPath.length > _capacity) {
      _opaqueRectFutureByPath.remove(_opaqueRectFutureByPath.keys.first);
    }
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

  /// Libère toutes les images décodées puis vide le cache.
  ///
  /// À n'appeler que quand plus rien ne peint depuis ce cache — typiquement
  /// au teardown du jeu propriétaire.
  void dispose() {
    for (final future in _imageFutureByPath.values) {
      unawaited(
        future.then((image) => image.dispose()).catchError((_) {}),
      );
    }
    _imageFutureByPath.clear();
    _opaqueRectFutureByPath.clear();
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
  // Le readback doit rester sur l'isolate UI, mais le balayage O(largeur ×
  // hauteur) part en isolate pour les grandes images (backdrops) : il tombait
  // pile pendant la transition d'entrée en combat.
  const inlinePixelBudget = 256 * 256;
  final bounds = width * height <= inlinePixelBudget
      ? _opaqueBoundsFromRgba(rgba, width, height)
      : await Isolate.run(() => _opaqueBoundsFromRgba(rgba, width, height));
  if (bounds == null) {
    return null;
  }
  return ui.Rect.fromLTRB(
    bounds.minX.toDouble(),
    bounds.minY.toDouble(),
    (bounds.maxX + 1).toDouble(),
    (bounds.maxY + 1).toDouble(),
  );
}

({int minX, int minY, int maxX, int maxY})? _opaqueBoundsFromRgba(
  Uint8List rgba,
  int width,
  int height,
) {
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
  return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
}
