// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_palette_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorPaletteContextKey {

 String get mapId; String get layerId;
/// Create a copy of EditorPaletteContextKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorPaletteContextKeyCopyWith<EditorPaletteContextKey> get copyWith => _$EditorPaletteContextKeyCopyWithImpl<EditorPaletteContextKey>(this as EditorPaletteContextKey, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorPaletteContextKey&&(identical(other.mapId, mapId) || other.mapId == mapId)&&(identical(other.layerId, layerId) || other.layerId == layerId));
}


@override
int get hashCode => Object.hash(runtimeType,mapId,layerId);

@override
String toString() {
  return 'EditorPaletteContextKey(mapId: $mapId, layerId: $layerId)';
}


}

/// @nodoc
abstract mixin class $EditorPaletteContextKeyCopyWith<$Res>  {
  factory $EditorPaletteContextKeyCopyWith(EditorPaletteContextKey value, $Res Function(EditorPaletteContextKey) _then) = _$EditorPaletteContextKeyCopyWithImpl;
@useResult
$Res call({
 String mapId, String layerId
});




}
/// @nodoc
class _$EditorPaletteContextKeyCopyWithImpl<$Res>
    implements $EditorPaletteContextKeyCopyWith<$Res> {
  _$EditorPaletteContextKeyCopyWithImpl(this._self, this._then);

  final EditorPaletteContextKey _self;
  final $Res Function(EditorPaletteContextKey) _then;

/// Create a copy of EditorPaletteContextKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mapId = null,Object? layerId = null,}) {
  return _then(_self.copyWith(
mapId: null == mapId ? _self.mapId : mapId // ignore: cast_nullable_to_non_nullable
as String,layerId: null == layerId ? _self.layerId : layerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EditorPaletteContextKey].
extension EditorPaletteContextKeyPatterns on EditorPaletteContextKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorPaletteContextKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorPaletteContextKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorPaletteContextKey value)  $default,){
final _that = this;
switch (_that) {
case _EditorPaletteContextKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorPaletteContextKey value)?  $default,){
final _that = this;
switch (_that) {
case _EditorPaletteContextKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mapId,  String layerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorPaletteContextKey() when $default != null:
return $default(_that.mapId,_that.layerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mapId,  String layerId)  $default,) {final _that = this;
switch (_that) {
case _EditorPaletteContextKey():
return $default(_that.mapId,_that.layerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mapId,  String layerId)?  $default,) {final _that = this;
switch (_that) {
case _EditorPaletteContextKey() when $default != null:
return $default(_that.mapId,_that.layerId);case _:
  return null;

}
}

}

/// @nodoc


class _EditorPaletteContextKey implements EditorPaletteContextKey {
  const _EditorPaletteContextKey({required this.mapId, required this.layerId});
  

@override final  String mapId;
@override final  String layerId;

/// Create a copy of EditorPaletteContextKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorPaletteContextKeyCopyWith<_EditorPaletteContextKey> get copyWith => __$EditorPaletteContextKeyCopyWithImpl<_EditorPaletteContextKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorPaletteContextKey&&(identical(other.mapId, mapId) || other.mapId == mapId)&&(identical(other.layerId, layerId) || other.layerId == layerId));
}


@override
int get hashCode => Object.hash(runtimeType,mapId,layerId);

@override
String toString() {
  return 'EditorPaletteContextKey(mapId: $mapId, layerId: $layerId)';
}


}

/// @nodoc
abstract mixin class _$EditorPaletteContextKeyCopyWith<$Res> implements $EditorPaletteContextKeyCopyWith<$Res> {
  factory _$EditorPaletteContextKeyCopyWith(_EditorPaletteContextKey value, $Res Function(_EditorPaletteContextKey) _then) = __$EditorPaletteContextKeyCopyWithImpl;
@override @useResult
$Res call({
 String mapId, String layerId
});




}
/// @nodoc
class __$EditorPaletteContextKeyCopyWithImpl<$Res>
    implements _$EditorPaletteContextKeyCopyWith<$Res> {
  __$EditorPaletteContextKeyCopyWithImpl(this._self, this._then);

  final _EditorPaletteContextKey _self;
  final $Res Function(_EditorPaletteContextKey) _then;

/// Create a copy of EditorPaletteContextKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mapId = null,Object? layerId = null,}) {
  return _then(_EditorPaletteContextKey(
mapId: null == mapId ? _self.mapId : mapId // ignore: cast_nullable_to_non_nullable
as String,layerId: null == layerId ? _self.layerId : layerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$EditorPaletteBrushMemory {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorPaletteBrushMemory);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorPaletteBrushMemory()';
}


}

/// @nodoc
class $EditorPaletteBrushMemoryCopyWith<$Res>  {
$EditorPaletteBrushMemoryCopyWith(EditorPaletteBrushMemory _, $Res Function(EditorPaletteBrushMemory) __);
}


/// Adds pattern-matching-related methods to [EditorPaletteBrushMemory].
extension EditorPaletteBrushMemoryPatterns on EditorPaletteBrushMemory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NoEditorPaletteBrushMemory value)?  none,TResult Function( TileEditorPaletteBrushMemory value)?  tile,TResult Function( PaletteEntryEditorPaletteBrushMemory value)?  paletteEntry,TResult Function( ProjectElementEditorPaletteBrushMemory value)?  projectElement,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NoEditorPaletteBrushMemory() when none != null:
return none(_that);case TileEditorPaletteBrushMemory() when tile != null:
return tile(_that);case PaletteEntryEditorPaletteBrushMemory() when paletteEntry != null:
return paletteEntry(_that);case ProjectElementEditorPaletteBrushMemory() when projectElement != null:
return projectElement(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NoEditorPaletteBrushMemory value)  none,required TResult Function( TileEditorPaletteBrushMemory value)  tile,required TResult Function( PaletteEntryEditorPaletteBrushMemory value)  paletteEntry,required TResult Function( ProjectElementEditorPaletteBrushMemory value)  projectElement,}){
final _that = this;
switch (_that) {
case NoEditorPaletteBrushMemory():
return none(_that);case TileEditorPaletteBrushMemory():
return tile(_that);case PaletteEntryEditorPaletteBrushMemory():
return paletteEntry(_that);case ProjectElementEditorPaletteBrushMemory():
return projectElement(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NoEditorPaletteBrushMemory value)?  none,TResult? Function( TileEditorPaletteBrushMemory value)?  tile,TResult? Function( PaletteEntryEditorPaletteBrushMemory value)?  paletteEntry,TResult? Function( ProjectElementEditorPaletteBrushMemory value)?  projectElement,}){
final _that = this;
switch (_that) {
case NoEditorPaletteBrushMemory() when none != null:
return none(_that);case TileEditorPaletteBrushMemory() when tile != null:
return tile(_that);case PaletteEntryEditorPaletteBrushMemory() when paletteEntry != null:
return paletteEntry(_that);case ProjectElementEditorPaletteBrushMemory() when projectElement != null:
return projectElement(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  none,TResult Function( int tileId,  String tilesetId)?  tile,TResult Function( String entryId,  String tilesetId)?  paletteEntry,TResult Function( String elementId)?  projectElement,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NoEditorPaletteBrushMemory() when none != null:
return none();case TileEditorPaletteBrushMemory() when tile != null:
return tile(_that.tileId,_that.tilesetId);case PaletteEntryEditorPaletteBrushMemory() when paletteEntry != null:
return paletteEntry(_that.entryId,_that.tilesetId);case ProjectElementEditorPaletteBrushMemory() when projectElement != null:
return projectElement(_that.elementId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  none,required TResult Function( int tileId,  String tilesetId)  tile,required TResult Function( String entryId,  String tilesetId)  paletteEntry,required TResult Function( String elementId)  projectElement,}) {final _that = this;
switch (_that) {
case NoEditorPaletteBrushMemory():
return none();case TileEditorPaletteBrushMemory():
return tile(_that.tileId,_that.tilesetId);case PaletteEntryEditorPaletteBrushMemory():
return paletteEntry(_that.entryId,_that.tilesetId);case ProjectElementEditorPaletteBrushMemory():
return projectElement(_that.elementId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  none,TResult? Function( int tileId,  String tilesetId)?  tile,TResult? Function( String entryId,  String tilesetId)?  paletteEntry,TResult? Function( String elementId)?  projectElement,}) {final _that = this;
switch (_that) {
case NoEditorPaletteBrushMemory() when none != null:
return none();case TileEditorPaletteBrushMemory() when tile != null:
return tile(_that.tileId,_that.tilesetId);case PaletteEntryEditorPaletteBrushMemory() when paletteEntry != null:
return paletteEntry(_that.entryId,_that.tilesetId);case ProjectElementEditorPaletteBrushMemory() when projectElement != null:
return projectElement(_that.elementId);case _:
  return null;

}
}

}

/// @nodoc


class NoEditorPaletteBrushMemory implements EditorPaletteBrushMemory {
  const NoEditorPaletteBrushMemory();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoEditorPaletteBrushMemory);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorPaletteBrushMemory.none()';
}


}




/// @nodoc


class TileEditorPaletteBrushMemory implements EditorPaletteBrushMemory {
  const TileEditorPaletteBrushMemory({required this.tileId, required this.tilesetId});
  

 final  int tileId;
 final  String tilesetId;

/// Create a copy of EditorPaletteBrushMemory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TileEditorPaletteBrushMemoryCopyWith<TileEditorPaletteBrushMemory> get copyWith => _$TileEditorPaletteBrushMemoryCopyWithImpl<TileEditorPaletteBrushMemory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TileEditorPaletteBrushMemory&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId));
}


@override
int get hashCode => Object.hash(runtimeType,tileId,tilesetId);

@override
String toString() {
  return 'EditorPaletteBrushMemory.tile(tileId: $tileId, tilesetId: $tilesetId)';
}


}

/// @nodoc
abstract mixin class $TileEditorPaletteBrushMemoryCopyWith<$Res> implements $EditorPaletteBrushMemoryCopyWith<$Res> {
  factory $TileEditorPaletteBrushMemoryCopyWith(TileEditorPaletteBrushMemory value, $Res Function(TileEditorPaletteBrushMemory) _then) = _$TileEditorPaletteBrushMemoryCopyWithImpl;
@useResult
$Res call({
 int tileId, String tilesetId
});




}
/// @nodoc
class _$TileEditorPaletteBrushMemoryCopyWithImpl<$Res>
    implements $TileEditorPaletteBrushMemoryCopyWith<$Res> {
  _$TileEditorPaletteBrushMemoryCopyWithImpl(this._self, this._then);

  final TileEditorPaletteBrushMemory _self;
  final $Res Function(TileEditorPaletteBrushMemory) _then;

/// Create a copy of EditorPaletteBrushMemory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tileId = null,Object? tilesetId = null,}) {
  return _then(TileEditorPaletteBrushMemory(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PaletteEntryEditorPaletteBrushMemory implements EditorPaletteBrushMemory {
  const PaletteEntryEditorPaletteBrushMemory({required this.entryId, required this.tilesetId});
  

 final  String entryId;
 final  String tilesetId;

/// Create a copy of EditorPaletteBrushMemory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaletteEntryEditorPaletteBrushMemoryCopyWith<PaletteEntryEditorPaletteBrushMemory> get copyWith => _$PaletteEntryEditorPaletteBrushMemoryCopyWithImpl<PaletteEntryEditorPaletteBrushMemory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaletteEntryEditorPaletteBrushMemory&&(identical(other.entryId, entryId) || other.entryId == entryId)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId));
}


@override
int get hashCode => Object.hash(runtimeType,entryId,tilesetId);

@override
String toString() {
  return 'EditorPaletteBrushMemory.paletteEntry(entryId: $entryId, tilesetId: $tilesetId)';
}


}

/// @nodoc
abstract mixin class $PaletteEntryEditorPaletteBrushMemoryCopyWith<$Res> implements $EditorPaletteBrushMemoryCopyWith<$Res> {
  factory $PaletteEntryEditorPaletteBrushMemoryCopyWith(PaletteEntryEditorPaletteBrushMemory value, $Res Function(PaletteEntryEditorPaletteBrushMemory) _then) = _$PaletteEntryEditorPaletteBrushMemoryCopyWithImpl;
@useResult
$Res call({
 String entryId, String tilesetId
});




}
/// @nodoc
class _$PaletteEntryEditorPaletteBrushMemoryCopyWithImpl<$Res>
    implements $PaletteEntryEditorPaletteBrushMemoryCopyWith<$Res> {
  _$PaletteEntryEditorPaletteBrushMemoryCopyWithImpl(this._self, this._then);

  final PaletteEntryEditorPaletteBrushMemory _self;
  final $Res Function(PaletteEntryEditorPaletteBrushMemory) _then;

/// Create a copy of EditorPaletteBrushMemory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entryId = null,Object? tilesetId = null,}) {
  return _then(PaletteEntryEditorPaletteBrushMemory(
entryId: null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProjectElementEditorPaletteBrushMemory implements EditorPaletteBrushMemory {
  const ProjectElementEditorPaletteBrushMemory({required this.elementId});
  

 final  String elementId;

/// Create a copy of EditorPaletteBrushMemory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectElementEditorPaletteBrushMemoryCopyWith<ProjectElementEditorPaletteBrushMemory> get copyWith => _$ProjectElementEditorPaletteBrushMemoryCopyWithImpl<ProjectElementEditorPaletteBrushMemory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectElementEditorPaletteBrushMemory&&(identical(other.elementId, elementId) || other.elementId == elementId));
}


@override
int get hashCode => Object.hash(runtimeType,elementId);

@override
String toString() {
  return 'EditorPaletteBrushMemory.projectElement(elementId: $elementId)';
}


}

/// @nodoc
abstract mixin class $ProjectElementEditorPaletteBrushMemoryCopyWith<$Res> implements $EditorPaletteBrushMemoryCopyWith<$Res> {
  factory $ProjectElementEditorPaletteBrushMemoryCopyWith(ProjectElementEditorPaletteBrushMemory value, $Res Function(ProjectElementEditorPaletteBrushMemory) _then) = _$ProjectElementEditorPaletteBrushMemoryCopyWithImpl;
@useResult
$Res call({
 String elementId
});




}
/// @nodoc
class _$ProjectElementEditorPaletteBrushMemoryCopyWithImpl<$Res>
    implements $ProjectElementEditorPaletteBrushMemoryCopyWith<$Res> {
  _$ProjectElementEditorPaletteBrushMemoryCopyWithImpl(this._self, this._then);

  final ProjectElementEditorPaletteBrushMemory _self;
  final $Res Function(ProjectElementEditorPaletteBrushMemory) _then;

/// Create a copy of EditorPaletteBrushMemory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? elementId = null,}) {
  return _then(ProjectElementEditorPaletteBrushMemory(
elementId: null == elementId ? _self.elementId : elementId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$EditorLayerPaletteContext {

 String? get selectedTilesetId; String? get selectedElementGroupId; PaletteCategory? get paletteCategoryFilter; EditorPaletteBrushMemory get activeBrush; TilesElementsPanelMode get panelMode; String get browserQuery; String? get browserFolderId; String? get projectElementCategoryId; EditorPaletteAssetCollection get browserCollection; bool get showIncompatible;
/// Create a copy of EditorLayerPaletteContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorLayerPaletteContextCopyWith<EditorLayerPaletteContext> get copyWith => _$EditorLayerPaletteContextCopyWithImpl<EditorLayerPaletteContext>(this as EditorLayerPaletteContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorLayerPaletteContext&&(identical(other.selectedTilesetId, selectedTilesetId) || other.selectedTilesetId == selectedTilesetId)&&(identical(other.selectedElementGroupId, selectedElementGroupId) || other.selectedElementGroupId == selectedElementGroupId)&&(identical(other.paletteCategoryFilter, paletteCategoryFilter) || other.paletteCategoryFilter == paletteCategoryFilter)&&(identical(other.activeBrush, activeBrush) || other.activeBrush == activeBrush)&&(identical(other.panelMode, panelMode) || other.panelMode == panelMode)&&(identical(other.browserQuery, browserQuery) || other.browserQuery == browserQuery)&&(identical(other.browserFolderId, browserFolderId) || other.browserFolderId == browserFolderId)&&(identical(other.projectElementCategoryId, projectElementCategoryId) || other.projectElementCategoryId == projectElementCategoryId)&&(identical(other.browserCollection, browserCollection) || other.browserCollection == browserCollection)&&(identical(other.showIncompatible, showIncompatible) || other.showIncompatible == showIncompatible));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTilesetId,selectedElementGroupId,paletteCategoryFilter,activeBrush,panelMode,browserQuery,browserFolderId,projectElementCategoryId,browserCollection,showIncompatible);

@override
String toString() {
  return 'EditorLayerPaletteContext(selectedTilesetId: $selectedTilesetId, selectedElementGroupId: $selectedElementGroupId, paletteCategoryFilter: $paletteCategoryFilter, activeBrush: $activeBrush, panelMode: $panelMode, browserQuery: $browserQuery, browserFolderId: $browserFolderId, projectElementCategoryId: $projectElementCategoryId, browserCollection: $browserCollection, showIncompatible: $showIncompatible)';
}


}

/// @nodoc
abstract mixin class $EditorLayerPaletteContextCopyWith<$Res>  {
  factory $EditorLayerPaletteContextCopyWith(EditorLayerPaletteContext value, $Res Function(EditorLayerPaletteContext) _then) = _$EditorLayerPaletteContextCopyWithImpl;
@useResult
$Res call({
 String? selectedTilesetId, String? selectedElementGroupId, PaletteCategory? paletteCategoryFilter, EditorPaletteBrushMemory activeBrush, TilesElementsPanelMode panelMode, String browserQuery, String? browserFolderId, String? projectElementCategoryId, EditorPaletteAssetCollection browserCollection, bool showIncompatible
});


$EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush;

}
/// @nodoc
class _$EditorLayerPaletteContextCopyWithImpl<$Res>
    implements $EditorLayerPaletteContextCopyWith<$Res> {
  _$EditorLayerPaletteContextCopyWithImpl(this._self, this._then);

  final EditorLayerPaletteContext _self;
  final $Res Function(EditorLayerPaletteContext) _then;

/// Create a copy of EditorLayerPaletteContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedTilesetId = freezed,Object? selectedElementGroupId = freezed,Object? paletteCategoryFilter = freezed,Object? activeBrush = null,Object? panelMode = null,Object? browserQuery = null,Object? browserFolderId = freezed,Object? projectElementCategoryId = freezed,Object? browserCollection = null,Object? showIncompatible = null,}) {
  return _then(_self.copyWith(
selectedTilesetId: freezed == selectedTilesetId ? _self.selectedTilesetId : selectedTilesetId // ignore: cast_nullable_to_non_nullable
as String?,selectedElementGroupId: freezed == selectedElementGroupId ? _self.selectedElementGroupId : selectedElementGroupId // ignore: cast_nullable_to_non_nullable
as String?,paletteCategoryFilter: freezed == paletteCategoryFilter ? _self.paletteCategoryFilter : paletteCategoryFilter // ignore: cast_nullable_to_non_nullable
as PaletteCategory?,activeBrush: null == activeBrush ? _self.activeBrush : activeBrush // ignore: cast_nullable_to_non_nullable
as EditorPaletteBrushMemory,panelMode: null == panelMode ? _self.panelMode : panelMode // ignore: cast_nullable_to_non_nullable
as TilesElementsPanelMode,browserQuery: null == browserQuery ? _self.browserQuery : browserQuery // ignore: cast_nullable_to_non_nullable
as String,browserFolderId: freezed == browserFolderId ? _self.browserFolderId : browserFolderId // ignore: cast_nullable_to_non_nullable
as String?,projectElementCategoryId: freezed == projectElementCategoryId ? _self.projectElementCategoryId : projectElementCategoryId // ignore: cast_nullable_to_non_nullable
as String?,browserCollection: null == browserCollection ? _self.browserCollection : browserCollection // ignore: cast_nullable_to_non_nullable
as EditorPaletteAssetCollection,showIncompatible: null == showIncompatible ? _self.showIncompatible : showIncompatible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of EditorLayerPaletteContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush {
  
  return $EditorPaletteBrushMemoryCopyWith<$Res>(_self.activeBrush, (value) {
    return _then(_self.copyWith(activeBrush: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorLayerPaletteContext].
extension EditorLayerPaletteContextPatterns on EditorLayerPaletteContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorLayerPaletteContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorLayerPaletteContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorLayerPaletteContext value)  $default,){
final _that = this;
switch (_that) {
case _EditorLayerPaletteContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorLayerPaletteContext value)?  $default,){
final _that = this;
switch (_that) {
case _EditorLayerPaletteContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? selectedTilesetId,  String? selectedElementGroupId,  PaletteCategory? paletteCategoryFilter,  EditorPaletteBrushMemory activeBrush,  TilesElementsPanelMode panelMode,  String browserQuery,  String? browserFolderId,  String? projectElementCategoryId,  EditorPaletteAssetCollection browserCollection,  bool showIncompatible)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorLayerPaletteContext() when $default != null:
return $default(_that.selectedTilesetId,_that.selectedElementGroupId,_that.paletteCategoryFilter,_that.activeBrush,_that.panelMode,_that.browserQuery,_that.browserFolderId,_that.projectElementCategoryId,_that.browserCollection,_that.showIncompatible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? selectedTilesetId,  String? selectedElementGroupId,  PaletteCategory? paletteCategoryFilter,  EditorPaletteBrushMemory activeBrush,  TilesElementsPanelMode panelMode,  String browserQuery,  String? browserFolderId,  String? projectElementCategoryId,  EditorPaletteAssetCollection browserCollection,  bool showIncompatible)  $default,) {final _that = this;
switch (_that) {
case _EditorLayerPaletteContext():
return $default(_that.selectedTilesetId,_that.selectedElementGroupId,_that.paletteCategoryFilter,_that.activeBrush,_that.panelMode,_that.browserQuery,_that.browserFolderId,_that.projectElementCategoryId,_that.browserCollection,_that.showIncompatible);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? selectedTilesetId,  String? selectedElementGroupId,  PaletteCategory? paletteCategoryFilter,  EditorPaletteBrushMemory activeBrush,  TilesElementsPanelMode panelMode,  String browserQuery,  String? browserFolderId,  String? projectElementCategoryId,  EditorPaletteAssetCollection browserCollection,  bool showIncompatible)?  $default,) {final _that = this;
switch (_that) {
case _EditorLayerPaletteContext() when $default != null:
return $default(_that.selectedTilesetId,_that.selectedElementGroupId,_that.paletteCategoryFilter,_that.activeBrush,_that.panelMode,_that.browserQuery,_that.browserFolderId,_that.projectElementCategoryId,_that.browserCollection,_that.showIncompatible);case _:
  return null;

}
}

}

/// @nodoc


class _EditorLayerPaletteContext implements EditorLayerPaletteContext {
  const _EditorLayerPaletteContext({this.selectedTilesetId, this.selectedElementGroupId, this.paletteCategoryFilter, this.activeBrush = const EditorPaletteBrushMemory.none(), this.panelMode = TilesElementsPanelMode.palette, this.browserQuery = '', this.browserFolderId, this.projectElementCategoryId, this.browserCollection = EditorPaletteAssetCollection.all, this.showIncompatible = false});
  

@override final  String? selectedTilesetId;
@override final  String? selectedElementGroupId;
@override final  PaletteCategory? paletteCategoryFilter;
@override@JsonKey() final  EditorPaletteBrushMemory activeBrush;
@override@JsonKey() final  TilesElementsPanelMode panelMode;
@override@JsonKey() final  String browserQuery;
@override final  String? browserFolderId;
@override final  String? projectElementCategoryId;
@override@JsonKey() final  EditorPaletteAssetCollection browserCollection;
@override@JsonKey() final  bool showIncompatible;

/// Create a copy of EditorLayerPaletteContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorLayerPaletteContextCopyWith<_EditorLayerPaletteContext> get copyWith => __$EditorLayerPaletteContextCopyWithImpl<_EditorLayerPaletteContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorLayerPaletteContext&&(identical(other.selectedTilesetId, selectedTilesetId) || other.selectedTilesetId == selectedTilesetId)&&(identical(other.selectedElementGroupId, selectedElementGroupId) || other.selectedElementGroupId == selectedElementGroupId)&&(identical(other.paletteCategoryFilter, paletteCategoryFilter) || other.paletteCategoryFilter == paletteCategoryFilter)&&(identical(other.activeBrush, activeBrush) || other.activeBrush == activeBrush)&&(identical(other.panelMode, panelMode) || other.panelMode == panelMode)&&(identical(other.browserQuery, browserQuery) || other.browserQuery == browserQuery)&&(identical(other.browserFolderId, browserFolderId) || other.browserFolderId == browserFolderId)&&(identical(other.projectElementCategoryId, projectElementCategoryId) || other.projectElementCategoryId == projectElementCategoryId)&&(identical(other.browserCollection, browserCollection) || other.browserCollection == browserCollection)&&(identical(other.showIncompatible, showIncompatible) || other.showIncompatible == showIncompatible));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTilesetId,selectedElementGroupId,paletteCategoryFilter,activeBrush,panelMode,browserQuery,browserFolderId,projectElementCategoryId,browserCollection,showIncompatible);

@override
String toString() {
  return 'EditorLayerPaletteContext(selectedTilesetId: $selectedTilesetId, selectedElementGroupId: $selectedElementGroupId, paletteCategoryFilter: $paletteCategoryFilter, activeBrush: $activeBrush, panelMode: $panelMode, browserQuery: $browserQuery, browserFolderId: $browserFolderId, projectElementCategoryId: $projectElementCategoryId, browserCollection: $browserCollection, showIncompatible: $showIncompatible)';
}


}

/// @nodoc
abstract mixin class _$EditorLayerPaletteContextCopyWith<$Res> implements $EditorLayerPaletteContextCopyWith<$Res> {
  factory _$EditorLayerPaletteContextCopyWith(_EditorLayerPaletteContext value, $Res Function(_EditorLayerPaletteContext) _then) = __$EditorLayerPaletteContextCopyWithImpl;
@override @useResult
$Res call({
 String? selectedTilesetId, String? selectedElementGroupId, PaletteCategory? paletteCategoryFilter, EditorPaletteBrushMemory activeBrush, TilesElementsPanelMode panelMode, String browserQuery, String? browserFolderId, String? projectElementCategoryId, EditorPaletteAssetCollection browserCollection, bool showIncompatible
});


@override $EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush;

}
/// @nodoc
class __$EditorLayerPaletteContextCopyWithImpl<$Res>
    implements _$EditorLayerPaletteContextCopyWith<$Res> {
  __$EditorLayerPaletteContextCopyWithImpl(this._self, this._then);

  final _EditorLayerPaletteContext _self;
  final $Res Function(_EditorLayerPaletteContext) _then;

/// Create a copy of EditorLayerPaletteContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedTilesetId = freezed,Object? selectedElementGroupId = freezed,Object? paletteCategoryFilter = freezed,Object? activeBrush = null,Object? panelMode = null,Object? browserQuery = null,Object? browserFolderId = freezed,Object? projectElementCategoryId = freezed,Object? browserCollection = null,Object? showIncompatible = null,}) {
  return _then(_EditorLayerPaletteContext(
selectedTilesetId: freezed == selectedTilesetId ? _self.selectedTilesetId : selectedTilesetId // ignore: cast_nullable_to_non_nullable
as String?,selectedElementGroupId: freezed == selectedElementGroupId ? _self.selectedElementGroupId : selectedElementGroupId // ignore: cast_nullable_to_non_nullable
as String?,paletteCategoryFilter: freezed == paletteCategoryFilter ? _self.paletteCategoryFilter : paletteCategoryFilter // ignore: cast_nullable_to_non_nullable
as PaletteCategory?,activeBrush: null == activeBrush ? _self.activeBrush : activeBrush // ignore: cast_nullable_to_non_nullable
as EditorPaletteBrushMemory,panelMode: null == panelMode ? _self.panelMode : panelMode // ignore: cast_nullable_to_non_nullable
as TilesElementsPanelMode,browserQuery: null == browserQuery ? _self.browserQuery : browserQuery // ignore: cast_nullable_to_non_nullable
as String,browserFolderId: freezed == browserFolderId ? _self.browserFolderId : browserFolderId // ignore: cast_nullable_to_non_nullable
as String?,projectElementCategoryId: freezed == projectElementCategoryId ? _self.projectElementCategoryId : projectElementCategoryId // ignore: cast_nullable_to_non_nullable
as String?,browserCollection: null == browserCollection ? _self.browserCollection : browserCollection // ignore: cast_nullable_to_non_nullable
as EditorPaletteAssetCollection,showIncompatible: null == showIncompatible ? _self.showIncompatible : showIncompatible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of EditorLayerPaletteContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush {
  
  return $EditorPaletteBrushMemoryCopyWith<$Res>(_self.activeBrush, (value) {
    return _then(_self.copyWith(activeBrush: value));
  });
}
}

/// @nodoc
mixin _$EditorPaletteSession {

 EditorPaletteContextKey? get activeKey; Map<EditorPaletteContextKey, EditorLayerPaletteContext> get contexts; List<String> get recentTilesetIds; List<String> get favoriteTilesetIds;
/// Create a copy of EditorPaletteSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorPaletteSessionCopyWith<EditorPaletteSession> get copyWith => _$EditorPaletteSessionCopyWithImpl<EditorPaletteSession>(this as EditorPaletteSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorPaletteSession&&(identical(other.activeKey, activeKey) || other.activeKey == activeKey)&&const DeepCollectionEquality().equals(other.contexts, contexts)&&const DeepCollectionEquality().equals(other.recentTilesetIds, recentTilesetIds)&&const DeepCollectionEquality().equals(other.favoriteTilesetIds, favoriteTilesetIds));
}


@override
int get hashCode => Object.hash(runtimeType,activeKey,const DeepCollectionEquality().hash(contexts),const DeepCollectionEquality().hash(recentTilesetIds),const DeepCollectionEquality().hash(favoriteTilesetIds));

@override
String toString() {
  return 'EditorPaletteSession(activeKey: $activeKey, contexts: $contexts, recentTilesetIds: $recentTilesetIds, favoriteTilesetIds: $favoriteTilesetIds)';
}


}

/// @nodoc
abstract mixin class $EditorPaletteSessionCopyWith<$Res>  {
  factory $EditorPaletteSessionCopyWith(EditorPaletteSession value, $Res Function(EditorPaletteSession) _then) = _$EditorPaletteSessionCopyWithImpl;
@useResult
$Res call({
 EditorPaletteContextKey? activeKey, Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts, List<String> recentTilesetIds, List<String> favoriteTilesetIds
});


$EditorPaletteContextKeyCopyWith<$Res>? get activeKey;

}
/// @nodoc
class _$EditorPaletteSessionCopyWithImpl<$Res>
    implements $EditorPaletteSessionCopyWith<$Res> {
  _$EditorPaletteSessionCopyWithImpl(this._self, this._then);

  final EditorPaletteSession _self;
  final $Res Function(EditorPaletteSession) _then;

/// Create a copy of EditorPaletteSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeKey = freezed,Object? contexts = null,Object? recentTilesetIds = null,Object? favoriteTilesetIds = null,}) {
  return _then(_self.copyWith(
activeKey: freezed == activeKey ? _self.activeKey : activeKey // ignore: cast_nullable_to_non_nullable
as EditorPaletteContextKey?,contexts: null == contexts ? _self.contexts : contexts // ignore: cast_nullable_to_non_nullable
as Map<EditorPaletteContextKey, EditorLayerPaletteContext>,recentTilesetIds: null == recentTilesetIds ? _self.recentTilesetIds : recentTilesetIds // ignore: cast_nullable_to_non_nullable
as List<String>,favoriteTilesetIds: null == favoriteTilesetIds ? _self.favoriteTilesetIds : favoriteTilesetIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of EditorPaletteSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPaletteContextKeyCopyWith<$Res>? get activeKey {
    if (_self.activeKey == null) {
    return null;
  }

  return $EditorPaletteContextKeyCopyWith<$Res>(_self.activeKey!, (value) {
    return _then(_self.copyWith(activeKey: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorPaletteSession].
extension EditorPaletteSessionPatterns on EditorPaletteSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorPaletteSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorPaletteSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorPaletteSession value)  $default,){
final _that = this;
switch (_that) {
case _EditorPaletteSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorPaletteSession value)?  $default,){
final _that = this;
switch (_that) {
case _EditorPaletteSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorPaletteContextKey? activeKey,  Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,  List<String> recentTilesetIds,  List<String> favoriteTilesetIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorPaletteSession() when $default != null:
return $default(_that.activeKey,_that.contexts,_that.recentTilesetIds,_that.favoriteTilesetIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorPaletteContextKey? activeKey,  Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,  List<String> recentTilesetIds,  List<String> favoriteTilesetIds)  $default,) {final _that = this;
switch (_that) {
case _EditorPaletteSession():
return $default(_that.activeKey,_that.contexts,_that.recentTilesetIds,_that.favoriteTilesetIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorPaletteContextKey? activeKey,  Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,  List<String> recentTilesetIds,  List<String> favoriteTilesetIds)?  $default,) {final _that = this;
switch (_that) {
case _EditorPaletteSession() when $default != null:
return $default(_that.activeKey,_that.contexts,_that.recentTilesetIds,_that.favoriteTilesetIds);case _:
  return null;

}
}

}

/// @nodoc


class _EditorPaletteSession implements EditorPaletteSession {
  const _EditorPaletteSession({this.activeKey, final  Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts = const <EditorPaletteContextKey, EditorLayerPaletteContext>{}, final  List<String> recentTilesetIds = const <String>[], final  List<String> favoriteTilesetIds = const <String>[]}): _contexts = contexts,_recentTilesetIds = recentTilesetIds,_favoriteTilesetIds = favoriteTilesetIds;
  

@override final  EditorPaletteContextKey? activeKey;
 final  Map<EditorPaletteContextKey, EditorLayerPaletteContext> _contexts;
@override@JsonKey() Map<EditorPaletteContextKey, EditorLayerPaletteContext> get contexts {
  if (_contexts is EqualUnmodifiableMapView) return _contexts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_contexts);
}

 final  List<String> _recentTilesetIds;
@override@JsonKey() List<String> get recentTilesetIds {
  if (_recentTilesetIds is EqualUnmodifiableListView) return _recentTilesetIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentTilesetIds);
}

 final  List<String> _favoriteTilesetIds;
@override@JsonKey() List<String> get favoriteTilesetIds {
  if (_favoriteTilesetIds is EqualUnmodifiableListView) return _favoriteTilesetIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favoriteTilesetIds);
}


/// Create a copy of EditorPaletteSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorPaletteSessionCopyWith<_EditorPaletteSession> get copyWith => __$EditorPaletteSessionCopyWithImpl<_EditorPaletteSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorPaletteSession&&(identical(other.activeKey, activeKey) || other.activeKey == activeKey)&&const DeepCollectionEquality().equals(other._contexts, _contexts)&&const DeepCollectionEquality().equals(other._recentTilesetIds, _recentTilesetIds)&&const DeepCollectionEquality().equals(other._favoriteTilesetIds, _favoriteTilesetIds));
}


@override
int get hashCode => Object.hash(runtimeType,activeKey,const DeepCollectionEquality().hash(_contexts),const DeepCollectionEquality().hash(_recentTilesetIds),const DeepCollectionEquality().hash(_favoriteTilesetIds));

@override
String toString() {
  return 'EditorPaletteSession(activeKey: $activeKey, contexts: $contexts, recentTilesetIds: $recentTilesetIds, favoriteTilesetIds: $favoriteTilesetIds)';
}


}

/// @nodoc
abstract mixin class _$EditorPaletteSessionCopyWith<$Res> implements $EditorPaletteSessionCopyWith<$Res> {
  factory _$EditorPaletteSessionCopyWith(_EditorPaletteSession value, $Res Function(_EditorPaletteSession) _then) = __$EditorPaletteSessionCopyWithImpl;
@override @useResult
$Res call({
 EditorPaletteContextKey? activeKey, Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts, List<String> recentTilesetIds, List<String> favoriteTilesetIds
});


@override $EditorPaletteContextKeyCopyWith<$Res>? get activeKey;

}
/// @nodoc
class __$EditorPaletteSessionCopyWithImpl<$Res>
    implements _$EditorPaletteSessionCopyWith<$Res> {
  __$EditorPaletteSessionCopyWithImpl(this._self, this._then);

  final _EditorPaletteSession _self;
  final $Res Function(_EditorPaletteSession) _then;

/// Create a copy of EditorPaletteSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeKey = freezed,Object? contexts = null,Object? recentTilesetIds = null,Object? favoriteTilesetIds = null,}) {
  return _then(_EditorPaletteSession(
activeKey: freezed == activeKey ? _self.activeKey : activeKey // ignore: cast_nullable_to_non_nullable
as EditorPaletteContextKey?,contexts: null == contexts ? _self._contexts : contexts // ignore: cast_nullable_to_non_nullable
as Map<EditorPaletteContextKey, EditorLayerPaletteContext>,recentTilesetIds: null == recentTilesetIds ? _self._recentTilesetIds : recentTilesetIds // ignore: cast_nullable_to_non_nullable
as List<String>,favoriteTilesetIds: null == favoriteTilesetIds ? _self._favoriteTilesetIds : favoriteTilesetIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of EditorPaletteSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPaletteContextKeyCopyWith<$Res>? get activeKey {
    if (_self.activeKey == null) {
    return null;
  }

  return $EditorPaletteContextKeyCopyWith<$Res>(_self.activeKey!, (value) {
    return _then(_self.copyWith(activeKey: value));
  });
}
}

// dart format on
