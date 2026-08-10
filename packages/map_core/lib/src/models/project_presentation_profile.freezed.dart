// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_presentation_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectPresentationDiagnostic {

 String get code; ProjectPresentationCategory get category; ProjectPresentationDiagnosticSeverity get severity; String get path; String get message;
/// Create a copy of ProjectPresentationDiagnostic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectPresentationDiagnosticCopyWith<ProjectPresentationDiagnostic> get copyWith => _$ProjectPresentationDiagnosticCopyWithImpl<ProjectPresentationDiagnostic>(this as ProjectPresentationDiagnostic, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectPresentationDiagnostic&&(identical(other.code, code) || other.code == code)&&(identical(other.category, category) || other.category == category)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.path, path) || other.path == path)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,code,category,severity,path,message);

@override
String toString() {
  return 'ProjectPresentationDiagnostic(code: $code, category: $category, severity: $severity, path: $path, message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectPresentationDiagnosticCopyWith<$Res>  {
  factory $ProjectPresentationDiagnosticCopyWith(ProjectPresentationDiagnostic value, $Res Function(ProjectPresentationDiagnostic) _then) = _$ProjectPresentationDiagnosticCopyWithImpl;
@useResult
$Res call({
 String code, ProjectPresentationCategory category, ProjectPresentationDiagnosticSeverity severity, String path, String message
});




}
/// @nodoc
class _$ProjectPresentationDiagnosticCopyWithImpl<$Res>
    implements $ProjectPresentationDiagnosticCopyWith<$Res> {
  _$ProjectPresentationDiagnosticCopyWithImpl(this._self, this._then);

  final ProjectPresentationDiagnostic _self;
  final $Res Function(ProjectPresentationDiagnostic) _then;

/// Create a copy of ProjectPresentationDiagnostic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? category = null,Object? severity = null,Object? path = null,Object? message = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProjectPresentationCategory,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as ProjectPresentationDiagnosticSeverity,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectPresentationDiagnostic].
extension ProjectPresentationDiagnosticPatterns on ProjectPresentationDiagnostic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectPresentationDiagnostic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectPresentationDiagnostic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectPresentationDiagnostic value)  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationDiagnostic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectPresentationDiagnostic value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationDiagnostic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  ProjectPresentationCategory category,  ProjectPresentationDiagnosticSeverity severity,  String path,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectPresentationDiagnostic() when $default != null:
return $default(_that.code,_that.category,_that.severity,_that.path,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  ProjectPresentationCategory category,  ProjectPresentationDiagnosticSeverity severity,  String path,  String message)  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationDiagnostic():
return $default(_that.code,_that.category,_that.severity,_that.path,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  ProjectPresentationCategory category,  ProjectPresentationDiagnosticSeverity severity,  String path,  String message)?  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationDiagnostic() when $default != null:
return $default(_that.code,_that.category,_that.severity,_that.path,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _ProjectPresentationDiagnostic implements ProjectPresentationDiagnostic {
  const _ProjectPresentationDiagnostic({required this.code, required this.category, required this.severity, required this.path, required this.message});


@override final  String code;
@override final  ProjectPresentationCategory category;
@override final  ProjectPresentationDiagnosticSeverity severity;
@override final  String path;
@override final  String message;

/// Create a copy of ProjectPresentationDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectPresentationDiagnosticCopyWith<_ProjectPresentationDiagnostic> get copyWith => __$ProjectPresentationDiagnosticCopyWithImpl<_ProjectPresentationDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectPresentationDiagnostic&&(identical(other.code, code) || other.code == code)&&(identical(other.category, category) || other.category == category)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.path, path) || other.path == path)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,code,category,severity,path,message);

@override
String toString() {
  return 'ProjectPresentationDiagnostic(code: $code, category: $category, severity: $severity, path: $path, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ProjectPresentationDiagnosticCopyWith<$Res> implements $ProjectPresentationDiagnosticCopyWith<$Res> {
  factory _$ProjectPresentationDiagnosticCopyWith(_ProjectPresentationDiagnostic value, $Res Function(_ProjectPresentationDiagnostic) _then) = __$ProjectPresentationDiagnosticCopyWithImpl;
@override @useResult
$Res call({
 String code, ProjectPresentationCategory category, ProjectPresentationDiagnosticSeverity severity, String path, String message
});




}
/// @nodoc
class __$ProjectPresentationDiagnosticCopyWithImpl<$Res>
    implements _$ProjectPresentationDiagnosticCopyWith<$Res> {
  __$ProjectPresentationDiagnosticCopyWithImpl(this._self, this._then);

  final _ProjectPresentationDiagnostic _self;
  final $Res Function(_ProjectPresentationDiagnostic) _then;

/// Create a copy of ProjectPresentationDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? category = null,Object? severity = null,Object? path = null,Object? message = null,}) {
  return _then(_ProjectPresentationDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProjectPresentationCategory,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as ProjectPresentationDiagnosticSeverity,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProjectBrandingProfile {

@JsonKey(includeIfNull: false) String? get iconPath;@JsonKey(includeIfNull: false) String? get coverPath;@JsonKey(includeIfNull: false) String? get heroPath;@JsonKey(includeIfNull: false) String? get accentColor;@JsonKey(includeIfNull: false) String? get titleMusicPath; String get layoutVariant;
/// Create a copy of ProjectBrandingProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectBrandingProfileCopyWith<ProjectBrandingProfile> get copyWith => _$ProjectBrandingProfileCopyWithImpl<ProjectBrandingProfile>(this as ProjectBrandingProfile, _$identity);

  /// Serializes this ProjectBrandingProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectBrandingProfile&&(identical(other.iconPath, iconPath) || other.iconPath == iconPath)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&(identical(other.heroPath, heroPath) || other.heroPath == heroPath)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.titleMusicPath, titleMusicPath) || other.titleMusicPath == titleMusicPath)&&(identical(other.layoutVariant, layoutVariant) || other.layoutVariant == layoutVariant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,iconPath,coverPath,heroPath,accentColor,titleMusicPath,layoutVariant);

@override
String toString() {
  return 'ProjectBrandingProfile(iconPath: $iconPath, coverPath: $coverPath, heroPath: $heroPath, accentColor: $accentColor, titleMusicPath: $titleMusicPath, layoutVariant: $layoutVariant)';
}


}

/// @nodoc
abstract mixin class $ProjectBrandingProfileCopyWith<$Res>  {
  factory $ProjectBrandingProfileCopyWith(ProjectBrandingProfile value, $Res Function(ProjectBrandingProfile) _then) = _$ProjectBrandingProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? iconPath,@JsonKey(includeIfNull: false) String? coverPath,@JsonKey(includeIfNull: false) String? heroPath,@JsonKey(includeIfNull: false) String? accentColor,@JsonKey(includeIfNull: false) String? titleMusicPath, String layoutVariant
});




}
/// @nodoc
class _$ProjectBrandingProfileCopyWithImpl<$Res>
    implements $ProjectBrandingProfileCopyWith<$Res> {
  _$ProjectBrandingProfileCopyWithImpl(this._self, this._then);

  final ProjectBrandingProfile _self;
  final $Res Function(ProjectBrandingProfile) _then;

/// Create a copy of ProjectBrandingProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? iconPath = freezed,Object? coverPath = freezed,Object? heroPath = freezed,Object? accentColor = freezed,Object? titleMusicPath = freezed,Object? layoutVariant = null,}) {
  return _then(_self.copyWith(
iconPath: freezed == iconPath ? _self.iconPath : iconPath // ignore: cast_nullable_to_non_nullable
as String?,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,heroPath: freezed == heroPath ? _self.heroPath : heroPath // ignore: cast_nullable_to_non_nullable
as String?,accentColor: freezed == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as String?,titleMusicPath: freezed == titleMusicPath ? _self.titleMusicPath : titleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,layoutVariant: null == layoutVariant ? _self.layoutVariant : layoutVariant // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectBrandingProfile].
extension ProjectBrandingProfilePatterns on ProjectBrandingProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectBrandingProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectBrandingProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectBrandingProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectBrandingProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectBrandingProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectBrandingProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? iconPath, @JsonKey(includeIfNull: false)  String? coverPath, @JsonKey(includeIfNull: false)  String? heroPath, @JsonKey(includeIfNull: false)  String? accentColor, @JsonKey(includeIfNull: false)  String? titleMusicPath,  String layoutVariant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectBrandingProfile() when $default != null:
return $default(_that.iconPath,_that.coverPath,_that.heroPath,_that.accentColor,_that.titleMusicPath,_that.layoutVariant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? iconPath, @JsonKey(includeIfNull: false)  String? coverPath, @JsonKey(includeIfNull: false)  String? heroPath, @JsonKey(includeIfNull: false)  String? accentColor, @JsonKey(includeIfNull: false)  String? titleMusicPath,  String layoutVariant)  $default,) {final _that = this;
switch (_that) {
case _ProjectBrandingProfile():
return $default(_that.iconPath,_that.coverPath,_that.heroPath,_that.accentColor,_that.titleMusicPath,_that.layoutVariant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? iconPath, @JsonKey(includeIfNull: false)  String? coverPath, @JsonKey(includeIfNull: false)  String? heroPath, @JsonKey(includeIfNull: false)  String? accentColor, @JsonKey(includeIfNull: false)  String? titleMusicPath,  String layoutVariant)?  $default,) {final _that = this;
switch (_that) {
case _ProjectBrandingProfile() when $default != null:
return $default(_that.iconPath,_that.coverPath,_that.heroPath,_that.accentColor,_that.titleMusicPath,_that.layoutVariant);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectBrandingProfile implements ProjectBrandingProfile {
  const _ProjectBrandingProfile({@JsonKey(includeIfNull: false) this.iconPath, @JsonKey(includeIfNull: false) this.coverPath, @JsonKey(includeIfNull: false) this.heroPath, @JsonKey(includeIfNull: false) this.accentColor, @JsonKey(includeIfNull: false) this.titleMusicPath, this.layoutVariant = 'standard'});
  factory _ProjectBrandingProfile.fromJson(Map<String, dynamic> json) => _$ProjectBrandingProfileFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? iconPath;
@override@JsonKey(includeIfNull: false) final  String? coverPath;
@override@JsonKey(includeIfNull: false) final  String? heroPath;
@override@JsonKey(includeIfNull: false) final  String? accentColor;
@override@JsonKey(includeIfNull: false) final  String? titleMusicPath;
@override@JsonKey() final  String layoutVariant;

/// Create a copy of ProjectBrandingProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectBrandingProfileCopyWith<_ProjectBrandingProfile> get copyWith => __$ProjectBrandingProfileCopyWithImpl<_ProjectBrandingProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectBrandingProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectBrandingProfile&&(identical(other.iconPath, iconPath) || other.iconPath == iconPath)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&(identical(other.heroPath, heroPath) || other.heroPath == heroPath)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.titleMusicPath, titleMusicPath) || other.titleMusicPath == titleMusicPath)&&(identical(other.layoutVariant, layoutVariant) || other.layoutVariant == layoutVariant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,iconPath,coverPath,heroPath,accentColor,titleMusicPath,layoutVariant);

@override
String toString() {
  return 'ProjectBrandingProfile(iconPath: $iconPath, coverPath: $coverPath, heroPath: $heroPath, accentColor: $accentColor, titleMusicPath: $titleMusicPath, layoutVariant: $layoutVariant)';
}


}

/// @nodoc
abstract mixin class _$ProjectBrandingProfileCopyWith<$Res> implements $ProjectBrandingProfileCopyWith<$Res> {
  factory _$ProjectBrandingProfileCopyWith(_ProjectBrandingProfile value, $Res Function(_ProjectBrandingProfile) _then) = __$ProjectBrandingProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? iconPath,@JsonKey(includeIfNull: false) String? coverPath,@JsonKey(includeIfNull: false) String? heroPath,@JsonKey(includeIfNull: false) String? accentColor,@JsonKey(includeIfNull: false) String? titleMusicPath, String layoutVariant
});




}
/// @nodoc
class __$ProjectBrandingProfileCopyWithImpl<$Res>
    implements _$ProjectBrandingProfileCopyWith<$Res> {
  __$ProjectBrandingProfileCopyWithImpl(this._self, this._then);

  final _ProjectBrandingProfile _self;
  final $Res Function(_ProjectBrandingProfile) _then;

/// Create a copy of ProjectBrandingProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? iconPath = freezed,Object? coverPath = freezed,Object? heroPath = freezed,Object? accentColor = freezed,Object? titleMusicPath = freezed,Object? layoutVariant = null,}) {
  return _then(_ProjectBrandingProfile(
iconPath: freezed == iconPath ? _self.iconPath : iconPath // ignore: cast_nullable_to_non_nullable
as String?,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,heroPath: freezed == heroPath ? _self.heroPath : heroPath // ignore: cast_nullable_to_non_nullable
as String?,accentColor: freezed == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as String?,titleMusicPath: freezed == titleMusicPath ? _self.titleMusicPath : titleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,layoutVariant: null == layoutVariant ? _self.layoutVariant : layoutVariant // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProjectVideoVariantProfile {

 String get videoPath; String get posterPath;@JsonKey(includeIfNull: false) String? get captionsPath; int get durationMilliseconds; int get width; int get height; int get bitrateKbps; int get sizeBytes; String get videoCodec; String get audioCodec; double get focalX; double get focalY;
/// Create a copy of ProjectVideoVariantProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectVideoVariantProfileCopyWith<ProjectVideoVariantProfile> get copyWith => _$ProjectVideoVariantProfileCopyWithImpl<ProjectVideoVariantProfile>(this as ProjectVideoVariantProfile, _$identity);

  /// Serializes this ProjectVideoVariantProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectVideoVariantProfile&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.captionsPath, captionsPath) || other.captionsPath == captionsPath)&&(identical(other.durationMilliseconds, durationMilliseconds) || other.durationMilliseconds == durationMilliseconds)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.bitrateKbps, bitrateKbps) || other.bitrateKbps == bitrateKbps)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.videoCodec, videoCodec) || other.videoCodec == videoCodec)&&(identical(other.audioCodec, audioCodec) || other.audioCodec == audioCodec)&&(identical(other.focalX, focalX) || other.focalX == focalX)&&(identical(other.focalY, focalY) || other.focalY == focalY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,videoPath,posterPath,captionsPath,durationMilliseconds,width,height,bitrateKbps,sizeBytes,videoCodec,audioCodec,focalX,focalY);

@override
String toString() {
  return 'ProjectVideoVariantProfile(videoPath: $videoPath, posterPath: $posterPath, captionsPath: $captionsPath, durationMilliseconds: $durationMilliseconds, width: $width, height: $height, bitrateKbps: $bitrateKbps, sizeBytes: $sizeBytes, videoCodec: $videoCodec, audioCodec: $audioCodec, focalX: $focalX, focalY: $focalY)';
}


}

/// @nodoc
abstract mixin class $ProjectVideoVariantProfileCopyWith<$Res>  {
  factory $ProjectVideoVariantProfileCopyWith(ProjectVideoVariantProfile value, $Res Function(ProjectVideoVariantProfile) _then) = _$ProjectVideoVariantProfileCopyWithImpl;
@useResult
$Res call({
 String videoPath, String posterPath,@JsonKey(includeIfNull: false) String? captionsPath, int durationMilliseconds, int width, int height, int bitrateKbps, int sizeBytes, String videoCodec, String audioCodec, double focalX, double focalY
});




}
/// @nodoc
class _$ProjectVideoVariantProfileCopyWithImpl<$Res>
    implements $ProjectVideoVariantProfileCopyWith<$Res> {
  _$ProjectVideoVariantProfileCopyWithImpl(this._self, this._then);

  final ProjectVideoVariantProfile _self;
  final $Res Function(ProjectVideoVariantProfile) _then;

/// Create a copy of ProjectVideoVariantProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoPath = null,Object? posterPath = null,Object? captionsPath = freezed,Object? durationMilliseconds = null,Object? width = null,Object? height = null,Object? bitrateKbps = null,Object? sizeBytes = null,Object? videoCodec = null,Object? audioCodec = null,Object? focalX = null,Object? focalY = null,}) {
  return _then(_self.copyWith(
videoPath: null == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String,posterPath: null == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String,captionsPath: freezed == captionsPath ? _self.captionsPath : captionsPath // ignore: cast_nullable_to_non_nullable
as String?,durationMilliseconds: null == durationMilliseconds ? _self.durationMilliseconds : durationMilliseconds // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,bitrateKbps: null == bitrateKbps ? _self.bitrateKbps : bitrateKbps // ignore: cast_nullable_to_non_nullable
as int,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,videoCodec: null == videoCodec ? _self.videoCodec : videoCodec // ignore: cast_nullable_to_non_nullable
as String,audioCodec: null == audioCodec ? _self.audioCodec : audioCodec // ignore: cast_nullable_to_non_nullable
as String,focalX: null == focalX ? _self.focalX : focalX // ignore: cast_nullable_to_non_nullable
as double,focalY: null == focalY ? _self.focalY : focalY // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectVideoVariantProfile].
extension ProjectVideoVariantProfilePatterns on ProjectVideoVariantProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectVideoVariantProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectVideoVariantProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectVideoVariantProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectVideoVariantProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectVideoVariantProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectVideoVariantProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String videoPath,  String posterPath, @JsonKey(includeIfNull: false)  String? captionsPath,  int durationMilliseconds,  int width,  int height,  int bitrateKbps,  int sizeBytes,  String videoCodec,  String audioCodec,  double focalX,  double focalY)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectVideoVariantProfile() when $default != null:
return $default(_that.videoPath,_that.posterPath,_that.captionsPath,_that.durationMilliseconds,_that.width,_that.height,_that.bitrateKbps,_that.sizeBytes,_that.videoCodec,_that.audioCodec,_that.focalX,_that.focalY);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String videoPath,  String posterPath, @JsonKey(includeIfNull: false)  String? captionsPath,  int durationMilliseconds,  int width,  int height,  int bitrateKbps,  int sizeBytes,  String videoCodec,  String audioCodec,  double focalX,  double focalY)  $default,) {final _that = this;
switch (_that) {
case _ProjectVideoVariantProfile():
return $default(_that.videoPath,_that.posterPath,_that.captionsPath,_that.durationMilliseconds,_that.width,_that.height,_that.bitrateKbps,_that.sizeBytes,_that.videoCodec,_that.audioCodec,_that.focalX,_that.focalY);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String videoPath,  String posterPath, @JsonKey(includeIfNull: false)  String? captionsPath,  int durationMilliseconds,  int width,  int height,  int bitrateKbps,  int sizeBytes,  String videoCodec,  String audioCodec,  double focalX,  double focalY)?  $default,) {final _that = this;
switch (_that) {
case _ProjectVideoVariantProfile() when $default != null:
return $default(_that.videoPath,_that.posterPath,_that.captionsPath,_that.durationMilliseconds,_that.width,_that.height,_that.bitrateKbps,_that.sizeBytes,_that.videoCodec,_that.audioCodec,_that.focalX,_that.focalY);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectVideoVariantProfile implements ProjectVideoVariantProfile {
  const _ProjectVideoVariantProfile({required this.videoPath, required this.posterPath, @JsonKey(includeIfNull: false) this.captionsPath, required this.durationMilliseconds, required this.width, required this.height, required this.bitrateKbps, required this.sizeBytes, required this.videoCodec, this.audioCodec = 'none', this.focalX = 0.5, this.focalY = 0.5});
  factory _ProjectVideoVariantProfile.fromJson(Map<String, dynamic> json) => _$ProjectVideoVariantProfileFromJson(json);

@override final  String videoPath;
@override final  String posterPath;
@override@JsonKey(includeIfNull: false) final  String? captionsPath;
@override final  int durationMilliseconds;
@override final  int width;
@override final  int height;
@override final  int bitrateKbps;
@override final  int sizeBytes;
@override final  String videoCodec;
@override@JsonKey() final  String audioCodec;
@override@JsonKey() final  double focalX;
@override@JsonKey() final  double focalY;

/// Create a copy of ProjectVideoVariantProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectVideoVariantProfileCopyWith<_ProjectVideoVariantProfile> get copyWith => __$ProjectVideoVariantProfileCopyWithImpl<_ProjectVideoVariantProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectVideoVariantProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectVideoVariantProfile&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.captionsPath, captionsPath) || other.captionsPath == captionsPath)&&(identical(other.durationMilliseconds, durationMilliseconds) || other.durationMilliseconds == durationMilliseconds)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.bitrateKbps, bitrateKbps) || other.bitrateKbps == bitrateKbps)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.videoCodec, videoCodec) || other.videoCodec == videoCodec)&&(identical(other.audioCodec, audioCodec) || other.audioCodec == audioCodec)&&(identical(other.focalX, focalX) || other.focalX == focalX)&&(identical(other.focalY, focalY) || other.focalY == focalY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,videoPath,posterPath,captionsPath,durationMilliseconds,width,height,bitrateKbps,sizeBytes,videoCodec,audioCodec,focalX,focalY);

@override
String toString() {
  return 'ProjectVideoVariantProfile(videoPath: $videoPath, posterPath: $posterPath, captionsPath: $captionsPath, durationMilliseconds: $durationMilliseconds, width: $width, height: $height, bitrateKbps: $bitrateKbps, sizeBytes: $sizeBytes, videoCodec: $videoCodec, audioCodec: $audioCodec, focalX: $focalX, focalY: $focalY)';
}


}

/// @nodoc
abstract mixin class _$ProjectVideoVariantProfileCopyWith<$Res> implements $ProjectVideoVariantProfileCopyWith<$Res> {
  factory _$ProjectVideoVariantProfileCopyWith(_ProjectVideoVariantProfile value, $Res Function(_ProjectVideoVariantProfile) _then) = __$ProjectVideoVariantProfileCopyWithImpl;
@override @useResult
$Res call({
 String videoPath, String posterPath,@JsonKey(includeIfNull: false) String? captionsPath, int durationMilliseconds, int width, int height, int bitrateKbps, int sizeBytes, String videoCodec, String audioCodec, double focalX, double focalY
});




}
/// @nodoc
class __$ProjectVideoVariantProfileCopyWithImpl<$Res>
    implements _$ProjectVideoVariantProfileCopyWith<$Res> {
  __$ProjectVideoVariantProfileCopyWithImpl(this._self, this._then);

  final _ProjectVideoVariantProfile _self;
  final $Res Function(_ProjectVideoVariantProfile) _then;

/// Create a copy of ProjectVideoVariantProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoPath = null,Object? posterPath = null,Object? captionsPath = freezed,Object? durationMilliseconds = null,Object? width = null,Object? height = null,Object? bitrateKbps = null,Object? sizeBytes = null,Object? videoCodec = null,Object? audioCodec = null,Object? focalX = null,Object? focalY = null,}) {
  return _then(_ProjectVideoVariantProfile(
videoPath: null == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String,posterPath: null == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String,captionsPath: freezed == captionsPath ? _self.captionsPath : captionsPath // ignore: cast_nullable_to_non_nullable
as String?,durationMilliseconds: null == durationMilliseconds ? _self.durationMilliseconds : durationMilliseconds // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,bitrateKbps: null == bitrateKbps ? _self.bitrateKbps : bitrateKbps // ignore: cast_nullable_to_non_nullable
as int,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,videoCodec: null == videoCodec ? _self.videoCodec : videoCodec // ignore: cast_nullable_to_non_nullable
as String,audioCodec: null == audioCodec ? _self.audioCodec : audioCodec // ignore: cast_nullable_to_non_nullable
as String,focalX: null == focalX ? _self.focalX : focalX // ignore: cast_nullable_to_non_nullable
as double,focalY: null == focalY ? _self.focalY : focalY // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ProjectResponsiveVideoProfile {

 ProjectVideoVariantProfile get landscape;@JsonKey(includeIfNull: false) ProjectVideoVariantProfile? get portrait;
/// Create a copy of ProjectResponsiveVideoProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectResponsiveVideoProfileCopyWith<ProjectResponsiveVideoProfile> get copyWith => _$ProjectResponsiveVideoProfileCopyWithImpl<ProjectResponsiveVideoProfile>(this as ProjectResponsiveVideoProfile, _$identity);

  /// Serializes this ProjectResponsiveVideoProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectResponsiveVideoProfile&&(identical(other.landscape, landscape) || other.landscape == landscape)&&(identical(other.portrait, portrait) || other.portrait == portrait));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,landscape,portrait);

@override
String toString() {
  return 'ProjectResponsiveVideoProfile(landscape: $landscape, portrait: $portrait)';
}


}

/// @nodoc
abstract mixin class $ProjectResponsiveVideoProfileCopyWith<$Res>  {
  factory $ProjectResponsiveVideoProfileCopyWith(ProjectResponsiveVideoProfile value, $Res Function(ProjectResponsiveVideoProfile) _then) = _$ProjectResponsiveVideoProfileCopyWithImpl;
@useResult
$Res call({
 ProjectVideoVariantProfile landscape,@JsonKey(includeIfNull: false) ProjectVideoVariantProfile? portrait
});


$ProjectVideoVariantProfileCopyWith<$Res> get landscape;$ProjectVideoVariantProfileCopyWith<$Res>? get portrait;

}
/// @nodoc
class _$ProjectResponsiveVideoProfileCopyWithImpl<$Res>
    implements $ProjectResponsiveVideoProfileCopyWith<$Res> {
  _$ProjectResponsiveVideoProfileCopyWithImpl(this._self, this._then);

  final ProjectResponsiveVideoProfile _self;
  final $Res Function(ProjectResponsiveVideoProfile) _then;

/// Create a copy of ProjectResponsiveVideoProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? landscape = null,Object? portrait = freezed,}) {
  return _then(_self.copyWith(
landscape: null == landscape ? _self.landscape : landscape // ignore: cast_nullable_to_non_nullable
as ProjectVideoVariantProfile,portrait: freezed == portrait ? _self.portrait : portrait // ignore: cast_nullable_to_non_nullable
as ProjectVideoVariantProfile?,
  ));
}
/// Create a copy of ProjectResponsiveVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectVideoVariantProfileCopyWith<$Res> get landscape {

  return $ProjectVideoVariantProfileCopyWith<$Res>(_self.landscape, (value) {
    return _then(_self.copyWith(landscape: value));
  });
}/// Create a copy of ProjectResponsiveVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectVideoVariantProfileCopyWith<$Res>? get portrait {
    if (_self.portrait == null) {
    return null;
  }

  return $ProjectVideoVariantProfileCopyWith<$Res>(_self.portrait!, (value) {
    return _then(_self.copyWith(portrait: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectResponsiveVideoProfile].
extension ProjectResponsiveVideoProfilePatterns on ProjectResponsiveVideoProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectResponsiveVideoProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectResponsiveVideoProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectResponsiveVideoProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectResponsiveVideoProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectResponsiveVideoProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectResponsiveVideoProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectVideoVariantProfile landscape, @JsonKey(includeIfNull: false)  ProjectVideoVariantProfile? portrait)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectResponsiveVideoProfile() when $default != null:
return $default(_that.landscape,_that.portrait);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectVideoVariantProfile landscape, @JsonKey(includeIfNull: false)  ProjectVideoVariantProfile? portrait)  $default,) {final _that = this;
switch (_that) {
case _ProjectResponsiveVideoProfile():
return $default(_that.landscape,_that.portrait);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectVideoVariantProfile landscape, @JsonKey(includeIfNull: false)  ProjectVideoVariantProfile? portrait)?  $default,) {final _that = this;
switch (_that) {
case _ProjectResponsiveVideoProfile() when $default != null:
return $default(_that.landscape,_that.portrait);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectResponsiveVideoProfile implements ProjectResponsiveVideoProfile {
  const _ProjectResponsiveVideoProfile({required this.landscape, @JsonKey(includeIfNull: false) this.portrait});
  factory _ProjectResponsiveVideoProfile.fromJson(Map<String, dynamic> json) => _$ProjectResponsiveVideoProfileFromJson(json);

@override final  ProjectVideoVariantProfile landscape;
@override@JsonKey(includeIfNull: false) final  ProjectVideoVariantProfile? portrait;

/// Create a copy of ProjectResponsiveVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectResponsiveVideoProfileCopyWith<_ProjectResponsiveVideoProfile> get copyWith => __$ProjectResponsiveVideoProfileCopyWithImpl<_ProjectResponsiveVideoProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectResponsiveVideoProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectResponsiveVideoProfile&&(identical(other.landscape, landscape) || other.landscape == landscape)&&(identical(other.portrait, portrait) || other.portrait == portrait));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,landscape,portrait);

@override
String toString() {
  return 'ProjectResponsiveVideoProfile(landscape: $landscape, portrait: $portrait)';
}


}

/// @nodoc
abstract mixin class _$ProjectResponsiveVideoProfileCopyWith<$Res> implements $ProjectResponsiveVideoProfileCopyWith<$Res> {
  factory _$ProjectResponsiveVideoProfileCopyWith(_ProjectResponsiveVideoProfile value, $Res Function(_ProjectResponsiveVideoProfile) _then) = __$ProjectResponsiveVideoProfileCopyWithImpl;
@override @useResult
$Res call({
 ProjectVideoVariantProfile landscape,@JsonKey(includeIfNull: false) ProjectVideoVariantProfile? portrait
});


@override $ProjectVideoVariantProfileCopyWith<$Res> get landscape;@override $ProjectVideoVariantProfileCopyWith<$Res>? get portrait;

}
/// @nodoc
class __$ProjectResponsiveVideoProfileCopyWithImpl<$Res>
    implements _$ProjectResponsiveVideoProfileCopyWith<$Res> {
  __$ProjectResponsiveVideoProfileCopyWithImpl(this._self, this._then);

  final _ProjectResponsiveVideoProfile _self;
  final $Res Function(_ProjectResponsiveVideoProfile) _then;

/// Create a copy of ProjectResponsiveVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? landscape = null,Object? portrait = freezed,}) {
  return _then(_ProjectResponsiveVideoProfile(
landscape: null == landscape ? _self.landscape : landscape // ignore: cast_nullable_to_non_nullable
as ProjectVideoVariantProfile,portrait: freezed == portrait ? _self.portrait : portrait // ignore: cast_nullable_to_non_nullable
as ProjectVideoVariantProfile?,
  ));
}

/// Create a copy of ProjectResponsiveVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectVideoVariantProfileCopyWith<$Res> get landscape {

  return $ProjectVideoVariantProfileCopyWith<$Res>(_self.landscape, (value) {
    return _then(_self.copyWith(landscape: value));
  });
}/// Create a copy of ProjectResponsiveVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectVideoVariantProfileCopyWith<$Res>? get portrait {
    if (_self.portrait == null) {
    return null;
  }

  return $ProjectVideoVariantProfileCopyWith<$Res>(_self.portrait!, (value) {
    return _then(_self.copyWith(portrait: value));
  });
}
}


/// @nodoc
mixin _$ProjectIntroVideoProfile {

 ProjectResponsiveVideoProfile get media; String get reducedMotionBehavior; bool get allowReplay;
/// Create a copy of ProjectIntroVideoProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectIntroVideoProfileCopyWith<ProjectIntroVideoProfile> get copyWith => _$ProjectIntroVideoProfileCopyWithImpl<ProjectIntroVideoProfile>(this as ProjectIntroVideoProfile, _$identity);

  /// Serializes this ProjectIntroVideoProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectIntroVideoProfile&&(identical(other.media, media) || other.media == media)&&(identical(other.reducedMotionBehavior, reducedMotionBehavior) || other.reducedMotionBehavior == reducedMotionBehavior)&&(identical(other.allowReplay, allowReplay) || other.allowReplay == allowReplay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,media,reducedMotionBehavior,allowReplay);

@override
String toString() {
  return 'ProjectIntroVideoProfile(media: $media, reducedMotionBehavior: $reducedMotionBehavior, allowReplay: $allowReplay)';
}


}

/// @nodoc
abstract mixin class $ProjectIntroVideoProfileCopyWith<$Res>  {
  factory $ProjectIntroVideoProfileCopyWith(ProjectIntroVideoProfile value, $Res Function(ProjectIntroVideoProfile) _then) = _$ProjectIntroVideoProfileCopyWithImpl;
@useResult
$Res call({
 ProjectResponsiveVideoProfile media, String reducedMotionBehavior, bool allowReplay
});


$ProjectResponsiveVideoProfileCopyWith<$Res> get media;

}
/// @nodoc
class _$ProjectIntroVideoProfileCopyWithImpl<$Res>
    implements $ProjectIntroVideoProfileCopyWith<$Res> {
  _$ProjectIntroVideoProfileCopyWithImpl(this._self, this._then);

  final ProjectIntroVideoProfile _self;
  final $Res Function(ProjectIntroVideoProfile) _then;

/// Create a copy of ProjectIntroVideoProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? media = null,Object? reducedMotionBehavior = null,Object? allowReplay = null,}) {
  return _then(_self.copyWith(
media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveVideoProfile,reducedMotionBehavior: null == reducedMotionBehavior ? _self.reducedMotionBehavior : reducedMotionBehavior // ignore: cast_nullable_to_non_nullable
as String,allowReplay: null == allowReplay ? _self.allowReplay : allowReplay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ProjectIntroVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveVideoProfileCopyWith<$Res> get media {

  return $ProjectResponsiveVideoProfileCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectIntroVideoProfile].
extension ProjectIntroVideoProfilePatterns on ProjectIntroVideoProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectIntroVideoProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectIntroVideoProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectIntroVideoProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectIntroVideoProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectIntroVideoProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectIntroVideoProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectResponsiveVideoProfile media,  String reducedMotionBehavior,  bool allowReplay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectIntroVideoProfile() when $default != null:
return $default(_that.media,_that.reducedMotionBehavior,_that.allowReplay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectResponsiveVideoProfile media,  String reducedMotionBehavior,  bool allowReplay)  $default,) {final _that = this;
switch (_that) {
case _ProjectIntroVideoProfile():
return $default(_that.media,_that.reducedMotionBehavior,_that.allowReplay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectResponsiveVideoProfile media,  String reducedMotionBehavior,  bool allowReplay)?  $default,) {final _that = this;
switch (_that) {
case _ProjectIntroVideoProfile() when $default != null:
return $default(_that.media,_that.reducedMotionBehavior,_that.allowReplay);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectIntroVideoProfile extends ProjectIntroVideoProfile {
  const _ProjectIntroVideoProfile({required this.media, this.reducedMotionBehavior = 'poster', this.allowReplay = true}): super._();
  factory _ProjectIntroVideoProfile.fromJson(Map<String, dynamic> json) => _$ProjectIntroVideoProfileFromJson(json);

@override final  ProjectResponsiveVideoProfile media;
@override@JsonKey() final  String reducedMotionBehavior;
@override@JsonKey() final  bool allowReplay;

/// Create a copy of ProjectIntroVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectIntroVideoProfileCopyWith<_ProjectIntroVideoProfile> get copyWith => __$ProjectIntroVideoProfileCopyWithImpl<_ProjectIntroVideoProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectIntroVideoProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectIntroVideoProfile&&(identical(other.media, media) || other.media == media)&&(identical(other.reducedMotionBehavior, reducedMotionBehavior) || other.reducedMotionBehavior == reducedMotionBehavior)&&(identical(other.allowReplay, allowReplay) || other.allowReplay == allowReplay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,media,reducedMotionBehavior,allowReplay);

@override
String toString() {
  return 'ProjectIntroVideoProfile(media: $media, reducedMotionBehavior: $reducedMotionBehavior, allowReplay: $allowReplay)';
}


}

/// @nodoc
abstract mixin class _$ProjectIntroVideoProfileCopyWith<$Res> implements $ProjectIntroVideoProfileCopyWith<$Res> {
  factory _$ProjectIntroVideoProfileCopyWith(_ProjectIntroVideoProfile value, $Res Function(_ProjectIntroVideoProfile) _then) = __$ProjectIntroVideoProfileCopyWithImpl;
@override @useResult
$Res call({
 ProjectResponsiveVideoProfile media, String reducedMotionBehavior, bool allowReplay
});


@override $ProjectResponsiveVideoProfileCopyWith<$Res> get media;

}
/// @nodoc
class __$ProjectIntroVideoProfileCopyWithImpl<$Res>
    implements _$ProjectIntroVideoProfileCopyWith<$Res> {
  __$ProjectIntroVideoProfileCopyWithImpl(this._self, this._then);

  final _ProjectIntroVideoProfile _self;
  final $Res Function(_ProjectIntroVideoProfile) _then;

/// Create a copy of ProjectIntroVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? media = null,Object? reducedMotionBehavior = null,Object? allowReplay = null,}) {
  return _then(_ProjectIntroVideoProfile(
media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveVideoProfile,reducedMotionBehavior: null == reducedMotionBehavior ? _self.reducedMotionBehavior : reducedMotionBehavior // ignore: cast_nullable_to_non_nullable
as String,allowReplay: null == allowReplay ? _self.allowReplay : allowReplay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ProjectIntroVideoProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveVideoProfileCopyWith<$Res> get media {

  return $ProjectResponsiveVideoProfileCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}


/// @nodoc
mixin _$ProjectTitleMotionProfile {

@JsonKey(includeIfNull: false) ProjectResponsiveVideoProfile? get promptLoop;@JsonKey(includeIfNull: false) ProjectResponsiveVideoProfile? get menuLoop;
/// Create a copy of ProjectTitleMotionProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTitleMotionProfileCopyWith<ProjectTitleMotionProfile> get copyWith => _$ProjectTitleMotionProfileCopyWithImpl<ProjectTitleMotionProfile>(this as ProjectTitleMotionProfile, _$identity);

  /// Serializes this ProjectTitleMotionProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTitleMotionProfile&&(identical(other.promptLoop, promptLoop) || other.promptLoop == promptLoop)&&(identical(other.menuLoop, menuLoop) || other.menuLoop == menuLoop));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,promptLoop,menuLoop);

@override
String toString() {
  return 'ProjectTitleMotionProfile(promptLoop: $promptLoop, menuLoop: $menuLoop)';
}


}

/// @nodoc
abstract mixin class $ProjectTitleMotionProfileCopyWith<$Res>  {
  factory $ProjectTitleMotionProfileCopyWith(ProjectTitleMotionProfile value, $Res Function(ProjectTitleMotionProfile) _then) = _$ProjectTitleMotionProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) ProjectResponsiveVideoProfile? promptLoop,@JsonKey(includeIfNull: false) ProjectResponsiveVideoProfile? menuLoop
});


$ProjectResponsiveVideoProfileCopyWith<$Res>? get promptLoop;$ProjectResponsiveVideoProfileCopyWith<$Res>? get menuLoop;

}
/// @nodoc
class _$ProjectTitleMotionProfileCopyWithImpl<$Res>
    implements $ProjectTitleMotionProfileCopyWith<$Res> {
  _$ProjectTitleMotionProfileCopyWithImpl(this._self, this._then);

  final ProjectTitleMotionProfile _self;
  final $Res Function(ProjectTitleMotionProfile) _then;

/// Create a copy of ProjectTitleMotionProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? promptLoop = freezed,Object? menuLoop = freezed,}) {
  return _then(_self.copyWith(
promptLoop: freezed == promptLoop ? _self.promptLoop : promptLoop // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveVideoProfile?,menuLoop: freezed == menuLoop ? _self.menuLoop : menuLoop // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveVideoProfile?,
  ));
}
/// Create a copy of ProjectTitleMotionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveVideoProfileCopyWith<$Res>? get promptLoop {
    if (_self.promptLoop == null) {
    return null;
  }

  return $ProjectResponsiveVideoProfileCopyWith<$Res>(_self.promptLoop!, (value) {
    return _then(_self.copyWith(promptLoop: value));
  });
}/// Create a copy of ProjectTitleMotionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveVideoProfileCopyWith<$Res>? get menuLoop {
    if (_self.menuLoop == null) {
    return null;
  }

  return $ProjectResponsiveVideoProfileCopyWith<$Res>(_self.menuLoop!, (value) {
    return _then(_self.copyWith(menuLoop: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectTitleMotionProfile].
extension ProjectTitleMotionProfilePatterns on ProjectTitleMotionProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTitleMotionProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTitleMotionProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTitleMotionProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTitleMotionProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTitleMotionProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTitleMotionProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  ProjectResponsiveVideoProfile? promptLoop, @JsonKey(includeIfNull: false)  ProjectResponsiveVideoProfile? menuLoop)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTitleMotionProfile() when $default != null:
return $default(_that.promptLoop,_that.menuLoop);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  ProjectResponsiveVideoProfile? promptLoop, @JsonKey(includeIfNull: false)  ProjectResponsiveVideoProfile? menuLoop)  $default,) {final _that = this;
switch (_that) {
case _ProjectTitleMotionProfile():
return $default(_that.promptLoop,_that.menuLoop);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  ProjectResponsiveVideoProfile? promptLoop, @JsonKey(includeIfNull: false)  ProjectResponsiveVideoProfile? menuLoop)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTitleMotionProfile() when $default != null:
return $default(_that.promptLoop,_that.menuLoop);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectTitleMotionProfile implements ProjectTitleMotionProfile {
  const _ProjectTitleMotionProfile({@JsonKey(includeIfNull: false) this.promptLoop, @JsonKey(includeIfNull: false) this.menuLoop});
  factory _ProjectTitleMotionProfile.fromJson(Map<String, dynamic> json) => _$ProjectTitleMotionProfileFromJson(json);

@override@JsonKey(includeIfNull: false) final  ProjectResponsiveVideoProfile? promptLoop;
@override@JsonKey(includeIfNull: false) final  ProjectResponsiveVideoProfile? menuLoop;

/// Create a copy of ProjectTitleMotionProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTitleMotionProfileCopyWith<_ProjectTitleMotionProfile> get copyWith => __$ProjectTitleMotionProfileCopyWithImpl<_ProjectTitleMotionProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTitleMotionProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTitleMotionProfile&&(identical(other.promptLoop, promptLoop) || other.promptLoop == promptLoop)&&(identical(other.menuLoop, menuLoop) || other.menuLoop == menuLoop));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,promptLoop,menuLoop);

@override
String toString() {
  return 'ProjectTitleMotionProfile(promptLoop: $promptLoop, menuLoop: $menuLoop)';
}


}

/// @nodoc
abstract mixin class _$ProjectTitleMotionProfileCopyWith<$Res> implements $ProjectTitleMotionProfileCopyWith<$Res> {
  factory _$ProjectTitleMotionProfileCopyWith(_ProjectTitleMotionProfile value, $Res Function(_ProjectTitleMotionProfile) _then) = __$ProjectTitleMotionProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) ProjectResponsiveVideoProfile? promptLoop,@JsonKey(includeIfNull: false) ProjectResponsiveVideoProfile? menuLoop
});


@override $ProjectResponsiveVideoProfileCopyWith<$Res>? get promptLoop;@override $ProjectResponsiveVideoProfileCopyWith<$Res>? get menuLoop;

}
/// @nodoc
class __$ProjectTitleMotionProfileCopyWithImpl<$Res>
    implements _$ProjectTitleMotionProfileCopyWith<$Res> {
  __$ProjectTitleMotionProfileCopyWithImpl(this._self, this._then);

  final _ProjectTitleMotionProfile _self;
  final $Res Function(_ProjectTitleMotionProfile) _then;

/// Create a copy of ProjectTitleMotionProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? promptLoop = freezed,Object? menuLoop = freezed,}) {
  return _then(_ProjectTitleMotionProfile(
promptLoop: freezed == promptLoop ? _self.promptLoop : promptLoop // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveVideoProfile?,menuLoop: freezed == menuLoop ? _self.menuLoop : menuLoop // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveVideoProfile?,
  ));
}

/// Create a copy of ProjectTitleMotionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveVideoProfileCopyWith<$Res>? get promptLoop {
    if (_self.promptLoop == null) {
    return null;
  }

  return $ProjectResponsiveVideoProfileCopyWith<$Res>(_self.promptLoop!, (value) {
    return _then(_self.copyWith(promptLoop: value));
  });
}/// Create a copy of ProjectTitleMotionProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveVideoProfileCopyWith<$Res>? get menuLoop {
    if (_self.menuLoop == null) {
    return null;
  }

  return $ProjectResponsiveVideoProfileCopyWith<$Res>(_self.menuLoop!, (value) {
    return _then(_self.copyWith(menuLoop: value));
  });
}
}


/// @nodoc
mixin _$ProjectTypographyRoleProfile {

@JsonKey(includeIfNull: false) String? get fontPath;@JsonKey(includeIfNull: false) String? get family;@JsonKey(includeIfNull: false) String? get licensePath; bool get redistributable; List<String> get fallbackFamilies; List<String> get glyphCoverage;
/// Create a copy of ProjectTypographyRoleProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<ProjectTypographyRoleProfile> get copyWith => _$ProjectTypographyRoleProfileCopyWithImpl<ProjectTypographyRoleProfile>(this as ProjectTypographyRoleProfile, _$identity);

  /// Serializes this ProjectTypographyRoleProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTypographyRoleProfile&&(identical(other.fontPath, fontPath) || other.fontPath == fontPath)&&(identical(other.family, family) || other.family == family)&&(identical(other.licensePath, licensePath) || other.licensePath == licensePath)&&(identical(other.redistributable, redistributable) || other.redistributable == redistributable)&&const DeepCollectionEquality().equals(other.fallbackFamilies, fallbackFamilies)&&const DeepCollectionEquality().equals(other.glyphCoverage, glyphCoverage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fontPath,family,licensePath,redistributable,const DeepCollectionEquality().hash(fallbackFamilies),const DeepCollectionEquality().hash(glyphCoverage));

@override
String toString() {
  return 'ProjectTypographyRoleProfile(fontPath: $fontPath, family: $family, licensePath: $licensePath, redistributable: $redistributable, fallbackFamilies: $fallbackFamilies, glyphCoverage: $glyphCoverage)';
}


}

/// @nodoc
abstract mixin class $ProjectTypographyRoleProfileCopyWith<$Res>  {
  factory $ProjectTypographyRoleProfileCopyWith(ProjectTypographyRoleProfile value, $Res Function(ProjectTypographyRoleProfile) _then) = _$ProjectTypographyRoleProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? fontPath,@JsonKey(includeIfNull: false) String? family,@JsonKey(includeIfNull: false) String? licensePath, bool redistributable, List<String> fallbackFamilies, List<String> glyphCoverage
});




}
/// @nodoc
class _$ProjectTypographyRoleProfileCopyWithImpl<$Res>
    implements $ProjectTypographyRoleProfileCopyWith<$Res> {
  _$ProjectTypographyRoleProfileCopyWithImpl(this._self, this._then);

  final ProjectTypographyRoleProfile _self;
  final $Res Function(ProjectTypographyRoleProfile) _then;

/// Create a copy of ProjectTypographyRoleProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fontPath = freezed,Object? family = freezed,Object? licensePath = freezed,Object? redistributable = null,Object? fallbackFamilies = null,Object? glyphCoverage = null,}) {
  return _then(_self.copyWith(
fontPath: freezed == fontPath ? _self.fontPath : fontPath // ignore: cast_nullable_to_non_nullable
as String?,family: freezed == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as String?,licensePath: freezed == licensePath ? _self.licensePath : licensePath // ignore: cast_nullable_to_non_nullable
as String?,redistributable: null == redistributable ? _self.redistributable : redistributable // ignore: cast_nullable_to_non_nullable
as bool,fallbackFamilies: null == fallbackFamilies ? _self.fallbackFamilies : fallbackFamilies // ignore: cast_nullable_to_non_nullable
as List<String>,glyphCoverage: null == glyphCoverage ? _self.glyphCoverage : glyphCoverage // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTypographyRoleProfile].
extension ProjectTypographyRoleProfilePatterns on ProjectTypographyRoleProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTypographyRoleProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTypographyRoleProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTypographyRoleProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTypographyRoleProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTypographyRoleProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTypographyRoleProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? fontPath, @JsonKey(includeIfNull: false)  String? family, @JsonKey(includeIfNull: false)  String? licensePath,  bool redistributable,  List<String> fallbackFamilies,  List<String> glyphCoverage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTypographyRoleProfile() when $default != null:
return $default(_that.fontPath,_that.family,_that.licensePath,_that.redistributable,_that.fallbackFamilies,_that.glyphCoverage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? fontPath, @JsonKey(includeIfNull: false)  String? family, @JsonKey(includeIfNull: false)  String? licensePath,  bool redistributable,  List<String> fallbackFamilies,  List<String> glyphCoverage)  $default,) {final _that = this;
switch (_that) {
case _ProjectTypographyRoleProfile():
return $default(_that.fontPath,_that.family,_that.licensePath,_that.redistributable,_that.fallbackFamilies,_that.glyphCoverage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? fontPath, @JsonKey(includeIfNull: false)  String? family, @JsonKey(includeIfNull: false)  String? licensePath,  bool redistributable,  List<String> fallbackFamilies,  List<String> glyphCoverage)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTypographyRoleProfile() when $default != null:
return $default(_that.fontPath,_that.family,_that.licensePath,_that.redistributable,_that.fallbackFamilies,_that.glyphCoverage);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectTypographyRoleProfile implements ProjectTypographyRoleProfile {
  const _ProjectTypographyRoleProfile({@JsonKey(includeIfNull: false) this.fontPath, @JsonKey(includeIfNull: false) this.family, @JsonKey(includeIfNull: false) this.licensePath, this.redistributable = false, final  List<String> fallbackFamilies = const <String>['sans-serif'], final  List<String> glyphCoverage = const <String>[]}): _fallbackFamilies = fallbackFamilies,_glyphCoverage = glyphCoverage;
  factory _ProjectTypographyRoleProfile.fromJson(Map<String, dynamic> json) => _$ProjectTypographyRoleProfileFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? fontPath;
@override@JsonKey(includeIfNull: false) final  String? family;
@override@JsonKey(includeIfNull: false) final  String? licensePath;
@override@JsonKey() final  bool redistributable;
 final  List<String> _fallbackFamilies;
@override@JsonKey() List<String> get fallbackFamilies {
  if (_fallbackFamilies is EqualUnmodifiableListView) return _fallbackFamilies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fallbackFamilies);
}

 final  List<String> _glyphCoverage;
@override@JsonKey() List<String> get glyphCoverage {
  if (_glyphCoverage is EqualUnmodifiableListView) return _glyphCoverage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_glyphCoverage);
}


/// Create a copy of ProjectTypographyRoleProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTypographyRoleProfileCopyWith<_ProjectTypographyRoleProfile> get copyWith => __$ProjectTypographyRoleProfileCopyWithImpl<_ProjectTypographyRoleProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTypographyRoleProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTypographyRoleProfile&&(identical(other.fontPath, fontPath) || other.fontPath == fontPath)&&(identical(other.family, family) || other.family == family)&&(identical(other.licensePath, licensePath) || other.licensePath == licensePath)&&(identical(other.redistributable, redistributable) || other.redistributable == redistributable)&&const DeepCollectionEquality().equals(other._fallbackFamilies, _fallbackFamilies)&&const DeepCollectionEquality().equals(other._glyphCoverage, _glyphCoverage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fontPath,family,licensePath,redistributable,const DeepCollectionEquality().hash(_fallbackFamilies),const DeepCollectionEquality().hash(_glyphCoverage));

@override
String toString() {
  return 'ProjectTypographyRoleProfile(fontPath: $fontPath, family: $family, licensePath: $licensePath, redistributable: $redistributable, fallbackFamilies: $fallbackFamilies, glyphCoverage: $glyphCoverage)';
}


}

/// @nodoc
abstract mixin class _$ProjectTypographyRoleProfileCopyWith<$Res> implements $ProjectTypographyRoleProfileCopyWith<$Res> {
  factory _$ProjectTypographyRoleProfileCopyWith(_ProjectTypographyRoleProfile value, $Res Function(_ProjectTypographyRoleProfile) _then) = __$ProjectTypographyRoleProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? fontPath,@JsonKey(includeIfNull: false) String? family,@JsonKey(includeIfNull: false) String? licensePath, bool redistributable, List<String> fallbackFamilies, List<String> glyphCoverage
});




}
/// @nodoc
class __$ProjectTypographyRoleProfileCopyWithImpl<$Res>
    implements _$ProjectTypographyRoleProfileCopyWith<$Res> {
  __$ProjectTypographyRoleProfileCopyWithImpl(this._self, this._then);

  final _ProjectTypographyRoleProfile _self;
  final $Res Function(_ProjectTypographyRoleProfile) _then;

/// Create a copy of ProjectTypographyRoleProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fontPath = freezed,Object? family = freezed,Object? licensePath = freezed,Object? redistributable = null,Object? fallbackFamilies = null,Object? glyphCoverage = null,}) {
  return _then(_ProjectTypographyRoleProfile(
fontPath: freezed == fontPath ? _self.fontPath : fontPath // ignore: cast_nullable_to_non_nullable
as String?,family: freezed == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as String?,licensePath: freezed == licensePath ? _self.licensePath : licensePath // ignore: cast_nullable_to_non_nullable
as String?,redistributable: null == redistributable ? _self.redistributable : redistributable // ignore: cast_nullable_to_non_nullable
as bool,fallbackFamilies: null == fallbackFamilies ? _self._fallbackFamilies : fallbackFamilies // ignore: cast_nullable_to_non_nullable
as List<String>,glyphCoverage: null == glyphCoverage ? _self._glyphCoverage : glyphCoverage // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ProjectTypographyProfile {

 ProjectTypographyRoleProfile get display; ProjectTypographyRoleProfile get body; ProjectTypographyRoleProfile get dialogue; ProjectTypographyRoleProfile get numbers;
/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTypographyProfileCopyWith<ProjectTypographyProfile> get copyWith => _$ProjectTypographyProfileCopyWithImpl<ProjectTypographyProfile>(this as ProjectTypographyProfile, _$identity);

  /// Serializes this ProjectTypographyProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTypographyProfile&&(identical(other.display, display) || other.display == display)&&(identical(other.body, body) || other.body == body)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.numbers, numbers) || other.numbers == numbers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,display,body,dialogue,numbers);

@override
String toString() {
  return 'ProjectTypographyProfile(display: $display, body: $body, dialogue: $dialogue, numbers: $numbers)';
}


}

/// @nodoc
abstract mixin class $ProjectTypographyProfileCopyWith<$Res>  {
  factory $ProjectTypographyProfileCopyWith(ProjectTypographyProfile value, $Res Function(ProjectTypographyProfile) _then) = _$ProjectTypographyProfileCopyWithImpl;
@useResult
$Res call({
 ProjectTypographyRoleProfile display, ProjectTypographyRoleProfile body, ProjectTypographyRoleProfile dialogue, ProjectTypographyRoleProfile numbers
});


$ProjectTypographyRoleProfileCopyWith<$Res> get display;$ProjectTypographyRoleProfileCopyWith<$Res> get body;$ProjectTypographyRoleProfileCopyWith<$Res> get dialogue;$ProjectTypographyRoleProfileCopyWith<$Res> get numbers;

}
/// @nodoc
class _$ProjectTypographyProfileCopyWithImpl<$Res>
    implements $ProjectTypographyProfileCopyWith<$Res> {
  _$ProjectTypographyProfileCopyWithImpl(this._self, this._then);

  final ProjectTypographyProfile _self;
  final $Res Function(ProjectTypographyProfile) _then;

/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? display = null,Object? body = null,Object? dialogue = null,Object? numbers = null,}) {
  return _then(_self.copyWith(
display: null == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as ProjectTypographyRoleProfile,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as ProjectTypographyRoleProfile,dialogue: null == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as ProjectTypographyRoleProfile,numbers: null == numbers ? _self.numbers : numbers // ignore: cast_nullable_to_non_nullable
as ProjectTypographyRoleProfile,
  ));
}
/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<$Res> get display {

  return $ProjectTypographyRoleProfileCopyWith<$Res>(_self.display, (value) {
    return _then(_self.copyWith(display: value));
  });
}/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<$Res> get body {

  return $ProjectTypographyRoleProfileCopyWith<$Res>(_self.body, (value) {
    return _then(_self.copyWith(body: value));
  });
}/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<$Res> get dialogue {

  return $ProjectTypographyRoleProfileCopyWith<$Res>(_self.dialogue, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<$Res> get numbers {

  return $ProjectTypographyRoleProfileCopyWith<$Res>(_self.numbers, (value) {
    return _then(_self.copyWith(numbers: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectTypographyProfile].
extension ProjectTypographyProfilePatterns on ProjectTypographyProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTypographyProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTypographyProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTypographyProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTypographyProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTypographyProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTypographyProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectTypographyRoleProfile display,  ProjectTypographyRoleProfile body,  ProjectTypographyRoleProfile dialogue,  ProjectTypographyRoleProfile numbers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTypographyProfile() when $default != null:
return $default(_that.display,_that.body,_that.dialogue,_that.numbers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectTypographyRoleProfile display,  ProjectTypographyRoleProfile body,  ProjectTypographyRoleProfile dialogue,  ProjectTypographyRoleProfile numbers)  $default,) {final _that = this;
switch (_that) {
case _ProjectTypographyProfile():
return $default(_that.display,_that.body,_that.dialogue,_that.numbers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectTypographyRoleProfile display,  ProjectTypographyRoleProfile body,  ProjectTypographyRoleProfile dialogue,  ProjectTypographyRoleProfile numbers)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTypographyProfile() when $default != null:
return $default(_that.display,_that.body,_that.dialogue,_that.numbers);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectTypographyProfile implements ProjectTypographyProfile {
  const _ProjectTypographyProfile({this.display = const ProjectTypographyRoleProfile(), this.body = const ProjectTypographyRoleProfile(), this.dialogue = const ProjectTypographyRoleProfile(), this.numbers = const ProjectTypographyRoleProfile()});
  factory _ProjectTypographyProfile.fromJson(Map<String, dynamic> json) => _$ProjectTypographyProfileFromJson(json);

@override@JsonKey() final  ProjectTypographyRoleProfile display;
@override@JsonKey() final  ProjectTypographyRoleProfile body;
@override@JsonKey() final  ProjectTypographyRoleProfile dialogue;
@override@JsonKey() final  ProjectTypographyRoleProfile numbers;

/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTypographyProfileCopyWith<_ProjectTypographyProfile> get copyWith => __$ProjectTypographyProfileCopyWithImpl<_ProjectTypographyProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTypographyProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTypographyProfile&&(identical(other.display, display) || other.display == display)&&(identical(other.body, body) || other.body == body)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.numbers, numbers) || other.numbers == numbers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,display,body,dialogue,numbers);

@override
String toString() {
  return 'ProjectTypographyProfile(display: $display, body: $body, dialogue: $dialogue, numbers: $numbers)';
}


}

/// @nodoc
abstract mixin class _$ProjectTypographyProfileCopyWith<$Res> implements $ProjectTypographyProfileCopyWith<$Res> {
  factory _$ProjectTypographyProfileCopyWith(_ProjectTypographyProfile value, $Res Function(_ProjectTypographyProfile) _then) = __$ProjectTypographyProfileCopyWithImpl;
@override @useResult
$Res call({
 ProjectTypographyRoleProfile display, ProjectTypographyRoleProfile body, ProjectTypographyRoleProfile dialogue, ProjectTypographyRoleProfile numbers
});


@override $ProjectTypographyRoleProfileCopyWith<$Res> get display;@override $ProjectTypographyRoleProfileCopyWith<$Res> get body;@override $ProjectTypographyRoleProfileCopyWith<$Res> get dialogue;@override $ProjectTypographyRoleProfileCopyWith<$Res> get numbers;

}
/// @nodoc
class __$ProjectTypographyProfileCopyWithImpl<$Res>
    implements _$ProjectTypographyProfileCopyWith<$Res> {
  __$ProjectTypographyProfileCopyWithImpl(this._self, this._then);

  final _ProjectTypographyProfile _self;
  final $Res Function(_ProjectTypographyProfile) _then;

/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? display = null,Object? body = null,Object? dialogue = null,Object? numbers = null,}) {
  return _then(_ProjectTypographyProfile(
display: null == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as ProjectTypographyRoleProfile,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as ProjectTypographyRoleProfile,dialogue: null == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as ProjectTypographyRoleProfile,numbers: null == numbers ? _self.numbers : numbers // ignore: cast_nullable_to_non_nullable
as ProjectTypographyRoleProfile,
  ));
}

/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<$Res> get display {

  return $ProjectTypographyRoleProfileCopyWith<$Res>(_self.display, (value) {
    return _then(_self.copyWith(display: value));
  });
}/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<$Res> get body {

  return $ProjectTypographyRoleProfileCopyWith<$Res>(_self.body, (value) {
    return _then(_self.copyWith(body: value));
  });
}/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<$Res> get dialogue {

  return $ProjectTypographyRoleProfileCopyWith<$Res>(_self.dialogue, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}/// Create a copy of ProjectTypographyProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyRoleProfileCopyWith<$Res> get numbers {

  return $ProjectTypographyRoleProfileCopyWith<$Res>(_self.numbers, (value) {
    return _then(_self.copyWith(numbers: value));
  });
}
}


/// @nodoc
mixin _$ProjectSemanticThemeProfile {

 String get primary; String get onPrimary; String get background; String get surface; String get surfaceElevated; String get textPrimary; String get textSecondary; String get outline; String get success; String get warning; String get danger; String get titleSurface; String get dialogueSurface; String get menuSurface; String get overworldHudSurface; String get battleHudSurface;
/// Create a copy of ProjectSemanticThemeProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSemanticThemeProfileCopyWith<ProjectSemanticThemeProfile> get copyWith => _$ProjectSemanticThemeProfileCopyWithImpl<ProjectSemanticThemeProfile>(this as ProjectSemanticThemeProfile, _$identity);

  /// Serializes this ProjectSemanticThemeProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSemanticThemeProfile&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.onPrimary, onPrimary) || other.onPrimary == onPrimary)&&(identical(other.background, background) || other.background == background)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.surfaceElevated, surfaceElevated) || other.surfaceElevated == surfaceElevated)&&(identical(other.textPrimary, textPrimary) || other.textPrimary == textPrimary)&&(identical(other.textSecondary, textSecondary) || other.textSecondary == textSecondary)&&(identical(other.outline, outline) || other.outline == outline)&&(identical(other.success, success) || other.success == success)&&(identical(other.warning, warning) || other.warning == warning)&&(identical(other.danger, danger) || other.danger == danger)&&(identical(other.titleSurface, titleSurface) || other.titleSurface == titleSurface)&&(identical(other.dialogueSurface, dialogueSurface) || other.dialogueSurface == dialogueSurface)&&(identical(other.menuSurface, menuSurface) || other.menuSurface == menuSurface)&&(identical(other.overworldHudSurface, overworldHudSurface) || other.overworldHudSurface == overworldHudSurface)&&(identical(other.battleHudSurface, battleHudSurface) || other.battleHudSurface == battleHudSurface));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,primary,onPrimary,background,surface,surfaceElevated,textPrimary,textSecondary,outline,success,warning,danger,titleSurface,dialogueSurface,menuSurface,overworldHudSurface,battleHudSurface);

@override
String toString() {
  return 'ProjectSemanticThemeProfile(primary: $primary, onPrimary: $onPrimary, background: $background, surface: $surface, surfaceElevated: $surfaceElevated, textPrimary: $textPrimary, textSecondary: $textSecondary, outline: $outline, success: $success, warning: $warning, danger: $danger, titleSurface: $titleSurface, dialogueSurface: $dialogueSurface, menuSurface: $menuSurface, overworldHudSurface: $overworldHudSurface, battleHudSurface: $battleHudSurface)';
}


}

/// @nodoc
abstract mixin class $ProjectSemanticThemeProfileCopyWith<$Res>  {
  factory $ProjectSemanticThemeProfileCopyWith(ProjectSemanticThemeProfile value, $Res Function(ProjectSemanticThemeProfile) _then) = _$ProjectSemanticThemeProfileCopyWithImpl;
@useResult
$Res call({
 String primary, String onPrimary, String background, String surface, String surfaceElevated, String textPrimary, String textSecondary, String outline, String success, String warning, String danger, String titleSurface, String dialogueSurface, String menuSurface, String overworldHudSurface, String battleHudSurface
});




}
/// @nodoc
class _$ProjectSemanticThemeProfileCopyWithImpl<$Res>
    implements $ProjectSemanticThemeProfileCopyWith<$Res> {
  _$ProjectSemanticThemeProfileCopyWithImpl(this._self, this._then);

  final ProjectSemanticThemeProfile _self;
  final $Res Function(ProjectSemanticThemeProfile) _then;

/// Create a copy of ProjectSemanticThemeProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primary = null,Object? onPrimary = null,Object? background = null,Object? surface = null,Object? surfaceElevated = null,Object? textPrimary = null,Object? textSecondary = null,Object? outline = null,Object? success = null,Object? warning = null,Object? danger = null,Object? titleSurface = null,Object? dialogueSurface = null,Object? menuSurface = null,Object? overworldHudSurface = null,Object? battleHudSurface = null,}) {
  return _then(_self.copyWith(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as String,onPrimary: null == onPrimary ? _self.onPrimary : onPrimary // ignore: cast_nullable_to_non_nullable
as String,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String,surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String,surfaceElevated: null == surfaceElevated ? _self.surfaceElevated : surfaceElevated // ignore: cast_nullable_to_non_nullable
as String,textPrimary: null == textPrimary ? _self.textPrimary : textPrimary // ignore: cast_nullable_to_non_nullable
as String,textSecondary: null == textSecondary ? _self.textSecondary : textSecondary // ignore: cast_nullable_to_non_nullable
as String,outline: null == outline ? _self.outline : outline // ignore: cast_nullable_to_non_nullable
as String,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as String,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,danger: null == danger ? _self.danger : danger // ignore: cast_nullable_to_non_nullable
as String,titleSurface: null == titleSurface ? _self.titleSurface : titleSurface // ignore: cast_nullable_to_non_nullable
as String,dialogueSurface: null == dialogueSurface ? _self.dialogueSurface : dialogueSurface // ignore: cast_nullable_to_non_nullable
as String,menuSurface: null == menuSurface ? _self.menuSurface : menuSurface // ignore: cast_nullable_to_non_nullable
as String,overworldHudSurface: null == overworldHudSurface ? _self.overworldHudSurface : overworldHudSurface // ignore: cast_nullable_to_non_nullable
as String,battleHudSurface: null == battleHudSurface ? _self.battleHudSurface : battleHudSurface // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSemanticThemeProfile].
extension ProjectSemanticThemeProfilePatterns on ProjectSemanticThemeProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSemanticThemeProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSemanticThemeProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSemanticThemeProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSemanticThemeProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSemanticThemeProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSemanticThemeProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String primary,  String onPrimary,  String background,  String surface,  String surfaceElevated,  String textPrimary,  String textSecondary,  String outline,  String success,  String warning,  String danger,  String titleSurface,  String dialogueSurface,  String menuSurface,  String overworldHudSurface,  String battleHudSurface)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSemanticThemeProfile() when $default != null:
return $default(_that.primary,_that.onPrimary,_that.background,_that.surface,_that.surfaceElevated,_that.textPrimary,_that.textSecondary,_that.outline,_that.success,_that.warning,_that.danger,_that.titleSurface,_that.dialogueSurface,_that.menuSurface,_that.overworldHudSurface,_that.battleHudSurface);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String primary,  String onPrimary,  String background,  String surface,  String surfaceElevated,  String textPrimary,  String textSecondary,  String outline,  String success,  String warning,  String danger,  String titleSurface,  String dialogueSurface,  String menuSurface,  String overworldHudSurface,  String battleHudSurface)  $default,) {final _that = this;
switch (_that) {
case _ProjectSemanticThemeProfile():
return $default(_that.primary,_that.onPrimary,_that.background,_that.surface,_that.surfaceElevated,_that.textPrimary,_that.textSecondary,_that.outline,_that.success,_that.warning,_that.danger,_that.titleSurface,_that.dialogueSurface,_that.menuSurface,_that.overworldHudSurface,_that.battleHudSurface);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String primary,  String onPrimary,  String background,  String surface,  String surfaceElevated,  String textPrimary,  String textSecondary,  String outline,  String success,  String warning,  String danger,  String titleSurface,  String dialogueSurface,  String menuSurface,  String overworldHudSurface,  String battleHudSurface)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSemanticThemeProfile() when $default != null:
return $default(_that.primary,_that.onPrimary,_that.background,_that.surface,_that.surfaceElevated,_that.textPrimary,_that.textSecondary,_that.outline,_that.success,_that.warning,_that.danger,_that.titleSurface,_that.dialogueSurface,_that.menuSurface,_that.overworldHudSurface,_that.battleHudSurface);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSemanticThemeProfile implements ProjectSemanticThemeProfile {
  const _ProjectSemanticThemeProfile({required this.primary, required this.onPrimary, required this.background, required this.surface, required this.surfaceElevated, required this.textPrimary, required this.textSecondary, required this.outline, required this.success, required this.warning, required this.danger, required this.titleSurface, required this.dialogueSurface, required this.menuSurface, required this.overworldHudSurface, required this.battleHudSurface});
  factory _ProjectSemanticThemeProfile.fromJson(Map<String, dynamic> json) => _$ProjectSemanticThemeProfileFromJson(json);

@override final  String primary;
@override final  String onPrimary;
@override final  String background;
@override final  String surface;
@override final  String surfaceElevated;
@override final  String textPrimary;
@override final  String textSecondary;
@override final  String outline;
@override final  String success;
@override final  String warning;
@override final  String danger;
@override final  String titleSurface;
@override final  String dialogueSurface;
@override final  String menuSurface;
@override final  String overworldHudSurface;
@override final  String battleHudSurface;

/// Create a copy of ProjectSemanticThemeProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSemanticThemeProfileCopyWith<_ProjectSemanticThemeProfile> get copyWith => __$ProjectSemanticThemeProfileCopyWithImpl<_ProjectSemanticThemeProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSemanticThemeProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSemanticThemeProfile&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.onPrimary, onPrimary) || other.onPrimary == onPrimary)&&(identical(other.background, background) || other.background == background)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.surfaceElevated, surfaceElevated) || other.surfaceElevated == surfaceElevated)&&(identical(other.textPrimary, textPrimary) || other.textPrimary == textPrimary)&&(identical(other.textSecondary, textSecondary) || other.textSecondary == textSecondary)&&(identical(other.outline, outline) || other.outline == outline)&&(identical(other.success, success) || other.success == success)&&(identical(other.warning, warning) || other.warning == warning)&&(identical(other.danger, danger) || other.danger == danger)&&(identical(other.titleSurface, titleSurface) || other.titleSurface == titleSurface)&&(identical(other.dialogueSurface, dialogueSurface) || other.dialogueSurface == dialogueSurface)&&(identical(other.menuSurface, menuSurface) || other.menuSurface == menuSurface)&&(identical(other.overworldHudSurface, overworldHudSurface) || other.overworldHudSurface == overworldHudSurface)&&(identical(other.battleHudSurface, battleHudSurface) || other.battleHudSurface == battleHudSurface));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,primary,onPrimary,background,surface,surfaceElevated,textPrimary,textSecondary,outline,success,warning,danger,titleSurface,dialogueSurface,menuSurface,overworldHudSurface,battleHudSurface);

@override
String toString() {
  return 'ProjectSemanticThemeProfile(primary: $primary, onPrimary: $onPrimary, background: $background, surface: $surface, surfaceElevated: $surfaceElevated, textPrimary: $textPrimary, textSecondary: $textSecondary, outline: $outline, success: $success, warning: $warning, danger: $danger, titleSurface: $titleSurface, dialogueSurface: $dialogueSurface, menuSurface: $menuSurface, overworldHudSurface: $overworldHudSurface, battleHudSurface: $battleHudSurface)';
}


}

/// @nodoc
abstract mixin class _$ProjectSemanticThemeProfileCopyWith<$Res> implements $ProjectSemanticThemeProfileCopyWith<$Res> {
  factory _$ProjectSemanticThemeProfileCopyWith(_ProjectSemanticThemeProfile value, $Res Function(_ProjectSemanticThemeProfile) _then) = __$ProjectSemanticThemeProfileCopyWithImpl;
@override @useResult
$Res call({
 String primary, String onPrimary, String background, String surface, String surfaceElevated, String textPrimary, String textSecondary, String outline, String success, String warning, String danger, String titleSurface, String dialogueSurface, String menuSurface, String overworldHudSurface, String battleHudSurface
});




}
/// @nodoc
class __$ProjectSemanticThemeProfileCopyWithImpl<$Res>
    implements _$ProjectSemanticThemeProfileCopyWith<$Res> {
  __$ProjectSemanticThemeProfileCopyWithImpl(this._self, this._then);

  final _ProjectSemanticThemeProfile _self;
  final $Res Function(_ProjectSemanticThemeProfile) _then;

/// Create a copy of ProjectSemanticThemeProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primary = null,Object? onPrimary = null,Object? background = null,Object? surface = null,Object? surfaceElevated = null,Object? textPrimary = null,Object? textSecondary = null,Object? outline = null,Object? success = null,Object? warning = null,Object? danger = null,Object? titleSurface = null,Object? dialogueSurface = null,Object? menuSurface = null,Object? overworldHudSurface = null,Object? battleHudSurface = null,}) {
  return _then(_ProjectSemanticThemeProfile(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as String,onPrimary: null == onPrimary ? _self.onPrimary : onPrimary // ignore: cast_nullable_to_non_nullable
as String,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String,surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String,surfaceElevated: null == surfaceElevated ? _self.surfaceElevated : surfaceElevated // ignore: cast_nullable_to_non_nullable
as String,textPrimary: null == textPrimary ? _self.textPrimary : textPrimary // ignore: cast_nullable_to_non_nullable
as String,textSecondary: null == textSecondary ? _self.textSecondary : textSecondary // ignore: cast_nullable_to_non_nullable
as String,outline: null == outline ? _self.outline : outline // ignore: cast_nullable_to_non_nullable
as String,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as String,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,danger: null == danger ? _self.danger : danger // ignore: cast_nullable_to_non_nullable
as String,titleSurface: null == titleSurface ? _self.titleSurface : titleSurface // ignore: cast_nullable_to_non_nullable
as String,dialogueSurface: null == dialogueSurface ? _self.dialogueSurface : dialogueSurface // ignore: cast_nullable_to_non_nullable
as String,menuSurface: null == menuSurface ? _self.menuSurface : menuSurface // ignore: cast_nullable_to_non_nullable
as String,overworldHudSurface: null == overworldHudSurface ? _self.overworldHudSurface : overworldHudSurface // ignore: cast_nullable_to_non_nullable
as String,battleHudSurface: null == battleHudSurface ? _self.battleHudSurface : battleHudSurface // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProjectMenuLabelsProfile {

@JsonKey(includeIfNull: false) String? get pauseTitle;@JsonKey(includeIfNull: false) String? get resume;@JsonKey(includeIfNull: false) String? get party;@JsonKey(includeIfNull: false) String? get bag;@JsonKey(includeIfNull: false) String? get pokedex;@JsonKey(includeIfNull: false) String? get map;@JsonKey(includeIfNull: false) String? get save;@JsonKey(includeIfNull: false) String? get options;@JsonKey(includeIfNull: false) String? get returnToTitle;
/// Create a copy of ProjectMenuLabelsProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectMenuLabelsProfileCopyWith<ProjectMenuLabelsProfile> get copyWith => _$ProjectMenuLabelsProfileCopyWithImpl<ProjectMenuLabelsProfile>(this as ProjectMenuLabelsProfile, _$identity);

  /// Serializes this ProjectMenuLabelsProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectMenuLabelsProfile&&(identical(other.pauseTitle, pauseTitle) || other.pauseTitle == pauseTitle)&&(identical(other.resume, resume) || other.resume == resume)&&(identical(other.party, party) || other.party == party)&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.pokedex, pokedex) || other.pokedex == pokedex)&&(identical(other.map, map) || other.map == map)&&(identical(other.save, save) || other.save == save)&&(identical(other.options, options) || other.options == options)&&(identical(other.returnToTitle, returnToTitle) || other.returnToTitle == returnToTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pauseTitle,resume,party,bag,pokedex,map,save,options,returnToTitle);

@override
String toString() {
  return 'ProjectMenuLabelsProfile(pauseTitle: $pauseTitle, resume: $resume, party: $party, bag: $bag, pokedex: $pokedex, map: $map, save: $save, options: $options, returnToTitle: $returnToTitle)';
}


}

/// @nodoc
abstract mixin class $ProjectMenuLabelsProfileCopyWith<$Res>  {
  factory $ProjectMenuLabelsProfileCopyWith(ProjectMenuLabelsProfile value, $Res Function(ProjectMenuLabelsProfile) _then) = _$ProjectMenuLabelsProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? pauseTitle,@JsonKey(includeIfNull: false) String? resume,@JsonKey(includeIfNull: false) String? party,@JsonKey(includeIfNull: false) String? bag,@JsonKey(includeIfNull: false) String? pokedex,@JsonKey(includeIfNull: false) String? map,@JsonKey(includeIfNull: false) String? save,@JsonKey(includeIfNull: false) String? options,@JsonKey(includeIfNull: false) String? returnToTitle
});




}
/// @nodoc
class _$ProjectMenuLabelsProfileCopyWithImpl<$Res>
    implements $ProjectMenuLabelsProfileCopyWith<$Res> {
  _$ProjectMenuLabelsProfileCopyWithImpl(this._self, this._then);

  final ProjectMenuLabelsProfile _self;
  final $Res Function(ProjectMenuLabelsProfile) _then;

/// Create a copy of ProjectMenuLabelsProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pauseTitle = freezed,Object? resume = freezed,Object? party = freezed,Object? bag = freezed,Object? pokedex = freezed,Object? map = freezed,Object? save = freezed,Object? options = freezed,Object? returnToTitle = freezed,}) {
  return _then(_self.copyWith(
pauseTitle: freezed == pauseTitle ? _self.pauseTitle : pauseTitle // ignore: cast_nullable_to_non_nullable
as String?,resume: freezed == resume ? _self.resume : resume // ignore: cast_nullable_to_non_nullable
as String?,party: freezed == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as String?,bag: freezed == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as String?,pokedex: freezed == pokedex ? _self.pokedex : pokedex // ignore: cast_nullable_to_non_nullable
as String?,map: freezed == map ? _self.map : map // ignore: cast_nullable_to_non_nullable
as String?,save: freezed == save ? _self.save : save // ignore: cast_nullable_to_non_nullable
as String?,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as String?,returnToTitle: freezed == returnToTitle ? _self.returnToTitle : returnToTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectMenuLabelsProfile].
extension ProjectMenuLabelsProfilePatterns on ProjectMenuLabelsProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectMenuLabelsProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectMenuLabelsProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectMenuLabelsProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectMenuLabelsProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectMenuLabelsProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectMenuLabelsProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? pauseTitle, @JsonKey(includeIfNull: false)  String? resume, @JsonKey(includeIfNull: false)  String? party, @JsonKey(includeIfNull: false)  String? bag, @JsonKey(includeIfNull: false)  String? pokedex, @JsonKey(includeIfNull: false)  String? map, @JsonKey(includeIfNull: false)  String? save, @JsonKey(includeIfNull: false)  String? options, @JsonKey(includeIfNull: false)  String? returnToTitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectMenuLabelsProfile() when $default != null:
return $default(_that.pauseTitle,_that.resume,_that.party,_that.bag,_that.pokedex,_that.map,_that.save,_that.options,_that.returnToTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? pauseTitle, @JsonKey(includeIfNull: false)  String? resume, @JsonKey(includeIfNull: false)  String? party, @JsonKey(includeIfNull: false)  String? bag, @JsonKey(includeIfNull: false)  String? pokedex, @JsonKey(includeIfNull: false)  String? map, @JsonKey(includeIfNull: false)  String? save, @JsonKey(includeIfNull: false)  String? options, @JsonKey(includeIfNull: false)  String? returnToTitle)  $default,) {final _that = this;
switch (_that) {
case _ProjectMenuLabelsProfile():
return $default(_that.pauseTitle,_that.resume,_that.party,_that.bag,_that.pokedex,_that.map,_that.save,_that.options,_that.returnToTitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? pauseTitle, @JsonKey(includeIfNull: false)  String? resume, @JsonKey(includeIfNull: false)  String? party, @JsonKey(includeIfNull: false)  String? bag, @JsonKey(includeIfNull: false)  String? pokedex, @JsonKey(includeIfNull: false)  String? map, @JsonKey(includeIfNull: false)  String? save, @JsonKey(includeIfNull: false)  String? options, @JsonKey(includeIfNull: false)  String? returnToTitle)?  $default,) {final _that = this;
switch (_that) {
case _ProjectMenuLabelsProfile() when $default != null:
return $default(_that.pauseTitle,_that.resume,_that.party,_that.bag,_that.pokedex,_that.map,_that.save,_that.options,_that.returnToTitle);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectMenuLabelsProfile implements ProjectMenuLabelsProfile {
  const _ProjectMenuLabelsProfile({@JsonKey(includeIfNull: false) this.pauseTitle, @JsonKey(includeIfNull: false) this.resume, @JsonKey(includeIfNull: false) this.party, @JsonKey(includeIfNull: false) this.bag, @JsonKey(includeIfNull: false) this.pokedex, @JsonKey(includeIfNull: false) this.map, @JsonKey(includeIfNull: false) this.save, @JsonKey(includeIfNull: false) this.options, @JsonKey(includeIfNull: false) this.returnToTitle});
  factory _ProjectMenuLabelsProfile.fromJson(Map<String, dynamic> json) => _$ProjectMenuLabelsProfileFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? pauseTitle;
@override@JsonKey(includeIfNull: false) final  String? resume;
@override@JsonKey(includeIfNull: false) final  String? party;
@override@JsonKey(includeIfNull: false) final  String? bag;
@override@JsonKey(includeIfNull: false) final  String? pokedex;
@override@JsonKey(includeIfNull: false) final  String? map;
@override@JsonKey(includeIfNull: false) final  String? save;
@override@JsonKey(includeIfNull: false) final  String? options;
@override@JsonKey(includeIfNull: false) final  String? returnToTitle;

/// Create a copy of ProjectMenuLabelsProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectMenuLabelsProfileCopyWith<_ProjectMenuLabelsProfile> get copyWith => __$ProjectMenuLabelsProfileCopyWithImpl<_ProjectMenuLabelsProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectMenuLabelsProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectMenuLabelsProfile&&(identical(other.pauseTitle, pauseTitle) || other.pauseTitle == pauseTitle)&&(identical(other.resume, resume) || other.resume == resume)&&(identical(other.party, party) || other.party == party)&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.pokedex, pokedex) || other.pokedex == pokedex)&&(identical(other.map, map) || other.map == map)&&(identical(other.save, save) || other.save == save)&&(identical(other.options, options) || other.options == options)&&(identical(other.returnToTitle, returnToTitle) || other.returnToTitle == returnToTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pauseTitle,resume,party,bag,pokedex,map,save,options,returnToTitle);

@override
String toString() {
  return 'ProjectMenuLabelsProfile(pauseTitle: $pauseTitle, resume: $resume, party: $party, bag: $bag, pokedex: $pokedex, map: $map, save: $save, options: $options, returnToTitle: $returnToTitle)';
}


}

/// @nodoc
abstract mixin class _$ProjectMenuLabelsProfileCopyWith<$Res> implements $ProjectMenuLabelsProfileCopyWith<$Res> {
  factory _$ProjectMenuLabelsProfileCopyWith(_ProjectMenuLabelsProfile value, $Res Function(_ProjectMenuLabelsProfile) _then) = __$ProjectMenuLabelsProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? pauseTitle,@JsonKey(includeIfNull: false) String? resume,@JsonKey(includeIfNull: false) String? party,@JsonKey(includeIfNull: false) String? bag,@JsonKey(includeIfNull: false) String? pokedex,@JsonKey(includeIfNull: false) String? map,@JsonKey(includeIfNull: false) String? save,@JsonKey(includeIfNull: false) String? options,@JsonKey(includeIfNull: false) String? returnToTitle
});




}
/// @nodoc
class __$ProjectMenuLabelsProfileCopyWithImpl<$Res>
    implements _$ProjectMenuLabelsProfileCopyWith<$Res> {
  __$ProjectMenuLabelsProfileCopyWithImpl(this._self, this._then);

  final _ProjectMenuLabelsProfile _self;
  final $Res Function(_ProjectMenuLabelsProfile) _then;

/// Create a copy of ProjectMenuLabelsProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pauseTitle = freezed,Object? resume = freezed,Object? party = freezed,Object? bag = freezed,Object? pokedex = freezed,Object? map = freezed,Object? save = freezed,Object? options = freezed,Object? returnToTitle = freezed,}) {
  return _then(_ProjectMenuLabelsProfile(
pauseTitle: freezed == pauseTitle ? _self.pauseTitle : pauseTitle // ignore: cast_nullable_to_non_nullable
as String?,resume: freezed == resume ? _self.resume : resume // ignore: cast_nullable_to_non_nullable
as String?,party: freezed == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as String?,bag: freezed == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as String?,pokedex: freezed == pokedex ? _self.pokedex : pokedex // ignore: cast_nullable_to_non_nullable
as String?,map: freezed == map ? _self.map : map // ignore: cast_nullable_to_non_nullable
as String?,save: freezed == save ? _self.save : save // ignore: cast_nullable_to_non_nullable
as String?,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as String?,returnToTitle: freezed == returnToTitle ? _self.returnToTitle : returnToTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProjectPresentationProfile {

 int get schemaVersion; ProjectBrandingProfile get branding;@JsonKey(includeIfNull: false) ProjectIntroVideoProfile? get intro;@JsonKey(includeIfNull: false) ProjectTitleMotionProfile? get titleMotion;@JsonKey(includeIfNull: false) ProjectTypographyProfile? get typography;@JsonKey(includeIfNull: false) ProjectSemanticThemeProfile? get theme;@JsonKey(includeIfNull: false) ProjectMenuLabelsProfile? get menuLabels;@JsonKey(includeIfNull: false) ProjectPresentationWindowsProfile? get windows;@JsonKey(includeIfNull: false) ProjectPresentationLayoutsProfile? get layouts;
/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectPresentationProfileCopyWith<ProjectPresentationProfile> get copyWith => _$ProjectPresentationProfileCopyWithImpl<ProjectPresentationProfile>(this as ProjectPresentationProfile, _$identity);

  /// Serializes this ProjectPresentationProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectPresentationProfile&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.branding, branding) || other.branding == branding)&&(identical(other.intro, intro) || other.intro == intro)&&(identical(other.titleMotion, titleMotion) || other.titleMotion == titleMotion)&&(identical(other.typography, typography) || other.typography == typography)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.menuLabels, menuLabels) || other.menuLabels == menuLabels)&&(identical(other.windows, windows) || other.windows == windows)&&(identical(other.layouts, layouts) || other.layouts == layouts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,branding,intro,titleMotion,typography,theme,menuLabels,windows,layouts);

@override
String toString() {
  return 'ProjectPresentationProfile(schemaVersion: $schemaVersion, branding: $branding, intro: $intro, titleMotion: $titleMotion, typography: $typography, theme: $theme, menuLabels: $menuLabels, windows: $windows, layouts: $layouts)';
}


}

/// @nodoc
abstract mixin class $ProjectPresentationProfileCopyWith<$Res>  {
  factory $ProjectPresentationProfileCopyWith(ProjectPresentationProfile value, $Res Function(ProjectPresentationProfile) _then) = _$ProjectPresentationProfileCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, ProjectBrandingProfile branding,@JsonKey(includeIfNull: false) ProjectIntroVideoProfile? intro,@JsonKey(includeIfNull: false) ProjectTitleMotionProfile? titleMotion,@JsonKey(includeIfNull: false) ProjectTypographyProfile? typography,@JsonKey(includeIfNull: false) ProjectSemanticThemeProfile? theme,@JsonKey(includeIfNull: false) ProjectMenuLabelsProfile? menuLabels,@JsonKey(includeIfNull: false) ProjectPresentationWindowsProfile? windows,@JsonKey(includeIfNull: false) ProjectPresentationLayoutsProfile? layouts
});


$ProjectBrandingProfileCopyWith<$Res> get branding;$ProjectIntroVideoProfileCopyWith<$Res>? get intro;$ProjectTitleMotionProfileCopyWith<$Res>? get titleMotion;$ProjectTypographyProfileCopyWith<$Res>? get typography;$ProjectSemanticThemeProfileCopyWith<$Res>? get theme;$ProjectMenuLabelsProfileCopyWith<$Res>? get menuLabels;$ProjectPresentationWindowsProfileCopyWith<$Res>? get windows;$ProjectPresentationLayoutsProfileCopyWith<$Res>? get layouts;

}
/// @nodoc
class _$ProjectPresentationProfileCopyWithImpl<$Res>
    implements $ProjectPresentationProfileCopyWith<$Res> {
  _$ProjectPresentationProfileCopyWithImpl(this._self, this._then);

  final ProjectPresentationProfile _self;
  final $Res Function(ProjectPresentationProfile) _then;

/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? branding = null,Object? intro = freezed,Object? titleMotion = freezed,Object? typography = freezed,Object? theme = freezed,Object? menuLabels = freezed,Object? windows = freezed,Object? layouts = freezed,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,branding: null == branding ? _self.branding : branding // ignore: cast_nullable_to_non_nullable
as ProjectBrandingProfile,intro: freezed == intro ? _self.intro : intro // ignore: cast_nullable_to_non_nullable
as ProjectIntroVideoProfile?,titleMotion: freezed == titleMotion ? _self.titleMotion : titleMotion // ignore: cast_nullable_to_non_nullable
as ProjectTitleMotionProfile?,typography: freezed == typography ? _self.typography : typography // ignore: cast_nullable_to_non_nullable
as ProjectTypographyProfile?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ProjectSemanticThemeProfile?,menuLabels: freezed == menuLabels ? _self.menuLabels : menuLabels // ignore: cast_nullable_to_non_nullable
as ProjectMenuLabelsProfile?,windows: freezed == windows ? _self.windows : windows // ignore: cast_nullable_to_non_nullable
as ProjectPresentationWindowsProfile?,layouts: freezed == layouts ? _self.layouts : layouts // ignore: cast_nullable_to_non_nullable
as ProjectPresentationLayoutsProfile?,
  ));
}
/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBrandingProfileCopyWith<$Res> get branding {

  return $ProjectBrandingProfileCopyWith<$Res>(_self.branding, (value) {
    return _then(_self.copyWith(branding: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectIntroVideoProfileCopyWith<$Res>? get intro {
    if (_self.intro == null) {
    return null;
  }

  return $ProjectIntroVideoProfileCopyWith<$Res>(_self.intro!, (value) {
    return _then(_self.copyWith(intro: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTitleMotionProfileCopyWith<$Res>? get titleMotion {
    if (_self.titleMotion == null) {
    return null;
  }

  return $ProjectTitleMotionProfileCopyWith<$Res>(_self.titleMotion!, (value) {
    return _then(_self.copyWith(titleMotion: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyProfileCopyWith<$Res>? get typography {
    if (_self.typography == null) {
    return null;
  }

  return $ProjectTypographyProfileCopyWith<$Res>(_self.typography!, (value) {
    return _then(_self.copyWith(typography: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSemanticThemeProfileCopyWith<$Res>? get theme {
    if (_self.theme == null) {
    return null;
  }

  return $ProjectSemanticThemeProfileCopyWith<$Res>(_self.theme!, (value) {
    return _then(_self.copyWith(theme: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectMenuLabelsProfileCopyWith<$Res>? get menuLabels {
    if (_self.menuLabels == null) {
    return null;
  }

  return $ProjectMenuLabelsProfileCopyWith<$Res>(_self.menuLabels!, (value) {
    return _then(_self.copyWith(menuLabels: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectPresentationWindowsProfileCopyWith<$Res>? get windows {
    if (_self.windows == null) {
    return null;
  }

  return $ProjectPresentationWindowsProfileCopyWith<$Res>(_self.windows!, (value) {
    return _then(_self.copyWith(windows: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectPresentationLayoutsProfileCopyWith<$Res>? get layouts {
    if (_self.layouts == null) {
    return null;
  }

  return $ProjectPresentationLayoutsProfileCopyWith<$Res>(_self.layouts!, (value) {
    return _then(_self.copyWith(layouts: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectPresentationProfile].
extension ProjectPresentationProfilePatterns on ProjectPresentationProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectPresentationProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectPresentationProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectPresentationProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectPresentationProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  ProjectBrandingProfile branding, @JsonKey(includeIfNull: false)  ProjectIntroVideoProfile? intro, @JsonKey(includeIfNull: false)  ProjectTitleMotionProfile? titleMotion, @JsonKey(includeIfNull: false)  ProjectTypographyProfile? typography, @JsonKey(includeIfNull: false)  ProjectSemanticThemeProfile? theme, @JsonKey(includeIfNull: false)  ProjectMenuLabelsProfile? menuLabels, @JsonKey(includeIfNull: false)  ProjectPresentationWindowsProfile? windows, @JsonKey(includeIfNull: false)  ProjectPresentationLayoutsProfile? layouts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectPresentationProfile() when $default != null:
return $default(_that.schemaVersion,_that.branding,_that.intro,_that.titleMotion,_that.typography,_that.theme,_that.menuLabels,_that.windows,_that.layouts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  ProjectBrandingProfile branding, @JsonKey(includeIfNull: false)  ProjectIntroVideoProfile? intro, @JsonKey(includeIfNull: false)  ProjectTitleMotionProfile? titleMotion, @JsonKey(includeIfNull: false)  ProjectTypographyProfile? typography, @JsonKey(includeIfNull: false)  ProjectSemanticThemeProfile? theme, @JsonKey(includeIfNull: false)  ProjectMenuLabelsProfile? menuLabels, @JsonKey(includeIfNull: false)  ProjectPresentationWindowsProfile? windows, @JsonKey(includeIfNull: false)  ProjectPresentationLayoutsProfile? layouts)  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationProfile():
return $default(_that.schemaVersion,_that.branding,_that.intro,_that.titleMotion,_that.typography,_that.theme,_that.menuLabels,_that.windows,_that.layouts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  ProjectBrandingProfile branding, @JsonKey(includeIfNull: false)  ProjectIntroVideoProfile? intro, @JsonKey(includeIfNull: false)  ProjectTitleMotionProfile? titleMotion, @JsonKey(includeIfNull: false)  ProjectTypographyProfile? typography, @JsonKey(includeIfNull: false)  ProjectSemanticThemeProfile? theme, @JsonKey(includeIfNull: false)  ProjectMenuLabelsProfile? menuLabels, @JsonKey(includeIfNull: false)  ProjectPresentationWindowsProfile? windows, @JsonKey(includeIfNull: false)  ProjectPresentationLayoutsProfile? layouts)?  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationProfile() when $default != null:
return $default(_that.schemaVersion,_that.branding,_that.intro,_that.titleMotion,_that.typography,_that.theme,_that.menuLabels,_that.windows,_that.layouts);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectPresentationProfile extends ProjectPresentationProfile {
  const _ProjectPresentationProfile({this.schemaVersion = ProjectPresentationProfile.supportedSchemaVersion, this.branding = const ProjectBrandingProfile(), @JsonKey(includeIfNull: false) this.intro, @JsonKey(includeIfNull: false) this.titleMotion, @JsonKey(includeIfNull: false) this.typography, @JsonKey(includeIfNull: false) this.theme, @JsonKey(includeIfNull: false) this.menuLabels, @JsonKey(includeIfNull: false) this.windows, @JsonKey(includeIfNull: false) this.layouts}): super._();
  factory _ProjectPresentationProfile.fromJson(Map<String, dynamic> json) => _$ProjectPresentationProfileFromJson(json);

@override@JsonKey() final  int schemaVersion;
@override@JsonKey() final  ProjectBrandingProfile branding;
@override@JsonKey(includeIfNull: false) final  ProjectIntroVideoProfile? intro;
@override@JsonKey(includeIfNull: false) final  ProjectTitleMotionProfile? titleMotion;
@override@JsonKey(includeIfNull: false) final  ProjectTypographyProfile? typography;
@override@JsonKey(includeIfNull: false) final  ProjectSemanticThemeProfile? theme;
@override@JsonKey(includeIfNull: false) final  ProjectMenuLabelsProfile? menuLabels;
@override@JsonKey(includeIfNull: false) final  ProjectPresentationWindowsProfile? windows;
@override@JsonKey(includeIfNull: false) final  ProjectPresentationLayoutsProfile? layouts;

/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectPresentationProfileCopyWith<_ProjectPresentationProfile> get copyWith => __$ProjectPresentationProfileCopyWithImpl<_ProjectPresentationProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectPresentationProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectPresentationProfile&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.branding, branding) || other.branding == branding)&&(identical(other.intro, intro) || other.intro == intro)&&(identical(other.titleMotion, titleMotion) || other.titleMotion == titleMotion)&&(identical(other.typography, typography) || other.typography == typography)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.menuLabels, menuLabels) || other.menuLabels == menuLabels)&&(identical(other.windows, windows) || other.windows == windows)&&(identical(other.layouts, layouts) || other.layouts == layouts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,branding,intro,titleMotion,typography,theme,menuLabels,windows,layouts);

@override
String toString() {
  return 'ProjectPresentationProfile(schemaVersion: $schemaVersion, branding: $branding, intro: $intro, titleMotion: $titleMotion, typography: $typography, theme: $theme, menuLabels: $menuLabels, windows: $windows, layouts: $layouts)';
}


}

/// @nodoc
abstract mixin class _$ProjectPresentationProfileCopyWith<$Res> implements $ProjectPresentationProfileCopyWith<$Res> {
  factory _$ProjectPresentationProfileCopyWith(_ProjectPresentationProfile value, $Res Function(_ProjectPresentationProfile) _then) = __$ProjectPresentationProfileCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, ProjectBrandingProfile branding,@JsonKey(includeIfNull: false) ProjectIntroVideoProfile? intro,@JsonKey(includeIfNull: false) ProjectTitleMotionProfile? titleMotion,@JsonKey(includeIfNull: false) ProjectTypographyProfile? typography,@JsonKey(includeIfNull: false) ProjectSemanticThemeProfile? theme,@JsonKey(includeIfNull: false) ProjectMenuLabelsProfile? menuLabels,@JsonKey(includeIfNull: false) ProjectPresentationWindowsProfile? windows,@JsonKey(includeIfNull: false) ProjectPresentationLayoutsProfile? layouts
});


@override $ProjectBrandingProfileCopyWith<$Res> get branding;@override $ProjectIntroVideoProfileCopyWith<$Res>? get intro;@override $ProjectTitleMotionProfileCopyWith<$Res>? get titleMotion;@override $ProjectTypographyProfileCopyWith<$Res>? get typography;@override $ProjectSemanticThemeProfileCopyWith<$Res>? get theme;@override $ProjectMenuLabelsProfileCopyWith<$Res>? get menuLabels;@override $ProjectPresentationWindowsProfileCopyWith<$Res>? get windows;@override $ProjectPresentationLayoutsProfileCopyWith<$Res>? get layouts;

}
/// @nodoc
class __$ProjectPresentationProfileCopyWithImpl<$Res>
    implements _$ProjectPresentationProfileCopyWith<$Res> {
  __$ProjectPresentationProfileCopyWithImpl(this._self, this._then);

  final _ProjectPresentationProfile _self;
  final $Res Function(_ProjectPresentationProfile) _then;

/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? branding = null,Object? intro = freezed,Object? titleMotion = freezed,Object? typography = freezed,Object? theme = freezed,Object? menuLabels = freezed,Object? windows = freezed,Object? layouts = freezed,}) {
  return _then(_ProjectPresentationProfile(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,branding: null == branding ? _self.branding : branding // ignore: cast_nullable_to_non_nullable
as ProjectBrandingProfile,intro: freezed == intro ? _self.intro : intro // ignore: cast_nullable_to_non_nullable
as ProjectIntroVideoProfile?,titleMotion: freezed == titleMotion ? _self.titleMotion : titleMotion // ignore: cast_nullable_to_non_nullable
as ProjectTitleMotionProfile?,typography: freezed == typography ? _self.typography : typography // ignore: cast_nullable_to_non_nullable
as ProjectTypographyProfile?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ProjectSemanticThemeProfile?,menuLabels: freezed == menuLabels ? _self.menuLabels : menuLabels // ignore: cast_nullable_to_non_nullable
as ProjectMenuLabelsProfile?,windows: freezed == windows ? _self.windows : windows // ignore: cast_nullable_to_non_nullable
as ProjectPresentationWindowsProfile?,layouts: freezed == layouts ? _self.layouts : layouts // ignore: cast_nullable_to_non_nullable
as ProjectPresentationLayoutsProfile?,
  ));
}

/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBrandingProfileCopyWith<$Res> get branding {

  return $ProjectBrandingProfileCopyWith<$Res>(_self.branding, (value) {
    return _then(_self.copyWith(branding: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectIntroVideoProfileCopyWith<$Res>? get intro {
    if (_self.intro == null) {
    return null;
  }

  return $ProjectIntroVideoProfileCopyWith<$Res>(_self.intro!, (value) {
    return _then(_self.copyWith(intro: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTitleMotionProfileCopyWith<$Res>? get titleMotion {
    if (_self.titleMotion == null) {
    return null;
  }

  return $ProjectTitleMotionProfileCopyWith<$Res>(_self.titleMotion!, (value) {
    return _then(_self.copyWith(titleMotion: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectTypographyProfileCopyWith<$Res>? get typography {
    if (_self.typography == null) {
    return null;
  }

  return $ProjectTypographyProfileCopyWith<$Res>(_self.typography!, (value) {
    return _then(_self.copyWith(typography: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSemanticThemeProfileCopyWith<$Res>? get theme {
    if (_self.theme == null) {
    return null;
  }

  return $ProjectSemanticThemeProfileCopyWith<$Res>(_self.theme!, (value) {
    return _then(_self.copyWith(theme: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectMenuLabelsProfileCopyWith<$Res>? get menuLabels {
    if (_self.menuLabels == null) {
    return null;
  }

  return $ProjectMenuLabelsProfileCopyWith<$Res>(_self.menuLabels!, (value) {
    return _then(_self.copyWith(menuLabels: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectPresentationWindowsProfileCopyWith<$Res>? get windows {
    if (_self.windows == null) {
    return null;
  }

  return $ProjectPresentationWindowsProfileCopyWith<$Res>(_self.windows!, (value) {
    return _then(_self.copyWith(windows: value));
  });
}/// Create a copy of ProjectPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectPresentationLayoutsProfileCopyWith<$Res>? get layouts {
    if (_self.layouts == null) {
    return null;
  }

  return $ProjectPresentationLayoutsProfileCopyWith<$Res>(_self.layouts!, (value) {
    return _then(_self.copyWith(layouts: value));
  });
}
}

// dart format on
