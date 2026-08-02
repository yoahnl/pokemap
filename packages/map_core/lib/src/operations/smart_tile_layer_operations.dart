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

/// One palette entry removed while canonicalizing a Smart Tile layer.
final class SmartTileRemovedPaletteEntry {
  const SmartTileRemovedPaletteEntry({
    required this.materialId,
    required this.oldIndex,
  });

  final String materialId;
  final int oldIndex;

  Map<String, Object?> toJson() => {
        'materialId': materialId,
        'oldIndex': oldIndex,
      };
}

/// Result of a render-preserving Smart Tile palette normalization.
final class SmartTileLayerNormalizationResult {
  SmartTileLayerNormalizationResult({
    required this.layer,
    required Iterable<SmartTileRemovedPaletteEntry> removedPaletteEntries,
    required Map<String, int> reindexedEntryCounts,
  })  : removedPaletteEntries = List.unmodifiable(removedPaletteEntries),
        reindexedEntryCounts = Map.unmodifiable(reindexedEntryCounts);

  final SmartTileLayer layer;
  final List<SmartTileRemovedPaletteEntry> removedPaletteEntries;
  final Map<String, int> reindexedEntryCounts;

  int get reindexedEntryCount =>
      reindexedEntryCounts.values.fold(0, (sum, value) => sum + value);
}

/// Result of a non-destructive union into the target Smart Tile layer.
final class SmartTileLayerUnionResult {
  SmartTileLayerUnionResult({
    required this.layer,
    required Map<String, int> mergedEntryCounts,
  }) : mergedEntryCounts = Map.unmodifiable(mergedEntryCounts);

  final SmartTileLayer layer;
  final Map<String, int> mergedEntryCounts;

  int get mergedEntryCount =>
      mergedEntryCounts.values.fold(0, (sum, value) => sum + value);
}

/// Removes palette entries that are not referenced by any of the four Smart
/// Tile lattices. Retained materials keep their original order, so only the
/// integer indirection changes; every resolved material and all metadata stay
/// identical.
SmartTileLayerNormalizationResult normalizeSmartTileLayer(
  SmartTileLayer layer,
) {
  final palette = layer.materialPalette;
  if (palette.isEmpty || palette.first.isNotEmpty) {
    throw const ValidationException(
      'Smart Tile materialPalette must start with the empty material',
    );
  }
  final lattices = <String, List<int>>{
    'materialCells': layer.materialCells,
    'horizontalEdges': layer.horizontalEdges,
    'verticalEdges': layer.verticalEdges,
    'corners': layer.corners,
  };
  final usedIndices = <int>{0};
  for (final entry in lattices.entries) {
    for (var offset = 0; offset < entry.value.length; offset++) {
      final index = entry.value[offset];
      if (index < 0 || index >= palette.length) {
        throw ValidationException(
          'Smart Tile ${entry.key}[$offset] references invalid material '
          'palette index $index',
        );
      }
      usedIndices.add(index);
    }
  }

  final normalizedPalette = <String>[''];
  final normalizedIndexByMaterial = <String, int>{};
  final oldToNew = <int, int>{0: 0};
  final retainedOldIndices = <int>{0};
  for (var oldIndex = 1; oldIndex < palette.length; oldIndex++) {
    if (!usedIndices.contains(oldIndex)) continue;
    final materialId = palette[oldIndex];
    if (materialId.trim().isEmpty) {
      throw ValidationException(
        'Smart Tile palette index $oldIndex resolves to an empty material',
      );
    }
    final existing = normalizedIndexByMaterial[materialId];
    if (existing != null) {
      oldToNew[oldIndex] = existing;
      continue;
    }
    final newIndex = normalizedPalette.length;
    normalizedPalette.add(materialId);
    normalizedIndexByMaterial[materialId] = newIndex;
    oldToNew[oldIndex] = newIndex;
    retainedOldIndices.add(oldIndex);
  }

  List<int> reindex(String label) {
    final source = lattices[label]!;
    return List<int>.generate(
      source.length,
      (offset) => oldToNew[source[offset]]!,
      growable: false,
    );
  }

  final materialCells = reindex('materialCells');
  final horizontalEdges = reindex('horizontalEdges');
  final verticalEdges = reindex('verticalEdges');
  final corners = reindex('corners');
  int changedCount(List<int> before, List<int> after) {
    var count = 0;
    for (var index = 0; index < before.length; index++) {
      if (before[index] != after[index]) count++;
    }
    return count;
  }

  return SmartTileLayerNormalizationResult(
    layer: layer.copyWith(
      materialPalette: List.unmodifiable(normalizedPalette),
      materialCells: materialCells,
      horizontalEdges: horizontalEdges,
      verticalEdges: verticalEdges,
      corners: corners,
    ),
    removedPaletteEntries: [
      for (var oldIndex = 1; oldIndex < palette.length; oldIndex++)
        if (!retainedOldIndices.contains(oldIndex))
          SmartTileRemovedPaletteEntry(
            materialId: palette[oldIndex],
            oldIndex: oldIndex,
          ),
    ],
    reindexedEntryCounts: {
      'materialCells': changedCount(layer.materialCells, materialCells),
      'horizontalEdges': changedCount(layer.horizontalEdges, horizontalEdges),
      'verticalEdges': changedCount(layer.verticalEdges, verticalEdges),
      'corners': changedCount(layer.corners, corners),
    },
  );
}

/// Unites compatible Smart Tile geometry into [target]. A non-empty overlap is
/// accepted only when both layers resolve to the same material (after an
/// optional explicit source mapping); otherwise the union is ambiguous and is
/// rejected before any caller can remove a source layer.
SmartTileLayerUnionResult unionSmartTileLayers({
  required SmartTileLayer target,
  required Iterable<SmartTileLayer> sources,
  Map<String, Map<String, String>> materialMappings = const {},
}) {
  final normalizedTarget = normalizeSmartTileLayer(target).layer;
  final normalizedSources = [
    for (final source in sources) normalizeSmartTileLayer(source).layer,
  ];
  for (final source in normalizedSources) {
    if (source.usage != normalizedTarget.usage) {
      throw ValidationException(
        'Smart Tile source ${source.id} usage does not match target '
        '${normalizedTarget.id}',
      );
    }
    _requireSameSmartTileLatticeLengths(normalizedTarget, source);
  }

  final targetLattices = <String, List<int>>{
    'materialCells': normalizedTarget.materialCells,
    'horizontalEdges': normalizedTarget.horizontalEdges,
    'verticalEdges': normalizedTarget.verticalEdges,
    'corners': normalizedTarget.corners,
  };
  final mergedMaterials = <String, List<String?>>{
    for (final entry in targetLattices.entries)
      entry.key: _resolvedSmartTileMaterials(
        normalizedTarget,
        entry.value,
        entry.key,
      ),
  };
  final mergedEntryCounts = <String, int>{
    for (final label in targetLattices.keys) label: 0,
  };

  for (final source in normalizedSources) {
    final mapping = materialMappings[source.id] ?? const <String, String>{};
    final sourceLattices = <String, List<int>>{
      'materialCells': source.materialCells,
      'horizontalEdges': source.horizontalEdges,
      'verticalEdges': source.verticalEdges,
      'corners': source.corners,
    };
    for (final entry in sourceLattices.entries) {
      final sourceMaterials = _resolvedSmartTileMaterials(
        source,
        entry.value,
        entry.key,
      );
      final targetMaterials = mergedMaterials[entry.key]!;
      for (var offset = 0; offset < sourceMaterials.length; offset++) {
        final rawSourceMaterial = sourceMaterials[offset];
        if (rawSourceMaterial == null) continue;
        final sourceMaterial = mapping[rawSourceMaterial] ?? rawSourceMaterial;
        if (sourceMaterial.trim().isEmpty) {
          throw ValidationException(
            'Smart Tile source ${source.id} maps material '
            '$rawSourceMaterial to an empty material',
          );
        }
        final targetMaterial = targetMaterials[offset];
        if (targetMaterial == null) {
          targetMaterials[offset] = sourceMaterial;
          mergedEntryCounts[entry.key] = mergedEntryCounts[entry.key]! + 1;
          continue;
        }
        if (targetMaterial != sourceMaterial) {
          throw ValidationException(
            'Smart Tile ${entry.key}[$offset] has an ambiguous material '
            'conflict between target ${normalizedTarget.id} '
            '($targetMaterial) and source ${source.id} ($sourceMaterial)',
            code: 'smart_tile.layer_merge_conflict',
            details: {
              'targetLayerId': normalizedTarget.id,
              'sourceLayerId': source.id,
              'lattice': entry.key,
              'offset': offset,
              'targetMaterialId': targetMaterial,
              'sourceMaterialId': sourceMaterial,
            },
            remediation: const [
              'Provide an explicit materialMappings entry or remove the '
                  'overlap before retrying.',
            ],
          );
        }
      }
    }
  }

  final palette = <String>[''];
  final paletteIndex = <String, int>{};
  void retain(String materialId) {
    if (paletteIndex.containsKey(materialId)) return;
    paletteIndex[materialId] = palette.length;
    palette.add(materialId);
  }

  // Retaining target order first makes repeated merges deterministic; source
  // materials are then discovered in caller-provided source/lattice order.
  for (final materialId in normalizedTarget.materialPalette.skip(1)) {
    retain(materialId);
  }
  for (final label in const [
    'materialCells',
    'horizontalEdges',
    'verticalEdges',
    'corners',
  ]) {
    for (final materialId in mergedMaterials[label]!) {
      if (materialId != null) retain(materialId);
    }
  }
  List<int> encode(String label) => [
        for (final materialId in mergedMaterials[label]!)
          materialId == null ? 0 : paletteIndex[materialId]!,
      ];

  return SmartTileLayerUnionResult(
    layer: normalizedTarget.copyWith(
      materialPalette: List.unmodifiable(palette),
      materialCells: encode('materialCells'),
      horizontalEdges: encode('horizontalEdges'),
      verticalEdges: encode('verticalEdges'),
      corners: encode('corners'),
    ),
    mergedEntryCounts: mergedEntryCounts,
  );
}

void _requireSameSmartTileLatticeLengths(
  SmartTileLayer target,
  SmartTileLayer source,
) {
  final targetLengths = <String, int>{
    'materialCells': target.materialCells.length,
    'horizontalEdges': target.horizontalEdges.length,
    'verticalEdges': target.verticalEdges.length,
    'corners': target.corners.length,
  };
  final sourceLengths = <String, int>{
    'materialCells': source.materialCells.length,
    'horizontalEdges': source.horizontalEdges.length,
    'verticalEdges': source.verticalEdges.length,
    'corners': source.corners.length,
  };
  for (final entry in targetLengths.entries) {
    if (sourceLengths[entry.key] == entry.value) continue;
    throw ValidationException(
      'Smart Tile source ${source.id} has incompatible ${entry.key} length '
      '${sourceLengths[entry.key]} (target ${entry.value})',
    );
  }
}

List<String?> _resolvedSmartTileMaterials(
  SmartTileLayer layer,
  List<int> values,
  String label,
) =>
    List<String?>.generate(values.length, (offset) {
      final index = values[offset];
      if (index < 0 || index >= layer.materialPalette.length) {
        throw ValidationException(
          'Smart Tile $label[$offset] references invalid material palette '
          'index $index in layer ${layer.id}',
        );
      }
      return index == 0 ? null : layer.materialPalette[index];
    }, growable: false);

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
