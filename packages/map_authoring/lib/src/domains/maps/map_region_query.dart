import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/json_contract_support.dart';

final class MapRegionQueryException implements Exception {
  const MapRegionQueryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'MapRegionQueryException($code): $message';
}

final class MapRegionQuery {
  const MapRegionQuery({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory MapRegionQuery.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    if (json['x'] is! int ||
        json['y'] is! int ||
        json['width'] is! int ||
        json['height'] is! int) {
      throw const FormatException('Map region coordinates must be integers.');
    }
    return MapRegionQuery(
      x: json['x']! as int,
      y: json['y']! as int,
      width: json['width']! as int,
      height: json['height']! as int,
    );
  }

  static const Set<String> _reservedKeys = {'x', 'y', 'width', 'height'};

  final int x;
  final int y;
  final int width;
  final int height;

  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  @override
  bool operator ==(Object other) =>
      other is MapRegionQuery &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

final class MapRegionResult {
  MapRegionResult(Map<String, Object?> json)
      : _json = freezeContractJsonObject(json, field: 'mapRegion');

  final Map<String, Object?> _json;

  Map<String, Object?> toJson() => _json;
}

/// Returns a bounded spatial projection and never serializes the complete map.
MapRegionResult queryMapRegion(MapData map, MapRegionQuery query) {
  _validateBounds(map, query);
  final entities = map.entities
      .where(
        (entity) => _intersects(
          query,
          x: entity.pos.x,
          y: entity.pos.y,
          width: entity.size.width,
          height: entity.size.height,
        ),
      )
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final placedElements = map.placedElements
      .where(
        (element) => _containsPoint(query, element.pos.x, element.pos.y),
      )
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final warps = map.warps
      .where((warp) => _containsPoint(query, warp.pos.x, warp.pos.y))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final triggers = map.triggers
      .where((trigger) => _intersectsRect(query, trigger.area))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final gameplayZones = map.gameplayZones
      .where((zone) => _intersectsRect(query, zone.area))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return MapRegionResult({
    'mapId': map.id,
    'mapName': map.name,
    'resourceKind': 'region',
    'bounds': query.toJson(),
    'layers': [
      for (final layer in map.layers)
        _sliceLayer(layer, mapWidth: map.size.width, query: query),
    ],
    'entities': [
      for (final entity in entities) _jsonObject(entity.toJson()),
    ],
    'placedElements': [
      for (final element in placedElements) _jsonObject(element.toJson()),
    ],
    'warps': [
      for (final warp in warps) _jsonObject(warp.toJson()),
    ],
    'triggers': [
      for (final trigger in triggers) _jsonObject(trigger.toJson()),
    ],
    'gameplayZones': [
      for (final zone in gameplayZones) _jsonObject(zone.toJson()),
    ],
    'nonSpatialConnectionCount': map.connections.length,
    'nonSpatialEventCount': map.events.length,
  });
}

Map<String, Object?> _sliceLayer(
  MapLayer layer, {
  required int mapWidth,
  required MapRegionQuery query,
}) {
  final base = <String, Object?>{
    'id': layer.id,
    'name': layer.name,
    'isVisible': layer.isVisible,
    'opacity': layer.opacity,
  };
  return switch (layer) {
    TileLayer() => {
        ...base,
        'type': 'tile',
        'encoding': 'tile_palette_v1',
        'palette': [for (final entry in layer.palette) entry.toJson()],
        'rows': _sliceFlat(
          layer.cells,
          mapWidth: mapWidth,
          query: query,
          encode: (value) => value,
        ),
      },
    CollisionLayer() => {
        ...base,
        'type': 'collision',
        'encoding': 'grid_rows',
        'rows': _sliceFlat(
          layer.collisions,
          mapWidth: mapWidth,
          query: query,
          encode: (value) => value,
        ),
      },
    SmartTileLayer() => {
        ...base,
        'type': 'smart_tile',
        'encoding': 'grid_rows',
        'presetId': layer.presetId,
        'rows': _sliceFlat(
          smartTileSemanticCells(layer),
          mapWidth: mapWidth,
          query: query,
          encode: (value) => value,
        ),
      },
    ObjectLayer() => {
        ...base,
        'type': 'object',
        'encoding': 'metadata_only',
      },
    EnvironmentLayer() => {
        ...base,
        'type': 'environment',
        'encoding': 'metadata_only',
      },
    BorderLayer() => {
        ...base,
        'type': 'border',
        'encoding': 'metadata_only',
      },
  };
}

List<List<Object?>> _sliceFlat<T>(
  List<T> values, {
  required int mapWidth,
  required MapRegionQuery query,
  required Object? Function(T value) encode,
}) {
  return [
    for (var row = 0; row < query.height; row++)
      [
        for (var column = 0; column < query.width; column++)
          if (((query.y + row) * mapWidth) + query.x + column < values.length)
            encode(
              values[((query.y + row) * mapWidth) + query.x + column],
            )
          else
            null,
      ],
  ];
}

void _validateBounds(MapData map, MapRegionQuery query) {
  if (query.width <= 0 || query.height <= 0) {
    throw const MapRegionQueryException(
      'map.region_size_invalid',
      'Map region dimensions must be positive.',
    );
  }
  if (query.x < 0 ||
      query.y < 0 ||
      query.x + query.width > map.size.width ||
      query.y + query.height > map.size.height) {
    throw const MapRegionQueryException(
      'map.region_out_of_bounds',
      'The requested map region is outside the map bounds.',
    );
  }
}

bool _containsPoint(MapRegionQuery query, int x, int y) =>
    x >= query.x &&
    y >= query.y &&
    x < query.x + query.width &&
    y < query.y + query.height;

bool _intersectsRect(MapRegionQuery query, MapRect rect) => _intersects(
      query,
      x: rect.pos.x,
      y: rect.pos.y,
      width: rect.size.width,
      height: rect.size.height,
    );

bool _intersects(
  MapRegionQuery query, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  return x < query.x + query.width &&
      x + width > query.x &&
      y < query.y + query.height &&
      y + height > query.y;
}

Map<String, Object?> _jsonObject(Map<String, dynamic> value) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
