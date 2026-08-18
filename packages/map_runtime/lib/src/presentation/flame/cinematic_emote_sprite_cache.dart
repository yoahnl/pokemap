import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

typedef CinematicEmoteImageLoader = Future<ui.Image> Function(String assetKey);

/// Découpe les emotes du catalogue depuis les atlas livrés avec le runtime.
///
/// Les atlas vivaient uniquement dans `map_editor`, où le Cinematic Studio les
/// prévisualise. Le runtime, lui, n'a jamais affiché que des glyphes texte : un
/// `!` là où l'auteur avait choisi un sprite. Les deux fichiers sont désormais
/// livrés ici aussi, sous le préfixe de package attendu par le bundle.
final class CinematicEmoteSpriteCache {
  CinematicEmoteSpriteCache({
    CinematicEmoteImageLoader? imageLoader,
  }) : _imageLoader = imageLoader ?? _loadImageFromAssetBundle;

  static const String _assetKeyPrefix = 'packages/map_runtime/';

  final CinematicEmoteImageLoader _imageLoader;
  final Map<String, Future<ui.Image>> _imageFutureByAtlasId =
      <String, Future<ui.Image>>{};
  final Map<String, Future<List<Sprite>>> _spriteFutureByEmoteId =
      <String, Future<List<Sprite>>>{};

  /// Clé de bundle du runtime pour un atlas du catalogue.
  ///
  /// Le catalogue de `map_core` porte le chemin tel que l'éditeur le résout ;
  /// le runtime le lit depuis son propre package et doit donc préfixer.
  static String runtimeAssetKeyFor(CinematicEmoteAtlas atlas) =>
      '$_assetKeyPrefix${atlas.assetKey}';

  /// Images de l'emote, dans l'ordre de lecture.
  ///
  /// Retourne une liste vide quand l'emote est inconnue ou qu'un de ses cadres
  /// déborde de l'atlas : un emote mal authoré ne doit pas faire tomber la
  /// carte. La liste compte deux images pour les emotes animées, une sinon.
  Future<List<Sprite>> loadEmoteFrames(String? emoteId) async {
    final entry = cinematicEmoteCatalogEntryById(emoteId);
    if (entry == null) {
      return const <Sprite>[];
    }
    final atlas = cinematicEmoteAtlasById(entry.atlasId);
    if (atlas == null ||
        entry.frames.any((frame) => !frame.fitsInside(atlas))) {
      return const <Sprite>[];
    }

    final cached = _spriteFutureByEmoteId[entry.id];
    if (cached != null) {
      return await cached;
    }

    final future = () async {
      final image = await _loadAtlasImage(atlas);
      return <Sprite>[
        for (final frame in entry.frames)
          Sprite(
            image,
            srcPosition: Vector2(frame.x.toDouble(), frame.y.toDouble()),
            srcSize: Vector2(frame.width.toDouble(), frame.height.toDouble()),
          ),
      ];
    }();
    _spriteFutureByEmoteId[entry.id] = future;
    try {
      return await future;
    } catch (_) {
      final current = _spriteFutureByEmoteId[entry.id];
      if (identical(current, future)) {
        _spriteFutureByEmoteId.remove(entry.id);
      }
      rethrow;
    }
  }

  Future<ui.Image> _loadAtlasImage(CinematicEmoteAtlas atlas) async {
    final cached = _imageFutureByAtlasId[atlas.id];
    if (cached != null) {
      return await cached;
    }
    final future = _imageLoader(runtimeAssetKeyFor(atlas));
    _imageFutureByAtlasId[atlas.id] = future;
    try {
      return await future;
    } catch (_) {
      final current = _imageFutureByAtlasId[atlas.id];
      if (identical(current, future)) {
        _imageFutureByAtlasId.remove(atlas.id);
      }
      rethrow;
    }
  }
}

Future<ui.Image> _loadImageFromAssetBundle(String assetKey) async {
  final data = await rootBundle.load(assetKey);
  final bytes = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}
