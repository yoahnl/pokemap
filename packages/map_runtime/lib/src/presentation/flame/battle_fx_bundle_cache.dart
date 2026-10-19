import 'dart:ui' as ui;

import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_ui_image.dart';

import 'battle_fx_catalog.dart';

typedef BattleFxImageLoader = Future<ui.Image> Function(String assetKey);

final class BattleFxBundleCache {
  BattleFxBundleCache({
    BattleFxImageLoader? imageLoader,
    RuntimeResourceBudget? resourceBudget,
    bool Function()? isCurrent,
  }) : resourceBudget = resourceBudget ?? RuntimeResourceBudget(),
       _ownsResourceBudget = resourceBudget == null {
    _images = RuntimeOwnedImageCache(
      imageLoader: imageLoader,
      loadLease: (key) =>
          _loadImageFromAssetBundle(key, this.resourceBudget, isCurrent),
    );
  }

  final RuntimeResourceBudget resourceBudget;
  final bool _ownsResourceBudget;
  late final RuntimeOwnedImageCache _images;

  /// BETA-BAT-018 : le nombre d'images déjà demandées au cache — la preuve
  /// observable qu'une préchauffe a bien eu lieu avant le premier coup.
  int get debugCachedImageCount => _images.length;

  Object beginScope() => _images.beginScope();

  void endScope(Object scope) {
    _images.endScope(scope);
  }

  void updateScope(
    Object scope, {
    required Iterable<String> effectIds,
    Iterable<ui.Image> liveImages = const [],
  }) {
    _images.updateScope(
      scope,
      keys: effectIds.map((id) => BattleFxCatalog.require(id).assetKey),
      liveImages: liveImages,
    );
  }

  Future<ui.Image> loadImage(String effectId) async {
    final normalizedEffectId = effectId.trim();
    final spec = BattleFxCatalog.require(normalizedEffectId);
    return _images.load(spec.assetKey);
  }

  Future<Sprite> loadSprite(String effectId) async {
    return Sprite(await loadImage(effectId));
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
    _images.trimUnused();
  }

  void dispose() {
    _images.dispose();
    if (_ownsResourceBudget) resourceBudget.dispose();
  }
}

Future<RuntimeUiImageLease> _loadImageFromAssetBundle(
  String assetKey,
  RuntimeResourceBudget resourceBudget,
  bool Function()? isCurrent,
) async {
  final data = await rootBundle.load(assetKey);
  final bytes = _asUint8List(data);
  return decodeRuntimeUiImage(
    bytes,
    resourceBudget: resourceBudget,
    isCurrent: isCurrent,
  );
}

Uint8List _asUint8List(ByteData data) {
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
