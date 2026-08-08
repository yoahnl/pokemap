import 'package:map_core/map_core.dart';

enum MapToolPreviewMode {
  paint,
  elementPlacement,
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
        elementId = null,
        terrain = null,
        cells = null;

  const MapToolPreview.elementPlacement({
    required this.origin,
    required this.size,
    required this.elementId,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.elementPlacement,
        tilesetId = null,
        tiles = null,
        terrain = null,
        cells = null;

  const MapToolPreview.erase({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.erase,
        elementId = null,
        tilesetId = null,
        tiles = null,
        terrain = null,
        cells = null;

  const MapToolPreview.terrainPaint({
    required this.origin,
    required this.size,
    required this.terrain,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.terrainPaint,
        elementId = null,
        tilesetId = null,
        tiles = null,
        cells = null;

  const MapToolPreview.terrainErase({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.terrainErase,
        elementId = null,
        tilesetId = null,
        tiles = null,
        terrain = null,
        cells = null;

  const MapToolPreview.pathPaint({
    required this.origin,
    required this.size,
    required this.validity,
    this.cells,
    this.reason,
  })  : mode = MapToolPreviewMode.pathPaint,
        elementId = null,
        tilesetId = null,
        tiles = null,
        terrain = null;

  const MapToolPreview.pathErase({
    required this.origin,
    required this.size,
    required this.validity,
    this.cells,
    this.reason,
  })  : mode = MapToolPreviewMode.pathErase,
        elementId = null,
        tilesetId = null,
        tiles = null,
        terrain = null;

  const MapToolPreview.collisionPaint({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.collisionPaint,
        elementId = null,
        tilesetId = null,
        tiles = null,
        terrain = null,
        cells = null;

  const MapToolPreview.collisionErase({
    required this.origin,
    required this.size,
    required this.validity,
    this.reason,
  })  : mode = MapToolPreviewMode.collisionErase,
        elementId = null,
        tilesetId = null,
        tiles = null,
        terrain = null,
        cells = null;

  final MapToolPreviewMode mode;
  final GridPos origin;
  final GridSize size;
  final String? tilesetId;
  final String? elementId;
  final List<TileLayerPaletteEntry?>? tiles;
  final TerrainType? terrain;
  final List<GridPos>? cells;
  final MapToolPreviewValidity validity;
  final String? reason;
}
