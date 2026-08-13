// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorBrush {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorBrush);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorBrush()';
}


}

/// @nodoc
class $EditorBrushCopyWith<$Res>  {
$EditorBrushCopyWith(EditorBrush _, $Res Function(EditorBrush) __);
}


/// Adds pattern-matching-related methods to [EditorBrush].
extension EditorBrushPatterns on EditorBrush {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NoEditorBrush value)?  none,TResult Function( TileEditorBrush value)?  tile,TResult Function( PaletteEntryEditorBrush value)?  paletteEntry,TResult Function( ProjectElementEditorBrush value)?  projectElement,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NoEditorBrush() when none != null:
return none(_that);case TileEditorBrush() when tile != null:
return tile(_that);case PaletteEntryEditorBrush() when paletteEntry != null:
return paletteEntry(_that);case ProjectElementEditorBrush() when projectElement != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NoEditorBrush value)  none,required TResult Function( TileEditorBrush value)  tile,required TResult Function( PaletteEntryEditorBrush value)  paletteEntry,required TResult Function( ProjectElementEditorBrush value)  projectElement,}){
final _that = this;
switch (_that) {
case NoEditorBrush():
return none(_that);case TileEditorBrush():
return tile(_that);case PaletteEntryEditorBrush():
return paletteEntry(_that);case ProjectElementEditorBrush():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NoEditorBrush value)?  none,TResult? Function( TileEditorBrush value)?  tile,TResult? Function( PaletteEntryEditorBrush value)?  paletteEntry,TResult? Function( ProjectElementEditorBrush value)?  projectElement,}){
final _that = this;
switch (_that) {
case NoEditorBrush() when none != null:
return none(_that);case TileEditorBrush() when tile != null:
return tile(_that);case PaletteEntryEditorBrush() when paletteEntry != null:
return paletteEntry(_that);case ProjectElementEditorBrush() when projectElement != null:
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
case NoEditorBrush() when none != null:
return none();case TileEditorBrush() when tile != null:
return tile(_that.tileId,_that.tilesetId);case PaletteEntryEditorBrush() when paletteEntry != null:
return paletteEntry(_that.entryId,_that.tilesetId);case ProjectElementEditorBrush() when projectElement != null:
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
case NoEditorBrush():
return none();case TileEditorBrush():
return tile(_that.tileId,_that.tilesetId);case PaletteEntryEditorBrush():
return paletteEntry(_that.entryId,_that.tilesetId);case ProjectElementEditorBrush():
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
case NoEditorBrush() when none != null:
return none();case TileEditorBrush() when tile != null:
return tile(_that.tileId,_that.tilesetId);case PaletteEntryEditorBrush() when paletteEntry != null:
return paletteEntry(_that.entryId,_that.tilesetId);case ProjectElementEditorBrush() when projectElement != null:
return projectElement(_that.elementId);case _:
  return null;

}
}

}

/// @nodoc


class NoEditorBrush implements EditorBrush {
  const NoEditorBrush();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoEditorBrush);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorBrush.none()';
}


}




/// @nodoc


class TileEditorBrush implements EditorBrush {
  const TileEditorBrush({required this.tileId, required this.tilesetId});
  

 final  int tileId;
 final  String tilesetId;

/// Create a copy of EditorBrush
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TileEditorBrushCopyWith<TileEditorBrush> get copyWith => _$TileEditorBrushCopyWithImpl<TileEditorBrush>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TileEditorBrush&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId));
}


@override
int get hashCode => Object.hash(runtimeType,tileId,tilesetId);

@override
String toString() {
  return 'EditorBrush.tile(tileId: $tileId, tilesetId: $tilesetId)';
}


}

/// @nodoc
abstract mixin class $TileEditorBrushCopyWith<$Res> implements $EditorBrushCopyWith<$Res> {
  factory $TileEditorBrushCopyWith(TileEditorBrush value, $Res Function(TileEditorBrush) _then) = _$TileEditorBrushCopyWithImpl;
@useResult
$Res call({
 int tileId, String tilesetId
});




}
/// @nodoc
class _$TileEditorBrushCopyWithImpl<$Res>
    implements $TileEditorBrushCopyWith<$Res> {
  _$TileEditorBrushCopyWithImpl(this._self, this._then);

  final TileEditorBrush _self;
  final $Res Function(TileEditorBrush) _then;

/// Create a copy of EditorBrush
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tileId = null,Object? tilesetId = null,}) {
  return _then(TileEditorBrush(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PaletteEntryEditorBrush implements EditorBrush {
  const PaletteEntryEditorBrush({required this.entryId, required this.tilesetId});
  

 final  String entryId;
 final  String tilesetId;

/// Create a copy of EditorBrush
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaletteEntryEditorBrushCopyWith<PaletteEntryEditorBrush> get copyWith => _$PaletteEntryEditorBrushCopyWithImpl<PaletteEntryEditorBrush>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaletteEntryEditorBrush&&(identical(other.entryId, entryId) || other.entryId == entryId)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId));
}


@override
int get hashCode => Object.hash(runtimeType,entryId,tilesetId);

@override
String toString() {
  return 'EditorBrush.paletteEntry(entryId: $entryId, tilesetId: $tilesetId)';
}


}

/// @nodoc
abstract mixin class $PaletteEntryEditorBrushCopyWith<$Res> implements $EditorBrushCopyWith<$Res> {
  factory $PaletteEntryEditorBrushCopyWith(PaletteEntryEditorBrush value, $Res Function(PaletteEntryEditorBrush) _then) = _$PaletteEntryEditorBrushCopyWithImpl;
@useResult
$Res call({
 String entryId, String tilesetId
});




}
/// @nodoc
class _$PaletteEntryEditorBrushCopyWithImpl<$Res>
    implements $PaletteEntryEditorBrushCopyWith<$Res> {
  _$PaletteEntryEditorBrushCopyWithImpl(this._self, this._then);

  final PaletteEntryEditorBrush _self;
  final $Res Function(PaletteEntryEditorBrush) _then;

/// Create a copy of EditorBrush
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entryId = null,Object? tilesetId = null,}) {
  return _then(PaletteEntryEditorBrush(
entryId: null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProjectElementEditorBrush implements EditorBrush {
  const ProjectElementEditorBrush({required this.elementId});
  

 final  String elementId;

/// Create a copy of EditorBrush
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectElementEditorBrushCopyWith<ProjectElementEditorBrush> get copyWith => _$ProjectElementEditorBrushCopyWithImpl<ProjectElementEditorBrush>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectElementEditorBrush&&(identical(other.elementId, elementId) || other.elementId == elementId));
}


@override
int get hashCode => Object.hash(runtimeType,elementId);

@override
String toString() {
  return 'EditorBrush.projectElement(elementId: $elementId)';
}


}

/// @nodoc
abstract mixin class $ProjectElementEditorBrushCopyWith<$Res> implements $EditorBrushCopyWith<$Res> {
  factory $ProjectElementEditorBrushCopyWith(ProjectElementEditorBrush value, $Res Function(ProjectElementEditorBrush) _then) = _$ProjectElementEditorBrushCopyWithImpl;
@useResult
$Res call({
 String elementId
});




}
/// @nodoc
class _$ProjectElementEditorBrushCopyWithImpl<$Res>
    implements $ProjectElementEditorBrushCopyWith<$Res> {
  _$ProjectElementEditorBrushCopyWithImpl(this._self, this._then);

  final ProjectElementEditorBrush _self;
  final $Res Function(ProjectElementEditorBrush) _then;

/// Create a copy of EditorBrush
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? elementId = null,}) {
  return _then(ProjectElementEditorBrush(
elementId: null == elementId ? _self.elementId : elementId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$EditorEraserFootprint {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorEraserFootprint);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorEraserFootprint()';
}


}

/// @nodoc
class $EditorEraserFootprintCopyWith<$Res>  {
$EditorEraserFootprintCopyWith(EditorEraserFootprint _, $Res Function(EditorEraserFootprint) __);
}


/// Adds pattern-matching-related methods to [EditorEraserFootprint].
extension EditorEraserFootprintPatterns on EditorEraserFootprint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SingleTileEditorEraserFootprint value)?  singleTile,TResult Function( PreviousBrushEditorEraserFootprint value)?  previousBrush,TResult Function( CustomEditorEraserFootprint value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SingleTileEditorEraserFootprint() when singleTile != null:
return singleTile(_that);case PreviousBrushEditorEraserFootprint() when previousBrush != null:
return previousBrush(_that);case CustomEditorEraserFootprint() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SingleTileEditorEraserFootprint value)  singleTile,required TResult Function( PreviousBrushEditorEraserFootprint value)  previousBrush,required TResult Function( CustomEditorEraserFootprint value)  custom,}){
final _that = this;
switch (_that) {
case SingleTileEditorEraserFootprint():
return singleTile(_that);case PreviousBrushEditorEraserFootprint():
return previousBrush(_that);case CustomEditorEraserFootprint():
return custom(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SingleTileEditorEraserFootprint value)?  singleTile,TResult? Function( PreviousBrushEditorEraserFootprint value)?  previousBrush,TResult? Function( CustomEditorEraserFootprint value)?  custom,}){
final _that = this;
switch (_that) {
case SingleTileEditorEraserFootprint() when singleTile != null:
return singleTile(_that);case PreviousBrushEditorEraserFootprint() when previousBrush != null:
return previousBrush(_that);case CustomEditorEraserFootprint() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  singleTile,TResult Function( GridSize size)?  previousBrush,TResult Function( GridSize size)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SingleTileEditorEraserFootprint() when singleTile != null:
return singleTile();case PreviousBrushEditorEraserFootprint() when previousBrush != null:
return previousBrush(_that.size);case CustomEditorEraserFootprint() when custom != null:
return custom(_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  singleTile,required TResult Function( GridSize size)  previousBrush,required TResult Function( GridSize size)  custom,}) {final _that = this;
switch (_that) {
case SingleTileEditorEraserFootprint():
return singleTile();case PreviousBrushEditorEraserFootprint():
return previousBrush(_that.size);case CustomEditorEraserFootprint():
return custom(_that.size);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  singleTile,TResult? Function( GridSize size)?  previousBrush,TResult? Function( GridSize size)?  custom,}) {final _that = this;
switch (_that) {
case SingleTileEditorEraserFootprint() when singleTile != null:
return singleTile();case PreviousBrushEditorEraserFootprint() when previousBrush != null:
return previousBrush(_that.size);case CustomEditorEraserFootprint() when custom != null:
return custom(_that.size);case _:
  return null;

}
}

}

/// @nodoc


class SingleTileEditorEraserFootprint implements EditorEraserFootprint {
  const SingleTileEditorEraserFootprint();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SingleTileEditorEraserFootprint);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorEraserFootprint.singleTile()';
}


}




/// @nodoc


class PreviousBrushEditorEraserFootprint implements EditorEraserFootprint {
  const PreviousBrushEditorEraserFootprint({required this.size});
  

 final  GridSize size;

/// Create a copy of EditorEraserFootprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreviousBrushEditorEraserFootprintCopyWith<PreviousBrushEditorEraserFootprint> get copyWith => _$PreviousBrushEditorEraserFootprintCopyWithImpl<PreviousBrushEditorEraserFootprint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreviousBrushEditorEraserFootprint&&(identical(other.size, size) || other.size == size));
}


@override
int get hashCode => Object.hash(runtimeType,size);

@override
String toString() {
  return 'EditorEraserFootprint.previousBrush(size: $size)';
}


}

/// @nodoc
abstract mixin class $PreviousBrushEditorEraserFootprintCopyWith<$Res> implements $EditorEraserFootprintCopyWith<$Res> {
  factory $PreviousBrushEditorEraserFootprintCopyWith(PreviousBrushEditorEraserFootprint value, $Res Function(PreviousBrushEditorEraserFootprint) _then) = _$PreviousBrushEditorEraserFootprintCopyWithImpl;
@useResult
$Res call({
 GridSize size
});


$GridSizeCopyWith<$Res> get size;

}
/// @nodoc
class _$PreviousBrushEditorEraserFootprintCopyWithImpl<$Res>
    implements $PreviousBrushEditorEraserFootprintCopyWith<$Res> {
  _$PreviousBrushEditorEraserFootprintCopyWithImpl(this._self, this._then);

  final PreviousBrushEditorEraserFootprint _self;
  final $Res Function(PreviousBrushEditorEraserFootprint) _then;

/// Create a copy of EditorEraserFootprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? size = null,}) {
  return _then(PreviousBrushEditorEraserFootprint(
size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as GridSize,
  ));
}

/// Create a copy of EditorEraserFootprint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridSizeCopyWith<$Res> get size {
  
  return $GridSizeCopyWith<$Res>(_self.size, (value) {
    return _then(_self.copyWith(size: value));
  });
}
}

/// @nodoc


class CustomEditorEraserFootprint implements EditorEraserFootprint {
  const CustomEditorEraserFootprint({required this.size});
  

 final  GridSize size;

/// Create a copy of EditorEraserFootprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomEditorEraserFootprintCopyWith<CustomEditorEraserFootprint> get copyWith => _$CustomEditorEraserFootprintCopyWithImpl<CustomEditorEraserFootprint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomEditorEraserFootprint&&(identical(other.size, size) || other.size == size));
}


@override
int get hashCode => Object.hash(runtimeType,size);

@override
String toString() {
  return 'EditorEraserFootprint.custom(size: $size)';
}


}

/// @nodoc
abstract mixin class $CustomEditorEraserFootprintCopyWith<$Res> implements $EditorEraserFootprintCopyWith<$Res> {
  factory $CustomEditorEraserFootprintCopyWith(CustomEditorEraserFootprint value, $Res Function(CustomEditorEraserFootprint) _then) = _$CustomEditorEraserFootprintCopyWithImpl;
@useResult
$Res call({
 GridSize size
});


$GridSizeCopyWith<$Res> get size;

}
/// @nodoc
class _$CustomEditorEraserFootprintCopyWithImpl<$Res>
    implements $CustomEditorEraserFootprintCopyWith<$Res> {
  _$CustomEditorEraserFootprintCopyWithImpl(this._self, this._then);

  final CustomEditorEraserFootprint _self;
  final $Res Function(CustomEditorEraserFootprint) _then;

/// Create a copy of EditorEraserFootprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? size = null,}) {
  return _then(CustomEditorEraserFootprint(
size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as GridSize,
  ));
}

/// Create a copy of EditorEraserFootprint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridSizeCopyWith<$Res> get size {
  
  return $GridSizeCopyWith<$Res>(_self.size, (value) {
    return _then(_self.copyWith(size: value));
  });
}
}

/// @nodoc
mixin _$EditorState {

// Session projet / document ouvert
 String? get projectRootPath; ProjectManifest? get project; EditorWorkspaceMode get workspaceMode; EncounterStudioSection get encounterStudioSection; String? get encounterStudioTableId; SmartTilesStudioLaunchContext get smartTilesStudioLaunchContext; PokemonCatalogSection get pokemonCatalogSection;// Document map actif
 MapData? get activeMap; String? get activeMapPath;// Outils et sélections d'édition
 EditorToolType get activeTool; String? get activeLayerId; GridPos? get hoveredTile; EditorBrush get activeBrush; MapEntityKind get selectedEntityKind; EditorEraserFootprint get eraserFootprint; CollisionBrushSizeMode get collisionBrushSizeMode; String? get selectedEntityId;/// Session de placement visuel de waypoint NPC active.
///
/// - `null` : aucun mode placement waypoint actif.
/// - non null : id de l'entité NPC ciblée par les clics map.
///
/// Le clic map est alors re-routé vers "ajout waypoint", au lieu du flux
/// d'outil normal (paint/place/select), tant que la session est valide.
 String? get npcWaypointPlacementEntityId; String? get selectedMapEventId; String? get selectedWarpId; String? get selectedTriggerId; String? get selectedGameplayZoneId;/// Lot Environment-22 : area dont le masque est édité (layer actif = Environment).
 String? get selectedEnvironmentAreaId; EnvironmentMaskEditMode? get environmentMaskEditMode;/// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
 MapRect? get gameplayZoneDraftArea; String? get selectedTilesetEditorId; String? get selectedTilesetElementGroupId; EditorPaletteSession get paletteSession; TilesElementsPanelMode get tilesElementsPanelMode; String? get selectedPlacedElementInstanceId;/// Dialogue projet sélectionné dans l’explorateur (bibliothèque).
 String? get selectedProjectDialogueId;// Rollback complet scénario/scripts:
// Les sélections dédiées au graphe scénario et à la bibliothèque de scripts
// runtime sont supprimées de l’état éditeur. Cela évite de conserver des
// états fantômes pour des surfaces UI désormais retirées.
/// Dresseur sélectionné dans la bibliothèque dresseurs.
 String? get selectedTrainerId;/// Personnage sélectionné dans la bibliothèque personnages.
 String? get selectedCharacterId; PaletteCategory? get paletteCategoryFilter;// Viewport canvas
 double get zoom; Offset get panOffset;// Statut document / historique
 List<MapHistoryEntry> get mapUndoStack; List<MapHistoryEntry> get mapRedoStack; MapHistorySnapshot? get mapStrokeStart; MapData? get savedMapSnapshot; bool get canUndoMap; bool get canRedoMap; bool get isDirty; bool get isProjectDirty; bool get isSaving; String? get statusMessage; String? get errorMessage;
/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorStateCopyWith<EditorState> get copyWith => _$EditorStateCopyWithImpl<EditorState>(this as EditorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorState&&(identical(other.projectRootPath, projectRootPath) || other.projectRootPath == projectRootPath)&&(identical(other.project, project) || other.project == project)&&(identical(other.workspaceMode, workspaceMode) || other.workspaceMode == workspaceMode)&&(identical(other.encounterStudioSection, encounterStudioSection) || other.encounterStudioSection == encounterStudioSection)&&(identical(other.encounterStudioTableId, encounterStudioTableId) || other.encounterStudioTableId == encounterStudioTableId)&&(identical(other.smartTilesStudioLaunchContext, smartTilesStudioLaunchContext) || other.smartTilesStudioLaunchContext == smartTilesStudioLaunchContext)&&(identical(other.pokemonCatalogSection, pokemonCatalogSection) || other.pokemonCatalogSection == pokemonCatalogSection)&&(identical(other.activeMap, activeMap) || other.activeMap == activeMap)&&(identical(other.activeMapPath, activeMapPath) || other.activeMapPath == activeMapPath)&&(identical(other.activeTool, activeTool) || other.activeTool == activeTool)&&(identical(other.activeLayerId, activeLayerId) || other.activeLayerId == activeLayerId)&&(identical(other.hoveredTile, hoveredTile) || other.hoveredTile == hoveredTile)&&(identical(other.activeBrush, activeBrush) || other.activeBrush == activeBrush)&&(identical(other.selectedEntityKind, selectedEntityKind) || other.selectedEntityKind == selectedEntityKind)&&(identical(other.eraserFootprint, eraserFootprint) || other.eraserFootprint == eraserFootprint)&&(identical(other.collisionBrushSizeMode, collisionBrushSizeMode) || other.collisionBrushSizeMode == collisionBrushSizeMode)&&(identical(other.selectedEntityId, selectedEntityId) || other.selectedEntityId == selectedEntityId)&&(identical(other.npcWaypointPlacementEntityId, npcWaypointPlacementEntityId) || other.npcWaypointPlacementEntityId == npcWaypointPlacementEntityId)&&(identical(other.selectedMapEventId, selectedMapEventId) || other.selectedMapEventId == selectedMapEventId)&&(identical(other.selectedWarpId, selectedWarpId) || other.selectedWarpId == selectedWarpId)&&(identical(other.selectedTriggerId, selectedTriggerId) || other.selectedTriggerId == selectedTriggerId)&&(identical(other.selectedGameplayZoneId, selectedGameplayZoneId) || other.selectedGameplayZoneId == selectedGameplayZoneId)&&(identical(other.selectedEnvironmentAreaId, selectedEnvironmentAreaId) || other.selectedEnvironmentAreaId == selectedEnvironmentAreaId)&&(identical(other.environmentMaskEditMode, environmentMaskEditMode) || other.environmentMaskEditMode == environmentMaskEditMode)&&(identical(other.gameplayZoneDraftArea, gameplayZoneDraftArea) || other.gameplayZoneDraftArea == gameplayZoneDraftArea)&&(identical(other.selectedTilesetEditorId, selectedTilesetEditorId) || other.selectedTilesetEditorId == selectedTilesetEditorId)&&(identical(other.selectedTilesetElementGroupId, selectedTilesetElementGroupId) || other.selectedTilesetElementGroupId == selectedTilesetElementGroupId)&&(identical(other.paletteSession, paletteSession) || other.paletteSession == paletteSession)&&(identical(other.tilesElementsPanelMode, tilesElementsPanelMode) || other.tilesElementsPanelMode == tilesElementsPanelMode)&&(identical(other.selectedPlacedElementInstanceId, selectedPlacedElementInstanceId) || other.selectedPlacedElementInstanceId == selectedPlacedElementInstanceId)&&(identical(other.selectedProjectDialogueId, selectedProjectDialogueId) || other.selectedProjectDialogueId == selectedProjectDialogueId)&&(identical(other.selectedTrainerId, selectedTrainerId) || other.selectedTrainerId == selectedTrainerId)&&(identical(other.selectedCharacterId, selectedCharacterId) || other.selectedCharacterId == selectedCharacterId)&&(identical(other.paletteCategoryFilter, paletteCategoryFilter) || other.paletteCategoryFilter == paletteCategoryFilter)&&(identical(other.zoom, zoom) || other.zoom == zoom)&&(identical(other.panOffset, panOffset) || other.panOffset == panOffset)&&const DeepCollectionEquality().equals(other.mapUndoStack, mapUndoStack)&&const DeepCollectionEquality().equals(other.mapRedoStack, mapRedoStack)&&(identical(other.mapStrokeStart, mapStrokeStart) || other.mapStrokeStart == mapStrokeStart)&&(identical(other.savedMapSnapshot, savedMapSnapshot) || other.savedMapSnapshot == savedMapSnapshot)&&(identical(other.canUndoMap, canUndoMap) || other.canUndoMap == canUndoMap)&&(identical(other.canRedoMap, canRedoMap) || other.canRedoMap == canRedoMap)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty)&&(identical(other.isProjectDirty, isProjectDirty) || other.isProjectDirty == isProjectDirty)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.statusMessage, statusMessage) || other.statusMessage == statusMessage)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hashAll([runtimeType,projectRootPath,project,workspaceMode,encounterStudioSection,encounterStudioTableId,smartTilesStudioLaunchContext,pokemonCatalogSection,activeMap,activeMapPath,activeTool,activeLayerId,hoveredTile,activeBrush,selectedEntityKind,eraserFootprint,collisionBrushSizeMode,selectedEntityId,npcWaypointPlacementEntityId,selectedMapEventId,selectedWarpId,selectedTriggerId,selectedGameplayZoneId,selectedEnvironmentAreaId,environmentMaskEditMode,gameplayZoneDraftArea,selectedTilesetEditorId,selectedTilesetElementGroupId,paletteSession,tilesElementsPanelMode,selectedPlacedElementInstanceId,selectedProjectDialogueId,selectedTrainerId,selectedCharacterId,paletteCategoryFilter,zoom,panOffset,const DeepCollectionEquality().hash(mapUndoStack),const DeepCollectionEquality().hash(mapRedoStack),mapStrokeStart,savedMapSnapshot,canUndoMap,canRedoMap,isDirty,isProjectDirty,isSaving,statusMessage,errorMessage]);

@override
String toString() {
  return 'EditorState(projectRootPath: $projectRootPath, project: $project, workspaceMode: $workspaceMode, encounterStudioSection: $encounterStudioSection, encounterStudioTableId: $encounterStudioTableId, smartTilesStudioLaunchContext: $smartTilesStudioLaunchContext, pokemonCatalogSection: $pokemonCatalogSection, activeMap: $activeMap, activeMapPath: $activeMapPath, activeTool: $activeTool, activeLayerId: $activeLayerId, hoveredTile: $hoveredTile, activeBrush: $activeBrush, selectedEntityKind: $selectedEntityKind, eraserFootprint: $eraserFootprint, collisionBrushSizeMode: $collisionBrushSizeMode, selectedEntityId: $selectedEntityId, npcWaypointPlacementEntityId: $npcWaypointPlacementEntityId, selectedMapEventId: $selectedMapEventId, selectedWarpId: $selectedWarpId, selectedTriggerId: $selectedTriggerId, selectedGameplayZoneId: $selectedGameplayZoneId, selectedEnvironmentAreaId: $selectedEnvironmentAreaId, environmentMaskEditMode: $environmentMaskEditMode, gameplayZoneDraftArea: $gameplayZoneDraftArea, selectedTilesetEditorId: $selectedTilesetEditorId, selectedTilesetElementGroupId: $selectedTilesetElementGroupId, paletteSession: $paletteSession, tilesElementsPanelMode: $tilesElementsPanelMode, selectedPlacedElementInstanceId: $selectedPlacedElementInstanceId, selectedProjectDialogueId: $selectedProjectDialogueId, selectedTrainerId: $selectedTrainerId, selectedCharacterId: $selectedCharacterId, paletteCategoryFilter: $paletteCategoryFilter, zoom: $zoom, panOffset: $panOffset, mapUndoStack: $mapUndoStack, mapRedoStack: $mapRedoStack, mapStrokeStart: $mapStrokeStart, savedMapSnapshot: $savedMapSnapshot, canUndoMap: $canUndoMap, canRedoMap: $canRedoMap, isDirty: $isDirty, isProjectDirty: $isProjectDirty, isSaving: $isSaving, statusMessage: $statusMessage, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $EditorStateCopyWith<$Res>  {
  factory $EditorStateCopyWith(EditorState value, $Res Function(EditorState) _then) = _$EditorStateCopyWithImpl;
@useResult
$Res call({
 String? projectRootPath, ProjectManifest? project, EditorWorkspaceMode workspaceMode, EncounterStudioSection encounterStudioSection, String? encounterStudioTableId, SmartTilesStudioLaunchContext smartTilesStudioLaunchContext, PokemonCatalogSection pokemonCatalogSection, MapData? activeMap, String? activeMapPath, EditorToolType activeTool, String? activeLayerId, GridPos? hoveredTile, EditorBrush activeBrush, MapEntityKind selectedEntityKind, EditorEraserFootprint eraserFootprint, CollisionBrushSizeMode collisionBrushSizeMode, String? selectedEntityId, String? npcWaypointPlacementEntityId, String? selectedMapEventId, String? selectedWarpId, String? selectedTriggerId, String? selectedGameplayZoneId, String? selectedEnvironmentAreaId, EnvironmentMaskEditMode? environmentMaskEditMode, MapRect? gameplayZoneDraftArea, String? selectedTilesetEditorId, String? selectedTilesetElementGroupId, EditorPaletteSession paletteSession, TilesElementsPanelMode tilesElementsPanelMode, String? selectedPlacedElementInstanceId, String? selectedProjectDialogueId, String? selectedTrainerId, String? selectedCharacterId, PaletteCategory? paletteCategoryFilter, double zoom, Offset panOffset, List<MapHistoryEntry> mapUndoStack, List<MapHistoryEntry> mapRedoStack, MapHistorySnapshot? mapStrokeStart, MapData? savedMapSnapshot, bool canUndoMap, bool canRedoMap, bool isDirty, bool isProjectDirty, bool isSaving, String? statusMessage, String? errorMessage
});


$ProjectManifestCopyWith<$Res>? get project;$MapDataCopyWith<$Res>? get activeMap;$GridPosCopyWith<$Res>? get hoveredTile;$EditorBrushCopyWith<$Res> get activeBrush;$EditorEraserFootprintCopyWith<$Res> get eraserFootprint;$MapRectCopyWith<$Res>? get gameplayZoneDraftArea;$EditorPaletteSessionCopyWith<$Res> get paletteSession;$MapHistorySnapshotCopyWith<$Res>? get mapStrokeStart;$MapDataCopyWith<$Res>? get savedMapSnapshot;

}
/// @nodoc
class _$EditorStateCopyWithImpl<$Res>
    implements $EditorStateCopyWith<$Res> {
  _$EditorStateCopyWithImpl(this._self, this._then);

  final EditorState _self;
  final $Res Function(EditorState) _then;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? projectRootPath = freezed,Object? project = freezed,Object? workspaceMode = null,Object? encounterStudioSection = null,Object? encounterStudioTableId = freezed,Object? smartTilesStudioLaunchContext = null,Object? pokemonCatalogSection = null,Object? activeMap = freezed,Object? activeMapPath = freezed,Object? activeTool = null,Object? activeLayerId = freezed,Object? hoveredTile = freezed,Object? activeBrush = null,Object? selectedEntityKind = null,Object? eraserFootprint = null,Object? collisionBrushSizeMode = null,Object? selectedEntityId = freezed,Object? npcWaypointPlacementEntityId = freezed,Object? selectedMapEventId = freezed,Object? selectedWarpId = freezed,Object? selectedTriggerId = freezed,Object? selectedGameplayZoneId = freezed,Object? selectedEnvironmentAreaId = freezed,Object? environmentMaskEditMode = freezed,Object? gameplayZoneDraftArea = freezed,Object? selectedTilesetEditorId = freezed,Object? selectedTilesetElementGroupId = freezed,Object? paletteSession = null,Object? tilesElementsPanelMode = null,Object? selectedPlacedElementInstanceId = freezed,Object? selectedProjectDialogueId = freezed,Object? selectedTrainerId = freezed,Object? selectedCharacterId = freezed,Object? paletteCategoryFilter = freezed,Object? zoom = null,Object? panOffset = null,Object? mapUndoStack = null,Object? mapRedoStack = null,Object? mapStrokeStart = freezed,Object? savedMapSnapshot = freezed,Object? canUndoMap = null,Object? canRedoMap = null,Object? isDirty = null,Object? isProjectDirty = null,Object? isSaving = null,Object? statusMessage = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
projectRootPath: freezed == projectRootPath ? _self.projectRootPath : projectRootPath // ignore: cast_nullable_to_non_nullable
as String?,project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as ProjectManifest?,workspaceMode: null == workspaceMode ? _self.workspaceMode : workspaceMode // ignore: cast_nullable_to_non_nullable
as EditorWorkspaceMode,encounterStudioSection: null == encounterStudioSection ? _self.encounterStudioSection : encounterStudioSection // ignore: cast_nullable_to_non_nullable
as EncounterStudioSection,encounterStudioTableId: freezed == encounterStudioTableId ? _self.encounterStudioTableId : encounterStudioTableId // ignore: cast_nullable_to_non_nullable
as String?,smartTilesStudioLaunchContext: null == smartTilesStudioLaunchContext ? _self.smartTilesStudioLaunchContext : smartTilesStudioLaunchContext // ignore: cast_nullable_to_non_nullable
as SmartTilesStudioLaunchContext,pokemonCatalogSection: null == pokemonCatalogSection ? _self.pokemonCatalogSection : pokemonCatalogSection // ignore: cast_nullable_to_non_nullable
as PokemonCatalogSection,activeMap: freezed == activeMap ? _self.activeMap : activeMap // ignore: cast_nullable_to_non_nullable
as MapData?,activeMapPath: freezed == activeMapPath ? _self.activeMapPath : activeMapPath // ignore: cast_nullable_to_non_nullable
as String?,activeTool: null == activeTool ? _self.activeTool : activeTool // ignore: cast_nullable_to_non_nullable
as EditorToolType,activeLayerId: freezed == activeLayerId ? _self.activeLayerId : activeLayerId // ignore: cast_nullable_to_non_nullable
as String?,hoveredTile: freezed == hoveredTile ? _self.hoveredTile : hoveredTile // ignore: cast_nullable_to_non_nullable
as GridPos?,activeBrush: null == activeBrush ? _self.activeBrush : activeBrush // ignore: cast_nullable_to_non_nullable
as EditorBrush,selectedEntityKind: null == selectedEntityKind ? _self.selectedEntityKind : selectedEntityKind // ignore: cast_nullable_to_non_nullable
as MapEntityKind,eraserFootprint: null == eraserFootprint ? _self.eraserFootprint : eraserFootprint // ignore: cast_nullable_to_non_nullable
as EditorEraserFootprint,collisionBrushSizeMode: null == collisionBrushSizeMode ? _self.collisionBrushSizeMode : collisionBrushSizeMode // ignore: cast_nullable_to_non_nullable
as CollisionBrushSizeMode,selectedEntityId: freezed == selectedEntityId ? _self.selectedEntityId : selectedEntityId // ignore: cast_nullable_to_non_nullable
as String?,npcWaypointPlacementEntityId: freezed == npcWaypointPlacementEntityId ? _self.npcWaypointPlacementEntityId : npcWaypointPlacementEntityId // ignore: cast_nullable_to_non_nullable
as String?,selectedMapEventId: freezed == selectedMapEventId ? _self.selectedMapEventId : selectedMapEventId // ignore: cast_nullable_to_non_nullable
as String?,selectedWarpId: freezed == selectedWarpId ? _self.selectedWarpId : selectedWarpId // ignore: cast_nullable_to_non_nullable
as String?,selectedTriggerId: freezed == selectedTriggerId ? _self.selectedTriggerId : selectedTriggerId // ignore: cast_nullable_to_non_nullable
as String?,selectedGameplayZoneId: freezed == selectedGameplayZoneId ? _self.selectedGameplayZoneId : selectedGameplayZoneId // ignore: cast_nullable_to_non_nullable
as String?,selectedEnvironmentAreaId: freezed == selectedEnvironmentAreaId ? _self.selectedEnvironmentAreaId : selectedEnvironmentAreaId // ignore: cast_nullable_to_non_nullable
as String?,environmentMaskEditMode: freezed == environmentMaskEditMode ? _self.environmentMaskEditMode : environmentMaskEditMode // ignore: cast_nullable_to_non_nullable
as EnvironmentMaskEditMode?,gameplayZoneDraftArea: freezed == gameplayZoneDraftArea ? _self.gameplayZoneDraftArea : gameplayZoneDraftArea // ignore: cast_nullable_to_non_nullable
as MapRect?,selectedTilesetEditorId: freezed == selectedTilesetEditorId ? _self.selectedTilesetEditorId : selectedTilesetEditorId // ignore: cast_nullable_to_non_nullable
as String?,selectedTilesetElementGroupId: freezed == selectedTilesetElementGroupId ? _self.selectedTilesetElementGroupId : selectedTilesetElementGroupId // ignore: cast_nullable_to_non_nullable
as String?,paletteSession: null == paletteSession ? _self.paletteSession : paletteSession // ignore: cast_nullable_to_non_nullable
as EditorPaletteSession,tilesElementsPanelMode: null == tilesElementsPanelMode ? _self.tilesElementsPanelMode : tilesElementsPanelMode // ignore: cast_nullable_to_non_nullable
as TilesElementsPanelMode,selectedPlacedElementInstanceId: freezed == selectedPlacedElementInstanceId ? _self.selectedPlacedElementInstanceId : selectedPlacedElementInstanceId // ignore: cast_nullable_to_non_nullable
as String?,selectedProjectDialogueId: freezed == selectedProjectDialogueId ? _self.selectedProjectDialogueId : selectedProjectDialogueId // ignore: cast_nullable_to_non_nullable
as String?,selectedTrainerId: freezed == selectedTrainerId ? _self.selectedTrainerId : selectedTrainerId // ignore: cast_nullable_to_non_nullable
as String?,selectedCharacterId: freezed == selectedCharacterId ? _self.selectedCharacterId : selectedCharacterId // ignore: cast_nullable_to_non_nullable
as String?,paletteCategoryFilter: freezed == paletteCategoryFilter ? _self.paletteCategoryFilter : paletteCategoryFilter // ignore: cast_nullable_to_non_nullable
as PaletteCategory?,zoom: null == zoom ? _self.zoom : zoom // ignore: cast_nullable_to_non_nullable
as double,panOffset: null == panOffset ? _self.panOffset : panOffset // ignore: cast_nullable_to_non_nullable
as Offset,mapUndoStack: null == mapUndoStack ? _self.mapUndoStack : mapUndoStack // ignore: cast_nullable_to_non_nullable
as List<MapHistoryEntry>,mapRedoStack: null == mapRedoStack ? _self.mapRedoStack : mapRedoStack // ignore: cast_nullable_to_non_nullable
as List<MapHistoryEntry>,mapStrokeStart: freezed == mapStrokeStart ? _self.mapStrokeStart : mapStrokeStart // ignore: cast_nullable_to_non_nullable
as MapHistorySnapshot?,savedMapSnapshot: freezed == savedMapSnapshot ? _self.savedMapSnapshot : savedMapSnapshot // ignore: cast_nullable_to_non_nullable
as MapData?,canUndoMap: null == canUndoMap ? _self.canUndoMap : canUndoMap // ignore: cast_nullable_to_non_nullable
as bool,canRedoMap: null == canRedoMap ? _self.canRedoMap : canRedoMap // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,isProjectDirty: null == isProjectDirty ? _self.isProjectDirty : isProjectDirty // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,statusMessage: freezed == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectManifestCopyWith<$Res>? get project {
    if (_self.project == null) {
    return null;
  }

  return $ProjectManifestCopyWith<$Res>(_self.project!, (value) {
    return _then(_self.copyWith(project: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapDataCopyWith<$Res>? get activeMap {
    if (_self.activeMap == null) {
    return null;
  }

  return $MapDataCopyWith<$Res>(_self.activeMap!, (value) {
    return _then(_self.copyWith(activeMap: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res>? get hoveredTile {
    if (_self.hoveredTile == null) {
    return null;
  }

  return $GridPosCopyWith<$Res>(_self.hoveredTile!, (value) {
    return _then(_self.copyWith(hoveredTile: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorBrushCopyWith<$Res> get activeBrush {
  
  return $EditorBrushCopyWith<$Res>(_self.activeBrush, (value) {
    return _then(_self.copyWith(activeBrush: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorEraserFootprintCopyWith<$Res> get eraserFootprint {
  
  return $EditorEraserFootprintCopyWith<$Res>(_self.eraserFootprint, (value) {
    return _then(_self.copyWith(eraserFootprint: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRectCopyWith<$Res>? get gameplayZoneDraftArea {
    if (_self.gameplayZoneDraftArea == null) {
    return null;
  }

  return $MapRectCopyWith<$Res>(_self.gameplayZoneDraftArea!, (value) {
    return _then(_self.copyWith(gameplayZoneDraftArea: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPaletteSessionCopyWith<$Res> get paletteSession {
  
  return $EditorPaletteSessionCopyWith<$Res>(_self.paletteSession, (value) {
    return _then(_self.copyWith(paletteSession: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapHistorySnapshotCopyWith<$Res>? get mapStrokeStart {
    if (_self.mapStrokeStart == null) {
    return null;
  }

  return $MapHistorySnapshotCopyWith<$Res>(_self.mapStrokeStart!, (value) {
    return _then(_self.copyWith(mapStrokeStart: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapDataCopyWith<$Res>? get savedMapSnapshot {
    if (_self.savedMapSnapshot == null) {
    return null;
  }

  return $MapDataCopyWith<$Res>(_self.savedMapSnapshot!, (value) {
    return _then(_self.copyWith(savedMapSnapshot: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorState].
extension EditorStatePatterns on EditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorState value)  $default,){
final _that = this;
switch (_that) {
case _EditorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorState value)?  $default,){
final _that = this;
switch (_that) {
case _EditorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? projectRootPath,  ProjectManifest? project,  EditorWorkspaceMode workspaceMode,  EncounterStudioSection encounterStudioSection,  String? encounterStudioTableId,  SmartTilesStudioLaunchContext smartTilesStudioLaunchContext,  PokemonCatalogSection pokemonCatalogSection,  MapData? activeMap,  String? activeMapPath,  EditorToolType activeTool,  String? activeLayerId,  GridPos? hoveredTile,  EditorBrush activeBrush,  MapEntityKind selectedEntityKind,  EditorEraserFootprint eraserFootprint,  CollisionBrushSizeMode collisionBrushSizeMode,  String? selectedEntityId,  String? npcWaypointPlacementEntityId,  String? selectedMapEventId,  String? selectedWarpId,  String? selectedTriggerId,  String? selectedGameplayZoneId,  String? selectedEnvironmentAreaId,  EnvironmentMaskEditMode? environmentMaskEditMode,  MapRect? gameplayZoneDraftArea,  String? selectedTilesetEditorId,  String? selectedTilesetElementGroupId,  EditorPaletteSession paletteSession,  TilesElementsPanelMode tilesElementsPanelMode,  String? selectedPlacedElementInstanceId,  String? selectedProjectDialogueId,  String? selectedTrainerId,  String? selectedCharacterId,  PaletteCategory? paletteCategoryFilter,  double zoom,  Offset panOffset,  List<MapHistoryEntry> mapUndoStack,  List<MapHistoryEntry> mapRedoStack,  MapHistorySnapshot? mapStrokeStart,  MapData? savedMapSnapshot,  bool canUndoMap,  bool canRedoMap,  bool isDirty,  bool isProjectDirty,  bool isSaving,  String? statusMessage,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorState() when $default != null:
return $default(_that.projectRootPath,_that.project,_that.workspaceMode,_that.encounterStudioSection,_that.encounterStudioTableId,_that.smartTilesStudioLaunchContext,_that.pokemonCatalogSection,_that.activeMap,_that.activeMapPath,_that.activeTool,_that.activeLayerId,_that.hoveredTile,_that.activeBrush,_that.selectedEntityKind,_that.eraserFootprint,_that.collisionBrushSizeMode,_that.selectedEntityId,_that.npcWaypointPlacementEntityId,_that.selectedMapEventId,_that.selectedWarpId,_that.selectedTriggerId,_that.selectedGameplayZoneId,_that.selectedEnvironmentAreaId,_that.environmentMaskEditMode,_that.gameplayZoneDraftArea,_that.selectedTilesetEditorId,_that.selectedTilesetElementGroupId,_that.paletteSession,_that.tilesElementsPanelMode,_that.selectedPlacedElementInstanceId,_that.selectedProjectDialogueId,_that.selectedTrainerId,_that.selectedCharacterId,_that.paletteCategoryFilter,_that.zoom,_that.panOffset,_that.mapUndoStack,_that.mapRedoStack,_that.mapStrokeStart,_that.savedMapSnapshot,_that.canUndoMap,_that.canRedoMap,_that.isDirty,_that.isProjectDirty,_that.isSaving,_that.statusMessage,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? projectRootPath,  ProjectManifest? project,  EditorWorkspaceMode workspaceMode,  EncounterStudioSection encounterStudioSection,  String? encounterStudioTableId,  SmartTilesStudioLaunchContext smartTilesStudioLaunchContext,  PokemonCatalogSection pokemonCatalogSection,  MapData? activeMap,  String? activeMapPath,  EditorToolType activeTool,  String? activeLayerId,  GridPos? hoveredTile,  EditorBrush activeBrush,  MapEntityKind selectedEntityKind,  EditorEraserFootprint eraserFootprint,  CollisionBrushSizeMode collisionBrushSizeMode,  String? selectedEntityId,  String? npcWaypointPlacementEntityId,  String? selectedMapEventId,  String? selectedWarpId,  String? selectedTriggerId,  String? selectedGameplayZoneId,  String? selectedEnvironmentAreaId,  EnvironmentMaskEditMode? environmentMaskEditMode,  MapRect? gameplayZoneDraftArea,  String? selectedTilesetEditorId,  String? selectedTilesetElementGroupId,  EditorPaletteSession paletteSession,  TilesElementsPanelMode tilesElementsPanelMode,  String? selectedPlacedElementInstanceId,  String? selectedProjectDialogueId,  String? selectedTrainerId,  String? selectedCharacterId,  PaletteCategory? paletteCategoryFilter,  double zoom,  Offset panOffset,  List<MapHistoryEntry> mapUndoStack,  List<MapHistoryEntry> mapRedoStack,  MapHistorySnapshot? mapStrokeStart,  MapData? savedMapSnapshot,  bool canUndoMap,  bool canRedoMap,  bool isDirty,  bool isProjectDirty,  bool isSaving,  String? statusMessage,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _EditorState():
return $default(_that.projectRootPath,_that.project,_that.workspaceMode,_that.encounterStudioSection,_that.encounterStudioTableId,_that.smartTilesStudioLaunchContext,_that.pokemonCatalogSection,_that.activeMap,_that.activeMapPath,_that.activeTool,_that.activeLayerId,_that.hoveredTile,_that.activeBrush,_that.selectedEntityKind,_that.eraserFootprint,_that.collisionBrushSizeMode,_that.selectedEntityId,_that.npcWaypointPlacementEntityId,_that.selectedMapEventId,_that.selectedWarpId,_that.selectedTriggerId,_that.selectedGameplayZoneId,_that.selectedEnvironmentAreaId,_that.environmentMaskEditMode,_that.gameplayZoneDraftArea,_that.selectedTilesetEditorId,_that.selectedTilesetElementGroupId,_that.paletteSession,_that.tilesElementsPanelMode,_that.selectedPlacedElementInstanceId,_that.selectedProjectDialogueId,_that.selectedTrainerId,_that.selectedCharacterId,_that.paletteCategoryFilter,_that.zoom,_that.panOffset,_that.mapUndoStack,_that.mapRedoStack,_that.mapStrokeStart,_that.savedMapSnapshot,_that.canUndoMap,_that.canRedoMap,_that.isDirty,_that.isProjectDirty,_that.isSaving,_that.statusMessage,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? projectRootPath,  ProjectManifest? project,  EditorWorkspaceMode workspaceMode,  EncounterStudioSection encounterStudioSection,  String? encounterStudioTableId,  SmartTilesStudioLaunchContext smartTilesStudioLaunchContext,  PokemonCatalogSection pokemonCatalogSection,  MapData? activeMap,  String? activeMapPath,  EditorToolType activeTool,  String? activeLayerId,  GridPos? hoveredTile,  EditorBrush activeBrush,  MapEntityKind selectedEntityKind,  EditorEraserFootprint eraserFootprint,  CollisionBrushSizeMode collisionBrushSizeMode,  String? selectedEntityId,  String? npcWaypointPlacementEntityId,  String? selectedMapEventId,  String? selectedWarpId,  String? selectedTriggerId,  String? selectedGameplayZoneId,  String? selectedEnvironmentAreaId,  EnvironmentMaskEditMode? environmentMaskEditMode,  MapRect? gameplayZoneDraftArea,  String? selectedTilesetEditorId,  String? selectedTilesetElementGroupId,  EditorPaletteSession paletteSession,  TilesElementsPanelMode tilesElementsPanelMode,  String? selectedPlacedElementInstanceId,  String? selectedProjectDialogueId,  String? selectedTrainerId,  String? selectedCharacterId,  PaletteCategory? paletteCategoryFilter,  double zoom,  Offset panOffset,  List<MapHistoryEntry> mapUndoStack,  List<MapHistoryEntry> mapRedoStack,  MapHistorySnapshot? mapStrokeStart,  MapData? savedMapSnapshot,  bool canUndoMap,  bool canRedoMap,  bool isDirty,  bool isProjectDirty,  bool isSaving,  String? statusMessage,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _EditorState() when $default != null:
return $default(_that.projectRootPath,_that.project,_that.workspaceMode,_that.encounterStudioSection,_that.encounterStudioTableId,_that.smartTilesStudioLaunchContext,_that.pokemonCatalogSection,_that.activeMap,_that.activeMapPath,_that.activeTool,_that.activeLayerId,_that.hoveredTile,_that.activeBrush,_that.selectedEntityKind,_that.eraserFootprint,_that.collisionBrushSizeMode,_that.selectedEntityId,_that.npcWaypointPlacementEntityId,_that.selectedMapEventId,_that.selectedWarpId,_that.selectedTriggerId,_that.selectedGameplayZoneId,_that.selectedEnvironmentAreaId,_that.environmentMaskEditMode,_that.gameplayZoneDraftArea,_that.selectedTilesetEditorId,_that.selectedTilesetElementGroupId,_that.paletteSession,_that.tilesElementsPanelMode,_that.selectedPlacedElementInstanceId,_that.selectedProjectDialogueId,_that.selectedTrainerId,_that.selectedCharacterId,_that.paletteCategoryFilter,_that.zoom,_that.panOffset,_that.mapUndoStack,_that.mapRedoStack,_that.mapStrokeStart,_that.savedMapSnapshot,_that.canUndoMap,_that.canRedoMap,_that.isDirty,_that.isProjectDirty,_that.isSaving,_that.statusMessage,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _EditorState implements EditorState {
  const _EditorState({this.projectRootPath, this.project, this.workspaceMode = EditorWorkspaceMode.map, this.encounterStudioSection = EncounterStudioSection.wildEncounters, this.encounterStudioTableId, this.smartTilesStudioLaunchContext = const SmartTilesStudioLaunchContext.library(), this.pokemonCatalogSection = PokemonCatalogSection.pokedex, this.activeMap, this.activeMapPath, this.activeTool = EditorToolType.selection, this.activeLayerId, this.hoveredTile, this.activeBrush = const EditorBrush.none(), this.selectedEntityKind = MapEntityKind.npc, this.eraserFootprint = const EditorEraserFootprint.singleTile(), this.collisionBrushSizeMode = CollisionBrushSizeMode.brushFootprint, this.selectedEntityId, this.npcWaypointPlacementEntityId, this.selectedMapEventId, this.selectedWarpId, this.selectedTriggerId, this.selectedGameplayZoneId, this.selectedEnvironmentAreaId, this.environmentMaskEditMode, this.gameplayZoneDraftArea, this.selectedTilesetEditorId, this.selectedTilesetElementGroupId, this.paletteSession = const EditorPaletteSession(), this.tilesElementsPanelMode = TilesElementsPanelMode.palette, this.selectedPlacedElementInstanceId, this.selectedProjectDialogueId, this.selectedTrainerId, this.selectedCharacterId, this.paletteCategoryFilter, this.zoom = 1.0, this.panOffset = Offset.zero, final  List<MapHistoryEntry> mapUndoStack = const [], final  List<MapHistoryEntry> mapRedoStack = const [], this.mapStrokeStart, this.savedMapSnapshot, this.canUndoMap = false, this.canRedoMap = false, this.isDirty = false, this.isProjectDirty = false, this.isSaving = false, this.statusMessage, this.errorMessage}): _mapUndoStack = mapUndoStack,_mapRedoStack = mapRedoStack;
  

// Session projet / document ouvert
@override final  String? projectRootPath;
@override final  ProjectManifest? project;
@override@JsonKey() final  EditorWorkspaceMode workspaceMode;
@override@JsonKey() final  EncounterStudioSection encounterStudioSection;
@override final  String? encounterStudioTableId;
@override@JsonKey() final  SmartTilesStudioLaunchContext smartTilesStudioLaunchContext;
@override@JsonKey() final  PokemonCatalogSection pokemonCatalogSection;
// Document map actif
@override final  MapData? activeMap;
@override final  String? activeMapPath;
// Outils et sélections d'édition
@override@JsonKey() final  EditorToolType activeTool;
@override final  String? activeLayerId;
@override final  GridPos? hoveredTile;
@override@JsonKey() final  EditorBrush activeBrush;
@override@JsonKey() final  MapEntityKind selectedEntityKind;
@override@JsonKey() final  EditorEraserFootprint eraserFootprint;
@override@JsonKey() final  CollisionBrushSizeMode collisionBrushSizeMode;
@override final  String? selectedEntityId;
/// Session de placement visuel de waypoint NPC active.
///
/// - `null` : aucun mode placement waypoint actif.
/// - non null : id de l'entité NPC ciblée par les clics map.
///
/// Le clic map est alors re-routé vers "ajout waypoint", au lieu du flux
/// d'outil normal (paint/place/select), tant que la session est valide.
@override final  String? npcWaypointPlacementEntityId;
@override final  String? selectedMapEventId;
@override final  String? selectedWarpId;
@override final  String? selectedTriggerId;
@override final  String? selectedGameplayZoneId;
/// Lot Environment-22 : area dont le masque est édité (layer actif = Environment).
@override final  String? selectedEnvironmentAreaId;
@override final  EnvironmentMaskEditMode? environmentMaskEditMode;
/// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
@override final  MapRect? gameplayZoneDraftArea;
@override final  String? selectedTilesetEditorId;
@override final  String? selectedTilesetElementGroupId;
@override@JsonKey() final  EditorPaletteSession paletteSession;
@override@JsonKey() final  TilesElementsPanelMode tilesElementsPanelMode;
@override final  String? selectedPlacedElementInstanceId;
/// Dialogue projet sélectionné dans l’explorateur (bibliothèque).
@override final  String? selectedProjectDialogueId;
// Rollback complet scénario/scripts:
// Les sélections dédiées au graphe scénario et à la bibliothèque de scripts
// runtime sont supprimées de l’état éditeur. Cela évite de conserver des
// états fantômes pour des surfaces UI désormais retirées.
/// Dresseur sélectionné dans la bibliothèque dresseurs.
@override final  String? selectedTrainerId;
/// Personnage sélectionné dans la bibliothèque personnages.
@override final  String? selectedCharacterId;
@override final  PaletteCategory? paletteCategoryFilter;
// Viewport canvas
@override@JsonKey() final  double zoom;
@override@JsonKey() final  Offset panOffset;
// Statut document / historique
 final  List<MapHistoryEntry> _mapUndoStack;
// Statut document / historique
@override@JsonKey() List<MapHistoryEntry> get mapUndoStack {
  if (_mapUndoStack is EqualUnmodifiableListView) return _mapUndoStack;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mapUndoStack);
}

 final  List<MapHistoryEntry> _mapRedoStack;
@override@JsonKey() List<MapHistoryEntry> get mapRedoStack {
  if (_mapRedoStack is EqualUnmodifiableListView) return _mapRedoStack;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mapRedoStack);
}

@override final  MapHistorySnapshot? mapStrokeStart;
@override final  MapData? savedMapSnapshot;
@override@JsonKey() final  bool canUndoMap;
@override@JsonKey() final  bool canRedoMap;
@override@JsonKey() final  bool isDirty;
@override@JsonKey() final  bool isProjectDirty;
@override@JsonKey() final  bool isSaving;
@override final  String? statusMessage;
@override final  String? errorMessage;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorStateCopyWith<_EditorState> get copyWith => __$EditorStateCopyWithImpl<_EditorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorState&&(identical(other.projectRootPath, projectRootPath) || other.projectRootPath == projectRootPath)&&(identical(other.project, project) || other.project == project)&&(identical(other.workspaceMode, workspaceMode) || other.workspaceMode == workspaceMode)&&(identical(other.encounterStudioSection, encounterStudioSection) || other.encounterStudioSection == encounterStudioSection)&&(identical(other.encounterStudioTableId, encounterStudioTableId) || other.encounterStudioTableId == encounterStudioTableId)&&(identical(other.smartTilesStudioLaunchContext, smartTilesStudioLaunchContext) || other.smartTilesStudioLaunchContext == smartTilesStudioLaunchContext)&&(identical(other.pokemonCatalogSection, pokemonCatalogSection) || other.pokemonCatalogSection == pokemonCatalogSection)&&(identical(other.activeMap, activeMap) || other.activeMap == activeMap)&&(identical(other.activeMapPath, activeMapPath) || other.activeMapPath == activeMapPath)&&(identical(other.activeTool, activeTool) || other.activeTool == activeTool)&&(identical(other.activeLayerId, activeLayerId) || other.activeLayerId == activeLayerId)&&(identical(other.hoveredTile, hoveredTile) || other.hoveredTile == hoveredTile)&&(identical(other.activeBrush, activeBrush) || other.activeBrush == activeBrush)&&(identical(other.selectedEntityKind, selectedEntityKind) || other.selectedEntityKind == selectedEntityKind)&&(identical(other.eraserFootprint, eraserFootprint) || other.eraserFootprint == eraserFootprint)&&(identical(other.collisionBrushSizeMode, collisionBrushSizeMode) || other.collisionBrushSizeMode == collisionBrushSizeMode)&&(identical(other.selectedEntityId, selectedEntityId) || other.selectedEntityId == selectedEntityId)&&(identical(other.npcWaypointPlacementEntityId, npcWaypointPlacementEntityId) || other.npcWaypointPlacementEntityId == npcWaypointPlacementEntityId)&&(identical(other.selectedMapEventId, selectedMapEventId) || other.selectedMapEventId == selectedMapEventId)&&(identical(other.selectedWarpId, selectedWarpId) || other.selectedWarpId == selectedWarpId)&&(identical(other.selectedTriggerId, selectedTriggerId) || other.selectedTriggerId == selectedTriggerId)&&(identical(other.selectedGameplayZoneId, selectedGameplayZoneId) || other.selectedGameplayZoneId == selectedGameplayZoneId)&&(identical(other.selectedEnvironmentAreaId, selectedEnvironmentAreaId) || other.selectedEnvironmentAreaId == selectedEnvironmentAreaId)&&(identical(other.environmentMaskEditMode, environmentMaskEditMode) || other.environmentMaskEditMode == environmentMaskEditMode)&&(identical(other.gameplayZoneDraftArea, gameplayZoneDraftArea) || other.gameplayZoneDraftArea == gameplayZoneDraftArea)&&(identical(other.selectedTilesetEditorId, selectedTilesetEditorId) || other.selectedTilesetEditorId == selectedTilesetEditorId)&&(identical(other.selectedTilesetElementGroupId, selectedTilesetElementGroupId) || other.selectedTilesetElementGroupId == selectedTilesetElementGroupId)&&(identical(other.paletteSession, paletteSession) || other.paletteSession == paletteSession)&&(identical(other.tilesElementsPanelMode, tilesElementsPanelMode) || other.tilesElementsPanelMode == tilesElementsPanelMode)&&(identical(other.selectedPlacedElementInstanceId, selectedPlacedElementInstanceId) || other.selectedPlacedElementInstanceId == selectedPlacedElementInstanceId)&&(identical(other.selectedProjectDialogueId, selectedProjectDialogueId) || other.selectedProjectDialogueId == selectedProjectDialogueId)&&(identical(other.selectedTrainerId, selectedTrainerId) || other.selectedTrainerId == selectedTrainerId)&&(identical(other.selectedCharacterId, selectedCharacterId) || other.selectedCharacterId == selectedCharacterId)&&(identical(other.paletteCategoryFilter, paletteCategoryFilter) || other.paletteCategoryFilter == paletteCategoryFilter)&&(identical(other.zoom, zoom) || other.zoom == zoom)&&(identical(other.panOffset, panOffset) || other.panOffset == panOffset)&&const DeepCollectionEquality().equals(other._mapUndoStack, _mapUndoStack)&&const DeepCollectionEquality().equals(other._mapRedoStack, _mapRedoStack)&&(identical(other.mapStrokeStart, mapStrokeStart) || other.mapStrokeStart == mapStrokeStart)&&(identical(other.savedMapSnapshot, savedMapSnapshot) || other.savedMapSnapshot == savedMapSnapshot)&&(identical(other.canUndoMap, canUndoMap) || other.canUndoMap == canUndoMap)&&(identical(other.canRedoMap, canRedoMap) || other.canRedoMap == canRedoMap)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty)&&(identical(other.isProjectDirty, isProjectDirty) || other.isProjectDirty == isProjectDirty)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.statusMessage, statusMessage) || other.statusMessage == statusMessage)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hashAll([runtimeType,projectRootPath,project,workspaceMode,encounterStudioSection,encounterStudioTableId,smartTilesStudioLaunchContext,pokemonCatalogSection,activeMap,activeMapPath,activeTool,activeLayerId,hoveredTile,activeBrush,selectedEntityKind,eraserFootprint,collisionBrushSizeMode,selectedEntityId,npcWaypointPlacementEntityId,selectedMapEventId,selectedWarpId,selectedTriggerId,selectedGameplayZoneId,selectedEnvironmentAreaId,environmentMaskEditMode,gameplayZoneDraftArea,selectedTilesetEditorId,selectedTilesetElementGroupId,paletteSession,tilesElementsPanelMode,selectedPlacedElementInstanceId,selectedProjectDialogueId,selectedTrainerId,selectedCharacterId,paletteCategoryFilter,zoom,panOffset,const DeepCollectionEquality().hash(_mapUndoStack),const DeepCollectionEquality().hash(_mapRedoStack),mapStrokeStart,savedMapSnapshot,canUndoMap,canRedoMap,isDirty,isProjectDirty,isSaving,statusMessage,errorMessage]);

@override
String toString() {
  return 'EditorState(projectRootPath: $projectRootPath, project: $project, workspaceMode: $workspaceMode, encounterStudioSection: $encounterStudioSection, encounterStudioTableId: $encounterStudioTableId, smartTilesStudioLaunchContext: $smartTilesStudioLaunchContext, pokemonCatalogSection: $pokemonCatalogSection, activeMap: $activeMap, activeMapPath: $activeMapPath, activeTool: $activeTool, activeLayerId: $activeLayerId, hoveredTile: $hoveredTile, activeBrush: $activeBrush, selectedEntityKind: $selectedEntityKind, eraserFootprint: $eraserFootprint, collisionBrushSizeMode: $collisionBrushSizeMode, selectedEntityId: $selectedEntityId, npcWaypointPlacementEntityId: $npcWaypointPlacementEntityId, selectedMapEventId: $selectedMapEventId, selectedWarpId: $selectedWarpId, selectedTriggerId: $selectedTriggerId, selectedGameplayZoneId: $selectedGameplayZoneId, selectedEnvironmentAreaId: $selectedEnvironmentAreaId, environmentMaskEditMode: $environmentMaskEditMode, gameplayZoneDraftArea: $gameplayZoneDraftArea, selectedTilesetEditorId: $selectedTilesetEditorId, selectedTilesetElementGroupId: $selectedTilesetElementGroupId, paletteSession: $paletteSession, tilesElementsPanelMode: $tilesElementsPanelMode, selectedPlacedElementInstanceId: $selectedPlacedElementInstanceId, selectedProjectDialogueId: $selectedProjectDialogueId, selectedTrainerId: $selectedTrainerId, selectedCharacterId: $selectedCharacterId, paletteCategoryFilter: $paletteCategoryFilter, zoom: $zoom, panOffset: $panOffset, mapUndoStack: $mapUndoStack, mapRedoStack: $mapRedoStack, mapStrokeStart: $mapStrokeStart, savedMapSnapshot: $savedMapSnapshot, canUndoMap: $canUndoMap, canRedoMap: $canRedoMap, isDirty: $isDirty, isProjectDirty: $isProjectDirty, isSaving: $isSaving, statusMessage: $statusMessage, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$EditorStateCopyWith<$Res> implements $EditorStateCopyWith<$Res> {
  factory _$EditorStateCopyWith(_EditorState value, $Res Function(_EditorState) _then) = __$EditorStateCopyWithImpl;
@override @useResult
$Res call({
 String? projectRootPath, ProjectManifest? project, EditorWorkspaceMode workspaceMode, EncounterStudioSection encounterStudioSection, String? encounterStudioTableId, SmartTilesStudioLaunchContext smartTilesStudioLaunchContext, PokemonCatalogSection pokemonCatalogSection, MapData? activeMap, String? activeMapPath, EditorToolType activeTool, String? activeLayerId, GridPos? hoveredTile, EditorBrush activeBrush, MapEntityKind selectedEntityKind, EditorEraserFootprint eraserFootprint, CollisionBrushSizeMode collisionBrushSizeMode, String? selectedEntityId, String? npcWaypointPlacementEntityId, String? selectedMapEventId, String? selectedWarpId, String? selectedTriggerId, String? selectedGameplayZoneId, String? selectedEnvironmentAreaId, EnvironmentMaskEditMode? environmentMaskEditMode, MapRect? gameplayZoneDraftArea, String? selectedTilesetEditorId, String? selectedTilesetElementGroupId, EditorPaletteSession paletteSession, TilesElementsPanelMode tilesElementsPanelMode, String? selectedPlacedElementInstanceId, String? selectedProjectDialogueId, String? selectedTrainerId, String? selectedCharacterId, PaletteCategory? paletteCategoryFilter, double zoom, Offset panOffset, List<MapHistoryEntry> mapUndoStack, List<MapHistoryEntry> mapRedoStack, MapHistorySnapshot? mapStrokeStart, MapData? savedMapSnapshot, bool canUndoMap, bool canRedoMap, bool isDirty, bool isProjectDirty, bool isSaving, String? statusMessage, String? errorMessage
});


@override $ProjectManifestCopyWith<$Res>? get project;@override $MapDataCopyWith<$Res>? get activeMap;@override $GridPosCopyWith<$Res>? get hoveredTile;@override $EditorBrushCopyWith<$Res> get activeBrush;@override $EditorEraserFootprintCopyWith<$Res> get eraserFootprint;@override $MapRectCopyWith<$Res>? get gameplayZoneDraftArea;@override $EditorPaletteSessionCopyWith<$Res> get paletteSession;@override $MapHistorySnapshotCopyWith<$Res>? get mapStrokeStart;@override $MapDataCopyWith<$Res>? get savedMapSnapshot;

}
/// @nodoc
class __$EditorStateCopyWithImpl<$Res>
    implements _$EditorStateCopyWith<$Res> {
  __$EditorStateCopyWithImpl(this._self, this._then);

  final _EditorState _self;
  final $Res Function(_EditorState) _then;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? projectRootPath = freezed,Object? project = freezed,Object? workspaceMode = null,Object? encounterStudioSection = null,Object? encounterStudioTableId = freezed,Object? smartTilesStudioLaunchContext = null,Object? pokemonCatalogSection = null,Object? activeMap = freezed,Object? activeMapPath = freezed,Object? activeTool = null,Object? activeLayerId = freezed,Object? hoveredTile = freezed,Object? activeBrush = null,Object? selectedEntityKind = null,Object? eraserFootprint = null,Object? collisionBrushSizeMode = null,Object? selectedEntityId = freezed,Object? npcWaypointPlacementEntityId = freezed,Object? selectedMapEventId = freezed,Object? selectedWarpId = freezed,Object? selectedTriggerId = freezed,Object? selectedGameplayZoneId = freezed,Object? selectedEnvironmentAreaId = freezed,Object? environmentMaskEditMode = freezed,Object? gameplayZoneDraftArea = freezed,Object? selectedTilesetEditorId = freezed,Object? selectedTilesetElementGroupId = freezed,Object? paletteSession = null,Object? tilesElementsPanelMode = null,Object? selectedPlacedElementInstanceId = freezed,Object? selectedProjectDialogueId = freezed,Object? selectedTrainerId = freezed,Object? selectedCharacterId = freezed,Object? paletteCategoryFilter = freezed,Object? zoom = null,Object? panOffset = null,Object? mapUndoStack = null,Object? mapRedoStack = null,Object? mapStrokeStart = freezed,Object? savedMapSnapshot = freezed,Object? canUndoMap = null,Object? canRedoMap = null,Object? isDirty = null,Object? isProjectDirty = null,Object? isSaving = null,Object? statusMessage = freezed,Object? errorMessage = freezed,}) {
  return _then(_EditorState(
projectRootPath: freezed == projectRootPath ? _self.projectRootPath : projectRootPath // ignore: cast_nullable_to_non_nullable
as String?,project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as ProjectManifest?,workspaceMode: null == workspaceMode ? _self.workspaceMode : workspaceMode // ignore: cast_nullable_to_non_nullable
as EditorWorkspaceMode,encounterStudioSection: null == encounterStudioSection ? _self.encounterStudioSection : encounterStudioSection // ignore: cast_nullable_to_non_nullable
as EncounterStudioSection,encounterStudioTableId: freezed == encounterStudioTableId ? _self.encounterStudioTableId : encounterStudioTableId // ignore: cast_nullable_to_non_nullable
as String?,smartTilesStudioLaunchContext: null == smartTilesStudioLaunchContext ? _self.smartTilesStudioLaunchContext : smartTilesStudioLaunchContext // ignore: cast_nullable_to_non_nullable
as SmartTilesStudioLaunchContext,pokemonCatalogSection: null == pokemonCatalogSection ? _self.pokemonCatalogSection : pokemonCatalogSection // ignore: cast_nullable_to_non_nullable
as PokemonCatalogSection,activeMap: freezed == activeMap ? _self.activeMap : activeMap // ignore: cast_nullable_to_non_nullable
as MapData?,activeMapPath: freezed == activeMapPath ? _self.activeMapPath : activeMapPath // ignore: cast_nullable_to_non_nullable
as String?,activeTool: null == activeTool ? _self.activeTool : activeTool // ignore: cast_nullable_to_non_nullable
as EditorToolType,activeLayerId: freezed == activeLayerId ? _self.activeLayerId : activeLayerId // ignore: cast_nullable_to_non_nullable
as String?,hoveredTile: freezed == hoveredTile ? _self.hoveredTile : hoveredTile // ignore: cast_nullable_to_non_nullable
as GridPos?,activeBrush: null == activeBrush ? _self.activeBrush : activeBrush // ignore: cast_nullable_to_non_nullable
as EditorBrush,selectedEntityKind: null == selectedEntityKind ? _self.selectedEntityKind : selectedEntityKind // ignore: cast_nullable_to_non_nullable
as MapEntityKind,eraserFootprint: null == eraserFootprint ? _self.eraserFootprint : eraserFootprint // ignore: cast_nullable_to_non_nullable
as EditorEraserFootprint,collisionBrushSizeMode: null == collisionBrushSizeMode ? _self.collisionBrushSizeMode : collisionBrushSizeMode // ignore: cast_nullable_to_non_nullable
as CollisionBrushSizeMode,selectedEntityId: freezed == selectedEntityId ? _self.selectedEntityId : selectedEntityId // ignore: cast_nullable_to_non_nullable
as String?,npcWaypointPlacementEntityId: freezed == npcWaypointPlacementEntityId ? _self.npcWaypointPlacementEntityId : npcWaypointPlacementEntityId // ignore: cast_nullable_to_non_nullable
as String?,selectedMapEventId: freezed == selectedMapEventId ? _self.selectedMapEventId : selectedMapEventId // ignore: cast_nullable_to_non_nullable
as String?,selectedWarpId: freezed == selectedWarpId ? _self.selectedWarpId : selectedWarpId // ignore: cast_nullable_to_non_nullable
as String?,selectedTriggerId: freezed == selectedTriggerId ? _self.selectedTriggerId : selectedTriggerId // ignore: cast_nullable_to_non_nullable
as String?,selectedGameplayZoneId: freezed == selectedGameplayZoneId ? _self.selectedGameplayZoneId : selectedGameplayZoneId // ignore: cast_nullable_to_non_nullable
as String?,selectedEnvironmentAreaId: freezed == selectedEnvironmentAreaId ? _self.selectedEnvironmentAreaId : selectedEnvironmentAreaId // ignore: cast_nullable_to_non_nullable
as String?,environmentMaskEditMode: freezed == environmentMaskEditMode ? _self.environmentMaskEditMode : environmentMaskEditMode // ignore: cast_nullable_to_non_nullable
as EnvironmentMaskEditMode?,gameplayZoneDraftArea: freezed == gameplayZoneDraftArea ? _self.gameplayZoneDraftArea : gameplayZoneDraftArea // ignore: cast_nullable_to_non_nullable
as MapRect?,selectedTilesetEditorId: freezed == selectedTilesetEditorId ? _self.selectedTilesetEditorId : selectedTilesetEditorId // ignore: cast_nullable_to_non_nullable
as String?,selectedTilesetElementGroupId: freezed == selectedTilesetElementGroupId ? _self.selectedTilesetElementGroupId : selectedTilesetElementGroupId // ignore: cast_nullable_to_non_nullable
as String?,paletteSession: null == paletteSession ? _self.paletteSession : paletteSession // ignore: cast_nullable_to_non_nullable
as EditorPaletteSession,tilesElementsPanelMode: null == tilesElementsPanelMode ? _self.tilesElementsPanelMode : tilesElementsPanelMode // ignore: cast_nullable_to_non_nullable
as TilesElementsPanelMode,selectedPlacedElementInstanceId: freezed == selectedPlacedElementInstanceId ? _self.selectedPlacedElementInstanceId : selectedPlacedElementInstanceId // ignore: cast_nullable_to_non_nullable
as String?,selectedProjectDialogueId: freezed == selectedProjectDialogueId ? _self.selectedProjectDialogueId : selectedProjectDialogueId // ignore: cast_nullable_to_non_nullable
as String?,selectedTrainerId: freezed == selectedTrainerId ? _self.selectedTrainerId : selectedTrainerId // ignore: cast_nullable_to_non_nullable
as String?,selectedCharacterId: freezed == selectedCharacterId ? _self.selectedCharacterId : selectedCharacterId // ignore: cast_nullable_to_non_nullable
as String?,paletteCategoryFilter: freezed == paletteCategoryFilter ? _self.paletteCategoryFilter : paletteCategoryFilter // ignore: cast_nullable_to_non_nullable
as PaletteCategory?,zoom: null == zoom ? _self.zoom : zoom // ignore: cast_nullable_to_non_nullable
as double,panOffset: null == panOffset ? _self.panOffset : panOffset // ignore: cast_nullable_to_non_nullable
as Offset,mapUndoStack: null == mapUndoStack ? _self._mapUndoStack : mapUndoStack // ignore: cast_nullable_to_non_nullable
as List<MapHistoryEntry>,mapRedoStack: null == mapRedoStack ? _self._mapRedoStack : mapRedoStack // ignore: cast_nullable_to_non_nullable
as List<MapHistoryEntry>,mapStrokeStart: freezed == mapStrokeStart ? _self.mapStrokeStart : mapStrokeStart // ignore: cast_nullable_to_non_nullable
as MapHistorySnapshot?,savedMapSnapshot: freezed == savedMapSnapshot ? _self.savedMapSnapshot : savedMapSnapshot // ignore: cast_nullable_to_non_nullable
as MapData?,canUndoMap: null == canUndoMap ? _self.canUndoMap : canUndoMap // ignore: cast_nullable_to_non_nullable
as bool,canRedoMap: null == canRedoMap ? _self.canRedoMap : canRedoMap // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,isProjectDirty: null == isProjectDirty ? _self.isProjectDirty : isProjectDirty // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,statusMessage: freezed == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectManifestCopyWith<$Res>? get project {
    if (_self.project == null) {
    return null;
  }

  return $ProjectManifestCopyWith<$Res>(_self.project!, (value) {
    return _then(_self.copyWith(project: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapDataCopyWith<$Res>? get activeMap {
    if (_self.activeMap == null) {
    return null;
  }

  return $MapDataCopyWith<$Res>(_self.activeMap!, (value) {
    return _then(_self.copyWith(activeMap: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res>? get hoveredTile {
    if (_self.hoveredTile == null) {
    return null;
  }

  return $GridPosCopyWith<$Res>(_self.hoveredTile!, (value) {
    return _then(_self.copyWith(hoveredTile: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorBrushCopyWith<$Res> get activeBrush {
  
  return $EditorBrushCopyWith<$Res>(_self.activeBrush, (value) {
    return _then(_self.copyWith(activeBrush: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorEraserFootprintCopyWith<$Res> get eraserFootprint {
  
  return $EditorEraserFootprintCopyWith<$Res>(_self.eraserFootprint, (value) {
    return _then(_self.copyWith(eraserFootprint: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRectCopyWith<$Res>? get gameplayZoneDraftArea {
    if (_self.gameplayZoneDraftArea == null) {
    return null;
  }

  return $MapRectCopyWith<$Res>(_self.gameplayZoneDraftArea!, (value) {
    return _then(_self.copyWith(gameplayZoneDraftArea: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPaletteSessionCopyWith<$Res> get paletteSession {
  
  return $EditorPaletteSessionCopyWith<$Res>(_self.paletteSession, (value) {
    return _then(_self.copyWith(paletteSession: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapHistorySnapshotCopyWith<$Res>? get mapStrokeStart {
    if (_self.mapStrokeStart == null) {
    return null;
  }

  return $MapHistorySnapshotCopyWith<$Res>(_self.mapStrokeStart!, (value) {
    return _then(_self.copyWith(mapStrokeStart: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapDataCopyWith<$Res>? get savedMapSnapshot {
    if (_self.savedMapSnapshot == null) {
    return null;
  }

  return $MapDataCopyWith<$Res>(_self.savedMapSnapshot!, (value) {
    return _then(_self.copyWith(savedMapSnapshot: value));
  });
}
}

// dart format on
