// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MapData {

 String get id; String get name; GridSize get size; ProjectVersion get version;@JsonKey(includeIfNull: false) MapVisualStackConfig? get visualStack; String get tilesetId; List<MapLayer> get layers; List<MapPlacedElement> get placedElements; List<MapEntity> get entities; List<MapConnection> get connections; List<MapWarp> get warps; List<MapTrigger> get triggers;/// Zones gameplay (rencontres, déplacement, dangers, etc.).
/// Séparées des triggers (logiques scriptées) et des layers visuelles.
 List<MapGameplayZone> get gameplayZones; MapMetadata get mapMetadata; Map<String, dynamic> get properties; List<MapEventDefinition> get events;
/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapDataCopyWith<MapData> get copyWith => _$MapDataCopyWithImpl<MapData>(this as MapData, _$identity);

  /// Serializes this MapData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapData&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.version, version) || other.version == version)&&(identical(other.visualStack, visualStack) || other.visualStack == visualStack)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&const DeepCollectionEquality().equals(other.layers, layers)&&const DeepCollectionEquality().equals(other.placedElements, placedElements)&&const DeepCollectionEquality().equals(other.entities, entities)&&const DeepCollectionEquality().equals(other.connections, connections)&&const DeepCollectionEquality().equals(other.warps, warps)&&const DeepCollectionEquality().equals(other.triggers, triggers)&&const DeepCollectionEquality().equals(other.gameplayZones, gameplayZones)&&(identical(other.mapMetadata, mapMetadata) || other.mapMetadata == mapMetadata)&&const DeepCollectionEquality().equals(other.properties, properties)&&const DeepCollectionEquality().equals(other.events, events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,size,version,visualStack,tilesetId,const DeepCollectionEquality().hash(layers),const DeepCollectionEquality().hash(placedElements),const DeepCollectionEquality().hash(entities),const DeepCollectionEquality().hash(connections),const DeepCollectionEquality().hash(warps),const DeepCollectionEquality().hash(triggers),const DeepCollectionEquality().hash(gameplayZones),mapMetadata,const DeepCollectionEquality().hash(properties),const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'MapData(id: $id, name: $name, size: $size, version: $version, visualStack: $visualStack, tilesetId: $tilesetId, layers: $layers, placedElements: $placedElements, entities: $entities, connections: $connections, warps: $warps, triggers: $triggers, gameplayZones: $gameplayZones, mapMetadata: $mapMetadata, properties: $properties, events: $events)';
}


}

/// @nodoc
abstract mixin class $MapDataCopyWith<$Res>  {
  factory $MapDataCopyWith(MapData value, $Res Function(MapData) _then) = _$MapDataCopyWithImpl;
@useResult
$Res call({
 String id, String name, GridSize size, ProjectVersion version,@JsonKey(includeIfNull: false) MapVisualStackConfig? visualStack, String tilesetId, List<MapLayer> layers, List<MapPlacedElement> placedElements, List<MapEntity> entities, List<MapConnection> connections, List<MapWarp> warps, List<MapTrigger> triggers, List<MapGameplayZone> gameplayZones, MapMetadata mapMetadata, Map<String, dynamic> properties, List<MapEventDefinition> events
});


$GridSizeCopyWith<$Res> get size;$MapMetadataCopyWith<$Res> get mapMetadata;

}
/// @nodoc
class _$MapDataCopyWithImpl<$Res>
    implements $MapDataCopyWith<$Res> {
  _$MapDataCopyWithImpl(this._self, this._then);

  final MapData _self;
  final $Res Function(MapData) _then;

/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? size = null,Object? version = null,Object? visualStack = freezed,Object? tilesetId = null,Object? layers = null,Object? placedElements = null,Object? entities = null,Object? connections = null,Object? warps = null,Object? triggers = null,Object? gameplayZones = null,Object? mapMetadata = null,Object? properties = null,Object? events = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as GridSize,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as ProjectVersion,visualStack: freezed == visualStack ? _self.visualStack : visualStack // ignore: cast_nullable_to_non_nullable
as MapVisualStackConfig?,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,layers: null == layers ? _self.layers : layers // ignore: cast_nullable_to_non_nullable
as List<MapLayer>,placedElements: null == placedElements ? _self.placedElements : placedElements // ignore: cast_nullable_to_non_nullable
as List<MapPlacedElement>,entities: null == entities ? _self.entities : entities // ignore: cast_nullable_to_non_nullable
as List<MapEntity>,connections: null == connections ? _self.connections : connections // ignore: cast_nullable_to_non_nullable
as List<MapConnection>,warps: null == warps ? _self.warps : warps // ignore: cast_nullable_to_non_nullable
as List<MapWarp>,triggers: null == triggers ? _self.triggers : triggers // ignore: cast_nullable_to_non_nullable
as List<MapTrigger>,gameplayZones: null == gameplayZones ? _self.gameplayZones : gameplayZones // ignore: cast_nullable_to_non_nullable
as List<MapGameplayZone>,mapMetadata: null == mapMetadata ? _self.mapMetadata : mapMetadata // ignore: cast_nullable_to_non_nullable
as MapMetadata,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<MapEventDefinition>,
  ));
}
/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridSizeCopyWith<$Res> get size {

  return $GridSizeCopyWith<$Res>(_self.size, (value) {
    return _then(_self.copyWith(size: value));
  });
}/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapMetadataCopyWith<$Res> get mapMetadata {

  return $MapMetadataCopyWith<$Res>(_self.mapMetadata, (value) {
    return _then(_self.copyWith(mapMetadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapData].
extension MapDataPatterns on MapData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapData value)  $default,){
final _that = this;
switch (_that) {
case _MapData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapData value)?  $default,){
final _that = this;
switch (_that) {
case _MapData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  GridSize size,  ProjectVersion version, @JsonKey(includeIfNull: false)  MapVisualStackConfig? visualStack,  String tilesetId,  List<MapLayer> layers,  List<MapPlacedElement> placedElements,  List<MapEntity> entities,  List<MapConnection> connections,  List<MapWarp> warps,  List<MapTrigger> triggers,  List<MapGameplayZone> gameplayZones,  MapMetadata mapMetadata,  Map<String, dynamic> properties,  List<MapEventDefinition> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapData() when $default != null:
return $default(_that.id,_that.name,_that.size,_that.version,_that.visualStack,_that.tilesetId,_that.layers,_that.placedElements,_that.entities,_that.connections,_that.warps,_that.triggers,_that.gameplayZones,_that.mapMetadata,_that.properties,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  GridSize size,  ProjectVersion version, @JsonKey(includeIfNull: false)  MapVisualStackConfig? visualStack,  String tilesetId,  List<MapLayer> layers,  List<MapPlacedElement> placedElements,  List<MapEntity> entities,  List<MapConnection> connections,  List<MapWarp> warps,  List<MapTrigger> triggers,  List<MapGameplayZone> gameplayZones,  MapMetadata mapMetadata,  Map<String, dynamic> properties,  List<MapEventDefinition> events)  $default,) {final _that = this;
switch (_that) {
case _MapData():
return $default(_that.id,_that.name,_that.size,_that.version,_that.visualStack,_that.tilesetId,_that.layers,_that.placedElements,_that.entities,_that.connections,_that.warps,_that.triggers,_that.gameplayZones,_that.mapMetadata,_that.properties,_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  GridSize size,  ProjectVersion version, @JsonKey(includeIfNull: false)  MapVisualStackConfig? visualStack,  String tilesetId,  List<MapLayer> layers,  List<MapPlacedElement> placedElements,  List<MapEntity> entities,  List<MapConnection> connections,  List<MapWarp> warps,  List<MapTrigger> triggers,  List<MapGameplayZone> gameplayZones,  MapMetadata mapMetadata,  Map<String, dynamic> properties,  List<MapEventDefinition> events)?  $default,) {final _that = this;
switch (_that) {
case _MapData() when $default != null:
return $default(_that.id,_that.name,_that.size,_that.version,_that.visualStack,_that.tilesetId,_that.layers,_that.placedElements,_that.entities,_that.connections,_that.warps,_that.triggers,_that.gameplayZones,_that.mapMetadata,_that.properties,_that.events);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapData implements MapData {
  const _MapData({required this.id, required this.name, required this.size, this.version = ProjectVersion.v6, @JsonKey(includeIfNull: false) this.visualStack, this.tilesetId = '', final  List<MapLayer> layers = const [], final  List<MapPlacedElement> placedElements = const [], final  List<MapEntity> entities = const [], final  List<MapConnection> connections = const [], final  List<MapWarp> warps = const [], final  List<MapTrigger> triggers = const [], final  List<MapGameplayZone> gameplayZones = const [], this.mapMetadata = const MapMetadata(), final  Map<String, dynamic> properties = const {}, final  List<MapEventDefinition> events = const []}): _layers = layers,_placedElements = placedElements,_entities = entities,_connections = connections,_warps = warps,_triggers = triggers,_gameplayZones = gameplayZones,_properties = properties,_events = events;
  factory _MapData.fromJson(Map<String, dynamic> json) => _$MapDataFromJson(json);

@override final  String id;
@override final  String name;
@override final  GridSize size;
@override@JsonKey() final  ProjectVersion version;
@override@JsonKey(includeIfNull: false) final  MapVisualStackConfig? visualStack;
@override@JsonKey() final  String tilesetId;
 final  List<MapLayer> _layers;
@override@JsonKey() List<MapLayer> get layers {
  if (_layers is EqualUnmodifiableListView) return _layers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_layers);
}

 final  List<MapPlacedElement> _placedElements;
@override@JsonKey() List<MapPlacedElement> get placedElements {
  if (_placedElements is EqualUnmodifiableListView) return _placedElements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_placedElements);
}

 final  List<MapEntity> _entities;
@override@JsonKey() List<MapEntity> get entities {
  if (_entities is EqualUnmodifiableListView) return _entities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entities);
}

 final  List<MapConnection> _connections;
@override@JsonKey() List<MapConnection> get connections {
  if (_connections is EqualUnmodifiableListView) return _connections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connections);
}

 final  List<MapWarp> _warps;
@override@JsonKey() List<MapWarp> get warps {
  if (_warps is EqualUnmodifiableListView) return _warps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warps);
}

 final  List<MapTrigger> _triggers;
@override@JsonKey() List<MapTrigger> get triggers {
  if (_triggers is EqualUnmodifiableListView) return _triggers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_triggers);
}

/// Zones gameplay (rencontres, déplacement, dangers, etc.).
/// Séparées des triggers (logiques scriptées) et des layers visuelles.
 final  List<MapGameplayZone> _gameplayZones;
/// Zones gameplay (rencontres, déplacement, dangers, etc.).
/// Séparées des triggers (logiques scriptées) et des layers visuelles.
@override@JsonKey() List<MapGameplayZone> get gameplayZones {
  if (_gameplayZones is EqualUnmodifiableListView) return _gameplayZones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gameplayZones);
}

@override@JsonKey() final  MapMetadata mapMetadata;
 final  Map<String, dynamic> _properties;
@override@JsonKey() Map<String, dynamic> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}

 final  List<MapEventDefinition> _events;
@override@JsonKey() List<MapEventDefinition> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapDataCopyWith<_MapData> get copyWith => __$MapDataCopyWithImpl<_MapData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapData&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.version, version) || other.version == version)&&(identical(other.visualStack, visualStack) || other.visualStack == visualStack)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&const DeepCollectionEquality().equals(other._layers, _layers)&&const DeepCollectionEquality().equals(other._placedElements, _placedElements)&&const DeepCollectionEquality().equals(other._entities, _entities)&&const DeepCollectionEquality().equals(other._connections, _connections)&&const DeepCollectionEquality().equals(other._warps, _warps)&&const DeepCollectionEquality().equals(other._triggers, _triggers)&&const DeepCollectionEquality().equals(other._gameplayZones, _gameplayZones)&&(identical(other.mapMetadata, mapMetadata) || other.mapMetadata == mapMetadata)&&const DeepCollectionEquality().equals(other._properties, _properties)&&const DeepCollectionEquality().equals(other._events, _events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,size,version,visualStack,tilesetId,const DeepCollectionEquality().hash(_layers),const DeepCollectionEquality().hash(_placedElements),const DeepCollectionEquality().hash(_entities),const DeepCollectionEquality().hash(_connections),const DeepCollectionEquality().hash(_warps),const DeepCollectionEquality().hash(_triggers),const DeepCollectionEquality().hash(_gameplayZones),mapMetadata,const DeepCollectionEquality().hash(_properties),const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'MapData(id: $id, name: $name, size: $size, version: $version, visualStack: $visualStack, tilesetId: $tilesetId, layers: $layers, placedElements: $placedElements, entities: $entities, connections: $connections, warps: $warps, triggers: $triggers, gameplayZones: $gameplayZones, mapMetadata: $mapMetadata, properties: $properties, events: $events)';
}


}

/// @nodoc
abstract mixin class _$MapDataCopyWith<$Res> implements $MapDataCopyWith<$Res> {
  factory _$MapDataCopyWith(_MapData value, $Res Function(_MapData) _then) = __$MapDataCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, GridSize size, ProjectVersion version,@JsonKey(includeIfNull: false) MapVisualStackConfig? visualStack, String tilesetId, List<MapLayer> layers, List<MapPlacedElement> placedElements, List<MapEntity> entities, List<MapConnection> connections, List<MapWarp> warps, List<MapTrigger> triggers, List<MapGameplayZone> gameplayZones, MapMetadata mapMetadata, Map<String, dynamic> properties, List<MapEventDefinition> events
});


@override $GridSizeCopyWith<$Res> get size;@override $MapMetadataCopyWith<$Res> get mapMetadata;

}
/// @nodoc
class __$MapDataCopyWithImpl<$Res>
    implements _$MapDataCopyWith<$Res> {
  __$MapDataCopyWithImpl(this._self, this._then);

  final _MapData _self;
  final $Res Function(_MapData) _then;

/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? size = null,Object? version = null,Object? visualStack = freezed,Object? tilesetId = null,Object? layers = null,Object? placedElements = null,Object? entities = null,Object? connections = null,Object? warps = null,Object? triggers = null,Object? gameplayZones = null,Object? mapMetadata = null,Object? properties = null,Object? events = null,}) {
  return _then(_MapData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as GridSize,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as ProjectVersion,visualStack: freezed == visualStack ? _self.visualStack : visualStack // ignore: cast_nullable_to_non_nullable
as MapVisualStackConfig?,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,layers: null == layers ? _self._layers : layers // ignore: cast_nullable_to_non_nullable
as List<MapLayer>,placedElements: null == placedElements ? _self._placedElements : placedElements // ignore: cast_nullable_to_non_nullable
as List<MapPlacedElement>,entities: null == entities ? _self._entities : entities // ignore: cast_nullable_to_non_nullable
as List<MapEntity>,connections: null == connections ? _self._connections : connections // ignore: cast_nullable_to_non_nullable
as List<MapConnection>,warps: null == warps ? _self._warps : warps // ignore: cast_nullable_to_non_nullable
as List<MapWarp>,triggers: null == triggers ? _self._triggers : triggers // ignore: cast_nullable_to_non_nullable
as List<MapTrigger>,gameplayZones: null == gameplayZones ? _self._gameplayZones : gameplayZones // ignore: cast_nullable_to_non_nullable
as List<MapGameplayZone>,mapMetadata: null == mapMetadata ? _self.mapMetadata : mapMetadata // ignore: cast_nullable_to_non_nullable
as MapMetadata,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<MapEventDefinition>,
  ));
}

/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridSizeCopyWith<$Res> get size {

  return $GridSizeCopyWith<$Res>(_self.size, (value) {
    return _then(_self.copyWith(size: value));
  });
}/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapMetadataCopyWith<$Res> get mapMetadata {

  return $MapMetadataCopyWith<$Res>(_self.mapMetadata, (value) {
    return _then(_self.copyWith(mapMetadata: value));
  });
}
}


/// @nodoc
mixin _$MapGameplayZone {

 String get id; String get name; GameplayZoneKind get kind; MapRect get area;/// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
 int get priority;/// Payload pour [GameplayZoneKind.encounter].
 EncounterZonePayload? get encounter;/// Payload pour [GameplayZoneKind.movement].
 MovementZonePayload? get movement;/// Payload pour [GameplayZoneKind.movementEffect].
 MovementEffectZonePayload? get movementEffect;/// Payload pour [GameplayZoneKind.hazard].
 HazardZonePayload? get hazard;/// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
 SpecialZonePayload? get special;
/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapGameplayZoneCopyWith<MapGameplayZone> get copyWith => _$MapGameplayZoneCopyWithImpl<MapGameplayZone>(this as MapGameplayZone, _$identity);

  /// Serializes this MapGameplayZone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapGameplayZone&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.area, area) || other.area == area)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.encounter, encounter) || other.encounter == encounter)&&(identical(other.movement, movement) || other.movement == movement)&&(identical(other.movementEffect, movementEffect) || other.movementEffect == movementEffect)&&(identical(other.hazard, hazard) || other.hazard == hazard)&&(identical(other.special, special) || other.special == special));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,kind,area,priority,encounter,movement,movementEffect,hazard,special);

@override
String toString() {
  return 'MapGameplayZone(id: $id, name: $name, kind: $kind, area: $area, priority: $priority, encounter: $encounter, movement: $movement, movementEffect: $movementEffect, hazard: $hazard, special: $special)';
}


}

/// @nodoc
abstract mixin class $MapGameplayZoneCopyWith<$Res>  {
  factory $MapGameplayZoneCopyWith(MapGameplayZone value, $Res Function(MapGameplayZone) _then) = _$MapGameplayZoneCopyWithImpl;
@useResult
$Res call({
 String id, String name, GameplayZoneKind kind, MapRect area, int priority, EncounterZonePayload? encounter, MovementZonePayload? movement, MovementEffectZonePayload? movementEffect, HazardZonePayload? hazard, SpecialZonePayload? special
});


$MapRectCopyWith<$Res> get area;$EncounterZonePayloadCopyWith<$Res>? get encounter;$MovementZonePayloadCopyWith<$Res>? get movement;$MovementEffectZonePayloadCopyWith<$Res>? get movementEffect;$HazardZonePayloadCopyWith<$Res>? get hazard;$SpecialZonePayloadCopyWith<$Res>? get special;

}
/// @nodoc
class _$MapGameplayZoneCopyWithImpl<$Res>
    implements $MapGameplayZoneCopyWith<$Res> {
  _$MapGameplayZoneCopyWithImpl(this._self, this._then);

  final MapGameplayZone _self;
  final $Res Function(MapGameplayZone) _then;

/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? area = null,Object? priority = null,Object? encounter = freezed,Object? movement = freezed,Object? movementEffect = freezed,Object? hazard = freezed,Object? special = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GameplayZoneKind,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as MapRect,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,encounter: freezed == encounter ? _self.encounter : encounter // ignore: cast_nullable_to_non_nullable
as EncounterZonePayload?,movement: freezed == movement ? _self.movement : movement // ignore: cast_nullable_to_non_nullable
as MovementZonePayload?,movementEffect: freezed == movementEffect ? _self.movementEffect : movementEffect // ignore: cast_nullable_to_non_nullable
as MovementEffectZonePayload?,hazard: freezed == hazard ? _self.hazard : hazard // ignore: cast_nullable_to_non_nullable
as HazardZonePayload?,special: freezed == special ? _self.special : special // ignore: cast_nullable_to_non_nullable
as SpecialZonePayload?,
  ));
}
/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRectCopyWith<$Res> get area {

  return $MapRectCopyWith<$Res>(_self.area, (value) {
    return _then(_self.copyWith(area: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EncounterZonePayloadCopyWith<$Res>? get encounter {
    if (_self.encounter == null) {
    return null;
  }

  return $EncounterZonePayloadCopyWith<$Res>(_self.encounter!, (value) {
    return _then(_self.copyWith(encounter: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementZonePayloadCopyWith<$Res>? get movement {
    if (_self.movement == null) {
    return null;
  }

  return $MovementZonePayloadCopyWith<$Res>(_self.movement!, (value) {
    return _then(_self.copyWith(movement: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementEffectZonePayloadCopyWith<$Res>? get movementEffect {
    if (_self.movementEffect == null) {
    return null;
  }

  return $MovementEffectZonePayloadCopyWith<$Res>(_self.movementEffect!, (value) {
    return _then(_self.copyWith(movementEffect: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HazardZonePayloadCopyWith<$Res>? get hazard {
    if (_self.hazard == null) {
    return null;
  }

  return $HazardZonePayloadCopyWith<$Res>(_self.hazard!, (value) {
    return _then(_self.copyWith(hazard: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpecialZonePayloadCopyWith<$Res>? get special {
    if (_self.special == null) {
    return null;
  }

  return $SpecialZonePayloadCopyWith<$Res>(_self.special!, (value) {
    return _then(_self.copyWith(special: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapGameplayZone].
extension MapGameplayZonePatterns on MapGameplayZone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapGameplayZone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapGameplayZone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapGameplayZone value)  $default,){
final _that = this;
switch (_that) {
case _MapGameplayZone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapGameplayZone value)?  $default,){
final _that = this;
switch (_that) {
case _MapGameplayZone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  GameplayZoneKind kind,  MapRect area,  int priority,  EncounterZonePayload? encounter,  MovementZonePayload? movement,  MovementEffectZonePayload? movementEffect,  HazardZonePayload? hazard,  SpecialZonePayload? special)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapGameplayZone() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.area,_that.priority,_that.encounter,_that.movement,_that.movementEffect,_that.hazard,_that.special);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  GameplayZoneKind kind,  MapRect area,  int priority,  EncounterZonePayload? encounter,  MovementZonePayload? movement,  MovementEffectZonePayload? movementEffect,  HazardZonePayload? hazard,  SpecialZonePayload? special)  $default,) {final _that = this;
switch (_that) {
case _MapGameplayZone():
return $default(_that.id,_that.name,_that.kind,_that.area,_that.priority,_that.encounter,_that.movement,_that.movementEffect,_that.hazard,_that.special);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  GameplayZoneKind kind,  MapRect area,  int priority,  EncounterZonePayload? encounter,  MovementZonePayload? movement,  MovementEffectZonePayload? movementEffect,  HazardZonePayload? hazard,  SpecialZonePayload? special)?  $default,) {final _that = this;
switch (_that) {
case _MapGameplayZone() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.area,_that.priority,_that.encounter,_that.movement,_that.movementEffect,_that.hazard,_that.special);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapGameplayZone implements MapGameplayZone {
  const _MapGameplayZone({required this.id, this.name = '', required this.kind, required this.area, this.priority = 0, this.encounter, this.movement, this.movementEffect, this.hazard, this.special});
  factory _MapGameplayZone.fromJson(Map<String, dynamic> json) => _$MapGameplayZoneFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override final  GameplayZoneKind kind;
@override final  MapRect area;
/// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
@override@JsonKey() final  int priority;
/// Payload pour [GameplayZoneKind.encounter].
@override final  EncounterZonePayload? encounter;
/// Payload pour [GameplayZoneKind.movement].
@override final  MovementZonePayload? movement;
/// Payload pour [GameplayZoneKind.movementEffect].
@override final  MovementEffectZonePayload? movementEffect;
/// Payload pour [GameplayZoneKind.hazard].
@override final  HazardZonePayload? hazard;
/// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
@override final  SpecialZonePayload? special;

/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapGameplayZoneCopyWith<_MapGameplayZone> get copyWith => __$MapGameplayZoneCopyWithImpl<_MapGameplayZone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapGameplayZoneToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapGameplayZone&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.area, area) || other.area == area)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.encounter, encounter) || other.encounter == encounter)&&(identical(other.movement, movement) || other.movement == movement)&&(identical(other.movementEffect, movementEffect) || other.movementEffect == movementEffect)&&(identical(other.hazard, hazard) || other.hazard == hazard)&&(identical(other.special, special) || other.special == special));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,kind,area,priority,encounter,movement,movementEffect,hazard,special);

@override
String toString() {
  return 'MapGameplayZone(id: $id, name: $name, kind: $kind, area: $area, priority: $priority, encounter: $encounter, movement: $movement, movementEffect: $movementEffect, hazard: $hazard, special: $special)';
}


}

/// @nodoc
abstract mixin class _$MapGameplayZoneCopyWith<$Res> implements $MapGameplayZoneCopyWith<$Res> {
  factory _$MapGameplayZoneCopyWith(_MapGameplayZone value, $Res Function(_MapGameplayZone) _then) = __$MapGameplayZoneCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, GameplayZoneKind kind, MapRect area, int priority, EncounterZonePayload? encounter, MovementZonePayload? movement, MovementEffectZonePayload? movementEffect, HazardZonePayload? hazard, SpecialZonePayload? special
});


@override $MapRectCopyWith<$Res> get area;@override $EncounterZonePayloadCopyWith<$Res>? get encounter;@override $MovementZonePayloadCopyWith<$Res>? get movement;@override $MovementEffectZonePayloadCopyWith<$Res>? get movementEffect;@override $HazardZonePayloadCopyWith<$Res>? get hazard;@override $SpecialZonePayloadCopyWith<$Res>? get special;

}
/// @nodoc
class __$MapGameplayZoneCopyWithImpl<$Res>
    implements _$MapGameplayZoneCopyWith<$Res> {
  __$MapGameplayZoneCopyWithImpl(this._self, this._then);

  final _MapGameplayZone _self;
  final $Res Function(_MapGameplayZone) _then;

/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? area = null,Object? priority = null,Object? encounter = freezed,Object? movement = freezed,Object? movementEffect = freezed,Object? hazard = freezed,Object? special = freezed,}) {
  return _then(_MapGameplayZone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GameplayZoneKind,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as MapRect,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,encounter: freezed == encounter ? _self.encounter : encounter // ignore: cast_nullable_to_non_nullable
as EncounterZonePayload?,movement: freezed == movement ? _self.movement : movement // ignore: cast_nullable_to_non_nullable
as MovementZonePayload?,movementEffect: freezed == movementEffect ? _self.movementEffect : movementEffect // ignore: cast_nullable_to_non_nullable
as MovementEffectZonePayload?,hazard: freezed == hazard ? _self.hazard : hazard // ignore: cast_nullable_to_non_nullable
as HazardZonePayload?,special: freezed == special ? _self.special : special // ignore: cast_nullable_to_non_nullable
as SpecialZonePayload?,
  ));
}

/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRectCopyWith<$Res> get area {

  return $MapRectCopyWith<$Res>(_self.area, (value) {
    return _then(_self.copyWith(area: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EncounterZonePayloadCopyWith<$Res>? get encounter {
    if (_self.encounter == null) {
    return null;
  }

  return $EncounterZonePayloadCopyWith<$Res>(_self.encounter!, (value) {
    return _then(_self.copyWith(encounter: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementZonePayloadCopyWith<$Res>? get movement {
    if (_self.movement == null) {
    return null;
  }

  return $MovementZonePayloadCopyWith<$Res>(_self.movement!, (value) {
    return _then(_self.copyWith(movement: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementEffectZonePayloadCopyWith<$Res>? get movementEffect {
    if (_self.movementEffect == null) {
    return null;
  }

  return $MovementEffectZonePayloadCopyWith<$Res>(_self.movementEffect!, (value) {
    return _then(_self.copyWith(movementEffect: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HazardZonePayloadCopyWith<$Res>? get hazard {
    if (_self.hazard == null) {
    return null;
  }

  return $HazardZonePayloadCopyWith<$Res>(_self.hazard!, (value) {
    return _then(_self.copyWith(hazard: value));
  });
}/// Create a copy of MapGameplayZone
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpecialZonePayloadCopyWith<$Res>? get special {
    if (_self.special == null) {
    return null;
  }

  return $SpecialZonePayloadCopyWith<$Res>(_self.special!, (value) {
    return _then(_self.copyWith(special: value));
  });
}
}


/// @nodoc
mixin _$MapPlacedElement {

 String get id; String get layerId; String get elementId; GridPos get pos;@JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson) int get quarterTurns; bool get applyCollision; double get opacity; MapPlacedElementAnimation? get animation;@MapPlacedElementShadowOverrideJsonConverter() MapPlacedElementShadowOverride? get shadowOverride; List<MapPlacedElementBehavior> get behaviors; Map<String, String> get properties;
/// Create a copy of MapPlacedElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapPlacedElementCopyWith<MapPlacedElement> get copyWith => _$MapPlacedElementCopyWithImpl<MapPlacedElement>(this as MapPlacedElement, _$identity);

  /// Serializes this MapPlacedElement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPlacedElement&&(identical(other.id, id) || other.id == id)&&(identical(other.layerId, layerId) || other.layerId == layerId)&&(identical(other.elementId, elementId) || other.elementId == elementId)&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.quarterTurns, quarterTurns) || other.quarterTurns == quarterTurns)&&(identical(other.applyCollision, applyCollision) || other.applyCollision == applyCollision)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.animation, animation) || other.animation == animation)&&(identical(other.shadowOverride, shadowOverride) || other.shadowOverride == shadowOverride)&&const DeepCollectionEquality().equals(other.behaviors, behaviors)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,layerId,elementId,pos,quarterTurns,applyCollision,opacity,animation,shadowOverride,const DeepCollectionEquality().hash(behaviors),const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'MapPlacedElement(id: $id, layerId: $layerId, elementId: $elementId, pos: $pos, quarterTurns: $quarterTurns, applyCollision: $applyCollision, opacity: $opacity, animation: $animation, shadowOverride: $shadowOverride, behaviors: $behaviors, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $MapPlacedElementCopyWith<$Res>  {
  factory $MapPlacedElementCopyWith(MapPlacedElement value, $Res Function(MapPlacedElement) _then) = _$MapPlacedElementCopyWithImpl;
@useResult
$Res call({
 String id, String layerId, String elementId, GridPos pos,@JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson) int quarterTurns, bool applyCollision, double opacity, MapPlacedElementAnimation? animation,@MapPlacedElementShadowOverrideJsonConverter() MapPlacedElementShadowOverride? shadowOverride, List<MapPlacedElementBehavior> behaviors, Map<String, String> properties
});


$GridPosCopyWith<$Res> get pos;$MapPlacedElementAnimationCopyWith<$Res>? get animation;

}
/// @nodoc
class _$MapPlacedElementCopyWithImpl<$Res>
    implements $MapPlacedElementCopyWith<$Res> {
  _$MapPlacedElementCopyWithImpl(this._self, this._then);

  final MapPlacedElement _self;
  final $Res Function(MapPlacedElement) _then;

/// Create a copy of MapPlacedElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? layerId = null,Object? elementId = null,Object? pos = null,Object? quarterTurns = null,Object? applyCollision = null,Object? opacity = null,Object? animation = freezed,Object? shadowOverride = freezed,Object? behaviors = null,Object? properties = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,layerId: null == layerId ? _self.layerId : layerId // ignore: cast_nullable_to_non_nullable
as String,elementId: null == elementId ? _self.elementId : elementId // ignore: cast_nullable_to_non_nullable
as String,pos: null == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as GridPos,quarterTurns: null == quarterTurns ? _self.quarterTurns : quarterTurns // ignore: cast_nullable_to_non_nullable
as int,applyCollision: null == applyCollision ? _self.applyCollision : applyCollision // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,animation: freezed == animation ? _self.animation : animation // ignore: cast_nullable_to_non_nullable
as MapPlacedElementAnimation?,shadowOverride: freezed == shadowOverride ? _self.shadowOverride : shadowOverride // ignore: cast_nullable_to_non_nullable
as MapPlacedElementShadowOverride?,behaviors: null == behaviors ? _self.behaviors : behaviors // ignore: cast_nullable_to_non_nullable
as List<MapPlacedElementBehavior>,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of MapPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get pos {

  return $GridPosCopyWith<$Res>(_self.pos, (value) {
    return _then(_self.copyWith(pos: value));
  });
}/// Create a copy of MapPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapPlacedElementAnimationCopyWith<$Res>? get animation {
    if (_self.animation == null) {
    return null;
  }

  return $MapPlacedElementAnimationCopyWith<$Res>(_self.animation!, (value) {
    return _then(_self.copyWith(animation: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapPlacedElement].
extension MapPlacedElementPatterns on MapPlacedElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapPlacedElement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapPlacedElement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapPlacedElement value)  $default,){
final _that = this;
switch (_that) {
case _MapPlacedElement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapPlacedElement value)?  $default,){
final _that = this;
switch (_that) {
case _MapPlacedElement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String layerId,  String elementId,  GridPos pos, @JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson)  int quarterTurns,  bool applyCollision,  double opacity,  MapPlacedElementAnimation? animation, @MapPlacedElementShadowOverrideJsonConverter()  MapPlacedElementShadowOverride? shadowOverride,  List<MapPlacedElementBehavior> behaviors,  Map<String, String> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapPlacedElement() when $default != null:
return $default(_that.id,_that.layerId,_that.elementId,_that.pos,_that.quarterTurns,_that.applyCollision,_that.opacity,_that.animation,_that.shadowOverride,_that.behaviors,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String layerId,  String elementId,  GridPos pos, @JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson)  int quarterTurns,  bool applyCollision,  double opacity,  MapPlacedElementAnimation? animation, @MapPlacedElementShadowOverrideJsonConverter()  MapPlacedElementShadowOverride? shadowOverride,  List<MapPlacedElementBehavior> behaviors,  Map<String, String> properties)  $default,) {final _that = this;
switch (_that) {
case _MapPlacedElement():
return $default(_that.id,_that.layerId,_that.elementId,_that.pos,_that.quarterTurns,_that.applyCollision,_that.opacity,_that.animation,_that.shadowOverride,_that.behaviors,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String layerId,  String elementId,  GridPos pos, @JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson)  int quarterTurns,  bool applyCollision,  double opacity,  MapPlacedElementAnimation? animation, @MapPlacedElementShadowOverrideJsonConverter()  MapPlacedElementShadowOverride? shadowOverride,  List<MapPlacedElementBehavior> behaviors,  Map<String, String> properties)?  $default,) {final _that = this;
switch (_that) {
case _MapPlacedElement() when $default != null:
return $default(_that.id,_that.layerId,_that.elementId,_that.pos,_that.quarterTurns,_that.applyCollision,_that.opacity,_that.animation,_that.shadowOverride,_that.behaviors,_that.properties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapPlacedElement implements MapPlacedElement {
  const _MapPlacedElement({required this.id, required this.layerId, required this.elementId, required this.pos, @JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson) this.quarterTurns = 0, this.applyCollision = true, this.opacity = 1.0, this.animation, @MapPlacedElementShadowOverrideJsonConverter() this.shadowOverride, final  List<MapPlacedElementBehavior> behaviors = const [], final  Map<String, String> properties = const {}}): _behaviors = behaviors,_properties = properties;
  factory _MapPlacedElement.fromJson(Map<String, dynamic> json) => _$MapPlacedElementFromJson(json);

@override final  String id;
@override final  String layerId;
@override final  String elementId;
@override final  GridPos pos;
@override@JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson) final  int quarterTurns;
@override@JsonKey() final  bool applyCollision;
@override@JsonKey() final  double opacity;
@override final  MapPlacedElementAnimation? animation;
@override@MapPlacedElementShadowOverrideJsonConverter() final  MapPlacedElementShadowOverride? shadowOverride;
 final  List<MapPlacedElementBehavior> _behaviors;
@override@JsonKey() List<MapPlacedElementBehavior> get behaviors {
  if (_behaviors is EqualUnmodifiableListView) return _behaviors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_behaviors);
}

 final  Map<String, String> _properties;
@override@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of MapPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapPlacedElementCopyWith<_MapPlacedElement> get copyWith => __$MapPlacedElementCopyWithImpl<_MapPlacedElement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapPlacedElementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapPlacedElement&&(identical(other.id, id) || other.id == id)&&(identical(other.layerId, layerId) || other.layerId == layerId)&&(identical(other.elementId, elementId) || other.elementId == elementId)&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.quarterTurns, quarterTurns) || other.quarterTurns == quarterTurns)&&(identical(other.applyCollision, applyCollision) || other.applyCollision == applyCollision)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.animation, animation) || other.animation == animation)&&(identical(other.shadowOverride, shadowOverride) || other.shadowOverride == shadowOverride)&&const DeepCollectionEquality().equals(other._behaviors, _behaviors)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,layerId,elementId,pos,quarterTurns,applyCollision,opacity,animation,shadowOverride,const DeepCollectionEquality().hash(_behaviors),const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'MapPlacedElement(id: $id, layerId: $layerId, elementId: $elementId, pos: $pos, quarterTurns: $quarterTurns, applyCollision: $applyCollision, opacity: $opacity, animation: $animation, shadowOverride: $shadowOverride, behaviors: $behaviors, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$MapPlacedElementCopyWith<$Res> implements $MapPlacedElementCopyWith<$Res> {
  factory _$MapPlacedElementCopyWith(_MapPlacedElement value, $Res Function(_MapPlacedElement) _then) = __$MapPlacedElementCopyWithImpl;
@override @useResult
$Res call({
 String id, String layerId, String elementId, GridPos pos,@JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson) int quarterTurns, bool applyCollision, double opacity, MapPlacedElementAnimation? animation,@MapPlacedElementShadowOverrideJsonConverter() MapPlacedElementShadowOverride? shadowOverride, List<MapPlacedElementBehavior> behaviors, Map<String, String> properties
});


@override $GridPosCopyWith<$Res> get pos;@override $MapPlacedElementAnimationCopyWith<$Res>? get animation;

}
/// @nodoc
class __$MapPlacedElementCopyWithImpl<$Res>
    implements _$MapPlacedElementCopyWith<$Res> {
  __$MapPlacedElementCopyWithImpl(this._self, this._then);

  final _MapPlacedElement _self;
  final $Res Function(_MapPlacedElement) _then;

/// Create a copy of MapPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? layerId = null,Object? elementId = null,Object? pos = null,Object? quarterTurns = null,Object? applyCollision = null,Object? opacity = null,Object? animation = freezed,Object? shadowOverride = freezed,Object? behaviors = null,Object? properties = null,}) {
  return _then(_MapPlacedElement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,layerId: null == layerId ? _self.layerId : layerId // ignore: cast_nullable_to_non_nullable
as String,elementId: null == elementId ? _self.elementId : elementId // ignore: cast_nullable_to_non_nullable
as String,pos: null == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as GridPos,quarterTurns: null == quarterTurns ? _self.quarterTurns : quarterTurns // ignore: cast_nullable_to_non_nullable
as int,applyCollision: null == applyCollision ? _self.applyCollision : applyCollision // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,animation: freezed == animation ? _self.animation : animation // ignore: cast_nullable_to_non_nullable
as MapPlacedElementAnimation?,shadowOverride: freezed == shadowOverride ? _self.shadowOverride : shadowOverride // ignore: cast_nullable_to_non_nullable
as MapPlacedElementShadowOverride?,behaviors: null == behaviors ? _self._behaviors : behaviors // ignore: cast_nullable_to_non_nullable
as List<MapPlacedElementBehavior>,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of MapPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get pos {

  return $GridPosCopyWith<$Res>(_self.pos, (value) {
    return _then(_self.copyWith(pos: value));
  });
}/// Create a copy of MapPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapPlacedElementAnimationCopyWith<$Res>? get animation {
    if (_self.animation == null) {
    return null;
  }

  return $MapPlacedElementAnimationCopyWith<$Res>(_self.animation!, (value) {
    return _then(_self.copyWith(animation: value));
  });
}
}


/// @nodoc
mixin _$MapPlacedElementBehavior {

 String get id; bool get enabled; MapPlacedElementTriggerScope get triggerScope; int? get cooldownMs; MapPlacedElementTriggerType get trigger; MapPlacedElementEffect get effect;
/// Create a copy of MapPlacedElementBehavior
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapPlacedElementBehaviorCopyWith<MapPlacedElementBehavior> get copyWith => _$MapPlacedElementBehaviorCopyWithImpl<MapPlacedElementBehavior>(this as MapPlacedElementBehavior, _$identity);

  /// Serializes this MapPlacedElementBehavior to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPlacedElementBehavior&&(identical(other.id, id) || other.id == id)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.triggerScope, triggerScope) || other.triggerScope == triggerScope)&&(identical(other.cooldownMs, cooldownMs) || other.cooldownMs == cooldownMs)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.effect, effect) || other.effect == effect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,enabled,triggerScope,cooldownMs,trigger,effect);

@override
String toString() {
  return 'MapPlacedElementBehavior(id: $id, enabled: $enabled, triggerScope: $triggerScope, cooldownMs: $cooldownMs, trigger: $trigger, effect: $effect)';
}


}

/// @nodoc
abstract mixin class $MapPlacedElementBehaviorCopyWith<$Res>  {
  factory $MapPlacedElementBehaviorCopyWith(MapPlacedElementBehavior value, $Res Function(MapPlacedElementBehavior) _then) = _$MapPlacedElementBehaviorCopyWithImpl;
@useResult
$Res call({
 String id, bool enabled, MapPlacedElementTriggerScope triggerScope, int? cooldownMs, MapPlacedElementTriggerType trigger, MapPlacedElementEffect effect
});


$MapPlacedElementEffectCopyWith<$Res> get effect;

}
/// @nodoc
class _$MapPlacedElementBehaviorCopyWithImpl<$Res>
    implements $MapPlacedElementBehaviorCopyWith<$Res> {
  _$MapPlacedElementBehaviorCopyWithImpl(this._self, this._then);

  final MapPlacedElementBehavior _self;
  final $Res Function(MapPlacedElementBehavior) _then;

/// Create a copy of MapPlacedElementBehavior
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? enabled = null,Object? triggerScope = null,Object? cooldownMs = freezed,Object? trigger = null,Object? effect = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,triggerScope: null == triggerScope ? _self.triggerScope : triggerScope // ignore: cast_nullable_to_non_nullable
as MapPlacedElementTriggerScope,cooldownMs: freezed == cooldownMs ? _self.cooldownMs : cooldownMs // ignore: cast_nullable_to_non_nullable
as int?,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as MapPlacedElementTriggerType,effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as MapPlacedElementEffect,
  ));
}
/// Create a copy of MapPlacedElementBehavior
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapPlacedElementEffectCopyWith<$Res> get effect {

  return $MapPlacedElementEffectCopyWith<$Res>(_self.effect, (value) {
    return _then(_self.copyWith(effect: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapPlacedElementBehavior].
extension MapPlacedElementBehaviorPatterns on MapPlacedElementBehavior {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapPlacedElementBehavior value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapPlacedElementBehavior() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapPlacedElementBehavior value)  $default,){
final _that = this;
switch (_that) {
case _MapPlacedElementBehavior():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapPlacedElementBehavior value)?  $default,){
final _that = this;
switch (_that) {
case _MapPlacedElementBehavior() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  bool enabled,  MapPlacedElementTriggerScope triggerScope,  int? cooldownMs,  MapPlacedElementTriggerType trigger,  MapPlacedElementEffect effect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapPlacedElementBehavior() when $default != null:
return $default(_that.id,_that.enabled,_that.triggerScope,_that.cooldownMs,_that.trigger,_that.effect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  bool enabled,  MapPlacedElementTriggerScope triggerScope,  int? cooldownMs,  MapPlacedElementTriggerType trigger,  MapPlacedElementEffect effect)  $default,) {final _that = this;
switch (_that) {
case _MapPlacedElementBehavior():
return $default(_that.id,_that.enabled,_that.triggerScope,_that.cooldownMs,_that.trigger,_that.effect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  bool enabled,  MapPlacedElementTriggerScope triggerScope,  int? cooldownMs,  MapPlacedElementTriggerType trigger,  MapPlacedElementEffect effect)?  $default,) {final _that = this;
switch (_that) {
case _MapPlacedElementBehavior() when $default != null:
return $default(_that.id,_that.enabled,_that.triggerScope,_that.cooldownMs,_that.trigger,_that.effect);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapPlacedElementBehavior implements MapPlacedElementBehavior {
  const _MapPlacedElementBehavior({this.id = '', this.enabled = true, this.triggerScope = MapPlacedElementTriggerScope.defaultScope, this.cooldownMs, this.trigger = MapPlacedElementTriggerType.onAction, required this.effect});
  factory _MapPlacedElementBehavior.fromJson(Map<String, dynamic> json) => _$MapPlacedElementBehaviorFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  MapPlacedElementTriggerScope triggerScope;
@override final  int? cooldownMs;
@override@JsonKey() final  MapPlacedElementTriggerType trigger;
@override final  MapPlacedElementEffect effect;

/// Create a copy of MapPlacedElementBehavior
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapPlacedElementBehaviorCopyWith<_MapPlacedElementBehavior> get copyWith => __$MapPlacedElementBehaviorCopyWithImpl<_MapPlacedElementBehavior>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapPlacedElementBehaviorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapPlacedElementBehavior&&(identical(other.id, id) || other.id == id)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.triggerScope, triggerScope) || other.triggerScope == triggerScope)&&(identical(other.cooldownMs, cooldownMs) || other.cooldownMs == cooldownMs)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.effect, effect) || other.effect == effect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,enabled,triggerScope,cooldownMs,trigger,effect);

@override
String toString() {
  return 'MapPlacedElementBehavior(id: $id, enabled: $enabled, triggerScope: $triggerScope, cooldownMs: $cooldownMs, trigger: $trigger, effect: $effect)';
}


}

/// @nodoc
abstract mixin class _$MapPlacedElementBehaviorCopyWith<$Res> implements $MapPlacedElementBehaviorCopyWith<$Res> {
  factory _$MapPlacedElementBehaviorCopyWith(_MapPlacedElementBehavior value, $Res Function(_MapPlacedElementBehavior) _then) = __$MapPlacedElementBehaviorCopyWithImpl;
@override @useResult
$Res call({
 String id, bool enabled, MapPlacedElementTriggerScope triggerScope, int? cooldownMs, MapPlacedElementTriggerType trigger, MapPlacedElementEffect effect
});


@override $MapPlacedElementEffectCopyWith<$Res> get effect;

}
/// @nodoc
class __$MapPlacedElementBehaviorCopyWithImpl<$Res>
    implements _$MapPlacedElementBehaviorCopyWith<$Res> {
  __$MapPlacedElementBehaviorCopyWithImpl(this._self, this._then);

  final _MapPlacedElementBehavior _self;
  final $Res Function(_MapPlacedElementBehavior) _then;

/// Create a copy of MapPlacedElementBehavior
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? enabled = null,Object? triggerScope = null,Object? cooldownMs = freezed,Object? trigger = null,Object? effect = null,}) {
  return _then(_MapPlacedElementBehavior(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,triggerScope: null == triggerScope ? _self.triggerScope : triggerScope // ignore: cast_nullable_to_non_nullable
as MapPlacedElementTriggerScope,cooldownMs: freezed == cooldownMs ? _self.cooldownMs : cooldownMs // ignore: cast_nullable_to_non_nullable
as int?,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as MapPlacedElementTriggerType,effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as MapPlacedElementEffect,
  ));
}

/// Create a copy of MapPlacedElementBehavior
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapPlacedElementEffectCopyWith<$Res> get effect {

  return $MapPlacedElementEffectCopyWith<$Res>(_self.effect, (value) {
    return _then(_self.copyWith(effect: value));
  });
}
}


/// @nodoc
mixin _$MapPlacedElementEffect {

 MapPlacedElementEffectType get type; String? get message; DialogueRef? get dialogue; bool? get animationEnabled;
/// Create a copy of MapPlacedElementEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapPlacedElementEffectCopyWith<MapPlacedElementEffect> get copyWith => _$MapPlacedElementEffectCopyWithImpl<MapPlacedElementEffect>(this as MapPlacedElementEffect, _$identity);

  /// Serializes this MapPlacedElementEffect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPlacedElementEffect&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.animationEnabled, animationEnabled) || other.animationEnabled == animationEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,message,dialogue,animationEnabled);

@override
String toString() {
  return 'MapPlacedElementEffect(type: $type, message: $message, dialogue: $dialogue, animationEnabled: $animationEnabled)';
}


}

/// @nodoc
abstract mixin class $MapPlacedElementEffectCopyWith<$Res>  {
  factory $MapPlacedElementEffectCopyWith(MapPlacedElementEffect value, $Res Function(MapPlacedElementEffect) _then) = _$MapPlacedElementEffectCopyWithImpl;
@useResult
$Res call({
 MapPlacedElementEffectType type, String? message, DialogueRef? dialogue, bool? animationEnabled
});


$DialogueRefCopyWith<$Res>? get dialogue;

}
/// @nodoc
class _$MapPlacedElementEffectCopyWithImpl<$Res>
    implements $MapPlacedElementEffectCopyWith<$Res> {
  _$MapPlacedElementEffectCopyWithImpl(this._self, this._then);

  final MapPlacedElementEffect _self;
  final $Res Function(MapPlacedElementEffect) _then;

/// Create a copy of MapPlacedElementEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? message = freezed,Object? dialogue = freezed,Object? animationEnabled = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MapPlacedElementEffectType,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,dialogue: freezed == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as DialogueRef?,animationEnabled: freezed == animationEnabled ? _self.animationEnabled : animationEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of MapPlacedElementEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
    return null;
  }

  return $DialogueRefCopyWith<$Res>(_self.dialogue!, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapPlacedElementEffect].
extension MapPlacedElementEffectPatterns on MapPlacedElementEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapPlacedElementEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapPlacedElementEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapPlacedElementEffect value)  $default,){
final _that = this;
switch (_that) {
case _MapPlacedElementEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapPlacedElementEffect value)?  $default,){
final _that = this;
switch (_that) {
case _MapPlacedElementEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MapPlacedElementEffectType type,  String? message,  DialogueRef? dialogue,  bool? animationEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapPlacedElementEffect() when $default != null:
return $default(_that.type,_that.message,_that.dialogue,_that.animationEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MapPlacedElementEffectType type,  String? message,  DialogueRef? dialogue,  bool? animationEnabled)  $default,) {final _that = this;
switch (_that) {
case _MapPlacedElementEffect():
return $default(_that.type,_that.message,_that.dialogue,_that.animationEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MapPlacedElementEffectType type,  String? message,  DialogueRef? dialogue,  bool? animationEnabled)?  $default,) {final _that = this;
switch (_that) {
case _MapPlacedElementEffect() when $default != null:
return $default(_that.type,_that.message,_that.dialogue,_that.animationEnabled);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapPlacedElementEffect implements MapPlacedElementEffect {
  const _MapPlacedElementEffect({required this.type, this.message, this.dialogue, this.animationEnabled});
  factory _MapPlacedElementEffect.fromJson(Map<String, dynamic> json) => _$MapPlacedElementEffectFromJson(json);

@override final  MapPlacedElementEffectType type;
@override final  String? message;
@override final  DialogueRef? dialogue;
@override final  bool? animationEnabled;

/// Create a copy of MapPlacedElementEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapPlacedElementEffectCopyWith<_MapPlacedElementEffect> get copyWith => __$MapPlacedElementEffectCopyWithImpl<_MapPlacedElementEffect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapPlacedElementEffectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapPlacedElementEffect&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.animationEnabled, animationEnabled) || other.animationEnabled == animationEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,message,dialogue,animationEnabled);

@override
String toString() {
  return 'MapPlacedElementEffect(type: $type, message: $message, dialogue: $dialogue, animationEnabled: $animationEnabled)';
}


}

/// @nodoc
abstract mixin class _$MapPlacedElementEffectCopyWith<$Res> implements $MapPlacedElementEffectCopyWith<$Res> {
  factory _$MapPlacedElementEffectCopyWith(_MapPlacedElementEffect value, $Res Function(_MapPlacedElementEffect) _then) = __$MapPlacedElementEffectCopyWithImpl;
@override @useResult
$Res call({
 MapPlacedElementEffectType type, String? message, DialogueRef? dialogue, bool? animationEnabled
});


@override $DialogueRefCopyWith<$Res>? get dialogue;

}
/// @nodoc
class __$MapPlacedElementEffectCopyWithImpl<$Res>
    implements _$MapPlacedElementEffectCopyWith<$Res> {
  __$MapPlacedElementEffectCopyWithImpl(this._self, this._then);

  final _MapPlacedElementEffect _self;
  final $Res Function(_MapPlacedElementEffect) _then;

/// Create a copy of MapPlacedElementEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? message = freezed,Object? dialogue = freezed,Object? animationEnabled = freezed,}) {
  return _then(_MapPlacedElementEffect(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MapPlacedElementEffectType,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,dialogue: freezed == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as DialogueRef?,animationEnabled: freezed == animationEnabled ? _self.animationEnabled : animationEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of MapPlacedElementEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
    return null;
  }

  return $DialogueRefCopyWith<$Res>(_self.dialogue!, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}
}


/// @nodoc
mixin _$MapPlacedElementAnimation {

 bool get enabled; MapPlacedElementAnimationMode get mode; bool get autoplay; double get speed; double? get startOffsetMs; bool get randomStart;
/// Create a copy of MapPlacedElementAnimation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapPlacedElementAnimationCopyWith<MapPlacedElementAnimation> get copyWith => _$MapPlacedElementAnimationCopyWithImpl<MapPlacedElementAnimation>(this as MapPlacedElementAnimation, _$identity);

  /// Serializes this MapPlacedElementAnimation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPlacedElementAnimation&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.autoplay, autoplay) || other.autoplay == autoplay)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.startOffsetMs, startOffsetMs) || other.startOffsetMs == startOffsetMs)&&(identical(other.randomStart, randomStart) || other.randomStart == randomStart));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,mode,autoplay,speed,startOffsetMs,randomStart);

@override
String toString() {
  return 'MapPlacedElementAnimation(enabled: $enabled, mode: $mode, autoplay: $autoplay, speed: $speed, startOffsetMs: $startOffsetMs, randomStart: $randomStart)';
}


}

/// @nodoc
abstract mixin class $MapPlacedElementAnimationCopyWith<$Res>  {
  factory $MapPlacedElementAnimationCopyWith(MapPlacedElementAnimation value, $Res Function(MapPlacedElementAnimation) _then) = _$MapPlacedElementAnimationCopyWithImpl;
@useResult
$Res call({
 bool enabled, MapPlacedElementAnimationMode mode, bool autoplay, double speed, double? startOffsetMs, bool randomStart
});




}
/// @nodoc
class _$MapPlacedElementAnimationCopyWithImpl<$Res>
    implements $MapPlacedElementAnimationCopyWith<$Res> {
  _$MapPlacedElementAnimationCopyWithImpl(this._self, this._then);

  final MapPlacedElementAnimation _self;
  final $Res Function(MapPlacedElementAnimation) _then;

/// Create a copy of MapPlacedElementAnimation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? mode = null,Object? autoplay = null,Object? speed = null,Object? startOffsetMs = freezed,Object? randomStart = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MapPlacedElementAnimationMode,autoplay: null == autoplay ? _self.autoplay : autoplay // ignore: cast_nullable_to_non_nullable
as bool,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,startOffsetMs: freezed == startOffsetMs ? _self.startOffsetMs : startOffsetMs // ignore: cast_nullable_to_non_nullable
as double?,randomStart: null == randomStart ? _self.randomStart : randomStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MapPlacedElementAnimation].
extension MapPlacedElementAnimationPatterns on MapPlacedElementAnimation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapPlacedElementAnimation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapPlacedElementAnimation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapPlacedElementAnimation value)  $default,){
final _that = this;
switch (_that) {
case _MapPlacedElementAnimation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapPlacedElementAnimation value)?  $default,){
final _that = this;
switch (_that) {
case _MapPlacedElementAnimation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  MapPlacedElementAnimationMode mode,  bool autoplay,  double speed,  double? startOffsetMs,  bool randomStart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapPlacedElementAnimation() when $default != null:
return $default(_that.enabled,_that.mode,_that.autoplay,_that.speed,_that.startOffsetMs,_that.randomStart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  MapPlacedElementAnimationMode mode,  bool autoplay,  double speed,  double? startOffsetMs,  bool randomStart)  $default,) {final _that = this;
switch (_that) {
case _MapPlacedElementAnimation():
return $default(_that.enabled,_that.mode,_that.autoplay,_that.speed,_that.startOffsetMs,_that.randomStart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  MapPlacedElementAnimationMode mode,  bool autoplay,  double speed,  double? startOffsetMs,  bool randomStart)?  $default,) {final _that = this;
switch (_that) {
case _MapPlacedElementAnimation() when $default != null:
return $default(_that.enabled,_that.mode,_that.autoplay,_that.speed,_that.startOffsetMs,_that.randomStart);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapPlacedElementAnimation implements MapPlacedElementAnimation {
  const _MapPlacedElementAnimation({this.enabled = false, this.mode = MapPlacedElementAnimationMode.none, this.autoplay = true, this.speed = 1.0, this.startOffsetMs, this.randomStart = false});
  factory _MapPlacedElementAnimation.fromJson(Map<String, dynamic> json) => _$MapPlacedElementAnimationFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  MapPlacedElementAnimationMode mode;
@override@JsonKey() final  bool autoplay;
@override@JsonKey() final  double speed;
@override final  double? startOffsetMs;
@override@JsonKey() final  bool randomStart;

/// Create a copy of MapPlacedElementAnimation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapPlacedElementAnimationCopyWith<_MapPlacedElementAnimation> get copyWith => __$MapPlacedElementAnimationCopyWithImpl<_MapPlacedElementAnimation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapPlacedElementAnimationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapPlacedElementAnimation&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.autoplay, autoplay) || other.autoplay == autoplay)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.startOffsetMs, startOffsetMs) || other.startOffsetMs == startOffsetMs)&&(identical(other.randomStart, randomStart) || other.randomStart == randomStart));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,mode,autoplay,speed,startOffsetMs,randomStart);

@override
String toString() {
  return 'MapPlacedElementAnimation(enabled: $enabled, mode: $mode, autoplay: $autoplay, speed: $speed, startOffsetMs: $startOffsetMs, randomStart: $randomStart)';
}


}

/// @nodoc
abstract mixin class _$MapPlacedElementAnimationCopyWith<$Res> implements $MapPlacedElementAnimationCopyWith<$Res> {
  factory _$MapPlacedElementAnimationCopyWith(_MapPlacedElementAnimation value, $Res Function(_MapPlacedElementAnimation) _then) = __$MapPlacedElementAnimationCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, MapPlacedElementAnimationMode mode, bool autoplay, double speed, double? startOffsetMs, bool randomStart
});




}
/// @nodoc
class __$MapPlacedElementAnimationCopyWithImpl<$Res>
    implements _$MapPlacedElementAnimationCopyWith<$Res> {
  __$MapPlacedElementAnimationCopyWithImpl(this._self, this._then);

  final _MapPlacedElementAnimation _self;
  final $Res Function(_MapPlacedElementAnimation) _then;

/// Create a copy of MapPlacedElementAnimation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? mode = null,Object? autoplay = null,Object? speed = null,Object? startOffsetMs = freezed,Object? randomStart = null,}) {
  return _then(_MapPlacedElementAnimation(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MapPlacedElementAnimationMode,autoplay: null == autoplay ? _self.autoplay : autoplay // ignore: cast_nullable_to_non_nullable
as bool,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,startOffsetMs: freezed == startOffsetMs ? _self.startOffsetMs : startOffsetMs // ignore: cast_nullable_to_non_nullable
as double?,randomStart: null == randomStart ? _self.randomStart : randomStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MapEntity {

 String get id; String get name; MapEntityKind get kind; GridPos get pos; GridSize get size; MapEntityNpcData? get npc; MapEntitySignData? get sign; MapEntityItemData? get item; MapEntitySpawnData? get spawn; MapEntityEditorVisual? get editorVisual; bool get blocksMovement; Map<String, String> get properties;
/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntityCopyWith<MapEntity> get copyWith => _$MapEntityCopyWithImpl<MapEntity>(this as MapEntity, _$identity);

  /// Serializes this MapEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.size, size) || other.size == size)&&(identical(other.npc, npc) || other.npc == npc)&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.item, item) || other.item == item)&&(identical(other.spawn, spawn) || other.spawn == spawn)&&(identical(other.editorVisual, editorVisual) || other.editorVisual == editorVisual)&&(identical(other.blocksMovement, blocksMovement) || other.blocksMovement == blocksMovement)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,kind,pos,size,npc,sign,item,spawn,editorVisual,blocksMovement,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'MapEntity(id: $id, name: $name, kind: $kind, pos: $pos, size: $size, npc: $npc, sign: $sign, item: $item, spawn: $spawn, editorVisual: $editorVisual, blocksMovement: $blocksMovement, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $MapEntityCopyWith<$Res>  {
  factory $MapEntityCopyWith(MapEntity value, $Res Function(MapEntity) _then) = _$MapEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, MapEntityKind kind, GridPos pos, GridSize size, MapEntityNpcData? npc, MapEntitySignData? sign, MapEntityItemData? item, MapEntitySpawnData? spawn, MapEntityEditorVisual? editorVisual, bool blocksMovement, Map<String, String> properties
});


$GridPosCopyWith<$Res> get pos;$GridSizeCopyWith<$Res> get size;$MapEntityNpcDataCopyWith<$Res>? get npc;$MapEntitySignDataCopyWith<$Res>? get sign;$MapEntityItemDataCopyWith<$Res>? get item;$MapEntitySpawnDataCopyWith<$Res>? get spawn;$MapEntityEditorVisualCopyWith<$Res>? get editorVisual;

}
/// @nodoc
class _$MapEntityCopyWithImpl<$Res>
    implements $MapEntityCopyWith<$Res> {
  _$MapEntityCopyWithImpl(this._self, this._then);

  final MapEntity _self;
  final $Res Function(MapEntity) _then;

/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? pos = null,Object? size = null,Object? npc = freezed,Object? sign = freezed,Object? item = freezed,Object? spawn = freezed,Object? editorVisual = freezed,Object? blocksMovement = null,Object? properties = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MapEntityKind,pos: null == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as GridPos,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as GridSize,npc: freezed == npc ? _self.npc : npc // ignore: cast_nullable_to_non_nullable
as MapEntityNpcData?,sign: freezed == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as MapEntitySignData?,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as MapEntityItemData?,spawn: freezed == spawn ? _self.spawn : spawn // ignore: cast_nullable_to_non_nullable
as MapEntitySpawnData?,editorVisual: freezed == editorVisual ? _self.editorVisual : editorVisual // ignore: cast_nullable_to_non_nullable
as MapEntityEditorVisual?,blocksMovement: null == blocksMovement ? _self.blocksMovement : blocksMovement // ignore: cast_nullable_to_non_nullable
as bool,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get pos {

  return $GridPosCopyWith<$Res>(_self.pos, (value) {
    return _then(_self.copyWith(pos: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridSizeCopyWith<$Res> get size {

  return $GridSizeCopyWith<$Res>(_self.size, (value) {
    return _then(_self.copyWith(size: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityNpcDataCopyWith<$Res>? get npc {
    if (_self.npc == null) {
    return null;
  }

  return $MapEntityNpcDataCopyWith<$Res>(_self.npc!, (value) {
    return _then(_self.copyWith(npc: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntitySignDataCopyWith<$Res>? get sign {
    if (_self.sign == null) {
    return null;
  }

  return $MapEntitySignDataCopyWith<$Res>(_self.sign!, (value) {
    return _then(_self.copyWith(sign: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityItemDataCopyWith<$Res>? get item {
    if (_self.item == null) {
    return null;
  }

  return $MapEntityItemDataCopyWith<$Res>(_self.item!, (value) {
    return _then(_self.copyWith(item: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntitySpawnDataCopyWith<$Res>? get spawn {
    if (_self.spawn == null) {
    return null;
  }

  return $MapEntitySpawnDataCopyWith<$Res>(_self.spawn!, (value) {
    return _then(_self.copyWith(spawn: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityEditorVisualCopyWith<$Res>? get editorVisual {
    if (_self.editorVisual == null) {
    return null;
  }

  return $MapEntityEditorVisualCopyWith<$Res>(_self.editorVisual!, (value) {
    return _then(_self.copyWith(editorVisual: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapEntity].
extension MapEntityPatterns on MapEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntity value)  $default,){
final _that = this;
switch (_that) {
case _MapEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  MapEntityKind kind,  GridPos pos,  GridSize size,  MapEntityNpcData? npc,  MapEntitySignData? sign,  MapEntityItemData? item,  MapEntitySpawnData? spawn,  MapEntityEditorVisual? editorVisual,  bool blocksMovement,  Map<String, String> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntity() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.pos,_that.size,_that.npc,_that.sign,_that.item,_that.spawn,_that.editorVisual,_that.blocksMovement,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  MapEntityKind kind,  GridPos pos,  GridSize size,  MapEntityNpcData? npc,  MapEntitySignData? sign,  MapEntityItemData? item,  MapEntitySpawnData? spawn,  MapEntityEditorVisual? editorVisual,  bool blocksMovement,  Map<String, String> properties)  $default,) {final _that = this;
switch (_that) {
case _MapEntity():
return $default(_that.id,_that.name,_that.kind,_that.pos,_that.size,_that.npc,_that.sign,_that.item,_that.spawn,_that.editorVisual,_that.blocksMovement,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  MapEntityKind kind,  GridPos pos,  GridSize size,  MapEntityNpcData? npc,  MapEntitySignData? sign,  MapEntityItemData? item,  MapEntitySpawnData? spawn,  MapEntityEditorVisual? editorVisual,  bool blocksMovement,  Map<String, String> properties)?  $default,) {final _that = this;
switch (_that) {
case _MapEntity() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.pos,_that.size,_that.npc,_that.sign,_that.item,_that.spawn,_that.editorVisual,_that.blocksMovement,_that.properties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntity implements MapEntity {
  const _MapEntity({required this.id, this.name = '', required this.kind, required this.pos, this.size = const GridSize(width: 1, height: 1), this.npc, this.sign, this.item, this.spawn, this.editorVisual, this.blocksMovement = true, final  Map<String, String> properties = const {}}): _properties = properties;
  factory _MapEntity.fromJson(Map<String, dynamic> json) => _$MapEntityFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override final  MapEntityKind kind;
@override final  GridPos pos;
@override@JsonKey() final  GridSize size;
@override final  MapEntityNpcData? npc;
@override final  MapEntitySignData? sign;
@override final  MapEntityItemData? item;
@override final  MapEntitySpawnData? spawn;
@override final  MapEntityEditorVisual? editorVisual;
@override@JsonKey() final  bool blocksMovement;
 final  Map<String, String> _properties;
@override@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntityCopyWith<_MapEntity> get copyWith => __$MapEntityCopyWithImpl<_MapEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.size, size) || other.size == size)&&(identical(other.npc, npc) || other.npc == npc)&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.item, item) || other.item == item)&&(identical(other.spawn, spawn) || other.spawn == spawn)&&(identical(other.editorVisual, editorVisual) || other.editorVisual == editorVisual)&&(identical(other.blocksMovement, blocksMovement) || other.blocksMovement == blocksMovement)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,kind,pos,size,npc,sign,item,spawn,editorVisual,blocksMovement,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'MapEntity(id: $id, name: $name, kind: $kind, pos: $pos, size: $size, npc: $npc, sign: $sign, item: $item, spawn: $spawn, editorVisual: $editorVisual, blocksMovement: $blocksMovement, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$MapEntityCopyWith<$Res> implements $MapEntityCopyWith<$Res> {
  factory _$MapEntityCopyWith(_MapEntity value, $Res Function(_MapEntity) _then) = __$MapEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, MapEntityKind kind, GridPos pos, GridSize size, MapEntityNpcData? npc, MapEntitySignData? sign, MapEntityItemData? item, MapEntitySpawnData? spawn, MapEntityEditorVisual? editorVisual, bool blocksMovement, Map<String, String> properties
});


@override $GridPosCopyWith<$Res> get pos;@override $GridSizeCopyWith<$Res> get size;@override $MapEntityNpcDataCopyWith<$Res>? get npc;@override $MapEntitySignDataCopyWith<$Res>? get sign;@override $MapEntityItemDataCopyWith<$Res>? get item;@override $MapEntitySpawnDataCopyWith<$Res>? get spawn;@override $MapEntityEditorVisualCopyWith<$Res>? get editorVisual;

}
/// @nodoc
class __$MapEntityCopyWithImpl<$Res>
    implements _$MapEntityCopyWith<$Res> {
  __$MapEntityCopyWithImpl(this._self, this._then);

  final _MapEntity _self;
  final $Res Function(_MapEntity) _then;

/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? pos = null,Object? size = null,Object? npc = freezed,Object? sign = freezed,Object? item = freezed,Object? spawn = freezed,Object? editorVisual = freezed,Object? blocksMovement = null,Object? properties = null,}) {
  return _then(_MapEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MapEntityKind,pos: null == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as GridPos,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as GridSize,npc: freezed == npc ? _self.npc : npc // ignore: cast_nullable_to_non_nullable
as MapEntityNpcData?,sign: freezed == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as MapEntitySignData?,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as MapEntityItemData?,spawn: freezed == spawn ? _self.spawn : spawn // ignore: cast_nullable_to_non_nullable
as MapEntitySpawnData?,editorVisual: freezed == editorVisual ? _self.editorVisual : editorVisual // ignore: cast_nullable_to_non_nullable
as MapEntityEditorVisual?,blocksMovement: null == blocksMovement ? _self.blocksMovement : blocksMovement // ignore: cast_nullable_to_non_nullable
as bool,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get pos {

  return $GridPosCopyWith<$Res>(_self.pos, (value) {
    return _then(_self.copyWith(pos: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridSizeCopyWith<$Res> get size {

  return $GridSizeCopyWith<$Res>(_self.size, (value) {
    return _then(_self.copyWith(size: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityNpcDataCopyWith<$Res>? get npc {
    if (_self.npc == null) {
    return null;
  }

  return $MapEntityNpcDataCopyWith<$Res>(_self.npc!, (value) {
    return _then(_self.copyWith(npc: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntitySignDataCopyWith<$Res>? get sign {
    if (_self.sign == null) {
    return null;
  }

  return $MapEntitySignDataCopyWith<$Res>(_self.sign!, (value) {
    return _then(_self.copyWith(sign: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityItemDataCopyWith<$Res>? get item {
    if (_self.item == null) {
    return null;
  }

  return $MapEntityItemDataCopyWith<$Res>(_self.item!, (value) {
    return _then(_self.copyWith(item: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntitySpawnDataCopyWith<$Res>? get spawn {
    if (_self.spawn == null) {
    return null;
  }

  return $MapEntitySpawnDataCopyWith<$Res>(_self.spawn!, (value) {
    return _then(_self.copyWith(spawn: value));
  });
}/// Create a copy of MapEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityEditorVisualCopyWith<$Res>? get editorVisual {
    if (_self.editorVisual == null) {
    return null;
  }

  return $MapEntityEditorVisualCopyWith<$Res>(_self.editorVisual!, (value) {
    return _then(_self.copyWith(editorVisual: value));
  });
}
}


/// @nodoc
mixin _$MapWarp {

 String get id; GridPos get pos; String get targetMapId; GridPos get targetPos; MapWarpTriggerMode get triggerMode; List<EntityFacing> get allowedApproachFacings; WarpTriggerPadding get triggerPadding;
/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapWarpCopyWith<MapWarp> get copyWith => _$MapWarpCopyWithImpl<MapWarp>(this as MapWarp, _$identity);

  /// Serializes this MapWarp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapWarp&&(identical(other.id, id) || other.id == id)&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.targetMapId, targetMapId) || other.targetMapId == targetMapId)&&(identical(other.targetPos, targetPos) || other.targetPos == targetPos)&&(identical(other.triggerMode, triggerMode) || other.triggerMode == triggerMode)&&const DeepCollectionEquality().equals(other.allowedApproachFacings, allowedApproachFacings)&&(identical(other.triggerPadding, triggerPadding) || other.triggerPadding == triggerPadding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pos,targetMapId,targetPos,triggerMode,const DeepCollectionEquality().hash(allowedApproachFacings),triggerPadding);

@override
String toString() {
  return 'MapWarp(id: $id, pos: $pos, targetMapId: $targetMapId, targetPos: $targetPos, triggerMode: $triggerMode, allowedApproachFacings: $allowedApproachFacings, triggerPadding: $triggerPadding)';
}


}

/// @nodoc
abstract mixin class $MapWarpCopyWith<$Res>  {
  factory $MapWarpCopyWith(MapWarp value, $Res Function(MapWarp) _then) = _$MapWarpCopyWithImpl;
@useResult
$Res call({
 String id, GridPos pos, String targetMapId, GridPos targetPos, MapWarpTriggerMode triggerMode, List<EntityFacing> allowedApproachFacings, WarpTriggerPadding triggerPadding
});


$GridPosCopyWith<$Res> get pos;$GridPosCopyWith<$Res> get targetPos;$WarpTriggerPaddingCopyWith<$Res> get triggerPadding;

}
/// @nodoc
class _$MapWarpCopyWithImpl<$Res>
    implements $MapWarpCopyWith<$Res> {
  _$MapWarpCopyWithImpl(this._self, this._then);

  final MapWarp _self;
  final $Res Function(MapWarp) _then;

/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pos = null,Object? targetMapId = null,Object? targetPos = null,Object? triggerMode = null,Object? allowedApproachFacings = null,Object? triggerPadding = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pos: null == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as GridPos,targetMapId: null == targetMapId ? _self.targetMapId : targetMapId // ignore: cast_nullable_to_non_nullable
as String,targetPos: null == targetPos ? _self.targetPos : targetPos // ignore: cast_nullable_to_non_nullable
as GridPos,triggerMode: null == triggerMode ? _self.triggerMode : triggerMode // ignore: cast_nullable_to_non_nullable
as MapWarpTriggerMode,allowedApproachFacings: null == allowedApproachFacings ? _self.allowedApproachFacings : allowedApproachFacings // ignore: cast_nullable_to_non_nullable
as List<EntityFacing>,triggerPadding: null == triggerPadding ? _self.triggerPadding : triggerPadding // ignore: cast_nullable_to_non_nullable
as WarpTriggerPadding,
  ));
}
/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get pos {

  return $GridPosCopyWith<$Res>(_self.pos, (value) {
    return _then(_self.copyWith(pos: value));
  });
}/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get targetPos {

  return $GridPosCopyWith<$Res>(_self.targetPos, (value) {
    return _then(_self.copyWith(targetPos: value));
  });
}/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarpTriggerPaddingCopyWith<$Res> get triggerPadding {

  return $WarpTriggerPaddingCopyWith<$Res>(_self.triggerPadding, (value) {
    return _then(_self.copyWith(triggerPadding: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapWarp].
extension MapWarpPatterns on MapWarp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapWarp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapWarp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapWarp value)  $default,){
final _that = this;
switch (_that) {
case _MapWarp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapWarp value)?  $default,){
final _that = this;
switch (_that) {
case _MapWarp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GridPos pos,  String targetMapId,  GridPos targetPos,  MapWarpTriggerMode triggerMode,  List<EntityFacing> allowedApproachFacings,  WarpTriggerPadding triggerPadding)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapWarp() when $default != null:
return $default(_that.id,_that.pos,_that.targetMapId,_that.targetPos,_that.triggerMode,_that.allowedApproachFacings,_that.triggerPadding);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GridPos pos,  String targetMapId,  GridPos targetPos,  MapWarpTriggerMode triggerMode,  List<EntityFacing> allowedApproachFacings,  WarpTriggerPadding triggerPadding)  $default,) {final _that = this;
switch (_that) {
case _MapWarp():
return $default(_that.id,_that.pos,_that.targetMapId,_that.targetPos,_that.triggerMode,_that.allowedApproachFacings,_that.triggerPadding);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GridPos pos,  String targetMapId,  GridPos targetPos,  MapWarpTriggerMode triggerMode,  List<EntityFacing> allowedApproachFacings,  WarpTriggerPadding triggerPadding)?  $default,) {final _that = this;
switch (_that) {
case _MapWarp() when $default != null:
return $default(_that.id,_that.pos,_that.targetMapId,_that.targetPos,_that.triggerMode,_that.allowedApproachFacings,_that.triggerPadding);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapWarp implements MapWarp {
  const _MapWarp({required this.id, required this.pos, required this.targetMapId, required this.targetPos, this.triggerMode = MapWarpTriggerMode.onEnter, final  List<EntityFacing> allowedApproachFacings = const [], this.triggerPadding = const WarpTriggerPadding()}): _allowedApproachFacings = allowedApproachFacings;
  factory _MapWarp.fromJson(Map<String, dynamic> json) => _$MapWarpFromJson(json);

@override final  String id;
@override final  GridPos pos;
@override final  String targetMapId;
@override final  GridPos targetPos;
@override@JsonKey() final  MapWarpTriggerMode triggerMode;
 final  List<EntityFacing> _allowedApproachFacings;
@override@JsonKey() List<EntityFacing> get allowedApproachFacings {
  if (_allowedApproachFacings is EqualUnmodifiableListView) return _allowedApproachFacings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allowedApproachFacings);
}

@override@JsonKey() final  WarpTriggerPadding triggerPadding;

/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapWarpCopyWith<_MapWarp> get copyWith => __$MapWarpCopyWithImpl<_MapWarp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapWarpToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapWarp&&(identical(other.id, id) || other.id == id)&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.targetMapId, targetMapId) || other.targetMapId == targetMapId)&&(identical(other.targetPos, targetPos) || other.targetPos == targetPos)&&(identical(other.triggerMode, triggerMode) || other.triggerMode == triggerMode)&&const DeepCollectionEquality().equals(other._allowedApproachFacings, _allowedApproachFacings)&&(identical(other.triggerPadding, triggerPadding) || other.triggerPadding == triggerPadding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pos,targetMapId,targetPos,triggerMode,const DeepCollectionEquality().hash(_allowedApproachFacings),triggerPadding);

@override
String toString() {
  return 'MapWarp(id: $id, pos: $pos, targetMapId: $targetMapId, targetPos: $targetPos, triggerMode: $triggerMode, allowedApproachFacings: $allowedApproachFacings, triggerPadding: $triggerPadding)';
}


}

/// @nodoc
abstract mixin class _$MapWarpCopyWith<$Res> implements $MapWarpCopyWith<$Res> {
  factory _$MapWarpCopyWith(_MapWarp value, $Res Function(_MapWarp) _then) = __$MapWarpCopyWithImpl;
@override @useResult
$Res call({
 String id, GridPos pos, String targetMapId, GridPos targetPos, MapWarpTriggerMode triggerMode, List<EntityFacing> allowedApproachFacings, WarpTriggerPadding triggerPadding
});


@override $GridPosCopyWith<$Res> get pos;@override $GridPosCopyWith<$Res> get targetPos;@override $WarpTriggerPaddingCopyWith<$Res> get triggerPadding;

}
/// @nodoc
class __$MapWarpCopyWithImpl<$Res>
    implements _$MapWarpCopyWith<$Res> {
  __$MapWarpCopyWithImpl(this._self, this._then);

  final _MapWarp _self;
  final $Res Function(_MapWarp) _then;

/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pos = null,Object? targetMapId = null,Object? targetPos = null,Object? triggerMode = null,Object? allowedApproachFacings = null,Object? triggerPadding = null,}) {
  return _then(_MapWarp(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pos: null == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as GridPos,targetMapId: null == targetMapId ? _self.targetMapId : targetMapId // ignore: cast_nullable_to_non_nullable
as String,targetPos: null == targetPos ? _self.targetPos : targetPos // ignore: cast_nullable_to_non_nullable
as GridPos,triggerMode: null == triggerMode ? _self.triggerMode : triggerMode // ignore: cast_nullable_to_non_nullable
as MapWarpTriggerMode,allowedApproachFacings: null == allowedApproachFacings ? _self._allowedApproachFacings : allowedApproachFacings // ignore: cast_nullable_to_non_nullable
as List<EntityFacing>,triggerPadding: null == triggerPadding ? _self.triggerPadding : triggerPadding // ignore: cast_nullable_to_non_nullable
as WarpTriggerPadding,
  ));
}

/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get pos {

  return $GridPosCopyWith<$Res>(_self.pos, (value) {
    return _then(_self.copyWith(pos: value));
  });
}/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get targetPos {

  return $GridPosCopyWith<$Res>(_self.targetPos, (value) {
    return _then(_self.copyWith(targetPos: value));
  });
}/// Create a copy of MapWarp
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarpTriggerPaddingCopyWith<$Res> get triggerPadding {

  return $WarpTriggerPaddingCopyWith<$Res>(_self.triggerPadding, (value) {
    return _then(_self.copyWith(triggerPadding: value));
  });
}
}


/// @nodoc
mixin _$WarpTriggerPadding {

 int get top; int get right; int get bottom; int get left;
/// Create a copy of WarpTriggerPadding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarpTriggerPaddingCopyWith<WarpTriggerPadding> get copyWith => _$WarpTriggerPaddingCopyWithImpl<WarpTriggerPadding>(this as WarpTriggerPadding, _$identity);

  /// Serializes this WarpTriggerPadding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarpTriggerPadding&&(identical(other.top, top) || other.top == top)&&(identical(other.right, right) || other.right == right)&&(identical(other.bottom, bottom) || other.bottom == bottom)&&(identical(other.left, left) || other.left == left));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,top,right,bottom,left);

@override
String toString() {
  return 'WarpTriggerPadding(top: $top, right: $right, bottom: $bottom, left: $left)';
}


}

/// @nodoc
abstract mixin class $WarpTriggerPaddingCopyWith<$Res>  {
  factory $WarpTriggerPaddingCopyWith(WarpTriggerPadding value, $Res Function(WarpTriggerPadding) _then) = _$WarpTriggerPaddingCopyWithImpl;
@useResult
$Res call({
 int top, int right, int bottom, int left
});




}
/// @nodoc
class _$WarpTriggerPaddingCopyWithImpl<$Res>
    implements $WarpTriggerPaddingCopyWith<$Res> {
  _$WarpTriggerPaddingCopyWithImpl(this._self, this._then);

  final WarpTriggerPadding _self;
  final $Res Function(WarpTriggerPadding) _then;

/// Create a copy of WarpTriggerPadding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? top = null,Object? right = null,Object? bottom = null,Object? left = null,}) {
  return _then(_self.copyWith(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as int,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as int,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as int,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WarpTriggerPadding].
extension WarpTriggerPaddingPatterns on WarpTriggerPadding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarpTriggerPadding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarpTriggerPadding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarpTriggerPadding value)  $default,){
final _that = this;
switch (_that) {
case _WarpTriggerPadding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarpTriggerPadding value)?  $default,){
final _that = this;
switch (_that) {
case _WarpTriggerPadding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int top,  int right,  int bottom,  int left)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarpTriggerPadding() when $default != null:
return $default(_that.top,_that.right,_that.bottom,_that.left);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int top,  int right,  int bottom,  int left)  $default,) {final _that = this;
switch (_that) {
case _WarpTriggerPadding():
return $default(_that.top,_that.right,_that.bottom,_that.left);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int top,  int right,  int bottom,  int left)?  $default,) {final _that = this;
switch (_that) {
case _WarpTriggerPadding() when $default != null:
return $default(_that.top,_that.right,_that.bottom,_that.left);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _WarpTriggerPadding implements WarpTriggerPadding {
  const _WarpTriggerPadding({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});
  factory _WarpTriggerPadding.fromJson(Map<String, dynamic> json) => _$WarpTriggerPaddingFromJson(json);

@override@JsonKey() final  int top;
@override@JsonKey() final  int right;
@override@JsonKey() final  int bottom;
@override@JsonKey() final  int left;

/// Create a copy of WarpTriggerPadding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarpTriggerPaddingCopyWith<_WarpTriggerPadding> get copyWith => __$WarpTriggerPaddingCopyWithImpl<_WarpTriggerPadding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarpTriggerPaddingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarpTriggerPadding&&(identical(other.top, top) || other.top == top)&&(identical(other.right, right) || other.right == right)&&(identical(other.bottom, bottom) || other.bottom == bottom)&&(identical(other.left, left) || other.left == left));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,top,right,bottom,left);

@override
String toString() {
  return 'WarpTriggerPadding(top: $top, right: $right, bottom: $bottom, left: $left)';
}


}

/// @nodoc
abstract mixin class _$WarpTriggerPaddingCopyWith<$Res> implements $WarpTriggerPaddingCopyWith<$Res> {
  factory _$WarpTriggerPaddingCopyWith(_WarpTriggerPadding value, $Res Function(_WarpTriggerPadding) _then) = __$WarpTriggerPaddingCopyWithImpl;
@override @useResult
$Res call({
 int top, int right, int bottom, int left
});




}
/// @nodoc
class __$WarpTriggerPaddingCopyWithImpl<$Res>
    implements _$WarpTriggerPaddingCopyWith<$Res> {
  __$WarpTriggerPaddingCopyWithImpl(this._self, this._then);

  final _WarpTriggerPadding _self;
  final $Res Function(_WarpTriggerPadding) _then;

/// Create a copy of WarpTriggerPadding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? top = null,Object? right = null,Object? bottom = null,Object? left = null,}) {
  return _then(_WarpTriggerPadding(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as int,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as int,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as int,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MapConnection {

 MapConnectionDirection get direction; String get targetMapId; int get offset;
/// Create a copy of MapConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapConnectionCopyWith<MapConnection> get copyWith => _$MapConnectionCopyWithImpl<MapConnection>(this as MapConnection, _$identity);

  /// Serializes this MapConnection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapConnection&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.targetMapId, targetMapId) || other.targetMapId == targetMapId)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,direction,targetMapId,offset);

@override
String toString() {
  return 'MapConnection(direction: $direction, targetMapId: $targetMapId, offset: $offset)';
}


}

/// @nodoc
abstract mixin class $MapConnectionCopyWith<$Res>  {
  factory $MapConnectionCopyWith(MapConnection value, $Res Function(MapConnection) _then) = _$MapConnectionCopyWithImpl;
@useResult
$Res call({
 MapConnectionDirection direction, String targetMapId, int offset
});




}
/// @nodoc
class _$MapConnectionCopyWithImpl<$Res>
    implements $MapConnectionCopyWith<$Res> {
  _$MapConnectionCopyWithImpl(this._self, this._then);

  final MapConnection _self;
  final $Res Function(MapConnection) _then;

/// Create a copy of MapConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = null,Object? targetMapId = null,Object? offset = null,}) {
  return _then(_self.copyWith(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as MapConnectionDirection,targetMapId: null == targetMapId ? _self.targetMapId : targetMapId // ignore: cast_nullable_to_non_nullable
as String,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MapConnection].
extension MapConnectionPatterns on MapConnection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapConnection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapConnection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapConnection value)  $default,){
final _that = this;
switch (_that) {
case _MapConnection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapConnection value)?  $default,){
final _that = this;
switch (_that) {
case _MapConnection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MapConnectionDirection direction,  String targetMapId,  int offset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapConnection() when $default != null:
return $default(_that.direction,_that.targetMapId,_that.offset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MapConnectionDirection direction,  String targetMapId,  int offset)  $default,) {final _that = this;
switch (_that) {
case _MapConnection():
return $default(_that.direction,_that.targetMapId,_that.offset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MapConnectionDirection direction,  String targetMapId,  int offset)?  $default,) {final _that = this;
switch (_that) {
case _MapConnection() when $default != null:
return $default(_that.direction,_that.targetMapId,_that.offset);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapConnection implements MapConnection {
  const _MapConnection({required this.direction, required this.targetMapId, this.offset = 0});
  factory _MapConnection.fromJson(Map<String, dynamic> json) => _$MapConnectionFromJson(json);

@override final  MapConnectionDirection direction;
@override final  String targetMapId;
@override@JsonKey() final  int offset;

/// Create a copy of MapConnection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapConnectionCopyWith<_MapConnection> get copyWith => __$MapConnectionCopyWithImpl<_MapConnection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapConnectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapConnection&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.targetMapId, targetMapId) || other.targetMapId == targetMapId)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,direction,targetMapId,offset);

@override
String toString() {
  return 'MapConnection(direction: $direction, targetMapId: $targetMapId, offset: $offset)';
}


}

/// @nodoc
abstract mixin class _$MapConnectionCopyWith<$Res> implements $MapConnectionCopyWith<$Res> {
  factory _$MapConnectionCopyWith(_MapConnection value, $Res Function(_MapConnection) _then) = __$MapConnectionCopyWithImpl;
@override @useResult
$Res call({
 MapConnectionDirection direction, String targetMapId, int offset
});




}
/// @nodoc
class __$MapConnectionCopyWithImpl<$Res>
    implements _$MapConnectionCopyWith<$Res> {
  __$MapConnectionCopyWithImpl(this._self, this._then);

  final _MapConnection _self;
  final $Res Function(_MapConnection) _then;

/// Create a copy of MapConnection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = null,Object? targetMapId = null,Object? offset = null,}) {
  return _then(_MapConnection(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as MapConnectionDirection,targetMapId: null == targetMapId ? _self.targetMapId : targetMapId // ignore: cast_nullable_to_non_nullable
as String,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MapTrigger {

 String get id; String get name; TriggerType get type; MapRect get area; Map<String, String> get properties;
/// Create a copy of MapTrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapTriggerCopyWith<MapTrigger> get copyWith => _$MapTriggerCopyWithImpl<MapTrigger>(this as MapTrigger, _$identity);

  /// Serializes this MapTrigger to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapTrigger&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.area, area) || other.area == area)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,area,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'MapTrigger(id: $id, name: $name, type: $type, area: $area, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $MapTriggerCopyWith<$Res>  {
  factory $MapTriggerCopyWith(MapTrigger value, $Res Function(MapTrigger) _then) = _$MapTriggerCopyWithImpl;
@useResult
$Res call({
 String id, String name, TriggerType type, MapRect area, Map<String, String> properties
});


$MapRectCopyWith<$Res> get area;

}
/// @nodoc
class _$MapTriggerCopyWithImpl<$Res>
    implements $MapTriggerCopyWith<$Res> {
  _$MapTriggerCopyWithImpl(this._self, this._then);

  final MapTrigger _self;
  final $Res Function(MapTrigger) _then;

/// Create a copy of MapTrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? area = null,Object? properties = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TriggerType,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as MapRect,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of MapTrigger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRectCopyWith<$Res> get area {

  return $MapRectCopyWith<$Res>(_self.area, (value) {
    return _then(_self.copyWith(area: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapTrigger].
extension MapTriggerPatterns on MapTrigger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapTrigger value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapTrigger() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapTrigger value)  $default,){
final _that = this;
switch (_that) {
case _MapTrigger():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapTrigger value)?  $default,){
final _that = this;
switch (_that) {
case _MapTrigger() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  TriggerType type,  MapRect area,  Map<String, String> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapTrigger() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.area,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  TriggerType type,  MapRect area,  Map<String, String> properties)  $default,) {final _that = this;
switch (_that) {
case _MapTrigger():
return $default(_that.id,_that.name,_that.type,_that.area,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  TriggerType type,  MapRect area,  Map<String, String> properties)?  $default,) {final _that = this;
switch (_that) {
case _MapTrigger() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.area,_that.properties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapTrigger implements MapTrigger {
  const _MapTrigger({required this.id, this.name = '', required this.type, required this.area, final  Map<String, String> properties = const {}}): _properties = properties;
  factory _MapTrigger.fromJson(Map<String, dynamic> json) => _$MapTriggerFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override final  TriggerType type;
@override final  MapRect area;
 final  Map<String, String> _properties;
@override@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of MapTrigger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapTriggerCopyWith<_MapTrigger> get copyWith => __$MapTriggerCopyWithImpl<_MapTrigger>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapTriggerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapTrigger&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.area, area) || other.area == area)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,area,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'MapTrigger(id: $id, name: $name, type: $type, area: $area, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$MapTriggerCopyWith<$Res> implements $MapTriggerCopyWith<$Res> {
  factory _$MapTriggerCopyWith(_MapTrigger value, $Res Function(_MapTrigger) _then) = __$MapTriggerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, TriggerType type, MapRect area, Map<String, String> properties
});


@override $MapRectCopyWith<$Res> get area;

}
/// @nodoc
class __$MapTriggerCopyWithImpl<$Res>
    implements _$MapTriggerCopyWith<$Res> {
  __$MapTriggerCopyWithImpl(this._self, this._then);

  final _MapTrigger _self;
  final $Res Function(_MapTrigger) _then;

/// Create a copy of MapTrigger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? area = null,Object? properties = null,}) {
  return _then(_MapTrigger(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TriggerType,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as MapRect,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of MapTrigger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRectCopyWith<$Res> get area {

  return $MapRectCopyWith<$Res>(_self.area, (value) {
    return _then(_self.copyWith(area: value));
  });
}
}

// dart format on
