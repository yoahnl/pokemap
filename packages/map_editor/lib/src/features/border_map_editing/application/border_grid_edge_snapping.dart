import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

/// Snaps a canvas-local pointer position to the nearest inclusive grid vertex.
///
/// [pan] and [zoom] use the same screen-space transform as the map canvas. A
/// vertex may therefore reach `mapSize.width` or `mapSize.height`, unlike a
/// tile-center coordinate. Positions outside the rendered canvas are rejected
/// before rounding so a nearby exterior click cannot create border geometry.
GridPos? snapBorderGridVertex({
  required Offset localPosition,
  required Offset pan,
  required double zoom,
  required GridSize mapSize,
  required double tileWidth,
  required double tileHeight,
}) {
  if (!zoom.isFinite ||
      zoom <= 0 ||
      !tileWidth.isFinite ||
      tileWidth <= 0 ||
      !tileHeight.isFinite ||
      tileHeight <= 0 ||
      mapSize.width < 0 ||
      mapSize.height < 0) {
    return null;
  }

  final worldX = (localPosition.dx - pan.dx) / zoom;
  final worldY = (localPosition.dy - pan.dy) / zoom;
  final canvasWidth = mapSize.width * tileWidth;
  final canvasHeight = mapSize.height * tileHeight;
  if (!worldX.isFinite ||
      !worldY.isFinite ||
      worldX < 0 ||
      worldY < 0 ||
      worldX > canvasWidth ||
      worldY > canvasHeight) {
    return null;
  }

  return GridPos(
    x: (worldX / tileWidth).round(),
    y: (worldY / tileHeight).round(),
  );
}
