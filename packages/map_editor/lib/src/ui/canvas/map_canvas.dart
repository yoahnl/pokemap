import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import '../../features/editor/state/editor_notifier.dart';

class MapCanvas extends ConsumerWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final activeMap = state.activeMap;

    if (activeMap == null) {
      return const Center(child: Text('No Map Loaded'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) {
            notifier.pan(details.delta);
          },
          onSecondaryTap: () {
            // Context menu could go here
          },
          child: Listener(
            onPointerHover: (event) {
              final localPos = event.localPosition;
              final gridPos = _screenToGrid(
                localPos, 
                state.panOffset, 
                state.zoom, 
                activeMap.size
              );
              notifier.updateHoveredTile(gridPos);
            },
            onPointerSignal: (event) {
              // Mouse wheel zoom would go here
            },
            child: ClipRect(
              child: CustomPaint(
                size: Size.infinite,
                painter: MapGridPainter(
                  map: activeMap,
                  zoom: state.zoom,
                  offset: state.panOffset,
                  hoveredTile: state.hoveredTile,
                  activeLayerId: state.activeLayerId,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  GridPos? _screenToGrid(Offset screenPos, Offset pan, double zoom, GridSize size) {
    final adjustedX = (screenPos.dx - pan.dx) / zoom;
    final adjustedY = (screenPos.dy - pan.dy) / zoom;
    
    final tileX = (adjustedX / 32).floor();
    final tileY = (adjustedY / 32).floor();

    if (tileX >= 0 && tileX < size.width && tileY >= 0 && tileY < size.height) {
      return GridPos(x: tileX, y: tileY);
    }
    return null;
  }
}

class MapGridPainter extends CustomPainter {
  final MapData map;
  final double zoom;
  final Offset offset;
  final GridPos? hoveredTile;
  final String? activeLayerId;
  final double tileSize = 32.0;

  MapGridPainter({
    required this.map,
    required this.zoom,
    required this.offset,
    this.hoveredTile,
    this.activeLayerId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    final gridWidth = map.size.width * tileSize;
    final gridHeight = map.size.height * tileSize;

    // Draw Layers
    for (final layer in map.layers) {
      if (!layer.isVisible) continue;
      
      // Highlight active layer border slightly?
      // Implementation of tile rendering would go here
    }

    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0 / zoom // Keep lines thin regardless of zoom
      ..style = PaintingStyle.stroke;

    for (int x = 0; x <= map.size.width; x++) {
      canvas.drawLine(Offset(x * tileSize, 0), Offset(x * tileSize, gridHeight), gridPaint);
    }
    for (int y = 0; y <= map.size.height; y++) {
      canvas.drawLine(Offset(0, y * tileSize), Offset(gridWidth, y * tileSize), gridPaint);
    }

    // Draw Hover Cursor
    if (hoveredTile != null) {
      final hoverPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(
          hoveredTile!.x * tileSize,
          hoveredTile!.y * tileSize,
          tileSize,
          tileSize,
        ),
        hoverPaint,
      );
      
      // Cursor Border
      final cursorBorder = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom;
        
      canvas.drawRect(
        Rect.fromLTWH(
          hoveredTile!.x * tileSize,
          hoveredTile!.y * tileSize,
          tileSize,
          tileSize,
        ),
        cursorBorder,
      );
    }

    // Draw Map Border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gridWidth, gridHeight),
      Paint()..color = Colors.white..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) {
    return oldDelegate.zoom != zoom ||
           oldDelegate.offset != offset ||
           oldDelegate.hoveredTile != hoveredTile ||
           oldDelegate.activeLayerId != activeLayerId;
  }
}
