import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_ui_image.dart';

typedef BattleVisualImageLoader = Future<ui.Image> Function(
  String absolutePath,
);

final class BattleVisualAssetCache {
  BattleVisualAssetCache({
    BattleVisualImageLoader? imageLoader,
    int capacity = 96,
    RuntimeResourceBudget? resourceBudget,
    bool Function()? isCurrent,
  }) : resourceBudget = resourceBudget ?? RuntimeResourceBudget(),
       _ownsResourceBudget = resourceBudget == null,
       _capacity = capacity {
    _images = RuntimeOwnedImageCache(
      capacity: capacity,
      imageLoader: imageLoader,
      loadLease: (path) => loadRuntimeUiImageFromFilePath(
        path,
        resourceBudget: this.resourceBudget,
        isCurrent: isCurrent,
      ),
    );
  }

  final RuntimeResourceBudget resourceBudget;
  final bool _ownsResourceBudget;
  late final RuntimeOwnedImageCache _images;

  Object beginScope() => _images.beginScope();

  void endScope(Object scope) {
    _images.endScope(scope);
    _opaqueRectFutureByPath.clear();
  }

  final int _capacity;
  final Map<String, Future<ui.Rect?>> _opaqueRectFutureByPath =
      <String, Future<ui.Rect?>>{};
  int _actualOpaqueRectComputeCount = 0;

  int get debugActualImageLoadCount => _images.actualLoadCount;

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

    Future<ui.Image> load() async {
      final stopwatch = Stopwatch()..start();
      try {
        return await _images.load(normalizedPath);
      } finally {
        stopwatch.stop();
        if (kDebugMode) {
          debugPrint(
            '[perf][battle][real] imageLoad path=$normalizedPath total=${stopwatch.elapsedMilliseconds}ms',
          );
        }
      }
    }

    return load();
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
      final scope = _images.beginScope();
      _images.retain(normalizedPath);
      final stopwatch = Stopwatch()..start();
      _actualOpaqueRectComputeCount += 1;
      try {
        final resolvedImage = image ?? await loadImage(normalizedPath);
        final reservation = await resourceBudget.acquire(
          residentBytes: resolvedImage.width * resolvedImage.height * 4,
          transientBytes: resolvedImage.width * resolvedImage.height * 8,
          isCurrent: () => !_images.isDisposed,
        );
        ui.Image? readbackImage;
        try {
          reservation.ensureCurrent();
          readbackImage = resolvedImage.clone();
          return await _computeOpaqueSourceRect(readbackImage);
        } finally {
          readbackImage?.dispose();
          reservation.release();
        }
      } finally {
        _images.endScope(scope, trim: false);
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
    await loadOpaqueSourceRect(absolutePath, image: image);
  }

  /// Libère toutes les images décodées puis vide le cache.
  ///
  /// À n'appeler que quand plus rien ne peint depuis ce cache — typiquement
  /// au teardown du jeu propriétaire.
  void dispose() {
    _images.dispose();
    _opaqueRectFutureByPath.clear();
    if (_ownsResourceBudget) resourceBudget.dispose();
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
