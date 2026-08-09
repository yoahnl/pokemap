// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tileset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TilesetConfig {

 String get id; String get name; String get relativePath;// path to the image asset
 int get tileSize; List<TileProperties> get tileProperties; Map<String, dynamic> get customProperties;
/// Create a copy of TilesetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TilesetConfigCopyWith<TilesetConfig> get copyWith => _$TilesetConfigCopyWithImpl<TilesetConfig>(this as TilesetConfig, _$identity);

  /// Serializes this TilesetConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TilesetConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.tileSize, tileSize) || other.tileSize == tileSize)&&const DeepCollectionEquality().equals(other.tileProperties, tileProperties)&&const DeepCollectionEquality().equals(other.customProperties, customProperties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,relativePath,tileSize,const DeepCollectionEquality().hash(tileProperties),const DeepCollectionEquality().hash(customProperties));

@override
String toString() {
  return 'TilesetConfig(id: $id, name: $name, relativePath: $relativePath, tileSize: $tileSize, tileProperties: $tileProperties, customProperties: $customProperties)';
}


}

/// @nodoc
abstract mixin class $TilesetConfigCopyWith<$Res>  {
  factory $TilesetConfigCopyWith(TilesetConfig value, $Res Function(TilesetConfig) _then) = _$TilesetConfigCopyWithImpl;
@useResult
$Res call({
 String id, String name, String relativePath, int tileSize, List<TileProperties> tileProperties, Map<String, dynamic> customProperties
});




}
/// @nodoc
class _$TilesetConfigCopyWithImpl<$Res>
    implements $TilesetConfigCopyWith<$Res> {
  _$TilesetConfigCopyWithImpl(this._self, this._then);

  final TilesetConfig _self;
  final $Res Function(TilesetConfig) _then;

/// Create a copy of TilesetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? relativePath = null,Object? tileSize = null,Object? tileProperties = null,Object? customProperties = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,tileSize: null == tileSize ? _self.tileSize : tileSize // ignore: cast_nullable_to_non_nullable
as int,tileProperties: null == tileProperties ? _self.tileProperties : tileProperties // ignore: cast_nullable_to_non_nullable
as List<TileProperties>,customProperties: null == customProperties ? _self.customProperties : customProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [TilesetConfig].
extension TilesetConfigPatterns on TilesetConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TilesetConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TilesetConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TilesetConfig value)  $default,){
final _that = this;
switch (_that) {
case _TilesetConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TilesetConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TilesetConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String relativePath,  int tileSize,  List<TileProperties> tileProperties,  Map<String, dynamic> customProperties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TilesetConfig() when $default != null:
return $default(_that.id,_that.name,_that.relativePath,_that.tileSize,_that.tileProperties,_that.customProperties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String relativePath,  int tileSize,  List<TileProperties> tileProperties,  Map<String, dynamic> customProperties)  $default,) {final _that = this;
switch (_that) {
case _TilesetConfig():
return $default(_that.id,_that.name,_that.relativePath,_that.tileSize,_that.tileProperties,_that.customProperties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String relativePath,  int tileSize,  List<TileProperties> tileProperties,  Map<String, dynamic> customProperties)?  $default,) {final _that = this;
switch (_that) {
case _TilesetConfig() when $default != null:
return $default(_that.id,_that.name,_that.relativePath,_that.tileSize,_that.tileProperties,_that.customProperties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _TilesetConfig implements TilesetConfig {
  const _TilesetConfig({required this.id, required this.name, required this.relativePath, this.tileSize = 32, final  List<TileProperties> tileProperties = const [], final  Map<String, dynamic> customProperties = const {}}): _tileProperties = tileProperties,_customProperties = customProperties;
  factory _TilesetConfig.fromJson(Map<String, dynamic> json) => _$TilesetConfigFromJson(json);

@override final  String id;
@override final  String name;
@override final  String relativePath;
// path to the image asset
@override@JsonKey() final  int tileSize;
 final  List<TileProperties> _tileProperties;
@override@JsonKey() List<TileProperties> get tileProperties {
  if (_tileProperties is EqualUnmodifiableListView) return _tileProperties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tileProperties);
}

 final  Map<String, dynamic> _customProperties;
@override@JsonKey() Map<String, dynamic> get customProperties {
  if (_customProperties is EqualUnmodifiableMapView) return _customProperties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customProperties);
}


/// Create a copy of TilesetConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TilesetConfigCopyWith<_TilesetConfig> get copyWith => __$TilesetConfigCopyWithImpl<_TilesetConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TilesetConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TilesetConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.tileSize, tileSize) || other.tileSize == tileSize)&&const DeepCollectionEquality().equals(other._tileProperties, _tileProperties)&&const DeepCollectionEquality().equals(other._customProperties, _customProperties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,relativePath,tileSize,const DeepCollectionEquality().hash(_tileProperties),const DeepCollectionEquality().hash(_customProperties));

@override
String toString() {
  return 'TilesetConfig(id: $id, name: $name, relativePath: $relativePath, tileSize: $tileSize, tileProperties: $tileProperties, customProperties: $customProperties)';
}


}

/// @nodoc
abstract mixin class _$TilesetConfigCopyWith<$Res> implements $TilesetConfigCopyWith<$Res> {
  factory _$TilesetConfigCopyWith(_TilesetConfig value, $Res Function(_TilesetConfig) _then) = __$TilesetConfigCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String relativePath, int tileSize, List<TileProperties> tileProperties, Map<String, dynamic> customProperties
});




}
/// @nodoc
class __$TilesetConfigCopyWithImpl<$Res>
    implements _$TilesetConfigCopyWith<$Res> {
  __$TilesetConfigCopyWithImpl(this._self, this._then);

  final _TilesetConfig _self;
  final $Res Function(_TilesetConfig) _then;

/// Create a copy of TilesetConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? relativePath = null,Object? tileSize = null,Object? tileProperties = null,Object? customProperties = null,}) {
  return _then(_TilesetConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,tileSize: null == tileSize ? _self.tileSize : tileSize // ignore: cast_nullable_to_non_nullable
as int,tileProperties: null == tileProperties ? _self._tileProperties : tileProperties // ignore: cast_nullable_to_non_nullable
as List<TileProperties>,customProperties: null == customProperties ? _self._customProperties : customProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$TileProperties {

 int get tileId; bool get isPassable; Map<String, dynamic> get properties;
/// Create a copy of TileProperties
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TilePropertiesCopyWith<TileProperties> get copyWith => _$TilePropertiesCopyWithImpl<TileProperties>(this as TileProperties, _$identity);

  /// Serializes this TileProperties to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TileProperties&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.isPassable, isPassable) || other.isPassable == isPassable)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,isPassable,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'TileProperties(tileId: $tileId, isPassable: $isPassable, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $TilePropertiesCopyWith<$Res>  {
  factory $TilePropertiesCopyWith(TileProperties value, $Res Function(TileProperties) _then) = _$TilePropertiesCopyWithImpl;
@useResult
$Res call({
 int tileId, bool isPassable, Map<String, dynamic> properties
});




}
/// @nodoc
class _$TilePropertiesCopyWithImpl<$Res>
    implements $TilePropertiesCopyWith<$Res> {
  _$TilePropertiesCopyWithImpl(this._self, this._then);

  final TileProperties _self;
  final $Res Function(TileProperties) _then;

/// Create a copy of TileProperties
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tileId = null,Object? isPassable = null,Object? properties = null,}) {
  return _then(_self.copyWith(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,isPassable: null == isPassable ? _self.isPassable : isPassable // ignore: cast_nullable_to_non_nullable
as bool,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [TileProperties].
extension TilePropertiesPatterns on TileProperties {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TileProperties value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TileProperties() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TileProperties value)  $default,){
final _that = this;
switch (_that) {
case _TileProperties():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TileProperties value)?  $default,){
final _that = this;
switch (_that) {
case _TileProperties() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tileId,  bool isPassable,  Map<String, dynamic> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TileProperties() when $default != null:
return $default(_that.tileId,_that.isPassable,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tileId,  bool isPassable,  Map<String, dynamic> properties)  $default,) {final _that = this;
switch (_that) {
case _TileProperties():
return $default(_that.tileId,_that.isPassable,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tileId,  bool isPassable,  Map<String, dynamic> properties)?  $default,) {final _that = this;
switch (_that) {
case _TileProperties() when $default != null:
return $default(_that.tileId,_that.isPassable,_that.properties);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TileProperties implements TileProperties {
  const _TileProperties({required this.tileId, this.isPassable = true, final  Map<String, dynamic> properties = const {}}): _properties = properties;
  factory _TileProperties.fromJson(Map<String, dynamic> json) => _$TilePropertiesFromJson(json);

@override final  int tileId;
@override@JsonKey() final  bool isPassable;
 final  Map<String, dynamic> _properties;
@override@JsonKey() Map<String, dynamic> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of TileProperties
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TilePropertiesCopyWith<_TileProperties> get copyWith => __$TilePropertiesCopyWithImpl<_TileProperties>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TilePropertiesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TileProperties&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.isPassable, isPassable) || other.isPassable == isPassable)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,isPassable,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'TileProperties(tileId: $tileId, isPassable: $isPassable, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$TilePropertiesCopyWith<$Res> implements $TilePropertiesCopyWith<$Res> {
  factory _$TilePropertiesCopyWith(_TileProperties value, $Res Function(_TileProperties) _then) = __$TilePropertiesCopyWithImpl;
@override @useResult
$Res call({
 int tileId, bool isPassable, Map<String, dynamic> properties
});




}
/// @nodoc
class __$TilePropertiesCopyWithImpl<$Res>
    implements _$TilePropertiesCopyWith<$Res> {
  __$TilePropertiesCopyWithImpl(this._self, this._then);

  final _TileProperties _self;
  final $Res Function(_TileProperties) _then;

/// Create a copy of TileProperties
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tileId = null,Object? isPassable = null,Object? properties = null,}) {
  return _then(_TileProperties(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,isPassable: null == isPassable ? _self.isPassable : isPassable // ignore: cast_nullable_to_non_nullable
as bool,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
