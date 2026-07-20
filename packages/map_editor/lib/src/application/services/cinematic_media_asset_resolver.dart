import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

typedef CinematicMediaFileExists = Future<bool> Function(String absolutePath);

final class CinematicResolvedMediaAsset {
  const CinematicResolvedMediaAsset({
    required this.asset,
    required this.resolution,
    this.absolutePath,
  });

  final CinematicMediaAsset asset;
  final CinematicMediaPathResolution resolution;
  final String? absolutePath;
}

/// Resolves project-owned media without accepting a free absolute path.
final class CinematicMediaAssetResolver {
  CinematicMediaAssetResolver({
    required String projectRoot,
    CinematicMediaFileExists? fileExists,
  })  : projectRoot = p.normalize(p.absolute(projectRoot)),
        _fileExists = fileExists ?? ((path) => File(path).exists());

  final String projectRoot;
  final CinematicMediaFileExists _fileExists;

  Future<Map<String, CinematicResolvedMediaAsset>> resolve(
    Iterable<CinematicMediaAsset> assets,
  ) async {
    final result = <String, CinematicResolvedMediaAsset>{};
    for (final asset in assets) {
      final relative = p.normalize(asset.relativePath);
      final absolute = p.normalize(p.join(projectRoot, relative));
      final insideRoot = p.isWithin(projectRoot, absolute);
      if (p.isAbsolute(asset.relativePath) || !insideRoot) {
        result[asset.id] = CinematicResolvedMediaAsset(
          asset: asset,
          resolution: CinematicMediaPathResolution.forbidden,
        );
        continue;
      }
      result[asset.id] = CinematicResolvedMediaAsset(
        asset: asset,
        absolutePath: absolute,
        resolution: await _fileExists(absolute)
            ? CinematicMediaPathResolution.present
            : CinematicMediaPathResolution.missing,
      );
    }
    return Map.unmodifiable(result);
  }
}
