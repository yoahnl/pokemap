// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_layer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MapLayer _$MapLayerFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'tile':
      return TileLayer.fromJson(json);
    case 'collision':
      return CollisionLayer.fromJson(json);
    case 'terrain':
      return TerrainLayer.fromJson(json);
    case 'object':
      return ObjectLayer.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'MapLayer',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$MapLayer {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isVisible => throw _privateConstructorUsedError;
  double get opacity => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String name, String? tilesetId,
            bool isVisible, double opacity, List<int> tiles)
        tile,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<bool> collisions)
        collision,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<TerrainType> terrains)
        terrain,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(ObjectLayer value) object,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(ObjectLayer value)? object,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(ObjectLayer value)? object,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this MapLayer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapLayerCopyWith<MapLayer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapLayerCopyWith<$Res> {
  factory $MapLayerCopyWith(MapLayer value, $Res Function(MapLayer) then) =
      _$MapLayerCopyWithImpl<$Res, MapLayer>;
  @useResult
  $Res call({String id, String name, bool isVisible, double opacity});
}

/// @nodoc
class _$MapLayerCopyWithImpl<$Res, $Val extends MapLayer>
    implements $MapLayerCopyWith<$Res> {
  _$MapLayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isVisible = null,
    Object? opacity = null,
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
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TileLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$TileLayerImplCopyWith(
          _$TileLayerImpl value, $Res Function(_$TileLayerImpl) then) =
      __$$TileLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? tilesetId,
      bool isVisible,
      double opacity,
      List<int> tiles});
}

/// @nodoc
class __$$TileLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$TileLayerImpl>
    implements _$$TileLayerImplCopyWith<$Res> {
  __$$TileLayerImplCopyWithImpl(
      _$TileLayerImpl _value, $Res Function(_$TileLayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = freezed,
    Object? isVisible = null,
    Object? opacity = null,
    Object? tiles = null,
  }) {
    return _then(_$TileLayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: freezed == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String?,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TileLayerImpl extends TileLayer {
  const _$TileLayerImpl(
      {required this.id,
      required this.name,
      this.tilesetId,
      this.isVisible = true,
      this.opacity = 1.0,
      final List<int> tiles = const [],
      final String? $type})
      : _tiles = tiles,
        $type = $type ?? 'tile',
        super._();

  factory _$TileLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$TileLayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? tilesetId;
  @override
  @JsonKey()
  final bool isVisible;
  @override
  @JsonKey()
  final double opacity;
  final List<int> _tiles;
  @override
  @JsonKey()
  List<int> get tiles {
    if (_tiles is EqualUnmodifiableListView) return _tiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tiles);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MapLayer.tile(id: $id, name: $name, tilesetId: $tilesetId, isVisible: $isVisible, opacity: $opacity, tiles: $tiles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TileLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            const DeepCollectionEquality().equals(other._tiles, _tiles));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, tilesetId, isVisible,
      opacity, const DeepCollectionEquality().hash(_tiles));

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TileLayerImplCopyWith<_$TileLayerImpl> get copyWith =>
      __$$TileLayerImplCopyWithImpl<_$TileLayerImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String name, String? tilesetId,
            bool isVisible, double opacity, List<int> tiles)
        tile,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<bool> collisions)
        collision,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<TerrainType> terrains)
        terrain,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
  }) {
    return tile(id, name, tilesetId, isVisible, opacity, tiles);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
  }) {
    return tile?.call(id, name, tilesetId, isVisible, opacity, tiles);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    required TResult orElse(),
  }) {
    if (tile != null) {
      return tile(id, name, tilesetId, isVisible, opacity, tiles);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(ObjectLayer value) object,
  }) {
    return tile(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(ObjectLayer value)? object,
  }) {
    return tile?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(ObjectLayer value)? object,
    required TResult orElse(),
  }) {
    if (tile != null) {
      return tile(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TileLayerImplToJson(
      this,
    );
  }
}

abstract class TileLayer extends MapLayer {
  const factory TileLayer(
      {required final String id,
      required final String name,
      final String? tilesetId,
      final bool isVisible,
      final double opacity,
      final List<int> tiles}) = _$TileLayerImpl;
  const TileLayer._() : super._();

  factory TileLayer.fromJson(Map<String, dynamic> json) =
      _$TileLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  String? get tilesetId;
  @override
  bool get isVisible;
  @override
  double get opacity;
  List<int> get tiles;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TileLayerImplCopyWith<_$TileLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CollisionLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$CollisionLayerImplCopyWith(_$CollisionLayerImpl value,
          $Res Function(_$CollisionLayerImpl) then) =
      __$$CollisionLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool isVisible,
      double opacity,
      List<bool> collisions});
}

/// @nodoc
class __$$CollisionLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$CollisionLayerImpl>
    implements _$$CollisionLayerImplCopyWith<$Res> {
  __$$CollisionLayerImplCopyWithImpl(
      _$CollisionLayerImpl _value, $Res Function(_$CollisionLayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isVisible = null,
    Object? opacity = null,
    Object? collisions = null,
  }) {
    return _then(_$CollisionLayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      collisions: null == collisions
          ? _value._collisions
          : collisions // ignore: cast_nullable_to_non_nullable
              as List<bool>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CollisionLayerImpl extends CollisionLayer {
  const _$CollisionLayerImpl(
      {required this.id,
      required this.name,
      this.isVisible = true,
      this.opacity = 1.0,
      final List<bool> collisions = const [],
      final String? $type})
      : _collisions = collisions,
        $type = $type ?? 'collision',
        super._();

  factory _$CollisionLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollisionLayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isVisible;
  @override
  @JsonKey()
  final double opacity;
  final List<bool> _collisions;
  @override
  @JsonKey()
  List<bool> get collisions {
    if (_collisions is EqualUnmodifiableListView) return _collisions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_collisions);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MapLayer.collision(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, collisions: $collisions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollisionLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            const DeepCollectionEquality()
                .equals(other._collisions, _collisions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, isVisible, opacity,
      const DeepCollectionEquality().hash(_collisions));

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollisionLayerImplCopyWith<_$CollisionLayerImpl> get copyWith =>
      __$$CollisionLayerImplCopyWithImpl<_$CollisionLayerImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String name, String? tilesetId,
            bool isVisible, double opacity, List<int> tiles)
        tile,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<bool> collisions)
        collision,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<TerrainType> terrains)
        terrain,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
  }) {
    return collision(id, name, isVisible, opacity, collisions);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
  }) {
    return collision?.call(id, name, isVisible, opacity, collisions);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    required TResult orElse(),
  }) {
    if (collision != null) {
      return collision(id, name, isVisible, opacity, collisions);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(ObjectLayer value) object,
  }) {
    return collision(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(ObjectLayer value)? object,
  }) {
    return collision?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(ObjectLayer value)? object,
    required TResult orElse(),
  }) {
    if (collision != null) {
      return collision(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CollisionLayerImplToJson(
      this,
    );
  }
}

abstract class CollisionLayer extends MapLayer {
  const factory CollisionLayer(
      {required final String id,
      required final String name,
      final bool isVisible,
      final double opacity,
      final List<bool> collisions}) = _$CollisionLayerImpl;
  const CollisionLayer._() : super._();

  factory CollisionLayer.fromJson(Map<String, dynamic> json) =
      _$CollisionLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isVisible;
  @override
  double get opacity;
  List<bool> get collisions;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollisionLayerImplCopyWith<_$CollisionLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TerrainLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$TerrainLayerImplCopyWith(
          _$TerrainLayerImpl value, $Res Function(_$TerrainLayerImpl) then) =
      __$$TerrainLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool isVisible,
      double opacity,
      List<TerrainType> terrains});
}

/// @nodoc
class __$$TerrainLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$TerrainLayerImpl>
    implements _$$TerrainLayerImplCopyWith<$Res> {
  __$$TerrainLayerImplCopyWithImpl(
      _$TerrainLayerImpl _value, $Res Function(_$TerrainLayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isVisible = null,
    Object? opacity = null,
    Object? terrains = null,
  }) {
    return _then(_$TerrainLayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      terrains: null == terrains
          ? _value._terrains
          : terrains // ignore: cast_nullable_to_non_nullable
              as List<TerrainType>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TerrainLayerImpl extends TerrainLayer {
  const _$TerrainLayerImpl(
      {required this.id,
      required this.name,
      this.isVisible = true,
      this.opacity = 1.0,
      final List<TerrainType> terrains = const [],
      final String? $type})
      : _terrains = terrains,
        $type = $type ?? 'terrain',
        super._();

  factory _$TerrainLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$TerrainLayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isVisible;
  @override
  @JsonKey()
  final double opacity;
  final List<TerrainType> _terrains;
  @override
  @JsonKey()
  List<TerrainType> get terrains {
    if (_terrains is EqualUnmodifiableListView) return _terrains;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_terrains);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MapLayer.terrain(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, terrains: $terrains)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerrainLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            const DeepCollectionEquality().equals(other._terrains, _terrains));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, isVisible, opacity,
      const DeepCollectionEquality().hash(_terrains));

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerrainLayerImplCopyWith<_$TerrainLayerImpl> get copyWith =>
      __$$TerrainLayerImplCopyWithImpl<_$TerrainLayerImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String name, String? tilesetId,
            bool isVisible, double opacity, List<int> tiles)
        tile,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<bool> collisions)
        collision,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<TerrainType> terrains)
        terrain,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
  }) {
    return terrain(id, name, isVisible, opacity, terrains);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
  }) {
    return terrain?.call(id, name, isVisible, opacity, terrains);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    required TResult orElse(),
  }) {
    if (terrain != null) {
      return terrain(id, name, isVisible, opacity, terrains);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(ObjectLayer value) object,
  }) {
    return terrain(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(ObjectLayer value)? object,
  }) {
    return terrain?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(ObjectLayer value)? object,
    required TResult orElse(),
  }) {
    if (terrain != null) {
      return terrain(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TerrainLayerImplToJson(
      this,
    );
  }
}

abstract class TerrainLayer extends MapLayer {
  const factory TerrainLayer(
      {required final String id,
      required final String name,
      final bool isVisible,
      final double opacity,
      final List<TerrainType> terrains}) = _$TerrainLayerImpl;
  const TerrainLayer._() : super._();

  factory TerrainLayer.fromJson(Map<String, dynamic> json) =
      _$TerrainLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isVisible;
  @override
  double get opacity;
  List<TerrainType> get terrains;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerrainLayerImplCopyWith<_$TerrainLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ObjectLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$ObjectLayerImplCopyWith(
          _$ObjectLayerImpl value, $Res Function(_$ObjectLayerImpl) then) =
      __$$ObjectLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, bool isVisible, double opacity});
}

/// @nodoc
class __$$ObjectLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$ObjectLayerImpl>
    implements _$$ObjectLayerImplCopyWith<$Res> {
  __$$ObjectLayerImplCopyWithImpl(
      _$ObjectLayerImpl _value, $Res Function(_$ObjectLayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isVisible = null,
    Object? opacity = null,
  }) {
    return _then(_$ObjectLayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ObjectLayerImpl extends ObjectLayer {
  const _$ObjectLayerImpl(
      {required this.id,
      required this.name,
      this.isVisible = true,
      this.opacity = 1.0,
      final String? $type})
      : $type = $type ?? 'object',
        super._();

  factory _$ObjectLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$ObjectLayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isVisible;
  @override
  @JsonKey()
  final double opacity;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MapLayer.object(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ObjectLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, isVisible, opacity);

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ObjectLayerImplCopyWith<_$ObjectLayerImpl> get copyWith =>
      __$$ObjectLayerImplCopyWithImpl<_$ObjectLayerImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String name, String? tilesetId,
            bool isVisible, double opacity, List<int> tiles)
        tile,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<bool> collisions)
        collision,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<TerrainType> terrains)
        terrain,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
  }) {
    return object(id, name, isVisible, opacity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult? Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
  }) {
    return object?.call(id, name, isVisible, opacity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String name, String? tilesetId, bool isVisible,
            double opacity, List<int> tiles)?
        tile,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<bool> collisions)?
        collision,
    TResult Function(String id, String name, bool isVisible, double opacity,
            List<TerrainType> terrains)?
        terrain,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    required TResult orElse(),
  }) {
    if (object != null) {
      return object(id, name, isVisible, opacity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(ObjectLayer value) object,
  }) {
    return object(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(ObjectLayer value)? object,
  }) {
    return object?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(ObjectLayer value)? object,
    required TResult orElse(),
  }) {
    if (object != null) {
      return object(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ObjectLayerImplToJson(
      this,
    );
  }
}

abstract class ObjectLayer extends MapLayer {
  const factory ObjectLayer(
      {required final String id,
      required final String name,
      final bool isVisible,
      final double opacity}) = _$ObjectLayerImpl;
  const ObjectLayer._() : super._();

  factory ObjectLayer.fromJson(Map<String, dynamic> json) =
      _$ObjectLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isVisible;
  @override
  double get opacity;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ObjectLayerImplCopyWith<_$ObjectLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
