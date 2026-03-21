// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tileset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TilesetConfig _$TilesetConfigFromJson(Map<String, dynamic> json) {
  return _TilesetConfig.fromJson(json);
}

/// @nodoc
mixin _$TilesetConfig {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get relativePath => throw _privateConstructorUsedError;
  int get tileSize => throw _privateConstructorUsedError;
  List<TileProperties> get tileProperties => throw _privateConstructorUsedError;

  /// Serializes this TilesetConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetConfigCopyWith<TilesetConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetConfigCopyWith<$Res> {
  factory $TilesetConfigCopyWith(
          TilesetConfig value, $Res Function(TilesetConfig) then) =
      _$TilesetConfigCopyWithImpl<$Res, TilesetConfig>;
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      int tileSize,
      List<TileProperties> tileProperties});
}

/// @nodoc
class _$TilesetConfigCopyWithImpl<$Res, $Val extends TilesetConfig>
    implements $TilesetConfigCopyWith<$Res> {
  _$TilesetConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? tileSize = null,
    Object? tileProperties = null,
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
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      tileSize: null == tileSize
          ? _value.tileSize
          : tileSize // ignore: cast_nullable_to_non_nullable
              as int,
      tileProperties: null == tileProperties
          ? _value.tileProperties
          : tileProperties // ignore: cast_nullable_to_non_nullable
              as List<TileProperties>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TilesetConfigImplCopyWith<$Res>
    implements $TilesetConfigCopyWith<$Res> {
  factory _$$TilesetConfigImplCopyWith(
          _$TilesetConfigImpl value, $Res Function(_$TilesetConfigImpl) then) =
      __$$TilesetConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      int tileSize,
      List<TileProperties> tileProperties});
}

/// @nodoc
class __$$TilesetConfigImplCopyWithImpl<$Res>
    extends _$TilesetConfigCopyWithImpl<$Res, _$TilesetConfigImpl>
    implements _$$TilesetConfigImplCopyWith<$Res> {
  __$$TilesetConfigImplCopyWithImpl(
      _$TilesetConfigImpl _value, $Res Function(_$TilesetConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? tileSize = null,
    Object? tileProperties = null,
  }) {
    return _then(_$TilesetConfigImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      tileSize: null == tileSize
          ? _value.tileSize
          : tileSize // ignore: cast_nullable_to_non_nullable
              as int,
      tileProperties: null == tileProperties
          ? _value._tileProperties
          : tileProperties // ignore: cast_nullable_to_non_nullable
              as List<TileProperties>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TilesetConfigImpl implements _TilesetConfig {
  const _$TilesetConfigImpl(
      {required this.id,
      required this.name,
      required this.relativePath,
      required this.tileSize,
      final List<TileProperties> tileProperties = const []})
      : _tileProperties = tileProperties;

  factory _$TilesetConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetConfigImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String relativePath;
  @override
  final int tileSize;
  final List<TileProperties> _tileProperties;
  @override
  @JsonKey()
  List<TileProperties> get tileProperties {
    if (_tileProperties is EqualUnmodifiableListView) return _tileProperties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tileProperties);
  }

  @override
  String toString() {
    return 'TilesetConfig(id: $id, name: $name, relativePath: $relativePath, tileSize: $tileSize, tileProperties: $tileProperties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetConfigImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.tileSize, tileSize) ||
                other.tileSize == tileSize) &&
            const DeepCollectionEquality()
                .equals(other._tileProperties, _tileProperties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, relativePath, tileSize,
      const DeepCollectionEquality().hash(_tileProperties));

  /// Create a copy of TilesetConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetConfigImplCopyWith<_$TilesetConfigImpl> get copyWith =>
      __$$TilesetConfigImplCopyWithImpl<_$TilesetConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetConfigImplToJson(
      this,
    );
  }
}

abstract class _TilesetConfig implements TilesetConfig {
  const factory _TilesetConfig(
      {required final String id,
      required final String name,
      required final String relativePath,
      required final int tileSize,
      final List<TileProperties> tileProperties}) = _$TilesetConfigImpl;

  factory _TilesetConfig.fromJson(Map<String, dynamic> json) =
      _$TilesetConfigImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get relativePath;
  @override
  int get tileSize;
  @override
  List<TileProperties> get tileProperties;

  /// Create a copy of TilesetConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetConfigImplCopyWith<_$TilesetConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TileProperties _$TilePropertiesFromJson(Map<String, dynamic> json) {
  return _TileProperties.fromJson(json);
}

/// @nodoc
mixin _$TileProperties {
  int get id => throw _privateConstructorUsedError;
  Map<String, dynamic> get customProperties =>
      throw _privateConstructorUsedError;
  bool get isPassable => throw _privateConstructorUsedError;

  /// Serializes this TileProperties to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TileProperties
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilePropertiesCopyWith<TileProperties> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilePropertiesCopyWith<$Res> {
  factory $TilePropertiesCopyWith(
          TileProperties value, $Res Function(TileProperties) then) =
      _$TilePropertiesCopyWithImpl<$Res, TileProperties>;
  @useResult
  $Res call({int id, Map<String, dynamic> customProperties, bool isPassable});
}

/// @nodoc
class _$TilePropertiesCopyWithImpl<$Res, $Val extends TileProperties>
    implements $TilePropertiesCopyWith<$Res> {
  _$TilePropertiesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TileProperties
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customProperties = null,
    Object? isPassable = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      customProperties: null == customProperties
          ? _value.customProperties
          : customProperties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isPassable: null == isPassable
          ? _value.isPassable
          : isPassable // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TilePropertiesImplCopyWith<$Res>
    implements $TilePropertiesCopyWith<$Res> {
  factory _$$TilePropertiesImplCopyWith(_$TilePropertiesImpl value,
          $Res Function(_$TilePropertiesImpl) then) =
      __$$TilePropertiesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, Map<String, dynamic> customProperties, bool isPassable});
}

/// @nodoc
class __$$TilePropertiesImplCopyWithImpl<$Res>
    extends _$TilePropertiesCopyWithImpl<$Res, _$TilePropertiesImpl>
    implements _$$TilePropertiesImplCopyWith<$Res> {
  __$$TilePropertiesImplCopyWithImpl(
      _$TilePropertiesImpl _value, $Res Function(_$TilePropertiesImpl) _then)
      : super(_value, _then);

  /// Create a copy of TileProperties
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customProperties = null,
    Object? isPassable = null,
  }) {
    return _then(_$TilePropertiesImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      customProperties: null == customProperties
          ? _value._customProperties
          : customProperties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isPassable: null == isPassable
          ? _value.isPassable
          : isPassable // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TilePropertiesImpl implements _TileProperties {
  const _$TilePropertiesImpl(
      {required this.id,
      final Map<String, dynamic> customProperties = const {},
      this.isPassable = false})
      : _customProperties = customProperties;

  factory _$TilePropertiesImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilePropertiesImplFromJson(json);

  @override
  final int id;
  final Map<String, dynamic> _customProperties;
  @override
  @JsonKey()
  Map<String, dynamic> get customProperties {
    if (_customProperties is EqualUnmodifiableMapView) return _customProperties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customProperties);
  }

  @override
  @JsonKey()
  final bool isPassable;

  @override
  String toString() {
    return 'TileProperties(id: $id, customProperties: $customProperties, isPassable: $isPassable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilePropertiesImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._customProperties, _customProperties) &&
            (identical(other.isPassable, isPassable) ||
                other.isPassable == isPassable));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id,
      const DeepCollectionEquality().hash(_customProperties), isPassable);

  /// Create a copy of TileProperties
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilePropertiesImplCopyWith<_$TilePropertiesImpl> get copyWith =>
      __$$TilePropertiesImplCopyWithImpl<_$TilePropertiesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilePropertiesImplToJson(
      this,
    );
  }
}

abstract class _TileProperties implements TileProperties {
  const factory _TileProperties(
      {required final int id,
      final Map<String, dynamic> customProperties,
      final bool isPassable}) = _$TilePropertiesImpl;

  factory _TileProperties.fromJson(Map<String, dynamic> json) =
      _$TilePropertiesImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, dynamic> get customProperties;
  @override
  bool get isPassable;

  /// Create a copy of TileProperties
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilePropertiesImplCopyWith<_$TilePropertiesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
