import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'environment_generator_regenerate_use_cases.dart';
import 'tile_layer_environment_clear_use_cases.dart';
import 'tile_layer_environment_generation_use_cases.dart';

final class TileLayerEnvironmentRegenerationResult {
  const TileLayerEnvironmentRegenerationResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.previousSeed,
    required this.currentSeed,
    required this.removedPlacementIds,
    required this.clearedReferenceCount,
    required this.generatedPlacementIds,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final int previousSeed;
  final int currentSeed;
  final List<String> removedPlacementIds;
  final int clearedReferenceCount;
  final List<String> generatedPlacementIds;

  int get removedPlacementCount => removedPlacementIds.length;
  int get generatedPlacementCount => generatedPlacementIds.length;
  bool get seedChanged => previousSeed != currentSeed;
}

class RegenerateTileLayerEnvironmentAreaPlacementsUseCase {
  TileLayerEnvironmentRegenerationResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String areaId,
  }) {
    return _regenerateOrShuffle(
      map,
      manifest: manifest,
      tileLayerId: tileLayerId,
      areaId: areaId,
      shuffle: false,
    );
  }
}

class ShuffleTileLayerEnvironmentAreaPlacementsUseCase {
  TileLayerEnvironmentRegenerationResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String areaId,
  }) {
    return _regenerateOrShuffle(
      map,
      manifest: manifest,
      tileLayerId: tileLayerId,
      areaId: areaId,
      shuffle: true,
    );
  }
}

TileLayerEnvironmentRegenerationResult _regenerateOrShuffle(
  MapData map, {
  required ProjectManifest manifest,
  required String tileLayerId,
  required String areaId,
  required bool shuffle,
}) {
  final target = _resolveRegenerationTarget(
    map,
    manifest: manifest,
    tileLayerId: tileLayerId,
    areaId: areaId,
  );
  final previousSeed = target.area.seed;
  final clear =
      ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase().execute(
    map,
    tileLayerId: target.tileLayer.id,
    areaId: target.area.id,
  );

  var working = clear.map;
  var currentSeed = previousSeed;
  if (shuffle) {
    currentSeed = nextEnvironmentAreaSeed(previousSeed);
    final seed = SetEnvironmentAreaSeedUseCase().execute(
      working,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      seed: currentSeed,
    );
    if (!seed.isSuccess) {
      throw EditorValidationException(seed.failureMessage ?? 'Seed invalide');
    }
    working = seed.map!;
  }

  final generate = GenerateTileLayerEnvironmentAreaPlacementsUseCase().execute(
    working,
    manifest: manifest,
    tileLayerId: target.tileLayer.id,
    areaId: target.area.id,
  );

  return TileLayerEnvironmentRegenerationResult(
    map: generate.map,
    tileLayerId: target.tileLayer.id,
    environmentLayerId: target.environmentLayer.id,
    areaId: target.area.id,
    previousSeed: previousSeed,
    currentSeed: currentSeed,
    removedPlacementIds: clear.removedPlacementIds,
    clearedReferenceCount: clear.clearedReferenceCount,
    generatedPlacementIds: generate.generatedPlacementIds,
  );
}

_TileLayerEnvironmentRegenerationTarget _resolveRegenerationTarget(
  MapData map, {
  required ProjectManifest manifest,
  required String tileLayerId,
  required String areaId,
}) {
  final tid = tileLayerId.trim();
  if (tid.isEmpty) {
    throw const EditorValidationException('Tile layer id cannot be empty');
  }
  final aid = areaId.trim();
  if (aid.isEmpty) {
    throw const EditorValidationException(
      'Environment area id cannot be empty',
    );
  }

  final layer = _findLayerById(map, tid);
  if (layer == null) {
    throw EditorValidationException('Tile layer not found: $tid');
  }
  if (layer is! TileLayer) {
    throw EditorValidationException('Layer is not a TileLayer: $tid');
  }

  final environmentLayer = _firstEnvironmentLayerTargeting(map, tid);
  if (environmentLayer == null) {
    throw const EditorValidationException(
      'Activez d’abord l’environnement sur ce layer.',
    );
  }

  final area = environmentLayer.content.areaById(aid);
  if (area == null) {
    throw EditorValidationException('Environment area not found: $aid');
  }
  if (_presetById(manifest, area.presetId) == null) {
    throw EditorValidationException(
      'Environment preset not found: ${area.presetId.trim()}',
    );
  }
  if (area.mask.activeCellCount == 0) {
    throw const EditorValidationException(
      'Masque vide : peignez une zone sur la carte avant de régénérer.',
    );
  }
  if (area.generatedPlacementIds.isEmpty) {
    throw const EditorValidationException(
      'Aucun placement généré à régénérer pour cette zone.',
    );
  }

  return _TileLayerEnvironmentRegenerationTarget(
    tileLayer: layer,
    environmentLayer: environmentLayer,
    area: area,
  );
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) return layer;
  }
  return null;
}

EnvironmentLayer? _firstEnvironmentLayerTargeting(
  MapData map,
  String tileLayerId,
) {
  for (final layer in map.layers) {
    if (layer is EnvironmentLayer &&
        layer.content.targetTileLayerId?.trim() == tileLayerId) {
      return layer;
    }
  }
  return null;
}

EnvironmentPreset? _presetById(ProjectManifest manifest, String presetId) {
  final pid = presetId.trim();
  for (final preset in manifest.environmentPresets) {
    if (preset.id == pid) return preset;
  }
  return null;
}

final class _TileLayerEnvironmentRegenerationTarget {
  const _TileLayerEnvironmentRegenerationTarget({
    required this.tileLayer,
    required this.environmentLayer,
    required this.area,
  });

  final TileLayer tileLayer;
  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
