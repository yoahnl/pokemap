import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
import 'package:meta/meta.dart' show immutable;

const currentMapInstanceWorldStateSchemaVersion = 1;
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
  }) : instanceId = _identity(instanceId, 'instanceId'),
       eventBooleans = Map.unmodifiable({
         for (final event in eventBooleans.entries)
           _identity(event.key, 'eventId'): Map<String, bool>.unmodifiable({
             for (final entry in event.value.entries)
               _identity(entry.key, 'key'): entry.value,
           }),
       });

  final String instanceId;
  final Map<String, Map<String, bool>> eventBooleans;

  factory MapInstanceRuntimeState.fromJson(Map<String, dynamic> json) {
    _keys(json, {'instanceId', 'eventBooleans'});
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
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid instance.');
    }
  }

  Map<String, dynamic> toJson() {
    final eventIds = eventBooleans.keys.toList()..sort();
    return {
      'instanceId': instanceId,
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
          _collectionEquality.equals(other.eventBooleans, eventBooleans);

  @override
  int get hashCode =>
      Object.hash(instanceId, _collectionEquality.hash(eventBooleans));
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
          eventBooleans: {
            ...instance.eventBooleans,
            eventId: {...?booleans, key: value},
          },
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
