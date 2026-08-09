// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_event_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MapEventDefinition {

/// Identifiant unique de l'événement.
 String get id;/// Titre optionnel (pour l'éditeur / debug).
 String get title;/// Pages de l'événement.
/// La première page valide (dans l'ordre) est active.
 List<MapEventPage> get pages;/// Position de l'événement sur la map.
 EventPosition get position;/// Type d'événement (détermine le rendu / comportement).
 MapEventType get type;/// Métadonnées.
 Map<String, String> get metadata;
/// Create a copy of MapEventDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEventDefinitionCopyWith<MapEventDefinition> get copyWith => _$MapEventDefinitionCopyWithImpl<MapEventDefinition>(this as MapEventDefinition, _$identity);

  /// Serializes this MapEventDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEventDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.pages, pages)&&(identical(other.position, position) || other.position == position)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(pages),position,type,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'MapEventDefinition(id: $id, title: $title, pages: $pages, position: $position, type: $type, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $MapEventDefinitionCopyWith<$Res>  {
  factory $MapEventDefinitionCopyWith(MapEventDefinition value, $Res Function(MapEventDefinition) _then) = _$MapEventDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<MapEventPage> pages, EventPosition position, MapEventType type, Map<String, String> metadata
});


$EventPositionCopyWith<$Res> get position;

}
/// @nodoc
class _$MapEventDefinitionCopyWithImpl<$Res>
    implements $MapEventDefinitionCopyWith<$Res> {
  _$MapEventDefinitionCopyWithImpl(this._self, this._then);

  final MapEventDefinition _self;
  final $Res Function(MapEventDefinition) _then;

/// Create a copy of MapEventDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? pages = null,Object? position = null,Object? type = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as List<MapEventPage>,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as EventPosition,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MapEventType,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of MapEventDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventPositionCopyWith<$Res> get position {

  return $EventPositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapEventDefinition].
extension MapEventDefinitionPatterns on MapEventDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEventDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEventDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEventDefinition value)  $default,){
final _that = this;
switch (_that) {
case _MapEventDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEventDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _MapEventDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<MapEventPage> pages,  EventPosition position,  MapEventType type,  Map<String, String> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEventDefinition() when $default != null:
return $default(_that.id,_that.title,_that.pages,_that.position,_that.type,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<MapEventPage> pages,  EventPosition position,  MapEventType type,  Map<String, String> metadata)  $default,) {final _that = this;
switch (_that) {
case _MapEventDefinition():
return $default(_that.id,_that.title,_that.pages,_that.position,_that.type,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<MapEventPage> pages,  EventPosition position,  MapEventType type,  Map<String, String> metadata)?  $default,) {final _that = this;
switch (_that) {
case _MapEventDefinition() when $default != null:
return $default(_that.id,_that.title,_that.pages,_that.position,_that.type,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEventDefinition implements MapEventDefinition {
  const _MapEventDefinition({required this.id, this.title = '', required final  List<MapEventPage> pages, required this.position, this.type = MapEventType.actor, final  Map<String, String> metadata = const {}}): _pages = pages,_metadata = metadata;
  factory _MapEventDefinition.fromJson(Map<String, dynamic> json) => _$MapEventDefinitionFromJson(json);

/// Identifiant unique de l'événement.
@override final  String id;
/// Titre optionnel (pour l'éditeur / debug).
@override@JsonKey() final  String title;
/// Pages de l'événement.
/// La première page valide (dans l'ordre) est active.
 final  List<MapEventPage> _pages;
/// Pages de l'événement.
/// La première page valide (dans l'ordre) est active.
@override List<MapEventPage> get pages {
  if (_pages is EqualUnmodifiableListView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pages);
}

/// Position de l'événement sur la map.
@override final  EventPosition position;
/// Type d'événement (détermine le rendu / comportement).
@override@JsonKey() final  MapEventType type;
/// Métadonnées.
 final  Map<String, String> _metadata;
/// Métadonnées.
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of MapEventDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEventDefinitionCopyWith<_MapEventDefinition> get copyWith => __$MapEventDefinitionCopyWithImpl<_MapEventDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEventDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEventDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._pages, _pages)&&(identical(other.position, position) || other.position == position)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_pages),position,type,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'MapEventDefinition(id: $id, title: $title, pages: $pages, position: $position, type: $type, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$MapEventDefinitionCopyWith<$Res> implements $MapEventDefinitionCopyWith<$Res> {
  factory _$MapEventDefinitionCopyWith(_MapEventDefinition value, $Res Function(_MapEventDefinition) _then) = __$MapEventDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<MapEventPage> pages, EventPosition position, MapEventType type, Map<String, String> metadata
});


@override $EventPositionCopyWith<$Res> get position;

}
/// @nodoc
class __$MapEventDefinitionCopyWithImpl<$Res>
    implements _$MapEventDefinitionCopyWith<$Res> {
  __$MapEventDefinitionCopyWithImpl(this._self, this._then);

  final _MapEventDefinition _self;
  final $Res Function(_MapEventDefinition) _then;

/// Create a copy of MapEventDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? pages = null,Object? position = null,Object? type = null,Object? metadata = null,}) {
  return _then(_MapEventDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as List<MapEventPage>,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as EventPosition,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MapEventType,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of MapEventDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventPositionCopyWith<$Res> get position {

  return $EventPositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}
}


/// @nodoc
mixin _$EventPosition {

/// Layer ID où placer l'événement.
 String get layerId;/// Coordonnée X.
 int get x;/// Coordonnée Y.
 int get y;
/// Create a copy of EventPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventPositionCopyWith<EventPosition> get copyWith => _$EventPositionCopyWithImpl<EventPosition>(this as EventPosition, _$identity);

  /// Serializes this EventPosition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventPosition&&(identical(other.layerId, layerId) || other.layerId == layerId)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,layerId,x,y);

@override
String toString() {
  return 'EventPosition(layerId: $layerId, x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $EventPositionCopyWith<$Res>  {
  factory $EventPositionCopyWith(EventPosition value, $Res Function(EventPosition) _then) = _$EventPositionCopyWithImpl;
@useResult
$Res call({
 String layerId, int x, int y
});




}
/// @nodoc
class _$EventPositionCopyWithImpl<$Res>
    implements $EventPositionCopyWith<$Res> {
  _$EventPositionCopyWithImpl(this._self, this._then);

  final EventPosition _self;
  final $Res Function(EventPosition) _then;

/// Create a copy of EventPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? layerId = null,Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
layerId: null == layerId ? _self.layerId : layerId // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EventPosition].
extension EventPositionPatterns on EventPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventPosition value)  $default,){
final _that = this;
switch (_that) {
case _EventPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventPosition value)?  $default,){
final _that = this;
switch (_that) {
case _EventPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String layerId,  int x,  int y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventPosition() when $default != null:
return $default(_that.layerId,_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String layerId,  int x,  int y)  $default,) {final _that = this;
switch (_that) {
case _EventPosition():
return $default(_that.layerId,_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String layerId,  int x,  int y)?  $default,) {final _that = this;
switch (_that) {
case _EventPosition() when $default != null:
return $default(_that.layerId,_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventPosition implements EventPosition {
  const _EventPosition({required this.layerId, required this.x, required this.y});
  factory _EventPosition.fromJson(Map<String, dynamic> json) => _$EventPositionFromJson(json);

/// Layer ID où placer l'événement.
@override final  String layerId;
/// Coordonnée X.
@override final  int x;
/// Coordonnée Y.
@override final  int y;

/// Create a copy of EventPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventPositionCopyWith<_EventPosition> get copyWith => __$EventPositionCopyWithImpl<_EventPosition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventPositionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventPosition&&(identical(other.layerId, layerId) || other.layerId == layerId)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,layerId,x,y);

@override
String toString() {
  return 'EventPosition(layerId: $layerId, x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$EventPositionCopyWith<$Res> implements $EventPositionCopyWith<$Res> {
  factory _$EventPositionCopyWith(_EventPosition value, $Res Function(_EventPosition) _then) = __$EventPositionCopyWithImpl;
@override @useResult
$Res call({
 String layerId, int x, int y
});




}
/// @nodoc
class __$EventPositionCopyWithImpl<$Res>
    implements _$EventPositionCopyWith<$Res> {
  __$EventPositionCopyWithImpl(this._self, this._then);

  final _EventPosition _self;
  final $Res Function(_EventPosition) _then;

/// Create a copy of EventPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? layerId = null,Object? x = null,Object? y = null,}) {
  return _then(_EventPosition(
layerId: null == layerId ? _self.layerId : layerId // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MapEventSceneTarget {

/// Identifiant de la Scene V1 cible.
 String get sceneId;
/// Create a copy of MapEventSceneTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEventSceneTargetCopyWith<MapEventSceneTarget> get copyWith => _$MapEventSceneTargetCopyWithImpl<MapEventSceneTarget>(this as MapEventSceneTarget, _$identity);

  /// Serializes this MapEventSceneTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEventSceneTarget&&(identical(other.sceneId, sceneId) || other.sceneId == sceneId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sceneId);

@override
String toString() {
  return 'MapEventSceneTarget(sceneId: $sceneId)';
}


}

/// @nodoc
abstract mixin class $MapEventSceneTargetCopyWith<$Res>  {
  factory $MapEventSceneTargetCopyWith(MapEventSceneTarget value, $Res Function(MapEventSceneTarget) _then) = _$MapEventSceneTargetCopyWithImpl;
@useResult
$Res call({
 String sceneId
});




}
/// @nodoc
class _$MapEventSceneTargetCopyWithImpl<$Res>
    implements $MapEventSceneTargetCopyWith<$Res> {
  _$MapEventSceneTargetCopyWithImpl(this._self, this._then);

  final MapEventSceneTarget _self;
  final $Res Function(MapEventSceneTarget) _then;

/// Create a copy of MapEventSceneTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sceneId = null,}) {
  return _then(_self.copyWith(
sceneId: null == sceneId ? _self.sceneId : sceneId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MapEventSceneTarget].
extension MapEventSceneTargetPatterns on MapEventSceneTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEventSceneTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEventSceneTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEventSceneTarget value)  $default,){
final _that = this;
switch (_that) {
case _MapEventSceneTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEventSceneTarget value)?  $default,){
final _that = this;
switch (_that) {
case _MapEventSceneTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sceneId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEventSceneTarget() when $default != null:
return $default(_that.sceneId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sceneId)  $default,) {final _that = this;
switch (_that) {
case _MapEventSceneTarget():
return $default(_that.sceneId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sceneId)?  $default,) {final _that = this;
switch (_that) {
case _MapEventSceneTarget() when $default != null:
return $default(_that.sceneId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEventSceneTarget implements MapEventSceneTarget {
  const _MapEventSceneTarget({required this.sceneId});
  factory _MapEventSceneTarget.fromJson(Map<String, dynamic> json) => _$MapEventSceneTargetFromJson(json);

/// Identifiant de la Scene V1 cible.
@override final  String sceneId;

/// Create a copy of MapEventSceneTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEventSceneTargetCopyWith<_MapEventSceneTarget> get copyWith => __$MapEventSceneTargetCopyWithImpl<_MapEventSceneTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEventSceneTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEventSceneTarget&&(identical(other.sceneId, sceneId) || other.sceneId == sceneId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sceneId);

@override
String toString() {
  return 'MapEventSceneTarget(sceneId: $sceneId)';
}


}

/// @nodoc
abstract mixin class _$MapEventSceneTargetCopyWith<$Res> implements $MapEventSceneTargetCopyWith<$Res> {
  factory _$MapEventSceneTargetCopyWith(_MapEventSceneTarget value, $Res Function(_MapEventSceneTarget) _then) = __$MapEventSceneTargetCopyWithImpl;
@override @useResult
$Res call({
 String sceneId
});




}
/// @nodoc
class __$MapEventSceneTargetCopyWithImpl<$Res>
    implements _$MapEventSceneTargetCopyWith<$Res> {
  __$MapEventSceneTargetCopyWithImpl(this._self, this._then);

  final _MapEventSceneTarget _self;
  final $Res Function(_MapEventSceneTarget) _then;

/// Create a copy of MapEventSceneTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sceneId = null,}) {
  return _then(_MapEventSceneTarget(
sceneId: null == sceneId ? _self.sceneId : sceneId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MapEventPage {

/// Numéro de page (0-based, pour référence).
 int get pageNumber;/// Conditions pour que cette page soit active.
/// Si null ou vide, la page est toujours active (fallback).
 ScriptCondition? get condition;/// Référence au script à exécuter lors de l'interaction.
 ScriptRef? get script;/// ID du sprite / visuel.
 String? get spriteId;/// Message à afficher (alternative simple au script).
 String? get message;/// Cible Scene V1 authoring.
///
/// Null signifie que cette page ne cible aucune Scene V1.
@JsonKey(includeIfNull: false) MapEventSceneTarget? get sceneTarget;/// Si true, l'événement est invisible mais toujours interactif.
 bool get isHidden;/// Si true, l'événement est désactivé (pas d'interaction).
 bool get isDisabled;/// Métadonnées.
 Map<String, String> get metadata;
/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEventPageCopyWith<MapEventPage> get copyWith => _$MapEventPageCopyWithImpl<MapEventPage>(this as MapEventPage, _$identity);

  /// Serializes this MapEventPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEventPage&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.script, script) || other.script == script)&&(identical(other.spriteId, spriteId) || other.spriteId == spriteId)&&(identical(other.message, message) || other.message == message)&&(identical(other.sceneTarget, sceneTarget) || other.sceneTarget == sceneTarget)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.isDisabled, isDisabled) || other.isDisabled == isDisabled)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageNumber,condition,script,spriteId,message,sceneTarget,isHidden,isDisabled,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'MapEventPage(pageNumber: $pageNumber, condition: $condition, script: $script, spriteId: $spriteId, message: $message, sceneTarget: $sceneTarget, isHidden: $isHidden, isDisabled: $isDisabled, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $MapEventPageCopyWith<$Res>  {
  factory $MapEventPageCopyWith(MapEventPage value, $Res Function(MapEventPage) _then) = _$MapEventPageCopyWithImpl;
@useResult
$Res call({
 int pageNumber, ScriptCondition? condition, ScriptRef? script, String? spriteId, String? message,@JsonKey(includeIfNull: false) MapEventSceneTarget? sceneTarget, bool isHidden, bool isDisabled, Map<String, String> metadata
});


$ScriptConditionCopyWith<$Res>? get condition;$ScriptRefCopyWith<$Res>? get script;$MapEventSceneTargetCopyWith<$Res>? get sceneTarget;

}
/// @nodoc
class _$MapEventPageCopyWithImpl<$Res>
    implements $MapEventPageCopyWith<$Res> {
  _$MapEventPageCopyWithImpl(this._self, this._then);

  final MapEventPage _self;
  final $Res Function(MapEventPage) _then;

/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageNumber = null,Object? condition = freezed,Object? script = freezed,Object? spriteId = freezed,Object? message = freezed,Object? sceneTarget = freezed,Object? isHidden = null,Object? isDisabled = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ScriptCondition?,script: freezed == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as ScriptRef?,spriteId: freezed == spriteId ? _self.spriteId : spriteId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,sceneTarget: freezed == sceneTarget ? _self.sceneTarget : sceneTarget // ignore: cast_nullable_to_non_nullable
as MapEventSceneTarget?,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,isDisabled: null == isDisabled ? _self.isDisabled : isDisabled // ignore: cast_nullable_to_non_nullable
as bool,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<$Res>? get condition {
    if (_self.condition == null) {
    return null;
  }

  return $ScriptConditionCopyWith<$Res>(_self.condition!, (value) {
    return _then(_self.copyWith(condition: value));
  });
}/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptRefCopyWith<$Res>? get script {
    if (_self.script == null) {
    return null;
  }

  return $ScriptRefCopyWith<$Res>(_self.script!, (value) {
    return _then(_self.copyWith(script: value));
  });
}/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEventSceneTargetCopyWith<$Res>? get sceneTarget {
    if (_self.sceneTarget == null) {
    return null;
  }

  return $MapEventSceneTargetCopyWith<$Res>(_self.sceneTarget!, (value) {
    return _then(_self.copyWith(sceneTarget: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapEventPage].
extension MapEventPagePatterns on MapEventPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEventPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEventPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEventPage value)  $default,){
final _that = this;
switch (_that) {
case _MapEventPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEventPage value)?  $default,){
final _that = this;
switch (_that) {
case _MapEventPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pageNumber,  ScriptCondition? condition,  ScriptRef? script,  String? spriteId,  String? message, @JsonKey(includeIfNull: false)  MapEventSceneTarget? sceneTarget,  bool isHidden,  bool isDisabled,  Map<String, String> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEventPage() when $default != null:
return $default(_that.pageNumber,_that.condition,_that.script,_that.spriteId,_that.message,_that.sceneTarget,_that.isHidden,_that.isDisabled,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pageNumber,  ScriptCondition? condition,  ScriptRef? script,  String? spriteId,  String? message, @JsonKey(includeIfNull: false)  MapEventSceneTarget? sceneTarget,  bool isHidden,  bool isDisabled,  Map<String, String> metadata)  $default,) {final _that = this;
switch (_that) {
case _MapEventPage():
return $default(_that.pageNumber,_that.condition,_that.script,_that.spriteId,_that.message,_that.sceneTarget,_that.isHidden,_that.isDisabled,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pageNumber,  ScriptCondition? condition,  ScriptRef? script,  String? spriteId,  String? message, @JsonKey(includeIfNull: false)  MapEventSceneTarget? sceneTarget,  bool isHidden,  bool isDisabled,  Map<String, String> metadata)?  $default,) {final _that = this;
switch (_that) {
case _MapEventPage() when $default != null:
return $default(_that.pageNumber,_that.condition,_that.script,_that.spriteId,_that.message,_that.sceneTarget,_that.isHidden,_that.isDisabled,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEventPage implements MapEventPage {
  const _MapEventPage({required this.pageNumber, this.condition, this.script, this.spriteId, this.message, @JsonKey(includeIfNull: false) this.sceneTarget, this.isHidden = false, this.isDisabled = false, final  Map<String, String> metadata = const {}}): _metadata = metadata;
  factory _MapEventPage.fromJson(Map<String, dynamic> json) => _$MapEventPageFromJson(json);

/// Numéro de page (0-based, pour référence).
@override final  int pageNumber;
/// Conditions pour que cette page soit active.
/// Si null ou vide, la page est toujours active (fallback).
@override final  ScriptCondition? condition;
/// Référence au script à exécuter lors de l'interaction.
@override final  ScriptRef? script;
/// ID du sprite / visuel.
@override final  String? spriteId;
/// Message à afficher (alternative simple au script).
@override final  String? message;
/// Cible Scene V1 authoring.
///
/// Null signifie que cette page ne cible aucune Scene V1.
@override@JsonKey(includeIfNull: false) final  MapEventSceneTarget? sceneTarget;
/// Si true, l'événement est invisible mais toujours interactif.
@override@JsonKey() final  bool isHidden;
/// Si true, l'événement est désactivé (pas d'interaction).
@override@JsonKey() final  bool isDisabled;
/// Métadonnées.
 final  Map<String, String> _metadata;
/// Métadonnées.
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEventPageCopyWith<_MapEventPage> get copyWith => __$MapEventPageCopyWithImpl<_MapEventPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEventPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEventPage&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.script, script) || other.script == script)&&(identical(other.spriteId, spriteId) || other.spriteId == spriteId)&&(identical(other.message, message) || other.message == message)&&(identical(other.sceneTarget, sceneTarget) || other.sceneTarget == sceneTarget)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.isDisabled, isDisabled) || other.isDisabled == isDisabled)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageNumber,condition,script,spriteId,message,sceneTarget,isHidden,isDisabled,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'MapEventPage(pageNumber: $pageNumber, condition: $condition, script: $script, spriteId: $spriteId, message: $message, sceneTarget: $sceneTarget, isHidden: $isHidden, isDisabled: $isDisabled, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$MapEventPageCopyWith<$Res> implements $MapEventPageCopyWith<$Res> {
  factory _$MapEventPageCopyWith(_MapEventPage value, $Res Function(_MapEventPage) _then) = __$MapEventPageCopyWithImpl;
@override @useResult
$Res call({
 int pageNumber, ScriptCondition? condition, ScriptRef? script, String? spriteId, String? message,@JsonKey(includeIfNull: false) MapEventSceneTarget? sceneTarget, bool isHidden, bool isDisabled, Map<String, String> metadata
});


@override $ScriptConditionCopyWith<$Res>? get condition;@override $ScriptRefCopyWith<$Res>? get script;@override $MapEventSceneTargetCopyWith<$Res>? get sceneTarget;

}
/// @nodoc
class __$MapEventPageCopyWithImpl<$Res>
    implements _$MapEventPageCopyWith<$Res> {
  __$MapEventPageCopyWithImpl(this._self, this._then);

  final _MapEventPage _self;
  final $Res Function(_MapEventPage) _then;

/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageNumber = null,Object? condition = freezed,Object? script = freezed,Object? spriteId = freezed,Object? message = freezed,Object? sceneTarget = freezed,Object? isHidden = null,Object? isDisabled = null,Object? metadata = null,}) {
  return _then(_MapEventPage(
pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ScriptCondition?,script: freezed == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as ScriptRef?,spriteId: freezed == spriteId ? _self.spriteId : spriteId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,sceneTarget: freezed == sceneTarget ? _self.sceneTarget : sceneTarget // ignore: cast_nullable_to_non_nullable
as MapEventSceneTarget?,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,isDisabled: null == isDisabled ? _self.isDisabled : isDisabled // ignore: cast_nullable_to_non_nullable
as bool,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<$Res>? get condition {
    if (_self.condition == null) {
    return null;
  }

  return $ScriptConditionCopyWith<$Res>(_self.condition!, (value) {
    return _then(_self.copyWith(condition: value));
  });
}/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptRefCopyWith<$Res>? get script {
    if (_self.script == null) {
    return null;
  }

  return $ScriptRefCopyWith<$Res>(_self.script!, (value) {
    return _then(_self.copyWith(script: value));
  });
}/// Create a copy of MapEventPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEventSceneTargetCopyWith<$Res>? get sceneTarget {
    if (_self.sceneTarget == null) {
    return null;
  }

  return $MapEventSceneTargetCopyWith<$Res>(_self.sceneTarget!, (value) {
    return _then(_self.copyWith(sceneTarget: value));
  });
}
}


/// @nodoc
mixin _$ScriptRef {

/// ID du script asset.
 String get scriptId;/// Noeud de démarrage.
/// Si null, utilise le defaultStartNode du script.
 String? get startNode;
/// Create a copy of ScriptRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptRefCopyWith<ScriptRef> get copyWith => _$ScriptRefCopyWithImpl<ScriptRef>(this as ScriptRef, _$identity);

  /// Serializes this ScriptRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptRef&&(identical(other.scriptId, scriptId) || other.scriptId == scriptId)&&(identical(other.startNode, startNode) || other.startNode == startNode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scriptId,startNode);

@override
String toString() {
  return 'ScriptRef(scriptId: $scriptId, startNode: $startNode)';
}


}

/// @nodoc
abstract mixin class $ScriptRefCopyWith<$Res>  {
  factory $ScriptRefCopyWith(ScriptRef value, $Res Function(ScriptRef) _then) = _$ScriptRefCopyWithImpl;
@useResult
$Res call({
 String scriptId, String? startNode
});




}
/// @nodoc
class _$ScriptRefCopyWithImpl<$Res>
    implements $ScriptRefCopyWith<$Res> {
  _$ScriptRefCopyWithImpl(this._self, this._then);

  final ScriptRef _self;
  final $Res Function(ScriptRef) _then;

/// Create a copy of ScriptRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scriptId = null,Object? startNode = freezed,}) {
  return _then(_self.copyWith(
scriptId: null == scriptId ? _self.scriptId : scriptId // ignore: cast_nullable_to_non_nullable
as String,startNode: freezed == startNode ? _self.startNode : startNode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScriptRef].
extension ScriptRefPatterns on ScriptRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScriptRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScriptRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScriptRef value)  $default,){
final _that = this;
switch (_that) {
case _ScriptRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScriptRef value)?  $default,){
final _that = this;
switch (_that) {
case _ScriptRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String scriptId,  String? startNode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScriptRef() when $default != null:
return $default(_that.scriptId,_that.startNode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String scriptId,  String? startNode)  $default,) {final _that = this;
switch (_that) {
case _ScriptRef():
return $default(_that.scriptId,_that.startNode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String scriptId,  String? startNode)?  $default,) {final _that = this;
switch (_that) {
case _ScriptRef() when $default != null:
return $default(_that.scriptId,_that.startNode);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScriptRef implements ScriptRef {
  const _ScriptRef({required this.scriptId, this.startNode});
  factory _ScriptRef.fromJson(Map<String, dynamic> json) => _$ScriptRefFromJson(json);

/// ID du script asset.
@override final  String scriptId;
/// Noeud de démarrage.
/// Si null, utilise le defaultStartNode du script.
@override final  String? startNode;

/// Create a copy of ScriptRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScriptRefCopyWith<_ScriptRef> get copyWith => __$ScriptRefCopyWithImpl<_ScriptRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScriptRef&&(identical(other.scriptId, scriptId) || other.scriptId == scriptId)&&(identical(other.startNode, startNode) || other.startNode == startNode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scriptId,startNode);

@override
String toString() {
  return 'ScriptRef(scriptId: $scriptId, startNode: $startNode)';
}


}

/// @nodoc
abstract mixin class _$ScriptRefCopyWith<$Res> implements $ScriptRefCopyWith<$Res> {
  factory _$ScriptRefCopyWith(_ScriptRef value, $Res Function(_ScriptRef) _then) = __$ScriptRefCopyWithImpl;
@override @useResult
$Res call({
 String scriptId, String? startNode
});




}
/// @nodoc
class __$ScriptRefCopyWithImpl<$Res>
    implements _$ScriptRefCopyWith<$Res> {
  __$ScriptRefCopyWithImpl(this._self, this._then);

  final _ScriptRef _self;
  final $Res Function(_ScriptRef) _then;

/// Create a copy of ScriptRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scriptId = null,Object? startNode = freezed,}) {
  return _then(_ScriptRef(
scriptId: null == scriptId ? _self.scriptId : scriptId // ignore: cast_nullable_to_non_nullable
as String,startNode: freezed == startNode ? _self.startNode : startNode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ActiveEventPage {

/// ID de l'événement.
 String get eventId;/// Page active.
 MapEventPage get page;/// Index de la page dans la liste.
 int get pageIndex;
/// Create a copy of ActiveEventPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveEventPageCopyWith<ActiveEventPage> get copyWith => _$ActiveEventPageCopyWithImpl<ActiveEventPage>(this as ActiveEventPage, _$identity);

  /// Serializes this ActiveEventPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveEventPage&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,page,pageIndex);

@override
String toString() {
  return 'ActiveEventPage(eventId: $eventId, page: $page, pageIndex: $pageIndex)';
}


}

/// @nodoc
abstract mixin class $ActiveEventPageCopyWith<$Res>  {
  factory $ActiveEventPageCopyWith(ActiveEventPage value, $Res Function(ActiveEventPage) _then) = _$ActiveEventPageCopyWithImpl;
@useResult
$Res call({
 String eventId, MapEventPage page, int pageIndex
});


$MapEventPageCopyWith<$Res> get page;

}
/// @nodoc
class _$ActiveEventPageCopyWithImpl<$Res>
    implements $ActiveEventPageCopyWith<$Res> {
  _$ActiveEventPageCopyWithImpl(this._self, this._then);

  final ActiveEventPage _self;
  final $Res Function(ActiveEventPage) _then;

/// Create a copy of ActiveEventPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? page = null,Object? pageIndex = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as MapEventPage,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ActiveEventPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEventPageCopyWith<$Res> get page {

  return $MapEventPageCopyWith<$Res>(_self.page, (value) {
    return _then(_self.copyWith(page: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActiveEventPage].
extension ActiveEventPagePatterns on ActiveEventPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveEventPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveEventPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveEventPage value)  $default,){
final _that = this;
switch (_that) {
case _ActiveEventPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveEventPage value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveEventPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  MapEventPage page,  int pageIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveEventPage() when $default != null:
return $default(_that.eventId,_that.page,_that.pageIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  MapEventPage page,  int pageIndex)  $default,) {final _that = this;
switch (_that) {
case _ActiveEventPage():
return $default(_that.eventId,_that.page,_that.pageIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  MapEventPage page,  int pageIndex)?  $default,) {final _that = this;
switch (_that) {
case _ActiveEventPage() when $default != null:
return $default(_that.eventId,_that.page,_that.pageIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActiveEventPage implements ActiveEventPage {
  const _ActiveEventPage({required this.eventId, required this.page, required this.pageIndex});
  factory _ActiveEventPage.fromJson(Map<String, dynamic> json) => _$ActiveEventPageFromJson(json);

/// ID de l'événement.
@override final  String eventId;
/// Page active.
@override final  MapEventPage page;
/// Index de la page dans la liste.
@override final  int pageIndex;

/// Create a copy of ActiveEventPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveEventPageCopyWith<_ActiveEventPage> get copyWith => __$ActiveEventPageCopyWithImpl<_ActiveEventPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActiveEventPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveEventPage&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,page,pageIndex);

@override
String toString() {
  return 'ActiveEventPage(eventId: $eventId, page: $page, pageIndex: $pageIndex)';
}


}

/// @nodoc
abstract mixin class _$ActiveEventPageCopyWith<$Res> implements $ActiveEventPageCopyWith<$Res> {
  factory _$ActiveEventPageCopyWith(_ActiveEventPage value, $Res Function(_ActiveEventPage) _then) = __$ActiveEventPageCopyWithImpl;
@override @useResult
$Res call({
 String eventId, MapEventPage page, int pageIndex
});


@override $MapEventPageCopyWith<$Res> get page;

}
/// @nodoc
class __$ActiveEventPageCopyWithImpl<$Res>
    implements _$ActiveEventPageCopyWith<$Res> {
  __$ActiveEventPageCopyWithImpl(this._self, this._then);

  final _ActiveEventPage _self;
  final $Res Function(_ActiveEventPage) _then;

/// Create a copy of ActiveEventPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? page = null,Object? pageIndex = null,}) {
  return _then(_ActiveEventPage(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as MapEventPage,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ActiveEventPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEventPageCopyWith<$Res> get page {

  return $MapEventPageCopyWith<$Res>(_self.page, (value) {
    return _then(_self.copyWith(page: value));
  });
}
}

// dart format on
