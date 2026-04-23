import 'dart:ui' as ui;

import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

import 'battle_fx_catalog.dart';

typedef BattleFxImageLoader = Future<ui.Image> Function(String assetKey);

final class BattleFxBundleCache {
  BattleFxBundleCache({
    BattleFxImageLoader? imageLoader,
  }) : _imageLoader = imageLoader ?? _loadImageFromAssetBundle;

  final BattleFxImageLoader _imageLoader;
  final Map<String, Future<ui.Image>> _imageFutureByEffectId =
      <String, Future<ui.Image>>{};
  final Map<String, Future<Sprite>> _spriteFutureByEffectId =
      <String, Future<Sprite>>{};

  Future<ui.Image> loadImage(String effectId) async {
    final normalizedEffectId = effectId.trim();
    final spec = BattleFxCatalog.require(normalizedEffectId);
    final cached = _imageFutureByEffectId[normalizedEffectId];
    if (cached != null) {
      return await cached;
    }

    final future = _imageLoader(spec.assetKey);
    _imageFutureByEffectId[normalizedEffectId] = future;
    try {
      return await future;
    } catch (_) {
      final current = _imageFutureByEffectId[normalizedEffectId];
      if (identical(current, future)) {
        _imageFutureByEffectId.remove(normalizedEffectId);
      }
      rethrow;
    }
  }

  Future<Sprite> loadSprite(String effectId) async {
    final normalizedEffectId = effectId.trim();
    BattleFxCatalog.require(normalizedEffectId);
    final cached = _spriteFutureByEffectId[normalizedEffectId];
    if (cached != null) {
      return await cached;
    }

    final future = () async {
      final image = await loadImage(normalizedEffectId);
      return Sprite(image);
    }();
    _spriteFutureByEffectId[normalizedEffectId] = future;
    try {
      return await future;
    } catch (_) {
      final current = _spriteFutureByEffectId[normalizedEffectId];
      if (identical(current, future)) {
        _spriteFutureByEffectId.remove(normalizedEffectId);
      }
      rethrow;
    }
  }

  Future<void> prewarm(Iterable<String> effectIds) async {
    final uniqueIds = <String>{};
    for (final effectId in effectIds) {
      final normalizedEffectId = effectId.trim();
      if (normalizedEffectId.isEmpty || !uniqueIds.add(normalizedEffectId)) {
        continue;
      }
      await loadImage(normalizedEffectId);
    }
  }

  void clear() {
    _imageFutureByEffectId.clear();
    _spriteFutureByEffectId.clear();
  }
}

Future<ui.Image> _loadImageFromAssetBundle(String assetKey) async {
  final data = await rootBundle.load(assetKey);
  final bytes = _asUint8List(data);
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

Uint8List _asUint8List(ByteData data) {
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
