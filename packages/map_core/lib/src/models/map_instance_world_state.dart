import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
import 'package:meta/meta.dart' show immutable;

import 'geometry.dart';

const currentMapInstanceWorldStateSchemaVersion = 3;
const _collectionEquality = DeepCollectionEquality();

Object? readMapInstanceWorldStateJson(Map<dynamic, dynamic> json, String key) {
  if (!json.containsKey(key) || json[key] == null) {
    throw FormatException('The state requires its $key zone.');
  }
  return json[key];
}

@immutable
final class MapInstanceRef {
  MapInstanceRef({required String mapId, required String instanceId})
    : mapId = _identity(mapId, 'mapId'),
      instanceId = _identity(instanceId, 'instanceId');

  final String mapId;
  final String instanceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapInstanceRef &&
          other.mapId == mapId &&
          other.instanceId == instanceId;

  @override
  int get hashCode => Object.hash(mapId, instanceId);
}

@immutable
final class MapInstanceRuntimeState {
  MapInstanceRuntimeState({
    required String instanceId,
    Map<String, Map<String, bool>> eventBooleans = const {},
    Set<String> clearedFieldObstacleIds = const {},
    Map<String, GridPos> fieldObstaclePositions = const {},
    Map<String, GridPos> npcPositions = const {},
    this.strengthActive = false,
  }) : instanceId = _identity(instanceId, 'instanceId'),
       fieldObstaclePositions = Map.unmodifiable({
         for (final entry in fieldObstaclePositions.entries)
           _identity(entry.key, 'fieldObstacleId'): _position(entry.value),
       }),
       npcPositions = Map.unmodifiable({
         for (final entry in npcPositions.entries)
           _identity(entry.key, 'npcId'): _position(entry.value),
       }),
       clearedFieldObstacleIds = Set.unmodifiable(
         clearedFieldObstacleIds.map((id) => _identity(id, 'fieldObstacleId')),
       ),
       eventBooleans = Map.unmodifiable({
         for (final event in eventBooleans.entries)
           _identity(event.key, 'eventId'): Map<String, bool>.unmodifiable({
             for (final entry in event.value.entries)
               _identity(entry.key, 'key'): entry.value,
           }),
       });

  final String instanceId;
  final Map<String, Map<String, bool>> eventBooleans;
  final Set<String> clearedFieldObstacleIds;
  final Map<String, GridPos> fieldObstaclePositions;
  final Map<String, GridPos> npcPositions;
  final bool strengthActive;

  factory MapInstanceRuntimeState.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'instanceId',
      'eventBooleans',
      'clearedFieldObstacleIds',
      'fieldObstaclePositions',
      'npcPositions',
      'strengthActive',
    });
    final positions = _readPositions(
      json['fieldObstaclePositions'],
      'fieldObstaclePositions',
    );
    final npcPositions = _readPositions(json['npcPositions'], 'npcPositions');
    if (json['strengthActive'] is! bool) {
      throw const FormatException('strengthActive must be a boolean.');
    }
    final cleared = json['clearedFieldObstacleIds'];
    if (cleared is! List ||
        cleared.any((id) => id is! String) ||
        cleared.toSet().length != cleared.length) {
      throw const FormatException(
        'Cleared field obstacle identities must be a unique string list.',
      );
    }
    final events = _object(json['eventBooleans'], 'eventBooleans');
    final booleans = <String, Map<String, bool>>{};
    for (final event in events.entries) {
      final values = _object(event.value, 'eventBooleans.${event.key}');
      final typed = <String, bool>{};
      for (final entry in values.entries) {
        final value = entry.value;
        if (value is! bool) {
          throw FormatException(
            'eventBooleans.${event.key}.${entry.key} must be a boolean.',
          );
        }
        typed[entry.key] = value;
      }
      booleans[event.key] = typed;
    }
    try {
      return MapInstanceRuntimeState(
        instanceId: _string(json['instanceId'], 'instanceId'),
        eventBooleans: booleans,
        fieldObstaclePositions: positions,
        npcPositions: npcPositions,
        strengthActive: json['strengthActive'] as bool,
        clearedFieldObstacleIds: cleared.cast<String>().toSet(),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid instance.');
    }
  }

  Map<String, dynamic> toJson() {
    final eventIds = eventBooleans.keys.toList()..sort();
    return {
      'instanceId': instanceId,
      'clearedFieldObstacleIds': clearedFieldObstacleIds.toList()..sort(),
      'fieldObstaclePositions': {
        for (final id in fieldObstaclePositions.keys.toList()..sort())
          id: fieldObstaclePositions[id]!.toJson(),
      },
      'npcPositions': {
        for (final id in npcPositions.keys.toList()..sort())
          id: npcPositions[id]!.toJson(),
      },
      'strengthActive': strengthActive,
      'eventBooleans': {
        for (final eventId in eventIds)
          eventId: {
            for (final key in eventBooleans[eventId]!.keys.toList()..sort())
              key: eventBooleans[eventId]![key],
          },
      },
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapInstanceRuntimeState &&
          other.instanceId == instanceId &&
          other.strengthActive == strengthActive &&
          _collectionEquality.equals(other.npcPositions, npcPositions) &&
          _collectionEquality.equals(
            other.fieldObstaclePositions,
            fieldObstaclePositions,
          ) &&
          _collectionEquality.equals(other.eventBooleans, eventBooleans) &&
          _collectionEquality.equals(
            other.clearedFieldObstacleIds,
            clearedFieldObstacleIds,
          );

  @override
  int get hashCode => Object.hash(
    instanceId,
    strengthActive,
    _collectionEquality.hash(fieldObstaclePositions),
    _collectionEquality.hash(npcPositions),
    _collectionEquality.hash(eventBooleans),
    _collectionEquality.hash(clearedFieldObstacleIds),
  );
}

@immutable
final class MapInstanceWorldState {
  const MapInstanceWorldState.empty() : instancesByMapId = const {};

  MapInstanceWorldState({
    required Map<String, MapInstanceRuntimeState> instancesByMapId,
  }) : instancesByMapId = Map.unmodifiable({
         for (final entry in instancesByMapId.entries)
           _identity(entry.key, 'mapId'): entry.value,
       }) {
    final identities = <String>{};
    for (final instance in this.instancesByMapId.values) {
      if (!identities.add(instance.instanceId)) {
        throw ArgumentError('Retained map instance identities must be unique.');
      }
    }
  }

  final Map<String, MapInstanceRuntimeState> instancesByMapId;

  factory MapInstanceWorldState.fromJson(Map<String, dynamic> json) {
    _keys(json, {'schemaVersion', 'instancesByMapId'});
    final version = json['schemaVersion'];
    if (version is! int ||
        version != currentMapInstanceWorldStateSchemaVersion) {
      throw FormatException('Unsupported map instance state schema: $version.');
    }
    final maps = _object(json['instancesByMapId'], 'instancesByMapId');
    final instances = <String, MapInstanceRuntimeState>{};
    for (final entry in maps.entries) {
      instances[entry.key] = MapInstanceRuntimeState.fromJson(
        _object(entry.value, 'instancesByMapId.${entry.key}'),
      );
    }
    try {
      return MapInstanceWorldState(instancesByMapId: instances);
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid instances.');
    }
  }

  MapInstanceRef? instanceRef(String mapId) {
    _identity(mapId, 'mapId');
    final instance = instancesByMapId[mapId];
    return instance == null
        ? null
        : MapInstanceRef(mapId: mapId, instanceId: instance.instanceId);
  }

  bool eventBoolean(MapInstanceRef scope, String eventId, String key) {
    final instance = _currentInstance(scope);
    _identity(eventId, 'eventId');
    _identity(key, 'key');
    return instance.eventBooleans[eventId]?[key] ?? false;
  }

  MapInstanceWorldState setEventBoolean(
    MapInstanceRef scope,
    String eventId,
    String key,
    bool value,
  ) {
    final instance = _currentInstance(scope);
    _identity(eventId, 'eventId');
    _identity(key, 'key');
    final booleans = instance.eventBooleans[eventId];
    if (booleans?.containsKey(key) == true && booleans![key] == value) {
      return this;
    }
    return MapInstanceWorldState(
      instancesByMapId: {
        ...instancesByMapId,
        scope.mapId: MapInstanceRuntimeState(
          instanceId: instance.instanceId,
          npcPositions: instance.npcPositions,
          fieldObstaclePositions: instance.fieldObstaclePositions,
          strengthActive: instance.strengthActive,
          clearedFieldObstacleIds: instance.clearedFieldObstacleIds,
          eventBooleans: {
            ...instance.eventBooleans,
            eventId: {...?booleans, key: value},
          },
        ),
      },
    );
  }

  bool isFieldObstacleCleared(MapInstanceRef scope, String entityId) =>
      _currentInstance(scope).clearedFieldObstacleIds.contains(
        _identity(entityId, 'fieldObstacleId'),
      );

  MapInstanceWorldState clearFieldObstacle(
    MapInstanceRef scope,
    String entityId,
  ) {
    final instance = _currentInstance(scope);
    _identity(entityId, 'fieldObstacleId');
    if (instance.clearedFieldObstacleIds.contains(entityId)) return this;
    return MapInstanceWorldState(
      instancesByMapId: {
        ...instancesByMapId,
        scope.mapId: MapInstanceRuntimeState(
          instanceId: instance.instanceId,
          npcPositions: instance.npcPositions,
          fieldObstaclePositions: instance.fieldObstaclePositions,
          strengthActive: instance.strengthActive,
          eventBooleans: instance.eventBooleans,
          clearedFieldObstacleIds: {
            ...instance.clearedFieldObstacleIds,
            entityId,
          },
        ),
      },
    );
  }

  GridPos? fieldObstaclePosition(MapInstanceRef scope, String entityId) =>
      _currentInstance(scope).fieldObstaclePositions[_identity(
        entityId,
        'fieldObstacleId',
      )];

  bool isStrengthActive(MapInstanceRef scope) =>
      _currentInstance(scope).strengthActive;

  MapInstanceWorldState activateStrength(MapInstanceRef scope) {
    final instance = _currentInstance(scope);
    if (instance.strengthActive) return this;
    return MapInstanceWorldState(
      instancesByMapId: {
        ...instancesByMapId,
        scope.mapId: MapInstanceRuntimeState(
          instanceId: instance.instanceId,
          npcPositions: instance.npcPositions,
          eventBooleans: instance.eventBooleans,
          clearedFieldObstacleIds: instance.clearedFieldObstacleIds,
          fieldObstaclePositions: instance.fieldObstaclePositions,
          strengthActive: true,
        ),
      },
    );
  }

  MapInstanceWorldState moveFieldObstacle(
    MapInstanceRef scope,
    String entityId,
    GridPos position,
  ) {
    final instance = _currentInstance(scope);
    _identity(entityId, 'fieldObstacleId');
    _position(position);
    if (instance.fieldObstaclePositions[entityId] == position) return this;
    return MapInstanceWorldState(
      instancesByMapId: {
        ...instancesByMapId,
        scope.mapId: MapInstanceRuntimeState(
          instanceId: instance.instanceId,
          npcPositions: instance.npcPositions,
          eventBooleans: instance.eventBooleans,
          clearedFieldObstacleIds: instance.clearedFieldObstacleIds,
          fieldObstaclePositions: {
            ...instance.fieldObstaclePositions,
            entityId: position,
          },
          strengthActive: instance.strengthActive,
        ),
      },
    );
  }

  MapInstanceWorldState setNpcPositions(
    MapInstanceRef scope,
    Map<String, GridPos> positions,
  ) {
    final instance = _currentInstance(scope);
    if (_collectionEquality.equals(instance.npcPositions, positions)) {
      return this;
    }
    return MapInstanceWorldState(
      instancesByMapId: {
        ...instancesByMapId,
        scope.mapId: MapInstanceRuntimeState(
          instanceId: instance.instanceId,
          npcPositions: positions,
          fieldObstaclePositions: instance.fieldObstaclePositions,
          clearedFieldObstacleIds: instance.clearedFieldObstacleIds,
          strengthActive: instance.strengthActive,
          eventBooleans: instance.eventBooleans,
        ),
      },
    );
  }

  MapInstanceRuntimeState _currentInstance(MapInstanceRef scope) {
    final instance = instancesByMapId[scope.mapId];
    if (instance == null || instance.instanceId != scope.instanceId) {
      throw StateError(
        'Map instance ${scope.mapId}/${scope.instanceId} is stale.',
      );
    }
    return instance;
  }

  Map<String, dynamic> toJson() {
    final mapIds = instancesByMapId.keys.toList()..sort();
    return {
      'schemaVersion': currentMapInstanceWorldStateSchemaVersion,
      'instancesByMapId': {
        for (final mapId in mapIds) mapId: instancesByMapId[mapId]!.toJson(),
      },
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapInstanceWorldState &&
          _collectionEquality.equals(other.instancesByMapId, instancesByMapId);

  @override
  int get hashCode => _collectionEquality.hash(instancesByMapId);
}

String _identity(String value, String field) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, field, 'must be a canonical identity');
  }
  return value;
}

String _string(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

Map<String, dynamic> _object(Object? value, String field) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$field must be an object with string keys.');
  }
  return Map<String, dynamic>.from(value);
}

void _keys(Map<String, dynamic> json, Set<String> expected) {
  if (json.length != expected.length || !json.keys.every(expected.contains)) {
    throw FormatException('Expected exactly ${expected.join(', ')}.');
  }
}

GridPos _position(GridPos value) {
  if (value.x < 0 || value.y < 0) {
    throw ArgumentError.value(
      value,
      'fieldObstaclePosition',
      'must be nonnegative',
    );
  }
  return value;
}

Map<String, GridPos> _readPositions(Object? raw, String field) {
  final positions = <String, GridPos>{};
  for (final entry in _object(raw, field).entries) {
    final value = _object(entry.value, '$field.${entry.key}');
    _keys(value, {'x', 'y'});
    if (value['x'] is! int ||
        value['y'] is! int ||
        (value['x'] as int) < 0 ||
        (value['y'] as int) < 0) {
      throw FormatException('$field requires nonnegative integer coordinates.');
    }
    positions[entry.key] = GridPos(x: value['x'] as int, y: value['y'] as int);
  }
  return positions;
}
