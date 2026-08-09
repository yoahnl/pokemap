// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pokemon_move.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PokemonMoveSourceRefs {

 String? get showdownMoveId; List<String> get showdownHooksPresent;
/// Create a copy of PokemonMoveSourceRefs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveSourceRefsCopyWith<PokemonMoveSourceRefs> get copyWith => _$PokemonMoveSourceRefsCopyWithImpl<PokemonMoveSourceRefs>(this as PokemonMoveSourceRefs, _$identity);

  /// Serializes this PokemonMoveSourceRefs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveSourceRefs&&(identical(other.showdownMoveId, showdownMoveId) || other.showdownMoveId == showdownMoveId)&&const DeepCollectionEquality().equals(other.showdownHooksPresent, showdownHooksPresent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showdownMoveId,const DeepCollectionEquality().hash(showdownHooksPresent));

@override
String toString() {
  return 'PokemonMoveSourceRefs(showdownMoveId: $showdownMoveId, showdownHooksPresent: $showdownHooksPresent)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveSourceRefsCopyWith<$Res>  {
  factory $PokemonMoveSourceRefsCopyWith(PokemonMoveSourceRefs value, $Res Function(PokemonMoveSourceRefs) _then) = _$PokemonMoveSourceRefsCopyWithImpl;
@useResult
$Res call({
 String? showdownMoveId, List<String> showdownHooksPresent
});




}
/// @nodoc
class _$PokemonMoveSourceRefsCopyWithImpl<$Res>
    implements $PokemonMoveSourceRefsCopyWith<$Res> {
  _$PokemonMoveSourceRefsCopyWithImpl(this._self, this._then);

  final PokemonMoveSourceRefs _self;
  final $Res Function(PokemonMoveSourceRefs) _then;

/// Create a copy of PokemonMoveSourceRefs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showdownMoveId = freezed,Object? showdownHooksPresent = null,}) {
  return _then(_self.copyWith(
showdownMoveId: freezed == showdownMoveId ? _self.showdownMoveId : showdownMoveId // ignore: cast_nullable_to_non_nullable
as String?,showdownHooksPresent: null == showdownHooksPresent ? _self.showdownHooksPresent : showdownHooksPresent // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PokemonMoveSourceRefs].
extension PokemonMoveSourceRefsPatterns on PokemonMoveSourceRefs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PokemonMoveSourceRefs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PokemonMoveSourceRefs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PokemonMoveSourceRefs value)  $default,){
final _that = this;
switch (_that) {
case _PokemonMoveSourceRefs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PokemonMoveSourceRefs value)?  $default,){
final _that = this;
switch (_that) {
case _PokemonMoveSourceRefs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? showdownMoveId,  List<String> showdownHooksPresent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PokemonMoveSourceRefs() when $default != null:
return $default(_that.showdownMoveId,_that.showdownHooksPresent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? showdownMoveId,  List<String> showdownHooksPresent)  $default,) {final _that = this;
switch (_that) {
case _PokemonMoveSourceRefs():
return $default(_that.showdownMoveId,_that.showdownHooksPresent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? showdownMoveId,  List<String> showdownHooksPresent)?  $default,) {final _that = this;
switch (_that) {
case _PokemonMoveSourceRefs() when $default != null:
return $default(_that.showdownMoveId,_that.showdownHooksPresent);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PokemonMoveSourceRefs extends PokemonMoveSourceRefs {
  const _PokemonMoveSourceRefs({this.showdownMoveId, final  List<String> showdownHooksPresent = const <String>[]}): _showdownHooksPresent = showdownHooksPresent,super._();
  factory _PokemonMoveSourceRefs.fromJson(Map<String, dynamic> json) => _$PokemonMoveSourceRefsFromJson(json);

@override final  String? showdownMoveId;
 final  List<String> _showdownHooksPresent;
@override@JsonKey() List<String> get showdownHooksPresent {
  if (_showdownHooksPresent is EqualUnmodifiableListView) return _showdownHooksPresent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_showdownHooksPresent);
}


/// Create a copy of PokemonMoveSourceRefs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PokemonMoveSourceRefsCopyWith<_PokemonMoveSourceRefs> get copyWith => __$PokemonMoveSourceRefsCopyWithImpl<_PokemonMoveSourceRefs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveSourceRefsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PokemonMoveSourceRefs&&(identical(other.showdownMoveId, showdownMoveId) || other.showdownMoveId == showdownMoveId)&&const DeepCollectionEquality().equals(other._showdownHooksPresent, _showdownHooksPresent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showdownMoveId,const DeepCollectionEquality().hash(_showdownHooksPresent));

@override
String toString() {
  return 'PokemonMoveSourceRefs(showdownMoveId: $showdownMoveId, showdownHooksPresent: $showdownHooksPresent)';
}


}

/// @nodoc
abstract mixin class _$PokemonMoveSourceRefsCopyWith<$Res> implements $PokemonMoveSourceRefsCopyWith<$Res> {
  factory _$PokemonMoveSourceRefsCopyWith(_PokemonMoveSourceRefs value, $Res Function(_PokemonMoveSourceRefs) _then) = __$PokemonMoveSourceRefsCopyWithImpl;
@override @useResult
$Res call({
 String? showdownMoveId, List<String> showdownHooksPresent
});




}
/// @nodoc
class __$PokemonMoveSourceRefsCopyWithImpl<$Res>
    implements _$PokemonMoveSourceRefsCopyWith<$Res> {
  __$PokemonMoveSourceRefsCopyWithImpl(this._self, this._then);

  final _PokemonMoveSourceRefs _self;
  final $Res Function(_PokemonMoveSourceRefs) _then;

/// Create a copy of PokemonMoveSourceRefs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showdownMoveId = freezed,Object? showdownHooksPresent = null,}) {
  return _then(_PokemonMoveSourceRefs(
showdownMoveId: freezed == showdownMoveId ? _self.showdownMoveId : showdownMoveId // ignore: cast_nullable_to_non_nullable
as String?,showdownHooksPresent: null == showdownHooksPresent ? _self._showdownHooksPresent : showdownHooksPresent // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$PokemonMove {

 String get id; String get name; Map<String, String> get names; int? get generation;/// `showdown`, `seed`, `project_custom`, etc.
 String get source; String get type; PokemonMoveCategory get category; PokemonMoveTarget get target; int get basePower; PokemonMoveAccuracy get accuracy; int get pp; bool get noPpBoosts; int get priority; int get critRatio;/// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
 List<PokemonMoveFlag> get flags;/// Tous les comportements applicatifs vivent ici.
 List<PokemonMoveEffect> get effects; String get shortDescription; String get description; PokemonMoveEngineSupportLevel get engineSupportLevel; List<String> get unsupportedReasons; PokemonMoveSourceRefs get sourceRefs;
/// Create a copy of PokemonMove
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveCopyWith<PokemonMove> get copyWith => _$PokemonMoveCopyWithImpl<PokemonMove>(this as PokemonMove, _$identity);

  /// Serializes this PokemonMove to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMove&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.names, names)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.source, source) || other.source == source)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.target, target) || other.target == target)&&(identical(other.basePower, basePower) || other.basePower == basePower)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.pp, pp) || other.pp == pp)&&(identical(other.noPpBoosts, noPpBoosts) || other.noPpBoosts == noPpBoosts)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.critRatio, critRatio) || other.critRatio == critRatio)&&const DeepCollectionEquality().equals(other.flags, flags)&&const DeepCollectionEquality().equals(other.effects, effects)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.description, description) || other.description == description)&&(identical(other.engineSupportLevel, engineSupportLevel) || other.engineSupportLevel == engineSupportLevel)&&const DeepCollectionEquality().equals(other.unsupportedReasons, unsupportedReasons)&&(identical(other.sourceRefs, sourceRefs) || other.sourceRefs == sourceRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,const DeepCollectionEquality().hash(names),generation,source,type,category,target,basePower,accuracy,pp,noPpBoosts,priority,critRatio,const DeepCollectionEquality().hash(flags),const DeepCollectionEquality().hash(effects),shortDescription,description,engineSupportLevel,const DeepCollectionEquality().hash(unsupportedReasons),sourceRefs]);

@override
String toString() {
  return 'PokemonMove(id: $id, name: $name, names: $names, generation: $generation, source: $source, type: $type, category: $category, target: $target, basePower: $basePower, accuracy: $accuracy, pp: $pp, noPpBoosts: $noPpBoosts, priority: $priority, critRatio: $critRatio, flags: $flags, effects: $effects, shortDescription: $shortDescription, description: $description, engineSupportLevel: $engineSupportLevel, unsupportedReasons: $unsupportedReasons, sourceRefs: $sourceRefs)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveCopyWith<$Res>  {
  factory $PokemonMoveCopyWith(PokemonMove value, $Res Function(PokemonMove) _then) = _$PokemonMoveCopyWithImpl;
@useResult
$Res call({
 String id, String name, Map<String, String> names, int? generation, String source, String type, PokemonMoveCategory category, PokemonMoveTarget target, int basePower, PokemonMoveAccuracy accuracy, int pp, bool noPpBoosts, int priority, int critRatio, List<PokemonMoveFlag> flags, List<PokemonMoveEffect> effects, String shortDescription, String description, PokemonMoveEngineSupportLevel engineSupportLevel, List<String> unsupportedReasons, PokemonMoveSourceRefs sourceRefs
});


$PokemonMoveAccuracyCopyWith<$Res> get accuracy;$PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs;

}
/// @nodoc
class _$PokemonMoveCopyWithImpl<$Res>
    implements $PokemonMoveCopyWith<$Res> {
  _$PokemonMoveCopyWithImpl(this._self, this._then);

  final PokemonMove _self;
  final $Res Function(PokemonMove) _then;

/// Create a copy of PokemonMove
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? names = null,Object? generation = freezed,Object? source = null,Object? type = null,Object? category = null,Object? target = null,Object? basePower = null,Object? accuracy = null,Object? pp = null,Object? noPpBoosts = null,Object? priority = null,Object? critRatio = null,Object? flags = null,Object? effects = null,Object? shortDescription = null,Object? description = null,Object? engineSupportLevel = null,Object? unsupportedReasons = null,Object? sourceRefs = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,names: null == names ? _self.names : names // ignore: cast_nullable_to_non_nullable
as Map<String, String>,generation: freezed == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as PokemonMoveCategory,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PokemonMoveTarget,basePower: null == basePower ? _self.basePower : basePower // ignore: cast_nullable_to_non_nullable
as int,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as PokemonMoveAccuracy,pp: null == pp ? _self.pp : pp // ignore: cast_nullable_to_non_nullable
as int,noPpBoosts: null == noPpBoosts ? _self.noPpBoosts : noPpBoosts // ignore: cast_nullable_to_non_nullable
as bool,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,critRatio: null == critRatio ? _self.critRatio : critRatio // ignore: cast_nullable_to_non_nullable
as int,flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as List<PokemonMoveFlag>,effects: null == effects ? _self.effects : effects // ignore: cast_nullable_to_non_nullable
as List<PokemonMoveEffect>,shortDescription: null == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,engineSupportLevel: null == engineSupportLevel ? _self.engineSupportLevel : engineSupportLevel // ignore: cast_nullable_to_non_nullable
as PokemonMoveEngineSupportLevel,unsupportedReasons: null == unsupportedReasons ? _self.unsupportedReasons : unsupportedReasons // ignore: cast_nullable_to_non_nullable
as List<String>,sourceRefs: null == sourceRefs ? _self.sourceRefs : sourceRefs // ignore: cast_nullable_to_non_nullable
as PokemonMoveSourceRefs,
  ));
}
/// Create a copy of PokemonMove
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonMoveAccuracyCopyWith<$Res> get accuracy {

  return $PokemonMoveAccuracyCopyWith<$Res>(_self.accuracy, (value) {
    return _then(_self.copyWith(accuracy: value));
  });
}/// Create a copy of PokemonMove
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs {

  return $PokemonMoveSourceRefsCopyWith<$Res>(_self.sourceRefs, (value) {
    return _then(_self.copyWith(sourceRefs: value));
  });
}
}


/// Adds pattern-matching-related methods to [PokemonMove].
extension PokemonMovePatterns on PokemonMove {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PokemonMove value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PokemonMove() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PokemonMove value)  $default,){
final _that = this;
switch (_that) {
case _PokemonMove():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PokemonMove value)?  $default,){
final _that = this;
switch (_that) {
case _PokemonMove() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, String> names,  int? generation,  String source,  String type,  PokemonMoveCategory category,  PokemonMoveTarget target,  int basePower,  PokemonMoveAccuracy accuracy,  int pp,  bool noPpBoosts,  int priority,  int critRatio,  List<PokemonMoveFlag> flags,  List<PokemonMoveEffect> effects,  String shortDescription,  String description,  PokemonMoveEngineSupportLevel engineSupportLevel,  List<String> unsupportedReasons,  PokemonMoveSourceRefs sourceRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PokemonMove() when $default != null:
return $default(_that.id,_that.name,_that.names,_that.generation,_that.source,_that.type,_that.category,_that.target,_that.basePower,_that.accuracy,_that.pp,_that.noPpBoosts,_that.priority,_that.critRatio,_that.flags,_that.effects,_that.shortDescription,_that.description,_that.engineSupportLevel,_that.unsupportedReasons,_that.sourceRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, String> names,  int? generation,  String source,  String type,  PokemonMoveCategory category,  PokemonMoveTarget target,  int basePower,  PokemonMoveAccuracy accuracy,  int pp,  bool noPpBoosts,  int priority,  int critRatio,  List<PokemonMoveFlag> flags,  List<PokemonMoveEffect> effects,  String shortDescription,  String description,  PokemonMoveEngineSupportLevel engineSupportLevel,  List<String> unsupportedReasons,  PokemonMoveSourceRefs sourceRefs)  $default,) {final _that = this;
switch (_that) {
case _PokemonMove():
return $default(_that.id,_that.name,_that.names,_that.generation,_that.source,_that.type,_that.category,_that.target,_that.basePower,_that.accuracy,_that.pp,_that.noPpBoosts,_that.priority,_that.critRatio,_that.flags,_that.effects,_that.shortDescription,_that.description,_that.engineSupportLevel,_that.unsupportedReasons,_that.sourceRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Map<String, String> names,  int? generation,  String source,  String type,  PokemonMoveCategory category,  PokemonMoveTarget target,  int basePower,  PokemonMoveAccuracy accuracy,  int pp,  bool noPpBoosts,  int priority,  int critRatio,  List<PokemonMoveFlag> flags,  List<PokemonMoveEffect> effects,  String shortDescription,  String description,  PokemonMoveEngineSupportLevel engineSupportLevel,  List<String> unsupportedReasons,  PokemonMoveSourceRefs sourceRefs)?  $default,) {final _that = this;
switch (_that) {
case _PokemonMove() when $default != null:
return $default(_that.id,_that.name,_that.names,_that.generation,_that.source,_that.type,_that.category,_that.target,_that.basePower,_that.accuracy,_that.pp,_that.noPpBoosts,_that.priority,_that.critRatio,_that.flags,_that.effects,_that.shortDescription,_that.description,_that.engineSupportLevel,_that.unsupportedReasons,_that.sourceRefs);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PokemonMove extends PokemonMove {
  const _PokemonMove({required this.id, required this.name, final  Map<String, String> names = const <String, String>{}, this.generation, this.source = '', required this.type, required this.category, this.target = PokemonMoveTarget.normal, this.basePower = 0, required this.accuracy, this.pp = 0, this.noPpBoosts = false, this.priority = 0, this.critRatio = 1, final  List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[], final  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[], this.shortDescription = '', this.description = '', this.engineSupportLevel = PokemonMoveEngineSupportLevel.catalogOnly, final  List<String> unsupportedReasons = const <String>[], this.sourceRefs = const PokemonMoveSourceRefs()}): _names = names,_flags = flags,_effects = effects,_unsupportedReasons = unsupportedReasons,super._();
  factory _PokemonMove.fromJson(Map<String, dynamic> json) => _$PokemonMoveFromJson(json);

@override final  String id;
@override final  String name;
 final  Map<String, String> _names;
@override@JsonKey() Map<String, String> get names {
  if (_names is EqualUnmodifiableMapView) return _names;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_names);
}

@override final  int? generation;
/// `showdown`, `seed`, `project_custom`, etc.
@override@JsonKey() final  String source;
@override final  String type;
@override final  PokemonMoveCategory category;
@override@JsonKey() final  PokemonMoveTarget target;
@override@JsonKey() final  int basePower;
@override final  PokemonMoveAccuracy accuracy;
@override@JsonKey() final  int pp;
@override@JsonKey() final  bool noPpBoosts;
@override@JsonKey() final  int priority;
@override@JsonKey() final  int critRatio;
/// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
 final  List<PokemonMoveFlag> _flags;
/// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
@override@JsonKey() List<PokemonMoveFlag> get flags {
  if (_flags is EqualUnmodifiableListView) return _flags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_flags);
}

/// Tous les comportements applicatifs vivent ici.
 final  List<PokemonMoveEffect> _effects;
/// Tous les comportements applicatifs vivent ici.
@override@JsonKey() List<PokemonMoveEffect> get effects {
  if (_effects is EqualUnmodifiableListView) return _effects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_effects);
}

@override@JsonKey() final  String shortDescription;
@override@JsonKey() final  String description;
@override@JsonKey() final  PokemonMoveEngineSupportLevel engineSupportLevel;
 final  List<String> _unsupportedReasons;
@override@JsonKey() List<String> get unsupportedReasons {
  if (_unsupportedReasons is EqualUnmodifiableListView) return _unsupportedReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unsupportedReasons);
}

@override@JsonKey() final  PokemonMoveSourceRefs sourceRefs;

/// Create a copy of PokemonMove
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PokemonMoveCopyWith<_PokemonMove> get copyWith => __$PokemonMoveCopyWithImpl<_PokemonMove>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PokemonMove&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._names, _names)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.source, source) || other.source == source)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.target, target) || other.target == target)&&(identical(other.basePower, basePower) || other.basePower == basePower)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.pp, pp) || other.pp == pp)&&(identical(other.noPpBoosts, noPpBoosts) || other.noPpBoosts == noPpBoosts)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.critRatio, critRatio) || other.critRatio == critRatio)&&const DeepCollectionEquality().equals(other._flags, _flags)&&const DeepCollectionEquality().equals(other._effects, _effects)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.description, description) || other.description == description)&&(identical(other.engineSupportLevel, engineSupportLevel) || other.engineSupportLevel == engineSupportLevel)&&const DeepCollectionEquality().equals(other._unsupportedReasons, _unsupportedReasons)&&(identical(other.sourceRefs, sourceRefs) || other.sourceRefs == sourceRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,const DeepCollectionEquality().hash(_names),generation,source,type,category,target,basePower,accuracy,pp,noPpBoosts,priority,critRatio,const DeepCollectionEquality().hash(_flags),const DeepCollectionEquality().hash(_effects),shortDescription,description,engineSupportLevel,const DeepCollectionEquality().hash(_unsupportedReasons),sourceRefs]);

@override
String toString() {
  return 'PokemonMove(id: $id, name: $name, names: $names, generation: $generation, source: $source, type: $type, category: $category, target: $target, basePower: $basePower, accuracy: $accuracy, pp: $pp, noPpBoosts: $noPpBoosts, priority: $priority, critRatio: $critRatio, flags: $flags, effects: $effects, shortDescription: $shortDescription, description: $description, engineSupportLevel: $engineSupportLevel, unsupportedReasons: $unsupportedReasons, sourceRefs: $sourceRefs)';
}


}

/// @nodoc
abstract mixin class _$PokemonMoveCopyWith<$Res> implements $PokemonMoveCopyWith<$Res> {
  factory _$PokemonMoveCopyWith(_PokemonMove value, $Res Function(_PokemonMove) _then) = __$PokemonMoveCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Map<String, String> names, int? generation, String source, String type, PokemonMoveCategory category, PokemonMoveTarget target, int basePower, PokemonMoveAccuracy accuracy, int pp, bool noPpBoosts, int priority, int critRatio, List<PokemonMoveFlag> flags, List<PokemonMoveEffect> effects, String shortDescription, String description, PokemonMoveEngineSupportLevel engineSupportLevel, List<String> unsupportedReasons, PokemonMoveSourceRefs sourceRefs
});


@override $PokemonMoveAccuracyCopyWith<$Res> get accuracy;@override $PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs;

}
/// @nodoc
class __$PokemonMoveCopyWithImpl<$Res>
    implements _$PokemonMoveCopyWith<$Res> {
  __$PokemonMoveCopyWithImpl(this._self, this._then);

  final _PokemonMove _self;
  final $Res Function(_PokemonMove) _then;

/// Create a copy of PokemonMove
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? names = null,Object? generation = freezed,Object? source = null,Object? type = null,Object? category = null,Object? target = null,Object? basePower = null,Object? accuracy = null,Object? pp = null,Object? noPpBoosts = null,Object? priority = null,Object? critRatio = null,Object? flags = null,Object? effects = null,Object? shortDescription = null,Object? description = null,Object? engineSupportLevel = null,Object? unsupportedReasons = null,Object? sourceRefs = null,}) {
  return _then(_PokemonMove(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,names: null == names ? _self._names : names // ignore: cast_nullable_to_non_nullable
as Map<String, String>,generation: freezed == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as PokemonMoveCategory,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PokemonMoveTarget,basePower: null == basePower ? _self.basePower : basePower // ignore: cast_nullable_to_non_nullable
as int,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as PokemonMoveAccuracy,pp: null == pp ? _self.pp : pp // ignore: cast_nullable_to_non_nullable
as int,noPpBoosts: null == noPpBoosts ? _self.noPpBoosts : noPpBoosts // ignore: cast_nullable_to_non_nullable
as bool,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,critRatio: null == critRatio ? _self.critRatio : critRatio // ignore: cast_nullable_to_non_nullable
as int,flags: null == flags ? _self._flags : flags // ignore: cast_nullable_to_non_nullable
as List<PokemonMoveFlag>,effects: null == effects ? _self._effects : effects // ignore: cast_nullable_to_non_nullable
as List<PokemonMoveEffect>,shortDescription: null == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,engineSupportLevel: null == engineSupportLevel ? _self.engineSupportLevel : engineSupportLevel // ignore: cast_nullable_to_non_nullable
as PokemonMoveEngineSupportLevel,unsupportedReasons: null == unsupportedReasons ? _self._unsupportedReasons : unsupportedReasons // ignore: cast_nullable_to_non_nullable
as List<String>,sourceRefs: null == sourceRefs ? _self.sourceRefs : sourceRefs // ignore: cast_nullable_to_non_nullable
as PokemonMoveSourceRefs,
  ));
}

/// Create a copy of PokemonMove
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonMoveAccuracyCopyWith<$Res> get accuracy {

  return $PokemonMoveAccuracyCopyWith<$Res>(_self.accuracy, (value) {
    return _then(_self.copyWith(accuracy: value));
  });
}/// Create a copy of PokemonMove
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs {

  return $PokemonMoveSourceRefsCopyWith<$Res>(_self.sourceRefs, (value) {
    return _then(_self.copyWith(sourceRefs: value));
  });
}
}

// dart format on
