import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';

class CinematicStagePointPreviewOverlay extends StatefulWidget {
  const CinematicStagePointPreviewOverlay({
    super.key,
    required this.stagePoints,
    required this.selectedStagePointId,
    required this.onSelectStagePointId,
    required this.onUpdateStagePoint,
    required this.transform,
    required this.compact,
  });

  final List<CinematicStagePoint> stagePoints;
  final String? selectedStagePointId;
  final ValueChanged<String?> onSelectStagePointId;
  final ValueChanged<CinematicStagePoint> onUpdateStagePoint;
  final CinematicMapBackdropViewportTransform transform;
  final bool compact;

  @override
  State<CinematicStagePointPreviewOverlay> createState() =>
      _CinematicStagePointPreviewOverlayState();
}

class _CinematicStagePointPreviewOverlayState
    extends State<CinematicStagePointPreviewOverlay> {
  String? _draggingPointId;
  Offset? _draggingTilePosition;
  Offset? _startDragGlobalPosition;
  Offset? _startDragTilePosition;
  Offset? _mouseDownGlobalPosition;

  @override
  Widget build(BuildContext context) {
    if (widget.stagePoints.isEmpty || !widget.transform.isUsable) {
      return const SizedBox.shrink(
        key: ValueKey('cinematic-builder-stage-points-overlay-empty'),
      );
    }

    return Stack(
      key: const ValueKey('cinematic-builder-stage-points-overlay'),
      clipBehavior: Clip.none,
      children: [
        for (final point in widget.stagePoints) _buildPointMarker(point),
      ],
    );
  }

  Widget _buildPointMarker(CinematicStagePoint point) {
    final colors = context.pokeMapColors;
    final isSelected = point.id == widget.selectedStagePointId;
    final isDragging = point.id == _draggingPointId;

    // Use local drag position if dragging, otherwise original coordinates
    final tileX = isDragging ? _draggingTilePosition!.dx : point.x;
    final tileY = isDragging ? _draggingTilePosition!.dy : point.y;

    final cellWidth = widget.transform.frame.width / widget.transform.mapWidth;
    final cellHeight = widget.transform.frame.height / widget.transform.mapHeight;

    // Center of the tile bottom or center?
    // Stage points are snapped to floor(x) + 0.5, floor(y) + 0.5.
    // So the tile center is at (tileX, tileY).
    final anchor = widget.transform.tileToPreview(tileX, tileY);

    final markerSize = widget.compact ? 24.0 : 32.0;
    final width = widget.compact ? 80.0 : 100.0;
    final height = markerSize + (widget.compact ? 16.0 : 20.0);

    final brandColor = colors.brandPrimary;
    final strokeColor = isSelected ? brandColor : colors.controlBorder;
    final backgroundColor = isSelected ? brandColor.withOpacity(0.15) : colors.controlSurface;

    return Positioned(
      left: anchor.dx - width / 2,
      top: anchor.dy - height / 2,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onSelectStagePointId(isSelected ? null : point.id);
        },
        onPanDown: (details) {
          _mouseDownGlobalPosition = details.globalPosition;
        },
        onPanStart: (details) {
          widget.onSelectStagePointId(point.id);
          setState(() {
            _draggingPointId = point.id;
            _startDragGlobalPosition = _mouseDownGlobalPosition ?? details.globalPosition;
            _startDragTilePosition = Offset(point.x, point.y);
            _draggingTilePosition = Offset(point.x, point.y);
          });
        },
        onPanUpdate: (details) {
          if (_draggingPointId != point.id ||
              _startDragGlobalPosition == null ||
              _startDragTilePosition == null) {
            return;
          }
          final totalDeltaX = (details.globalPosition.dx - _startDragGlobalPosition!.dx) / cellWidth;
          final totalDeltaY = (details.globalPosition.dy - _startDragGlobalPosition!.dy) / cellHeight;
          setState(() {
            final newTileX = (_startDragTilePosition!.dx + totalDeltaX)
                .clamp(0.0, widget.transform.mapWidth.toDouble());
            final newTileY = (_startDragTilePosition!.dy + totalDeltaY)
                .clamp(0.0, widget.transform.mapHeight.toDouble());
            _draggingTilePosition = Offset(newTileX, newTileY);
          });
        },
        onPanEnd: (details) {
          if (_draggingPointId != point.id || _draggingTilePosition == null) {
            return;
          }
          final snappedX = _draggingTilePosition!.dx.floor() + 0.5;
          final snappedY = _draggingTilePosition!.dy.floor() + 0.5;
          final finalX = snappedX.clamp(0.5, widget.transform.mapWidth - 0.5);
          final finalY = snappedY.clamp(0.5, widget.transform.mapHeight - 0.5);

          widget.onUpdateStagePoint(CinematicStagePoint(
            id: point.id,
            label: point.label,
            x: finalX,
            y: finalY,
            description: point.description,
          ));

          setState(() {
            _draggingPointId = null;
            _draggingTilePosition = null;
            _startDragGlobalPosition = null;
            _startDragTilePosition = null;
          });
        },
        onPanCancel: () {
          print('DEBUG DRAG: onPanCancel');
          setState(() {
            _draggingPointId = null;
            _draggingTilePosition = null;
          });
        },
        child: Semantics(
          label: 'Stage Point ${point.label}',
          selected: isSelected,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Point Pin Marker
              Container(
                key: ValueKey('cinematic-stage-point-marker-${point.id}'),
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: strokeColor,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: brandColor.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.location_solid,
                    size: widget.compact ? 12 : 16,
                    color: isSelected ? brandColor : colors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Label Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? brandColor
                      : colors.controlSurface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? brandColor : colors.controlBorder,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  point.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: isSelected ? Colors.white : colors.textPrimary,
                        fontSize: widget.compact ? 8 : 9,
                        fontWeight: FontWeight.w900,
                        height: 1,
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
