import 'dart:math' as math;

import 'package:flutter/widgets.dart';

Rect fittedCinematicMapBackdropRect({
  required Size availableSize,
  required Size mapPixelSize,
}) {
  if (availableSize.isEmpty ||
      mapPixelSize.width <= 0 ||
      mapPixelSize.height <= 0) {
    return Rect.zero;
  }
  final scale = math.min(
    availableSize.width / mapPixelSize.width,
    availableSize.height / mapPixelSize.height,
  );
  final width = mapPixelSize.width * scale;
  final height = mapPixelSize.height * scale;
  return Rect.fromLTWH(
    (availableSize.width - width) / 2,
    (availableSize.height - height) / 2,
    width,
    height,
  );
}

@immutable
final class CinematicMapBackdropViewportTransform {
  const CinematicMapBackdropViewportTransform({
    required this.frame,
    required this.mapWidth,
    required this.mapHeight,
  });

  factory CinematicMapBackdropViewportTransform.fill({
    required Size viewportSize,
    required int mapWidth,
    required int mapHeight,
  }) {
    return CinematicMapBackdropViewportTransform(
      frame: Offset.zero & viewportSize,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
  }

  final Rect frame;
  final int mapWidth;
  final int mapHeight;

  bool get isUsable => !frame.isEmpty && mapWidth > 0 && mapHeight > 0;

  Rect tileRect({required int tileX, required int tileY}) {
    if (!isUsable) {
      return Rect.zero;
    }
    final cellWidth = frame.width / mapWidth;
    final cellHeight = frame.height / mapHeight;
    return Rect.fromLTWH(
      frame.left + tileX * cellWidth,
      frame.top + tileY * cellHeight,
      cellWidth,
      cellHeight,
    );
  }

  Offset tileCenterBottom({required int tileX, required int tileY}) {
    final rect = tileRect(tileX: tileX, tileY: tileY);
    if (rect.isEmpty) {
      return Offset.zero;
    }
    return Offset(rect.center.dx, rect.bottom);
  }
}
