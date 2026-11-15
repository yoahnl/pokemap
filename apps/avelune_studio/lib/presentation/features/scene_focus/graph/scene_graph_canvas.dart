import 'dart:math' as math;

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_painters.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_toolbar.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_world.dart';

class SceneGraphCanvas extends StatefulWidget {
  const SceneGraphCanvas({
    super.key,
    required this.scene,
    required this.project,
    this.pathNodeIds = const [],
    this.pathChoices = const {},
    this.dialogueNames = const {},
  });

  final SceneAsset scene;
  final ProjectManifest? project;
  final List<String> pathNodeIds;
  final Map<String, String> pathChoices;
  final Map<String, String> dialogueNames;

  @override
  State<SceneGraphCanvas> createState() => SceneGraphCanvasState();
}

class SceneGraphCanvasState extends State<SceneGraphCanvas> {
  static const double _wheelZoomRate = 1 / 400;

  late SceneGraphView _view = projectSceneGraph(widget.scene);
  ValueNotifier<SceneGraphCamera>? _camera;
  Size _viewport = Size.zero;
  Set<String> _selected = {};
  Set<String> _marqueeBase = {};
  Offset? _marqueeStart;
  Offset? _marqueeEnd;
  int? _marqueePointer;
  int? _panPointer;
  double _pinchScale = 1;

  Set<String> get selection => Set.unmodifiable(_selected);
  SceneGraphCamera? get camera => _camera?.value;

  @override
  void didUpdateWidget(SceneGraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scene, widget.scene)) {
      _view = projectSceneGraph(widget.scene);
      final ids = {for (final card in _view.cards) card.id};
      _selected = _selected.where(ids.contains).toSet();
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  void showAll() =>
      _camera?.value = SceneGraphCamera.fit(sceneGraphBounds(_view), _viewport);

  void _down(PointerDownEvent event) {
    final camera = _camera;
    if (camera == null) return;
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons & (kSecondaryMouseButton | kMiddleMouseButton) != 0) {
      _panPointer = event.pointer;
      return;
    }
    if (event.buttons & kPrimaryButton == 0) return;
    final additive = HardwareKeyboard.instance.isShiftPressed;
    final hit = sceneGraphCardAt(
      _view,
      camera.value.toWorld(event.localPosition),
    );
    if (hit != null) {
      setState(() {
        _selected = !additive
            ? {hit.id}
            : _selected.contains(hit.id)
            ? (_selected.toSet()..remove(hit.id))
            : {..._selected, hit.id};
      });
      return;
    }
    setState(() {
      _marqueePointer = event.pointer;
      _marqueeStart = event.localPosition;
      _marqueeEnd = event.localPosition;
      _marqueeBase = additive ? _selected : {};
      _selected = _marqueeBase;
    });
  }

  void _move(PointerMoveEvent event) {
    final camera = _camera;
    if (camera == null) return;
    if (event.pointer == _panPointer) {
      camera.value = camera.value.panBy(event.localDelta);
      return;
    }
    final start = _marqueeStart;
    if (event.pointer != _marqueePointer || start == null) return;
    final rect = Rect.fromPoints(
      camera.value.toWorld(start),
      camera.value.toWorld(event.localPosition),
    );
    setState(() {
      _marqueeEnd = event.localPosition;
      _selected = {..._marqueeBase, ...sceneGraphCardsIn(_view, rect)};
    });
  }

  void _up(PointerEvent event) {
    if (event.pointer == _panPointer) _panPointer = null;
    if (event.pointer != _marqueePointer) return;
    setState(() {
      _marqueePointer = null;
      _marqueeStart = null;
      _marqueeEnd = null;
    });
  }

  void _signal(PointerSignalEvent event) {
    final camera = _camera;
    if (event is! PointerScrollEvent || camera == null) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      camera.value = event.kind == PointerDeviceKind.trackpad
          ? camera.value.panBy(-event.scrollDelta)
          : camera.value.zoomAt(
              event.localPosition,
              math.exp(-event.scrollDelta.dy * _wheelZoomRate),
            );
    });
  }

  void _pinch(PointerPanZoomUpdateEvent event) {
    final camera = _camera;
    if (camera == null) return;
    final factor = event.scale / _pinchScale;
    _pinchScale = event.scale;
    camera.value = camera.value
        .panBy(event.localPanDelta)
        .zoomAt(event.localPosition, factor);
  }

  Set<String> get _pathEdgeIds {
    final steps = {
      for (var i = 1; i < widget.pathNodeIds.length; i++)
        (widget.pathNodeIds[i - 1], widget.pathNodeIds[i]),
    };
    return {
      for (final wire in _view.wires)
        if (steps.contains((wire.edge.fromNodeId, wire.edge.toNodeId)) &&
            (widget.pathChoices[wire.edge.fromNodeId] ??
                    wire.edge.fromPortId) ==
                wire.edge.fromPortId)
          wire.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectionColor = StudioColors.of(context).canvasSelection;
    final bounds = sceneGraphBounds(_view);
    final world = SceneGraphWorld(
      view: _view,
      bounds: bounds,
      scene: widget.scene,
      project: widget.project,
      selected: _selected,
      pathNodeIds: widget.pathNodeIds.toSet(),
      pathEdgeIds: _pathEdgeIds,
      dialogueNames: widget.dialogueNames,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        final camera = _camera ??= ValueNotifier(
          SceneGraphCamera.opening(bounds, _viewport, _startCentre(bounds)),
        );
        final marquee = (_marqueeStart, _marqueeEnd);
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                key: const ValueKey('scene-graph-canvas'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: _down,
                onPointerMove: _move,
                onPointerUp: _up,
                onPointerCancel: _up,
                onPointerSignal: _signal,
                onPointerPanZoomStart: (_) => _pinchScale = 1,
                onPointerPanZoomUpdate: _pinch,
                child: ClipRect(
                  child: ColoredBox(
                    color: scheme.surfaceContainerLowest,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ValueListenableBuilder(
                            valueListenable: camera,
                            builder: (context, value, _) => CustomPaint(
                              painter: SceneGraphGridPainter(
                                camera: value,
                                minor: scheme.outlineVariant.withValues(
                                  alpha: .25,
                                ),
                                major: scheme.outlineVariant.withValues(
                                  alpha: .6,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: ValueListenableBuilder(
                            valueListenable: camera,
                            builder: (context, value, child) => Transform(
                              transform: _matrix(value, bounds.topLeft),
                              child: child,
                            ),
                            child: IgnorePointer(child: world),
                          ),
                        ),
                        if (marquee case (final start?, final end?))
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SceneGraphMarqueePainter(
                                rect: Rect.fromPoints(start, end),
                                color: selectionColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: StudioSpacing.l,
              right: StudioSpacing.l,
              bottom: StudioSpacing.l,
              child: SceneGraphToolbar(camera: camera, onShowAll: showAll),
            ),
          ],
        );
      },
    );
  }

  Offset _startCentre(Rect bounds) =>
      switch (_view.card(widget.scene.graph.startNodeId)) {
        final start? => sceneGraphCardRect(start).center,
        null => bounds.centerLeft,
      };

  Matrix4 _matrix(SceneGraphCamera camera, Offset origin) =>
      Matrix4.diagonal3Values(camera.scale, camera.scale, 1)..setTranslationRaw(
        camera.pan.dx + origin.dx * camera.scale,
        camera.pan.dy + origin.dy * camera.scale,
        0,
      );
}
