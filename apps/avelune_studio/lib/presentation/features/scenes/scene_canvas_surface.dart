import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/theme/studio_tokens.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_layer.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_minimap.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_painter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_types.dart';

class SceneCanvasSurface extends StatelessWidget {
  const SceneCanvasSurface({
    super.key,
    required this.canvasKey,
    required this.geometry,
    required this.viewport,
    required this.positions,
    required this.onSelect,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onCancel,
    required this.onWireStart,
    required this.onWireMove,
    required this.onWireEnd,
    required this.onBackgroundTap,
    required this.onContext,
    required this.onDrop,
    required this.onSize,
    required this.onToggleMinimap,
    required this.showMinimap,
    this.selectedNodeId,
    this.selectedEdgeId,
    this.sourceNodeId,
    this.targetNodeId,
    this.previewStart,
    this.previewEnd,
    this.highlightedNodes = const {},
    this.highlightedEdges = const {},
    this.summary,
  });
  final GlobalKey canvasKey;
  final SceneCanvasGeometry geometry;
  final SceneGraphViewport viewport;
  final Map<String, Offset> positions;
  final String? selectedNodeId, selectedEdgeId, sourceNodeId, targetNodeId;
  final Offset? previewStart, previewEnd;
  final Set<String> highlightedNodes, highlightedEdges;
  final bool showMinimap;
  final ValueChanged<String> onSelect, onDragStart;
  final ValueChanged<Offset> onDragMove, onWireMove, onBackgroundTap, onContext;
  final VoidCallback onDragEnd, onCancel, onWireEnd, onToggleMinimap;
  final void Function(String, String) onWireStart;
  final void Function(SceneBlockDragData, Offset) onDrop;
  final ValueChanged<Size> onSize;
  final String Function(SceneNode)? summary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      onSize(size);
      final colors = Theme.of(context).colorScheme;
      final tokens = StudioColors.of(context);
      return DragTarget<SceneBlockDragData>(
        onAcceptWithDetails: (details) => onDrop(details.data, details.offset),
        builder: (_, candidates, _) => ClipRect(
          child: Material(
            color: colors.surfaceContainerLowest,
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent && sourceNodeId == null) {
                  GestureBinding.instance.pointerSignalResolver.register(
                    event,
                    (_) => viewport.zoomAt(
                      viewport.zoom * (event.scrollDelta.dy > 0 ? .9 : 1.1),
                      event.localPosition,
                    ),
                  );
                }
              },
              onPointerPanZoomStart: (event) {
                viewport.startTrackpad(event.localPosition);
              },
              onPointerPanZoomUpdate: (event) {
                if (sourceNodeId == null) {
                  viewport.updateTrackpad(
                    event.scale,
                    event.pan,
                    event.localPosition,
                  );
                }
              },
              onPointerPanZoomEnd: (_) {
                viewport.trackpadActive = false;
              },
              child: Stack(
                key: canvasKey,
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    key: const ValueKey('scene-graph-pan-surface'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (e) => onBackgroundTap(e.localPosition),
                    onPanUpdate: sourceNodeId == null
                        ? (e) {
                            if (!viewport.trackpadActive) {
                              viewport.translate(e.delta);
                            }
                          }
                        : null,
                    onSecondaryTapDown: (e) => onContext(e.localPosition),
                    child: CustomPaint(
                      painter: SceneCanvasPainter(
                        geometry: geometry,
                        viewport: viewport,
                        positions: positions,
                        gridColor: colors.outlineVariant.withValues(alpha: .35),
                        wireColor: colors.primary.withValues(alpha: .8),
                        selectionColor: tokens.canvasSelection,
                        successColor: tokens.success,
                        falseColor: colors.error,
                        selectedEdgeId: selectedEdgeId,
                        highlighted: highlightedEdges,
                        previewStart: previewStart,
                        previewEnd: previewEnd,
                      ),
                    ),
                  ),
                  SceneCanvasLayer(
                    geometry: geometry,
                    viewport: viewport,
                    positions: positions,
                    selectedNodeId: selectedNodeId,
                    sourceNodeId: sourceNodeId,
                    targetNodeId: targetNodeId,
                    highlighted: highlightedNodes,
                    summary: summary,
                    onSelect: onSelect,
                    onDragStart: onDragStart,
                    onDragMove: onDragMove,
                    onDragEnd: onDragEnd,
                    onCancel: onCancel,
                    onWireStart: onWireStart,
                    onWireMove: onWireMove,
                    onWireEnd: onWireEnd,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: colors.surface.withValues(alpha: .96),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const ValueKey('scene-graph-zoom-out'),
                            tooltip: 'Dézoomer',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => viewport.zoomAt(
                              viewport.zoom * .9,
                              size.center(Offset.zero),
                            ),
                            icon: const Icon(Icons.remove, size: 18),
                          ),
                          Text(
                            '${(viewport.zoom * 100).round()} %',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          IconButton(
                            key: const ValueKey('scene-graph-zoom-in'),
                            tooltip: 'Zoomer',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => viewport.zoomAt(
                              viewport.zoom * 1.1,
                              size.center(Offset.zero),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Cadrer la scène',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                viewport.fit(geometry.bounds(positions)),
                            icon: const Icon(Icons.fit_screen, size: 18),
                          ),
                          if (selectedNodeId != null &&
                              geometry.nodes.containsKey(selectedNodeId))
                            IconButton(
                              tooltip: 'Cadrer la sélection',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => viewport.centerOn(
                                geometry
                                    .nodeRect(selectedNodeId!, positions)
                                    .center,
                              ),
                              icon: const Icon(
                                Icons.center_focus_strong,
                                size: 18,
                              ),
                            ),
                          IconButton(
                            tooltip: 'Afficher / masquer la mini-carte',
                            visualDensity: VisualDensity.compact,
                            onPressed: onToggleMinimap,
                            icon: const Icon(Icons.map_outlined, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showMinimap && size.width > 350 && size.height > 250)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: SceneCanvasMinimap(
                        geometry: geometry,
                        viewport: viewport,
                      ),
                    ),
                  if (sourceNodeId != null)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Material(
                        color: colors.surface,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Reliez une entrée · Échap pour annuler',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
