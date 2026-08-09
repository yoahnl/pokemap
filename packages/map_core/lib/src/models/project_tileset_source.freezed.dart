// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_tileset_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VisualTileProperty {

 int get tileId; bool get passable; List<String> get tags;
/// Create a copy of VisualTileProperty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisualTilePropertyCopyWith<VisualTileProperty> get copyWith => _$VisualTilePropertyCopyWithImpl<VisualTileProperty>(this as VisualTileProperty, _$identity);

  /// Serializes this VisualTileProperty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisualTileProperty&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.passable, passable) || other.passable == passable)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,passable,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'VisualTileProperty(tileId: $tileId, passable: $passable, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $VisualTilePropertyCopyWith<$Res>  {
  factory $VisualTilePropertyCopyWith(VisualTileProperty value, $Res Function(VisualTileProperty) _then) = _$VisualTilePropertyCopyWithImpl;
@useResult
$Res call({
 int tileId, bool passable, List<String> tags
});




}
/// @nodoc
class _$VisualTilePropertyCopyWithImpl<$Res>
    implements $VisualTilePropertyCopyWith<$Res> {
  _$VisualTilePropertyCopyWithImpl(this._self, this._then);

  final VisualTileProperty _self;
  final $Res Function(VisualTileProperty) _then;

/// Create a copy of VisualTileProperty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tileId = null,Object? passable = null,Object? tags = null,}) {
  return _then(_self.copyWith(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,passable: null == passable ? _self.passable : passable // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [VisualTileProperty].
extension VisualTilePropertyPatterns on VisualTileProperty {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisualTileProperty value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisualTileProperty() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisualTileProperty value)  $default,){
final _that = this;
switch (_that) {
case _VisualTileProperty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisualTileProperty value)?  $default,){
final _that = this;
switch (_that) {
case _VisualTileProperty() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tileId,  bool passable,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisualTileProperty() when $default != null:
return $default(_that.tileId,_that.passable,_that.tags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tileId,  bool passable,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _VisualTileProperty():
return $default(_that.tileId,_that.passable,_that.tags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tileId,  bool passable,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _VisualTileProperty() when $default != null:
return $default(_that.tileId,_that.passable,_that.tags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisualTileProperty implements VisualTileProperty {
  const _VisualTileProperty({required this.tileId, this.passable = true, final  List<String> tags = const <String>[]}): _tags = tags;
  factory _VisualTileProperty.fromJson(Map<String, dynamic> json) => _$VisualTilePropertyFromJson(json);

@override final  int tileId;
@override@JsonKey() final  bool passable;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of VisualTileProperty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisualTilePropertyCopyWith<_VisualTileProperty> get copyWith => __$VisualTilePropertyCopyWithImpl<_VisualTileProperty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisualTilePropertyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisualTileProperty&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.passable, passable) || other.passable == passable)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,passable,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'VisualTileProperty(tileId: $tileId, passable: $passable, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$VisualTilePropertyCopyWith<$Res> implements $VisualTilePropertyCopyWith<$Res> {
  factory _$VisualTilePropertyCopyWith(_VisualTileProperty value, $Res Function(_VisualTileProperty) _then) = __$VisualTilePropertyCopyWithImpl;
@override @useResult
$Res call({
 int tileId, bool passable, List<String> tags
});




}
/// @nodoc
class __$VisualTilePropertyCopyWithImpl<$Res>
    implements _$VisualTilePropertyCopyWith<$Res> {
  __$VisualTilePropertyCopyWithImpl(this._self, this._then);

  final _VisualTileProperty _self;
  final $Res Function(_VisualTileProperty) _then;

/// Create a copy of VisualTileProperty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tileId = null,Object? passable = null,Object? tags = null,}) {
  return _then(_VisualTileProperty(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,passable: null == passable ? _self.passable : passable // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ProjectTilesetProperty {

 String get name; ProjectTilesetPropertyType get type; Object? get value;@JsonKey(includeIfNull: false) String? get customType;
/// Create a copy of ProjectTilesetProperty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTilesetPropertyCopyWith<ProjectTilesetProperty> get copyWith => _$ProjectTilesetPropertyCopyWithImpl<ProjectTilesetProperty>(this as ProjectTilesetProperty, _$identity);

  /// Serializes this ProjectTilesetProperty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTilesetProperty&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.customType, customType) || other.customType == customType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,const DeepCollectionEquality().hash(value),customType);

@override
String toString() {
  return 'ProjectTilesetProperty(name: $name, type: $type, value: $value, customType: $customType)';
}


}

/// @nodoc
abstract mixin class $ProjectTilesetPropertyCopyWith<$Res>  {
  factory $ProjectTilesetPropertyCopyWith(ProjectTilesetProperty value, $Res Function(ProjectTilesetProperty) _then) = _$ProjectTilesetPropertyCopyWithImpl;
@useResult
$Res call({
 String name, ProjectTilesetPropertyType type, Object? value,@JsonKey(includeIfNull: false) String? customType
});




}
/// @nodoc
class _$ProjectTilesetPropertyCopyWithImpl<$Res>
    implements $ProjectTilesetPropertyCopyWith<$Res> {
  _$ProjectTilesetPropertyCopyWithImpl(this._self, this._then);

  final ProjectTilesetProperty _self;
  final $Res Function(ProjectTilesetProperty) _then;

/// Create a copy of ProjectTilesetProperty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? value = freezed,Object? customType = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProjectTilesetPropertyType,value: freezed == value ? _self.value : value ,customType: freezed == customType ? _self.customType : customType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTilesetProperty].
extension ProjectTilesetPropertyPatterns on ProjectTilesetProperty {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTilesetProperty value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTilesetProperty() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTilesetProperty value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetProperty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTilesetProperty value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetProperty() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  ProjectTilesetPropertyType type,  Object? value, @JsonKey(includeIfNull: false)  String? customType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTilesetProperty() when $default != null:
return $default(_that.name,_that.type,_that.value,_that.customType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  ProjectTilesetPropertyType type,  Object? value, @JsonKey(includeIfNull: false)  String? customType)  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetProperty():
return $default(_that.name,_that.type,_that.value,_that.customType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  ProjectTilesetPropertyType type,  Object? value, @JsonKey(includeIfNull: false)  String? customType)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetProperty() when $default != null:
return $default(_that.name,_that.type,_that.value,_that.customType);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectTilesetProperty implements ProjectTilesetProperty {
  const _ProjectTilesetProperty({required this.name, required this.type, this.value, @JsonKey(includeIfNull: false) this.customType});
  factory _ProjectTilesetProperty.fromJson(Map<String, dynamic> json) => _$ProjectTilesetPropertyFromJson(json);

@override final  String name;
@override final  ProjectTilesetPropertyType type;
@override final  Object? value;
@override@JsonKey(includeIfNull: false) final  String? customType;

/// Create a copy of ProjectTilesetProperty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTilesetPropertyCopyWith<_ProjectTilesetProperty> get copyWith => __$ProjectTilesetPropertyCopyWithImpl<_ProjectTilesetProperty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTilesetPropertyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTilesetProperty&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.customType, customType) || other.customType == customType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,const DeepCollectionEquality().hash(value),customType);

@override
String toString() {
  return 'ProjectTilesetProperty(name: $name, type: $type, value: $value, customType: $customType)';
}


}

/// @nodoc
abstract mixin class _$ProjectTilesetPropertyCopyWith<$Res> implements $ProjectTilesetPropertyCopyWith<$Res> {
  factory _$ProjectTilesetPropertyCopyWith(_ProjectTilesetProperty value, $Res Function(_ProjectTilesetProperty) _then) = __$ProjectTilesetPropertyCopyWithImpl;
@override @useResult
$Res call({
 String name, ProjectTilesetPropertyType type, Object? value,@JsonKey(includeIfNull: false) String? customType
});




}
/// @nodoc
class __$ProjectTilesetPropertyCopyWithImpl<$Res>
    implements _$ProjectTilesetPropertyCopyWith<$Res> {
  __$ProjectTilesetPropertyCopyWithImpl(this._self, this._then);

  final _ProjectTilesetProperty _self;
  final $Res Function(_ProjectTilesetProperty) _then;

/// Create a copy of ProjectTilesetProperty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? value = freezed,Object? customType = freezed,}) {
  return _then(_ProjectTilesetProperty(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProjectTilesetPropertyType,value: freezed == value ? _self.value : value ,customType: freezed == customType ? _self.customType : customType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProjectTilesetPixelRect {

 int get x; int get y; int get width; int get height;
/// Create a copy of ProjectTilesetPixelRect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTilesetPixelRectCopyWith<ProjectTilesetPixelRect> get copyWith => _$ProjectTilesetPixelRectCopyWithImpl<ProjectTilesetPixelRect>(this as ProjectTilesetPixelRect, _$identity);

  /// Serializes this ProjectTilesetPixelRect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTilesetPixelRect&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'ProjectTilesetPixelRect(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $ProjectTilesetPixelRectCopyWith<$Res>  {
  factory $ProjectTilesetPixelRectCopyWith(ProjectTilesetPixelRect value, $Res Function(ProjectTilesetPixelRect) _then) = _$ProjectTilesetPixelRectCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$ProjectTilesetPixelRectCopyWithImpl<$Res>
    implements $ProjectTilesetPixelRectCopyWith<$Res> {
  _$ProjectTilesetPixelRectCopyWithImpl(this._self, this._then);

  final ProjectTilesetPixelRect _self;
  final $Res Function(ProjectTilesetPixelRect) _then;

/// Create a copy of ProjectTilesetPixelRect
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


/// Adds pattern-matching-related methods to [ProjectTilesetPixelRect].
extension ProjectTilesetPixelRectPatterns on ProjectTilesetPixelRect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTilesetPixelRect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTilesetPixelRect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTilesetPixelRect value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetPixelRect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTilesetPixelRect value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetPixelRect() when $default != null:
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
case _ProjectTilesetPixelRect() when $default != null:
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
case _ProjectTilesetPixelRect():
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
case _ProjectTilesetPixelRect() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectTilesetPixelRect implements ProjectTilesetPixelRect {
  const _ProjectTilesetPixelRect({required this.x, required this.y, required this.width, required this.height});
  factory _ProjectTilesetPixelRect.fromJson(Map<String, dynamic> json) => _$ProjectTilesetPixelRectFromJson(json);

@override final  int x;
@override final  int y;
@override final  int width;
@override final  int height;

/// Create a copy of ProjectTilesetPixelRect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTilesetPixelRectCopyWith<_ProjectTilesetPixelRect> get copyWith => __$ProjectTilesetPixelRectCopyWithImpl<_ProjectTilesetPixelRect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTilesetPixelRectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTilesetPixelRect&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'ProjectTilesetPixelRect(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$ProjectTilesetPixelRectCopyWith<$Res> implements $ProjectTilesetPixelRectCopyWith<$Res> {
  factory _$ProjectTilesetPixelRectCopyWith(_ProjectTilesetPixelRect value, $Res Function(_ProjectTilesetPixelRect) _then) = __$ProjectTilesetPixelRectCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class __$ProjectTilesetPixelRectCopyWithImpl<$Res>
    implements _$ProjectTilesetPixelRectCopyWith<$Res> {
  __$ProjectTilesetPixelRectCopyWithImpl(this._self, this._then);

  final _ProjectTilesetPixelRect _self;
  final $Res Function(_ProjectTilesetPixelRect) _then;

/// Create a copy of ProjectTilesetPixelRect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_ProjectTilesetPixelRect(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectTilesetPixelPoint {

 double get x; double get y;
/// Create a copy of ProjectTilesetPixelPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTilesetPixelPointCopyWith<ProjectTilesetPixelPoint> get copyWith => _$ProjectTilesetPixelPointCopyWithImpl<ProjectTilesetPixelPoint>(this as ProjectTilesetPixelPoint, _$identity);

  /// Serializes this ProjectTilesetPixelPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTilesetPixelPoint&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'ProjectTilesetPixelPoint(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $ProjectTilesetPixelPointCopyWith<$Res>  {
  factory $ProjectTilesetPixelPointCopyWith(ProjectTilesetPixelPoint value, $Res Function(ProjectTilesetPixelPoint) _then) = _$ProjectTilesetPixelPointCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$ProjectTilesetPixelPointCopyWithImpl<$Res>
    implements $ProjectTilesetPixelPointCopyWith<$Res> {
  _$ProjectTilesetPixelPointCopyWithImpl(this._self, this._then);

  final ProjectTilesetPixelPoint _self;
  final $Res Function(ProjectTilesetPixelPoint) _then;

/// Create a copy of ProjectTilesetPixelPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTilesetPixelPoint].
extension ProjectTilesetPixelPointPatterns on ProjectTilesetPixelPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTilesetPixelPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTilesetPixelPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTilesetPixelPoint value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetPixelPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTilesetPixelPoint value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetPixelPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTilesetPixelPoint() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y)  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetPixelPoint():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetPixelPoint() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectTilesetPixelPoint implements ProjectTilesetPixelPoint {
  const _ProjectTilesetPixelPoint({required this.x, required this.y});
  factory _ProjectTilesetPixelPoint.fromJson(Map<String, dynamic> json) => _$ProjectTilesetPixelPointFromJson(json);

@override final  double x;
@override final  double y;

/// Create a copy of ProjectTilesetPixelPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTilesetPixelPointCopyWith<_ProjectTilesetPixelPoint> get copyWith => __$ProjectTilesetPixelPointCopyWithImpl<_ProjectTilesetPixelPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTilesetPixelPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTilesetPixelPoint&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'ProjectTilesetPixelPoint(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$ProjectTilesetPixelPointCopyWith<$Res> implements $ProjectTilesetPixelPointCopyWith<$Res> {
  factory _$ProjectTilesetPixelPointCopyWith(_ProjectTilesetPixelPoint value, $Res Function(_ProjectTilesetPixelPoint) _then) = __$ProjectTilesetPixelPointCopyWithImpl;
@override @useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class __$ProjectTilesetPixelPointCopyWithImpl<$Res>
    implements _$ProjectTilesetPixelPointCopyWith<$Res> {
  __$ProjectTilesetPixelPointCopyWithImpl(this._self, this._then);

  final _ProjectTilesetPixelPoint _self;
  final $Res Function(_ProjectTilesetPixelPoint) _then;

/// Create a copy of ProjectTilesetPixelPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_ProjectTilesetPixelPoint(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ProjectTilesetCollisionObject {

 int get id; String get name; String get type; ProjectTilesetCollisionShape get shape; double get x; double get y; double get width; double get height; double get rotation; List<ProjectTilesetPixelPoint> get points; List<ProjectTilesetProperty> get properties;
/// Create a copy of ProjectTilesetCollisionObject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTilesetCollisionObjectCopyWith<ProjectTilesetCollisionObject> get copyWith => _$ProjectTilesetCollisionObjectCopyWithImpl<ProjectTilesetCollisionObject>(this as ProjectTilesetCollisionObject, _$identity);

  /// Serializes this ProjectTilesetCollisionObject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTilesetCollisionObject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&const DeepCollectionEquality().equals(other.points, points)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,shape,x,y,width,height,rotation,const DeepCollectionEquality().hash(points),const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'ProjectTilesetCollisionObject(id: $id, name: $name, type: $type, shape: $shape, x: $x, y: $y, width: $width, height: $height, rotation: $rotation, points: $points, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $ProjectTilesetCollisionObjectCopyWith<$Res>  {
  factory $ProjectTilesetCollisionObjectCopyWith(ProjectTilesetCollisionObject value, $Res Function(ProjectTilesetCollisionObject) _then) = _$ProjectTilesetCollisionObjectCopyWithImpl;
@useResult
$Res call({
 int id, String name, String type, ProjectTilesetCollisionShape shape, double x, double y, double width, double height, double rotation, List<ProjectTilesetPixelPoint> points, List<ProjectTilesetProperty> properties
});




}
/// @nodoc
class _$ProjectTilesetCollisionObjectCopyWithImpl<$Res>
    implements $ProjectTilesetCollisionObjectCopyWith<$Res> {
  _$ProjectTilesetCollisionObjectCopyWithImpl(this._self, this._then);

  final ProjectTilesetCollisionObject _self;
  final $Res Function(ProjectTilesetCollisionObject) _then;

/// Create a copy of ProjectTilesetCollisionObject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? shape = null,Object? x = null,Object? y = null,Object? width = null,Object? height = null,Object? rotation = null,Object? points = null,Object? properties = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as ProjectTilesetCollisionShape,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as double,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetPixelPoint>,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetProperty>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTilesetCollisionObject].
extension ProjectTilesetCollisionObjectPatterns on ProjectTilesetCollisionObject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTilesetCollisionObject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTilesetCollisionObject() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTilesetCollisionObject value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetCollisionObject():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTilesetCollisionObject value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetCollisionObject() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String type,  ProjectTilesetCollisionShape shape,  double x,  double y,  double width,  double height,  double rotation,  List<ProjectTilesetPixelPoint> points,  List<ProjectTilesetProperty> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTilesetCollisionObject() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.shape,_that.x,_that.y,_that.width,_that.height,_that.rotation,_that.points,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String type,  ProjectTilesetCollisionShape shape,  double x,  double y,  double width,  double height,  double rotation,  List<ProjectTilesetPixelPoint> points,  List<ProjectTilesetProperty> properties)  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetCollisionObject():
return $default(_that.id,_that.name,_that.type,_that.shape,_that.x,_that.y,_that.width,_that.height,_that.rotation,_that.points,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String type,  ProjectTilesetCollisionShape shape,  double x,  double y,  double width,  double height,  double rotation,  List<ProjectTilesetPixelPoint> points,  List<ProjectTilesetProperty> properties)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetCollisionObject() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.shape,_that.x,_that.y,_that.width,_that.height,_that.rotation,_that.points,_that.properties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectTilesetCollisionObject implements ProjectTilesetCollisionObject {
  const _ProjectTilesetCollisionObject({required this.id, this.name = '', this.type = '', this.shape = ProjectTilesetCollisionShape.rectangle, required this.x, required this.y, this.width = 0, this.height = 0, this.rotation = 0, final  List<ProjectTilesetPixelPoint> points = const <ProjectTilesetPixelPoint>[], final  List<ProjectTilesetProperty> properties = const <ProjectTilesetProperty>[]}): _points = points,_properties = properties;
  factory _ProjectTilesetCollisionObject.fromJson(Map<String, dynamic> json) => _$ProjectTilesetCollisionObjectFromJson(json);

@override final  int id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String type;
@override@JsonKey() final  ProjectTilesetCollisionShape shape;
@override final  double x;
@override final  double y;
@override@JsonKey() final  double width;
@override@JsonKey() final  double height;
@override@JsonKey() final  double rotation;
 final  List<ProjectTilesetPixelPoint> _points;
@override@JsonKey() List<ProjectTilesetPixelPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

 final  List<ProjectTilesetProperty> _properties;
@override@JsonKey() List<ProjectTilesetProperty> get properties {
  if (_properties is EqualUnmodifiableListView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_properties);
}


/// Create a copy of ProjectTilesetCollisionObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTilesetCollisionObjectCopyWith<_ProjectTilesetCollisionObject> get copyWith => __$ProjectTilesetCollisionObjectCopyWithImpl<_ProjectTilesetCollisionObject>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTilesetCollisionObjectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTilesetCollisionObject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&const DeepCollectionEquality().equals(other._points, _points)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,shape,x,y,width,height,rotation,const DeepCollectionEquality().hash(_points),const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'ProjectTilesetCollisionObject(id: $id, name: $name, type: $type, shape: $shape, x: $x, y: $y, width: $width, height: $height, rotation: $rotation, points: $points, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$ProjectTilesetCollisionObjectCopyWith<$Res> implements $ProjectTilesetCollisionObjectCopyWith<$Res> {
  factory _$ProjectTilesetCollisionObjectCopyWith(_ProjectTilesetCollisionObject value, $Res Function(_ProjectTilesetCollisionObject) _then) = __$ProjectTilesetCollisionObjectCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String type, ProjectTilesetCollisionShape shape, double x, double y, double width, double height, double rotation, List<ProjectTilesetPixelPoint> points, List<ProjectTilesetProperty> properties
});




}
/// @nodoc
class __$ProjectTilesetCollisionObjectCopyWithImpl<$Res>
    implements _$ProjectTilesetCollisionObjectCopyWith<$Res> {
  __$ProjectTilesetCollisionObjectCopyWithImpl(this._self, this._then);

  final _ProjectTilesetCollisionObject _self;
  final $Res Function(_ProjectTilesetCollisionObject) _then;

/// Create a copy of ProjectTilesetCollisionObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? shape = null,Object? x = null,Object? y = null,Object? width = null,Object? height = null,Object? rotation = null,Object? points = null,Object? properties = null,}) {
  return _then(_ProjectTilesetCollisionObject(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as ProjectTilesetCollisionShape,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as double,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetPixelPoint>,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetProperty>,
  ));
}


}


/// @nodoc
mixin _$ProjectImageCollectionPage {

 String get id; String get assetId; int get pixelWidth; int get pixelHeight;
/// Create a copy of ProjectImageCollectionPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectImageCollectionPageCopyWith<ProjectImageCollectionPage> get copyWith => _$ProjectImageCollectionPageCopyWithImpl<ProjectImageCollectionPage>(this as ProjectImageCollectionPage, _$identity);

  /// Serializes this ProjectImageCollectionPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectImageCollectionPage&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.pixelWidth, pixelWidth) || other.pixelWidth == pixelWidth)&&(identical(other.pixelHeight, pixelHeight) || other.pixelHeight == pixelHeight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,assetId,pixelWidth,pixelHeight);

@override
String toString() {
  return 'ProjectImageCollectionPage(id: $id, assetId: $assetId, pixelWidth: $pixelWidth, pixelHeight: $pixelHeight)';
}


}

/// @nodoc
abstract mixin class $ProjectImageCollectionPageCopyWith<$Res>  {
  factory $ProjectImageCollectionPageCopyWith(ProjectImageCollectionPage value, $Res Function(ProjectImageCollectionPage) _then) = _$ProjectImageCollectionPageCopyWithImpl;
@useResult
$Res call({
 String id, String assetId, int pixelWidth, int pixelHeight
});




}
/// @nodoc
class _$ProjectImageCollectionPageCopyWithImpl<$Res>
    implements $ProjectImageCollectionPageCopyWith<$Res> {
  _$ProjectImageCollectionPageCopyWithImpl(this._self, this._then);

  final ProjectImageCollectionPage _self;
  final $Res Function(ProjectImageCollectionPage) _then;

/// Create a copy of ProjectImageCollectionPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? assetId = null,Object? pixelWidth = null,Object? pixelHeight = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,pixelWidth: null == pixelWidth ? _self.pixelWidth : pixelWidth // ignore: cast_nullable_to_non_nullable
as int,pixelHeight: null == pixelHeight ? _self.pixelHeight : pixelHeight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectImageCollectionPage].
extension ProjectImageCollectionPagePatterns on ProjectImageCollectionPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectImageCollectionPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectImageCollectionPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectImageCollectionPage value)  $default,){
final _that = this;
switch (_that) {
case _ProjectImageCollectionPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectImageCollectionPage value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectImageCollectionPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String assetId,  int pixelWidth,  int pixelHeight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectImageCollectionPage() when $default != null:
return $default(_that.id,_that.assetId,_that.pixelWidth,_that.pixelHeight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String assetId,  int pixelWidth,  int pixelHeight)  $default,) {final _that = this;
switch (_that) {
case _ProjectImageCollectionPage():
return $default(_that.id,_that.assetId,_that.pixelWidth,_that.pixelHeight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String assetId,  int pixelWidth,  int pixelHeight)?  $default,) {final _that = this;
switch (_that) {
case _ProjectImageCollectionPage() when $default != null:
return $default(_that.id,_that.assetId,_that.pixelWidth,_that.pixelHeight);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectImageCollectionPage implements ProjectImageCollectionPage {
  const _ProjectImageCollectionPage({required this.id, required this.assetId, required this.pixelWidth, required this.pixelHeight});
  factory _ProjectImageCollectionPage.fromJson(Map<String, dynamic> json) => _$ProjectImageCollectionPageFromJson(json);

@override final  String id;
@override final  String assetId;
@override final  int pixelWidth;
@override final  int pixelHeight;

/// Create a copy of ProjectImageCollectionPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectImageCollectionPageCopyWith<_ProjectImageCollectionPage> get copyWith => __$ProjectImageCollectionPageCopyWithImpl<_ProjectImageCollectionPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectImageCollectionPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectImageCollectionPage&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.pixelWidth, pixelWidth) || other.pixelWidth == pixelWidth)&&(identical(other.pixelHeight, pixelHeight) || other.pixelHeight == pixelHeight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,assetId,pixelWidth,pixelHeight);

@override
String toString() {
  return 'ProjectImageCollectionPage(id: $id, assetId: $assetId, pixelWidth: $pixelWidth, pixelHeight: $pixelHeight)';
}


}

/// @nodoc
abstract mixin class _$ProjectImageCollectionPageCopyWith<$Res> implements $ProjectImageCollectionPageCopyWith<$Res> {
  factory _$ProjectImageCollectionPageCopyWith(_ProjectImageCollectionPage value, $Res Function(_ProjectImageCollectionPage) _then) = __$ProjectImageCollectionPageCopyWithImpl;
@override @useResult
$Res call({
 String id, String assetId, int pixelWidth, int pixelHeight
});




}
/// @nodoc
class __$ProjectImageCollectionPageCopyWithImpl<$Res>
    implements _$ProjectImageCollectionPageCopyWith<$Res> {
  __$ProjectImageCollectionPageCopyWithImpl(this._self, this._then);

  final _ProjectImageCollectionPage _self;
  final $Res Function(_ProjectImageCollectionPage) _then;

/// Create a copy of ProjectImageCollectionPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? assetId = null,Object? pixelWidth = null,Object? pixelHeight = null,}) {
  return _then(_ProjectImageCollectionPage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,pixelWidth: null == pixelWidth ? _self.pixelWidth : pixelWidth // ignore: cast_nullable_to_non_nullable
as int,pixelHeight: null == pixelHeight ? _self.pixelHeight : pixelHeight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectImageCollectionAnimationFrame {

 int get tileId; int get durationMs;
/// Create a copy of ProjectImageCollectionAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectImageCollectionAnimationFrameCopyWith<ProjectImageCollectionAnimationFrame> get copyWith => _$ProjectImageCollectionAnimationFrameCopyWithImpl<ProjectImageCollectionAnimationFrame>(this as ProjectImageCollectionAnimationFrame, _$identity);

  /// Serializes this ProjectImageCollectionAnimationFrame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectImageCollectionAnimationFrame&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,durationMs);

@override
String toString() {
  return 'ProjectImageCollectionAnimationFrame(tileId: $tileId, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $ProjectImageCollectionAnimationFrameCopyWith<$Res>  {
  factory $ProjectImageCollectionAnimationFrameCopyWith(ProjectImageCollectionAnimationFrame value, $Res Function(ProjectImageCollectionAnimationFrame) _then) = _$ProjectImageCollectionAnimationFrameCopyWithImpl;
@useResult
$Res call({
 int tileId, int durationMs
});




}
/// @nodoc
class _$ProjectImageCollectionAnimationFrameCopyWithImpl<$Res>
    implements $ProjectImageCollectionAnimationFrameCopyWith<$Res> {
  _$ProjectImageCollectionAnimationFrameCopyWithImpl(this._self, this._then);

  final ProjectImageCollectionAnimationFrame _self;
  final $Res Function(ProjectImageCollectionAnimationFrame) _then;

/// Create a copy of ProjectImageCollectionAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tileId = null,Object? durationMs = null,}) {
  return _then(_self.copyWith(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectImageCollectionAnimationFrame].
extension ProjectImageCollectionAnimationFramePatterns on ProjectImageCollectionAnimationFrame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectImageCollectionAnimationFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectImageCollectionAnimationFrame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectImageCollectionAnimationFrame value)  $default,){
final _that = this;
switch (_that) {
case _ProjectImageCollectionAnimationFrame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectImageCollectionAnimationFrame value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectImageCollectionAnimationFrame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tileId,  int durationMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectImageCollectionAnimationFrame() when $default != null:
return $default(_that.tileId,_that.durationMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tileId,  int durationMs)  $default,) {final _that = this;
switch (_that) {
case _ProjectImageCollectionAnimationFrame():
return $default(_that.tileId,_that.durationMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tileId,  int durationMs)?  $default,) {final _that = this;
switch (_that) {
case _ProjectImageCollectionAnimationFrame() when $default != null:
return $default(_that.tileId,_that.durationMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectImageCollectionAnimationFrame implements ProjectImageCollectionAnimationFrame {
  const _ProjectImageCollectionAnimationFrame({required this.tileId, required this.durationMs});
  factory _ProjectImageCollectionAnimationFrame.fromJson(Map<String, dynamic> json) => _$ProjectImageCollectionAnimationFrameFromJson(json);

@override final  int tileId;
@override final  int durationMs;

/// Create a copy of ProjectImageCollectionAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectImageCollectionAnimationFrameCopyWith<_ProjectImageCollectionAnimationFrame> get copyWith => __$ProjectImageCollectionAnimationFrameCopyWithImpl<_ProjectImageCollectionAnimationFrame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectImageCollectionAnimationFrameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectImageCollectionAnimationFrame&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,durationMs);

@override
String toString() {
  return 'ProjectImageCollectionAnimationFrame(tileId: $tileId, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class _$ProjectImageCollectionAnimationFrameCopyWith<$Res> implements $ProjectImageCollectionAnimationFrameCopyWith<$Res> {
  factory _$ProjectImageCollectionAnimationFrameCopyWith(_ProjectImageCollectionAnimationFrame value, $Res Function(_ProjectImageCollectionAnimationFrame) _then) = __$ProjectImageCollectionAnimationFrameCopyWithImpl;
@override @useResult
$Res call({
 int tileId, int durationMs
});




}
/// @nodoc
class __$ProjectImageCollectionAnimationFrameCopyWithImpl<$Res>
    implements _$ProjectImageCollectionAnimationFrameCopyWith<$Res> {
  __$ProjectImageCollectionAnimationFrameCopyWithImpl(this._self, this._then);

  final _ProjectImageCollectionAnimationFrame _self;
  final $Res Function(_ProjectImageCollectionAnimationFrame) _then;

/// Create a copy of ProjectImageCollectionAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tileId = null,Object? durationMs = null,}) {
  return _then(_ProjectImageCollectionAnimationFrame(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectRegularAtlasTileAnimation {

 int get tileId; List<ProjectImageCollectionAnimationFrame> get frames;
/// Create a copy of ProjectRegularAtlasTileAnimation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectRegularAtlasTileAnimationCopyWith<ProjectRegularAtlasTileAnimation> get copyWith => _$ProjectRegularAtlasTileAnimationCopyWithImpl<ProjectRegularAtlasTileAnimation>(this as ProjectRegularAtlasTileAnimation, _$identity);

  /// Serializes this ProjectRegularAtlasTileAnimation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectRegularAtlasTileAnimation&&(identical(other.tileId, tileId) || other.tileId == tileId)&&const DeepCollectionEquality().equals(other.frames, frames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,const DeepCollectionEquality().hash(frames));

@override
String toString() {
  return 'ProjectRegularAtlasTileAnimation(tileId: $tileId, frames: $frames)';
}


}

/// @nodoc
abstract mixin class $ProjectRegularAtlasTileAnimationCopyWith<$Res>  {
  factory $ProjectRegularAtlasTileAnimationCopyWith(ProjectRegularAtlasTileAnimation value, $Res Function(ProjectRegularAtlasTileAnimation) _then) = _$ProjectRegularAtlasTileAnimationCopyWithImpl;
@useResult
$Res call({
 int tileId, List<ProjectImageCollectionAnimationFrame> frames
});




}
/// @nodoc
class _$ProjectRegularAtlasTileAnimationCopyWithImpl<$Res>
    implements $ProjectRegularAtlasTileAnimationCopyWith<$Res> {
  _$ProjectRegularAtlasTileAnimationCopyWithImpl(this._self, this._then);

  final ProjectRegularAtlasTileAnimation _self;
  final $Res Function(ProjectRegularAtlasTileAnimation) _then;

/// Create a copy of ProjectRegularAtlasTileAnimation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tileId = null,Object? frames = null,}) {
  return _then(_self.copyWith(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as List<ProjectImageCollectionAnimationFrame>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectRegularAtlasTileAnimation].
extension ProjectRegularAtlasTileAnimationPatterns on ProjectRegularAtlasTileAnimation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectRegularAtlasTileAnimation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectRegularAtlasTileAnimation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectRegularAtlasTileAnimation value)  $default,){
final _that = this;
switch (_that) {
case _ProjectRegularAtlasTileAnimation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectRegularAtlasTileAnimation value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectRegularAtlasTileAnimation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tileId,  List<ProjectImageCollectionAnimationFrame> frames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectRegularAtlasTileAnimation() when $default != null:
return $default(_that.tileId,_that.frames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tileId,  List<ProjectImageCollectionAnimationFrame> frames)  $default,) {final _that = this;
switch (_that) {
case _ProjectRegularAtlasTileAnimation():
return $default(_that.tileId,_that.frames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tileId,  List<ProjectImageCollectionAnimationFrame> frames)?  $default,) {final _that = this;
switch (_that) {
case _ProjectRegularAtlasTileAnimation() when $default != null:
return $default(_that.tileId,_that.frames);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectRegularAtlasTileAnimation implements ProjectRegularAtlasTileAnimation {
  const _ProjectRegularAtlasTileAnimation({required this.tileId, required final  List<ProjectImageCollectionAnimationFrame> frames}): _frames = frames;
  factory _ProjectRegularAtlasTileAnimation.fromJson(Map<String, dynamic> json) => _$ProjectRegularAtlasTileAnimationFromJson(json);

@override final  int tileId;
 final  List<ProjectImageCollectionAnimationFrame> _frames;
@override List<ProjectImageCollectionAnimationFrame> get frames {
  if (_frames is EqualUnmodifiableListView) return _frames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_frames);
}


/// Create a copy of ProjectRegularAtlasTileAnimation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectRegularAtlasTileAnimationCopyWith<_ProjectRegularAtlasTileAnimation> get copyWith => __$ProjectRegularAtlasTileAnimationCopyWithImpl<_ProjectRegularAtlasTileAnimation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectRegularAtlasTileAnimationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectRegularAtlasTileAnimation&&(identical(other.tileId, tileId) || other.tileId == tileId)&&const DeepCollectionEquality().equals(other._frames, _frames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,const DeepCollectionEquality().hash(_frames));

@override
String toString() {
  return 'ProjectRegularAtlasTileAnimation(tileId: $tileId, frames: $frames)';
}


}

/// @nodoc
abstract mixin class _$ProjectRegularAtlasTileAnimationCopyWith<$Res> implements $ProjectRegularAtlasTileAnimationCopyWith<$Res> {
  factory _$ProjectRegularAtlasTileAnimationCopyWith(_ProjectRegularAtlasTileAnimation value, $Res Function(_ProjectRegularAtlasTileAnimation) _then) = __$ProjectRegularAtlasTileAnimationCopyWithImpl;
@override @useResult
$Res call({
 int tileId, List<ProjectImageCollectionAnimationFrame> frames
});




}
/// @nodoc
class __$ProjectRegularAtlasTileAnimationCopyWithImpl<$Res>
    implements _$ProjectRegularAtlasTileAnimationCopyWith<$Res> {
  __$ProjectRegularAtlasTileAnimationCopyWithImpl(this._self, this._then);

  final _ProjectRegularAtlasTileAnimation _self;
  final $Res Function(_ProjectRegularAtlasTileAnimation) _then;

/// Create a copy of ProjectRegularAtlasTileAnimation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tileId = null,Object? frames = null,}) {
  return _then(_ProjectRegularAtlasTileAnimation(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,frames: null == frames ? _self._frames : frames // ignore: cast_nullable_to_non_nullable
as List<ProjectImageCollectionAnimationFrame>,
  ));
}


}


/// @nodoc
mixin _$ProjectImageCollectionTileDefinition {

 int get tileId; String get pageId; ProjectTilesetPixelRect get sourceRect; int get offsetX; int get offsetY; List<ProjectImageCollectionAnimationFrame> get animation; List<ProjectTilesetProperty> get properties; List<ProjectTilesetCollisionObject> get collisionObjects;
/// Create a copy of ProjectImageCollectionTileDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectImageCollectionTileDefinitionCopyWith<ProjectImageCollectionTileDefinition> get copyWith => _$ProjectImageCollectionTileDefinitionCopyWithImpl<ProjectImageCollectionTileDefinition>(this as ProjectImageCollectionTileDefinition, _$identity);

  /// Serializes this ProjectImageCollectionTileDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectImageCollectionTileDefinition&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.pageId, pageId) || other.pageId == pageId)&&(identical(other.sourceRect, sourceRect) || other.sourceRect == sourceRect)&&(identical(other.offsetX, offsetX) || other.offsetX == offsetX)&&(identical(other.offsetY, offsetY) || other.offsetY == offsetY)&&const DeepCollectionEquality().equals(other.animation, animation)&&const DeepCollectionEquality().equals(other.properties, properties)&&const DeepCollectionEquality().equals(other.collisionObjects, collisionObjects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,pageId,sourceRect,offsetX,offsetY,const DeepCollectionEquality().hash(animation),const DeepCollectionEquality().hash(properties),const DeepCollectionEquality().hash(collisionObjects));

@override
String toString() {
  return 'ProjectImageCollectionTileDefinition(tileId: $tileId, pageId: $pageId, sourceRect: $sourceRect, offsetX: $offsetX, offsetY: $offsetY, animation: $animation, properties: $properties, collisionObjects: $collisionObjects)';
}


}

/// @nodoc
abstract mixin class $ProjectImageCollectionTileDefinitionCopyWith<$Res>  {
  factory $ProjectImageCollectionTileDefinitionCopyWith(ProjectImageCollectionTileDefinition value, $Res Function(ProjectImageCollectionTileDefinition) _then) = _$ProjectImageCollectionTileDefinitionCopyWithImpl;
@useResult
$Res call({
 int tileId, String pageId, ProjectTilesetPixelRect sourceRect, int offsetX, int offsetY, List<ProjectImageCollectionAnimationFrame> animation, List<ProjectTilesetProperty> properties, List<ProjectTilesetCollisionObject> collisionObjects
});


$ProjectTilesetPixelRectCopyWith<$Res> get sourceRect;

}
/// @nodoc
class _$ProjectImageCollectionTileDefinitionCopyWithImpl<$Res>
    implements $ProjectImageCollectionTileDefinitionCopyWith<$Res> {
  _$ProjectImageCollectionTileDefinitionCopyWithImpl(this._self, this._then);

  final ProjectImageCollectionTileDefinition _self;
  final $Res Function(ProjectImageCollectionTileDefinition) _then;

/// Create a copy of ProjectImageCollectionTileDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tileId = null,Object? pageId = null,Object? sourceRect = null,Object? offsetX = null,Object? offsetY = null,Object? animation = null,Object? properties = null,Object? collisionObjects = null,}) {
  return _then(_self.copyWith(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as String,sourceRect: null == sourceRect ? _self.sourceRect : sourceRect // ignore: cast_nullable_to_non_nullable
as ProjectTilesetPixelRect,offsetX: null == offsetX ? _self.offsetX : offsetX // ignore: cast_nullable_to_non_nullable
as int,offsetY: null == offsetY ? _self.offsetY : offsetY // ignore: cast_nullable_to_non_nullable
as int,animation: null == animation ? _self.animation : animation // ignore: cast_nullable_to_non_nullable
as List<ProjectImageCollectionAnimationFrame>,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetProperty>,collisionObjects: null == collisionObjects ? _self.collisionObjects : collisionObjects // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetCollisionObject>,
  ));
}
/// Create a copy of ProjectImageCollectionTileDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTilesetPixelRectCopyWith<$Res> get sourceRect {

  return $ProjectTilesetPixelRectCopyWith<$Res>(_self.sourceRect, (value) {
    return _then(_self.copyWith(sourceRect: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectImageCollectionTileDefinition].
extension ProjectImageCollectionTileDefinitionPatterns on ProjectImageCollectionTileDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectImageCollectionTileDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectImageCollectionTileDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectImageCollectionTileDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ProjectImageCollectionTileDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectImageCollectionTileDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectImageCollectionTileDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tileId,  String pageId,  ProjectTilesetPixelRect sourceRect,  int offsetX,  int offsetY,  List<ProjectImageCollectionAnimationFrame> animation,  List<ProjectTilesetProperty> properties,  List<ProjectTilesetCollisionObject> collisionObjects)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectImageCollectionTileDefinition() when $default != null:
return $default(_that.tileId,_that.pageId,_that.sourceRect,_that.offsetX,_that.offsetY,_that.animation,_that.properties,_that.collisionObjects);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tileId,  String pageId,  ProjectTilesetPixelRect sourceRect,  int offsetX,  int offsetY,  List<ProjectImageCollectionAnimationFrame> animation,  List<ProjectTilesetProperty> properties,  List<ProjectTilesetCollisionObject> collisionObjects)  $default,) {final _that = this;
switch (_that) {
case _ProjectImageCollectionTileDefinition():
return $default(_that.tileId,_that.pageId,_that.sourceRect,_that.offsetX,_that.offsetY,_that.animation,_that.properties,_that.collisionObjects);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tileId,  String pageId,  ProjectTilesetPixelRect sourceRect,  int offsetX,  int offsetY,  List<ProjectImageCollectionAnimationFrame> animation,  List<ProjectTilesetProperty> properties,  List<ProjectTilesetCollisionObject> collisionObjects)?  $default,) {final _that = this;
switch (_that) {
case _ProjectImageCollectionTileDefinition() when $default != null:
return $default(_that.tileId,_that.pageId,_that.sourceRect,_that.offsetX,_that.offsetY,_that.animation,_that.properties,_that.collisionObjects);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectImageCollectionTileDefinition implements ProjectImageCollectionTileDefinition {
  const _ProjectImageCollectionTileDefinition({required this.tileId, required this.pageId, required this.sourceRect, this.offsetX = 0, this.offsetY = 0, final  List<ProjectImageCollectionAnimationFrame> animation = const <ProjectImageCollectionAnimationFrame>[], final  List<ProjectTilesetProperty> properties = const <ProjectTilesetProperty>[], final  List<ProjectTilesetCollisionObject> collisionObjects = const <ProjectTilesetCollisionObject>[]}): _animation = animation,_properties = properties,_collisionObjects = collisionObjects;
  factory _ProjectImageCollectionTileDefinition.fromJson(Map<String, dynamic> json) => _$ProjectImageCollectionTileDefinitionFromJson(json);

@override final  int tileId;
@override final  String pageId;
@override final  ProjectTilesetPixelRect sourceRect;
@override@JsonKey() final  int offsetX;
@override@JsonKey() final  int offsetY;
 final  List<ProjectImageCollectionAnimationFrame> _animation;
@override@JsonKey() List<ProjectImageCollectionAnimationFrame> get animation {
  if (_animation is EqualUnmodifiableListView) return _animation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_animation);
}

 final  List<ProjectTilesetProperty> _properties;
@override@JsonKey() List<ProjectTilesetProperty> get properties {
  if (_properties is EqualUnmodifiableListView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_properties);
}

 final  List<ProjectTilesetCollisionObject> _collisionObjects;
@override@JsonKey() List<ProjectTilesetCollisionObject> get collisionObjects {
  if (_collisionObjects is EqualUnmodifiableListView) return _collisionObjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_collisionObjects);
}


/// Create a copy of ProjectImageCollectionTileDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectImageCollectionTileDefinitionCopyWith<_ProjectImageCollectionTileDefinition> get copyWith => __$ProjectImageCollectionTileDefinitionCopyWithImpl<_ProjectImageCollectionTileDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectImageCollectionTileDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectImageCollectionTileDefinition&&(identical(other.tileId, tileId) || other.tileId == tileId)&&(identical(other.pageId, pageId) || other.pageId == pageId)&&(identical(other.sourceRect, sourceRect) || other.sourceRect == sourceRect)&&(identical(other.offsetX, offsetX) || other.offsetX == offsetX)&&(identical(other.offsetY, offsetY) || other.offsetY == offsetY)&&const DeepCollectionEquality().equals(other._animation, _animation)&&const DeepCollectionEquality().equals(other._properties, _properties)&&const DeepCollectionEquality().equals(other._collisionObjects, _collisionObjects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileId,pageId,sourceRect,offsetX,offsetY,const DeepCollectionEquality().hash(_animation),const DeepCollectionEquality().hash(_properties),const DeepCollectionEquality().hash(_collisionObjects));

@override
String toString() {
  return 'ProjectImageCollectionTileDefinition(tileId: $tileId, pageId: $pageId, sourceRect: $sourceRect, offsetX: $offsetX, offsetY: $offsetY, animation: $animation, properties: $properties, collisionObjects: $collisionObjects)';
}


}

/// @nodoc
abstract mixin class _$ProjectImageCollectionTileDefinitionCopyWith<$Res> implements $ProjectImageCollectionTileDefinitionCopyWith<$Res> {
  factory _$ProjectImageCollectionTileDefinitionCopyWith(_ProjectImageCollectionTileDefinition value, $Res Function(_ProjectImageCollectionTileDefinition) _then) = __$ProjectImageCollectionTileDefinitionCopyWithImpl;
@override @useResult
$Res call({
 int tileId, String pageId, ProjectTilesetPixelRect sourceRect, int offsetX, int offsetY, List<ProjectImageCollectionAnimationFrame> animation, List<ProjectTilesetProperty> properties, List<ProjectTilesetCollisionObject> collisionObjects
});


@override $ProjectTilesetPixelRectCopyWith<$Res> get sourceRect;

}
/// @nodoc
class __$ProjectImageCollectionTileDefinitionCopyWithImpl<$Res>
    implements _$ProjectImageCollectionTileDefinitionCopyWith<$Res> {
  __$ProjectImageCollectionTileDefinitionCopyWithImpl(this._self, this._then);

  final _ProjectImageCollectionTileDefinition _self;
  final $Res Function(_ProjectImageCollectionTileDefinition) _then;

/// Create a copy of ProjectImageCollectionTileDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tileId = null,Object? pageId = null,Object? sourceRect = null,Object? offsetX = null,Object? offsetY = null,Object? animation = null,Object? properties = null,Object? collisionObjects = null,}) {
  return _then(_ProjectImageCollectionTileDefinition(
tileId: null == tileId ? _self.tileId : tileId // ignore: cast_nullable_to_non_nullable
as int,pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as String,sourceRect: null == sourceRect ? _self.sourceRect : sourceRect // ignore: cast_nullable_to_non_nullable
as ProjectTilesetPixelRect,offsetX: null == offsetX ? _self.offsetX : offsetX // ignore: cast_nullable_to_non_nullable
as int,offsetY: null == offsetY ? _self.offsetY : offsetY // ignore: cast_nullable_to_non_nullable
as int,animation: null == animation ? _self._animation : animation // ignore: cast_nullable_to_non_nullable
as List<ProjectImageCollectionAnimationFrame>,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetProperty>,collisionObjects: null == collisionObjects ? _self._collisionObjects : collisionObjects // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetCollisionObject>,
  ));
}

/// Create a copy of ProjectImageCollectionTileDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTilesetPixelRectCopyWith<$Res> get sourceRect {

  return $ProjectTilesetPixelRectCopyWith<$Res>(_self.sourceRect, (value) {
    return _then(_self.copyWith(sourceRect: value));
  });
}
}

// dart format on
