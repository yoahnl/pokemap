import 'cinematic_transport_listenable.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_preview_transport.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'cinematic_map_model.dart';
import 'cinematic_map_overlay.dart';
import 'cinematic_playback_viewport.dart';
import 'cinematic_view_state.dart';

class CinematicMapScene extends StatefulWidget {
  const CinematicMapScene({
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
  State<CinematicMapScene> createState() => _CinematicMapSceneState();
}

class _CinematicMapSceneState extends State<CinematicMapScene> {
  bool fitted = false;
  Size? previousSize;
  @override
  Widget build(BuildContext context) {
    final model = widget.model, view = widget.view;
    final cell = Size(
      model.project.settings.tileWidth *
          model.project.settings.displayScale.toDouble(),
      model.project.settings.tileHeight *
          model.project.settings.displayScale.toDouble(),
    );
    final mapSize = Size(
      model.map.size.width * cell.width,
      model.map.size.height * cell.height,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        void fit() {
          widget.transport.stop();
          final scale = math
              .min(
                viewport.width / mapSize.width,
                viewport.height / mapSize.height,
              )
              .clamp(.1, 8.0);
          view.mapTransform.value = Matrix4.identity()
            ..translateByDouble(
              (viewport.width - mapSize.width * scale) / 2,
              (viewport.height - mapSize.height * scale) / 2,
              0,
              1,
            )
            ..scaleByDouble(scale, scale, 1, 1);
        }

        if (!fitted) {
          fitted = true;
          if (view.mapTransform.value == Matrix4.identity()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) fit();
            });
          }
        }
        final previous = previousSize;
        previousSize = viewport;
        if (previous != null && previous != viewport) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || previousSize != viewport) return;
            final m = view.mapTransform.value.clone();
            m.setEntry(
              0,
              3,
              m.entry(0, 3) + (viewport.width - previous.width) / 2,
            );
            m.setEntry(
              1,
              3,
              m.entry(1, 3) + (viewport.height - previous.height) / 2,
            );
            view.mapTransform.value = m;
          });
        }
        void zoom(double factor) {
          widget.transport.stop();
          final current = view.mapTransform.value.getMaxScaleOnAxis();
          final target = (current * factor).clamp(.1, 8.0);
          view.mapTransform.value = view.mapTransform.value.clone()
            ..scaleByDouble(target / current, target / current, 1, 1);
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              widget.transport.stop();
              view.mode = CinematicMapMode.select;
              widget.changed();
            },
          },
          child: Focus(
            child: StudioGraphCard(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: CinematicTransportListenable(widget.transport),
                      builder: (context, child) => Offstage(
                        offstage: widget.transport.previewActive,
                        child: child,
                      ),
                      child: ClipRect(
                        child: InteractiveViewer(
                          key: const ValueKey('cinematic-map-viewport'),
                          transformationController: view.mapTransform,
                          constrained: false,
                          alignment: Alignment.topLeft,
                          minScale: .1,
                          maxScale: 8,
                          boundaryMargin: const EdgeInsets.all(500),
                          panEnabled:
                              view.mode == CinematicMapMode.pan ||
                              view.mode == CinematicMapMode.select,
                          child: GestureDetector(
                            key: const ValueKey('cinematic-map-pick'),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (event) => widget.onPoint(
                              Offset(
                                (event.localPosition.dx / cell.width)
                                    .floorToDouble(),
                                (event.localPosition.dy / cell.height)
                                    .floorToDouble(),
                              ),
                            ),
                            child: SizedBox(
                              width: mapSize.width,
                              height: mapSize.height,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: RepaintBoundary(
                                      child: widget.visuals.canvas(
                                        model.background,
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: CinematicMapOverlay(
                                      model: model,
                                      visuals: widget.visuals,
                                      transport: widget.transport,
                                      view: view,
                                      cell: cell,
                                      changed: widget.changed,
                                      onPointMove: widget.onPointMove,
                                      beforeSelect: widget.beforeSelect,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: CinematicTransportListenable(widget.transport),
                      builder: (context, _) => !widget.transport.previewActive
                          ? const SizedBox.shrink()
                          : ColoredBox(
                              color: Theme.of(context).colorScheme.surface,
                              child: CinematicPlaybackViewport(
                                model: model,
                                transport: widget.transport,
                                viewport: viewport,
                                cell: cell,
                                child: SizedBox(
                                  width: mapSize.width,
                                  height: mapSize.height,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: widget.visuals.canvas(
                                          model.background,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: CinematicMapOverlay(
                                          model: model,
                                          visuals: widget.visuals,
                                          transport: widget.transport,
                                          view: view,
                                          cell: cell,
                                          changed: widget.changed,
                                          onPointMove: widget.onPointMove,
                                          beforeSelect: widget.beforeSelect,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                          onPressed: () => zoom(.8),
                        ),
                        StudioTool(
                          label: 'Agrandir la carte',
                          icon: Icons.add,
                          onPressed: () => zoom(1.25),
                        ),
                        StudioTool(
                          label: 'Cadrer la carte',
                          icon: Icons.fit_screen,
                          onPressed: fit,
                        ),
                      ],
                    ),
                  ),
                  if (view.mode != CinematicMapMode.select &&
                      view.mode != CinematicMapMode.pan)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: StudioGraphCard(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${view.mode == CinematicMapMode.destination
                                ? 'Destination'
                                : view.mode == CinematicMapMode.path
                                ? 'Point de trajet'
                                : 'Placement initial'} : cliquez sur une case · Échap pour annuler',
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
}
