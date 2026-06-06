import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import '../../../application/services/tileset_transparent_color_processor.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';

final class CinematicTilesetAssetRegistry {
  CinematicTilesetAssetRegistry();

  final Map<String, Future<CinematicResolvedTilesetAsset>> _cache = {};

  Future<CinematicResolvedTilesetAsset> resolve({
    required ProjectTilesetEntry? tileset,
    required String? absolutePath,
    required int tileWidth,
    required int tileHeight,
  }) {
    final tilesetId = tileset?.id.trim() ?? '';
    if (tileset == null || tilesetId.isEmpty) {
      return Future.value(
        CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.missingTilesetEntry,
          message: 'Entrée tileset absente du manifeste.',
        ),
      );
    }
    if (tileWidth <= 0 || tileHeight <= 0) {
      return Future.value(
        CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.invalidTileSize,
          message: 'Taille de tuile invalide pour le tileset $tilesetId.',
        ),
      );
    }
    final path = absolutePath?.trim();
    if (path == null || path.isEmpty) {
      return Future.value(
        CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.missingFile,
          message: 'Image de tileset introuvable pour $tilesetId.',
        ),
      );
    }

    final key =
        '$tilesetId|$path|$tileWidth|$tileHeight|${tileset.transparentColor?.toHexRgb() ?? ''}';
    return _cache.putIfAbsent(
      key,
      () => _load(
        tileset: tileset,
        absolutePath: path,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
    );
  }

  void invalidateTileset(String tilesetId) {
    final prefix = '${tilesetId.trim()}|';
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() {
    _cache.clear();
  }

  Future<CinematicResolvedTilesetAsset> _load({
    required ProjectTilesetEntry tileset,
    required String absolutePath,
    required int tileWidth,
    required int tileHeight,
  }) async {
    final tilesetId = tileset.id.trim();
    try {
      final file = File(absolutePath);
      if (!await file.exists()) {
        return CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.missingFile,
          message: 'Image de tileset introuvable pour $tilesetId.',
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.emptyImage,
          message: 'Image de tileset vide pour $tilesetId.',
        );
      }
      var displayBytes = bytes;
      final transparentColor = tileset.transparentColor;
      if (transparentColor != null) {
        try {
          displayBytes = applyTilesetTransparentColorToPngBytes(
            imageBytes: bytes,
            transparentColor: transparentColor,
          );
        } catch (_) {
          displayBytes = bytes;
        }
      }
      final codec = await ui.instantiateImageCodec(displayBytes);
      final frame = await codec.getNextFrame();
      return CinematicResolvedTilesetAsset.available(
        tilesetId: tilesetId,
        image: frame.image,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      );
    } catch (_) {
      return CinematicResolvedTilesetAsset.diagnostic(
        tilesetId: tilesetId,
        status: CinematicResolvedTilesetAssetStatus.decodeFailed,
        message: 'Image de tileset illisible pour $tilesetId.',
      );
    }
  }
}
