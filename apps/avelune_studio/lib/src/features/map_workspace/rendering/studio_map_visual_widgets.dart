import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import 'studio_map_resources.dart';
import '../../../shared/design_system/studio_surfaces.dart';

class StudioMapVisual extends StatefulWidget {
  const StudioMapVisual({
    super.key,
    required this.map,
    required this.resources,
  });

  final MapData map;
  final StudioMapResources resources;

  @override
  State<StudioMapVisual> createState() => _StudioMapVisualState();
}

class _StudioMapVisualState extends State<StudioMapVisual> {
  late RuntimeAuthoringMapRenderer renderer;

  @override
  void initState() {
    super.initState();
    renderer = widget.resources.renderer(widget.map)..update(0);
  }

  @override
  void didUpdateWidget(StudioMapVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.map, widget.map) ||
        !identical(oldWidget.resources, widget.resources)) {
      renderer = widget.resources.renderer(widget.map)..update(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.resources.manifest.settings;
    final paint = CustomPaint(
      size: Size(
        widget.map.size.width * settings.tileWidth * settings.displayScale,
        widget.map.size.height * settings.tileHeight * settings.displayScale,
      ),
      painter: _MapPainter(renderer),
      foregroundPainter: _MissingResourcePainter(
        widget.map,
        widget.resources,
        Theme.of(context).colorScheme.error,
      ),
    );
    if (!widget.map.layers.any(
      (layer) => layer is BorderLayer && layer.isVisible,
    )) {
      return paint;
    }
    return Stack(
      children: [
        paint,
        const Positioned(
          left: 12,
          top: 12,
          right: 12,
          child: StudioNotice(
            'Les bordures de cette carte ne sont pas prévisualisées dans le Studio. Elles restent conservées et rendues dans le test du jeu.',
          ),
        ),
      ],
    );
  }
}

class _MissingResourcePainter extends CustomPainter {
  _MissingResourcePainter(this.map, this.resources, this.color);
  final MapData map;
  final StudioMapResources resources;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final settings = resources.manifest.settings;
    final width = settings.tileWidth * settings.displayScale;
    final height = settings.tileHeight * settings.displayScale;
    final elements = {
      for (final entry in resources.manifest.elements) entry.id: entry,
    };
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final clip = canvas.getLocalClipBounds();
    for (final instance in map.placedElements) {
      final element = elements[instance.elementId];
      final frame = element?.frames.firstOrNull;
      final id = frame == null || frame.tilesetId.isEmpty
          ? element?.tilesetId
          : frame.tilesetId;
      if (frame != null && resources.images.containsKey(id)) continue;
      final rect = Rect.fromLTWH(
        instance.pos.x * width,
        instance.pos.y * height,
        (frame?.source.width ?? 1) * width,
        (frame?.source.height ?? 1) * height,
      );
      if (!clip.overlaps(rect)) continue;
      canvas.drawRect(rect, paint);
      canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
      canvas.drawLine(rect.topRight, rect.bottomLeft, paint);
    }
  }

  @override
  bool shouldRepaint(_MissingResourcePainter oldDelegate) =>
      map != oldDelegate.map ||
      resources != oldDelegate.resources ||
      color != oldDelegate.color;
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.renderer);
  final RuntimeAuthoringMapRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) =>
      renderer.paint(canvas, viewport: canvas.getLocalClipBounds());

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      renderer != oldDelegate.renderer;
}

class StudioMapThumbnail extends StatelessWidget {
  const StudioMapThumbnail({
    super.key,
    required this.element,
    required this.resources,
    required this.size,
  });

  final ProjectElementEntry element;
  final StudioMapResources resources;
  final double size;

  @override
  Widget build(BuildContext context) {
    final frame = element.frames.firstOrNull;
    final image =
        resources.images[frame == null || frame.tilesetId.isEmpty
            ? element.tilesetId
            : frame.tilesetId];
    if (frame == null || image == null) {
      return SizedBox.square(
        dimension: size,
        child: const Icon(Icons.broken_image_outlined),
      );
    }
    final settings = resources.manifest.settings;
    final source = ui.Rect.fromLTWH(
      frame.source.x * settings.tileWidth.toDouble(),
      frame.source.y * settings.tileHeight.toDouble(),
      frame.source.width * settings.tileWidth.toDouble(),
      frame.source.height * settings.tileHeight.toDouble(),
    );
    if (!image.containsSourceRect(source)) {
      return SizedBox.square(
        dimension: size,
        child: const Icon(Icons.broken_image_outlined),
      );
    }
    return CustomPaint(
      size: Size.square(size),
      painter: _ThumbnailPainter(image, source),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  _ThumbnailPainter(this.image, this.source);
  final RuntimeTilesetImage image;
  final Rect source;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(BoxFit.contain, source.size, size).destination;
    image.drawImageRect(
      canvas,
      source,
      Alignment.center.inscribe(fitted, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_ThumbnailPainter oldDelegate) =>
      image != oldDelegate.image || source != oldDelegate.source;
}
