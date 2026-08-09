// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MapMetadata {

 String get displayName; MapType get mapType; String? get musicId; MapWeather get weather; bool get isIndoor; bool get allowEscapeRope; String? get defaultSpawnId; List<String> get tags;
/// Create a copy of MapMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapMetadataCopyWith<MapMetadata> get copyWith => _$MapMetadataCopyWithImpl<MapMetadata>(this as MapMetadata, _$identity);

  /// Serializes this MapMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapMetadata&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mapType, mapType) || other.mapType == mapType)&&(identical(other.musicId, musicId) || other.musicId == musicId)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.isIndoor, isIndoor) || other.isIndoor == isIndoor)&&(identical(other.allowEscapeRope, allowEscapeRope) || other.allowEscapeRope == allowEscapeRope)&&(identical(other.defaultSpawnId, defaultSpawnId) || other.defaultSpawnId == defaultSpawnId)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,mapType,musicId,weather,isIndoor,allowEscapeRope,defaultSpawnId,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'MapMetadata(displayName: $displayName, mapType: $mapType, musicId: $musicId, weather: $weather, isIndoor: $isIndoor, allowEscapeRope: $allowEscapeRope, defaultSpawnId: $defaultSpawnId, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $MapMetadataCopyWith<$Res>  {
  factory $MapMetadataCopyWith(MapMetadata value, $Res Function(MapMetadata) _then) = _$MapMetadataCopyWithImpl;
@useResult
$Res call({
 String displayName, MapType mapType, String? musicId, MapWeather weather, bool isIndoor, bool allowEscapeRope, String? defaultSpawnId, List<String> tags
});




}
/// @nodoc
class _$MapMetadataCopyWithImpl<$Res>
    implements $MapMetadataCopyWith<$Res> {
  _$MapMetadataCopyWithImpl(this._self, this._then);

  final MapMetadata _self;
  final $Res Function(MapMetadata) _then;

/// Create a copy of MapMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? mapType = null,Object? musicId = freezed,Object? weather = null,Object? isIndoor = null,Object? allowEscapeRope = null,Object? defaultSpawnId = freezed,Object? tags = null,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mapType: null == mapType ? _self.mapType : mapType // ignore: cast_nullable_to_non_nullable
as MapType,musicId: freezed == musicId ? _self.musicId : musicId // ignore: cast_nullable_to_non_nullable
as String?,weather: null == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as MapWeather,isIndoor: null == isIndoor ? _self.isIndoor : isIndoor // ignore: cast_nullable_to_non_nullable
as bool,allowEscapeRope: null == allowEscapeRope ? _self.allowEscapeRope : allowEscapeRope // ignore: cast_nullable_to_non_nullable
as bool,defaultSpawnId: freezed == defaultSpawnId ? _self.defaultSpawnId : defaultSpawnId // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MapMetadata].
extension MapMetadataPatterns on MapMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapMetadata value)  $default,){
final _that = this;
switch (_that) {
case _MapMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _MapMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  MapType mapType,  String? musicId,  MapWeather weather,  bool isIndoor,  bool allowEscapeRope,  String? defaultSpawnId,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapMetadata() when $default != null:
return $default(_that.displayName,_that.mapType,_that.musicId,_that.weather,_that.isIndoor,_that.allowEscapeRope,_that.defaultSpawnId,_that.tags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  MapType mapType,  String? musicId,  MapWeather weather,  bool isIndoor,  bool allowEscapeRope,  String? defaultSpawnId,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _MapMetadata():
return $default(_that.displayName,_that.mapType,_that.musicId,_that.weather,_that.isIndoor,_that.allowEscapeRope,_that.defaultSpawnId,_that.tags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  MapType mapType,  String? musicId,  MapWeather weather,  bool isIndoor,  bool allowEscapeRope,  String? defaultSpawnId,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _MapMetadata() when $default != null:
return $default(_that.displayName,_that.mapType,_that.musicId,_that.weather,_that.isIndoor,_that.allowEscapeRope,_that.defaultSpawnId,_that.tags);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapMetadata implements MapMetadata {
  const _MapMetadata({this.displayName = '', this.mapType = MapType.route, this.musicId, this.weather = MapWeather.none, this.isIndoor = false, this.allowEscapeRope = true, this.defaultSpawnId, final  List<String> tags = const []}): _tags = tags;
  factory _MapMetadata.fromJson(Map<String, dynamic> json) => _$MapMetadataFromJson(json);

@override@JsonKey() final  String displayName;
@override@JsonKey() final  MapType mapType;
@override final  String? musicId;
@override@JsonKey() final  MapWeather weather;
@override@JsonKey() final  bool isIndoor;
@override@JsonKey() final  bool allowEscapeRope;
@override final  String? defaultSpawnId;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of MapMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapMetadataCopyWith<_MapMetadata> get copyWith => __$MapMetadataCopyWithImpl<_MapMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapMetadata&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mapType, mapType) || other.mapType == mapType)&&(identical(other.musicId, musicId) || other.musicId == musicId)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.isIndoor, isIndoor) || other.isIndoor == isIndoor)&&(identical(other.allowEscapeRope, allowEscapeRope) || other.allowEscapeRope == allowEscapeRope)&&(identical(other.defaultSpawnId, defaultSpawnId) || other.defaultSpawnId == defaultSpawnId)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,mapType,musicId,weather,isIndoor,allowEscapeRope,defaultSpawnId,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'MapMetadata(displayName: $displayName, mapType: $mapType, musicId: $musicId, weather: $weather, isIndoor: $isIndoor, allowEscapeRope: $allowEscapeRope, defaultSpawnId: $defaultSpawnId, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$MapMetadataCopyWith<$Res> implements $MapMetadataCopyWith<$Res> {
  factory _$MapMetadataCopyWith(_MapMetadata value, $Res Function(_MapMetadata) _then) = __$MapMetadataCopyWithImpl;
@override @useResult
$Res call({
 String displayName, MapType mapType, String? musicId, MapWeather weather, bool isIndoor, bool allowEscapeRope, String? defaultSpawnId, List<String> tags
});




}
/// @nodoc
class __$MapMetadataCopyWithImpl<$Res>
    implements _$MapMetadataCopyWith<$Res> {
  __$MapMetadataCopyWithImpl(this._self, this._then);

  final _MapMetadata _self;
  final $Res Function(_MapMetadata) _then;

/// Create a copy of MapMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? mapType = null,Object? musicId = freezed,Object? weather = null,Object? isIndoor = null,Object? allowEscapeRope = null,Object? defaultSpawnId = freezed,Object? tags = null,}) {
  return _then(_MapMetadata(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mapType: null == mapType ? _self.mapType : mapType // ignore: cast_nullable_to_non_nullable
as MapType,musicId: freezed == musicId ? _self.musicId : musicId // ignore: cast_nullable_to_non_nullable
as String?,weather: null == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as MapWeather,isIndoor: null == isIndoor ? _self.isIndoor : isIndoor // ignore: cast_nullable_to_non_nullable
as bool,allowEscapeRope: null == allowEscapeRope ? _self.allowEscapeRope : allowEscapeRope // ignore: cast_nullable_to_non_nullable
as bool,defaultSpawnId: freezed == defaultSpawnId ? _self.defaultSpawnId : defaultSpawnId // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
