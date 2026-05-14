import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../ui/shared/cupertino_editor_widgets.dart';

typedef EnvironmentTilesetPathResolver = String? Function(String tilesetId);

class EnvironmentElementThumbnail extends StatelessWidget {
  const EnvironmentElementThumbnail({
    super.key,
    required this.manifest,
    required this.element,
    required this.elementId,
    this.resolveTilesetPathById,
    this.size = 34,
    this.previewKey,
    this.fallbackKey,
    this.fallbackAccent,
  });

  final ProjectManifest manifest;
  final ProjectElementEntry? element;
  final String elementId;
  final EnvironmentTilesetPathResolver? resolveTilesetPathById;
  final double size;
  final Key? previewKey;
  final Key? fallbackKey;
  final Color? fallbackAccent;

  @override
  Widget build(BuildContext context) {
    final resolved = _ResolvedEnvironmentElementThumbnail.resolve(
      manifest: manifest,
      element: element,
      resolveTilesetPathById: resolveTilesetPathById,
    );
    if (resolved == null) {
      return _fallback(context);
    }

    final croppedImage = _EnvironmentElementThumbnailImageCache.crop(resolved);
    if (croppedImage == null) {
      return _fallback(context);
    }
    return Container(
      key: previewKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EditorChrome.badgeFill(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _EnvironmentElementThumbnailRasterPainter(croppedImage),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final accent = fallbackAccent ?? EditorChrome.accentJade;
    final id = elementId.trim();
    return Container(
      key: fallbackKey,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Text(
        id.isEmpty ? '?' : id.characters.first.toUpperCase(),
        style: TextStyle(
          color: accent,
          fontSize: size <= 30 ? 13 : 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ResolvedEnvironmentElementThumbnail {
  const _ResolvedEnvironmentElementThumbnail({
    required this.path,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  final String path;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  static _ResolvedEnvironmentElementThumbnail? resolve({
    required ProjectManifest manifest,
    required ProjectElementEntry? element,
    required EnvironmentTilesetPathResolver? resolveTilesetPathById,
  }) {
    if (element == null || element.frames.isEmpty) {
      return null;
    }
    final frame = element.frames.primaryFrame;
    final tilesetId = frame.tilesetId.trim().isNotEmpty
        ? frame.tilesetId.trim()
        : element.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return null;
    }
    final tileWidth = manifest.settings.tileWidth;
    final tileHeight = manifest.settings.tileHeight;
    if (tileWidth <= 0 || tileHeight <= 0) {
      return null;
    }
    final source = frame.source;
    if (source.width <= 0 || source.height <= 0) {
      return null;
    }
    final path = _resolvePath(
      manifest: manifest,
      tilesetId: tilesetId,
      resolveTilesetPathById: resolveTilesetPathById,
    );
    if (path == null) {
      return null;
    }
    return _ResolvedEnvironmentElementThumbnail(
      path: path,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
  }

  static String? _resolvePath({
    required ProjectManifest manifest,
    required String tilesetId,
    required EnvironmentTilesetPathResolver? resolveTilesetPathById,
  }) {
    final resolved = resolveTilesetPathById?.call(tilesetId)?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    for (final tileset in manifest.tilesets) {
      if (tileset.id != tilesetId) {
        continue;
      }
      final relativePath = tileset.relativePath.trim();
      if (relativePath.isNotEmpty && p.isAbsolute(relativePath)) {
        return relativePath;
      }
      return null;
    }
    return null;
  }

  String get cacheKey {
    return [
      path,
      source.x,
      source.y,
      source.width,
      source.height,
      tileWidth,
      tileHeight,
    ].join('|');
  }

  img.Image? crop() {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      final bytes = file.readAsBytesSync();
      if (bytes.isEmpty) {
        return null;
      }
      final image = img.decodeImage(bytes);
      if (image == null || !fits(image.width, image.height)) {
        return null;
      }
      final cropped = img.copyCrop(
        image,
        x: source.x * tileWidth,
        y: source.y * tileHeight,
        width: source.width * tileWidth,
        height: source.height * tileHeight,
      );
      return cropped;
    } catch (_) {
      return null;
    }
  }

  bool fits(int imageWidth, int imageHeight) {
    final left = source.x * tileWidth;
    final top = source.y * tileHeight;
    final width = source.width * tileWidth;
    final height = source.height * tileHeight;
    return left >= 0 &&
        top >= 0 &&
        width > 0 &&
        height > 0 &&
        left + width <= imageWidth &&
        top + height <= imageHeight;
  }
}

class _EnvironmentElementThumbnailRasterPainter extends CustomPainter {
  _EnvironmentElementThumbnailRasterPainter(this.image);

  final img.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _scaleToFit(size);
    final drawWidth = image.width * scale;
    final drawHeight = image.height * scale;
    final left = (size.width - drawWidth) / 2;
    final top = (size.height - drawHeight) / 2;
    final paint = Paint();
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        paint.color = Color.fromARGB(
          pixel.a.toInt(),
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
        canvas.drawRect(
          Rect.fromLTWH(
            left + x * scale,
            top + y * scale,
            scale.ceilToDouble(),
            scale.ceilToDouble(),
          ),
          paint,
        );
      }
    }
  }

  double _scaleToFit(Size size) {
    final widthScale = size.width / image.width;
    final heightScale = size.height / image.height;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  @override
  bool shouldRepaint(covariant _EnvironmentElementThumbnailRasterPainter old) {
    return old.image != image;
  }
}

class _EnvironmentElementThumbnailImageCache {
  static final Map<String, img.Image?> _cache = {};

  static img.Image? crop(_ResolvedEnvironmentElementThumbnail resolved) {
    return _cache.putIfAbsent(resolved.cacheKey, resolved.crop);
  }
}
