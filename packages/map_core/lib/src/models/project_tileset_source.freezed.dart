// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_tileset_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VisualTileProperty _$VisualTilePropertyFromJson(Map<String, dynamic> json) {
  return _VisualTileProperty.fromJson(json);
}

/// @nodoc
mixin _$VisualTileProperty {
  int get tileId => throw _privateConstructorUsedError;
  bool get passable => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this VisualTileProperty to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisualTilePropertyCopyWith<VisualTileProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisualTilePropertyCopyWith<$Res> {
  factory $VisualTilePropertyCopyWith(
          VisualTileProperty value, $Res Function(VisualTileProperty) then) =
      _$VisualTilePropertyCopyWithImpl<$Res, VisualTileProperty>;
  @useResult
  $Res call({int tileId, bool passable, List<String> tags});
}

/// @nodoc
class _$VisualTilePropertyCopyWithImpl<$Res, $Val extends VisualTileProperty>
    implements $VisualTilePropertyCopyWith<$Res> {
  _$VisualTilePropertyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? passable = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      passable: null == passable
          ? _value.passable
          : passable // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisualTilePropertyImplCopyWith<$Res>
    implements $VisualTilePropertyCopyWith<$Res> {
  factory _$$VisualTilePropertyImplCopyWith(_$VisualTilePropertyImpl value,
          $Res Function(_$VisualTilePropertyImpl) then) =
      __$$VisualTilePropertyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int tileId, bool passable, List<String> tags});
}

/// @nodoc
class __$$VisualTilePropertyImplCopyWithImpl<$Res>
    extends _$VisualTilePropertyCopyWithImpl<$Res, _$VisualTilePropertyImpl>
    implements _$$VisualTilePropertyImplCopyWith<$Res> {
  __$$VisualTilePropertyImplCopyWithImpl(_$VisualTilePropertyImpl _value,
      $Res Function(_$VisualTilePropertyImpl) _then)
      : super(_value, _then);

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? passable = null,
    Object? tags = null,
  }) {
    return _then(_$VisualTilePropertyImpl(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      passable: null == passable
          ? _value.passable
          : passable // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VisualTilePropertyImpl implements _VisualTileProperty {
  const _$VisualTilePropertyImpl(
      {required this.tileId,
      this.passable = true,
      final List<String> tags = const <String>[]})
      : _tags = tags;

  factory _$VisualTilePropertyImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisualTilePropertyImplFromJson(json);

  @override
  final int tileId;
  @override
  @JsonKey()
  final bool passable;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'VisualTileProperty(tileId: $tileId, passable: $passable, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisualTilePropertyImpl &&
            (identical(other.tileId, tileId) || other.tileId == tileId) &&
            (identical(other.passable, passable) ||
                other.passable == passable) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tileId, passable,
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisualTilePropertyImplCopyWith<_$VisualTilePropertyImpl> get copyWith =>
      __$$VisualTilePropertyImplCopyWithImpl<_$VisualTilePropertyImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisualTilePropertyImplToJson(
      this,
    );
  }
}

abstract class _VisualTileProperty implements VisualTileProperty {
  const factory _VisualTileProperty(
      {required final int tileId,
      final bool passable,
      final List<String> tags}) = _$VisualTilePropertyImpl;

  factory _VisualTileProperty.fromJson(Map<String, dynamic> json) =
      _$VisualTilePropertyImpl.fromJson;

  @override
  int get tileId;
  @override
  bool get passable;
  @override
  List<String> get tags;

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisualTilePropertyImplCopyWith<_$VisualTilePropertyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectTilesetProperty _$ProjectTilesetPropertyFromJson(
    Map<String, dynamic> json) {
  return _ProjectTilesetProperty.fromJson(json);
}

/// @nodoc
mixin _$ProjectTilesetProperty {
  String get name => throw _privateConstructorUsedError;
  ProjectTilesetPropertyType get type => throw _privateConstructorUsedError;
  Object? get value => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  String? get customType => throw _privateConstructorUsedError;

  /// Serializes this ProjectTilesetProperty to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTilesetProperty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTilesetPropertyCopyWith<ProjectTilesetProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTilesetPropertyCopyWith<$Res> {
  factory $ProjectTilesetPropertyCopyWith(ProjectTilesetProperty value,
          $Res Function(ProjectTilesetProperty) then) =
      _$ProjectTilesetPropertyCopyWithImpl<$Res, ProjectTilesetProperty>;
  @useResult
  $Res call(
      {String name,
      ProjectTilesetPropertyType type,
      Object? value,
      @JsonKey(includeIfNull: false) String? customType});
}

/// @nodoc
class _$ProjectTilesetPropertyCopyWithImpl<$Res,
        $Val extends ProjectTilesetProperty>
    implements $ProjectTilesetPropertyCopyWith<$Res> {
  _$ProjectTilesetPropertyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTilesetProperty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? value = freezed,
    Object? customType = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ProjectTilesetPropertyType,
      value: freezed == value ? _value.value : value,
      customType: freezed == customType
          ? _value.customType
          : customType // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTilesetPropertyImplCopyWith<$Res>
    implements $ProjectTilesetPropertyCopyWith<$Res> {
  factory _$$ProjectTilesetPropertyImplCopyWith(
          _$ProjectTilesetPropertyImpl value,
          $Res Function(_$ProjectTilesetPropertyImpl) then) =
      __$$ProjectTilesetPropertyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      ProjectTilesetPropertyType type,
      Object? value,
      @JsonKey(includeIfNull: false) String? customType});
}

/// @nodoc
class __$$ProjectTilesetPropertyImplCopyWithImpl<$Res>
    extends _$ProjectTilesetPropertyCopyWithImpl<$Res,
        _$ProjectTilesetPropertyImpl>
    implements _$$ProjectTilesetPropertyImplCopyWith<$Res> {
  __$$ProjectTilesetPropertyImplCopyWithImpl(
      _$ProjectTilesetPropertyImpl _value,
      $Res Function(_$ProjectTilesetPropertyImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTilesetProperty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? value = freezed,
    Object? customType = freezed,
  }) {
    return _then(_$ProjectTilesetPropertyImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ProjectTilesetPropertyType,
      value: freezed == value ? _value.value : value,
      customType: freezed == customType
          ? _value.customType
          : customType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectTilesetPropertyImpl implements _ProjectTilesetProperty {
  const _$ProjectTilesetPropertyImpl(
      {required this.name,
      required this.type,
      this.value,
      @JsonKey(includeIfNull: false) this.customType});

  factory _$ProjectTilesetPropertyImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTilesetPropertyImplFromJson(json);

  @override
  final String name;
  @override
  final ProjectTilesetPropertyType type;
  @override
  final Object? value;
  @override
  @JsonKey(includeIfNull: false)
  final String? customType;

  @override
  String toString() {
    return 'ProjectTilesetProperty(name: $name, type: $type, value: $value, customType: $customType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetPropertyImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other.value, value) &&
            (identical(other.customType, customType) ||
                other.customType == customType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, type,
      const DeepCollectionEquality().hash(value), customType);

  /// Create a copy of ProjectTilesetProperty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTilesetPropertyImplCopyWith<_$ProjectTilesetPropertyImpl>
      get copyWith => __$$ProjectTilesetPropertyImplCopyWithImpl<
          _$ProjectTilesetPropertyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTilesetPropertyImplToJson(
      this,
    );
  }
}

abstract class _ProjectTilesetProperty implements ProjectTilesetProperty {
  const factory _ProjectTilesetProperty(
          {required final String name,
          required final ProjectTilesetPropertyType type,
          final Object? value,
          @JsonKey(includeIfNull: false) final String? customType}) =
      _$ProjectTilesetPropertyImpl;

  factory _ProjectTilesetProperty.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetPropertyImpl.fromJson;

  @override
  String get name;
  @override
  ProjectTilesetPropertyType get type;
  @override
  Object? get value;
  @override
  @JsonKey(includeIfNull: false)
  String? get customType;

  /// Create a copy of ProjectTilesetProperty
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetPropertyImplCopyWith<_$ProjectTilesetPropertyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectTilesetPixelRect _$ProjectTilesetPixelRectFromJson(
    Map<String, dynamic> json) {
  return _ProjectTilesetPixelRect.fromJson(json);
}

/// @nodoc
mixin _$ProjectTilesetPixelRect {
  int get x => throw _privateConstructorUsedError;
  int get y => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;

  /// Serializes this ProjectTilesetPixelRect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTilesetPixelRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTilesetPixelRectCopyWith<ProjectTilesetPixelRect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTilesetPixelRectCopyWith<$Res> {
  factory $ProjectTilesetPixelRectCopyWith(ProjectTilesetPixelRect value,
          $Res Function(ProjectTilesetPixelRect) then) =
      _$ProjectTilesetPixelRectCopyWithImpl<$Res, ProjectTilesetPixelRect>;
  @useResult
  $Res call({int x, int y, int width, int height});
}

/// @nodoc
class _$ProjectTilesetPixelRectCopyWithImpl<$Res,
        $Val extends ProjectTilesetPixelRect>
    implements $ProjectTilesetPixelRectCopyWith<$Res> {
  _$ProjectTilesetPixelRectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTilesetPixelRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
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
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTilesetPixelRectImplCopyWith<$Res>
    implements $ProjectTilesetPixelRectCopyWith<$Res> {
  factory _$$ProjectTilesetPixelRectImplCopyWith(
          _$ProjectTilesetPixelRectImpl value,
          $Res Function(_$ProjectTilesetPixelRectImpl) then) =
      __$$ProjectTilesetPixelRectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int x, int y, int width, int height});
}

/// @nodoc
class __$$ProjectTilesetPixelRectImplCopyWithImpl<$Res>
    extends _$ProjectTilesetPixelRectCopyWithImpl<$Res,
        _$ProjectTilesetPixelRectImpl>
    implements _$$ProjectTilesetPixelRectImplCopyWith<$Res> {
  __$$ProjectTilesetPixelRectImplCopyWithImpl(
      _$ProjectTilesetPixelRectImpl _value,
      $Res Function(_$ProjectTilesetPixelRectImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTilesetPixelRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$ProjectTilesetPixelRectImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTilesetPixelRectImpl implements _ProjectTilesetPixelRect {
  const _$ProjectTilesetPixelRectImpl(
      {required this.x,
      required this.y,
      required this.width,
      required this.height});

  factory _$ProjectTilesetPixelRectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTilesetPixelRectImplFromJson(json);

  @override
  final int x;
  @override
  final int y;
  @override
  final int width;
  @override
  final int height;

  @override
  String toString() {
    return 'ProjectTilesetPixelRect(x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetPixelRectImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, width, height);

  /// Create a copy of ProjectTilesetPixelRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTilesetPixelRectImplCopyWith<_$ProjectTilesetPixelRectImpl>
      get copyWith => __$$ProjectTilesetPixelRectImplCopyWithImpl<
          _$ProjectTilesetPixelRectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTilesetPixelRectImplToJson(
      this,
    );
  }
}

abstract class _ProjectTilesetPixelRect implements ProjectTilesetPixelRect {
  const factory _ProjectTilesetPixelRect(
      {required final int x,
      required final int y,
      required final int width,
      required final int height}) = _$ProjectTilesetPixelRectImpl;

  factory _ProjectTilesetPixelRect.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetPixelRectImpl.fromJson;

  @override
  int get x;
  @override
  int get y;
  @override
  int get width;
  @override
  int get height;

  /// Create a copy of ProjectTilesetPixelRect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetPixelRectImplCopyWith<_$ProjectTilesetPixelRectImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectTilesetPixelPoint _$ProjectTilesetPixelPointFromJson(
    Map<String, dynamic> json) {
  return _ProjectTilesetPixelPoint.fromJson(json);
}

/// @nodoc
mixin _$ProjectTilesetPixelPoint {
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;

  /// Serializes this ProjectTilesetPixelPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTilesetPixelPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTilesetPixelPointCopyWith<ProjectTilesetPixelPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTilesetPixelPointCopyWith<$Res> {
  factory $ProjectTilesetPixelPointCopyWith(ProjectTilesetPixelPoint value,
          $Res Function(ProjectTilesetPixelPoint) then) =
      _$ProjectTilesetPixelPointCopyWithImpl<$Res, ProjectTilesetPixelPoint>;
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class _$ProjectTilesetPixelPointCopyWithImpl<$Res,
        $Val extends ProjectTilesetPixelPoint>
    implements $ProjectTilesetPixelPointCopyWith<$Res> {
  _$ProjectTilesetPixelPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTilesetPixelPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTilesetPixelPointImplCopyWith<$Res>
    implements $ProjectTilesetPixelPointCopyWith<$Res> {
  factory _$$ProjectTilesetPixelPointImplCopyWith(
          _$ProjectTilesetPixelPointImpl value,
          $Res Function(_$ProjectTilesetPixelPointImpl) then) =
      __$$ProjectTilesetPixelPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class __$$ProjectTilesetPixelPointImplCopyWithImpl<$Res>
    extends _$ProjectTilesetPixelPointCopyWithImpl<$Res,
        _$ProjectTilesetPixelPointImpl>
    implements _$$ProjectTilesetPixelPointImplCopyWith<$Res> {
  __$$ProjectTilesetPixelPointImplCopyWithImpl(
      _$ProjectTilesetPixelPointImpl _value,
      $Res Function(_$ProjectTilesetPixelPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTilesetPixelPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_$ProjectTilesetPixelPointImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTilesetPixelPointImpl implements _ProjectTilesetPixelPoint {
  const _$ProjectTilesetPixelPointImpl({required this.x, required this.y});

  factory _$ProjectTilesetPixelPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTilesetPixelPointImplFromJson(json);

  @override
  final double x;
  @override
  final double y;

  @override
  String toString() {
    return 'ProjectTilesetPixelPoint(x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetPixelPointImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y);

  /// Create a copy of ProjectTilesetPixelPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTilesetPixelPointImplCopyWith<_$ProjectTilesetPixelPointImpl>
      get copyWith => __$$ProjectTilesetPixelPointImplCopyWithImpl<
          _$ProjectTilesetPixelPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTilesetPixelPointImplToJson(
      this,
    );
  }
}

abstract class _ProjectTilesetPixelPoint implements ProjectTilesetPixelPoint {
  const factory _ProjectTilesetPixelPoint(
      {required final double x,
      required final double y}) = _$ProjectTilesetPixelPointImpl;

  factory _ProjectTilesetPixelPoint.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetPixelPointImpl.fromJson;

  @override
  double get x;
  @override
  double get y;

  /// Create a copy of ProjectTilesetPixelPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetPixelPointImplCopyWith<_$ProjectTilesetPixelPointImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectTilesetCollisionObject _$ProjectTilesetCollisionObjectFromJson(
    Map<String, dynamic> json) {
  return _ProjectTilesetCollisionObject.fromJson(json);
}

/// @nodoc
mixin _$ProjectTilesetCollisionObject {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  ProjectTilesetCollisionShape get shape => throw _privateConstructorUsedError;
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;
  double get width => throw _privateConstructorUsedError;
  double get height => throw _privateConstructorUsedError;
  double get rotation => throw _privateConstructorUsedError;
  List<ProjectTilesetPixelPoint> get points =>
      throw _privateConstructorUsedError;
  List<ProjectTilesetProperty> get properties =>
      throw _privateConstructorUsedError;

  /// Serializes this ProjectTilesetCollisionObject to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTilesetCollisionObject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTilesetCollisionObjectCopyWith<ProjectTilesetCollisionObject>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTilesetCollisionObjectCopyWith<$Res> {
  factory $ProjectTilesetCollisionObjectCopyWith(
          ProjectTilesetCollisionObject value,
          $Res Function(ProjectTilesetCollisionObject) then) =
      _$ProjectTilesetCollisionObjectCopyWithImpl<$Res,
          ProjectTilesetCollisionObject>;
  @useResult
  $Res call(
      {int id,
      String name,
      String type,
      ProjectTilesetCollisionShape shape,
      double x,
      double y,
      double width,
      double height,
      double rotation,
      List<ProjectTilesetPixelPoint> points,
      List<ProjectTilesetProperty> properties});
}

/// @nodoc
class _$ProjectTilesetCollisionObjectCopyWithImpl<$Res,
        $Val extends ProjectTilesetCollisionObject>
    implements $ProjectTilesetCollisionObjectCopyWith<$Res> {
  _$ProjectTilesetCollisionObjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTilesetCollisionObject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? shape = null,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? rotation = null,
    Object? points = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      shape: null == shape
          ? _value.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as ProjectTilesetCollisionShape,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetPixelPoint>,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetProperty>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTilesetCollisionObjectImplCopyWith<$Res>
    implements $ProjectTilesetCollisionObjectCopyWith<$Res> {
  factory _$$ProjectTilesetCollisionObjectImplCopyWith(
          _$ProjectTilesetCollisionObjectImpl value,
          $Res Function(_$ProjectTilesetCollisionObjectImpl) then) =
      __$$ProjectTilesetCollisionObjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String type,
      ProjectTilesetCollisionShape shape,
      double x,
      double y,
      double width,
      double height,
      double rotation,
      List<ProjectTilesetPixelPoint> points,
      List<ProjectTilesetProperty> properties});
}

/// @nodoc
class __$$ProjectTilesetCollisionObjectImplCopyWithImpl<$Res>
    extends _$ProjectTilesetCollisionObjectCopyWithImpl<$Res,
        _$ProjectTilesetCollisionObjectImpl>
    implements _$$ProjectTilesetCollisionObjectImplCopyWith<$Res> {
  __$$ProjectTilesetCollisionObjectImplCopyWithImpl(
      _$ProjectTilesetCollisionObjectImpl _value,
      $Res Function(_$ProjectTilesetCollisionObjectImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTilesetCollisionObject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? shape = null,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? rotation = null,
    Object? points = null,
    Object? properties = null,
  }) {
    return _then(_$ProjectTilesetCollisionObjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      shape: null == shape
          ? _value.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as ProjectTilesetCollisionShape,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
      points: null == points
          ? _value._points
          : points // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetPixelPoint>,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetProperty>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectTilesetCollisionObjectImpl
    implements _ProjectTilesetCollisionObject {
  const _$ProjectTilesetCollisionObjectImpl(
      {required this.id,
      this.name = '',
      this.type = '',
      this.shape = ProjectTilesetCollisionShape.rectangle,
      required this.x,
      required this.y,
      this.width = 0,
      this.height = 0,
      this.rotation = 0,
      final List<ProjectTilesetPixelPoint> points =
          const <ProjectTilesetPixelPoint>[],
      final List<ProjectTilesetProperty> properties =
          const <ProjectTilesetProperty>[]})
      : _points = points,
        _properties = properties;

  factory _$ProjectTilesetCollisionObjectImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectTilesetCollisionObjectImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final ProjectTilesetCollisionShape shape;
  @override
  final double x;
  @override
  final double y;
  @override
  @JsonKey()
  final double width;
  @override
  @JsonKey()
  final double height;
  @override
  @JsonKey()
  final double rotation;
  final List<ProjectTilesetPixelPoint> _points;
  @override
  @JsonKey()
  List<ProjectTilesetPixelPoint> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  final List<ProjectTilesetProperty> _properties;
  @override
  @JsonKey()
  List<ProjectTilesetProperty> get properties {
    if (_properties is EqualUnmodifiableListView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_properties);
  }

  @override
  String toString() {
    return 'ProjectTilesetCollisionObject(id: $id, name: $name, type: $type, shape: $shape, x: $x, y: $y, width: $width, height: $height, rotation: $rotation, points: $points, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetCollisionObjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.shape, shape) || other.shape == shape) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.rotation, rotation) ||
                other.rotation == rotation) &&
            const DeepCollectionEquality().equals(other._points, _points) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      shape,
      x,
      y,
      width,
      height,
      rotation,
      const DeepCollectionEquality().hash(_points),
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of ProjectTilesetCollisionObject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTilesetCollisionObjectImplCopyWith<
          _$ProjectTilesetCollisionObjectImpl>
      get copyWith => __$$ProjectTilesetCollisionObjectImplCopyWithImpl<
          _$ProjectTilesetCollisionObjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTilesetCollisionObjectImplToJson(
      this,
    );
  }
}

abstract class _ProjectTilesetCollisionObject
    implements ProjectTilesetCollisionObject {
  const factory _ProjectTilesetCollisionObject(
          {required final int id,
          final String name,
          final String type,
          final ProjectTilesetCollisionShape shape,
          required final double x,
          required final double y,
          final double width,
          final double height,
          final double rotation,
          final List<ProjectTilesetPixelPoint> points,
          final List<ProjectTilesetProperty> properties}) =
      _$ProjectTilesetCollisionObjectImpl;

  factory _ProjectTilesetCollisionObject.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetCollisionObjectImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get type;
  @override
  ProjectTilesetCollisionShape get shape;
  @override
  double get x;
  @override
  double get y;
  @override
  double get width;
  @override
  double get height;
  @override
  double get rotation;
  @override
  List<ProjectTilesetPixelPoint> get points;
  @override
  List<ProjectTilesetProperty> get properties;

  /// Create a copy of ProjectTilesetCollisionObject
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetCollisionObjectImplCopyWith<
          _$ProjectTilesetCollisionObjectImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectImageCollectionPage _$ProjectImageCollectionPageFromJson(
    Map<String, dynamic> json) {
  return _ProjectImageCollectionPage.fromJson(json);
}

/// @nodoc
mixin _$ProjectImageCollectionPage {
  String get id => throw _privateConstructorUsedError;
  String get assetId => throw _privateConstructorUsedError;
  int get pixelWidth => throw _privateConstructorUsedError;
  int get pixelHeight => throw _privateConstructorUsedError;

  /// Serializes this ProjectImageCollectionPage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectImageCollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectImageCollectionPageCopyWith<ProjectImageCollectionPage>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectImageCollectionPageCopyWith<$Res> {
  factory $ProjectImageCollectionPageCopyWith(ProjectImageCollectionPage value,
          $Res Function(ProjectImageCollectionPage) then) =
      _$ProjectImageCollectionPageCopyWithImpl<$Res,
          ProjectImageCollectionPage>;
  @useResult
  $Res call({String id, String assetId, int pixelWidth, int pixelHeight});
}

/// @nodoc
class _$ProjectImageCollectionPageCopyWithImpl<$Res,
        $Val extends ProjectImageCollectionPage>
    implements $ProjectImageCollectionPageCopyWith<$Res> {
  _$ProjectImageCollectionPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectImageCollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? assetId = null,
    Object? pixelWidth = null,
    Object? pixelHeight = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      assetId: null == assetId
          ? _value.assetId
          : assetId // ignore: cast_nullable_to_non_nullable
              as String,
      pixelWidth: null == pixelWidth
          ? _value.pixelWidth
          : pixelWidth // ignore: cast_nullable_to_non_nullable
              as int,
      pixelHeight: null == pixelHeight
          ? _value.pixelHeight
          : pixelHeight // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectImageCollectionPageImplCopyWith<$Res>
    implements $ProjectImageCollectionPageCopyWith<$Res> {
  factory _$$ProjectImageCollectionPageImplCopyWith(
          _$ProjectImageCollectionPageImpl value,
          $Res Function(_$ProjectImageCollectionPageImpl) then) =
      __$$ProjectImageCollectionPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String assetId, int pixelWidth, int pixelHeight});
}

/// @nodoc
class __$$ProjectImageCollectionPageImplCopyWithImpl<$Res>
    extends _$ProjectImageCollectionPageCopyWithImpl<$Res,
        _$ProjectImageCollectionPageImpl>
    implements _$$ProjectImageCollectionPageImplCopyWith<$Res> {
  __$$ProjectImageCollectionPageImplCopyWithImpl(
      _$ProjectImageCollectionPageImpl _value,
      $Res Function(_$ProjectImageCollectionPageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectImageCollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? assetId = null,
    Object? pixelWidth = null,
    Object? pixelHeight = null,
  }) {
    return _then(_$ProjectImageCollectionPageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      assetId: null == assetId
          ? _value.assetId
          : assetId // ignore: cast_nullable_to_non_nullable
              as String,
      pixelWidth: null == pixelWidth
          ? _value.pixelWidth
          : pixelWidth // ignore: cast_nullable_to_non_nullable
              as int,
      pixelHeight: null == pixelHeight
          ? _value.pixelHeight
          : pixelHeight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImageCollectionPageImpl implements _ProjectImageCollectionPage {
  const _$ProjectImageCollectionPageImpl(
      {required this.id,
      required this.assetId,
      required this.pixelWidth,
      required this.pixelHeight});

  factory _$ProjectImageCollectionPageImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectImageCollectionPageImplFromJson(json);

  @override
  final String id;
  @override
  final String assetId;
  @override
  final int pixelWidth;
  @override
  final int pixelHeight;

  @override
  String toString() {
    return 'ProjectImageCollectionPage(id: $id, assetId: $assetId, pixelWidth: $pixelWidth, pixelHeight: $pixelHeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImageCollectionPageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.assetId, assetId) || other.assetId == assetId) &&
            (identical(other.pixelWidth, pixelWidth) ||
                other.pixelWidth == pixelWidth) &&
            (identical(other.pixelHeight, pixelHeight) ||
                other.pixelHeight == pixelHeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, assetId, pixelWidth, pixelHeight);

  /// Create a copy of ProjectImageCollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImageCollectionPageImplCopyWith<_$ProjectImageCollectionPageImpl>
      get copyWith => __$$ProjectImageCollectionPageImplCopyWithImpl<
          _$ProjectImageCollectionPageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImageCollectionPageImplToJson(
      this,
    );
  }
}

abstract class _ProjectImageCollectionPage
    implements ProjectImageCollectionPage {
  const factory _ProjectImageCollectionPage(
      {required final String id,
      required final String assetId,
      required final int pixelWidth,
      required final int pixelHeight}) = _$ProjectImageCollectionPageImpl;

  factory _ProjectImageCollectionPage.fromJson(Map<String, dynamic> json) =
      _$ProjectImageCollectionPageImpl.fromJson;

  @override
  String get id;
  @override
  String get assetId;
  @override
  int get pixelWidth;
  @override
  int get pixelHeight;

  /// Create a copy of ProjectImageCollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectImageCollectionPageImplCopyWith<_$ProjectImageCollectionPageImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectImageCollectionAnimationFrame
    _$ProjectImageCollectionAnimationFrameFromJson(Map<String, dynamic> json) {
  return _ProjectImageCollectionAnimationFrame.fromJson(json);
}

/// @nodoc
mixin _$ProjectImageCollectionAnimationFrame {
  int get tileId => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;

  /// Serializes this ProjectImageCollectionAnimationFrame to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectImageCollectionAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectImageCollectionAnimationFrameCopyWith<
          ProjectImageCollectionAnimationFrame>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectImageCollectionAnimationFrameCopyWith<$Res> {
  factory $ProjectImageCollectionAnimationFrameCopyWith(
          ProjectImageCollectionAnimationFrame value,
          $Res Function(ProjectImageCollectionAnimationFrame) then) =
      _$ProjectImageCollectionAnimationFrameCopyWithImpl<$Res,
          ProjectImageCollectionAnimationFrame>;
  @useResult
  $Res call({int tileId, int durationMs});
}

/// @nodoc
class _$ProjectImageCollectionAnimationFrameCopyWithImpl<$Res,
        $Val extends ProjectImageCollectionAnimationFrame>
    implements $ProjectImageCollectionAnimationFrameCopyWith<$Res> {
  _$ProjectImageCollectionAnimationFrameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectImageCollectionAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? durationMs = null,
  }) {
    return _then(_value.copyWith(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectImageCollectionAnimationFrameImplCopyWith<$Res>
    implements $ProjectImageCollectionAnimationFrameCopyWith<$Res> {
  factory _$$ProjectImageCollectionAnimationFrameImplCopyWith(
          _$ProjectImageCollectionAnimationFrameImpl value,
          $Res Function(_$ProjectImageCollectionAnimationFrameImpl) then) =
      __$$ProjectImageCollectionAnimationFrameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int tileId, int durationMs});
}

/// @nodoc
class __$$ProjectImageCollectionAnimationFrameImplCopyWithImpl<$Res>
    extends _$ProjectImageCollectionAnimationFrameCopyWithImpl<$Res,
        _$ProjectImageCollectionAnimationFrameImpl>
    implements _$$ProjectImageCollectionAnimationFrameImplCopyWith<$Res> {
  __$$ProjectImageCollectionAnimationFrameImplCopyWithImpl(
      _$ProjectImageCollectionAnimationFrameImpl _value,
      $Res Function(_$ProjectImageCollectionAnimationFrameImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectImageCollectionAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? durationMs = null,
  }) {
    return _then(_$ProjectImageCollectionAnimationFrameImpl(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImageCollectionAnimationFrameImpl
    implements _ProjectImageCollectionAnimationFrame {
  const _$ProjectImageCollectionAnimationFrameImpl(
      {required this.tileId, required this.durationMs});

  factory _$ProjectImageCollectionAnimationFrameImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectImageCollectionAnimationFrameImplFromJson(json);

  @override
  final int tileId;
  @override
  final int durationMs;

  @override
  String toString() {
    return 'ProjectImageCollectionAnimationFrame(tileId: $tileId, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImageCollectionAnimationFrameImpl &&
            (identical(other.tileId, tileId) || other.tileId == tileId) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tileId, durationMs);

  /// Create a copy of ProjectImageCollectionAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImageCollectionAnimationFrameImplCopyWith<
          _$ProjectImageCollectionAnimationFrameImpl>
      get copyWith => __$$ProjectImageCollectionAnimationFrameImplCopyWithImpl<
          _$ProjectImageCollectionAnimationFrameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImageCollectionAnimationFrameImplToJson(
      this,
    );
  }
}

abstract class _ProjectImageCollectionAnimationFrame
    implements ProjectImageCollectionAnimationFrame {
  const factory _ProjectImageCollectionAnimationFrame(
          {required final int tileId, required final int durationMs}) =
      _$ProjectImageCollectionAnimationFrameImpl;

  factory _ProjectImageCollectionAnimationFrame.fromJson(
          Map<String, dynamic> json) =
      _$ProjectImageCollectionAnimationFrameImpl.fromJson;

  @override
  int get tileId;
  @override
  int get durationMs;

  /// Create a copy of ProjectImageCollectionAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectImageCollectionAnimationFrameImplCopyWith<
          _$ProjectImageCollectionAnimationFrameImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectRegularAtlasTileAnimation _$ProjectRegularAtlasTileAnimationFromJson(
    Map<String, dynamic> json) {
  return _ProjectRegularAtlasTileAnimation.fromJson(json);
}

/// @nodoc
mixin _$ProjectRegularAtlasTileAnimation {
  int get tileId => throw _privateConstructorUsedError;
  List<ProjectImageCollectionAnimationFrame> get frames =>
      throw _privateConstructorUsedError;

  /// Serializes this ProjectRegularAtlasTileAnimation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectRegularAtlasTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectRegularAtlasTileAnimationCopyWith<ProjectRegularAtlasTileAnimation>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectRegularAtlasTileAnimationCopyWith<$Res> {
  factory $ProjectRegularAtlasTileAnimationCopyWith(
          ProjectRegularAtlasTileAnimation value,
          $Res Function(ProjectRegularAtlasTileAnimation) then) =
      _$ProjectRegularAtlasTileAnimationCopyWithImpl<$Res,
          ProjectRegularAtlasTileAnimation>;
  @useResult
  $Res call({int tileId, List<ProjectImageCollectionAnimationFrame> frames});
}

/// @nodoc
class _$ProjectRegularAtlasTileAnimationCopyWithImpl<$Res,
        $Val extends ProjectRegularAtlasTileAnimation>
    implements $ProjectRegularAtlasTileAnimationCopyWith<$Res> {
  _$ProjectRegularAtlasTileAnimationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectRegularAtlasTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? frames = null,
  }) {
    return _then(_value.copyWith(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<ProjectImageCollectionAnimationFrame>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectRegularAtlasTileAnimationImplCopyWith<$Res>
    implements $ProjectRegularAtlasTileAnimationCopyWith<$Res> {
  factory _$$ProjectRegularAtlasTileAnimationImplCopyWith(
          _$ProjectRegularAtlasTileAnimationImpl value,
          $Res Function(_$ProjectRegularAtlasTileAnimationImpl) then) =
      __$$ProjectRegularAtlasTileAnimationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int tileId, List<ProjectImageCollectionAnimationFrame> frames});
}

/// @nodoc
class __$$ProjectRegularAtlasTileAnimationImplCopyWithImpl<$Res>
    extends _$ProjectRegularAtlasTileAnimationCopyWithImpl<$Res,
        _$ProjectRegularAtlasTileAnimationImpl>
    implements _$$ProjectRegularAtlasTileAnimationImplCopyWith<$Res> {
  __$$ProjectRegularAtlasTileAnimationImplCopyWithImpl(
      _$ProjectRegularAtlasTileAnimationImpl _value,
      $Res Function(_$ProjectRegularAtlasTileAnimationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectRegularAtlasTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? frames = null,
  }) {
    return _then(_$ProjectRegularAtlasTileAnimationImpl(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<ProjectImageCollectionAnimationFrame>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectRegularAtlasTileAnimationImpl
    implements _ProjectRegularAtlasTileAnimation {
  const _$ProjectRegularAtlasTileAnimationImpl(
      {required this.tileId,
      required final List<ProjectImageCollectionAnimationFrame> frames})
      : _frames = frames;

  factory _$ProjectRegularAtlasTileAnimationImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectRegularAtlasTileAnimationImplFromJson(json);

  @override
  final int tileId;
  final List<ProjectImageCollectionAnimationFrame> _frames;
  @override
  List<ProjectImageCollectionAnimationFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  String toString() {
    return 'ProjectRegularAtlasTileAnimation(tileId: $tileId, frames: $frames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectRegularAtlasTileAnimationImpl &&
            (identical(other.tileId, tileId) || other.tileId == tileId) &&
            const DeepCollectionEquality().equals(other._frames, _frames));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, tileId, const DeepCollectionEquality().hash(_frames));

  /// Create a copy of ProjectRegularAtlasTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectRegularAtlasTileAnimationImplCopyWith<
          _$ProjectRegularAtlasTileAnimationImpl>
      get copyWith => __$$ProjectRegularAtlasTileAnimationImplCopyWithImpl<
          _$ProjectRegularAtlasTileAnimationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectRegularAtlasTileAnimationImplToJson(
      this,
    );
  }
}

abstract class _ProjectRegularAtlasTileAnimation
    implements ProjectRegularAtlasTileAnimation {
  const factory _ProjectRegularAtlasTileAnimation(
          {required final int tileId,
          required final List<ProjectImageCollectionAnimationFrame> frames}) =
      _$ProjectRegularAtlasTileAnimationImpl;

  factory _ProjectRegularAtlasTileAnimation.fromJson(
          Map<String, dynamic> json) =
      _$ProjectRegularAtlasTileAnimationImpl.fromJson;

  @override
  int get tileId;
  @override
  List<ProjectImageCollectionAnimationFrame> get frames;

  /// Create a copy of ProjectRegularAtlasTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectRegularAtlasTileAnimationImplCopyWith<
          _$ProjectRegularAtlasTileAnimationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectImageCollectionTileDefinition
    _$ProjectImageCollectionTileDefinitionFromJson(Map<String, dynamic> json) {
  return _ProjectImageCollectionTileDefinition.fromJson(json);
}

/// @nodoc
mixin _$ProjectImageCollectionTileDefinition {
  int get tileId => throw _privateConstructorUsedError;
  String get pageId => throw _privateConstructorUsedError;
  ProjectTilesetPixelRect get sourceRect => throw _privateConstructorUsedError;
  int get offsetX => throw _privateConstructorUsedError;
  int get offsetY => throw _privateConstructorUsedError;
  List<ProjectImageCollectionAnimationFrame> get animation =>
      throw _privateConstructorUsedError;
  List<ProjectTilesetProperty> get properties =>
      throw _privateConstructorUsedError;
  List<ProjectTilesetCollisionObject> get collisionObjects =>
      throw _privateConstructorUsedError;

  /// Serializes this ProjectImageCollectionTileDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectImageCollectionTileDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectImageCollectionTileDefinitionCopyWith<
          ProjectImageCollectionTileDefinition>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectImageCollectionTileDefinitionCopyWith<$Res> {
  factory $ProjectImageCollectionTileDefinitionCopyWith(
          ProjectImageCollectionTileDefinition value,
          $Res Function(ProjectImageCollectionTileDefinition) then) =
      _$ProjectImageCollectionTileDefinitionCopyWithImpl<$Res,
          ProjectImageCollectionTileDefinition>;
  @useResult
  $Res call(
      {int tileId,
      String pageId,
      ProjectTilesetPixelRect sourceRect,
      int offsetX,
      int offsetY,
      List<ProjectImageCollectionAnimationFrame> animation,
      List<ProjectTilesetProperty> properties,
      List<ProjectTilesetCollisionObject> collisionObjects});

  $ProjectTilesetPixelRectCopyWith<$Res> get sourceRect;
}

/// @nodoc
class _$ProjectImageCollectionTileDefinitionCopyWithImpl<$Res,
        $Val extends ProjectImageCollectionTileDefinition>
    implements $ProjectImageCollectionTileDefinitionCopyWith<$Res> {
  _$ProjectImageCollectionTileDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectImageCollectionTileDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? pageId = null,
    Object? sourceRect = null,
    Object? offsetX = null,
    Object? offsetY = null,
    Object? animation = null,
    Object? properties = null,
    Object? collisionObjects = null,
  }) {
    return _then(_value.copyWith(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceRect: null == sourceRect
          ? _value.sourceRect
          : sourceRect // ignore: cast_nullable_to_non_nullable
              as ProjectTilesetPixelRect,
      offsetX: null == offsetX
          ? _value.offsetX
          : offsetX // ignore: cast_nullable_to_non_nullable
              as int,
      offsetY: null == offsetY
          ? _value.offsetY
          : offsetY // ignore: cast_nullable_to_non_nullable
              as int,
      animation: null == animation
          ? _value.animation
          : animation // ignore: cast_nullable_to_non_nullable
              as List<ProjectImageCollectionAnimationFrame>,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetProperty>,
      collisionObjects: null == collisionObjects
          ? _value.collisionObjects
          : collisionObjects // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetCollisionObject>,
    ) as $Val);
  }

  /// Create a copy of ProjectImageCollectionTileDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectTilesetPixelRectCopyWith<$Res> get sourceRect {
    return $ProjectTilesetPixelRectCopyWith<$Res>(_value.sourceRect, (value) {
      return _then(_value.copyWith(sourceRect: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectImageCollectionTileDefinitionImplCopyWith<$Res>
    implements $ProjectImageCollectionTileDefinitionCopyWith<$Res> {
  factory _$$ProjectImageCollectionTileDefinitionImplCopyWith(
          _$ProjectImageCollectionTileDefinitionImpl value,
          $Res Function(_$ProjectImageCollectionTileDefinitionImpl) then) =
      __$$ProjectImageCollectionTileDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int tileId,
      String pageId,
      ProjectTilesetPixelRect sourceRect,
      int offsetX,
      int offsetY,
      List<ProjectImageCollectionAnimationFrame> animation,
      List<ProjectTilesetProperty> properties,
      List<ProjectTilesetCollisionObject> collisionObjects});

  @override
  $ProjectTilesetPixelRectCopyWith<$Res> get sourceRect;
}

/// @nodoc
class __$$ProjectImageCollectionTileDefinitionImplCopyWithImpl<$Res>
    extends _$ProjectImageCollectionTileDefinitionCopyWithImpl<$Res,
        _$ProjectImageCollectionTileDefinitionImpl>
    implements _$$ProjectImageCollectionTileDefinitionImplCopyWith<$Res> {
  __$$ProjectImageCollectionTileDefinitionImplCopyWithImpl(
      _$ProjectImageCollectionTileDefinitionImpl _value,
      $Res Function(_$ProjectImageCollectionTileDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectImageCollectionTileDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? pageId = null,
    Object? sourceRect = null,
    Object? offsetX = null,
    Object? offsetY = null,
    Object? animation = null,
    Object? properties = null,
    Object? collisionObjects = null,
  }) {
    return _then(_$ProjectImageCollectionTileDefinitionImpl(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceRect: null == sourceRect
          ? _value.sourceRect
          : sourceRect // ignore: cast_nullable_to_non_nullable
              as ProjectTilesetPixelRect,
      offsetX: null == offsetX
          ? _value.offsetX
          : offsetX // ignore: cast_nullable_to_non_nullable
              as int,
      offsetY: null == offsetY
          ? _value.offsetY
          : offsetY // ignore: cast_nullable_to_non_nullable
              as int,
      animation: null == animation
          ? _value._animation
          : animation // ignore: cast_nullable_to_non_nullable
              as List<ProjectImageCollectionAnimationFrame>,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetProperty>,
      collisionObjects: null == collisionObjects
          ? _value._collisionObjects
          : collisionObjects // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetCollisionObject>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectImageCollectionTileDefinitionImpl
    implements _ProjectImageCollectionTileDefinition {
  const _$ProjectImageCollectionTileDefinitionImpl(
      {required this.tileId,
      required this.pageId,
      required this.sourceRect,
      this.offsetX = 0,
      this.offsetY = 0,
      final List<ProjectImageCollectionAnimationFrame> animation =
          const <ProjectImageCollectionAnimationFrame>[],
      final List<ProjectTilesetProperty> properties =
          const <ProjectTilesetProperty>[],
      final List<ProjectTilesetCollisionObject> collisionObjects =
          const <ProjectTilesetCollisionObject>[]})
      : _animation = animation,
        _properties = properties,
        _collisionObjects = collisionObjects;

  factory _$ProjectImageCollectionTileDefinitionImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectImageCollectionTileDefinitionImplFromJson(json);

  @override
  final int tileId;
  @override
  final String pageId;
  @override
  final ProjectTilesetPixelRect sourceRect;
  @override
  @JsonKey()
  final int offsetX;
  @override
  @JsonKey()
  final int offsetY;
  final List<ProjectImageCollectionAnimationFrame> _animation;
  @override
  @JsonKey()
  List<ProjectImageCollectionAnimationFrame> get animation {
    if (_animation is EqualUnmodifiableListView) return _animation;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_animation);
  }

  final List<ProjectTilesetProperty> _properties;
  @override
  @JsonKey()
  List<ProjectTilesetProperty> get properties {
    if (_properties is EqualUnmodifiableListView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_properties);
  }

  final List<ProjectTilesetCollisionObject> _collisionObjects;
  @override
  @JsonKey()
  List<ProjectTilesetCollisionObject> get collisionObjects {
    if (_collisionObjects is EqualUnmodifiableListView)
      return _collisionObjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_collisionObjects);
  }

  @override
  String toString() {
    return 'ProjectImageCollectionTileDefinition(tileId: $tileId, pageId: $pageId, sourceRect: $sourceRect, offsetX: $offsetX, offsetY: $offsetY, animation: $animation, properties: $properties, collisionObjects: $collisionObjects)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImageCollectionTileDefinitionImpl &&
            (identical(other.tileId, tileId) || other.tileId == tileId) &&
            (identical(other.pageId, pageId) || other.pageId == pageId) &&
            (identical(other.sourceRect, sourceRect) ||
                other.sourceRect == sourceRect) &&
            (identical(other.offsetX, offsetX) || other.offsetX == offsetX) &&
            (identical(other.offsetY, offsetY) || other.offsetY == offsetY) &&
            const DeepCollectionEquality()
                .equals(other._animation, _animation) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties) &&
            const DeepCollectionEquality()
                .equals(other._collisionObjects, _collisionObjects));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      tileId,
      pageId,
      sourceRect,
      offsetX,
      offsetY,
      const DeepCollectionEquality().hash(_animation),
      const DeepCollectionEquality().hash(_properties),
      const DeepCollectionEquality().hash(_collisionObjects));

  /// Create a copy of ProjectImageCollectionTileDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImageCollectionTileDefinitionImplCopyWith<
          _$ProjectImageCollectionTileDefinitionImpl>
      get copyWith => __$$ProjectImageCollectionTileDefinitionImplCopyWithImpl<
          _$ProjectImageCollectionTileDefinitionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImageCollectionTileDefinitionImplToJson(
      this,
    );
  }
}

abstract class _ProjectImageCollectionTileDefinition
    implements ProjectImageCollectionTileDefinition {
  const factory _ProjectImageCollectionTileDefinition(
          {required final int tileId,
          required final String pageId,
          required final ProjectTilesetPixelRect sourceRect,
          final int offsetX,
          final int offsetY,
          final List<ProjectImageCollectionAnimationFrame> animation,
          final List<ProjectTilesetProperty> properties,
          final List<ProjectTilesetCollisionObject> collisionObjects}) =
      _$ProjectImageCollectionTileDefinitionImpl;

  factory _ProjectImageCollectionTileDefinition.fromJson(
          Map<String, dynamic> json) =
      _$ProjectImageCollectionTileDefinitionImpl.fromJson;

  @override
  int get tileId;
  @override
  String get pageId;
  @override
  ProjectTilesetPixelRect get sourceRect;
  @override
  int get offsetX;
  @override
  int get offsetY;
  @override
  List<ProjectImageCollectionAnimationFrame> get animation;
  @override
  List<ProjectTilesetProperty> get properties;
  @override
  List<ProjectTilesetCollisionObject> get collisionObjects;

  /// Create a copy of ProjectImageCollectionTileDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectImageCollectionTileDefinitionImplCopyWith<
          _$ProjectImageCollectionTileDefinitionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
