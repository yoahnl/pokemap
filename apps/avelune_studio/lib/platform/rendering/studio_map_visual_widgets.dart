import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'studio_border_preview.dart';

RuntimeAuthoringMapRenderer createStudioMapRenderer(
  MapData map,
  StudioMapResources resources, {
  StudioBorderPreview? previewBorders,
}) => RuntimeAuthoringMapRenderer(
  bundle: RuntimeMapBundle(
    manifest: resources.manifest,
    map: map,
    projectRootDirectory: resources.projectRoot,
    tilesetAbsolutePathsById: resources.paths,
  ),
  images: resources.images,
  borderAssets: (previewBorders ?? resources.borderPreview).assetsFor(map),
  includeCharacters: true,
);

class StudioMapVisual extends StatefulWidget {
  const StudioMapVisual({
    super.key,
    required this.map,
    required this.resources,
    this.preview = false,
    this.placedElementPreview,
    this.collisionColor,
  });

  final MapData map;
  final StudioMapResources resources;
  final bool preview;
  final MapPlacedElement? placedElementPreview;
  final Color? collisionColor;

  @override
  State<StudioMapVisual> createState() => _StudioMapVisualState();
}

class _StudioMapVisualState extends State<StudioMapVisual> {
  late RuntimeAuthoringMapRenderer renderer;
  final Object _owner = Object();
  int _catalogVersion = -1;
  BorderRuntimeAssetBundle? _borderAssets;
  StudioBorderPreview? _previewBorders;
  MapPlacedElement? _appliedPreview;

  StudioBorderPreview get _borders =>
      _previewBorders ?? widget.resources.borderPreview;

  void _prepareBorders() {
    final previous = _previewBorders;
    if (previous != null) unawaited(previous.dispose());
    _previewBorders = widget.preview
        ? StudioBorderPreview(
            projectRoot: widget.resources.projectRoot,
            changed: () => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _changed();
            }),
          )
        : null;
    _previewBorders?.setActiveMap(widget.resources.manifest, widget.map);
  }

  @override
  void initState() {
    super.initState();
    _prepareBorders();
    widget.resources.retain(
      _owner,
      widget.resources.mapResourceIds(widget.map),
    );
    renderer = createStudioMapRenderer(
      widget.map,
      widget.resources,
      previewBorders: _previewBorders,
    )..update(0);
    _borderAssets = _borders.assetsFor(widget.map);
    _catalogVersion = widget.resources.catalogVersion;
    widget.resources.addListener(_changed);
    _syncDecorPreview();
  }

  void _syncDecorPreview() {
    final candidate = widget.placedElementPreview;
    if (candidate == _appliedPreview) return;
    _appliedPreview = candidate;
    if (candidate == null) {
      renderer.clearPlacedElementPreview();
    } else {
      renderer.setPlacedElementPreview(candidate);
    }
  }

  void _changed() {
    if (!mounted) return;
    if (_previewBorders != null &&
        _catalogVersion != widget.resources.catalogVersion) {
      _previewBorders!.setActiveMap(widget.resources.manifest, widget.map);
    }
    if (_catalogVersion != widget.resources.catalogVersion ||
        !identical(_borderAssets, _borders.assetsFor(widget.map))) {
      _catalogVersion = widget.resources.catalogVersion;
      _borderAssets = _borders.assetsFor(widget.map);
      renderer.dispose();
      _appliedPreview = null;
      setState(
        () => renderer = createStudioMapRenderer(
          widget.map,
          widget.resources,
          previewBorders: _previewBorders,
        )..update(0),
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
    _syncDecorPreview();
  }

  @override
  void didUpdateWidget(StudioMapVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.map, widget.map) ||
        !identical(oldWidget.resources, widget.resources)) {
      renderer.dispose();
      _appliedPreview = null;
      oldWidget.resources.release(_owner);
      oldWidget.resources.removeListener(_changed);
      if (widget.preview &&
          (oldWidget.map != widget.map ||
              oldWidget.resources.manifest != widget.resources.manifest)) {
        if (oldWidget.resources != widget.resources) {
          _prepareBorders();
        } else {
          _previewBorders?.setActiveMap(widget.resources.manifest, widget.map);
        }
      } else if (oldWidget.preview != widget.preview) {
        _prepareBorders();
      }
      widget.resources.addListener(_changed);
      widget.resources.retain(
        _owner,
        widget.resources.mapResourceIds(widget.map),
      );
      renderer = createStudioMapRenderer(
        widget.map,
        widget.resources,
        previewBorders: _previewBorders,
      )..update(0);
      _borderAssets = _borders.assetsFor(widget.map);
    }
    _syncDecorPreview();
  }

  @override
  void dispose() {
    renderer.dispose();
    widget.resources.removeListener(_changed);
    widget.resources.release(_owner);
    if (_previewBorders != null) unawaited(_previewBorders!.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.resources.manifest.settings;
    renderer.setCollisionOverlay(
      visible: widget.collisionColor != null,
      color: widget.collisionColor ?? Theme.of(context).colorScheme.error,
    );
    final paint = CustomPaint(
      size: Size(
        widget.map.size.width * settings.tileWidth * settings.displayScale,
        widget.map.size.height * settings.tileHeight * settings.displayScale,
      ),
      painter: _MapPainter(
        renderer,
        widget.resources,
        widget.placedElementPreview,
        widget.collisionColor,
      ),
      foregroundPainter: _MissingResourcePainter(
        widget.map,
        widget.resources,
        Theme.of(context).colorScheme.error,
        widget.placedElementPreview,
      ),
    );
    return paint;
  }
}

class _MissingResourcePainter extends CustomPainter {
  _MissingResourcePainter(this.map, this.resources, this.color, this.preview)
    : super(repaint: resources);
  final MapData map;
  final StudioMapResources resources;
  final Color color;
  final MapPlacedElement? preview;

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
      color != oldDelegate.color;
}

class _MapPainter extends CustomPainter {
  _MapPainter(
    this.renderer,
    StudioMapResources resources,
    this.preview,
    this.collisionColor,
  ) : super(repaint: resources);
  final RuntimeAuthoringMapRenderer renderer;
  final MapPlacedElement? preview;
  final Color? collisionColor;

  @override
  void paint(Canvas canvas, Size size) => renderer.paint(
    canvas,
    viewport: (Offset.zero & size).intersect(canvas.getLocalClipBounds()),
  );

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      renderer != oldDelegate.renderer ||
      preview != oldDelegate.preview ||
      collisionColor != oldDelegate.collisionColor;
}
