// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'smart_tile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SmartTileSourceRect {

 int get x; int get y; int get width; int get height;
/// Create a copy of SmartTileSourceRect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileSourceRectCopyWith<SmartTileSourceRect> get copyWith => _$SmartTileSourceRectCopyWithImpl<SmartTileSourceRect>(this as SmartTileSourceRect, _$identity);

  /// Serializes this SmartTileSourceRect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileSourceRect&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'SmartTileSourceRect(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $SmartTileSourceRectCopyWith<$Res>  {
  factory $SmartTileSourceRectCopyWith(SmartTileSourceRect value, $Res Function(SmartTileSourceRect) _then) = _$SmartTileSourceRectCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$SmartTileSourceRectCopyWithImpl<$Res>
    implements $SmartTileSourceRectCopyWith<$Res> {
  _$SmartTileSourceRectCopyWithImpl(this._self, this._then);

  final SmartTileSourceRect _self;
  final $Res Function(SmartTileSourceRect) _then;

/// Create a copy of SmartTileSourceRect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileSourceRect].
extension SmartTileSourceRectPatterns on SmartTileSourceRect {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileSourceRect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileSourceRect() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileSourceRect value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileSourceRect():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileSourceRect value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileSourceRect() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileSourceRect() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _SmartTileSourceRect():
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int x,  int y,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileSourceRect() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SmartTileSourceRect implements SmartTileSourceRect {
  const _SmartTileSourceRect({required this.x, required this.y, required this.width, required this.height}): assert(x >= 0, 'x must not be negative'),assert(y >= 0, 'y must not be negative'),assert(width > 0, 'width must be positive'),assert(height > 0, 'height must be positive');
  factory _SmartTileSourceRect.fromJson(Map<String, dynamic> json) => _$SmartTileSourceRectFromJson(json);

@override final  int x;
@override final  int y;
@override final  int width;
@override final  int height;

/// Create a copy of SmartTileSourceRect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileSourceRectCopyWith<_SmartTileSourceRect> get copyWith => __$SmartTileSourceRectCopyWithImpl<_SmartTileSourceRect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileSourceRectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileSourceRect&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'SmartTileSourceRect(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$SmartTileSourceRectCopyWith<$Res> implements $SmartTileSourceRectCopyWith<$Res> {
  factory _$SmartTileSourceRectCopyWith(_SmartTileSourceRect value, $Res Function(_SmartTileSourceRect) _then) = __$SmartTileSourceRectCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class __$SmartTileSourceRectCopyWithImpl<$Res>
    implements _$SmartTileSourceRectCopyWith<$Res> {
  __$SmartTileSourceRectCopyWithImpl(this._self, this._then);

  final _SmartTileSourceRect _self;
  final $Res Function(_SmartTileSourceRect) _then;

/// Create a copy of SmartTileSourceRect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_SmartTileSourceRect(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SmartTileFrameRef {

 String get atlasId; int get column; int get row; int get columnSpan; int get rowSpan;
/// Create a copy of SmartTileFrameRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileFrameRefCopyWith<SmartTileFrameRef> get copyWith => _$SmartTileFrameRefCopyWithImpl<SmartTileFrameRef>(this as SmartTileFrameRef, _$identity);

  /// Serializes this SmartTileFrameRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileFrameRef&&(identical(other.atlasId, atlasId) || other.atlasId == atlasId)&&(identical(other.column, column) || other.column == column)&&(identical(other.row, row) || other.row == row)&&(identical(other.columnSpan, columnSpan) || other.columnSpan == columnSpan)&&(identical(other.rowSpan, rowSpan) || other.rowSpan == rowSpan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,atlasId,column,row,columnSpan,rowSpan);

@override
String toString() {
  return 'SmartTileFrameRef(atlasId: $atlasId, column: $column, row: $row, columnSpan: $columnSpan, rowSpan: $rowSpan)';
}


}

/// @nodoc
abstract mixin class $SmartTileFrameRefCopyWith<$Res>  {
  factory $SmartTileFrameRefCopyWith(SmartTileFrameRef value, $Res Function(SmartTileFrameRef) _then) = _$SmartTileFrameRefCopyWithImpl;
@useResult
$Res call({
 String atlasId, int column, int row, int columnSpan, int rowSpan
});




}
/// @nodoc
class _$SmartTileFrameRefCopyWithImpl<$Res>
    implements $SmartTileFrameRefCopyWith<$Res> {
  _$SmartTileFrameRefCopyWithImpl(this._self, this._then);

  final SmartTileFrameRef _self;
  final $Res Function(SmartTileFrameRef) _then;

/// Create a copy of SmartTileFrameRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? atlasId = null,Object? column = null,Object? row = null,Object? columnSpan = null,Object? rowSpan = null,}) {
  return _then(_self.copyWith(
atlasId: null == atlasId ? _self.atlasId : atlasId // ignore: cast_nullable_to_non_nullable
as String,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as int,columnSpan: null == columnSpan ? _self.columnSpan : columnSpan // ignore: cast_nullable_to_non_nullable
as int,rowSpan: null == rowSpan ? _self.rowSpan : rowSpan // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileFrameRef].
extension SmartTileFrameRefPatterns on SmartTileFrameRef {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileFrameRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileFrameRef() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileFrameRef value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileFrameRef():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileFrameRef value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileFrameRef() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String atlasId,  int column,  int row,  int columnSpan,  int rowSpan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileFrameRef() when $default != null:
return $default(_that.atlasId,_that.column,_that.row,_that.columnSpan,_that.rowSpan);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String atlasId,  int column,  int row,  int columnSpan,  int rowSpan)  $default,) {final _that = this;
switch (_that) {
case _SmartTileFrameRef():
return $default(_that.atlasId,_that.column,_that.row,_that.columnSpan,_that.rowSpan);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String atlasId,  int column,  int row,  int columnSpan,  int rowSpan)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileFrameRef() when $default != null:
return $default(_that.atlasId,_that.column,_that.row,_that.columnSpan,_that.rowSpan);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SmartTileFrameRef implements SmartTileFrameRef {
  const _SmartTileFrameRef({required this.atlasId, required this.column, required this.row, this.columnSpan = 1, this.rowSpan = 1}): assert(atlasId != "", 'atlasId must not be blank'),assert(column >= 0, 'column must not be negative'),assert(row >= 0, 'row must not be negative'),assert(columnSpan > 0, 'columnSpan must be positive'),assert(rowSpan > 0, 'rowSpan must be positive');
  factory _SmartTileFrameRef.fromJson(Map<String, dynamic> json) => _$SmartTileFrameRefFromJson(json);

@override final  String atlasId;
@override final  int column;
@override final  int row;
@override@JsonKey() final  int columnSpan;
@override@JsonKey() final  int rowSpan;

/// Create a copy of SmartTileFrameRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileFrameRefCopyWith<_SmartTileFrameRef> get copyWith => __$SmartTileFrameRefCopyWithImpl<_SmartTileFrameRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileFrameRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileFrameRef&&(identical(other.atlasId, atlasId) || other.atlasId == atlasId)&&(identical(other.column, column) || other.column == column)&&(identical(other.row, row) || other.row == row)&&(identical(other.columnSpan, columnSpan) || other.columnSpan == columnSpan)&&(identical(other.rowSpan, rowSpan) || other.rowSpan == rowSpan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,atlasId,column,row,columnSpan,rowSpan);

@override
String toString() {
  return 'SmartTileFrameRef(atlasId: $atlasId, column: $column, row: $row, columnSpan: $columnSpan, rowSpan: $rowSpan)';
}


}

/// @nodoc
abstract mixin class _$SmartTileFrameRefCopyWith<$Res> implements $SmartTileFrameRefCopyWith<$Res> {
  factory _$SmartTileFrameRefCopyWith(_SmartTileFrameRef value, $Res Function(_SmartTileFrameRef) _then) = __$SmartTileFrameRefCopyWithImpl;
@override @useResult
$Res call({
 String atlasId, int column, int row, int columnSpan, int rowSpan
});




}
/// @nodoc
class __$SmartTileFrameRefCopyWithImpl<$Res>
    implements _$SmartTileFrameRefCopyWith<$Res> {
  __$SmartTileFrameRefCopyWithImpl(this._self, this._then);

  final _SmartTileFrameRef _self;
  final $Res Function(_SmartTileFrameRef) _then;

/// Create a copy of SmartTileFrameRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? atlasId = null,Object? column = null,Object? row = null,Object? columnSpan = null,Object? rowSpan = null,}) {
  return _then(_SmartTileFrameRef(
atlasId: null == atlasId ? _self.atlasId : atlasId // ignore: cast_nullable_to_non_nullable
as String,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as int,columnSpan: null == columnSpan ? _self.columnSpan : columnSpan // ignore: cast_nullable_to_non_nullable
as int,rowSpan: null == rowSpan ? _self.rowSpan : rowSpan // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SmartTileSignature {

 SmartTileSlotMatch get northWestCorner; SmartTileSlotMatch get northEdge; SmartTileSlotMatch get northEastCorner; SmartTileSlotMatch get eastEdge; SmartTileSlotMatch get southEastCorner; SmartTileSlotMatch get southEdge; SmartTileSlotMatch get southWestCorner; SmartTileSlotMatch get westEdge;
/// Create a copy of SmartTileSignature
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileSignatureCopyWith<SmartTileSignature> get copyWith => _$SmartTileSignatureCopyWithImpl<SmartTileSignature>(this as SmartTileSignature, _$identity);

  /// Serializes this SmartTileSignature to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileSignature&&(identical(other.northWestCorner, northWestCorner) || other.northWestCorner == northWestCorner)&&(identical(other.northEdge, northEdge) || other.northEdge == northEdge)&&(identical(other.northEastCorner, northEastCorner) || other.northEastCorner == northEastCorner)&&(identical(other.eastEdge, eastEdge) || other.eastEdge == eastEdge)&&(identical(other.southEastCorner, southEastCorner) || other.southEastCorner == southEastCorner)&&(identical(other.southEdge, southEdge) || other.southEdge == southEdge)&&(identical(other.southWestCorner, southWestCorner) || other.southWestCorner == southWestCorner)&&(identical(other.westEdge, westEdge) || other.westEdge == westEdge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,northWestCorner,northEdge,northEastCorner,eastEdge,southEastCorner,southEdge,southWestCorner,westEdge);

@override
String toString() {
  return 'SmartTileSignature(northWestCorner: $northWestCorner, northEdge: $northEdge, northEastCorner: $northEastCorner, eastEdge: $eastEdge, southEastCorner: $southEastCorner, southEdge: $southEdge, southWestCorner: $southWestCorner, westEdge: $westEdge)';
}


}

/// @nodoc
abstract mixin class $SmartTileSignatureCopyWith<$Res>  {
  factory $SmartTileSignatureCopyWith(SmartTileSignature value, $Res Function(SmartTileSignature) _then) = _$SmartTileSignatureCopyWithImpl;
@useResult
$Res call({
 SmartTileSlotMatch northWestCorner, SmartTileSlotMatch northEdge, SmartTileSlotMatch northEastCorner, SmartTileSlotMatch eastEdge, SmartTileSlotMatch southEastCorner, SmartTileSlotMatch southEdge, SmartTileSlotMatch southWestCorner, SmartTileSlotMatch westEdge
});




}
/// @nodoc
class _$SmartTileSignatureCopyWithImpl<$Res>
    implements $SmartTileSignatureCopyWith<$Res> {
  _$SmartTileSignatureCopyWithImpl(this._self, this._then);

  final SmartTileSignature _self;
  final $Res Function(SmartTileSignature) _then;

/// Create a copy of SmartTileSignature
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? northWestCorner = null,Object? northEdge = null,Object? northEastCorner = null,Object? eastEdge = null,Object? southEastCorner = null,Object? southEdge = null,Object? southWestCorner = null,Object? westEdge = null,}) {
  return _then(_self.copyWith(
northWestCorner: null == northWestCorner ? _self.northWestCorner : northWestCorner // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,northEdge: null == northEdge ? _self.northEdge : northEdge // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,northEastCorner: null == northEastCorner ? _self.northEastCorner : northEastCorner // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,eastEdge: null == eastEdge ? _self.eastEdge : eastEdge // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,southEastCorner: null == southEastCorner ? _self.southEastCorner : southEastCorner // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,southEdge: null == southEdge ? _self.southEdge : southEdge // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,southWestCorner: null == southWestCorner ? _self.southWestCorner : southWestCorner // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,westEdge: null == westEdge ? _self.westEdge : westEdge // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileSignature].
extension SmartTileSignaturePatterns on SmartTileSignature {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileSignature value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileSignature() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileSignature value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileSignature():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileSignature value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileSignature() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SmartTileSlotMatch northWestCorner,  SmartTileSlotMatch northEdge,  SmartTileSlotMatch northEastCorner,  SmartTileSlotMatch eastEdge,  SmartTileSlotMatch southEastCorner,  SmartTileSlotMatch southEdge,  SmartTileSlotMatch southWestCorner,  SmartTileSlotMatch westEdge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileSignature() when $default != null:
return $default(_that.northWestCorner,_that.northEdge,_that.northEastCorner,_that.eastEdge,_that.southEastCorner,_that.southEdge,_that.southWestCorner,_that.westEdge);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SmartTileSlotMatch northWestCorner,  SmartTileSlotMatch northEdge,  SmartTileSlotMatch northEastCorner,  SmartTileSlotMatch eastEdge,  SmartTileSlotMatch southEastCorner,  SmartTileSlotMatch southEdge,  SmartTileSlotMatch southWestCorner,  SmartTileSlotMatch westEdge)  $default,) {final _that = this;
switch (_that) {
case _SmartTileSignature():
return $default(_that.northWestCorner,_that.northEdge,_that.northEastCorner,_that.eastEdge,_that.southEastCorner,_that.southEdge,_that.southWestCorner,_that.westEdge);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SmartTileSlotMatch northWestCorner,  SmartTileSlotMatch northEdge,  SmartTileSlotMatch northEastCorner,  SmartTileSlotMatch eastEdge,  SmartTileSlotMatch southEastCorner,  SmartTileSlotMatch southEdge,  SmartTileSlotMatch southWestCorner,  SmartTileSlotMatch westEdge)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileSignature() when $default != null:
return $default(_that.northWestCorner,_that.northEdge,_that.northEastCorner,_that.eastEdge,_that.southEastCorner,_that.southEdge,_that.southWestCorner,_that.westEdge);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTileSignature implements SmartTileSignature {
  const _SmartTileSignature({this.northWestCorner = const SmartTileSlotMatch.any(), this.northEdge = const SmartTileSlotMatch.any(), this.northEastCorner = const SmartTileSlotMatch.any(), this.eastEdge = const SmartTileSlotMatch.any(), this.southEastCorner = const SmartTileSlotMatch.any(), this.southEdge = const SmartTileSlotMatch.any(), this.southWestCorner = const SmartTileSlotMatch.any(), this.westEdge = const SmartTileSlotMatch.any()});
  factory _SmartTileSignature.fromJson(Map<String, dynamic> json) => _$SmartTileSignatureFromJson(json);

@override@JsonKey() final  SmartTileSlotMatch northWestCorner;
@override@JsonKey() final  SmartTileSlotMatch northEdge;
@override@JsonKey() final  SmartTileSlotMatch northEastCorner;
@override@JsonKey() final  SmartTileSlotMatch eastEdge;
@override@JsonKey() final  SmartTileSlotMatch southEastCorner;
@override@JsonKey() final  SmartTileSlotMatch southEdge;
@override@JsonKey() final  SmartTileSlotMatch southWestCorner;
@override@JsonKey() final  SmartTileSlotMatch westEdge;

/// Create a copy of SmartTileSignature
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileSignatureCopyWith<_SmartTileSignature> get copyWith => __$SmartTileSignatureCopyWithImpl<_SmartTileSignature>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileSignatureToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileSignature&&(identical(other.northWestCorner, northWestCorner) || other.northWestCorner == northWestCorner)&&(identical(other.northEdge, northEdge) || other.northEdge == northEdge)&&(identical(other.northEastCorner, northEastCorner) || other.northEastCorner == northEastCorner)&&(identical(other.eastEdge, eastEdge) || other.eastEdge == eastEdge)&&(identical(other.southEastCorner, southEastCorner) || other.southEastCorner == southEastCorner)&&(identical(other.southEdge, southEdge) || other.southEdge == southEdge)&&(identical(other.southWestCorner, southWestCorner) || other.southWestCorner == southWestCorner)&&(identical(other.westEdge, westEdge) || other.westEdge == westEdge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,northWestCorner,northEdge,northEastCorner,eastEdge,southEastCorner,southEdge,southWestCorner,westEdge);

@override
String toString() {
  return 'SmartTileSignature(northWestCorner: $northWestCorner, northEdge: $northEdge, northEastCorner: $northEastCorner, eastEdge: $eastEdge, southEastCorner: $southEastCorner, southEdge: $southEdge, southWestCorner: $southWestCorner, westEdge: $westEdge)';
}


}

/// @nodoc
abstract mixin class _$SmartTileSignatureCopyWith<$Res> implements $SmartTileSignatureCopyWith<$Res> {
  factory _$SmartTileSignatureCopyWith(_SmartTileSignature value, $Res Function(_SmartTileSignature) _then) = __$SmartTileSignatureCopyWithImpl;
@override @useResult
$Res call({
 SmartTileSlotMatch northWestCorner, SmartTileSlotMatch northEdge, SmartTileSlotMatch northEastCorner, SmartTileSlotMatch eastEdge, SmartTileSlotMatch southEastCorner, SmartTileSlotMatch southEdge, SmartTileSlotMatch southWestCorner, SmartTileSlotMatch westEdge
});




}
/// @nodoc
class __$SmartTileSignatureCopyWithImpl<$Res>
    implements _$SmartTileSignatureCopyWith<$Res> {
  __$SmartTileSignatureCopyWithImpl(this._self, this._then);

  final _SmartTileSignature _self;
  final $Res Function(_SmartTileSignature) _then;

/// Create a copy of SmartTileSignature
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? northWestCorner = null,Object? northEdge = null,Object? northEastCorner = null,Object? eastEdge = null,Object? southEastCorner = null,Object? southEdge = null,Object? southWestCorner = null,Object? westEdge = null,}) {
  return _then(_SmartTileSignature(
northWestCorner: null == northWestCorner ? _self.northWestCorner : northWestCorner // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,northEdge: null == northEdge ? _self.northEdge : northEdge // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,northEastCorner: null == northEastCorner ? _self.northEastCorner : northEastCorner // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,eastEdge: null == eastEdge ? _self.eastEdge : eastEdge // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,southEastCorner: null == southEastCorner ? _self.southEastCorner : southEastCorner // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,southEdge: null == southEdge ? _self.southEdge : southEdge // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,southWestCorner: null == southWestCorner ? _self.southWestCorner : southWestCorner // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,westEdge: null == westEdge ? _self.westEdge : westEdge // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,
  ));
}


}


/// @nodoc
mixin _$SmartTileExactSignature {

 String? get northEdge; String? get northEastCorner; String? get eastEdge; String? get southEastCorner; String? get southEdge; String? get southWestCorner; String? get westEdge; String? get northWestCorner;
/// Create a copy of SmartTileExactSignature
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileExactSignatureCopyWith<SmartTileExactSignature> get copyWith => _$SmartTileExactSignatureCopyWithImpl<SmartTileExactSignature>(this as SmartTileExactSignature, _$identity);

  /// Serializes this SmartTileExactSignature to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileExactSignature&&(identical(other.northEdge, northEdge) || other.northEdge == northEdge)&&(identical(other.northEastCorner, northEastCorner) || other.northEastCorner == northEastCorner)&&(identical(other.eastEdge, eastEdge) || other.eastEdge == eastEdge)&&(identical(other.southEastCorner, southEastCorner) || other.southEastCorner == southEastCorner)&&(identical(other.southEdge, southEdge) || other.southEdge == southEdge)&&(identical(other.southWestCorner, southWestCorner) || other.southWestCorner == southWestCorner)&&(identical(other.westEdge, westEdge) || other.westEdge == westEdge)&&(identical(other.northWestCorner, northWestCorner) || other.northWestCorner == northWestCorner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,northEdge,northEastCorner,eastEdge,southEastCorner,southEdge,southWestCorner,westEdge,northWestCorner);

@override
String toString() {
  return 'SmartTileExactSignature(northEdge: $northEdge, northEastCorner: $northEastCorner, eastEdge: $eastEdge, southEastCorner: $southEastCorner, southEdge: $southEdge, southWestCorner: $southWestCorner, westEdge: $westEdge, northWestCorner: $northWestCorner)';
}


}

/// @nodoc
abstract mixin class $SmartTileExactSignatureCopyWith<$Res>  {
  factory $SmartTileExactSignatureCopyWith(SmartTileExactSignature value, $Res Function(SmartTileExactSignature) _then) = _$SmartTileExactSignatureCopyWithImpl;
@useResult
$Res call({
 String? northEdge, String? northEastCorner, String? eastEdge, String? southEastCorner, String? southEdge, String? southWestCorner, String? westEdge, String? northWestCorner
});




}
/// @nodoc
class _$SmartTileExactSignatureCopyWithImpl<$Res>
    implements $SmartTileExactSignatureCopyWith<$Res> {
  _$SmartTileExactSignatureCopyWithImpl(this._self, this._then);

  final SmartTileExactSignature _self;
  final $Res Function(SmartTileExactSignature) _then;

/// Create a copy of SmartTileExactSignature
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? northEdge = freezed,Object? northEastCorner = freezed,Object? eastEdge = freezed,Object? southEastCorner = freezed,Object? southEdge = freezed,Object? southWestCorner = freezed,Object? westEdge = freezed,Object? northWestCorner = freezed,}) {
  return _then(_self.copyWith(
northEdge: freezed == northEdge ? _self.northEdge : northEdge // ignore: cast_nullable_to_non_nullable
as String?,northEastCorner: freezed == northEastCorner ? _self.northEastCorner : northEastCorner // ignore: cast_nullable_to_non_nullable
as String?,eastEdge: freezed == eastEdge ? _self.eastEdge : eastEdge // ignore: cast_nullable_to_non_nullable
as String?,southEastCorner: freezed == southEastCorner ? _self.southEastCorner : southEastCorner // ignore: cast_nullable_to_non_nullable
as String?,southEdge: freezed == southEdge ? _self.southEdge : southEdge // ignore: cast_nullable_to_non_nullable
as String?,southWestCorner: freezed == southWestCorner ? _self.southWestCorner : southWestCorner // ignore: cast_nullable_to_non_nullable
as String?,westEdge: freezed == westEdge ? _self.westEdge : westEdge // ignore: cast_nullable_to_non_nullable
as String?,northWestCorner: freezed == northWestCorner ? _self.northWestCorner : northWestCorner // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileExactSignature].
extension SmartTileExactSignaturePatterns on SmartTileExactSignature {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileExactSignature value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileExactSignature() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileExactSignature value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileExactSignature():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileExactSignature value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileExactSignature() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? northEdge,  String? northEastCorner,  String? eastEdge,  String? southEastCorner,  String? southEdge,  String? southWestCorner,  String? westEdge,  String? northWestCorner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileExactSignature() when $default != null:
return $default(_that.northEdge,_that.northEastCorner,_that.eastEdge,_that.southEastCorner,_that.southEdge,_that.southWestCorner,_that.westEdge,_that.northWestCorner);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? northEdge,  String? northEastCorner,  String? eastEdge,  String? southEastCorner,  String? southEdge,  String? southWestCorner,  String? westEdge,  String? northWestCorner)  $default,) {final _that = this;
switch (_that) {
case _SmartTileExactSignature():
return $default(_that.northEdge,_that.northEastCorner,_that.eastEdge,_that.southEastCorner,_that.southEdge,_that.southWestCorner,_that.westEdge,_that.northWestCorner);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? northEdge,  String? northEastCorner,  String? eastEdge,  String? southEastCorner,  String? southEdge,  String? southWestCorner,  String? westEdge,  String? northWestCorner)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileExactSignature() when $default != null:
return $default(_that.northEdge,_that.northEastCorner,_that.eastEdge,_that.southEastCorner,_that.southEdge,_that.southWestCorner,_that.westEdge,_that.northWestCorner);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTileExactSignature implements SmartTileExactSignature {
  const _SmartTileExactSignature({this.northEdge, this.northEastCorner, this.eastEdge, this.southEastCorner, this.southEdge, this.southWestCorner, this.westEdge, this.northWestCorner});
  factory _SmartTileExactSignature.fromJson(Map<String, dynamic> json) => _$SmartTileExactSignatureFromJson(json);

@override final  String? northEdge;
@override final  String? northEastCorner;
@override final  String? eastEdge;
@override final  String? southEastCorner;
@override final  String? southEdge;
@override final  String? southWestCorner;
@override final  String? westEdge;
@override final  String? northWestCorner;

/// Create a copy of SmartTileExactSignature
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileExactSignatureCopyWith<_SmartTileExactSignature> get copyWith => __$SmartTileExactSignatureCopyWithImpl<_SmartTileExactSignature>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileExactSignatureToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileExactSignature&&(identical(other.northEdge, northEdge) || other.northEdge == northEdge)&&(identical(other.northEastCorner, northEastCorner) || other.northEastCorner == northEastCorner)&&(identical(other.eastEdge, eastEdge) || other.eastEdge == eastEdge)&&(identical(other.southEastCorner, southEastCorner) || other.southEastCorner == southEastCorner)&&(identical(other.southEdge, southEdge) || other.southEdge == southEdge)&&(identical(other.southWestCorner, southWestCorner) || other.southWestCorner == southWestCorner)&&(identical(other.westEdge, westEdge) || other.westEdge == westEdge)&&(identical(other.northWestCorner, northWestCorner) || other.northWestCorner == northWestCorner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,northEdge,northEastCorner,eastEdge,southEastCorner,southEdge,southWestCorner,westEdge,northWestCorner);

@override
String toString() {
  return 'SmartTileExactSignature(northEdge: $northEdge, northEastCorner: $northEastCorner, eastEdge: $eastEdge, southEastCorner: $southEastCorner, southEdge: $southEdge, southWestCorner: $southWestCorner, westEdge: $westEdge, northWestCorner: $northWestCorner)';
}


}

/// @nodoc
abstract mixin class _$SmartTileExactSignatureCopyWith<$Res> implements $SmartTileExactSignatureCopyWith<$Res> {
  factory _$SmartTileExactSignatureCopyWith(_SmartTileExactSignature value, $Res Function(_SmartTileExactSignature) _then) = __$SmartTileExactSignatureCopyWithImpl;
@override @useResult
$Res call({
 String? northEdge, String? northEastCorner, String? eastEdge, String? southEastCorner, String? southEdge, String? southWestCorner, String? westEdge, String? northWestCorner
});




}
/// @nodoc
class __$SmartTileExactSignatureCopyWithImpl<$Res>
    implements _$SmartTileExactSignatureCopyWith<$Res> {
  __$SmartTileExactSignatureCopyWithImpl(this._self, this._then);

  final _SmartTileExactSignature _self;
  final $Res Function(_SmartTileExactSignature) _then;

/// Create a copy of SmartTileExactSignature
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? northEdge = freezed,Object? northEastCorner = freezed,Object? eastEdge = freezed,Object? southEastCorner = freezed,Object? southEdge = freezed,Object? southWestCorner = freezed,Object? westEdge = freezed,Object? northWestCorner = freezed,}) {
  return _then(_SmartTileExactSignature(
northEdge: freezed == northEdge ? _self.northEdge : northEdge // ignore: cast_nullable_to_non_nullable
as String?,northEastCorner: freezed == northEastCorner ? _self.northEastCorner : northEastCorner // ignore: cast_nullable_to_non_nullable
as String?,eastEdge: freezed == eastEdge ? _self.eastEdge : eastEdge // ignore: cast_nullable_to_non_nullable
as String?,southEastCorner: freezed == southEastCorner ? _self.southEastCorner : southEastCorner // ignore: cast_nullable_to_non_nullable
as String?,southEdge: freezed == southEdge ? _self.southEdge : southEdge // ignore: cast_nullable_to_non_nullable
as String?,southWestCorner: freezed == southWestCorner ? _self.southWestCorner : southWestCorner // ignore: cast_nullable_to_non_nullable
as String?,westEdge: freezed == westEdge ? _self.westEdge : westEdge // ignore: cast_nullable_to_non_nullable
as String?,northWestCorner: freezed == northWestCorner ? _self.northWestCorner : northWestCorner // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SmartTileCoverageScenario {

 String get id; String? get centerMaterialId; SmartTileExactSignature get signature;
/// Create a copy of SmartTileCoverageScenario
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileCoverageScenarioCopyWith<SmartTileCoverageScenario> get copyWith => _$SmartTileCoverageScenarioCopyWithImpl<SmartTileCoverageScenario>(this as SmartTileCoverageScenario, _$identity);

  /// Serializes this SmartTileCoverageScenario to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileCoverageScenario&&(identical(other.id, id) || other.id == id)&&(identical(other.centerMaterialId, centerMaterialId) || other.centerMaterialId == centerMaterialId)&&(identical(other.signature, signature) || other.signature == signature));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,centerMaterialId,signature);

@override
String toString() {
  return 'SmartTileCoverageScenario(id: $id, centerMaterialId: $centerMaterialId, signature: $signature)';
}


}

/// @nodoc
abstract mixin class $SmartTileCoverageScenarioCopyWith<$Res>  {
  factory $SmartTileCoverageScenarioCopyWith(SmartTileCoverageScenario value, $Res Function(SmartTileCoverageScenario) _then) = _$SmartTileCoverageScenarioCopyWithImpl;
@useResult
$Res call({
 String id, String? centerMaterialId, SmartTileExactSignature signature
});


$SmartTileExactSignatureCopyWith<$Res> get signature;

}
/// @nodoc
class _$SmartTileCoverageScenarioCopyWithImpl<$Res>
    implements $SmartTileCoverageScenarioCopyWith<$Res> {
  _$SmartTileCoverageScenarioCopyWithImpl(this._self, this._then);

  final SmartTileCoverageScenario _self;
  final $Res Function(SmartTileCoverageScenario) _then;

/// Create a copy of SmartTileCoverageScenario
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? centerMaterialId = freezed,Object? signature = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,centerMaterialId: freezed == centerMaterialId ? _self.centerMaterialId : centerMaterialId // ignore: cast_nullable_to_non_nullable
as String?,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as SmartTileExactSignature,
  ));
}
/// Create a copy of SmartTileCoverageScenario
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileExactSignatureCopyWith<$Res> get signature {

  return $SmartTileExactSignatureCopyWith<$Res>(_self.signature, (value) {
    return _then(_self.copyWith(signature: value));
  });
}
}


/// Adds pattern-matching-related methods to [SmartTileCoverageScenario].
extension SmartTileCoverageScenarioPatterns on SmartTileCoverageScenario {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileCoverageScenario value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileCoverageScenario() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileCoverageScenario value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileCoverageScenario():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileCoverageScenario value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileCoverageScenario() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? centerMaterialId,  SmartTileExactSignature signature)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileCoverageScenario() when $default != null:
return $default(_that.id,_that.centerMaterialId,_that.signature);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? centerMaterialId,  SmartTileExactSignature signature)  $default,) {final _that = this;
switch (_that) {
case _SmartTileCoverageScenario():
return $default(_that.id,_that.centerMaterialId,_that.signature);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? centerMaterialId,  SmartTileExactSignature signature)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileCoverageScenario() when $default != null:
return $default(_that.id,_that.centerMaterialId,_that.signature);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTileCoverageScenario implements SmartTileCoverageScenario {
  const _SmartTileCoverageScenario({required this.id, this.centerMaterialId, this.signature = const SmartTileExactSignature()});
  factory _SmartTileCoverageScenario.fromJson(Map<String, dynamic> json) => _$SmartTileCoverageScenarioFromJson(json);

@override final  String id;
@override final  String? centerMaterialId;
@override@JsonKey() final  SmartTileExactSignature signature;

/// Create a copy of SmartTileCoverageScenario
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileCoverageScenarioCopyWith<_SmartTileCoverageScenario> get copyWith => __$SmartTileCoverageScenarioCopyWithImpl<_SmartTileCoverageScenario>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileCoverageScenarioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileCoverageScenario&&(identical(other.id, id) || other.id == id)&&(identical(other.centerMaterialId, centerMaterialId) || other.centerMaterialId == centerMaterialId)&&(identical(other.signature, signature) || other.signature == signature));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,centerMaterialId,signature);

@override
String toString() {
  return 'SmartTileCoverageScenario(id: $id, centerMaterialId: $centerMaterialId, signature: $signature)';
}


}

/// @nodoc
abstract mixin class _$SmartTileCoverageScenarioCopyWith<$Res> implements $SmartTileCoverageScenarioCopyWith<$Res> {
  factory _$SmartTileCoverageScenarioCopyWith(_SmartTileCoverageScenario value, $Res Function(_SmartTileCoverageScenario) _then) = __$SmartTileCoverageScenarioCopyWithImpl;
@override @useResult
$Res call({
 String id, String? centerMaterialId, SmartTileExactSignature signature
});


@override $SmartTileExactSignatureCopyWith<$Res> get signature;

}
/// @nodoc
class __$SmartTileCoverageScenarioCopyWithImpl<$Res>
    implements _$SmartTileCoverageScenarioCopyWith<$Res> {
  __$SmartTileCoverageScenarioCopyWithImpl(this._self, this._then);

  final _SmartTileCoverageScenario _self;
  final $Res Function(_SmartTileCoverageScenario) _then;

/// Create a copy of SmartTileCoverageScenario
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? centerMaterialId = freezed,Object? signature = null,}) {
  return _then(_SmartTileCoverageScenario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,centerMaterialId: freezed == centerMaterialId ? _self.centerMaterialId : centerMaterialId // ignore: cast_nullable_to_non_nullable
as String?,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as SmartTileExactSignature,
  ));
}

/// Create a copy of SmartTileCoverageScenario
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileExactSignatureCopyWith<$Res> get signature {

  return $SmartTileExactSignatureCopyWith<$Res>(_self.signature, (value) {
    return _then(_self.copyWith(signature: value));
  });
}
}


/// @nodoc
mixin _$SmartTileCoverageProfile {

 SmartTileCoverageMode get mode; List<SmartTileCoverageScenario> get requiredScenarios; bool get allowFallback;
/// Create a copy of SmartTileCoverageProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileCoverageProfileCopyWith<SmartTileCoverageProfile> get copyWith => _$SmartTileCoverageProfileCopyWithImpl<SmartTileCoverageProfile>(this as SmartTileCoverageProfile, _$identity);

  /// Serializes this SmartTileCoverageProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileCoverageProfile&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other.requiredScenarios, requiredScenarios)&&(identical(other.allowFallback, allowFallback) || other.allowFallback == allowFallback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,const DeepCollectionEquality().hash(requiredScenarios),allowFallback);

@override
String toString() {
  return 'SmartTileCoverageProfile(mode: $mode, requiredScenarios: $requiredScenarios, allowFallback: $allowFallback)';
}


}

/// @nodoc
abstract mixin class $SmartTileCoverageProfileCopyWith<$Res>  {
  factory $SmartTileCoverageProfileCopyWith(SmartTileCoverageProfile value, $Res Function(SmartTileCoverageProfile) _then) = _$SmartTileCoverageProfileCopyWithImpl;
@useResult
$Res call({
 SmartTileCoverageMode mode, List<SmartTileCoverageScenario> requiredScenarios, bool allowFallback
});




}
/// @nodoc
class _$SmartTileCoverageProfileCopyWithImpl<$Res>
    implements $SmartTileCoverageProfileCopyWith<$Res> {
  _$SmartTileCoverageProfileCopyWithImpl(this._self, this._then);

  final SmartTileCoverageProfile _self;
  final $Res Function(SmartTileCoverageProfile) _then;

/// Create a copy of SmartTileCoverageProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? requiredScenarios = null,Object? allowFallback = null,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SmartTileCoverageMode,requiredScenarios: null == requiredScenarios ? _self.requiredScenarios : requiredScenarios // ignore: cast_nullable_to_non_nullable
as List<SmartTileCoverageScenario>,allowFallback: null == allowFallback ? _self.allowFallback : allowFallback // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileCoverageProfile].
extension SmartTileCoverageProfilePatterns on SmartTileCoverageProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileCoverageProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileCoverageProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileCoverageProfile value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileCoverageProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileCoverageProfile value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileCoverageProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SmartTileCoverageMode mode,  List<SmartTileCoverageScenario> requiredScenarios,  bool allowFallback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileCoverageProfile() when $default != null:
return $default(_that.mode,_that.requiredScenarios,_that.allowFallback);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SmartTileCoverageMode mode,  List<SmartTileCoverageScenario> requiredScenarios,  bool allowFallback)  $default,) {final _that = this;
switch (_that) {
case _SmartTileCoverageProfile():
return $default(_that.mode,_that.requiredScenarios,_that.allowFallback);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SmartTileCoverageMode mode,  List<SmartTileCoverageScenario> requiredScenarios,  bool allowFallback)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileCoverageProfile() when $default != null:
return $default(_that.mode,_that.requiredScenarios,_that.allowFallback);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTileCoverageProfile implements SmartTileCoverageProfile {
  const _SmartTileCoverageProfile({required this.mode, final  List<SmartTileCoverageScenario> requiredScenarios = const <SmartTileCoverageScenario>[], this.allowFallback = false}): _requiredScenarios = requiredScenarios;
  factory _SmartTileCoverageProfile.fromJson(Map<String, dynamic> json) => _$SmartTileCoverageProfileFromJson(json);

@override final  SmartTileCoverageMode mode;
 final  List<SmartTileCoverageScenario> _requiredScenarios;
@override@JsonKey() List<SmartTileCoverageScenario> get requiredScenarios {
  if (_requiredScenarios is EqualUnmodifiableListView) return _requiredScenarios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredScenarios);
}

@override@JsonKey() final  bool allowFallback;

/// Create a copy of SmartTileCoverageProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileCoverageProfileCopyWith<_SmartTileCoverageProfile> get copyWith => __$SmartTileCoverageProfileCopyWithImpl<_SmartTileCoverageProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileCoverageProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileCoverageProfile&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other._requiredScenarios, _requiredScenarios)&&(identical(other.allowFallback, allowFallback) || other.allowFallback == allowFallback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,const DeepCollectionEquality().hash(_requiredScenarios),allowFallback);

@override
String toString() {
  return 'SmartTileCoverageProfile(mode: $mode, requiredScenarios: $requiredScenarios, allowFallback: $allowFallback)';
}


}

/// @nodoc
abstract mixin class _$SmartTileCoverageProfileCopyWith<$Res> implements $SmartTileCoverageProfileCopyWith<$Res> {
  factory _$SmartTileCoverageProfileCopyWith(_SmartTileCoverageProfile value, $Res Function(_SmartTileCoverageProfile) _then) = __$SmartTileCoverageProfileCopyWithImpl;
@override @useResult
$Res call({
 SmartTileCoverageMode mode, List<SmartTileCoverageScenario> requiredScenarios, bool allowFallback
});




}
/// @nodoc
class __$SmartTileCoverageProfileCopyWithImpl<$Res>
    implements _$SmartTileCoverageProfileCopyWith<$Res> {
  __$SmartTileCoverageProfileCopyWithImpl(this._self, this._then);

  final _SmartTileCoverageProfile _self;
  final $Res Function(_SmartTileCoverageProfile) _then;

/// Create a copy of SmartTileCoverageProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? requiredScenarios = null,Object? allowFallback = null,}) {
  return _then(_SmartTileCoverageProfile(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SmartTileCoverageMode,requiredScenarios: null == requiredScenarios ? _self._requiredScenarios : requiredScenarios // ignore: cast_nullable_to_non_nullable
as List<SmartTileCoverageScenario>,allowFallback: null == allowFallback ? _self.allowFallback : allowFallback // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SmartTileTransformPolicy {

 bool get allowHFlip; bool get allowVFlip; bool get allowQuarterTurns; bool get preferUntransformed;
/// Create a copy of SmartTileTransformPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileTransformPolicyCopyWith<SmartTileTransformPolicy> get copyWith => _$SmartTileTransformPolicyCopyWithImpl<SmartTileTransformPolicy>(this as SmartTileTransformPolicy, _$identity);

  /// Serializes this SmartTileTransformPolicy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileTransformPolicy&&(identical(other.allowHFlip, allowHFlip) || other.allowHFlip == allowHFlip)&&(identical(other.allowVFlip, allowVFlip) || other.allowVFlip == allowVFlip)&&(identical(other.allowQuarterTurns, allowQuarterTurns) || other.allowQuarterTurns == allowQuarterTurns)&&(identical(other.preferUntransformed, preferUntransformed) || other.preferUntransformed == preferUntransformed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,allowHFlip,allowVFlip,allowQuarterTurns,preferUntransformed);

@override
String toString() {
  return 'SmartTileTransformPolicy(allowHFlip: $allowHFlip, allowVFlip: $allowVFlip, allowQuarterTurns: $allowQuarterTurns, preferUntransformed: $preferUntransformed)';
}


}

/// @nodoc
abstract mixin class $SmartTileTransformPolicyCopyWith<$Res>  {
  factory $SmartTileTransformPolicyCopyWith(SmartTileTransformPolicy value, $Res Function(SmartTileTransformPolicy) _then) = _$SmartTileTransformPolicyCopyWithImpl;
@useResult
$Res call({
 bool allowHFlip, bool allowVFlip, bool allowQuarterTurns, bool preferUntransformed
});




}
/// @nodoc
class _$SmartTileTransformPolicyCopyWithImpl<$Res>
    implements $SmartTileTransformPolicyCopyWith<$Res> {
  _$SmartTileTransformPolicyCopyWithImpl(this._self, this._then);

  final SmartTileTransformPolicy _self;
  final $Res Function(SmartTileTransformPolicy) _then;

/// Create a copy of SmartTileTransformPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allowHFlip = null,Object? allowVFlip = null,Object? allowQuarterTurns = null,Object? preferUntransformed = null,}) {
  return _then(_self.copyWith(
allowHFlip: null == allowHFlip ? _self.allowHFlip : allowHFlip // ignore: cast_nullable_to_non_nullable
as bool,allowVFlip: null == allowVFlip ? _self.allowVFlip : allowVFlip // ignore: cast_nullable_to_non_nullable
as bool,allowQuarterTurns: null == allowQuarterTurns ? _self.allowQuarterTurns : allowQuarterTurns // ignore: cast_nullable_to_non_nullable
as bool,preferUntransformed: null == preferUntransformed ? _self.preferUntransformed : preferUntransformed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileTransformPolicy].
extension SmartTileTransformPolicyPatterns on SmartTileTransformPolicy {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileTransformPolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileTransformPolicy() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileTransformPolicy value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileTransformPolicy():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileTransformPolicy value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileTransformPolicy() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool allowHFlip,  bool allowVFlip,  bool allowQuarterTurns,  bool preferUntransformed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileTransformPolicy() when $default != null:
return $default(_that.allowHFlip,_that.allowVFlip,_that.allowQuarterTurns,_that.preferUntransformed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool allowHFlip,  bool allowVFlip,  bool allowQuarterTurns,  bool preferUntransformed)  $default,) {final _that = this;
switch (_that) {
case _SmartTileTransformPolicy():
return $default(_that.allowHFlip,_that.allowVFlip,_that.allowQuarterTurns,_that.preferUntransformed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool allowHFlip,  bool allowVFlip,  bool allowQuarterTurns,  bool preferUntransformed)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileTransformPolicy() when $default != null:
return $default(_that.allowHFlip,_that.allowVFlip,_that.allowQuarterTurns,_that.preferUntransformed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SmartTileTransformPolicy implements SmartTileTransformPolicy {
  const _SmartTileTransformPolicy({this.allowHFlip = false, this.allowVFlip = false, this.allowQuarterTurns = false, this.preferUntransformed = true});
  factory _SmartTileTransformPolicy.fromJson(Map<String, dynamic> json) => _$SmartTileTransformPolicyFromJson(json);

@override@JsonKey() final  bool allowHFlip;
@override@JsonKey() final  bool allowVFlip;
@override@JsonKey() final  bool allowQuarterTurns;
@override@JsonKey() final  bool preferUntransformed;

/// Create a copy of SmartTileTransformPolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileTransformPolicyCopyWith<_SmartTileTransformPolicy> get copyWith => __$SmartTileTransformPolicyCopyWithImpl<_SmartTileTransformPolicy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileTransformPolicyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileTransformPolicy&&(identical(other.allowHFlip, allowHFlip) || other.allowHFlip == allowHFlip)&&(identical(other.allowVFlip, allowVFlip) || other.allowVFlip == allowVFlip)&&(identical(other.allowQuarterTurns, allowQuarterTurns) || other.allowQuarterTurns == allowQuarterTurns)&&(identical(other.preferUntransformed, preferUntransformed) || other.preferUntransformed == preferUntransformed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,allowHFlip,allowVFlip,allowQuarterTurns,preferUntransformed);

@override
String toString() {
  return 'SmartTileTransformPolicy(allowHFlip: $allowHFlip, allowVFlip: $allowVFlip, allowQuarterTurns: $allowQuarterTurns, preferUntransformed: $preferUntransformed)';
}


}

/// @nodoc
abstract mixin class _$SmartTileTransformPolicyCopyWith<$Res> implements $SmartTileTransformPolicyCopyWith<$Res> {
  factory _$SmartTileTransformPolicyCopyWith(_SmartTileTransformPolicy value, $Res Function(_SmartTileTransformPolicy) _then) = __$SmartTileTransformPolicyCopyWithImpl;
@override @useResult
$Res call({
 bool allowHFlip, bool allowVFlip, bool allowQuarterTurns, bool preferUntransformed
});




}
/// @nodoc
class __$SmartTileTransformPolicyCopyWithImpl<$Res>
    implements _$SmartTileTransformPolicyCopyWith<$Res> {
  __$SmartTileTransformPolicyCopyWithImpl(this._self, this._then);

  final _SmartTileTransformPolicy _self;
  final $Res Function(_SmartTileTransformPolicy) _then;

/// Create a copy of SmartTileTransformPolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allowHFlip = null,Object? allowVFlip = null,Object? allowQuarterTurns = null,Object? preferUntransformed = null,}) {
  return _then(_SmartTileTransformPolicy(
allowHFlip: null == allowHFlip ? _self.allowHFlip : allowHFlip // ignore: cast_nullable_to_non_nullable
as bool,allowVFlip: null == allowVFlip ? _self.allowVFlip : allowVFlip // ignore: cast_nullable_to_non_nullable
as bool,allowQuarterTurns: null == allowQuarterTurns ? _self.allowQuarterTurns : allowQuarterTurns // ignore: cast_nullable_to_non_nullable
as bool,preferUntransformed: null == preferUntransformed ? _self.preferUntransformed : preferUntransformed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SmartTileSpriteTransform {

 int get quarterTurns; bool get flipX;
/// Create a copy of SmartTileSpriteTransform
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileSpriteTransformCopyWith<SmartTileSpriteTransform> get copyWith => _$SmartTileSpriteTransformCopyWithImpl<SmartTileSpriteTransform>(this as SmartTileSpriteTransform, _$identity);

  /// Serializes this SmartTileSpriteTransform to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileSpriteTransform&&(identical(other.quarterTurns, quarterTurns) || other.quarterTurns == quarterTurns)&&(identical(other.flipX, flipX) || other.flipX == flipX));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quarterTurns,flipX);

@override
String toString() {
  return 'SmartTileSpriteTransform(quarterTurns: $quarterTurns, flipX: $flipX)';
}


}

/// @nodoc
abstract mixin class $SmartTileSpriteTransformCopyWith<$Res>  {
  factory $SmartTileSpriteTransformCopyWith(SmartTileSpriteTransform value, $Res Function(SmartTileSpriteTransform) _then) = _$SmartTileSpriteTransformCopyWithImpl;
@useResult
$Res call({
 int quarterTurns, bool flipX
});




}
/// @nodoc
class _$SmartTileSpriteTransformCopyWithImpl<$Res>
    implements $SmartTileSpriteTransformCopyWith<$Res> {
  _$SmartTileSpriteTransformCopyWithImpl(this._self, this._then);

  final SmartTileSpriteTransform _self;
  final $Res Function(SmartTileSpriteTransform) _then;

/// Create a copy of SmartTileSpriteTransform
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quarterTurns = null,Object? flipX = null,}) {
  return _then(_self.copyWith(
quarterTurns: null == quarterTurns ? _self.quarterTurns : quarterTurns // ignore: cast_nullable_to_non_nullable
as int,flipX: null == flipX ? _self.flipX : flipX // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileSpriteTransform].
extension SmartTileSpriteTransformPatterns on SmartTileSpriteTransform {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileSpriteTransform value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileSpriteTransform() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileSpriteTransform value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileSpriteTransform():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileSpriteTransform value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileSpriteTransform() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int quarterTurns,  bool flipX)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileSpriteTransform() when $default != null:
return $default(_that.quarterTurns,_that.flipX);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int quarterTurns,  bool flipX)  $default,) {final _that = this;
switch (_that) {
case _SmartTileSpriteTransform():
return $default(_that.quarterTurns,_that.flipX);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int quarterTurns,  bool flipX)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileSpriteTransform() when $default != null:
return $default(_that.quarterTurns,_that.flipX);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SmartTileSpriteTransform implements SmartTileSpriteTransform {
  const _SmartTileSpriteTransform({this.quarterTurns = 0, this.flipX = false}): assert(quarterTurns >= 0 && quarterTurns <= 3, 'quarterTurns must be between 0 and 3');
  factory _SmartTileSpriteTransform.fromJson(Map<String, dynamic> json) => _$SmartTileSpriteTransformFromJson(json);

@override@JsonKey() final  int quarterTurns;
@override@JsonKey() final  bool flipX;

/// Create a copy of SmartTileSpriteTransform
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileSpriteTransformCopyWith<_SmartTileSpriteTransform> get copyWith => __$SmartTileSpriteTransformCopyWithImpl<_SmartTileSpriteTransform>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileSpriteTransformToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileSpriteTransform&&(identical(other.quarterTurns, quarterTurns) || other.quarterTurns == quarterTurns)&&(identical(other.flipX, flipX) || other.flipX == flipX));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quarterTurns,flipX);

@override
String toString() {
  return 'SmartTileSpriteTransform(quarterTurns: $quarterTurns, flipX: $flipX)';
}


}

/// @nodoc
abstract mixin class _$SmartTileSpriteTransformCopyWith<$Res> implements $SmartTileSpriteTransformCopyWith<$Res> {
  factory _$SmartTileSpriteTransformCopyWith(_SmartTileSpriteTransform value, $Res Function(_SmartTileSpriteTransform) _then) = __$SmartTileSpriteTransformCopyWithImpl;
@override @useResult
$Res call({
 int quarterTurns, bool flipX
});




}
/// @nodoc
class __$SmartTileSpriteTransformCopyWithImpl<$Res>
    implements _$SmartTileSpriteTransformCopyWith<$Res> {
  __$SmartTileSpriteTransformCopyWithImpl(this._self, this._then);

  final _SmartTileSpriteTransform _self;
  final $Res Function(_SmartTileSpriteTransform) _then;

/// Create a copy of SmartTileSpriteTransform
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quarterTurns = null,Object? flipX = null,}) {
  return _then(_SmartTileSpriteTransform(
quarterTurns: null == quarterTurns ? _self.quarterTurns : quarterTurns // ignore: cast_nullable_to_non_nullable
as int,flipX: null == flipX ? _self.flipX : flipX // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

SmartTileVisualSource _$SmartTileVisualSourceFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'frame':
          return SmartTileFrameSource.fromJson(
            json
          );
                case 'animation':
          return SmartTileAnimationSource.fromJson(
            json
          );

          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'SmartTileVisualSource',
  'Invalid union type "${json['kind']}"!'
);
        }

}

/// @nodoc
mixin _$SmartTileVisualSource {



  /// Serializes this SmartTileVisualSource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileVisualSource);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SmartTileVisualSource()';
}


}

/// @nodoc
class $SmartTileVisualSourceCopyWith<$Res>  {
$SmartTileVisualSourceCopyWith(SmartTileVisualSource _, $Res Function(SmartTileVisualSource) __);
}


/// Adds pattern-matching-related methods to [SmartTileVisualSource].
extension SmartTileVisualSourcePatterns on SmartTileVisualSource {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SmartTileFrameSource value)?  frame,TResult Function( SmartTileAnimationSource value)?  animation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SmartTileFrameSource() when frame != null:
return frame(_that);case SmartTileAnimationSource() when animation != null:
return animation(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SmartTileFrameSource value)  frame,required TResult Function( SmartTileAnimationSource value)  animation,}){
final _that = this;
switch (_that) {
case SmartTileFrameSource():
return frame(_that);case SmartTileAnimationSource():
return animation(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SmartTileFrameSource value)?  frame,TResult? Function( SmartTileAnimationSource value)?  animation,}){
final _that = this;
switch (_that) {
case SmartTileFrameSource() when frame != null:
return frame(_that);case SmartTileAnimationSource() when animation != null:
return animation(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SmartTileFrameRef frame)?  frame,TResult Function( String animationId)?  animation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SmartTileFrameSource() when frame != null:
return frame(_that.frame);case SmartTileAnimationSource() when animation != null:
return animation(_that.animationId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SmartTileFrameRef frame)  frame,required TResult Function( String animationId)  animation,}) {final _that = this;
switch (_that) {
case SmartTileFrameSource():
return frame(_that.frame);case SmartTileAnimationSource():
return animation(_that.animationId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SmartTileFrameRef frame)?  frame,TResult? Function( String animationId)?  animation,}) {final _that = this;
switch (_that) {
case SmartTileFrameSource() when frame != null:
return frame(_that.frame);case SmartTileAnimationSource() when animation != null:
return animation(_that.animationId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class SmartTileFrameSource implements SmartTileVisualSource {
  const SmartTileFrameSource({required this.frame, final  String? $type}): $type = $type ?? 'frame';
  factory SmartTileFrameSource.fromJson(Map<String, dynamic> json) => _$SmartTileFrameSourceFromJson(json);

 final  SmartTileFrameRef frame;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SmartTileVisualSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileFrameSourceCopyWith<SmartTileFrameSource> get copyWith => _$SmartTileFrameSourceCopyWithImpl<SmartTileFrameSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileFrameSourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileFrameSource&&(identical(other.frame, frame) || other.frame == frame));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frame);

@override
String toString() {
  return 'SmartTileVisualSource.frame(frame: $frame)';
}


}

/// @nodoc
abstract mixin class $SmartTileFrameSourceCopyWith<$Res> implements $SmartTileVisualSourceCopyWith<$Res> {
  factory $SmartTileFrameSourceCopyWith(SmartTileFrameSource value, $Res Function(SmartTileFrameSource) _then) = _$SmartTileFrameSourceCopyWithImpl;
@useResult
$Res call({
 SmartTileFrameRef frame
});


$SmartTileFrameRefCopyWith<$Res> get frame;

}
/// @nodoc
class _$SmartTileFrameSourceCopyWithImpl<$Res>
    implements $SmartTileFrameSourceCopyWith<$Res> {
  _$SmartTileFrameSourceCopyWithImpl(this._self, this._then);

  final SmartTileFrameSource _self;
  final $Res Function(SmartTileFrameSource) _then;

/// Create a copy of SmartTileVisualSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? frame = null,}) {
  return _then(SmartTileFrameSource(
frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as SmartTileFrameRef,
  ));
}

/// Create a copy of SmartTileVisualSource
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileFrameRefCopyWith<$Res> get frame {

  return $SmartTileFrameRefCopyWith<$Res>(_self.frame, (value) {
    return _then(_self.copyWith(frame: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class SmartTileAnimationSource implements SmartTileVisualSource {
  const SmartTileAnimationSource({required this.animationId, final  String? $type}): $type = $type ?? 'animation';
  factory SmartTileAnimationSource.fromJson(Map<String, dynamic> json) => _$SmartTileAnimationSourceFromJson(json);

 final  String animationId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SmartTileVisualSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileAnimationSourceCopyWith<SmartTileAnimationSource> get copyWith => _$SmartTileAnimationSourceCopyWithImpl<SmartTileAnimationSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileAnimationSourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileAnimationSource&&(identical(other.animationId, animationId) || other.animationId == animationId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,animationId);

@override
String toString() {
  return 'SmartTileVisualSource.animation(animationId: $animationId)';
}


}

/// @nodoc
abstract mixin class $SmartTileAnimationSourceCopyWith<$Res> implements $SmartTileVisualSourceCopyWith<$Res> {
  factory $SmartTileAnimationSourceCopyWith(SmartTileAnimationSource value, $Res Function(SmartTileAnimationSource) _then) = _$SmartTileAnimationSourceCopyWithImpl;
@useResult
$Res call({
 String animationId
});




}
/// @nodoc
class _$SmartTileAnimationSourceCopyWithImpl<$Res>
    implements $SmartTileAnimationSourceCopyWith<$Res> {
  _$SmartTileAnimationSourceCopyWithImpl(this._self, this._then);

  final SmartTileAnimationSource _self;
  final $Res Function(SmartTileAnimationSource) _then;

/// Create a copy of SmartTileVisualSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? animationId = null,}) {
  return _then(SmartTileAnimationSource(
animationId: null == animationId ? _self.animationId : animationId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SmartTileVisualPart {

 SmartTileVisualSource get source; SmartTileSpriteTransform get transform; SmartTileRenderChannel get channel; SmartTileFrameSampling get frameSampling; SmartTileOffsetUnit get offsetUnit; int get offsetX; int get offsetY; int get footprintWidth; int get footprintHeight; int get anchorX; int get anchorY; int get drawOrder;
/// Create a copy of SmartTileVisualPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileVisualPartCopyWith<SmartTileVisualPart> get copyWith => _$SmartTileVisualPartCopyWithImpl<SmartTileVisualPart>(this as SmartTileVisualPart, _$identity);

  /// Serializes this SmartTileVisualPart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileVisualPart&&(identical(other.source, source) || other.source == source)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.frameSampling, frameSampling) || other.frameSampling == frameSampling)&&(identical(other.offsetUnit, offsetUnit) || other.offsetUnit == offsetUnit)&&(identical(other.offsetX, offsetX) || other.offsetX == offsetX)&&(identical(other.offsetY, offsetY) || other.offsetY == offsetY)&&(identical(other.footprintWidth, footprintWidth) || other.footprintWidth == footprintWidth)&&(identical(other.footprintHeight, footprintHeight) || other.footprintHeight == footprintHeight)&&(identical(other.anchorX, anchorX) || other.anchorX == anchorX)&&(identical(other.anchorY, anchorY) || other.anchorY == anchorY)&&(identical(other.drawOrder, drawOrder) || other.drawOrder == drawOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,transform,channel,frameSampling,offsetUnit,offsetX,offsetY,footprintWidth,footprintHeight,anchorX,anchorY,drawOrder);

@override
String toString() {
  return 'SmartTileVisualPart(source: $source, transform: $transform, channel: $channel, frameSampling: $frameSampling, offsetUnit: $offsetUnit, offsetX: $offsetX, offsetY: $offsetY, footprintWidth: $footprintWidth, footprintHeight: $footprintHeight, anchorX: $anchorX, anchorY: $anchorY, drawOrder: $drawOrder)';
}


}

/// @nodoc
abstract mixin class $SmartTileVisualPartCopyWith<$Res>  {
  factory $SmartTileVisualPartCopyWith(SmartTileVisualPart value, $Res Function(SmartTileVisualPart) _then) = _$SmartTileVisualPartCopyWithImpl;
@useResult
$Res call({
 SmartTileVisualSource source, SmartTileSpriteTransform transform, SmartTileRenderChannel channel, SmartTileFrameSampling frameSampling, SmartTileOffsetUnit offsetUnit, int offsetX, int offsetY, int footprintWidth, int footprintHeight, int anchorX, int anchorY, int drawOrder
});


$SmartTileVisualSourceCopyWith<$Res> get source;$SmartTileSpriteTransformCopyWith<$Res> get transform;

}
/// @nodoc
class _$SmartTileVisualPartCopyWithImpl<$Res>
    implements $SmartTileVisualPartCopyWith<$Res> {
  _$SmartTileVisualPartCopyWithImpl(this._self, this._then);

  final SmartTileVisualPart _self;
  final $Res Function(SmartTileVisualPart) _then;

/// Create a copy of SmartTileVisualPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? transform = null,Object? channel = null,Object? frameSampling = null,Object? offsetUnit = null,Object? offsetX = null,Object? offsetY = null,Object? footprintWidth = null,Object? footprintHeight = null,Object? anchorX = null,Object? anchorY = null,Object? drawOrder = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SmartTileVisualSource,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as SmartTileSpriteTransform,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as SmartTileRenderChannel,frameSampling: null == frameSampling ? _self.frameSampling : frameSampling // ignore: cast_nullable_to_non_nullable
as SmartTileFrameSampling,offsetUnit: null == offsetUnit ? _self.offsetUnit : offsetUnit // ignore: cast_nullable_to_non_nullable
as SmartTileOffsetUnit,offsetX: null == offsetX ? _self.offsetX : offsetX // ignore: cast_nullable_to_non_nullable
as int,offsetY: null == offsetY ? _self.offsetY : offsetY // ignore: cast_nullable_to_non_nullable
as int,footprintWidth: null == footprintWidth ? _self.footprintWidth : footprintWidth // ignore: cast_nullable_to_non_nullable
as int,footprintHeight: null == footprintHeight ? _self.footprintHeight : footprintHeight // ignore: cast_nullable_to_non_nullable
as int,anchorX: null == anchorX ? _self.anchorX : anchorX // ignore: cast_nullable_to_non_nullable
as int,anchorY: null == anchorY ? _self.anchorY : anchorY // ignore: cast_nullable_to_non_nullable
as int,drawOrder: null == drawOrder ? _self.drawOrder : drawOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SmartTileVisualPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileVisualSourceCopyWith<$Res> get source {

  return $SmartTileVisualSourceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of SmartTileVisualPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileSpriteTransformCopyWith<$Res> get transform {

  return $SmartTileSpriteTransformCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}


/// Adds pattern-matching-related methods to [SmartTileVisualPart].
extension SmartTileVisualPartPatterns on SmartTileVisualPart {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileVisualPart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileVisualPart() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileVisualPart value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileVisualPart():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileVisualPart value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileVisualPart() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SmartTileVisualSource source,  SmartTileSpriteTransform transform,  SmartTileRenderChannel channel,  SmartTileFrameSampling frameSampling,  SmartTileOffsetUnit offsetUnit,  int offsetX,  int offsetY,  int footprintWidth,  int footprintHeight,  int anchorX,  int anchorY,  int drawOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileVisualPart() when $default != null:
return $default(_that.source,_that.transform,_that.channel,_that.frameSampling,_that.offsetUnit,_that.offsetX,_that.offsetY,_that.footprintWidth,_that.footprintHeight,_that.anchorX,_that.anchorY,_that.drawOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SmartTileVisualSource source,  SmartTileSpriteTransform transform,  SmartTileRenderChannel channel,  SmartTileFrameSampling frameSampling,  SmartTileOffsetUnit offsetUnit,  int offsetX,  int offsetY,  int footprintWidth,  int footprintHeight,  int anchorX,  int anchorY,  int drawOrder)  $default,) {final _that = this;
switch (_that) {
case _SmartTileVisualPart():
return $default(_that.source,_that.transform,_that.channel,_that.frameSampling,_that.offsetUnit,_that.offsetX,_that.offsetY,_that.footprintWidth,_that.footprintHeight,_that.anchorX,_that.anchorY,_that.drawOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SmartTileVisualSource source,  SmartTileSpriteTransform transform,  SmartTileRenderChannel channel,  SmartTileFrameSampling frameSampling,  SmartTileOffsetUnit offsetUnit,  int offsetX,  int offsetY,  int footprintWidth,  int footprintHeight,  int anchorX,  int anchorY,  int drawOrder)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileVisualPart() when $default != null:
return $default(_that.source,_that.transform,_that.channel,_that.frameSampling,_that.offsetUnit,_that.offsetX,_that.offsetY,_that.footprintWidth,_that.footprintHeight,_that.anchorX,_that.anchorY,_that.drawOrder);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTileVisualPart implements SmartTileVisualPart {
  const _SmartTileVisualPart({required this.source, this.transform = const SmartTileSpriteTransform(), this.channel = SmartTileRenderChannel.ground, this.frameSampling = SmartTileFrameSampling.fullFrame, this.offsetUnit = SmartTileOffsetUnit.pixel, this.offsetX = 0, this.offsetY = 0, this.footprintWidth = 1, this.footprintHeight = 1, this.anchorX = 0, this.anchorY = 0, this.drawOrder = 0}): assert(footprintWidth > 0, 'footprintWidth must be positive'),assert(footprintHeight > 0, 'footprintHeight must be positive');
  factory _SmartTileVisualPart.fromJson(Map<String, dynamic> json) => _$SmartTileVisualPartFromJson(json);

@override final  SmartTileVisualSource source;
@override@JsonKey() final  SmartTileSpriteTransform transform;
@override@JsonKey() final  SmartTileRenderChannel channel;
@override@JsonKey() final  SmartTileFrameSampling frameSampling;
@override@JsonKey() final  SmartTileOffsetUnit offsetUnit;
@override@JsonKey() final  int offsetX;
@override@JsonKey() final  int offsetY;
@override@JsonKey() final  int footprintWidth;
@override@JsonKey() final  int footprintHeight;
@override@JsonKey() final  int anchorX;
@override@JsonKey() final  int anchorY;
@override@JsonKey() final  int drawOrder;

/// Create a copy of SmartTileVisualPart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileVisualPartCopyWith<_SmartTileVisualPart> get copyWith => __$SmartTileVisualPartCopyWithImpl<_SmartTileVisualPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileVisualPartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileVisualPart&&(identical(other.source, source) || other.source == source)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.frameSampling, frameSampling) || other.frameSampling == frameSampling)&&(identical(other.offsetUnit, offsetUnit) || other.offsetUnit == offsetUnit)&&(identical(other.offsetX, offsetX) || other.offsetX == offsetX)&&(identical(other.offsetY, offsetY) || other.offsetY == offsetY)&&(identical(other.footprintWidth, footprintWidth) || other.footprintWidth == footprintWidth)&&(identical(other.footprintHeight, footprintHeight) || other.footprintHeight == footprintHeight)&&(identical(other.anchorX, anchorX) || other.anchorX == anchorX)&&(identical(other.anchorY, anchorY) || other.anchorY == anchorY)&&(identical(other.drawOrder, drawOrder) || other.drawOrder == drawOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,transform,channel,frameSampling,offsetUnit,offsetX,offsetY,footprintWidth,footprintHeight,anchorX,anchorY,drawOrder);

@override
String toString() {
  return 'SmartTileVisualPart(source: $source, transform: $transform, channel: $channel, frameSampling: $frameSampling, offsetUnit: $offsetUnit, offsetX: $offsetX, offsetY: $offsetY, footprintWidth: $footprintWidth, footprintHeight: $footprintHeight, anchorX: $anchorX, anchorY: $anchorY, drawOrder: $drawOrder)';
}


}

/// @nodoc
abstract mixin class _$SmartTileVisualPartCopyWith<$Res> implements $SmartTileVisualPartCopyWith<$Res> {
  factory _$SmartTileVisualPartCopyWith(_SmartTileVisualPart value, $Res Function(_SmartTileVisualPart) _then) = __$SmartTileVisualPartCopyWithImpl;
@override @useResult
$Res call({
 SmartTileVisualSource source, SmartTileSpriteTransform transform, SmartTileRenderChannel channel, SmartTileFrameSampling frameSampling, SmartTileOffsetUnit offsetUnit, int offsetX, int offsetY, int footprintWidth, int footprintHeight, int anchorX, int anchorY, int drawOrder
});


@override $SmartTileVisualSourceCopyWith<$Res> get source;@override $SmartTileSpriteTransformCopyWith<$Res> get transform;

}
/// @nodoc
class __$SmartTileVisualPartCopyWithImpl<$Res>
    implements _$SmartTileVisualPartCopyWith<$Res> {
  __$SmartTileVisualPartCopyWithImpl(this._self, this._then);

  final _SmartTileVisualPart _self;
  final $Res Function(_SmartTileVisualPart) _then;

/// Create a copy of SmartTileVisualPart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? transform = null,Object? channel = null,Object? frameSampling = null,Object? offsetUnit = null,Object? offsetX = null,Object? offsetY = null,Object? footprintWidth = null,Object? footprintHeight = null,Object? anchorX = null,Object? anchorY = null,Object? drawOrder = null,}) {
  return _then(_SmartTileVisualPart(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SmartTileVisualSource,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as SmartTileSpriteTransform,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as SmartTileRenderChannel,frameSampling: null == frameSampling ? _self.frameSampling : frameSampling // ignore: cast_nullable_to_non_nullable
as SmartTileFrameSampling,offsetUnit: null == offsetUnit ? _self.offsetUnit : offsetUnit // ignore: cast_nullable_to_non_nullable
as SmartTileOffsetUnit,offsetX: null == offsetX ? _self.offsetX : offsetX // ignore: cast_nullable_to_non_nullable
as int,offsetY: null == offsetY ? _self.offsetY : offsetY // ignore: cast_nullable_to_non_nullable
as int,footprintWidth: null == footprintWidth ? _self.footprintWidth : footprintWidth // ignore: cast_nullable_to_non_nullable
as int,footprintHeight: null == footprintHeight ? _self.footprintHeight : footprintHeight // ignore: cast_nullable_to_non_nullable
as int,anchorX: null == anchorX ? _self.anchorX : anchorX // ignore: cast_nullable_to_non_nullable
as int,anchorY: null == anchorY ? _self.anchorY : anchorY // ignore: cast_nullable_to_non_nullable
as int,drawOrder: null == drawOrder ? _self.drawOrder : drawOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SmartTileVisualPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileVisualSourceCopyWith<$Res> get source {

  return $SmartTileVisualSourceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of SmartTileVisualPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileSpriteTransformCopyWith<$Res> get transform {

  return $SmartTileSpriteTransformCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}


/// @nodoc
mixin _$SmartTilePatternCell {

 int get x; int get y; List<SmartTileVisualPart> get parts; bool get eraseMaterial; SmartTilePatternCollision get collision;
/// Create a copy of SmartTilePatternCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTilePatternCellCopyWith<SmartTilePatternCell> get copyWith => _$SmartTilePatternCellCopyWithImpl<SmartTilePatternCell>(this as SmartTilePatternCell, _$identity);

  /// Serializes this SmartTilePatternCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTilePatternCell&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&const DeepCollectionEquality().equals(other.parts, parts)&&(identical(other.eraseMaterial, eraseMaterial) || other.eraseMaterial == eraseMaterial)&&(identical(other.collision, collision) || other.collision == collision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,const DeepCollectionEquality().hash(parts),eraseMaterial,collision);

@override
String toString() {
  return 'SmartTilePatternCell(x: $x, y: $y, parts: $parts, eraseMaterial: $eraseMaterial, collision: $collision)';
}


}

/// @nodoc
abstract mixin class $SmartTilePatternCellCopyWith<$Res>  {
  factory $SmartTilePatternCellCopyWith(SmartTilePatternCell value, $Res Function(SmartTilePatternCell) _then) = _$SmartTilePatternCellCopyWithImpl;
@useResult
$Res call({
 int x, int y, List<SmartTileVisualPart> parts, bool eraseMaterial, SmartTilePatternCollision collision
});




}
/// @nodoc
class _$SmartTilePatternCellCopyWithImpl<$Res>
    implements $SmartTilePatternCellCopyWith<$Res> {
  _$SmartTilePatternCellCopyWithImpl(this._self, this._then);

  final SmartTilePatternCell _self;
  final $Res Function(SmartTilePatternCell) _then;

/// Create a copy of SmartTilePatternCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? parts = null,Object? eraseMaterial = null,Object? collision = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<SmartTileVisualPart>,eraseMaterial: null == eraseMaterial ? _self.eraseMaterial : eraseMaterial // ignore: cast_nullable_to_non_nullable
as bool,collision: null == collision ? _self.collision : collision // ignore: cast_nullable_to_non_nullable
as SmartTilePatternCollision,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTilePatternCell].
extension SmartTilePatternCellPatterns on SmartTilePatternCell {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTilePatternCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTilePatternCell() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTilePatternCell value)  $default,){
final _that = this;
switch (_that) {
case _SmartTilePatternCell():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTilePatternCell value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTilePatternCell() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int x,  int y,  List<SmartTileVisualPart> parts,  bool eraseMaterial,  SmartTilePatternCollision collision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTilePatternCell() when $default != null:
return $default(_that.x,_that.y,_that.parts,_that.eraseMaterial,_that.collision);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y,  List<SmartTileVisualPart> parts,  bool eraseMaterial,  SmartTilePatternCollision collision)  $default,) {final _that = this;
switch (_that) {
case _SmartTilePatternCell():
return $default(_that.x,_that.y,_that.parts,_that.eraseMaterial,_that.collision);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int x,  int y,  List<SmartTileVisualPart> parts,  bool eraseMaterial,  SmartTilePatternCollision collision)?  $default,) {final _that = this;
switch (_that) {
case _SmartTilePatternCell() when $default != null:
return $default(_that.x,_that.y,_that.parts,_that.eraseMaterial,_that.collision);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTilePatternCell implements SmartTilePatternCell {
  const _SmartTilePatternCell({required this.x, required this.y, final  List<SmartTileVisualPart> parts = const <SmartTileVisualPart>[], this.eraseMaterial = false, this.collision = SmartTilePatternCollision.inherit}): assert(x >= 0, 'x must not be negative'),assert(y >= 0, 'y must not be negative'),_parts = parts;
  factory _SmartTilePatternCell.fromJson(Map<String, dynamic> json) => _$SmartTilePatternCellFromJson(json);

@override final  int x;
@override final  int y;
 final  List<SmartTileVisualPart> _parts;
@override@JsonKey() List<SmartTileVisualPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

@override@JsonKey() final  bool eraseMaterial;
@override@JsonKey() final  SmartTilePatternCollision collision;

/// Create a copy of SmartTilePatternCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTilePatternCellCopyWith<_SmartTilePatternCell> get copyWith => __$SmartTilePatternCellCopyWithImpl<_SmartTilePatternCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTilePatternCellToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTilePatternCell&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&const DeepCollectionEquality().equals(other._parts, _parts)&&(identical(other.eraseMaterial, eraseMaterial) || other.eraseMaterial == eraseMaterial)&&(identical(other.collision, collision) || other.collision == collision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,const DeepCollectionEquality().hash(_parts),eraseMaterial,collision);

@override
String toString() {
  return 'SmartTilePatternCell(x: $x, y: $y, parts: $parts, eraseMaterial: $eraseMaterial, collision: $collision)';
}


}

/// @nodoc
abstract mixin class _$SmartTilePatternCellCopyWith<$Res> implements $SmartTilePatternCellCopyWith<$Res> {
  factory _$SmartTilePatternCellCopyWith(_SmartTilePatternCell value, $Res Function(_SmartTilePatternCell) _then) = __$SmartTilePatternCellCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, List<SmartTileVisualPart> parts, bool eraseMaterial, SmartTilePatternCollision collision
});




}
/// @nodoc
class __$SmartTilePatternCellCopyWithImpl<$Res>
    implements _$SmartTilePatternCellCopyWith<$Res> {
  __$SmartTilePatternCellCopyWithImpl(this._self, this._then);

  final _SmartTilePatternCell _self;
  final $Res Function(_SmartTilePatternCell) _then;

/// Create a copy of SmartTilePatternCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? parts = null,Object? eraseMaterial = null,Object? collision = null,}) {
  return _then(_SmartTilePatternCell(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<SmartTileVisualPart>,eraseMaterial: null == eraseMaterial ? _self.eraseMaterial : eraseMaterial // ignore: cast_nullable_to_non_nullable
as bool,collision: null == collision ? _self.collision : collision // ignore: cast_nullable_to_non_nullable
as SmartTilePatternCollision,
  ));
}


}


/// @nodoc
mixin _$ProjectSmartTilePattern {

 String get id; String get name; String get categoryId; SmartTileUsage get usage; int get width; int get height; int get anchorX; int get anchorY; SmartTilePatternRepeatMode get repeatMode; List<SmartTilePatternCell> get cells; int get drawOrder; List<String> get tags; int get sortOrder;
/// Create a copy of ProjectSmartTilePattern
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSmartTilePatternCopyWith<ProjectSmartTilePattern> get copyWith => _$ProjectSmartTilePatternCopyWithImpl<ProjectSmartTilePattern>(this as ProjectSmartTilePattern, _$identity);

  /// Serializes this ProjectSmartTilePattern to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSmartTilePattern&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.anchorX, anchorX) || other.anchorX == anchorX)&&(identical(other.anchorY, anchorY) || other.anchorY == anchorY)&&(identical(other.repeatMode, repeatMode) || other.repeatMode == repeatMode)&&const DeepCollectionEquality().equals(other.cells, cells)&&(identical(other.drawOrder, drawOrder) || other.drawOrder == drawOrder)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,usage,width,height,anchorX,anchorY,repeatMode,const DeepCollectionEquality().hash(cells),drawOrder,const DeepCollectionEquality().hash(tags),sortOrder);

@override
String toString() {
  return 'ProjectSmartTilePattern(id: $id, name: $name, categoryId: $categoryId, usage: $usage, width: $width, height: $height, anchorX: $anchorX, anchorY: $anchorY, repeatMode: $repeatMode, cells: $cells, drawOrder: $drawOrder, tags: $tags, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectSmartTilePatternCopyWith<$Res>  {
  factory $ProjectSmartTilePatternCopyWith(ProjectSmartTilePattern value, $Res Function(ProjectSmartTilePattern) _then) = _$ProjectSmartTilePatternCopyWithImpl;
@useResult
$Res call({
 String id, String name, String categoryId, SmartTileUsage usage, int width, int height, int anchorX, int anchorY, SmartTilePatternRepeatMode repeatMode, List<SmartTilePatternCell> cells, int drawOrder, List<String> tags, int sortOrder
});




}
/// @nodoc
class _$ProjectSmartTilePatternCopyWithImpl<$Res>
    implements $ProjectSmartTilePatternCopyWith<$Res> {
  _$ProjectSmartTilePatternCopyWithImpl(this._self, this._then);

  final ProjectSmartTilePattern _self;
  final $Res Function(ProjectSmartTilePattern) _then;

/// Create a copy of ProjectSmartTilePattern
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? usage = null,Object? width = null,Object? height = null,Object? anchorX = null,Object? anchorY = null,Object? repeatMode = null,Object? cells = null,Object? drawOrder = null,Object? tags = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as SmartTileUsage,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,anchorX: null == anchorX ? _self.anchorX : anchorX // ignore: cast_nullable_to_non_nullable
as int,anchorY: null == anchorY ? _self.anchorY : anchorY // ignore: cast_nullable_to_non_nullable
as int,repeatMode: null == repeatMode ? _self.repeatMode : repeatMode // ignore: cast_nullable_to_non_nullable
as SmartTilePatternRepeatMode,cells: null == cells ? _self.cells : cells // ignore: cast_nullable_to_non_nullable
as List<SmartTilePatternCell>,drawOrder: null == drawOrder ? _self.drawOrder : drawOrder // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSmartTilePattern].
extension ProjectSmartTilePatternPatterns on ProjectSmartTilePattern {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSmartTilePattern value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSmartTilePattern() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSmartTilePattern value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTilePattern():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSmartTilePattern value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTilePattern() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String categoryId,  SmartTileUsage usage,  int width,  int height,  int anchorX,  int anchorY,  SmartTilePatternRepeatMode repeatMode,  List<SmartTilePatternCell> cells,  int drawOrder,  List<String> tags,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSmartTilePattern() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.usage,_that.width,_that.height,_that.anchorX,_that.anchorY,_that.repeatMode,_that.cells,_that.drawOrder,_that.tags,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String categoryId,  SmartTileUsage usage,  int width,  int height,  int anchorX,  int anchorY,  SmartTilePatternRepeatMode repeatMode,  List<SmartTilePatternCell> cells,  int drawOrder,  List<String> tags,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTilePattern():
return $default(_that.id,_that.name,_that.categoryId,_that.usage,_that.width,_that.height,_that.anchorX,_that.anchorY,_that.repeatMode,_that.cells,_that.drawOrder,_that.tags,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String categoryId,  SmartTileUsage usage,  int width,  int height,  int anchorX,  int anchorY,  SmartTilePatternRepeatMode repeatMode,  List<SmartTilePatternCell> cells,  int drawOrder,  List<String> tags,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTilePattern() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.usage,_that.width,_that.height,_that.anchorX,_that.anchorY,_that.repeatMode,_that.cells,_that.drawOrder,_that.tags,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSmartTilePattern implements ProjectSmartTilePattern {
  const _ProjectSmartTilePattern({required this.id, required this.name, this.categoryId = '', required this.usage, required this.width, required this.height, this.anchorX = 0, this.anchorY = 0, this.repeatMode = SmartTilePatternRepeatMode.tiled, final  List<SmartTilePatternCell> cells = const <SmartTilePatternCell>[], this.drawOrder = 0, final  List<String> tags = const <String>[], this.sortOrder = 0}): assert(id != "", 'id must not be blank'),assert(name != "", 'name must not be blank'),assert(width > 0 && width <= 64, 'width must be between 1 and 64'),assert(height > 0 && height <= 64, 'height must be between 1 and 64'),assert(anchorX >= 0 && anchorX < width, 'anchorX must be in bounds'),assert(anchorY >= 0 && anchorY < height, 'anchorY must be in bounds'),_cells = cells,_tags = tags;
  factory _ProjectSmartTilePattern.fromJson(Map<String, dynamic> json) => _$ProjectSmartTilePatternFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String categoryId;
@override final  SmartTileUsage usage;
@override final  int width;
@override final  int height;
@override@JsonKey() final  int anchorX;
@override@JsonKey() final  int anchorY;
@override@JsonKey() final  SmartTilePatternRepeatMode repeatMode;
 final  List<SmartTilePatternCell> _cells;
@override@JsonKey() List<SmartTilePatternCell> get cells {
  if (_cells is EqualUnmodifiableListView) return _cells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cells);
}

@override@JsonKey() final  int drawOrder;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectSmartTilePattern
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSmartTilePatternCopyWith<_ProjectSmartTilePattern> get copyWith => __$ProjectSmartTilePatternCopyWithImpl<_ProjectSmartTilePattern>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSmartTilePatternToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSmartTilePattern&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.anchorX, anchorX) || other.anchorX == anchorX)&&(identical(other.anchorY, anchorY) || other.anchorY == anchorY)&&(identical(other.repeatMode, repeatMode) || other.repeatMode == repeatMode)&&const DeepCollectionEquality().equals(other._cells, _cells)&&(identical(other.drawOrder, drawOrder) || other.drawOrder == drawOrder)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,usage,width,height,anchorX,anchorY,repeatMode,const DeepCollectionEquality().hash(_cells),drawOrder,const DeepCollectionEquality().hash(_tags),sortOrder);

@override
String toString() {
  return 'ProjectSmartTilePattern(id: $id, name: $name, categoryId: $categoryId, usage: $usage, width: $width, height: $height, anchorX: $anchorX, anchorY: $anchorY, repeatMode: $repeatMode, cells: $cells, drawOrder: $drawOrder, tags: $tags, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectSmartTilePatternCopyWith<$Res> implements $ProjectSmartTilePatternCopyWith<$Res> {
  factory _$ProjectSmartTilePatternCopyWith(_ProjectSmartTilePattern value, $Res Function(_ProjectSmartTilePattern) _then) = __$ProjectSmartTilePatternCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String categoryId, SmartTileUsage usage, int width, int height, int anchorX, int anchorY, SmartTilePatternRepeatMode repeatMode, List<SmartTilePatternCell> cells, int drawOrder, List<String> tags, int sortOrder
});




}
/// @nodoc
class __$ProjectSmartTilePatternCopyWithImpl<$Res>
    implements _$ProjectSmartTilePatternCopyWith<$Res> {
  __$ProjectSmartTilePatternCopyWithImpl(this._self, this._then);

  final _ProjectSmartTilePattern _self;
  final $Res Function(_ProjectSmartTilePattern) _then;

/// Create a copy of ProjectSmartTilePattern
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? usage = null,Object? width = null,Object? height = null,Object? anchorX = null,Object? anchorY = null,Object? repeatMode = null,Object? cells = null,Object? drawOrder = null,Object? tags = null,Object? sortOrder = null,}) {
  return _then(_ProjectSmartTilePattern(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as SmartTileUsage,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,anchorX: null == anchorX ? _self.anchorX : anchorX // ignore: cast_nullable_to_non_nullable
as int,anchorY: null == anchorY ? _self.anchorY : anchorY // ignore: cast_nullable_to_non_nullable
as int,repeatMode: null == repeatMode ? _self.repeatMode : repeatMode // ignore: cast_nullable_to_non_nullable
as SmartTilePatternRepeatMode,cells: null == cells ? _self._cells : cells // ignore: cast_nullable_to_non_nullable
as List<SmartTilePatternCell>,drawOrder: null == drawOrder ? _self.drawOrder : drawOrder // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SmartTilePatternStroke {

 String get id; String get patternId; List<GridPos> get cells; int get phaseX; int get phaseY;
/// Create a copy of SmartTilePatternStroke
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTilePatternStrokeCopyWith<SmartTilePatternStroke> get copyWith => _$SmartTilePatternStrokeCopyWithImpl<SmartTilePatternStroke>(this as SmartTilePatternStroke, _$identity);

  /// Serializes this SmartTilePatternStroke to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTilePatternStroke&&(identical(other.id, id) || other.id == id)&&(identical(other.patternId, patternId) || other.patternId == patternId)&&const DeepCollectionEquality().equals(other.cells, cells)&&(identical(other.phaseX, phaseX) || other.phaseX == phaseX)&&(identical(other.phaseY, phaseY) || other.phaseY == phaseY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patternId,const DeepCollectionEquality().hash(cells),phaseX,phaseY);

@override
String toString() {
  return 'SmartTilePatternStroke(id: $id, patternId: $patternId, cells: $cells, phaseX: $phaseX, phaseY: $phaseY)';
}


}

/// @nodoc
abstract mixin class $SmartTilePatternStrokeCopyWith<$Res>  {
  factory $SmartTilePatternStrokeCopyWith(SmartTilePatternStroke value, $Res Function(SmartTilePatternStroke) _then) = _$SmartTilePatternStrokeCopyWithImpl;
@useResult
$Res call({
 String id, String patternId, List<GridPos> cells, int phaseX, int phaseY
});




}
/// @nodoc
class _$SmartTilePatternStrokeCopyWithImpl<$Res>
    implements $SmartTilePatternStrokeCopyWith<$Res> {
  _$SmartTilePatternStrokeCopyWithImpl(this._self, this._then);

  final SmartTilePatternStroke _self;
  final $Res Function(SmartTilePatternStroke) _then;

/// Create a copy of SmartTilePatternStroke
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patternId = null,Object? cells = null,Object? phaseX = null,Object? phaseY = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patternId: null == patternId ? _self.patternId : patternId // ignore: cast_nullable_to_non_nullable
as String,cells: null == cells ? _self.cells : cells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,phaseX: null == phaseX ? _self.phaseX : phaseX // ignore: cast_nullable_to_non_nullable
as int,phaseY: null == phaseY ? _self.phaseY : phaseY // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTilePatternStroke].
extension SmartTilePatternStrokePatterns on SmartTilePatternStroke {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTilePatternStroke value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTilePatternStroke() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTilePatternStroke value)  $default,){
final _that = this;
switch (_that) {
case _SmartTilePatternStroke():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTilePatternStroke value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTilePatternStroke() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String patternId,  List<GridPos> cells,  int phaseX,  int phaseY)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTilePatternStroke() when $default != null:
return $default(_that.id,_that.patternId,_that.cells,_that.phaseX,_that.phaseY);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String patternId,  List<GridPos> cells,  int phaseX,  int phaseY)  $default,) {final _that = this;
switch (_that) {
case _SmartTilePatternStroke():
return $default(_that.id,_that.patternId,_that.cells,_that.phaseX,_that.phaseY);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String patternId,  List<GridPos> cells,  int phaseX,  int phaseY)?  $default,) {final _that = this;
switch (_that) {
case _SmartTilePatternStroke() when $default != null:
return $default(_that.id,_that.patternId,_that.cells,_that.phaseX,_that.phaseY);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTilePatternStroke implements SmartTilePatternStroke {
  const _SmartTilePatternStroke({required this.id, required this.patternId, required final  List<GridPos> cells, this.phaseX = 0, this.phaseY = 0}): assert(id != "", 'id must not be blank'),assert(patternId != "", 'patternId must not be blank'),_cells = cells;
  factory _SmartTilePatternStroke.fromJson(Map<String, dynamic> json) => _$SmartTilePatternStrokeFromJson(json);

@override final  String id;
@override final  String patternId;
 final  List<GridPos> _cells;
@override List<GridPos> get cells {
  if (_cells is EqualUnmodifiableListView) return _cells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cells);
}

@override@JsonKey() final  int phaseX;
@override@JsonKey() final  int phaseY;

/// Create a copy of SmartTilePatternStroke
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTilePatternStrokeCopyWith<_SmartTilePatternStroke> get copyWith => __$SmartTilePatternStrokeCopyWithImpl<_SmartTilePatternStroke>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTilePatternStrokeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTilePatternStroke&&(identical(other.id, id) || other.id == id)&&(identical(other.patternId, patternId) || other.patternId == patternId)&&const DeepCollectionEquality().equals(other._cells, _cells)&&(identical(other.phaseX, phaseX) || other.phaseX == phaseX)&&(identical(other.phaseY, phaseY) || other.phaseY == phaseY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patternId,const DeepCollectionEquality().hash(_cells),phaseX,phaseY);

@override
String toString() {
  return 'SmartTilePatternStroke(id: $id, patternId: $patternId, cells: $cells, phaseX: $phaseX, phaseY: $phaseY)';
}


}

/// @nodoc
abstract mixin class _$SmartTilePatternStrokeCopyWith<$Res> implements $SmartTilePatternStrokeCopyWith<$Res> {
  factory _$SmartTilePatternStrokeCopyWith(_SmartTilePatternStroke value, $Res Function(_SmartTilePatternStroke) _then) = __$SmartTilePatternStrokeCopyWithImpl;
@override @useResult
$Res call({
 String id, String patternId, List<GridPos> cells, int phaseX, int phaseY
});




}
/// @nodoc
class __$SmartTilePatternStrokeCopyWithImpl<$Res>
    implements _$SmartTilePatternStrokeCopyWith<$Res> {
  __$SmartTilePatternStrokeCopyWithImpl(this._self, this._then);

  final _SmartTilePatternStroke _self;
  final $Res Function(_SmartTilePatternStroke) _then;

/// Create a copy of SmartTilePatternStroke
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patternId = null,Object? cells = null,Object? phaseX = null,Object? phaseY = null,}) {
  return _then(_SmartTilePatternStroke(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patternId: null == patternId ? _self.patternId : patternId // ignore: cast_nullable_to_non_nullable
as String,cells: null == cells ? _self._cells : cells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,phaseX: null == phaseX ? _self.phaseX : phaseX // ignore: cast_nullable_to_non_nullable
as int,phaseY: null == phaseY ? _self.phaseY : phaseY // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SmartTileCandidate {

 String get id; String get label; int get weight; List<SmartTileVisualPart> get parts;
/// Create a copy of SmartTileCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileCandidateCopyWith<SmartTileCandidate> get copyWith => _$SmartTileCandidateCopyWithImpl<SmartTileCandidate>(this as SmartTileCandidate, _$identity);

  /// Serializes this SmartTileCandidate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileCandidate&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.weight, weight) || other.weight == weight)&&const DeepCollectionEquality().equals(other.parts, parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,weight,const DeepCollectionEquality().hash(parts));

@override
String toString() {
  return 'SmartTileCandidate(id: $id, label: $label, weight: $weight, parts: $parts)';
}


}

/// @nodoc
abstract mixin class $SmartTileCandidateCopyWith<$Res>  {
  factory $SmartTileCandidateCopyWith(SmartTileCandidate value, $Res Function(SmartTileCandidate) _then) = _$SmartTileCandidateCopyWithImpl;
@useResult
$Res call({
 String id, String label, int weight, List<SmartTileVisualPart> parts
});




}
/// @nodoc
class _$SmartTileCandidateCopyWithImpl<$Res>
    implements $SmartTileCandidateCopyWith<$Res> {
  _$SmartTileCandidateCopyWithImpl(this._self, this._then);

  final SmartTileCandidate _self;
  final $Res Function(SmartTileCandidate) _then;

/// Create a copy of SmartTileCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? weight = null,Object? parts = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<SmartTileVisualPart>,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileCandidate].
extension SmartTileCandidatePatterns on SmartTileCandidate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileCandidate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileCandidate value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileCandidate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileCandidate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  int weight,  List<SmartTileVisualPart> parts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileCandidate() when $default != null:
return $default(_that.id,_that.label,_that.weight,_that.parts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  int weight,  List<SmartTileVisualPart> parts)  $default,) {final _that = this;
switch (_that) {
case _SmartTileCandidate():
return $default(_that.id,_that.label,_that.weight,_that.parts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  int weight,  List<SmartTileVisualPart> parts)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileCandidate() when $default != null:
return $default(_that.id,_that.label,_that.weight,_that.parts);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTileCandidate implements SmartTileCandidate {
  const _SmartTileCandidate({required this.id, this.label = '', this.weight = 1, final  List<SmartTileVisualPart> parts = const <SmartTileVisualPart>[]}): assert(id != "", 'id must not be blank'),_parts = parts;
  factory _SmartTileCandidate.fromJson(Map<String, dynamic> json) => _$SmartTileCandidateFromJson(json);

@override final  String id;
@override@JsonKey() final  String label;
@override@JsonKey() final  int weight;
 final  List<SmartTileVisualPart> _parts;
@override@JsonKey() List<SmartTileVisualPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}


/// Create a copy of SmartTileCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileCandidateCopyWith<_SmartTileCandidate> get copyWith => __$SmartTileCandidateCopyWithImpl<_SmartTileCandidate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileCandidateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileCandidate&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.weight, weight) || other.weight == weight)&&const DeepCollectionEquality().equals(other._parts, _parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,weight,const DeepCollectionEquality().hash(_parts));

@override
String toString() {
  return 'SmartTileCandidate(id: $id, label: $label, weight: $weight, parts: $parts)';
}


}

/// @nodoc
abstract mixin class _$SmartTileCandidateCopyWith<$Res> implements $SmartTileCandidateCopyWith<$Res> {
  factory _$SmartTileCandidateCopyWith(_SmartTileCandidate value, $Res Function(_SmartTileCandidate) _then) = __$SmartTileCandidateCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, int weight, List<SmartTileVisualPart> parts
});




}
/// @nodoc
class __$SmartTileCandidateCopyWithImpl<$Res>
    implements _$SmartTileCandidateCopyWith<$Res> {
  __$SmartTileCandidateCopyWithImpl(this._self, this._then);

  final _SmartTileCandidate _self;
  final $Res Function(_SmartTileCandidate) _then;

/// Create a copy of SmartTileCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? weight = null,Object? parts = null,}) {
  return _then(_SmartTileCandidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<SmartTileVisualPart>,
  ));
}


}


/// @nodoc
mixin _$SmartTileRule {

 String get id; SmartTileSlotMatch get centerMatch; SmartTileSignature get signature; List<SmartTileCandidate> get candidates;
/// Create a copy of SmartTileRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileRuleCopyWith<SmartTileRule> get copyWith => _$SmartTileRuleCopyWithImpl<SmartTileRule>(this as SmartTileRule, _$identity);

  /// Serializes this SmartTileRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileRule&&(identical(other.id, id) || other.id == id)&&(identical(other.centerMatch, centerMatch) || other.centerMatch == centerMatch)&&(identical(other.signature, signature) || other.signature == signature)&&const DeepCollectionEquality().equals(other.candidates, candidates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,centerMatch,signature,const DeepCollectionEquality().hash(candidates));

@override
String toString() {
  return 'SmartTileRule(id: $id, centerMatch: $centerMatch, signature: $signature, candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class $SmartTileRuleCopyWith<$Res>  {
  factory $SmartTileRuleCopyWith(SmartTileRule value, $Res Function(SmartTileRule) _then) = _$SmartTileRuleCopyWithImpl;
@useResult
$Res call({
 String id, SmartTileSlotMatch centerMatch, SmartTileSignature signature, List<SmartTileCandidate> candidates
});


$SmartTileSignatureCopyWith<$Res> get signature;

}
/// @nodoc
class _$SmartTileRuleCopyWithImpl<$Res>
    implements $SmartTileRuleCopyWith<$Res> {
  _$SmartTileRuleCopyWithImpl(this._self, this._then);

  final SmartTileRule _self;
  final $Res Function(SmartTileRule) _then;

/// Create a copy of SmartTileRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? centerMatch = null,Object? signature = null,Object? candidates = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,centerMatch: null == centerMatch ? _self.centerMatch : centerMatch // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as SmartTileSignature,candidates: null == candidates ? _self.candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<SmartTileCandidate>,
  ));
}
/// Create a copy of SmartTileRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileSignatureCopyWith<$Res> get signature {

  return $SmartTileSignatureCopyWith<$Res>(_self.signature, (value) {
    return _then(_self.copyWith(signature: value));
  });
}
}


/// Adds pattern-matching-related methods to [SmartTileRule].
extension SmartTileRulePatterns on SmartTileRule {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileRule() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileRule value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileRule():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileRule value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileRule() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SmartTileSlotMatch centerMatch,  SmartTileSignature signature,  List<SmartTileCandidate> candidates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileRule() when $default != null:
return $default(_that.id,_that.centerMatch,_that.signature,_that.candidates);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SmartTileSlotMatch centerMatch,  SmartTileSignature signature,  List<SmartTileCandidate> candidates)  $default,) {final _that = this;
switch (_that) {
case _SmartTileRule():
return $default(_that.id,_that.centerMatch,_that.signature,_that.candidates);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SmartTileSlotMatch centerMatch,  SmartTileSignature signature,  List<SmartTileCandidate> candidates)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileRule() when $default != null:
return $default(_that.id,_that.centerMatch,_that.signature,_that.candidates);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTileRule implements SmartTileRule {
  const _SmartTileRule({required this.id, required this.centerMatch, this.signature = const SmartTileSignature(), final  List<SmartTileCandidate> candidates = const <SmartTileCandidate>[]}): assert(id != "", 'id must not be blank'),_candidates = candidates;
  factory _SmartTileRule.fromJson(Map<String, dynamic> json) => _$SmartTileRuleFromJson(json);

@override final  String id;
@override final  SmartTileSlotMatch centerMatch;
@override@JsonKey() final  SmartTileSignature signature;
 final  List<SmartTileCandidate> _candidates;
@override@JsonKey() List<SmartTileCandidate> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}


/// Create a copy of SmartTileRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileRuleCopyWith<_SmartTileRule> get copyWith => __$SmartTileRuleCopyWithImpl<_SmartTileRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileRule&&(identical(other.id, id) || other.id == id)&&(identical(other.centerMatch, centerMatch) || other.centerMatch == centerMatch)&&(identical(other.signature, signature) || other.signature == signature)&&const DeepCollectionEquality().equals(other._candidates, _candidates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,centerMatch,signature,const DeepCollectionEquality().hash(_candidates));

@override
String toString() {
  return 'SmartTileRule(id: $id, centerMatch: $centerMatch, signature: $signature, candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class _$SmartTileRuleCopyWith<$Res> implements $SmartTileRuleCopyWith<$Res> {
  factory _$SmartTileRuleCopyWith(_SmartTileRule value, $Res Function(_SmartTileRule) _then) = __$SmartTileRuleCopyWithImpl;
@override @useResult
$Res call({
 String id, SmartTileSlotMatch centerMatch, SmartTileSignature signature, List<SmartTileCandidate> candidates
});


@override $SmartTileSignatureCopyWith<$Res> get signature;

}
/// @nodoc
class __$SmartTileRuleCopyWithImpl<$Res>
    implements _$SmartTileRuleCopyWith<$Res> {
  __$SmartTileRuleCopyWithImpl(this._self, this._then);

  final _SmartTileRule _self;
  final $Res Function(_SmartTileRule) _then;

/// Create a copy of SmartTileRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? centerMatch = null,Object? signature = null,Object? candidates = null,}) {
  return _then(_SmartTileRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,centerMatch: null == centerMatch ? _self.centerMatch : centerMatch // ignore: cast_nullable_to_non_nullable
as SmartTileSlotMatch,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as SmartTileSignature,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<SmartTileCandidate>,
  ));
}

/// Create a copy of SmartTileRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileSignatureCopyWith<$Res> get signature {

  return $SmartTileSignatureCopyWith<$Res>(_self.signature, (value) {
    return _then(_self.copyWith(signature: value));
  });
}
}


/// @nodoc
mixin _$ProjectSmartTileCategory {

 String get id; String get name; int get sortOrder;
/// Create a copy of ProjectSmartTileCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSmartTileCategoryCopyWith<ProjectSmartTileCategory> get copyWith => _$ProjectSmartTileCategoryCopyWithImpl<ProjectSmartTileCategory>(this as ProjectSmartTileCategory, _$identity);

  /// Serializes this ProjectSmartTileCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSmartTileCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sortOrder);

@override
String toString() {
  return 'ProjectSmartTileCategory(id: $id, name: $name, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectSmartTileCategoryCopyWith<$Res>  {
  factory $ProjectSmartTileCategoryCopyWith(ProjectSmartTileCategory value, $Res Function(ProjectSmartTileCategory) _then) = _$ProjectSmartTileCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, int sortOrder
});




}
/// @nodoc
class _$ProjectSmartTileCategoryCopyWithImpl<$Res>
    implements $ProjectSmartTileCategoryCopyWith<$Res> {
  _$ProjectSmartTileCategoryCopyWithImpl(this._self, this._then);

  final ProjectSmartTileCategory _self;
  final $Res Function(ProjectSmartTileCategory) _then;

/// Create a copy of ProjectSmartTileCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSmartTileCategory].
extension ProjectSmartTileCategoryPatterns on ProjectSmartTileCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSmartTileCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSmartTileCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSmartTileCategory value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileCategory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSmartTileCategory value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSmartTileCategory() when $default != null:
return $default(_that.id,_that.name,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileCategory():
return $default(_that.id,_that.name,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileCategory() when $default != null:
return $default(_that.id,_that.name,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectSmartTileCategory implements ProjectSmartTileCategory {
  const _ProjectSmartTileCategory({required this.id, required this.name, this.sortOrder = 0}): assert(id != "", 'id must not be blank'),assert(name != "", 'name must not be blank');
  factory _ProjectSmartTileCategory.fromJson(Map<String, dynamic> json) => _$ProjectSmartTileCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectSmartTileCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSmartTileCategoryCopyWith<_ProjectSmartTileCategory> get copyWith => __$ProjectSmartTileCategoryCopyWithImpl<_ProjectSmartTileCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSmartTileCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSmartTileCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sortOrder);

@override
String toString() {
  return 'ProjectSmartTileCategory(id: $id, name: $name, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectSmartTileCategoryCopyWith<$Res> implements $ProjectSmartTileCategoryCopyWith<$Res> {
  factory _$ProjectSmartTileCategoryCopyWith(_ProjectSmartTileCategory value, $Res Function(_ProjectSmartTileCategory) _then) = __$ProjectSmartTileCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int sortOrder
});




}
/// @nodoc
class __$ProjectSmartTileCategoryCopyWithImpl<$Res>
    implements _$ProjectSmartTileCategoryCopyWith<$Res> {
  __$ProjectSmartTileCategoryCopyWithImpl(this._self, this._then);

  final _ProjectSmartTileCategory _self;
  final $Res Function(_ProjectSmartTileCategory) _then;

/// Create a copy of ProjectSmartTileCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sortOrder = null,}) {
  return _then(_ProjectSmartTileCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectSmartTileAtlas {

 String get id; String get name; String get tilesetId; int get cellWidth; int get cellHeight; int get originX; int get originY; int get marginX; int get marginY; int get spacingX; int get spacingY; int get columns; int get rows; int get pixelOffsetX; int get pixelOffsetY;
/// Create a copy of ProjectSmartTileAtlas
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSmartTileAtlasCopyWith<ProjectSmartTileAtlas> get copyWith => _$ProjectSmartTileAtlasCopyWithImpl<ProjectSmartTileAtlas>(this as ProjectSmartTileAtlas, _$identity);

  /// Serializes this ProjectSmartTileAtlas to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSmartTileAtlas&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.cellWidth, cellWidth) || other.cellWidth == cellWidth)&&(identical(other.cellHeight, cellHeight) || other.cellHeight == cellHeight)&&(identical(other.originX, originX) || other.originX == originX)&&(identical(other.originY, originY) || other.originY == originY)&&(identical(other.marginX, marginX) || other.marginX == marginX)&&(identical(other.marginY, marginY) || other.marginY == marginY)&&(identical(other.spacingX, spacingX) || other.spacingX == spacingX)&&(identical(other.spacingY, spacingY) || other.spacingY == spacingY)&&(identical(other.columns, columns) || other.columns == columns)&&(identical(other.rows, rows) || other.rows == rows)&&(identical(other.pixelOffsetX, pixelOffsetX) || other.pixelOffsetX == pixelOffsetX)&&(identical(other.pixelOffsetY, pixelOffsetY) || other.pixelOffsetY == pixelOffsetY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tilesetId,cellWidth,cellHeight,originX,originY,marginX,marginY,spacingX,spacingY,columns,rows,pixelOffsetX,pixelOffsetY);

@override
String toString() {
  return 'ProjectSmartTileAtlas(id: $id, name: $name, tilesetId: $tilesetId, cellWidth: $cellWidth, cellHeight: $cellHeight, originX: $originX, originY: $originY, marginX: $marginX, marginY: $marginY, spacingX: $spacingX, spacingY: $spacingY, columns: $columns, rows: $rows, pixelOffsetX: $pixelOffsetX, pixelOffsetY: $pixelOffsetY)';
}


}

/// @nodoc
abstract mixin class $ProjectSmartTileAtlasCopyWith<$Res>  {
  factory $ProjectSmartTileAtlasCopyWith(ProjectSmartTileAtlas value, $Res Function(ProjectSmartTileAtlas) _then) = _$ProjectSmartTileAtlasCopyWithImpl;
@useResult
$Res call({
 String id, String name, String tilesetId, int cellWidth, int cellHeight, int originX, int originY, int marginX, int marginY, int spacingX, int spacingY, int columns, int rows, int pixelOffsetX, int pixelOffsetY
});




}
/// @nodoc
class _$ProjectSmartTileAtlasCopyWithImpl<$Res>
    implements $ProjectSmartTileAtlasCopyWith<$Res> {
  _$ProjectSmartTileAtlasCopyWithImpl(this._self, this._then);

  final ProjectSmartTileAtlas _self;
  final $Res Function(ProjectSmartTileAtlas) _then;

/// Create a copy of ProjectSmartTileAtlas
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tilesetId = null,Object? cellWidth = null,Object? cellHeight = null,Object? originX = null,Object? originY = null,Object? marginX = null,Object? marginY = null,Object? spacingX = null,Object? spacingY = null,Object? columns = null,Object? rows = null,Object? pixelOffsetX = null,Object? pixelOffsetY = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,cellWidth: null == cellWidth ? _self.cellWidth : cellWidth // ignore: cast_nullable_to_non_nullable
as int,cellHeight: null == cellHeight ? _self.cellHeight : cellHeight // ignore: cast_nullable_to_non_nullable
as int,originX: null == originX ? _self.originX : originX // ignore: cast_nullable_to_non_nullable
as int,originY: null == originY ? _self.originY : originY // ignore: cast_nullable_to_non_nullable
as int,marginX: null == marginX ? _self.marginX : marginX // ignore: cast_nullable_to_non_nullable
as int,marginY: null == marginY ? _self.marginY : marginY // ignore: cast_nullable_to_non_nullable
as int,spacingX: null == spacingX ? _self.spacingX : spacingX // ignore: cast_nullable_to_non_nullable
as int,spacingY: null == spacingY ? _self.spacingY : spacingY // ignore: cast_nullable_to_non_nullable
as int,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as int,pixelOffsetX: null == pixelOffsetX ? _self.pixelOffsetX : pixelOffsetX // ignore: cast_nullable_to_non_nullable
as int,pixelOffsetY: null == pixelOffsetY ? _self.pixelOffsetY : pixelOffsetY // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSmartTileAtlas].
extension ProjectSmartTileAtlasPatterns on ProjectSmartTileAtlas {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSmartTileAtlas value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSmartTileAtlas() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSmartTileAtlas value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileAtlas():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSmartTileAtlas value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileAtlas() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String tilesetId,  int cellWidth,  int cellHeight,  int originX,  int originY,  int marginX,  int marginY,  int spacingX,  int spacingY,  int columns,  int rows,  int pixelOffsetX,  int pixelOffsetY)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSmartTileAtlas() when $default != null:
return $default(_that.id,_that.name,_that.tilesetId,_that.cellWidth,_that.cellHeight,_that.originX,_that.originY,_that.marginX,_that.marginY,_that.spacingX,_that.spacingY,_that.columns,_that.rows,_that.pixelOffsetX,_that.pixelOffsetY);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String tilesetId,  int cellWidth,  int cellHeight,  int originX,  int originY,  int marginX,  int marginY,  int spacingX,  int spacingY,  int columns,  int rows,  int pixelOffsetX,  int pixelOffsetY)  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileAtlas():
return $default(_that.id,_that.name,_that.tilesetId,_that.cellWidth,_that.cellHeight,_that.originX,_that.originY,_that.marginX,_that.marginY,_that.spacingX,_that.spacingY,_that.columns,_that.rows,_that.pixelOffsetX,_that.pixelOffsetY);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String tilesetId,  int cellWidth,  int cellHeight,  int originX,  int originY,  int marginX,  int marginY,  int spacingX,  int spacingY,  int columns,  int rows,  int pixelOffsetX,  int pixelOffsetY)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileAtlas() when $default != null:
return $default(_that.id,_that.name,_that.tilesetId,_that.cellWidth,_that.cellHeight,_that.originX,_that.originY,_that.marginX,_that.marginY,_that.spacingX,_that.spacingY,_that.columns,_that.rows,_that.pixelOffsetX,_that.pixelOffsetY);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectSmartTileAtlas extends ProjectSmartTileAtlas {
  const _ProjectSmartTileAtlas({required this.id, required this.name, required this.tilesetId, this.cellWidth = 32, this.cellHeight = 32, this.originX = 0, this.originY = 0, this.marginX = 0, this.marginY = 0, this.spacingX = 0, this.spacingY = 0, required this.columns, required this.rows, this.pixelOffsetX = 0, this.pixelOffsetY = 0}): assert(id != "", 'id must not be blank'),assert(name != "", 'name must not be blank'),assert(tilesetId != "", 'tilesetId must not be blank'),assert(cellWidth > 0, 'cellWidth must be positive'),assert(cellHeight > 0, 'cellHeight must be positive'),assert(originX >= 0, 'originX must not be negative'),assert(originY >= 0, 'originY must not be negative'),assert(marginX >= 0, 'marginX must not be negative'),assert(marginY >= 0, 'marginY must not be negative'),assert(spacingX >= 0, 'spacingX must not be negative'),assert(spacingY >= 0, 'spacingY must not be negative'),assert(columns > 0, 'columns must be positive'),assert(rows > 0, 'rows must be positive'),super._();
  factory _ProjectSmartTileAtlas.fromJson(Map<String, dynamic> json) => _$ProjectSmartTileAtlasFromJson(json);

@override final  String id;
@override final  String name;
@override final  String tilesetId;
@override@JsonKey() final  int cellWidth;
@override@JsonKey() final  int cellHeight;
@override@JsonKey() final  int originX;
@override@JsonKey() final  int originY;
@override@JsonKey() final  int marginX;
@override@JsonKey() final  int marginY;
@override@JsonKey() final  int spacingX;
@override@JsonKey() final  int spacingY;
@override final  int columns;
@override final  int rows;
@override@JsonKey() final  int pixelOffsetX;
@override@JsonKey() final  int pixelOffsetY;

/// Create a copy of ProjectSmartTileAtlas
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSmartTileAtlasCopyWith<_ProjectSmartTileAtlas> get copyWith => __$ProjectSmartTileAtlasCopyWithImpl<_ProjectSmartTileAtlas>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSmartTileAtlasToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSmartTileAtlas&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.cellWidth, cellWidth) || other.cellWidth == cellWidth)&&(identical(other.cellHeight, cellHeight) || other.cellHeight == cellHeight)&&(identical(other.originX, originX) || other.originX == originX)&&(identical(other.originY, originY) || other.originY == originY)&&(identical(other.marginX, marginX) || other.marginX == marginX)&&(identical(other.marginY, marginY) || other.marginY == marginY)&&(identical(other.spacingX, spacingX) || other.spacingX == spacingX)&&(identical(other.spacingY, spacingY) || other.spacingY == spacingY)&&(identical(other.columns, columns) || other.columns == columns)&&(identical(other.rows, rows) || other.rows == rows)&&(identical(other.pixelOffsetX, pixelOffsetX) || other.pixelOffsetX == pixelOffsetX)&&(identical(other.pixelOffsetY, pixelOffsetY) || other.pixelOffsetY == pixelOffsetY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tilesetId,cellWidth,cellHeight,originX,originY,marginX,marginY,spacingX,spacingY,columns,rows,pixelOffsetX,pixelOffsetY);

@override
String toString() {
  return 'ProjectSmartTileAtlas(id: $id, name: $name, tilesetId: $tilesetId, cellWidth: $cellWidth, cellHeight: $cellHeight, originX: $originX, originY: $originY, marginX: $marginX, marginY: $marginY, spacingX: $spacingX, spacingY: $spacingY, columns: $columns, rows: $rows, pixelOffsetX: $pixelOffsetX, pixelOffsetY: $pixelOffsetY)';
}


}

/// @nodoc
abstract mixin class _$ProjectSmartTileAtlasCopyWith<$Res> implements $ProjectSmartTileAtlasCopyWith<$Res> {
  factory _$ProjectSmartTileAtlasCopyWith(_ProjectSmartTileAtlas value, $Res Function(_ProjectSmartTileAtlas) _then) = __$ProjectSmartTileAtlasCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String tilesetId, int cellWidth, int cellHeight, int originX, int originY, int marginX, int marginY, int spacingX, int spacingY, int columns, int rows, int pixelOffsetX, int pixelOffsetY
});




}
/// @nodoc
class __$ProjectSmartTileAtlasCopyWithImpl<$Res>
    implements _$ProjectSmartTileAtlasCopyWith<$Res> {
  __$ProjectSmartTileAtlasCopyWithImpl(this._self, this._then);

  final _ProjectSmartTileAtlas _self;
  final $Res Function(_ProjectSmartTileAtlas) _then;

/// Create a copy of ProjectSmartTileAtlas
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tilesetId = null,Object? cellWidth = null,Object? cellHeight = null,Object? originX = null,Object? originY = null,Object? marginX = null,Object? marginY = null,Object? spacingX = null,Object? spacingY = null,Object? columns = null,Object? rows = null,Object? pixelOffsetX = null,Object? pixelOffsetY = null,}) {
  return _then(_ProjectSmartTileAtlas(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,cellWidth: null == cellWidth ? _self.cellWidth : cellWidth // ignore: cast_nullable_to_non_nullable
as int,cellHeight: null == cellHeight ? _self.cellHeight : cellHeight // ignore: cast_nullable_to_non_nullable
as int,originX: null == originX ? _self.originX : originX // ignore: cast_nullable_to_non_nullable
as int,originY: null == originY ? _self.originY : originY // ignore: cast_nullable_to_non_nullable
as int,marginX: null == marginX ? _self.marginX : marginX // ignore: cast_nullable_to_non_nullable
as int,marginY: null == marginY ? _self.marginY : marginY // ignore: cast_nullable_to_non_nullable
as int,spacingX: null == spacingX ? _self.spacingX : spacingX // ignore: cast_nullable_to_non_nullable
as int,spacingY: null == spacingY ? _self.spacingY : spacingY // ignore: cast_nullable_to_non_nullable
as int,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as int,pixelOffsetX: null == pixelOffsetX ? _self.pixelOffsetX : pixelOffsetX // ignore: cast_nullable_to_non_nullable
as int,pixelOffsetY: null == pixelOffsetY ? _self.pixelOffsetY : pixelOffsetY // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectSmartTileMaterial {

 String get id; String get name; String get connectionGroupId; String get categoryId; TerrainType? get terrainType; PathSurfaceKind? get pathSurfaceKind; bool get isEmpty; int get sortOrder; int? get editorColorArgb;
/// Create a copy of ProjectSmartTileMaterial
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSmartTileMaterialCopyWith<ProjectSmartTileMaterial> get copyWith => _$ProjectSmartTileMaterialCopyWithImpl<ProjectSmartTileMaterial>(this as ProjectSmartTileMaterial, _$identity);

  /// Serializes this ProjectSmartTileMaterial to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSmartTileMaterial&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.connectionGroupId, connectionGroupId) || other.connectionGroupId == connectionGroupId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.terrainType, terrainType) || other.terrainType == terrainType)&&(identical(other.pathSurfaceKind, pathSurfaceKind) || other.pathSurfaceKind == pathSurfaceKind)&&(identical(other.isEmpty, isEmpty) || other.isEmpty == isEmpty)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.editorColorArgb, editorColorArgb) || other.editorColorArgb == editorColorArgb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,connectionGroupId,categoryId,terrainType,pathSurfaceKind,isEmpty,sortOrder,editorColorArgb);

@override
String toString() {
  return 'ProjectSmartTileMaterial(id: $id, name: $name, connectionGroupId: $connectionGroupId, categoryId: $categoryId, terrainType: $terrainType, pathSurfaceKind: $pathSurfaceKind, isEmpty: $isEmpty, sortOrder: $sortOrder, editorColorArgb: $editorColorArgb)';
}


}

/// @nodoc
abstract mixin class $ProjectSmartTileMaterialCopyWith<$Res>  {
  factory $ProjectSmartTileMaterialCopyWith(ProjectSmartTileMaterial value, $Res Function(ProjectSmartTileMaterial) _then) = _$ProjectSmartTileMaterialCopyWithImpl;
@useResult
$Res call({
 String id, String name, String connectionGroupId, String categoryId, TerrainType? terrainType, PathSurfaceKind? pathSurfaceKind, bool isEmpty, int sortOrder, int? editorColorArgb
});




}
/// @nodoc
class _$ProjectSmartTileMaterialCopyWithImpl<$Res>
    implements $ProjectSmartTileMaterialCopyWith<$Res> {
  _$ProjectSmartTileMaterialCopyWithImpl(this._self, this._then);

  final ProjectSmartTileMaterial _self;
  final $Res Function(ProjectSmartTileMaterial) _then;

/// Create a copy of ProjectSmartTileMaterial
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? connectionGroupId = null,Object? categoryId = null,Object? terrainType = freezed,Object? pathSurfaceKind = freezed,Object? isEmpty = null,Object? sortOrder = null,Object? editorColorArgb = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,connectionGroupId: null == connectionGroupId ? _self.connectionGroupId : connectionGroupId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,terrainType: freezed == terrainType ? _self.terrainType : terrainType // ignore: cast_nullable_to_non_nullable
as TerrainType?,pathSurfaceKind: freezed == pathSurfaceKind ? _self.pathSurfaceKind : pathSurfaceKind // ignore: cast_nullable_to_non_nullable
as PathSurfaceKind?,isEmpty: null == isEmpty ? _self.isEmpty : isEmpty // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,editorColorArgb: freezed == editorColorArgb ? _self.editorColorArgb : editorColorArgb // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSmartTileMaterial].
extension ProjectSmartTileMaterialPatterns on ProjectSmartTileMaterial {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSmartTileMaterial value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSmartTileMaterial() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSmartTileMaterial value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileMaterial():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSmartTileMaterial value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileMaterial() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String connectionGroupId,  String categoryId,  TerrainType? terrainType,  PathSurfaceKind? pathSurfaceKind,  bool isEmpty,  int sortOrder,  int? editorColorArgb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSmartTileMaterial() when $default != null:
return $default(_that.id,_that.name,_that.connectionGroupId,_that.categoryId,_that.terrainType,_that.pathSurfaceKind,_that.isEmpty,_that.sortOrder,_that.editorColorArgb);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String connectionGroupId,  String categoryId,  TerrainType? terrainType,  PathSurfaceKind? pathSurfaceKind,  bool isEmpty,  int sortOrder,  int? editorColorArgb)  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileMaterial():
return $default(_that.id,_that.name,_that.connectionGroupId,_that.categoryId,_that.terrainType,_that.pathSurfaceKind,_that.isEmpty,_that.sortOrder,_that.editorColorArgb);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String connectionGroupId,  String categoryId,  TerrainType? terrainType,  PathSurfaceKind? pathSurfaceKind,  bool isEmpty,  int sortOrder,  int? editorColorArgb)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileMaterial() when $default != null:
return $default(_that.id,_that.name,_that.connectionGroupId,_that.categoryId,_that.terrainType,_that.pathSurfaceKind,_that.isEmpty,_that.sortOrder,_that.editorColorArgb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectSmartTileMaterial implements ProjectSmartTileMaterial {
  const _ProjectSmartTileMaterial({required this.id, required this.name, required this.connectionGroupId, this.categoryId = '', this.terrainType, this.pathSurfaceKind, this.isEmpty = false, this.sortOrder = 0, this.editorColorArgb}): assert(id != "", 'id must not be blank'),assert(name != "", 'name must not be blank'),assert(connectionGroupId != "", 'connectionGroupId must not be blank');
  factory _ProjectSmartTileMaterial.fromJson(Map<String, dynamic> json) => _$ProjectSmartTileMaterialFromJson(json);

@override final  String id;
@override final  String name;
@override final  String connectionGroupId;
@override@JsonKey() final  String categoryId;
@override final  TerrainType? terrainType;
@override final  PathSurfaceKind? pathSurfaceKind;
@override@JsonKey() final  bool isEmpty;
@override@JsonKey() final  int sortOrder;
@override final  int? editorColorArgb;

/// Create a copy of ProjectSmartTileMaterial
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSmartTileMaterialCopyWith<_ProjectSmartTileMaterial> get copyWith => __$ProjectSmartTileMaterialCopyWithImpl<_ProjectSmartTileMaterial>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSmartTileMaterialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSmartTileMaterial&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.connectionGroupId, connectionGroupId) || other.connectionGroupId == connectionGroupId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.terrainType, terrainType) || other.terrainType == terrainType)&&(identical(other.pathSurfaceKind, pathSurfaceKind) || other.pathSurfaceKind == pathSurfaceKind)&&(identical(other.isEmpty, isEmpty) || other.isEmpty == isEmpty)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.editorColorArgb, editorColorArgb) || other.editorColorArgb == editorColorArgb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,connectionGroupId,categoryId,terrainType,pathSurfaceKind,isEmpty,sortOrder,editorColorArgb);

@override
String toString() {
  return 'ProjectSmartTileMaterial(id: $id, name: $name, connectionGroupId: $connectionGroupId, categoryId: $categoryId, terrainType: $terrainType, pathSurfaceKind: $pathSurfaceKind, isEmpty: $isEmpty, sortOrder: $sortOrder, editorColorArgb: $editorColorArgb)';
}


}

/// @nodoc
abstract mixin class _$ProjectSmartTileMaterialCopyWith<$Res> implements $ProjectSmartTileMaterialCopyWith<$Res> {
  factory _$ProjectSmartTileMaterialCopyWith(_ProjectSmartTileMaterial value, $Res Function(_ProjectSmartTileMaterial) _then) = __$ProjectSmartTileMaterialCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String connectionGroupId, String categoryId, TerrainType? terrainType, PathSurfaceKind? pathSurfaceKind, bool isEmpty, int sortOrder, int? editorColorArgb
});




}
/// @nodoc
class __$ProjectSmartTileMaterialCopyWithImpl<$Res>
    implements _$ProjectSmartTileMaterialCopyWith<$Res> {
  __$ProjectSmartTileMaterialCopyWithImpl(this._self, this._then);

  final _ProjectSmartTileMaterial _self;
  final $Res Function(_ProjectSmartTileMaterial) _then;

/// Create a copy of ProjectSmartTileMaterial
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? connectionGroupId = null,Object? categoryId = null,Object? terrainType = freezed,Object? pathSurfaceKind = freezed,Object? isEmpty = null,Object? sortOrder = null,Object? editorColorArgb = freezed,}) {
  return _then(_ProjectSmartTileMaterial(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,connectionGroupId: null == connectionGroupId ? _self.connectionGroupId : connectionGroupId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,terrainType: freezed == terrainType ? _self.terrainType : terrainType // ignore: cast_nullable_to_non_nullable
as TerrainType?,pathSurfaceKind: freezed == pathSurfaceKind ? _self.pathSurfaceKind : pathSurfaceKind // ignore: cast_nullable_to_non_nullable
as PathSurfaceKind?,isEmpty: null == isEmpty ? _self.isEmpty : isEmpty // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,editorColorArgb: freezed == editorColorArgb ? _self.editorColorArgb : editorColorArgb // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ProjectSmartTileAnimationFrame {

 SmartTileFrameRef get frame; int get durationMs;
/// Create a copy of ProjectSmartTileAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSmartTileAnimationFrameCopyWith<ProjectSmartTileAnimationFrame> get copyWith => _$ProjectSmartTileAnimationFrameCopyWithImpl<ProjectSmartTileAnimationFrame>(this as ProjectSmartTileAnimationFrame, _$identity);

  /// Serializes this ProjectSmartTileAnimationFrame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSmartTileAnimationFrame&&(identical(other.frame, frame) || other.frame == frame)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frame,durationMs);

@override
String toString() {
  return 'ProjectSmartTileAnimationFrame(frame: $frame, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $ProjectSmartTileAnimationFrameCopyWith<$Res>  {
  factory $ProjectSmartTileAnimationFrameCopyWith(ProjectSmartTileAnimationFrame value, $Res Function(ProjectSmartTileAnimationFrame) _then) = _$ProjectSmartTileAnimationFrameCopyWithImpl;
@useResult
$Res call({
 SmartTileFrameRef frame, int durationMs
});


$SmartTileFrameRefCopyWith<$Res> get frame;

}
/// @nodoc
class _$ProjectSmartTileAnimationFrameCopyWithImpl<$Res>
    implements $ProjectSmartTileAnimationFrameCopyWith<$Res> {
  _$ProjectSmartTileAnimationFrameCopyWithImpl(this._self, this._then);

  final ProjectSmartTileAnimationFrame _self;
  final $Res Function(ProjectSmartTileAnimationFrame) _then;

/// Create a copy of ProjectSmartTileAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frame = null,Object? durationMs = null,}) {
  return _then(_self.copyWith(
frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as SmartTileFrameRef,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ProjectSmartTileAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileFrameRefCopyWith<$Res> get frame {

  return $SmartTileFrameRefCopyWith<$Res>(_self.frame, (value) {
    return _then(_self.copyWith(frame: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectSmartTileAnimationFrame].
extension ProjectSmartTileAnimationFramePatterns on ProjectSmartTileAnimationFrame {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSmartTileAnimationFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSmartTileAnimationFrame() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSmartTileAnimationFrame value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileAnimationFrame():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSmartTileAnimationFrame value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileAnimationFrame() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SmartTileFrameRef frame,  int durationMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSmartTileAnimationFrame() when $default != null:
return $default(_that.frame,_that.durationMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SmartTileFrameRef frame,  int durationMs)  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileAnimationFrame():
return $default(_that.frame,_that.durationMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SmartTileFrameRef frame,  int durationMs)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileAnimationFrame() when $default != null:
return $default(_that.frame,_that.durationMs);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSmartTileAnimationFrame implements ProjectSmartTileAnimationFrame {
  const _ProjectSmartTileAnimationFrame({required this.frame, required this.durationMs});
  factory _ProjectSmartTileAnimationFrame.fromJson(Map<String, dynamic> json) => _$ProjectSmartTileAnimationFrameFromJson(json);

@override final  SmartTileFrameRef frame;
@override final  int durationMs;

/// Create a copy of ProjectSmartTileAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSmartTileAnimationFrameCopyWith<_ProjectSmartTileAnimationFrame> get copyWith => __$ProjectSmartTileAnimationFrameCopyWithImpl<_ProjectSmartTileAnimationFrame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSmartTileAnimationFrameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSmartTileAnimationFrame&&(identical(other.frame, frame) || other.frame == frame)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frame,durationMs);

@override
String toString() {
  return 'ProjectSmartTileAnimationFrame(frame: $frame, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class _$ProjectSmartTileAnimationFrameCopyWith<$Res> implements $ProjectSmartTileAnimationFrameCopyWith<$Res> {
  factory _$ProjectSmartTileAnimationFrameCopyWith(_ProjectSmartTileAnimationFrame value, $Res Function(_ProjectSmartTileAnimationFrame) _then) = __$ProjectSmartTileAnimationFrameCopyWithImpl;
@override @useResult
$Res call({
 SmartTileFrameRef frame, int durationMs
});


@override $SmartTileFrameRefCopyWith<$Res> get frame;

}
/// @nodoc
class __$ProjectSmartTileAnimationFrameCopyWithImpl<$Res>
    implements _$ProjectSmartTileAnimationFrameCopyWith<$Res> {
  __$ProjectSmartTileAnimationFrameCopyWithImpl(this._self, this._then);

  final _ProjectSmartTileAnimationFrame _self;
  final $Res Function(_ProjectSmartTileAnimationFrame) _then;

/// Create a copy of ProjectSmartTileAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frame = null,Object? durationMs = null,}) {
  return _then(_ProjectSmartTileAnimationFrame(
frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as SmartTileFrameRef,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ProjectSmartTileAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileFrameRefCopyWith<$Res> get frame {

  return $SmartTileFrameRefCopyWith<$Res>(_self.frame, (value) {
    return _then(_self.copyWith(frame: value));
  });
}
}


/// @nodoc
mixin _$ProjectSmartTileAnimation {

 String get id; String get name; List<ProjectSmartTileAnimationFrame> get frames; SmartTileAnimationSync get sync; SmartTileAnimationLoop get loop;
/// Create a copy of ProjectSmartTileAnimation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSmartTileAnimationCopyWith<ProjectSmartTileAnimation> get copyWith => _$ProjectSmartTileAnimationCopyWithImpl<ProjectSmartTileAnimation>(this as ProjectSmartTileAnimation, _$identity);

  /// Serializes this ProjectSmartTileAnimation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSmartTileAnimation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.sync, sync) || other.sync == sync)&&(identical(other.loop, loop) || other.loop == loop));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(frames),sync,loop);

@override
String toString() {
  return 'ProjectSmartTileAnimation(id: $id, name: $name, frames: $frames, sync: $sync, loop: $loop)';
}


}

/// @nodoc
abstract mixin class $ProjectSmartTileAnimationCopyWith<$Res>  {
  factory $ProjectSmartTileAnimationCopyWith(ProjectSmartTileAnimation value, $Res Function(ProjectSmartTileAnimation) _then) = _$ProjectSmartTileAnimationCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<ProjectSmartTileAnimationFrame> frames, SmartTileAnimationSync sync, SmartTileAnimationLoop loop
});




}
/// @nodoc
class _$ProjectSmartTileAnimationCopyWithImpl<$Res>
    implements $ProjectSmartTileAnimationCopyWith<$Res> {
  _$ProjectSmartTileAnimationCopyWithImpl(this._self, this._then);

  final ProjectSmartTileAnimation _self;
  final $Res Function(ProjectSmartTileAnimation) _then;

/// Create a copy of ProjectSmartTileAnimation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? frames = null,Object? sync = null,Object? loop = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as List<ProjectSmartTileAnimationFrame>,sync: null == sync ? _self.sync : sync // ignore: cast_nullable_to_non_nullable
as SmartTileAnimationSync,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as SmartTileAnimationLoop,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSmartTileAnimation].
extension ProjectSmartTileAnimationPatterns on ProjectSmartTileAnimation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSmartTileAnimation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSmartTileAnimation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSmartTileAnimation value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileAnimation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSmartTileAnimation value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileAnimation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<ProjectSmartTileAnimationFrame> frames,  SmartTileAnimationSync sync,  SmartTileAnimationLoop loop)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSmartTileAnimation() when $default != null:
return $default(_that.id,_that.name,_that.frames,_that.sync,_that.loop);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<ProjectSmartTileAnimationFrame> frames,  SmartTileAnimationSync sync,  SmartTileAnimationLoop loop)  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileAnimation():
return $default(_that.id,_that.name,_that.frames,_that.sync,_that.loop);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<ProjectSmartTileAnimationFrame> frames,  SmartTileAnimationSync sync,  SmartTileAnimationLoop loop)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileAnimation() when $default != null:
return $default(_that.id,_that.name,_that.frames,_that.sync,_that.loop);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSmartTileAnimation implements ProjectSmartTileAnimation {
  const _ProjectSmartTileAnimation({required this.id, required this.name, required final  List<ProjectSmartTileAnimationFrame> frames, this.sync = SmartTileAnimationSync.global, this.loop = SmartTileAnimationLoop.repeat}): assert(id != "", 'id must not be blank'),assert(name != "", 'name must not be blank'),_frames = frames;
  factory _ProjectSmartTileAnimation.fromJson(Map<String, dynamic> json) => _$ProjectSmartTileAnimationFromJson(json);

@override final  String id;
@override final  String name;
 final  List<ProjectSmartTileAnimationFrame> _frames;
@override List<ProjectSmartTileAnimationFrame> get frames {
  if (_frames is EqualUnmodifiableListView) return _frames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_frames);
}

@override@JsonKey() final  SmartTileAnimationSync sync;
@override@JsonKey() final  SmartTileAnimationLoop loop;

/// Create a copy of ProjectSmartTileAnimation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSmartTileAnimationCopyWith<_ProjectSmartTileAnimation> get copyWith => __$ProjectSmartTileAnimationCopyWithImpl<_ProjectSmartTileAnimation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSmartTileAnimationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSmartTileAnimation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._frames, _frames)&&(identical(other.sync, sync) || other.sync == sync)&&(identical(other.loop, loop) || other.loop == loop));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_frames),sync,loop);

@override
String toString() {
  return 'ProjectSmartTileAnimation(id: $id, name: $name, frames: $frames, sync: $sync, loop: $loop)';
}


}

/// @nodoc
abstract mixin class _$ProjectSmartTileAnimationCopyWith<$Res> implements $ProjectSmartTileAnimationCopyWith<$Res> {
  factory _$ProjectSmartTileAnimationCopyWith(_ProjectSmartTileAnimation value, $Res Function(_ProjectSmartTileAnimation) _then) = __$ProjectSmartTileAnimationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<ProjectSmartTileAnimationFrame> frames, SmartTileAnimationSync sync, SmartTileAnimationLoop loop
});




}
/// @nodoc
class __$ProjectSmartTileAnimationCopyWithImpl<$Res>
    implements _$ProjectSmartTileAnimationCopyWith<$Res> {
  __$ProjectSmartTileAnimationCopyWithImpl(this._self, this._then);

  final _ProjectSmartTileAnimation _self;
  final $Res Function(_ProjectSmartTileAnimation) _then;

/// Create a copy of ProjectSmartTileAnimation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? frames = null,Object? sync = null,Object? loop = null,}) {
  return _then(_ProjectSmartTileAnimation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self._frames : frames // ignore: cast_nullable_to_non_nullable
as List<ProjectSmartTileAnimationFrame>,sync: null == sync ? _self.sync : sync // ignore: cast_nullable_to_non_nullable
as SmartTileAnimationSync,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as SmartTileAnimationLoop,
  ));
}


}


/// @nodoc
mixin _$ProjectSmartTilePreset {

 String get id; String get name; String get categoryId; SmartTileUsage get usage; SmartTileTopology get topology; SmartTileTemplateHint get templateHint; SmartTileBoundaryPolicy get boundaryPolicy; SmartTilePresetStatus get status; SmartTileCoveragePolicy get coveragePolicy; SmartTileCoverageProfile get coverageProfile; SmartTileTransformPolicy get transformPolicy; String get defaultMaterialId; List<String> get allowedMaterialIds; List<SmartTileRule> get rules; List<String> get tags; int get sortOrder; int get seedSalt; String? get fallbackRuleId;
/// Create a copy of ProjectSmartTilePreset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSmartTilePresetCopyWith<ProjectSmartTilePreset> get copyWith => _$ProjectSmartTilePresetCopyWithImpl<ProjectSmartTilePreset>(this as ProjectSmartTilePreset, _$identity);

  /// Serializes this ProjectSmartTilePreset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSmartTilePreset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.topology, topology) || other.topology == topology)&&(identical(other.templateHint, templateHint) || other.templateHint == templateHint)&&(identical(other.boundaryPolicy, boundaryPolicy) || other.boundaryPolicy == boundaryPolicy)&&(identical(other.status, status) || other.status == status)&&(identical(other.coveragePolicy, coveragePolicy) || other.coveragePolicy == coveragePolicy)&&(identical(other.coverageProfile, coverageProfile) || other.coverageProfile == coverageProfile)&&(identical(other.transformPolicy, transformPolicy) || other.transformPolicy == transformPolicy)&&(identical(other.defaultMaterialId, defaultMaterialId) || other.defaultMaterialId == defaultMaterialId)&&const DeepCollectionEquality().equals(other.allowedMaterialIds, allowedMaterialIds)&&const DeepCollectionEquality().equals(other.rules, rules)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.seedSalt, seedSalt) || other.seedSalt == seedSalt)&&(identical(other.fallbackRuleId, fallbackRuleId) || other.fallbackRuleId == fallbackRuleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,usage,topology,templateHint,boundaryPolicy,status,coveragePolicy,coverageProfile,transformPolicy,defaultMaterialId,const DeepCollectionEquality().hash(allowedMaterialIds),const DeepCollectionEquality().hash(rules),const DeepCollectionEquality().hash(tags),sortOrder,seedSalt,fallbackRuleId);

@override
String toString() {
  return 'ProjectSmartTilePreset(id: $id, name: $name, categoryId: $categoryId, usage: $usage, topology: $topology, templateHint: $templateHint, boundaryPolicy: $boundaryPolicy, status: $status, coveragePolicy: $coveragePolicy, coverageProfile: $coverageProfile, transformPolicy: $transformPolicy, defaultMaterialId: $defaultMaterialId, allowedMaterialIds: $allowedMaterialIds, rules: $rules, tags: $tags, sortOrder: $sortOrder, seedSalt: $seedSalt, fallbackRuleId: $fallbackRuleId)';
}


}

/// @nodoc
abstract mixin class $ProjectSmartTilePresetCopyWith<$Res>  {
  factory $ProjectSmartTilePresetCopyWith(ProjectSmartTilePreset value, $Res Function(ProjectSmartTilePreset) _then) = _$ProjectSmartTilePresetCopyWithImpl;
@useResult
$Res call({
 String id, String name, String categoryId, SmartTileUsage usage, SmartTileTopology topology, SmartTileTemplateHint templateHint, SmartTileBoundaryPolicy boundaryPolicy, SmartTilePresetStatus status, SmartTileCoveragePolicy coveragePolicy, SmartTileCoverageProfile coverageProfile, SmartTileTransformPolicy transformPolicy, String defaultMaterialId, List<String> allowedMaterialIds, List<SmartTileRule> rules, List<String> tags, int sortOrder, int seedSalt, String? fallbackRuleId
});


$SmartTileCoverageProfileCopyWith<$Res> get coverageProfile;$SmartTileTransformPolicyCopyWith<$Res> get transformPolicy;

}
/// @nodoc
class _$ProjectSmartTilePresetCopyWithImpl<$Res>
    implements $ProjectSmartTilePresetCopyWith<$Res> {
  _$ProjectSmartTilePresetCopyWithImpl(this._self, this._then);

  final ProjectSmartTilePreset _self;
  final $Res Function(ProjectSmartTilePreset) _then;

/// Create a copy of ProjectSmartTilePreset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? usage = null,Object? topology = null,Object? templateHint = null,Object? boundaryPolicy = null,Object? status = null,Object? coveragePolicy = null,Object? coverageProfile = null,Object? transformPolicy = null,Object? defaultMaterialId = null,Object? allowedMaterialIds = null,Object? rules = null,Object? tags = null,Object? sortOrder = null,Object? seedSalt = null,Object? fallbackRuleId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as SmartTileUsage,topology: null == topology ? _self.topology : topology // ignore: cast_nullable_to_non_nullable
as SmartTileTopology,templateHint: null == templateHint ? _self.templateHint : templateHint // ignore: cast_nullable_to_non_nullable
as SmartTileTemplateHint,boundaryPolicy: null == boundaryPolicy ? _self.boundaryPolicy : boundaryPolicy // ignore: cast_nullable_to_non_nullable
as SmartTileBoundaryPolicy,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SmartTilePresetStatus,coveragePolicy: null == coveragePolicy ? _self.coveragePolicy : coveragePolicy // ignore: cast_nullable_to_non_nullable
as SmartTileCoveragePolicy,coverageProfile: null == coverageProfile ? _self.coverageProfile : coverageProfile // ignore: cast_nullable_to_non_nullable
as SmartTileCoverageProfile,transformPolicy: null == transformPolicy ? _self.transformPolicy : transformPolicy // ignore: cast_nullable_to_non_nullable
as SmartTileTransformPolicy,defaultMaterialId: null == defaultMaterialId ? _self.defaultMaterialId : defaultMaterialId // ignore: cast_nullable_to_non_nullable
as String,allowedMaterialIds: null == allowedMaterialIds ? _self.allowedMaterialIds : allowedMaterialIds // ignore: cast_nullable_to_non_nullable
as List<String>,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<SmartTileRule>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,seedSalt: null == seedSalt ? _self.seedSalt : seedSalt // ignore: cast_nullable_to_non_nullable
as int,fallbackRuleId: freezed == fallbackRuleId ? _self.fallbackRuleId : fallbackRuleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProjectSmartTilePreset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileCoverageProfileCopyWith<$Res> get coverageProfile {

  return $SmartTileCoverageProfileCopyWith<$Res>(_self.coverageProfile, (value) {
    return _then(_self.copyWith(coverageProfile: value));
  });
}/// Create a copy of ProjectSmartTilePreset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileTransformPolicyCopyWith<$Res> get transformPolicy {

  return $SmartTileTransformPolicyCopyWith<$Res>(_self.transformPolicy, (value) {
    return _then(_self.copyWith(transformPolicy: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectSmartTilePreset].
extension ProjectSmartTilePresetPatterns on ProjectSmartTilePreset {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSmartTilePreset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSmartTilePreset() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSmartTilePreset value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTilePreset():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSmartTilePreset value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTilePreset() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String categoryId,  SmartTileUsage usage,  SmartTileTopology topology,  SmartTileTemplateHint templateHint,  SmartTileBoundaryPolicy boundaryPolicy,  SmartTilePresetStatus status,  SmartTileCoveragePolicy coveragePolicy,  SmartTileCoverageProfile coverageProfile,  SmartTileTransformPolicy transformPolicy,  String defaultMaterialId,  List<String> allowedMaterialIds,  List<SmartTileRule> rules,  List<String> tags,  int sortOrder,  int seedSalt,  String? fallbackRuleId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSmartTilePreset() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.usage,_that.topology,_that.templateHint,_that.boundaryPolicy,_that.status,_that.coveragePolicy,_that.coverageProfile,_that.transformPolicy,_that.defaultMaterialId,_that.allowedMaterialIds,_that.rules,_that.tags,_that.sortOrder,_that.seedSalt,_that.fallbackRuleId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String categoryId,  SmartTileUsage usage,  SmartTileTopology topology,  SmartTileTemplateHint templateHint,  SmartTileBoundaryPolicy boundaryPolicy,  SmartTilePresetStatus status,  SmartTileCoveragePolicy coveragePolicy,  SmartTileCoverageProfile coverageProfile,  SmartTileTransformPolicy transformPolicy,  String defaultMaterialId,  List<String> allowedMaterialIds,  List<SmartTileRule> rules,  List<String> tags,  int sortOrder,  int seedSalt,  String? fallbackRuleId)  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTilePreset():
return $default(_that.id,_that.name,_that.categoryId,_that.usage,_that.topology,_that.templateHint,_that.boundaryPolicy,_that.status,_that.coveragePolicy,_that.coverageProfile,_that.transformPolicy,_that.defaultMaterialId,_that.allowedMaterialIds,_that.rules,_that.tags,_that.sortOrder,_that.seedSalt,_that.fallbackRuleId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String categoryId,  SmartTileUsage usage,  SmartTileTopology topology,  SmartTileTemplateHint templateHint,  SmartTileBoundaryPolicy boundaryPolicy,  SmartTilePresetStatus status,  SmartTileCoveragePolicy coveragePolicy,  SmartTileCoverageProfile coverageProfile,  SmartTileTransformPolicy transformPolicy,  String defaultMaterialId,  List<String> allowedMaterialIds,  List<SmartTileRule> rules,  List<String> tags,  int sortOrder,  int seedSalt,  String? fallbackRuleId)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTilePreset() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.usage,_that.topology,_that.templateHint,_that.boundaryPolicy,_that.status,_that.coveragePolicy,_that.coverageProfile,_that.transformPolicy,_that.defaultMaterialId,_that.allowedMaterialIds,_that.rules,_that.tags,_that.sortOrder,_that.seedSalt,_that.fallbackRuleId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSmartTilePreset implements ProjectSmartTilePreset {
  const _ProjectSmartTilePreset({required this.id, required this.name, this.categoryId = '', required this.usage, required this.topology, this.templateHint = SmartTileTemplateHint.free, this.boundaryPolicy = SmartTileBoundaryPolicy.empty, this.status = SmartTilePresetStatus.draft, required this.coveragePolicy, required this.coverageProfile, required this.transformPolicy, required this.defaultMaterialId, required final  List<String> allowedMaterialIds, final  List<SmartTileRule> rules = const <SmartTileRule>[], final  List<String> tags = const <String>[], this.sortOrder = 0, this.seedSalt = 0, this.fallbackRuleId}): assert(id != "", 'id must not be blank'),assert(name != "", 'name must not be blank'),assert(defaultMaterialId != "", 'defaultMaterialId must not be blank'),_allowedMaterialIds = allowedMaterialIds,_rules = rules,_tags = tags;
  factory _ProjectSmartTilePreset.fromJson(Map<String, dynamic> json) => _$ProjectSmartTilePresetFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String categoryId;
@override final  SmartTileUsage usage;
@override final  SmartTileTopology topology;
@override@JsonKey() final  SmartTileTemplateHint templateHint;
@override@JsonKey() final  SmartTileBoundaryPolicy boundaryPolicy;
@override@JsonKey() final  SmartTilePresetStatus status;
@override final  SmartTileCoveragePolicy coveragePolicy;
@override final  SmartTileCoverageProfile coverageProfile;
@override final  SmartTileTransformPolicy transformPolicy;
@override final  String defaultMaterialId;
 final  List<String> _allowedMaterialIds;
@override List<String> get allowedMaterialIds {
  if (_allowedMaterialIds is EqualUnmodifiableListView) return _allowedMaterialIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allowedMaterialIds);
}

 final  List<SmartTileRule> _rules;
@override@JsonKey() List<SmartTileRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  int sortOrder;
@override@JsonKey() final  int seedSalt;
@override final  String? fallbackRuleId;

/// Create a copy of ProjectSmartTilePreset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSmartTilePresetCopyWith<_ProjectSmartTilePreset> get copyWith => __$ProjectSmartTilePresetCopyWithImpl<_ProjectSmartTilePreset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSmartTilePresetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSmartTilePreset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.topology, topology) || other.topology == topology)&&(identical(other.templateHint, templateHint) || other.templateHint == templateHint)&&(identical(other.boundaryPolicy, boundaryPolicy) || other.boundaryPolicy == boundaryPolicy)&&(identical(other.status, status) || other.status == status)&&(identical(other.coveragePolicy, coveragePolicy) || other.coveragePolicy == coveragePolicy)&&(identical(other.coverageProfile, coverageProfile) || other.coverageProfile == coverageProfile)&&(identical(other.transformPolicy, transformPolicy) || other.transformPolicy == transformPolicy)&&(identical(other.defaultMaterialId, defaultMaterialId) || other.defaultMaterialId == defaultMaterialId)&&const DeepCollectionEquality().equals(other._allowedMaterialIds, _allowedMaterialIds)&&const DeepCollectionEquality().equals(other._rules, _rules)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.seedSalt, seedSalt) || other.seedSalt == seedSalt)&&(identical(other.fallbackRuleId, fallbackRuleId) || other.fallbackRuleId == fallbackRuleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,usage,topology,templateHint,boundaryPolicy,status,coveragePolicy,coverageProfile,transformPolicy,defaultMaterialId,const DeepCollectionEquality().hash(_allowedMaterialIds),const DeepCollectionEquality().hash(_rules),const DeepCollectionEquality().hash(_tags),sortOrder,seedSalt,fallbackRuleId);

@override
String toString() {
  return 'ProjectSmartTilePreset(id: $id, name: $name, categoryId: $categoryId, usage: $usage, topology: $topology, templateHint: $templateHint, boundaryPolicy: $boundaryPolicy, status: $status, coveragePolicy: $coveragePolicy, coverageProfile: $coverageProfile, transformPolicy: $transformPolicy, defaultMaterialId: $defaultMaterialId, allowedMaterialIds: $allowedMaterialIds, rules: $rules, tags: $tags, sortOrder: $sortOrder, seedSalt: $seedSalt, fallbackRuleId: $fallbackRuleId)';
}


}

/// @nodoc
abstract mixin class _$ProjectSmartTilePresetCopyWith<$Res> implements $ProjectSmartTilePresetCopyWith<$Res> {
  factory _$ProjectSmartTilePresetCopyWith(_ProjectSmartTilePreset value, $Res Function(_ProjectSmartTilePreset) _then) = __$ProjectSmartTilePresetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String categoryId, SmartTileUsage usage, SmartTileTopology topology, SmartTileTemplateHint templateHint, SmartTileBoundaryPolicy boundaryPolicy, SmartTilePresetStatus status, SmartTileCoveragePolicy coveragePolicy, SmartTileCoverageProfile coverageProfile, SmartTileTransformPolicy transformPolicy, String defaultMaterialId, List<String> allowedMaterialIds, List<SmartTileRule> rules, List<String> tags, int sortOrder, int seedSalt, String? fallbackRuleId
});


@override $SmartTileCoverageProfileCopyWith<$Res> get coverageProfile;@override $SmartTileTransformPolicyCopyWith<$Res> get transformPolicy;

}
/// @nodoc
class __$ProjectSmartTilePresetCopyWithImpl<$Res>
    implements _$ProjectSmartTilePresetCopyWith<$Res> {
  __$ProjectSmartTilePresetCopyWithImpl(this._self, this._then);

  final _ProjectSmartTilePreset _self;
  final $Res Function(_ProjectSmartTilePreset) _then;

/// Create a copy of ProjectSmartTilePreset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? usage = null,Object? topology = null,Object? templateHint = null,Object? boundaryPolicy = null,Object? status = null,Object? coveragePolicy = null,Object? coverageProfile = null,Object? transformPolicy = null,Object? defaultMaterialId = null,Object? allowedMaterialIds = null,Object? rules = null,Object? tags = null,Object? sortOrder = null,Object? seedSalt = null,Object? fallbackRuleId = freezed,}) {
  return _then(_ProjectSmartTilePreset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as SmartTileUsage,topology: null == topology ? _self.topology : topology // ignore: cast_nullable_to_non_nullable
as SmartTileTopology,templateHint: null == templateHint ? _self.templateHint : templateHint // ignore: cast_nullable_to_non_nullable
as SmartTileTemplateHint,boundaryPolicy: null == boundaryPolicy ? _self.boundaryPolicy : boundaryPolicy // ignore: cast_nullable_to_non_nullable
as SmartTileBoundaryPolicy,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SmartTilePresetStatus,coveragePolicy: null == coveragePolicy ? _self.coveragePolicy : coveragePolicy // ignore: cast_nullable_to_non_nullable
as SmartTileCoveragePolicy,coverageProfile: null == coverageProfile ? _self.coverageProfile : coverageProfile // ignore: cast_nullable_to_non_nullable
as SmartTileCoverageProfile,transformPolicy: null == transformPolicy ? _self.transformPolicy : transformPolicy // ignore: cast_nullable_to_non_nullable
as SmartTileTransformPolicy,defaultMaterialId: null == defaultMaterialId ? _self.defaultMaterialId : defaultMaterialId // ignore: cast_nullable_to_non_nullable
as String,allowedMaterialIds: null == allowedMaterialIds ? _self._allowedMaterialIds : allowedMaterialIds // ignore: cast_nullable_to_non_nullable
as List<String>,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<SmartTileRule>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,seedSalt: null == seedSalt ? _self.seedSalt : seedSalt // ignore: cast_nullable_to_non_nullable
as int,fallbackRuleId: freezed == fallbackRuleId ? _self.fallbackRuleId : fallbackRuleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProjectSmartTilePreset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileCoverageProfileCopyWith<$Res> get coverageProfile {

  return $SmartTileCoverageProfileCopyWith<$Res>(_self.coverageProfile, (value) {
    return _then(_self.copyWith(coverageProfile: value));
  });
}/// Create a copy of ProjectSmartTilePreset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileTransformPolicyCopyWith<$Res> get transformPolicy {

  return $SmartTileTransformPolicyCopyWith<$Res>(_self.transformPolicy, (value) {
    return _then(_self.copyWith(transformPolicy: value));
  });
}
}


/// @nodoc
mixin _$ProjectSmartTileAuthoringDraft {

 String get id; String get targetPresetId; String? get sourcePresetId; String get name; String get categoryId; SmartTileUsage get usage; SmartTileAuthoringStage get lastStage; String? get guideId; List<String> get sourceTilesetIds; List<ProjectSmartTileAtlas> get atlases; String? get primaryAtlasId; List<ProjectSmartTileMaterial> get materials; List<ProjectSmartTileAnimation> get animations; String? get defaultMaterialId; List<String> get allowedMaterialIds; SmartTileTopology get topology; SmartTileTemplateHint get templateHint; SmartTileBoundaryPolicy get boundaryPolicy; SmartTileCoveragePolicy get coveragePolicy; SmartTileCoverageProfile get coverageProfile; SmartTileTransformPolicy get transformPolicy; List<SmartTileRule> get rules; String? get fallbackRuleId; List<String> get tags; int get sortOrder; int get seedSalt;
/// Create a copy of ProjectSmartTileAuthoringDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSmartTileAuthoringDraftCopyWith<ProjectSmartTileAuthoringDraft> get copyWith => _$ProjectSmartTileAuthoringDraftCopyWithImpl<ProjectSmartTileAuthoringDraft>(this as ProjectSmartTileAuthoringDraft, _$identity);

  /// Serializes this ProjectSmartTileAuthoringDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSmartTileAuthoringDraft&&(identical(other.id, id) || other.id == id)&&(identical(other.targetPresetId, targetPresetId) || other.targetPresetId == targetPresetId)&&(identical(other.sourcePresetId, sourcePresetId) || other.sourcePresetId == sourcePresetId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.lastStage, lastStage) || other.lastStage == lastStage)&&(identical(other.guideId, guideId) || other.guideId == guideId)&&const DeepCollectionEquality().equals(other.sourceTilesetIds, sourceTilesetIds)&&const DeepCollectionEquality().equals(other.atlases, atlases)&&(identical(other.primaryAtlasId, primaryAtlasId) || other.primaryAtlasId == primaryAtlasId)&&const DeepCollectionEquality().equals(other.materials, materials)&&const DeepCollectionEquality().equals(other.animations, animations)&&(identical(other.defaultMaterialId, defaultMaterialId) || other.defaultMaterialId == defaultMaterialId)&&const DeepCollectionEquality().equals(other.allowedMaterialIds, allowedMaterialIds)&&(identical(other.topology, topology) || other.topology == topology)&&(identical(other.templateHint, templateHint) || other.templateHint == templateHint)&&(identical(other.boundaryPolicy, boundaryPolicy) || other.boundaryPolicy == boundaryPolicy)&&(identical(other.coveragePolicy, coveragePolicy) || other.coveragePolicy == coveragePolicy)&&(identical(other.coverageProfile, coverageProfile) || other.coverageProfile == coverageProfile)&&(identical(other.transformPolicy, transformPolicy) || other.transformPolicy == transformPolicy)&&const DeepCollectionEquality().equals(other.rules, rules)&&(identical(other.fallbackRuleId, fallbackRuleId) || other.fallbackRuleId == fallbackRuleId)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.seedSalt, seedSalt) || other.seedSalt == seedSalt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,targetPresetId,sourcePresetId,name,categoryId,usage,lastStage,guideId,const DeepCollectionEquality().hash(sourceTilesetIds),const DeepCollectionEquality().hash(atlases),primaryAtlasId,const DeepCollectionEquality().hash(materials),const DeepCollectionEquality().hash(animations),defaultMaterialId,const DeepCollectionEquality().hash(allowedMaterialIds),topology,templateHint,boundaryPolicy,coveragePolicy,coverageProfile,transformPolicy,const DeepCollectionEquality().hash(rules),fallbackRuleId,const DeepCollectionEquality().hash(tags),sortOrder,seedSalt]);

@override
String toString() {
  return 'ProjectSmartTileAuthoringDraft(id: $id, targetPresetId: $targetPresetId, sourcePresetId: $sourcePresetId, name: $name, categoryId: $categoryId, usage: $usage, lastStage: $lastStage, guideId: $guideId, sourceTilesetIds: $sourceTilesetIds, atlases: $atlases, primaryAtlasId: $primaryAtlasId, materials: $materials, animations: $animations, defaultMaterialId: $defaultMaterialId, allowedMaterialIds: $allowedMaterialIds, topology: $topology, templateHint: $templateHint, boundaryPolicy: $boundaryPolicy, coveragePolicy: $coveragePolicy, coverageProfile: $coverageProfile, transformPolicy: $transformPolicy, rules: $rules, fallbackRuleId: $fallbackRuleId, tags: $tags, sortOrder: $sortOrder, seedSalt: $seedSalt)';
}


}

/// @nodoc
abstract mixin class $ProjectSmartTileAuthoringDraftCopyWith<$Res>  {
  factory $ProjectSmartTileAuthoringDraftCopyWith(ProjectSmartTileAuthoringDraft value, $Res Function(ProjectSmartTileAuthoringDraft) _then) = _$ProjectSmartTileAuthoringDraftCopyWithImpl;
@useResult
$Res call({
 String id, String targetPresetId, String? sourcePresetId, String name, String categoryId, SmartTileUsage usage, SmartTileAuthoringStage lastStage, String? guideId, List<String> sourceTilesetIds, List<ProjectSmartTileAtlas> atlases, String? primaryAtlasId, List<ProjectSmartTileMaterial> materials, List<ProjectSmartTileAnimation> animations, String? defaultMaterialId, List<String> allowedMaterialIds, SmartTileTopology topology, SmartTileTemplateHint templateHint, SmartTileBoundaryPolicy boundaryPolicy, SmartTileCoveragePolicy coveragePolicy, SmartTileCoverageProfile coverageProfile, SmartTileTransformPolicy transformPolicy, List<SmartTileRule> rules, String? fallbackRuleId, List<String> tags, int sortOrder, int seedSalt
});


$SmartTileCoverageProfileCopyWith<$Res> get coverageProfile;$SmartTileTransformPolicyCopyWith<$Res> get transformPolicy;

}
/// @nodoc
class _$ProjectSmartTileAuthoringDraftCopyWithImpl<$Res>
    implements $ProjectSmartTileAuthoringDraftCopyWith<$Res> {
  _$ProjectSmartTileAuthoringDraftCopyWithImpl(this._self, this._then);

  final ProjectSmartTileAuthoringDraft _self;
  final $Res Function(ProjectSmartTileAuthoringDraft) _then;

/// Create a copy of ProjectSmartTileAuthoringDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? targetPresetId = null,Object? sourcePresetId = freezed,Object? name = null,Object? categoryId = null,Object? usage = null,Object? lastStage = null,Object? guideId = freezed,Object? sourceTilesetIds = null,Object? atlases = null,Object? primaryAtlasId = freezed,Object? materials = null,Object? animations = null,Object? defaultMaterialId = freezed,Object? allowedMaterialIds = null,Object? topology = null,Object? templateHint = null,Object? boundaryPolicy = null,Object? coveragePolicy = null,Object? coverageProfile = null,Object? transformPolicy = null,Object? rules = null,Object? fallbackRuleId = freezed,Object? tags = null,Object? sortOrder = null,Object? seedSalt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetPresetId: null == targetPresetId ? _self.targetPresetId : targetPresetId // ignore: cast_nullable_to_non_nullable
as String,sourcePresetId: freezed == sourcePresetId ? _self.sourcePresetId : sourcePresetId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as SmartTileUsage,lastStage: null == lastStage ? _self.lastStage : lastStage // ignore: cast_nullable_to_non_nullable
as SmartTileAuthoringStage,guideId: freezed == guideId ? _self.guideId : guideId // ignore: cast_nullable_to_non_nullable
as String?,sourceTilesetIds: null == sourceTilesetIds ? _self.sourceTilesetIds : sourceTilesetIds // ignore: cast_nullable_to_non_nullable
as List<String>,atlases: null == atlases ? _self.atlases : atlases // ignore: cast_nullable_to_non_nullable
as List<ProjectSmartTileAtlas>,primaryAtlasId: freezed == primaryAtlasId ? _self.primaryAtlasId : primaryAtlasId // ignore: cast_nullable_to_non_nullable
as String?,materials: null == materials ? _self.materials : materials // ignore: cast_nullable_to_non_nullable
as List<ProjectSmartTileMaterial>,animations: null == animations ? _self.animations : animations // ignore: cast_nullable_to_non_nullable
as List<ProjectSmartTileAnimation>,defaultMaterialId: freezed == defaultMaterialId ? _self.defaultMaterialId : defaultMaterialId // ignore: cast_nullable_to_non_nullable
as String?,allowedMaterialIds: null == allowedMaterialIds ? _self.allowedMaterialIds : allowedMaterialIds // ignore: cast_nullable_to_non_nullable
as List<String>,topology: null == topology ? _self.topology : topology // ignore: cast_nullable_to_non_nullable
as SmartTileTopology,templateHint: null == templateHint ? _self.templateHint : templateHint // ignore: cast_nullable_to_non_nullable
as SmartTileTemplateHint,boundaryPolicy: null == boundaryPolicy ? _self.boundaryPolicy : boundaryPolicy // ignore: cast_nullable_to_non_nullable
as SmartTileBoundaryPolicy,coveragePolicy: null == coveragePolicy ? _self.coveragePolicy : coveragePolicy // ignore: cast_nullable_to_non_nullable
as SmartTileCoveragePolicy,coverageProfile: null == coverageProfile ? _self.coverageProfile : coverageProfile // ignore: cast_nullable_to_non_nullable
as SmartTileCoverageProfile,transformPolicy: null == transformPolicy ? _self.transformPolicy : transformPolicy // ignore: cast_nullable_to_non_nullable
as SmartTileTransformPolicy,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<SmartTileRule>,fallbackRuleId: freezed == fallbackRuleId ? _self.fallbackRuleId : fallbackRuleId // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,seedSalt: null == seedSalt ? _self.seedSalt : seedSalt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ProjectSmartTileAuthoringDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileCoverageProfileCopyWith<$Res> get coverageProfile {

  return $SmartTileCoverageProfileCopyWith<$Res>(_self.coverageProfile, (value) {
    return _then(_self.copyWith(coverageProfile: value));
  });
}/// Create a copy of ProjectSmartTileAuthoringDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileTransformPolicyCopyWith<$Res> get transformPolicy {

  return $SmartTileTransformPolicyCopyWith<$Res>(_self.transformPolicy, (value) {
    return _then(_self.copyWith(transformPolicy: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectSmartTileAuthoringDraft].
extension ProjectSmartTileAuthoringDraftPatterns on ProjectSmartTileAuthoringDraft {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSmartTileAuthoringDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSmartTileAuthoringDraft() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSmartTileAuthoringDraft value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileAuthoringDraft():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSmartTileAuthoringDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSmartTileAuthoringDraft() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String targetPresetId,  String? sourcePresetId,  String name,  String categoryId,  SmartTileUsage usage,  SmartTileAuthoringStage lastStage,  String? guideId,  List<String> sourceTilesetIds,  List<ProjectSmartTileAtlas> atlases,  String? primaryAtlasId,  List<ProjectSmartTileMaterial> materials,  List<ProjectSmartTileAnimation> animations,  String? defaultMaterialId,  List<String> allowedMaterialIds,  SmartTileTopology topology,  SmartTileTemplateHint templateHint,  SmartTileBoundaryPolicy boundaryPolicy,  SmartTileCoveragePolicy coveragePolicy,  SmartTileCoverageProfile coverageProfile,  SmartTileTransformPolicy transformPolicy,  List<SmartTileRule> rules,  String? fallbackRuleId,  List<String> tags,  int sortOrder,  int seedSalt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSmartTileAuthoringDraft() when $default != null:
return $default(_that.id,_that.targetPresetId,_that.sourcePresetId,_that.name,_that.categoryId,_that.usage,_that.lastStage,_that.guideId,_that.sourceTilesetIds,_that.atlases,_that.primaryAtlasId,_that.materials,_that.animations,_that.defaultMaterialId,_that.allowedMaterialIds,_that.topology,_that.templateHint,_that.boundaryPolicy,_that.coveragePolicy,_that.coverageProfile,_that.transformPolicy,_that.rules,_that.fallbackRuleId,_that.tags,_that.sortOrder,_that.seedSalt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String targetPresetId,  String? sourcePresetId,  String name,  String categoryId,  SmartTileUsage usage,  SmartTileAuthoringStage lastStage,  String? guideId,  List<String> sourceTilesetIds,  List<ProjectSmartTileAtlas> atlases,  String? primaryAtlasId,  List<ProjectSmartTileMaterial> materials,  List<ProjectSmartTileAnimation> animations,  String? defaultMaterialId,  List<String> allowedMaterialIds,  SmartTileTopology topology,  SmartTileTemplateHint templateHint,  SmartTileBoundaryPolicy boundaryPolicy,  SmartTileCoveragePolicy coveragePolicy,  SmartTileCoverageProfile coverageProfile,  SmartTileTransformPolicy transformPolicy,  List<SmartTileRule> rules,  String? fallbackRuleId,  List<String> tags,  int sortOrder,  int seedSalt)  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileAuthoringDraft():
return $default(_that.id,_that.targetPresetId,_that.sourcePresetId,_that.name,_that.categoryId,_that.usage,_that.lastStage,_that.guideId,_that.sourceTilesetIds,_that.atlases,_that.primaryAtlasId,_that.materials,_that.animations,_that.defaultMaterialId,_that.allowedMaterialIds,_that.topology,_that.templateHint,_that.boundaryPolicy,_that.coveragePolicy,_that.coverageProfile,_that.transformPolicy,_that.rules,_that.fallbackRuleId,_that.tags,_that.sortOrder,_that.seedSalt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String targetPresetId,  String? sourcePresetId,  String name,  String categoryId,  SmartTileUsage usage,  SmartTileAuthoringStage lastStage,  String? guideId,  List<String> sourceTilesetIds,  List<ProjectSmartTileAtlas> atlases,  String? primaryAtlasId,  List<ProjectSmartTileMaterial> materials,  List<ProjectSmartTileAnimation> animations,  String? defaultMaterialId,  List<String> allowedMaterialIds,  SmartTileTopology topology,  SmartTileTemplateHint templateHint,  SmartTileBoundaryPolicy boundaryPolicy,  SmartTileCoveragePolicy coveragePolicy,  SmartTileCoverageProfile coverageProfile,  SmartTileTransformPolicy transformPolicy,  List<SmartTileRule> rules,  String? fallbackRuleId,  List<String> tags,  int sortOrder,  int seedSalt)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSmartTileAuthoringDraft() when $default != null:
return $default(_that.id,_that.targetPresetId,_that.sourcePresetId,_that.name,_that.categoryId,_that.usage,_that.lastStage,_that.guideId,_that.sourceTilesetIds,_that.atlases,_that.primaryAtlasId,_that.materials,_that.animations,_that.defaultMaterialId,_that.allowedMaterialIds,_that.topology,_that.templateHint,_that.boundaryPolicy,_that.coveragePolicy,_that.coverageProfile,_that.transformPolicy,_that.rules,_that.fallbackRuleId,_that.tags,_that.sortOrder,_that.seedSalt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSmartTileAuthoringDraft implements ProjectSmartTileAuthoringDraft {
  const _ProjectSmartTileAuthoringDraft({required this.id, required this.targetPresetId, this.sourcePresetId, required this.name, this.categoryId = '', required this.usage, required this.lastStage, this.guideId, final  List<String> sourceTilesetIds = const <String>[], final  List<ProjectSmartTileAtlas> atlases = const <ProjectSmartTileAtlas>[], this.primaryAtlasId, final  List<ProjectSmartTileMaterial> materials = const <ProjectSmartTileMaterial>[], final  List<ProjectSmartTileAnimation> animations = const <ProjectSmartTileAnimation>[], this.defaultMaterialId, final  List<String> allowedMaterialIds = const <String>[], this.topology = SmartTileTopology.uniform, this.templateHint = SmartTileTemplateHint.simple, this.boundaryPolicy = SmartTileBoundaryPolicy.empty, this.coveragePolicy = SmartTileCoveragePolicy.complete, this.coverageProfile = const SmartTileCoverageProfile(mode: SmartTileCoverageMode.template), this.transformPolicy = const SmartTileTransformPolicy(), final  List<SmartTileRule> rules = const <SmartTileRule>[], this.fallbackRuleId, final  List<String> tags = const <String>[], this.sortOrder = 0, this.seedSalt = 0}): assert(id != "", 'id must not be blank'),assert(targetPresetId != "", 'targetPresetId must not be blank'),assert(name != "", 'name must not be blank'),_sourceTilesetIds = sourceTilesetIds,_atlases = atlases,_materials = materials,_animations = animations,_allowedMaterialIds = allowedMaterialIds,_rules = rules,_tags = tags;
  factory _ProjectSmartTileAuthoringDraft.fromJson(Map<String, dynamic> json) => _$ProjectSmartTileAuthoringDraftFromJson(json);

@override final  String id;
@override final  String targetPresetId;
@override final  String? sourcePresetId;
@override final  String name;
@override@JsonKey() final  String categoryId;
@override final  SmartTileUsage usage;
@override final  SmartTileAuthoringStage lastStage;
@override final  String? guideId;
 final  List<String> _sourceTilesetIds;
@override@JsonKey() List<String> get sourceTilesetIds {
  if (_sourceTilesetIds is EqualUnmodifiableListView) return _sourceTilesetIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceTilesetIds);
}

 final  List<ProjectSmartTileAtlas> _atlases;
@override@JsonKey() List<ProjectSmartTileAtlas> get atlases {
  if (_atlases is EqualUnmodifiableListView) return _atlases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_atlases);
}

@override final  String? primaryAtlasId;
 final  List<ProjectSmartTileMaterial> _materials;
@override@JsonKey() List<ProjectSmartTileMaterial> get materials {
  if (_materials is EqualUnmodifiableListView) return _materials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_materials);
}

 final  List<ProjectSmartTileAnimation> _animations;
@override@JsonKey() List<ProjectSmartTileAnimation> get animations {
  if (_animations is EqualUnmodifiableListView) return _animations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_animations);
}

@override final  String? defaultMaterialId;
 final  List<String> _allowedMaterialIds;
@override@JsonKey() List<String> get allowedMaterialIds {
  if (_allowedMaterialIds is EqualUnmodifiableListView) return _allowedMaterialIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allowedMaterialIds);
}

@override@JsonKey() final  SmartTileTopology topology;
@override@JsonKey() final  SmartTileTemplateHint templateHint;
@override@JsonKey() final  SmartTileBoundaryPolicy boundaryPolicy;
@override@JsonKey() final  SmartTileCoveragePolicy coveragePolicy;
@override@JsonKey() final  SmartTileCoverageProfile coverageProfile;
@override@JsonKey() final  SmartTileTransformPolicy transformPolicy;
 final  List<SmartTileRule> _rules;
@override@JsonKey() List<SmartTileRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}

@override final  String? fallbackRuleId;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  int sortOrder;
@override@JsonKey() final  int seedSalt;

/// Create a copy of ProjectSmartTileAuthoringDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSmartTileAuthoringDraftCopyWith<_ProjectSmartTileAuthoringDraft> get copyWith => __$ProjectSmartTileAuthoringDraftCopyWithImpl<_ProjectSmartTileAuthoringDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSmartTileAuthoringDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSmartTileAuthoringDraft&&(identical(other.id, id) || other.id == id)&&(identical(other.targetPresetId, targetPresetId) || other.targetPresetId == targetPresetId)&&(identical(other.sourcePresetId, sourcePresetId) || other.sourcePresetId == sourcePresetId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.lastStage, lastStage) || other.lastStage == lastStage)&&(identical(other.guideId, guideId) || other.guideId == guideId)&&const DeepCollectionEquality().equals(other._sourceTilesetIds, _sourceTilesetIds)&&const DeepCollectionEquality().equals(other._atlases, _atlases)&&(identical(other.primaryAtlasId, primaryAtlasId) || other.primaryAtlasId == primaryAtlasId)&&const DeepCollectionEquality().equals(other._materials, _materials)&&const DeepCollectionEquality().equals(other._animations, _animations)&&(identical(other.defaultMaterialId, defaultMaterialId) || other.defaultMaterialId == defaultMaterialId)&&const DeepCollectionEquality().equals(other._allowedMaterialIds, _allowedMaterialIds)&&(identical(other.topology, topology) || other.topology == topology)&&(identical(other.templateHint, templateHint) || other.templateHint == templateHint)&&(identical(other.boundaryPolicy, boundaryPolicy) || other.boundaryPolicy == boundaryPolicy)&&(identical(other.coveragePolicy, coveragePolicy) || other.coveragePolicy == coveragePolicy)&&(identical(other.coverageProfile, coverageProfile) || other.coverageProfile == coverageProfile)&&(identical(other.transformPolicy, transformPolicy) || other.transformPolicy == transformPolicy)&&const DeepCollectionEquality().equals(other._rules, _rules)&&(identical(other.fallbackRuleId, fallbackRuleId) || other.fallbackRuleId == fallbackRuleId)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.seedSalt, seedSalt) || other.seedSalt == seedSalt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,targetPresetId,sourcePresetId,name,categoryId,usage,lastStage,guideId,const DeepCollectionEquality().hash(_sourceTilesetIds),const DeepCollectionEquality().hash(_atlases),primaryAtlasId,const DeepCollectionEquality().hash(_materials),const DeepCollectionEquality().hash(_animations),defaultMaterialId,const DeepCollectionEquality().hash(_allowedMaterialIds),topology,templateHint,boundaryPolicy,coveragePolicy,coverageProfile,transformPolicy,const DeepCollectionEquality().hash(_rules),fallbackRuleId,const DeepCollectionEquality().hash(_tags),sortOrder,seedSalt]);

@override
String toString() {
  return 'ProjectSmartTileAuthoringDraft(id: $id, targetPresetId: $targetPresetId, sourcePresetId: $sourcePresetId, name: $name, categoryId: $categoryId, usage: $usage, lastStage: $lastStage, guideId: $guideId, sourceTilesetIds: $sourceTilesetIds, atlases: $atlases, primaryAtlasId: $primaryAtlasId, materials: $materials, animations: $animations, defaultMaterialId: $defaultMaterialId, allowedMaterialIds: $allowedMaterialIds, topology: $topology, templateHint: $templateHint, boundaryPolicy: $boundaryPolicy, coveragePolicy: $coveragePolicy, coverageProfile: $coverageProfile, transformPolicy: $transformPolicy, rules: $rules, fallbackRuleId: $fallbackRuleId, tags: $tags, sortOrder: $sortOrder, seedSalt: $seedSalt)';
}


}

/// @nodoc
abstract mixin class _$ProjectSmartTileAuthoringDraftCopyWith<$Res> implements $ProjectSmartTileAuthoringDraftCopyWith<$Res> {
  factory _$ProjectSmartTileAuthoringDraftCopyWith(_ProjectSmartTileAuthoringDraft value, $Res Function(_ProjectSmartTileAuthoringDraft) _then) = __$ProjectSmartTileAuthoringDraftCopyWithImpl;
@override @useResult
$Res call({
 String id, String targetPresetId, String? sourcePresetId, String name, String categoryId, SmartTileUsage usage, SmartTileAuthoringStage lastStage, String? guideId, List<String> sourceTilesetIds, List<ProjectSmartTileAtlas> atlases, String? primaryAtlasId, List<ProjectSmartTileMaterial> materials, List<ProjectSmartTileAnimation> animations, String? defaultMaterialId, List<String> allowedMaterialIds, SmartTileTopology topology, SmartTileTemplateHint templateHint, SmartTileBoundaryPolicy boundaryPolicy, SmartTileCoveragePolicy coveragePolicy, SmartTileCoverageProfile coverageProfile, SmartTileTransformPolicy transformPolicy, List<SmartTileRule> rules, String? fallbackRuleId, List<String> tags, int sortOrder, int seedSalt
});


@override $SmartTileCoverageProfileCopyWith<$Res> get coverageProfile;@override $SmartTileTransformPolicyCopyWith<$Res> get transformPolicy;

}
/// @nodoc
class __$ProjectSmartTileAuthoringDraftCopyWithImpl<$Res>
    implements _$ProjectSmartTileAuthoringDraftCopyWith<$Res> {
  __$ProjectSmartTileAuthoringDraftCopyWithImpl(this._self, this._then);

  final _ProjectSmartTileAuthoringDraft _self;
  final $Res Function(_ProjectSmartTileAuthoringDraft) _then;

/// Create a copy of ProjectSmartTileAuthoringDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? targetPresetId = null,Object? sourcePresetId = freezed,Object? name = null,Object? categoryId = null,Object? usage = null,Object? lastStage = null,Object? guideId = freezed,Object? sourceTilesetIds = null,Object? atlases = null,Object? primaryAtlasId = freezed,Object? materials = null,Object? animations = null,Object? defaultMaterialId = freezed,Object? allowedMaterialIds = null,Object? topology = null,Object? templateHint = null,Object? boundaryPolicy = null,Object? coveragePolicy = null,Object? coverageProfile = null,Object? transformPolicy = null,Object? rules = null,Object? fallbackRuleId = freezed,Object? tags = null,Object? sortOrder = null,Object? seedSalt = null,}) {
  return _then(_ProjectSmartTileAuthoringDraft(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetPresetId: null == targetPresetId ? _self.targetPresetId : targetPresetId // ignore: cast_nullable_to_non_nullable
as String,sourcePresetId: freezed == sourcePresetId ? _self.sourcePresetId : sourcePresetId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as SmartTileUsage,lastStage: null == lastStage ? _self.lastStage : lastStage // ignore: cast_nullable_to_non_nullable
as SmartTileAuthoringStage,guideId: freezed == guideId ? _self.guideId : guideId // ignore: cast_nullable_to_non_nullable
as String?,sourceTilesetIds: null == sourceTilesetIds ? _self._sourceTilesetIds : sourceTilesetIds // ignore: cast_nullable_to_non_nullable
as List<String>,atlases: null == atlases ? _self._atlases : atlases // ignore: cast_nullable_to_non_nullable
as List<ProjectSmartTileAtlas>,primaryAtlasId: freezed == primaryAtlasId ? _self.primaryAtlasId : primaryAtlasId // ignore: cast_nullable_to_non_nullable
as String?,materials: null == materials ? _self._materials : materials // ignore: cast_nullable_to_non_nullable
as List<ProjectSmartTileMaterial>,animations: null == animations ? _self._animations : animations // ignore: cast_nullable_to_non_nullable
as List<ProjectSmartTileAnimation>,defaultMaterialId: freezed == defaultMaterialId ? _self.defaultMaterialId : defaultMaterialId // ignore: cast_nullable_to_non_nullable
as String?,allowedMaterialIds: null == allowedMaterialIds ? _self._allowedMaterialIds : allowedMaterialIds // ignore: cast_nullable_to_non_nullable
as List<String>,topology: null == topology ? _self.topology : topology // ignore: cast_nullable_to_non_nullable
as SmartTileTopology,templateHint: null == templateHint ? _self.templateHint : templateHint // ignore: cast_nullable_to_non_nullable
as SmartTileTemplateHint,boundaryPolicy: null == boundaryPolicy ? _self.boundaryPolicy : boundaryPolicy // ignore: cast_nullable_to_non_nullable
as SmartTileBoundaryPolicy,coveragePolicy: null == coveragePolicy ? _self.coveragePolicy : coveragePolicy // ignore: cast_nullable_to_non_nullable
as SmartTileCoveragePolicy,coverageProfile: null == coverageProfile ? _self.coverageProfile : coverageProfile // ignore: cast_nullable_to_non_nullable
as SmartTileCoverageProfile,transformPolicy: null == transformPolicy ? _self.transformPolicy : transformPolicy // ignore: cast_nullable_to_non_nullable
as SmartTileTransformPolicy,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<SmartTileRule>,fallbackRuleId: freezed == fallbackRuleId ? _self.fallbackRuleId : fallbackRuleId // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,seedSalt: null == seedSalt ? _self.seedSalt : seedSalt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ProjectSmartTileAuthoringDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileCoverageProfileCopyWith<$Res> get coverageProfile {

  return $SmartTileCoverageProfileCopyWith<$Res>(_self.coverageProfile, (value) {
    return _then(_self.copyWith(coverageProfile: value));
  });
}/// Create a copy of ProjectSmartTileAuthoringDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileTransformPolicyCopyWith<$Res> get transformPolicy {

  return $SmartTileTransformPolicyCopyWith<$Res>(_self.transformPolicy, (value) {
    return _then(_self.copyWith(transformPolicy: value));
  });
}
}

// dart format on
