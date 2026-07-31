import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

enum SmartTileAtlasImageLoadStatus {
  loaded,
  missingProjectRoot,
  outsideProject,
  missingFile,
  invalidImage,
}

final class SmartTileAtlasImage {
  const SmartTileAtlasImage({
    required this.absolutePath,
    required this.bytes,
    required this.width,
    required this.height,
    required this.columnAlphaCoverage,
    required this.rowAlphaCoverage,
  });

  final String absolutePath;
  final Uint8List bytes;
  final int width;
  final int height;
  final List<double> columnAlphaCoverage;
  final List<double> rowAlphaCoverage;
}

final class SmartTileAtlasImageLoadResult {
  const SmartTileAtlasImageLoadResult({
    required this.status,
    required this.message,
    this.image,
  });

  final SmartTileAtlasImageLoadStatus status;
  final String message;
  final SmartTileAtlasImage? image;

  bool get isLoaded =>
      status == SmartTileAtlasImageLoadStatus.loaded && image != null;
}

abstract interface class SmartTileAtlasImageLoader {
  Future<SmartTileAtlasImageLoadResult> load({
    required String? projectRootPath,
    required ProjectTilesetEntry tileset,
  });
}

final class FileSmartTileAtlasImageLoader implements SmartTileAtlasImageLoader {
  const FileSmartTileAtlasImageLoader();

  @override
  Future<SmartTileAtlasImageLoadResult> load({
    required String? projectRootPath,
    required ProjectTilesetEntry tileset,
  }) async {
    final root = projectRootPath?.trim();
    if (root == null || root.isEmpty) {
      return const SmartTileAtlasImageLoadResult(
        status: SmartTileAtlasImageLoadStatus.missingProjectRoot,
        message: 'Racine du projet indisponible.',
      );
    }

    final normalizedRoot = p.normalize(p.absolute(root));
    final relativePath = tileset.relativePath.trim();
    if (relativePath.isEmpty || p.isAbsolute(relativePath)) {
      return const SmartTileAtlasImageLoadResult(
        status: SmartTileAtlasImageLoadStatus.outsideProject,
        message: 'Le tileset doit référencer une image interne au projet.',
      );
    }
    final absolutePath = p.normalize(p.join(normalizedRoot, relativePath));
    if (absolutePath != normalizedRoot &&
        !p.isWithin(normalizedRoot, absolutePath)) {
      return const SmartTileAtlasImageLoadResult(
        status: SmartTileAtlasImageLoadStatus.outsideProject,
        message: 'Le tileset sort de la racine du projet.',
      );
    }

    final file = File(absolutePath);
    if (!await file.exists()) {
      return const SmartTileAtlasImageLoadResult(
        status: SmartTileAtlasImageLoadStatus.missingFile,
        message: 'Image du tileset introuvable.',
      );
    }

    try {
      final resolvedRoot =
          await Directory(normalizedRoot).resolveSymbolicLinks();
      final resolvedFile = await file.resolveSymbolicLinks();
      if (resolvedFile != resolvedRoot &&
          !p.isWithin(resolvedRoot, resolvedFile)) {
        return const SmartTileAtlasImageLoadResult(
          status: SmartTileAtlasImageLoadStatus.outsideProject,
          message: 'Le tileset résolu sort de la racine du projet.',
        );
      }

      final bytes = await file.readAsBytes();
      final decoded = await Isolate.run(() => _decodeAtlas(bytes));
      if (decoded == null) {
        return const SmartTileAtlasImageLoadResult(
          status: SmartTileAtlasImageLoadStatus.invalidImage,
          message: 'Image du tileset illisible.',
        );
      }
      return SmartTileAtlasImageLoadResult(
        status: SmartTileAtlasImageLoadStatus.loaded,
        message: 'Image du tileset chargée.',
        image: SmartTileAtlasImage(
          absolutePath: absolutePath,
          bytes: bytes,
          width: decoded.width,
          height: decoded.height,
          columnAlphaCoverage: decoded.columnAlphaCoverage,
          rowAlphaCoverage: decoded.rowAlphaCoverage,
        ),
      );
    } on Object {
      return const SmartTileAtlasImageLoadResult(
        status: SmartTileAtlasImageLoadStatus.invalidImage,
        message: 'Image du tileset illisible.',
      );
    }
  }
}

final class _DecodedSmartTileAtlas {
  const _DecodedSmartTileAtlas({
    required this.width,
    required this.height,
    required this.columnAlphaCoverage,
    required this.rowAlphaCoverage,
  });

  final int width;
  final int height;
  final List<double> columnAlphaCoverage;
  final List<double> rowAlphaCoverage;
}

_DecodedSmartTileAtlas? _decodeAtlas(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
    return null;
  }
  if (decoded.numChannels < 4) {
    return _DecodedSmartTileAtlas(
      width: decoded.width,
      height: decoded.height,
      columnAlphaCoverage: List<double>.filled(decoded.width, 1),
      rowAlphaCoverage: List<double>.filled(decoded.height, 1),
    );
  }

  final columnAlpha = List<double>.filled(decoded.width, 0);
  final rowAlpha = List<double>.filled(decoded.height, 0);
  for (var y = 0; y < decoded.height; y += 1) {
    for (var x = 0; x < decoded.width; x += 1) {
      final alpha = decoded.getPixel(x, y).aNormalized.toDouble();
      columnAlpha[x] += alpha;
      rowAlpha[y] += alpha;
    }
  }
  for (var x = 0; x < columnAlpha.length; x += 1) {
    columnAlpha[x] /= decoded.height;
  }
  for (var y = 0; y < rowAlpha.length; y += 1) {
    rowAlpha[y] /= decoded.width;
  }
  return _DecodedSmartTileAtlas(
    width: decoded.width,
    height: decoded.height,
    columnAlphaCoverage: columnAlpha,
    rowAlphaCoverage: rowAlpha,
  );
}
