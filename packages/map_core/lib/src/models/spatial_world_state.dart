import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'enums.dart';

final class SpatialActorRuntimeState {
  SpatialActorRuntimeState({
    required num x,
    required num z,
    required this.facing,
  }) : x = x.toDouble(),
       z = z.toDouble() {
    if (!this.x.isFinite || !this.z.isFinite || this.x < 0 || this.z < 0) {
      throw const FormatException('Invalid spatial actor runtime position.');
    }
  }

  final double x, z;
  final EntityFacing facing;

  factory SpatialActorRuntimeState.fromJson(Map<String, dynamic> json) {
    _keys(json, {'x', 'z', 'facing'});
    final x = json['x'], z = json['z'];
    final facing = EntityFacing.values
        .where((value) => value.name == json['facing'])
        .firstOrNull;
    if (x is! num || z is! num || facing == null) {
      throw const FormatException('Invalid spatial actor runtime fields.');
    }
    return SpatialActorRuntimeState(x: x, z: z, facing: facing);
  }

  Map<String, dynamic> toJson() => {'x': x, 'z': z, 'facing': facing.name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialActorRuntimeState &&
          other.x == x &&
          other.z == z &&
          other.facing == facing;

  @override
  int get hashCode => Object.hash(x, z, facing);
}

final class SpatialModelRuntimeState {
  SpatialModelRuntimeState({
    required String modelId,
    required this.animationIndex,
    required num normalizedTime,
    required this.blocksMovement,
  }) : modelId = _identity(modelId),
       normalizedTime = normalizedTime.toDouble() {
    if ((animationIndex != null && animationIndex! < 0) ||
        !this.normalizedTime.isFinite ||
        this.normalizedTime < 0 ||
        this.normalizedTime > 1 ||
        (animationIndex == null && this.normalizedTime != 0)) {
      throw const FormatException('Invalid spatial model runtime pose.');
    }
  }

  final String modelId;
  final int? animationIndex;
  final double normalizedTime;
  final bool blocksMovement;

  SpatialModelRuntimeState copyWith({
    double? normalizedTime,
    bool? blocksMovement,
  }) => SpatialModelRuntimeState(
    modelId: modelId,
    animationIndex: animationIndex,
    normalizedTime: normalizedTime ?? this.normalizedTime,
    blocksMovement: blocksMovement ?? this.blocksMovement,
  );

  factory SpatialModelRuntimeState.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'modelId',
      'animationIndex',
      'normalizedTime',
      'blocksMovement',
    });
    final index = json['animationIndex'];
    final time = json['normalizedTime'];
    final blocks = json['blocksMovement'];
    if ((index != null && index is! int) || time is! num || blocks is! bool) {
      throw const FormatException('Invalid spatial model runtime fields.');
    }
    return SpatialModelRuntimeState(
      modelId: _identity(json['modelId']),
      animationIndex: index as int?,
      normalizedTime: time,
      blocksMovement: blocks,
    );
  }

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'animationIndex': animationIndex,
    'normalizedTime': normalizedTime,
    'blocksMovement': blocksMovement,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialModelRuntimeState &&
          other.modelId == modelId &&
          other.animationIndex == animationIndex &&
          other.normalizedTime == normalizedTime &&
          other.blocksMovement == blocksMovement;

  @override
  int get hashCode =>
      Object.hash(modelId, animationIndex, normalizedTime, blocksMovement);
}

final class SpatialWorldState {
  const SpatialWorldState.empty()
    : modelsByMap = const {},
      actorsByMap = const {};

  SpatialWorldState({
    required Map<String, Map<String, SpatialModelRuntimeState>> modelsByMap,
    Map<String, Map<String, SpatialActorRuntimeState>> actorsByMap = const {},
  }) : modelsByMap = Map.unmodifiable({
         for (final entry in modelsByMap.entries)
           _identity(
             entry.key,
           ): Map<String, SpatialModelRuntimeState>.unmodifiable({
             for (final model in entry.value.entries)
               _identity(model.key): model.value,
           }),
       }),
       actorsByMap = Map.unmodifiable({
         for (final entry in actorsByMap.entries)
           _identity(
             entry.key,
           ): Map<String, SpatialActorRuntimeState>.unmodifiable({
             for (final actor in entry.value.entries)
               _identity(actor.key): actor.value,
           }),
       });

  final Map<String, Map<String, SpatialModelRuntimeState>> modelsByMap;
  final Map<String, Map<String, SpatialActorRuntimeState>> actorsByMap;

  SpatialActorRuntimeState? actorState(String mapId, String entityId) =>
      actorsByMap[mapId]?[entityId];

  SpatialWorldState setActorState(
    String mapId,
    String entityId,
    SpatialActorRuntimeState state,
  ) {
    _identity(mapId);
    _identity(entityId);
    if (actorState(mapId, entityId) == state) return this;
    return SpatialWorldState(
      modelsByMap: modelsByMap,
      actorsByMap: {
        ...actorsByMap,
        mapId: {...?actorsByMap[mapId], entityId: state},
      },
    );
  }

  SpatialModelRuntimeState? modelState(String mapId, String instanceId) =>
      modelsByMap[mapId]?[instanceId];

  SpatialWorldState setModelState(
    String mapId,
    String instanceId,
    SpatialModelRuntimeState state,
  ) {
    _identity(mapId);
    _identity(instanceId);
    if (modelState(mapId, instanceId) == state) return this;
    return SpatialWorldState(
      actorsByMap: actorsByMap,
      modelsByMap: {
        ...modelsByMap,
        mapId: {...?modelsByMap[mapId], instanceId: state},
      },
    );
  }

  SpatialWorldState removeModelState(String mapId, String instanceId) {
    if (modelState(mapId, instanceId) == null) return this;
    final next = Map<String, SpatialModelRuntimeState>.of(modelsByMap[mapId]!)
      ..remove(instanceId);
    return SpatialWorldState(
      actorsByMap: actorsByMap,
      modelsByMap: {
        for (final entry in modelsByMap.entries)
          if (entry.key != mapId) entry.key: entry.value,
        if (next.isNotEmpty) mapId: next,
      },
    );
  }

  factory SpatialWorldState.fromJson(Map<String, dynamic> json) {
    _keys(json, {'schemaVersion', 'modelsByMap', 'actorsByMap'});
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported spatial world state version.');
    }
    final maps = _object(json['modelsByMap']);
    final actors = _object(json['actorsByMap']);
    return SpatialWorldState(
      modelsByMap: {
        for (final entry in maps.entries)
          _identity(entry.key): {
            for (final instance in _object(entry.value).entries)
              _identity(instance.key): SpatialModelRuntimeState.fromJson(
                _object(instance.value),
              ),
          },
      },
      actorsByMap: {
        for (final entry in actors.entries)
          _identity(entry.key): {
            for (final actor in _object(entry.value).entries)
              _identity(actor.key): SpatialActorRuntimeState.fromJson(
                _object(actor.value),
              ),
          },
      },
    );
  }

  Map<String, dynamic> toJson() {
    final maps = modelsByMap.keys.toList()..sort();
    final actorMaps = actorsByMap.keys.toList()..sort();
    return {
      'schemaVersion': 1,
      'modelsByMap': {
        for (final mapId in maps)
          mapId: {
            for (final instanceId
                in (modelsByMap[mapId]!.keys.toList()..sort()))
              instanceId: modelsByMap[mapId]![instanceId]!.toJson(),
          },
      },
      'actorsByMap': {
        for (final mapId in actorMaps)
          mapId: {
            for (final entityId in (actorsByMap[mapId]!.keys.toList()..sort()))
              entityId: actorsByMap[mapId]![entityId]!.toJson(),
          },
      },
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialWorldState &&
          const DeepCollectionEquality().equals(
            modelsByMap,
            other.modelsByMap,
          ) &&
          const DeepCollectionEquality().equals(actorsByMap, other.actorsByMap);

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(modelsByMap),
    const DeepCollectionEquality().hash(actorsByMap),
  );
}

String _identity(Object? value) {
  if (value is! String ||
      value.trim() != value ||
      value.isEmpty ||
      value.length > 256 ||
      value.contains('\u0000')) {
    throw const FormatException('Invalid spatial world identity.');
  }
  return value;
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected spatial world object.');
  }
  return Map<String, dynamic>.from(value);
}

void _keys(Map<String, dynamic> json, Set<String> expected) {
  if (json.length != expected.length ||
      json.keys.any((key) => !expected.contains(key))) {
    throw const FormatException('Invalid spatial world document fields.');
  }
}
