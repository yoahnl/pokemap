import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import '../contracts/semantic_map_failure.dart';

part 'environment_editing_models.dart';
part 'environment_area_editing.dart';
part 'environment_mask_editing.dart';
part 'environment_placement_editing.dart';
part 'environment_generation_editing.dart';
part 'environment_generation_support.dart';

class EnvironmentEditing with _EnvironmentGenerationEditing {
  const EnvironmentEditing();

  static const int generationHaloCells = 1;
  static const int maxGenerationCells = 4096;

  MapData createArea(
    MapData map, {
    required ProjectManifest manifest,
    required String layerId,
    required String areaId,
    required String name,
    required String presetId,
    required int seed,
  }) {
    _requireStableText(layerId, 'layerId');
    _requireStableText(areaId, 'areaId');
    _requireStableText(name, 'name');
    _requireStableText(presetId, 'presetId');
    _preset(manifest, presetId);
    return _createArea(map,
        layerId: layerId,
        areaId: areaId,
        name: name,
        presetId: presetId,
        seed: seed);
  }

  MapData paintCells(
    MapData map, {
    required String layerId,
    required String areaId,
    required Iterable<GridPos> cells,
    required bool value,
  }) {
    _requireEditableMask(map, layerId, areaId);
    final selection = _parameterCells(
      [
        for (final cell in cells) {'x': cell.x, 'y': cell.y}
      ],
      map.size,
    );
    return _editMaskCells(map,
        layerId: layerId, areaId: areaId, cells: selection, value: value);
  }

  MapData paintRegion(
    MapData map, {
    required String layerId,
    required String areaId,
    required EnvironmentGenerationRegion region,
    required bool value,
  }) {
    _requireEditableMask(map, layerId, areaId);
    _requireRegion(region, map.size);
    return _editMask(map,
        layerId: layerId, areaId: areaId, region: region, value: value);
  }

  MapData deleteArea(MapData map,
          {required String layerId, required String areaId}) =>
      _deleteArea(map, layerId: layerId, areaId: areaId);

  MapData setSeed(MapData map,
          {required String layerId,
          required String areaId,
          required int seed}) =>
      _replaceArea(map,
          layerId: layerId,
          areaId: areaId,
          update: (area) => _copyArea(area, seed: seed));

  MapData attachToTileLayer(MapData map,
          {required String layerId, required String targetTileLayerId}) =>
      _attach(map, layerId: layerId, targetTileLayerId: targetTileLayerId);

  static void validateRegion(
          EnvironmentGenerationRegion region, GridSize size) =>
      _requireRegion(region, size);

  static List<({int x, int y})> parseMaskCells(
          List<Object?> raw, GridSize size) =>
      _parameterCells(raw, size);

  static int nextSeed(int seed) => _nextSeed(seed);

  EnvironmentArea areaOf(MapData map,
      {required String layerId, required String areaId}) {
    final area = _environmentLayer(map, layerId).content.areaById(areaId);
    if (area == null) {
      throw semanticFailure('environment.area_missing',
          'The requested Environment area does not exist.',
          details: {'areaId': areaId});
    }
    return area;
  }

  MapData updateArea(
    MapData map, {
    required ProjectManifest manifest,
    required String layerId,
    required String areaId,
    String? name,
    String? presetId,
    int? seed,
    EnvironmentGenerationParams? paramsOverride,
    bool clearParamsOverride = false,
  }) {
    if (name != null) _requireStableText(name, 'name');
    if (presetId != null) _preset(manifest, presetId);
    if (clearParamsOverride && paramsOverride != null) {
      throw invalidSemanticField(
          'paramsOverride', 'absent when clearParamsOverride is true');
    }
    return _replaceArea(map,
        layerId: layerId,
        areaId: areaId,
        update: (area) => _copyArea(area,
            name: name,
            presetId: presetId,
            seed: seed,
            paramsOverride: paramsOverride,
            clearParamsOverride: clearParamsOverride));
  }

  MapData detachFromTileLayer(MapData map, {required String layerId}) =>
      _attach(map, layerId: layerId, targetTileLayerId: null);

  MapData clearMask(MapData map,
          {required String layerId, required String areaId}) =>
      _clearMask(map, layerId: layerId, areaId: areaId);

  MapData addGeneratedPlacement(
    ProjectManifest manifest,
    MapData map, {
    required String layerId,
    required String areaId,
    required String placementId,
    required String elementId,
    required GridPos pos,
  }) =>
      _addManualPlacement(manifest, map,
          layerId: layerId,
          areaId: areaId,
          placementId: placementId,
          elementId: elementId,
          pos: pos);

  MapData moveGeneratedPlacement(
    MapData map, {
    required String layerId,
    required String areaId,
    required String placementId,
    required GridPos pos,
  }) =>
      _moveManualPlacement(map,
          layerId: layerId, areaId: areaId, placementId: placementId, pos: pos);

  MapData deleteGeneratedPlacement(
    MapData map, {
    required String layerId,
    required String areaId,
    required String placementId,
  }) =>
      _deletePlacement(map,
          layerId: layerId, areaId: areaId, placementId: placementId);

  MapData clearGeneratedPlacements(MapData map,
          {required String layerId, required String areaId}) =>
      _clearPlacements(map, layerId: layerId, areaId: areaId);
}
