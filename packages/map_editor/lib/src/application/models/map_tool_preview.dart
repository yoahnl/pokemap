import 'package:map_core/map_core.dart';

enum MapToolPreviewMode {
  paint,
  erase,
  terrainPaint,
  terrainErase,
  pathPaint,
  pathErase,
  collisionPaint,
  collisionErase,
}

enum MapToolPreviewValidity {
  valid,
  invalid,
}

class MapToolPreview {
  const MapToolPreview.paint({
    required this.origin,
    required this.size,
    required this.tilesetId,
    required this.tiles,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.paint,
        terrain = null;

  const MapToolPreview.erase({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.erase,
        tilesetId = null,
        tiles = null,
        terrain = null;

  const MapToolPreview.terrainPaint({
    required this.origin,
    required this.size,
    required this.terrain,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.terrainPaint,
        tilesetId = null,
        tiles = null;

  const MapToolPreview.terrainErase({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.terrainErase,
        tilesetId = null,
        tiles = null,
        terrain = null;

  const MapToolPreview.pathPaint({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.pathPaint,
        tilesetId = null,
        tiles = null,
        terrain = null;

  const MapToolPreview.pathErase({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.pathErase,
        tilesetId = null,
        tiles = null,
        terrain = null;

  const MapToolPreview.collisionPaint({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.collisionPaint,
        tilesetId = null,
        tiles = null,
        terrain = null;

  const MapToolPreview.collisionErase({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.collisionErase,
        tilesetId = null,
        tiles = null,
        terrain = null;

  final MapToolPreviewMode mode;
  final GridPos origin;
  final GridSize size;
  final String? tilesetId;
  final List<int>? tiles;
  final TerrainType? terrain;
  final MapToolPreviewValidity validity;
  final String? reason;
}
