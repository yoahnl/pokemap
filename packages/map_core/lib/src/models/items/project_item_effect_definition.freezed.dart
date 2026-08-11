// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_item_effect_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
ProjectItemEffectDefinition _$ProjectItemEffectDefinitionFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'heal_hp':
          return ProjectItemHealHpEffectDefinition.fromJson(
            json
          );
                case 'cure_status':
          return ProjectItemCureStatusEffectDefinition.fromJson(
            json
          );
                case 'revive':
          return ProjectItemReviveEffectDefinition.fromJson(
            json
          );
                case 'restore_pp':
          return ProjectItemRestorePpEffectDefinition.fromJson(
            json
          );
                case 'repel':
          return ProjectItemRepelEffectDefinition.fromJson(
            json
          );
                case 'semantic_action':
          return ProjectItemSemanticActionEffectDefinition.fromJson(
            json
          );

          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'ProjectItemEffectDefinition',
  'Invalid union type "${json['kind']}"!'
);
        }

}

/// @nodoc
mixin _$ProjectItemEffectDefinition {



  /// Serializes this ProjectItemEffectDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemEffectDefinition);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectItemEffectDefinition()';
}


}

/// @nodoc
class $ProjectItemEffectDefinitionCopyWith<$Res>  {
$ProjectItemEffectDefinitionCopyWith(ProjectItemEffectDefinition _, $Res Function(ProjectItemEffectDefinition) __);
}


/// Adds pattern-matching-related methods to [ProjectItemEffectDefinition].
extension ProjectItemEffectDefinitionPatterns on ProjectItemEffectDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectItemHealHpEffectDefinition value)?  healHp,TResult Function( ProjectItemCureStatusEffectDefinition value)?  cureStatus,TResult Function( ProjectItemReviveEffectDefinition value)?  revive,TResult Function( ProjectItemRestorePpEffectDefinition value)?  restorePp,TResult Function( ProjectItemRepelEffectDefinition value)?  repel,TResult Function( ProjectItemSemanticActionEffectDefinition value)?  semanticAction,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition() when healHp != null:
return healHp(_that);case ProjectItemCureStatusEffectDefinition() when cureStatus != null:
return cureStatus(_that);case ProjectItemReviveEffectDefinition() when revive != null:
return revive(_that);case ProjectItemRestorePpEffectDefinition() when restorePp != null:
return restorePp(_that);case ProjectItemRepelEffectDefinition() when repel != null:
return repel(_that);case ProjectItemSemanticActionEffectDefinition() when semanticAction != null:
return semanticAction(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectItemHealHpEffectDefinition value)  healHp,required TResult Function( ProjectItemCureStatusEffectDefinition value)  cureStatus,required TResult Function( ProjectItemReviveEffectDefinition value)  revive,required TResult Function( ProjectItemRestorePpEffectDefinition value)  restorePp,required TResult Function( ProjectItemRepelEffectDefinition value)  repel,required TResult Function( ProjectItemSemanticActionEffectDefinition value)  semanticAction,}){
final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition():
return healHp(_that);case ProjectItemCureStatusEffectDefinition():
return cureStatus(_that);case ProjectItemReviveEffectDefinition():
return revive(_that);case ProjectItemRestorePpEffectDefinition():
return restorePp(_that);case ProjectItemRepelEffectDefinition():
return repel(_that);case ProjectItemSemanticActionEffectDefinition():
return semanticAction(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectItemHealHpEffectDefinition value)?  healHp,TResult? Function( ProjectItemCureStatusEffectDefinition value)?  cureStatus,TResult? Function( ProjectItemReviveEffectDefinition value)?  revive,TResult? Function( ProjectItemRestorePpEffectDefinition value)?  restorePp,TResult? Function( ProjectItemRepelEffectDefinition value)?  repel,TResult? Function( ProjectItemSemanticActionEffectDefinition value)?  semanticAction,}){
final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition() when healHp != null:
return healHp(_that);case ProjectItemCureStatusEffectDefinition() when cureStatus != null:
return cureStatus(_that);case ProjectItemReviveEffectDefinition() when revive != null:
return revive(_that);case ProjectItemRestorePpEffectDefinition() when restorePp != null:
return restorePp(_that);case ProjectItemRepelEffectDefinition() when repel != null:
return repel(_that);case ProjectItemSemanticActionEffectDefinition() when semanticAction != null:
return semanticAction(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ProjectItemAmountMode mode,  int? amount)?  healHp,TResult Function( ProjectItemStatusCureMode mode,  Set<String> statusIds)?  cureStatus,TResult Function( int rateNumerator,  int rateDenominator)?  revive,TResult Function( ProjectItemAmountMode mode,  int? amount)?  restorePp,TResult Function( int steps)?  repel,TResult Function( String actionId)?  semanticAction,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition() when healHp != null:
return healHp(_that.mode,_that.amount);case ProjectItemCureStatusEffectDefinition() when cureStatus != null:
return cureStatus(_that.mode,_that.statusIds);case ProjectItemReviveEffectDefinition() when revive != null:
return revive(_that.rateNumerator,_that.rateDenominator);case ProjectItemRestorePpEffectDefinition() when restorePp != null:
return restorePp(_that.mode,_that.amount);case ProjectItemRepelEffectDefinition() when repel != null:
return repel(_that.steps);case ProjectItemSemanticActionEffectDefinition() when semanticAction != null:
return semanticAction(_that.actionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ProjectItemAmountMode mode,  int? amount)  healHp,required TResult Function( ProjectItemStatusCureMode mode,  Set<String> statusIds)  cureStatus,required TResult Function( int rateNumerator,  int rateDenominator)  revive,required TResult Function( ProjectItemAmountMode mode,  int? amount)  restorePp,required TResult Function( int steps)  repel,required TResult Function( String actionId)  semanticAction,}) {final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition():
return healHp(_that.mode,_that.amount);case ProjectItemCureStatusEffectDefinition():
return cureStatus(_that.mode,_that.statusIds);case ProjectItemReviveEffectDefinition():
return revive(_that.rateNumerator,_that.rateDenominator);case ProjectItemRestorePpEffectDefinition():
return restorePp(_that.mode,_that.amount);case ProjectItemRepelEffectDefinition():
return repel(_that.steps);case ProjectItemSemanticActionEffectDefinition():
return semanticAction(_that.actionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ProjectItemAmountMode mode,  int? amount)?  healHp,TResult? Function( ProjectItemStatusCureMode mode,  Set<String> statusIds)?  cureStatus,TResult? Function( int rateNumerator,  int rateDenominator)?  revive,TResult? Function( ProjectItemAmountMode mode,  int? amount)?  restorePp,TResult? Function( int steps)?  repel,TResult? Function( String actionId)?  semanticAction,}) {final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition() when healHp != null:
return healHp(_that.mode,_that.amount);case ProjectItemCureStatusEffectDefinition() when cureStatus != null:
return cureStatus(_that.mode,_that.statusIds);case ProjectItemReviveEffectDefinition() when revive != null:
return revive(_that.rateNumerator,_that.rateDenominator);case ProjectItemRestorePpEffectDefinition() when restorePp != null:
return restorePp(_that.mode,_that.amount);case ProjectItemRepelEffectDefinition() when repel != null:
return repel(_that.steps);case ProjectItemSemanticActionEffectDefinition() when semanticAction != null:
return semanticAction(_that.actionId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ProjectItemHealHpEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemHealHpEffectDefinition({required this.mode, this.amount, final  String? $type}): $type = $type ?? 'heal_hp',super._();
  factory ProjectItemHealHpEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemHealHpEffectDefinitionFromJson(json);

 final  ProjectItemAmountMode mode;
 final  int? amount;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemHealHpEffectDefinitionCopyWith<ProjectItemHealHpEffectDefinition> get copyWith => _$ProjectItemHealHpEffectDefinitionCopyWithImpl<ProjectItemHealHpEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemHealHpEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemHealHpEffectDefinition&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,amount);

@override
String toString() {
  return 'ProjectItemEffectDefinition.healHp(mode: $mode, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $ProjectItemHealHpEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemHealHpEffectDefinitionCopyWith(ProjectItemHealHpEffectDefinition value, $Res Function(ProjectItemHealHpEffectDefinition) _then) = _$ProjectItemHealHpEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 ProjectItemAmountMode mode, int? amount
});




}
/// @nodoc
class _$ProjectItemHealHpEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemHealHpEffectDefinitionCopyWith<$Res> {
  _$ProjectItemHealHpEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemHealHpEffectDefinition _self;
  final $Res Function(ProjectItemHealHpEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? amount = freezed,}) {
  return _then(ProjectItemHealHpEffectDefinition(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ProjectItemAmountMode,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ProjectItemCureStatusEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemCureStatusEffectDefinition({required this.mode, final  Set<String> statusIds = const <String>{}, final  String? $type}): _statusIds = statusIds,$type = $type ?? 'cure_status',super._();
  factory ProjectItemCureStatusEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemCureStatusEffectDefinitionFromJson(json);

 final  ProjectItemStatusCureMode mode;
 final  Set<String> _statusIds;
@JsonKey() Set<String> get statusIds {
  if (_statusIds is EqualUnmodifiableSetView) return _statusIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_statusIds);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemCureStatusEffectDefinitionCopyWith<ProjectItemCureStatusEffectDefinition> get copyWith => _$ProjectItemCureStatusEffectDefinitionCopyWithImpl<ProjectItemCureStatusEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemCureStatusEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemCureStatusEffectDefinition&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other._statusIds, _statusIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,const DeepCollectionEquality().hash(_statusIds));

@override
String toString() {
  return 'ProjectItemEffectDefinition.cureStatus(mode: $mode, statusIds: $statusIds)';
}


}

/// @nodoc
abstract mixin class $ProjectItemCureStatusEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemCureStatusEffectDefinitionCopyWith(ProjectItemCureStatusEffectDefinition value, $Res Function(ProjectItemCureStatusEffectDefinition) _then) = _$ProjectItemCureStatusEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 ProjectItemStatusCureMode mode, Set<String> statusIds
});




}
/// @nodoc
class _$ProjectItemCureStatusEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemCureStatusEffectDefinitionCopyWith<$Res> {
  _$ProjectItemCureStatusEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemCureStatusEffectDefinition _self;
  final $Res Function(ProjectItemCureStatusEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? statusIds = null,}) {
  return _then(ProjectItemCureStatusEffectDefinition(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ProjectItemStatusCureMode,statusIds: null == statusIds ? _self._statusIds : statusIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ProjectItemReviveEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemReviveEffectDefinition({required this.rateNumerator, required this.rateDenominator, final  String? $type}): $type = $type ?? 'revive',super._();
  factory ProjectItemReviveEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemReviveEffectDefinitionFromJson(json);

 final  int rateNumerator;
 final  int rateDenominator;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemReviveEffectDefinitionCopyWith<ProjectItemReviveEffectDefinition> get copyWith => _$ProjectItemReviveEffectDefinitionCopyWithImpl<ProjectItemReviveEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemReviveEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemReviveEffectDefinition&&(identical(other.rateNumerator, rateNumerator) || other.rateNumerator == rateNumerator)&&(identical(other.rateDenominator, rateDenominator) || other.rateDenominator == rateDenominator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rateNumerator,rateDenominator);

@override
String toString() {
  return 'ProjectItemEffectDefinition.revive(rateNumerator: $rateNumerator, rateDenominator: $rateDenominator)';
}


}

/// @nodoc
abstract mixin class $ProjectItemReviveEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemReviveEffectDefinitionCopyWith(ProjectItemReviveEffectDefinition value, $Res Function(ProjectItemReviveEffectDefinition) _then) = _$ProjectItemReviveEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 int rateNumerator, int rateDenominator
});




}
/// @nodoc
class _$ProjectItemReviveEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemReviveEffectDefinitionCopyWith<$Res> {
  _$ProjectItemReviveEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemReviveEffectDefinition _self;
  final $Res Function(ProjectItemReviveEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rateNumerator = null,Object? rateDenominator = null,}) {
  return _then(ProjectItemReviveEffectDefinition(
rateNumerator: null == rateNumerator ? _self.rateNumerator : rateNumerator // ignore: cast_nullable_to_non_nullable
as int,rateDenominator: null == rateDenominator ? _self.rateDenominator : rateDenominator // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ProjectItemRestorePpEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemRestorePpEffectDefinition({required this.mode, this.amount, final  String? $type}): $type = $type ?? 'restore_pp',super._();
  factory ProjectItemRestorePpEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemRestorePpEffectDefinitionFromJson(json);

 final  ProjectItemAmountMode mode;
 final  int? amount;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemRestorePpEffectDefinitionCopyWith<ProjectItemRestorePpEffectDefinition> get copyWith => _$ProjectItemRestorePpEffectDefinitionCopyWithImpl<ProjectItemRestorePpEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemRestorePpEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemRestorePpEffectDefinition&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,amount);

@override
String toString() {
  return 'ProjectItemEffectDefinition.restorePp(mode: $mode, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $ProjectItemRestorePpEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemRestorePpEffectDefinitionCopyWith(ProjectItemRestorePpEffectDefinition value, $Res Function(ProjectItemRestorePpEffectDefinition) _then) = _$ProjectItemRestorePpEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 ProjectItemAmountMode mode, int? amount
});




}
/// @nodoc
class _$ProjectItemRestorePpEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemRestorePpEffectDefinitionCopyWith<$Res> {
  _$ProjectItemRestorePpEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemRestorePpEffectDefinition _self;
  final $Res Function(ProjectItemRestorePpEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? amount = freezed,}) {
  return _then(ProjectItemRestorePpEffectDefinition(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ProjectItemAmountMode,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ProjectItemRepelEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemRepelEffectDefinition({required this.steps, final  String? $type}): $type = $type ?? 'repel',super._();
  factory ProjectItemRepelEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemRepelEffectDefinitionFromJson(json);

 final  int steps;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemRepelEffectDefinitionCopyWith<ProjectItemRepelEffectDefinition> get copyWith => _$ProjectItemRepelEffectDefinitionCopyWithImpl<ProjectItemRepelEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemRepelEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemRepelEffectDefinition&&(identical(other.steps, steps) || other.steps == steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,steps);

@override
String toString() {
  return 'ProjectItemEffectDefinition.repel(steps: $steps)';
}


}

/// @nodoc
abstract mixin class $ProjectItemRepelEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemRepelEffectDefinitionCopyWith(ProjectItemRepelEffectDefinition value, $Res Function(ProjectItemRepelEffectDefinition) _then) = _$ProjectItemRepelEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 int steps
});




}
/// @nodoc
class _$ProjectItemRepelEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemRepelEffectDefinitionCopyWith<$Res> {
  _$ProjectItemRepelEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemRepelEffectDefinition _self;
  final $Res Function(ProjectItemRepelEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? steps = null,}) {
  return _then(ProjectItemRepelEffectDefinition(
steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ProjectItemSemanticActionEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemSemanticActionEffectDefinition({required this.actionId, final  String? $type}): $type = $type ?? 'semantic_action',super._();
  factory ProjectItemSemanticActionEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemSemanticActionEffectDefinitionFromJson(json);

 final  String actionId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemSemanticActionEffectDefinitionCopyWith<ProjectItemSemanticActionEffectDefinition> get copyWith => _$ProjectItemSemanticActionEffectDefinitionCopyWithImpl<ProjectItemSemanticActionEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemSemanticActionEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemSemanticActionEffectDefinition&&(identical(other.actionId, actionId) || other.actionId == actionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionId);

@override
String toString() {
  return 'ProjectItemEffectDefinition.semanticAction(actionId: $actionId)';
}


}

/// @nodoc
abstract mixin class $ProjectItemSemanticActionEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemSemanticActionEffectDefinitionCopyWith(ProjectItemSemanticActionEffectDefinition value, $Res Function(ProjectItemSemanticActionEffectDefinition) _then) = _$ProjectItemSemanticActionEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 String actionId
});




}
/// @nodoc
class _$ProjectItemSemanticActionEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemSemanticActionEffectDefinitionCopyWith<$Res> {
  _$ProjectItemSemanticActionEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemSemanticActionEffectDefinition _self;
  final $Res Function(ProjectItemSemanticActionEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? actionId = null,}) {
  return _then(ProjectItemSemanticActionEffectDefinition(
actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
