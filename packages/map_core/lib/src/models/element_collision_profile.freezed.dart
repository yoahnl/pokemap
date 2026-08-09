// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'element_collision_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ElementCollisionPixelMask {

 int get widthPx; int get heightPx; ElementCollisionMaskEncoding get encoding; String get dataBase64;
/// Create a copy of ElementCollisionPixelMask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementCollisionPixelMaskCopyWith<ElementCollisionPixelMask> get copyWith => _$ElementCollisionPixelMaskCopyWithImpl<ElementCollisionPixelMask>(this as ElementCollisionPixelMask, _$identity);

  /// Serializes this ElementCollisionPixelMask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementCollisionPixelMask&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.encoding, encoding) || other.encoding == encoding)&&(identical(other.dataBase64, dataBase64) || other.dataBase64 == dataBase64));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,widthPx,heightPx,encoding,dataBase64);

@override
String toString() {
  return 'ElementCollisionPixelMask(widthPx: $widthPx, heightPx: $heightPx, encoding: $encoding, dataBase64: $dataBase64)';
}


}

/// @nodoc
abstract mixin class $ElementCollisionPixelMaskCopyWith<$Res>  {
  factory $ElementCollisionPixelMaskCopyWith(ElementCollisionPixelMask value, $Res Function(ElementCollisionPixelMask) _then) = _$ElementCollisionPixelMaskCopyWithImpl;
@useResult
$Res call({
 int widthPx, int heightPx, ElementCollisionMaskEncoding encoding, String dataBase64
});




}
/// @nodoc
class _$ElementCollisionPixelMaskCopyWithImpl<$Res>
    implements $ElementCollisionPixelMaskCopyWith<$Res> {
  _$ElementCollisionPixelMaskCopyWithImpl(this._self, this._then);

  final ElementCollisionPixelMask _self;
  final $Res Function(ElementCollisionPixelMask) _then;

/// Create a copy of ElementCollisionPixelMask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? widthPx = null,Object? heightPx = null,Object? encoding = null,Object? dataBase64 = null,}) {
  return _then(_self.copyWith(
widthPx: null == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int,heightPx: null == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int,encoding: null == encoding ? _self.encoding : encoding // ignore: cast_nullable_to_non_nullable
as ElementCollisionMaskEncoding,dataBase64: null == dataBase64 ? _self.dataBase64 : dataBase64 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ElementCollisionPixelMask].
extension ElementCollisionPixelMaskPatterns on ElementCollisionPixelMask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ElementCollisionPixelMask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ElementCollisionPixelMask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ElementCollisionPixelMask value)  $default,){
final _that = this;
switch (_that) {
case _ElementCollisionPixelMask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ElementCollisionPixelMask value)?  $default,){
final _that = this;
switch (_that) {
case _ElementCollisionPixelMask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int widthPx,  int heightPx,  ElementCollisionMaskEncoding encoding,  String dataBase64)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ElementCollisionPixelMask() when $default != null:
return $default(_that.widthPx,_that.heightPx,_that.encoding,_that.dataBase64);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int widthPx,  int heightPx,  ElementCollisionMaskEncoding encoding,  String dataBase64)  $default,) {final _that = this;
switch (_that) {
case _ElementCollisionPixelMask():
return $default(_that.widthPx,_that.heightPx,_that.encoding,_that.dataBase64);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int widthPx,  int heightPx,  ElementCollisionMaskEncoding encoding,  String dataBase64)?  $default,) {final _that = this;
switch (_that) {
case _ElementCollisionPixelMask() when $default != null:
return $default(_that.widthPx,_that.heightPx,_that.encoding,_that.dataBase64);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ElementCollisionPixelMask implements ElementCollisionPixelMask {
  const _ElementCollisionPixelMask({required this.widthPx, required this.heightPx, this.encoding = ElementCollisionMaskEncoding.packedBitsV1, this.dataBase64 = ''});
  factory _ElementCollisionPixelMask.fromJson(Map<String, dynamic> json) => _$ElementCollisionPixelMaskFromJson(json);

@override final  int widthPx;
@override final  int heightPx;
@override@JsonKey() final  ElementCollisionMaskEncoding encoding;
@override@JsonKey() final  String dataBase64;

/// Create a copy of ElementCollisionPixelMask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ElementCollisionPixelMaskCopyWith<_ElementCollisionPixelMask> get copyWith => __$ElementCollisionPixelMaskCopyWithImpl<_ElementCollisionPixelMask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ElementCollisionPixelMaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ElementCollisionPixelMask&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.encoding, encoding) || other.encoding == encoding)&&(identical(other.dataBase64, dataBase64) || other.dataBase64 == dataBase64));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,widthPx,heightPx,encoding,dataBase64);

@override
String toString() {
  return 'ElementCollisionPixelMask(widthPx: $widthPx, heightPx: $heightPx, encoding: $encoding, dataBase64: $dataBase64)';
}


}

/// @nodoc
abstract mixin class _$ElementCollisionPixelMaskCopyWith<$Res> implements $ElementCollisionPixelMaskCopyWith<$Res> {
  factory _$ElementCollisionPixelMaskCopyWith(_ElementCollisionPixelMask value, $Res Function(_ElementCollisionPixelMask) _then) = __$ElementCollisionPixelMaskCopyWithImpl;
@override @useResult
$Res call({
 int widthPx, int heightPx, ElementCollisionMaskEncoding encoding, String dataBase64
});




}
/// @nodoc
class __$ElementCollisionPixelMaskCopyWithImpl<$Res>
    implements _$ElementCollisionPixelMaskCopyWith<$Res> {
  __$ElementCollisionPixelMaskCopyWithImpl(this._self, this._then);

  final _ElementCollisionPixelMask _self;
  final $Res Function(_ElementCollisionPixelMask) _then;

/// Create a copy of ElementCollisionPixelMask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? widthPx = null,Object? heightPx = null,Object? encoding = null,Object? dataBase64 = null,}) {
  return _then(_ElementCollisionPixelMask(
widthPx: null == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int,heightPx: null == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int,encoding: null == encoding ? _self.encoding : encoding // ignore: cast_nullable_to_non_nullable
as ElementCollisionMaskEncoding,dataBase64: null == dataBase64 ? _self.dataBase64 : dataBase64 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ElementCollisionProfile {

 ElementCollisionProfileSource get source; ElementCollisionPixelMask? get visualMask;@JsonKey(name: 'pixelMask') ElementCollisionPixelMask? get collisionMask; ElementCollisionPixelMask? get occlusionMask; WarpTriggerPadding get padding;// Authoring base when `source == manual`.
//
// This field is editor-facing only. It stores the main collision shape as
// authored by the user (for example a lasso/polygon around a building).
//
// Important product invariant:
// - when this manual shape exists, it is the primary collision base
// - padding stays available as a secondary helper only
// - runtime still ignores this field and consumes only `cells`
 List<GridPos> get shapeCells;// Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
 List<GridPos> get cells;// Authoring intent: cells explicitly added on top of the current primary
// base.
//
// That base is:
// - the padding-derived rectangle when `source == generated`
// - the author polygon/shape when `source == manual`
 List<GridPos> get manualAddedCells;// Authoring intent: cells explicitly removed from the current primary base.
// Runtime ignores this field; the editor folds it into `cells` before
// save/use.
 List<GridPos> get manualRemovedCells;
/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementCollisionProfileCopyWith<ElementCollisionProfile> get copyWith => _$ElementCollisionProfileCopyWithImpl<ElementCollisionProfile>(this as ElementCollisionProfile, _$identity);

  /// Serializes this ElementCollisionProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementCollisionProfile&&(identical(other.source, source) || other.source == source)&&(identical(other.visualMask, visualMask) || other.visualMask == visualMask)&&(identical(other.collisionMask, collisionMask) || other.collisionMask == collisionMask)&&(identical(other.occlusionMask, occlusionMask) || other.occlusionMask == occlusionMask)&&(identical(other.padding, padding) || other.padding == padding)&&const DeepCollectionEquality().equals(other.shapeCells, shapeCells)&&const DeepCollectionEquality().equals(other.cells, cells)&&const DeepCollectionEquality().equals(other.manualAddedCells, manualAddedCells)&&const DeepCollectionEquality().equals(other.manualRemovedCells, manualRemovedCells));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,visualMask,collisionMask,occlusionMask,padding,const DeepCollectionEquality().hash(shapeCells),const DeepCollectionEquality().hash(cells),const DeepCollectionEquality().hash(manualAddedCells),const DeepCollectionEquality().hash(manualRemovedCells));

@override
String toString() {
  return 'ElementCollisionProfile(source: $source, visualMask: $visualMask, collisionMask: $collisionMask, occlusionMask: $occlusionMask, padding: $padding, shapeCells: $shapeCells, cells: $cells, manualAddedCells: $manualAddedCells, manualRemovedCells: $manualRemovedCells)';
}


}

/// @nodoc
abstract mixin class $ElementCollisionProfileCopyWith<$Res>  {
  factory $ElementCollisionProfileCopyWith(ElementCollisionProfile value, $Res Function(ElementCollisionProfile) _then) = _$ElementCollisionProfileCopyWithImpl;
@useResult
$Res call({
 ElementCollisionProfileSource source, ElementCollisionPixelMask? visualMask,@JsonKey(name: 'pixelMask') ElementCollisionPixelMask? collisionMask, ElementCollisionPixelMask? occlusionMask, WarpTriggerPadding padding, List<GridPos> shapeCells, List<GridPos> cells, List<GridPos> manualAddedCells, List<GridPos> manualRemovedCells
});


$ElementCollisionPixelMaskCopyWith<$Res>? get visualMask;$ElementCollisionPixelMaskCopyWith<$Res>? get collisionMask;$ElementCollisionPixelMaskCopyWith<$Res>? get occlusionMask;$WarpTriggerPaddingCopyWith<$Res> get padding;

}
/// @nodoc
class _$ElementCollisionProfileCopyWithImpl<$Res>
    implements $ElementCollisionProfileCopyWith<$Res> {
  _$ElementCollisionProfileCopyWithImpl(this._self, this._then);

  final ElementCollisionProfile _self;
  final $Res Function(ElementCollisionProfile) _then;

/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? visualMask = freezed,Object? collisionMask = freezed,Object? occlusionMask = freezed,Object? padding = null,Object? shapeCells = null,Object? cells = null,Object? manualAddedCells = null,Object? manualRemovedCells = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ElementCollisionProfileSource,visualMask: freezed == visualMask ? _self.visualMask : visualMask // ignore: cast_nullable_to_non_nullable
as ElementCollisionPixelMask?,collisionMask: freezed == collisionMask ? _self.collisionMask : collisionMask // ignore: cast_nullable_to_non_nullable
as ElementCollisionPixelMask?,occlusionMask: freezed == occlusionMask ? _self.occlusionMask : occlusionMask // ignore: cast_nullable_to_non_nullable
as ElementCollisionPixelMask?,padding: null == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as WarpTriggerPadding,shapeCells: null == shapeCells ? _self.shapeCells : shapeCells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,cells: null == cells ? _self.cells : cells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,manualAddedCells: null == manualAddedCells ? _self.manualAddedCells : manualAddedCells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,manualRemovedCells: null == manualRemovedCells ? _self.manualRemovedCells : manualRemovedCells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,
  ));
}
/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementCollisionPixelMaskCopyWith<$Res>? get visualMask {
    if (_self.visualMask == null) {
    return null;
  }

  return $ElementCollisionPixelMaskCopyWith<$Res>(_self.visualMask!, (value) {
    return _then(_self.copyWith(visualMask: value));
  });
}/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementCollisionPixelMaskCopyWith<$Res>? get collisionMask {
    if (_self.collisionMask == null) {
    return null;
  }

  return $ElementCollisionPixelMaskCopyWith<$Res>(_self.collisionMask!, (value) {
    return _then(_self.copyWith(collisionMask: value));
  });
}/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementCollisionPixelMaskCopyWith<$Res>? get occlusionMask {
    if (_self.occlusionMask == null) {
    return null;
  }

  return $ElementCollisionPixelMaskCopyWith<$Res>(_self.occlusionMask!, (value) {
    return _then(_self.copyWith(occlusionMask: value));
  });
}/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarpTriggerPaddingCopyWith<$Res> get padding {

  return $WarpTriggerPaddingCopyWith<$Res>(_self.padding, (value) {
    return _then(_self.copyWith(padding: value));
  });
}
}


/// Adds pattern-matching-related methods to [ElementCollisionProfile].
extension ElementCollisionProfilePatterns on ElementCollisionProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ElementCollisionProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ElementCollisionProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ElementCollisionProfile value)  $default,){
final _that = this;
switch (_that) {
case _ElementCollisionProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ElementCollisionProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ElementCollisionProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ElementCollisionProfileSource source,  ElementCollisionPixelMask? visualMask, @JsonKey(name: 'pixelMask')  ElementCollisionPixelMask? collisionMask,  ElementCollisionPixelMask? occlusionMask,  WarpTriggerPadding padding,  List<GridPos> shapeCells,  List<GridPos> cells,  List<GridPos> manualAddedCells,  List<GridPos> manualRemovedCells)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ElementCollisionProfile() when $default != null:
return $default(_that.source,_that.visualMask,_that.collisionMask,_that.occlusionMask,_that.padding,_that.shapeCells,_that.cells,_that.manualAddedCells,_that.manualRemovedCells);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ElementCollisionProfileSource source,  ElementCollisionPixelMask? visualMask, @JsonKey(name: 'pixelMask')  ElementCollisionPixelMask? collisionMask,  ElementCollisionPixelMask? occlusionMask,  WarpTriggerPadding padding,  List<GridPos> shapeCells,  List<GridPos> cells,  List<GridPos> manualAddedCells,  List<GridPos> manualRemovedCells)  $default,) {final _that = this;
switch (_that) {
case _ElementCollisionProfile():
return $default(_that.source,_that.visualMask,_that.collisionMask,_that.occlusionMask,_that.padding,_that.shapeCells,_that.cells,_that.manualAddedCells,_that.manualRemovedCells);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ElementCollisionProfileSource source,  ElementCollisionPixelMask? visualMask, @JsonKey(name: 'pixelMask')  ElementCollisionPixelMask? collisionMask,  ElementCollisionPixelMask? occlusionMask,  WarpTriggerPadding padding,  List<GridPos> shapeCells,  List<GridPos> cells,  List<GridPos> manualAddedCells,  List<GridPos> manualRemovedCells)?  $default,) {final _that = this;
switch (_that) {
case _ElementCollisionProfile() when $default != null:
return $default(_that.source,_that.visualMask,_that.collisionMask,_that.occlusionMask,_that.padding,_that.shapeCells,_that.cells,_that.manualAddedCells,_that.manualRemovedCells);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ElementCollisionProfile implements ElementCollisionProfile {
  const _ElementCollisionProfile({this.source = ElementCollisionProfileSource.generated, this.visualMask, @JsonKey(name: 'pixelMask') this.collisionMask, this.occlusionMask, this.padding = const WarpTriggerPadding(), final  List<GridPos> shapeCells = const [], final  List<GridPos> cells = const [], final  List<GridPos> manualAddedCells = const [], final  List<GridPos> manualRemovedCells = const []}): _shapeCells = shapeCells,_cells = cells,_manualAddedCells = manualAddedCells,_manualRemovedCells = manualRemovedCells;
  factory _ElementCollisionProfile.fromJson(Map<String, dynamic> json) => _$ElementCollisionProfileFromJson(json);

@override@JsonKey() final  ElementCollisionProfileSource source;
@override final  ElementCollisionPixelMask? visualMask;
@override@JsonKey(name: 'pixelMask') final  ElementCollisionPixelMask? collisionMask;
@override final  ElementCollisionPixelMask? occlusionMask;
@override@JsonKey() final  WarpTriggerPadding padding;
// Authoring base when `source == manual`.
//
// This field is editor-facing only. It stores the main collision shape as
// authored by the user (for example a lasso/polygon around a building).
//
// Important product invariant:
// - when this manual shape exists, it is the primary collision base
// - padding stays available as a secondary helper only
// - runtime still ignores this field and consumes only `cells`
 final  List<GridPos> _shapeCells;
// Authoring base when `source == manual`.
//
// This field is editor-facing only. It stores the main collision shape as
// authored by the user (for example a lasso/polygon around a building).
//
// Important product invariant:
// - when this manual shape exists, it is the primary collision base
// - padding stays available as a secondary helper only
// - runtime still ignores this field and consumes only `cells`
@override@JsonKey() List<GridPos> get shapeCells {
  if (_shapeCells is EqualUnmodifiableListView) return _shapeCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shapeCells);
}

// Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
 final  List<GridPos> _cells;
// Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
@override@JsonKey() List<GridPos> get cells {
  if (_cells is EqualUnmodifiableListView) return _cells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cells);
}

// Authoring intent: cells explicitly added on top of the current primary
// base.
//
// That base is:
// - the padding-derived rectangle when `source == generated`
// - the author polygon/shape when `source == manual`
 final  List<GridPos> _manualAddedCells;
// Authoring intent: cells explicitly added on top of the current primary
// base.
//
// That base is:
// - the padding-derived rectangle when `source == generated`
// - the author polygon/shape when `source == manual`
@override@JsonKey() List<GridPos> get manualAddedCells {
  if (_manualAddedCells is EqualUnmodifiableListView) return _manualAddedCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_manualAddedCells);
}

// Authoring intent: cells explicitly removed from the current primary base.
// Runtime ignores this field; the editor folds it into `cells` before
// save/use.
 final  List<GridPos> _manualRemovedCells;
// Authoring intent: cells explicitly removed from the current primary base.
// Runtime ignores this field; the editor folds it into `cells` before
// save/use.
@override@JsonKey() List<GridPos> get manualRemovedCells {
  if (_manualRemovedCells is EqualUnmodifiableListView) return _manualRemovedCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_manualRemovedCells);
}


/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ElementCollisionProfileCopyWith<_ElementCollisionProfile> get copyWith => __$ElementCollisionProfileCopyWithImpl<_ElementCollisionProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ElementCollisionProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ElementCollisionProfile&&(identical(other.source, source) || other.source == source)&&(identical(other.visualMask, visualMask) || other.visualMask == visualMask)&&(identical(other.collisionMask, collisionMask) || other.collisionMask == collisionMask)&&(identical(other.occlusionMask, occlusionMask) || other.occlusionMask == occlusionMask)&&(identical(other.padding, padding) || other.padding == padding)&&const DeepCollectionEquality().equals(other._shapeCells, _shapeCells)&&const DeepCollectionEquality().equals(other._cells, _cells)&&const DeepCollectionEquality().equals(other._manualAddedCells, _manualAddedCells)&&const DeepCollectionEquality().equals(other._manualRemovedCells, _manualRemovedCells));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,visualMask,collisionMask,occlusionMask,padding,const DeepCollectionEquality().hash(_shapeCells),const DeepCollectionEquality().hash(_cells),const DeepCollectionEquality().hash(_manualAddedCells),const DeepCollectionEquality().hash(_manualRemovedCells));

@override
String toString() {
  return 'ElementCollisionProfile(source: $source, visualMask: $visualMask, collisionMask: $collisionMask, occlusionMask: $occlusionMask, padding: $padding, shapeCells: $shapeCells, cells: $cells, manualAddedCells: $manualAddedCells, manualRemovedCells: $manualRemovedCells)';
}


}

/// @nodoc
abstract mixin class _$ElementCollisionProfileCopyWith<$Res> implements $ElementCollisionProfileCopyWith<$Res> {
  factory _$ElementCollisionProfileCopyWith(_ElementCollisionProfile value, $Res Function(_ElementCollisionProfile) _then) = __$ElementCollisionProfileCopyWithImpl;
@override @useResult
$Res call({
 ElementCollisionProfileSource source, ElementCollisionPixelMask? visualMask,@JsonKey(name: 'pixelMask') ElementCollisionPixelMask? collisionMask, ElementCollisionPixelMask? occlusionMask, WarpTriggerPadding padding, List<GridPos> shapeCells, List<GridPos> cells, List<GridPos> manualAddedCells, List<GridPos> manualRemovedCells
});


@override $ElementCollisionPixelMaskCopyWith<$Res>? get visualMask;@override $ElementCollisionPixelMaskCopyWith<$Res>? get collisionMask;@override $ElementCollisionPixelMaskCopyWith<$Res>? get occlusionMask;@override $WarpTriggerPaddingCopyWith<$Res> get padding;

}
/// @nodoc
class __$ElementCollisionProfileCopyWithImpl<$Res>
    implements _$ElementCollisionProfileCopyWith<$Res> {
  __$ElementCollisionProfileCopyWithImpl(this._self, this._then);

  final _ElementCollisionProfile _self;
  final $Res Function(_ElementCollisionProfile) _then;

/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? visualMask = freezed,Object? collisionMask = freezed,Object? occlusionMask = freezed,Object? padding = null,Object? shapeCells = null,Object? cells = null,Object? manualAddedCells = null,Object? manualRemovedCells = null,}) {
  return _then(_ElementCollisionProfile(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ElementCollisionProfileSource,visualMask: freezed == visualMask ? _self.visualMask : visualMask // ignore: cast_nullable_to_non_nullable
as ElementCollisionPixelMask?,collisionMask: freezed == collisionMask ? _self.collisionMask : collisionMask // ignore: cast_nullable_to_non_nullable
as ElementCollisionPixelMask?,occlusionMask: freezed == occlusionMask ? _self.occlusionMask : occlusionMask // ignore: cast_nullable_to_non_nullable
as ElementCollisionPixelMask?,padding: null == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as WarpTriggerPadding,shapeCells: null == shapeCells ? _self._shapeCells : shapeCells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,cells: null == cells ? _self._cells : cells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,manualAddedCells: null == manualAddedCells ? _self._manualAddedCells : manualAddedCells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,manualRemovedCells: null == manualRemovedCells ? _self._manualRemovedCells : manualRemovedCells // ignore: cast_nullable_to_non_nullable
as List<GridPos>,
  ));
}

/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementCollisionPixelMaskCopyWith<$Res>? get visualMask {
    if (_self.visualMask == null) {
    return null;
  }

  return $ElementCollisionPixelMaskCopyWith<$Res>(_self.visualMask!, (value) {
    return _then(_self.copyWith(visualMask: value));
  });
}/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementCollisionPixelMaskCopyWith<$Res>? get collisionMask {
    if (_self.collisionMask == null) {
    return null;
  }

  return $ElementCollisionPixelMaskCopyWith<$Res>(_self.collisionMask!, (value) {
    return _then(_self.copyWith(collisionMask: value));
  });
}/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementCollisionPixelMaskCopyWith<$Res>? get occlusionMask {
    if (_self.occlusionMask == null) {
    return null;
  }

  return $ElementCollisionPixelMaskCopyWith<$Res>(_self.occlusionMask!, (value) {
    return _then(_self.copyWith(occlusionMask: value));
  });
}/// Create a copy of ElementCollisionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarpTriggerPaddingCopyWith<$Res> get padding {

  return $WarpTriggerPaddingCopyWith<$Res>(_self.padding, (value) {
    return _then(_self.copyWith(padding: value));
  });
}
}

// dart format on
