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
  String get version => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  List<MapLayerData> get layers => throw _privateConstructorUsedError;
  List<MapEntity> get entities => throw _privateConstructorUsedError;
  List<MapWarp> get warps => throw _privateConstructorUsedError;
  List<MapTrigger> get triggers => throw _privateConstructorUsedError;
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
      String version,
      String tilesetId,
      List<MapLayerData> layers,
      List<MapEntity> entities,
      List<MapWarp> warps,
      List<MapTrigger> triggers,
      Map<String, dynamic> properties});

  $GridSizeCopyWith<$Res> get size;
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
    Object? warps = null,
    Object? triggers = null,
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
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      layers: null == layers
          ? _value.layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<MapLayerData>,
      entities: null == entities
          ? _value.entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<MapEntity>,
      warps: null == warps
          ? _value.warps
          : warps // ignore: cast_nullable_to_non_nullable
              as List<MapWarp>,
      triggers: null == triggers
          ? _value.triggers
          : triggers // ignore: cast_nullable_to_non_nullable
              as List<MapTrigger>,
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
      String version,
      String tilesetId,
      List<MapLayerData> layers,
      List<MapEntity> entities,
      List<MapWarp> warps,
      List<MapTrigger> triggers,
      Map<String, dynamic> properties});

  @override
  $GridSizeCopyWith<$Res> get size;
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
    Object? warps = null,
    Object? triggers = null,
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
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      layers: null == layers
          ? _value._layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<MapLayerData>,
      entities: null == entities
          ? _value._entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<MapEntity>,
      warps: null == warps
          ? _value._warps
          : warps // ignore: cast_nullable_to_non_nullable
              as List<MapWarp>,
      triggers: null == triggers
          ? _value._triggers
          : triggers // ignore: cast_nullable_to_non_nullable
              as List<MapTrigger>,
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
      this.version = 'v1',
      required this.tilesetId,
      final List<MapLayerData> layers = const [],
      final List<MapEntity> entities = const [],
      final List<MapWarp> warps = const [],
      final List<MapTrigger> triggers = const [],
      final Map<String, dynamic> properties = const {}})
      : _layers = layers,
        _entities = entities,
        _warps = warps,
        _triggers = triggers,
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
  final String version;
  @override
  final String tilesetId;
  final List<MapLayerData> _layers;
  @override
  @JsonKey()
  List<MapLayerData> get layers {
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
    return 'MapData(id: $id, name: $name, size: $size, version: $version, tilesetId: $tilesetId, layers: $layers, entities: $entities, warps: $warps, triggers: $triggers, properties: $properties)';
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
            const DeepCollectionEquality().equals(other._warps, _warps) &&
            const DeepCollectionEquality().equals(other._triggers, _triggers) &&
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
      const DeepCollectionEquality().hash(_warps),
      const DeepCollectionEquality().hash(_triggers),
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
      final String version,
      required final String tilesetId,
      final List<MapLayerData> layers,
      final List<MapEntity> entities,
      final List<MapWarp> warps,
      final List<MapTrigger> triggers,
      final Map<String, dynamic> properties}) = _$MapDataImpl;

  factory _MapData.fromJson(Map<String, dynamic> json) = _$MapDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  GridSize get size;
  @override
  String get version;
  @override
  String get tilesetId;
  @override
  List<MapLayerData> get layers;
  @override
  List<MapEntity> get entities;
  @override
  List<MapWarp> get warps;
  @override
  List<MapTrigger> get triggers;
  @override
  Map<String, dynamic> get properties;

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapDataImplCopyWith<_$MapDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapLayerData _$MapLayerDataFromJson(Map<String, dynamic> json) {
  return _MapLayerData.fromJson(json);
}

/// @nodoc
mixin _$MapLayerData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  LayerType get type => throw _privateConstructorUsedError;
  bool get isVisible => throw _privateConstructorUsedError;
  double get opacity => throw _privateConstructorUsedError; // For Tile Layers
  List<int> get tiles => throw _privateConstructorUsedError; // Flattened array
// For Collision Layers
  List<bool> get collisions => throw _privateConstructorUsedError;

  /// Serializes this MapLayerData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapLayerData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapLayerDataCopyWith<MapLayerData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapLayerDataCopyWith<$Res> {
  factory $MapLayerDataCopyWith(
          MapLayerData value, $Res Function(MapLayerData) then) =
      _$MapLayerDataCopyWithImpl<$Res, MapLayerData>;
  @useResult
  $Res call(
      {String id,
      String name,
      LayerType type,
      bool isVisible,
      double opacity,
      List<int> tiles,
      List<bool> collisions});
}

/// @nodoc
class _$MapLayerDataCopyWithImpl<$Res, $Val extends MapLayerData>
    implements $MapLayerDataCopyWith<$Res> {
  _$MapLayerDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapLayerData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? isVisible = null,
    Object? opacity = null,
    Object? tiles = null,
    Object? collisions = null,
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
              as LayerType,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      tiles: null == tiles
          ? _value.tiles
          : tiles // ignore: cast_nullable_to_non_nullable
              as List<int>,
      collisions: null == collisions
          ? _value.collisions
          : collisions // ignore: cast_nullable_to_non_nullable
              as List<bool>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapLayerDataImplCopyWith<$Res>
    implements $MapLayerDataCopyWith<$Res> {
  factory _$$MapLayerDataImplCopyWith(
          _$MapLayerDataImpl value, $Res Function(_$MapLayerDataImpl) then) =
      __$$MapLayerDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      LayerType type,
      bool isVisible,
      double opacity,
      List<int> tiles,
      List<bool> collisions});
}

/// @nodoc
class __$$MapLayerDataImplCopyWithImpl<$Res>
    extends _$MapLayerDataCopyWithImpl<$Res, _$MapLayerDataImpl>
    implements _$$MapLayerDataImplCopyWith<$Res> {
  __$$MapLayerDataImplCopyWithImpl(
      _$MapLayerDataImpl _value, $Res Function(_$MapLayerDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapLayerData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? isVisible = null,
    Object? opacity = null,
    Object? tiles = null,
    Object? collisions = null,
  }) {
    return _then(_$MapLayerDataImpl(
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
              as LayerType,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      tiles: null == tiles
          ? _value._tiles
          : tiles // ignore: cast_nullable_to_non_nullable
              as List<int>,
      collisions: null == collisions
          ? _value._collisions
          : collisions // ignore: cast_nullable_to_non_nullable
              as List<bool>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapLayerDataImpl implements _MapLayerData {
  const _$MapLayerDataImpl(
      {required this.id,
      required this.name,
      required this.type,
      this.isVisible = true,
      this.opacity = 1.0,
      final List<int> tiles = const [],
      final List<bool> collisions = const []})
      : _tiles = tiles,
        _collisions = collisions;

  factory _$MapLayerDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapLayerDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final LayerType type;
  @override
  @JsonKey()
  final bool isVisible;
  @override
  @JsonKey()
  final double opacity;
// For Tile Layers
  final List<int> _tiles;
// For Tile Layers
  @override
  @JsonKey()
  List<int> get tiles {
    if (_tiles is EqualUnmodifiableListView) return _tiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tiles);
  }

// Flattened array
// For Collision Layers
  final List<bool> _collisions;
// Flattened array
// For Collision Layers
  @override
  @JsonKey()
  List<bool> get collisions {
    if (_collisions is EqualUnmodifiableListView) return _collisions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_collisions);
  }

  @override
  String toString() {
    return 'MapLayerData(id: $id, name: $name, type: $type, isVisible: $isVisible, opacity: $opacity, tiles: $tiles, collisions: $collisions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapLayerDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            const DeepCollectionEquality().equals(other._tiles, _tiles) &&
            const DeepCollectionEquality()
                .equals(other._collisions, _collisions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      isVisible,
      opacity,
      const DeepCollectionEquality().hash(_tiles),
      const DeepCollectionEquality().hash(_collisions));

  /// Create a copy of MapLayerData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapLayerDataImplCopyWith<_$MapLayerDataImpl> get copyWith =>
      __$$MapLayerDataImplCopyWithImpl<_$MapLayerDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapLayerDataImplToJson(
      this,
    );
  }
}

abstract class _MapLayerData implements MapLayerData {
  const factory _MapLayerData(
      {required final String id,
      required final String name,
      required final LayerType type,
      final bool isVisible,
      final double opacity,
      final List<int> tiles,
      final List<bool> collisions}) = _$MapLayerDataImpl;

  factory _MapLayerData.fromJson(Map<String, dynamic> json) =
      _$MapLayerDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  LayerType get type;
  @override
  bool get isVisible;
  @override
  double get opacity; // For Tile Layers
  @override
  List<int> get tiles; // Flattened array
// For Collision Layers
  @override
  List<bool> get collisions;

  /// Create a copy of MapLayerData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapLayerDataImplCopyWith<_$MapLayerDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapEntity _$MapEntityFromJson(Map<String, dynamic> json) {
  return _MapEntity.fromJson(json);
}

/// @nodoc
mixin _$MapEntity {
  String get id => throw _privateConstructorUsedError;
  EntityType get type => throw _privateConstructorUsedError;
  GridPos get pos => throw _privateConstructorUsedError;
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

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
      EntityType type,
      GridPos pos,
      Map<String, dynamic> properties});

  $GridPosCopyWith<$Res> get pos;
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
    Object? type = null,
    Object? pos = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EntityType,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
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
      EntityType type,
      GridPos pos,
      Map<String, dynamic> properties});

  @override
  $GridPosCopyWith<$Res> get pos;
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
    Object? type = null,
    Object? pos = null,
    Object? properties = null,
  }) {
    return _then(_$MapEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EntityType,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntityImpl implements _MapEntity {
  const _$MapEntityImpl(
      {required this.id,
      required this.type,
      required this.pos,
      final Map<String, dynamic> properties = const {}})
      : _properties = properties;

  factory _$MapEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEntityImplFromJson(json);

  @override
  final String id;
  @override
  final EntityType type;
  @override
  final GridPos pos;
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
    return 'MapEntity(id: $id, type: $type, pos: $pos, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.pos, pos) || other.pos == pos) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, pos,
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
      required final EntityType type,
      required final GridPos pos,
      final Map<String, dynamic> properties}) = _$MapEntityImpl;

  factory _MapEntity.fromJson(Map<String, dynamic> json) =
      _$MapEntityImpl.fromJson;

  @override
  String get id;
  @override
  EntityType get type;
  @override
  GridPos get pos;
  @override
  Map<String, dynamic> get properties;

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

MapTrigger _$MapTriggerFromJson(Map<String, dynamic> json) {
  return _MapTrigger.fromJson(json);
}

/// @nodoc
mixin _$MapTrigger {
  String get id => throw _privateConstructorUsedError;
  TriggerType get type => throw _privateConstructorUsedError;
  GridPos get pos => throw _privateConstructorUsedError;
  MapRect get zone =>
      throw _privateConstructorUsedError; // Triggers can be zones
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

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
      TriggerType type,
      GridPos pos,
      MapRect zone,
      Map<String, dynamic> properties});

  $GridPosCopyWith<$Res> get pos;
  $MapRectCopyWith<$Res> get zone;
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
    Object? type = null,
    Object? pos = null,
    Object? zone = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TriggerType,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      zone: null == zone
          ? _value.zone
          : zone // ignore: cast_nullable_to_non_nullable
              as MapRect,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get pos {
    return $GridPosCopyWith<$Res>(_value.pos, (value) {
      return _then(_value.copyWith(pos: value) as $Val);
    });
  }

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapRectCopyWith<$Res> get zone {
    return $MapRectCopyWith<$Res>(_value.zone, (value) {
      return _then(_value.copyWith(zone: value) as $Val);
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
      TriggerType type,
      GridPos pos,
      MapRect zone,
      Map<String, dynamic> properties});

  @override
  $GridPosCopyWith<$Res> get pos;
  @override
  $MapRectCopyWith<$Res> get zone;
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
    Object? type = null,
    Object? pos = null,
    Object? zone = null,
    Object? properties = null,
  }) {
    return _then(_$MapTriggerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TriggerType,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      zone: null == zone
          ? _value.zone
          : zone // ignore: cast_nullable_to_non_nullable
              as MapRect,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapTriggerImpl implements _MapTrigger {
  const _$MapTriggerImpl(
      {required this.id,
      required this.type,
      required this.pos,
      required this.zone,
      final Map<String, dynamic> properties = const {}})
      : _properties = properties;

  factory _$MapTriggerImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapTriggerImplFromJson(json);

  @override
  final String id;
  @override
  final TriggerType type;
  @override
  final GridPos pos;
  @override
  final MapRect zone;
// Triggers can be zones
  final Map<String, dynamic> _properties;
// Triggers can be zones
  @override
  @JsonKey()
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'MapTrigger(id: $id, type: $type, pos: $pos, zone: $zone, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapTriggerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.pos, pos) || other.pos == pos) &&
            (identical(other.zone, zone) || other.zone == zone) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, pos, zone,
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
      required final TriggerType type,
      required final GridPos pos,
      required final MapRect zone,
      final Map<String, dynamic> properties}) = _$MapTriggerImpl;

  factory _MapTrigger.fromJson(Map<String, dynamic> json) =
      _$MapTriggerImpl.fromJson;

  @override
  String get id;
  @override
  TriggerType get type;
  @override
  GridPos get pos;
  @override
  MapRect get zone; // Triggers can be zones
  @override
  Map<String, dynamic> get properties;

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapTriggerImplCopyWith<_$MapTriggerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
