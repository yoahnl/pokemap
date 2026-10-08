import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../../features/cinematics/application/cinematic_preview_transport.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../map_workspace/studio_spatial_map_preview.dart';
import 'cinematic_map_model.dart';
import 'cinematic_transport_listenable.dart';
import 'cinematic_view_state.dart';
import 'cinematic_workspace_visuals.dart';

class CinematicSpatialMapScene extends StatefulWidget {
  const CinematicSpatialMapScene({
    super.key,
    required this.model,
    required this.visuals,
    required this.view,
    required this.transport,
    required this.changed,
    required this.onPoint,
    required this.onPointMove,
    required this.beforeSelect,
  });
  final CinematicMapModel model;
  final MapWorkspaceVisuals visuals;
  final CinematicViewState view;
  final CinematicPreviewTransport transport;
  final VoidCallback changed;
  final ValueChanged<Offset> onPoint;
  final void Function(CinematicStagePoint, Offset) onPointMove;
  final bool Function() beforeSelect;
  @override
  State<CinematicSpatialMapScene> createState() =>
      _CinematicSpatialMapSceneState();
}

class _CinematicSpatialMapSceneState extends State<CinematicSpatialMapScene> {
  final _camera = SpatialSceneController()..setView(SpatialEditorView.game);
  final _focus = FocusNode();
  CinematicSpatialPreview? _preview;
  CinematicStagePoint? _dragPoint;
  Offset? _dragOrigin, _dragDestination;
  SpatialSurfaceHit? _hover;
  String? _error;
  int _request = 0;
  CinematicPreviewPlaybackPlan? _plan;
  CinematicViewportProjection? _projection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CinematicSpatialMapScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model ||
        oldWidget.visuals != widget.visuals) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    _error = null;
    _preview?.dispose();
    _preview = null;
    final source = widget.visuals;
    if (source is! CinematicSpatialWorkspaceVisuals) return;
    try {
      final preview = await (source as CinematicSpatialWorkspaceVisuals)
          .cinematicSpatialPreview(widget.model.map, widget.model.actors);
      if (!mounted || request != _request) {
        preview.dispose();
        return;
      }
      setState(() {
        _preview?.dispose();
        _preview = preview;
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = 'Acteurs indisponibles : $error');
      }
    }
  }

  void _cancel() {
    _dragPoint = null;
    _dragOrigin = null;
    _dragDestination = null;
    widget.transport.stop();
    widget.view.mode = CinematicMapMode.select;
    widget.changed();
    setState(() {});
  }

  @override
  void dispose() {
    _request++;
    _preview?.dispose();
    _camera.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _start(int x, int z, SpatialSceneContentHit? hit) {
    if (widget.transport.previewActive ||
        widget.view.mode != CinematicMapMode.select) {
      return false;
    }
    final point = widget.model.asset.stageContext?.stagePoints
        .where((point) => point.x.floor() == x && point.y.floor() == z)
        .firstOrNull;
    if (point == null || !widget.beforeSelect()) return false;
    _focus.requestFocus();
    _dragPoint = point;
    _dragOrigin = Offset(x.toDouble(), z.toDouble());
    _dragDestination = Offset(point.x, point.y);
    return true;
  }

  void _finish() {
    final point = _dragPoint, destination = _dragDestination;
    _dragPoint = null;
    _dragOrigin = null;
    _dragDestination = null;
    if (point != null &&
        destination != null &&
        destination != Offset(point.x, point.y)) {
      widget.onPointMove(point, destination);
    }
    setState(() {});
  }

  CinematicViewportFrame? _viewportFrame() {
    final transport = widget.transport, model = widget.model;
    final player = model.actors.actors
        .where((actor) => actor.bindingKind == CinematicActorBindingKind.player)
        .firstOrNull;
    final origin = player?.position;
    if (_plan != transport.plan) {
      _plan = transport.plan;
      _projection = _plan == null
          ? null
          : CinematicViewportProjection(
              plan: _plan!,
              cellWidth: 1,
              cellHeight: 1,
              initialCamera: CinematicViewportCamera(
                centerX: origin?.x?.toDouble() ?? model.map.size.width / 2,
                centerY: origin?.y?.toDouble() ?? model.map.size.height / 2,
                visibleWidth: 15,
                visibleHeight: 11,
              ),
            );
    }
    return transport.previewActive
        ? _projection?.frameAt(transport.timeMs)
        : null;
  }

  ({double x, double y, double z, double zoom})? _cameraPose() {
    final frame = _viewportFrame();
    if (frame == null) return null;
    final x = frame.camera.centerX + frame.shakeOffsetX;
    final z = frame.camera.centerY;
    return (
      x: x - _camera.pan.dx,
      y: widget.model.map.spatialScene!.worldHeightAt(x, z),
      z: z - _camera.pan.dy,
      zoom: _camera.zoom * 15 / frame.camera.visibleWidth,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: CinematicTransportListenable(widget.transport),
    builder: (context, _) {
      final view = widget.view, model = widget.model;
      final playing = widget.transport.previewActive;
      final viewportFrame = _viewportFrame();
      final color = Theme.of(context).colorScheme.primary;
      final actor = model.actors.actorById(view.actorId ?? '');
      final pose = widget.transport.frame?.actorPoseById(actor?.actorId ?? '');
      final x = pose?.x ?? actor?.position.x?.toDouble(),
          z = pose?.y ?? actor?.position.y?.toDouble();
      return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
        child: Focus(
          focusNode: _focus,
          child: StudioGraphCard(
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: playing,
                    child: StudioSpatialMapPreview(
                      map: model.background,
                      project: model.project,
                      visuals: widget.visuals,
                      controller: _camera,
                      selectedContent:
                          playing || actor == null || x == null || z == null
                          ? null
                          : SpatialSceneContentHit(
                              kind: SpatialSceneContentKind.actor,
                              id:
                                  actor.bindingKind ==
                                      CinematicActorBindingKind.player
                                  ? 'hero'
                                  : 'cinematic:${actor.actorId}',
                              cell: (x.floor(), z.floor()),
                            ),
                      selectContent: view.mode == CinematicMapMode.select,
                      cameraPose: _cameraPose,
                      actorFrames: (_) =>
                          _preview?.frames(
                            model.asset,
                            widget.transport.plan,
                            widget.transport.frame,
                            widget.transport.timeMs,
                          ) ??
                          const {},
                      onContent: (hit) {
                        if (hit.kind != SpatialSceneContentKind.actor ||
                            !widget.beforeSelect()) {
                          return;
                        }
                        final selected = hit.id == 'hero'
                            ? model.actors.actors
                                  .where(
                                    (actor) =>
                                        actor.bindingKind ==
                                        CinematicActorBindingKind.player,
                                  )
                                  .firstOrNull
                                  ?.actorId
                            : hit.id.startsWith('cinematic:')
                            ? hit.id.substring(10)
                            : null;
                        if (selected == null) return;
                        _focus.requestFocus();
                        view.actorId = selected;
                        view.selection.clear();
                        view.inspectorTab = 'actors';
                        widget.changed();
                      },
                      onCell: (x, z) {
                        if (view.mode != CinematicMapMode.select &&
                            view.mode != CinematicMapMode.pan) {
                          _focus.requestFocus();
                          widget.onPoint(Offset(x + .5, z + .5));
                        }
                      },
                      onHover: (hit) {
                        if (_hover?.cell == hit?.cell) return;
                        setState(() => _hover = hit);
                      },
                      onDragStart: _start,
                      onDragUpdate: (cell) {
                        if (_dragPoint == null || _dragOrigin == null) return;
                        setState(
                          () => _dragDestination = Offset(
                            _dragPoint!.x + cell.$1 - _dragOrigin!.dx,
                            _dragPoint!.y + cell.$2 - _dragOrigin!.dy,
                          ),
                        );
                      },
                      onDragEnd: _finish,
                      onDragCancel: () => setState(() {
                        _dragPoint = null;
                        _dragOrigin = null;
                        _dragDestination = null;
                      }),
                      overlays: playing
                          ? const []
                          : [
                              ...cinematicSpatialOverlays(model, color),
                              if (_dragDestination case final point?)
                                SpatialCellOverlay(
                                  id: 'drag-point',
                                  cell: (point.dx.floor(), point.dy.floor()),
                                  kind: SpatialCellOverlayKind.preview,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              if (_hover != null &&
                                  view.mode != CinematicMapMode.select &&
                                  view.mode != CinematicMapMode.pan)
                                SpatialCellOverlay(
                                  id: 'hover-point',
                                  cell: _hover!.cell,
                                  kind: SpatialCellOverlayKind.preview,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                            ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      StudioTool(
                        label: 'Sélectionner un acteur',
                        icon: Icons.near_me_outlined,
                        selected: view.mode == CinematicMapMode.select,
                        onPressed: () {
                          widget.transport.stop();
                          view.mode = CinematicMapMode.select;
                          widget.changed();
                        },
                      ),
                      StudioTool(
                        label: 'Déplacer la vue',
                        icon: Icons.pan_tool_outlined,
                        selected: view.mode == CinematicMapMode.pan,
                        onPressed: () {
                          widget.transport.stop();
                          view.mode = CinematicMapMode.pan;
                          widget.changed();
                        },
                      ),
                      StudioTool(
                        label: 'Réduire la carte',
                        icon: Icons.remove,
                        onPressed: playing ? null : () => _camera.dolly(220),
                      ),
                      StudioTool(
                        label: 'Agrandir la carte',
                        icon: Icons.add,
                        onPressed: playing ? null : () => _camera.dolly(-220),
                      ),
                      StudioTool(
                        label: 'Cadrer la carte',
                        icon: Icons.fit_screen,
                        onPressed: playing ? null : _camera.reset,
                      ),
                    ],
                  ),
                ),
                if (view.mode != CinematicMapMode.select &&
                    view.mode != CinematicMapMode.pan)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: IgnorePointer(
                      child: StudioNotice(
                        '${view.mode == CinematicMapMode.destination
                            ? 'Destination'
                            : view.mode == CinematicMapMode.path
                            ? 'Point de trajet'
                            : 'Placement initial'} : cliquez sur une case · Échap pour annuler${_hover == null ? '' : ' · (${_hover!.cell.$1 + .5}, ${_hover!.cell.$2 + .5})'}',
                      ),
                    ),
                  ),
                if (_error != null)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: StudioNotice(_error!, isError: true),
                  ),
                if (playing)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.scrim.withValues(
                          alpha: viewportFrame?.fadeOpacity ?? 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

List<SpatialCellOverlay> cinematicSpatialOverlays(
  CinematicMapModel model,
  Color color,
) {
  final cells = <(int, int)>{};
  final points = {
    for (final point
        in model.asset.stageContext?.stagePoints ?? <CinematicStagePoint>[])
      point.id: Offset(point.x, point.y),
  };
  void line(Offset start, Offset end) {
    final count =
        math.max((end.dx - start.dx).abs(), (end.dy - start.dy).abs()).ceil() *
        2;
    for (var i = 0; i <= count; i++) {
      final point = Offset.lerp(start, end, count == 0 ? 0 : i / count)!;
      cells.add((point.dx.floor(), point.dy.floor()));
    }
  }

  final positions = {
    for (final actor in model.actors.actors)
      if (actor.position.isResolved)
        actor.actorId: Offset(
          actor.position.x!.toDouble(),
          actor.position.y!.toDouble(),
        ),
  };
  for (final step in model.asset.timeline.steps.where(
    (step) => step.kind == CinematicTimelineStepKind.actorMove,
  )) {
    var origin = positions[step.actorId];
    if (origin == null) continue;
    final path = model.asset.stageContext?.manualPaths
        .where((path) => path.ownerActorMoveStepId == step.id)
        .firstOrNull;
    for (final id in path?.waypointStagePointIds ?? <String>[]) {
      final point = points[id];
      if (point != null) {
        line(origin!, point);
        origin = point;
      }
    }
    final binding = model.asset.stageContext?.movementTargetBindings
        .where((binding) => binding.targetId == step.targetId)
        .firstOrNull;
    final target =
        binding?.kind == CinematicMovementTargetBindingKind.stagePoint
        ? points[binding?.sourceId]
        : null;
    final external = model.targets[step.targetId];
    final end =
        target ?? (external == null ? null : Offset(external.x, external.y));
    if (end != null) {
      line(origin!, end);
      positions[step.actorId!] = end;
    }
  }
  cells.addAll(
    points.values.map((point) => (point.dx.floor(), point.dy.floor())),
  );
  return [
    for (final cell in cells)
      SpatialCellOverlay(
        id: 'cinematic-path:${cell.$1}:${cell.$2}',
        cell: cell,
        kind: SpatialCellOverlayKind.preview,
        color: color,
      ),
  ];
}
