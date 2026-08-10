// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_presentation_window_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectWindowStyleProfile {

 String get id; String get fillToken; String get borderToken; int get borderWidth; int get cornerRadius; int get contentPadding; int get shadowElevation;
/// Create a copy of ProjectWindowStyleProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectWindowStyleProfileCopyWith<ProjectWindowStyleProfile> get copyWith => _$ProjectWindowStyleProfileCopyWithImpl<ProjectWindowStyleProfile>(this as ProjectWindowStyleProfile, _$identity);

  /// Serializes this ProjectWindowStyleProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectWindowStyleProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fillToken, fillToken) || other.fillToken == fillToken)&&(identical(other.borderToken, borderToken) || other.borderToken == borderToken)&&(identical(other.borderWidth, borderWidth) || other.borderWidth == borderWidth)&&(identical(other.cornerRadius, cornerRadius) || other.cornerRadius == cornerRadius)&&(identical(other.contentPadding, contentPadding) || other.contentPadding == contentPadding)&&(identical(other.shadowElevation, shadowElevation) || other.shadowElevation == shadowElevation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fillToken,borderToken,borderWidth,cornerRadius,contentPadding,shadowElevation);

@override
String toString() {
  return 'ProjectWindowStyleProfile(id: $id, fillToken: $fillToken, borderToken: $borderToken, borderWidth: $borderWidth, cornerRadius: $cornerRadius, contentPadding: $contentPadding, shadowElevation: $shadowElevation)';
}


}

/// @nodoc
abstract mixin class $ProjectWindowStyleProfileCopyWith<$Res>  {
  factory $ProjectWindowStyleProfileCopyWith(ProjectWindowStyleProfile value, $Res Function(ProjectWindowStyleProfile) _then) = _$ProjectWindowStyleProfileCopyWithImpl;
@useResult
$Res call({
 String id, String fillToken, String borderToken, int borderWidth, int cornerRadius, int contentPadding, int shadowElevation
});




}
/// @nodoc
class _$ProjectWindowStyleProfileCopyWithImpl<$Res>
    implements $ProjectWindowStyleProfileCopyWith<$Res> {
  _$ProjectWindowStyleProfileCopyWithImpl(this._self, this._then);

  final ProjectWindowStyleProfile _self;
  final $Res Function(ProjectWindowStyleProfile) _then;

/// Create a copy of ProjectWindowStyleProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fillToken = null,Object? borderToken = null,Object? borderWidth = null,Object? cornerRadius = null,Object? contentPadding = null,Object? shadowElevation = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fillToken: null == fillToken ? _self.fillToken : fillToken // ignore: cast_nullable_to_non_nullable
as String,borderToken: null == borderToken ? _self.borderToken : borderToken // ignore: cast_nullable_to_non_nullable
as String,borderWidth: null == borderWidth ? _self.borderWidth : borderWidth // ignore: cast_nullable_to_non_nullable
as int,cornerRadius: null == cornerRadius ? _self.cornerRadius : cornerRadius // ignore: cast_nullable_to_non_nullable
as int,contentPadding: null == contentPadding ? _self.contentPadding : contentPadding // ignore: cast_nullable_to_non_nullable
as int,shadowElevation: null == shadowElevation ? _self.shadowElevation : shadowElevation // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectWindowStyleProfile].
extension ProjectWindowStyleProfilePatterns on ProjectWindowStyleProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectWindowStyleProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectWindowStyleProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectWindowStyleProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectWindowStyleProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectWindowStyleProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectWindowStyleProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fillToken,  String borderToken,  int borderWidth,  int cornerRadius,  int contentPadding,  int shadowElevation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectWindowStyleProfile() when $default != null:
return $default(_that.id,_that.fillToken,_that.borderToken,_that.borderWidth,_that.cornerRadius,_that.contentPadding,_that.shadowElevation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fillToken,  String borderToken,  int borderWidth,  int cornerRadius,  int contentPadding,  int shadowElevation)  $default,) {final _that = this;
switch (_that) {
case _ProjectWindowStyleProfile():
return $default(_that.id,_that.fillToken,_that.borderToken,_that.borderWidth,_that.cornerRadius,_that.contentPadding,_that.shadowElevation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fillToken,  String borderToken,  int borderWidth,  int cornerRadius,  int contentPadding,  int shadowElevation)?  $default,) {final _that = this;
switch (_that) {
case _ProjectWindowStyleProfile() when $default != null:
return $default(_that.id,_that.fillToken,_that.borderToken,_that.borderWidth,_that.cornerRadius,_that.contentPadding,_that.shadowElevation);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectWindowStyleProfile implements ProjectWindowStyleProfile {
  const _ProjectWindowStyleProfile({required this.id, required this.fillToken, required this.borderToken, required this.borderWidth, required this.cornerRadius, required this.contentPadding, required this.shadowElevation});
  factory _ProjectWindowStyleProfile.fromJson(Map<String, dynamic> json) => _$ProjectWindowStyleProfileFromJson(json);

@override final  String id;
@override final  String fillToken;
@override final  String borderToken;
@override final  int borderWidth;
@override final  int cornerRadius;
@override final  int contentPadding;
@override final  int shadowElevation;

/// Create a copy of ProjectWindowStyleProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectWindowStyleProfileCopyWith<_ProjectWindowStyleProfile> get copyWith => __$ProjectWindowStyleProfileCopyWithImpl<_ProjectWindowStyleProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectWindowStyleProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectWindowStyleProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fillToken, fillToken) || other.fillToken == fillToken)&&(identical(other.borderToken, borderToken) || other.borderToken == borderToken)&&(identical(other.borderWidth, borderWidth) || other.borderWidth == borderWidth)&&(identical(other.cornerRadius, cornerRadius) || other.cornerRadius == cornerRadius)&&(identical(other.contentPadding, contentPadding) || other.contentPadding == contentPadding)&&(identical(other.shadowElevation, shadowElevation) || other.shadowElevation == shadowElevation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fillToken,borderToken,borderWidth,cornerRadius,contentPadding,shadowElevation);

@override
String toString() {
  return 'ProjectWindowStyleProfile(id: $id, fillToken: $fillToken, borderToken: $borderToken, borderWidth: $borderWidth, cornerRadius: $cornerRadius, contentPadding: $contentPadding, shadowElevation: $shadowElevation)';
}


}

/// @nodoc
abstract mixin class _$ProjectWindowStyleProfileCopyWith<$Res> implements $ProjectWindowStyleProfileCopyWith<$Res> {
  factory _$ProjectWindowStyleProfileCopyWith(_ProjectWindowStyleProfile value, $Res Function(_ProjectWindowStyleProfile) _then) = __$ProjectWindowStyleProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String fillToken, String borderToken, int borderWidth, int cornerRadius, int contentPadding, int shadowElevation
});




}
/// @nodoc
class __$ProjectWindowStyleProfileCopyWithImpl<$Res>
    implements _$ProjectWindowStyleProfileCopyWith<$Res> {
  __$ProjectWindowStyleProfileCopyWithImpl(this._self, this._then);

  final _ProjectWindowStyleProfile _self;
  final $Res Function(_ProjectWindowStyleProfile) _then;

/// Create a copy of ProjectWindowStyleProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fillToken = null,Object? borderToken = null,Object? borderWidth = null,Object? cornerRadius = null,Object? contentPadding = null,Object? shadowElevation = null,}) {
  return _then(_ProjectWindowStyleProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fillToken: null == fillToken ? _self.fillToken : fillToken // ignore: cast_nullable_to_non_nullable
as String,borderToken: null == borderToken ? _self.borderToken : borderToken // ignore: cast_nullable_to_non_nullable
as String,borderWidth: null == borderWidth ? _self.borderWidth : borderWidth // ignore: cast_nullable_to_non_nullable
as int,cornerRadius: null == cornerRadius ? _self.cornerRadius : cornerRadius // ignore: cast_nullable_to_non_nullable
as int,contentPadding: null == contentPadding ? _self.contentPadding : contentPadding // ignore: cast_nullable_to_non_nullable
as int,shadowElevation: null == shadowElevation ? _self.shadowElevation : shadowElevation // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectPresentationWindowsProfile {

 List<ProjectWindowStyleProfile> get styles; String get defaultStyleId; String get pauseMenuStyleId; String get dialogueStyleId;@JsonKey(includeIfNull: false) String? get battleStyleId; double get pauseBackdropOpacity;
/// Create a copy of ProjectPresentationWindowsProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectPresentationWindowsProfileCopyWith<ProjectPresentationWindowsProfile> get copyWith => _$ProjectPresentationWindowsProfileCopyWithImpl<ProjectPresentationWindowsProfile>(this as ProjectPresentationWindowsProfile, _$identity);

  /// Serializes this ProjectPresentationWindowsProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectPresentationWindowsProfile&&const DeepCollectionEquality().equals(other.styles, styles)&&(identical(other.defaultStyleId, defaultStyleId) || other.defaultStyleId == defaultStyleId)&&(identical(other.pauseMenuStyleId, pauseMenuStyleId) || other.pauseMenuStyleId == pauseMenuStyleId)&&(identical(other.dialogueStyleId, dialogueStyleId) || other.dialogueStyleId == dialogueStyleId)&&(identical(other.battleStyleId, battleStyleId) || other.battleStyleId == battleStyleId)&&(identical(other.pauseBackdropOpacity, pauseBackdropOpacity) || other.pauseBackdropOpacity == pauseBackdropOpacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(styles),defaultStyleId,pauseMenuStyleId,dialogueStyleId,battleStyleId,pauseBackdropOpacity);

@override
String toString() {
  return 'ProjectPresentationWindowsProfile(styles: $styles, defaultStyleId: $defaultStyleId, pauseMenuStyleId: $pauseMenuStyleId, dialogueStyleId: $dialogueStyleId, battleStyleId: $battleStyleId, pauseBackdropOpacity: $pauseBackdropOpacity)';
}


}

/// @nodoc
abstract mixin class $ProjectPresentationWindowsProfileCopyWith<$Res>  {
  factory $ProjectPresentationWindowsProfileCopyWith(ProjectPresentationWindowsProfile value, $Res Function(ProjectPresentationWindowsProfile) _then) = _$ProjectPresentationWindowsProfileCopyWithImpl;
@useResult
$Res call({
 List<ProjectWindowStyleProfile> styles, String defaultStyleId, String pauseMenuStyleId, String dialogueStyleId,@JsonKey(includeIfNull: false) String? battleStyleId, double pauseBackdropOpacity
});




}
/// @nodoc
class _$ProjectPresentationWindowsProfileCopyWithImpl<$Res>
    implements $ProjectPresentationWindowsProfileCopyWith<$Res> {
  _$ProjectPresentationWindowsProfileCopyWithImpl(this._self, this._then);

  final ProjectPresentationWindowsProfile _self;
  final $Res Function(ProjectPresentationWindowsProfile) _then;

/// Create a copy of ProjectPresentationWindowsProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? styles = null,Object? defaultStyleId = null,Object? pauseMenuStyleId = null,Object? dialogueStyleId = null,Object? battleStyleId = freezed,Object? pauseBackdropOpacity = null,}) {
  return _then(_self.copyWith(
styles: null == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as List<ProjectWindowStyleProfile>,defaultStyleId: null == defaultStyleId ? _self.defaultStyleId : defaultStyleId // ignore: cast_nullable_to_non_nullable
as String,pauseMenuStyleId: null == pauseMenuStyleId ? _self.pauseMenuStyleId : pauseMenuStyleId // ignore: cast_nullable_to_non_nullable
as String,dialogueStyleId: null == dialogueStyleId ? _self.dialogueStyleId : dialogueStyleId // ignore: cast_nullable_to_non_nullable
as String,battleStyleId: freezed == battleStyleId ? _self.battleStyleId : battleStyleId // ignore: cast_nullable_to_non_nullable
as String?,pauseBackdropOpacity: null == pauseBackdropOpacity ? _self.pauseBackdropOpacity : pauseBackdropOpacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectPresentationWindowsProfile].
extension ProjectPresentationWindowsProfilePatterns on ProjectPresentationWindowsProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectPresentationWindowsProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectPresentationWindowsProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectPresentationWindowsProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationWindowsProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectPresentationWindowsProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationWindowsProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProjectWindowStyleProfile> styles,  String defaultStyleId,  String pauseMenuStyleId,  String dialogueStyleId, @JsonKey(includeIfNull: false)  String? battleStyleId,  double pauseBackdropOpacity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectPresentationWindowsProfile() when $default != null:
return $default(_that.styles,_that.defaultStyleId,_that.pauseMenuStyleId,_that.dialogueStyleId,_that.battleStyleId,_that.pauseBackdropOpacity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProjectWindowStyleProfile> styles,  String defaultStyleId,  String pauseMenuStyleId,  String dialogueStyleId, @JsonKey(includeIfNull: false)  String? battleStyleId,  double pauseBackdropOpacity)  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationWindowsProfile():
return $default(_that.styles,_that.defaultStyleId,_that.pauseMenuStyleId,_that.dialogueStyleId,_that.battleStyleId,_that.pauseBackdropOpacity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProjectWindowStyleProfile> styles,  String defaultStyleId,  String pauseMenuStyleId,  String dialogueStyleId, @JsonKey(includeIfNull: false)  String? battleStyleId,  double pauseBackdropOpacity)?  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationWindowsProfile() when $default != null:
return $default(_that.styles,_that.defaultStyleId,_that.pauseMenuStyleId,_that.dialogueStyleId,_that.battleStyleId,_that.pauseBackdropOpacity);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectPresentationWindowsProfile extends ProjectPresentationWindowsProfile {
  const _ProjectPresentationWindowsProfile({required final  List<ProjectWindowStyleProfile> styles, required this.defaultStyleId, required this.pauseMenuStyleId, required this.dialogueStyleId, @JsonKey(includeIfNull: false) this.battleStyleId, required this.pauseBackdropOpacity}): _styles = styles,super._();
  factory _ProjectPresentationWindowsProfile.fromJson(Map<String, dynamic> json) => _$ProjectPresentationWindowsProfileFromJson(json);

 final  List<ProjectWindowStyleProfile> _styles;
@override List<ProjectWindowStyleProfile> get styles {
  if (_styles is EqualUnmodifiableListView) return _styles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_styles);
}

@override final  String defaultStyleId;
@override final  String pauseMenuStyleId;
@override final  String dialogueStyleId;
@override@JsonKey(includeIfNull: false) final  String? battleStyleId;
@override final  double pauseBackdropOpacity;

/// Create a copy of ProjectPresentationWindowsProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectPresentationWindowsProfileCopyWith<_ProjectPresentationWindowsProfile> get copyWith => __$ProjectPresentationWindowsProfileCopyWithImpl<_ProjectPresentationWindowsProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectPresentationWindowsProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectPresentationWindowsProfile&&const DeepCollectionEquality().equals(other._styles, _styles)&&(identical(other.defaultStyleId, defaultStyleId) || other.defaultStyleId == defaultStyleId)&&(identical(other.pauseMenuStyleId, pauseMenuStyleId) || other.pauseMenuStyleId == pauseMenuStyleId)&&(identical(other.dialogueStyleId, dialogueStyleId) || other.dialogueStyleId == dialogueStyleId)&&(identical(other.battleStyleId, battleStyleId) || other.battleStyleId == battleStyleId)&&(identical(other.pauseBackdropOpacity, pauseBackdropOpacity) || other.pauseBackdropOpacity == pauseBackdropOpacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_styles),defaultStyleId,pauseMenuStyleId,dialogueStyleId,battleStyleId,pauseBackdropOpacity);

@override
String toString() {
  return 'ProjectPresentationWindowsProfile(styles: $styles, defaultStyleId: $defaultStyleId, pauseMenuStyleId: $pauseMenuStyleId, dialogueStyleId: $dialogueStyleId, battleStyleId: $battleStyleId, pauseBackdropOpacity: $pauseBackdropOpacity)';
}


}

/// @nodoc
abstract mixin class _$ProjectPresentationWindowsProfileCopyWith<$Res> implements $ProjectPresentationWindowsProfileCopyWith<$Res> {
  factory _$ProjectPresentationWindowsProfileCopyWith(_ProjectPresentationWindowsProfile value, $Res Function(_ProjectPresentationWindowsProfile) _then) = __$ProjectPresentationWindowsProfileCopyWithImpl;
@override @useResult
$Res call({
 List<ProjectWindowStyleProfile> styles, String defaultStyleId, String pauseMenuStyleId, String dialogueStyleId,@JsonKey(includeIfNull: false) String? battleStyleId, double pauseBackdropOpacity
});




}
/// @nodoc
class __$ProjectPresentationWindowsProfileCopyWithImpl<$Res>
    implements _$ProjectPresentationWindowsProfileCopyWith<$Res> {
  __$ProjectPresentationWindowsProfileCopyWithImpl(this._self, this._then);

  final _ProjectPresentationWindowsProfile _self;
  final $Res Function(_ProjectPresentationWindowsProfile) _then;

/// Create a copy of ProjectPresentationWindowsProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? styles = null,Object? defaultStyleId = null,Object? pauseMenuStyleId = null,Object? dialogueStyleId = null,Object? battleStyleId = freezed,Object? pauseBackdropOpacity = null,}) {
  return _then(_ProjectPresentationWindowsProfile(
styles: null == styles ? _self._styles : styles // ignore: cast_nullable_to_non_nullable
as List<ProjectWindowStyleProfile>,defaultStyleId: null == defaultStyleId ? _self.defaultStyleId : defaultStyleId // ignore: cast_nullable_to_non_nullable
as String,pauseMenuStyleId: null == pauseMenuStyleId ? _self.pauseMenuStyleId : pauseMenuStyleId // ignore: cast_nullable_to_non_nullable
as String,dialogueStyleId: null == dialogueStyleId ? _self.dialogueStyleId : dialogueStyleId // ignore: cast_nullable_to_non_nullable
as String,battleStyleId: freezed == battleStyleId ? _self.battleStyleId : battleStyleId // ignore: cast_nullable_to_non_nullable
as String?,pauseBackdropOpacity: null == pauseBackdropOpacity ? _self.pauseBackdropOpacity : pauseBackdropOpacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
