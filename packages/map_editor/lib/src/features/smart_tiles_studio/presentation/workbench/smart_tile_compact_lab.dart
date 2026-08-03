import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../application/smart_tile_test_layer_controller.dart';

class SmartTileCompactLab extends StatelessWidget {
  const SmartTileCompactLab({
    super.key,
    required this.layer,
    required this.mapSize,
    required this.topology,
    required this.onTargetPressed,
    this.selectedX,
    this.selectedY,
    this.cellExtent = 44,
  });

  static const double canvasPadding = 14;

  final SmartTileLayer layer;
  final GridSize mapSize;
  final SmartTileTopology topology;
  final ValueChanged<SmartTileLabTarget> onTargetPressed;
  final int? selectedX;
  final int? selectedY;
  final double cellExtent;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final size = Size(
      mapSize.width * cellExtent + canvasPadding * 2,
      mapSize.height * cellExtent + canvasPadding * 2,
    );
    return Semantics(
      container: true,
      label: _semanticLabel(topology),
      child: GestureDetector(
        key: const Key('smart-tiles-compact-lab'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final target = smartTileLabTargetAt(
            position: details.localPosition,
            mapSize: mapSize,
            topology: topology,
            cellExtent: cellExtent,
            padding: canvasPadding,
          );
          if (target != null) onTargetPressed(target);
        },
        child: SizedBox.fromSize(
          size: size,
          child: CustomPaint(
            painter: _SmartTileCompactLabPainter(
              layer: layer,
              mapSize: mapSize,
              topology: topology,
              cellExtent: cellExtent,
              padding: canvasPadding,
              selectedX: selectedX,
              selectedY: selectedY,
              backgroundColor: colors.surfaceSubtle,
              emptyCellColor: colors.controlSurface,
              authoredCellColor: colors.brandPrimarySoft,
              gridColor: colors.borderStrong,
              edgeColor: colors.mapAccent,
              cornerColor: colors.warning,
              selectionColor: colors.focusRing,
            ),
          ),
        ),
      ),
    );
  }
}

SmartTileLabTarget? smartTileLabTargetAt({
  required Offset position,
  required GridSize mapSize,
  required SmartTileTopology topology,
  double cellExtent = 44,
  double padding = SmartTileCompactLab.canvasPadding,
}) {
  final localX = position.dx - padding;
  final localY = position.dy - padding;
  if (localX < -8 ||
      localY < -8 ||
      localX > mapSize.width * cellExtent + 8 ||
      localY > mapSize.height * cellExtent + 8) {
    return null;
  }
  final gridX = localX / cellExtent;
  final gridY = localY / cellExtent;
  final nearestX = gridX.round();
  final nearestY = gridY.round();
  final distanceX = (gridX - nearestX).abs() * cellExtent;
  final distanceY = (gridY - nearestY).abs() * cellExtent;
  final usesEdges = topology == SmartTileTopology.wangEdge4 ||
      topology == SmartTileTopology.wang8;
  final usesCorners = topology == SmartTileTopology.wangCorner4 ||
      topology == SmartTileTopology.wang8;

  if (usesCorners &&
      distanceX <= 8 &&
      distanceY <= 8 &&
      nearestX >= 0 &&
      nearestX <= mapSize.width &&
      nearestY >= 0 &&
      nearestY <= mapSize.height) {
    return SmartTileLabTarget(
      kind: SmartTileLabTargetKind.corner,
      x: nearestX,
      y: nearestY,
    );
  }
  if (usesEdges && distanceY <= 7 && distanceY <= distanceX) {
    final x = gridX.floor();
    if (x >= 0 &&
        x < mapSize.width &&
        nearestY >= 0 &&
        nearestY <= mapSize.height) {
      return SmartTileLabTarget(
        kind: SmartTileLabTargetKind.horizontalEdge,
        x: x,
        y: nearestY,
      );
    }
  }
  if (usesEdges && distanceX <= 7) {
    final y = gridY.floor();
    if (nearestX >= 0 &&
        nearestX <= mapSize.width &&
        y >= 0 &&
        y < mapSize.height) {
      return SmartTileLabTarget(
        kind: SmartTileLabTargetKind.verticalEdge,
        x: nearestX,
        y: y,
      );
    }
  }
  final cellX = gridX.floor();
  final cellY = gridY.floor();
  if (cellX < 0 ||
      cellY < 0 ||
      cellX >= mapSize.width ||
      cellY >= mapSize.height) {
    return null;
  }
  return SmartTileLabTarget(
    kind: SmartTileLabTargetKind.cell,
    x: cellX,
    y: cellY,
  );
}

class _SmartTileCompactLabPainter extends CustomPainter {
  const _SmartTileCompactLabPainter({
    required this.layer,
    required this.mapSize,
    required this.topology,
    required this.cellExtent,
    required this.padding,
    required this.selectedX,
    required this.selectedY,
    required this.backgroundColor,
    required this.emptyCellColor,
    required this.authoredCellColor,
    required this.gridColor,
    required this.edgeColor,
    required this.cornerColor,
    required this.selectionColor,
  });

  final SmartTileLayer layer;
  final GridSize mapSize;
  final SmartTileTopology topology;
  final double cellExtent;
  final double padding;
  final int? selectedX;
  final int? selectedY;
  final Color backgroundColor;
  final Color emptyCellColor;
  final Color authoredCellColor;
  final Color gridColor;
  final Color edgeColor;
  final Color cornerColor;
  final Color selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(10)),
      Paint()..color = backgroundColor,
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var y = 0; y < mapSize.height; y += 1) {
      for (var x = 0; x < mapSize.width; x += 1) {
        final rect = Rect.fromLTWH(
          padding + x * cellExtent + 2,
          padding + y * cellExtent + 2,
          cellExtent - 4,
          cellExtent - 4,
        );
        final authored = smartTileMaterialIdAt(
              layer,
              mapSize: mapSize,
              x: x,
              y: y,
            ) !=
            null;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()..color = authored ? authoredCellColor : emptyCellColor,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          gridPaint,
        );
      }
    }

    if (_usesEdges) {
      final edgePaint = Paint()
        ..color = edgeColor
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      for (var y = 0; y <= mapSize.height; y += 1) {
        for (var x = 0; x < mapSize.width; x += 1) {
          if (smartTileHorizontalEdgeMaterialIdAt(
                layer,
                mapSize: mapSize,
                x: x,
                y: y,
              ) ==
              null) {
            continue;
          }
          final left = padding + x * cellExtent + 7;
          final right = padding + (x + 1) * cellExtent - 7;
          final top = padding + y * cellExtent;
          canvas.drawLine(Offset(left, top), Offset(right, top), edgePaint);
        }
      }
      for (var y = 0; y < mapSize.height; y += 1) {
        for (var x = 0; x <= mapSize.width; x += 1) {
          if (smartTileVerticalEdgeMaterialIdAt(
                layer,
                mapSize: mapSize,
                x: x,
                y: y,
              ) ==
              null) {
            continue;
          }
          final left = padding + x * cellExtent;
          final top = padding + y * cellExtent + 7;
          final bottom = padding + (y + 1) * cellExtent - 7;
          canvas.drawLine(Offset(left, top), Offset(left, bottom), edgePaint);
        }
      }
    }

    if (_usesCorners) {
      final cornerPaint = Paint()..color = cornerColor;
      for (var y = 0; y <= mapSize.height; y += 1) {
        for (var x = 0; x <= mapSize.width; x += 1) {
          if (smartTileCornerMaterialIdAt(
                layer,
                mapSize: mapSize,
                x: x,
                y: y,
              ) ==
              null) {
            continue;
          }
          canvas.drawCircle(
            Offset(padding + x * cellExtent, padding + y * cellExtent),
            6,
            cornerPaint,
          );
        }
      }
    }

    final x = selectedX;
    final y = selectedY;
    if (x != null &&
        y != null &&
        x >= 0 &&
        y >= 0 &&
        x < mapSize.width &&
        y < mapSize.height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            padding + x * cellExtent,
            padding + y * cellExtent,
            cellExtent,
            cellExtent,
          ),
          const Radius.circular(6),
        ),
        Paint()
          ..color = selectionColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  bool get _usesEdges =>
      topology == SmartTileTopology.wangEdge4 ||
      topology == SmartTileTopology.wang8;

  bool get _usesCorners =>
      topology == SmartTileTopology.wangCorner4 ||
      topology == SmartTileTopology.wang8;

  @override
  bool shouldRepaint(covariant _SmartTileCompactLabPainter oldDelegate) {
    return oldDelegate.layer != layer ||
        oldDelegate.mapSize != mapSize ||
        oldDelegate.topology != topology ||
        oldDelegate.selectedX != selectedX ||
        oldDelegate.selectedY != selectedY ||
        oldDelegate.cellExtent != cellExtent ||
        oldDelegate.padding != padding ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.emptyCellColor != emptyCellColor ||
        oldDelegate.authoredCellColor != authoredCellColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.edgeColor != edgeColor ||
        oldDelegate.cornerColor != cornerColor ||
        oldDelegate.selectionColor != selectionColor;
  }
}

String _semanticLabel(SmartTileTopology topology) => switch (topology) {
      SmartTileTopology.uniform ||
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.blob8 =>
        'Laboratoire cellulaire : peindre ou effacer une cellule',
      SmartTileTopology.wangEdge4 =>
        'Laboratoire par arêtes : peindre les cellules et les segments',
      SmartTileTopology.wangCorner4 =>
        'Laboratoire par coins : peindre les cellules et les intersections',
      SmartTileTopology.wang8 =>
        'Laboratoire mixte : peindre cellules, segments et intersections',
    };
