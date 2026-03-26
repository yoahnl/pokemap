// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MapData _$MapDataFromJson(Map<String, dynamic> json) {
  return _MapData.fromJson(json);
}

/// @nodoc
mixin _$MapData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  GridSize get size => throw _privateConstructorUsedError;
  ProjectVersion get version => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  List<MapLayer> get layers => throw _privateConstructorUsedError;
  List<MapEntity> get entities => throw _privateConstructorUsedError;
  List<MapConnection> get connections => throw _privateConstructorUsedError;
  List<MapWarp> get warps => throw _privateConstructorUsedError;
  List<MapTrigger> get triggers => throw _privateConstructorUsedError;

  /// Zones gameplay (rencontres, déplacement, dangers, etc.).
  /// Séparées des triggers (logiques scriptées) et des layers visuelles.
  List<MapGameplayZone> get gameplayZones => throw _privateConstructorUsedError;
  MapMetadata get mapMetadata => throw _privateConstructorUsedError;
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

  /// Serializes this MapData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapDataCopyWith<MapData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapDataCopyWith<$Res> {
  factory $MapDataCopyWith(MapData value, $Res Function(MapData) then) =
      _$MapDataCopyWithImpl<$Res, MapData>;
  @useResult
  $Res call(
      {String id,
      String name,
      GridSize size,
      ProjectVersion version,
      String tilesetId,
      List<MapLayer> layers,
      List<MapEntity> entities,
      List<MapConnection> connections,
      List<MapWarp> warps,
      List<MapTrigger> triggers,
      List<MapGameplayZone> gameplayZones,
      MapMetadata mapMetadata,
      Map<String, dynamic> properties});

  $GridSizeCopyWith<$Res> get size;
  $MapMetadataCopyWith<$Res> get mapMetadata;
}

/// @nodoc
class _$MapDataCopyWithImpl<$Res, $Val extends MapData>
    implements $MapDataCopyWith<$Res> {
  _$MapDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? size = null,
    Object? version = null,
    Object? tilesetId = null,
    Object? layers = null,
    Object? entities = null,
    Object? connections = null,
    Object? warps = null,
    Object? triggers = null,
    Object? gameplayZones = null,
    Object? mapMetadata = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as ProjectVersion,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      layers: null == layers
          ? _value.layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<MapLayer>,
      entities: null == entities
          ? _value.entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<MapEntity>,
      connections: null == connections
          ? _value.connections
          : connections // ignore: cast_nullable_to_non_nullable
              as List<MapConnection>,
      warps: null == warps
          ? _value.warps
          : warps // ignore: cast_nullable_to_non_nullable
              as List<MapWarp>,
      triggers: null == triggers
          ? _value.triggers
          : triggers // ignore: cast_nullable_to_non_nullable
              as List<MapTrigger>,
      gameplayZones: null == gameplayZones
          ? _value.gameplayZones
          : gameplayZones // ignore: cast_nullable_to_non_nullable
              as List<MapGameplayZone>,
      mapMetadata: null == mapMetadata
          ? _value.mapMetadata
          : mapMetadata // ignore: cast_nullable_to_non_nullable
              as MapMetadata,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridSizeCopyWith<$Res> get size {
    return $GridSizeCopyWith<$Res>(_value.size, (value) {
      return _then(_value.copyWith(size: value) as $Val);
    });
  }

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapMetadataCopyWith<$Res> get mapMetadata {
    return $MapMetadataCopyWith<$Res>(_value.mapMetadata, (value) {
      return _then(_value.copyWith(mapMetadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapDataImplCopyWith<$Res> implements $MapDataCopyWith<$Res> {
  factory _$$MapDataImplCopyWith(
          _$MapDataImpl value, $Res Function(_$MapDataImpl) then) =
      __$$MapDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      GridSize size,
      ProjectVersion version,
      String tilesetId,
      List<MapLayer> layers,
      List<MapEntity> entities,
      List<MapConnection> connections,
      List<MapWarp> warps,
      List<MapTrigger> triggers,
      List<MapGameplayZone> gameplayZones,
      MapMetadata mapMetadata,
      Map<String, dynamic> properties});

  @override
  $GridSizeCopyWith<$Res> get size;
  @override
  $MapMetadataCopyWith<$Res> get mapMetadata;
}

/// @nodoc
class __$$MapDataImplCopyWithImpl<$Res>
    extends _$MapDataCopyWithImpl<$Res, _$MapDataImpl>
    implements _$$MapDataImplCopyWith<$Res> {
  __$$MapDataImplCopyWithImpl(
      _$MapDataImpl _value, $Res Function(_$MapDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? size = null,
    Object? version = null,
    Object? tilesetId = null,
    Object? layers = null,
    Object? entities = null,
    Object? connections = null,
    Object? warps = null,
    Object? triggers = null,
    Object? gameplayZones = null,
    Object? mapMetadata = null,
    Object? properties = null,
  }) {
    return _then(_$MapDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as ProjectVersion,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      layers: null == layers
          ? _value._layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<MapLayer>,
      entities: null == entities
          ? _value._entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<MapEntity>,
      connections: null == connections
          ? _value._connections
          : connections // ignore: cast_nullable_to_non_nullable
              as List<MapConnection>,
      warps: null == warps
          ? _value._warps
          : warps // ignore: cast_nullable_to_non_nullable
              as List<MapWarp>,
      triggers: null == triggers
          ? _value._triggers
          : triggers // ignore: cast_nullable_to_non_nullable
              as List<MapTrigger>,
      gameplayZones: null == gameplayZones
          ? _value._gameplayZones
          : gameplayZones // ignore: cast_nullable_to_non_nullable
              as List<MapGameplayZone>,
      mapMetadata: null == mapMetadata
          ? _value.mapMetadata
          : mapMetadata // ignore: cast_nullable_to_non_nullable
              as MapMetadata,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapDataImpl implements _MapData {
  const _$MapDataImpl(
      {required this.id,
      required this.name,
      required this.size,
      this.version = ProjectVersion.v1,
      this.tilesetId = '',
      final List<MapLayer> layers = const [],
      final List<MapEntity> entities = const [],
      final List<MapConnection> connections = const [],
      final List<MapWarp> warps = const [],
      final List<MapTrigger> triggers = const [],
      final List<MapGameplayZone> gameplayZones = const [],
      this.mapMetadata = const MapMetadata(),
      final Map<String, dynamic> properties = const {}})
      : _layers = layers,
        _entities = entities,
        _connections = connections,
        _warps = warps,
        _triggers = triggers,
        _gameplayZones = gameplayZones,
        _properties = properties;

  factory _$MapDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final GridSize size;
  @override
  @JsonKey()
  final ProjectVersion version;
  @override
  @JsonKey()
  final String tilesetId;
  final List<MapLayer> _layers;
  @override
  @JsonKey()
  List<MapLayer> get layers {
    if (_layers is EqualUnmodifiableListView) return _layers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_layers);
  }

  final List<MapEntity> _entities;
  @override
  @JsonKey()
  List<MapEntity> get entities {
    if (_entities is EqualUnmodifiableListView) return _entities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entities);
  }

  final List<MapConnection> _connections;
  @override
  @JsonKey()
  List<MapConnection> get connections {
    if (_connections is EqualUnmodifiableListView) return _connections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_connections);
  }

  final List<MapWarp> _warps;
  @override
  @JsonKey()
  List<MapWarp> get warps {
    if (_warps is EqualUnmodifiableListView) return _warps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warps);
  }

  final List<MapTrigger> _triggers;
  @override
  @JsonKey()
  List<MapTrigger> get triggers {
    if (_triggers is EqualUnmodifiableListView) return _triggers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_triggers);
  }

  /// Zones gameplay (rencontres, déplacement, dangers, etc.).
  /// Séparées des triggers (logiques scriptées) et des layers visuelles.
  final List<MapGameplayZone> _gameplayZones;

  /// Zones gameplay (rencontres, déplacement, dangers, etc.).
  /// Séparées des triggers (logiques scriptées) et des layers visuelles.
  @override
  @JsonKey()
  List<MapGameplayZone> get gameplayZones {
    if (_gameplayZones is EqualUnmodifiableListView) return _gameplayZones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_gameplayZones);
  }

  @override
  @JsonKey()
  final MapMetadata mapMetadata;
  final Map<String, dynamic> _properties;
  @override
  @JsonKey()
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'MapData(id: $id, name: $name, size: $size, version: $version, tilesetId: $tilesetId, layers: $layers, entities: $entities, connections: $connections, warps: $warps, triggers: $triggers, gameplayZones: $gameplayZones, mapMetadata: $mapMetadata, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            const DeepCollectionEquality().equals(other._layers, _layers) &&
            const DeepCollectionEquality().equals(other._entities, _entities) &&
            const DeepCollectionEquality()
                .equals(other._connections, _connections) &&
            const DeepCollectionEquality().equals(other._warps, _warps) &&
            const DeepCollectionEquality().equals(other._triggers, _triggers) &&
            const DeepCollectionEquality()
                .equals(other._gameplayZones, _gameplayZones) &&
            (identical(other.mapMetadata, mapMetadata) ||
                other.mapMetadata == mapMetadata) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      size,
      version,
      tilesetId,
      const DeepCollectionEquality().hash(_layers),
      const DeepCollectionEquality().hash(_entities),
      const DeepCollectionEquality().hash(_connections),
      const DeepCollectionEquality().hash(_warps),
      const DeepCollectionEquality().hash(_triggers),
      const DeepCollectionEquality().hash(_gameplayZones),
      mapMetadata,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapDataImplCopyWith<_$MapDataImpl> get copyWith =>
      __$$MapDataImplCopyWithImpl<_$MapDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapDataImplToJson(
      this,
    );
  }
}

abstract class _MapData implements MapData {
  const factory _MapData(
      {required final String id,
      required final String name,
      required final GridSize size,
      final ProjectVersion version,
      final String tilesetId,
      final List<MapLayer> layers,
      final List<MapEntity> entities,
      final List<MapConnection> connections,
      final List<MapWarp> warps,
      final List<MapTrigger> triggers,
      final List<MapGameplayZone> gameplayZones,
      final MapMetadata mapMetadata,
      final Map<String, dynamic> properties}) = _$MapDataImpl;

  factory _MapData.fromJson(Map<String, dynamic> json) = _$MapDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  GridSize get size;
  @override
  ProjectVersion get version;
  @override
  String get tilesetId;
  @override
  List<MapLayer> get layers;
  @override
  List<MapEntity> get entities;
  @override
  List<MapConnection> get connections;
  @override
  List<MapWarp> get warps;
  @override
  List<MapTrigger> get triggers;

  /// Zones gameplay (rencontres, déplacement, dangers, etc.).
  /// Séparées des triggers (logiques scriptées) et des layers visuelles.
  @override
  List<MapGameplayZone> get gameplayZones;
  @override
  MapMetadata get mapMetadata;
  @override
  Map<String, dynamic> get properties;

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapDataImplCopyWith<_$MapDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapGameplayZone _$MapGameplayZoneFromJson(Map<String, dynamic> json) {
  return _MapGameplayZone.fromJson(json);
}

/// @nodoc
mixin _$MapGameplayZone {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  GameplayZoneKind get kind => throw _privateConstructorUsedError;
  MapRect get area => throw _privateConstructorUsedError;

  /// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
  int get priority => throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.encounter].
  EncounterZonePayload? get encounter => throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.movement].
  MovementZonePayload? get movement => throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.hazard].
  HazardZonePayload? get hazard => throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
  SpecialZonePayload? get special => throw _privateConstructorUsedError;

  /// Serializes this MapGameplayZone to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapGameplayZoneCopyWith<MapGameplayZone> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapGameplayZoneCopyWith<$Res> {
  factory $MapGameplayZoneCopyWith(
          MapGameplayZone value, $Res Function(MapGameplayZone) then) =
      _$MapGameplayZoneCopyWithImpl<$Res, MapGameplayZone>;
  @useResult
  $Res call(
      {String id,
      String name,
      GameplayZoneKind kind,
      MapRect area,
      int priority,
      EncounterZonePayload? encounter,
      MovementZonePayload? movement,
      HazardZonePayload? hazard,
      SpecialZonePayload? special});

  $MapRectCopyWith<$Res> get area;
  $EncounterZonePayloadCopyWith<$Res>? get encounter;
  $MovementZonePayloadCopyWith<$Res>? get movement;
  $HazardZonePayloadCopyWith<$Res>? get hazard;
  $SpecialZonePayloadCopyWith<$Res>? get special;
}

/// @nodoc
class _$MapGameplayZoneCopyWithImpl<$Res, $Val extends MapGameplayZone>
    implements $MapGameplayZoneCopyWith<$Res> {
  _$MapGameplayZoneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? area = null,
    Object? priority = null,
    Object? encounter = freezed,
    Object? movement = freezed,
    Object? hazard = freezed,
    Object? special = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as GameplayZoneKind,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as MapRect,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      encounter: freezed == encounter
          ? _value.encounter
          : encounter // ignore: cast_nullable_to_non_nullable
              as EncounterZonePayload?,
      movement: freezed == movement
          ? _value.movement
          : movement // ignore: cast_nullable_to_non_nullable
              as MovementZonePayload?,
      hazard: freezed == hazard
          ? _value.hazard
          : hazard // ignore: cast_nullable_to_non_nullable
              as HazardZonePayload?,
      special: freezed == special
          ? _value.special
          : special // ignore: cast_nullable_to_non_nullable
              as SpecialZonePayload?,
    ) as $Val);
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapRectCopyWith<$Res> get area {
    return $MapRectCopyWith<$Res>(_value.area, (value) {
      return _then(_value.copyWith(area: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EncounterZonePayloadCopyWith<$Res>? get encounter {
    if (_value.encounter == null) {
      return null;
    }

    return $EncounterZonePayloadCopyWith<$Res>(_value.encounter!, (value) {
      return _then(_value.copyWith(encounter: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MovementZonePayloadCopyWith<$Res>? get movement {
    if (_value.movement == null) {
      return null;
    }

    return $MovementZonePayloadCopyWith<$Res>(_value.movement!, (value) {
      return _then(_value.copyWith(movement: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HazardZonePayloadCopyWith<$Res>? get hazard {
    if (_value.hazard == null) {
      return null;
    }

    return $HazardZonePayloadCopyWith<$Res>(_value.hazard!, (value) {
      return _then(_value.copyWith(hazard: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SpecialZonePayloadCopyWith<$Res>? get special {
    if (_value.special == null) {
      return null;
    }

    return $SpecialZonePayloadCopyWith<$Res>(_value.special!, (value) {
      return _then(_value.copyWith(special: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapGameplayZoneImplCopyWith<$Res>
    implements $MapGameplayZoneCopyWith<$Res> {
  factory _$$MapGameplayZoneImplCopyWith(_$MapGameplayZoneImpl value,
          $Res Function(_$MapGameplayZoneImpl) then) =
      __$$MapGameplayZoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      GameplayZoneKind kind,
      MapRect area,
      int priority,
      EncounterZonePayload? encounter,
      MovementZonePayload? movement,
      HazardZonePayload? hazard,
      SpecialZonePayload? special});

  @override
  $MapRectCopyWith<$Res> get area;
  @override
  $EncounterZonePayloadCopyWith<$Res>? get encounter;
  @override
  $MovementZonePayloadCopyWith<$Res>? get movement;
  @override
  $HazardZonePayloadCopyWith<$Res>? get hazard;
  @override
  $SpecialZonePayloadCopyWith<$Res>? get special;
}

/// @nodoc
class __$$MapGameplayZoneImplCopyWithImpl<$Res>
    extends _$MapGameplayZoneCopyWithImpl<$Res, _$MapGameplayZoneImpl>
    implements _$$MapGameplayZoneImplCopyWith<$Res> {
  __$$MapGameplayZoneImplCopyWithImpl(
      _$MapGameplayZoneImpl _value, $Res Function(_$MapGameplayZoneImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? area = null,
    Object? priority = null,
    Object? encounter = freezed,
    Object? movement = freezed,
    Object? hazard = freezed,
    Object? special = freezed,
  }) {
    return _then(_$MapGameplayZoneImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as GameplayZoneKind,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as MapRect,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      encounter: freezed == encounter
          ? _value.encounter
          : encounter // ignore: cast_nullable_to_non_nullable
              as EncounterZonePayload?,
      movement: freezed == movement
          ? _value.movement
          : movement // ignore: cast_nullable_to_non_nullable
              as MovementZonePayload?,
      hazard: freezed == hazard
          ? _value.hazard
          : hazard // ignore: cast_nullable_to_non_nullable
              as HazardZonePayload?,
      special: freezed == special
          ? _value.special
          : special // ignore: cast_nullable_to_non_nullable
              as SpecialZonePayload?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapGameplayZoneImpl implements _MapGameplayZone {
  const _$MapGameplayZoneImpl(
      {required this.id,
      this.name = '',
      required this.kind,
      required this.area,
      this.priority = 0,
      this.encounter,
      this.movement,
      this.hazard,
      this.special});

  factory _$MapGameplayZoneImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapGameplayZoneImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  final GameplayZoneKind kind;
  @override
  final MapRect area;

  /// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
  @override
  @JsonKey()
  final int priority;

  /// Payload pour [GameplayZoneKind.encounter].
  @override
  final EncounterZonePayload? encounter;

  /// Payload pour [GameplayZoneKind.movement].
  @override
  final MovementZonePayload? movement;

  /// Payload pour [GameplayZoneKind.hazard].
  @override
  final HazardZonePayload? hazard;

  /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
  @override
  final SpecialZonePayload? special;

  @override
  String toString() {
    return 'MapGameplayZone(id: $id, name: $name, kind: $kind, area: $area, priority: $priority, encounter: $encounter, movement: $movement, hazard: $hazard, special: $special)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapGameplayZoneImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.area, area) || other.area == area) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.encounter, encounter) ||
                other.encounter == encounter) &&
            (identical(other.movement, movement) ||
                other.movement == movement) &&
            (identical(other.hazard, hazard) || other.hazard == hazard) &&
            (identical(other.special, special) || other.special == special));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, kind, area, priority,
      encounter, movement, hazard, special);

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapGameplayZoneImplCopyWith<_$MapGameplayZoneImpl> get copyWith =>
      __$$MapGameplayZoneImplCopyWithImpl<_$MapGameplayZoneImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapGameplayZoneImplToJson(
      this,
    );
  }
}

abstract class _MapGameplayZone implements MapGameplayZone {
  const factory _MapGameplayZone(
      {required final String id,
      final String name,
      required final GameplayZoneKind kind,
      required final MapRect area,
      final int priority,
      final EncounterZonePayload? encounter,
      final MovementZonePayload? movement,
      final HazardZonePayload? hazard,
      final SpecialZonePayload? special}) = _$MapGameplayZoneImpl;

  factory _MapGameplayZone.fromJson(Map<String, dynamic> json) =
      _$MapGameplayZoneImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  GameplayZoneKind get kind;
  @override
  MapRect get area;

  /// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
  @override
  int get priority;

  /// Payload pour [GameplayZoneKind.encounter].
  @override
  EncounterZonePayload? get encounter;

  /// Payload pour [GameplayZoneKind.movement].
  @override
  MovementZonePayload? get movement;

  /// Payload pour [GameplayZoneKind.hazard].
  @override
  HazardZonePayload? get hazard;

  /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
  @override
  SpecialZonePayload? get special;

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapGameplayZoneImplCopyWith<_$MapGameplayZoneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapEntity _$MapEntityFromJson(Map<String, dynamic> json) {
  return _MapEntity.fromJson(json);
}

/// @nodoc
mixin _$MapEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  MapEntityKind get kind => throw _privateConstructorUsedError;
  GridPos get pos => throw _privateConstructorUsedError;
  GridSize get size => throw _privateConstructorUsedError;
  MapEntityNpcData? get npc => throw _privateConstructorUsedError;
  MapEntitySignData? get sign => throw _privateConstructorUsedError;
  MapEntityItemData? get item => throw _privateConstructorUsedError;
  MapEntitySpawnData? get spawn => throw _privateConstructorUsedError;
  MapEntityEditorVisual? get editorVisual => throw _privateConstructorUsedError;
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this MapEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEntityCopyWith<MapEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEntityCopyWith<$Res> {
  factory $MapEntityCopyWith(MapEntity value, $Res Function(MapEntity) then) =
      _$MapEntityCopyWithImpl<$Res, MapEntity>;
  @useResult
  $Res call(
      {String id,
      String name,
      MapEntityKind kind,
      GridPos pos,
      GridSize size,
      MapEntityNpcData? npc,
      MapEntitySignData? sign,
      MapEntityItemData? item,
      MapEntitySpawnData? spawn,
      MapEntityEditorVisual? editorVisual,
      Map<String, String> properties});

  $GridPosCopyWith<$Res> get pos;
  $GridSizeCopyWith<$Res> get size;
  $MapEntityNpcDataCopyWith<$Res>? get npc;
  $MapEntitySignDataCopyWith<$Res>? get sign;
  $MapEntityItemDataCopyWith<$Res>? get item;
  $MapEntitySpawnDataCopyWith<$Res>? get spawn;
  $MapEntityEditorVisualCopyWith<$Res>? get editorVisual;
}

/// @nodoc
class _$MapEntityCopyWithImpl<$Res, $Val extends MapEntity>
    implements $MapEntityCopyWith<$Res> {
  _$MapEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? pos = null,
    Object? size = null,
    Object? npc = freezed,
    Object? sign = freezed,
    Object? item = freezed,
    Object? spawn = freezed,
    Object? editorVisual = freezed,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MapEntityKind,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
      npc: freezed == npc
          ? _value.npc
          : npc // ignore: cast_nullable_to_non_nullable
              as MapEntityNpcData?,
      sign: freezed == sign
          ? _value.sign
          : sign // ignore: cast_nullable_to_non_nullable
              as MapEntitySignData?,
      item: freezed == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as MapEntityItemData?,
      spawn: freezed == spawn
          ? _value.spawn
          : spawn // ignore: cast_nullable_to_non_nullable
              as MapEntitySpawnData?,
      editorVisual: freezed == editorVisual
          ? _value.editorVisual
          : editorVisual // ignore: cast_nullable_to_non_nullable
              as MapEntityEditorVisual?,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get pos {
    return $GridPosCopyWith<$Res>(_value.pos, (value) {
      return _then(_value.copyWith(pos: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridSizeCopyWith<$Res> get size {
    return $GridSizeCopyWith<$Res>(_value.size, (value) {
      return _then(_value.copyWith(size: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntityNpcDataCopyWith<$Res>? get npc {
    if (_value.npc == null) {
      return null;
    }

    return $MapEntityNpcDataCopyWith<$Res>(_value.npc!, (value) {
      return _then(_value.copyWith(npc: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntitySignDataCopyWith<$Res>? get sign {
    if (_value.sign == null) {
      return null;
    }

    return $MapEntitySignDataCopyWith<$Res>(_value.sign!, (value) {
      return _then(_value.copyWith(sign: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntityItemDataCopyWith<$Res>? get item {
    if (_value.item == null) {
      return null;
    }

    return $MapEntityItemDataCopyWith<$Res>(_value.item!, (value) {
      return _then(_value.copyWith(item: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntitySpawnDataCopyWith<$Res>? get spawn {
    if (_value.spawn == null) {
      return null;
    }

    return $MapEntitySpawnDataCopyWith<$Res>(_value.spawn!, (value) {
      return _then(_value.copyWith(spawn: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntityEditorVisualCopyWith<$Res>? get editorVisual {
    if (_value.editorVisual == null) {
      return null;
    }

    return $MapEntityEditorVisualCopyWith<$Res>(_value.editorVisual!, (value) {
      return _then(_value.copyWith(editorVisual: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapEntityImplCopyWith<$Res>
    implements $MapEntityCopyWith<$Res> {
  factory _$$MapEntityImplCopyWith(
          _$MapEntityImpl value, $Res Function(_$MapEntityImpl) then) =
      __$$MapEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      MapEntityKind kind,
      GridPos pos,
      GridSize size,
      MapEntityNpcData? npc,
      MapEntitySignData? sign,
      MapEntityItemData? item,
      MapEntitySpawnData? spawn,
      MapEntityEditorVisual? editorVisual,
      Map<String, String> properties});

  @override
  $GridPosCopyWith<$Res> get pos;
  @override
  $GridSizeCopyWith<$Res> get size;
  @override
  $MapEntityNpcDataCopyWith<$Res>? get npc;
  @override
  $MapEntitySignDataCopyWith<$Res>? get sign;
  @override
  $MapEntityItemDataCopyWith<$Res>? get item;
  @override
  $MapEntitySpawnDataCopyWith<$Res>? get spawn;
  @override
  $MapEntityEditorVisualCopyWith<$Res>? get editorVisual;
}

/// @nodoc
class __$$MapEntityImplCopyWithImpl<$Res>
    extends _$MapEntityCopyWithImpl<$Res, _$MapEntityImpl>
    implements _$$MapEntityImplCopyWith<$Res> {
  __$$MapEntityImplCopyWithImpl(
      _$MapEntityImpl _value, $Res Function(_$MapEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? pos = null,
    Object? size = null,
    Object? npc = freezed,
    Object? sign = freezed,
    Object? item = freezed,
    Object? spawn = freezed,
    Object? editorVisual = freezed,
    Object? properties = null,
  }) {
    return _then(_$MapEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MapEntityKind,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
      npc: freezed == npc
          ? _value.npc
          : npc // ignore: cast_nullable_to_non_nullable
              as MapEntityNpcData?,
      sign: freezed == sign
          ? _value.sign
          : sign // ignore: cast_nullable_to_non_nullable
              as MapEntitySignData?,
      item: freezed == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as MapEntityItemData?,
      spawn: freezed == spawn
          ? _value.spawn
          : spawn // ignore: cast_nullable_to_non_nullable
              as MapEntitySpawnData?,
      editorVisual: freezed == editorVisual
          ? _value.editorVisual
          : editorVisual // ignore: cast_nullable_to_non_nullable
              as MapEntityEditorVisual?,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntityImpl implements _MapEntity {
  const _$MapEntityImpl(
      {required this.id,
      this.name = '',
      required this.kind,
      required this.pos,
      this.size = const GridSize(width: 1, height: 1),
      this.npc,
      this.sign,
      this.item,
      this.spawn,
      this.editorVisual,
      final Map<String, String> properties = const {}})
      : _properties = properties;

  factory _$MapEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEntityImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  final MapEntityKind kind;
  @override
  final GridPos pos;
  @override
  @JsonKey()
  final GridSize size;
  @override
  final MapEntityNpcData? npc;
  @override
  final MapEntitySignData? sign;
  @override
  final MapEntityItemData? item;
  @override
  final MapEntitySpawnData? spawn;
  @override
  final MapEntityEditorVisual? editorVisual;
  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'MapEntity(id: $id, name: $name, kind: $kind, pos: $pos, size: $size, npc: $npc, sign: $sign, item: $item, spawn: $spawn, editorVisual: $editorVisual, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.pos, pos) || other.pos == pos) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.npc, npc) || other.npc == npc) &&
            (identical(other.sign, sign) || other.sign == sign) &&
            (identical(other.item, item) || other.item == item) &&
            (identical(other.spawn, spawn) || other.spawn == spawn) &&
            (identical(other.editorVisual, editorVisual) ||
                other.editorVisual == editorVisual) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      kind,
      pos,
      size,
      npc,
      sign,
      item,
      spawn,
      editorVisual,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEntityImplCopyWith<_$MapEntityImpl> get copyWith =>
      __$$MapEntityImplCopyWithImpl<_$MapEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEntityImplToJson(
      this,
    );
  }
}

abstract class _MapEntity implements MapEntity {
  const factory _MapEntity(
      {required final String id,
      final String name,
      required final MapEntityKind kind,
      required final GridPos pos,
      final GridSize size,
      final MapEntityNpcData? npc,
      final MapEntitySignData? sign,
      final MapEntityItemData? item,
      final MapEntitySpawnData? spawn,
      final MapEntityEditorVisual? editorVisual,
      final Map<String, String> properties}) = _$MapEntityImpl;

  factory _MapEntity.fromJson(Map<String, dynamic> json) =
      _$MapEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  MapEntityKind get kind;
  @override
  GridPos get pos;
  @override
  GridSize get size;
  @override
  MapEntityNpcData? get npc;
  @override
  MapEntitySignData? get sign;
  @override
  MapEntityItemData? get item;
  @override
  MapEntitySpawnData? get spawn;
  @override
  MapEntityEditorVisual? get editorVisual;
  @override
  Map<String, String> get properties;

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEntityImplCopyWith<_$MapEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapWarp _$MapWarpFromJson(Map<String, dynamic> json) {
  return _MapWarp.fromJson(json);
}

/// @nodoc
mixin _$MapWarp {
  String get id => throw _privateConstructorUsedError;
  GridPos get pos => throw _privateConstructorUsedError;
  String get targetMapId => throw _privateConstructorUsedError;
  GridPos get targetPos => throw _privateConstructorUsedError;

  /// Serializes this MapWarp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapWarpCopyWith<MapWarp> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapWarpCopyWith<$Res> {
  factory $MapWarpCopyWith(MapWarp value, $Res Function(MapWarp) then) =
      _$MapWarpCopyWithImpl<$Res, MapWarp>;
  @useResult
  $Res call({String id, GridPos pos, String targetMapId, GridPos targetPos});

  $GridPosCopyWith<$Res> get pos;
  $GridPosCopyWith<$Res> get targetPos;
}

/// @nodoc
class _$MapWarpCopyWithImpl<$Res, $Val extends MapWarp>
    implements $MapWarpCopyWith<$Res> {
  _$MapWarpCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pos = null,
    Object? targetMapId = null,
    Object? targetPos = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      targetMapId: null == targetMapId
          ? _value.targetMapId
          : targetMapId // ignore: cast_nullable_to_non_nullable
              as String,
      targetPos: null == targetPos
          ? _value.targetPos
          : targetPos // ignore: cast_nullable_to_non_nullable
              as GridPos,
    ) as $Val);
  }

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get pos {
    return $GridPosCopyWith<$Res>(_value.pos, (value) {
      return _then(_value.copyWith(pos: value) as $Val);
    });
  }

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get targetPos {
    return $GridPosCopyWith<$Res>(_value.targetPos, (value) {
      return _then(_value.copyWith(targetPos: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapWarpImplCopyWith<$Res> implements $MapWarpCopyWith<$Res> {
  factory _$$MapWarpImplCopyWith(
          _$MapWarpImpl value, $Res Function(_$MapWarpImpl) then) =
      __$$MapWarpImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, GridPos pos, String targetMapId, GridPos targetPos});

  @override
  $GridPosCopyWith<$Res> get pos;
  @override
  $GridPosCopyWith<$Res> get targetPos;
}

/// @nodoc
class __$$MapWarpImplCopyWithImpl<$Res>
    extends _$MapWarpCopyWithImpl<$Res, _$MapWarpImpl>
    implements _$$MapWarpImplCopyWith<$Res> {
  __$$MapWarpImplCopyWithImpl(
      _$MapWarpImpl _value, $Res Function(_$MapWarpImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pos = null,
    Object? targetMapId = null,
    Object? targetPos = null,
  }) {
    return _then(_$MapWarpImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      targetMapId: null == targetMapId
          ? _value.targetMapId
          : targetMapId // ignore: cast_nullable_to_non_nullable
              as String,
      targetPos: null == targetPos
          ? _value.targetPos
          : targetPos // ignore: cast_nullable_to_non_nullable
              as GridPos,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapWarpImpl implements _MapWarp {
  const _$MapWarpImpl(
      {required this.id,
      required this.pos,
      required this.targetMapId,
      required this.targetPos});

  factory _$MapWarpImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapWarpImplFromJson(json);

  @override
  final String id;
  @override
  final GridPos pos;
  @override
  final String targetMapId;
  @override
  final GridPos targetPos;

  @override
  String toString() {
    return 'MapWarp(id: $id, pos: $pos, targetMapId: $targetMapId, targetPos: $targetPos)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapWarpImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pos, pos) || other.pos == pos) &&
            (identical(other.targetMapId, targetMapId) ||
                other.targetMapId == targetMapId) &&
            (identical(other.targetPos, targetPos) ||
                other.targetPos == targetPos));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, pos, targetMapId, targetPos);

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapWarpImplCopyWith<_$MapWarpImpl> get copyWith =>
      __$$MapWarpImplCopyWithImpl<_$MapWarpImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapWarpImplToJson(
      this,
    );
  }
}

abstract class _MapWarp implements MapWarp {
  const factory _MapWarp(
      {required final String id,
      required final GridPos pos,
      required final String targetMapId,
      required final GridPos targetPos}) = _$MapWarpImpl;

  factory _MapWarp.fromJson(Map<String, dynamic> json) = _$MapWarpImpl.fromJson;

  @override
  String get id;
  @override
  GridPos get pos;
  @override
  String get targetMapId;
  @override
  GridPos get targetPos;

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapWarpImplCopyWith<_$MapWarpImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapConnection _$MapConnectionFromJson(Map<String, dynamic> json) {
  return _MapConnection.fromJson(json);
}

/// @nodoc
mixin _$MapConnection {
  MapConnectionDirection get direction => throw _privateConstructorUsedError;
  String get targetMapId => throw _privateConstructorUsedError;
  int get offset => throw _privateConstructorUsedError;

  /// Serializes this MapConnection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapConnectionCopyWith<MapConnection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapConnectionCopyWith<$Res> {
  factory $MapConnectionCopyWith(
          MapConnection value, $Res Function(MapConnection) then) =
      _$MapConnectionCopyWithImpl<$Res, MapConnection>;
  @useResult
  $Res call({MapConnectionDirection direction, String targetMapId, int offset});
}

/// @nodoc
class _$MapConnectionCopyWithImpl<$Res, $Val extends MapConnection>
    implements $MapConnectionCopyWith<$Res> {
  _$MapConnectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? direction = null,
    Object? targetMapId = null,
    Object? offset = null,
  }) {
    return _then(_value.copyWith(
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as MapConnectionDirection,
      targetMapId: null == targetMapId
          ? _value.targetMapId
          : targetMapId // ignore: cast_nullable_to_non_nullable
              as String,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapConnectionImplCopyWith<$Res>
    implements $MapConnectionCopyWith<$Res> {
  factory _$$MapConnectionImplCopyWith(
          _$MapConnectionImpl value, $Res Function(_$MapConnectionImpl) then) =
      __$$MapConnectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MapConnectionDirection direction, String targetMapId, int offset});
}

/// @nodoc
class __$$MapConnectionImplCopyWithImpl<$Res>
    extends _$MapConnectionCopyWithImpl<$Res, _$MapConnectionImpl>
    implements _$$MapConnectionImplCopyWith<$Res> {
  __$$MapConnectionImplCopyWithImpl(
      _$MapConnectionImpl _value, $Res Function(_$MapConnectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? direction = null,
    Object? targetMapId = null,
    Object? offset = null,
  }) {
    return _then(_$MapConnectionImpl(
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as MapConnectionDirection,
      targetMapId: null == targetMapId
          ? _value.targetMapId
          : targetMapId // ignore: cast_nullable_to_non_nullable
              as String,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapConnectionImpl implements _MapConnection {
  const _$MapConnectionImpl(
      {required this.direction, required this.targetMapId, this.offset = 0});

  factory _$MapConnectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapConnectionImplFromJson(json);

  @override
  final MapConnectionDirection direction;
  @override
  final String targetMapId;
  @override
  @JsonKey()
  final int offset;

  @override
  String toString() {
    return 'MapConnection(direction: $direction, targetMapId: $targetMapId, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapConnectionImpl &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.targetMapId, targetMapId) ||
                other.targetMapId == targetMapId) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, direction, targetMapId, offset);

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapConnectionImplCopyWith<_$MapConnectionImpl> get copyWith =>
      __$$MapConnectionImplCopyWithImpl<_$MapConnectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapConnectionImplToJson(
      this,
    );
  }
}

abstract class _MapConnection implements MapConnection {
  const factory _MapConnection(
      {required final MapConnectionDirection direction,
      required final String targetMapId,
      final int offset}) = _$MapConnectionImpl;

  factory _MapConnection.fromJson(Map<String, dynamic> json) =
      _$MapConnectionImpl.fromJson;

  @override
  MapConnectionDirection get direction;
  @override
  String get targetMapId;
  @override
  int get offset;

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapConnectionImplCopyWith<_$MapConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapTrigger _$MapTriggerFromJson(Map<String, dynamic> json) {
  return _MapTrigger.fromJson(json);
}

/// @nodoc
mixin _$MapTrigger {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  TriggerType get type => throw _privateConstructorUsedError;
  MapRect get area => throw _privateConstructorUsedError;
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this MapTrigger to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapTriggerCopyWith<MapTrigger> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapTriggerCopyWith<$Res> {
  factory $MapTriggerCopyWith(
          MapTrigger value, $Res Function(MapTrigger) then) =
      _$MapTriggerCopyWithImpl<$Res, MapTrigger>;
  @useResult
  $Res call(
      {String id,
      String name,
      TriggerType type,
      MapRect area,
      Map<String, String> properties});

  $MapRectCopyWith<$Res> get area;
}

/// @nodoc
class _$MapTriggerCopyWithImpl<$Res, $Val extends MapTrigger>
    implements $MapTriggerCopyWith<$Res> {
  _$MapTriggerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? area = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TriggerType,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as MapRect,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapRectCopyWith<$Res> get area {
    return $MapRectCopyWith<$Res>(_value.area, (value) {
      return _then(_value.copyWith(area: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapTriggerImplCopyWith<$Res>
    implements $MapTriggerCopyWith<$Res> {
  factory _$$MapTriggerImplCopyWith(
          _$MapTriggerImpl value, $Res Function(_$MapTriggerImpl) then) =
      __$$MapTriggerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      TriggerType type,
      MapRect area,
      Map<String, String> properties});

  @override
  $MapRectCopyWith<$Res> get area;
}

/// @nodoc
class __$$MapTriggerImplCopyWithImpl<$Res>
    extends _$MapTriggerCopyWithImpl<$Res, _$MapTriggerImpl>
    implements _$$MapTriggerImplCopyWith<$Res> {
  __$$MapTriggerImplCopyWithImpl(
      _$MapTriggerImpl _value, $Res Function(_$MapTriggerImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? area = null,
    Object? properties = null,
  }) {
    return _then(_$MapTriggerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TriggerType,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as MapRect,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapTriggerImpl implements _MapTrigger {
  const _$MapTriggerImpl(
      {required this.id,
      this.name = '',
      required this.type,
      required this.area,
      final Map<String, String> properties = const {}})
      : _properties = properties;

  factory _$MapTriggerImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapTriggerImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  final TriggerType type;
  @override
  final MapRect area;
  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'MapTrigger(id: $id, name: $name, type: $type, area: $area, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapTriggerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.area, area) || other.area == area) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, type, area,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapTriggerImplCopyWith<_$MapTriggerImpl> get copyWith =>
      __$$MapTriggerImplCopyWithImpl<_$MapTriggerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapTriggerImplToJson(
      this,
    );
  }
}

abstract class _MapTrigger implements MapTrigger {
  const factory _MapTrigger(
      {required final String id,
      final String name,
      required final TriggerType type,
      required final MapRect area,
      final Map<String, String> properties}) = _$MapTriggerImpl;

  factory _MapTrigger.fromJson(Map<String, dynamic> json) =
      _$MapTriggerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  TriggerType get type;
  @override
  MapRect get area;
  @override
  Map<String, String> get properties;

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapTriggerImplCopyWith<_$MapTriggerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
