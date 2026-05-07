import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'layer_use_cases.dart';

final class EnableTileLayerEnvironmentAttachmentResult {
  const EnableTileLayerEnvironmentAttachmentResult({
    required this.map,
    required this.environmentLayerId,
    required this.tileLayerId,
    required this.created,
    required this.alreadyAttached,
  });

  final MapData map;
  final String environmentLayerId;
  final String tileLayerId;
  final bool created;
  final bool alreadyAttached;
}

class EnableTileLayerEnvironmentAttachmentUseCase {
  EnableTileLayerEnvironmentAttachmentResult execute(
    MapData map, {
    required String tileLayerId,
  }) {
    final tid = tileLayerId.trim();
    if (tid.isEmpty) {
      throw const EditorValidationException('Tile layer id cannot be empty');
    }

    final tileLayerIndex = map.layers.indexWhere((layer) => layer.id == tid);
    if (tileLayerIndex < 0) {
      throw EditorValidationException('Tile layer not found: $tid');
    }

    final tileLayer = map.layers[tileLayerIndex];
    if (tileLayer is! TileLayer) {
      throw EditorValidationException('Layer is not a TileLayer: $tid');
    }

    for (final layer in map.layers) {
      if (layer is EnvironmentLayer &&
          layer.content.targetTileLayerId?.trim() == tid) {
        return EnableTileLayerEnvironmentAttachmentResult(
          map: map,
          environmentLayerId: layer.id,
          tileLayerId: tid,
          created: false,
          alreadyAttached: true,
        );
      }
    }

    final environmentLayerId = _uniqueEnvironmentLayerId(
      map,
      tileLayerName: tileLayer.name,
    );
    final environmentLayer = MapLayer.environment(
      id: environmentLayerId,
      name: _environmentLayerName(tileLayer.name),
      content: EnvironmentLayerContent(
        targetTileLayerId: tid,
        areas: const [],
      ),
    );

    final updatedLayers = List<MapLayer>.from(map.layers, growable: true)
      ..insert(tileLayerIndex + 1, environmentLayer);
    final updatedMap = map.copyWith(layers: updatedLayers);

    try {
      MapValidator.validate(updatedMap);
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }

    return EnableTileLayerEnvironmentAttachmentResult(
      map: updatedMap,
      environmentLayerId: environmentLayerId,
      tileLayerId: tid,
      created: true,
      alreadyAttached: false,
    );
  }
}

final class CreateTileLayerEnvironmentAreaResult {
  const CreateTileLayerEnvironmentAreaResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.presetId,
    required this.created,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final String presetId;
  final bool created;
}

class CreateTileLayerEnvironmentAreaUseCase {
  CreateTileLayerEnvironmentAreaResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String presetId,
  }) {
    final tid = tileLayerId.trim();
    if (tid.isEmpty) {
      throw const EditorValidationException('Tile layer id cannot be empty');
    }
    final pid = presetId.trim();
    if (pid.isEmpty) {
      throw const EditorValidationException('Preset id cannot be empty');
    }

    final selectedLayer = _findLayerById(map, tid);
    if (selectedLayer == null) {
      throw EditorValidationException('Tile layer not found: $tid');
    }
    if (selectedLayer is! TileLayer) {
      throw EditorValidationException('Layer is not a TileLayer: $tid');
    }

    final environmentLayer = _firstEnvironmentLayerTargeting(map, tid);
    if (environmentLayer == null) {
      throw const EditorValidationException(
        'Activez d’abord l’environnement sur ce layer.',
      );
    }

    final result = AddEnvironmentAreaUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: environmentLayer.id,
      presetId: pid,
    );

    return CreateTileLayerEnvironmentAreaResult(
      map: result.map,
      tileLayerId: tid,
      environmentLayerId: environmentLayer.id,
      areaId: result.area.id,
      presetId: pid,
      created: true,
    );
  }
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
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

String _environmentLayerName(String tileLayerName) {
  final normalized = tileLayerName.trim();
  if (normalized.isEmpty) {
    return 'Environnement';
  }
  return 'Environnement - $normalized';
}

String _uniqueEnvironmentLayerId(
  MapData map, {
  required String tileLayerName,
}) {
  final existingIds = map.layers.map((layer) => layer.id).toSet();
  final slug = _slugify(tileLayerName);
  final base = slug.isEmpty ? 'l_environment' : 'l_environment_$slug';
  if (!existingIds.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existingIds.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return replaced.replaceAll(RegExp(r'^_+|_+$'), '');
}
