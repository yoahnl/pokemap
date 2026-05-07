import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'environment_generator_apply_use_cases.dart';
import 'environment_generator_use_cases.dart';

final class GenerateTileLayerEnvironmentAreaPlacementsResult {
  const GenerateTileLayerEnvironmentAreaPlacementsResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.generatedPlacementIds,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final List<String> generatedPlacementIds;

  int get generatedPlacementCount => generatedPlacementIds.length;
}

class GenerateTileLayerEnvironmentAreaPlacementsUseCase {
  GenerateTileLayerEnvironmentAreaPlacementsResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String areaId,
  }) {
    final target = _resolveTarget(
      map,
      manifest: manifest,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );

    final generation = GenerateEnvironmentAreaPlacementsUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
    );
    if (generation.hasErrors) {
      throw EditorValidationException(_firstGenerationError(generation));
    }
    if (generation.placements.isEmpty) {
      return GenerateTileLayerEnvironmentAreaPlacementsResult(
        map: map,
        tileLayerId: target.tileLayer.id,
        environmentLayerId: target.environmentLayer.id,
        areaId: target.area.id,
        generatedPlacementIds: const [],
      );
    }

    final apply = ApplyEnvironmentGeneratedPlacementsUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      candidates: generation.placements,
    );
    if (apply.hasErrors) {
      throw EditorValidationException(_firstApplyError(apply));
    }

    return GenerateTileLayerEnvironmentAreaPlacementsResult(
      map: apply.map,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      generatedPlacementIds: [
        for (final placement in apply.appliedPlacements)
          placement.placedElementId,
      ],
    );
  }
}

_TileLayerEnvironmentGenerationTarget _resolveTarget(
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

  final preset = _presetById(manifest, area.presetId);
  if (preset == null) {
    throw EditorValidationException(
      'Environment preset not found: ${area.presetId.trim()}',
    );
  }
  if (area.mask.activeCellCount == 0) {
    throw const EditorValidationException(
      'Masque vide : peignez une zone sur la carte avant de générer.',
    );
  }
  if (area.generatedPlacementIds.isNotEmpty) {
    throw const EditorValidationException(
      'Cette zone possède déjà des placements générés.',
    );
  }

  return _TileLayerEnvironmentGenerationTarget(
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

String _firstGenerationError(EnvironmentGenerationResult result) {
  final issue = result.issues.firstWhere(
    (issue) => issue.severity == EnvironmentGenerationIssueSeverity.error,
    orElse: () => result.issues.first,
  );
  return issue.message;
}

String _firstApplyError(EnvironmentApplyResult result) {
  final issue = result.issues.firstWhere(
    (issue) => issue.severity == EnvironmentApplyIssueSeverity.error,
    orElse: () => result.issues.first,
  );
  return issue.message;
}

final class _TileLayerEnvironmentGenerationTarget {
  const _TileLayerEnvironmentGenerationTarget({
    required this.tileLayer,
    required this.environmentLayer,
    required this.area,
  });

  final TileLayer tileLayer;
  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
