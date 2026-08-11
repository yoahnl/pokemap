// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_item_capabilities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectItemUseDefinition {

 Set<ProjectItemUseContext> get contexts; ProjectItemTargetKind get target; ProjectItemConsumptionPolicy get consumption; ProjectItemEffectDefinition get effect;
/// Create a copy of ProjectItemUseDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemUseDefinitionCopyWith<ProjectItemUseDefinition> get copyWith => _$ProjectItemUseDefinitionCopyWithImpl<ProjectItemUseDefinition>(this as ProjectItemUseDefinition, _$identity);

  /// Serializes this ProjectItemUseDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemUseDefinition&&const DeepCollectionEquality().equals(other.contexts, contexts)&&(identical(other.target, target) || other.target == target)&&(identical(other.consumption, consumption) || other.consumption == consumption)&&(identical(other.effect, effect) || other.effect == effect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(contexts),target,consumption,effect);

@override
String toString() {
  return 'ProjectItemUseDefinition(contexts: $contexts, target: $target, consumption: $consumption, effect: $effect)';
}


}

/// @nodoc
abstract mixin class $ProjectItemUseDefinitionCopyWith<$Res>  {
  factory $ProjectItemUseDefinitionCopyWith(ProjectItemUseDefinition value, $Res Function(ProjectItemUseDefinition) _then) = _$ProjectItemUseDefinitionCopyWithImpl;
@useResult
$Res call({
 Set<ProjectItemUseContext> contexts, ProjectItemTargetKind target, ProjectItemConsumptionPolicy consumption, ProjectItemEffectDefinition effect
});


$ProjectItemEffectDefinitionCopyWith<$Res> get effect;

}
/// @nodoc
class _$ProjectItemUseDefinitionCopyWithImpl<$Res>
    implements $ProjectItemUseDefinitionCopyWith<$Res> {
  _$ProjectItemUseDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemUseDefinition _self;
  final $Res Function(ProjectItemUseDefinition) _then;

/// Create a copy of ProjectItemUseDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contexts = null,Object? target = null,Object? consumption = null,Object? effect = null,}) {
  return _then(_self.copyWith(
contexts: null == contexts ? _self.contexts : contexts // ignore: cast_nullable_to_non_nullable
as Set<ProjectItemUseContext>,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ProjectItemTargetKind,consumption: null == consumption ? _self.consumption : consumption // ignore: cast_nullable_to_non_nullable
as ProjectItemConsumptionPolicy,effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as ProjectItemEffectDefinition,
  ));
}
/// Create a copy of ProjectItemUseDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectItemEffectDefinitionCopyWith<$Res> get effect {

  return $ProjectItemEffectDefinitionCopyWith<$Res>(_self.effect, (value) {
    return _then(_self.copyWith(effect: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectItemUseDefinition].
extension ProjectItemUseDefinitionPatterns on ProjectItemUseDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectItemUseDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectItemUseDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectItemUseDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ProjectItemUseDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectItemUseDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectItemUseDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<ProjectItemUseContext> contexts,  ProjectItemTargetKind target,  ProjectItemConsumptionPolicy consumption,  ProjectItemEffectDefinition effect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectItemUseDefinition() when $default != null:
return $default(_that.contexts,_that.target,_that.consumption,_that.effect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<ProjectItemUseContext> contexts,  ProjectItemTargetKind target,  ProjectItemConsumptionPolicy consumption,  ProjectItemEffectDefinition effect)  $default,) {final _that = this;
switch (_that) {
case _ProjectItemUseDefinition():
return $default(_that.contexts,_that.target,_that.consumption,_that.effect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<ProjectItemUseContext> contexts,  ProjectItemTargetKind target,  ProjectItemConsumptionPolicy consumption,  ProjectItemEffectDefinition effect)?  $default,) {final _that = this;
switch (_that) {
case _ProjectItemUseDefinition() when $default != null:
return $default(_that.contexts,_that.target,_that.consumption,_that.effect);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectItemUseDefinition extends ProjectItemUseDefinition {
  const _ProjectItemUseDefinition({required final  Set<ProjectItemUseContext> contexts, required this.target, required this.consumption, required this.effect}): _contexts = contexts,super._();
  factory _ProjectItemUseDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemUseDefinitionFromJson(json);

 final  Set<ProjectItemUseContext> _contexts;
@override Set<ProjectItemUseContext> get contexts {
  if (_contexts is EqualUnmodifiableSetView) return _contexts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_contexts);
}

@override final  ProjectItemTargetKind target;
@override final  ProjectItemConsumptionPolicy consumption;
@override final  ProjectItemEffectDefinition effect;

/// Create a copy of ProjectItemUseDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectItemUseDefinitionCopyWith<_ProjectItemUseDefinition> get copyWith => __$ProjectItemUseDefinitionCopyWithImpl<_ProjectItemUseDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemUseDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectItemUseDefinition&&const DeepCollectionEquality().equals(other._contexts, _contexts)&&(identical(other.target, target) || other.target == target)&&(identical(other.consumption, consumption) || other.consumption == consumption)&&(identical(other.effect, effect) || other.effect == effect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_contexts),target,consumption,effect);

@override
String toString() {
  return 'ProjectItemUseDefinition(contexts: $contexts, target: $target, consumption: $consumption, effect: $effect)';
}


}

/// @nodoc
abstract mixin class _$ProjectItemUseDefinitionCopyWith<$Res> implements $ProjectItemUseDefinitionCopyWith<$Res> {
  factory _$ProjectItemUseDefinitionCopyWith(_ProjectItemUseDefinition value, $Res Function(_ProjectItemUseDefinition) _then) = __$ProjectItemUseDefinitionCopyWithImpl;
@override @useResult
$Res call({
 Set<ProjectItemUseContext> contexts, ProjectItemTargetKind target, ProjectItemConsumptionPolicy consumption, ProjectItemEffectDefinition effect
});


@override $ProjectItemEffectDefinitionCopyWith<$Res> get effect;

}
/// @nodoc
class __$ProjectItemUseDefinitionCopyWithImpl<$Res>
    implements _$ProjectItemUseDefinitionCopyWith<$Res> {
  __$ProjectItemUseDefinitionCopyWithImpl(this._self, this._then);

  final _ProjectItemUseDefinition _self;
  final $Res Function(_ProjectItemUseDefinition) _then;

/// Create a copy of ProjectItemUseDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contexts = null,Object? target = null,Object? consumption = null,Object? effect = null,}) {
  return _then(_ProjectItemUseDefinition(
contexts: null == contexts ? _self._contexts : contexts // ignore: cast_nullable_to_non_nullable
as Set<ProjectItemUseContext>,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ProjectItemTargetKind,consumption: null == consumption ? _self.consumption : consumption // ignore: cast_nullable_to_non_nullable
as ProjectItemConsumptionPolicy,effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as ProjectItemEffectDefinition,
  ));
}

/// Create a copy of ProjectItemUseDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectItemEffectDefinitionCopyWith<$Res> get effect {

  return $ProjectItemEffectDefinitionCopyWith<$Res>(_self.effect, (value) {
    return _then(_self.copyWith(effect: value));
  });
}
}


/// @nodoc
mixin _$ProjectCaptureItemDefinition {

 int get rateNumerator; int get rateDenominator; Set<EncounterKind> get allowedEncounterKinds;
/// Create a copy of ProjectCaptureItemDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCaptureItemDefinitionCopyWith<ProjectCaptureItemDefinition> get copyWith => _$ProjectCaptureItemDefinitionCopyWithImpl<ProjectCaptureItemDefinition>(this as ProjectCaptureItemDefinition, _$identity);

  /// Serializes this ProjectCaptureItemDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectCaptureItemDefinition&&(identical(other.rateNumerator, rateNumerator) || other.rateNumerator == rateNumerator)&&(identical(other.rateDenominator, rateDenominator) || other.rateDenominator == rateDenominator)&&const DeepCollectionEquality().equals(other.allowedEncounterKinds, allowedEncounterKinds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rateNumerator,rateDenominator,const DeepCollectionEquality().hash(allowedEncounterKinds));

@override
String toString() {
  return 'ProjectCaptureItemDefinition(rateNumerator: $rateNumerator, rateDenominator: $rateDenominator, allowedEncounterKinds: $allowedEncounterKinds)';
}


}

/// @nodoc
abstract mixin class $ProjectCaptureItemDefinitionCopyWith<$Res>  {
  factory $ProjectCaptureItemDefinitionCopyWith(ProjectCaptureItemDefinition value, $Res Function(ProjectCaptureItemDefinition) _then) = _$ProjectCaptureItemDefinitionCopyWithImpl;
@useResult
$Res call({
 int rateNumerator, int rateDenominator, Set<EncounterKind> allowedEncounterKinds
});




}
/// @nodoc
class _$ProjectCaptureItemDefinitionCopyWithImpl<$Res>
    implements $ProjectCaptureItemDefinitionCopyWith<$Res> {
  _$ProjectCaptureItemDefinitionCopyWithImpl(this._self, this._then);

  final ProjectCaptureItemDefinition _self;
  final $Res Function(ProjectCaptureItemDefinition) _then;

/// Create a copy of ProjectCaptureItemDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rateNumerator = null,Object? rateDenominator = null,Object? allowedEncounterKinds = null,}) {
  return _then(_self.copyWith(
rateNumerator: null == rateNumerator ? _self.rateNumerator : rateNumerator // ignore: cast_nullable_to_non_nullable
as int,rateDenominator: null == rateDenominator ? _self.rateDenominator : rateDenominator // ignore: cast_nullable_to_non_nullable
as int,allowedEncounterKinds: null == allowedEncounterKinds ? _self.allowedEncounterKinds : allowedEncounterKinds // ignore: cast_nullable_to_non_nullable
as Set<EncounterKind>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectCaptureItemDefinition].
extension ProjectCaptureItemDefinitionPatterns on ProjectCaptureItemDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectCaptureItemDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectCaptureItemDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectCaptureItemDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ProjectCaptureItemDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectCaptureItemDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectCaptureItemDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rateNumerator,  int rateDenominator,  Set<EncounterKind> allowedEncounterKinds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectCaptureItemDefinition() when $default != null:
return $default(_that.rateNumerator,_that.rateDenominator,_that.allowedEncounterKinds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rateNumerator,  int rateDenominator,  Set<EncounterKind> allowedEncounterKinds)  $default,) {final _that = this;
switch (_that) {
case _ProjectCaptureItemDefinition():
return $default(_that.rateNumerator,_that.rateDenominator,_that.allowedEncounterKinds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rateNumerator,  int rateDenominator,  Set<EncounterKind> allowedEncounterKinds)?  $default,) {final _that = this;
switch (_that) {
case _ProjectCaptureItemDefinition() when $default != null:
return $default(_that.rateNumerator,_that.rateDenominator,_that.allowedEncounterKinds);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectCaptureItemDefinition extends ProjectCaptureItemDefinition {
  const _ProjectCaptureItemDefinition({required this.rateNumerator, required this.rateDenominator, required final  Set<EncounterKind> allowedEncounterKinds}): _allowedEncounterKinds = allowedEncounterKinds,super._();
  factory _ProjectCaptureItemDefinition.fromJson(Map<String, dynamic> json) => _$ProjectCaptureItemDefinitionFromJson(json);

@override final  int rateNumerator;
@override final  int rateDenominator;
 final  Set<EncounterKind> _allowedEncounterKinds;
@override Set<EncounterKind> get allowedEncounterKinds {
  if (_allowedEncounterKinds is EqualUnmodifiableSetView) return _allowedEncounterKinds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_allowedEncounterKinds);
}


/// Create a copy of ProjectCaptureItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCaptureItemDefinitionCopyWith<_ProjectCaptureItemDefinition> get copyWith => __$ProjectCaptureItemDefinitionCopyWithImpl<_ProjectCaptureItemDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectCaptureItemDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectCaptureItemDefinition&&(identical(other.rateNumerator, rateNumerator) || other.rateNumerator == rateNumerator)&&(identical(other.rateDenominator, rateDenominator) || other.rateDenominator == rateDenominator)&&const DeepCollectionEquality().equals(other._allowedEncounterKinds, _allowedEncounterKinds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rateNumerator,rateDenominator,const DeepCollectionEquality().hash(_allowedEncounterKinds));

@override
String toString() {
  return 'ProjectCaptureItemDefinition(rateNumerator: $rateNumerator, rateDenominator: $rateDenominator, allowedEncounterKinds: $allowedEncounterKinds)';
}


}

/// @nodoc
abstract mixin class _$ProjectCaptureItemDefinitionCopyWith<$Res> implements $ProjectCaptureItemDefinitionCopyWith<$Res> {
  factory _$ProjectCaptureItemDefinitionCopyWith(_ProjectCaptureItemDefinition value, $Res Function(_ProjectCaptureItemDefinition) _then) = __$ProjectCaptureItemDefinitionCopyWithImpl;
@override @useResult
$Res call({
 int rateNumerator, int rateDenominator, Set<EncounterKind> allowedEncounterKinds
});




}
/// @nodoc
class __$ProjectCaptureItemDefinitionCopyWithImpl<$Res>
    implements _$ProjectCaptureItemDefinitionCopyWith<$Res> {
  __$ProjectCaptureItemDefinitionCopyWithImpl(this._self, this._then);

  final _ProjectCaptureItemDefinition _self;
  final $Res Function(_ProjectCaptureItemDefinition) _then;

/// Create a copy of ProjectCaptureItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rateNumerator = null,Object? rateDenominator = null,Object? allowedEncounterKinds = null,}) {
  return _then(_ProjectCaptureItemDefinition(
rateNumerator: null == rateNumerator ? _self.rateNumerator : rateNumerator // ignore: cast_nullable_to_non_nullable
as int,rateDenominator: null == rateDenominator ? _self.rateDenominator : rateDenominator // ignore: cast_nullable_to_non_nullable
as int,allowedEncounterKinds: null == allowedEncounterKinds ? _self._allowedEncounterKinds : allowedEncounterKinds // ignore: cast_nullable_to_non_nullable
as Set<EncounterKind>,
  ));
}


}


/// @nodoc
mixin _$ProjectMoveMachineItemDefinition {

 String get moveId; ProjectMoveMachineKind get kind; bool get consumable;
/// Create a copy of ProjectMoveMachineItemDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectMoveMachineItemDefinitionCopyWith<ProjectMoveMachineItemDefinition> get copyWith => _$ProjectMoveMachineItemDefinitionCopyWithImpl<ProjectMoveMachineItemDefinition>(this as ProjectMoveMachineItemDefinition, _$identity);

  /// Serializes this ProjectMoveMachineItemDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectMoveMachineItemDefinition&&(identical(other.moveId, moveId) || other.moveId == moveId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.consumable, consumable) || other.consumable == consumable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,moveId,kind,consumable);

@override
String toString() {
  return 'ProjectMoveMachineItemDefinition(moveId: $moveId, kind: $kind, consumable: $consumable)';
}


}

/// @nodoc
abstract mixin class $ProjectMoveMachineItemDefinitionCopyWith<$Res>  {
  factory $ProjectMoveMachineItemDefinitionCopyWith(ProjectMoveMachineItemDefinition value, $Res Function(ProjectMoveMachineItemDefinition) _then) = _$ProjectMoveMachineItemDefinitionCopyWithImpl;
@useResult
$Res call({
 String moveId, ProjectMoveMachineKind kind, bool consumable
});




}
/// @nodoc
class _$ProjectMoveMachineItemDefinitionCopyWithImpl<$Res>
    implements $ProjectMoveMachineItemDefinitionCopyWith<$Res> {
  _$ProjectMoveMachineItemDefinitionCopyWithImpl(this._self, this._then);

  final ProjectMoveMachineItemDefinition _self;
  final $Res Function(ProjectMoveMachineItemDefinition) _then;

/// Create a copy of ProjectMoveMachineItemDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? moveId = null,Object? kind = null,Object? consumable = null,}) {
  return _then(_self.copyWith(
moveId: null == moveId ? _self.moveId : moveId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProjectMoveMachineKind,consumable: null == consumable ? _self.consumable : consumable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectMoveMachineItemDefinition].
extension ProjectMoveMachineItemDefinitionPatterns on ProjectMoveMachineItemDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectMoveMachineItemDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectMoveMachineItemDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectMoveMachineItemDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ProjectMoveMachineItemDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectMoveMachineItemDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectMoveMachineItemDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String moveId,  ProjectMoveMachineKind kind,  bool consumable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectMoveMachineItemDefinition() when $default != null:
return $default(_that.moveId,_that.kind,_that.consumable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String moveId,  ProjectMoveMachineKind kind,  bool consumable)  $default,) {final _that = this;
switch (_that) {
case _ProjectMoveMachineItemDefinition():
return $default(_that.moveId,_that.kind,_that.consumable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String moveId,  ProjectMoveMachineKind kind,  bool consumable)?  $default,) {final _that = this;
switch (_that) {
case _ProjectMoveMachineItemDefinition() when $default != null:
return $default(_that.moveId,_that.kind,_that.consumable);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectMoveMachineItemDefinition extends ProjectMoveMachineItemDefinition {
  const _ProjectMoveMachineItemDefinition({required this.moveId, required this.kind, required this.consumable}): super._();
  factory _ProjectMoveMachineItemDefinition.fromJson(Map<String, dynamic> json) => _$ProjectMoveMachineItemDefinitionFromJson(json);

@override final  String moveId;
@override final  ProjectMoveMachineKind kind;
@override final  bool consumable;

/// Create a copy of ProjectMoveMachineItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectMoveMachineItemDefinitionCopyWith<_ProjectMoveMachineItemDefinition> get copyWith => __$ProjectMoveMachineItemDefinitionCopyWithImpl<_ProjectMoveMachineItemDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectMoveMachineItemDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectMoveMachineItemDefinition&&(identical(other.moveId, moveId) || other.moveId == moveId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.consumable, consumable) || other.consumable == consumable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,moveId,kind,consumable);

@override
String toString() {
  return 'ProjectMoveMachineItemDefinition(moveId: $moveId, kind: $kind, consumable: $consumable)';
}


}

/// @nodoc
abstract mixin class _$ProjectMoveMachineItemDefinitionCopyWith<$Res> implements $ProjectMoveMachineItemDefinitionCopyWith<$Res> {
  factory _$ProjectMoveMachineItemDefinitionCopyWith(_ProjectMoveMachineItemDefinition value, $Res Function(_ProjectMoveMachineItemDefinition) _then) = __$ProjectMoveMachineItemDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String moveId, ProjectMoveMachineKind kind, bool consumable
});




}
/// @nodoc
class __$ProjectMoveMachineItemDefinitionCopyWithImpl<$Res>
    implements _$ProjectMoveMachineItemDefinitionCopyWith<$Res> {
  __$ProjectMoveMachineItemDefinitionCopyWithImpl(this._self, this._then);

  final _ProjectMoveMachineItemDefinition _self;
  final $Res Function(_ProjectMoveMachineItemDefinition) _then;

/// Create a copy of ProjectMoveMachineItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? moveId = null,Object? kind = null,Object? consumable = null,}) {
  return _then(_ProjectMoveMachineItemDefinition(
moveId: null == moveId ? _self.moveId : moveId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProjectMoveMachineKind,consumable: null == consumable ? _self.consumable : consumable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
