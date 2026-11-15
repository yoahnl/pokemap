import 'dart:math' as math;

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_layout.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_templates.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_painters.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_step_menu.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_toolbar.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_world.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

part 'scene_graph_canvas_edits.dart';
part 'scene_graph_canvas_pointer.dart';

class SceneGraphCanvas extends StatefulWidget {
  const SceneGraphCanvas({
    super.key,
    required this.scene,
    required this.project,
    this.pathNodeIds = const [],
    this.pathChoices = const {},
    this.dialogueNames = const {},
    this.map,
    this.onChanged,
    this.checks,
    this.onSelectionChanged,
  });

  final SceneAsset scene;
  final ProjectManifest? project;
  final List<String> pathNodeIds;
  final Map<String, String> pathChoices;
  final Map<String, String> dialogueNames;
  final MapData? map;
  final bool Function(SceneAsset scene)? onChanged;
  final SceneGraphChecks? checks;
  final ValueChanged<Set<String>>? onSelectionChanged;

  @override
  State<SceneGraphCanvas> createState() => SceneGraphCanvasState();
}

class SceneGraphCanvasState extends State<SceneGraphCanvas> {
  static const double _wheelZoomRate = 1 / 400;
  static const double _dragSlop = 4;
  static const double _portReach = 10;
  static const double _snap = 16;
  static const double _duplicateShift = 32;
  static SceneGraphFragment? _clipboard;

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
  final _focus = FocusNode(debugLabel: 'scene-graph');
  ({int pointer, Offset origin, bool moved})? _rightPress;
  _CardDrag? _drag;
  Map<String, SceneGraphPoint> _moved = const {};
  ({int pointer, SceneGraphExit from, Offset end})? _wire;
  _StepMenu? _menu;
  Offset? _pointer;

  Set<String> get selection => Set.unmodifiable(_selected);
  SceneGraphCamera? get camera => _camera?.value;
  bool get _editable => widget.onChanged != null;
  SceneGraphView get _shown => _view.withPositions(_moved);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(SceneGraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scene, widget.scene)) {
      _view = projectSceneGraph(widget.scene);
      final ids = {for (final card in _view.cards) card.id};
      final kept = _selected.where(ids.contains).toSet();
      if (kept.length != _selected.length) {
        _selected = kept;
        WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
      }
      _moved = const {};
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _mutate(VoidCallback change) {
    final before = _selected;
    setState(change);
    if (!identical(before, _selected)) _announce();
  }

  Set<String> _announced = const {};

  void _announce() {
    if (!mounted) return;
    if (_announced.length == _selected.length &&
        _announced.containsAll(_selected)) {
      return;
    }
    _announced = Set.unmodifiable(_selected);
    widget.onSelectionChanged?.call(_announced);
  }

  void show(String nodeId) {
    final card = _view.card(nodeId);
    final camera = _camera;
    if (card == null || camera == null) return;
    camera.value = SceneGraphCamera(
      pan:
          _viewport.center(Offset.zero) -
          sceneGraphCardRect(card).center * camera.value.scale,
      scale: camera.value.scale,
    );
    _mutate(() => _selected = {nodeId});
  }

  void showAll() =>
      _camera?.value = SceneGraphCamera.fit(sceneGraphBounds(_view), _viewport);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectionColor = StudioColors.of(context).canvasSelection;
    final shown = _shown;
    final bounds = sceneGraphBounds(shown);
    final world = SceneGraphWorld(
      view: shown,
      bounds: bounds,
      scene: widget.scene,
      project: widget.project,
      selected: _selected,
      pathNodeIds: widget.pathNodeIds.toSet(),
      pathEdgeIds: _pathEdgeIds,
      dialogueNames: widget.dialogueNames,
      checks: widget.checks ?? checkSceneGraph(widget.scene),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        final camera = _camera ??= ValueNotifier(
          SceneGraphCamera.opening(bounds, _viewport, _startCentre(bounds)),
        );
        final marquee = (_marqueeStart, _marqueeEnd);
        final wire = _wire;
        final menu = _menu;
        return Stack(
          children: [
            Positioned.fill(
              child: Focus(
                focusNode: _focus,
                onKeyEvent: _key,
                child: Listener(
                  key: const ValueKey('scene-graph-canvas'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _down,
                  onPointerHover: (event) => _pointer = event.localPosition,
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
                          if (wire != null)
                            Positioned.fill(
                              child: CustomPaint(
                                key: const ValueKey('scene-graph-draft-wire'),
                                painter: SceneGraphDraftWirePainter(
                                  from: camera.value.toScreen(
                                    sceneGraphOutputAnchor(
                                      shown.card(wire.from.nodeId)!,
                                      wire.from.portId,
                                    ),
                                  ),
                                  to: wire.end,
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
            ),
            if (menu != null)
              Positioned(
                left: menu.screen.dx
                    .clamp(
                      0,
                      math.max(0, _viewport.width - SceneGraphStepMenu.width),
                    )
                    .toDouble(),
                top: menu.screen.dy
                    .clamp(0, math.max(0, _viewport.height - 320))
                    .toDouble(),
                child: SceneGraphStepMenu(
                  choices: sceneGraphStepChoices(
                    context,
                    widget.project,
                    widget.map,
                  ),
                  onChosen: _addFromMenu,
                  onDismiss: _closeMenu,
                ),
              ),
            Positioned(
              left: StudioSpacing.l,
              right: StudioSpacing.l,
              bottom: StudioSpacing.l,
              child: SceneGraphToolbar(
                camera: camera,
                editable: _editable,
                onShowAll: showAll,
              ),
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
