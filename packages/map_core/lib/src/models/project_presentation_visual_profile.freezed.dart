// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_presentation_visual_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectTypographyMetricsProfile {

 double get sizeScale; int get weight; double get lineHeight; double get letterSpacing;
/// Create a copy of ProjectTypographyMetricsProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTypographyMetricsProfileCopyWith<ProjectTypographyMetricsProfile> get copyWith => _$ProjectTypographyMetricsProfileCopyWithImpl<ProjectTypographyMetricsProfile>(this as ProjectTypographyMetricsProfile, _$identity);

  /// Serializes this ProjectTypographyMetricsProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTypographyMetricsProfile&&(identical(other.sizeScale, sizeScale) || other.sizeScale == sizeScale)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.lineHeight, lineHeight) || other.lineHeight == lineHeight)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sizeScale,weight,lineHeight,letterSpacing);

@override
String toString() {
  return 'ProjectTypographyMetricsProfile(sizeScale: $sizeScale, weight: $weight, lineHeight: $lineHeight, letterSpacing: $letterSpacing)';
}


}

/// @nodoc
abstract mixin class $ProjectTypographyMetricsProfileCopyWith<$Res>  {
  factory $ProjectTypographyMetricsProfileCopyWith(ProjectTypographyMetricsProfile value, $Res Function(ProjectTypographyMetricsProfile) _then) = _$ProjectTypographyMetricsProfileCopyWithImpl;
@useResult
$Res call({
 double sizeScale, int weight, double lineHeight, double letterSpacing
});




}
/// @nodoc
class _$ProjectTypographyMetricsProfileCopyWithImpl<$Res>
    implements $ProjectTypographyMetricsProfileCopyWith<$Res> {
  _$ProjectTypographyMetricsProfileCopyWithImpl(this._self, this._then);

  final ProjectTypographyMetricsProfile _self;
  final $Res Function(ProjectTypographyMetricsProfile) _then;

/// Create a copy of ProjectTypographyMetricsProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sizeScale = null,Object? weight = null,Object? lineHeight = null,Object? letterSpacing = null,}) {
  return _then(_self.copyWith(
sizeScale: null == sizeScale ? _self.sizeScale : sizeScale // ignore: cast_nullable_to_non_nullable
as double,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,lineHeight: null == lineHeight ? _self.lineHeight : lineHeight // ignore: cast_nullable_to_non_nullable
as double,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTypographyMetricsProfile].
extension ProjectTypographyMetricsProfilePatterns on ProjectTypographyMetricsProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTypographyMetricsProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTypographyMetricsProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTypographyMetricsProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTypographyMetricsProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTypographyMetricsProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTypographyMetricsProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double sizeScale,  int weight,  double lineHeight,  double letterSpacing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTypographyMetricsProfile() when $default != null:
return $default(_that.sizeScale,_that.weight,_that.lineHeight,_that.letterSpacing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double sizeScale,  int weight,  double lineHeight,  double letterSpacing)  $default,) {final _that = this;
switch (_that) {
case _ProjectTypographyMetricsProfile():
return $default(_that.sizeScale,_that.weight,_that.lineHeight,_that.letterSpacing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double sizeScale,  int weight,  double lineHeight,  double letterSpacing)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTypographyMetricsProfile() when $default != null:
return $default(_that.sizeScale,_that.weight,_that.lineHeight,_that.letterSpacing);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectTypographyMetricsProfile implements ProjectTypographyMetricsProfile {
  const _ProjectTypographyMetricsProfile({this.sizeScale = 1, this.weight = 400, this.lineHeight = 1.25, this.letterSpacing = 0});
  factory _ProjectTypographyMetricsProfile.fromJson(Map<String, dynamic> json) => _$ProjectTypographyMetricsProfileFromJson(json);

@override@JsonKey() final  double sizeScale;
@override@JsonKey() final  int weight;
@override@JsonKey() final  double lineHeight;
@override@JsonKey() final  double letterSpacing;

/// Create a copy of ProjectTypographyMetricsProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTypographyMetricsProfileCopyWith<_ProjectTypographyMetricsProfile> get copyWith => __$ProjectTypographyMetricsProfileCopyWithImpl<_ProjectTypographyMetricsProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTypographyMetricsProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTypographyMetricsProfile&&(identical(other.sizeScale, sizeScale) || other.sizeScale == sizeScale)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.lineHeight, lineHeight) || other.lineHeight == lineHeight)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sizeScale,weight,lineHeight,letterSpacing);

@override
String toString() {
  return 'ProjectTypographyMetricsProfile(sizeScale: $sizeScale, weight: $weight, lineHeight: $lineHeight, letterSpacing: $letterSpacing)';
}


}

/// @nodoc
abstract mixin class _$ProjectTypographyMetricsProfileCopyWith<$Res> implements $ProjectTypographyMetricsProfileCopyWith<$Res> {
  factory _$ProjectTypographyMetricsProfileCopyWith(_ProjectTypographyMetricsProfile value, $Res Function(_ProjectTypographyMetricsProfile) _then) = __$ProjectTypographyMetricsProfileCopyWithImpl;
@override @useResult
$Res call({
 double sizeScale, int weight, double lineHeight, double letterSpacing
});




}
/// @nodoc
class __$ProjectTypographyMetricsProfileCopyWithImpl<$Res>
    implements _$ProjectTypographyMetricsProfileCopyWith<$Res> {
  __$ProjectTypographyMetricsProfileCopyWithImpl(this._self, this._then);

  final _ProjectTypographyMetricsProfile _self;
  final $Res Function(_ProjectTypographyMetricsProfile) _then;

/// Create a copy of ProjectTypographyMetricsProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sizeScale = null,Object? weight = null,Object? lineHeight = null,Object? letterSpacing = null,}) {
  return _then(_ProjectTypographyMetricsProfile(
sizeScale: null == sizeScale ? _self.sizeScale : sizeScale // ignore: cast_nullable_to_non_nullable
as double,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,lineHeight: null == lineHeight ? _self.lineHeight : lineHeight // ignore: cast_nullable_to_non_nullable
as double,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ProjectSurfacePaletteProfile {

@JsonKey(includeIfNull: false) String? get background;@JsonKey(includeIfNull: false) String? get surface;@JsonKey(includeIfNull: false) String? get border;@JsonKey(includeIfNull: false) String? get text;@JsonKey(includeIfNull: false) String? get accent;@JsonKey(includeIfNull: false) String? get selection;
/// Create a copy of ProjectSurfacePaletteProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<ProjectSurfacePaletteProfile> get copyWith => _$ProjectSurfacePaletteProfileCopyWithImpl<ProjectSurfacePaletteProfile>(this as ProjectSurfacePaletteProfile, _$identity);

  /// Serializes this ProjectSurfacePaletteProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSurfacePaletteProfile&&(identical(other.background, background) || other.background == background)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.border, border) || other.border == border)&&(identical(other.text, text) || other.text == text)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.selection, selection) || other.selection == selection));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,background,surface,border,text,accent,selection);

@override
String toString() {
  return 'ProjectSurfacePaletteProfile(background: $background, surface: $surface, border: $border, text: $text, accent: $accent, selection: $selection)';
}


}

/// @nodoc
abstract mixin class $ProjectSurfacePaletteProfileCopyWith<$Res>  {
  factory $ProjectSurfacePaletteProfileCopyWith(ProjectSurfacePaletteProfile value, $Res Function(ProjectSurfacePaletteProfile) _then) = _$ProjectSurfacePaletteProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? background,@JsonKey(includeIfNull: false) String? surface,@JsonKey(includeIfNull: false) String? border,@JsonKey(includeIfNull: false) String? text,@JsonKey(includeIfNull: false) String? accent,@JsonKey(includeIfNull: false) String? selection
});




}
/// @nodoc
class _$ProjectSurfacePaletteProfileCopyWithImpl<$Res>
    implements $ProjectSurfacePaletteProfileCopyWith<$Res> {
  _$ProjectSurfacePaletteProfileCopyWithImpl(this._self, this._then);

  final ProjectSurfacePaletteProfile _self;
  final $Res Function(ProjectSurfacePaletteProfile) _then;

/// Create a copy of ProjectSurfacePaletteProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? background = freezed,Object? surface = freezed,Object? border = freezed,Object? text = freezed,Object? accent = freezed,Object? selection = freezed,}) {
  return _then(_self.copyWith(
background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,surface: freezed == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String?,border: freezed == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,accent: freezed == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as String?,selection: freezed == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSurfacePaletteProfile].
extension ProjectSurfacePaletteProfilePatterns on ProjectSurfacePaletteProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSurfacePaletteProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSurfacePaletteProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSurfacePaletteProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSurfacePaletteProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSurfacePaletteProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSurfacePaletteProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? background, @JsonKey(includeIfNull: false)  String? surface, @JsonKey(includeIfNull: false)  String? border, @JsonKey(includeIfNull: false)  String? text, @JsonKey(includeIfNull: false)  String? accent, @JsonKey(includeIfNull: false)  String? selection)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSurfacePaletteProfile() when $default != null:
return $default(_that.background,_that.surface,_that.border,_that.text,_that.accent,_that.selection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? background, @JsonKey(includeIfNull: false)  String? surface, @JsonKey(includeIfNull: false)  String? border, @JsonKey(includeIfNull: false)  String? text, @JsonKey(includeIfNull: false)  String? accent, @JsonKey(includeIfNull: false)  String? selection)  $default,) {final _that = this;
switch (_that) {
case _ProjectSurfacePaletteProfile():
return $default(_that.background,_that.surface,_that.border,_that.text,_that.accent,_that.selection);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? background, @JsonKey(includeIfNull: false)  String? surface, @JsonKey(includeIfNull: false)  String? border, @JsonKey(includeIfNull: false)  String? text, @JsonKey(includeIfNull: false)  String? accent, @JsonKey(includeIfNull: false)  String? selection)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSurfacePaletteProfile() when $default != null:
return $default(_that.background,_that.surface,_that.border,_that.text,_that.accent,_that.selection);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSurfacePaletteProfile implements ProjectSurfacePaletteProfile {
  const _ProjectSurfacePaletteProfile({@JsonKey(includeIfNull: false) this.background, @JsonKey(includeIfNull: false) this.surface, @JsonKey(includeIfNull: false) this.border, @JsonKey(includeIfNull: false) this.text, @JsonKey(includeIfNull: false) this.accent, @JsonKey(includeIfNull: false) this.selection});
  factory _ProjectSurfacePaletteProfile.fromJson(Map<String, dynamic> json) => _$ProjectSurfacePaletteProfileFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? background;
@override@JsonKey(includeIfNull: false) final  String? surface;
@override@JsonKey(includeIfNull: false) final  String? border;
@override@JsonKey(includeIfNull: false) final  String? text;
@override@JsonKey(includeIfNull: false) final  String? accent;
@override@JsonKey(includeIfNull: false) final  String? selection;

/// Create a copy of ProjectSurfacePaletteProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSurfacePaletteProfileCopyWith<_ProjectSurfacePaletteProfile> get copyWith => __$ProjectSurfacePaletteProfileCopyWithImpl<_ProjectSurfacePaletteProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSurfacePaletteProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSurfacePaletteProfile&&(identical(other.background, background) || other.background == background)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.border, border) || other.border == border)&&(identical(other.text, text) || other.text == text)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.selection, selection) || other.selection == selection));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,background,surface,border,text,accent,selection);

@override
String toString() {
  return 'ProjectSurfacePaletteProfile(background: $background, surface: $surface, border: $border, text: $text, accent: $accent, selection: $selection)';
}


}

/// @nodoc
abstract mixin class _$ProjectSurfacePaletteProfileCopyWith<$Res> implements $ProjectSurfacePaletteProfileCopyWith<$Res> {
  factory _$ProjectSurfacePaletteProfileCopyWith(_ProjectSurfacePaletteProfile value, $Res Function(_ProjectSurfacePaletteProfile) _then) = __$ProjectSurfacePaletteProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? background,@JsonKey(includeIfNull: false) String? surface,@JsonKey(includeIfNull: false) String? border,@JsonKey(includeIfNull: false) String? text,@JsonKey(includeIfNull: false) String? accent,@JsonKey(includeIfNull: false) String? selection
});




}
/// @nodoc
class __$ProjectSurfacePaletteProfileCopyWithImpl<$Res>
    implements _$ProjectSurfacePaletteProfileCopyWith<$Res> {
  __$ProjectSurfacePaletteProfileCopyWithImpl(this._self, this._then);

  final _ProjectSurfacePaletteProfile _self;
  final $Res Function(_ProjectSurfacePaletteProfile) _then;

/// Create a copy of ProjectSurfacePaletteProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? background = freezed,Object? surface = freezed,Object? border = freezed,Object? text = freezed,Object? accent = freezed,Object? selection = freezed,}) {
  return _then(_ProjectSurfacePaletteProfile(
background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,surface: freezed == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String?,border: freezed == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,accent: freezed == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as String?,selection: freezed == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProjectPresentationSurfacePalettesProfile {

@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? get title;@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? get pauseMenu;@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? get dialogue;@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? get battle;
/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectPresentationSurfacePalettesProfileCopyWith<ProjectPresentationSurfacePalettesProfile> get copyWith => _$ProjectPresentationSurfacePalettesProfileCopyWithImpl<ProjectPresentationSurfacePalettesProfile>(this as ProjectPresentationSurfacePalettesProfile, _$identity);

  /// Serializes this ProjectPresentationSurfacePalettesProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectPresentationSurfacePalettesProfile&&(identical(other.title, title) || other.title == title)&&(identical(other.pauseMenu, pauseMenu) || other.pauseMenu == pauseMenu)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.battle, battle) || other.battle == battle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,pauseMenu,dialogue,battle);

@override
String toString() {
  return 'ProjectPresentationSurfacePalettesProfile(title: $title, pauseMenu: $pauseMenu, dialogue: $dialogue, battle: $battle)';
}


}

/// @nodoc
abstract mixin class $ProjectPresentationSurfacePalettesProfileCopyWith<$Res>  {
  factory $ProjectPresentationSurfacePalettesProfileCopyWith(ProjectPresentationSurfacePalettesProfile value, $Res Function(ProjectPresentationSurfacePalettesProfile) _then) = _$ProjectPresentationSurfacePalettesProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? title,@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? pauseMenu,@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? dialogue,@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? battle
});


$ProjectSurfacePaletteProfileCopyWith<$Res>? get title;$ProjectSurfacePaletteProfileCopyWith<$Res>? get pauseMenu;$ProjectSurfacePaletteProfileCopyWith<$Res>? get dialogue;$ProjectSurfacePaletteProfileCopyWith<$Res>? get battle;

}
/// @nodoc
class _$ProjectPresentationSurfacePalettesProfileCopyWithImpl<$Res>
    implements $ProjectPresentationSurfacePalettesProfileCopyWith<$Res> {
  _$ProjectPresentationSurfacePalettesProfileCopyWithImpl(this._self, this._then);

  final ProjectPresentationSurfacePalettesProfile _self;
  final $Res Function(ProjectPresentationSurfacePalettesProfile) _then;

/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? pauseMenu = freezed,Object? dialogue = freezed,Object? battle = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as ProjectSurfacePaletteProfile?,pauseMenu: freezed == pauseMenu ? _self.pauseMenu : pauseMenu // ignore: cast_nullable_to_non_nullable
as ProjectSurfacePaletteProfile?,dialogue: freezed == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as ProjectSurfacePaletteProfile?,battle: freezed == battle ? _self.battle : battle // ignore: cast_nullable_to_non_nullable
as ProjectSurfacePaletteProfile?,
  ));
}
/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<$Res>? get title {
    if (_self.title == null) {
    return null;
  }

  return $ProjectSurfacePaletteProfileCopyWith<$Res>(_self.title!, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<$Res>? get pauseMenu {
    if (_self.pauseMenu == null) {
    return null;
  }

  return $ProjectSurfacePaletteProfileCopyWith<$Res>(_self.pauseMenu!, (value) {
    return _then(_self.copyWith(pauseMenu: value));
  });
}/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
    return null;
  }

  return $ProjectSurfacePaletteProfileCopyWith<$Res>(_self.dialogue!, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<$Res>? get battle {
    if (_self.battle == null) {
    return null;
  }

  return $ProjectSurfacePaletteProfileCopyWith<$Res>(_self.battle!, (value) {
    return _then(_self.copyWith(battle: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectPresentationSurfacePalettesProfile].
extension ProjectPresentationSurfacePalettesProfilePatterns on ProjectPresentationSurfacePalettesProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectPresentationSurfacePalettesProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectPresentationSurfacePalettesProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectPresentationSurfacePalettesProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationSurfacePalettesProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectPresentationSurfacePalettesProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationSurfacePalettesProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? title, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? pauseMenu, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? dialogue, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? battle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectPresentationSurfacePalettesProfile() when $default != null:
return $default(_that.title,_that.pauseMenu,_that.dialogue,_that.battle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? title, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? pauseMenu, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? dialogue, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? battle)  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationSurfacePalettesProfile():
return $default(_that.title,_that.pauseMenu,_that.dialogue,_that.battle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? title, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? pauseMenu, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? dialogue, @JsonKey(includeIfNull: false)  ProjectSurfacePaletteProfile? battle)?  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationSurfacePalettesProfile() when $default != null:
return $default(_that.title,_that.pauseMenu,_that.dialogue,_that.battle);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectPresentationSurfacePalettesProfile extends ProjectPresentationSurfacePalettesProfile {
  const _ProjectPresentationSurfacePalettesProfile({@JsonKey(includeIfNull: false) this.title, @JsonKey(includeIfNull: false) this.pauseMenu, @JsonKey(includeIfNull: false) this.dialogue, @JsonKey(includeIfNull: false) this.battle}): super._();
  factory _ProjectPresentationSurfacePalettesProfile.fromJson(Map<String, dynamic> json) => _$ProjectPresentationSurfacePalettesProfileFromJson(json);

@override@JsonKey(includeIfNull: false) final  ProjectSurfacePaletteProfile? title;
@override@JsonKey(includeIfNull: false) final  ProjectSurfacePaletteProfile? pauseMenu;
@override@JsonKey(includeIfNull: false) final  ProjectSurfacePaletteProfile? dialogue;
@override@JsonKey(includeIfNull: false) final  ProjectSurfacePaletteProfile? battle;

/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectPresentationSurfacePalettesProfileCopyWith<_ProjectPresentationSurfacePalettesProfile> get copyWith => __$ProjectPresentationSurfacePalettesProfileCopyWithImpl<_ProjectPresentationSurfacePalettesProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectPresentationSurfacePalettesProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectPresentationSurfacePalettesProfile&&(identical(other.title, title) || other.title == title)&&(identical(other.pauseMenu, pauseMenu) || other.pauseMenu == pauseMenu)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.battle, battle) || other.battle == battle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,pauseMenu,dialogue,battle);

@override
String toString() {
  return 'ProjectPresentationSurfacePalettesProfile(title: $title, pauseMenu: $pauseMenu, dialogue: $dialogue, battle: $battle)';
}


}

/// @nodoc
abstract mixin class _$ProjectPresentationSurfacePalettesProfileCopyWith<$Res> implements $ProjectPresentationSurfacePalettesProfileCopyWith<$Res> {
  factory _$ProjectPresentationSurfacePalettesProfileCopyWith(_ProjectPresentationSurfacePalettesProfile value, $Res Function(_ProjectPresentationSurfacePalettesProfile) _then) = __$ProjectPresentationSurfacePalettesProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? title,@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? pauseMenu,@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? dialogue,@JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? battle
});


@override $ProjectSurfacePaletteProfileCopyWith<$Res>? get title;@override $ProjectSurfacePaletteProfileCopyWith<$Res>? get pauseMenu;@override $ProjectSurfacePaletteProfileCopyWith<$Res>? get dialogue;@override $ProjectSurfacePaletteProfileCopyWith<$Res>? get battle;

}
/// @nodoc
class __$ProjectPresentationSurfacePalettesProfileCopyWithImpl<$Res>
    implements _$ProjectPresentationSurfacePalettesProfileCopyWith<$Res> {
  __$ProjectPresentationSurfacePalettesProfileCopyWithImpl(this._self, this._then);

  final _ProjectPresentationSurfacePalettesProfile _self;
  final $Res Function(_ProjectPresentationSurfacePalettesProfile) _then;

/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? pauseMenu = freezed,Object? dialogue = freezed,Object? battle = freezed,}) {
  return _then(_ProjectPresentationSurfacePalettesProfile(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as ProjectSurfacePaletteProfile?,pauseMenu: freezed == pauseMenu ? _self.pauseMenu : pauseMenu // ignore: cast_nullable_to_non_nullable
as ProjectSurfacePaletteProfile?,dialogue: freezed == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as ProjectSurfacePaletteProfile?,battle: freezed == battle ? _self.battle : battle // ignore: cast_nullable_to_non_nullable
as ProjectSurfacePaletteProfile?,
  ));
}

/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<$Res>? get title {
    if (_self.title == null) {
    return null;
  }

  return $ProjectSurfacePaletteProfileCopyWith<$Res>(_self.title!, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<$Res>? get pauseMenu {
    if (_self.pauseMenu == null) {
    return null;
  }

  return $ProjectSurfacePaletteProfileCopyWith<$Res>(_self.pauseMenu!, (value) {
    return _then(_self.copyWith(pauseMenu: value));
  });
}/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
    return null;
  }

  return $ProjectSurfacePaletteProfileCopyWith<$Res>(_self.dialogue!, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}/// Create a copy of ProjectPresentationSurfacePalettesProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfacePaletteProfileCopyWith<$Res>? get battle {
    if (_self.battle == null) {
    return null;
  }

  return $ProjectSurfacePaletteProfileCopyWith<$Res>(_self.battle!, (value) {
    return _then(_self.copyWith(battle: value));
  });
}
}

// dart format on
