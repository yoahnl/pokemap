import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import '../models/smart_tile_field.dart';

/// Map-only creation cannot atomically update the v5 manifest catalog.
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
  throw const ValidationException(
    'Use the canonical smart_tile.layer.create authoring action',
    code: 'smart_tile_canonical_layer_action_required',
  );
}

List<int> smartTileSemanticCells(SmartTileLayer layer) => switch (layer.field) {
      SmartTileCellField(:final semanticCells) => semanticCells,
      SmartTileCornerField(:final semanticCells) => semanticCells,
      SmartTileEdgeField(:final semanticCells) => semanticCells,
      SmartTileMixedField(:final semanticCells) => semanticCells,
    };

List<int> smartTileHorizontalEdges(SmartTileLayer layer) =>
    switch (layer.field) {
      SmartTileEdgeField(:final horizontalEdges) => horizontalEdges,
      SmartTileMixedField(:final horizontalEdges) => horizontalEdges,
      SmartTileCellField() || SmartTileCornerField() => const <int>[],
    };

List<int> smartTileVerticalEdges(SmartTileLayer layer) => switch (layer.field) {
      SmartTileEdgeField(:final verticalEdges) => verticalEdges,
      SmartTileMixedField(:final verticalEdges) => verticalEdges,
      SmartTileCellField() || SmartTileCornerField() => const <int>[],
    };

List<int> smartTileCorners(SmartTileLayer layer) => switch (layer.field) {
      SmartTileCornerField(:final corners) => corners,
      SmartTileMixedField(:final corners) => corners,
      SmartTileCellField() || SmartTileEdgeField() => const <int>[],
    };

/// Counts authored palette references across every active native lattice.
int smartTileAuthoredValueCount(SmartTileLayer layer) => <List<int>>[
      smartTileSemanticCells(layer),
      smartTileHorizontalEdges(layer),
      smartTileVerticalEdges(layer),
      smartTileCorners(layer),
    ].fold<int>(
      0,
      (total, values) =>
          total + values.where((materialIndex) => materialIndex != 0).length,
    );

/// Whether a map cell is touched by semantic, edge, or corner authored data.
///
/// Edge and corner fields live between cells. A cell therefore owns the two
/// horizontal edges, two vertical edges, and four corners surrounding it.
bool smartTileCellHasAuthoredValue(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height, 'cell');
  final semantic = smartTileSemanticCells(layer);
  if (_isAuthoredAt(semantic, y * mapSize.width + x)) return true;

  final horizontal = smartTileHorizontalEdges(layer);
  if (_isAuthoredAt(horizontal, y * mapSize.width + x) ||
      _isAuthoredAt(horizontal, (y + 1) * mapSize.width + x)) {
    return true;
  }

  final vertical = smartTileVerticalEdges(layer);
  final verticalStride = mapSize.width + 1;
  if (_isAuthoredAt(vertical, y * verticalStride + x) ||
      _isAuthoredAt(vertical, y * verticalStride + x + 1)) {
    return true;
  }

  final corners = smartTileCorners(layer);
  final cornerStride = mapSize.width + 1;
  return _isAuthoredAt(corners, y * cornerStride + x) ||
      _isAuthoredAt(corners, y * cornerStride + x + 1) ||
      _isAuthoredAt(corners, (y + 1) * cornerStride + x) ||
      _isAuthoredAt(corners, (y + 1) * cornerStride + x + 1);
}

bool _isAuthoredAt(List<int> values, int index) =>
    index >= 0 && index < values.length && values[index] != 0;

String? smartTileMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height, 'cell');
  return _materialIdForIndex(
    layer,
    smartTileSemanticCells(layer)[y * mapSize.width + x],
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
    smartTileHorizontalEdges(layer)[y * mapSize.width + x],
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
    smartTileVerticalEdges(layer)[y * (mapSize.width + 1) + x],
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
    smartTileCorners(layer)[y * (mapSize.width + 1) + x],
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
  final values = List<int>.of(smartTileSemanticCells(layer));
  values[y * mapSize.width + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    field: _withSemanticCells(layer.field, values),
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
  final values = List<int>.of(smartTileHorizontalEdges(layer));
  if (values.isEmpty) {
    throw const ValidationException(
      'Smart Tile field has no horizontal edge lattice',
    );
  }
  values[y * mapSize.width + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    field: _withHorizontalEdges(layer.field, values),
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
  final values = List<int>.of(smartTileVerticalEdges(layer));
  if (values.isEmpty) {
    throw const ValidationException(
      'Smart Tile field has no vertical edge lattice',
    );
  }
  values[y * (mapSize.width + 1) + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    field: _withVerticalEdges(layer.field, values),
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
  final values = List<int>.of(smartTileCorners(layer));
  if (values.isEmpty) {
    throw const ValidationException('Smart Tile field has no corner lattice');
  }
  values[y * (mapSize.width + 1) + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    field: _withCorners(layer.field, values),
  );
}

MapData replaceSmartTileLayer(
  MapData map, {
  required SmartTileLayer layer,
}) {
  // Replacement is deliberately map-only: it may maintain an already-native
  // v6 layer, but it must never manufacture the project-wide v6 transition
  // owned by the canonical authoring action together with the manifest.
  if (map.version != ProjectVersion.v6) {
    throw const ValidationException(
      'Native Smart Tile replacement requires a ProjectVersion.v6 map',
      code: 'smart_tile_native_project_version_required',
    );
  }
  final index = map.layers.indexWhere((candidate) => candidate.id == layer.id);
  if (index < 0) {
    throw ValidationException('Layer not found: ${layer.id}');
  }
  if (map.layers[index] is! SmartTileLayer) {
    throw ValidationException('Layer is not a Smart Tile layer: ${layer.id}');
  }
  final layers = List<MapLayer>.of(map.layers)..[index] = layer;
  return map.copyWith(layers: layers);
}

final class SmartTileRemovedPaletteEntry {
  const SmartTileRemovedPaletteEntry({
    required this.materialId,
    required this.oldIndex,
  });

  final String materialId;
  final int oldIndex;

  Map<String, Object?> toJson() => <String, Object?>{
        'materialId': materialId,
        'oldIndex': oldIndex,
      };
}

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

SmartTileLayerNormalizationResult normalizeSmartTileLayer(
  SmartTileLayer layer,
) {
  final palette = layer.materialPalette;
  if (palette.isEmpty || palette.first.isNotEmpty) {
    throw const ValidationException(
      'Smart Tile materialPalette must start with the empty material',
    );
  }
  final lattices = _activeLattices(layer);
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

  final reindexed = <String, List<int>>{
    for (final entry in lattices.entries)
      entry.key: <int>[for (final index in entry.value) oldToNew[index]!],
  };
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
      field: _fieldFromLattices(layer.field, reindexed),
    ),
    removedPaletteEntries: <SmartTileRemovedPaletteEntry>[
      for (var oldIndex = 1; oldIndex < palette.length; oldIndex++)
        if (!retainedOldIndices.contains(oldIndex))
          SmartTileRemovedPaletteEntry(
            materialId: palette[oldIndex],
            oldIndex: oldIndex,
          ),
    ],
    reindexedEntryCounts: <String, int>{
      for (final entry in lattices.entries)
        entry.key: changedCount(entry.value, reindexed[entry.key]!),
    },
  );
}

SmartTileLayerUnionResult unionSmartTileLayers({
  required SmartTileLayer target,
  required Iterable<SmartTileLayer> sources,
  Map<String, Map<String, String>> materialMappings = const {},
}) {
  final normalizedTarget = normalizeSmartTileLayer(target).layer;
  final normalizedSources = <SmartTileLayer>[
    for (final source in sources) normalizeSmartTileLayer(source).layer,
  ];
  final targetLattices = _activeLattices(normalizedTarget);
  for (final source in normalizedSources) {
    if (source.usage != normalizedTarget.usage) {
      throw ValidationException(
        'Smart Tile source ${source.id} usage does not match target '
        '${normalizedTarget.id}',
      );
    }
    final sourceLattices = _activeLattices(source);
    if (source.field.runtimeType != normalizedTarget.field.runtimeType ||
        sourceLattices.keys
            .toSet()
            .difference(targetLattices.keys.toSet())
            .isNotEmpty ||
        targetLattices.keys
            .toSet()
            .difference(sourceLattices.keys.toSet())
            .isNotEmpty) {
      throw ValidationException(
        'Smart Tile source ${source.id} has an incompatible field kind',
      );
    }
    for (final entry in targetLattices.entries) {
      if (sourceLattices[entry.key]!.length != entry.value.length) {
        throw ValidationException(
          'Smart Tile source ${source.id} has incompatible ${entry.key} length',
        );
      }
    }
  }

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
    for (final entry in _activeLattices(source).entries) {
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
        } else if (targetMaterial != sourceMaterial) {
          throw ValidationException(
            'Smart Tile ${entry.key}[$offset] has an ambiguous material '
            'conflict between target ${normalizedTarget.id} '
            '($targetMaterial) and source ${source.id} ($sourceMaterial)',
            code: 'smart_tile.layer_merge_conflict',
            details: <String, Object?>{
              'lattice': entry.key,
              'offset': offset,
              'targetLayerId': normalizedTarget.id,
              'targetMaterialId': targetMaterial,
              'sourceLayerId': source.id,
              'sourceMaterialId': sourceMaterial,
            },
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

  for (final materialId in normalizedTarget.materialPalette.skip(1)) {
    retain(materialId);
  }
  for (final values in mergedMaterials.values) {
    for (final materialId in values) {
      if (materialId != null) retain(materialId);
    }
  }
  final encoded = <String, List<int>>{
    for (final entry in mergedMaterials.entries)
      entry.key: <int>[
        for (final materialId in entry.value)
          materialId == null ? 0 : paletteIndex[materialId]!,
      ],
  };

  return SmartTileLayerUnionResult(
    layer: normalizedTarget.copyWith(
      materialPalette: List.unmodifiable(palette),
      field: _fieldFromLattices(normalizedTarget.field, encoded),
    ),
    mergedEntryCounts: mergedEntryCounts,
  );
}

Map<String, List<int>> _activeLattices(SmartTileLayer layer) =>
    switch (layer.field) {
      SmartTileCellField(:final semanticCells) => <String, List<int>>{
          'semanticCells': semanticCells,
        },
      SmartTileCornerField(:final semanticCells, :final corners) =>
        <String, List<int>>{
          'semanticCells': semanticCells,
          'corners': corners,
        },
      SmartTileEdgeField(
        :final semanticCells,
        :final horizontalEdges,
        :final verticalEdges,
      ) =>
        <String, List<int>>{
          'semanticCells': semanticCells,
          'horizontalEdges': horizontalEdges,
          'verticalEdges': verticalEdges,
        },
      SmartTileMixedField(
        :final semanticCells,
        :final horizontalEdges,
        :final verticalEdges,
        :final corners,
      ) =>
        <String, List<int>>{
          'semanticCells': semanticCells,
          'horizontalEdges': horizontalEdges,
          'verticalEdges': verticalEdges,
          'corners': corners,
        },
    };

SmartTileField _fieldFromLattices(
  SmartTileField field,
  Map<String, List<int>> lattices,
) =>
    switch (field) {
      SmartTileCellField() => SmartTileField.cell(
          semanticCells: lattices['semanticCells']!,
        ),
      SmartTileCornerField() => SmartTileField.corner(
          semanticCells: lattices['semanticCells']!,
          corners: lattices['corners']!,
        ),
      SmartTileEdgeField() => SmartTileField.edge(
          semanticCells: lattices['semanticCells']!,
          horizontalEdges: lattices['horizontalEdges']!,
          verticalEdges: lattices['verticalEdges']!,
        ),
      SmartTileMixedField() => SmartTileField.mixed(
          semanticCells: lattices['semanticCells']!,
          horizontalEdges: lattices['horizontalEdges']!,
          verticalEdges: lattices['verticalEdges']!,
          corners: lattices['corners']!,
        ),
    };

SmartTileField _withSemanticCells(SmartTileField field, List<int> values) =>
    switch (field) {
      SmartTileCellField() => SmartTileField.cell(semanticCells: values),
      SmartTileCornerField(:final corners) => SmartTileField.corner(
          semanticCells: values,
          corners: corners,
        ),
      SmartTileEdgeField(:final horizontalEdges, :final verticalEdges) =>
        SmartTileField.edge(
          semanticCells: values,
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
        ),
      SmartTileMixedField(
        :final horizontalEdges,
        :final verticalEdges,
        :final corners,
      ) =>
        SmartTileField.mixed(
          semanticCells: values,
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          corners: corners,
        ),
    };

SmartTileField _withHorizontalEdges(SmartTileField field, List<int> values) =>
    switch (field) {
      SmartTileEdgeField(:final semanticCells, :final verticalEdges) =>
        SmartTileField.edge(
          semanticCells: semanticCells,
          horizontalEdges: values,
          verticalEdges: verticalEdges,
        ),
      SmartTileMixedField(
        :final semanticCells,
        :final verticalEdges,
        :final corners,
      ) =>
        SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: values,
          verticalEdges: verticalEdges,
          corners: corners,
        ),
      SmartTileCellField() ||
      SmartTileCornerField() =>
        throw const ValidationException(
          'Smart Tile field has no horizontal edge lattice',
        ),
    };

SmartTileField _withVerticalEdges(SmartTileField field, List<int> values) =>
    switch (field) {
      SmartTileEdgeField(:final semanticCells, :final horizontalEdges) =>
        SmartTileField.edge(
          semanticCells: semanticCells,
          horizontalEdges: horizontalEdges,
          verticalEdges: values,
        ),
      SmartTileMixedField(
        :final semanticCells,
        :final horizontalEdges,
        :final corners,
      ) =>
        SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: horizontalEdges,
          verticalEdges: values,
          corners: corners,
        ),
      SmartTileCellField() ||
      SmartTileCornerField() =>
        throw const ValidationException(
          'Smart Tile field has no vertical edge lattice',
        ),
    };

SmartTileField _withCorners(SmartTileField field, List<int> values) =>
    switch (field) {
      SmartTileCornerField(:final semanticCells) => SmartTileField.corner(
          semanticCells: semanticCells,
          corners: values,
        ),
      SmartTileMixedField(
        :final semanticCells,
        :final horizontalEdges,
        :final verticalEdges,
      ) =>
        SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          corners: values,
        ),
      SmartTileCellField() ||
      SmartTileEdgeField() =>
        throw const ValidationException(
            'Smart Tile field has no corner lattice'),
    };

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
