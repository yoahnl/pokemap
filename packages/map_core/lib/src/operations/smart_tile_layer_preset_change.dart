import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import '../models/smart_tile_field.dart';
import 'smart_tile_layer_readiness.dart';

sealed class SmartTileLayerPresetChangeResult {
  const SmartTileLayerPresetChangeResult();
}

final class SmartTileLayerPresetChangeSuccess
    extends SmartTileLayerPresetChangeResult {
  SmartTileLayerPresetChangeSuccess({
    required this.layer,
    required this.remappedEntryCount,
    required this.clearedCandidateWeightCount,
    required Map<String, String> materialMappings,
  }) : materialMappings = Map<String, String>.unmodifiable(materialMappings);

  final SmartTileLayer layer;
  final int remappedEntryCount;
  final int clearedCandidateWeightCount;
  final Map<String, String> materialMappings;
}

final class SmartTileLayerPresetChangeFailure
    extends SmartTileLayerPresetChangeResult {
  SmartTileLayerPresetChangeFailure({
    required this.code,
    required this.message,
    List<String> requiredMaterialIds = const <String>[],
  }) : requiredMaterialIds = List<String>.unmodifiable(requiredMaterialIds);

  final String code;
  final String message;
  final List<String> requiredMaterialIds;
}

SmartTileLayerPresetChangeResult planSmartTileLayerPresetChange({
  required MapData map,
  required SmartTileLayer layer,
  required ProjectSmartTilePreset sourcePreset,
  required ProjectSmartTilePreset targetPreset,
  required ProjectSmartTileCatalog catalog,
  Map<String, String> materialMappings = const <String, String>{},
}) {
  if (sourcePreset.id != layer.presetId) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_source_mismatch',
      message:
          'Layer "${layer.id}" references preset "${layer.presetId}", '
          'not "${sourcePreset.id}".',
    );
  }
  if (sourcePreset.id == targetPreset.id) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_no_change',
      message: 'Layer "${layer.id}" already uses preset "${targetPreset.id}".',
    );
  }
  if (targetPreset.status != SmartTilePresetStatus.published) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_not_published',
      message: 'Target preset "${targetPreset.id}" is not published.',
    );
  }
  if (sourcePreset.usage != layer.usage || targetPreset.usage != layer.usage) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_usage_incompatible',
      message:
          'Target preset "${targetPreset.id}" does not use the '
          '${layer.usage.name} layer usage.',
    );
  }
  if (!isSmartTileFieldCompatibleWithTopology(
    targetPreset.topology,
    layer.field,
  )) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_topology_incompatible',
      message:
          'Target preset "${targetPreset.id}" topology '
          '${targetPreset.topology.name} is incompatible with the existing '
          'layer field.',
    );
  }

  final mapLayerIndex = map.layers.indexWhere(
    (candidate) => candidate.id == layer.id,
  );
  if (mapLayerIndex < 0 || map.layers[mapLayerIndex] != layer) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_layer_mismatch',
      message:
          'Layer "${layer.id}" is not the current layer in map '
          '"${map.id}".',
    );
  }

  final targetPalette = _targetPalette(targetPreset);
  final catalogMaterialIds = catalog.materials
      .map((material) => material.id)
      .toSet();
  final invalidTargetMaterialIds = targetPalette
      .skip(1)
      .where((materialId) => !catalogMaterialIds.contains(materialId))
      .toList(growable: false);
  final targetDefaultMaterialId = targetPreset.defaultMaterialId.trim();
  if (!targetPalette.contains(targetDefaultMaterialId) ||
      invalidTargetMaterialIds.isNotEmpty) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_material_mapping_invalid',
      message:
          'Target preset "${targetPreset.id}" has an invalid material '
          'palette.',
    );
  }

  final activeLattices = _activeLattices(layer.field);
  if (!_hasExpectedDimensions(map, layer.field)) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_field_invalid',
      message:
          'Layer "${layer.id}" field dimensions do not match map '
          '"${map.id}".',
    );
  }
  int? invalidPaletteIndex;
  for (final lattice in activeLattices) {
    for (final value in lattice) {
      if (value < 0 || value >= layer.materialPalette.length) {
        invalidPaletteIndex = value;
        break;
      }
    }
    if (invalidPaletteIndex != null) {
      break;
    }
  }
  if (invalidPaletteIndex != null) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_material_mapping_invalid',
      message:
          'Layer "${layer.id}" references palette index '
          '$invalidPaletteIndex outside its material palette.',
    );
  }

  final usedPaletteIndexes = <int>{
    for (final lattice in activeLattices)
      for (final value in lattice) value,
  };
  final behaviorMaterialId = layer.encounterBehavior?.materialId.trim();
  if (behaviorMaterialId != null && behaviorMaterialId.isNotEmpty) {
    final behaviorPaletteIndex = layer.materialPalette.indexOf(
      behaviorMaterialId,
    );
    if (behaviorPaletteIndex <= 0) {
      return SmartTileLayerPresetChangeFailure(
        code: 'smart_tile.layer_preset_material_mapping_invalid',
        message:
            'Layer "${layer.id}" encounter behavior references invalid '
            'material "$behaviorMaterialId".',
      );
    }
    usedPaletteIndexes.add(behaviorPaletteIndex);
  }
  final usedMaterialIds = <String>[];
  final seenUsedMaterialIds = <String>{};
  for (
    var paletteIndex = 1;
    paletteIndex < layer.materialPalette.length;
    paletteIndex += 1
  ) {
    if (!usedPaletteIndexes.contains(paletteIndex)) {
      continue;
    }
    final materialId = layer.materialPalette[paletteIndex].trim();
    if (materialId.isEmpty || !catalogMaterialIds.contains(materialId)) {
      return SmartTileLayerPresetChangeFailure(
        code: 'smart_tile.layer_preset_material_mapping_invalid',
        message:
            'Layer "${layer.id}" uses invalid material at palette '
            'index $paletteIndex.',
      );
    }
    if (seenUsedMaterialIds.add(materialId)) {
      usedMaterialIds.add(materialId);
    }
  }

  final normalizedMappings = <String, String>{};
  for (final entry in materialMappings.entries) {
    final sourceMaterialId = entry.key.trim();
    final targetMaterialId = entry.value.trim();
    if (sourceMaterialId.isEmpty ||
        targetMaterialId.isEmpty ||
        !seenUsedMaterialIds.contains(sourceMaterialId) ||
        !targetPalette.contains(targetMaterialId) ||
        !catalogMaterialIds.contains(targetMaterialId)) {
      return SmartTileLayerPresetChangeFailure(
        code: 'smart_tile.layer_preset_material_mapping_invalid',
        message:
            'Material mapping "${entry.key}" to "${entry.value}" '
            'cannot be applied to target preset "${targetPreset.id}".',
      );
    }
    final previous = normalizedMappings[sourceMaterialId];
    if (previous != null && previous != targetMaterialId) {
      return SmartTileLayerPresetChangeFailure(
        code: 'smart_tile.layer_preset_material_mapping_invalid',
        message: 'Material "$sourceMaterialId" has conflicting mappings.',
      );
    }
    normalizedMappings[sourceMaterialId] = targetMaterialId;
  }

  final effectiveMappings = <String, String>{};
  final requiredMaterialIds = <String>[];
  for (final sourceMaterialId in usedMaterialIds) {
    final explicitTarget = normalizedMappings[sourceMaterialId];
    if (explicitTarget != null) {
      effectiveMappings[sourceMaterialId] = explicitTarget;
    } else if (targetPalette.contains(sourceMaterialId)) {
      effectiveMappings[sourceMaterialId] = sourceMaterialId;
    } else {
      requiredMaterialIds.add(sourceMaterialId);
    }
  }
  if (requiredMaterialIds.isNotEmpty) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_material_mapping_required',
      message:
          'Target preset "${targetPreset.id}" needs mappings for '
          '${requiredMaterialIds.join(', ')}.',
      requiredMaterialIds: requiredMaterialIds,
    );
  }

  final paletteIndexMappings = <int, int>{0: 0};
  for (
    var sourceIndex = 1;
    sourceIndex < layer.materialPalette.length;
    sourceIndex += 1
  ) {
    final sourceMaterialId = layer.materialPalette[sourceIndex].trim();
    final targetMaterialId = effectiveMappings[sourceMaterialId];
    if (targetMaterialId != null) {
      paletteIndexMappings[sourceIndex] = targetPalette.indexOf(
        targetMaterialId,
      );
    }
  }

  var remappedEntryCount = 0;
  List<int> reproject(List<int> values) => List<int>.unmodifiable(
    values.map((sourceIndex) {
      final targetIndex = paletteIndexMappings[sourceIndex];
      if (targetIndex == null) {
        return 0;
      }
      final sourceMaterialId = sourceIndex == 0
          ? null
          : layer.materialPalette[sourceIndex].trim();
      final targetMaterialId = sourceMaterialId == null
          ? null
          : effectiveMappings[sourceMaterialId];
      if (sourceIndex != targetIndex || sourceMaterialId != targetMaterialId) {
        remappedEntryCount += 1;
      }
      return targetIndex;
    }),
  );

  final projectedField = switch (layer.field) {
    SmartTileCellField(:final semanticCells) => SmartTileField.cell(
      semanticCells: reproject(semanticCells),
    ),
    SmartTileEdgeField(
      :final semanticCells,
      :final horizontalEdges,
      :final verticalEdges,
    ) =>
      SmartTileField.edge(
        semanticCells: reproject(semanticCells),
        horizontalEdges: reproject(horizontalEdges),
        verticalEdges: reproject(verticalEdges),
      ),
    SmartTileCornerField(:final semanticCells, :final corners) =>
      SmartTileField.corner(
        semanticCells: reproject(semanticCells),
        corners: reproject(corners),
      ),
    SmartTileMixedField(
      :final semanticCells,
      :final horizontalEdges,
      :final verticalEdges,
      :final corners,
    ) =>
      SmartTileField.mixed(
        semanticCells: reproject(semanticCells),
        horizontalEdges: reproject(horizontalEdges),
        verticalEdges: reproject(verticalEdges),
        corners: reproject(corners),
      ),
  };
  final projectedLayer = layer.copyWith(
    presetId: targetPreset.id,
    materialPalette: targetPalette,
    field: projectedField,
    candidateWeights: const <String, int>{},
    encounterBehavior: layer.encounterBehavior == null
        ? null
        : layer.encounterBehavior!.copyWith(
            materialId: effectiveMappings[behaviorMaterialId]!,
          ),
  );
  final projectedLayers = List<MapLayer>.of(map.layers)
    ..[mapLayerIndex] = projectedLayer;
  final readiness = analyzeSmartTileLayerReadiness(
    map: map.copyWith(layers: List<MapLayer>.unmodifiable(projectedLayers)),
    layer: projectedLayer,
    preset: targetPreset,
    materials: catalog.materials,
  );
  if (readiness.hasErrors) {
    return SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_unresolved',
      message:
          'Target preset "${targetPreset.id}" cannot resolve the '
          'existing layer geometry.',
    );
  }

  return SmartTileLayerPresetChangeSuccess(
    layer: projectedLayer,
    remappedEntryCount: remappedEntryCount,
    clearedCandidateWeightCount: layer.candidateWeights.length,
    materialMappings: effectiveMappings,
  );
}

List<String> _targetPalette(ProjectSmartTilePreset preset) {
  final palette = <String>[''];
  final seenMaterialIds = <String>{};
  for (final rawMaterialId in preset.allowedMaterialIds) {
    final materialId = rawMaterialId.trim();
    if (materialId.isNotEmpty && seenMaterialIds.add(materialId)) {
      palette.add(materialId);
    }
  }
  return List<String>.unmodifiable(palette);
}

List<List<int>> _activeLattices(SmartTileField field) => switch (field) {
  SmartTileCellField(:final semanticCells) => <List<int>>[semanticCells],
  SmartTileEdgeField(
    :final semanticCells,
    :final horizontalEdges,
    :final verticalEdges,
  ) =>
    <List<int>>[semanticCells, horizontalEdges, verticalEdges],
  SmartTileCornerField(:final semanticCells, :final corners) => <List<int>>[
    semanticCells,
    corners,
  ],
  SmartTileMixedField(
    :final semanticCells,
    :final horizontalEdges,
    :final verticalEdges,
    :final corners,
  ) =>
    <List<int>>[semanticCells, horizontalEdges, verticalEdges, corners],
};

bool _hasExpectedDimensions(MapData map, SmartTileField field) {
  final width = map.size.width;
  final height = map.size.height;
  final cellCount = width * height;
  final horizontalEdgeCount = width * (height + 1);
  final verticalEdgeCount = (width + 1) * height;
  final cornerCount = (width + 1) * (height + 1);
  return switch (field) {
    SmartTileCellField(:final semanticCells) =>
      semanticCells.length == cellCount,
    SmartTileEdgeField(
      :final semanticCells,
      :final horizontalEdges,
      :final verticalEdges,
    ) =>
      semanticCells.length == cellCount &&
          horizontalEdges.length == horizontalEdgeCount &&
          verticalEdges.length == verticalEdgeCount,
    SmartTileCornerField(:final semanticCells, :final corners) =>
      semanticCells.length == cellCount && corners.length == cornerCount,
    SmartTileMixedField(
      :final semanticCells,
      :final horizontalEdges,
      :final verticalEdges,
      :final corners,
    ) =>
      semanticCells.length == cellCount &&
          horizontalEdges.length == horizontalEdgeCount &&
          verticalEdges.length == verticalEdgeCount &&
          corners.length == cornerCount,
  };
}
