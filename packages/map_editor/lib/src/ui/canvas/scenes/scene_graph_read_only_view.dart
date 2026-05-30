import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

typedef SceneNodeLayoutChanged = Future<void> Function({
  required String nodeId,
  required double x,
  required double y,
});

typedef SceneVisualEdgeDraftCreator = Future<void> Function({
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
});

class SceneGraphReadOnlyView extends StatefulWidget {
  const SceneGraphReadOnlyView({
    super.key,
    required this.scene,
    this.selectedNodeId,
    this.selectedEdgeId,
    this.onSelectNode,
    this.onSelectEdge,
    this.onUpdateNodeLayout,
    this.onCreateEdgeDraft,
    this.canDragNodes = true,
    this.expandToFill = false,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final ValueChanged<String>? onSelectNode;
  final ValueChanged<String>? onSelectEdge;
  final SceneNodeLayoutChanged? onUpdateNodeLayout;
  final SceneVisualEdgeDraftCreator? onCreateEdgeDraft;
  final bool canDragNodes;
  final bool expandToFill;

  @override
  State<SceneGraphReadOnlyView> createState() => _SceneGraphReadOnlyViewState();
}

class _SceneGraphReadOnlyViewState extends State<SceneGraphReadOnlyView> {
  static const double _minZoom = 0.5;
  static const double _maxZoom = 2;
  static const double _zoomStep = 0.25;

  double _zoom = 1;
  Offset _pan = Offset.zero;
  double _trackpadGestureStartZoom = 1;
  final Map<String, Offset> _nodePositionOverrides = {};
  final GlobalKey _canvasKey = GlobalKey();
  _SceneGraphVisualConnection? _visualConnection;

  @override
  void didUpdateWidget(covariant SceneGraphReadOnlyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.id != widget.scene.id) {
      _zoom = 1;
      _pan = Offset.zero;
      _nodePositionOverrides.clear();
      _visualConnection = null;
      return;
    }

    final nodeIds = widget.scene.graph.nodes.map((node) => node.id).toSet();
    _nodePositionOverrides
        .removeWhere((nodeId, _) => !nodeIds.contains(nodeId));
    if (_visualConnection != null &&
        !nodeIds.contains(_visualConnection!.fromNodeId)) {
      _visualConnection = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final layout = _SceneGraphLayoutPlan.fromScene(scene);
    final worldPositions = _worldPositionsFor(layout);
    final screenPositions = _screenPositionsFor(worldPositions);
    final inputPorts = _inputPortPlacements(screenPositions);
    final outputPorts = _outputPortPlacements(screenPositions);
    final edgeColors = _SceneGraphEdgeColors.fromTokens(colors);
    final canvas = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.backgroundShell,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Listener(
          onPointerPanZoomStart: _handleTrackpadPanZoomStart,
          onPointerPanZoomUpdate: _handleTrackpadPanZoomUpdate,
          onPointerPanZoomEnd: _handleTrackpadPanZoomEnd,
          child: Stack(
            key: _canvasKey,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('scene-graph-pan-surface'),
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: _handleCanvasPanUpdate,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          key: const ValueKey('scene-graph-grid'),
                          painter: _SceneGraphGridPainter(
                            pan: _pan,
                            zoom: _zoom,
                            lineColor:
                                colors.borderSubtle.withValues(alpha: 0.32),
                            majorLineColor:
                                colors.borderStrong.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SceneGraphEdgePainter(
                            edges: scene.graph.edges,
                            positions: screenPositions,
                            outputPortCenters:
                                _outputPortCentersByKey(outputPorts),
                            inputPortCenters:
                                _inputPortCentersByNodeId(inputPorts),
                            zoom: _zoom,
                            selectedEdgeId: selectedEdgeId,
                            edgeColors: edgeColors,
                            selectedShadowColor: colors.focusRing,
                            labelColor: colors.textSecondary,
                            labelBackground: colors.cardSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final edge in scene.graph.edges)
                _SceneGraphEdgeLabel(
                  edge: edge,
                  position: _screenOffset(
                    _edgeLabelPosition(edge, worldPositions),
                  ),
                  isSelected: edge.id == selectedEdgeId,
                  onTap: null,
                ),
              if (_visualConnection != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey(
                        'scene-graph-connection-preview-wire',
                      ),
                      painter: _SceneGraphConnectionPreviewPainter(
                        connection: _visualConnection!,
                        lineColor: edgeColors.forKind(
                          _visualConnection!.edgeKind,
                        ),
                        shadowColor: colors.borderStrong,
                      ),
                    ),
                  ),
                ),
              for (final node in scene.graph.nodes)
                _SceneGraphNodeCard(
                  node: node,
                  position: screenPositions[node.id]!,
                  zoom: _zoom,
                  isSelected: node.id == selectedNodeId,
                  canDrag: widget.canDragNodes && _visualConnection == null,
                  onSelect: onSelectNode == null
                      ? null
                      : () => onSelectNode!(node.id),
                  onDragDelta: (delta) => _moveNodeLocally(node.id, delta),
                  onDragEnd: () => _persistNodeLayout(node.id),
                ),
              for (final port in inputPorts)
                _SceneGraphInputPortHandle(
                  placement: port,
                  isCompatible: _isCompatibleInputPort(port.nodeId),
                  isHovered:
                      _visualConnection?.hoveredTargetNodeId == port.nodeId,
                  connectionColor: _visualConnection == null
                      ? null
                      : edgeColors.forKind(_visualConnection!.edgeKind),
                ),
              for (final port in outputPorts)
                _SceneGraphOutputPortHandle(
                  placement: port,
                  isDisabled: _isOutputPortUsed(
                    port.nodeId,
                    port.port.id,
                  ),
                  toneColor: edgeColors.forKind(port.port.edgeKind),
                  onStart: () => _startVisualConnection(port),
                  onUpdate: _updateVisualConnection,
                  onEnd: _endVisualConnection,
                ),
              for (final edge in scene.graph.edges)
                _SceneGraphEdgeHitTarget(
                  edgeId: edge.id,
                  position: _screenOffset(
                    _edgeLabelPosition(edge, worldPositions),
                  ),
                  onTap: widget.onSelectEdge == null
                      ? null
                      : () => widget.onSelectEdge!(edge.id),
                ),
            ],
          ),
        ),
      ),
    );

    return PokeMapCard(
      key: const ValueKey('scene-graph-read-only-view'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.flowchart,
                tone: PokeMapTone.narrative,
                size: 34,
                iconSize: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Canvas Blueprint',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SceneGraphBadge(
                key: ValueKey(
                  layout.usesPersistedLayout
                      ? 'scene-graph-layout-source-real'
                      : 'scene-graph-layout-source-derived',
                ),
                label: layout.usesPersistedLayout
                    ? 'Layout réel'
                    : 'Layout dérivé',
              ),
              const SizedBox(width: 8),
              _SceneGraphCanvasControls(
                zoom: _zoom,
                onZoomOut: () => _setZoom(_zoom - _zoomStep),
                onZoomReset: () => _setZoom(1),
                onZoomIn: () => _setZoom(_zoom + _zoomStep),
                onResetView: _resetView,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (expandToFill)
            Expanded(child: canvas)
          else
            SizedBox(height: layout.canvasHeight, child: canvas),
        ],
      ),
    );
  }

  NarrativeSceneSummary get scene => widget.scene;
  String? get selectedNodeId => widget.selectedNodeId;
  String? get selectedEdgeId => widget.selectedEdgeId;
  ValueChanged<String>? get onSelectNode => widget.onSelectNode;
  bool get expandToFill => widget.expandToFill;

  void _setZoom(double value) {
    setState(() => _applyZoom(value));
  }

  void _applyZoom(double value, {Offset? focalPoint}) {
    final nextZoom = value.clamp(_minZoom, _maxZoom).toDouble();
    if (focalPoint != null && _zoom > 0) {
      final focalWorldPosition = (focalPoint - _pan) / _zoom;
      _pan = focalPoint - (focalWorldPosition * nextZoom);
    }
    _zoom = nextZoom;
  }

  void _resetView() {
    setState(() {
      _zoom = 1;
      _pan = Offset.zero;
    });
  }

  void _handleCanvasPanUpdate(DragUpdateDetails details) {
    if (_visualConnection != null) {
      return;
    }
    setState(() => _pan += details.delta);
  }

  void _handleTrackpadPanZoomStart(PointerPanZoomStartEvent event) {
    if (_visualConnection != null) {
      return;
    }
    _trackpadGestureStartZoom = _zoom;
  }

  void _handleTrackpadPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (_visualConnection != null) {
      return;
    }
    setState(() {
      _applyZoom(
        _trackpadGestureStartZoom * event.scale,
        focalPoint: event.localPosition,
      );
      _pan += event.panDelta;
    });
  }

  void _handleTrackpadPanZoomEnd(PointerPanZoomEndEvent event) {
    if (_visualConnection != null) {
      return;
    }
    _trackpadGestureStartZoom = _zoom;
  }

  void _moveNodeLocally(String nodeId, Offset screenDelta) {
    final layout = _SceneGraphLayoutPlan.fromScene(scene);
    final worldPositions = _worldPositionsFor(layout);
    final current = worldPositions[nodeId];
    if (current == null) {
      return;
    }
    setState(() {
      _nodePositionOverrides[nodeId] = current + (screenDelta / _zoom);
    });
  }

  void _persistNodeLayout(String nodeId) {
    final position = _nodePositionOverrides[nodeId];
    final updater = widget.onUpdateNodeLayout;
    if (position == null || updater == null) {
      return;
    }
    unawaited(updater(nodeId: nodeId, x: position.dx, y: position.dy));
  }

  void _startVisualConnection(_SceneGraphOutputPortPlacement port) {
    if (_isOutputPortUsed(port.nodeId, port.port.id) ||
        widget.onCreateEdgeDraft == null) {
      return;
    }
    onSelectNode?.call(port.nodeId);
    setState(() {
      _visualConnection = _SceneGraphVisualConnection(
        fromNodeId: port.nodeId,
        fromPortId: port.port.id,
        edgeKind: port.port.edgeKind,
        start: port.center,
        current: port.center,
      );
    });
  }

  void _updateVisualConnection(Offset globalPosition) {
    final connection = _visualConnection;
    if (connection == null) {
      return;
    }
    final pointer = _globalToCanvasOffset(globalPosition);
    if (pointer == null) {
      return;
    }
    final snap = _nearestCompatibleInputPort(pointer);
    setState(() {
      _visualConnection = connection.copyWith(
        current: snap?.center ?? pointer,
        hoveredTargetNodeId: snap?.nodeId,
      );
    });
  }

  void _endVisualConnection() {
    final connection = _visualConnection;
    if (connection == null) {
      return;
    }
    setState(() => _visualConnection = null);
    final targetNodeId = connection.hoveredTargetNodeId;
    final createEdge = widget.onCreateEdgeDraft;
    if (targetNodeId == null || createEdge == null) {
      return;
    }
    unawaited(createEdge(
      fromNodeId: connection.fromNodeId,
      fromPortId: connection.fromPortId,
      toNodeId: targetNodeId,
    ));
  }

  Offset? _globalToCanvasOffset(Offset globalPosition) {
    final context = _canvasKey.currentContext;
    if (context == null) {
      return null;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return null;
    }
    return renderObject.globalToLocal(globalPosition);
  }

  _SceneGraphInputPortPlacement? _nearestCompatibleInputPort(Offset pointer) {
    final layout = _SceneGraphLayoutPlan.fromScene(scene);
    final inputPorts = _inputPortPlacements(
      _screenPositionsFor(_worldPositionsFor(layout)),
    );
    _SceneGraphInputPortPlacement? nearest;
    var nearestDistance = double.infinity;
    for (final port in inputPorts) {
      if (!_isCompatibleInputPort(port.nodeId)) {
        continue;
      }
      final distance = (port.center - pointer).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = port;
      }
    }
    if (nearestDistance <= _SceneGraphPortMetrics.snapRadius * _zoom) {
      return nearest;
    }
    return null;
  }

  bool _isCompatibleInputPort(String nodeId) {
    final connection = _visualConnection;
    if (connection == null) {
      return false;
    }
    return nodeId != connection.fromNodeId && _hasInputPort(nodeId);
  }

  bool _hasInputPort(String nodeId) {
    for (final node in scene.graph.nodes) {
      if (node.id == nodeId) {
        return switch (node.kind) {
          SceneNodeKind.condition ||
          SceneNodeKind.merge ||
          SceneNodeKind.end =>
            true,
          SceneNodeKind.start ||
          SceneNodeKind.yarnDialogue ||
          SceneNodeKind.action ||
          SceneNodeKind.battle ||
          SceneNodeKind.cinematic ||
          SceneNodeKind.branchByOutcome =>
            false,
        };
      }
    }
    return false;
  }

  bool _isOutputPortUsed(String nodeId, String portId) {
    for (final edge in scene.graph.edges) {
      if (edge.fromNodeId == nodeId && edge.fromPortId == portId) {
        return true;
      }
    }
    return false;
  }

  List<_SceneGraphInputPortPlacement> _inputPortPlacements(
    Map<String, Offset> screenPositions,
  ) {
    return [
      for (final node in scene.graph.nodes)
        if (_hasInputPort(node.id))
          _SceneGraphInputPortPlacement(
            nodeId: node.id,
            center: _inputPortCenter(screenPositions[node.id]!),
          ),
    ];
  }

  List<_SceneGraphOutputPortPlacement> _outputPortPlacements(
    Map<String, Offset> screenPositions,
  ) {
    final placements = <_SceneGraphOutputPortPlacement>[];
    for (final node in scene.graph.nodes) {
      final ports = authorableSceneOutputPortsForNode(node);
      for (var index = 0; index < ports.length; index++) {
        placements.add(
          _SceneGraphOutputPortPlacement(
            nodeId: node.id,
            port: ports[index],
            center: _outputPortCenter(
              screenPositions[node.id]!,
              index,
              ports.length,
            ),
          ),
        );
      }
    }
    return placements;
  }

  Map<String, Offset> _inputPortCentersByNodeId(
    List<_SceneGraphInputPortPlacement> ports,
  ) {
    return {
      for (final port in ports) port.nodeId: port.center,
    };
  }

  Map<String, Offset> _outputPortCentersByKey(
    List<_SceneGraphOutputPortPlacement> ports,
  ) {
    return {
      for (final port in ports)
        _sceneGraphPortKey(port.nodeId, port.port.id): port.center,
    };
  }

  Offset _inputPortCenter(Offset nodePosition) {
    return Offset(
      nodePosition.dx,
      nodePosition.dy + (_SceneGraphLayoutPlan.nodeHeight * _zoom / 2),
    );
  }

  Offset _outputPortCenter(
    Offset nodePosition,
    int index,
    int count,
  ) {
    final height = _SceneGraphLayoutPlan.nodeHeight * _zoom;
    final y = count == 1 ? height / 2 : height * ((index + 1) / (count + 1));
    return Offset(
      nodePosition.dx + (_SceneGraphLayoutPlan.nodeWidth * _zoom),
      nodePosition.dy + y,
    );
  }

  Map<String, Offset> _worldPositionsFor(_SceneGraphLayoutPlan layout) {
    return {
      for (final entry in layout.positions.entries)
        entry.key: _nodePositionOverrides[entry.key] ?? entry.value,
    };
  }

  Map<String, Offset> _screenPositionsFor(Map<String, Offset> positions) {
    return {
      for (final entry in positions.entries)
        entry.key: _screenOffset(entry.value),
    };
  }

  Offset _screenOffset(Offset worldOffset) {
    return (worldOffset * _zoom) + _pan;
  }

  Offset _edgeLabelPosition(
    SceneEdge edge,
    Map<String, Offset> worldPositions,
  ) {
    final from = worldPositions[edge.fromNodeId];
    final to = worldPositions[edge.toNodeId];
    if (from == null || to == null) {
      return const Offset(12, 12);
    }
    return Offset(
      (from.dx + to.dx + _SceneGraphLayoutPlan.nodeWidth) / 2 - 38,
      (from.dy + to.dy + _SceneGraphLayoutPlan.nodeHeight) / 2 - 14,
    );
  }
}

class _SceneGraphNodeCard extends StatelessWidget {
  const _SceneGraphNodeCard({
    required this.node,
    required this.position,
    required this.zoom,
    required this.isSelected,
    required this.canDrag,
    required this.onSelect,
    required this.onDragDelta,
    required this.onDragEnd,
  });

  final SceneNode node;
  final Offset position;
  final double zoom;
  final bool isSelected;
  final bool canDrag;
  final VoidCallback? onSelect;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = _toneForNode(node.kind);
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: _SceneGraphLayoutPlan.nodeWidth * zoom,
      height: _SceneGraphLayoutPlan.nodeHeight * zoom,
      child: GestureDetector(
        key: ValueKey('scene-graph-node-drag-target-${node.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        onPanStart: canDrag ? (_) => onSelect?.call() : null,
        onPanUpdate: canDrag ? (details) => onDragDelta(details.delta) : null,
        onPanEnd: canDrag ? (_) => onDragEnd() : null,
        onPanCancel: canDrag ? onDragEnd : null,
        child: Stack(
          children: [
            if (isSelected)
              Positioned.fill(
                child: DecoratedBox(
                  key: ValueKey('scene-graph-node-selected-${node.id}'),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.focusRing, width: 2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            Positioned.fill(
              child: Transform.scale(
                alignment: Alignment.topLeft,
                scale: zoom,
                child: SizedBox(
                  width: _SceneGraphLayoutPlan.nodeWidth,
                  height: _SceneGraphLayoutPlan.nodeHeight,
                  child: Padding(
                    padding:
                        isSelected ? const EdgeInsets.all(3) : EdgeInsets.zero,
                    child: PokeMapCard(
                      key: ValueKey('scene-graph-node-${node.id}'),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              PokeMapIconTile(
                                icon: _iconForNode(node.kind),
                                tone: tone,
                                size: 24,
                                iconSize: 13,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  node.title ?? _nodeKindLabel(node.kind),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _nodeKindLabel(node.kind),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (node.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              node.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 10,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SceneGraphVisualConnection {
  const _SceneGraphVisualConnection({
    required this.fromNodeId,
    required this.fromPortId,
    required this.edgeKind,
    required this.start,
    required this.current,
    this.hoveredTargetNodeId,
  });

  final String fromNodeId;
  final String fromPortId;
  final SceneEdgeKind edgeKind;
  final Offset start;
  final Offset current;
  final String? hoveredTargetNodeId;

  _SceneGraphVisualConnection copyWith({
    required Offset current,
    required String? hoveredTargetNodeId,
  }) {
    return _SceneGraphVisualConnection(
      fromNodeId: fromNodeId,
      fromPortId: fromPortId,
      edgeKind: edgeKind,
      start: start,
      current: current,
      hoveredTargetNodeId: hoveredTargetNodeId,
    );
  }
}

final class _SceneGraphInputPortPlacement {
  const _SceneGraphInputPortPlacement({
    required this.nodeId,
    required this.center,
  });

  final String nodeId;
  final Offset center;
}

final class _SceneGraphOutputPortPlacement {
  const _SceneGraphOutputPortPlacement({
    required this.nodeId,
    required this.port,
    required this.center,
  });

  final String nodeId;
  final SceneAuthorableOutputPort port;
  final Offset center;
}

abstract final class _SceneGraphPortMetrics {
  static const double visualSize = 14;
  static const double hitSize = 32;
  static const double snapRadius = 30;
}

class _SceneGraphInputPortHandle extends StatelessWidget {
  const _SceneGraphInputPortHandle({
    required this.placement,
    required this.isCompatible,
    required this.isHovered,
    required this.connectionColor,
  });

  final _SceneGraphInputPortPlacement placement;
  final bool isCompatible;
  final bool isHovered;
  final Color? connectionColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final activeColor = connectionColor ?? colors.success;
    final borderColor = isHovered
        ? activeColor
        : isCompatible
            ? activeColor
            : colors.borderStrong;
    final fillColor = isHovered
        ? activeColor.withValues(alpha: 0.28)
        : isCompatible
            ? activeColor.withValues(alpha: 0.2)
            : colors.backgroundShell.withValues(alpha: 0.9);
    return Positioned(
      key: ValueKey('scene-graph-input-port-${placement.nodeId}-in'),
      left: placement.center.dx - (_SceneGraphPortMetrics.hitSize / 2),
      top: placement.center.dy - (_SceneGraphPortMetrics.hitSize / 2),
      width: _SceneGraphPortMetrics.hitSize,
      height: _SceneGraphPortMetrics.hitSize,
      child: Center(
        child: DecoratedBox(
          key: ValueKey(
            isHovered
                ? 'scene-graph-input-port-hover-${placement.nodeId}'
                : isCompatible
                    ? 'scene-graph-input-port-compatible-${placement.nodeId}'
                    : 'scene-graph-input-port-neutral-${placement.nodeId}',
          ),
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: isHovered ? 2.4 : 1.5,
            ),
            boxShadow: [
              if (isCompatible || isHovered)
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.28),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: const SizedBox.square(
            dimension: _SceneGraphPortMetrics.visualSize,
          ),
        ),
      ),
    );
  }
}

class _SceneGraphOutputPortHandle extends StatelessWidget {
  const _SceneGraphOutputPortHandle({
    required this.placement,
    required this.isDisabled,
    required this.toneColor,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final _SceneGraphOutputPortPlacement placement;
  final bool isDisabled;
  final Color toneColor;
  final VoidCallback onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final effectiveToneColor = isDisabled ? colors.textMuted : toneColor;
    return Positioned(
      key: ValueKey(
        'scene-graph-output-port-${placement.nodeId}-${placement.port.id}',
      ),
      left: placement.center.dx - (_SceneGraphPortMetrics.hitSize / 2),
      top: placement.center.dy - (_SceneGraphPortMetrics.hitSize / 2),
      width: _SceneGraphPortMetrics.hitSize + 72,
      height: _SceneGraphPortMetrics.hitSize,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: isDisabled ? null : (_) => onStart(),
        onPointerMove: isDisabled ? null : (event) => onUpdate(event.position),
        onPointerUp: isDisabled ? null : (_) => onEnd(),
        onPointerCancel: isDisabled ? null : (_) => onEnd(),
        child: MouseRegion(
          cursor:
              isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: Row(
            children: [
              SizedBox(
                width: _SceneGraphPortMetrics.hitSize,
                height: _SceneGraphPortMetrics.hitSize,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? colors.backgroundShell.withValues(alpha: 0.85)
                          : effectiveToneColor.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: effectiveToneColor,
                        width: isDisabled ? 1.2 : 1.8,
                      ),
                    ),
                    child: const SizedBox.square(
                      dimension: _SceneGraphPortMetrics.visualSize,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  placement.port.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveToneColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneGraphConnectionPreviewPainter extends CustomPainter {
  const _SceneGraphConnectionPreviewPainter({
    required this.connection,
    required this.lineColor,
    required this.shadowColor,
  });

  final _SceneGraphVisualConnection connection;
  final Color lineColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final start = connection.start;
    final end = connection.current;
    final controlDistance = math.max(44, (end.dx - start.dx).abs() / 2);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + controlDistance,
        start.dy,
        end.dx - controlDistance,
        end.dy,
        end.dx,
        end.dy,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = shadowColor.withValues(alpha: 0.44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(
      covariant _SceneGraphConnectionPreviewPainter oldDelegate) {
    return oldDelegate.connection != connection ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}

class _SceneGraphEdgeLabel extends StatelessWidget {
  const _SceneGraphEdgeLabel({
    required this.edge,
    required this.position,
    required this.isSelected,
    required this.onTap,
  });

  final SceneEdge edge;
  final Offset position;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColor = _SceneGraphEdgeColors.fromTokens(colors).forKind(
      edge.kind,
    );
    return Positioned(
      key: ValueKey('scene-graph-edge-${edge.id}'),
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          key: isSelected
              ? ValueKey('scene-graph-edge-selected-${edge.id}')
              : null,
          decoration: BoxDecoration(
            color: isSelected
                ? toneColor.withValues(alpha: 0.18)
                : colors.controlSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? toneColor : toneColor.withValues(alpha: 0.44),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: toneColor.withValues(alpha: 0.24),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              edge.label ?? '${_edgeKindLabel(edge.kind)} · ${edge.fromPortId}',
              style: TextStyle(
                color: isSelected ? colors.textPrimary : toneColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SceneGraphEdgeHitTarget extends StatelessWidget {
  const _SceneGraphEdgeHitTarget({
    required this.edgeId,
    required this.position,
    required this.onTap,
  });

  final String edgeId;
  final Offset position;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: ValueKey('scene-graph-edge-hit-target-$edgeId'),
      left: position.dx - 10,
      top: position.dy - 8,
      width: 120,
      height: 40,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
      ),
    );
  }
}

class _SceneGraphBadge extends StatelessWidget {
  const _SceneGraphBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SceneGraphCanvasControls extends StatelessWidget {
  const _SceneGraphCanvasControls({
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomReset,
    required this.onZoomIn,
    required this.onResetView,
  });

  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomReset;
  final VoidCallback onZoomIn;
  final VoidCallback onResetView;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapIconButton(
          key: const ValueKey('scene-graph-zoom-out'),
          onPressed: onZoomOut,
          tooltip: 'Zoom arrière',
          variant: PokeMapIconButtonVariant.soft,
          size: 30,
          icon: const Icon(CupertinoIcons.minus),
        ),
        const SizedBox(width: 6),
        PokeMapButton(
          key: const ValueKey('scene-graph-zoom-reset'),
          onPressed: onZoomReset,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          child: Text(
            '${(zoom * 100).round()}%',
            key: const ValueKey('scene-graph-zoom-label'),
          ),
        ),
        const SizedBox(width: 6),
        PokeMapIconButton(
          key: const ValueKey('scene-graph-zoom-in'),
          onPressed: onZoomIn,
          tooltip: 'Zoom avant',
          variant: PokeMapIconButtonVariant.soft,
          size: 30,
          icon: const Icon(CupertinoIcons.plus),
        ),
        const SizedBox(width: 6),
        PokeMapIconButton(
          key: const ValueKey('scene-graph-reset-view'),
          onPressed: onResetView,
          tooltip: 'Recentrer le canvas',
          variant: PokeMapIconButtonVariant.soft,
          size: 30,
          icon: const Icon(CupertinoIcons.scope),
        ),
      ],
    );
  }
}

final class _SceneGraphEdgeColors {
  const _SceneGraphEdgeColors({
    required this.defaultFlow,
    required this.conditionTrue,
    required this.conditionFalse,
    required this.dialogueOutcome,
    required this.battleVictory,
    required this.battleDefeat,
    required this.cinematicCompleted,
    required this.actionCompleted,
    required this.branchOutcome,
    required this.error,
    required this.blocked,
  });

  factory _SceneGraphEdgeColors.fromTokens(PokeMapColorTokens colors) {
    return _SceneGraphEdgeColors(
      defaultFlow: colors.textPrimary.withValues(alpha: 0.86),
      conditionTrue: colors.success,
      conditionFalse: colors.error,
      dialogueOutcome: colors.focusRing,
      battleVictory: colors.success,
      battleDefeat: colors.error,
      cinematicCompleted: colors.warning,
      actionCompleted: colors.warning,
      branchOutcome: colors.focusRing,
      error: colors.error,
      blocked: colors.warning,
    );
  }

  final Color defaultFlow;
  final Color conditionTrue;
  final Color conditionFalse;
  final Color dialogueOutcome;
  final Color battleVictory;
  final Color battleDefeat;
  final Color cinematicCompleted;
  final Color actionCompleted;
  final Color branchOutcome;
  final Color error;
  final Color blocked;

  Color forKind(SceneEdgeKind kind) {
    return switch (kind) {
      SceneEdgeKind.defaultFlow => defaultFlow,
      SceneEdgeKind.conditionTrue => conditionTrue,
      SceneEdgeKind.conditionFalse => conditionFalse,
      SceneEdgeKind.dialogueOutcome => dialogueOutcome,
      SceneEdgeKind.battleVictory => battleVictory,
      SceneEdgeKind.battleDefeat => battleDefeat,
      SceneEdgeKind.cinematicCompleted => cinematicCompleted,
      SceneEdgeKind.actionCompleted => actionCompleted,
      SceneEdgeKind.branchOutcome => branchOutcome,
      SceneEdgeKind.error => error,
      SceneEdgeKind.blocked => blocked,
    };
  }
}

class _SceneGraphGridPainter extends CustomPainter {
  const _SceneGraphGridPainter({
    required this.pan,
    required this.zoom,
    required this.lineColor,
    required this.majorLineColor,
  });

  final Offset pan;
  final double zoom;
  final Color lineColor;
  final Color majorLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = 24 * zoom;
    if (spacing <= 0) {
      return;
    }
    final minorPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = majorLineColor
      ..strokeWidth = 1.2;

    final startX = pan.dx % spacing;
    var column = ((-pan.dx + startX) / spacing).round();
    for (var x = startX; x <= size.width; x += spacing) {
      final paint = column % 4 == 0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      column++;
    }

    final startY = pan.dy % spacing;
    var row = ((-pan.dy + startY) / spacing).round();
    for (var y = startY; y <= size.height; y += spacing) {
      final paint = row % 4 == 0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _SceneGraphGridPainter oldDelegate) {
    return oldDelegate.pan != pan ||
        oldDelegate.zoom != zoom ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.majorLineColor != majorLineColor;
  }
}

class _SceneGraphEdgePainter extends CustomPainter {
  const _SceneGraphEdgePainter({
    required this.edges,
    required this.positions,
    required this.outputPortCenters,
    required this.inputPortCenters,
    required this.zoom,
    required this.selectedEdgeId,
    required this.edgeColors,
    required this.selectedShadowColor,
    required this.labelColor,
    required this.labelBackground,
  });

  final List<SceneEdge> edges;
  final Map<String, Offset> positions;
  final Map<String, Offset> outputPortCenters;
  final Map<String, Offset> inputPortCenters;
  final double zoom;
  final String? selectedEdgeId;
  final _SceneGraphEdgeColors edgeColors;
  final Color selectedShadowColor;
  final Color labelColor;
  final Color labelBackground;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final from = positions[edge.fromNodeId];
      final to = positions[edge.toNodeId];
      if (from == null || to == null) {
        continue;
      }
      final selected = edge.id == selectedEdgeId;
      final lineColor = edgeColors.forKind(edge.kind);
      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = selected ? 2.8 : 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = selected ? StrokeCap.round : StrokeCap.butt;
      final start = outputPortCenters[
              _sceneGraphPortKey(edge.fromNodeId, edge.fromPortId)] ??
          Offset(
            from.dx + (_SceneGraphLayoutPlan.nodeWidth * zoom),
            from.dy + ((_SceneGraphLayoutPlan.nodeHeight * zoom) / 2),
          );
      final end = inputPortCenters[edge.toNodeId] ??
          Offset(
            to.dx,
            to.dy + ((_SceneGraphLayoutPlan.nodeHeight * zoom) / 2),
          );
      final controlDistance =
          math.max(48 * zoom, (end.dx - start.dx).abs() / 2);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + controlDistance,
          start.dy,
          end.dx - controlDistance,
          end.dy,
          end.dx,
          end.dy,
        );
      if (selected) {
        canvas.drawPath(
          path,
          Paint()
            ..color = selectedShadowColor.withValues(alpha: 0.22)
            ..strokeWidth = 8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawPath(path, paint);
      _drawArrow(canvas, paint, end);
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset end) {
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 7, end.dy - 4)
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 7, end.dy + 4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SceneGraphEdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.positions != positions ||
        oldDelegate.outputPortCenters != outputPortCenters ||
        oldDelegate.inputPortCenters != inputPortCenters ||
        oldDelegate.zoom != zoom ||
        oldDelegate.selectedEdgeId != selectedEdgeId ||
        oldDelegate.edgeColors != edgeColors ||
        oldDelegate.selectedShadowColor != selectedShadowColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.labelBackground != labelBackground;
  }
}

class _SceneGraphLayoutPlan {
  const _SceneGraphLayoutPlan({
    required this.positions,
    required this.usesPersistedLayout,
    required this.canvasHeight,
  });

  static const nodeWidth = 168.0;
  static const nodeHeight = 104.0;
  static const horizontalGap = 92.0;
  static const verticalGap = 34.0;

  final Map<String, Offset> positions;
  final bool usesPersistedLayout;
  final double canvasHeight;

  static _SceneGraphLayoutPlan fromScene(NarrativeSceneSummary scene) {
    final persisted = {
      for (final layout in scene.layout.nodeLayouts)
        layout.nodeId: Offset(layout.x, layout.y),
    };
    final hasCompleteLayout =
        scene.graph.nodes.every((node) => persisted.containsKey(node.id));
    final positions = hasCompleteLayout
        ? persisted
        : _derivePositions(scene.graph.nodes, scene.graph.edges);

    final maxY = positions.values.fold<double>(
      0,
      (value, position) => math.max(value, position.dy),
    );
    return _SceneGraphLayoutPlan(
      positions: positions,
      usesPersistedLayout: hasCompleteLayout && positions.isNotEmpty,
      canvasHeight: math.max(280, maxY + nodeHeight + 32),
    );
  }

  static Map<String, Offset> _derivePositions(
    List<SceneNode> nodes,
    List<SceneEdge> edges,
  ) {
    if (nodes.isEmpty) {
      return {};
    }

    final nodeIds = nodes.map((node) => node.id).toSet();
    final adjacency = <String, List<String>>{
      for (final node in nodes) node.id: <String>[],
    };
    final incomingCount = <String, int>{
      for (final node in nodes) node.id: 0,
    };

    for (final edge in edges) {
      if (!nodeIds.contains(edge.fromNodeId) ||
          !nodeIds.contains(edge.toNodeId)) {
        continue;
      }
      adjacency[edge.fromNodeId]!.add(edge.toNodeId);
      incomingCount[edge.toNodeId] = (incomingCount[edge.toNodeId] ?? 0) + 1;
    }

    final levels = <String, int>{};
    final visited = <String>{};

    void traverseFrom(String startNodeId) {
      if (!visited.add(startNodeId)) {
        return;
      }
      levels[startNodeId] = 0;
      final queue = <String>[startNodeId];
      for (var cursor = 0; cursor < queue.length; cursor++) {
        final current = queue[cursor];
        final currentLevel = levels[current] ?? 0;
        for (final next in adjacency[current] ?? const <String>[]) {
          if (!visited.add(next)) {
            continue;
          }
          levels[next] = currentLevel + 1;
          queue.add(next);
        }
      }
    }

    final roots = [
      for (final node in nodes)
        if ((incomingCount[node.id] ?? 0) == 0) node.id,
    ];
    for (final root in roots.isEmpty ? <String>[nodes.first.id] : roots) {
      traverseFrom(root);
    }

    for (var index = 0; index < nodes.length; index++) {
      final nodeId = nodes[index].id;
      if (!visited.contains(nodeId)) {
        traverseFrom(nodeId);
      }
      levels.putIfAbsent(nodeId, () => index);
    }

    final rowByLevel = <int, int>{};
    final positions = <String, Offset>{};
    for (final node in nodes) {
      final level = levels[node.id] ?? 0;
      final row =
          rowByLevel.update(level, (value) => value + 1, ifAbsent: () => 0);
      positions[node.id] = Offset(
        24 + (level * (nodeWidth + horizontalGap)),
        42 + (row * (nodeHeight + verticalGap)),
      );
    }
    return positions;
  }
}

PokeMapTone _toneForNode(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => PokeMapTone.success,
    SceneNodeKind.end => PokeMapTone.info,
    SceneNodeKind.yarnDialogue => PokeMapTone.info,
    SceneNodeKind.condition => PokeMapTone.warning,
    SceneNodeKind.action => PokeMapTone.warning,
    SceneNodeKind.battle => PokeMapTone.danger,
    SceneNodeKind.cinematic => PokeMapTone.narrative,
    SceneNodeKind.branchByOutcome => PokeMapTone.narrative,
    SceneNodeKind.merge => PokeMapTone.neutral,
  };
}

IconData _iconForNode(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => CupertinoIcons.play_circle,
    SceneNodeKind.end => CupertinoIcons.flag,
    SceneNodeKind.yarnDialogue => CupertinoIcons.text_bubble,
    SceneNodeKind.condition => CupertinoIcons.check_mark_circled,
    SceneNodeKind.action => CupertinoIcons.bolt,
    SceneNodeKind.battle => CupertinoIcons.asterisk_circle,
    SceneNodeKind.cinematic => CupertinoIcons.film,
    SceneNodeKind.branchByOutcome => CupertinoIcons.arrow_branch,
    SceneNodeKind.merge => CupertinoIcons.arrow_merge,
  };
}

String _nodeKindLabel(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => 'Début',
    SceneNodeKind.end => 'Fin',
    SceneNodeKind.yarnDialogue => 'Dialogue Yarn',
    SceneNodeKind.condition => 'Condition',
    SceneNodeKind.action => 'Action',
    SceneNodeKind.battle => 'Combat',
    SceneNodeKind.cinematic => 'Cinématique',
    SceneNodeKind.branchByOutcome => 'Branche',
    SceneNodeKind.merge => 'Merge',
  };
}

String _edgeKindLabel(SceneEdgeKind kind) {
  return switch (kind) {
    SceneEdgeKind.defaultFlow => 'default',
    SceneEdgeKind.conditionTrue => 'true',
    SceneEdgeKind.conditionFalse => 'false',
    SceneEdgeKind.dialogueOutcome => 'dialogue',
    SceneEdgeKind.battleVictory => 'victory',
    SceneEdgeKind.battleDefeat => 'defeat',
    SceneEdgeKind.cinematicCompleted => 'cinematic',
    SceneEdgeKind.actionCompleted => 'action',
    SceneEdgeKind.branchOutcome => 'branch',
    SceneEdgeKind.error => 'error',
    SceneEdgeKind.blocked => 'blocked',
  };
}

String _sceneGraphPortKey(String nodeId, String portId) => '$nodeId::$portId';
