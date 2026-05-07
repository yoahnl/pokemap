import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

/// Lot Environment-22 : peinture / effacement d’une cellule du masque d’une zone.
///
/// Ne modifie pas [MapData] si la cellule a déjà la valeur demandée (référence
/// identique pour éviter dirty inutile).
class PaintEnvironmentAreaMaskCellUseCase {
  MapData execute(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
    required GridPos pos,
    required bool isActive,
  }) {
    final envId = environmentLayerId.trim();
    if (envId.isEmpty) {
      throw const EditorValidationException(
        'Environment layer id cannot be empty',
      );
    }
    final aid = areaId.trim();
    if (aid.isEmpty) {
      throw const EditorValidationException('Area id cannot be empty');
    }

    if (pos.x < 0 ||
        pos.y < 0 ||
        pos.x >= map.size.width ||
        pos.y >= map.size.height) {
      throw EditorValidationException(
        'Position out of map bounds: (${pos.x}, ${pos.y})',
      );
    }

    MapLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        envLayer = layer;
        break;
      }
    }
    if (envLayer == null) {
      throw EditorValidationException('Environment layer not found: $envId');
    }
    if (envLayer is! EnvironmentLayer) {
      throw EditorValidationException(
        'Layer is not an environment layer: $envId',
      );
    }

    EnvironmentArea? area;
    for (final a in envLayer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      throw EditorValidationException('Environment area not found: $aid');
    }

    final mask = area.mask;
    if (mask.width != map.size.width || mask.height != map.size.height) {
      throw EditorValidationException(
        'Environment mask size ${mask.width}x${mask.height} does not match '
        'map size ${map.size.width}x${map.size.height}',
      );
    }
    final expected = mask.width * mask.height;
    if (mask.cells.length != expected) {
      throw EditorValidationException(
        'Environment mask cells length ${mask.cells.length} != $expected',
      );
    }

    final index = pos.y * mask.width + pos.x;
    if (index < 0 || index >= mask.cells.length) {
      throw EditorValidationException('Mask index out of bounds: $index');
    }

    if (mask.cells[index] == isActive) {
      return map;
    }

    final nextCells = List<bool>.from(mask.cells, growable: false);
    nextCells[index] = isActive;
    final nextMask = EnvironmentAreaMask(
      width: mask.width,
      height: mask.height,
      cells: nextCells,
    );
    final updatedArea = EnvironmentArea(
      id: area.id,
      name: area.name,
      presetId: area.presetId,
      mask: nextMask,
      seed: area.seed,
      paramsOverride: area.paramsOverride,
      generatedPlacementIds: area.generatedPlacementIds,
    );

    final nextAreas = envLayer.content.areas
        .map((a) => a.id == aid ? updatedArea : a)
        .toList(growable: false);
    final nextContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: nextAreas,
    );
    try {
      final updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: nextContent,
      );
      MapValidator.validate(updated);
      return updated;
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }
  }
}

class PaintEnvironmentAreaMaskBrushStrokeUseCase {
  static const allowedBrushSizes = {1, 3, 5, 7};

  MapData execute(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
    required GridPos center,
    required int brushSize,
    required bool isActive,
  }) {
    final envId = environmentLayerId.trim();
    if (envId.isEmpty) {
      throw const EditorValidationException(
        'Environment layer id cannot be empty',
      );
    }
    final aid = areaId.trim();
    if (aid.isEmpty) {
      throw const EditorValidationException('Area id cannot be empty');
    }
    if (!allowedBrushSizes.contains(brushSize)) {
      throw EditorValidationException(
        'Environment mask brush size must be one of 1, 3, 5 or 7: $brushSize',
      );
    }
    if (center.x < 0 ||
        center.y < 0 ||
        center.x >= map.size.width ||
        center.y >= map.size.height) {
      return map;
    }

    MapLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        envLayer = layer;
        break;
      }
    }
    if (envLayer == null) {
      throw EditorValidationException('Environment layer not found: $envId');
    }
    if (envLayer is! EnvironmentLayer) {
      throw EditorValidationException(
        'Layer is not an environment layer: $envId',
      );
    }

    EnvironmentArea? area;
    for (final a in envLayer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      throw EditorValidationException('Environment area not found: $aid');
    }

    final mask = area.mask;
    if (mask.width != map.size.width || mask.height != map.size.height) {
      throw EditorValidationException(
        'Environment mask size ${mask.width}x${mask.height} does not match '
        'map size ${map.size.width}x${map.size.height}',
      );
    }
    final expected = mask.width * mask.height;
    if (mask.cells.length != expected) {
      throw EditorValidationException(
        'Environment mask cells length ${mask.cells.length} != $expected',
      );
    }

    final radius = (brushSize - 1) ~/ 2;
    final minX = (center.x - radius).clamp(0, mask.width - 1);
    final maxX = (center.x + radius).clamp(0, mask.width - 1);
    final minY = (center.y - radius).clamp(0, mask.height - 1);
    final maxY = (center.y + radius).clamp(0, mask.height - 1);

    List<bool>? nextCells;
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final index = y * mask.width + x;
        if (mask.cells[index] == isActive) {
          continue;
        }
        nextCells ??= List<bool>.from(mask.cells, growable: false);
        nextCells[index] = isActive;
      }
    }

    if (nextCells == null) {
      return map;
    }

    final nextMask = EnvironmentAreaMask(
      width: mask.width,
      height: mask.height,
      cells: nextCells,
    );
    final updatedArea = EnvironmentArea(
      id: area.id,
      name: area.name,
      presetId: area.presetId,
      mask: nextMask,
      seed: area.seed,
      paramsOverride: area.paramsOverride,
      generatedPlacementIds: area.generatedPlacementIds,
    );

    final nextAreas = envLayer.content.areas
        .map((a) => a.id == aid ? updatedArea : a)
        .toList(growable: false);
    final nextContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: nextAreas,
    );
    try {
      final updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: nextContent,
      );
      MapValidator.validate(updated);
      return updated;
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }
  }
}
