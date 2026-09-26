import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';

RuntimeAuthoringMapRenderer createStudioMapRenderer(
  MapData map,
  StudioMapResources resources,
) => RuntimeAuthoringMapRenderer(
  bundle: RuntimeMapBundle(
    manifest: resources.manifest,
    map: map,
    projectRootDirectory: resources.projectRoot,
    tilesetAbsolutePathsById: resources.paths,
  ),
  images: resources.images,
  borderAssets: resources.borderPreview.assetsFor(map),
  includeCharacters: true,
);

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
  final Object _owner = Object();
  int _catalogVersion = -1;
  BorderRuntimeAssetBundle? _borderAssets;

  @override
  void initState() {
    super.initState();
    widget.resources.retain(
      _owner,
      widget.resources.mapResourceIds(widget.map),
    );
    renderer = widget.resources.renderer(widget.map)..update(0);
    _borderAssets = widget.resources.borderPreview.assetsFor(widget.map);
    _catalogVersion = widget.resources.catalogVersion;
    widget.resources.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    if (_catalogVersion != widget.resources.catalogVersion ||
        !identical(
          _borderAssets,
          widget.resources.borderPreview.assetsFor(widget.map),
        )) {
      _catalogVersion = widget.resources.catalogVersion;
      _borderAssets = widget.resources.borderPreview.assetsFor(widget.map);
      setState(
        () => renderer = widget.resources.renderer(widget.map)..update(0),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.resources.retain(
          _owner,
          widget.resources.mapResourceIds(widget.map),
        );
      }
    });
  }

  @override
  void didUpdateWidget(StudioMapVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.map, widget.map) ||
        !identical(oldWidget.resources, widget.resources)) {
      oldWidget.resources.release(_owner);
      oldWidget.resources.removeListener(_changed);
      widget.resources.addListener(_changed);
      widget.resources.retain(
        _owner,
        widget.resources.mapResourceIds(widget.map),
      );
      renderer = widget.resources.renderer(widget.map)..update(0);
      _borderAssets = widget.resources.borderPreview.assetsFor(widget.map);
    }
  }

  @override
  void dispose() {
    widget.resources.removeListener(_changed);
    widget.resources.release(_owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.resources.manifest.settings;
    final paint = CustomPaint(
      size: Size(
        widget.map.size.width * settings.tileWidth * settings.displayScale,
        widget.map.size.height * settings.tileHeight * settings.displayScale,
      ),
      painter: _MapPainter(renderer, widget.resources),
      foregroundPainter: _MissingResourcePainter(
        widget.map,
        widget.resources,
        Theme.of(context).colorScheme.error,
      ),
    );
    return paint;
  }
}

class _MissingResourcePainter extends CustomPainter {
  _MissingResourcePainter(this.map, this.resources, this.color)
    : super(repaint: resources);
  final MapData map;
  final StudioMapResources resources;
  final Color color;

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
    for (final instance in map.placedElements) {
      final element = elements[instance.elementId];
      final frame = element?.frames.firstOrNull;
      final id = frame == null || frame.tilesetId.isEmpty
          ? element?.tilesetId
          : frame.tilesetId;
      if (frame != null && resources.images.containsKey(id)) continue;
      if (id == null || !resources.hasFailure({id})) continue;
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
  _MapPainter(this.renderer, StudioMapResources resources)
    : super(repaint: resources);
  final RuntimeAuthoringMapRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) => renderer.paint(
    canvas,
    viewport: (Offset.zero & size).intersect(canvas.getLocalClipBounds()),
  );

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      renderer != oldDelegate.renderer;
}
