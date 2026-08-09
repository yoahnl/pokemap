// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_layer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TileLayerPaletteEntry {

 String get tilesetId; int get localTileId; SmartTileSpriteTransform get transform;
/// Create a copy of TileLayerPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TileLayerPaletteEntryCopyWith<TileLayerPaletteEntry> get copyWith => _$TileLayerPaletteEntryCopyWithImpl<TileLayerPaletteEntry>(this as TileLayerPaletteEntry, _$identity);

  /// Serializes this TileLayerPaletteEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TileLayerPaletteEntry&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.localTileId, localTileId) || other.localTileId == localTileId)&&(identical(other.transform, transform) || other.transform == transform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tilesetId,localTileId,transform);

@override
String toString() {
  return 'TileLayerPaletteEntry(tilesetId: $tilesetId, localTileId: $localTileId, transform: $transform)';
}


}

/// @nodoc
abstract mixin class $TileLayerPaletteEntryCopyWith<$Res>  {
  factory $TileLayerPaletteEntryCopyWith(TileLayerPaletteEntry value, $Res Function(TileLayerPaletteEntry) _then) = _$TileLayerPaletteEntryCopyWithImpl;
@useResult
$Res call({
 String tilesetId, int localTileId, SmartTileSpriteTransform transform
});


$SmartTileSpriteTransformCopyWith<$Res> get transform;

}
/// @nodoc
class _$TileLayerPaletteEntryCopyWithImpl<$Res>
    implements $TileLayerPaletteEntryCopyWith<$Res> {
  _$TileLayerPaletteEntryCopyWithImpl(this._self, this._then);

  final TileLayerPaletteEntry _self;
  final $Res Function(TileLayerPaletteEntry) _then;

/// Create a copy of TileLayerPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tilesetId = null,Object? localTileId = null,Object? transform = null,}) {
  return _then(_self.copyWith(
tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,localTileId: null == localTileId ? _self.localTileId : localTileId // ignore: cast_nullable_to_non_nullable
as int,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as SmartTileSpriteTransform,
  ));
}
/// Create a copy of TileLayerPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileSpriteTransformCopyWith<$Res> get transform {

  return $SmartTileSpriteTransformCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}


/// Adds pattern-matching-related methods to [TileLayerPaletteEntry].
extension TileLayerPaletteEntryPatterns on TileLayerPaletteEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TileLayerPaletteEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TileLayerPaletteEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TileLayerPaletteEntry value)  $default,){
final _that = this;
switch (_that) {
case _TileLayerPaletteEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TileLayerPaletteEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TileLayerPaletteEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tilesetId,  int localTileId,  SmartTileSpriteTransform transform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TileLayerPaletteEntry() when $default != null:
return $default(_that.tilesetId,_that.localTileId,_that.transform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tilesetId,  int localTileId,  SmartTileSpriteTransform transform)  $default,) {final _that = this;
switch (_that) {
case _TileLayerPaletteEntry():
return $default(_that.tilesetId,_that.localTileId,_that.transform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tilesetId,  int localTileId,  SmartTileSpriteTransform transform)?  $default,) {final _that = this;
switch (_that) {
case _TileLayerPaletteEntry() when $default != null:
return $default(_that.tilesetId,_that.localTileId,_that.transform);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _TileLayerPaletteEntry implements TileLayerPaletteEntry {
  const _TileLayerPaletteEntry({required this.tilesetId, required this.localTileId, this.transform = const SmartTileSpriteTransform()});
  factory _TileLayerPaletteEntry.fromJson(Map<String, dynamic> json) => _$TileLayerPaletteEntryFromJson(json);

@override final  String tilesetId;
@override final  int localTileId;
@override@JsonKey() final  SmartTileSpriteTransform transform;

/// Create a copy of TileLayerPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TileLayerPaletteEntryCopyWith<_TileLayerPaletteEntry> get copyWith => __$TileLayerPaletteEntryCopyWithImpl<_TileLayerPaletteEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TileLayerPaletteEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TileLayerPaletteEntry&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.localTileId, localTileId) || other.localTileId == localTileId)&&(identical(other.transform, transform) || other.transform == transform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tilesetId,localTileId,transform);

@override
String toString() {
  return 'TileLayerPaletteEntry(tilesetId: $tilesetId, localTileId: $localTileId, transform: $transform)';
}


}

/// @nodoc
abstract mixin class _$TileLayerPaletteEntryCopyWith<$Res> implements $TileLayerPaletteEntryCopyWith<$Res> {
  factory _$TileLayerPaletteEntryCopyWith(_TileLayerPaletteEntry value, $Res Function(_TileLayerPaletteEntry) _then) = __$TileLayerPaletteEntryCopyWithImpl;
@override @useResult
$Res call({
 String tilesetId, int localTileId, SmartTileSpriteTransform transform
});


@override $SmartTileSpriteTransformCopyWith<$Res> get transform;

}
/// @nodoc
class __$TileLayerPaletteEntryCopyWithImpl<$Res>
    implements _$TileLayerPaletteEntryCopyWith<$Res> {
  __$TileLayerPaletteEntryCopyWithImpl(this._self, this._then);

  final _TileLayerPaletteEntry _self;
  final $Res Function(_TileLayerPaletteEntry) _then;

/// Create a copy of TileLayerPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tilesetId = null,Object? localTileId = null,Object? transform = null,}) {
  return _then(_TileLayerPaletteEntry(
tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,localTileId: null == localTileId ? _self.localTileId : localTileId // ignore: cast_nullable_to_non_nullable
as int,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as SmartTileSpriteTransform,
  ));
}

/// Create a copy of TileLayerPaletteEntry
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
mixin _$MapPlacedTile {

 String get id; String get name; String get className; TileLayerPaletteEntry get tile; double get anchorX; double get anchorY; double get width; double get height; int get quarterTurns; bool get isVisible; double get opacity; Map<String, Object?> get importMetadata;
/// Create a copy of MapPlacedTile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapPlacedTileCopyWith<MapPlacedTile> get copyWith => _$MapPlacedTileCopyWithImpl<MapPlacedTile>(this as MapPlacedTile, _$identity);

  /// Serializes this MapPlacedTile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPlacedTile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.className, className) || other.className == className)&&(identical(other.tile, tile) || other.tile == tile)&&(identical(other.anchorX, anchorX) || other.anchorX == anchorX)&&(identical(other.anchorY, anchorY) || other.anchorY == anchorY)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.quarterTurns, quarterTurns) || other.quarterTurns == quarterTurns)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&const DeepCollectionEquality().equals(other.importMetadata, importMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,className,tile,anchorX,anchorY,width,height,quarterTurns,isVisible,opacity,const DeepCollectionEquality().hash(importMetadata));

@override
String toString() {
  return 'MapPlacedTile(id: $id, name: $name, className: $className, tile: $tile, anchorX: $anchorX, anchorY: $anchorY, width: $width, height: $height, quarterTurns: $quarterTurns, isVisible: $isVisible, opacity: $opacity, importMetadata: $importMetadata)';
}


}

/// @nodoc
abstract mixin class $MapPlacedTileCopyWith<$Res>  {
  factory $MapPlacedTileCopyWith(MapPlacedTile value, $Res Function(MapPlacedTile) _then) = _$MapPlacedTileCopyWithImpl;
@useResult
$Res call({
 String id, String name, String className, TileLayerPaletteEntry tile, double anchorX, double anchorY, double width, double height, int quarterTurns, bool isVisible, double opacity, Map<String, Object?> importMetadata
});


$TileLayerPaletteEntryCopyWith<$Res> get tile;

}
/// @nodoc
class _$MapPlacedTileCopyWithImpl<$Res>
    implements $MapPlacedTileCopyWith<$Res> {
  _$MapPlacedTileCopyWithImpl(this._self, this._then);

  final MapPlacedTile _self;
  final $Res Function(MapPlacedTile) _then;

/// Create a copy of MapPlacedTile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? className = null,Object? tile = null,Object? anchorX = null,Object? anchorY = null,Object? width = null,Object? height = null,Object? quarterTurns = null,Object? isVisible = null,Object? opacity = null,Object? importMetadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,tile: null == tile ? _self.tile : tile // ignore: cast_nullable_to_non_nullable
as TileLayerPaletteEntry,anchorX: null == anchorX ? _self.anchorX : anchorX // ignore: cast_nullable_to_non_nullable
as double,anchorY: null == anchorY ? _self.anchorY : anchorY // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,quarterTurns: null == quarterTurns ? _self.quarterTurns : quarterTurns // ignore: cast_nullable_to_non_nullable
as int,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,importMetadata: null == importMetadata ? _self.importMetadata : importMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of MapPlacedTile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TileLayerPaletteEntryCopyWith<$Res> get tile {

  return $TileLayerPaletteEntryCopyWith<$Res>(_self.tile, (value) {
    return _then(_self.copyWith(tile: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapPlacedTile].
extension MapPlacedTilePatterns on MapPlacedTile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapPlacedTile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapPlacedTile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapPlacedTile value)  $default,){
final _that = this;
switch (_that) {
case _MapPlacedTile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapPlacedTile value)?  $default,){
final _that = this;
switch (_that) {
case _MapPlacedTile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String className,  TileLayerPaletteEntry tile,  double anchorX,  double anchorY,  double width,  double height,  int quarterTurns,  bool isVisible,  double opacity,  Map<String, Object?> importMetadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapPlacedTile() when $default != null:
return $default(_that.id,_that.name,_that.className,_that.tile,_that.anchorX,_that.anchorY,_that.width,_that.height,_that.quarterTurns,_that.isVisible,_that.opacity,_that.importMetadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String className,  TileLayerPaletteEntry tile,  double anchorX,  double anchorY,  double width,  double height,  int quarterTurns,  bool isVisible,  double opacity,  Map<String, Object?> importMetadata)  $default,) {final _that = this;
switch (_that) {
case _MapPlacedTile():
return $default(_that.id,_that.name,_that.className,_that.tile,_that.anchorX,_that.anchorY,_that.width,_that.height,_that.quarterTurns,_that.isVisible,_that.opacity,_that.importMetadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String className,  TileLayerPaletteEntry tile,  double anchorX,  double anchorY,  double width,  double height,  int quarterTurns,  bool isVisible,  double opacity,  Map<String, Object?> importMetadata)?  $default,) {final _that = this;
switch (_that) {
case _MapPlacedTile() when $default != null:
return $default(_that.id,_that.name,_that.className,_that.tile,_that.anchorX,_that.anchorY,_that.width,_that.height,_that.quarterTurns,_that.isVisible,_that.opacity,_that.importMetadata);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapPlacedTile implements MapPlacedTile {
  const _MapPlacedTile({required this.id, this.name = '', this.className = '', required this.tile, required this.anchorX, required this.anchorY, required this.width, required this.height, this.quarterTurns = 0, this.isVisible = true, this.opacity = 1.0, final  Map<String, Object?> importMetadata = const <String, Object?>{}}): _importMetadata = importMetadata;
  factory _MapPlacedTile.fromJson(Map<String, dynamic> json) => _$MapPlacedTileFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String className;
@override final  TileLayerPaletteEntry tile;
@override final  double anchorX;
@override final  double anchorY;
@override final  double width;
@override final  double height;
@override@JsonKey() final  int quarterTurns;
@override@JsonKey() final  bool isVisible;
@override@JsonKey() final  double opacity;
 final  Map<String, Object?> _importMetadata;
@override@JsonKey() Map<String, Object?> get importMetadata {
  if (_importMetadata is EqualUnmodifiableMapView) return _importMetadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_importMetadata);
}


/// Create a copy of MapPlacedTile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapPlacedTileCopyWith<_MapPlacedTile> get copyWith => __$MapPlacedTileCopyWithImpl<_MapPlacedTile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapPlacedTileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapPlacedTile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.className, className) || other.className == className)&&(identical(other.tile, tile) || other.tile == tile)&&(identical(other.anchorX, anchorX) || other.anchorX == anchorX)&&(identical(other.anchorY, anchorY) || other.anchorY == anchorY)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.quarterTurns, quarterTurns) || other.quarterTurns == quarterTurns)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&const DeepCollectionEquality().equals(other._importMetadata, _importMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,className,tile,anchorX,anchorY,width,height,quarterTurns,isVisible,opacity,const DeepCollectionEquality().hash(_importMetadata));

@override
String toString() {
  return 'MapPlacedTile(id: $id, name: $name, className: $className, tile: $tile, anchorX: $anchorX, anchorY: $anchorY, width: $width, height: $height, quarterTurns: $quarterTurns, isVisible: $isVisible, opacity: $opacity, importMetadata: $importMetadata)';
}


}

/// @nodoc
abstract mixin class _$MapPlacedTileCopyWith<$Res> implements $MapPlacedTileCopyWith<$Res> {
  factory _$MapPlacedTileCopyWith(_MapPlacedTile value, $Res Function(_MapPlacedTile) _then) = __$MapPlacedTileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String className, TileLayerPaletteEntry tile, double anchorX, double anchorY, double width, double height, int quarterTurns, bool isVisible, double opacity, Map<String, Object?> importMetadata
});


@override $TileLayerPaletteEntryCopyWith<$Res> get tile;

}
/// @nodoc
class __$MapPlacedTileCopyWithImpl<$Res>
    implements _$MapPlacedTileCopyWith<$Res> {
  __$MapPlacedTileCopyWithImpl(this._self, this._then);

  final _MapPlacedTile _self;
  final $Res Function(_MapPlacedTile) _then;

/// Create a copy of MapPlacedTile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? className = null,Object? tile = null,Object? anchorX = null,Object? anchorY = null,Object? width = null,Object? height = null,Object? quarterTurns = null,Object? isVisible = null,Object? opacity = null,Object? importMetadata = null,}) {
  return _then(_MapPlacedTile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,tile: null == tile ? _self.tile : tile // ignore: cast_nullable_to_non_nullable
as TileLayerPaletteEntry,anchorX: null == anchorX ? _self.anchorX : anchorX // ignore: cast_nullable_to_non_nullable
as double,anchorY: null == anchorY ? _self.anchorY : anchorY // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,quarterTurns: null == quarterTurns ? _self.quarterTurns : quarterTurns // ignore: cast_nullable_to_non_nullable
as int,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,importMetadata: null == importMetadata ? _self._importMetadata : importMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

/// Create a copy of MapPlacedTile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TileLayerPaletteEntryCopyWith<$Res> get tile {

  return $TileLayerPaletteEntryCopyWith<$Res>(_self.tile, (value) {
    return _then(_self.copyWith(tile: value));
  });
}
}

MapLayer _$MapLayerFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'tile':
          return TileLayer.fromJson(
            json
          );
                case 'collision':
          return CollisionLayer.fromJson(
            json
          );
                case 'smart_tile':
          return SmartTileLayer.fromJson(
            json
          );
                case 'object':
          return ObjectLayer.fromJson(
            json
          );
                case 'environment':
          return EnvironmentLayer.fromJson(
            json
          );
                case 'border':
          return BorderLayer.fromJson(
            json
          );

          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'MapLayer',
  'Invalid union type "${json['runtimeType']}"!'
);
        }

}

/// @nodoc
mixin _$MapLayer {

 String get id; String get name; bool get isVisible; double get opacity;
/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapLayerCopyWith<MapLayer> get copyWith => _$MapLayerCopyWithImpl<MapLayer>(this as MapLayer, _$identity);

  /// Serializes this MapLayer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapLayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVisible,opacity);

@override
String toString() {
  return 'MapLayer(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class $MapLayerCopyWith<$Res>  {
  factory $MapLayerCopyWith(MapLayer value, $Res Function(MapLayer) _then) = _$MapLayerCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isVisible, double opacity
});




}
/// @nodoc
class _$MapLayerCopyWithImpl<$Res>
    implements $MapLayerCopyWith<$Res> {
  _$MapLayerCopyWithImpl(this._self, this._then);

  final MapLayer _self;
  final $Res Function(MapLayer) _then;

/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isVisible = null,Object? opacity = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MapLayer].
extension MapLayerPatterns on MapLayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TileLayer value)?  tile,TResult Function( CollisionLayer value)?  collision,TResult Function( SmartTileLayer value)?  smartTile,TResult Function( ObjectLayer value)?  object,TResult Function( EnvironmentLayer value)?  environment,TResult Function( BorderLayer value)?  border,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TileLayer() when tile != null:
return tile(_that);case CollisionLayer() when collision != null:
return collision(_that);case SmartTileLayer() when smartTile != null:
return smartTile(_that);case ObjectLayer() when object != null:
return object(_that);case EnvironmentLayer() when environment != null:
return environment(_that);case BorderLayer() when border != null:
return border(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TileLayer value)  tile,required TResult Function( CollisionLayer value)  collision,required TResult Function( SmartTileLayer value)  smartTile,required TResult Function( ObjectLayer value)  object,required TResult Function( EnvironmentLayer value)  environment,required TResult Function( BorderLayer value)  border,}){
final _that = this;
switch (_that) {
case TileLayer():
return tile(_that);case CollisionLayer():
return collision(_that);case SmartTileLayer():
return smartTile(_that);case ObjectLayer():
return object(_that);case EnvironmentLayer():
return environment(_that);case BorderLayer():
return border(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TileLayer value)?  tile,TResult? Function( CollisionLayer value)?  collision,TResult? Function( SmartTileLayer value)?  smartTile,TResult? Function( ObjectLayer value)?  object,TResult? Function( EnvironmentLayer value)?  environment,TResult? Function( BorderLayer value)?  border,}){
final _that = this;
switch (_that) {
case TileLayer() when tile != null:
return tile(_that);case CollisionLayer() when collision != null:
return collision(_that);case SmartTileLayer() when smartTile != null:
return smartTile(_that);case ObjectLayer() when object != null:
return object(_that);case EnvironmentLayer() when environment != null:
return environment(_that);case BorderLayer() when border != null:
return border(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name,  bool isVisible,  double opacity,  MapLayerPurpose purpose,  List<TileLayerPaletteEntry> palette,  List<int> cells)?  tile,TResult Function( String id,  String name,  bool isVisible,  double opacity,  List<bool> collisions)?  collision,TResult Function( String id,  String name,  bool isVisible,  double opacity,  String presetId,  SmartTileUsage usage,  List<String> materialPalette,  SmartTileField field,  List<SmartTilePatternStroke> patternStrokes,  int layerSeed, @JsonKey(toJson: _candidateWeightsToJson, includeIfNull: false)  Map<String, int> candidateWeights,  SmartTileAnimationActivation animationActivation,  Map<String, String> properties)?  smartTile,TResult Function( String id,  String name,  bool isVisible,  double opacity,  MapLayerPurpose purpose,  List<MapPlacedTile> tileObjects)?  object,TResult Function( String id,  String name,  bool isVisible,  double opacity, @JsonKey(fromJson: decodeEnvironmentLayerContent, toJson: encodeEnvironmentLayerContent)  EnvironmentLayerContent content,  Map<String, String> properties)?  environment,TResult Function( String id,  String name,  bool isVisible,  double opacity, @JsonKey(readValue: _readBorderLayerContent, fromJson: _borderLayerContentFromJson, toJson: _borderLayerContentToJson)  BorderLayerContent content,  Map<String, String> properties)?  border,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TileLayer() when tile != null:
return tile(_that.id,_that.name,_that.isVisible,_that.opacity,_that.purpose,_that.palette,_that.cells);case CollisionLayer() when collision != null:
return collision(_that.id,_that.name,_that.isVisible,_that.opacity,_that.collisions);case SmartTileLayer() when smartTile != null:
return smartTile(_that.id,_that.name,_that.isVisible,_that.opacity,_that.presetId,_that.usage,_that.materialPalette,_that.field,_that.patternStrokes,_that.layerSeed,_that.candidateWeights,_that.animationActivation,_that.properties);case ObjectLayer() when object != null:
return object(_that.id,_that.name,_that.isVisible,_that.opacity,_that.purpose,_that.tileObjects);case EnvironmentLayer() when environment != null:
return environment(_that.id,_that.name,_that.isVisible,_that.opacity,_that.content,_that.properties);case BorderLayer() when border != null:
return border(_that.id,_that.name,_that.isVisible,_that.opacity,_that.content,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name,  bool isVisible,  double opacity,  MapLayerPurpose purpose,  List<TileLayerPaletteEntry> palette,  List<int> cells)  tile,required TResult Function( String id,  String name,  bool isVisible,  double opacity,  List<bool> collisions)  collision,required TResult Function( String id,  String name,  bool isVisible,  double opacity,  String presetId,  SmartTileUsage usage,  List<String> materialPalette,  SmartTileField field,  List<SmartTilePatternStroke> patternStrokes,  int layerSeed, @JsonKey(toJson: _candidateWeightsToJson, includeIfNull: false)  Map<String, int> candidateWeights,  SmartTileAnimationActivation animationActivation,  Map<String, String> properties)  smartTile,required TResult Function( String id,  String name,  bool isVisible,  double opacity,  MapLayerPurpose purpose,  List<MapPlacedTile> tileObjects)  object,required TResult Function( String id,  String name,  bool isVisible,  double opacity, @JsonKey(fromJson: decodeEnvironmentLayerContent, toJson: encodeEnvironmentLayerContent)  EnvironmentLayerContent content,  Map<String, String> properties)  environment,required TResult Function( String id,  String name,  bool isVisible,  double opacity, @JsonKey(readValue: _readBorderLayerContent, fromJson: _borderLayerContentFromJson, toJson: _borderLayerContentToJson)  BorderLayerContent content,  Map<String, String> properties)  border,}) {final _that = this;
switch (_that) {
case TileLayer():
return tile(_that.id,_that.name,_that.isVisible,_that.opacity,_that.purpose,_that.palette,_that.cells);case CollisionLayer():
return collision(_that.id,_that.name,_that.isVisible,_that.opacity,_that.collisions);case SmartTileLayer():
return smartTile(_that.id,_that.name,_that.isVisible,_that.opacity,_that.presetId,_that.usage,_that.materialPalette,_that.field,_that.patternStrokes,_that.layerSeed,_that.candidateWeights,_that.animationActivation,_that.properties);case ObjectLayer():
return object(_that.id,_that.name,_that.isVisible,_that.opacity,_that.purpose,_that.tileObjects);case EnvironmentLayer():
return environment(_that.id,_that.name,_that.isVisible,_that.opacity,_that.content,_that.properties);case BorderLayer():
return border(_that.id,_that.name,_that.isVisible,_that.opacity,_that.content,_that.properties);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name,  bool isVisible,  double opacity,  MapLayerPurpose purpose,  List<TileLayerPaletteEntry> palette,  List<int> cells)?  tile,TResult? Function( String id,  String name,  bool isVisible,  double opacity,  List<bool> collisions)?  collision,TResult? Function( String id,  String name,  bool isVisible,  double opacity,  String presetId,  SmartTileUsage usage,  List<String> materialPalette,  SmartTileField field,  List<SmartTilePatternStroke> patternStrokes,  int layerSeed, @JsonKey(toJson: _candidateWeightsToJson, includeIfNull: false)  Map<String, int> candidateWeights,  SmartTileAnimationActivation animationActivation,  Map<String, String> properties)?  smartTile,TResult? Function( String id,  String name,  bool isVisible,  double opacity,  MapLayerPurpose purpose,  List<MapPlacedTile> tileObjects)?  object,TResult? Function( String id,  String name,  bool isVisible,  double opacity, @JsonKey(fromJson: decodeEnvironmentLayerContent, toJson: encodeEnvironmentLayerContent)  EnvironmentLayerContent content,  Map<String, String> properties)?  environment,TResult? Function( String id,  String name,  bool isVisible,  double opacity, @JsonKey(readValue: _readBorderLayerContent, fromJson: _borderLayerContentFromJson, toJson: _borderLayerContentToJson)  BorderLayerContent content,  Map<String, String> properties)?  border,}) {final _that = this;
switch (_that) {
case TileLayer() when tile != null:
return tile(_that.id,_that.name,_that.isVisible,_that.opacity,_that.purpose,_that.palette,_that.cells);case CollisionLayer() when collision != null:
return collision(_that.id,_that.name,_that.isVisible,_that.opacity,_that.collisions);case SmartTileLayer() when smartTile != null:
return smartTile(_that.id,_that.name,_that.isVisible,_that.opacity,_that.presetId,_that.usage,_that.materialPalette,_that.field,_that.patternStrokes,_that.layerSeed,_that.candidateWeights,_that.animationActivation,_that.properties);case ObjectLayer() when object != null:
return object(_that.id,_that.name,_that.isVisible,_that.opacity,_that.purpose,_that.tileObjects);case EnvironmentLayer() when environment != null:
return environment(_that.id,_that.name,_that.isVisible,_that.opacity,_that.content,_that.properties);case BorderLayer() when border != null:
return border(_that.id,_that.name,_that.isVisible,_that.opacity,_that.content,_that.properties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class TileLayer extends MapLayer {
  const TileLayer({required this.id, required this.name, this.isVisible = true, this.opacity = 1.0, this.purpose = MapLayerPurpose.visual, final  List<TileLayerPaletteEntry> palette = const <TileLayerPaletteEntry>[], final  List<int> cells = const <int>[], final  String? $type}): _palette = palette,_cells = cells,$type = $type ?? 'tile',super._();
  factory TileLayer.fromJson(Map<String, dynamic> json) => _$TileLayerFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool isVisible;
@override@JsonKey() final  double opacity;
@JsonKey() final  MapLayerPurpose purpose;
 final  List<TileLayerPaletteEntry> _palette;
@JsonKey() List<TileLayerPaletteEntry> get palette {
  if (_palette is EqualUnmodifiableListView) return _palette;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_palette);
}

 final  List<int> _cells;
@JsonKey() List<int> get cells {
  if (_cells is EqualUnmodifiableListView) return _cells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cells);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TileLayerCopyWith<TileLayer> get copyWith => _$TileLayerCopyWithImpl<TileLayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TileLayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TileLayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&const DeepCollectionEquality().equals(other._palette, _palette)&&const DeepCollectionEquality().equals(other._cells, _cells));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVisible,opacity,purpose,const DeepCollectionEquality().hash(_palette),const DeepCollectionEquality().hash(_cells));

@override
String toString() {
  return 'MapLayer.tile(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, purpose: $purpose, palette: $palette, cells: $cells)';
}


}

/// @nodoc
abstract mixin class $TileLayerCopyWith<$Res> implements $MapLayerCopyWith<$Res> {
  factory $TileLayerCopyWith(TileLayer value, $Res Function(TileLayer) _then) = _$TileLayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isVisible, double opacity, MapLayerPurpose purpose, List<TileLayerPaletteEntry> palette, List<int> cells
});




}
/// @nodoc
class _$TileLayerCopyWithImpl<$Res>
    implements $TileLayerCopyWith<$Res> {
  _$TileLayerCopyWithImpl(this._self, this._then);

  final TileLayer _self;
  final $Res Function(TileLayer) _then;

/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isVisible = null,Object? opacity = null,Object? purpose = null,Object? palette = null,Object? cells = null,}) {
  return _then(TileLayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as MapLayerPurpose,palette: null == palette ? _self._palette : palette // ignore: cast_nullable_to_non_nullable
as List<TileLayerPaletteEntry>,cells: null == cells ? _self._cells : cells // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CollisionLayer extends MapLayer {
  const CollisionLayer({required this.id, required this.name, this.isVisible = true, this.opacity = 1.0, final  List<bool> collisions = const [], final  String? $type}): _collisions = collisions,$type = $type ?? 'collision',super._();
  factory CollisionLayer.fromJson(Map<String, dynamic> json) => _$CollisionLayerFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool isVisible;
@override@JsonKey() final  double opacity;
 final  List<bool> _collisions;
@JsonKey() List<bool> get collisions {
  if (_collisions is EqualUnmodifiableListView) return _collisions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_collisions);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollisionLayerCopyWith<CollisionLayer> get copyWith => _$CollisionLayerCopyWithImpl<CollisionLayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollisionLayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollisionLayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&const DeepCollectionEquality().equals(other._collisions, _collisions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVisible,opacity,const DeepCollectionEquality().hash(_collisions));

@override
String toString() {
  return 'MapLayer.collision(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, collisions: $collisions)';
}


}

/// @nodoc
abstract mixin class $CollisionLayerCopyWith<$Res> implements $MapLayerCopyWith<$Res> {
  factory $CollisionLayerCopyWith(CollisionLayer value, $Res Function(CollisionLayer) _then) = _$CollisionLayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isVisible, double opacity, List<bool> collisions
});




}
/// @nodoc
class _$CollisionLayerCopyWithImpl<$Res>
    implements $CollisionLayerCopyWith<$Res> {
  _$CollisionLayerCopyWithImpl(this._self, this._then);

  final CollisionLayer _self;
  final $Res Function(CollisionLayer) _then;

/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isVisible = null,Object? opacity = null,Object? collisions = null,}) {
  return _then(CollisionLayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,collisions: null == collisions ? _self._collisions : collisions // ignore: cast_nullable_to_non_nullable
as List<bool>,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class SmartTileLayer extends MapLayer {
  const SmartTileLayer({required this.id, required this.name, this.isVisible = true, this.opacity = 1.0, required this.presetId, required this.usage, final  List<String> materialPalette = const <String>[''], required this.field, final  List<SmartTilePatternStroke> patternStrokes = const <SmartTilePatternStroke>[], this.layerSeed = 0, @JsonKey(toJson: _candidateWeightsToJson, includeIfNull: false) final  Map<String, int> candidateWeights = const <String, int>{}, this.animationActivation = SmartTileAnimationActivation.always, final  Map<String, String> properties = const <String, String>{}, final  String? $type}): _materialPalette = materialPalette,_patternStrokes = patternStrokes,_candidateWeights = candidateWeights,_properties = properties,$type = $type ?? 'smart_tile',super._();
  factory SmartTileLayer.fromJson(Map<String, dynamic> json) => _$SmartTileLayerFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool isVisible;
@override@JsonKey() final  double opacity;
 final  String presetId;
 final  SmartTileUsage usage;
 final  List<String> _materialPalette;
@JsonKey() List<String> get materialPalette {
  if (_materialPalette is EqualUnmodifiableListView) return _materialPalette;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_materialPalette);
}

 final  SmartTileField field;
 final  List<SmartTilePatternStroke> _patternStrokes;
@JsonKey() List<SmartTilePatternStroke> get patternStrokes {
  if (_patternStrokes is EqualUnmodifiableListView) return _patternStrokes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patternStrokes);
}

@JsonKey() final  int layerSeed;
/// Surcharge locale des poids de variantes du preset, par identifiant de
/// candidat. Une clé absente prend le poids du preset ; `0` exclut le
/// candidat du tirage sur ce calque. Table vide : le calque suit le
/// preset, et la clé n'est pas sérialisée.
 final  Map<String, int> _candidateWeights;
/// Surcharge locale des poids de variantes du preset, par identifiant de
/// candidat. Une clé absente prend le poids du preset ; `0` exclut le
/// candidat du tirage sur ce calque. Table vide : le calque suit le
/// preset, et la clé n'est pas sérialisée.
@JsonKey(toJson: _candidateWeightsToJson, includeIfNull: false) Map<String, int> get candidateWeights {
  if (_candidateWeights is EqualUnmodifiableMapView) return _candidateWeights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_candidateWeights);
}

@JsonKey() final  SmartTileAnimationActivation animationActivation;
 final  Map<String, String> _properties;
@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileLayerCopyWith<SmartTileLayer> get copyWith => _$SmartTileLayerCopyWithImpl<SmartTileLayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileLayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileLayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.presetId, presetId) || other.presetId == presetId)&&(identical(other.usage, usage) || other.usage == usage)&&const DeepCollectionEquality().equals(other._materialPalette, _materialPalette)&&(identical(other.field, field) || other.field == field)&&const DeepCollectionEquality().equals(other._patternStrokes, _patternStrokes)&&(identical(other.layerSeed, layerSeed) || other.layerSeed == layerSeed)&&const DeepCollectionEquality().equals(other._candidateWeights, _candidateWeights)&&(identical(other.animationActivation, animationActivation) || other.animationActivation == animationActivation)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVisible,opacity,presetId,usage,const DeepCollectionEquality().hash(_materialPalette),field,const DeepCollectionEquality().hash(_patternStrokes),layerSeed,const DeepCollectionEquality().hash(_candidateWeights),animationActivation,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'MapLayer.smartTile(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, presetId: $presetId, usage: $usage, materialPalette: $materialPalette, field: $field, patternStrokes: $patternStrokes, layerSeed: $layerSeed, candidateWeights: $candidateWeights, animationActivation: $animationActivation, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $SmartTileLayerCopyWith<$Res> implements $MapLayerCopyWith<$Res> {
  factory $SmartTileLayerCopyWith(SmartTileLayer value, $Res Function(SmartTileLayer) _then) = _$SmartTileLayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isVisible, double opacity, String presetId, SmartTileUsage usage, List<String> materialPalette, SmartTileField field, List<SmartTilePatternStroke> patternStrokes, int layerSeed,@JsonKey(toJson: _candidateWeightsToJson, includeIfNull: false) Map<String, int> candidateWeights, SmartTileAnimationActivation animationActivation, Map<String, String> properties
});


$SmartTileFieldCopyWith<$Res> get field;

}
/// @nodoc
class _$SmartTileLayerCopyWithImpl<$Res>
    implements $SmartTileLayerCopyWith<$Res> {
  _$SmartTileLayerCopyWithImpl(this._self, this._then);

  final SmartTileLayer _self;
  final $Res Function(SmartTileLayer) _then;

/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isVisible = null,Object? opacity = null,Object? presetId = null,Object? usage = null,Object? materialPalette = null,Object? field = null,Object? patternStrokes = null,Object? layerSeed = null,Object? candidateWeights = null,Object? animationActivation = null,Object? properties = null,}) {
  return _then(SmartTileLayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,presetId: null == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as SmartTileUsage,materialPalette: null == materialPalette ? _self._materialPalette : materialPalette // ignore: cast_nullable_to_non_nullable
as List<String>,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as SmartTileField,patternStrokes: null == patternStrokes ? _self._patternStrokes : patternStrokes // ignore: cast_nullable_to_non_nullable
as List<SmartTilePatternStroke>,layerSeed: null == layerSeed ? _self.layerSeed : layerSeed // ignore: cast_nullable_to_non_nullable
as int,candidateWeights: null == candidateWeights ? _self._candidateWeights : candidateWeights // ignore: cast_nullable_to_non_nullable
as Map<String, int>,animationActivation: null == animationActivation ? _self.animationActivation : animationActivation // ignore: cast_nullable_to_non_nullable
as SmartTileAnimationActivation,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SmartTileFieldCopyWith<$Res> get field {

  return $SmartTileFieldCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ObjectLayer extends MapLayer {
  const ObjectLayer({required this.id, required this.name, this.isVisible = true, this.opacity = 1.0, this.purpose = MapLayerPurpose.visual, final  List<MapPlacedTile> tileObjects = const <MapPlacedTile>[], final  String? $type}): _tileObjects = tileObjects,$type = $type ?? 'object',super._();
  factory ObjectLayer.fromJson(Map<String, dynamic> json) => _$ObjectLayerFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool isVisible;
@override@JsonKey() final  double opacity;
@JsonKey() final  MapLayerPurpose purpose;
 final  List<MapPlacedTile> _tileObjects;
@JsonKey() List<MapPlacedTile> get tileObjects {
  if (_tileObjects is EqualUnmodifiableListView) return _tileObjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tileObjects);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ObjectLayerCopyWith<ObjectLayer> get copyWith => _$ObjectLayerCopyWithImpl<ObjectLayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ObjectLayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ObjectLayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&const DeepCollectionEquality().equals(other._tileObjects, _tileObjects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVisible,opacity,purpose,const DeepCollectionEquality().hash(_tileObjects));

@override
String toString() {
  return 'MapLayer.object(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, purpose: $purpose, tileObjects: $tileObjects)';
}


}

/// @nodoc
abstract mixin class $ObjectLayerCopyWith<$Res> implements $MapLayerCopyWith<$Res> {
  factory $ObjectLayerCopyWith(ObjectLayer value, $Res Function(ObjectLayer) _then) = _$ObjectLayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isVisible, double opacity, MapLayerPurpose purpose, List<MapPlacedTile> tileObjects
});




}
/// @nodoc
class _$ObjectLayerCopyWithImpl<$Res>
    implements $ObjectLayerCopyWith<$Res> {
  _$ObjectLayerCopyWithImpl(this._self, this._then);

  final ObjectLayer _self;
  final $Res Function(ObjectLayer) _then;

/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isVisible = null,Object? opacity = null,Object? purpose = null,Object? tileObjects = null,}) {
  return _then(ObjectLayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as MapLayerPurpose,tileObjects: null == tileObjects ? _self._tileObjects : tileObjects // ignore: cast_nullable_to_non_nullable
as List<MapPlacedTile>,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class EnvironmentLayer extends MapLayer {
  const EnvironmentLayer({required this.id, required this.name, this.isVisible = true, this.opacity = 1.0, @JsonKey(fromJson: decodeEnvironmentLayerContent, toJson: encodeEnvironmentLayerContent) this.content = EnvironmentLayerContent.emptyContent, final  Map<String, String> properties = const <String, String>{}, final  String? $type}): _properties = properties,$type = $type ?? 'environment',super._();
  factory EnvironmentLayer.fromJson(Map<String, dynamic> json) => _$EnvironmentLayerFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool isVisible;
@override@JsonKey() final  double opacity;
@JsonKey(fromJson: decodeEnvironmentLayerContent, toJson: encodeEnvironmentLayerContent) final  EnvironmentLayerContent content;
 final  Map<String, String> _properties;
@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnvironmentLayerCopyWith<EnvironmentLayer> get copyWith => _$EnvironmentLayerCopyWithImpl<EnvironmentLayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnvironmentLayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnvironmentLayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVisible,opacity,content,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'MapLayer.environment(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, content: $content, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $EnvironmentLayerCopyWith<$Res> implements $MapLayerCopyWith<$Res> {
  factory $EnvironmentLayerCopyWith(EnvironmentLayer value, $Res Function(EnvironmentLayer) _then) = _$EnvironmentLayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isVisible, double opacity,@JsonKey(fromJson: decodeEnvironmentLayerContent, toJson: encodeEnvironmentLayerContent) EnvironmentLayerContent content, Map<String, String> properties
});




}
/// @nodoc
class _$EnvironmentLayerCopyWithImpl<$Res>
    implements $EnvironmentLayerCopyWith<$Res> {
  _$EnvironmentLayerCopyWithImpl(this._self, this._then);

  final EnvironmentLayer _self;
  final $Res Function(EnvironmentLayer) _then;

/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isVisible = null,Object? opacity = null,Object? content = null,Object? properties = null,}) {
  return _then(EnvironmentLayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as EnvironmentLayerContent,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class BorderLayer extends MapLayer {
  const BorderLayer({required this.id, required this.name, this.isVisible = true, this.opacity = 1.0, @JsonKey(readValue: _readBorderLayerContent, fromJson: _borderLayerContentFromJson, toJson: _borderLayerContentToJson) this.content = BorderLayerContent.emptyContent, final  Map<String, String> properties = const <String, String>{}, final  String? $type}): _properties = properties,$type = $type ?? 'border',super._();
  factory BorderLayer.fromJson(Map<String, dynamic> json) => _$BorderLayerFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool isVisible;
@override@JsonKey() final  double opacity;
@JsonKey(readValue: _readBorderLayerContent, fromJson: _borderLayerContentFromJson, toJson: _borderLayerContentToJson) final  BorderLayerContent content;
 final  Map<String, String> _properties;
@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BorderLayerCopyWith<BorderLayer> get copyWith => _$BorderLayerCopyWithImpl<BorderLayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BorderLayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BorderLayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isVisible,opacity,content,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'MapLayer.border(id: $id, name: $name, isVisible: $isVisible, opacity: $opacity, content: $content, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $BorderLayerCopyWith<$Res> implements $MapLayerCopyWith<$Res> {
  factory $BorderLayerCopyWith(BorderLayer value, $Res Function(BorderLayer) _then) = _$BorderLayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isVisible, double opacity,@JsonKey(readValue: _readBorderLayerContent, fromJson: _borderLayerContentFromJson, toJson: _borderLayerContentToJson) BorderLayerContent content, Map<String, String> properties
});




}
/// @nodoc
class _$BorderLayerCopyWithImpl<$Res>
    implements $BorderLayerCopyWith<$Res> {
  _$BorderLayerCopyWithImpl(this._self, this._then);

  final BorderLayer _self;
  final $Res Function(BorderLayer) _then;

/// Create a copy of MapLayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isVisible = null,Object? opacity = null,Object? content = null,Object? properties = null,}) {
  return _then(BorderLayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as BorderLayerContent,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
