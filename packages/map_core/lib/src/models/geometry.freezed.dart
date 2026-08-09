// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geometry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GridPos {

 int get x; int get y;
/// Create a copy of GridPos
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GridPosCopyWith<GridPos> get copyWith => _$GridPosCopyWithImpl<GridPos>(this as GridPos, _$identity);

  /// Serializes this GridPos to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GridPos&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'GridPos(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $GridPosCopyWith<$Res>  {
  factory $GridPosCopyWith(GridPos value, $Res Function(GridPos) _then) = _$GridPosCopyWithImpl;
@useResult
$Res call({
 int x, int y
});




}
/// @nodoc
class _$GridPosCopyWithImpl<$Res>
    implements $GridPosCopyWith<$Res> {
  _$GridPosCopyWithImpl(this._self, this._then);

  final GridPos _self;
  final $Res Function(GridPos) _then;

/// Create a copy of GridPos
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GridPos].
extension GridPosPatterns on GridPos {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GridPos value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GridPos() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GridPos value)  $default,){
final _that = this;
switch (_that) {
case _GridPos():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GridPos value)?  $default,){
final _that = this;
switch (_that) {
case _GridPos() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int x,  int y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GridPos() when $default != null:
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y)  $default,) {final _that = this;
switch (_that) {
case _GridPos():
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int x,  int y)?  $default,) {final _that = this;
switch (_that) {
case _GridPos() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GridPos implements GridPos {
  const _GridPos({required this.x, required this.y});
  factory _GridPos.fromJson(Map<String, dynamic> json) => _$GridPosFromJson(json);

@override final  int x;
@override final  int y;

/// Create a copy of GridPos
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GridPosCopyWith<_GridPos> get copyWith => __$GridPosCopyWithImpl<_GridPos>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GridPosToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GridPos&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'GridPos(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$GridPosCopyWith<$Res> implements $GridPosCopyWith<$Res> {
  factory _$GridPosCopyWith(_GridPos value, $Res Function(_GridPos) _then) = __$GridPosCopyWithImpl;
@override @useResult
$Res call({
 int x, int y
});




}
/// @nodoc
class __$GridPosCopyWithImpl<$Res>
    implements _$GridPosCopyWith<$Res> {
  __$GridPosCopyWithImpl(this._self, this._then);

  final _GridPos _self;
  final $Res Function(_GridPos) _then;

/// Create a copy of GridPos
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_GridPos(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GridSize {

 int get width; int get height;
/// Create a copy of GridSize
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GridSizeCopyWith<GridSize> get copyWith => _$GridSizeCopyWithImpl<GridSize>(this as GridSize, _$identity);

  /// Serializes this GridSize to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GridSize&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height);

@override
String toString() {
  return 'GridSize(width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $GridSizeCopyWith<$Res>  {
  factory $GridSizeCopyWith(GridSize value, $Res Function(GridSize) _then) = _$GridSizeCopyWithImpl;
@useResult
$Res call({
 int width, int height
});




}
/// @nodoc
class _$GridSizeCopyWithImpl<$Res>
    implements $GridSizeCopyWith<$Res> {
  _$GridSizeCopyWithImpl(this._self, this._then);

  final GridSize _self;
  final $Res Function(GridSize) _then;

/// Create a copy of GridSize
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GridSize].
extension GridSizePatterns on GridSize {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GridSize value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GridSize() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GridSize value)  $default,){
final _that = this;
switch (_that) {
case _GridSize():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GridSize value)?  $default,){
final _that = this;
switch (_that) {
case _GridSize() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GridSize() when $default != null:
return $default(_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _GridSize():
return $default(_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _GridSize() when $default != null:
return $default(_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GridSize implements GridSize {
  const _GridSize({required this.width, required this.height});
  factory _GridSize.fromJson(Map<String, dynamic> json) => _$GridSizeFromJson(json);

@override final  int width;
@override final  int height;

/// Create a copy of GridSize
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GridSizeCopyWith<_GridSize> get copyWith => __$GridSizeCopyWithImpl<_GridSize>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GridSizeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GridSize&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height);

@override
String toString() {
  return 'GridSize(width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$GridSizeCopyWith<$Res> implements $GridSizeCopyWith<$Res> {
  factory _$GridSizeCopyWith(_GridSize value, $Res Function(_GridSize) _then) = __$GridSizeCopyWithImpl;
@override @useResult
$Res call({
 int width, int height
});




}
/// @nodoc
class __$GridSizeCopyWithImpl<$Res>
    implements _$GridSizeCopyWith<$Res> {
  __$GridSizeCopyWithImpl(this._self, this._then);

  final _GridSize _self;
  final $Res Function(_GridSize) _then;

/// Create a copy of GridSize
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? width = null,Object? height = null,}) {
  return _then(_GridSize(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MapRect {

 GridPos get pos; GridSize get size;
/// Create a copy of MapRect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapRectCopyWith<MapRect> get copyWith => _$MapRectCopyWithImpl<MapRect>(this as MapRect, _$identity);

  /// Serializes this MapRect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapRect&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pos,size);

@override
String toString() {
  return 'MapRect(pos: $pos, size: $size)';
}


}

/// @nodoc
abstract mixin class $MapRectCopyWith<$Res>  {
  factory $MapRectCopyWith(MapRect value, $Res Function(MapRect) _then) = _$MapRectCopyWithImpl;
@useResult
$Res call({
 GridPos pos, GridSize size
});


$GridPosCopyWith<$Res> get pos;$GridSizeCopyWith<$Res> get size;

}
/// @nodoc
class _$MapRectCopyWithImpl<$Res>
    implements $MapRectCopyWith<$Res> {
  _$MapRectCopyWithImpl(this._self, this._then);

  final MapRect _self;
  final $Res Function(MapRect) _then;

/// Create a copy of MapRect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pos = null,Object? size = null,}) {
  return _then(_self.copyWith(
pos: null == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as GridPos,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as GridSize,
  ));
}
/// Create a copy of MapRect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get pos {

  return $GridPosCopyWith<$Res>(_self.pos, (value) {
    return _then(_self.copyWith(pos: value));
  });
}/// Create a copy of MapRect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridSizeCopyWith<$Res> get size {

  return $GridSizeCopyWith<$Res>(_self.size, (value) {
    return _then(_self.copyWith(size: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapRect].
extension MapRectPatterns on MapRect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapRect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapRect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapRect value)  $default,){
final _that = this;
switch (_that) {
case _MapRect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapRect value)?  $default,){
final _that = this;
switch (_that) {
case _MapRect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GridPos pos,  GridSize size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapRect() when $default != null:
return $default(_that.pos,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GridPos pos,  GridSize size)  $default,) {final _that = this;
switch (_that) {
case _MapRect():
return $default(_that.pos,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GridPos pos,  GridSize size)?  $default,) {final _that = this;
switch (_that) {
case _MapRect() when $default != null:
return $default(_that.pos,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MapRect implements MapRect {
  const _MapRect({required this.pos, required this.size});
  factory _MapRect.fromJson(Map<String, dynamic> json) => _$MapRectFromJson(json);

@override final  GridPos pos;
@override final  GridSize size;

/// Create a copy of MapRect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapRectCopyWith<_MapRect> get copyWith => __$MapRectCopyWithImpl<_MapRect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapRectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapRect&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pos,size);

@override
String toString() {
  return 'MapRect(pos: $pos, size: $size)';
}


}

/// @nodoc
abstract mixin class _$MapRectCopyWith<$Res> implements $MapRectCopyWith<$Res> {
  factory _$MapRectCopyWith(_MapRect value, $Res Function(_MapRect) _then) = __$MapRectCopyWithImpl;
@override @useResult
$Res call({
 GridPos pos, GridSize size
});


@override $GridPosCopyWith<$Res> get pos;@override $GridSizeCopyWith<$Res> get size;

}
/// @nodoc
class __$MapRectCopyWithImpl<$Res>
    implements _$MapRectCopyWith<$Res> {
  __$MapRectCopyWithImpl(this._self, this._then);

  final _MapRect _self;
  final $Res Function(_MapRect) _then;

/// Create a copy of MapRect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pos = null,Object? size = null,}) {
  return _then(_MapRect(
pos: null == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as GridPos,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as GridSize,
  ));
}

/// Create a copy of MapRect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get pos {

  return $GridPosCopyWith<$Res>(_self.pos, (value) {
    return _then(_self.copyWith(pos: value));
  });
}/// Create a copy of MapRect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridSizeCopyWith<$Res> get size {

  return $GridSizeCopyWith<$Res>(_self.size, (value) {
    return _then(_self.copyWith(size: value));
  });
}
}

// dart format on
