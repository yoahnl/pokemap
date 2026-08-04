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
    case 'smart_tile':
      return SmartTileLayer.fromJson(json);
    case 'object':
      return ObjectLayer.fromJson(json);
    case 'environment':
      return EnvironmentLayer.fromJson(json);
    case 'border':
      return BorderLayer.fromJson(json);

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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)
        smartTile,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)
        border,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(SmartTileLayer value) smartTile,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
    required TResult Function(BorderLayer value) border,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(SmartTileLayer value)? smartTile,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
    TResult? Function(BorderLayer value)? border,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(SmartTileLayer value)? smartTile,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    TResult Function(BorderLayer value)? border,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)
        smartTile,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)
        border,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    required TResult Function(SmartTileLayer value) smartTile,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
    required TResult Function(BorderLayer value) border,
  }) {
    return tile(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(SmartTileLayer value)? smartTile,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
    TResult? Function(BorderLayer value)? border,
  }) {
    return tile?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(SmartTileLayer value)? smartTile,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    TResult Function(BorderLayer value)? border,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)
        smartTile,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)
        border,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    required TResult Function(SmartTileLayer value) smartTile,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
    required TResult Function(BorderLayer value) border,
  }) {
    return collision(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(SmartTileLayer value)? smartTile,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
    TResult? Function(BorderLayer value)? border,
  }) {
    return collision?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(SmartTileLayer value)? smartTile,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    TResult Function(BorderLayer value)? border,
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
abstract class _$$SmartTileLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$SmartTileLayerImplCopyWith(_$SmartTileLayerImpl value,
          $Res Function(_$SmartTileLayerImpl) then) =
      __$$SmartTileLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool isVisible,
      double opacity,
      String presetId,
      SmartTileUsage usage,
      List<String> materialPalette,
      SmartTileField field,
      List<SmartTilePatternStroke> patternStrokes,
      int layerSeed,
      Map<String, String> properties});

  $SmartTileFieldCopyWith<$Res> get field;
}

/// @nodoc
class __$$SmartTileLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$SmartTileLayerImpl>
    implements _$$SmartTileLayerImplCopyWith<$Res> {
  __$$SmartTileLayerImplCopyWithImpl(
      _$SmartTileLayerImpl _value, $Res Function(_$SmartTileLayerImpl) _then)
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
    Object? usage = null,
    Object? materialPalette = null,
    Object? field = null,
    Object? patternStrokes = null,
    Object? layerSeed = null,
    Object? properties = null,
  }) {
    return _then(_$SmartTileLayerImpl(
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
      usage: null == usage
          ? _value.usage
          : usage // ignore: cast_nullable_to_non_nullable
              as SmartTileUsage,
      materialPalette: null == materialPalette
          ? _value._materialPalette
          : materialPalette // ignore: cast_nullable_to_non_nullable
              as List<String>,
      field: null == field
          ? _value.field
          : field // ignore: cast_nullable_to_non_nullable
              as SmartTileField,
      patternStrokes: null == patternStrokes
          ? _value._patternStrokes
          : patternStrokes // ignore: cast_nullable_to_non_nullable
              as List<SmartTilePatternStroke>,
      layerSeed: null == layerSeed
          ? _value.layerSeed
          : layerSeed // ignore: cast_nullable_to_non_nullable
              as int,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartTileFieldCopyWith<$Res> get field {
    return $SmartTileFieldCopyWith<$Res>(_value.field, (value) {
      return _then(_value.copyWith(field: value));
    });
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileLayerImpl extends SmartTileLayer {
  const _$SmartTileLayerImpl(
      {required this.id,
      required this.name,
      this.isVisible = true,
      this.opacity = 1.0,
      required this.presetId,
      required this.usage,
      final List<String> materialPalette = const <String>[''],
      required this.field,
      final List<SmartTilePatternStroke> patternStrokes =
          const <SmartTilePatternStroke>[],
      this.layerSeed = 0,
      final Map<String, String> properties = const <String, String>{},
      final String? $type})
      : _materialPalette = materialPalette,
        _patternStrokes = patternStrokes,
        _properties = properties,
        $type = $type ?? 'smart_tile',
        super._();

  factory _$SmartTileLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileLayerImplFromJson(json);

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
  final String presetId;
  @override
  final SmartTileUsage usage;
  final List<String> _materialPalette;
  @override
  @JsonKey()
  List<String> get materialPalette {
    if (_materialPalette is EqualUnmodifiableListView) return _materialPalette;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_materialPalette);
  }

  @override
  final SmartTileField field;
  final List<SmartTilePatternStroke> _patternStrokes;
  @override
  @JsonKey()
  List<SmartTilePatternStroke> get patternStrokes {
    if (_patternStrokes is EqualUnmodifiableListView) return _patternStrokes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_patternStrokes);
  }

  @override
  @JsonKey()
  final int layerSeed;
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
    return 'MapLayer.smartTile(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, presetId: $presetId, usage: $usage, materialPalette: $materialPalette, field: $field, patternStrokes: $patternStrokes, layerSeed: $layerSeed, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            (identical(other.presetId, presetId) ||
                other.presetId == presetId) &&
            (identical(other.usage, usage) || other.usage == usage) &&
            const DeepCollectionEquality()
                .equals(other._materialPalette, _materialPalette) &&
            (identical(other.field, field) || other.field == field) &&
            const DeepCollectionEquality()
                .equals(other._patternStrokes, _patternStrokes) &&
            (identical(other.layerSeed, layerSeed) ||
                other.layerSeed == layerSeed) &&
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
      presetId,
      usage,
      const DeepCollectionEquality().hash(_materialPalette),
      field,
      const DeepCollectionEquality().hash(_patternStrokes),
      layerSeed,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileLayerImplCopyWith<_$SmartTileLayerImpl> get copyWith =>
      __$$SmartTileLayerImplCopyWithImpl<_$SmartTileLayerImpl>(
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)
        smartTile,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)
        border,
  }) {
    return smartTile(id, name, isVisible, opacity, presetId, usage,
        materialPalette, field, patternStrokes, layerSeed, properties);
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
  }) {
    return smartTile?.call(id, name, isVisible, opacity, presetId, usage,
        materialPalette, field, patternStrokes, layerSeed, properties);
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
    required TResult orElse(),
  }) {
    if (smartTile != null) {
      return smartTile(id, name, isVisible, opacity, presetId, usage,
          materialPalette, field, patternStrokes, layerSeed, properties);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(SmartTileLayer value) smartTile,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
    required TResult Function(BorderLayer value) border,
  }) {
    return smartTile(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(SmartTileLayer value)? smartTile,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
    TResult? Function(BorderLayer value)? border,
  }) {
    return smartTile?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(SmartTileLayer value)? smartTile,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    TResult Function(BorderLayer value)? border,
    required TResult orElse(),
  }) {
    if (smartTile != null) {
      return smartTile(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileLayerImplToJson(
      this,
    );
  }
}

abstract class SmartTileLayer extends MapLayer {
  const factory SmartTileLayer(
      {required final String id,
      required final String name,
      final bool isVisible,
      final double opacity,
      required final String presetId,
      required final SmartTileUsage usage,
      final List<String> materialPalette,
      required final SmartTileField field,
      final List<SmartTilePatternStroke> patternStrokes,
      final int layerSeed,
      final Map<String, String> properties}) = _$SmartTileLayerImpl;
  const SmartTileLayer._() : super._();

  factory SmartTileLayer.fromJson(Map<String, dynamic> json) =
      _$SmartTileLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isVisible;
  @override
  double get opacity;
  String get presetId;
  SmartTileUsage get usage;
  List<String> get materialPalette;
  SmartTileField get field;
  List<SmartTilePatternStroke> get patternStrokes;
  int get layerSeed;
  Map<String, String> get properties;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileLayerImplCopyWith<_$SmartTileLayerImpl> get copyWith =>
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)
        smartTile,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)
        border,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    required TResult Function(SmartTileLayer value) smartTile,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
    required TResult Function(BorderLayer value) border,
  }) {
    return object(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(SmartTileLayer value)? smartTile,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
    TResult? Function(BorderLayer value)? border,
  }) {
    return object?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(SmartTileLayer value)? smartTile,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    TResult Function(BorderLayer value)? border,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)
        smartTile,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)
        border,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
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
    required TResult Function(SmartTileLayer value) smartTile,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
    required TResult Function(BorderLayer value) border,
  }) {
    return environment(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(SmartTileLayer value)? smartTile,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
    TResult? Function(BorderLayer value)? border,
  }) {
    return environment?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(SmartTileLayer value)? smartTile,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    TResult Function(BorderLayer value)? border,
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

/// @nodoc
abstract class _$$BorderLayerImplCopyWith<$Res>
    implements $MapLayerCopyWith<$Res> {
  factory _$$BorderLayerImplCopyWith(
          _$BorderLayerImpl value, $Res Function(_$BorderLayerImpl) then) =
      __$$BorderLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool isVisible,
      double opacity,
      @JsonKey(
          readValue: _readBorderLayerContent,
          fromJson: _borderLayerContentFromJson,
          toJson: _borderLayerContentToJson)
      BorderLayerContent content,
      Map<String, String> properties});
}

/// @nodoc
class __$$BorderLayerImplCopyWithImpl<$Res>
    extends _$MapLayerCopyWithImpl<$Res, _$BorderLayerImpl>
    implements _$$BorderLayerImplCopyWith<$Res> {
  __$$BorderLayerImplCopyWithImpl(
      _$BorderLayerImpl _value, $Res Function(_$BorderLayerImpl) _then)
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
    return _then(_$BorderLayerImpl(
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
              as BorderLayerContent,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$BorderLayerImpl extends BorderLayer {
  const _$BorderLayerImpl(
      {required this.id,
      required this.name,
      this.isVisible = true,
      this.opacity = 1.0,
      @JsonKey(
          readValue: _readBorderLayerContent,
          fromJson: _borderLayerContentFromJson,
          toJson: _borderLayerContentToJson)
      this.content = BorderLayerContent.emptyContent,
      final Map<String, String> properties = const <String, String>{},
      final String? $type})
      : _properties = properties,
        $type = $type ?? 'border',
        super._();

  factory _$BorderLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$BorderLayerImplFromJson(json);

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
      readValue: _readBorderLayerContent,
      fromJson: _borderLayerContentFromJson,
      toJson: _borderLayerContentToJson)
  final BorderLayerContent content;
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
    return 'MapLayer.border(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, content: $content, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BorderLayerImpl &&
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
  _$$BorderLayerImplCopyWith<_$BorderLayerImpl> get copyWith =>
      __$$BorderLayerImplCopyWithImpl<_$BorderLayerImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String name, String? tilesetId,
            bool isVisible, double opacity, List<int> tiles)
        tile,
    required TResult Function(String id, String name, bool isVisible,
            double opacity, List<bool> collisions)
        collision,
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)
        smartTile,
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
    required TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)
        border,
  }) {
    return border(id, name, isVisible, opacity, content, properties);
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult? Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
  }) {
    return border?.call(id, name, isVisible, opacity, content, properties);
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            String presetId,
            SmartTileUsage usage,
            List<String> materialPalette,
            SmartTileField field,
            List<SmartTilePatternStroke> patternStrokes,
            int layerSeed,
            Map<String, String> properties)?
        smartTile,
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
    TResult Function(
            String id,
            String name,
            bool isVisible,
            double opacity,
            @JsonKey(
                readValue: _readBorderLayerContent,
                fromJson: _borderLayerContentFromJson,
                toJson: _borderLayerContentToJson)
            BorderLayerContent content,
            Map<String, String> properties)?
        border,
    required TResult orElse(),
  }) {
    if (border != null) {
      return border(id, name, isVisible, opacity, content, properties);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TileLayer value) tile,
    required TResult Function(CollisionLayer value) collision,
    required TResult Function(SmartTileLayer value) smartTile,
    required TResult Function(ObjectLayer value) object,
    required TResult Function(EnvironmentLayer value) environment,
    required TResult Function(BorderLayer value) border,
  }) {
    return border(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TileLayer value)? tile,
    TResult? Function(CollisionLayer value)? collision,
    TResult? Function(SmartTileLayer value)? smartTile,
    TResult? Function(ObjectLayer value)? object,
    TResult? Function(EnvironmentLayer value)? environment,
    TResult? Function(BorderLayer value)? border,
  }) {
    return border?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TileLayer value)? tile,
    TResult Function(CollisionLayer value)? collision,
    TResult Function(SmartTileLayer value)? smartTile,
    TResult Function(ObjectLayer value)? object,
    TResult Function(EnvironmentLayer value)? environment,
    TResult Function(BorderLayer value)? border,
    required TResult orElse(),
  }) {
    if (border != null) {
      return border(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$BorderLayerImplToJson(
      this,
    );
  }
}

abstract class BorderLayer extends MapLayer {
  const factory BorderLayer(
      {required final String id,
      required final String name,
      final bool isVisible,
      final double opacity,
      @JsonKey(
          readValue: _readBorderLayerContent,
          fromJson: _borderLayerContentFromJson,
          toJson: _borderLayerContentToJson)
      final BorderLayerContent content,
      final Map<String, String> properties}) = _$BorderLayerImpl;
  const BorderLayer._() : super._();

  factory BorderLayer.fromJson(Map<String, dynamic> json) =
      _$BorderLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isVisible;
  @override
  double get opacity;
  @JsonKey(
      readValue: _readBorderLayerContent,
      fromJson: _borderLayerContentFromJson,
      toJson: _borderLayerContentToJson)
  BorderLayerContent get content;
  Map<String, String> get properties;

  /// Create a copy of MapLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BorderLayerImplCopyWith<_$BorderLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
