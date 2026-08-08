import 'package:map_core/map_core.dart';

import 'placed_element_placement_origin.dart';

final class PlacedElementMutationIntent {
  const PlacedElementMutationIntent({
    required this.actionId,
    required this.parameters,
    required this.instanceId,
  });

  final String actionId;
  final Map<String, Object?> parameters;
  final String instanceId;
}

final class PlacedElementEditingService {
  const PlacedElementEditingService();

  PlacedElementMutationIntent buildPlaceIntent({
    required MapData map,
    required String layerId,
    required String elementId,
    required GridPos pos,
  }) {
    final normalizedLayerId = layerId.trim();
    final normalizedElementId = elementId.trim();
    if (normalizedLayerId.isEmpty) {
      throw const FormatException('Placed element layer id cannot be empty.');
    }
    if (normalizedElementId.isEmpty) {
      throw const FormatException('Placed element source id cannot be empty.');
    }
    final instanceId = _reserveInstanceId(
      buildMapPlacedElementId(
        layerId: normalizedLayerId,
        elementId: normalizedElementId,
        pos: pos,
      ),
      map.placedElements.map((entry) => entry.id).toSet(),
    );
    final instance = MapPlacedElement(
      id: instanceId,
      layerId: normalizedLayerId,
      elementId: normalizedElementId,
      pos: pos,
      applyCollision: true,
      properties: const <String, String>{
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
    );
    return PlacedElementMutationIntent(
      actionId: 'placed_element.place',
      parameters: Map<String, Object?>.unmodifiable({
        'mapId': map.id,
        'instance': instance.toJson(),
      }),
      instanceId: instanceId,
    );
  }

  String _reserveInstanceId(String baseId, Set<String> reservedIds) {
    if (!reservedIds.contains(baseId)) {
      return baseId;
    }
    var suffix = 2;
    while (reservedIds.contains('${baseId}_$suffix')) {
      suffix += 1;
    }
    return '${baseId}_$suffix';
  }
}
