import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';

import 'studio_border_preview.dart';

part 'studio_map_visual_animation_clock.dart';
part 'studio_map_visual_animation_scan.dart';
part 'studio_map_visual_painters.dart';

RuntimeAuthoringMapRenderer createStudioMapRenderer(
  MapData map,
  StudioMapResources resources, {
  StudioBorderPreview? previewBorders,
  ProjectManifest? previewProject,
}) => RuntimeAuthoringMapRenderer(
  bundle: RuntimeMapBundle(
    manifest: previewProject ?? resources.manifest,
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
    this.previewProject,
    this.placedElementPreview,
    this.collisionColor,
  }) : assert(previewProject == null || preview);

  final MapData map;
  final StudioMapResources resources;
  final bool preview;
  final ProjectManifest? previewProject;
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
  ProjectManifest get _project =>
      widget.previewProject ?? widget.resources.manifest;

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
    _previewBorders?.setActiveMap(_project, widget.map);
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
      previewProject: widget.previewProject,
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
        widget.previewProject == null &&
        _catalogVersion != widget.resources.catalogVersion) {
      _previewBorders!.setActiveMap(_project, widget.map);
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
          previewProject: widget.previewProject,
        )..update(0),
      );
    } else if (widget.previewProject != null) {
      setState(() {});
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
        !identical(oldWidget.previewProject, widget.previewProject) ||
        !identical(oldWidget.resources, widget.resources)) {
      _resetClock();
      renderer.dispose();
      _appliedPreview = null;
      oldWidget.resources.release(_owner);
      oldWidget.resources.removeListener(_changed);
      if (widget.preview &&
          (oldWidget.map != widget.map ||
              oldWidget.previewProject != widget.previewProject ||
              oldWidget.resources.manifest != widget.resources.manifest)) {
        if (oldWidget.resources != widget.resources) {
          _prepareBorders();
        } else {
          _previewBorders?.setActiveMap(_project, widget.map);
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
        previewProject: widget.previewProject,
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
    if (widget.previewProject != null) {
      if (_borders.loading) {
        return const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Chargement du tracé'),
        );
      }
      if (_borders.issue != null) {
        return const Center(child: Text('Images de la bordure indisponibles'));
      }
    }
    final settings = _project.settings;
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
