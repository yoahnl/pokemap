import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/smart_tile.dart';
import '../models/smart_tile_field.dart';
import '../exceptions/map_exceptions.dart';
import '../validation/validators.dart';

sealed class SmartTileLayerCreationResult {
  const SmartTileLayerCreationResult();
}

final class SmartTileLayerCreationSuccess extends SmartTileLayerCreationResult {
  const SmartTileLayerCreationSuccess({
    required this.map,
    required this.manifest,
    required this.layerId,
  });

  final MapData map;
  final ProjectManifest manifest;
  final String layerId;
}

final class SmartTileLayerCreationFailure extends SmartTileLayerCreationResult {
  const SmartTileLayerCreationFailure({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

SmartTileLayerCreationResult planNativeSmartTileLayerCreation({
  required Iterable<MapData> projectMaps,
  required String targetMapId,
  required ProjectManifest manifest,
  required ProjectSmartTilePreset preset,
  required String layerId,
  required String layerName,
}) {
  final maps = List<MapData>.unmodifiable(projectMaps);
  final mapCoverageFailure = _validateProjectMapCoverage(
    manifest: manifest,
    projectMaps: maps,
  );
  if (mapCoverageFailure != null) {
    return mapCoverageFailure;
  }
  try {
    ProjectValidator.validate(manifest);
  } on ValidationException catch (error) {
    return SmartTileLayerCreationFailure(
      code: error.code ?? 'smart_tile_project_manifest_invalid',
      message: error.message,
    );
  }
  for (final map in maps) {
    if (map.id == targetMapId &&
        (map.size.width <= 0 || map.size.height <= 0)) {
      return SmartTileLayerCreationFailure(
        code: 'smart_tile_field_size_invalid',
        message: 'Smart Tile field size must be positive; received '
            '${map.size.width}x${map.size.height}.',
      );
    }
    try {
      MapValidator.validate(map, projectDialogueContext: manifest);
    } on ValidationException catch (error) {
      return SmartTileLayerCreationFailure(
        code: error.code ?? 'smart_tile_project_map_invalid',
        message: 'Map "${map.id}" is invalid: ${error.message}',
      );
    }
  }

  MapData? target;
  for (final map in maps) {
    if (map.id == targetMapId) {
      target = map;
      break;
    }
  }
  if (target == null) {
    return SmartTileLayerCreationFailure(
      code: 'smart_tile_target_map_missing',
      message: 'Target map "$targetMapId" does not exist.',
    );
  }

  final normalizedLayerId = layerId.trim();
  final normalizedLayerName = layerName.trim();
  if (normalizedLayerId.isEmpty || normalizedLayerName.isEmpty) {
    return const SmartTileLayerCreationFailure(
      code: 'smart_tile_layer_identity_invalid',
      message: 'Smart Tile layer id and name must not be blank.',
    );
  }
  if (target.layers.any((layer) => layer.id == normalizedLayerId)) {
    return SmartTileLayerCreationFailure(
      code: 'smart_tile_layer_id_duplicate',
      message: 'Layer id "$normalizedLayerId" already exists.',
    );
  }
  if (preset.usage == SmartTileUsage.terrain &&
      target.layers.any(
        (layer) =>
            layer is SmartTileLayer && layer.usage == SmartTileUsage.terrain,
      )) {
    return const SmartTileLayerCreationFailure(
      code: 'smart_tile_terrain_provider_already_exists',
      message: 'The target map already has a Smart Tile terrain provider.',
    );
  }

  final palette = <String>[''];
  final seenMaterials = <String>{};
  for (final rawMaterialId in preset.allowedMaterialIds) {
    final materialId = rawMaterialId.trim();
    if (materialId.isNotEmpty && seenMaterials.add(materialId)) {
      palette.add(materialId);
    }
  }
  final defaultMaterialIndex = palette.indexOf(preset.defaultMaterialId.trim());
  if (defaultMaterialIndex <= 0) {
    return const SmartTileLayerCreationFailure(
      code: 'smart_tile_default_material_invalid',
      message: 'The default material must be present in allowedMaterialIds.',
    );
  }
  final catalogMaterialIds = manifest.smartTileCatalog.materials
      .map((material) => material.id)
      .toSet();
  final missingMaterialIds = palette
      .skip(1)
      .where((materialId) => !catalogMaterialIds.contains(materialId))
      .toList(growable: false);
  if (missingMaterialIds.isNotEmpty) {
    return SmartTileLayerCreationFailure(
      code: 'smart_tile_native_catalog_materials_required',
      message: 'Native Smart Tile layer creation requires canonical catalog '
          'materials first; missing: ${missingMaterialIds.join(', ')}.',
    );
  }

  final fieldCreation = _createField(
    topology: preset.topology,
    width: target.size.width,
    height: target.size.height,
    fillIndex: preset.coveragePolicy == SmartTileCoveragePolicy.complete
        ? defaultMaterialIndex
        : 0,
    boundaryPolicy: preset.boundaryPolicy,
  );
  if (fieldCreation case final _SmartTileFieldCreationFailure failure) {
    return SmartTileLayerCreationFailure(
      code: failure.code,
      message: failure.message,
    );
  }
  final field = (fieldCreation as _SmartTileFieldCreationSuccess).field;
  if (!isSmartTileFieldCompatibleWithTopology(preset.topology, field)) {
    return const SmartTileLayerCreationFailure(
      code: 'smart_tile_topology_field_incompatible',
      message: 'The preset topology cannot create a compatible field.',
    );
  }

  final layer = MapLayer.smartTile(
    id: normalizedLayerId,
    name: normalizedLayerName,
    presetId: preset.id,
    usage: preset.usage,
    materialPalette: List<String>.unmodifiable(palette),
    field: field,
    layerSeed: preset.seedSalt,
  );
  final projectedMap = target.copyWith(
    version: ProjectVersion.v6,
    layers: List<MapLayer>.unmodifiable(<MapLayer>[...target.layers, layer]),
  );

  final catalog = manifest.smartTileCatalog;
  final existingPreset = catalog.presets
      .where((candidate) => candidate.id == preset.id)
      .firstOrNull;
  if (existingPreset != null && existingPreset != preset) {
    return SmartTileLayerCreationFailure(
      code: 'smart_tile_preset_id_conflict',
      message: 'Preset id "${preset.id}" already identifies another preset.',
    );
  }
  final projectedCatalog = ProjectSmartTileCatalog(
    categories: catalog.categories,
    atlases: catalog.atlases,
    materials: catalog.materials,
    animations: catalog.animations,
    drafts: catalog.drafts,
    patterns: catalog.patterns,
    presets: <ProjectSmartTilePreset>[
      ...catalog.presets,
      if (existingPreset == null) preset,
    ],
  );
  final projectedManifest = manifest.copyWith(
    version: ProjectVersion.v6,
    smartTileCatalog: projectedCatalog,
  );

  try {
    ProjectValidator.validate(projectedManifest);
  } on ValidationException catch (error) {
    return SmartTileLayerCreationFailure(
      code: error.code ?? 'smart_tile_projected_manifest_invalid',
      message: error.message,
    );
  }
  try {
    MapValidator.validate(
      projectedMap,
      projectDialogueContext: projectedManifest,
    );
  } on ValidationException catch (error) {
    return SmartTileLayerCreationFailure(
      code: error.code ?? 'smart_tile_projected_map_invalid',
      message: error.message,
    );
  }

  return SmartTileLayerCreationSuccess(
    map: projectedMap,
    manifest: projectedManifest,
    layerId: normalizedLayerId,
  );
}

SmartTileLayerCreationFailure? _validateProjectMapCoverage({
  required ProjectManifest manifest,
  required List<MapData> projectMaps,
}) {
  final duplicateManifestIds = _duplicateIds(
    manifest.maps.map((entry) => entry.id),
  );
  if (duplicateManifestIds.isNotEmpty) {
    return SmartTileLayerCreationFailure(
      code: 'smart_tile_manifest_maps_duplicate',
      message: 'manifest.maps: duplicate map ids '
          '[${duplicateManifestIds.join(', ')}].',
    );
  }
  final duplicateProjectMapIds = _duplicateIds(
    projectMaps.map((map) => map.id),
  );
  if (duplicateProjectMapIds.isNotEmpty) {
    return SmartTileLayerCreationFailure(
      code: 'smart_tile_project_maps_duplicate',
      message: 'projectMaps: duplicate map ids '
          '[${duplicateProjectMapIds.join(', ')}].',
    );
  }

  final manifestIds = manifest.maps.map((entry) => entry.id).toSet();
  final projectMapIds = projectMaps.map((map) => map.id).toSet();
  final missingIds = manifestIds.difference(projectMapIds).toList()..sort();
  if (missingIds.isNotEmpty) {
    return SmartTileLayerCreationFailure(
      code: 'smart_tile_project_maps_missing',
      message: 'projectMaps: missing manifest map ids '
          '[${missingIds.join(', ')}].',
    );
  }
  final extraIds = projectMapIds.difference(manifestIds).toList()..sort();
  if (extraIds.isNotEmpty) {
    return SmartTileLayerCreationFailure(
      code: 'smart_tile_project_maps_extra',
      message: 'projectMaps: map ids absent from manifest.maps '
          '[${extraIds.join(', ')}].',
    );
  }
  return null;
}

List<String> _duplicateIds(Iterable<String> ids) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      duplicates.add(id);
    }
  }
  return duplicates.toList()..sort();
}

const int _maximumSmartTileFieldEntries = 4194304;

sealed class _SmartTileFieldCreationResult {
  const _SmartTileFieldCreationResult();
}

final class _SmartTileFieldCreationSuccess
    extends _SmartTileFieldCreationResult {
  const _SmartTileFieldCreationSuccess(this.field);

  final SmartTileField field;
}

final class _SmartTileFieldCreationFailure
    extends _SmartTileFieldCreationResult {
  const _SmartTileFieldCreationFailure({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

_SmartTileFieldCreationResult _createField({
  required SmartTileTopology topology,
  required int width,
  required int height,
  required int fillIndex,
  required SmartTileBoundaryPolicy boundaryPolicy,
}) {
  if (width <= 0 || height <= 0) {
    return _SmartTileFieldCreationFailure(
      code: 'smart_tile_field_size_invalid',
      message: 'Smart Tile field size must be positive; received '
          '${width}x$height.',
    );
  }
  final shape = _fieldShape(
    topology: topology,
    width: width,
    height: height,
  );
  if (shape == null) {
    return _SmartTileFieldCreationFailure(
      code: 'smart_tile_field_allocation_limit_exceeded',
      message: 'Smart Tile field allocation exceeds the supported limit '
          '(topology=${topology.name}, size=${width}x$height, '
          'maximumEntries=$_maximumSmartTileFieldEntries).',
    );
  }

  final semanticCells = List<int>.filled(
    shape.semanticCells,
    fillIndex,
    growable: false,
  );
  final boundaryIndex =
      boundaryPolicy == SmartTileBoundaryPolicy.connected ? fillIndex : 0;

  return switch (topology) {
    SmartTileTopology.uniform ||
    SmartTileTopology.cardinal4 ||
    SmartTileTopology.blob8 =>
      _SmartTileFieldCreationSuccess(
        SmartTileField.cell(semanticCells: semanticCells),
      ),
    SmartTileTopology.wangEdge4 => _SmartTileFieldCreationSuccess(
        SmartTileField.edge(
          semanticCells: semanticCells,
          horizontalEdges: _createHorizontalEdges(
            length: shape.horizontalEdges!,
            width: width,
            height: height,
            fillIndex: fillIndex,
            boundaryIndex: boundaryIndex,
          ),
          verticalEdges: _createVerticalEdges(
            length: shape.verticalEdges!,
            width: width,
            fillIndex: fillIndex,
            boundaryIndex: boundaryIndex,
          ),
        ),
      ),
    SmartTileTopology.wangCorner4 => _SmartTileFieldCreationSuccess(
        SmartTileField.corner(
          semanticCells: semanticCells,
          corners: _createCorners(
            length: shape.corners!,
            width: width,
            height: height,
            fillIndex: fillIndex,
            boundaryIndex: boundaryIndex,
          ),
        ),
      ),
    SmartTileTopology.wang8 => _SmartTileFieldCreationSuccess(
        SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: _createHorizontalEdges(
            length: shape.horizontalEdges!,
            width: width,
            height: height,
            fillIndex: fillIndex,
            boundaryIndex: boundaryIndex,
          ),
          verticalEdges: _createVerticalEdges(
            length: shape.verticalEdges!,
            width: width,
            fillIndex: fillIndex,
            boundaryIndex: boundaryIndex,
          ),
          corners: _createCorners(
            length: shape.corners!,
            width: width,
            height: height,
            fillIndex: fillIndex,
            boundaryIndex: boundaryIndex,
          ),
        ),
      ),
  };
}

final class _SmartTileFieldShape {
  const _SmartTileFieldShape({
    required this.semanticCells,
    this.horizontalEdges,
    this.verticalEdges,
    this.corners,
  });

  final int semanticCells;
  final int? horizontalEdges;
  final int? verticalEdges;
  final int? corners;
}

_SmartTileFieldShape? _fieldShape({
  required SmartTileTopology topology,
  required int width,
  required int height,
}) {
  final semanticCells = _checkedFieldProduct(width, height);
  if (semanticCells == null) {
    return null;
  }
  final usesEdges = topology == SmartTileTopology.wangEdge4 ||
      topology == SmartTileTopology.wang8;
  final usesCorners = topology == SmartTileTopology.wangCorner4 ||
      topology == SmartTileTopology.wang8;
  final horizontalEdges =
      usesEdges ? _checkedFieldProduct(width, height + 1) : null;
  final verticalEdges =
      usesEdges ? _checkedFieldProduct(width + 1, height) : null;
  final corners =
      usesCorners ? _checkedFieldProduct(width + 1, height + 1) : null;
  if ((usesEdges && (horizontalEdges == null || verticalEdges == null)) ||
      (usesCorners && corners == null)) {
    return null;
  }

  final activeCounts = <int>[
    semanticCells,
    if (usesEdges) horizontalEdges!,
    if (usesEdges) verticalEdges!,
    if (usesCorners) corners!,
  ];
  var total = 0;
  for (final count in activeCounts) {
    if (count > _maximumSmartTileFieldEntries - total) {
      return null;
    }
    total += count;
  }
  return _SmartTileFieldShape(
    semanticCells: semanticCells,
    horizontalEdges: horizontalEdges,
    verticalEdges: verticalEdges,
    corners: corners,
  );
}

int? _checkedFieldProduct(int left, int right) {
  if (left <= 0 ||
      right <= 0 ||
      left > _maximumSmartTileFieldEntries ||
      right > _maximumSmartTileFieldEntries ||
      left > _maximumSmartTileFieldEntries ~/ right) {
    return null;
  }
  return left * right;
}

List<int> _createHorizontalEdges({
  required int length,
  required int width,
  required int height,
  required int fillIndex,
  required int boundaryIndex,
}) =>
    List<int>.generate(
      length,
      (index) {
        final y = index ~/ width;
        return y > 0 && y < height ? fillIndex : boundaryIndex;
      },
      growable: false,
    );

List<int> _createVerticalEdges({
  required int length,
  required int width,
  required int fillIndex,
  required int boundaryIndex,
}) =>
    List<int>.generate(
      length,
      (index) {
        final x = index % (width + 1);
        return x > 0 && x < width ? fillIndex : boundaryIndex;
      },
      growable: false,
    );

List<int> _createCorners({
  required int length,
  required int width,
  required int height,
  required int fillIndex,
  required int boundaryIndex,
}) =>
    List<int>.generate(
      length,
      (index) {
        final x = index % (width + 1);
        final y = index ~/ (width + 1);
        return x > 0 && x < width && y > 0 && y < height
            ? fillIndex
            : boundaryIndex;
      },
      growable: false,
    );

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
