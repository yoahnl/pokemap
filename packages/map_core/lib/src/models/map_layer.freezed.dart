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

SurfaceCellPlacement _$SurfaceCellPlacementFromJson(Map<String, dynamic> json) {
  return _SurfaceCellPlacement.fromJson(json);
}

/// @nodoc
mixin _$SurfaceCellPlacement {
  int get x => throw _privateConstructorUsedError;
  int get y => throw _privateConstructorUsedError;
  String get surfacePresetId => throw _privateConstructorUsedError;

  /// Serializes this SurfaceCellPlacement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SurfaceCellPlacement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SurfaceCellPlacementCopyWith<SurfaceCellPlacement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SurfaceCellPlacementCopyWith<$Res> {
  factory $SurfaceCellPlacementCopyWith(SurfaceCellPlacement value,
          $Res Function(SurfaceCellPlacement) then) =
      _$SurfaceCellPlacementCopyWithImpl<$Res, SurfaceCellPlacement>;
  @useResult
  $Res call({int x, int y, String surfacePresetId});
}

/// @nodoc
class _$SurfaceCellPlacementCopyWithImpl<$Res,
        $Val extends SurfaceCellPlacement>
    implements $SurfaceCellPlacementCopyWith<$Res> {
  _$SurfaceCellPlacementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SurfaceCellPlacement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? surfacePresetId = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
      surfacePresetId: null == surfacePresetId
          ? _value.surfacePresetId
          : surfacePresetId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SurfaceCellPlacementImplCopyWith<$Res>
    implements $SurfaceCellPlacementCopyWith<$Res> {
  factory _$$SurfaceCellPlacementImplCopyWith(_$SurfaceCellPlacementImpl value,
          $Res Function(_$SurfaceCellPlacementImpl) then) =
      __$$SurfaceCellPlacementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int x, int y, String surfacePresetId});
}

/// @nodoc
class __$$SurfaceCellPlacementImplCopyWithImpl<$Res>
    extends _$SurfaceCellPlacementCopyWithImpl<$Res, _$SurfaceCellPlacementImpl>
    implements _$$SurfaceCellPlacementImplCopyWith<$Res> {
  __$$SurfaceCellPlacementImplCopyWithImpl(_$SurfaceCellPlacementImpl _value,
      $Res Function(_$SurfaceCellPlacementImpl) _then)
      : super(_value, _then);

  /// Create a copy of SurfaceCellPlacement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? surfacePresetId = null,
  }) {
    return _then(_$SurfaceCellPlacementImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
      surfacePresetId: null == surfacePresetId
          ? _value.surfacePresetId
          : surfacePresetId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SurfaceCellPlacementImpl implements _SurfaceCellPlacement {
  const _$SurfaceCellPlacementImpl(
      {required this.x, required this.y, required this.surfacePresetId});

  factory _$SurfaceCellPlacementImpl.fromJson(Map<String, dynamic> json) =>
      _$$SurfaceCellPlacementImplFromJson(json);

  @override
  final int x;
  @override
  final int y;
  @override
  final String surfacePresetId;

  @override
  String toString() {
    return 'SurfaceCellPlacement(x: $x, y: $y, surfacePresetId: $surfacePresetId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SurfaceCellPlacementImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.surfacePresetId, surfacePresetId) ||
                other.surfacePresetId == surfacePresetId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, surfacePresetId);

  /// Create a copy of SurfaceCellPlacement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SurfaceCellPlacementImplCopyWith<_$SurfaceCellPlacementImpl>
      get copyWith =>
          __$$SurfaceCellPlacementImplCopyWithImpl<_$SurfaceCellPlacementImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SurfaceCellPlacementImplToJson(
      this,
    );
  }
}

abstract class _SurfaceCellPlacement implements SurfaceCellPlacement {
  const factory _SurfaceCellPlacement(
      {required final int x,
      required final int y,
      required final String surfacePresetId}) = _$SurfaceCellPlacementImpl;

  factory _SurfaceCellPlacement.fromJson(Map<String, dynamic> json) =
      _$SurfaceCellPlacementImpl.fromJson;

  @override
  int get x;
  @override
  int get y;
  @override
  String get surfacePresetId;

  /// Create a copy of SurfaceCellPlacement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SurfaceCellPlacementImplCopyWith<_$SurfaceCellPlacementImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MapLayer _$MapLayerFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'tile':
      return TileLayer.fromJson(json);
    case 'collision':
      return CollisionLayer.fromJson(json);
    case 'terrain':
      return TerrainLayer.fromJson(json);
    case 'path':
      return PathLayer.fromJson(json);
    case 'surface':
      return SurfaceLayer.fromJson(json);
    case 'object':
      return ObjectLayer.fromJson(json);
    case 'environment':
      return EnvironmentLayer.fromJson(json);

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
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)
        path,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)
        surface,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)
        environment,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(PathLayer value) path,
    required TResult Function(SurfaceLayer value) surface,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(PathLayer value)? path,
    TResult? Function(SurfaceLayer value)? surface,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(PathLayer value)? path,
    TResult Function(SurfaceLayer value)? surface,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
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
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)
        path,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)
        surface,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)
        environment,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    required TResult Function(PathLayer value) path,
    required TResult Function(SurfaceLayer value) surface,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
  }) {
    return tile(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(PathLayer value)? path,
    TResult? Function(SurfaceLayer value)? surface,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
  }) {
    return tile?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(PathLayer value)? path,
    TResult Function(SurfaceLayer value)? surface,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
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
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)
        path,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)
        surface,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)
        environment,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    required TResult Function(PathLayer value) path,
    required TResult Function(SurfaceLayer value) surface,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
  }) {
    return collision(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(PathLayer value)? path,
    TResult? Function(SurfaceLayer value)? surface,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
  }) {
    return collision?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(PathLayer value)? path,
    TResult Function(SurfaceLayer value)? surface,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
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
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)
        path,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)
        surface,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)
        environment,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    required TResult Function(PathLayer value) path,
    required TResult Function(SurfaceLayer value) surface,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
  }) {
    return terrain(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(PathLayer value)? path,
    TResult? Function(SurfaceLayer value)? surface,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
  }) {
    return terrain?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(PathLayer value)? path,
    TResult Function(SurfaceLayer value)? surface,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
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
abstract class _$$PathLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$PathLayerImplCopyWith(
          _$PathLayerImpl value, $Res Function(_$PathLayerImpl) then) =
      __$$PathLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool isVisible,
      double opacity,
      String presetId,
      List<bool> cells,
      Map<String, String> properties,
      PathAnimationMode animationMode,
      List<PathAnimationTriggerRule> animationTriggers});
}

/// @nodoc
class __$$PathLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$PathLayerImpl>
    implements _$$PathLayerImplCopyWith<$Res> {
  __$$PathLayerImplCopyWithImpl(
      _$PathLayerImpl _value, $Res Function(_$PathLayerImpl) _then)
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
    Object? presetId = null,
    Object? cells = null,
    Object? properties = null,
    Object? animationMode = null,
    Object? animationTriggers = null,
  }) {
    return _then(_$PathLayerImpl(
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
      presetId: null == presetId
          ? _value.presetId
          : presetId // ignore: cast_nullable_to_non_nullable
              as String,
      cells: null == cells
          ? _value._cells
          : cells // ignore: cast_nullable_to_non_nullable
              as List<bool>,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      animationMode: null == animationMode
          ? _value.animationMode
          : animationMode // ignore: cast_nullable_to_non_nullable
              as PathAnimationMode,
      animationTriggers: null == animationTriggers
          ? _value._animationTriggers
          : animationTriggers // ignore: cast_nullable_to_non_nullable
              as List<PathAnimationTriggerRule>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PathLayerImpl extends PathLayer {
  const _$PathLayerImpl(
      {required this.id,
      required this.name,
      this.isVisible = true,
      this.opacity = 1.0,
      this.presetId = '',
      final List<bool> cells = const [],
      final Map<String, String> properties = const <String, String>{},
      this.animationMode = PathAnimationMode.triggered,
      final List<PathAnimationTriggerRule> animationTriggers = const [],
      final String? $type})
      : _cells = cells,
        _properties = properties,
        _animationTriggers = animationTriggers,
        $type = $type ?? 'path',
        super._();

  factory _$PathLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PathLayerImplFromJson(json);

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
  @override
  @JsonKey()
  final String presetId;
  final List<bool> _cells;
  @override
  @JsonKey()
  List<bool> get cells {
    if (_cells is EqualUnmodifiableListView) return _cells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cells);
  }

  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  @JsonKey()
  final PathAnimationMode animationMode;
  final List<PathAnimationTriggerRule> _animationTriggers;
  @override
  @JsonKey()
  List<PathAnimationTriggerRule> get animationTriggers {
    if (_animationTriggers is EqualUnmodifiableListView)
      return _animationTriggers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_animationTriggers);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MapLayer.path(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, presetId: $presetId, cells: $cells, properties: $properties, animationMode: $animationMode, animationTriggers: $animationTriggers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PathLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            (identical(other.presetId, presetId) ||
                other.presetId == presetId) &&
            const DeepCollectionEquality().equals(other._cells, _cells) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties) &&
            (identical(other.animationMode, animationMode) ||
                other.animationMode == animationMode) &&
            const DeepCollectionEquality()
                .equals(other._animationTriggers, _animationTriggers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      isVisible,
      opacity,
      presetId,
      const DeepCollectionEquality().hash(_cells),
      const DeepCollectionEquality().hash(_properties),
      animationMode,
      const DeepCollectionEquality().hash(_animationTriggers));

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PathLayerImplCopyWith<_$PathLayerImpl> get copyWith =>
      __$$PathLayerImplCopyWithImpl<_$PathLayerImpl>(this, _$identity);

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
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)
        path,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)
        surface,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)
        environment,
  }) {
    return path(id, name, isVisible, opacity, presetId, cells, properties,
        animationMode, animationTriggers);
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
  }) {
    return path?.call(id, name, isVisible, opacity, presetId, cells, properties,
        animationMode, animationTriggers);
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
    required TResult orElse(),
  }) {
    if (path != null) {
      return path(id, name, isVisible, opacity, presetId, cells, properties,
          animationMode, animationTriggers);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(PathLayer value) path,
    required TResult Function(SurfaceLayer value) surface,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
  }) {
    return path(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(PathLayer value)? path,
    TResult? Function(SurfaceLayer value)? surface,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
  }) {
    return path?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(PathLayer value)? path,
    TResult Function(SurfaceLayer value)? surface,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    required TResult orElse(),
  }) {
    if (path != null) {
      return path(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PathLayerImplToJson(
      this,
    );
  }
}

abstract class PathLayer extends MapLayer {
  const factory PathLayer(
          {required final String id,
          required final String name,
          final bool isVisible,
          final double opacity,
          final String presetId,
          final List<bool> cells,
          final Map<String, String> properties,
          final PathAnimationMode animationMode,
          final List<PathAnimationTriggerRule> animationTriggers}) =
      _$PathLayerImpl;
  const PathLayer._() : super._();

  factory PathLayer.fromJson(Map<String, dynamic> json) =
      _$PathLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isVisible;
  @override
  double get opacity;
  String get presetId;
  List<bool> get cells;
  Map<String, String> get properties;
  PathAnimationMode get animationMode;
  List<PathAnimationTriggerRule> get animationTriggers;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PathLayerImplCopyWith<_$PathLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SurfaceLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$SurfaceLayerImplCopyWith(
          _$SurfaceLayerImpl value, $Res Function(_$SurfaceLayerImpl) then) =
      __$$SurfaceLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool isVisible,
      double opacity,
      List<SurfaceCellPlacement> placements,
      Map<String, String> properties});
}

/// @nodoc
class __$$SurfaceLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$SurfaceLayerImpl>
    implements _$$SurfaceLayerImplCopyWith<$Res> {
  __$$SurfaceLayerImplCopyWithImpl(
      _$SurfaceLayerImpl _value, $Res Function(_$SurfaceLayerImpl) _then)
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
    Object? placements = null,
    Object? properties = null,
  }) {
    return _then(_$SurfaceLayerImpl(
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
      placements: null == placements
          ? _value._placements
          : placements // ignore: cast_nullable_to_non_nullable
              as List<SurfaceCellPlacement>,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SurfaceLayerImpl extends SurfaceLayer {
  const _$SurfaceLayerImpl(
      {required this.id,
      required this.name,
      this.isVisible = true,
      this.opacity = 1.0,
      final List<SurfaceCellPlacement> placements = const [],
      final Map<String, String> properties = const <String, String>{},
      final String? $type})
      : _placements = placements,
        _properties = properties,
        $type = $type ?? 'surface',
        super._();

  factory _$SurfaceLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$SurfaceLayerImplFromJson(json);

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
  final List<SurfaceCellPlacement> _placements;
  @override
  @JsonKey()
  List<SurfaceCellPlacement> get placements {
    if (_placements is EqualUnmodifiableListView) return _placements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_placements);
  }

  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MapLayer.surface(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, placements: $placements, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SurfaceLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            const DeepCollectionEquality()
                .equals(other._placements, _placements) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      isVisible,
      opacity,
      const DeepCollectionEquality().hash(_placements),
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SurfaceLayerImplCopyWith<_$SurfaceLayerImpl> get copyWith =>
      __$$SurfaceLayerImplCopyWithImpl<_$SurfaceLayerImpl>(this, _$identity);

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
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)
        path,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)
        surface,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)
        environment,
  }) {
    return surface(id, name, isVisible, opacity, placements, properties);
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
  }) {
    return surface?.call(id, name, isVisible, opacity, placements, properties);
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
    required TResult orElse(),
  }) {
    if (surface != null) {
      return surface(id, name, isVisible, opacity, placements, properties);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(PathLayer value) path,
    required TResult Function(SurfaceLayer value) surface,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
  }) {
    return surface(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(PathLayer value)? path,
    TResult? Function(SurfaceLayer value)? surface,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
  }) {
    return surface?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(PathLayer value)? path,
    TResult Function(SurfaceLayer value)? surface,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    required TResult orElse(),
  }) {
    if (surface != null) {
      return surface(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SurfaceLayerImplToJson(
      this,
    );
  }
}

abstract class SurfaceLayer extends MapLayer {
  const factory SurfaceLayer(
      {required final String id,
      required final String name,
      final bool isVisible,
      final double opacity,
      final List<SurfaceCellPlacement> placements,
      final Map<String, String> properties}) = _$SurfaceLayerImpl;
  const SurfaceLayer._() : super._();

  factory SurfaceLayer.fromJson(Map<String, dynamic> json) =
      _$SurfaceLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isVisible;
  @override
  double get opacity;
  List<SurfaceCellPlacement> get placements;
  Map<String, String> get properties;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SurfaceLayerImplCopyWith<_$SurfaceLayerImpl> get copyWith =>
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
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)
        path,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)
        surface,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)
        environment,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
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
    required TResult Function(PathLayer value) path,
    required TResult Function(SurfaceLayer value) surface,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
  }) {
    return object(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(PathLayer value)? path,
    TResult? Function(SurfaceLayer value)? surface,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
  }) {
    return object?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(PathLayer value)? path,
    TResult Function(SurfaceLayer value)? surface,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
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

/// @nodoc
abstract class _$$EnvironmentLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$EnvironmentLayerImplCopyWith(_$EnvironmentLayerImpl value,
          $Res Function(_$EnvironmentLayerImpl) then) =
      __$$EnvironmentLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool isVisible,
      double opacity,
      @JsonKey(
          fromJson: decodeEnvironmentLayerContent,
          toJson: encodeEnvironmentLayerContent)
      EnvironmentLayerContent content,
      Map<String, String> properties});
}

/// @nodoc
class __$$EnvironmentLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$EnvironmentLayerImpl>
    implements _$$EnvironmentLayerImplCopyWith<$Res> {
  __$$EnvironmentLayerImplCopyWithImpl(_$EnvironmentLayerImpl _value,
      $Res Function(_$EnvironmentLayerImpl) _then)
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
    Object? content = null,
    Object? properties = null,
  }) {
    return _then(_$EnvironmentLayerImpl(
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as EnvironmentLayerContent,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$EnvironmentLayerImpl extends EnvironmentLayer {
  const _$EnvironmentLayerImpl(
      {required this.id,
      required this.name,
      this.isVisible = true,
      this.opacity = 1.0,
      @JsonKey(
          fromJson: decodeEnvironmentLayerContent,
          toJson: encodeEnvironmentLayerContent)
      this.content = EnvironmentLayerContent.emptyContent,
      final Map<String, String> properties = const <String, String>{},
      final String? $type})
      : _properties = properties,
        $type = $type ?? 'environment',
        super._();

  factory _$EnvironmentLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnvironmentLayerImplFromJson(json);

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
  @override
  @JsonKey(
      fromJson: decodeEnvironmentLayerContent,
      toJson: encodeEnvironmentLayerContent)
  final EnvironmentLayerContent content;
  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MapLayer.environment(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, content: $content, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnvironmentLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, isVisible, opacity,
      content, const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnvironmentLayerImplCopyWith<_$EnvironmentLayerImpl> get copyWith =>
      __$$EnvironmentLayerImplCopyWithImpl<_$EnvironmentLayerImpl>(
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
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)
        path,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)
        surface,
    required TResult Function(
            String id, String name, bool isVisible, double opacity)
        object,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)
        environment,
  }) {
    return environment(id, name, isVisible, opacity, content, properties);
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult? Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
  }) {
    return environment?.call(id, name, isVisible, opacity, content, properties);
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            List<bool> cells,
            Map<String, String> properties,
            PathAnimationMode animationMode,
            List<PathAnimationTriggerRule> animationTriggers)?
        path,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            List<SurfaceCellPlacement> placements,
            Map<String, String> properties)?
        surface,
    TResult Function(String id, String name, bool isVisible, double opacity)?
        object,
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                fromJson: decodeEnvironmentLayerContent,
                toJson: encodeEnvironmentLayerContent)
            EnvironmentLayerContent content,
            Map<String, String> properties)?
        environment,
    required TResult orElse(),
  }) {
    if (environment != null) {
      return environment(id, name, isVisible, opacity, content, properties);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(TerrainLayer value) terrain,
    required TResult Function(PathLayer value) path,
    required TResult Function(SurfaceLayer value) surface,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
  }) {
    return environment(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(TerrainLayer value)? terrain,
    TResult? Function(PathLayer value)? path,
    TResult? Function(SurfaceLayer value)? surface,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
  }) {
    return environment?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(TerrainLayer value)? terrain,
    TResult Function(PathLayer value)? path,
    TResult Function(SurfaceLayer value)? surface,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    required TResult orElse(),
  }) {
    if (environment != null) {
      return environment(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$EnvironmentLayerImplToJson(
      this,
    );
  }
}

abstract class EnvironmentLayer extends MapLayer {
  const factory EnvironmentLayer(
      {required final String id,
      required final String name,
      final bool isVisible,
      final double opacity,
      @JsonKey(
          fromJson: decodeEnvironmentLayerContent,
          toJson: encodeEnvironmentLayerContent)
      final EnvironmentLayerContent content,
      final Map<String, String> properties}) = _$EnvironmentLayerImpl;
  const EnvironmentLayer._() : super._();

  factory EnvironmentLayer.fromJson(Map<String, dynamic> json) =
      _$EnvironmentLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isVisible;
  @override
  double get opacity;
  @JsonKey(
      fromJson: decodeEnvironmentLayerContent,
      toJson: encodeEnvironmentLayerContent)
  EnvironmentLayerContent get content;
  Map<String, String> get properties;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnvironmentLayerImplCopyWith<_$EnvironmentLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
