part of 'studio_map_visual_widgets.dart';

class _MissingResourcePainter extends CustomPainter {
  _MissingResourcePainter(
    this.map,
    this.resources,
    this.color,
    this.preview,
    this.editorState,
    this.renderer,
  ) : super(repaint: resources);
  final MapData map;
  final StudioMapResources resources;
  final Color color;
  final MapPlacedElement? preview;
  final MapEditorState? editorState;
  final RuntimeAuthoringMapRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) {
    final settings = resources.manifest.settings;
    final width = settings.tileWidth * settings.displayScale;
    final height = settings.tileHeight * settings.displayScale;
    final elements = resources.elements;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final clip = canvas.getLocalClipBounds();
    for (final original in map.placedElements) {
      if (!renderer.isPlacedElementVisible(original)) continue;
      final instance = preview?.id == original.id ? preview! : original;
      final element = elements[instance.elementId];
      final frame = element?.frames.firstOrNull;
      final id = frame == null || frame.tilesetId.isEmpty
          ? element?.tilesetId
          : frame.tilesetId;
      if (frame != null && resources.images.containsKey(id)) continue;
      if (id == null || !resources.hasFailure({id})) continue;
      final bounds = element == null
          ? null
          : resolveMapPlacedElementVisualBounds(
              instance: instance,
              element: element,
              manifest: resources.manifest,
            );
      final rect = bounds == null
          ? Rect.fromLTWH(
              instance.pos.x * width,
              instance.pos.y * height,
              width.toDouble(),
              height.toDouble(),
            )
          : Rect.fromLTWH(
              bounds.leftPx * settings.displayScale.toDouble(),
              bounds.topPx * settings.displayScale.toDouble(),
              bounds.widthPx * settings.displayScale.toDouble(),
              bounds.heightPx * settings.displayScale.toDouble(),
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
      preview != oldDelegate.preview ||
      !setEquals(
        editorState?.hiddenElements,
        oldDelegate.editorState?.hiddenElements,
      ) ||
      !setEquals(
        editorState?.hiddenFamilies,
        oldDelegate.editorState?.hiddenFamilies,
      ) ||
      color != oldDelegate.color;
}

class _MapPainter extends CustomPainter {
  _MapPainter(
    this.renderer,
    StudioMapResources resources,
    this.preview,
    this.collisionColor,
    Listenable animationRepaint,
    this.painted,
    this.editorState,
  ) : super(repaint: Listenable.merge([resources, animationRepaint]));
  final RuntimeAuthoringMapRenderer renderer;
  final MapPlacedElement? preview;
  final Color? collisionColor;
  final void Function(Rect viewport) painted;
  final MapEditorState? editorState;

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = (Offset.zero & size).intersect(
      canvas.getLocalClipBounds(),
    );
    renderer.paint(canvas, viewport: viewport);
    painted(viewport);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      renderer != oldDelegate.renderer ||
      preview != oldDelegate.preview ||
      !setEquals(
        editorState?.hiddenElements,
        oldDelegate.editorState?.hiddenElements,
      ) ||
      !setEquals(
        editorState?.hiddenFamilies,
        oldDelegate.editorState?.hiddenFamilies,
      ) ||
      collisionColor != oldDelegate.collisionColor;
}
