// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_battle_presentation_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectBattleCommandProfile {

 ProjectBattleCommandId get id;@JsonKey(includeIfNull: false) String? get label;@JsonKey(includeIfNull: false) ProjectBattleCommandIcon? get icon;
/// Create a copy of ProjectBattleCommandProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectBattleCommandProfileCopyWith<ProjectBattleCommandProfile> get copyWith => _$ProjectBattleCommandProfileCopyWithImpl<ProjectBattleCommandProfile>(this as ProjectBattleCommandProfile, _$identity);

  /// Serializes this ProjectBattleCommandProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectBattleCommandProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,icon);

@override
String toString() {
  return 'ProjectBattleCommandProfile(id: $id, label: $label, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $ProjectBattleCommandProfileCopyWith<$Res>  {
  factory $ProjectBattleCommandProfileCopyWith(ProjectBattleCommandProfile value, $Res Function(ProjectBattleCommandProfile) _then) = _$ProjectBattleCommandProfileCopyWithImpl;
@useResult
$Res call({
 ProjectBattleCommandId id,@JsonKey(includeIfNull: false) String? label,@JsonKey(includeIfNull: false) ProjectBattleCommandIcon? icon
});




}
/// @nodoc
class _$ProjectBattleCommandProfileCopyWithImpl<$Res>
    implements $ProjectBattleCommandProfileCopyWith<$Res> {
  _$ProjectBattleCommandProfileCopyWithImpl(this._self, this._then);

  final ProjectBattleCommandProfile _self;
  final $Res Function(ProjectBattleCommandProfile) _then;

/// Create a copy of ProjectBattleCommandProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = freezed,Object? icon = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ProjectBattleCommandId,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as ProjectBattleCommandIcon?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectBattleCommandProfile].
extension ProjectBattleCommandProfilePatterns on ProjectBattleCommandProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectBattleCommandProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectBattleCommandProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectBattleCommandProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectBattleCommandProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectBattleCommandProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectBattleCommandProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectBattleCommandId id, @JsonKey(includeIfNull: false)  String? label, @JsonKey(includeIfNull: false)  ProjectBattleCommandIcon? icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectBattleCommandProfile() when $default != null:
return $default(_that.id,_that.label,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectBattleCommandId id, @JsonKey(includeIfNull: false)  String? label, @JsonKey(includeIfNull: false)  ProjectBattleCommandIcon? icon)  $default,) {final _that = this;
switch (_that) {
case _ProjectBattleCommandProfile():
return $default(_that.id,_that.label,_that.icon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectBattleCommandId id, @JsonKey(includeIfNull: false)  String? label, @JsonKey(includeIfNull: false)  ProjectBattleCommandIcon? icon)?  $default,) {final _that = this;
switch (_that) {
case _ProjectBattleCommandProfile() when $default != null:
return $default(_that.id,_that.label,_that.icon);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectBattleCommandProfile implements ProjectBattleCommandProfile {
  const _ProjectBattleCommandProfile({required this.id, @JsonKey(includeIfNull: false) this.label, @JsonKey(includeIfNull: false) this.icon});
  factory _ProjectBattleCommandProfile.fromJson(Map<String, dynamic> json) => _$ProjectBattleCommandProfileFromJson(json);

@override final  ProjectBattleCommandId id;
@override@JsonKey(includeIfNull: false) final  String? label;
@override@JsonKey(includeIfNull: false) final  ProjectBattleCommandIcon? icon;

/// Create a copy of ProjectBattleCommandProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectBattleCommandProfileCopyWith<_ProjectBattleCommandProfile> get copyWith => __$ProjectBattleCommandProfileCopyWithImpl<_ProjectBattleCommandProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectBattleCommandProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectBattleCommandProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,icon);

@override
String toString() {
  return 'ProjectBattleCommandProfile(id: $id, label: $label, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$ProjectBattleCommandProfileCopyWith<$Res> implements $ProjectBattleCommandProfileCopyWith<$Res> {
  factory _$ProjectBattleCommandProfileCopyWith(_ProjectBattleCommandProfile value, $Res Function(_ProjectBattleCommandProfile) _then) = __$ProjectBattleCommandProfileCopyWithImpl;
@override @useResult
$Res call({
 ProjectBattleCommandId id,@JsonKey(includeIfNull: false) String? label,@JsonKey(includeIfNull: false) ProjectBattleCommandIcon? icon
});




}
/// @nodoc
class __$ProjectBattleCommandProfileCopyWithImpl<$Res>
    implements _$ProjectBattleCommandProfileCopyWith<$Res> {
  __$ProjectBattleCommandProfileCopyWithImpl(this._self, this._then);

  final _ProjectBattleCommandProfile _self;
  final $Res Function(_ProjectBattleCommandProfile) _then;

/// Create a copy of ProjectBattleCommandProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = freezed,Object? icon = freezed,}) {
  return _then(_ProjectBattleCommandProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ProjectBattleCommandId,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as ProjectBattleCommandIcon?,
  ));
}


}


/// @nodoc
mixin _$ProjectBattlePanelPresentationProfile {

 ProjectBattleCommandLayout get layout; int get columns; ProjectWindowShape get shape; double get padding;@JsonKey(includeIfNull: false) String? get surfaceColor;@JsonKey(includeIfNull: false) String? get borderColor;@JsonKey(includeIfNull: false) String? get textColor;@JsonKey(includeIfNull: false) String? get selectionColor;
/// Create a copy of ProjectBattlePanelPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectBattlePanelPresentationProfileCopyWith<ProjectBattlePanelPresentationProfile> get copyWith => _$ProjectBattlePanelPresentationProfileCopyWithImpl<ProjectBattlePanelPresentationProfile>(this as ProjectBattlePanelPresentationProfile, _$identity);

  /// Serializes this ProjectBattlePanelPresentationProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectBattlePanelPresentationProfile&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.columns, columns) || other.columns == columns)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.surfaceColor, surfaceColor) || other.surfaceColor == surfaceColor)&&(identical(other.borderColor, borderColor) || other.borderColor == borderColor)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.selectionColor, selectionColor) || other.selectionColor == selectionColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,layout,columns,shape,padding,surfaceColor,borderColor,textColor,selectionColor);

@override
String toString() {
  return 'ProjectBattlePanelPresentationProfile(layout: $layout, columns: $columns, shape: $shape, padding: $padding, surfaceColor: $surfaceColor, borderColor: $borderColor, textColor: $textColor, selectionColor: $selectionColor)';
}


}

/// @nodoc
abstract mixin class $ProjectBattlePanelPresentationProfileCopyWith<$Res>  {
  factory $ProjectBattlePanelPresentationProfileCopyWith(ProjectBattlePanelPresentationProfile value, $Res Function(ProjectBattlePanelPresentationProfile) _then) = _$ProjectBattlePanelPresentationProfileCopyWithImpl;
@useResult
$Res call({
 ProjectBattleCommandLayout layout, int columns, ProjectWindowShape shape, double padding,@JsonKey(includeIfNull: false) String? surfaceColor,@JsonKey(includeIfNull: false) String? borderColor,@JsonKey(includeIfNull: false) String? textColor,@JsonKey(includeIfNull: false) String? selectionColor
});




}
/// @nodoc
class _$ProjectBattlePanelPresentationProfileCopyWithImpl<$Res>
    implements $ProjectBattlePanelPresentationProfileCopyWith<$Res> {
  _$ProjectBattlePanelPresentationProfileCopyWithImpl(this._self, this._then);

  final ProjectBattlePanelPresentationProfile _self;
  final $Res Function(ProjectBattlePanelPresentationProfile) _then;

/// Create a copy of ProjectBattlePanelPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? layout = null,Object? columns = null,Object? shape = null,Object? padding = null,Object? surfaceColor = freezed,Object? borderColor = freezed,Object? textColor = freezed,Object? selectionColor = freezed,}) {
  return _then(_self.copyWith(
layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as ProjectBattleCommandLayout,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as int,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as ProjectWindowShape,padding: null == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as double,surfaceColor: freezed == surfaceColor ? _self.surfaceColor : surfaceColor // ignore: cast_nullable_to_non_nullable
as String?,borderColor: freezed == borderColor ? _self.borderColor : borderColor // ignore: cast_nullable_to_non_nullable
as String?,textColor: freezed == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as String?,selectionColor: freezed == selectionColor ? _self.selectionColor : selectionColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectBattlePanelPresentationProfile].
extension ProjectBattlePanelPresentationProfilePatterns on ProjectBattlePanelPresentationProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectBattlePanelPresentationProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectBattlePanelPresentationProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectBattlePanelPresentationProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectBattlePanelPresentationProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectBattlePanelPresentationProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectBattlePanelPresentationProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectBattleCommandLayout layout,  int columns,  ProjectWindowShape shape,  double padding, @JsonKey(includeIfNull: false)  String? surfaceColor, @JsonKey(includeIfNull: false)  String? borderColor, @JsonKey(includeIfNull: false)  String? textColor, @JsonKey(includeIfNull: false)  String? selectionColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectBattlePanelPresentationProfile() when $default != null:
return $default(_that.layout,_that.columns,_that.shape,_that.padding,_that.surfaceColor,_that.borderColor,_that.textColor,_that.selectionColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectBattleCommandLayout layout,  int columns,  ProjectWindowShape shape,  double padding, @JsonKey(includeIfNull: false)  String? surfaceColor, @JsonKey(includeIfNull: false)  String? borderColor, @JsonKey(includeIfNull: false)  String? textColor, @JsonKey(includeIfNull: false)  String? selectionColor)  $default,) {final _that = this;
switch (_that) {
case _ProjectBattlePanelPresentationProfile():
return $default(_that.layout,_that.columns,_that.shape,_that.padding,_that.surfaceColor,_that.borderColor,_that.textColor,_that.selectionColor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectBattleCommandLayout layout,  int columns,  ProjectWindowShape shape,  double padding, @JsonKey(includeIfNull: false)  String? surfaceColor, @JsonKey(includeIfNull: false)  String? borderColor, @JsonKey(includeIfNull: false)  String? textColor, @JsonKey(includeIfNull: false)  String? selectionColor)?  $default,) {final _that = this;
switch (_that) {
case _ProjectBattlePanelPresentationProfile() when $default != null:
return $default(_that.layout,_that.columns,_that.shape,_that.padding,_that.surfaceColor,_that.borderColor,_that.textColor,_that.selectionColor);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectBattlePanelPresentationProfile implements ProjectBattlePanelPresentationProfile {
  const _ProjectBattlePanelPresentationProfile({this.layout = ProjectBattleCommandLayout.grid, this.columns = 2, this.shape = ProjectWindowShape.rounded, this.padding = 12, @JsonKey(includeIfNull: false) this.surfaceColor, @JsonKey(includeIfNull: false) this.borderColor, @JsonKey(includeIfNull: false) this.textColor, @JsonKey(includeIfNull: false) this.selectionColor});
  factory _ProjectBattlePanelPresentationProfile.fromJson(Map<String, dynamic> json) => _$ProjectBattlePanelPresentationProfileFromJson(json);

@override@JsonKey() final  ProjectBattleCommandLayout layout;
@override@JsonKey() final  int columns;
@override@JsonKey() final  ProjectWindowShape shape;
@override@JsonKey() final  double padding;
@override@JsonKey(includeIfNull: false) final  String? surfaceColor;
@override@JsonKey(includeIfNull: false) final  String? borderColor;
@override@JsonKey(includeIfNull: false) final  String? textColor;
@override@JsonKey(includeIfNull: false) final  String? selectionColor;

/// Create a copy of ProjectBattlePanelPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectBattlePanelPresentationProfileCopyWith<_ProjectBattlePanelPresentationProfile> get copyWith => __$ProjectBattlePanelPresentationProfileCopyWithImpl<_ProjectBattlePanelPresentationProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectBattlePanelPresentationProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectBattlePanelPresentationProfile&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.columns, columns) || other.columns == columns)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.surfaceColor, surfaceColor) || other.surfaceColor == surfaceColor)&&(identical(other.borderColor, borderColor) || other.borderColor == borderColor)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.selectionColor, selectionColor) || other.selectionColor == selectionColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,layout,columns,shape,padding,surfaceColor,borderColor,textColor,selectionColor);

@override
String toString() {
  return 'ProjectBattlePanelPresentationProfile(layout: $layout, columns: $columns, shape: $shape, padding: $padding, surfaceColor: $surfaceColor, borderColor: $borderColor, textColor: $textColor, selectionColor: $selectionColor)';
}


}

/// @nodoc
abstract mixin class _$ProjectBattlePanelPresentationProfileCopyWith<$Res> implements $ProjectBattlePanelPresentationProfileCopyWith<$Res> {
  factory _$ProjectBattlePanelPresentationProfileCopyWith(_ProjectBattlePanelPresentationProfile value, $Res Function(_ProjectBattlePanelPresentationProfile) _then) = __$ProjectBattlePanelPresentationProfileCopyWithImpl;
@override @useResult
$Res call({
 ProjectBattleCommandLayout layout, int columns, ProjectWindowShape shape, double padding,@JsonKey(includeIfNull: false) String? surfaceColor,@JsonKey(includeIfNull: false) String? borderColor,@JsonKey(includeIfNull: false) String? textColor,@JsonKey(includeIfNull: false) String? selectionColor
});




}
/// @nodoc
class __$ProjectBattlePanelPresentationProfileCopyWithImpl<$Res>
    implements _$ProjectBattlePanelPresentationProfileCopyWith<$Res> {
  __$ProjectBattlePanelPresentationProfileCopyWithImpl(this._self, this._then);

  final _ProjectBattlePanelPresentationProfile _self;
  final $Res Function(_ProjectBattlePanelPresentationProfile) _then;

/// Create a copy of ProjectBattlePanelPresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? layout = null,Object? columns = null,Object? shape = null,Object? padding = null,Object? surfaceColor = freezed,Object? borderColor = freezed,Object? textColor = freezed,Object? selectionColor = freezed,}) {
  return _then(_ProjectBattlePanelPresentationProfile(
layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as ProjectBattleCommandLayout,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as int,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as ProjectWindowShape,padding: null == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as double,surfaceColor: freezed == surfaceColor ? _self.surfaceColor : surfaceColor // ignore: cast_nullable_to_non_nullable
as String?,borderColor: freezed == borderColor ? _self.borderColor : borderColor // ignore: cast_nullable_to_non_nullable
as String?,textColor: freezed == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as String?,selectionColor: freezed == selectionColor ? _self.selectionColor : selectionColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProjectBattlePresentationProfile {

 ProjectBattleCommandLayout get commandLayout; int get commandColumns; bool get showCommandIcons; ProjectWindowShape get commandShape; double get commandPadding;@JsonKey(includeIfNull: false) String? get commandSurfaceColor;@JsonKey(includeIfNull: false) String? get commandBorderColor;@JsonKey(includeIfNull: false) String? get commandTextColor;@JsonKey(includeIfNull: false) String? get commandSelectionColor;@JsonKey(includeIfNull: false) List<ProjectBattleCommandProfile>? get commands; ProjectWindowShape get hudShape; ProjectBattleHudPosition get enemyHudPosition; ProjectBattleHudPosition get playerHudPosition; bool get showOwnerLabel; bool get showLevel; bool get showExactHp; ProjectBattleHpBarShape get hpBarShape; String get hpHealthyColor; String get hpWarningColor; String get hpDangerColor; String get statusColor; ProjectBattlePanelPresentationProfile get moves; ProjectBattlePanelPresentationProfile get target; ProjectBattlePanelPresentationProfile get message;
/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectBattlePresentationProfileCopyWith<ProjectBattlePresentationProfile> get copyWith => _$ProjectBattlePresentationProfileCopyWithImpl<ProjectBattlePresentationProfile>(this as ProjectBattlePresentationProfile, _$identity);

  /// Serializes this ProjectBattlePresentationProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectBattlePresentationProfile&&(identical(other.commandLayout, commandLayout) || other.commandLayout == commandLayout)&&(identical(other.commandColumns, commandColumns) || other.commandColumns == commandColumns)&&(identical(other.showCommandIcons, showCommandIcons) || other.showCommandIcons == showCommandIcons)&&(identical(other.commandShape, commandShape) || other.commandShape == commandShape)&&(identical(other.commandPadding, commandPadding) || other.commandPadding == commandPadding)&&(identical(other.commandSurfaceColor, commandSurfaceColor) || other.commandSurfaceColor == commandSurfaceColor)&&(identical(other.commandBorderColor, commandBorderColor) || other.commandBorderColor == commandBorderColor)&&(identical(other.commandTextColor, commandTextColor) || other.commandTextColor == commandTextColor)&&(identical(other.commandSelectionColor, commandSelectionColor) || other.commandSelectionColor == commandSelectionColor)&&const DeepCollectionEquality().equals(other.commands, commands)&&(identical(other.hudShape, hudShape) || other.hudShape == hudShape)&&(identical(other.enemyHudPosition, enemyHudPosition) || other.enemyHudPosition == enemyHudPosition)&&(identical(other.playerHudPosition, playerHudPosition) || other.playerHudPosition == playerHudPosition)&&(identical(other.showOwnerLabel, showOwnerLabel) || other.showOwnerLabel == showOwnerLabel)&&(identical(other.showLevel, showLevel) || other.showLevel == showLevel)&&(identical(other.showExactHp, showExactHp) || other.showExactHp == showExactHp)&&(identical(other.hpBarShape, hpBarShape) || other.hpBarShape == hpBarShape)&&(identical(other.hpHealthyColor, hpHealthyColor) || other.hpHealthyColor == hpHealthyColor)&&(identical(other.hpWarningColor, hpWarningColor) || other.hpWarningColor == hpWarningColor)&&(identical(other.hpDangerColor, hpDangerColor) || other.hpDangerColor == hpDangerColor)&&(identical(other.statusColor, statusColor) || other.statusColor == statusColor)&&(identical(other.moves, moves) || other.moves == moves)&&(identical(other.target, target) || other.target == target)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,commandLayout,commandColumns,showCommandIcons,commandShape,commandPadding,commandSurfaceColor,commandBorderColor,commandTextColor,commandSelectionColor,const DeepCollectionEquality().hash(commands),hudShape,enemyHudPosition,playerHudPosition,showOwnerLabel,showLevel,showExactHp,hpBarShape,hpHealthyColor,hpWarningColor,hpDangerColor,statusColor,moves,target,message]);

@override
String toString() {
  return 'ProjectBattlePresentationProfile(commandLayout: $commandLayout, commandColumns: $commandColumns, showCommandIcons: $showCommandIcons, commandShape: $commandShape, commandPadding: $commandPadding, commandSurfaceColor: $commandSurfaceColor, commandBorderColor: $commandBorderColor, commandTextColor: $commandTextColor, commandSelectionColor: $commandSelectionColor, commands: $commands, hudShape: $hudShape, enemyHudPosition: $enemyHudPosition, playerHudPosition: $playerHudPosition, showOwnerLabel: $showOwnerLabel, showLevel: $showLevel, showExactHp: $showExactHp, hpBarShape: $hpBarShape, hpHealthyColor: $hpHealthyColor, hpWarningColor: $hpWarningColor, hpDangerColor: $hpDangerColor, statusColor: $statusColor, moves: $moves, target: $target, message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectBattlePresentationProfileCopyWith<$Res>  {
  factory $ProjectBattlePresentationProfileCopyWith(ProjectBattlePresentationProfile value, $Res Function(ProjectBattlePresentationProfile) _then) = _$ProjectBattlePresentationProfileCopyWithImpl;
@useResult
$Res call({
 ProjectBattleCommandLayout commandLayout, int commandColumns, bool showCommandIcons, ProjectWindowShape commandShape, double commandPadding,@JsonKey(includeIfNull: false) String? commandSurfaceColor,@JsonKey(includeIfNull: false) String? commandBorderColor,@JsonKey(includeIfNull: false) String? commandTextColor,@JsonKey(includeIfNull: false) String? commandSelectionColor,@JsonKey(includeIfNull: false) List<ProjectBattleCommandProfile>? commands, ProjectWindowShape hudShape, ProjectBattleHudPosition enemyHudPosition, ProjectBattleHudPosition playerHudPosition, bool showOwnerLabel, bool showLevel, bool showExactHp, ProjectBattleHpBarShape hpBarShape, String hpHealthyColor, String hpWarningColor, String hpDangerColor, String statusColor, ProjectBattlePanelPresentationProfile moves, ProjectBattlePanelPresentationProfile target, ProjectBattlePanelPresentationProfile message
});


$ProjectBattlePanelPresentationProfileCopyWith<$Res> get moves;$ProjectBattlePanelPresentationProfileCopyWith<$Res> get target;$ProjectBattlePanelPresentationProfileCopyWith<$Res> get message;

}
/// @nodoc
class _$ProjectBattlePresentationProfileCopyWithImpl<$Res>
    implements $ProjectBattlePresentationProfileCopyWith<$Res> {
  _$ProjectBattlePresentationProfileCopyWithImpl(this._self, this._then);

  final ProjectBattlePresentationProfile _self;
  final $Res Function(ProjectBattlePresentationProfile) _then;

/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? commandLayout = null,Object? commandColumns = null,Object? showCommandIcons = null,Object? commandShape = null,Object? commandPadding = null,Object? commandSurfaceColor = freezed,Object? commandBorderColor = freezed,Object? commandTextColor = freezed,Object? commandSelectionColor = freezed,Object? commands = freezed,Object? hudShape = null,Object? enemyHudPosition = null,Object? playerHudPosition = null,Object? showOwnerLabel = null,Object? showLevel = null,Object? showExactHp = null,Object? hpBarShape = null,Object? hpHealthyColor = null,Object? hpWarningColor = null,Object? hpDangerColor = null,Object? statusColor = null,Object? moves = null,Object? target = null,Object? message = null,}) {
  return _then(_self.copyWith(
commandLayout: null == commandLayout ? _self.commandLayout : commandLayout // ignore: cast_nullable_to_non_nullable
as ProjectBattleCommandLayout,commandColumns: null == commandColumns ? _self.commandColumns : commandColumns // ignore: cast_nullable_to_non_nullable
as int,showCommandIcons: null == showCommandIcons ? _self.showCommandIcons : showCommandIcons // ignore: cast_nullable_to_non_nullable
as bool,commandShape: null == commandShape ? _self.commandShape : commandShape // ignore: cast_nullable_to_non_nullable
as ProjectWindowShape,commandPadding: null == commandPadding ? _self.commandPadding : commandPadding // ignore: cast_nullable_to_non_nullable
as double,commandSurfaceColor: freezed == commandSurfaceColor ? _self.commandSurfaceColor : commandSurfaceColor // ignore: cast_nullable_to_non_nullable
as String?,commandBorderColor: freezed == commandBorderColor ? _self.commandBorderColor : commandBorderColor // ignore: cast_nullable_to_non_nullable
as String?,commandTextColor: freezed == commandTextColor ? _self.commandTextColor : commandTextColor // ignore: cast_nullable_to_non_nullable
as String?,commandSelectionColor: freezed == commandSelectionColor ? _self.commandSelectionColor : commandSelectionColor // ignore: cast_nullable_to_non_nullable
as String?,commands: freezed == commands ? _self.commands : commands // ignore: cast_nullable_to_non_nullable
as List<ProjectBattleCommandProfile>?,hudShape: null == hudShape ? _self.hudShape : hudShape // ignore: cast_nullable_to_non_nullable
as ProjectWindowShape,enemyHudPosition: null == enemyHudPosition ? _self.enemyHudPosition : enemyHudPosition // ignore: cast_nullable_to_non_nullable
as ProjectBattleHudPosition,playerHudPosition: null == playerHudPosition ? _self.playerHudPosition : playerHudPosition // ignore: cast_nullable_to_non_nullable
as ProjectBattleHudPosition,showOwnerLabel: null == showOwnerLabel ? _self.showOwnerLabel : showOwnerLabel // ignore: cast_nullable_to_non_nullable
as bool,showLevel: null == showLevel ? _self.showLevel : showLevel // ignore: cast_nullable_to_non_nullable
as bool,showExactHp: null == showExactHp ? _self.showExactHp : showExactHp // ignore: cast_nullable_to_non_nullable
as bool,hpBarShape: null == hpBarShape ? _self.hpBarShape : hpBarShape // ignore: cast_nullable_to_non_nullable
as ProjectBattleHpBarShape,hpHealthyColor: null == hpHealthyColor ? _self.hpHealthyColor : hpHealthyColor // ignore: cast_nullable_to_non_nullable
as String,hpWarningColor: null == hpWarningColor ? _self.hpWarningColor : hpWarningColor // ignore: cast_nullable_to_non_nullable
as String,hpDangerColor: null == hpDangerColor ? _self.hpDangerColor : hpDangerColor // ignore: cast_nullable_to_non_nullable
as String,statusColor: null == statusColor ? _self.statusColor : statusColor // ignore: cast_nullable_to_non_nullable
as String,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as ProjectBattlePanelPresentationProfile,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ProjectBattlePanelPresentationProfile,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ProjectBattlePanelPresentationProfile,
  ));
}
/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattlePanelPresentationProfileCopyWith<$Res> get moves {

  return $ProjectBattlePanelPresentationProfileCopyWith<$Res>(_self.moves, (value) {
    return _then(_self.copyWith(moves: value));
  });
}/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattlePanelPresentationProfileCopyWith<$Res> get target {

  return $ProjectBattlePanelPresentationProfileCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattlePanelPresentationProfileCopyWith<$Res> get message {

  return $ProjectBattlePanelPresentationProfileCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectBattlePresentationProfile].
extension ProjectBattlePresentationProfilePatterns on ProjectBattlePresentationProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectBattlePresentationProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectBattlePresentationProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectBattlePresentationProfile value)  $default,){
final _that = this;
switch (_that) {
case _ProjectBattlePresentationProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectBattlePresentationProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectBattlePresentationProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProjectBattleCommandLayout commandLayout,  int commandColumns,  bool showCommandIcons,  ProjectWindowShape commandShape,  double commandPadding, @JsonKey(includeIfNull: false)  String? commandSurfaceColor, @JsonKey(includeIfNull: false)  String? commandBorderColor, @JsonKey(includeIfNull: false)  String? commandTextColor, @JsonKey(includeIfNull: false)  String? commandSelectionColor, @JsonKey(includeIfNull: false)  List<ProjectBattleCommandProfile>? commands,  ProjectWindowShape hudShape,  ProjectBattleHudPosition enemyHudPosition,  ProjectBattleHudPosition playerHudPosition,  bool showOwnerLabel,  bool showLevel,  bool showExactHp,  ProjectBattleHpBarShape hpBarShape,  String hpHealthyColor,  String hpWarningColor,  String hpDangerColor,  String statusColor,  ProjectBattlePanelPresentationProfile moves,  ProjectBattlePanelPresentationProfile target,  ProjectBattlePanelPresentationProfile message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectBattlePresentationProfile() when $default != null:
return $default(_that.commandLayout,_that.commandColumns,_that.showCommandIcons,_that.commandShape,_that.commandPadding,_that.commandSurfaceColor,_that.commandBorderColor,_that.commandTextColor,_that.commandSelectionColor,_that.commands,_that.hudShape,_that.enemyHudPosition,_that.playerHudPosition,_that.showOwnerLabel,_that.showLevel,_that.showExactHp,_that.hpBarShape,_that.hpHealthyColor,_that.hpWarningColor,_that.hpDangerColor,_that.statusColor,_that.moves,_that.target,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProjectBattleCommandLayout commandLayout,  int commandColumns,  bool showCommandIcons,  ProjectWindowShape commandShape,  double commandPadding, @JsonKey(includeIfNull: false)  String? commandSurfaceColor, @JsonKey(includeIfNull: false)  String? commandBorderColor, @JsonKey(includeIfNull: false)  String? commandTextColor, @JsonKey(includeIfNull: false)  String? commandSelectionColor, @JsonKey(includeIfNull: false)  List<ProjectBattleCommandProfile>? commands,  ProjectWindowShape hudShape,  ProjectBattleHudPosition enemyHudPosition,  ProjectBattleHudPosition playerHudPosition,  bool showOwnerLabel,  bool showLevel,  bool showExactHp,  ProjectBattleHpBarShape hpBarShape,  String hpHealthyColor,  String hpWarningColor,  String hpDangerColor,  String statusColor,  ProjectBattlePanelPresentationProfile moves,  ProjectBattlePanelPresentationProfile target,  ProjectBattlePanelPresentationProfile message)  $default,) {final _that = this;
switch (_that) {
case _ProjectBattlePresentationProfile():
return $default(_that.commandLayout,_that.commandColumns,_that.showCommandIcons,_that.commandShape,_that.commandPadding,_that.commandSurfaceColor,_that.commandBorderColor,_that.commandTextColor,_that.commandSelectionColor,_that.commands,_that.hudShape,_that.enemyHudPosition,_that.playerHudPosition,_that.showOwnerLabel,_that.showLevel,_that.showExactHp,_that.hpBarShape,_that.hpHealthyColor,_that.hpWarningColor,_that.hpDangerColor,_that.statusColor,_that.moves,_that.target,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProjectBattleCommandLayout commandLayout,  int commandColumns,  bool showCommandIcons,  ProjectWindowShape commandShape,  double commandPadding, @JsonKey(includeIfNull: false)  String? commandSurfaceColor, @JsonKey(includeIfNull: false)  String? commandBorderColor, @JsonKey(includeIfNull: false)  String? commandTextColor, @JsonKey(includeIfNull: false)  String? commandSelectionColor, @JsonKey(includeIfNull: false)  List<ProjectBattleCommandProfile>? commands,  ProjectWindowShape hudShape,  ProjectBattleHudPosition enemyHudPosition,  ProjectBattleHudPosition playerHudPosition,  bool showOwnerLabel,  bool showLevel,  bool showExactHp,  ProjectBattleHpBarShape hpBarShape,  String hpHealthyColor,  String hpWarningColor,  String hpDangerColor,  String statusColor,  ProjectBattlePanelPresentationProfile moves,  ProjectBattlePanelPresentationProfile target,  ProjectBattlePanelPresentationProfile message)?  $default,) {final _that = this;
switch (_that) {
case _ProjectBattlePresentationProfile() when $default != null:
return $default(_that.commandLayout,_that.commandColumns,_that.showCommandIcons,_that.commandShape,_that.commandPadding,_that.commandSurfaceColor,_that.commandBorderColor,_that.commandTextColor,_that.commandSelectionColor,_that.commands,_that.hudShape,_that.enemyHudPosition,_that.playerHudPosition,_that.showOwnerLabel,_that.showLevel,_that.showExactHp,_that.hpBarShape,_that.hpHealthyColor,_that.hpWarningColor,_that.hpDangerColor,_that.statusColor,_that.moves,_that.target,_that.message);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectBattlePresentationProfile extends ProjectBattlePresentationProfile {
  const _ProjectBattlePresentationProfile({this.commandLayout = ProjectBattleCommandLayout.grid, this.commandColumns = 2, this.showCommandIcons = true, this.commandShape = ProjectWindowShape.rounded, this.commandPadding = 12, @JsonKey(includeIfNull: false) this.commandSurfaceColor, @JsonKey(includeIfNull: false) this.commandBorderColor, @JsonKey(includeIfNull: false) this.commandTextColor, @JsonKey(includeIfNull: false) this.commandSelectionColor, @JsonKey(includeIfNull: false) final  List<ProjectBattleCommandProfile>? commands, this.hudShape = ProjectWindowShape.rounded, this.enemyHudPosition = ProjectBattleHudPosition.topStart, this.playerHudPosition = ProjectBattleHudPosition.bottomEnd, this.showOwnerLabel = true, this.showLevel = true, this.showExactHp = true, this.hpBarShape = ProjectBattleHpBarShape.rounded, this.hpHealthyColor = '#16794B', this.hpWarningColor = '#8A5100', this.hpDangerColor = '#B4233C', this.statusColor = '#8A5100', this.moves = const ProjectBattlePanelPresentationProfile(), this.target = const ProjectBattlePanelPresentationProfile(), this.message = const ProjectBattlePanelPresentationProfile()}): _commands = commands,super._();
  factory _ProjectBattlePresentationProfile.fromJson(Map<String, dynamic> json) => _$ProjectBattlePresentationProfileFromJson(json);

@override@JsonKey() final  ProjectBattleCommandLayout commandLayout;
@override@JsonKey() final  int commandColumns;
@override@JsonKey() final  bool showCommandIcons;
@override@JsonKey() final  ProjectWindowShape commandShape;
@override@JsonKey() final  double commandPadding;
@override@JsonKey(includeIfNull: false) final  String? commandSurfaceColor;
@override@JsonKey(includeIfNull: false) final  String? commandBorderColor;
@override@JsonKey(includeIfNull: false) final  String? commandTextColor;
@override@JsonKey(includeIfNull: false) final  String? commandSelectionColor;
 final  List<ProjectBattleCommandProfile>? _commands;
@override@JsonKey(includeIfNull: false) List<ProjectBattleCommandProfile>? get commands {
  final value = _commands;
  if (value == null) return null;
  if (_commands is EqualUnmodifiableListView) return _commands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  ProjectWindowShape hudShape;
@override@JsonKey() final  ProjectBattleHudPosition enemyHudPosition;
@override@JsonKey() final  ProjectBattleHudPosition playerHudPosition;
@override@JsonKey() final  bool showOwnerLabel;
@override@JsonKey() final  bool showLevel;
@override@JsonKey() final  bool showExactHp;
@override@JsonKey() final  ProjectBattleHpBarShape hpBarShape;
@override@JsonKey() final  String hpHealthyColor;
@override@JsonKey() final  String hpWarningColor;
@override@JsonKey() final  String hpDangerColor;
@override@JsonKey() final  String statusColor;
@override@JsonKey() final  ProjectBattlePanelPresentationProfile moves;
@override@JsonKey() final  ProjectBattlePanelPresentationProfile target;
@override@JsonKey() final  ProjectBattlePanelPresentationProfile message;

/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectBattlePresentationProfileCopyWith<_ProjectBattlePresentationProfile> get copyWith => __$ProjectBattlePresentationProfileCopyWithImpl<_ProjectBattlePresentationProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectBattlePresentationProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectBattlePresentationProfile&&(identical(other.commandLayout, commandLayout) || other.commandLayout == commandLayout)&&(identical(other.commandColumns, commandColumns) || other.commandColumns == commandColumns)&&(identical(other.showCommandIcons, showCommandIcons) || other.showCommandIcons == showCommandIcons)&&(identical(other.commandShape, commandShape) || other.commandShape == commandShape)&&(identical(other.commandPadding, commandPadding) || other.commandPadding == commandPadding)&&(identical(other.commandSurfaceColor, commandSurfaceColor) || other.commandSurfaceColor == commandSurfaceColor)&&(identical(other.commandBorderColor, commandBorderColor) || other.commandBorderColor == commandBorderColor)&&(identical(other.commandTextColor, commandTextColor) || other.commandTextColor == commandTextColor)&&(identical(other.commandSelectionColor, commandSelectionColor) || other.commandSelectionColor == commandSelectionColor)&&const DeepCollectionEquality().equals(other._commands, _commands)&&(identical(other.hudShape, hudShape) || other.hudShape == hudShape)&&(identical(other.enemyHudPosition, enemyHudPosition) || other.enemyHudPosition == enemyHudPosition)&&(identical(other.playerHudPosition, playerHudPosition) || other.playerHudPosition == playerHudPosition)&&(identical(other.showOwnerLabel, showOwnerLabel) || other.showOwnerLabel == showOwnerLabel)&&(identical(other.showLevel, showLevel) || other.showLevel == showLevel)&&(identical(other.showExactHp, showExactHp) || other.showExactHp == showExactHp)&&(identical(other.hpBarShape, hpBarShape) || other.hpBarShape == hpBarShape)&&(identical(other.hpHealthyColor, hpHealthyColor) || other.hpHealthyColor == hpHealthyColor)&&(identical(other.hpWarningColor, hpWarningColor) || other.hpWarningColor == hpWarningColor)&&(identical(other.hpDangerColor, hpDangerColor) || other.hpDangerColor == hpDangerColor)&&(identical(other.statusColor, statusColor) || other.statusColor == statusColor)&&(identical(other.moves, moves) || other.moves == moves)&&(identical(other.target, target) || other.target == target)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,commandLayout,commandColumns,showCommandIcons,commandShape,commandPadding,commandSurfaceColor,commandBorderColor,commandTextColor,commandSelectionColor,const DeepCollectionEquality().hash(_commands),hudShape,enemyHudPosition,playerHudPosition,showOwnerLabel,showLevel,showExactHp,hpBarShape,hpHealthyColor,hpWarningColor,hpDangerColor,statusColor,moves,target,message]);

@override
String toString() {
  return 'ProjectBattlePresentationProfile(commandLayout: $commandLayout, commandColumns: $commandColumns, showCommandIcons: $showCommandIcons, commandShape: $commandShape, commandPadding: $commandPadding, commandSurfaceColor: $commandSurfaceColor, commandBorderColor: $commandBorderColor, commandTextColor: $commandTextColor, commandSelectionColor: $commandSelectionColor, commands: $commands, hudShape: $hudShape, enemyHudPosition: $enemyHudPosition, playerHudPosition: $playerHudPosition, showOwnerLabel: $showOwnerLabel, showLevel: $showLevel, showExactHp: $showExactHp, hpBarShape: $hpBarShape, hpHealthyColor: $hpHealthyColor, hpWarningColor: $hpWarningColor, hpDangerColor: $hpDangerColor, statusColor: $statusColor, moves: $moves, target: $target, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ProjectBattlePresentationProfileCopyWith<$Res> implements $ProjectBattlePresentationProfileCopyWith<$Res> {
  factory _$ProjectBattlePresentationProfileCopyWith(_ProjectBattlePresentationProfile value, $Res Function(_ProjectBattlePresentationProfile) _then) = __$ProjectBattlePresentationProfileCopyWithImpl;
@override @useResult
$Res call({
 ProjectBattleCommandLayout commandLayout, int commandColumns, bool showCommandIcons, ProjectWindowShape commandShape, double commandPadding,@JsonKey(includeIfNull: false) String? commandSurfaceColor,@JsonKey(includeIfNull: false) String? commandBorderColor,@JsonKey(includeIfNull: false) String? commandTextColor,@JsonKey(includeIfNull: false) String? commandSelectionColor,@JsonKey(includeIfNull: false) List<ProjectBattleCommandProfile>? commands, ProjectWindowShape hudShape, ProjectBattleHudPosition enemyHudPosition, ProjectBattleHudPosition playerHudPosition, bool showOwnerLabel, bool showLevel, bool showExactHp, ProjectBattleHpBarShape hpBarShape, String hpHealthyColor, String hpWarningColor, String hpDangerColor, String statusColor, ProjectBattlePanelPresentationProfile moves, ProjectBattlePanelPresentationProfile target, ProjectBattlePanelPresentationProfile message
});


@override $ProjectBattlePanelPresentationProfileCopyWith<$Res> get moves;@override $ProjectBattlePanelPresentationProfileCopyWith<$Res> get target;@override $ProjectBattlePanelPresentationProfileCopyWith<$Res> get message;

}
/// @nodoc
class __$ProjectBattlePresentationProfileCopyWithImpl<$Res>
    implements _$ProjectBattlePresentationProfileCopyWith<$Res> {
  __$ProjectBattlePresentationProfileCopyWithImpl(this._self, this._then);

  final _ProjectBattlePresentationProfile _self;
  final $Res Function(_ProjectBattlePresentationProfile) _then;

/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? commandLayout = null,Object? commandColumns = null,Object? showCommandIcons = null,Object? commandShape = null,Object? commandPadding = null,Object? commandSurfaceColor = freezed,Object? commandBorderColor = freezed,Object? commandTextColor = freezed,Object? commandSelectionColor = freezed,Object? commands = freezed,Object? hudShape = null,Object? enemyHudPosition = null,Object? playerHudPosition = null,Object? showOwnerLabel = null,Object? showLevel = null,Object? showExactHp = null,Object? hpBarShape = null,Object? hpHealthyColor = null,Object? hpWarningColor = null,Object? hpDangerColor = null,Object? statusColor = null,Object? moves = null,Object? target = null,Object? message = null,}) {
  return _then(_ProjectBattlePresentationProfile(
commandLayout: null == commandLayout ? _self.commandLayout : commandLayout // ignore: cast_nullable_to_non_nullable
as ProjectBattleCommandLayout,commandColumns: null == commandColumns ? _self.commandColumns : commandColumns // ignore: cast_nullable_to_non_nullable
as int,showCommandIcons: null == showCommandIcons ? _self.showCommandIcons : showCommandIcons // ignore: cast_nullable_to_non_nullable
as bool,commandShape: null == commandShape ? _self.commandShape : commandShape // ignore: cast_nullable_to_non_nullable
as ProjectWindowShape,commandPadding: null == commandPadding ? _self.commandPadding : commandPadding // ignore: cast_nullable_to_non_nullable
as double,commandSurfaceColor: freezed == commandSurfaceColor ? _self.commandSurfaceColor : commandSurfaceColor // ignore: cast_nullable_to_non_nullable
as String?,commandBorderColor: freezed == commandBorderColor ? _self.commandBorderColor : commandBorderColor // ignore: cast_nullable_to_non_nullable
as String?,commandTextColor: freezed == commandTextColor ? _self.commandTextColor : commandTextColor // ignore: cast_nullable_to_non_nullable
as String?,commandSelectionColor: freezed == commandSelectionColor ? _self.commandSelectionColor : commandSelectionColor // ignore: cast_nullable_to_non_nullable
as String?,commands: freezed == commands ? _self._commands : commands // ignore: cast_nullable_to_non_nullable
as List<ProjectBattleCommandProfile>?,hudShape: null == hudShape ? _self.hudShape : hudShape // ignore: cast_nullable_to_non_nullable
as ProjectWindowShape,enemyHudPosition: null == enemyHudPosition ? _self.enemyHudPosition : enemyHudPosition // ignore: cast_nullable_to_non_nullable
as ProjectBattleHudPosition,playerHudPosition: null == playerHudPosition ? _self.playerHudPosition : playerHudPosition // ignore: cast_nullable_to_non_nullable
as ProjectBattleHudPosition,showOwnerLabel: null == showOwnerLabel ? _self.showOwnerLabel : showOwnerLabel // ignore: cast_nullable_to_non_nullable
as bool,showLevel: null == showLevel ? _self.showLevel : showLevel // ignore: cast_nullable_to_non_nullable
as bool,showExactHp: null == showExactHp ? _self.showExactHp : showExactHp // ignore: cast_nullable_to_non_nullable
as bool,hpBarShape: null == hpBarShape ? _self.hpBarShape : hpBarShape // ignore: cast_nullable_to_non_nullable
as ProjectBattleHpBarShape,hpHealthyColor: null == hpHealthyColor ? _self.hpHealthyColor : hpHealthyColor // ignore: cast_nullable_to_non_nullable
as String,hpWarningColor: null == hpWarningColor ? _self.hpWarningColor : hpWarningColor // ignore: cast_nullable_to_non_nullable
as String,hpDangerColor: null == hpDangerColor ? _self.hpDangerColor : hpDangerColor // ignore: cast_nullable_to_non_nullable
as String,statusColor: null == statusColor ? _self.statusColor : statusColor // ignore: cast_nullable_to_non_nullable
as String,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as ProjectBattlePanelPresentationProfile,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ProjectBattlePanelPresentationProfile,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ProjectBattlePanelPresentationProfile,
  ));
}

/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattlePanelPresentationProfileCopyWith<$Res> get moves {

  return $ProjectBattlePanelPresentationProfileCopyWith<$Res>(_self.moves, (value) {
    return _then(_self.copyWith(moves: value));
  });
}/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattlePanelPresentationProfileCopyWith<$Res> get target {

  return $ProjectBattlePanelPresentationProfileCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of ProjectBattlePresentationProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattlePanelPresentationProfileCopyWith<$Res> get message {

  return $ProjectBattlePanelPresentationProfileCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

// dart format on
