import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/smart_tile_field.dart';
import '../operations/smart_tile_layer_operations.dart';
import 'validators.dart';

sealed class MapMutationDelta {
  const MapMutationDelta();

  const factory MapMutationDelta.tileCells({
    required String layerId,
    required Set<int> cellIndices,
    bool placedElementLayerReindexed,
  }) = TileCellMapMutationDelta;

  const factory MapMutationDelta.collisionCells({
    required String layerId,
    required Set<int> cellIndices,
  }) = CollisionCellMapMutationDelta;

  const factory MapMutationDelta.smartTileCells({
    required String layerId,
    required Set<int> cellIndices,
  }) = SmartTileCellMapMutationDelta;

  const factory MapMutationDelta.placedElement({required String instanceId}) =
      PlacedElementMapMutationDelta;
}

final class TileCellMapMutationDelta extends MapMutationDelta {
  const TileCellMapMutationDelta({
    required this.layerId,
    required this.cellIndices,
    this.placedElementLayerReindexed = false,
  });

  final String layerId;
  final Set<int> cellIndices;
  final bool placedElementLayerReindexed;
}

final class CollisionCellMapMutationDelta extends MapMutationDelta {
  const CollisionCellMapMutationDelta({
    required this.layerId,
    required this.cellIndices,
  });

  final String layerId;
  final Set<int> cellIndices;
}

final class SmartTileCellMapMutationDelta extends MapMutationDelta {
  const SmartTileCellMapMutationDelta({
    required this.layerId,
    required this.cellIndices,
  });

  final String layerId;
  final Set<int> cellIndices;
}

final class PlacedElementMapMutationDelta extends MapMutationDelta {
  const PlacedElementMapMutationDelta({required this.instanceId});

  final String instanceId;
}

final class DeltaValidationContext {
  const DeltaValidationContext({
    required this.before,
    required this.after,
    required this.delta,
    this.project,
  });

  final MapData before;
  final MapData after;
  final MapMutationDelta delta;
  final ProjectManifest? project;
}

final class MapDeltaValidationReceipt {
  const MapDeltaValidationReceipt({
    required this.inspectedCellCount,
    required this.inspectedLayerCount,
    required this.inspectedResourceCount,
    required this.inspectedPlacedElementCount,
  });

  final int inspectedCellCount;
  final int inspectedLayerCount;
  final int inspectedResourceCount;
  final int inspectedPlacedElementCount;
}

Set<int> mapDeltaCellIndicesForRectangle({
  required GridSize mapSize,
  required GridPos origin,
  required GridSize size,
}) {
  final indices = <int>{};
  for (var y = 0; y < size.height; y++) {
    for (var x = 0; x < size.width; x++) {
      final mapX = origin.x + x;
      final mapY = origin.y + y;
      if (mapX < 0 ||
          mapY < 0 ||
          mapX >= mapSize.width ||
          mapY >= mapSize.height) {
        continue;
      }
      indices.add(mapY * mapSize.width + mapX);
    }
  }
  return indices;
}

final class MapDeltaValidator {
  const MapDeltaValidator._();

  static MapDeltaValidationReceipt validate(DeltaValidationContext context) {
    _validateMapEnvelope(context);
    return switch (context.delta) {
      TileCellMapMutationDelta delta => _validateTileCells(context, delta),
      CollisionCellMapMutationDelta delta => _validateCollisionCells(
        context,
        delta,
      ),
      SmartTileCellMapMutationDelta delta => _validateSmartTileCells(
        context,
        delta,
      ),
      PlacedElementMapMutationDelta delta => _validatePlacedElementMutation(
        context,
        delta,
      ),
    };
  }

  static void _validateMapEnvelope(DeltaValidationContext context) {
    final before = context.before;
    final after = context.after;
    if (before.id != after.id ||
        before.name != after.name ||
        before.size != after.size ||
        before.version != after.version ||
        before.visualStack != after.visualStack ||
        before.tilesetId != after.tilesetId ||
        !_sameReferences(before.entities, after.entities) ||
        !_sameReferences(before.connections, after.connections) ||
        !_sameReferences(before.warps, after.warps) ||
        !_sameReferences(before.triggers, after.triggers) ||
        !_sameReferences(before.gameplayZones, after.gameplayZones) ||
        before.mapMetadata != after.mapMetadata ||
        !_sameMapEntries(before.properties, after.properties) ||
        !_sameReferences(before.events, after.events)) {
      throw const ValidationException(
        'Incremental map validation received an undeclared map mutation',
      );
    }
  }

  static MapDeltaValidationReceipt _validateTileCells(
    DeltaValidationContext context,
    TileCellMapMutationDelta delta,
  ) {
    final layers = _targetLayers<TileLayer>(context, delta.layerId);
    final before = layers.before;
    final after = layers.after;
    _validateLayerIdentity(before, after);
    if (before.purpose != after.purpose ||
        after.palette.length < before.palette.length) {
      throw ValidationException(
        'Tile layer ${after.id} contains an undeclared mutation',
      );
    }
    for (var index = 0; index < before.palette.length; index++) {
      if (before.palette[index] != after.palette[index]) {
        throw ValidationException(
          'Tile layer ${after.id} changed an existing palette entry',
        );
      }
    }
    final expectedCellCount =
        context.after.size.width * context.after.size.height;
    if (after.cells.length != expectedCellCount) {
      throw ValidationException(
        'Tile layer ${after.id} has invalid cell count: expected '
        '$expectedCellCount, got ${after.cells.length}',
      );
    }
    final paletteEntries = <TileLayerPaletteEntry>{};
    for (var index = 0; index < after.palette.length; index++) {
      final entry = after.palette[index];
      if (entry.tilesetId.trim().isEmpty ||
          entry.tilesetId != entry.tilesetId.trim() ||
          entry.localTileId < 0 ||
          entry.transform.quarterTurns < 0 ||
          entry.transform.quarterTurns > 3 ||
          !paletteEntries.add(entry)) {
        throw ValidationException(
          'Tile layer ${after.id} has invalid palette entry at index $index',
        );
      }
    }
    _validateIndices(delta.cellIndices, expectedCellCount, after.id);
    for (final index in delta.cellIndices) {
      final value = after.cells[index];
      if (value < 0 || value > after.palette.length) {
        throw ValidationException(
          'Tile layer ${after.id} has invalid palette cell at index '
          '$index: $value',
        );
      }
    }
    final placedCount = delta.placedElementLayerReindexed
        ? _validatePlacedElementLayer(context, after.id)
        : _requirePlacedElementsUntouched(context);
    return MapDeltaValidationReceipt(
      inspectedCellCount: delta.cellIndices.length,
      inspectedLayerCount: context.after.layers.length,
      inspectedResourceCount: 1 + after.palette.length,
      inspectedPlacedElementCount: placedCount,
    );
  }

  static MapDeltaValidationReceipt _validateCollisionCells(
    DeltaValidationContext context,
    CollisionCellMapMutationDelta delta,
  ) {
    final layers = _targetLayers<CollisionLayer>(context, delta.layerId);
    final after = layers.after;
    _validateLayerIdentity(layers.before, after);
    final expectedCellCount =
        context.after.size.width * context.after.size.height;
    if (after.collisions.length != expectedCellCount) {
      throw ValidationException(
        'Collision layer ${after.id} has invalid collision count: expected '
        '$expectedCellCount, got ${after.collisions.length}',
      );
    }
    _validateIndices(delta.cellIndices, expectedCellCount, after.id);
    _requirePlacedElementsUntouched(context);
    return MapDeltaValidationReceipt(
      inspectedCellCount: delta.cellIndices.length,
      inspectedLayerCount: context.after.layers.length,
      inspectedResourceCount: 1,
      inspectedPlacedElementCount: 0,
    );
  }

  static MapDeltaValidationReceipt _validateSmartTileCells(
    DeltaValidationContext context,
    SmartTileCellMapMutationDelta delta,
  ) {
    final layers = _targetLayers<SmartTileLayer>(context, delta.layerId);
    final before = layers.before;
    final after = layers.after;
    _validateLayerIdentity(before, after);
    if (before.presetId != after.presetId ||
        before.usage != after.usage ||
        before.layerSeed != after.layerSeed ||
        before.animationActivation != after.animationActivation ||
        !_sameReferences(before.patternStrokes, after.patternStrokes) ||
        !_sameMapEntries(before.candidateWeights, after.candidateWeights) ||
        !_sameMapEntries(before.properties, after.properties) ||
        before.field.runtimeType != after.field.runtimeType) {
      throw ValidationException(
        'Smart Tile layer ${after.id} contains an undeclared mutation',
      );
    }
    final palette = after.materialPalette;
    if (palette.length < before.materialPalette.length) {
      throw ValidationException(
        'Smart Tile layer ${after.id} removed a material palette entry',
      );
    }
    for (var index = 0; index < before.materialPalette.length; index++) {
      if (before.materialPalette[index] != palette[index]) {
        throw ValidationException(
          'Smart Tile layer ${after.id} changed an existing material palette '
          'entry',
        );
      }
    }
    if (palette.isEmpty || palette.first.isNotEmpty) {
      throw ValidationException(
        'Smart Tile layer ${after.id} materialPalette must start with the '
        'empty material',
      );
    }
    final materialIds = <String>{};
    for (var index = 1; index < palette.length; index++) {
      final value = palette[index];
      if (value.trim().isEmpty ||
          value != value.trim() ||
          !materialIds.add(value)) {
        throw ValidationException(
          'Smart Tile layer ${after.id} has invalid material at palette '
          'index $index',
        );
      }
    }
    _validateSmartTileProject(context.project, after, materialIds);
    final width = context.after.size.width;
    final height = context.after.size.height;
    final expectedCellCount = width * height;
    _validateIndices(delta.cellIndices, expectedCellCount, after.id);
    final semanticCells = smartTileSemanticCells(after);
    if (semanticCells.length != expectedCellCount) {
      throw ValidationException(
        'Smart Tile layer ${after.id} has invalid semanticCells count',
      );
    }
    final horizontalEdges = smartTileHorizontalEdges(after);
    final verticalEdges = smartTileVerticalEdges(after);
    final corners = smartTileCorners(after);
    final hasEdges =
        after.field is SmartTileEdgeField || after.field is SmartTileMixedField;
    final hasCorners =
        after.field is SmartTileCornerField ||
        after.field is SmartTileMixedField;
    final expectedHorizontalCount = hasEdges ? width * (height + 1) : 0;
    final expectedVerticalCount = hasEdges ? (width + 1) * height : 0;
    final expectedCornerCount = hasCorners ? (width + 1) * (height + 1) : 0;
    if (horizontalEdges.length != expectedHorizontalCount) {
      throw ValidationException(
        'Smart Tile layer ${after.id} has invalid horizontalEdges count',
      );
    }
    if (verticalEdges.length != expectedVerticalCount) {
      throw ValidationException(
        'Smart Tile layer ${after.id} has invalid verticalEdges count',
      );
    }
    if (corners.length != expectedCornerCount) {
      throw ValidationException(
        'Smart Tile layer ${after.id} has invalid corners count',
      );
    }
    final horizontalIndices = <int>{};
    final verticalIndices = <int>{};
    final cornerIndices = <int>{};
    final verticalStride = width + 1;
    for (final index in delta.cellIndices) {
      _validateMaterialIndex(
        after,
        'semanticCells',
        index,
        semanticCells[index],
      );
      final x = index % width;
      final y = index ~/ width;
      if (hasEdges) {
        horizontalIndices
          ..add(y * width + x)
          ..add((y + 1) * width + x);
        verticalIndices
          ..add(y * verticalStride + x)
          ..add(y * verticalStride + x + 1);
      }
      if (corners.isNotEmpty) {
        cornerIndices
          ..add(y * verticalStride + x)
          ..add(y * verticalStride + x + 1)
          ..add((y + 1) * verticalStride + x)
          ..add((y + 1) * verticalStride + x + 1);
      }
    }
    for (final index in horizontalIndices) {
      _validateMaterialIndex(
        after,
        'horizontalEdges',
        index,
        horizontalEdges[index],
      );
    }
    for (final index in verticalIndices) {
      _validateMaterialIndex(
        after,
        'verticalEdges',
        index,
        verticalEdges[index],
      );
    }
    for (final index in cornerIndices) {
      _validateMaterialIndex(after, 'corners', index, corners[index]);
    }
    _requirePlacedElementsUntouched(context);
    return MapDeltaValidationReceipt(
      inspectedCellCount:
          delta.cellIndices.length +
          horizontalIndices.length +
          verticalIndices.length +
          cornerIndices.length,
      inspectedLayerCount: context.after.layers.length,
      inspectedResourceCount: 1 + palette.length,
      inspectedPlacedElementCount: 0,
    );
  }

  static MapDeltaValidationReceipt _validatePlacedElementMutation(
    DeltaValidationContext context,
    PlacedElementMapMutationDelta delta,
  ) {
    _requireLayersUntouched(context);
    final before = context.before.placedElements;
    final after = context.after.placedElements;
    final oldIndex = before.indexWhere((entry) => entry.id == delta.instanceId);
    final newIndex = after.indexWhere((entry) => entry.id == delta.instanceId);
    if (newIndex < 0 ||
        (oldIndex < 0 && after.length != before.length + 1) ||
        (oldIndex >= 0 && after.length != before.length)) {
      throw ValidationException(
        'Placed element delta ${delta.instanceId} has an invalid collection '
        'shape',
      );
    }
    for (var index = 0; index < before.length; index++) {
      if (index == oldIndex) continue;
      final afterIndex = oldIndex < 0 ? index : index;
      if (!identical(before[index], after[afterIndex])) {
        throw ValidationException(
          'Placed element delta ${delta.instanceId} changed another instance',
        );
      }
    }
    final seenIds = <String>{};
    for (final instance in after) {
      if (!seenIds.add(instance.id.trim())) {
        throw ValidationException(
          'Duplicate placed element instance ID: ${instance.id.trim()}',
        );
      }
    }
    MapValidator.validatePlacedElement(
      context.after,
      after[newIndex],
      projectDialogueContext: context.project,
    );
    return MapDeltaValidationReceipt(
      inspectedCellCount: 0,
      inspectedLayerCount: context.after.layers.length,
      inspectedResourceCount: 1,
      inspectedPlacedElementCount: after.length,
    );
  }

  static ({T before, T after}) _targetLayers<T extends MapLayer>(
    DeltaValidationContext context,
    String layerId,
  ) {
    if (context.before.layers.length != context.after.layers.length) {
      throw const ValidationException(
        'Incremental map validation cannot add or remove layers',
      );
    }
    var targetIndex = -1;
    for (var index = 0; index < context.before.layers.length; index++) {
      final before = context.before.layers[index];
      final after = context.after.layers[index];
      if (before.id == layerId) {
        targetIndex = index;
        continue;
      }
      if (!identical(before, after)) {
        throw ValidationException(
          'Incremental map validation found an undeclared layer mutation: '
          '${before.id}',
        );
      }
    }
    if (targetIndex < 0 ||
        context.before.layers[targetIndex] is! T ||
        context.after.layers[targetIndex] is! T) {
      throw ValidationException(
        'Incremental map validation has an invalid target layer: $layerId',
      );
    }
    return (
      before: context.before.layers[targetIndex] as T,
      after: context.after.layers[targetIndex] as T,
    );
  }

  static void _requireLayersUntouched(DeltaValidationContext context) {
    if (context.before.layers.length != context.after.layers.length) {
      throw const ValidationException('Placed element delta changed layers');
    }
    for (var index = 0; index < context.before.layers.length; index++) {
      if (!identical(
        context.before.layers[index],
        context.after.layers[index],
      )) {
        throw const ValidationException('Placed element delta changed layers');
      }
    }
  }

  static void _validateLayerIdentity(MapLayer before, MapLayer after) {
    if (before.id != after.id ||
        before.name != after.name ||
        before.isVisible != after.isVisible ||
        before.opacity != after.opacity) {
      throw ValidationException(
        'Layer ${before.id} contains an undeclared metadata mutation',
      );
    }
  }

  static void _validateIndices(Set<int> indices, int length, String layerId) {
    if (indices.isEmpty) {
      throw ValidationException('Layer $layerId delta has no touched cells');
    }
    for (final index in indices) {
      if (index < 0 || index >= length) {
        throw ValidationException(
          'Layer $layerId delta contains an invalid cell index: $index',
        );
      }
    }
  }

  static void _validateMaterialIndex(
    SmartTileLayer layer,
    String field,
    int index,
    int value,
  ) {
    if (value < 0 || value >= layer.materialPalette.length) {
      throw ValidationException(
        'Smart Tile layer ${layer.id} $field[$index] references invalid '
        'material palette index $value',
      );
    }
  }

  static void _validateSmartTileProject(
    ProjectManifest? project,
    SmartTileLayer layer,
    Set<String> materialIds,
  ) {
    if (project == null) return;
    final preset = project.smartTileCatalog.presets
        .where((candidate) => candidate.id == layer.presetId)
        .firstOrNull;
    if (preset == null || preset.usage != layer.usage) {
      throw ValidationException(
        'Smart Tile layer ${layer.id} references an invalid preset',
      );
    }
    if (!isSmartTileFieldCompatibleWithTopology(preset.topology, layer.field)) {
      throw ValidationException(
        'Smart Tile layer ${layer.id} field is incompatible with its preset',
      );
    }
    final knownMaterialIds = project.smartTileCatalog.materials
        .map((material) => material.id)
        .toSet();
    for (final materialId in materialIds) {
      if (!knownMaterialIds.contains(materialId) ||
          !preset.allowedMaterialIds.contains(materialId)) {
        throw ValidationException(
          'Smart Tile layer ${layer.id} references invalid material: '
          '$materialId',
        );
      }
    }
  }

  static int _requirePlacedElementsUntouched(DeltaValidationContext context) {
    if (!_sameReferences(
      context.before.placedElements,
      context.after.placedElements,
    )) {
      throw const ValidationException(
        'Incremental map validation found an undeclared placed element '
        'mutation',
      );
    }
    return 0;
  }

  static int _validatePlacedElementLayer(
    DeltaValidationContext context,
    String layerId,
  ) {
    final beforeOther = context.before.placedElements
        .where((instance) => instance.layerId != layerId)
        .toList(growable: false);
    final afterOther = context.after.placedElements
        .where((instance) => instance.layerId != layerId)
        .toList(growable: false);
    if (beforeOther.length != afterOther.length) {
      throw const ValidationException(
        'Tile delta changed placed elements on another layer',
      );
    }
    for (var index = 0; index < beforeOther.length; index++) {
      if (!identical(beforeOther[index], afterOther[index])) {
        throw const ValidationException(
          'Tile delta changed placed elements on another layer',
        );
      }
    }
    final seenIds = <String>{};
    var count = 0;
    for (final instance in context.after.placedElements) {
      if (!seenIds.add(instance.id.trim())) {
        throw ValidationException(
          'Duplicate placed element instance ID: ${instance.id.trim()}',
        );
      }
      if (instance.layerId == layerId) {
        MapValidator.validatePlacedElement(
          context.after,
          instance,
          projectDialogueContext: context.project,
        );
        count++;
      }
    }
    return count;
  }

  static bool _sameReferences<T>(List<T> before, List<T> after) {
    if (before.length != after.length) return false;
    for (var index = 0; index < before.length; index++) {
      if (!identical(before[index], after[index])) return false;
    }
    return true;
  }

  static bool _sameMapEntries<K, V>(Map<K, V> before, Map<K, V> after) {
    if (before.length != after.length) return false;
    for (final entry in before.entries) {
      if (!after.containsKey(entry.key) || after[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
