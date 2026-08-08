import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../infrastructure/runtime_tileset_image.dart';
import '../infrastructure/tile_image_loader.dart';
import 'border_runtime_asset_collection.dart';

typedef BorderRuntimeImageLoader = Future<RuntimeTilesetImage> Function(
  String absolutePath, {
  TilesetTransparentColor? transparentColor,
});

/// One loaded frame retaining its persisted source rectangle and timing.
@immutable
final class BorderRuntimeLoadedFrame {
  const BorderRuntimeLoadedFrame({
    required this.request,
    required this.image,
  });

  final BorderRuntimeFrameRequest request;
  final RuntimeTilesetImage image;
}

/// Every ordered frame loaded for one immutable snapshot.
@immutable
final class BorderRuntimeLoadedSnapshot {
  factory BorderRuntimeLoadedSnapshot({
    required String snapshotId,
    required List<BorderRuntimeLoadedFrame> frames,
  }) {
    final ownedFrames = List<BorderRuntimeLoadedFrame>.unmodifiable(frames);
    if (ownedFrames.isEmpty) {
      throw ArgumentError.value(frames, 'frames', 'must not be empty');
    }
    var totalDurationMs = 0;
    for (final frame in ownedFrames) {
      if (frame.request.durationMs <= 0) {
        throw AssetNotFoundException(
          'Border snapshot has a non-positive frame duration: '
          '$snapshotId frame ${frame.request.frameIndex}',
        );
      }
      totalDurationMs += frame.request.durationMs;
    }
    return BorderRuntimeLoadedSnapshot._(
      snapshotId: snapshotId,
      frames: ownedFrames,
      totalDurationMs: totalDurationMs,
    );
  }

  const BorderRuntimeLoadedSnapshot._({
    required this.snapshotId,
    required this.frames,
    required this.totalDurationMs,
  });

  final String snapshotId;
  final List<BorderRuntimeLoadedFrame> frames;

  /// Sum of every frame duration, validated and computed once at load time
  /// instead of per rendered instruction per frame.
  final int totalDurationMs;
}

/// Loaded immutable Border visuals indexed by snapshot identity.
@immutable
final class BorderRuntimeAssetBundle {
  BorderRuntimeAssetBundle({
    required List<BorderRuntimeLoadedSnapshot> snapshots,
  }) : _snapshotById = <String, BorderRuntimeLoadedSnapshot>{
          for (final snapshot in snapshots) snapshot.snapshotId: snapshot,
        } {
    if (_snapshotById.length != snapshots.length) {
      throw ArgumentError.value(
        snapshots,
        'snapshots',
        'must not contain duplicate snapshot ids',
      );
    }
  }

  final Map<String, BorderRuntimeLoadedSnapshot> _snapshotById;

  BorderRuntimeLoadedSnapshot snapshotById(String snapshotId) {
    final snapshot = _snapshotById[snapshotId];
    if (snapshot == null) {
      throw AssetNotFoundException(
        'Border visual snapshot was not loaded: $snapshotId',
      );
    }
    return snapshot;
  }
}

/// Concurrency-safe cache for immutable Border frame files.
///
/// The cache key is the normalized absolute path plus the effective low-24
/// RGB transparency key. Failed futures are evicted so an explicit retry can
/// observe a restored file.
final class BorderRuntimeAssetCache {
  BorderRuntimeAssetCache({BorderRuntimeImageLoader? imageLoader})
      : _imageLoader = imageLoader ?? _loadRuntimeImage;

  final BorderRuntimeImageLoader _imageLoader;
  final Map<_BorderRuntimeImageCacheKey, Future<RuntimeTilesetImage>>
      _imageFutureByKey =
      <_BorderRuntimeImageCacheKey, Future<RuntimeTilesetImage>>{};

  Future<RuntimeTilesetImage> loadFrame({
    required String projectRoot,
    required BorderRuntimeFrameRequest frame,
  }) async {
    final absolutePath = p.normalize(
      p.absolute(p.join(projectRoot, frame.relativeAssetPath)),
    );
    final key = _BorderRuntimeImageCacheKey(
      absolutePath: absolutePath,
      transparentRgb: frame.effectiveTransparentRgb,
    );
    final cached = _imageFutureByKey[key];
    if (cached != null) {
      return cached;
    }

    final future = _imageLoader(
      absolutePath,
      transparentColor: _transparentColor(frame.effectiveTransparentRgb),
    );
    _imageFutureByKey[key] = future;
    try {
      return await future;
    } catch (_) {
      if (identical(_imageFutureByKey[key], future)) {
        _imageFutureByKey.remove(key);
      }
      rethrow;
    }
  }

  Future<BorderRuntimeAssetBundle> loadCollection({
    required String projectRoot,
    required BorderRuntimeAssetCollection collection,
  }) async {
    // Décodages concurrents : le cache single-flight dédupe déjà les chemins
    // partagés, la latence passe de la somme des décodages au plus lent.
    final loadedSnapshots = await Future.wait(
      collection.snapshots.map((snapshot) async {
        final loadedFrames = await Future.wait(
          snapshot.frames.map(
            (frame) async => BorderRuntimeLoadedFrame(
              request: frame,
              image: await loadFrame(projectRoot: projectRoot, frame: frame),
            ),
          ),
        );
        return BorderRuntimeLoadedSnapshot(
          snapshotId: snapshot.snapshotId,
          frames: loadedFrames,
        );
      }),
    );
    return BorderRuntimeAssetBundle(snapshots: loadedSnapshots);
  }
}

Future<RuntimeTilesetImage> _loadRuntimeImage(
  String absolutePath, {
  TilesetTransparentColor? transparentColor,
}) {
  return loadTilesetImageFromFilePath(
    absolutePath,
    transparentColor: transparentColor,
  );
}

TilesetTransparentColor? _transparentColor(int? rgb) {
  if (rgb == null) {
    return null;
  }
  return TilesetTransparentColor(
    red: (rgb >> 16) & 0xff,
    green: (rgb >> 8) & 0xff,
    blue: rgb & 0xff,
  );
}

@immutable
final class _BorderRuntimeImageCacheKey {
  const _BorderRuntimeImageCacheKey({
    required this.absolutePath,
    required this.transparentRgb,
  });

  final String absolutePath;
  final int? transparentRgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BorderRuntimeImageCacheKey &&
          absolutePath == other.absolutePath &&
          transparentRgb == other.transparentRgb;

  @override
  int get hashCode => Object.hash(absolutePath, transparentRgb);
}
