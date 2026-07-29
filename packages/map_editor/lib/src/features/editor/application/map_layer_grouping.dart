import 'package:map_core/map_core.dart';

enum MapLayerGroupMoveDirection {
  up,
  down,
}

/// One visible top-first layer row and every serialized layer it owns.
///
/// A valid Environment attachment belongs to its target Tile group. Other
/// layer kinds, including orphan or invalid Environment layers, remain
/// standalone groups.
final class MapLayerGroup {
  MapLayerGroup._({
    required this.primaryLayer,
    required List<MapLayer> membersTopFirst,
    required List<EnvironmentLayer> attachedEnvironmentLayersTopFirst,
  })  : membersTopFirst = List<MapLayer>.unmodifiable(membersTopFirst),
        attachedEnvironmentLayersTopFirst = List<EnvironmentLayer>.unmodifiable(
          attachedEnvironmentLayersTopFirst,
        );

  final MapLayer primaryLayer;
  final List<MapLayer> membersTopFirst;
  final List<EnvironmentLayer> attachedEnvironmentLayersTopFirst;

  String get id => primaryLayer.id;

  bool get isTileEnvironmentGroup =>
      primaryLayer is TileLayer && attachedEnvironmentLayersTopFirst.isNotEmpty;

  bool containsLayerId(String layerId) {
    return membersTopFirst.any((layer) => layer.id == layerId);
  }
}

/// Builds and atomically reorders the visible top-first layer groups.
final class MapLayerGroupService {
  const MapLayerGroupService();

  List<MapLayerGroup> groupsTopFirst(MapData map) {
    final layersById = <String, MapLayer>{
      for (final layer in map.layers) layer.id: layer,
    };
    final attachmentsByTarget =
        Map<TileLayer, List<EnvironmentLayer>>.identity();
    final attachedEnvironments = Set<EnvironmentLayer>.identity();

    for (final layer in map.layers.whereType<EnvironmentLayer>()) {
      final targetId = layer.content.targetTileLayerId?.trim();
      final target =
          targetId == null || targetId.isEmpty ? null : layersById[targetId];
      if (target is! TileLayer) {
        continue;
      }
      attachmentsByTarget
          .putIfAbsent(target, () => <EnvironmentLayer>[])
          .add(layer);
      attachedEnvironments.add(layer);
    }

    final groups = <MapLayerGroup>[];
    for (final layer in map.layers) {
      if (layer is EnvironmentLayer && attachedEnvironments.contains(layer)) {
        continue;
      }
      final attachments = layer is TileLayer
          ? attachmentsByTarget[layer] ?? const <EnvironmentLayer>[]
          : const <EnvironmentLayer>[];
      if (attachments.isEmpty) {
        groups.add(
          MapLayerGroup._(
            primaryLayer: layer,
            membersTopFirst: <MapLayer>[layer],
            attachedEnvironmentLayersTopFirst: const <EnvironmentLayer>[],
          ),
        );
        continue;
      }

      final attachmentSet = Set<EnvironmentLayer>.identity()
        ..addAll(attachments);
      groups.add(
        MapLayerGroup._(
          primaryLayer: layer,
          membersTopFirst: <MapLayer>[
            for (final candidate in map.layers)
              if (identical(candidate, layer) ||
                  candidate is EnvironmentLayer &&
                      attachmentSet.contains(candidate))
                candidate,
          ],
          attachedEnvironmentLayersTopFirst: attachments,
        ),
      );
    }
    return List<MapLayerGroup>.unmodifiable(groups);
  }

  MapData moveAdjacent({
    required MapData map,
    required String layerId,
    required MapLayerGroupMoveDirection direction,
  }) {
    final groups = groupsTopFirst(map);
    final sourceIndex = _groupIndexForLayerId(groups, layerId);
    final destinationIndex = switch (direction) {
      MapLayerGroupMoveDirection.up => sourceIndex - 1,
      MapLayerGroupMoveDirection.down => sourceIndex + 1,
    };
    if (destinationIndex < 0 || destinationIndex >= groups.length) {
      return map;
    }

    final reordered = List<MapLayerGroup>.from(groups, growable: false);
    final destination = reordered[destinationIndex];
    reordered[destinationIndex] = reordered[sourceIndex];
    reordered[sourceIndex] = destination;
    return _mapWithGroups(map, reordered);
  }

  /// Moves the group containing [layerId] before a top-first group slot.
  ///
  /// [beforeGroupIndex] follows `ReorderableListView` insertion semantics:
  /// zero is the top and `groups.length` is the slot after the last group.
  MapData moveBeforeGroupIndex({
    required MapData map,
    required String layerId,
    required int beforeGroupIndex,
  }) {
    final groups = groupsTopFirst(map);
    if (beforeGroupIndex < 0 || beforeGroupIndex > groups.length) {
      throw RangeError.range(
        beforeGroupIndex,
        0,
        groups.length,
        'beforeGroupIndex',
      );
    }
    final sourceIndex = _groupIndexForLayerId(groups, layerId);
    var insertionIndex = beforeGroupIndex;
    if (insertionIndex > sourceIndex) {
      insertionIndex -= 1;
    }
    if (insertionIndex == sourceIndex) {
      return map;
    }

    final reordered = List<MapLayerGroup>.from(groups, growable: true);
    final source = reordered.removeAt(sourceIndex);
    reordered.insert(insertionIndex, source);
    return _mapWithGroups(map, reordered);
  }

  /// Moves one group before the group containing [beforeLayerId].
  MapData moveBeforeGroup({
    required MapData map,
    required String layerId,
    required String beforeLayerId,
  }) {
    final groups = groupsTopFirst(map);
    final beforeGroupIndex = _groupIndexForLayerId(groups, beforeLayerId);
    return moveBeforeGroupIndex(
      map: map,
      layerId: layerId,
      beforeGroupIndex: beforeGroupIndex,
    );
  }
}

int _groupIndexForLayerId(
  List<MapLayerGroup> groups,
  String layerId,
) {
  final index = groups.indexWhere((group) => group.containsLayerId(layerId));
  if (index < 0) {
    throw ArgumentError.value(
      layerId,
      'layerId',
      'Layer does not belong to a map layer group',
    );
  }
  return index;
}

MapData _mapWithGroups(
  MapData map,
  List<MapLayerGroup> groups,
) {
  final layers = <MapLayer>[
    for (final group in groups) ...group.membersTopFirst,
  ];
  if (!_hasSameIdentityMembers(map.layers, layers)) {
    throw StateError(
      'Layer group reorder must preserve every serialized layer instance '
      'exactly once.',
    );
  }
  if (_hasSameIdentityOrder(map.layers, layers)) {
    return map;
  }
  return map.copyWith(layers: layers);
}

bool _hasSameIdentityMembers(
  List<MapLayer> previous,
  List<MapLayer> next,
) {
  if (previous.length != next.length) {
    return false;
  }
  final remaining = List<MapLayer>.of(next);
  for (final previousLayer in previous) {
    final matchIndex = remaining.indexWhere(
      (nextLayer) => identical(nextLayer, previousLayer),
    );
    if (matchIndex < 0) {
      return false;
    }
    remaining.removeAt(matchIndex);
  }
  return remaining.isEmpty;
}

bool _hasSameIdentityOrder(
  List<MapLayer> previous,
  List<MapLayer> next,
) {
  if (previous.length != next.length) {
    return false;
  }
  for (var index = 0; index < previous.length; index++) {
    if (!identical(previous[index], next[index])) {
      return false;
    }
  }
  return true;
}
