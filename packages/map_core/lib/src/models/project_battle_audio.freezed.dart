// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_battle_audio.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectBattleAudioConfig {

/// Combat contre un Pokémon sauvage.
@JsonKey(includeIfNull: false) String? get wildBattleMusicPath;/// Combat contre un dresseur, quand le dresseur n'en porte pas.
@JsonKey(includeIfNull: false) String? get trainerBattleMusicPath;/// Thème de victoire d'un combat sauvage.
@JsonKey(includeIfNull: false) String? get wildVictoryMusicPath;/// Thème de victoire d'un combat de dresseur.
@JsonKey(includeIfNull: false) String? get trainerVictoryMusicPath;/// Musique de rencontre, jouée au repérage (le « ! ») avant le combat.
@JsonKey(includeIfNull: false) String? get encounterMusicPath;
/// Create a copy of ProjectBattleAudioConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectBattleAudioConfigCopyWith<ProjectBattleAudioConfig> get copyWith => _$ProjectBattleAudioConfigCopyWithImpl<ProjectBattleAudioConfig>(this as ProjectBattleAudioConfig, _$identity);

  /// Serializes this ProjectBattleAudioConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectBattleAudioConfig&&(identical(other.wildBattleMusicPath, wildBattleMusicPath) || other.wildBattleMusicPath == wildBattleMusicPath)&&(identical(other.trainerBattleMusicPath, trainerBattleMusicPath) || other.trainerBattleMusicPath == trainerBattleMusicPath)&&(identical(other.wildVictoryMusicPath, wildVictoryMusicPath) || other.wildVictoryMusicPath == wildVictoryMusicPath)&&(identical(other.trainerVictoryMusicPath, trainerVictoryMusicPath) || other.trainerVictoryMusicPath == trainerVictoryMusicPath)&&(identical(other.encounterMusicPath, encounterMusicPath) || other.encounterMusicPath == encounterMusicPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wildBattleMusicPath,trainerBattleMusicPath,wildVictoryMusicPath,trainerVictoryMusicPath,encounterMusicPath);

@override
String toString() {
  return 'ProjectBattleAudioConfig(wildBattleMusicPath: $wildBattleMusicPath, trainerBattleMusicPath: $trainerBattleMusicPath, wildVictoryMusicPath: $wildVictoryMusicPath, trainerVictoryMusicPath: $trainerVictoryMusicPath, encounterMusicPath: $encounterMusicPath)';
}


}

/// @nodoc
abstract mixin class $ProjectBattleAudioConfigCopyWith<$Res>  {
  factory $ProjectBattleAudioConfigCopyWith(ProjectBattleAudioConfig value, $Res Function(ProjectBattleAudioConfig) _then) = _$ProjectBattleAudioConfigCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? wildBattleMusicPath,@JsonKey(includeIfNull: false) String? trainerBattleMusicPath,@JsonKey(includeIfNull: false) String? wildVictoryMusicPath,@JsonKey(includeIfNull: false) String? trainerVictoryMusicPath,@JsonKey(includeIfNull: false) String? encounterMusicPath
});




}
/// @nodoc
class _$ProjectBattleAudioConfigCopyWithImpl<$Res>
    implements $ProjectBattleAudioConfigCopyWith<$Res> {
  _$ProjectBattleAudioConfigCopyWithImpl(this._self, this._then);

  final ProjectBattleAudioConfig _self;
  final $Res Function(ProjectBattleAudioConfig) _then;

/// Create a copy of ProjectBattleAudioConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wildBattleMusicPath = freezed,Object? trainerBattleMusicPath = freezed,Object? wildVictoryMusicPath = freezed,Object? trainerVictoryMusicPath = freezed,Object? encounterMusicPath = freezed,}) {
  return _then(_self.copyWith(
wildBattleMusicPath: freezed == wildBattleMusicPath ? _self.wildBattleMusicPath : wildBattleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,trainerBattleMusicPath: freezed == trainerBattleMusicPath ? _self.trainerBattleMusicPath : trainerBattleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,wildVictoryMusicPath: freezed == wildVictoryMusicPath ? _self.wildVictoryMusicPath : wildVictoryMusicPath // ignore: cast_nullable_to_non_nullable
as String?,trainerVictoryMusicPath: freezed == trainerVictoryMusicPath ? _self.trainerVictoryMusicPath : trainerVictoryMusicPath // ignore: cast_nullable_to_non_nullable
as String?,encounterMusicPath: freezed == encounterMusicPath ? _self.encounterMusicPath : encounterMusicPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectBattleAudioConfig].
extension ProjectBattleAudioConfigPatterns on ProjectBattleAudioConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectBattleAudioConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectBattleAudioConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectBattleAudioConfig value)  $default,){
final _that = this;
switch (_that) {
case _ProjectBattleAudioConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectBattleAudioConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectBattleAudioConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? wildBattleMusicPath, @JsonKey(includeIfNull: false)  String? trainerBattleMusicPath, @JsonKey(includeIfNull: false)  String? wildVictoryMusicPath, @JsonKey(includeIfNull: false)  String? trainerVictoryMusicPath, @JsonKey(includeIfNull: false)  String? encounterMusicPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectBattleAudioConfig() when $default != null:
return $default(_that.wildBattleMusicPath,_that.trainerBattleMusicPath,_that.wildVictoryMusicPath,_that.trainerVictoryMusicPath,_that.encounterMusicPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? wildBattleMusicPath, @JsonKey(includeIfNull: false)  String? trainerBattleMusicPath, @JsonKey(includeIfNull: false)  String? wildVictoryMusicPath, @JsonKey(includeIfNull: false)  String? trainerVictoryMusicPath, @JsonKey(includeIfNull: false)  String? encounterMusicPath)  $default,) {final _that = this;
switch (_that) {
case _ProjectBattleAudioConfig():
return $default(_that.wildBattleMusicPath,_that.trainerBattleMusicPath,_that.wildVictoryMusicPath,_that.trainerVictoryMusicPath,_that.encounterMusicPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? wildBattleMusicPath, @JsonKey(includeIfNull: false)  String? trainerBattleMusicPath, @JsonKey(includeIfNull: false)  String? wildVictoryMusicPath, @JsonKey(includeIfNull: false)  String? trainerVictoryMusicPath, @JsonKey(includeIfNull: false)  String? encounterMusicPath)?  $default,) {final _that = this;
switch (_that) {
case _ProjectBattleAudioConfig() when $default != null:
return $default(_that.wildBattleMusicPath,_that.trainerBattleMusicPath,_that.wildVictoryMusicPath,_that.trainerVictoryMusicPath,_that.encounterMusicPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectBattleAudioConfig implements ProjectBattleAudioConfig {
  const _ProjectBattleAudioConfig({@JsonKey(includeIfNull: false) this.wildBattleMusicPath, @JsonKey(includeIfNull: false) this.trainerBattleMusicPath, @JsonKey(includeIfNull: false) this.wildVictoryMusicPath, @JsonKey(includeIfNull: false) this.trainerVictoryMusicPath, @JsonKey(includeIfNull: false) this.encounterMusicPath});
  factory _ProjectBattleAudioConfig.fromJson(Map<String, dynamic> json) => _$ProjectBattleAudioConfigFromJson(json);

/// Combat contre un Pokémon sauvage.
@override@JsonKey(includeIfNull: false) final  String? wildBattleMusicPath;
/// Combat contre un dresseur, quand le dresseur n'en porte pas.
@override@JsonKey(includeIfNull: false) final  String? trainerBattleMusicPath;
/// Thème de victoire d'un combat sauvage.
@override@JsonKey(includeIfNull: false) final  String? wildVictoryMusicPath;
/// Thème de victoire d'un combat de dresseur.
@override@JsonKey(includeIfNull: false) final  String? trainerVictoryMusicPath;
/// Musique de rencontre, jouée au repérage (le « ! ») avant le combat.
@override@JsonKey(includeIfNull: false) final  String? encounterMusicPath;

/// Create a copy of ProjectBattleAudioConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectBattleAudioConfigCopyWith<_ProjectBattleAudioConfig> get copyWith => __$ProjectBattleAudioConfigCopyWithImpl<_ProjectBattleAudioConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectBattleAudioConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectBattleAudioConfig&&(identical(other.wildBattleMusicPath, wildBattleMusicPath) || other.wildBattleMusicPath == wildBattleMusicPath)&&(identical(other.trainerBattleMusicPath, trainerBattleMusicPath) || other.trainerBattleMusicPath == trainerBattleMusicPath)&&(identical(other.wildVictoryMusicPath, wildVictoryMusicPath) || other.wildVictoryMusicPath == wildVictoryMusicPath)&&(identical(other.trainerVictoryMusicPath, trainerVictoryMusicPath) || other.trainerVictoryMusicPath == trainerVictoryMusicPath)&&(identical(other.encounterMusicPath, encounterMusicPath) || other.encounterMusicPath == encounterMusicPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wildBattleMusicPath,trainerBattleMusicPath,wildVictoryMusicPath,trainerVictoryMusicPath,encounterMusicPath);

@override
String toString() {
  return 'ProjectBattleAudioConfig(wildBattleMusicPath: $wildBattleMusicPath, trainerBattleMusicPath: $trainerBattleMusicPath, wildVictoryMusicPath: $wildVictoryMusicPath, trainerVictoryMusicPath: $trainerVictoryMusicPath, encounterMusicPath: $encounterMusicPath)';
}


}

/// @nodoc
abstract mixin class _$ProjectBattleAudioConfigCopyWith<$Res> implements $ProjectBattleAudioConfigCopyWith<$Res> {
  factory _$ProjectBattleAudioConfigCopyWith(_ProjectBattleAudioConfig value, $Res Function(_ProjectBattleAudioConfig) _then) = __$ProjectBattleAudioConfigCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? wildBattleMusicPath,@JsonKey(includeIfNull: false) String? trainerBattleMusicPath,@JsonKey(includeIfNull: false) String? wildVictoryMusicPath,@JsonKey(includeIfNull: false) String? trainerVictoryMusicPath,@JsonKey(includeIfNull: false) String? encounterMusicPath
});




}
/// @nodoc
class __$ProjectBattleAudioConfigCopyWithImpl<$Res>
    implements _$ProjectBattleAudioConfigCopyWith<$Res> {
  __$ProjectBattleAudioConfigCopyWithImpl(this._self, this._then);

  final _ProjectBattleAudioConfig _self;
  final $Res Function(_ProjectBattleAudioConfig) _then;

/// Create a copy of ProjectBattleAudioConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wildBattleMusicPath = freezed,Object? trainerBattleMusicPath = freezed,Object? wildVictoryMusicPath = freezed,Object? trainerVictoryMusicPath = freezed,Object? encounterMusicPath = freezed,}) {
  return _then(_ProjectBattleAudioConfig(
wildBattleMusicPath: freezed == wildBattleMusicPath ? _self.wildBattleMusicPath : wildBattleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,trainerBattleMusicPath: freezed == trainerBattleMusicPath ? _self.trainerBattleMusicPath : trainerBattleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,wildVictoryMusicPath: freezed == wildVictoryMusicPath ? _self.wildVictoryMusicPath : wildVictoryMusicPath // ignore: cast_nullable_to_non_nullable
as String?,trainerVictoryMusicPath: freezed == trainerVictoryMusicPath ? _self.trainerVictoryMusicPath : trainerVictoryMusicPath // ignore: cast_nullable_to_non_nullable
as String?,encounterMusicPath: freezed == encounterMusicPath ? _self.encounterMusicPath : encounterMusicPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
