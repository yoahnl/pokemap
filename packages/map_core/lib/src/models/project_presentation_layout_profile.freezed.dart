// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_presentation_layout_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectSurfaceLayoutVariant {

 ProjectPresentationBreakpoint get breakpoint; ProjectPresentationLayoutSlot get slot; ProjectPresentationContentWidth get width; ProjectPresentationSpacing get spacing; ProjectPresentationScreenMargin get screenMargin; List<ProjectPresentationSecondaryElement> get visibleSecondaryElements;
/// Create a copy of ProjectSurfaceLayoutVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSurfaceLayoutVariantCopyWith<ProjectSurfaceLayoutVariant> get copyWith => _$ProjectSurfaceLayoutVariantCopyWithImpl<ProjectSurfaceLayoutVariant>(this as ProjectSurfaceLayoutVariant, _$identity);

  /// Serializes this ProjectSurfaceLayoutVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSurfaceLayoutVariant&&(identical(other.breakpoint, breakpoint) || other.breakpoint == breakpoint)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.width, width) || other.width == width)&&(identical(other.spacing, spacing) || other.spacing == spacing)&&(identical(other.screenMargin, screenMargin) || other.screenMargin == screenMargin)&&const DeepCollectionEquality().equals(other.visibleSecondaryElements, visibleSecondaryElements));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,breakpoint,slot,width,spacing,screenMargin,const DeepCollectionEquality().hash(visibleSecondaryElements));

@override
String toString() {
  return 'ProjectSurfaceLayoutVariant(breakpoint: $breakpoint, slot: $slot, width: $width, spacing: $spacing, screenMargin: $screenMargin, visibleSecondaryElements: $visibleSecondaryElements)';
}


}

/// @nodoc
abstract mixin class $ProjectSurfaceLayoutVariantCopyWith<$Res>  {
  factory $ProjectSurfaceLayoutVariantCopyWith(ProjectSurfaceLayoutVariant value, $Res Function(ProjectSurfaceLayoutVariant) _then) = _$ProjectSurfaceLayoutVariantCopyWithImpl;
@useResult
$Res call({
 ProjectPresentationBreakpoint breakpoint, ProjectPresentationLayoutSlot slot, ProjectPresentationContentWidth width, ProjectPresentationSpacing spacing, ProjectPresentationScreenMargin screenMargin, List<ProjectPresentationSecondaryElement> visibleSecondaryElements
});




}
/// @nodoc
class _$ProjectSurfaceLayoutVariantCopyWithImpl<$Res>
    implements $ProjectSurfaceLayoutVariantCopyWith<$Res> {
  _$ProjectSurfaceLayoutVariantCopyWithImpl(this._self, this._then);

  final ProjectSurfaceLayoutVariant _self;
  final $Res Function(ProjectSurfaceLayoutVariant) _then;

/// Create a copy of ProjectSurfaceLayoutVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? breakpoint = null,Object? slot = null,Object? width = null,Object? spacing = null,Object? screenMargin = null,Object? visibleSecondaryElements = null,}) {
  return _then(_self.copyWith(
breakpoint: null == breakpoint ? _self.breakpoint : breakpoint // ignore: cast_nullable_to_non_nullable
as ProjectPresentationBreakpoint,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as ProjectPresentationLayoutSlot,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as ProjectPresentationContentWidth,spacing: null == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as ProjectPresentationSpacing,screenMargin: null == screenMargin ? _self.screenMargin : screenMargin // ignore: cast_nullable_to_non_nullable
as ProjectPresentationScreenMargin,visibleSecondaryElements: null == visibleSecondaryElements ? _self.visibleSecondaryElements : visibleSecondaryElements // ignore: cast_nullable_to_non_nullable
as List<ProjectPresentationSecondaryElement>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSurfaceLayoutVariant].
extension ProjectSurfaceLayoutVariantPatterns on ProjectSurfaceLayoutVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSurfaceLayoutVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSurfaceLayoutVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSurfaceLayoutVariant value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSurfaceLayoutVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSurfaceLayoutVariant value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSurfaceLayoutVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectPresentationBreakpoint breakpoint,  ProjectPresentationLayoutSlot slot,  ProjectPresentationContentWidth width,  ProjectPresentationSpacing spacing,  ProjectPresentationScreenMargin screenMargin,  List<ProjectPresentationSecondaryElement> visibleSecondaryElements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSurfaceLayoutVariant() when $default != null:
return $default(_that.breakpoint,_that.slot,_that.width,_that.spacing,_that.screenMargin,_that.visibleSecondaryElements);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectPresentationBreakpoint breakpoint,  ProjectPresentationLayoutSlot slot,  ProjectPresentationContentWidth width,  ProjectPresentationSpacing spacing,  ProjectPresentationScreenMargin screenMargin,  List<ProjectPresentationSecondaryElement> visibleSecondaryElements)  $default,) {final _that = this;
switch (_that) {
case _ProjectSurfaceLayoutVariant():
return $default(_that.breakpoint,_that.slot,_that.width,_that.spacing,_that.screenMargin,_that.visibleSecondaryElements);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectPresentationBreakpoint breakpoint,  ProjectPresentationLayoutSlot slot,  ProjectPresentationContentWidth width,  ProjectPresentationSpacing spacing,  ProjectPresentationScreenMargin screenMargin,  List<ProjectPresentationSecondaryElement> visibleSecondaryElements)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSurfaceLayoutVariant() when $default != null:
return $default(_that.breakpoint,_that.slot,_that.width,_that.spacing,_that.screenMargin,_that.visibleSecondaryElements);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSurfaceLayoutVariant implements ProjectSurfaceLayoutVariant {
  const _ProjectSurfaceLayoutVariant({required this.breakpoint, required this.slot, this.width = ProjectPresentationContentWidth.comfortable, this.spacing = ProjectPresentationSpacing.normal, this.screenMargin = ProjectPresentationScreenMargin.compact, final  List<ProjectPresentationSecondaryElement> visibleSecondaryElements = const <ProjectPresentationSecondaryElement>[]}): _visibleSecondaryElements = visibleSecondaryElements;
  factory _ProjectSurfaceLayoutVariant.fromJson(Map<String, dynamic> json) => _$ProjectSurfaceLayoutVariantFromJson(json);

@override final  ProjectPresentationBreakpoint breakpoint;
@override final  ProjectPresentationLayoutSlot slot;
@override@JsonKey() final  ProjectPresentationContentWidth width;
@override@JsonKey() final  ProjectPresentationSpacing spacing;
@override@JsonKey() final  ProjectPresentationScreenMargin screenMargin;
 final  List<ProjectPresentationSecondaryElement> _visibleSecondaryElements;
@override@JsonKey() List<ProjectPresentationSecondaryElement> get visibleSecondaryElements {
  if (_visibleSecondaryElements is EqualUnmodifiableListView) return _visibleSecondaryElements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visibleSecondaryElements);
}


/// Create a copy of ProjectSurfaceLayoutVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSurfaceLayoutVariantCopyWith<_ProjectSurfaceLayoutVariant> get copyWith => __$ProjectSurfaceLayoutVariantCopyWithImpl<_ProjectSurfaceLayoutVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSurfaceLayoutVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSurfaceLayoutVariant&&(identical(other.breakpoint, breakpoint) || other.breakpoint == breakpoint)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.width, width) || other.width == width)&&(identical(other.spacing, spacing) || other.spacing == spacing)&&(identical(other.screenMargin, screenMargin) || other.screenMargin == screenMargin)&&const DeepCollectionEquality().equals(other._visibleSecondaryElements, _visibleSecondaryElements));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,breakpoint,slot,width,spacing,screenMargin,const DeepCollectionEquality().hash(_visibleSecondaryElements));

@override
String toString() {
  return 'ProjectSurfaceLayoutVariant(breakpoint: $breakpoint, slot: $slot, width: $width, spacing: $spacing, screenMargin: $screenMargin, visibleSecondaryElements: $visibleSecondaryElements)';
}


}

/// @nodoc
abstract mixin class _$ProjectSurfaceLayoutVariantCopyWith<$Res> implements $ProjectSurfaceLayoutVariantCopyWith<$Res> {
  factory _$ProjectSurfaceLayoutVariantCopyWith(_ProjectSurfaceLayoutVariant value, $Res Function(_ProjectSurfaceLayoutVariant) _then) = __$ProjectSurfaceLayoutVariantCopyWithImpl;
@override @useResult
$Res call({
 ProjectPresentationBreakpoint breakpoint, ProjectPresentationLayoutSlot slot, ProjectPresentationContentWidth width, ProjectPresentationSpacing spacing, ProjectPresentationScreenMargin screenMargin, List<ProjectPresentationSecondaryElement> visibleSecondaryElements
});




}
/// @nodoc
class __$ProjectSurfaceLayoutVariantCopyWithImpl<$Res>
    implements _$ProjectSurfaceLayoutVariantCopyWith<$Res> {
  __$ProjectSurfaceLayoutVariantCopyWithImpl(this._self, this._then);

  final _ProjectSurfaceLayoutVariant _self;
  final $Res Function(_ProjectSurfaceLayoutVariant) _then;

/// Create a copy of ProjectSurfaceLayoutVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? breakpoint = null,Object? slot = null,Object? width = null,Object? spacing = null,Object? screenMargin = null,Object? visibleSecondaryElements = null,}) {
  return _then(_ProjectSurfaceLayoutVariant(
breakpoint: null == breakpoint ? _self.breakpoint : breakpoint // ignore: cast_nullable_to_non_nullable
as ProjectPresentationBreakpoint,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as ProjectPresentationLayoutSlot,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as ProjectPresentationContentWidth,spacing: null == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as ProjectPresentationSpacing,screenMargin: null == screenMargin ? _self.screenMargin : screenMargin // ignore: cast_nullable_to_non_nullable
as ProjectPresentationScreenMargin,visibleSecondaryElements: null == visibleSecondaryElements ? _self._visibleSecondaryElements : visibleSecondaryElements // ignore: cast_nullable_to_non_nullable
as List<ProjectPresentationSecondaryElement>,
  ));
}


}


/// @nodoc
mixin _$ProjectResponsiveSurfaceLayoutProfile {

 ProjectSurfaceLayoutVariant get compact; ProjectSurfaceLayoutVariant get regular; ProjectSurfaceLayoutVariant get expanded;
/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<ProjectResponsiveSurfaceLayoutProfile> get copyWith => _$ProjectResponsiveSurfaceLayoutProfileCopyWithImpl<ProjectResponsiveSurfaceLayoutProfile>(this as ProjectResponsiveSurfaceLayoutProfile, _$identity);

  /// Serializes this ProjectResponsiveSurfaceLayoutProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectResponsiveSurfaceLayoutProfile&&(identical(other.compact, compact) || other.compact == compact)&&(identical(other.regular, regular) || other.regular == regular)&&(identical(other.expanded, expanded) || other.expanded == expanded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,compact,regular,expanded);

@override
String toString() {
  return 'ProjectResponsiveSurfaceLayoutProfile(compact: $compact, regular: $regular, expanded: $expanded)';
}


}

/// @nodoc
abstract mixin class $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>  {
  factory $ProjectResponsiveSurfaceLayoutProfileCopyWith(ProjectResponsiveSurfaceLayoutProfile value, $Res Function(ProjectResponsiveSurfaceLayoutProfile) _then) = _$ProjectResponsiveSurfaceLayoutProfileCopyWithImpl;
@useResult
$Res call({
 ProjectSurfaceLayoutVariant compact, ProjectSurfaceLayoutVariant regular, ProjectSurfaceLayoutVariant expanded
});


$ProjectSurfaceLayoutVariantCopyWith<$Res> get compact;$ProjectSurfaceLayoutVariantCopyWith<$Res> get regular;$ProjectSurfaceLayoutVariantCopyWith<$Res> get expanded;

}
/// @nodoc
class _$ProjectResponsiveSurfaceLayoutProfileCopyWithImpl<$Res>
    implements $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> {
  _$ProjectResponsiveSurfaceLayoutProfileCopyWithImpl(this._self, this._then);

  final ProjectResponsiveSurfaceLayoutProfile _self;
  final $Res Function(ProjectResponsiveSurfaceLayoutProfile) _then;

/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? compact = null,Object? regular = null,Object? expanded = null,}) {
  return _then(_self.copyWith(
compact: null == compact ? _self.compact : compact // ignore: cast_nullable_to_non_nullable
as ProjectSurfaceLayoutVariant,regular: null == regular ? _self.regular : regular // ignore: cast_nullable_to_non_nullable
as ProjectSurfaceLayoutVariant,expanded: null == expanded ? _self.expanded : expanded // ignore: cast_nullable_to_non_nullable
as ProjectSurfaceLayoutVariant,
  ));
}
/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfaceLayoutVariantCopyWith<$Res> get compact {

  return $ProjectSurfaceLayoutVariantCopyWith<$Res>(_self.compact, (value) {
    return _then(_self.copyWith(compact: value));
  });
}/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfaceLayoutVariantCopyWith<$Res> get regular {

  return $ProjectSurfaceLayoutVariantCopyWith<$Res>(_self.regular, (value) {
    return _then(_self.copyWith(regular: value));
  });
}/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfaceLayoutVariantCopyWith<$Res> get expanded {

  return $ProjectSurfaceLayoutVariantCopyWith<$Res>(_self.expanded, (value) {
    return _then(_self.copyWith(expanded: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectResponsiveSurfaceLayoutProfile].
extension ProjectResponsiveSurfaceLayoutProfilePatterns on ProjectResponsiveSurfaceLayoutProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectResponsiveSurfaceLayoutProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectResponsiveSurfaceLayoutProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectResponsiveSurfaceLayoutProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectResponsiveSurfaceLayoutProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectResponsiveSurfaceLayoutProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectResponsiveSurfaceLayoutProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectSurfaceLayoutVariant compact,  ProjectSurfaceLayoutVariant regular,  ProjectSurfaceLayoutVariant expanded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectResponsiveSurfaceLayoutProfile() when $default != null:
return $default(_that.compact,_that.regular,_that.expanded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectSurfaceLayoutVariant compact,  ProjectSurfaceLayoutVariant regular,  ProjectSurfaceLayoutVariant expanded)  $default,) {final _that = this;
switch (_that) {
case _ProjectResponsiveSurfaceLayoutProfile():
return $default(_that.compact,_that.regular,_that.expanded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectSurfaceLayoutVariant compact,  ProjectSurfaceLayoutVariant regular,  ProjectSurfaceLayoutVariant expanded)?  $default,) {final _that = this;
switch (_that) {
case _ProjectResponsiveSurfaceLayoutProfile() when $default != null:
return $default(_that.compact,_that.regular,_that.expanded);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectResponsiveSurfaceLayoutProfile extends ProjectResponsiveSurfaceLayoutProfile {
  const _ProjectResponsiveSurfaceLayoutProfile({required this.compact, required this.regular, required this.expanded}): super._();
  factory _ProjectResponsiveSurfaceLayoutProfile.fromJson(Map<String, dynamic> json) => _$ProjectResponsiveSurfaceLayoutProfileFromJson(json);

@override final  ProjectSurfaceLayoutVariant compact;
@override final  ProjectSurfaceLayoutVariant regular;
@override final  ProjectSurfaceLayoutVariant expanded;

/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectResponsiveSurfaceLayoutProfileCopyWith<_ProjectResponsiveSurfaceLayoutProfile> get copyWith => __$ProjectResponsiveSurfaceLayoutProfileCopyWithImpl<_ProjectResponsiveSurfaceLayoutProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectResponsiveSurfaceLayoutProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectResponsiveSurfaceLayoutProfile&&(identical(other.compact, compact) || other.compact == compact)&&(identical(other.regular, regular) || other.regular == regular)&&(identical(other.expanded, expanded) || other.expanded == expanded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,compact,regular,expanded);

@override
String toString() {
  return 'ProjectResponsiveSurfaceLayoutProfile(compact: $compact, regular: $regular, expanded: $expanded)';
}


}

/// @nodoc
abstract mixin class _$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> implements $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> {
  factory _$ProjectResponsiveSurfaceLayoutProfileCopyWith(_ProjectResponsiveSurfaceLayoutProfile value, $Res Function(_ProjectResponsiveSurfaceLayoutProfile) _then) = __$ProjectResponsiveSurfaceLayoutProfileCopyWithImpl;
@override @useResult
$Res call({
 ProjectSurfaceLayoutVariant compact, ProjectSurfaceLayoutVariant regular, ProjectSurfaceLayoutVariant expanded
});


@override $ProjectSurfaceLayoutVariantCopyWith<$Res> get compact;@override $ProjectSurfaceLayoutVariantCopyWith<$Res> get regular;@override $ProjectSurfaceLayoutVariantCopyWith<$Res> get expanded;

}
/// @nodoc
class __$ProjectResponsiveSurfaceLayoutProfileCopyWithImpl<$Res>
    implements _$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> {
  __$ProjectResponsiveSurfaceLayoutProfileCopyWithImpl(this._self, this._then);

  final _ProjectResponsiveSurfaceLayoutProfile _self;
  final $Res Function(_ProjectResponsiveSurfaceLayoutProfile) _then;

/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? compact = null,Object? regular = null,Object? expanded = null,}) {
  return _then(_ProjectResponsiveSurfaceLayoutProfile(
compact: null == compact ? _self.compact : compact // ignore: cast_nullable_to_non_nullable
as ProjectSurfaceLayoutVariant,regular: null == regular ? _self.regular : regular // ignore: cast_nullable_to_non_nullable
as ProjectSurfaceLayoutVariant,expanded: null == expanded ? _self.expanded : expanded // ignore: cast_nullable_to_non_nullable
as ProjectSurfaceLayoutVariant,
  ));
}

/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfaceLayoutVariantCopyWith<$Res> get compact {

  return $ProjectSurfaceLayoutVariantCopyWith<$Res>(_self.compact, (value) {
    return _then(_self.copyWith(compact: value));
  });
}/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfaceLayoutVariantCopyWith<$Res> get regular {

  return $ProjectSurfaceLayoutVariantCopyWith<$Res>(_self.regular, (value) {
    return _then(_self.copyWith(regular: value));
  });
}/// Create a copy of ProjectResponsiveSurfaceLayoutProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSurfaceLayoutVariantCopyWith<$Res> get expanded {

  return $ProjectSurfaceLayoutVariantCopyWith<$Res>(_self.expanded, (value) {
    return _then(_self.copyWith(expanded: value));
  });
}
}


/// @nodoc
mixin _$ProjectPresentationLayoutsProfile {

 ProjectResponsiveSurfaceLayoutProfile get title; ProjectResponsiveSurfaceLayoutProfile get pauseMenu; ProjectResponsiveSurfaceLayoutProfile get dialogue;@JsonKey(includeIfNull: false) ProjectResponsiveSurfaceLayoutProfile? get battle;
/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectPresentationLayoutsProfileCopyWith<ProjectPresentationLayoutsProfile> get copyWith => _$ProjectPresentationLayoutsProfileCopyWithImpl<ProjectPresentationLayoutsProfile>(this as ProjectPresentationLayoutsProfile, _$identity);

  /// Serializes this ProjectPresentationLayoutsProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectPresentationLayoutsProfile&&(identical(other.title, title) || other.title == title)&&(identical(other.pauseMenu, pauseMenu) || other.pauseMenu == pauseMenu)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.battle, battle) || other.battle == battle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,pauseMenu,dialogue,battle);

@override
String toString() {
  return 'ProjectPresentationLayoutsProfile(title: $title, pauseMenu: $pauseMenu, dialogue: $dialogue, battle: $battle)';
}


}

/// @nodoc
abstract mixin class $ProjectPresentationLayoutsProfileCopyWith<$Res>  {
  factory $ProjectPresentationLayoutsProfileCopyWith(ProjectPresentationLayoutsProfile value, $Res Function(ProjectPresentationLayoutsProfile) _then) = _$ProjectPresentationLayoutsProfileCopyWithImpl;
@useResult
$Res call({
 ProjectResponsiveSurfaceLayoutProfile title, ProjectResponsiveSurfaceLayoutProfile pauseMenu, ProjectResponsiveSurfaceLayoutProfile dialogue,@JsonKey(includeIfNull: false) ProjectResponsiveSurfaceLayoutProfile? battle
});


$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get title;$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get pauseMenu;$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get dialogue;$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>? get battle;

}
/// @nodoc
class _$ProjectPresentationLayoutsProfileCopyWithImpl<$Res>
    implements $ProjectPresentationLayoutsProfileCopyWith<$Res> {
  _$ProjectPresentationLayoutsProfileCopyWithImpl(this._self, this._then);

  final ProjectPresentationLayoutsProfile _self;
  final $Res Function(ProjectPresentationLayoutsProfile) _then;

/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? pauseMenu = null,Object? dialogue = null,Object? battle = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveSurfaceLayoutProfile,pauseMenu: null == pauseMenu ? _self.pauseMenu : pauseMenu // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveSurfaceLayoutProfile,dialogue: null == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveSurfaceLayoutProfile,battle: freezed == battle ? _self.battle : battle // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveSurfaceLayoutProfile?,
  ));
}
/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get title {

  return $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get pauseMenu {

  return $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>(_self.pauseMenu, (value) {
    return _then(_self.copyWith(pauseMenu: value));
  });
}/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get dialogue {

  return $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>(_self.dialogue, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>? get battle {
    if (_self.battle == null) {
    return null;
  }

  return $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>(_self.battle!, (value) {
    return _then(_self.copyWith(battle: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectPresentationLayoutsProfile].
extension ProjectPresentationLayoutsProfilePatterns on ProjectPresentationLayoutsProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectPresentationLayoutsProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectPresentationLayoutsProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectPresentationLayoutsProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationLayoutsProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectPresentationLayoutsProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectPresentationLayoutsProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectResponsiveSurfaceLayoutProfile title,  ProjectResponsiveSurfaceLayoutProfile pauseMenu,  ProjectResponsiveSurfaceLayoutProfile dialogue, @JsonKey(includeIfNull: false)  ProjectResponsiveSurfaceLayoutProfile? battle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectPresentationLayoutsProfile() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectResponsiveSurfaceLayoutProfile title,  ProjectResponsiveSurfaceLayoutProfile pauseMenu,  ProjectResponsiveSurfaceLayoutProfile dialogue, @JsonKey(includeIfNull: false)  ProjectResponsiveSurfaceLayoutProfile? battle)  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationLayoutsProfile():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectResponsiveSurfaceLayoutProfile title,  ProjectResponsiveSurfaceLayoutProfile pauseMenu,  ProjectResponsiveSurfaceLayoutProfile dialogue, @JsonKey(includeIfNull: false)  ProjectResponsiveSurfaceLayoutProfile? battle)?  $default,) {final _that = this;
switch (_that) {
case _ProjectPresentationLayoutsProfile() when $default != null:
return $default(_that.title,_that.pauseMenu,_that.dialogue,_that.battle);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectPresentationLayoutsProfile extends ProjectPresentationLayoutsProfile {
  const _ProjectPresentationLayoutsProfile({required this.title, required this.pauseMenu, required this.dialogue, @JsonKey(includeIfNull: false) this.battle}): super._();
  factory _ProjectPresentationLayoutsProfile.fromJson(Map<String, dynamic> json) => _$ProjectPresentationLayoutsProfileFromJson(json);

@override final  ProjectResponsiveSurfaceLayoutProfile title;
@override final  ProjectResponsiveSurfaceLayoutProfile pauseMenu;
@override final  ProjectResponsiveSurfaceLayoutProfile dialogue;
@override@JsonKey(includeIfNull: false) final  ProjectResponsiveSurfaceLayoutProfile? battle;

/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectPresentationLayoutsProfileCopyWith<_ProjectPresentationLayoutsProfile> get copyWith => __$ProjectPresentationLayoutsProfileCopyWithImpl<_ProjectPresentationLayoutsProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectPresentationLayoutsProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectPresentationLayoutsProfile&&(identical(other.title, title) || other.title == title)&&(identical(other.pauseMenu, pauseMenu) || other.pauseMenu == pauseMenu)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.battle, battle) || other.battle == battle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,pauseMenu,dialogue,battle);

@override
String toString() {
  return 'ProjectPresentationLayoutsProfile(title: $title, pauseMenu: $pauseMenu, dialogue: $dialogue, battle: $battle)';
}


}

/// @nodoc
abstract mixin class _$ProjectPresentationLayoutsProfileCopyWith<$Res> implements $ProjectPresentationLayoutsProfileCopyWith<$Res> {
  factory _$ProjectPresentationLayoutsProfileCopyWith(_ProjectPresentationLayoutsProfile value, $Res Function(_ProjectPresentationLayoutsProfile) _then) = __$ProjectPresentationLayoutsProfileCopyWithImpl;
@override @useResult
$Res call({
 ProjectResponsiveSurfaceLayoutProfile title, ProjectResponsiveSurfaceLayoutProfile pauseMenu, ProjectResponsiveSurfaceLayoutProfile dialogue,@JsonKey(includeIfNull: false) ProjectResponsiveSurfaceLayoutProfile? battle
});


@override $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get title;@override $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get pauseMenu;@override $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get dialogue;@override $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>? get battle;

}
/// @nodoc
class __$ProjectPresentationLayoutsProfileCopyWithImpl<$Res>
    implements _$ProjectPresentationLayoutsProfileCopyWith<$Res> {
  __$ProjectPresentationLayoutsProfileCopyWithImpl(this._self, this._then);

  final _ProjectPresentationLayoutsProfile _self;
  final $Res Function(_ProjectPresentationLayoutsProfile) _then;

/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? pauseMenu = null,Object? dialogue = null,Object? battle = freezed,}) {
  return _then(_ProjectPresentationLayoutsProfile(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveSurfaceLayoutProfile,pauseMenu: null == pauseMenu ? _self.pauseMenu : pauseMenu // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveSurfaceLayoutProfile,dialogue: null == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveSurfaceLayoutProfile,battle: freezed == battle ? _self.battle : battle // ignore: cast_nullable_to_non_nullable
as ProjectResponsiveSurfaceLayoutProfile?,
  ));
}

/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get title {

  return $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get pauseMenu {

  return $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>(_self.pauseMenu, (value) {
    return _then(_self.copyWith(pauseMenu: value));
  });
}/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res> get dialogue {

  return $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>(_self.dialogue, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}/// Create a copy of ProjectPresentationLayoutsProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>? get battle {
    if (_self.battle == null) {
    return null;
  }

  return $ProjectResponsiveSurfaceLayoutProfileCopyWith<$Res>(_self.battle!, (value) {
    return _then(_self.copyWith(battle: value));
  });
}
}

// dart format on
