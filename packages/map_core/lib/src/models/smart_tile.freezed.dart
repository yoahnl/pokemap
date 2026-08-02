// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'smart_tile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SmartTileSourceRect _$SmartTileSourceRectFromJson(Map<String, dynamic> json) {
  return _SmartTileSourceRect.fromJson(json);
}

/// @nodoc
mixin _$SmartTileSourceRect {
  int get x => throw _privateConstructorUsedError;
  int get y => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;

  /// Serializes this SmartTileSourceRect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileSourceRectCopyWith<SmartTileSourceRect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileSourceRectCopyWith<$Res> {
  factory $SmartTileSourceRectCopyWith(
          SmartTileSourceRect value, $Res Function(SmartTileSourceRect) then) =
      _$SmartTileSourceRectCopyWithImpl<$Res, SmartTileSourceRect>;
  @useResult
  $Res call({int x, int y, int width, int height});
}

/// @nodoc
class _$SmartTileSourceRectCopyWithImpl<$Res, $Val extends SmartTileSourceRect>
    implements $SmartTileSourceRectCopyWith<$Res> {
  _$SmartTileSourceRectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileSourceRect
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
abstract class _$$SmartTileSourceRectImplCopyWith<$Res>
    implements $SmartTileSourceRectCopyWith<$Res> {
  factory _$$SmartTileSourceRectImplCopyWith(_$SmartTileSourceRectImpl value,
          $Res Function(_$SmartTileSourceRectImpl) then) =
      __$$SmartTileSourceRectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int x, int y, int width, int height});
}

/// @nodoc
class __$$SmartTileSourceRectImplCopyWithImpl<$Res>
    extends _$SmartTileSourceRectCopyWithImpl<$Res, _$SmartTileSourceRectImpl>
    implements _$$SmartTileSourceRectImplCopyWith<$Res> {
  __$$SmartTileSourceRectImplCopyWithImpl(_$SmartTileSourceRectImpl _value,
      $Res Function(_$SmartTileSourceRectImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$SmartTileSourceRectImpl(
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
class _$SmartTileSourceRectImpl implements _SmartTileSourceRect {
  const _$SmartTileSourceRectImpl(
      {required this.x,
      required this.y,
      required this.width,
      required this.height})
      : assert(x >= 0, 'x must not be negative'),
        assert(y >= 0, 'y must not be negative'),
        assert(width > 0, 'width must be positive'),
        assert(height > 0, 'height must be positive');

  factory _$SmartTileSourceRectImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileSourceRectImplFromJson(json);

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
    return 'SmartTileSourceRect(x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileSourceRectImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, width, height);

  /// Create a copy of SmartTileSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileSourceRectImplCopyWith<_$SmartTileSourceRectImpl> get copyWith =>
      __$$SmartTileSourceRectImplCopyWithImpl<_$SmartTileSourceRectImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileSourceRectImplToJson(
      this,
    );
  }
}

abstract class _SmartTileSourceRect implements SmartTileSourceRect {
  const factory _SmartTileSourceRect(
      {required final int x,
      required final int y,
      required final int width,
      required final int height}) = _$SmartTileSourceRectImpl;

  factory _SmartTileSourceRect.fromJson(Map<String, dynamic> json) =
      _$SmartTileSourceRectImpl.fromJson;

  @override
  int get x;
  @override
  int get y;
  @override
  int get width;
  @override
  int get height;

  /// Create a copy of SmartTileSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileSourceRectImplCopyWith<_$SmartTileSourceRectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SmartTileFrameRef _$SmartTileFrameRefFromJson(Map<String, dynamic> json) {
  return _SmartTileFrameRef.fromJson(json);
}

/// @nodoc
mixin _$SmartTileFrameRef {
  String get atlasId => throw _privateConstructorUsedError;
  int get column => throw _privateConstructorUsedError;
  int get row => throw _privateConstructorUsedError;
  int get columnSpan => throw _privateConstructorUsedError;
  int get rowSpan => throw _privateConstructorUsedError;

  /// Serializes this SmartTileFrameRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileFrameRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileFrameRefCopyWith<SmartTileFrameRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileFrameRefCopyWith<$Res> {
  factory $SmartTileFrameRefCopyWith(
          SmartTileFrameRef value, $Res Function(SmartTileFrameRef) then) =
      _$SmartTileFrameRefCopyWithImpl<$Res, SmartTileFrameRef>;
  @useResult
  $Res call({String atlasId, int column, int row, int columnSpan, int rowSpan});
}

/// @nodoc
class _$SmartTileFrameRefCopyWithImpl<$Res, $Val extends SmartTileFrameRef>
    implements $SmartTileFrameRefCopyWith<$Res> {
  _$SmartTileFrameRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileFrameRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? atlasId = null,
    Object? column = null,
    Object? row = null,
    Object? columnSpan = null,
    Object? rowSpan = null,
  }) {
    return _then(_value.copyWith(
      atlasId: null == atlasId
          ? _value.atlasId
          : atlasId // ignore: cast_nullable_to_non_nullable
              as String,
      column: null == column
          ? _value.column
          : column // ignore: cast_nullable_to_non_nullable
              as int,
      row: null == row
          ? _value.row
          : row // ignore: cast_nullable_to_non_nullable
              as int,
      columnSpan: null == columnSpan
          ? _value.columnSpan
          : columnSpan // ignore: cast_nullable_to_non_nullable
              as int,
      rowSpan: null == rowSpan
          ? _value.rowSpan
          : rowSpan // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SmartTileFrameRefImplCopyWith<$Res>
    implements $SmartTileFrameRefCopyWith<$Res> {
  factory _$$SmartTileFrameRefImplCopyWith(_$SmartTileFrameRefImpl value,
          $Res Function(_$SmartTileFrameRefImpl) then) =
      __$$SmartTileFrameRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String atlasId, int column, int row, int columnSpan, int rowSpan});
}

/// @nodoc
class __$$SmartTileFrameRefImplCopyWithImpl<$Res>
    extends _$SmartTileFrameRefCopyWithImpl<$Res, _$SmartTileFrameRefImpl>
    implements _$$SmartTileFrameRefImplCopyWith<$Res> {
  __$$SmartTileFrameRefImplCopyWithImpl(_$SmartTileFrameRefImpl _value,
      $Res Function(_$SmartTileFrameRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileFrameRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? atlasId = null,
    Object? column = null,
    Object? row = null,
    Object? columnSpan = null,
    Object? rowSpan = null,
  }) {
    return _then(_$SmartTileFrameRefImpl(
      atlasId: null == atlasId
          ? _value.atlasId
          : atlasId // ignore: cast_nullable_to_non_nullable
              as String,
      column: null == column
          ? _value.column
          : column // ignore: cast_nullable_to_non_nullable
              as int,
      row: null == row
          ? _value.row
          : row // ignore: cast_nullable_to_non_nullable
              as int,
      columnSpan: null == columnSpan
          ? _value.columnSpan
          : columnSpan // ignore: cast_nullable_to_non_nullable
              as int,
      rowSpan: null == rowSpan
          ? _value.rowSpan
          : rowSpan // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SmartTileFrameRefImpl implements _SmartTileFrameRef {
  const _$SmartTileFrameRefImpl(
      {required this.atlasId,
      required this.column,
      required this.row,
      this.columnSpan = 1,
      this.rowSpan = 1})
      : assert(atlasId != "", 'atlasId must not be blank'),
        assert(column >= 0, 'column must not be negative'),
        assert(row >= 0, 'row must not be negative'),
        assert(columnSpan > 0, 'columnSpan must be positive'),
        assert(rowSpan > 0, 'rowSpan must be positive');

  factory _$SmartTileFrameRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileFrameRefImplFromJson(json);

  @override
  final String atlasId;
  @override
  final int column;
  @override
  final int row;
  @override
  @JsonKey()
  final int columnSpan;
  @override
  @JsonKey()
  final int rowSpan;

  @override
  String toString() {
    return 'SmartTileFrameRef(atlasId: $atlasId, column: $column, row: $row, columnSpan: $columnSpan, rowSpan: $rowSpan)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileFrameRefImpl &&
            (identical(other.atlasId, atlasId) || other.atlasId == atlasId) &&
            (identical(other.column, column) || other.column == column) &&
            (identical(other.row, row) || other.row == row) &&
            (identical(other.columnSpan, columnSpan) ||
                other.columnSpan == columnSpan) &&
            (identical(other.rowSpan, rowSpan) || other.rowSpan == rowSpan));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, atlasId, column, row, columnSpan, rowSpan);

  /// Create a copy of SmartTileFrameRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileFrameRefImplCopyWith<_$SmartTileFrameRefImpl> get copyWith =>
      __$$SmartTileFrameRefImplCopyWithImpl<_$SmartTileFrameRefImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileFrameRefImplToJson(
      this,
    );
  }
}

abstract class _SmartTileFrameRef implements SmartTileFrameRef {
  const factory _SmartTileFrameRef(
      {required final String atlasId,
      required final int column,
      required final int row,
      final int columnSpan,
      final int rowSpan}) = _$SmartTileFrameRefImpl;

  factory _SmartTileFrameRef.fromJson(Map<String, dynamic> json) =
      _$SmartTileFrameRefImpl.fromJson;

  @override
  String get atlasId;
  @override
  int get column;
  @override
  int get row;
  @override
  int get columnSpan;
  @override
  int get rowSpan;

  /// Create a copy of SmartTileFrameRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileFrameRefImplCopyWith<_$SmartTileFrameRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SmartTileSignature _$SmartTileSignatureFromJson(Map<String, dynamic> json) {
  return _SmartTileSignature.fromJson(json);
}

/// @nodoc
mixin _$SmartTileSignature {
  SmartTileSlotMatch get northWestCorner => throw _privateConstructorUsedError;
  SmartTileSlotMatch get northEdge => throw _privateConstructorUsedError;
  SmartTileSlotMatch get northEastCorner => throw _privateConstructorUsedError;
  SmartTileSlotMatch get eastEdge => throw _privateConstructorUsedError;
  SmartTileSlotMatch get southEastCorner => throw _privateConstructorUsedError;
  SmartTileSlotMatch get southEdge => throw _privateConstructorUsedError;
  SmartTileSlotMatch get southWestCorner => throw _privateConstructorUsedError;
  SmartTileSlotMatch get westEdge => throw _privateConstructorUsedError;

  /// Serializes this SmartTileSignature to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileSignature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileSignatureCopyWith<SmartTileSignature> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileSignatureCopyWith<$Res> {
  factory $SmartTileSignatureCopyWith(
          SmartTileSignature value, $Res Function(SmartTileSignature) then) =
      _$SmartTileSignatureCopyWithImpl<$Res, SmartTileSignature>;
  @useResult
  $Res call(
      {SmartTileSlotMatch northWestCorner,
      SmartTileSlotMatch northEdge,
      SmartTileSlotMatch northEastCorner,
      SmartTileSlotMatch eastEdge,
      SmartTileSlotMatch southEastCorner,
      SmartTileSlotMatch southEdge,
      SmartTileSlotMatch southWestCorner,
      SmartTileSlotMatch westEdge});
}

/// @nodoc
class _$SmartTileSignatureCopyWithImpl<$Res, $Val extends SmartTileSignature>
    implements $SmartTileSignatureCopyWith<$Res> {
  _$SmartTileSignatureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileSignature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? northWestCorner = null,
    Object? northEdge = null,
    Object? northEastCorner = null,
    Object? eastEdge = null,
    Object? southEastCorner = null,
    Object? southEdge = null,
    Object? southWestCorner = null,
    Object? westEdge = null,
  }) {
    return _then(_value.copyWith(
      northWestCorner: null == northWestCorner
          ? _value.northWestCorner
          : northWestCorner // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      northEdge: null == northEdge
          ? _value.northEdge
          : northEdge // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      northEastCorner: null == northEastCorner
          ? _value.northEastCorner
          : northEastCorner // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      eastEdge: null == eastEdge
          ? _value.eastEdge
          : eastEdge // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      southEastCorner: null == southEastCorner
          ? _value.southEastCorner
          : southEastCorner // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      southEdge: null == southEdge
          ? _value.southEdge
          : southEdge // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      southWestCorner: null == southWestCorner
          ? _value.southWestCorner
          : southWestCorner // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      westEdge: null == westEdge
          ? _value.westEdge
          : westEdge // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SmartTileSignatureImplCopyWith<$Res>
    implements $SmartTileSignatureCopyWith<$Res> {
  factory _$$SmartTileSignatureImplCopyWith(_$SmartTileSignatureImpl value,
          $Res Function(_$SmartTileSignatureImpl) then) =
      __$$SmartTileSignatureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SmartTileSlotMatch northWestCorner,
      SmartTileSlotMatch northEdge,
      SmartTileSlotMatch northEastCorner,
      SmartTileSlotMatch eastEdge,
      SmartTileSlotMatch southEastCorner,
      SmartTileSlotMatch southEdge,
      SmartTileSlotMatch southWestCorner,
      SmartTileSlotMatch westEdge});
}

/// @nodoc
class __$$SmartTileSignatureImplCopyWithImpl<$Res>
    extends _$SmartTileSignatureCopyWithImpl<$Res, _$SmartTileSignatureImpl>
    implements _$$SmartTileSignatureImplCopyWith<$Res> {
  __$$SmartTileSignatureImplCopyWithImpl(_$SmartTileSignatureImpl _value,
      $Res Function(_$SmartTileSignatureImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileSignature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? northWestCorner = null,
    Object? northEdge = null,
    Object? northEastCorner = null,
    Object? eastEdge = null,
    Object? southEastCorner = null,
    Object? southEdge = null,
    Object? southWestCorner = null,
    Object? westEdge = null,
  }) {
    return _then(_$SmartTileSignatureImpl(
      northWestCorner: null == northWestCorner
          ? _value.northWestCorner
          : northWestCorner // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      northEdge: null == northEdge
          ? _value.northEdge
          : northEdge // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      northEastCorner: null == northEastCorner
          ? _value.northEastCorner
          : northEastCorner // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      eastEdge: null == eastEdge
          ? _value.eastEdge
          : eastEdge // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      southEastCorner: null == southEastCorner
          ? _value.southEastCorner
          : southEastCorner // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      southEdge: null == southEdge
          ? _value.southEdge
          : southEdge // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      southWestCorner: null == southWestCorner
          ? _value.southWestCorner
          : southWestCorner // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      westEdge: null == westEdge
          ? _value.westEdge
          : westEdge // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileSignatureImpl implements _SmartTileSignature {
  const _$SmartTileSignatureImpl(
      {this.northWestCorner = const SmartTileSlotMatch.any(),
      this.northEdge = const SmartTileSlotMatch.any(),
      this.northEastCorner = const SmartTileSlotMatch.any(),
      this.eastEdge = const SmartTileSlotMatch.any(),
      this.southEastCorner = const SmartTileSlotMatch.any(),
      this.southEdge = const SmartTileSlotMatch.any(),
      this.southWestCorner = const SmartTileSlotMatch.any(),
      this.westEdge = const SmartTileSlotMatch.any()});

  factory _$SmartTileSignatureImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileSignatureImplFromJson(json);

  @override
  @JsonKey()
  final SmartTileSlotMatch northWestCorner;
  @override
  @JsonKey()
  final SmartTileSlotMatch northEdge;
  @override
  @JsonKey()
  final SmartTileSlotMatch northEastCorner;
  @override
  @JsonKey()
  final SmartTileSlotMatch eastEdge;
  @override
  @JsonKey()
  final SmartTileSlotMatch southEastCorner;
  @override
  @JsonKey()
  final SmartTileSlotMatch southEdge;
  @override
  @JsonKey()
  final SmartTileSlotMatch southWestCorner;
  @override
  @JsonKey()
  final SmartTileSlotMatch westEdge;

  @override
  String toString() {
    return 'SmartTileSignature(northWestCorner: $northWestCorner, northEdge: $northEdge, northEastCorner: $northEastCorner, eastEdge: $eastEdge, southEastCorner: $southEastCorner, southEdge: $southEdge, southWestCorner: $southWestCorner, westEdge: $westEdge)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileSignatureImpl &&
            (identical(other.northWestCorner, northWestCorner) ||
                other.northWestCorner == northWestCorner) &&
            (identical(other.northEdge, northEdge) ||
                other.northEdge == northEdge) &&
            (identical(other.northEastCorner, northEastCorner) ||
                other.northEastCorner == northEastCorner) &&
            (identical(other.eastEdge, eastEdge) ||
                other.eastEdge == eastEdge) &&
            (identical(other.southEastCorner, southEastCorner) ||
                other.southEastCorner == southEastCorner) &&
            (identical(other.southEdge, southEdge) ||
                other.southEdge == southEdge) &&
            (identical(other.southWestCorner, southWestCorner) ||
                other.southWestCorner == southWestCorner) &&
            (identical(other.westEdge, westEdge) ||
                other.westEdge == westEdge));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      northWestCorner,
      northEdge,
      northEastCorner,
      eastEdge,
      southEastCorner,
      southEdge,
      southWestCorner,
      westEdge);

  /// Create a copy of SmartTileSignature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileSignatureImplCopyWith<_$SmartTileSignatureImpl> get copyWith =>
      __$$SmartTileSignatureImplCopyWithImpl<_$SmartTileSignatureImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileSignatureImplToJson(
      this,
    );
  }
}

abstract class _SmartTileSignature implements SmartTileSignature {
  const factory _SmartTileSignature(
      {final SmartTileSlotMatch northWestCorner,
      final SmartTileSlotMatch northEdge,
      final SmartTileSlotMatch northEastCorner,
      final SmartTileSlotMatch eastEdge,
      final SmartTileSlotMatch southEastCorner,
      final SmartTileSlotMatch southEdge,
      final SmartTileSlotMatch southWestCorner,
      final SmartTileSlotMatch westEdge}) = _$SmartTileSignatureImpl;

  factory _SmartTileSignature.fromJson(Map<String, dynamic> json) =
      _$SmartTileSignatureImpl.fromJson;

  @override
  SmartTileSlotMatch get northWestCorner;
  @override
  SmartTileSlotMatch get northEdge;
  @override
  SmartTileSlotMatch get northEastCorner;
  @override
  SmartTileSlotMatch get eastEdge;
  @override
  SmartTileSlotMatch get southEastCorner;
  @override
  SmartTileSlotMatch get southEdge;
  @override
  SmartTileSlotMatch get southWestCorner;
  @override
  SmartTileSlotMatch get westEdge;

  /// Create a copy of SmartTileSignature
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileSignatureImplCopyWith<_$SmartTileSignatureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SmartTileExactSignature _$SmartTileExactSignatureFromJson(
    Map<String, dynamic> json) {
  return _SmartTileExactSignature.fromJson(json);
}

/// @nodoc
mixin _$SmartTileExactSignature {
  String? get northEdge => throw _privateConstructorUsedError;
  String? get northEastCorner => throw _privateConstructorUsedError;
  String? get eastEdge => throw _privateConstructorUsedError;
  String? get southEastCorner => throw _privateConstructorUsedError;
  String? get southEdge => throw _privateConstructorUsedError;
  String? get southWestCorner => throw _privateConstructorUsedError;
  String? get westEdge => throw _privateConstructorUsedError;
  String? get northWestCorner => throw _privateConstructorUsedError;

  /// Serializes this SmartTileExactSignature to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileExactSignature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileExactSignatureCopyWith<SmartTileExactSignature> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileExactSignatureCopyWith<$Res> {
  factory $SmartTileExactSignatureCopyWith(SmartTileExactSignature value,
          $Res Function(SmartTileExactSignature) then) =
      _$SmartTileExactSignatureCopyWithImpl<$Res, SmartTileExactSignature>;
  @useResult
  $Res call(
      {String? northEdge,
      String? northEastCorner,
      String? eastEdge,
      String? southEastCorner,
      String? southEdge,
      String? southWestCorner,
      String? westEdge,
      String? northWestCorner});
}

/// @nodoc
class _$SmartTileExactSignatureCopyWithImpl<$Res,
        $Val extends SmartTileExactSignature>
    implements $SmartTileExactSignatureCopyWith<$Res> {
  _$SmartTileExactSignatureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileExactSignature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? northEdge = freezed,
    Object? northEastCorner = freezed,
    Object? eastEdge = freezed,
    Object? southEastCorner = freezed,
    Object? southEdge = freezed,
    Object? southWestCorner = freezed,
    Object? westEdge = freezed,
    Object? northWestCorner = freezed,
  }) {
    return _then(_value.copyWith(
      northEdge: freezed == northEdge
          ? _value.northEdge
          : northEdge // ignore: cast_nullable_to_non_nullable
              as String?,
      northEastCorner: freezed == northEastCorner
          ? _value.northEastCorner
          : northEastCorner // ignore: cast_nullable_to_non_nullable
              as String?,
      eastEdge: freezed == eastEdge
          ? _value.eastEdge
          : eastEdge // ignore: cast_nullable_to_non_nullable
              as String?,
      southEastCorner: freezed == southEastCorner
          ? _value.southEastCorner
          : southEastCorner // ignore: cast_nullable_to_non_nullable
              as String?,
      southEdge: freezed == southEdge
          ? _value.southEdge
          : southEdge // ignore: cast_nullable_to_non_nullable
              as String?,
      southWestCorner: freezed == southWestCorner
          ? _value.southWestCorner
          : southWestCorner // ignore: cast_nullable_to_non_nullable
              as String?,
      westEdge: freezed == westEdge
          ? _value.westEdge
          : westEdge // ignore: cast_nullable_to_non_nullable
              as String?,
      northWestCorner: freezed == northWestCorner
          ? _value.northWestCorner
          : northWestCorner // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SmartTileExactSignatureImplCopyWith<$Res>
    implements $SmartTileExactSignatureCopyWith<$Res> {
  factory _$$SmartTileExactSignatureImplCopyWith(
          _$SmartTileExactSignatureImpl value,
          $Res Function(_$SmartTileExactSignatureImpl) then) =
      __$$SmartTileExactSignatureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? northEdge,
      String? northEastCorner,
      String? eastEdge,
      String? southEastCorner,
      String? southEdge,
      String? southWestCorner,
      String? westEdge,
      String? northWestCorner});
}

/// @nodoc
class __$$SmartTileExactSignatureImplCopyWithImpl<$Res>
    extends _$SmartTileExactSignatureCopyWithImpl<$Res,
        _$SmartTileExactSignatureImpl>
    implements _$$SmartTileExactSignatureImplCopyWith<$Res> {
  __$$SmartTileExactSignatureImplCopyWithImpl(
      _$SmartTileExactSignatureImpl _value,
      $Res Function(_$SmartTileExactSignatureImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileExactSignature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? northEdge = freezed,
    Object? northEastCorner = freezed,
    Object? eastEdge = freezed,
    Object? southEastCorner = freezed,
    Object? southEdge = freezed,
    Object? southWestCorner = freezed,
    Object? westEdge = freezed,
    Object? northWestCorner = freezed,
  }) {
    return _then(_$SmartTileExactSignatureImpl(
      northEdge: freezed == northEdge
          ? _value.northEdge
          : northEdge // ignore: cast_nullable_to_non_nullable
              as String?,
      northEastCorner: freezed == northEastCorner
          ? _value.northEastCorner
          : northEastCorner // ignore: cast_nullable_to_non_nullable
              as String?,
      eastEdge: freezed == eastEdge
          ? _value.eastEdge
          : eastEdge // ignore: cast_nullable_to_non_nullable
              as String?,
      southEastCorner: freezed == southEastCorner
          ? _value.southEastCorner
          : southEastCorner // ignore: cast_nullable_to_non_nullable
              as String?,
      southEdge: freezed == southEdge
          ? _value.southEdge
          : southEdge // ignore: cast_nullable_to_non_nullable
              as String?,
      southWestCorner: freezed == southWestCorner
          ? _value.southWestCorner
          : southWestCorner // ignore: cast_nullable_to_non_nullable
              as String?,
      westEdge: freezed == westEdge
          ? _value.westEdge
          : westEdge // ignore: cast_nullable_to_non_nullable
              as String?,
      northWestCorner: freezed == northWestCorner
          ? _value.northWestCorner
          : northWestCorner // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileExactSignatureImpl implements _SmartTileExactSignature {
  const _$SmartTileExactSignatureImpl(
      {this.northEdge,
      this.northEastCorner,
      this.eastEdge,
      this.southEastCorner,
      this.southEdge,
      this.southWestCorner,
      this.westEdge,
      this.northWestCorner});

  factory _$SmartTileExactSignatureImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileExactSignatureImplFromJson(json);

  @override
  final String? northEdge;
  @override
  final String? northEastCorner;
  @override
  final String? eastEdge;
  @override
  final String? southEastCorner;
  @override
  final String? southEdge;
  @override
  final String? southWestCorner;
  @override
  final String? westEdge;
  @override
  final String? northWestCorner;

  @override
  String toString() {
    return 'SmartTileExactSignature(northEdge: $northEdge, northEastCorner: $northEastCorner, eastEdge: $eastEdge, southEastCorner: $southEastCorner, southEdge: $southEdge, southWestCorner: $southWestCorner, westEdge: $westEdge, northWestCorner: $northWestCorner)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileExactSignatureImpl &&
            (identical(other.northEdge, northEdge) ||
                other.northEdge == northEdge) &&
            (identical(other.northEastCorner, northEastCorner) ||
                other.northEastCorner == northEastCorner) &&
            (identical(other.eastEdge, eastEdge) ||
                other.eastEdge == eastEdge) &&
            (identical(other.southEastCorner, southEastCorner) ||
                other.southEastCorner == southEastCorner) &&
            (identical(other.southEdge, southEdge) ||
                other.southEdge == southEdge) &&
            (identical(other.southWestCorner, southWestCorner) ||
                other.southWestCorner == southWestCorner) &&
            (identical(other.westEdge, westEdge) ||
                other.westEdge == westEdge) &&
            (identical(other.northWestCorner, northWestCorner) ||
                other.northWestCorner == northWestCorner));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      northEdge,
      northEastCorner,
      eastEdge,
      southEastCorner,
      southEdge,
      southWestCorner,
      westEdge,
      northWestCorner);

  /// Create a copy of SmartTileExactSignature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileExactSignatureImplCopyWith<_$SmartTileExactSignatureImpl>
      get copyWith => __$$SmartTileExactSignatureImplCopyWithImpl<
          _$SmartTileExactSignatureImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileExactSignatureImplToJson(
      this,
    );
  }
}

abstract class _SmartTileExactSignature implements SmartTileExactSignature {
  const factory _SmartTileExactSignature(
      {final String? northEdge,
      final String? northEastCorner,
      final String? eastEdge,
      final String? southEastCorner,
      final String? southEdge,
      final String? southWestCorner,
      final String? westEdge,
      final String? northWestCorner}) = _$SmartTileExactSignatureImpl;

  factory _SmartTileExactSignature.fromJson(Map<String, dynamic> json) =
      _$SmartTileExactSignatureImpl.fromJson;

  @override
  String? get northEdge;
  @override
  String? get northEastCorner;
  @override
  String? get eastEdge;
  @override
  String? get southEastCorner;
  @override
  String? get southEdge;
  @override
  String? get southWestCorner;
  @override
  String? get westEdge;
  @override
  String? get northWestCorner;

  /// Create a copy of SmartTileExactSignature
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileExactSignatureImplCopyWith<_$SmartTileExactSignatureImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SmartTileCoverageScenario _$SmartTileCoverageScenarioFromJson(
    Map<String, dynamic> json) {
  return _SmartTileCoverageScenario.fromJson(json);
}

/// @nodoc
mixin _$SmartTileCoverageScenario {
  String get id => throw _privateConstructorUsedError;
  String? get centerMaterialId => throw _privateConstructorUsedError;
  SmartTileExactSignature get signature => throw _privateConstructorUsedError;

  /// Serializes this SmartTileCoverageScenario to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileCoverageScenario
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileCoverageScenarioCopyWith<SmartTileCoverageScenario> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileCoverageScenarioCopyWith<$Res> {
  factory $SmartTileCoverageScenarioCopyWith(SmartTileCoverageScenario value,
          $Res Function(SmartTileCoverageScenario) then) =
      _$SmartTileCoverageScenarioCopyWithImpl<$Res, SmartTileCoverageScenario>;
  @useResult
  $Res call(
      {String id, String? centerMaterialId, SmartTileExactSignature signature});

  $SmartTileExactSignatureCopyWith<$Res> get signature;
}

/// @nodoc
class _$SmartTileCoverageScenarioCopyWithImpl<$Res,
        $Val extends SmartTileCoverageScenario>
    implements $SmartTileCoverageScenarioCopyWith<$Res> {
  _$SmartTileCoverageScenarioCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileCoverageScenario
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? centerMaterialId = freezed,
    Object? signature = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      centerMaterialId: freezed == centerMaterialId
          ? _value.centerMaterialId
          : centerMaterialId // ignore: cast_nullable_to_non_nullable
              as String?,
      signature: null == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as SmartTileExactSignature,
    ) as $Val);
  }

  /// Create a copy of SmartTileCoverageScenario
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartTileExactSignatureCopyWith<$Res> get signature {
    return $SmartTileExactSignatureCopyWith<$Res>(_value.signature, (value) {
      return _then(_value.copyWith(signature: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SmartTileCoverageScenarioImplCopyWith<$Res>
    implements $SmartTileCoverageScenarioCopyWith<$Res> {
  factory _$$SmartTileCoverageScenarioImplCopyWith(
          _$SmartTileCoverageScenarioImpl value,
          $Res Function(_$SmartTileCoverageScenarioImpl) then) =
      __$$SmartTileCoverageScenarioImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String? centerMaterialId, SmartTileExactSignature signature});

  @override
  $SmartTileExactSignatureCopyWith<$Res> get signature;
}

/// @nodoc
class __$$SmartTileCoverageScenarioImplCopyWithImpl<$Res>
    extends _$SmartTileCoverageScenarioCopyWithImpl<$Res,
        _$SmartTileCoverageScenarioImpl>
    implements _$$SmartTileCoverageScenarioImplCopyWith<$Res> {
  __$$SmartTileCoverageScenarioImplCopyWithImpl(
      _$SmartTileCoverageScenarioImpl _value,
      $Res Function(_$SmartTileCoverageScenarioImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileCoverageScenario
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? centerMaterialId = freezed,
    Object? signature = null,
  }) {
    return _then(_$SmartTileCoverageScenarioImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      centerMaterialId: freezed == centerMaterialId
          ? _value.centerMaterialId
          : centerMaterialId // ignore: cast_nullable_to_non_nullable
              as String?,
      signature: null == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as SmartTileExactSignature,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileCoverageScenarioImpl implements _SmartTileCoverageScenario {
  const _$SmartTileCoverageScenarioImpl(
      {required this.id,
      this.centerMaterialId,
      this.signature = const SmartTileExactSignature()});

  factory _$SmartTileCoverageScenarioImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileCoverageScenarioImplFromJson(json);

  @override
  final String id;
  @override
  final String? centerMaterialId;
  @override
  @JsonKey()
  final SmartTileExactSignature signature;

  @override
  String toString() {
    return 'SmartTileCoverageScenario(id: $id, centerMaterialId: $centerMaterialId, signature: $signature)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileCoverageScenarioImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.centerMaterialId, centerMaterialId) ||
                other.centerMaterialId == centerMaterialId) &&
            (identical(other.signature, signature) ||
                other.signature == signature));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, centerMaterialId, signature);

  /// Create a copy of SmartTileCoverageScenario
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileCoverageScenarioImplCopyWith<_$SmartTileCoverageScenarioImpl>
      get copyWith => __$$SmartTileCoverageScenarioImplCopyWithImpl<
          _$SmartTileCoverageScenarioImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileCoverageScenarioImplToJson(
      this,
    );
  }
}

abstract class _SmartTileCoverageScenario implements SmartTileCoverageScenario {
  const factory _SmartTileCoverageScenario(
          {required final String id,
          final String? centerMaterialId,
          final SmartTileExactSignature signature}) =
      _$SmartTileCoverageScenarioImpl;

  factory _SmartTileCoverageScenario.fromJson(Map<String, dynamic> json) =
      _$SmartTileCoverageScenarioImpl.fromJson;

  @override
  String get id;
  @override
  String? get centerMaterialId;
  @override
  SmartTileExactSignature get signature;

  /// Create a copy of SmartTileCoverageScenario
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileCoverageScenarioImplCopyWith<_$SmartTileCoverageScenarioImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SmartTileCoverageProfile _$SmartTileCoverageProfileFromJson(
    Map<String, dynamic> json) {
  return _SmartTileCoverageProfile.fromJson(json);
}

/// @nodoc
mixin _$SmartTileCoverageProfile {
  SmartTileCoverageMode get mode => throw _privateConstructorUsedError;
  List<SmartTileCoverageScenario> get requiredScenarios =>
      throw _privateConstructorUsedError;
  bool get allowFallback => throw _privateConstructorUsedError;

  /// Serializes this SmartTileCoverageProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileCoverageProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileCoverageProfileCopyWith<SmartTileCoverageProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileCoverageProfileCopyWith<$Res> {
  factory $SmartTileCoverageProfileCopyWith(SmartTileCoverageProfile value,
          $Res Function(SmartTileCoverageProfile) then) =
      _$SmartTileCoverageProfileCopyWithImpl<$Res, SmartTileCoverageProfile>;
  @useResult
  $Res call(
      {SmartTileCoverageMode mode,
      List<SmartTileCoverageScenario> requiredScenarios,
      bool allowFallback});
}

/// @nodoc
class _$SmartTileCoverageProfileCopyWithImpl<$Res,
        $Val extends SmartTileCoverageProfile>
    implements $SmartTileCoverageProfileCopyWith<$Res> {
  _$SmartTileCoverageProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileCoverageProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? requiredScenarios = null,
    Object? allowFallback = null,
  }) {
    return _then(_value.copyWith(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as SmartTileCoverageMode,
      requiredScenarios: null == requiredScenarios
          ? _value.requiredScenarios
          : requiredScenarios // ignore: cast_nullable_to_non_nullable
              as List<SmartTileCoverageScenario>,
      allowFallback: null == allowFallback
          ? _value.allowFallback
          : allowFallback // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SmartTileCoverageProfileImplCopyWith<$Res>
    implements $SmartTileCoverageProfileCopyWith<$Res> {
  factory _$$SmartTileCoverageProfileImplCopyWith(
          _$SmartTileCoverageProfileImpl value,
          $Res Function(_$SmartTileCoverageProfileImpl) then) =
      __$$SmartTileCoverageProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SmartTileCoverageMode mode,
      List<SmartTileCoverageScenario> requiredScenarios,
      bool allowFallback});
}

/// @nodoc
class __$$SmartTileCoverageProfileImplCopyWithImpl<$Res>
    extends _$SmartTileCoverageProfileCopyWithImpl<$Res,
        _$SmartTileCoverageProfileImpl>
    implements _$$SmartTileCoverageProfileImplCopyWith<$Res> {
  __$$SmartTileCoverageProfileImplCopyWithImpl(
      _$SmartTileCoverageProfileImpl _value,
      $Res Function(_$SmartTileCoverageProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileCoverageProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? requiredScenarios = null,
    Object? allowFallback = null,
  }) {
    return _then(_$SmartTileCoverageProfileImpl(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as SmartTileCoverageMode,
      requiredScenarios: null == requiredScenarios
          ? _value._requiredScenarios
          : requiredScenarios // ignore: cast_nullable_to_non_nullable
              as List<SmartTileCoverageScenario>,
      allowFallback: null == allowFallback
          ? _value.allowFallback
          : allowFallback // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileCoverageProfileImpl implements _SmartTileCoverageProfile {
  const _$SmartTileCoverageProfileImpl(
      {required this.mode,
      final List<SmartTileCoverageScenario> requiredScenarios =
          const <SmartTileCoverageScenario>[],
      this.allowFallback = false})
      : _requiredScenarios = requiredScenarios;

  factory _$SmartTileCoverageProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileCoverageProfileImplFromJson(json);

  @override
  final SmartTileCoverageMode mode;
  final List<SmartTileCoverageScenario> _requiredScenarios;
  @override
  @JsonKey()
  List<SmartTileCoverageScenario> get requiredScenarios {
    if (_requiredScenarios is EqualUnmodifiableListView)
      return _requiredScenarios;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredScenarios);
  }

  @override
  @JsonKey()
  final bool allowFallback;

  @override
  String toString() {
    return 'SmartTileCoverageProfile(mode: $mode, requiredScenarios: $requiredScenarios, allowFallback: $allowFallback)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileCoverageProfileImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality()
                .equals(other._requiredScenarios, _requiredScenarios) &&
            (identical(other.allowFallback, allowFallback) ||
                other.allowFallback == allowFallback));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, mode,
      const DeepCollectionEquality().hash(_requiredScenarios), allowFallback);

  /// Create a copy of SmartTileCoverageProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileCoverageProfileImplCopyWith<_$SmartTileCoverageProfileImpl>
      get copyWith => __$$SmartTileCoverageProfileImplCopyWithImpl<
          _$SmartTileCoverageProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileCoverageProfileImplToJson(
      this,
    );
  }
}

abstract class _SmartTileCoverageProfile implements SmartTileCoverageProfile {
  const factory _SmartTileCoverageProfile(
      {required final SmartTileCoverageMode mode,
      final List<SmartTileCoverageScenario> requiredScenarios,
      final bool allowFallback}) = _$SmartTileCoverageProfileImpl;

  factory _SmartTileCoverageProfile.fromJson(Map<String, dynamic> json) =
      _$SmartTileCoverageProfileImpl.fromJson;

  @override
  SmartTileCoverageMode get mode;
  @override
  List<SmartTileCoverageScenario> get requiredScenarios;
  @override
  bool get allowFallback;

  /// Create a copy of SmartTileCoverageProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileCoverageProfileImplCopyWith<_$SmartTileCoverageProfileImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SmartTileTransformPolicy _$SmartTileTransformPolicyFromJson(
    Map<String, dynamic> json) {
  return _SmartTileTransformPolicy.fromJson(json);
}

/// @nodoc
mixin _$SmartTileTransformPolicy {
  bool get allowHFlip => throw _privateConstructorUsedError;
  bool get allowVFlip => throw _privateConstructorUsedError;
  bool get allowQuarterTurns => throw _privateConstructorUsedError;
  bool get preferUntransformed => throw _privateConstructorUsedError;

  /// Serializes this SmartTileTransformPolicy to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileTransformPolicy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileTransformPolicyCopyWith<SmartTileTransformPolicy> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileTransformPolicyCopyWith<$Res> {
  factory $SmartTileTransformPolicyCopyWith(SmartTileTransformPolicy value,
          $Res Function(SmartTileTransformPolicy) then) =
      _$SmartTileTransformPolicyCopyWithImpl<$Res, SmartTileTransformPolicy>;
  @useResult
  $Res call(
      {bool allowHFlip,
      bool allowVFlip,
      bool allowQuarterTurns,
      bool preferUntransformed});
}

/// @nodoc
class _$SmartTileTransformPolicyCopyWithImpl<$Res,
        $Val extends SmartTileTransformPolicy>
    implements $SmartTileTransformPolicyCopyWith<$Res> {
  _$SmartTileTransformPolicyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileTransformPolicy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allowHFlip = null,
    Object? allowVFlip = null,
    Object? allowQuarterTurns = null,
    Object? preferUntransformed = null,
  }) {
    return _then(_value.copyWith(
      allowHFlip: null == allowHFlip
          ? _value.allowHFlip
          : allowHFlip // ignore: cast_nullable_to_non_nullable
              as bool,
      allowVFlip: null == allowVFlip
          ? _value.allowVFlip
          : allowVFlip // ignore: cast_nullable_to_non_nullable
              as bool,
      allowQuarterTurns: null == allowQuarterTurns
          ? _value.allowQuarterTurns
          : allowQuarterTurns // ignore: cast_nullable_to_non_nullable
              as bool,
      preferUntransformed: null == preferUntransformed
          ? _value.preferUntransformed
          : preferUntransformed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SmartTileTransformPolicyImplCopyWith<$Res>
    implements $SmartTileTransformPolicyCopyWith<$Res> {
  factory _$$SmartTileTransformPolicyImplCopyWith(
          _$SmartTileTransformPolicyImpl value,
          $Res Function(_$SmartTileTransformPolicyImpl) then) =
      __$$SmartTileTransformPolicyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool allowHFlip,
      bool allowVFlip,
      bool allowQuarterTurns,
      bool preferUntransformed});
}

/// @nodoc
class __$$SmartTileTransformPolicyImplCopyWithImpl<$Res>
    extends _$SmartTileTransformPolicyCopyWithImpl<$Res,
        _$SmartTileTransformPolicyImpl>
    implements _$$SmartTileTransformPolicyImplCopyWith<$Res> {
  __$$SmartTileTransformPolicyImplCopyWithImpl(
      _$SmartTileTransformPolicyImpl _value,
      $Res Function(_$SmartTileTransformPolicyImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileTransformPolicy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allowHFlip = null,
    Object? allowVFlip = null,
    Object? allowQuarterTurns = null,
    Object? preferUntransformed = null,
  }) {
    return _then(_$SmartTileTransformPolicyImpl(
      allowHFlip: null == allowHFlip
          ? _value.allowHFlip
          : allowHFlip // ignore: cast_nullable_to_non_nullable
              as bool,
      allowVFlip: null == allowVFlip
          ? _value.allowVFlip
          : allowVFlip // ignore: cast_nullable_to_non_nullable
              as bool,
      allowQuarterTurns: null == allowQuarterTurns
          ? _value.allowQuarterTurns
          : allowQuarterTurns // ignore: cast_nullable_to_non_nullable
              as bool,
      preferUntransformed: null == preferUntransformed
          ? _value.preferUntransformed
          : preferUntransformed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SmartTileTransformPolicyImpl implements _SmartTileTransformPolicy {
  const _$SmartTileTransformPolicyImpl(
      {this.allowHFlip = false,
      this.allowVFlip = false,
      this.allowQuarterTurns = false,
      this.preferUntransformed = true});

  factory _$SmartTileTransformPolicyImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileTransformPolicyImplFromJson(json);

  @override
  @JsonKey()
  final bool allowHFlip;
  @override
  @JsonKey()
  final bool allowVFlip;
  @override
  @JsonKey()
  final bool allowQuarterTurns;
  @override
  @JsonKey()
  final bool preferUntransformed;

  @override
  String toString() {
    return 'SmartTileTransformPolicy(allowHFlip: $allowHFlip, allowVFlip: $allowVFlip, allowQuarterTurns: $allowQuarterTurns, preferUntransformed: $preferUntransformed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileTransformPolicyImpl &&
            (identical(other.allowHFlip, allowHFlip) ||
                other.allowHFlip == allowHFlip) &&
            (identical(other.allowVFlip, allowVFlip) ||
                other.allowVFlip == allowVFlip) &&
            (identical(other.allowQuarterTurns, allowQuarterTurns) ||
                other.allowQuarterTurns == allowQuarterTurns) &&
            (identical(other.preferUntransformed, preferUntransformed) ||
                other.preferUntransformed == preferUntransformed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, allowHFlip, allowVFlip,
      allowQuarterTurns, preferUntransformed);

  /// Create a copy of SmartTileTransformPolicy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileTransformPolicyImplCopyWith<_$SmartTileTransformPolicyImpl>
      get copyWith => __$$SmartTileTransformPolicyImplCopyWithImpl<
          _$SmartTileTransformPolicyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileTransformPolicyImplToJson(
      this,
    );
  }
}

abstract class _SmartTileTransformPolicy implements SmartTileTransformPolicy {
  const factory _SmartTileTransformPolicy(
      {final bool allowHFlip,
      final bool allowVFlip,
      final bool allowQuarterTurns,
      final bool preferUntransformed}) = _$SmartTileTransformPolicyImpl;

  factory _SmartTileTransformPolicy.fromJson(Map<String, dynamic> json) =
      _$SmartTileTransformPolicyImpl.fromJson;

  @override
  bool get allowHFlip;
  @override
  bool get allowVFlip;
  @override
  bool get allowQuarterTurns;
  @override
  bool get preferUntransformed;

  /// Create a copy of SmartTileTransformPolicy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileTransformPolicyImplCopyWith<_$SmartTileTransformPolicyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SmartTileVisualSource _$SmartTileVisualSourceFromJson(
    Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'frame':
      return SmartTileFrameSource.fromJson(json);
    case 'animation':
      return SmartTileAnimationSource.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'kind', 'SmartTileVisualSource',
          'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$SmartTileVisualSource {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SmartTileFrameRef frame) frame,
    required TResult Function(String animationId) animation,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SmartTileFrameRef frame)? frame,
    TResult? Function(String animationId)? animation,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SmartTileFrameRef frame)? frame,
    TResult Function(String animationId)? animation,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SmartTileFrameSource value) frame,
    required TResult Function(SmartTileAnimationSource value) animation,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SmartTileFrameSource value)? frame,
    TResult? Function(SmartTileAnimationSource value)? animation,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SmartTileFrameSource value)? frame,
    TResult Function(SmartTileAnimationSource value)? animation,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this SmartTileVisualSource to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileVisualSourceCopyWith<$Res> {
  factory $SmartTileVisualSourceCopyWith(SmartTileVisualSource value,
          $Res Function(SmartTileVisualSource) then) =
      _$SmartTileVisualSourceCopyWithImpl<$Res, SmartTileVisualSource>;
}

/// @nodoc
class _$SmartTileVisualSourceCopyWithImpl<$Res,
        $Val extends SmartTileVisualSource>
    implements $SmartTileVisualSourceCopyWith<$Res> {
  _$SmartTileVisualSourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileVisualSource
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SmartTileFrameSourceImplCopyWith<$Res> {
  factory _$$SmartTileFrameSourceImplCopyWith(_$SmartTileFrameSourceImpl value,
          $Res Function(_$SmartTileFrameSourceImpl) then) =
      __$$SmartTileFrameSourceImplCopyWithImpl<$Res>;
  @useResult
  $Res call({SmartTileFrameRef frame});

  $SmartTileFrameRefCopyWith<$Res> get frame;
}

/// @nodoc
class __$$SmartTileFrameSourceImplCopyWithImpl<$Res>
    extends _$SmartTileVisualSourceCopyWithImpl<$Res,
        _$SmartTileFrameSourceImpl>
    implements _$$SmartTileFrameSourceImplCopyWith<$Res> {
  __$$SmartTileFrameSourceImplCopyWithImpl(_$SmartTileFrameSourceImpl _value,
      $Res Function(_$SmartTileFrameSourceImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileVisualSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frame = null,
  }) {
    return _then(_$SmartTileFrameSourceImpl(
      frame: null == frame
          ? _value.frame
          : frame // ignore: cast_nullable_to_non_nullable
              as SmartTileFrameRef,
    ));
  }

  /// Create a copy of SmartTileVisualSource
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartTileFrameRefCopyWith<$Res> get frame {
    return $SmartTileFrameRefCopyWith<$Res>(_value.frame, (value) {
      return _then(_value.copyWith(frame: value));
    });
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileFrameSourceImpl implements SmartTileFrameSource {
  const _$SmartTileFrameSourceImpl({required this.frame, final String? $type})
      : $type = $type ?? 'frame';

  factory _$SmartTileFrameSourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileFrameSourceImplFromJson(json);

  @override
  final SmartTileFrameRef frame;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'SmartTileVisualSource.frame(frame: $frame)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileFrameSourceImpl &&
            (identical(other.frame, frame) || other.frame == frame));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, frame);

  /// Create a copy of SmartTileVisualSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileFrameSourceImplCopyWith<_$SmartTileFrameSourceImpl>
      get copyWith =>
          __$$SmartTileFrameSourceImplCopyWithImpl<_$SmartTileFrameSourceImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SmartTileFrameRef frame) frame,
    required TResult Function(String animationId) animation,
  }) {
    return frame(this.frame);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SmartTileFrameRef frame)? frame,
    TResult? Function(String animationId)? animation,
  }) {
    return frame?.call(this.frame);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SmartTileFrameRef frame)? frame,
    TResult Function(String animationId)? animation,
    required TResult orElse(),
  }) {
    if (frame != null) {
      return frame(this.frame);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SmartTileFrameSource value) frame,
    required TResult Function(SmartTileAnimationSource value) animation,
  }) {
    return frame(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SmartTileFrameSource value)? frame,
    TResult? Function(SmartTileAnimationSource value)? animation,
  }) {
    return frame?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SmartTileFrameSource value)? frame,
    TResult Function(SmartTileAnimationSource value)? animation,
    required TResult orElse(),
  }) {
    if (frame != null) {
      return frame(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileFrameSourceImplToJson(
      this,
    );
  }
}

abstract class SmartTileFrameSource implements SmartTileVisualSource {
  const factory SmartTileFrameSource({required final SmartTileFrameRef frame}) =
      _$SmartTileFrameSourceImpl;

  factory SmartTileFrameSource.fromJson(Map<String, dynamic> json) =
      _$SmartTileFrameSourceImpl.fromJson;

  SmartTileFrameRef get frame;

  /// Create a copy of SmartTileVisualSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileFrameSourceImplCopyWith<_$SmartTileFrameSourceImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SmartTileAnimationSourceImplCopyWith<$Res> {
  factory _$$SmartTileAnimationSourceImplCopyWith(
          _$SmartTileAnimationSourceImpl value,
          $Res Function(_$SmartTileAnimationSourceImpl) then) =
      __$$SmartTileAnimationSourceImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String animationId});
}

/// @nodoc
class __$$SmartTileAnimationSourceImplCopyWithImpl<$Res>
    extends _$SmartTileVisualSourceCopyWithImpl<$Res,
        _$SmartTileAnimationSourceImpl>
    implements _$$SmartTileAnimationSourceImplCopyWith<$Res> {
  __$$SmartTileAnimationSourceImplCopyWithImpl(
      _$SmartTileAnimationSourceImpl _value,
      $Res Function(_$SmartTileAnimationSourceImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileVisualSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? animationId = null,
  }) {
    return _then(_$SmartTileAnimationSourceImpl(
      animationId: null == animationId
          ? _value.animationId
          : animationId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SmartTileAnimationSourceImpl implements SmartTileAnimationSource {
  const _$SmartTileAnimationSourceImpl(
      {required this.animationId, final String? $type})
      : $type = $type ?? 'animation';

  factory _$SmartTileAnimationSourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileAnimationSourceImplFromJson(json);

  @override
  final String animationId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'SmartTileVisualSource.animation(animationId: $animationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileAnimationSourceImpl &&
            (identical(other.animationId, animationId) ||
                other.animationId == animationId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, animationId);

  /// Create a copy of SmartTileVisualSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileAnimationSourceImplCopyWith<_$SmartTileAnimationSourceImpl>
      get copyWith => __$$SmartTileAnimationSourceImplCopyWithImpl<
          _$SmartTileAnimationSourceImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SmartTileFrameRef frame) frame,
    required TResult Function(String animationId) animation,
  }) {
    return animation(animationId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SmartTileFrameRef frame)? frame,
    TResult? Function(String animationId)? animation,
  }) {
    return animation?.call(animationId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SmartTileFrameRef frame)? frame,
    TResult Function(String animationId)? animation,
    required TResult orElse(),
  }) {
    if (animation != null) {
      return animation(animationId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SmartTileFrameSource value) frame,
    required TResult Function(SmartTileAnimationSource value) animation,
  }) {
    return animation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SmartTileFrameSource value)? frame,
    TResult? Function(SmartTileAnimationSource value)? animation,
  }) {
    return animation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SmartTileFrameSource value)? frame,
    TResult Function(SmartTileAnimationSource value)? animation,
    required TResult orElse(),
  }) {
    if (animation != null) {
      return animation(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileAnimationSourceImplToJson(
      this,
    );
  }
}

abstract class SmartTileAnimationSource implements SmartTileVisualSource {
  const factory SmartTileAnimationSource({required final String animationId}) =
      _$SmartTileAnimationSourceImpl;

  factory SmartTileAnimationSource.fromJson(Map<String, dynamic> json) =
      _$SmartTileAnimationSourceImpl.fromJson;

  String get animationId;

  /// Create a copy of SmartTileVisualSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileAnimationSourceImplCopyWith<_$SmartTileAnimationSourceImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SmartTileVisualPart _$SmartTileVisualPartFromJson(Map<String, dynamic> json) {
  return _SmartTileVisualPart.fromJson(json);
}

/// @nodoc
mixin _$SmartTileVisualPart {
  SmartTileVisualSource get source => throw _privateConstructorUsedError;
  SmartTileRenderChannel get channel => throw _privateConstructorUsedError;
  SmartTileFrameSampling get frameSampling =>
      throw _privateConstructorUsedError;
  SmartTileOffsetUnit get offsetUnit => throw _privateConstructorUsedError;
  int get offsetX => throw _privateConstructorUsedError;
  int get offsetY => throw _privateConstructorUsedError;
  int get footprintWidth => throw _privateConstructorUsedError;
  int get footprintHeight => throw _privateConstructorUsedError;
  int get anchorX => throw _privateConstructorUsedError;
  int get anchorY => throw _privateConstructorUsedError;
  int get drawOrder => throw _privateConstructorUsedError;

  /// Serializes this SmartTileVisualPart to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileVisualPart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileVisualPartCopyWith<SmartTileVisualPart> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileVisualPartCopyWith<$Res> {
  factory $SmartTileVisualPartCopyWith(
          SmartTileVisualPart value, $Res Function(SmartTileVisualPart) then) =
      _$SmartTileVisualPartCopyWithImpl<$Res, SmartTileVisualPart>;
  @useResult
  $Res call(
      {SmartTileVisualSource source,
      SmartTileRenderChannel channel,
      SmartTileFrameSampling frameSampling,
      SmartTileOffsetUnit offsetUnit,
      int offsetX,
      int offsetY,
      int footprintWidth,
      int footprintHeight,
      int anchorX,
      int anchorY,
      int drawOrder});

  $SmartTileVisualSourceCopyWith<$Res> get source;
}

/// @nodoc
class _$SmartTileVisualPartCopyWithImpl<$Res, $Val extends SmartTileVisualPart>
    implements $SmartTileVisualPartCopyWith<$Res> {
  _$SmartTileVisualPartCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileVisualPart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? channel = null,
    Object? frameSampling = null,
    Object? offsetUnit = null,
    Object? offsetX = null,
    Object? offsetY = null,
    Object? footprintWidth = null,
    Object? footprintHeight = null,
    Object? anchorX = null,
    Object? anchorY = null,
    Object? drawOrder = null,
  }) {
    return _then(_value.copyWith(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as SmartTileVisualSource,
      channel: null == channel
          ? _value.channel
          : channel // ignore: cast_nullable_to_non_nullable
              as SmartTileRenderChannel,
      frameSampling: null == frameSampling
          ? _value.frameSampling
          : frameSampling // ignore: cast_nullable_to_non_nullable
              as SmartTileFrameSampling,
      offsetUnit: null == offsetUnit
          ? _value.offsetUnit
          : offsetUnit // ignore: cast_nullable_to_non_nullable
              as SmartTileOffsetUnit,
      offsetX: null == offsetX
          ? _value.offsetX
          : offsetX // ignore: cast_nullable_to_non_nullable
              as int,
      offsetY: null == offsetY
          ? _value.offsetY
          : offsetY // ignore: cast_nullable_to_non_nullable
              as int,
      footprintWidth: null == footprintWidth
          ? _value.footprintWidth
          : footprintWidth // ignore: cast_nullable_to_non_nullable
              as int,
      footprintHeight: null == footprintHeight
          ? _value.footprintHeight
          : footprintHeight // ignore: cast_nullable_to_non_nullable
              as int,
      anchorX: null == anchorX
          ? _value.anchorX
          : anchorX // ignore: cast_nullable_to_non_nullable
              as int,
      anchorY: null == anchorY
          ? _value.anchorY
          : anchorY // ignore: cast_nullable_to_non_nullable
              as int,
      drawOrder: null == drawOrder
          ? _value.drawOrder
          : drawOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of SmartTileVisualPart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartTileVisualSourceCopyWith<$Res> get source {
    return $SmartTileVisualSourceCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SmartTileVisualPartImplCopyWith<$Res>
    implements $SmartTileVisualPartCopyWith<$Res> {
  factory _$$SmartTileVisualPartImplCopyWith(_$SmartTileVisualPartImpl value,
          $Res Function(_$SmartTileVisualPartImpl) then) =
      __$$SmartTileVisualPartImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SmartTileVisualSource source,
      SmartTileRenderChannel channel,
      SmartTileFrameSampling frameSampling,
      SmartTileOffsetUnit offsetUnit,
      int offsetX,
      int offsetY,
      int footprintWidth,
      int footprintHeight,
      int anchorX,
      int anchorY,
      int drawOrder});

  @override
  $SmartTileVisualSourceCopyWith<$Res> get source;
}

/// @nodoc
class __$$SmartTileVisualPartImplCopyWithImpl<$Res>
    extends _$SmartTileVisualPartCopyWithImpl<$Res, _$SmartTileVisualPartImpl>
    implements _$$SmartTileVisualPartImplCopyWith<$Res> {
  __$$SmartTileVisualPartImplCopyWithImpl(_$SmartTileVisualPartImpl _value,
      $Res Function(_$SmartTileVisualPartImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileVisualPart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? channel = null,
    Object? frameSampling = null,
    Object? offsetUnit = null,
    Object? offsetX = null,
    Object? offsetY = null,
    Object? footprintWidth = null,
    Object? footprintHeight = null,
    Object? anchorX = null,
    Object? anchorY = null,
    Object? drawOrder = null,
  }) {
    return _then(_$SmartTileVisualPartImpl(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as SmartTileVisualSource,
      channel: null == channel
          ? _value.channel
          : channel // ignore: cast_nullable_to_non_nullable
              as SmartTileRenderChannel,
      frameSampling: null == frameSampling
          ? _value.frameSampling
          : frameSampling // ignore: cast_nullable_to_non_nullable
              as SmartTileFrameSampling,
      offsetUnit: null == offsetUnit
          ? _value.offsetUnit
          : offsetUnit // ignore: cast_nullable_to_non_nullable
              as SmartTileOffsetUnit,
      offsetX: null == offsetX
          ? _value.offsetX
          : offsetX // ignore: cast_nullable_to_non_nullable
              as int,
      offsetY: null == offsetY
          ? _value.offsetY
          : offsetY // ignore: cast_nullable_to_non_nullable
              as int,
      footprintWidth: null == footprintWidth
          ? _value.footprintWidth
          : footprintWidth // ignore: cast_nullable_to_non_nullable
              as int,
      footprintHeight: null == footprintHeight
          ? _value.footprintHeight
          : footprintHeight // ignore: cast_nullable_to_non_nullable
              as int,
      anchorX: null == anchorX
          ? _value.anchorX
          : anchorX // ignore: cast_nullable_to_non_nullable
              as int,
      anchorY: null == anchorY
          ? _value.anchorY
          : anchorY // ignore: cast_nullable_to_non_nullable
              as int,
      drawOrder: null == drawOrder
          ? _value.drawOrder
          : drawOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileVisualPartImpl implements _SmartTileVisualPart {
  const _$SmartTileVisualPartImpl(
      {required this.source,
      this.channel = SmartTileRenderChannel.ground,
      this.frameSampling = SmartTileFrameSampling.fullFrame,
      this.offsetUnit = SmartTileOffsetUnit.pixel,
      this.offsetX = 0,
      this.offsetY = 0,
      this.footprintWidth = 1,
      this.footprintHeight = 1,
      this.anchorX = 0,
      this.anchorY = 0,
      this.drawOrder = 0})
      : assert(footprintWidth > 0, 'footprintWidth must be positive'),
        assert(footprintHeight > 0, 'footprintHeight must be positive');

  factory _$SmartTileVisualPartImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileVisualPartImplFromJson(json);

  @override
  final SmartTileVisualSource source;
  @override
  @JsonKey()
  final SmartTileRenderChannel channel;
  @override
  @JsonKey()
  final SmartTileFrameSampling frameSampling;
  @override
  @JsonKey()
  final SmartTileOffsetUnit offsetUnit;
  @override
  @JsonKey()
  final int offsetX;
  @override
  @JsonKey()
  final int offsetY;
  @override
  @JsonKey()
  final int footprintWidth;
  @override
  @JsonKey()
  final int footprintHeight;
  @override
  @JsonKey()
  final int anchorX;
  @override
  @JsonKey()
  final int anchorY;
  @override
  @JsonKey()
  final int drawOrder;

  @override
  String toString() {
    return 'SmartTileVisualPart(source: $source, channel: $channel, frameSampling: $frameSampling, offsetUnit: $offsetUnit, offsetX: $offsetX, offsetY: $offsetY, footprintWidth: $footprintWidth, footprintHeight: $footprintHeight, anchorX: $anchorX, anchorY: $anchorY, drawOrder: $drawOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileVisualPartImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.channel, channel) || other.channel == channel) &&
            (identical(other.frameSampling, frameSampling) ||
                other.frameSampling == frameSampling) &&
            (identical(other.offsetUnit, offsetUnit) ||
                other.offsetUnit == offsetUnit) &&
            (identical(other.offsetX, offsetX) || other.offsetX == offsetX) &&
            (identical(other.offsetY, offsetY) || other.offsetY == offsetY) &&
            (identical(other.footprintWidth, footprintWidth) ||
                other.footprintWidth == footprintWidth) &&
            (identical(other.footprintHeight, footprintHeight) ||
                other.footprintHeight == footprintHeight) &&
            (identical(other.anchorX, anchorX) || other.anchorX == anchorX) &&
            (identical(other.anchorY, anchorY) || other.anchorY == anchorY) &&
            (identical(other.drawOrder, drawOrder) ||
                other.drawOrder == drawOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      source,
      channel,
      frameSampling,
      offsetUnit,
      offsetX,
      offsetY,
      footprintWidth,
      footprintHeight,
      anchorX,
      anchorY,
      drawOrder);

  /// Create a copy of SmartTileVisualPart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileVisualPartImplCopyWith<_$SmartTileVisualPartImpl> get copyWith =>
      __$$SmartTileVisualPartImplCopyWithImpl<_$SmartTileVisualPartImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileVisualPartImplToJson(
      this,
    );
  }
}

abstract class _SmartTileVisualPart implements SmartTileVisualPart {
  const factory _SmartTileVisualPart(
      {required final SmartTileVisualSource source,
      final SmartTileRenderChannel channel,
      final SmartTileFrameSampling frameSampling,
      final SmartTileOffsetUnit offsetUnit,
      final int offsetX,
      final int offsetY,
      final int footprintWidth,
      final int footprintHeight,
      final int anchorX,
      final int anchorY,
      final int drawOrder}) = _$SmartTileVisualPartImpl;

  factory _SmartTileVisualPart.fromJson(Map<String, dynamic> json) =
      _$SmartTileVisualPartImpl.fromJson;

  @override
  SmartTileVisualSource get source;
  @override
  SmartTileRenderChannel get channel;
  @override
  SmartTileFrameSampling get frameSampling;
  @override
  SmartTileOffsetUnit get offsetUnit;
  @override
  int get offsetX;
  @override
  int get offsetY;
  @override
  int get footprintWidth;
  @override
  int get footprintHeight;
  @override
  int get anchorX;
  @override
  int get anchorY;
  @override
  int get drawOrder;

  /// Create a copy of SmartTileVisualPart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileVisualPartImplCopyWith<_$SmartTileVisualPartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SmartTileCandidate _$SmartTileCandidateFromJson(Map<String, dynamic> json) {
  return _SmartTileCandidate.fromJson(json);
}

/// @nodoc
mixin _$SmartTileCandidate {
  String get id => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;
  List<SmartTileVisualPart> get parts => throw _privateConstructorUsedError;

  /// Serializes this SmartTileCandidate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileCandidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileCandidateCopyWith<SmartTileCandidate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileCandidateCopyWith<$Res> {
  factory $SmartTileCandidateCopyWith(
          SmartTileCandidate value, $Res Function(SmartTileCandidate) then) =
      _$SmartTileCandidateCopyWithImpl<$Res, SmartTileCandidate>;
  @useResult
  $Res call({String id, int weight, List<SmartTileVisualPart> parts});
}

/// @nodoc
class _$SmartTileCandidateCopyWithImpl<$Res, $Val extends SmartTileCandidate>
    implements $SmartTileCandidateCopyWith<$Res> {
  _$SmartTileCandidateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileCandidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? weight = null,
    Object? parts = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      parts: null == parts
          ? _value.parts
          : parts // ignore: cast_nullable_to_non_nullable
              as List<SmartTileVisualPart>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SmartTileCandidateImplCopyWith<$Res>
    implements $SmartTileCandidateCopyWith<$Res> {
  factory _$$SmartTileCandidateImplCopyWith(_$SmartTileCandidateImpl value,
          $Res Function(_$SmartTileCandidateImpl) then) =
      __$$SmartTileCandidateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, int weight, List<SmartTileVisualPart> parts});
}

/// @nodoc
class __$$SmartTileCandidateImplCopyWithImpl<$Res>
    extends _$SmartTileCandidateCopyWithImpl<$Res, _$SmartTileCandidateImpl>
    implements _$$SmartTileCandidateImplCopyWith<$Res> {
  __$$SmartTileCandidateImplCopyWithImpl(_$SmartTileCandidateImpl _value,
      $Res Function(_$SmartTileCandidateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileCandidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? weight = null,
    Object? parts = null,
  }) {
    return _then(_$SmartTileCandidateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      parts: null == parts
          ? _value._parts
          : parts // ignore: cast_nullable_to_non_nullable
              as List<SmartTileVisualPart>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileCandidateImpl implements _SmartTileCandidate {
  const _$SmartTileCandidateImpl(
      {required this.id,
      this.weight = 1,
      final List<SmartTileVisualPart> parts = const <SmartTileVisualPart>[]})
      : assert(id != "", 'id must not be blank'),
        _parts = parts;

  factory _$SmartTileCandidateImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileCandidateImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final int weight;
  final List<SmartTileVisualPart> _parts;
  @override
  @JsonKey()
  List<SmartTileVisualPart> get parts {
    if (_parts is EqualUnmodifiableListView) return _parts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parts);
  }

  @override
  String toString() {
    return 'SmartTileCandidate(id: $id, weight: $weight, parts: $parts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileCandidateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            const DeepCollectionEquality().equals(other._parts, _parts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, weight, const DeepCollectionEquality().hash(_parts));

  /// Create a copy of SmartTileCandidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileCandidateImplCopyWith<_$SmartTileCandidateImpl> get copyWith =>
      __$$SmartTileCandidateImplCopyWithImpl<_$SmartTileCandidateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileCandidateImplToJson(
      this,
    );
  }
}

abstract class _SmartTileCandidate implements SmartTileCandidate {
  const factory _SmartTileCandidate(
      {required final String id,
      final int weight,
      final List<SmartTileVisualPart> parts}) = _$SmartTileCandidateImpl;

  factory _SmartTileCandidate.fromJson(Map<String, dynamic> json) =
      _$SmartTileCandidateImpl.fromJson;

  @override
  String get id;
  @override
  int get weight;
  @override
  List<SmartTileVisualPart> get parts;

  /// Create a copy of SmartTileCandidate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileCandidateImplCopyWith<_$SmartTileCandidateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SmartTileRule _$SmartTileRuleFromJson(Map<String, dynamic> json) {
  return _SmartTileRule.fromJson(json);
}

/// @nodoc
mixin _$SmartTileRule {
  String get id => throw _privateConstructorUsedError;
  SmartTileSlotMatch get centerMatch => throw _privateConstructorUsedError;
  SmartTileSignature get signature => throw _privateConstructorUsedError;
  List<SmartTileCandidate> get candidates => throw _privateConstructorUsedError;

  /// Serializes this SmartTileRule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileRuleCopyWith<SmartTileRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileRuleCopyWith<$Res> {
  factory $SmartTileRuleCopyWith(
          SmartTileRule value, $Res Function(SmartTileRule) then) =
      _$SmartTileRuleCopyWithImpl<$Res, SmartTileRule>;
  @useResult
  $Res call(
      {String id,
      SmartTileSlotMatch centerMatch,
      SmartTileSignature signature,
      List<SmartTileCandidate> candidates});

  $SmartTileSignatureCopyWith<$Res> get signature;
}

/// @nodoc
class _$SmartTileRuleCopyWithImpl<$Res, $Val extends SmartTileRule>
    implements $SmartTileRuleCopyWith<$Res> {
  _$SmartTileRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? centerMatch = null,
    Object? signature = null,
    Object? candidates = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      centerMatch: null == centerMatch
          ? _value.centerMatch
          : centerMatch // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      signature: null == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as SmartTileSignature,
      candidates: null == candidates
          ? _value.candidates
          : candidates // ignore: cast_nullable_to_non_nullable
              as List<SmartTileCandidate>,
    ) as $Val);
  }

  /// Create a copy of SmartTileRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartTileSignatureCopyWith<$Res> get signature {
    return $SmartTileSignatureCopyWith<$Res>(_value.signature, (value) {
      return _then(_value.copyWith(signature: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SmartTileRuleImplCopyWith<$Res>
    implements $SmartTileRuleCopyWith<$Res> {
  factory _$$SmartTileRuleImplCopyWith(
          _$SmartTileRuleImpl value, $Res Function(_$SmartTileRuleImpl) then) =
      __$$SmartTileRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      SmartTileSlotMatch centerMatch,
      SmartTileSignature signature,
      List<SmartTileCandidate> candidates});

  @override
  $SmartTileSignatureCopyWith<$Res> get signature;
}

/// @nodoc
class __$$SmartTileRuleImplCopyWithImpl<$Res>
    extends _$SmartTileRuleCopyWithImpl<$Res, _$SmartTileRuleImpl>
    implements _$$SmartTileRuleImplCopyWith<$Res> {
  __$$SmartTileRuleImplCopyWithImpl(
      _$SmartTileRuleImpl _value, $Res Function(_$SmartTileRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? centerMatch = null,
    Object? signature = null,
    Object? candidates = null,
  }) {
    return _then(_$SmartTileRuleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      centerMatch: null == centerMatch
          ? _value.centerMatch
          : centerMatch // ignore: cast_nullable_to_non_nullable
              as SmartTileSlotMatch,
      signature: null == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as SmartTileSignature,
      candidates: null == candidates
          ? _value._candidates
          : candidates // ignore: cast_nullable_to_non_nullable
              as List<SmartTileCandidate>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SmartTileRuleImpl implements _SmartTileRule {
  const _$SmartTileRuleImpl(
      {required this.id,
      required this.centerMatch,
      this.signature = const SmartTileSignature(),
      final List<SmartTileCandidate> candidates = const <SmartTileCandidate>[]})
      : assert(id != "", 'id must not be blank'),
        _candidates = candidates;

  factory _$SmartTileRuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileRuleImplFromJson(json);

  @override
  final String id;
  @override
  final SmartTileSlotMatch centerMatch;
  @override
  @JsonKey()
  final SmartTileSignature signature;
  final List<SmartTileCandidate> _candidates;
  @override
  @JsonKey()
  List<SmartTileCandidate> get candidates {
    if (_candidates is EqualUnmodifiableListView) return _candidates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_candidates);
  }

  @override
  String toString() {
    return 'SmartTileRule(id: $id, centerMatch: $centerMatch, signature: $signature, candidates: $candidates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileRuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.centerMatch, centerMatch) ||
                other.centerMatch == centerMatch) &&
            (identical(other.signature, signature) ||
                other.signature == signature) &&
            const DeepCollectionEquality()
                .equals(other._candidates, _candidates));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, centerMatch, signature,
      const DeepCollectionEquality().hash(_candidates));

  /// Create a copy of SmartTileRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileRuleImplCopyWith<_$SmartTileRuleImpl> get copyWith =>
      __$$SmartTileRuleImplCopyWithImpl<_$SmartTileRuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileRuleImplToJson(
      this,
    );
  }
}

abstract class _SmartTileRule implements SmartTileRule {
  const factory _SmartTileRule(
      {required final String id,
      required final SmartTileSlotMatch centerMatch,
      final SmartTileSignature signature,
      final List<SmartTileCandidate> candidates}) = _$SmartTileRuleImpl;

  factory _SmartTileRule.fromJson(Map<String, dynamic> json) =
      _$SmartTileRuleImpl.fromJson;

  @override
  String get id;
  @override
  SmartTileSlotMatch get centerMatch;
  @override
  SmartTileSignature get signature;
  @override
  List<SmartTileCandidate> get candidates;

  /// Create a copy of SmartTileRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileRuleImplCopyWith<_$SmartTileRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectSmartTileCategory _$ProjectSmartTileCategoryFromJson(
    Map<String, dynamic> json) {
  return _ProjectSmartTileCategory.fromJson(json);
}

/// @nodoc
mixin _$ProjectSmartTileCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectSmartTileCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSmartTileCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSmartTileCategoryCopyWith<ProjectSmartTileCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSmartTileCategoryCopyWith<$Res> {
  factory $ProjectSmartTileCategoryCopyWith(ProjectSmartTileCategory value,
          $Res Function(ProjectSmartTileCategory) then) =
      _$ProjectSmartTileCategoryCopyWithImpl<$Res, ProjectSmartTileCategory>;
  @useResult
  $Res call({String id, String name, int sortOrder});
}

/// @nodoc
class _$ProjectSmartTileCategoryCopyWithImpl<$Res,
        $Val extends ProjectSmartTileCategory>
    implements $ProjectSmartTileCategoryCopyWith<$Res> {
  _$ProjectSmartTileCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSmartTileCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sortOrder = null,
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
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectSmartTileCategoryImplCopyWith<$Res>
    implements $ProjectSmartTileCategoryCopyWith<$Res> {
  factory _$$ProjectSmartTileCategoryImplCopyWith(
          _$ProjectSmartTileCategoryImpl value,
          $Res Function(_$ProjectSmartTileCategoryImpl) then) =
      __$$ProjectSmartTileCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, int sortOrder});
}

/// @nodoc
class __$$ProjectSmartTileCategoryImplCopyWithImpl<$Res>
    extends _$ProjectSmartTileCategoryCopyWithImpl<$Res,
        _$ProjectSmartTileCategoryImpl>
    implements _$$ProjectSmartTileCategoryImplCopyWith<$Res> {
  __$$ProjectSmartTileCategoryImplCopyWithImpl(
      _$ProjectSmartTileCategoryImpl _value,
      $Res Function(_$ProjectSmartTileCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSmartTileCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectSmartTileCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectSmartTileCategoryImpl implements _ProjectSmartTileCategory {
  const _$ProjectSmartTileCategoryImpl(
      {required this.id, required this.name, this.sortOrder = 0})
      : assert(id != "", 'id must not be blank'),
        assert(name != "", 'name must not be blank');

  factory _$ProjectSmartTileCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectSmartTileCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectSmartTileCategory(id: $id, name: $name, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSmartTileCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, sortOrder);

  /// Create a copy of ProjectSmartTileCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSmartTileCategoryImplCopyWith<_$ProjectSmartTileCategoryImpl>
      get copyWith => __$$ProjectSmartTileCategoryImplCopyWithImpl<
          _$ProjectSmartTileCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSmartTileCategoryImplToJson(
      this,
    );
  }
}

abstract class _ProjectSmartTileCategory implements ProjectSmartTileCategory {
  const factory _ProjectSmartTileCategory(
      {required final String id,
      required final String name,
      final int sortOrder}) = _$ProjectSmartTileCategoryImpl;

  factory _ProjectSmartTileCategory.fromJson(Map<String, dynamic> json) =
      _$ProjectSmartTileCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get sortOrder;

  /// Create a copy of ProjectSmartTileCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSmartTileCategoryImplCopyWith<_$ProjectSmartTileCategoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectSmartTileAtlas _$ProjectSmartTileAtlasFromJson(
    Map<String, dynamic> json) {
  return _ProjectSmartTileAtlas.fromJson(json);
}

/// @nodoc
mixin _$ProjectSmartTileAtlas {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  int get cellWidth => throw _privateConstructorUsedError;
  int get cellHeight => throw _privateConstructorUsedError;
  int get originX => throw _privateConstructorUsedError;
  int get originY => throw _privateConstructorUsedError;
  int get marginX => throw _privateConstructorUsedError;
  int get marginY => throw _privateConstructorUsedError;
  int get spacingX => throw _privateConstructorUsedError;
  int get spacingY => throw _privateConstructorUsedError;
  int get columns => throw _privateConstructorUsedError;
  int get rows => throw _privateConstructorUsedError;
  int get pixelOffsetX => throw _privateConstructorUsedError;
  int get pixelOffsetY => throw _privateConstructorUsedError;

  /// Serializes this ProjectSmartTileAtlas to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSmartTileAtlas
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSmartTileAtlasCopyWith<ProjectSmartTileAtlas> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSmartTileAtlasCopyWith<$Res> {
  factory $ProjectSmartTileAtlasCopyWith(ProjectSmartTileAtlas value,
          $Res Function(ProjectSmartTileAtlas) then) =
      _$ProjectSmartTileAtlasCopyWithImpl<$Res, ProjectSmartTileAtlas>;
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      int cellWidth,
      int cellHeight,
      int originX,
      int originY,
      int marginX,
      int marginY,
      int spacingX,
      int spacingY,
      int columns,
      int rows,
      int pixelOffsetX,
      int pixelOffsetY});
}

/// @nodoc
class _$ProjectSmartTileAtlasCopyWithImpl<$Res,
        $Val extends ProjectSmartTileAtlas>
    implements $ProjectSmartTileAtlasCopyWith<$Res> {
  _$ProjectSmartTileAtlasCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSmartTileAtlas
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? cellWidth = null,
    Object? cellHeight = null,
    Object? originX = null,
    Object? originY = null,
    Object? marginX = null,
    Object? marginY = null,
    Object? spacingX = null,
    Object? spacingY = null,
    Object? columns = null,
    Object? rows = null,
    Object? pixelOffsetX = null,
    Object? pixelOffsetY = null,
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
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      cellWidth: null == cellWidth
          ? _value.cellWidth
          : cellWidth // ignore: cast_nullable_to_non_nullable
              as int,
      cellHeight: null == cellHeight
          ? _value.cellHeight
          : cellHeight // ignore: cast_nullable_to_non_nullable
              as int,
      originX: null == originX
          ? _value.originX
          : originX // ignore: cast_nullable_to_non_nullable
              as int,
      originY: null == originY
          ? _value.originY
          : originY // ignore: cast_nullable_to_non_nullable
              as int,
      marginX: null == marginX
          ? _value.marginX
          : marginX // ignore: cast_nullable_to_non_nullable
              as int,
      marginY: null == marginY
          ? _value.marginY
          : marginY // ignore: cast_nullable_to_non_nullable
              as int,
      spacingX: null == spacingX
          ? _value.spacingX
          : spacingX // ignore: cast_nullable_to_non_nullable
              as int,
      spacingY: null == spacingY
          ? _value.spacingY
          : spacingY // ignore: cast_nullable_to_non_nullable
              as int,
      columns: null == columns
          ? _value.columns
          : columns // ignore: cast_nullable_to_non_nullable
              as int,
      rows: null == rows
          ? _value.rows
          : rows // ignore: cast_nullable_to_non_nullable
              as int,
      pixelOffsetX: null == pixelOffsetX
          ? _value.pixelOffsetX
          : pixelOffsetX // ignore: cast_nullable_to_non_nullable
              as int,
      pixelOffsetY: null == pixelOffsetY
          ? _value.pixelOffsetY
          : pixelOffsetY // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectSmartTileAtlasImplCopyWith<$Res>
    implements $ProjectSmartTileAtlasCopyWith<$Res> {
  factory _$$ProjectSmartTileAtlasImplCopyWith(
          _$ProjectSmartTileAtlasImpl value,
          $Res Function(_$ProjectSmartTileAtlasImpl) then) =
      __$$ProjectSmartTileAtlasImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      int cellWidth,
      int cellHeight,
      int originX,
      int originY,
      int marginX,
      int marginY,
      int spacingX,
      int spacingY,
      int columns,
      int rows,
      int pixelOffsetX,
      int pixelOffsetY});
}

/// @nodoc
class __$$ProjectSmartTileAtlasImplCopyWithImpl<$Res>
    extends _$ProjectSmartTileAtlasCopyWithImpl<$Res,
        _$ProjectSmartTileAtlasImpl>
    implements _$$ProjectSmartTileAtlasImplCopyWith<$Res> {
  __$$ProjectSmartTileAtlasImplCopyWithImpl(_$ProjectSmartTileAtlasImpl _value,
      $Res Function(_$ProjectSmartTileAtlasImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSmartTileAtlas
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? cellWidth = null,
    Object? cellHeight = null,
    Object? originX = null,
    Object? originY = null,
    Object? marginX = null,
    Object? marginY = null,
    Object? spacingX = null,
    Object? spacingY = null,
    Object? columns = null,
    Object? rows = null,
    Object? pixelOffsetX = null,
    Object? pixelOffsetY = null,
  }) {
    return _then(_$ProjectSmartTileAtlasImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      cellWidth: null == cellWidth
          ? _value.cellWidth
          : cellWidth // ignore: cast_nullable_to_non_nullable
              as int,
      cellHeight: null == cellHeight
          ? _value.cellHeight
          : cellHeight // ignore: cast_nullable_to_non_nullable
              as int,
      originX: null == originX
          ? _value.originX
          : originX // ignore: cast_nullable_to_non_nullable
              as int,
      originY: null == originY
          ? _value.originY
          : originY // ignore: cast_nullable_to_non_nullable
              as int,
      marginX: null == marginX
          ? _value.marginX
          : marginX // ignore: cast_nullable_to_non_nullable
              as int,
      marginY: null == marginY
          ? _value.marginY
          : marginY // ignore: cast_nullable_to_non_nullable
              as int,
      spacingX: null == spacingX
          ? _value.spacingX
          : spacingX // ignore: cast_nullable_to_non_nullable
              as int,
      spacingY: null == spacingY
          ? _value.spacingY
          : spacingY // ignore: cast_nullable_to_non_nullable
              as int,
      columns: null == columns
          ? _value.columns
          : columns // ignore: cast_nullable_to_non_nullable
              as int,
      rows: null == rows
          ? _value.rows
          : rows // ignore: cast_nullable_to_non_nullable
              as int,
      pixelOffsetX: null == pixelOffsetX
          ? _value.pixelOffsetX
          : pixelOffsetX // ignore: cast_nullable_to_non_nullable
              as int,
      pixelOffsetY: null == pixelOffsetY
          ? _value.pixelOffsetY
          : pixelOffsetY // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectSmartTileAtlasImpl extends _ProjectSmartTileAtlas {
  const _$ProjectSmartTileAtlasImpl(
      {required this.id,
      required this.name,
      required this.tilesetId,
      this.cellWidth = 32,
      this.cellHeight = 32,
      this.originX = 0,
      this.originY = 0,
      this.marginX = 0,
      this.marginY = 0,
      this.spacingX = 0,
      this.spacingY = 0,
      required this.columns,
      required this.rows,
      this.pixelOffsetX = 0,
      this.pixelOffsetY = 0})
      : assert(id != "", 'id must not be blank'),
        assert(name != "", 'name must not be blank'),
        assert(tilesetId != "", 'tilesetId must not be blank'),
        assert(cellWidth > 0, 'cellWidth must be positive'),
        assert(cellHeight > 0, 'cellHeight must be positive'),
        assert(originX >= 0, 'originX must not be negative'),
        assert(originY >= 0, 'originY must not be negative'),
        assert(marginX >= 0, 'marginX must not be negative'),
        assert(marginY >= 0, 'marginY must not be negative'),
        assert(spacingX >= 0, 'spacingX must not be negative'),
        assert(spacingY >= 0, 'spacingY must not be negative'),
        assert(columns > 0, 'columns must be positive'),
        assert(rows > 0, 'rows must be positive'),
        super._();

  factory _$ProjectSmartTileAtlasImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectSmartTileAtlasImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String tilesetId;
  @override
  @JsonKey()
  final int cellWidth;
  @override
  @JsonKey()
  final int cellHeight;
  @override
  @JsonKey()
  final int originX;
  @override
  @JsonKey()
  final int originY;
  @override
  @JsonKey()
  final int marginX;
  @override
  @JsonKey()
  final int marginY;
  @override
  @JsonKey()
  final int spacingX;
  @override
  @JsonKey()
  final int spacingY;
  @override
  final int columns;
  @override
  final int rows;
  @override
  @JsonKey()
  final int pixelOffsetX;
  @override
  @JsonKey()
  final int pixelOffsetY;

  @override
  String toString() {
    return 'ProjectSmartTileAtlas(id: $id, name: $name, tilesetId: $tilesetId, cellWidth: $cellWidth, cellHeight: $cellHeight, originX: $originX, originY: $originY, marginX: $marginX, marginY: $marginY, spacingX: $spacingX, spacingY: $spacingY, columns: $columns, rows: $rows, pixelOffsetX: $pixelOffsetX, pixelOffsetY: $pixelOffsetY)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSmartTileAtlasImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            (identical(other.cellWidth, cellWidth) ||
                other.cellWidth == cellWidth) &&
            (identical(other.cellHeight, cellHeight) ||
                other.cellHeight == cellHeight) &&
            (identical(other.originX, originX) || other.originX == originX) &&
            (identical(other.originY, originY) || other.originY == originY) &&
            (identical(other.marginX, marginX) || other.marginX == marginX) &&
            (identical(other.marginY, marginY) || other.marginY == marginY) &&
            (identical(other.spacingX, spacingX) ||
                other.spacingX == spacingX) &&
            (identical(other.spacingY, spacingY) ||
                other.spacingY == spacingY) &&
            (identical(other.columns, columns) || other.columns == columns) &&
            (identical(other.rows, rows) || other.rows == rows) &&
            (identical(other.pixelOffsetX, pixelOffsetX) ||
                other.pixelOffsetX == pixelOffsetX) &&
            (identical(other.pixelOffsetY, pixelOffsetY) ||
                other.pixelOffsetY == pixelOffsetY));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      tilesetId,
      cellWidth,
      cellHeight,
      originX,
      originY,
      marginX,
      marginY,
      spacingX,
      spacingY,
      columns,
      rows,
      pixelOffsetX,
      pixelOffsetY);

  /// Create a copy of ProjectSmartTileAtlas
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSmartTileAtlasImplCopyWith<_$ProjectSmartTileAtlasImpl>
      get copyWith => __$$ProjectSmartTileAtlasImplCopyWithImpl<
          _$ProjectSmartTileAtlasImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSmartTileAtlasImplToJson(
      this,
    );
  }
}

abstract class _ProjectSmartTileAtlas extends ProjectSmartTileAtlas {
  const factory _ProjectSmartTileAtlas(
      {required final String id,
      required final String name,
      required final String tilesetId,
      final int cellWidth,
      final int cellHeight,
      final int originX,
      final int originY,
      final int marginX,
      final int marginY,
      final int spacingX,
      final int spacingY,
      required final int columns,
      required final int rows,
      final int pixelOffsetX,
      final int pixelOffsetY}) = _$ProjectSmartTileAtlasImpl;
  const _ProjectSmartTileAtlas._() : super._();

  factory _ProjectSmartTileAtlas.fromJson(Map<String, dynamic> json) =
      _$ProjectSmartTileAtlasImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get tilesetId;
  @override
  int get cellWidth;
  @override
  int get cellHeight;
  @override
  int get originX;
  @override
  int get originY;
  @override
  int get marginX;
  @override
  int get marginY;
  @override
  int get spacingX;
  @override
  int get spacingY;
  @override
  int get columns;
  @override
  int get rows;
  @override
  int get pixelOffsetX;
  @override
  int get pixelOffsetY;

  /// Create a copy of ProjectSmartTileAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSmartTileAtlasImplCopyWith<_$ProjectSmartTileAtlasImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectSmartTileMaterial _$ProjectSmartTileMaterialFromJson(
    Map<String, dynamic> json) {
  return _ProjectSmartTileMaterial.fromJson(json);
}

/// @nodoc
mixin _$ProjectSmartTileMaterial {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get connectionGroupId => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  TerrainType? get terrainType => throw _privateConstructorUsedError;
  PathSurfaceKind? get pathSurfaceKind => throw _privateConstructorUsedError;
  bool get isEmpty => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  int? get editorColorArgb => throw _privateConstructorUsedError;

  /// Serializes this ProjectSmartTileMaterial to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSmartTileMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSmartTileMaterialCopyWith<ProjectSmartTileMaterial> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSmartTileMaterialCopyWith<$Res> {
  factory $ProjectSmartTileMaterialCopyWith(ProjectSmartTileMaterial value,
          $Res Function(ProjectSmartTileMaterial) then) =
      _$ProjectSmartTileMaterialCopyWithImpl<$Res, ProjectSmartTileMaterial>;
  @useResult
  $Res call(
      {String id,
      String name,
      String connectionGroupId,
      String categoryId,
      TerrainType? terrainType,
      PathSurfaceKind? pathSurfaceKind,
      bool isEmpty,
      int sortOrder,
      int? editorColorArgb});
}

/// @nodoc
class _$ProjectSmartTileMaterialCopyWithImpl<$Res,
        $Val extends ProjectSmartTileMaterial>
    implements $ProjectSmartTileMaterialCopyWith<$Res> {
  _$ProjectSmartTileMaterialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSmartTileMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? connectionGroupId = null,
    Object? categoryId = null,
    Object? terrainType = freezed,
    Object? pathSurfaceKind = freezed,
    Object? isEmpty = null,
    Object? sortOrder = null,
    Object? editorColorArgb = freezed,
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
      connectionGroupId: null == connectionGroupId
          ? _value.connectionGroupId
          : connectionGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      terrainType: freezed == terrainType
          ? _value.terrainType
          : terrainType // ignore: cast_nullable_to_non_nullable
              as TerrainType?,
      pathSurfaceKind: freezed == pathSurfaceKind
          ? _value.pathSurfaceKind
          : pathSurfaceKind // ignore: cast_nullable_to_non_nullable
              as PathSurfaceKind?,
      isEmpty: null == isEmpty
          ? _value.isEmpty
          : isEmpty // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      editorColorArgb: freezed == editorColorArgb
          ? _value.editorColorArgb
          : editorColorArgb // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectSmartTileMaterialImplCopyWith<$Res>
    implements $ProjectSmartTileMaterialCopyWith<$Res> {
  factory _$$ProjectSmartTileMaterialImplCopyWith(
          _$ProjectSmartTileMaterialImpl value,
          $Res Function(_$ProjectSmartTileMaterialImpl) then) =
      __$$ProjectSmartTileMaterialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String connectionGroupId,
      String categoryId,
      TerrainType? terrainType,
      PathSurfaceKind? pathSurfaceKind,
      bool isEmpty,
      int sortOrder,
      int? editorColorArgb});
}

/// @nodoc
class __$$ProjectSmartTileMaterialImplCopyWithImpl<$Res>
    extends _$ProjectSmartTileMaterialCopyWithImpl<$Res,
        _$ProjectSmartTileMaterialImpl>
    implements _$$ProjectSmartTileMaterialImplCopyWith<$Res> {
  __$$ProjectSmartTileMaterialImplCopyWithImpl(
      _$ProjectSmartTileMaterialImpl _value,
      $Res Function(_$ProjectSmartTileMaterialImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSmartTileMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? connectionGroupId = null,
    Object? categoryId = null,
    Object? terrainType = freezed,
    Object? pathSurfaceKind = freezed,
    Object? isEmpty = null,
    Object? sortOrder = null,
    Object? editorColorArgb = freezed,
  }) {
    return _then(_$ProjectSmartTileMaterialImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      connectionGroupId: null == connectionGroupId
          ? _value.connectionGroupId
          : connectionGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      terrainType: freezed == terrainType
          ? _value.terrainType
          : terrainType // ignore: cast_nullable_to_non_nullable
              as TerrainType?,
      pathSurfaceKind: freezed == pathSurfaceKind
          ? _value.pathSurfaceKind
          : pathSurfaceKind // ignore: cast_nullable_to_non_nullable
              as PathSurfaceKind?,
      isEmpty: null == isEmpty
          ? _value.isEmpty
          : isEmpty // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      editorColorArgb: freezed == editorColorArgb
          ? _value.editorColorArgb
          : editorColorArgb // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectSmartTileMaterialImpl implements _ProjectSmartTileMaterial {
  const _$ProjectSmartTileMaterialImpl(
      {required this.id,
      required this.name,
      required this.connectionGroupId,
      this.categoryId = '',
      this.terrainType,
      this.pathSurfaceKind,
      this.isEmpty = false,
      this.sortOrder = 0,
      this.editorColorArgb})
      : assert(id != "", 'id must not be blank'),
        assert(name != "", 'name must not be blank'),
        assert(connectionGroupId != "", 'connectionGroupId must not be blank');

  factory _$ProjectSmartTileMaterialImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectSmartTileMaterialImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String connectionGroupId;
  @override
  @JsonKey()
  final String categoryId;
  @override
  final TerrainType? terrainType;
  @override
  final PathSurfaceKind? pathSurfaceKind;
  @override
  @JsonKey()
  final bool isEmpty;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final int? editorColorArgb;

  @override
  String toString() {
    return 'ProjectSmartTileMaterial(id: $id, name: $name, connectionGroupId: $connectionGroupId, categoryId: $categoryId, terrainType: $terrainType, pathSurfaceKind: $pathSurfaceKind, isEmpty: $isEmpty, sortOrder: $sortOrder, editorColorArgb: $editorColorArgb)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSmartTileMaterialImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.connectionGroupId, connectionGroupId) ||
                other.connectionGroupId == connectionGroupId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.terrainType, terrainType) ||
                other.terrainType == terrainType) &&
            (identical(other.pathSurfaceKind, pathSurfaceKind) ||
                other.pathSurfaceKind == pathSurfaceKind) &&
            (identical(other.isEmpty, isEmpty) || other.isEmpty == isEmpty) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.editorColorArgb, editorColorArgb) ||
                other.editorColorArgb == editorColorArgb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      connectionGroupId,
      categoryId,
      terrainType,
      pathSurfaceKind,
      isEmpty,
      sortOrder,
      editorColorArgb);

  /// Create a copy of ProjectSmartTileMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSmartTileMaterialImplCopyWith<_$ProjectSmartTileMaterialImpl>
      get copyWith => __$$ProjectSmartTileMaterialImplCopyWithImpl<
          _$ProjectSmartTileMaterialImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSmartTileMaterialImplToJson(
      this,
    );
  }
}

abstract class _ProjectSmartTileMaterial implements ProjectSmartTileMaterial {
  const factory _ProjectSmartTileMaterial(
      {required final String id,
      required final String name,
      required final String connectionGroupId,
      final String categoryId,
      final TerrainType? terrainType,
      final PathSurfaceKind? pathSurfaceKind,
      final bool isEmpty,
      final int sortOrder,
      final int? editorColorArgb}) = _$ProjectSmartTileMaterialImpl;

  factory _ProjectSmartTileMaterial.fromJson(Map<String, dynamic> json) =
      _$ProjectSmartTileMaterialImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get connectionGroupId;
  @override
  String get categoryId;
  @override
  TerrainType? get terrainType;
  @override
  PathSurfaceKind? get pathSurfaceKind;
  @override
  bool get isEmpty;
  @override
  int get sortOrder;
  @override
  int? get editorColorArgb;

  /// Create a copy of ProjectSmartTileMaterial
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSmartTileMaterialImplCopyWith<_$ProjectSmartTileMaterialImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectSmartTileAnimationFrame _$ProjectSmartTileAnimationFrameFromJson(
    Map<String, dynamic> json) {
  return _ProjectSmartTileAnimationFrame.fromJson(json);
}

/// @nodoc
mixin _$ProjectSmartTileAnimationFrame {
  SmartTileFrameRef get frame => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;

  /// Serializes this ProjectSmartTileAnimationFrame to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSmartTileAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSmartTileAnimationFrameCopyWith<ProjectSmartTileAnimationFrame>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSmartTileAnimationFrameCopyWith<$Res> {
  factory $ProjectSmartTileAnimationFrameCopyWith(
          ProjectSmartTileAnimationFrame value,
          $Res Function(ProjectSmartTileAnimationFrame) then) =
      _$ProjectSmartTileAnimationFrameCopyWithImpl<$Res,
          ProjectSmartTileAnimationFrame>;
  @useResult
  $Res call({SmartTileFrameRef frame, int durationMs});

  $SmartTileFrameRefCopyWith<$Res> get frame;
}

/// @nodoc
class _$ProjectSmartTileAnimationFrameCopyWithImpl<$Res,
        $Val extends ProjectSmartTileAnimationFrame>
    implements $ProjectSmartTileAnimationFrameCopyWith<$Res> {
  _$ProjectSmartTileAnimationFrameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSmartTileAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frame = null,
    Object? durationMs = null,
  }) {
    return _then(_value.copyWith(
      frame: null == frame
          ? _value.frame
          : frame // ignore: cast_nullable_to_non_nullable
              as SmartTileFrameRef,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of ProjectSmartTileAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartTileFrameRefCopyWith<$Res> get frame {
    return $SmartTileFrameRefCopyWith<$Res>(_value.frame, (value) {
      return _then(_value.copyWith(frame: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectSmartTileAnimationFrameImplCopyWith<$Res>
    implements $ProjectSmartTileAnimationFrameCopyWith<$Res> {
  factory _$$ProjectSmartTileAnimationFrameImplCopyWith(
          _$ProjectSmartTileAnimationFrameImpl value,
          $Res Function(_$ProjectSmartTileAnimationFrameImpl) then) =
      __$$ProjectSmartTileAnimationFrameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SmartTileFrameRef frame, int durationMs});

  @override
  $SmartTileFrameRefCopyWith<$Res> get frame;
}

/// @nodoc
class __$$ProjectSmartTileAnimationFrameImplCopyWithImpl<$Res>
    extends _$ProjectSmartTileAnimationFrameCopyWithImpl<$Res,
        _$ProjectSmartTileAnimationFrameImpl>
    implements _$$ProjectSmartTileAnimationFrameImplCopyWith<$Res> {
  __$$ProjectSmartTileAnimationFrameImplCopyWithImpl(
      _$ProjectSmartTileAnimationFrameImpl _value,
      $Res Function(_$ProjectSmartTileAnimationFrameImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSmartTileAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frame = null,
    Object? durationMs = null,
  }) {
    return _then(_$ProjectSmartTileAnimationFrameImpl(
      frame: null == frame
          ? _value.frame
          : frame // ignore: cast_nullable_to_non_nullable
              as SmartTileFrameRef,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectSmartTileAnimationFrameImpl
    implements _ProjectSmartTileAnimationFrame {
  const _$ProjectSmartTileAnimationFrameImpl(
      {required this.frame, required this.durationMs});

  factory _$ProjectSmartTileAnimationFrameImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectSmartTileAnimationFrameImplFromJson(json);

  @override
  final SmartTileFrameRef frame;
  @override
  final int durationMs;

  @override
  String toString() {
    return 'ProjectSmartTileAnimationFrame(frame: $frame, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSmartTileAnimationFrameImpl &&
            (identical(other.frame, frame) || other.frame == frame) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, frame, durationMs);

  /// Create a copy of ProjectSmartTileAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSmartTileAnimationFrameImplCopyWith<
          _$ProjectSmartTileAnimationFrameImpl>
      get copyWith => __$$ProjectSmartTileAnimationFrameImplCopyWithImpl<
          _$ProjectSmartTileAnimationFrameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSmartTileAnimationFrameImplToJson(
      this,
    );
  }
}

abstract class _ProjectSmartTileAnimationFrame
    implements ProjectSmartTileAnimationFrame {
  const factory _ProjectSmartTileAnimationFrame(
      {required final SmartTileFrameRef frame,
      required final int durationMs}) = _$ProjectSmartTileAnimationFrameImpl;

  factory _ProjectSmartTileAnimationFrame.fromJson(Map<String, dynamic> json) =
      _$ProjectSmartTileAnimationFrameImpl.fromJson;

  @override
  SmartTileFrameRef get frame;
  @override
  int get durationMs;

  /// Create a copy of ProjectSmartTileAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSmartTileAnimationFrameImplCopyWith<
          _$ProjectSmartTileAnimationFrameImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectSmartTileAnimation _$ProjectSmartTileAnimationFromJson(
    Map<String, dynamic> json) {
  return _ProjectSmartTileAnimation.fromJson(json);
}

/// @nodoc
mixin _$ProjectSmartTileAnimation {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<ProjectSmartTileAnimationFrame> get frames =>
      throw _privateConstructorUsedError;
  SmartTileAnimationSync get sync => throw _privateConstructorUsedError;
  SmartTileAnimationLoop get loop => throw _privateConstructorUsedError;

  /// Serializes this ProjectSmartTileAnimation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSmartTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSmartTileAnimationCopyWith<ProjectSmartTileAnimation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSmartTileAnimationCopyWith<$Res> {
  factory $ProjectSmartTileAnimationCopyWith(ProjectSmartTileAnimation value,
          $Res Function(ProjectSmartTileAnimation) then) =
      _$ProjectSmartTileAnimationCopyWithImpl<$Res, ProjectSmartTileAnimation>;
  @useResult
  $Res call(
      {String id,
      String name,
      List<ProjectSmartTileAnimationFrame> frames,
      SmartTileAnimationSync sync,
      SmartTileAnimationLoop loop});
}

/// @nodoc
class _$ProjectSmartTileAnimationCopyWithImpl<$Res,
        $Val extends ProjectSmartTileAnimation>
    implements $ProjectSmartTileAnimationCopyWith<$Res> {
  _$ProjectSmartTileAnimationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSmartTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? frames = null,
    Object? sync = null,
    Object? loop = null,
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
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<ProjectSmartTileAnimationFrame>,
      sync: null == sync
          ? _value.sync
          : sync // ignore: cast_nullable_to_non_nullable
              as SmartTileAnimationSync,
      loop: null == loop
          ? _value.loop
          : loop // ignore: cast_nullable_to_non_nullable
              as SmartTileAnimationLoop,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectSmartTileAnimationImplCopyWith<$Res>
    implements $ProjectSmartTileAnimationCopyWith<$Res> {
  factory _$$ProjectSmartTileAnimationImplCopyWith(
          _$ProjectSmartTileAnimationImpl value,
          $Res Function(_$ProjectSmartTileAnimationImpl) then) =
      __$$ProjectSmartTileAnimationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      List<ProjectSmartTileAnimationFrame> frames,
      SmartTileAnimationSync sync,
      SmartTileAnimationLoop loop});
}

/// @nodoc
class __$$ProjectSmartTileAnimationImplCopyWithImpl<$Res>
    extends _$ProjectSmartTileAnimationCopyWithImpl<$Res,
        _$ProjectSmartTileAnimationImpl>
    implements _$$ProjectSmartTileAnimationImplCopyWith<$Res> {
  __$$ProjectSmartTileAnimationImplCopyWithImpl(
      _$ProjectSmartTileAnimationImpl _value,
      $Res Function(_$ProjectSmartTileAnimationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSmartTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? frames = null,
    Object? sync = null,
    Object? loop = null,
  }) {
    return _then(_$ProjectSmartTileAnimationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<ProjectSmartTileAnimationFrame>,
      sync: null == sync
          ? _value.sync
          : sync // ignore: cast_nullable_to_non_nullable
              as SmartTileAnimationSync,
      loop: null == loop
          ? _value.loop
          : loop // ignore: cast_nullable_to_non_nullable
              as SmartTileAnimationLoop,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectSmartTileAnimationImpl implements _ProjectSmartTileAnimation {
  const _$ProjectSmartTileAnimationImpl(
      {required this.id,
      required this.name,
      required final List<ProjectSmartTileAnimationFrame> frames,
      this.sync = SmartTileAnimationSync.global,
      this.loop = SmartTileAnimationLoop.repeat})
      : assert(id != "", 'id must not be blank'),
        assert(name != "", 'name must not be blank'),
        _frames = frames;

  factory _$ProjectSmartTileAnimationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectSmartTileAnimationImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<ProjectSmartTileAnimationFrame> _frames;
  @override
  List<ProjectSmartTileAnimationFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  @JsonKey()
  final SmartTileAnimationSync sync;
  @override
  @JsonKey()
  final SmartTileAnimationLoop loop;

  @override
  String toString() {
    return 'ProjectSmartTileAnimation(id: $id, name: $name, frames: $frames, sync: $sync, loop: $loop)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSmartTileAnimationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.sync, sync) || other.sync == sync) &&
            (identical(other.loop, loop) || other.loop == loop));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name,
      const DeepCollectionEquality().hash(_frames), sync, loop);

  /// Create a copy of ProjectSmartTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSmartTileAnimationImplCopyWith<_$ProjectSmartTileAnimationImpl>
      get copyWith => __$$ProjectSmartTileAnimationImplCopyWithImpl<
          _$ProjectSmartTileAnimationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSmartTileAnimationImplToJson(
      this,
    );
  }
}

abstract class _ProjectSmartTileAnimation implements ProjectSmartTileAnimation {
  const factory _ProjectSmartTileAnimation(
      {required final String id,
      required final String name,
      required final List<ProjectSmartTileAnimationFrame> frames,
      final SmartTileAnimationSync sync,
      final SmartTileAnimationLoop loop}) = _$ProjectSmartTileAnimationImpl;

  factory _ProjectSmartTileAnimation.fromJson(Map<String, dynamic> json) =
      _$ProjectSmartTileAnimationImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<ProjectSmartTileAnimationFrame> get frames;
  @override
  SmartTileAnimationSync get sync;
  @override
  SmartTileAnimationLoop get loop;

  /// Create a copy of ProjectSmartTileAnimation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSmartTileAnimationImplCopyWith<_$ProjectSmartTileAnimationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectSmartTilePreset _$ProjectSmartTilePresetFromJson(
    Map<String, dynamic> json) {
  return _ProjectSmartTilePreset.fromJson(json);
}

/// @nodoc
mixin _$ProjectSmartTilePreset {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  SmartTileUsage get usage => throw _privateConstructorUsedError;
  SmartTileTopology get topology => throw _privateConstructorUsedError;
  SmartTileTemplateHint get templateHint => throw _privateConstructorUsedError;
  SmartTileBoundaryPolicy get boundaryPolicy =>
      throw _privateConstructorUsedError;
  SmartTilePresetStatus get status => throw _privateConstructorUsedError;
  SmartTileCoveragePolicy get coveragePolicy =>
      throw _privateConstructorUsedError;
  SmartTileCoverageProfile get coverageProfile =>
      throw _privateConstructorUsedError;
  SmartTileTransformPolicy get transformPolicy =>
      throw _privateConstructorUsedError;
  String get defaultMaterialId => throw _privateConstructorUsedError;
  List<String> get allowedMaterialIds => throw _privateConstructorUsedError;
  List<SmartTileRule> get rules => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  int get seedSalt => throw _privateConstructorUsedError;
  String? get fallbackRuleId => throw _privateConstructorUsedError;

  /// Serializes this ProjectSmartTilePreset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSmartTilePreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSmartTilePresetCopyWith<ProjectSmartTilePreset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSmartTilePresetCopyWith<$Res> {
  factory $ProjectSmartTilePresetCopyWith(ProjectSmartTilePreset value,
          $Res Function(ProjectSmartTilePreset) then) =
      _$ProjectSmartTilePresetCopyWithImpl<$Res, ProjectSmartTilePreset>;
  @useResult
  $Res call(
      {String id,
      String name,
      String categoryId,
      SmartTileUsage usage,
      SmartTileTopology topology,
      SmartTileTemplateHint templateHint,
      SmartTileBoundaryPolicy boundaryPolicy,
      SmartTilePresetStatus status,
      SmartTileCoveragePolicy coveragePolicy,
      SmartTileCoverageProfile coverageProfile,
      SmartTileTransformPolicy transformPolicy,
      String defaultMaterialId,
      List<String> allowedMaterialIds,
      List<SmartTileRule> rules,
      List<String> tags,
      int sortOrder,
      int seedSalt,
      String? fallbackRuleId});

  $SmartTileCoverageProfileCopyWith<$Res> get coverageProfile;
  $SmartTileTransformPolicyCopyWith<$Res> get transformPolicy;
}

/// @nodoc
class _$ProjectSmartTilePresetCopyWithImpl<$Res,
        $Val extends ProjectSmartTilePreset>
    implements $ProjectSmartTilePresetCopyWith<$Res> {
  _$ProjectSmartTilePresetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSmartTilePreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? categoryId = null,
    Object? usage = null,
    Object? topology = null,
    Object? templateHint = null,
    Object? boundaryPolicy = null,
    Object? status = null,
    Object? coveragePolicy = null,
    Object? coverageProfile = null,
    Object? transformPolicy = null,
    Object? defaultMaterialId = null,
    Object? allowedMaterialIds = null,
    Object? rules = null,
    Object? tags = null,
    Object? sortOrder = null,
    Object? seedSalt = null,
    Object? fallbackRuleId = freezed,
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
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      usage: null == usage
          ? _value.usage
          : usage // ignore: cast_nullable_to_non_nullable
              as SmartTileUsage,
      topology: null == topology
          ? _value.topology
          : topology // ignore: cast_nullable_to_non_nullable
              as SmartTileTopology,
      templateHint: null == templateHint
          ? _value.templateHint
          : templateHint // ignore: cast_nullable_to_non_nullable
              as SmartTileTemplateHint,
      boundaryPolicy: null == boundaryPolicy
          ? _value.boundaryPolicy
          : boundaryPolicy // ignore: cast_nullable_to_non_nullable
              as SmartTileBoundaryPolicy,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SmartTilePresetStatus,
      coveragePolicy: null == coveragePolicy
          ? _value.coveragePolicy
          : coveragePolicy // ignore: cast_nullable_to_non_nullable
              as SmartTileCoveragePolicy,
      coverageProfile: null == coverageProfile
          ? _value.coverageProfile
          : coverageProfile // ignore: cast_nullable_to_non_nullable
              as SmartTileCoverageProfile,
      transformPolicy: null == transformPolicy
          ? _value.transformPolicy
          : transformPolicy // ignore: cast_nullable_to_non_nullable
              as SmartTileTransformPolicy,
      defaultMaterialId: null == defaultMaterialId
          ? _value.defaultMaterialId
          : defaultMaterialId // ignore: cast_nullable_to_non_nullable
              as String,
      allowedMaterialIds: null == allowedMaterialIds
          ? _value.allowedMaterialIds
          : allowedMaterialIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rules: null == rules
          ? _value.rules
          : rules // ignore: cast_nullable_to_non_nullable
              as List<SmartTileRule>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      seedSalt: null == seedSalt
          ? _value.seedSalt
          : seedSalt // ignore: cast_nullable_to_non_nullable
              as int,
      fallbackRuleId: freezed == fallbackRuleId
          ? _value.fallbackRuleId
          : fallbackRuleId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of ProjectSmartTilePreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartTileCoverageProfileCopyWith<$Res> get coverageProfile {
    return $SmartTileCoverageProfileCopyWith<$Res>(_value.coverageProfile,
        (value) {
      return _then(_value.copyWith(coverageProfile: value) as $Val);
    });
  }

  /// Create a copy of ProjectSmartTilePreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartTileTransformPolicyCopyWith<$Res> get transformPolicy {
    return $SmartTileTransformPolicyCopyWith<$Res>(_value.transformPolicy,
        (value) {
      return _then(_value.copyWith(transformPolicy: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectSmartTilePresetImplCopyWith<$Res>
    implements $ProjectSmartTilePresetCopyWith<$Res> {
  factory _$$ProjectSmartTilePresetImplCopyWith(
          _$ProjectSmartTilePresetImpl value,
          $Res Function(_$ProjectSmartTilePresetImpl) then) =
      __$$ProjectSmartTilePresetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String categoryId,
      SmartTileUsage usage,
      SmartTileTopology topology,
      SmartTileTemplateHint templateHint,
      SmartTileBoundaryPolicy boundaryPolicy,
      SmartTilePresetStatus status,
      SmartTileCoveragePolicy coveragePolicy,
      SmartTileCoverageProfile coverageProfile,
      SmartTileTransformPolicy transformPolicy,
      String defaultMaterialId,
      List<String> allowedMaterialIds,
      List<SmartTileRule> rules,
      List<String> tags,
      int sortOrder,
      int seedSalt,
      String? fallbackRuleId});

  @override
  $SmartTileCoverageProfileCopyWith<$Res> get coverageProfile;
  @override
  $SmartTileTransformPolicyCopyWith<$Res> get transformPolicy;
}

/// @nodoc
class __$$ProjectSmartTilePresetImplCopyWithImpl<$Res>
    extends _$ProjectSmartTilePresetCopyWithImpl<$Res,
        _$ProjectSmartTilePresetImpl>
    implements _$$ProjectSmartTilePresetImplCopyWith<$Res> {
  __$$ProjectSmartTilePresetImplCopyWithImpl(
      _$ProjectSmartTilePresetImpl _value,
      $Res Function(_$ProjectSmartTilePresetImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSmartTilePreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? categoryId = null,
    Object? usage = null,
    Object? topology = null,
    Object? templateHint = null,
    Object? boundaryPolicy = null,
    Object? status = null,
    Object? coveragePolicy = null,
    Object? coverageProfile = null,
    Object? transformPolicy = null,
    Object? defaultMaterialId = null,
    Object? allowedMaterialIds = null,
    Object? rules = null,
    Object? tags = null,
    Object? sortOrder = null,
    Object? seedSalt = null,
    Object? fallbackRuleId = freezed,
  }) {
    return _then(_$ProjectSmartTilePresetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      usage: null == usage
          ? _value.usage
          : usage // ignore: cast_nullable_to_non_nullable
              as SmartTileUsage,
      topology: null == topology
          ? _value.topology
          : topology // ignore: cast_nullable_to_non_nullable
              as SmartTileTopology,
      templateHint: null == templateHint
          ? _value.templateHint
          : templateHint // ignore: cast_nullable_to_non_nullable
              as SmartTileTemplateHint,
      boundaryPolicy: null == boundaryPolicy
          ? _value.boundaryPolicy
          : boundaryPolicy // ignore: cast_nullable_to_non_nullable
              as SmartTileBoundaryPolicy,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SmartTilePresetStatus,
      coveragePolicy: null == coveragePolicy
          ? _value.coveragePolicy
          : coveragePolicy // ignore: cast_nullable_to_non_nullable
              as SmartTileCoveragePolicy,
      coverageProfile: null == coverageProfile
          ? _value.coverageProfile
          : coverageProfile // ignore: cast_nullable_to_non_nullable
              as SmartTileCoverageProfile,
      transformPolicy: null == transformPolicy
          ? _value.transformPolicy
          : transformPolicy // ignore: cast_nullable_to_non_nullable
              as SmartTileTransformPolicy,
      defaultMaterialId: null == defaultMaterialId
          ? _value.defaultMaterialId
          : defaultMaterialId // ignore: cast_nullable_to_non_nullable
              as String,
      allowedMaterialIds: null == allowedMaterialIds
          ? _value._allowedMaterialIds
          : allowedMaterialIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rules: null == rules
          ? _value._rules
          : rules // ignore: cast_nullable_to_non_nullable
              as List<SmartTileRule>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      seedSalt: null == seedSalt
          ? _value.seedSalt
          : seedSalt // ignore: cast_nullable_to_non_nullable
              as int,
      fallbackRuleId: freezed == fallbackRuleId
          ? _value.fallbackRuleId
          : fallbackRuleId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectSmartTilePresetImpl implements _ProjectSmartTilePreset {
  const _$ProjectSmartTilePresetImpl(
      {required this.id,
      required this.name,
      this.categoryId = '',
      required this.usage,
      required this.topology,
      this.templateHint = SmartTileTemplateHint.free,
      this.boundaryPolicy = SmartTileBoundaryPolicy.empty,
      this.status = SmartTilePresetStatus.draft,
      required this.coveragePolicy,
      required this.coverageProfile,
      required this.transformPolicy,
      required this.defaultMaterialId,
      required final List<String> allowedMaterialIds,
      final List<SmartTileRule> rules = const <SmartTileRule>[],
      final List<String> tags = const <String>[],
      this.sortOrder = 0,
      this.seedSalt = 0,
      this.fallbackRuleId})
      : assert(id != "", 'id must not be blank'),
        assert(name != "", 'name must not be blank'),
        assert(defaultMaterialId != "", 'defaultMaterialId must not be blank'),
        _allowedMaterialIds = allowedMaterialIds,
        _rules = rules,
        _tags = tags;

  factory _$ProjectSmartTilePresetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectSmartTilePresetImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String categoryId;
  @override
  final SmartTileUsage usage;
  @override
  final SmartTileTopology topology;
  @override
  @JsonKey()
  final SmartTileTemplateHint templateHint;
  @override
  @JsonKey()
  final SmartTileBoundaryPolicy boundaryPolicy;
  @override
  @JsonKey()
  final SmartTilePresetStatus status;
  @override
  final SmartTileCoveragePolicy coveragePolicy;
  @override
  final SmartTileCoverageProfile coverageProfile;
  @override
  final SmartTileTransformPolicy transformPolicy;
  @override
  final String defaultMaterialId;
  final List<String> _allowedMaterialIds;
  @override
  List<String> get allowedMaterialIds {
    if (_allowedMaterialIds is EqualUnmodifiableListView)
      return _allowedMaterialIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedMaterialIds);
  }

  final List<SmartTileRule> _rules;
  @override
  @JsonKey()
  List<SmartTileRule> get rules {
    if (_rules is EqualUnmodifiableListView) return _rules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rules);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final int sortOrder;
  @override
  @JsonKey()
  final int seedSalt;
  @override
  final String? fallbackRuleId;

  @override
  String toString() {
    return 'ProjectSmartTilePreset(id: $id, name: $name, categoryId: $categoryId, usage: $usage, topology: $topology, templateHint: $templateHint, boundaryPolicy: $boundaryPolicy, status: $status, coveragePolicy: $coveragePolicy, coverageProfile: $coverageProfile, transformPolicy: $transformPolicy, defaultMaterialId: $defaultMaterialId, allowedMaterialIds: $allowedMaterialIds, rules: $rules, tags: $tags, sortOrder: $sortOrder, seedSalt: $seedSalt, fallbackRuleId: $fallbackRuleId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSmartTilePresetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.usage, usage) || other.usage == usage) &&
            (identical(other.topology, topology) ||
                other.topology == topology) &&
            (identical(other.templateHint, templateHint) ||
                other.templateHint == templateHint) &&
            (identical(other.boundaryPolicy, boundaryPolicy) ||
                other.boundaryPolicy == boundaryPolicy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.coveragePolicy, coveragePolicy) ||
                other.coveragePolicy == coveragePolicy) &&
            (identical(other.coverageProfile, coverageProfile) ||
                other.coverageProfile == coverageProfile) &&
            (identical(other.transformPolicy, transformPolicy) ||
                other.transformPolicy == transformPolicy) &&
            (identical(other.defaultMaterialId, defaultMaterialId) ||
                other.defaultMaterialId == defaultMaterialId) &&
            const DeepCollectionEquality()
                .equals(other._allowedMaterialIds, _allowedMaterialIds) &&
            const DeepCollectionEquality().equals(other._rules, _rules) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.seedSalt, seedSalt) ||
                other.seedSalt == seedSalt) &&
            (identical(other.fallbackRuleId, fallbackRuleId) ||
                other.fallbackRuleId == fallbackRuleId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      categoryId,
      usage,
      topology,
      templateHint,
      boundaryPolicy,
      status,
      coveragePolicy,
      coverageProfile,
      transformPolicy,
      defaultMaterialId,
      const DeepCollectionEquality().hash(_allowedMaterialIds),
      const DeepCollectionEquality().hash(_rules),
      const DeepCollectionEquality().hash(_tags),
      sortOrder,
      seedSalt,
      fallbackRuleId);

  /// Create a copy of ProjectSmartTilePreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSmartTilePresetImplCopyWith<_$ProjectSmartTilePresetImpl>
      get copyWith => __$$ProjectSmartTilePresetImplCopyWithImpl<
          _$ProjectSmartTilePresetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSmartTilePresetImplToJson(
      this,
    );
  }
}

abstract class _ProjectSmartTilePreset implements ProjectSmartTilePreset {
  const factory _ProjectSmartTilePreset(
      {required final String id,
      required final String name,
      final String categoryId,
      required final SmartTileUsage usage,
      required final SmartTileTopology topology,
      final SmartTileTemplateHint templateHint,
      final SmartTileBoundaryPolicy boundaryPolicy,
      final SmartTilePresetStatus status,
      required final SmartTileCoveragePolicy coveragePolicy,
      required final SmartTileCoverageProfile coverageProfile,
      required final SmartTileTransformPolicy transformPolicy,
      required final String defaultMaterialId,
      required final List<String> allowedMaterialIds,
      final List<SmartTileRule> rules,
      final List<String> tags,
      final int sortOrder,
      final int seedSalt,
      final String? fallbackRuleId}) = _$ProjectSmartTilePresetImpl;

  factory _ProjectSmartTilePreset.fromJson(Map<String, dynamic> json) =
      _$ProjectSmartTilePresetImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get categoryId;
  @override
  SmartTileUsage get usage;
  @override
  SmartTileTopology get topology;
  @override
  SmartTileTemplateHint get templateHint;
  @override
  SmartTileBoundaryPolicy get boundaryPolicy;
  @override
  SmartTilePresetStatus get status;
  @override
  SmartTileCoveragePolicy get coveragePolicy;
  @override
  SmartTileCoverageProfile get coverageProfile;
  @override
  SmartTileTransformPolicy get transformPolicy;
  @override
  String get defaultMaterialId;
  @override
  List<String> get allowedMaterialIds;
  @override
  List<SmartTileRule> get rules;
  @override
  List<String> get tags;
  @override
  int get sortOrder;
  @override
  int get seedSalt;
  @override
  String? get fallbackRuleId;

  /// Create a copy of ProjectSmartTilePreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSmartTilePresetImplCopyWith<_$ProjectSmartTilePresetImpl>
      get copyWith => throw _privateConstructorUsedError;
}
