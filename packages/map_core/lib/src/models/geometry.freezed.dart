// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geometry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GridPos _$GridPosFromJson(Map<String, dynamic> json) {
  return _GridPos.fromJson(json);
}

/// @nodoc
mixin _$GridPos {
  int get x => throw _privateConstructorUsedError;
  int get y => throw _privateConstructorUsedError;

  /// Serializes this GridPos to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GridPos
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GridPosCopyWith<GridPos> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GridPosCopyWith<$Res> {
  factory $GridPosCopyWith(GridPos value, $Res Function(GridPos) then) =
      _$GridPosCopyWithImpl<$Res, GridPos>;
  @useResult
  $Res call({int x, int y});
}

/// @nodoc
class _$GridPosCopyWithImpl<$Res, $Val extends GridPos>
    implements $GridPosCopyWith<$Res> {
  _$GridPosCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GridPos
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
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GridPosImplCopyWith<$Res> implements $GridPosCopyWith<$Res> {
  factory _$$GridPosImplCopyWith(
          _$GridPosImpl value, $Res Function(_$GridPosImpl) then) =
      __$$GridPosImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int x, int y});
}

/// @nodoc
class __$$GridPosImplCopyWithImpl<$Res>
    extends _$GridPosCopyWithImpl<$Res, _$GridPosImpl>
    implements _$$GridPosImplCopyWith<$Res> {
  __$$GridPosImplCopyWithImpl(
      _$GridPosImpl _value, $Res Function(_$GridPosImpl) _then)
      : super(_value, _then);

  /// Create a copy of GridPos
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_$GridPosImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GridPosImpl implements _GridPos {
  const _$GridPosImpl({required this.x, required this.y});

  factory _$GridPosImpl.fromJson(Map<String, dynamic> json) =>
      _$$GridPosImplFromJson(json);

  @override
  final int x;
  @override
  final int y;

  @override
  String toString() {
    return 'GridPos(x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GridPosImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y);

  /// Create a copy of GridPos
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GridPosImplCopyWith<_$GridPosImpl> get copyWith =>
      __$$GridPosImplCopyWithImpl<_$GridPosImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GridPosImplToJson(
      this,
    );
  }
}

abstract class _GridPos implements GridPos {
  const factory _GridPos({required final int x, required final int y}) =
      _$GridPosImpl;

  factory _GridPos.fromJson(Map<String, dynamic> json) = _$GridPosImpl.fromJson;

  @override
  int get x;
  @override
  int get y;

  /// Create a copy of GridPos
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GridPosImplCopyWith<_$GridPosImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GridSize _$GridSizeFromJson(Map<String, dynamic> json) {
  return _GridSize.fromJson(json);
}

/// @nodoc
mixin _$GridSize {
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;

  /// Serializes this GridSize to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GridSize
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GridSizeCopyWith<GridSize> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GridSizeCopyWith<$Res> {
  factory $GridSizeCopyWith(GridSize value, $Res Function(GridSize) then) =
      _$GridSizeCopyWithImpl<$Res, GridSize>;
  @useResult
  $Res call({int width, int height});
}

/// @nodoc
class _$GridSizeCopyWithImpl<$Res, $Val extends GridSize>
    implements $GridSizeCopyWith<$Res> {
  _$GridSizeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GridSize
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_value.copyWith(
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
abstract class _$$GridSizeImplCopyWith<$Res>
    implements $GridSizeCopyWith<$Res> {
  factory _$$GridSizeImplCopyWith(
          _$GridSizeImpl value, $Res Function(_$GridSizeImpl) then) =
      __$$GridSizeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int width, int height});
}

/// @nodoc
class __$$GridSizeImplCopyWithImpl<$Res>
    extends _$GridSizeCopyWithImpl<$Res, _$GridSizeImpl>
    implements _$$GridSizeImplCopyWith<$Res> {
  __$$GridSizeImplCopyWithImpl(
      _$GridSizeImpl _value, $Res Function(_$GridSizeImpl) _then)
      : super(_value, _then);

  /// Create a copy of GridSize
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$GridSizeImpl(
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
class _$GridSizeImpl implements _GridSize {
  const _$GridSizeImpl({required this.width, required this.height});

  factory _$GridSizeImpl.fromJson(Map<String, dynamic> json) =>
      _$$GridSizeImplFromJson(json);

  @override
  final int width;
  @override
  final int height;

  @override
  String toString() {
    return 'GridSize(width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GridSizeImpl &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, width, height);

  /// Create a copy of GridSize
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GridSizeImplCopyWith<_$GridSizeImpl> get copyWith =>
      __$$GridSizeImplCopyWithImpl<_$GridSizeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GridSizeImplToJson(
      this,
    );
  }
}

abstract class _GridSize implements GridSize {
  const factory _GridSize(
      {required final int width, required final int height}) = _$GridSizeImpl;

  factory _GridSize.fromJson(Map<String, dynamic> json) =
      _$GridSizeImpl.fromJson;

  @override
  int get width;
  @override
  int get height;

  /// Create a copy of GridSize
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GridSizeImplCopyWith<_$GridSizeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapRect _$MapRectFromJson(Map<String, dynamic> json) {
  return _MapRect.fromJson(json);
}

/// @nodoc
mixin _$MapRect {
  GridPos get pos => throw _privateConstructorUsedError;
  GridSize get size => throw _privateConstructorUsedError;

  /// Serializes this MapRect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapRectCopyWith<MapRect> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapRectCopyWith<$Res> {
  factory $MapRectCopyWith(MapRect value, $Res Function(MapRect) then) =
      _$MapRectCopyWithImpl<$Res, MapRect>;
  @useResult
  $Res call({GridPos pos, GridSize size});

  $GridPosCopyWith<$Res> get pos;
  $GridSizeCopyWith<$Res> get size;
}

/// @nodoc
class _$MapRectCopyWithImpl<$Res, $Val extends MapRect>
    implements $MapRectCopyWith<$Res> {
  _$MapRectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pos = null,
    Object? size = null,
  }) {
    return _then(_value.copyWith(
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
    ) as $Val);
  }

  /// Create a copy of MapRect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get pos {
    return $GridPosCopyWith<$Res>(_value.pos, (value) {
      return _then(_value.copyWith(pos: value) as $Val);
    });
  }

  /// Create a copy of MapRect
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
abstract class _$$MapRectImplCopyWith<$Res> implements $MapRectCopyWith<$Res> {
  factory _$$MapRectImplCopyWith(
          _$MapRectImpl value, $Res Function(_$MapRectImpl) then) =
      __$$MapRectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({GridPos pos, GridSize size});

  @override
  $GridPosCopyWith<$Res> get pos;
  @override
  $GridSizeCopyWith<$Res> get size;
}

/// @nodoc
class __$$MapRectImplCopyWithImpl<$Res>
    extends _$MapRectCopyWithImpl<$Res, _$MapRectImpl>
    implements _$$MapRectImplCopyWith<$Res> {
  __$$MapRectImplCopyWithImpl(
      _$MapRectImpl _value, $Res Function(_$MapRectImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pos = null,
    Object? size = null,
  }) {
    return _then(_$MapRectImpl(
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MapRectImpl implements _MapRect {
  const _$MapRectImpl({required this.pos, required this.size});

  factory _$MapRectImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapRectImplFromJson(json);

  @override
  final GridPos pos;
  @override
  final GridSize size;

  @override
  String toString() {
    return 'MapRect(pos: $pos, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapRectImpl &&
            (identical(other.pos, pos) || other.pos == pos) &&
            (identical(other.size, size) || other.size == size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pos, size);

  /// Create a copy of MapRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapRectImplCopyWith<_$MapRectImpl> get copyWith =>
      __$$MapRectImplCopyWithImpl<_$MapRectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapRectImplToJson(
      this,
    );
  }
}

abstract class _MapRect implements MapRect {
  const factory _MapRect(
      {required final GridPos pos,
      required final GridSize size}) = _$MapRectImpl;

  factory _MapRect.fromJson(Map<String, dynamic> json) = _$MapRectImpl.fromJson;

  @override
  GridPos get pos;
  @override
  GridSize get size;

  /// Create a copy of MapRect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapRectImplCopyWith<_$MapRectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
