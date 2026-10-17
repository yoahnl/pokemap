// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_gameplay_zone_payloads.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EncounterZonePayload {

/// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
 String? get encounterTableId;/// Type de rencontre déclenchée dans cette zone.
 EncounterKind get encounterKind;/// Image de fond de combat authorée explicitement pour cette zone.
///
/// Le chemin reste project-local et optionnel :
/// - aucune bibliothèque média globale n'est introduite ici ;
/// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
/// - l'absence de valeur garde le comportement contextuel existant.
 String? get battleBackgroundRelativePath;/// Musique des combats déclenchés dans cette zone — BETA-BAT-015.
///
/// Même sémantique que le fond : chemin project-local optionnel. La
/// chaîne runtime la place entre le thème explicite du dresseur et la
/// musique de combat de la carte ; vide = la chaîne continue.
 String? get battleMusicPath;/// Musique de rencontre jouée quand un dresseur repère le joueur dans
/// cette zone — BETA-BAT-015. Gagne sur le défaut projet ; vide = défaut.
 String? get encounterMusicPath;/// Transitions de début de combat de cette zone — BETA-BAT-019.
///
/// Des ids du registre moteur (`battleTransitionRegistry`). Plusieurs
/// valeurs = le runtime en tire une par rencontre (déterministe par
/// requête, donc rejouable). Vide = le défaut projet puis le défaut
/// moteur ; un id inconnu retombe sur le défaut du type sans jamais
/// casser l'entrée en combat.
 List<String> get battleTransitionIds;
/// Create a copy of EncounterZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EncounterZonePayloadCopyWith<EncounterZonePayload> get copyWith => _$EncounterZonePayloadCopyWithImpl<EncounterZonePayload>(this as EncounterZonePayload, _$identity);

  /// Serializes this EncounterZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EncounterZonePayload&&(identical(other.encounterTableId, encounterTableId) || other.encounterTableId == encounterTableId)&&(identical(other.encounterKind, encounterKind) || other.encounterKind == encounterKind)&&(identical(other.battleBackgroundRelativePath, battleBackgroundRelativePath) || other.battleBackgroundRelativePath == battleBackgroundRelativePath)&&(identical(other.battleMusicPath, battleMusicPath) || other.battleMusicPath == battleMusicPath)&&(identical(other.encounterMusicPath, encounterMusicPath) || other.encounterMusicPath == encounterMusicPath)&&const DeepCollectionEquality().equals(other.battleTransitionIds, battleTransitionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,encounterTableId,encounterKind,battleBackgroundRelativePath,battleMusicPath,encounterMusicPath,const DeepCollectionEquality().hash(battleTransitionIds));

@override
String toString() {
  return 'EncounterZonePayload(encounterTableId: $encounterTableId, encounterKind: $encounterKind, battleBackgroundRelativePath: $battleBackgroundRelativePath, battleMusicPath: $battleMusicPath, encounterMusicPath: $encounterMusicPath, battleTransitionIds: $battleTransitionIds)';
}


}

/// @nodoc
abstract mixin class $EncounterZonePayloadCopyWith<$Res>  {
  factory $EncounterZonePayloadCopyWith(EncounterZonePayload value, $Res Function(EncounterZonePayload) _then) = _$EncounterZonePayloadCopyWithImpl;
@useResult
$Res call({
 String? encounterTableId, EncounterKind encounterKind, String? battleBackgroundRelativePath, String? battleMusicPath, String? encounterMusicPath, List<String> battleTransitionIds
});




}
/// @nodoc
class _$EncounterZonePayloadCopyWithImpl<$Res>
    implements $EncounterZonePayloadCopyWith<$Res> {
  _$EncounterZonePayloadCopyWithImpl(this._self, this._then);

  final EncounterZonePayload _self;
  final $Res Function(EncounterZonePayload) _then;

/// Create a copy of EncounterZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? encounterTableId = freezed,Object? encounterKind = null,Object? battleBackgroundRelativePath = freezed,Object? battleMusicPath = freezed,Object? encounterMusicPath = freezed,Object? battleTransitionIds = null,}) {
  return _then(_self.copyWith(
encounterTableId: freezed == encounterTableId ? _self.encounterTableId : encounterTableId // ignore: cast_nullable_to_non_nullable
as String?,encounterKind: null == encounterKind ? _self.encounterKind : encounterKind // ignore: cast_nullable_to_non_nullable
as EncounterKind,battleBackgroundRelativePath: freezed == battleBackgroundRelativePath ? _self.battleBackgroundRelativePath : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
as String?,battleMusicPath: freezed == battleMusicPath ? _self.battleMusicPath : battleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,encounterMusicPath: freezed == encounterMusicPath ? _self.encounterMusicPath : encounterMusicPath // ignore: cast_nullable_to_non_nullable
as String?,battleTransitionIds: null == battleTransitionIds ? _self.battleTransitionIds : battleTransitionIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [EncounterZonePayload].
extension EncounterZonePayloadPatterns on EncounterZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EncounterZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EncounterZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EncounterZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _EncounterZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EncounterZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _EncounterZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? encounterTableId,  EncounterKind encounterKind,  String? battleBackgroundRelativePath,  String? battleMusicPath,  String? encounterMusicPath,  List<String> battleTransitionIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EncounterZonePayload() when $default != null:
return $default(_that.encounterTableId,_that.encounterKind,_that.battleBackgroundRelativePath,_that.battleMusicPath,_that.encounterMusicPath,_that.battleTransitionIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? encounterTableId,  EncounterKind encounterKind,  String? battleBackgroundRelativePath,  String? battleMusicPath,  String? encounterMusicPath,  List<String> battleTransitionIds)  $default,) {final _that = this;
switch (_that) {
case _EncounterZonePayload():
return $default(_that.encounterTableId,_that.encounterKind,_that.battleBackgroundRelativePath,_that.battleMusicPath,_that.encounterMusicPath,_that.battleTransitionIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? encounterTableId,  EncounterKind encounterKind,  String? battleBackgroundRelativePath,  String? battleMusicPath,  String? encounterMusicPath,  List<String> battleTransitionIds)?  $default,) {final _that = this;
switch (_that) {
case _EncounterZonePayload() when $default != null:
return $default(_that.encounterTableId,_that.encounterKind,_that.battleBackgroundRelativePath,_that.battleMusicPath,_that.encounterMusicPath,_that.battleTransitionIds);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _EncounterZonePayload implements EncounterZonePayload {
  const _EncounterZonePayload({this.encounterTableId, this.encounterKind = EncounterKind.walk, this.battleBackgroundRelativePath, this.battleMusicPath, this.encounterMusicPath, final  List<String> battleTransitionIds = const <String>[]}): _battleTransitionIds = battleTransitionIds;
  factory _EncounterZonePayload.fromJson(Map<String, dynamic> json) => _$EncounterZonePayloadFromJson(json);

/// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
@override final  String? encounterTableId;
/// Type de rencontre déclenchée dans cette zone.
@override@JsonKey() final  EncounterKind encounterKind;
/// Image de fond de combat authorée explicitement pour cette zone.
///
/// Le chemin reste project-local et optionnel :
/// - aucune bibliothèque média globale n'est introduite ici ;
/// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
/// - l'absence de valeur garde le comportement contextuel existant.
@override final  String? battleBackgroundRelativePath;
/// Musique des combats déclenchés dans cette zone — BETA-BAT-015.
///
/// Même sémantique que le fond : chemin project-local optionnel. La
/// chaîne runtime la place entre le thème explicite du dresseur et la
/// musique de combat de la carte ; vide = la chaîne continue.
@override final  String? battleMusicPath;
/// Musique de rencontre jouée quand un dresseur repère le joueur dans
/// cette zone — BETA-BAT-015. Gagne sur le défaut projet ; vide = défaut.
@override final  String? encounterMusicPath;
/// Transitions de début de combat de cette zone — BETA-BAT-019.
///
/// Des ids du registre moteur (`battleTransitionRegistry`). Plusieurs
/// valeurs = le runtime en tire une par rencontre (déterministe par
/// requête, donc rejouable). Vide = le défaut projet puis le défaut
/// moteur ; un id inconnu retombe sur le défaut du type sans jamais
/// casser l'entrée en combat.
 final  List<String> _battleTransitionIds;
/// Transitions de début de combat de cette zone — BETA-BAT-019.
///
/// Des ids du registre moteur (`battleTransitionRegistry`). Plusieurs
/// valeurs = le runtime en tire une par rencontre (déterministe par
/// requête, donc rejouable). Vide = le défaut projet puis le défaut
/// moteur ; un id inconnu retombe sur le défaut du type sans jamais
/// casser l'entrée en combat.
@override@JsonKey() List<String> get battleTransitionIds {
  if (_battleTransitionIds is EqualUnmodifiableListView) return _battleTransitionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_battleTransitionIds);
}


/// Create a copy of EncounterZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EncounterZonePayloadCopyWith<_EncounterZonePayload> get copyWith => __$EncounterZonePayloadCopyWithImpl<_EncounterZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EncounterZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EncounterZonePayload&&(identical(other.encounterTableId, encounterTableId) || other.encounterTableId == encounterTableId)&&(identical(other.encounterKind, encounterKind) || other.encounterKind == encounterKind)&&(identical(other.battleBackgroundRelativePath, battleBackgroundRelativePath) || other.battleBackgroundRelativePath == battleBackgroundRelativePath)&&(identical(other.battleMusicPath, battleMusicPath) || other.battleMusicPath == battleMusicPath)&&(identical(other.encounterMusicPath, encounterMusicPath) || other.encounterMusicPath == encounterMusicPath)&&const DeepCollectionEquality().equals(other._battleTransitionIds, _battleTransitionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,encounterTableId,encounterKind,battleBackgroundRelativePath,battleMusicPath,encounterMusicPath,const DeepCollectionEquality().hash(_battleTransitionIds));

@override
String toString() {
  return 'EncounterZonePayload(encounterTableId: $encounterTableId, encounterKind: $encounterKind, battleBackgroundRelativePath: $battleBackgroundRelativePath, battleMusicPath: $battleMusicPath, encounterMusicPath: $encounterMusicPath, battleTransitionIds: $battleTransitionIds)';
}


}

/// @nodoc
abstract mixin class _$EncounterZonePayloadCopyWith<$Res> implements $EncounterZonePayloadCopyWith<$Res> {
  factory _$EncounterZonePayloadCopyWith(_EncounterZonePayload value, $Res Function(_EncounterZonePayload) _then) = __$EncounterZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 String? encounterTableId, EncounterKind encounterKind, String? battleBackgroundRelativePath, String? battleMusicPath, String? encounterMusicPath, List<String> battleTransitionIds
});




}
/// @nodoc
class __$EncounterZonePayloadCopyWithImpl<$Res>
    implements _$EncounterZonePayloadCopyWith<$Res> {
  __$EncounterZonePayloadCopyWithImpl(this._self, this._then);

  final _EncounterZonePayload _self;
  final $Res Function(_EncounterZonePayload) _then;

/// Create a copy of EncounterZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? encounterTableId = freezed,Object? encounterKind = null,Object? battleBackgroundRelativePath = freezed,Object? battleMusicPath = freezed,Object? encounterMusicPath = freezed,Object? battleTransitionIds = null,}) {
  return _then(_EncounterZonePayload(
encounterTableId: freezed == encounterTableId ? _self.encounterTableId : encounterTableId // ignore: cast_nullable_to_non_nullable
as String?,encounterKind: null == encounterKind ? _self.encounterKind : encounterKind // ignore: cast_nullable_to_non_nullable
as EncounterKind,battleBackgroundRelativePath: freezed == battleBackgroundRelativePath ? _self.battleBackgroundRelativePath : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
as String?,battleMusicPath: freezed == battleMusicPath ? _self.battleMusicPath : battleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,encounterMusicPath: freezed == encounterMusicPath ? _self.encounterMusicPath : encounterMusicPath // ignore: cast_nullable_to_non_nullable
as String?,battleTransitionIds: null == battleTransitionIds ? _self._battleTransitionIds : battleTransitionIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$MovementZonePayload {

/// Mode de déplacement requis pour traverser la zone.
 MovementMode get requiredMode;/// Modes supplémentaires autorisés en plus de [requiredMode].
 List<MovementMode> get allowedModes;
/// Create a copy of MovementZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementZonePayloadCopyWith<MovementZonePayload> get copyWith => _$MovementZonePayloadCopyWithImpl<MovementZonePayload>(this as MovementZonePayload, _$identity);

  /// Serializes this MovementZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementZonePayload&&(identical(other.requiredMode, requiredMode) || other.requiredMode == requiredMode)&&const DeepCollectionEquality().equals(other.allowedModes, allowedModes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requiredMode,const DeepCollectionEquality().hash(allowedModes));

@override
String toString() {
  return 'MovementZonePayload(requiredMode: $requiredMode, allowedModes: $allowedModes)';
}


}

/// @nodoc
abstract mixin class $MovementZonePayloadCopyWith<$Res>  {
  factory $MovementZonePayloadCopyWith(MovementZonePayload value, $Res Function(MovementZonePayload) _then) = _$MovementZonePayloadCopyWithImpl;
@useResult
$Res call({
 MovementMode requiredMode, List<MovementMode> allowedModes
});




}
/// @nodoc
class _$MovementZonePayloadCopyWithImpl<$Res>
    implements $MovementZonePayloadCopyWith<$Res> {
  _$MovementZonePayloadCopyWithImpl(this._self, this._then);

  final MovementZonePayload _self;
  final $Res Function(MovementZonePayload) _then;

/// Create a copy of MovementZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requiredMode = null,Object? allowedModes = null,}) {
  return _then(_self.copyWith(
requiredMode: null == requiredMode ? _self.requiredMode : requiredMode // ignore: cast_nullable_to_non_nullable
as MovementMode,allowedModes: null == allowedModes ? _self.allowedModes : allowedModes // ignore: cast_nullable_to_non_nullable
as List<MovementMode>,
  ));
}

}


/// Adds pattern-matching-related methods to [MovementZonePayload].
extension MovementZonePayloadPatterns on MovementZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovementZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovementZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovementZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _MovementZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovementZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _MovementZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MovementMode requiredMode,  List<MovementMode> allowedModes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovementZonePayload() when $default != null:
return $default(_that.requiredMode,_that.allowedModes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MovementMode requiredMode,  List<MovementMode> allowedModes)  $default,) {final _that = this;
switch (_that) {
case _MovementZonePayload():
return $default(_that.requiredMode,_that.allowedModes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MovementMode requiredMode,  List<MovementMode> allowedModes)?  $default,) {final _that = this;
switch (_that) {
case _MovementZonePayload() when $default != null:
return $default(_that.requiredMode,_that.allowedModes);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MovementZonePayload implements MovementZonePayload {
  const _MovementZonePayload({this.requiredMode = MovementMode.walk, final  List<MovementMode> allowedModes = const []}): _allowedModes = allowedModes;
  factory _MovementZonePayload.fromJson(Map<String, dynamic> json) => _$MovementZonePayloadFromJson(json);

/// Mode de déplacement requis pour traverser la zone.
@override@JsonKey() final  MovementMode requiredMode;
/// Modes supplémentaires autorisés en plus de [requiredMode].
 final  List<MovementMode> _allowedModes;
/// Modes supplémentaires autorisés en plus de [requiredMode].
@override@JsonKey() List<MovementMode> get allowedModes {
  if (_allowedModes is EqualUnmodifiableListView) return _allowedModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allowedModes);
}


/// Create a copy of MovementZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovementZonePayloadCopyWith<_MovementZonePayload> get copyWith => __$MovementZonePayloadCopyWithImpl<_MovementZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovementZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovementZonePayload&&(identical(other.requiredMode, requiredMode) || other.requiredMode == requiredMode)&&const DeepCollectionEquality().equals(other._allowedModes, _allowedModes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requiredMode,const DeepCollectionEquality().hash(_allowedModes));

@override
String toString() {
  return 'MovementZonePayload(requiredMode: $requiredMode, allowedModes: $allowedModes)';
}


}

/// @nodoc
abstract mixin class _$MovementZonePayloadCopyWith<$Res> implements $MovementZonePayloadCopyWith<$Res> {
  factory _$MovementZonePayloadCopyWith(_MovementZonePayload value, $Res Function(_MovementZonePayload) _then) = __$MovementZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 MovementMode requiredMode, List<MovementMode> allowedModes
});




}
/// @nodoc
class __$MovementZonePayloadCopyWithImpl<$Res>
    implements _$MovementZonePayloadCopyWith<$Res> {
  __$MovementZonePayloadCopyWithImpl(this._self, this._then);

  final _MovementZonePayload _self;
  final $Res Function(_MovementZonePayload) _then;

/// Create a copy of MovementZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requiredMode = null,Object? allowedModes = null,}) {
  return _then(_MovementZonePayload(
requiredMode: null == requiredMode ? _self.requiredMode : requiredMode // ignore: cast_nullable_to_non_nullable
as MovementMode,allowedModes: null == allowedModes ? _self._allowedModes : allowedModes // ignore: cast_nullable_to_non_nullable
as List<MovementMode>,
  ));
}


}


/// @nodoc
mixin _$MovementEffectZonePayload {

 MovementEffectZoneKind get effectKind;/// Coût entier positif pour [MovementEffectZoneKind.movementCost].
///
/// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
/// pour garder un JSON stable, mais elle n'est pas consommée.
 int get movementCost;@JsonKey(includeIfNull: false) DirectedJumpZonePayload? get directedJump;
/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementEffectZonePayloadCopyWith<MovementEffectZonePayload> get copyWith => _$MovementEffectZonePayloadCopyWithImpl<MovementEffectZonePayload>(this as MovementEffectZonePayload, _$identity);

  /// Serializes this MovementEffectZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementEffectZonePayload&&(identical(other.effectKind, effectKind) || other.effectKind == effectKind)&&(identical(other.movementCost, movementCost) || other.movementCost == movementCost)&&(identical(other.directedJump, directedJump) || other.directedJump == directedJump));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,effectKind,movementCost,directedJump);

@override
String toString() {
  return 'MovementEffectZonePayload(effectKind: $effectKind, movementCost: $movementCost, directedJump: $directedJump)';
}


}

/// @nodoc
abstract mixin class $MovementEffectZonePayloadCopyWith<$Res>  {
  factory $MovementEffectZonePayloadCopyWith(MovementEffectZonePayload value, $Res Function(MovementEffectZonePayload) _then) = _$MovementEffectZonePayloadCopyWithImpl;
@useResult
$Res call({
 MovementEffectZoneKind effectKind, int movementCost,@JsonKey(includeIfNull: false) DirectedJumpZonePayload? directedJump
});


$DirectedJumpZonePayloadCopyWith<$Res>? get directedJump;

}
/// @nodoc
class _$MovementEffectZonePayloadCopyWithImpl<$Res>
    implements $MovementEffectZonePayloadCopyWith<$Res> {
  _$MovementEffectZonePayloadCopyWithImpl(this._self, this._then);

  final MovementEffectZonePayload _self;
  final $Res Function(MovementEffectZonePayload) _then;

/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? effectKind = null,Object? movementCost = null,Object? directedJump = freezed,}) {
  return _then(_self.copyWith(
effectKind: null == effectKind ? _self.effectKind : effectKind // ignore: cast_nullable_to_non_nullable
as MovementEffectZoneKind,movementCost: null == movementCost ? _self.movementCost : movementCost // ignore: cast_nullable_to_non_nullable
as int,directedJump: freezed == directedJump ? _self.directedJump : directedJump // ignore: cast_nullable_to_non_nullable
as DirectedJumpZonePayload?,
  ));
}
/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DirectedJumpZonePayloadCopyWith<$Res>? get directedJump {
    if (_self.directedJump == null) {
    return null;
  }

  return $DirectedJumpZonePayloadCopyWith<$Res>(_self.directedJump!, (value) {
    return _then(_self.copyWith(directedJump: value));
  });
}
}


/// Adds pattern-matching-related methods to [MovementEffectZonePayload].
extension MovementEffectZonePayloadPatterns on MovementEffectZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovementEffectZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovementEffectZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovementEffectZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _MovementEffectZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovementEffectZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _MovementEffectZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MovementEffectZoneKind effectKind,  int movementCost, @JsonKey(includeIfNull: false)  DirectedJumpZonePayload? directedJump)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovementEffectZonePayload() when $default != null:
return $default(_that.effectKind,_that.movementCost,_that.directedJump);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MovementEffectZoneKind effectKind,  int movementCost, @JsonKey(includeIfNull: false)  DirectedJumpZonePayload? directedJump)  $default,) {final _that = this;
switch (_that) {
case _MovementEffectZonePayload():
return $default(_that.effectKind,_that.movementCost,_that.directedJump);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MovementEffectZoneKind effectKind,  int movementCost, @JsonKey(includeIfNull: false)  DirectedJumpZonePayload? directedJump)?  $default,) {final _that = this;
switch (_that) {
case _MovementEffectZonePayload() when $default != null:
return $default(_that.effectKind,_that.movementCost,_that.directedJump);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class _MovementEffectZonePayload implements MovementEffectZonePayload {
  const _MovementEffectZonePayload({this.effectKind = MovementEffectZoneKind.slide, this.movementCost = 1, @JsonKey(includeIfNull: false) this.directedJump});
  factory _MovementEffectZonePayload.fromJson(Map<String, dynamic> json) => _$MovementEffectZonePayloadFromJson(json);

@override@JsonKey() final  MovementEffectZoneKind effectKind;
/// Coût entier positif pour [MovementEffectZoneKind.movementCost].
///
/// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
/// pour garder un JSON stable, mais elle n'est pas consommée.
@override@JsonKey() final  int movementCost;
@override@JsonKey(includeIfNull: false) final  DirectedJumpZonePayload? directedJump;

/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovementEffectZonePayloadCopyWith<_MovementEffectZonePayload> get copyWith => __$MovementEffectZonePayloadCopyWithImpl<_MovementEffectZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovementEffectZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovementEffectZonePayload&&(identical(other.effectKind, effectKind) || other.effectKind == effectKind)&&(identical(other.movementCost, movementCost) || other.movementCost == movementCost)&&(identical(other.directedJump, directedJump) || other.directedJump == directedJump));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,effectKind,movementCost,directedJump);

@override
String toString() {
  return 'MovementEffectZonePayload(effectKind: $effectKind, movementCost: $movementCost, directedJump: $directedJump)';
}


}

/// @nodoc
abstract mixin class _$MovementEffectZonePayloadCopyWith<$Res> implements $MovementEffectZonePayloadCopyWith<$Res> {
  factory _$MovementEffectZonePayloadCopyWith(_MovementEffectZonePayload value, $Res Function(_MovementEffectZonePayload) _then) = __$MovementEffectZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 MovementEffectZoneKind effectKind, int movementCost,@JsonKey(includeIfNull: false) DirectedJumpZonePayload? directedJump
});


@override $DirectedJumpZonePayloadCopyWith<$Res>? get directedJump;

}
/// @nodoc
class __$MovementEffectZonePayloadCopyWithImpl<$Res>
    implements _$MovementEffectZonePayloadCopyWith<$Res> {
  __$MovementEffectZonePayloadCopyWithImpl(this._self, this._then);

  final _MovementEffectZonePayload _self;
  final $Res Function(_MovementEffectZonePayload) _then;

/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? effectKind = null,Object? movementCost = null,Object? directedJump = freezed,}) {
  return _then(_MovementEffectZonePayload(
effectKind: null == effectKind ? _self.effectKind : effectKind // ignore: cast_nullable_to_non_nullable
as MovementEffectZoneKind,movementCost: null == movementCost ? _self.movementCost : movementCost // ignore: cast_nullable_to_non_nullable
as int,directedJump: freezed == directedJump ? _self.directedJump : directedJump // ignore: cast_nullable_to_non_nullable
as DirectedJumpZonePayload?,
  ));
}

/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DirectedJumpZonePayloadCopyWith<$Res>? get directedJump {
    if (_self.directedJump == null) {
    return null;
  }

  return $DirectedJumpZonePayloadCopyWith<$Res>(_self.directedJump!, (value) {
    return _then(_self.copyWith(directedJump: value));
  });
}
}


/// @nodoc
mixin _$DirectedJumpZonePayload {

 MapConnectionDirection get direction; int get distanceCells; int get durationMs; int get peakHeightPx;
/// Create a copy of DirectedJumpZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DirectedJumpZonePayloadCopyWith<DirectedJumpZonePayload> get copyWith => _$DirectedJumpZonePayloadCopyWithImpl<DirectedJumpZonePayload>(this as DirectedJumpZonePayload, _$identity);

  /// Serializes this DirectedJumpZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DirectedJumpZonePayload&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.distanceCells, distanceCells) || other.distanceCells == distanceCells)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.peakHeightPx, peakHeightPx) || other.peakHeightPx == peakHeightPx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,direction,distanceCells,durationMs,peakHeightPx);

@override
String toString() {
  return 'DirectedJumpZonePayload(direction: $direction, distanceCells: $distanceCells, durationMs: $durationMs, peakHeightPx: $peakHeightPx)';
}


}

/// @nodoc
abstract mixin class $DirectedJumpZonePayloadCopyWith<$Res>  {
  factory $DirectedJumpZonePayloadCopyWith(DirectedJumpZonePayload value, $Res Function(DirectedJumpZonePayload) _then) = _$DirectedJumpZonePayloadCopyWithImpl;
@useResult
$Res call({
 MapConnectionDirection direction, int distanceCells, int durationMs, int peakHeightPx
});




}
/// @nodoc
class _$DirectedJumpZonePayloadCopyWithImpl<$Res>
    implements $DirectedJumpZonePayloadCopyWith<$Res> {
  _$DirectedJumpZonePayloadCopyWithImpl(this._self, this._then);

  final DirectedJumpZonePayload _self;
  final $Res Function(DirectedJumpZonePayload) _then;

/// Create a copy of DirectedJumpZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = null,Object? distanceCells = null,Object? durationMs = null,Object? peakHeightPx = null,}) {
  return _then(_self.copyWith(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as MapConnectionDirection,distanceCells: null == distanceCells ? _self.distanceCells : distanceCells // ignore: cast_nullable_to_non_nullable
as int,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,peakHeightPx: null == peakHeightPx ? _self.peakHeightPx : peakHeightPx // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DirectedJumpZonePayload].
extension DirectedJumpZonePayloadPatterns on DirectedJumpZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DirectedJumpZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DirectedJumpZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DirectedJumpZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _DirectedJumpZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DirectedJumpZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _DirectedJumpZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MapConnectionDirection direction,  int distanceCells,  int durationMs,  int peakHeightPx)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DirectedJumpZonePayload() when $default != null:
return $default(_that.direction,_that.distanceCells,_that.durationMs,_that.peakHeightPx);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MapConnectionDirection direction,  int distanceCells,  int durationMs,  int peakHeightPx)  $default,) {final _that = this;
switch (_that) {
case _DirectedJumpZonePayload():
return $default(_that.direction,_that.distanceCells,_that.durationMs,_that.peakHeightPx);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MapConnectionDirection direction,  int distanceCells,  int durationMs,  int peakHeightPx)?  $default,) {final _that = this;
switch (_that) {
case _DirectedJumpZonePayload() when $default != null:
return $default(_that.direction,_that.distanceCells,_that.durationMs,_that.peakHeightPx);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(disallowUnrecognizedKeys: true)
class _DirectedJumpZonePayload implements DirectedJumpZonePayload {
  const _DirectedJumpZonePayload({required this.direction, this.distanceCells = 2, this.durationMs = 500, this.peakHeightPx = 24});
  factory _DirectedJumpZonePayload.fromJson(Map<String, dynamic> json) => _$DirectedJumpZonePayloadFromJson(json);

@override final  MapConnectionDirection direction;
@override@JsonKey() final  int distanceCells;
@override@JsonKey() final  int durationMs;
@override@JsonKey() final  int peakHeightPx;

/// Create a copy of DirectedJumpZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DirectedJumpZonePayloadCopyWith<_DirectedJumpZonePayload> get copyWith => __$DirectedJumpZonePayloadCopyWithImpl<_DirectedJumpZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DirectedJumpZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DirectedJumpZonePayload&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.distanceCells, distanceCells) || other.distanceCells == distanceCells)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.peakHeightPx, peakHeightPx) || other.peakHeightPx == peakHeightPx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,direction,distanceCells,durationMs,peakHeightPx);

@override
String toString() {
  return 'DirectedJumpZonePayload(direction: $direction, distanceCells: $distanceCells, durationMs: $durationMs, peakHeightPx: $peakHeightPx)';
}


}

/// @nodoc
abstract mixin class _$DirectedJumpZonePayloadCopyWith<$Res> implements $DirectedJumpZonePayloadCopyWith<$Res> {
  factory _$DirectedJumpZonePayloadCopyWith(_DirectedJumpZonePayload value, $Res Function(_DirectedJumpZonePayload) _then) = __$DirectedJumpZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 MapConnectionDirection direction, int distanceCells, int durationMs, int peakHeightPx
});




}
/// @nodoc
class __$DirectedJumpZonePayloadCopyWithImpl<$Res>
    implements _$DirectedJumpZonePayloadCopyWith<$Res> {
  __$DirectedJumpZonePayloadCopyWithImpl(this._self, this._then);

  final _DirectedJumpZonePayload _self;
  final $Res Function(_DirectedJumpZonePayload) _then;

/// Create a copy of DirectedJumpZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = null,Object? distanceCells = null,Object? durationMs = null,Object? peakHeightPx = null,}) {
  return _then(_DirectedJumpZonePayload(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as MapConnectionDirection,distanceCells: null == distanceCells ? _self.distanceCells : distanceCells // ignore: cast_nullable_to_non_nullable
as int,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,peakHeightPx: null == peakHeightPx ? _self.peakHeightPx : peakHeightPx // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HazardZonePayload {

 HazardKind get hazardKind;/// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
 int get damagePerStep;
/// Create a copy of HazardZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HazardZonePayloadCopyWith<HazardZonePayload> get copyWith => _$HazardZonePayloadCopyWithImpl<HazardZonePayload>(this as HazardZonePayload, _$identity);

  /// Serializes this HazardZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HazardZonePayload&&(identical(other.hazardKind, hazardKind) || other.hazardKind == hazardKind)&&(identical(other.damagePerStep, damagePerStep) || other.damagePerStep == damagePerStep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hazardKind,damagePerStep);

@override
String toString() {
  return 'HazardZonePayload(hazardKind: $hazardKind, damagePerStep: $damagePerStep)';
}


}

/// @nodoc
abstract mixin class $HazardZonePayloadCopyWith<$Res>  {
  factory $HazardZonePayloadCopyWith(HazardZonePayload value, $Res Function(HazardZonePayload) _then) = _$HazardZonePayloadCopyWithImpl;
@useResult
$Res call({
 HazardKind hazardKind, int damagePerStep
});




}
/// @nodoc
class _$HazardZonePayloadCopyWithImpl<$Res>
    implements $HazardZonePayloadCopyWith<$Res> {
  _$HazardZonePayloadCopyWithImpl(this._self, this._then);

  final HazardZonePayload _self;
  final $Res Function(HazardZonePayload) _then;

/// Create a copy of HazardZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hazardKind = null,Object? damagePerStep = null,}) {
  return _then(_self.copyWith(
hazardKind: null == hazardKind ? _self.hazardKind : hazardKind // ignore: cast_nullable_to_non_nullable
as HazardKind,damagePerStep: null == damagePerStep ? _self.damagePerStep : damagePerStep // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HazardZonePayload].
extension HazardZonePayloadPatterns on HazardZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HazardZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HazardZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HazardZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _HazardZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HazardZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _HazardZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HazardKind hazardKind,  int damagePerStep)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HazardZonePayload() when $default != null:
return $default(_that.hazardKind,_that.damagePerStep);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HazardKind hazardKind,  int damagePerStep)  $default,) {final _that = this;
switch (_that) {
case _HazardZonePayload():
return $default(_that.hazardKind,_that.damagePerStep);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HazardKind hazardKind,  int damagePerStep)?  $default,) {final _that = this;
switch (_that) {
case _HazardZonePayload() when $default != null:
return $default(_that.hazardKind,_that.damagePerStep);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _HazardZonePayload implements HazardZonePayload {
  const _HazardZonePayload({this.hazardKind = HazardKind.other, this.damagePerStep = 0});
  factory _HazardZonePayload.fromJson(Map<String, dynamic> json) => _$HazardZonePayloadFromJson(json);

@override@JsonKey() final  HazardKind hazardKind;
/// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
@override@JsonKey() final  int damagePerStep;

/// Create a copy of HazardZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HazardZonePayloadCopyWith<_HazardZonePayload> get copyWith => __$HazardZonePayloadCopyWithImpl<_HazardZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HazardZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HazardZonePayload&&(identical(other.hazardKind, hazardKind) || other.hazardKind == hazardKind)&&(identical(other.damagePerStep, damagePerStep) || other.damagePerStep == damagePerStep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hazardKind,damagePerStep);

@override
String toString() {
  return 'HazardZonePayload(hazardKind: $hazardKind, damagePerStep: $damagePerStep)';
}


}

/// @nodoc
abstract mixin class _$HazardZonePayloadCopyWith<$Res> implements $HazardZonePayloadCopyWith<$Res> {
  factory _$HazardZonePayloadCopyWith(_HazardZonePayload value, $Res Function(_HazardZonePayload) _then) = __$HazardZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 HazardKind hazardKind, int damagePerStep
});




}
/// @nodoc
class __$HazardZonePayloadCopyWithImpl<$Res>
    implements _$HazardZonePayloadCopyWith<$Res> {
  __$HazardZonePayloadCopyWithImpl(this._self, this._then);

  final _HazardZonePayload _self;
  final $Res Function(_HazardZonePayload) _then;

/// Create a copy of HazardZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hazardKind = null,Object? damagePerStep = null,}) {
  return _then(_HazardZonePayload(
hazardKind: null == hazardKind ? _self.hazardKind : hazardKind // ignore: cast_nullable_to_non_nullable
as HazardKind,damagePerStep: null == damagePerStep ? _self.damagePerStep : damagePerStep // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SpecialZonePayload {

/// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
 String? get scriptKey;/// Propriétés libres (clé → valeur).
 Map<String, String> get properties;
/// Create a copy of SpecialZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpecialZonePayloadCopyWith<SpecialZonePayload> get copyWith => _$SpecialZonePayloadCopyWithImpl<SpecialZonePayload>(this as SpecialZonePayload, _$identity);

  /// Serializes this SpecialZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpecialZonePayload&&(identical(other.scriptKey, scriptKey) || other.scriptKey == scriptKey)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scriptKey,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'SpecialZonePayload(scriptKey: $scriptKey, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $SpecialZonePayloadCopyWith<$Res>  {
  factory $SpecialZonePayloadCopyWith(SpecialZonePayload value, $Res Function(SpecialZonePayload) _then) = _$SpecialZonePayloadCopyWithImpl;
@useResult
$Res call({
 String? scriptKey, Map<String, String> properties
});




}
/// @nodoc
class _$SpecialZonePayloadCopyWithImpl<$Res>
    implements $SpecialZonePayloadCopyWith<$Res> {
  _$SpecialZonePayloadCopyWithImpl(this._self, this._then);

  final SpecialZonePayload _self;
  final $Res Function(SpecialZonePayload) _then;

/// Create a copy of SpecialZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scriptKey = freezed,Object? properties = null,}) {
  return _then(_self.copyWith(
scriptKey: freezed == scriptKey ? _self.scriptKey : scriptKey // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpecialZonePayload].
extension SpecialZonePayloadPatterns on SpecialZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpecialZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpecialZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpecialZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _SpecialZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpecialZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _SpecialZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? scriptKey,  Map<String, String> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpecialZonePayload() when $default != null:
return $default(_that.scriptKey,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? scriptKey,  Map<String, String> properties)  $default,) {final _that = this;
switch (_that) {
case _SpecialZonePayload():
return $default(_that.scriptKey,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? scriptKey,  Map<String, String> properties)?  $default,) {final _that = this;
switch (_that) {
case _SpecialZonePayload() when $default != null:
return $default(_that.scriptKey,_that.properties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SpecialZonePayload implements SpecialZonePayload {
  const _SpecialZonePayload({this.scriptKey, final  Map<String, String> properties = const {}}): _properties = properties;
  factory _SpecialZonePayload.fromJson(Map<String, dynamic> json) => _$SpecialZonePayloadFromJson(json);

/// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
@override final  String? scriptKey;
/// Propriétés libres (clé → valeur).
 final  Map<String, String> _properties;
/// Propriétés libres (clé → valeur).
@override@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of SpecialZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpecialZonePayloadCopyWith<_SpecialZonePayload> get copyWith => __$SpecialZonePayloadCopyWithImpl<_SpecialZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpecialZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpecialZonePayload&&(identical(other.scriptKey, scriptKey) || other.scriptKey == scriptKey)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scriptKey,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'SpecialZonePayload(scriptKey: $scriptKey, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$SpecialZonePayloadCopyWith<$Res> implements $SpecialZonePayloadCopyWith<$Res> {
  factory _$SpecialZonePayloadCopyWith(_SpecialZonePayload value, $Res Function(_SpecialZonePayload) _then) = __$SpecialZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 String? scriptKey, Map<String, String> properties
});




}
/// @nodoc
class __$SpecialZonePayloadCopyWithImpl<$Res>
    implements _$SpecialZonePayloadCopyWith<$Res> {
  __$SpecialZonePayloadCopyWithImpl(this._self, this._then);

  final _SpecialZonePayload _self;
  final $Res Function(_SpecialZonePayload) _then;

/// Create a copy of SpecialZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scriptKey = freezed,Object? properties = null,}) {
  return _then(_SpecialZonePayload(
scriptKey: freezed == scriptKey ? _self.scriptKey : scriptKey // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$FieldActionZonePayload {

 FieldActionZoneKind get actionKind;@JsonKey(includeIfNull: false) DarknessZonePayload? get darkness;@JsonKey(includeIfNull: false) WaterfallZonePayload? get waterfall;@JsonKey(includeIfNull: false) DiveZonePayload? get dive;
/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldActionZonePayloadCopyWith<FieldActionZonePayload> get copyWith => _$FieldActionZonePayloadCopyWithImpl<FieldActionZonePayload>(this as FieldActionZonePayload, _$identity);

  /// Serializes this FieldActionZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldActionZonePayload&&(identical(other.actionKind, actionKind) || other.actionKind == actionKind)&&(identical(other.darkness, darkness) || other.darkness == darkness)&&(identical(other.waterfall, waterfall) || other.waterfall == waterfall)&&(identical(other.dive, dive) || other.dive == dive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionKind,darkness,waterfall,dive);

@override
String toString() {
  return 'FieldActionZonePayload(actionKind: $actionKind, darkness: $darkness, waterfall: $waterfall, dive: $dive)';
}


}

/// @nodoc
abstract mixin class $FieldActionZonePayloadCopyWith<$Res>  {
  factory $FieldActionZonePayloadCopyWith(FieldActionZonePayload value, $Res Function(FieldActionZonePayload) _then) = _$FieldActionZonePayloadCopyWithImpl;
@useResult
$Res call({
 FieldActionZoneKind actionKind,@JsonKey(includeIfNull: false) DarknessZonePayload? darkness,@JsonKey(includeIfNull: false) WaterfallZonePayload? waterfall,@JsonKey(includeIfNull: false) DiveZonePayload? dive
});


$DarknessZonePayloadCopyWith<$Res>? get darkness;$WaterfallZonePayloadCopyWith<$Res>? get waterfall;$DiveZonePayloadCopyWith<$Res>? get dive;

}
/// @nodoc
class _$FieldActionZonePayloadCopyWithImpl<$Res>
    implements $FieldActionZonePayloadCopyWith<$Res> {
  _$FieldActionZonePayloadCopyWithImpl(this._self, this._then);

  final FieldActionZonePayload _self;
  final $Res Function(FieldActionZonePayload) _then;

/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actionKind = null,Object? darkness = freezed,Object? waterfall = freezed,Object? dive = freezed,}) {
  return _then(_self.copyWith(
actionKind: null == actionKind ? _self.actionKind : actionKind // ignore: cast_nullable_to_non_nullable
as FieldActionZoneKind,darkness: freezed == darkness ? _self.darkness : darkness // ignore: cast_nullable_to_non_nullable
as DarknessZonePayload?,waterfall: freezed == waterfall ? _self.waterfall : waterfall // ignore: cast_nullable_to_non_nullable
as WaterfallZonePayload?,dive: freezed == dive ? _self.dive : dive // ignore: cast_nullable_to_non_nullable
as DiveZonePayload?,
  ));
}
/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DarknessZonePayloadCopyWith<$Res>? get darkness {
    if (_self.darkness == null) {
    return null;
  }

  return $DarknessZonePayloadCopyWith<$Res>(_self.darkness!, (value) {
    return _then(_self.copyWith(darkness: value));
  });
}/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaterfallZonePayloadCopyWith<$Res>? get waterfall {
    if (_self.waterfall == null) {
    return null;
  }

  return $WaterfallZonePayloadCopyWith<$Res>(_self.waterfall!, (value) {
    return _then(_self.copyWith(waterfall: value));
  });
}/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiveZonePayloadCopyWith<$Res>? get dive {
    if (_self.dive == null) {
    return null;
  }

  return $DiveZonePayloadCopyWith<$Res>(_self.dive!, (value) {
    return _then(_self.copyWith(dive: value));
  });
}
}


/// Adds pattern-matching-related methods to [FieldActionZonePayload].
extension FieldActionZonePayloadPatterns on FieldActionZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldActionZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldActionZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldActionZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _FieldActionZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldActionZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _FieldActionZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FieldActionZoneKind actionKind, @JsonKey(includeIfNull: false)  DarknessZonePayload? darkness, @JsonKey(includeIfNull: false)  WaterfallZonePayload? waterfall, @JsonKey(includeIfNull: false)  DiveZonePayload? dive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldActionZonePayload() when $default != null:
return $default(_that.actionKind,_that.darkness,_that.waterfall,_that.dive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FieldActionZoneKind actionKind, @JsonKey(includeIfNull: false)  DarknessZonePayload? darkness, @JsonKey(includeIfNull: false)  WaterfallZonePayload? waterfall, @JsonKey(includeIfNull: false)  DiveZonePayload? dive)  $default,) {final _that = this;
switch (_that) {
case _FieldActionZonePayload():
return $default(_that.actionKind,_that.darkness,_that.waterfall,_that.dive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FieldActionZoneKind actionKind, @JsonKey(includeIfNull: false)  DarknessZonePayload? darkness, @JsonKey(includeIfNull: false)  WaterfallZonePayload? waterfall, @JsonKey(includeIfNull: false)  DiveZonePayload? dive)?  $default,) {final _that = this;
switch (_that) {
case _FieldActionZonePayload() when $default != null:
return $default(_that.actionKind,_that.darkness,_that.waterfall,_that.dive);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class _FieldActionZonePayload implements FieldActionZonePayload {
  const _FieldActionZonePayload({required this.actionKind, @JsonKey(includeIfNull: false) this.darkness, @JsonKey(includeIfNull: false) this.waterfall, @JsonKey(includeIfNull: false) this.dive});
  factory _FieldActionZonePayload.fromJson(Map<String, dynamic> json) => _$FieldActionZonePayloadFromJson(json);

@override final  FieldActionZoneKind actionKind;
@override@JsonKey(includeIfNull: false) final  DarknessZonePayload? darkness;
@override@JsonKey(includeIfNull: false) final  WaterfallZonePayload? waterfall;
@override@JsonKey(includeIfNull: false) final  DiveZonePayload? dive;

/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldActionZonePayloadCopyWith<_FieldActionZonePayload> get copyWith => __$FieldActionZonePayloadCopyWithImpl<_FieldActionZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldActionZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldActionZonePayload&&(identical(other.actionKind, actionKind) || other.actionKind == actionKind)&&(identical(other.darkness, darkness) || other.darkness == darkness)&&(identical(other.waterfall, waterfall) || other.waterfall == waterfall)&&(identical(other.dive, dive) || other.dive == dive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionKind,darkness,waterfall,dive);

@override
String toString() {
  return 'FieldActionZonePayload(actionKind: $actionKind, darkness: $darkness, waterfall: $waterfall, dive: $dive)';
}


}

/// @nodoc
abstract mixin class _$FieldActionZonePayloadCopyWith<$Res> implements $FieldActionZonePayloadCopyWith<$Res> {
  factory _$FieldActionZonePayloadCopyWith(_FieldActionZonePayload value, $Res Function(_FieldActionZonePayload) _then) = __$FieldActionZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 FieldActionZoneKind actionKind,@JsonKey(includeIfNull: false) DarknessZonePayload? darkness,@JsonKey(includeIfNull: false) WaterfallZonePayload? waterfall,@JsonKey(includeIfNull: false) DiveZonePayload? dive
});


@override $DarknessZonePayloadCopyWith<$Res>? get darkness;@override $WaterfallZonePayloadCopyWith<$Res>? get waterfall;@override $DiveZonePayloadCopyWith<$Res>? get dive;

}
/// @nodoc
class __$FieldActionZonePayloadCopyWithImpl<$Res>
    implements _$FieldActionZonePayloadCopyWith<$Res> {
  __$FieldActionZonePayloadCopyWithImpl(this._self, this._then);

  final _FieldActionZonePayload _self;
  final $Res Function(_FieldActionZonePayload) _then;

/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actionKind = null,Object? darkness = freezed,Object? waterfall = freezed,Object? dive = freezed,}) {
  return _then(_FieldActionZonePayload(
actionKind: null == actionKind ? _self.actionKind : actionKind // ignore: cast_nullable_to_non_nullable
as FieldActionZoneKind,darkness: freezed == darkness ? _self.darkness : darkness // ignore: cast_nullable_to_non_nullable
as DarknessZonePayload?,waterfall: freezed == waterfall ? _self.waterfall : waterfall // ignore: cast_nullable_to_non_nullable
as WaterfallZonePayload?,dive: freezed == dive ? _self.dive : dive // ignore: cast_nullable_to_non_nullable
as DiveZonePayload?,
  ));
}

/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DarknessZonePayloadCopyWith<$Res>? get darkness {
    if (_self.darkness == null) {
    return null;
  }

  return $DarknessZonePayloadCopyWith<$Res>(_self.darkness!, (value) {
    return _then(_self.copyWith(darkness: value));
  });
}/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaterfallZonePayloadCopyWith<$Res>? get waterfall {
    if (_self.waterfall == null) {
    return null;
  }

  return $WaterfallZonePayloadCopyWith<$Res>(_self.waterfall!, (value) {
    return _then(_self.copyWith(waterfall: value));
  });
}/// Create a copy of FieldActionZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiveZonePayloadCopyWith<$Res>? get dive {
    if (_self.dive == null) {
    return null;
  }

  return $DiveZonePayloadCopyWith<$Res>(_self.dive!, (value) {
    return _then(_self.copyWith(dive: value));
  });
}
}


/// @nodoc
mixin _$DarknessZonePayload {

 double get opacity;
/// Create a copy of DarknessZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DarknessZonePayloadCopyWith<DarknessZonePayload> get copyWith => _$DarknessZonePayloadCopyWithImpl<DarknessZonePayload>(this as DarknessZonePayload, _$identity);

  /// Serializes this DarknessZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DarknessZonePayload&&(identical(other.opacity, opacity) || other.opacity == opacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,opacity);

@override
String toString() {
  return 'DarknessZonePayload(opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class $DarknessZonePayloadCopyWith<$Res>  {
  factory $DarknessZonePayloadCopyWith(DarknessZonePayload value, $Res Function(DarknessZonePayload) _then) = _$DarknessZonePayloadCopyWithImpl;
@useResult
$Res call({
 double opacity
});




}
/// @nodoc
class _$DarknessZonePayloadCopyWithImpl<$Res>
    implements $DarknessZonePayloadCopyWith<$Res> {
  _$DarknessZonePayloadCopyWithImpl(this._self, this._then);

  final DarknessZonePayload _self;
  final $Res Function(DarknessZonePayload) _then;

/// Create a copy of DarknessZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? opacity = null,}) {
  return _then(_self.copyWith(
opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DarknessZonePayload].
extension DarknessZonePayloadPatterns on DarknessZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DarknessZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DarknessZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DarknessZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _DarknessZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DarknessZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _DarknessZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double opacity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DarknessZonePayload() when $default != null:
return $default(_that.opacity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double opacity)  $default,) {final _that = this;
switch (_that) {
case _DarknessZonePayload():
return $default(_that.opacity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double opacity)?  $default,) {final _that = this;
switch (_that) {
case _DarknessZonePayload() when $default != null:
return $default(_that.opacity);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(disallowUnrecognizedKeys: true)
class _DarknessZonePayload implements DarknessZonePayload {
  const _DarknessZonePayload({required this.opacity});
  factory _DarknessZonePayload.fromJson(Map<String, dynamic> json) => _$DarknessZonePayloadFromJson(json);

@override final  double opacity;

/// Create a copy of DarknessZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DarknessZonePayloadCopyWith<_DarknessZonePayload> get copyWith => __$DarknessZonePayloadCopyWithImpl<_DarknessZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DarknessZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DarknessZonePayload&&(identical(other.opacity, opacity) || other.opacity == opacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,opacity);

@override
String toString() {
  return 'DarknessZonePayload(opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class _$DarknessZonePayloadCopyWith<$Res> implements $DarknessZonePayloadCopyWith<$Res> {
  factory _$DarknessZonePayloadCopyWith(_DarknessZonePayload value, $Res Function(_DarknessZonePayload) _then) = __$DarknessZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 double opacity
});




}
/// @nodoc
class __$DarknessZonePayloadCopyWithImpl<$Res>
    implements _$DarknessZonePayloadCopyWith<$Res> {
  __$DarknessZonePayloadCopyWithImpl(this._self, this._then);

  final _DarknessZonePayload _self;
  final $Res Function(_DarknessZonePayload) _then;

/// Create a copy of DarknessZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? opacity = null,}) {
  return _then(_DarknessZonePayload(
opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$WaterfallZonePayload {

 GridPos get entry; List<GridPos> get path; GridPos get exit; MapConnectionDirection get direction; bool get requiresSurf;
/// Create a copy of WaterfallZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaterfallZonePayloadCopyWith<WaterfallZonePayload> get copyWith => _$WaterfallZonePayloadCopyWithImpl<WaterfallZonePayload>(this as WaterfallZonePayload, _$identity);

  /// Serializes this WaterfallZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaterfallZonePayload&&(identical(other.entry, entry) || other.entry == entry)&&const DeepCollectionEquality().equals(other.path, path)&&(identical(other.exit, exit) || other.exit == exit)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.requiresSurf, requiresSurf) || other.requiresSurf == requiresSurf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entry,const DeepCollectionEquality().hash(path),exit,direction,requiresSurf);

@override
String toString() {
  return 'WaterfallZonePayload(entry: $entry, path: $path, exit: $exit, direction: $direction, requiresSurf: $requiresSurf)';
}


}

/// @nodoc
abstract mixin class $WaterfallZonePayloadCopyWith<$Res>  {
  factory $WaterfallZonePayloadCopyWith(WaterfallZonePayload value, $Res Function(WaterfallZonePayload) _then) = _$WaterfallZonePayloadCopyWithImpl;
@useResult
$Res call({
 GridPos entry, List<GridPos> path, GridPos exit, MapConnectionDirection direction, bool requiresSurf
});


$GridPosCopyWith<$Res> get entry;$GridPosCopyWith<$Res> get exit;

}
/// @nodoc
class _$WaterfallZonePayloadCopyWithImpl<$Res>
    implements $WaterfallZonePayloadCopyWith<$Res> {
  _$WaterfallZonePayloadCopyWithImpl(this._self, this._then);

  final WaterfallZonePayload _self;
  final $Res Function(WaterfallZonePayload) _then;

/// Create a copy of WaterfallZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entry = null,Object? path = null,Object? exit = null,Object? direction = null,Object? requiresSurf = null,}) {
  return _then(_self.copyWith(
entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as GridPos,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<GridPos>,exit: null == exit ? _self.exit : exit // ignore: cast_nullable_to_non_nullable
as GridPos,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as MapConnectionDirection,requiresSurf: null == requiresSurf ? _self.requiresSurf : requiresSurf // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of WaterfallZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get entry {
  
  return $GridPosCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}/// Create a copy of WaterfallZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get exit {
  
  return $GridPosCopyWith<$Res>(_self.exit, (value) {
    return _then(_self.copyWith(exit: value));
  });
}
}


/// Adds pattern-matching-related methods to [WaterfallZonePayload].
extension WaterfallZonePayloadPatterns on WaterfallZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaterfallZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaterfallZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaterfallZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _WaterfallZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaterfallZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _WaterfallZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GridPos entry,  List<GridPos> path,  GridPos exit,  MapConnectionDirection direction,  bool requiresSurf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaterfallZonePayload() when $default != null:
return $default(_that.entry,_that.path,_that.exit,_that.direction,_that.requiresSurf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GridPos entry,  List<GridPos> path,  GridPos exit,  MapConnectionDirection direction,  bool requiresSurf)  $default,) {final _that = this;
switch (_that) {
case _WaterfallZonePayload():
return $default(_that.entry,_that.path,_that.exit,_that.direction,_that.requiresSurf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GridPos entry,  List<GridPos> path,  GridPos exit,  MapConnectionDirection direction,  bool requiresSurf)?  $default,) {final _that = this;
switch (_that) {
case _WaterfallZonePayload() when $default != null:
return $default(_that.entry,_that.path,_that.exit,_that.direction,_that.requiresSurf);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class _WaterfallZonePayload implements WaterfallZonePayload {
  const _WaterfallZonePayload({required this.entry, required final  List<GridPos> path, required this.exit, required this.direction, this.requiresSurf = true}): _path = path;
  factory _WaterfallZonePayload.fromJson(Map<String, dynamic> json) => _$WaterfallZonePayloadFromJson(json);

@override final  GridPos entry;
 final  List<GridPos> _path;
@override List<GridPos> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}

@override final  GridPos exit;
@override final  MapConnectionDirection direction;
@override@JsonKey() final  bool requiresSurf;

/// Create a copy of WaterfallZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaterfallZonePayloadCopyWith<_WaterfallZonePayload> get copyWith => __$WaterfallZonePayloadCopyWithImpl<_WaterfallZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaterfallZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaterfallZonePayload&&(identical(other.entry, entry) || other.entry == entry)&&const DeepCollectionEquality().equals(other._path, _path)&&(identical(other.exit, exit) || other.exit == exit)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.requiresSurf, requiresSurf) || other.requiresSurf == requiresSurf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entry,const DeepCollectionEquality().hash(_path),exit,direction,requiresSurf);

@override
String toString() {
  return 'WaterfallZonePayload(entry: $entry, path: $path, exit: $exit, direction: $direction, requiresSurf: $requiresSurf)';
}


}

/// @nodoc
abstract mixin class _$WaterfallZonePayloadCopyWith<$Res> implements $WaterfallZonePayloadCopyWith<$Res> {
  factory _$WaterfallZonePayloadCopyWith(_WaterfallZonePayload value, $Res Function(_WaterfallZonePayload) _then) = __$WaterfallZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 GridPos entry, List<GridPos> path, GridPos exit, MapConnectionDirection direction, bool requiresSurf
});


@override $GridPosCopyWith<$Res> get entry;@override $GridPosCopyWith<$Res> get exit;

}
/// @nodoc
class __$WaterfallZonePayloadCopyWithImpl<$Res>
    implements _$WaterfallZonePayloadCopyWith<$Res> {
  __$WaterfallZonePayloadCopyWithImpl(this._self, this._then);

  final _WaterfallZonePayload _self;
  final $Res Function(_WaterfallZonePayload) _then;

/// Create a copy of WaterfallZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entry = null,Object? path = null,Object? exit = null,Object? direction = null,Object? requiresSurf = null,}) {
  return _then(_WaterfallZonePayload(
entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as GridPos,path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<GridPos>,exit: null == exit ? _self.exit : exit // ignore: cast_nullable_to_non_nullable
as GridPos,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as MapConnectionDirection,requiresSurf: null == requiresSurf ? _self.requiresSurf : requiresSurf // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of WaterfallZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get entry {
  
  return $GridPosCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}/// Create a copy of WaterfallZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get exit {
  
  return $GridPosCopyWith<$Res>(_self.exit, (value) {
    return _then(_self.copyWith(exit: value));
  });
}
}


/// @nodoc
mixin _$DiveZonePayload {

 DiveZoneRole get role;@JsonKey(includeIfNull: false) String? get arrivalSpawnId;@JsonKey(includeIfNull: false) DiveZoneLink? get link;
/// Create a copy of DiveZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiveZonePayloadCopyWith<DiveZonePayload> get copyWith => _$DiveZonePayloadCopyWithImpl<DiveZonePayload>(this as DiveZonePayload, _$identity);

  /// Serializes this DiveZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiveZonePayload&&(identical(other.role, role) || other.role == role)&&(identical(other.arrivalSpawnId, arrivalSpawnId) || other.arrivalSpawnId == arrivalSpawnId)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,arrivalSpawnId,link);

@override
String toString() {
  return 'DiveZonePayload(role: $role, arrivalSpawnId: $arrivalSpawnId, link: $link)';
}


}

/// @nodoc
abstract mixin class $DiveZonePayloadCopyWith<$Res>  {
  factory $DiveZonePayloadCopyWith(DiveZonePayload value, $Res Function(DiveZonePayload) _then) = _$DiveZonePayloadCopyWithImpl;
@useResult
$Res call({
 DiveZoneRole role,@JsonKey(includeIfNull: false) String? arrivalSpawnId,@JsonKey(includeIfNull: false) DiveZoneLink? link
});


$DiveZoneLinkCopyWith<$Res>? get link;

}
/// @nodoc
class _$DiveZonePayloadCopyWithImpl<$Res>
    implements $DiveZonePayloadCopyWith<$Res> {
  _$DiveZonePayloadCopyWithImpl(this._self, this._then);

  final DiveZonePayload _self;
  final $Res Function(DiveZonePayload) _then;

/// Create a copy of DiveZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? arrivalSpawnId = freezed,Object? link = freezed,}) {
  return _then(_self.copyWith(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as DiveZoneRole,arrivalSpawnId: freezed == arrivalSpawnId ? _self.arrivalSpawnId : arrivalSpawnId // ignore: cast_nullable_to_non_nullable
as String?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as DiveZoneLink?,
  ));
}
/// Create a copy of DiveZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiveZoneLinkCopyWith<$Res>? get link {
    if (_self.link == null) {
    return null;
  }

  return $DiveZoneLinkCopyWith<$Res>(_self.link!, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}


/// Adds pattern-matching-related methods to [DiveZonePayload].
extension DiveZonePayloadPatterns on DiveZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiveZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiveZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiveZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _DiveZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiveZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _DiveZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DiveZoneRole role, @JsonKey(includeIfNull: false)  String? arrivalSpawnId, @JsonKey(includeIfNull: false)  DiveZoneLink? link)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiveZonePayload() when $default != null:
return $default(_that.role,_that.arrivalSpawnId,_that.link);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DiveZoneRole role, @JsonKey(includeIfNull: false)  String? arrivalSpawnId, @JsonKey(includeIfNull: false)  DiveZoneLink? link)  $default,) {final _that = this;
switch (_that) {
case _DiveZonePayload():
return $default(_that.role,_that.arrivalSpawnId,_that.link);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DiveZoneRole role, @JsonKey(includeIfNull: false)  String? arrivalSpawnId, @JsonKey(includeIfNull: false)  DiveZoneLink? link)?  $default,) {final _that = this;
switch (_that) {
case _DiveZonePayload() when $default != null:
return $default(_that.role,_that.arrivalSpawnId,_that.link);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class _DiveZonePayload implements DiveZonePayload {
  const _DiveZonePayload({required this.role, @JsonKey(includeIfNull: false) this.arrivalSpawnId, @JsonKey(includeIfNull: false) this.link});
  factory _DiveZonePayload.fromJson(Map<String, dynamic> json) => _$DiveZonePayloadFromJson(json);

@override final  DiveZoneRole role;
@override@JsonKey(includeIfNull: false) final  String? arrivalSpawnId;
@override@JsonKey(includeIfNull: false) final  DiveZoneLink? link;

/// Create a copy of DiveZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiveZonePayloadCopyWith<_DiveZonePayload> get copyWith => __$DiveZonePayloadCopyWithImpl<_DiveZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiveZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiveZonePayload&&(identical(other.role, role) || other.role == role)&&(identical(other.arrivalSpawnId, arrivalSpawnId) || other.arrivalSpawnId == arrivalSpawnId)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,arrivalSpawnId,link);

@override
String toString() {
  return 'DiveZonePayload(role: $role, arrivalSpawnId: $arrivalSpawnId, link: $link)';
}


}

/// @nodoc
abstract mixin class _$DiveZonePayloadCopyWith<$Res> implements $DiveZonePayloadCopyWith<$Res> {
  factory _$DiveZonePayloadCopyWith(_DiveZonePayload value, $Res Function(_DiveZonePayload) _then) = __$DiveZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 DiveZoneRole role,@JsonKey(includeIfNull: false) String? arrivalSpawnId,@JsonKey(includeIfNull: false) DiveZoneLink? link
});


@override $DiveZoneLinkCopyWith<$Res>? get link;

}
/// @nodoc
class __$DiveZonePayloadCopyWithImpl<$Res>
    implements _$DiveZonePayloadCopyWith<$Res> {
  __$DiveZonePayloadCopyWithImpl(this._self, this._then);

  final _DiveZonePayload _self;
  final $Res Function(_DiveZonePayload) _then;

/// Create a copy of DiveZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? arrivalSpawnId = freezed,Object? link = freezed,}) {
  return _then(_DiveZonePayload(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as DiveZoneRole,arrivalSpawnId: freezed == arrivalSpawnId ? _self.arrivalSpawnId : arrivalSpawnId // ignore: cast_nullable_to_non_nullable
as String?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as DiveZoneLink?,
  ));
}

/// Create a copy of DiveZonePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiveZoneLinkCopyWith<$Res>? get link {
    if (_self.link == null) {
    return null;
  }

  return $DiveZoneLinkCopyWith<$Res>(_self.link!, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}


/// @nodoc
mixin _$DiveZoneLink {

 String get mapId; String get zoneId;
/// Create a copy of DiveZoneLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiveZoneLinkCopyWith<DiveZoneLink> get copyWith => _$DiveZoneLinkCopyWithImpl<DiveZoneLink>(this as DiveZoneLink, _$identity);

  /// Serializes this DiveZoneLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiveZoneLink&&(identical(other.mapId, mapId) || other.mapId == mapId)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mapId,zoneId);

@override
String toString() {
  return 'DiveZoneLink(mapId: $mapId, zoneId: $zoneId)';
}


}

/// @nodoc
abstract mixin class $DiveZoneLinkCopyWith<$Res>  {
  factory $DiveZoneLinkCopyWith(DiveZoneLink value, $Res Function(DiveZoneLink) _then) = _$DiveZoneLinkCopyWithImpl;
@useResult
$Res call({
 String mapId, String zoneId
});




}
/// @nodoc
class _$DiveZoneLinkCopyWithImpl<$Res>
    implements $DiveZoneLinkCopyWith<$Res> {
  _$DiveZoneLinkCopyWithImpl(this._self, this._then);

  final DiveZoneLink _self;
  final $Res Function(DiveZoneLink) _then;

/// Create a copy of DiveZoneLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mapId = null,Object? zoneId = null,}) {
  return _then(_self.copyWith(
mapId: null == mapId ? _self.mapId : mapId // ignore: cast_nullable_to_non_nullable
as String,zoneId: null == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DiveZoneLink].
extension DiveZoneLinkPatterns on DiveZoneLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiveZoneLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiveZoneLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiveZoneLink value)  $default,){
final _that = this;
switch (_that) {
case _DiveZoneLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiveZoneLink value)?  $default,){
final _that = this;
switch (_that) {
case _DiveZoneLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mapId,  String zoneId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiveZoneLink() when $default != null:
return $default(_that.mapId,_that.zoneId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mapId,  String zoneId)  $default,) {final _that = this;
switch (_that) {
case _DiveZoneLink():
return $default(_that.mapId,_that.zoneId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mapId,  String zoneId)?  $default,) {final _that = this;
switch (_that) {
case _DiveZoneLink() when $default != null:
return $default(_that.mapId,_that.zoneId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(disallowUnrecognizedKeys: true)
class _DiveZoneLink implements DiveZoneLink {
  const _DiveZoneLink({required this.mapId, required this.zoneId});
  factory _DiveZoneLink.fromJson(Map<String, dynamic> json) => _$DiveZoneLinkFromJson(json);

@override final  String mapId;
@override final  String zoneId;

/// Create a copy of DiveZoneLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiveZoneLinkCopyWith<_DiveZoneLink> get copyWith => __$DiveZoneLinkCopyWithImpl<_DiveZoneLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiveZoneLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiveZoneLink&&(identical(other.mapId, mapId) || other.mapId == mapId)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mapId,zoneId);

@override
String toString() {
  return 'DiveZoneLink(mapId: $mapId, zoneId: $zoneId)';
}


}

/// @nodoc
abstract mixin class _$DiveZoneLinkCopyWith<$Res> implements $DiveZoneLinkCopyWith<$Res> {
  factory _$DiveZoneLinkCopyWith(_DiveZoneLink value, $Res Function(_DiveZoneLink) _then) = __$DiveZoneLinkCopyWithImpl;
@override @useResult
$Res call({
 String mapId, String zoneId
});




}
/// @nodoc
class __$DiveZoneLinkCopyWithImpl<$Res>
    implements _$DiveZoneLinkCopyWith<$Res> {
  __$DiveZoneLinkCopyWithImpl(this._self, this._then);

  final _DiveZoneLink _self;
  final $Res Function(_DiveZoneLink) _then;

/// Create a copy of DiveZoneLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mapId = null,Object? zoneId = null,}) {
  return _then(_DiveZoneLink(
mapId: null == mapId ? _self.mapId : mapId // ignore: cast_nullable_to_non_nullable
as String,zoneId: null == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
