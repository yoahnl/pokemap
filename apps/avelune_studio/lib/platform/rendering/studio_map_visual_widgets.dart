import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

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

class _StudioMapVisualState extends State<StudioMapVisual>
    with SingleTickerProviderStateMixin {
  late RuntimeAuthoringMapRenderer renderer;
  late final Ticker _ticker;
  final ValueNotifier<int> _animationRepaint = ValueNotifier(0);
  final Map<(String, int), ProjectTilesetVisualResolution?> _animations = {};
  final Map<ObjectLayer, MapPlacedTileVisualIndex> _objectIndices = {};
  final Map<ObjectLayer, Map<String, ProjectTilesetVisualResolution>>
  _objectAnimations = {};
  Set<ProjectTilesetVisualResolution> _visibleAnimations = {};
  Rect? _paintViewport;
  Rect? _clockViewport;
  Duration _elapsed = Duration.zero;
  Duration _lastTick = Duration.zero;
  double _rendererSeconds = 0;
  bool _tickingEnabled = false;
  bool _waitingForVisibility = false;
  bool? _hasAnimations;
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
    _ticker = createTicker(_tick);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    if (_tickingEnabled == enabled) return;
    _tickingEnabled = enabled;
    if (!enabled) _stopTicker();
    _animationRepaint.value++;
    if (enabled) _waitForVisibleAnimation();
  }

  void _stopTicker() {
    _ticker.stop();
    _lastTick = Duration.zero;
  }

  bool _hasUsedAnimation() {
    final cached = _hasAnimations;
    if (cached != null) return cached;
    for (final layer in widget.map.layers) {
      if (!layer.isVisible ||
          layer.opacity <= 0 ||
          !mapLayerParticipatesInVisualComposition(layer)) {
        continue;
      }
      if (layer is TileLayer) {
        final animatedIndices = <int>{};
        for (var i = 0; i < layer.palette.length; i++) {
          if (_animationFor(layer.palette[i]) != null) {
            animatedIndices.add(i + 1);
          }
        }
        if (animatedIndices.isNotEmpty &&
            layer.cells.any(animatedIndices.contains)) {
          return _hasAnimations = true;
        }
      } else if (layer is ObjectLayer &&
          layer.tileObjects.any(
            (object) =>
                object.isVisible &&
                object.opacity > 0 &&
                _animationFor(object.tile) != null,
          )) {
        return _hasAnimations = true;
      }
    }
    return _hasAnimations = false;
  }

  void _waitForVisibleAnimation() {
    if (_waitingForVisibility || !_hasUsedAnimation()) return;
    _waitingForVisibility = true;
    void check(Duration _) {
      if (!mounted ||
          !_tickingEnabled ||
          _ticker.isActive ||
          !_hasUsedAnimation()) {
        _waitingForVisibility = false;
        return;
      }
      final viewport = _visibleViewport();
      if (viewport != _clockViewport) {
        _clockViewport = viewport;
        _visibleAnimations = _animationsIn(viewport);
      }
      if (_visibleAnimations.isNotEmpty) {
        _waitingForVisibility = false;
        _animationRepaint.value++;
      } else {
        WidgetsBinding.instance.addPostFrameCallback(check);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(check);
  }

  void _resetClock() {
    _stopTicker();
    _elapsed = Duration.zero;
    _rendererSeconds = 0;
    _paintViewport = null;
    _clockViewport = null;
    _visibleAnimations = {};
    _animations.clear();
    _objectIndices.clear();
    _objectAnimations.clear();
    _hasAnimations = null;
  }

  Rect _visibleViewport() {
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.attached || !render.hasSize) {
      return Rect.zero;
    }
    var viewport = (Offset.zero & render.size);
    final view = View.of(context);
    viewport = viewport.intersect(
      MatrixUtils.inverseTransformRect(
        render.getTransformTo(null),
        Offset.zero & (view.physicalSize / view.devicePixelRatio),
      ),
    );
    RenderObject child = render;
    for (var parent = child.parent; parent != null; parent = child.parent) {
      if (parent is RenderOffstage && parent.offstage ||
          parent is RenderOpacity && parent.opacity == 0 ||
          parent is RenderAnimatedOpacity && parent.opacity.value == 0) {
        return Rect.zero;
      }
      final clip = parent.describeApproximatePaintClip(child);
      if (clip != null) {
        viewport = viewport.intersect(
          MatrixUtils.inverseTransformRect(render.getTransformTo(parent), clip),
        );
      }
      if (viewport.isEmpty) return Rect.zero;
      child = parent;
    }
    return viewport;
  }

  ProjectTilesetVisualResolution? _animationFor(TileLayerPaletteEntry tile) =>
      _animations.putIfAbsent((tile.tilesetId, tile.localTileId), () {
        final source = widget.resources.tilesets[tile.tilesetId]?.source;
        if (source is! ProjectRegularAtlasTilesetSource ||
            source.columns <= 0 ||
            tile.localTileId < 0 ||
            tile.localTileId >= source.tileCount ||
            !source.tileAnimations.any(
              (animation) =>
                  animation.tileId == tile.localTileId &&
                  animation.frames.length > 1,
            )) {
          return null;
        }
        final settings = widget.resources.manifest.settings;
        try {
          return const ProjectTilesetVisualResolver().resolve(
            source: source,
            selection: ProjectTilesetVisualSelection.regularAtlas(
              source: TilesetSourceRect(
                x: tile.localTileId % source.columns,
                y: tile.localTileId ~/ source.columns,
              ),
            ),
            cellWidth: settings.tileWidth,
            cellHeight: settings.tileHeight,
          );
        } on ProjectTilesetVisualResolutionException {
          return null;
        }
      });

  bool _loaded(ProjectTilesetVisualResolution visual, String tilesetId) =>
      visual.frames.every(
        (frame) => frame.slices.every((slice) {
          final image =
              widget.resources.images[slice.assetId] ??
              widget.resources.images[tilesetId];
          final source = slice.sourceRect;
          return image != null &&
              image.containsSourceRect(
                Rect.fromLTWH(
                  source.x.toDouble(),
                  source.y.toDouble(),
                  source.width.toDouble(),
                  source.height.toDouble(),
                ),
              );
        }),
      );

  Set<ProjectTilesetVisualResolution> _animationsIn(Rect viewport) {
    final found = <ProjectTilesetVisualResolution>{};
    if (viewport.isEmpty) return found;
    final settings = widget.resources.manifest.settings;
    final scale = settings.displayScale;
    final cellWidth = settings.tileWidth * scale;
    final cellHeight = settings.tileHeight * scale;
    if (cellWidth <= 0 || cellHeight <= 0) return found;
    for (final layer in widget.map.layers) {
      if (!layer.isVisible ||
          layer.opacity <= 0 ||
          !mapLayerParticipatesInVisualComposition(layer)) {
        continue;
      }
      if (layer is TileLayer) {
        final palette = <int, ProjectTilesetVisualResolution>{};
        Rect? bounds;
        for (var i = 0; i < layer.palette.length; i++) {
          final tile = layer.palette[i];
          final visual = _animationFor(tile);
          if (visual == null || !_loaded(visual, tile.tilesetId)) continue;
          palette[i + 1] = visual;
          final extent = visual.animationBounds;
          final rect = Rect.fromLTWH(
            extent.x * scale.toDouble(),
            extent.y * scale.toDouble(),
            extent.width * scale.toDouble(),
            extent.height * scale.toDouble(),
          );
          bounds = bounds?.expandToInclude(rect) ?? rect;
        }
        if (bounds == null) continue;
        final width = widget.map.size.width;
        final height = widget.map.size.height;
        final startX = ((viewport.left - bounds.right) / cellWidth)
            .floor()
            .clamp(0, width);
        final endX = ((viewport.right - bounds.left) / cellWidth).ceil().clamp(
          0,
          width,
        );
        final startY = ((viewport.top - bounds.bottom) / cellHeight)
            .floor()
            .clamp(0, height);
        final endY = ((viewport.bottom - bounds.top) / cellHeight).ceil().clamp(
          0,
          height,
        );
        for (var y = startY; y < endY; y++) {
          for (var x = startX; x < endX; x++) {
            final index = y * width + x;
            if (index >= layer.cells.length) continue;
            final visual = palette[layer.cells[index]];
            if (visual == null) continue;
            final extent = visual.animationBounds;
            final rect = Rect.fromLTWH(
              x * cellWidth + extent.x * scale.toDouble(),
              y * cellHeight + extent.y * scale.toDouble(),
              extent.width * scale.toDouble(),
              extent.height * scale.toDouble(),
            );
            if (rect.overlaps(viewport)) found.add(visual);
          }
        }
      } else if (layer is ObjectLayer) {
        final animatedObjects = _objectAnimations.putIfAbsent(layer, () {
          final animations = <String, ProjectTilesetVisualResolution>{};
          for (final object in layer.tileObjects) {
            if (!object.isVisible || object.opacity <= 0) continue;
            final visual = _animationFor(object.tile);
            if (visual != null) animations[object.id] = visual;
          }
          return animations;
        });
        if (animatedObjects.isEmpty) continue;
        try {
          final index = _objectIndices.putIfAbsent(
            layer,
            () => MapPlacedTileVisualIndex.build(
              layer: layer,
              tilesetsById: {
                for (final entry in widget.resources.manifest.tilesets)
                  entry.id: ?entry.source,
              },
              sourceCellWidth: settings.tileWidth,
              sourceCellHeight: settings.tileHeight,
              destinationCellWidth: cellWidth.toDouble(),
              destinationCellHeight: cellHeight.toDouble(),
            ),
          );
          for (final instruction
              in index
                  .resolve(
                    elapsedMs: _elapsed.inMilliseconds,
                    viewport: SmartTileGeometryRect(
                      left: viewport.left,
                      top: viewport.top,
                      width: viewport.width,
                      height: viewport.height,
                    ),
                  )
                  .visuals) {
            final visual = animatedObjects[instruction.objectId];
            if (visual != null && _loaded(visual, instruction.tilesetId)) {
              found.add(visual);
            }
          }
        } on MapPlacedTileVisualResolutionException {
          continue;
        }
      }
    }
    return found;
  }

  void _painted(Rect viewport) {
    _paintViewport = viewport;
    final visible = viewport.intersect(_visibleViewport());
    if (visible != _clockViewport) {
      _clockViewport = visible;
      _visibleAnimations = _animationsIn(visible);
    }
    if (!_tickingEnabled || _visibleAnimations.isEmpty) {
      _stopTicker();
      if (_tickingEnabled) _waitForVisibleAnimation();
    } else if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    if (!_tickingEnabled || !mounted) {
      _stopTicker();
      return;
    }
    final viewport = _visibleViewport().intersect(_paintViewport ?? Rect.zero);
    if (viewport != _clockViewport) {
      _clockViewport = viewport;
      _visibleAnimations = _animationsIn(viewport);
    }
    if (_visibleAnimations.isEmpty) {
      _stopTicker();
      _waitForVisibleAnimation();
      return;
    }
    final before = _elapsed.inMilliseconds;
    _elapsed += elapsed - _lastTick;
    _lastTick = elapsed;
    final seconds =
        (_elapsed.inMilliseconds + 0.5) / Duration.millisecondsPerSecond;
    renderer.update(seconds - _rendererSeconds);
    _rendererSeconds = seconds;
    final after = _elapsed.inMilliseconds;
    if (_visibleAnimations.any(
      (visual) => !identical(visual.frameAt(before), visual.frameAt(after)),
    )) {
      _animationRepaint.value++;
    }
  }

  @override
  void deactivate() {
    _stopTicker();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _animationRepaint.value++;
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
    _clockViewport = null;
    if (_previewBorders != null &&
        _catalogVersion != widget.resources.catalogVersion) {
      _previewBorders!.setActiveMap(widget.resources.manifest, widget.map);
    }
    if (_catalogVersion != widget.resources.catalogVersion ||
        !identical(_borderAssets, _borders.assetsFor(widget.map))) {
      _catalogVersion = widget.resources.catalogVersion;
      _borderAssets = _borders.assetsFor(widget.map);
      _resetClock();
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
      _resetClock();
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
    _ticker.dispose();
    _animationRepaint.dispose();
    renderer.dispose();
    widget.resources.removeListener(_changed);
    widget.resources.release(_owner);
    if (_previewBorders != null) unawaited(_previewBorders!.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.resources.manifest.settings;
    final editorState = MapEditorVisibilityScope.maybeOf(context);
    renderer.setEditorState(editorState);
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
        _animationRepaint,
        _painted,
        editorState,
      ),
      foregroundPainter: _MissingResourcePainter(
        widget.map,
        widget.resources,
        Theme.of(context).colorScheme.error,
        widget.placedElementPreview,
        editorState,
        renderer,
      ),
    );
    return paint;
  }
}

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
