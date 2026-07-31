import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';

/// Adds a native v4 Smart Tile layer with all paint lattices materialized.
MapData addSmartTileLayer(
  MapData map, {
  required String id,
  required String name,
  required String presetId,
  required SmartTileUsage usage,
  required String defaultMaterialId,
  int layerSeed = 0,
  int? insertIndex,
}) {
  final normalizedId = id.trim();
  final normalizedName = name.trim();
  final normalizedPresetId = presetId.trim();
  final normalizedMaterialId = defaultMaterialId.trim();
  if (normalizedId.isEmpty) {
    throw const ValidationException('Layer ID cannot be empty');
  }
  if (normalizedName.isEmpty) {
    throw const ValidationException('Layer name cannot be empty');
  }
  if (normalizedPresetId.isEmpty) {
    throw const ValidationException('Smart Tile presetId cannot be empty');
  }
  if (normalizedMaterialId.isEmpty) {
    throw const ValidationException(
      'Smart Tile defaultMaterialId cannot be empty',
    );
  }
  if (map.layers.any((layer) => layer.id == normalizedId)) {
    throw ValidationException('Layer ID already exists: $normalizedId');
  }
  if (usage == SmartTileUsage.terrain &&
      map.layers
          .whereType<SmartTileLayer>()
          .any((layer) => layer.usage == SmartTileUsage.terrain)) {
    throw const ValidationException(
      'A map can contain only one Smart Tile terrain layer',
    );
  }

  final width = map.size.width;
  final height = map.size.height;
  final defaultIndex = usage == SmartTileUsage.terrain ? 1 : 0;
  final layer = MapLayer.smartTile(
    id: normalizedId,
    name: normalizedName,
    presetId: normalizedPresetId,
    usage: usage,
    materialPalette: <String>['', normalizedMaterialId],
    materialCells: List<int>.filled(
      width * height,
      defaultIndex,
      growable: false,
    ),
    horizontalEdges: List<int>.filled(
      width * (height + 1),
      0,
      growable: false,
    ),
    verticalEdges: List<int>.filled(
      (width + 1) * height,
      0,
      growable: false,
    ),
    corners: List<int>.filled(
      (width + 1) * (height + 1),
      0,
      growable: false,
    ),
    layerSeed: layerSeed,
  );
  final layers = List<MapLayer>.from(map.layers);
  var targetIndex = insertIndex ?? layers.length;
  if (targetIndex < 0) targetIndex = 0;
  if (targetIndex > layers.length) targetIndex = layers.length;
  layers.insert(targetIndex, layer);
  return map.copyWith(version: ProjectVersion.v4, layers: layers);
}

String? smartTileMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height, 'cell');
  return _materialIdForIndex(
    layer,
    layer.materialCells[y * mapSize.width + x],
  );
}

String? smartTileHorizontalEdgeMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height + 1, 'horizontal edge');
  return _materialIdForIndex(
    layer,
    layer.horizontalEdges[y * mapSize.width + x],
  );
}

String? smartTileVerticalEdgeMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width + 1, mapSize.height, 'vertical edge');
  return _materialIdForIndex(
    layer,
    layer.verticalEdges[y * (mapSize.width + 1) + x],
  );
}

String? smartTileCornerMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width + 1, mapSize.height + 1, 'corner');
  return _materialIdForIndex(
    layer,
    layer.corners[y * (mapSize.width + 1) + x],
  );
}

SmartTileLayer setSmartTileCellMaterial(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
  required String? materialId,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height, 'cell');
  final interned = _internMaterial(layer, materialId);
  final values = List<int>.of(layer.materialCells);
  values[y * mapSize.width + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    materialCells: values,
  );
}

SmartTileLayer setSmartTileHorizontalEdgeMaterial(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
  required String? materialId,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height + 1, 'horizontal edge');
  final interned = _internMaterial(layer, materialId);
  final values = List<int>.of(layer.horizontalEdges);
  values[y * mapSize.width + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    horizontalEdges: values,
  );
}

SmartTileLayer setSmartTileVerticalEdgeMaterial(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
  required String? materialId,
}) {
  _checkCoordinate(x, y, mapSize.width + 1, mapSize.height, 'vertical edge');
  final interned = _internMaterial(layer, materialId);
  final values = List<int>.of(layer.verticalEdges);
  values[y * (mapSize.width + 1) + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    verticalEdges: values,
  );
}

SmartTileLayer setSmartTileCornerMaterial(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
  required String? materialId,
}) {
  _checkCoordinate(x, y, mapSize.width + 1, mapSize.height + 1, 'corner');
  final interned = _internMaterial(layer, materialId);
  final values = List<int>.of(layer.corners);
  values[y * (mapSize.width + 1) + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    corners: values,
  );
}

MapData replaceSmartTileLayer(
  MapData map, {
  required SmartTileLayer layer,
}) {
  final index = map.layers.indexWhere((candidate) => candidate.id == layer.id);
  if (index < 0) {
    throw ValidationException('Layer not found: ${layer.id}');
  }
  if (map.layers[index] is! SmartTileLayer) {
    throw ValidationException('Layer is not a Smart Tile layer: ${layer.id}');
  }
  final layers = List<MapLayer>.of(map.layers);
  layers[index] = layer;
  return map.copyWith(version: ProjectVersion.v4, layers: layers);
}

({List<String> palette, int index}) _internMaterial(
  SmartTileLayer layer,
  String? materialId,
) {
  final normalized = materialId?.trim() ?? '';
  if (normalized.isEmpty) {
    return (palette: layer.materialPalette, index: 0);
  }
  final existing = layer.materialPalette.indexOf(normalized);
  if (existing >= 0) {
    return (palette: layer.materialPalette, index: existing);
  }
  return (
    palette: List<String>.unmodifiable(
      <String>[...layer.materialPalette, normalized],
    ),
    index: layer.materialPalette.length,
  );
}

String? _materialIdForIndex(SmartTileLayer layer, int index) {
  if (index == 0) return null;
  if (index < 0 || index >= layer.materialPalette.length) {
    throw RangeError.index(index, layer.materialPalette, 'materialIndex');
  }
  return layer.materialPalette[index];
}

void _checkCoordinate(
  int x,
  int y,
  int width,
  int height,
  String label,
) {
  if (x < 0 || y < 0 || x >= width || y >= height) {
    throw RangeError('$label coordinate is outside its Smart Tile lattice');
  }
}
