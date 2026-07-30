part of 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

// Palette previews, their painters, and the lightweight image cache are kept
// together because they form one visual rendering unit used across the panel.
// Extracting them as a dedicated part keeps the main panel focused on layout
// and interaction orchestration.

class _PaletteRectPreview extends StatelessWidget {
  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  const _PaletteRectPreview({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaletteRectPainter(
        image: image,
        source: source,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _PaletteRectPainter extends CustomPainter {
  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  _PaletteRectPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (srcRect.right > image.width || srcRect.bottom > image.height) {
      return;
    }

    final aspect = srcRect.width / srcRect.height;
    final targetAspect = size.width / size.height;
    Rect dstRect;
    if (aspect > targetAspect) {
      final height = size.width / aspect;
      final top = (size.height - height) / 2;
      dstRect = Rect.fromLTWH(0, top, size.width, height);
    } else {
      final width = size.height * aspect;
      final left = (size.width - width) / 2;
      dstRect = Rect.fromLTWH(left, 0, width, size.height);
    }
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _PaletteRectPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight;
  }
}
