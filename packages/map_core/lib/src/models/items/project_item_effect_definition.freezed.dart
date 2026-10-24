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
                case 'full_restore':
          return ProjectItemFullRestoreEffectDefinition.fromJson(
            json
          );
                case 'vitamin':
          return ProjectItemVitaminEffectDefinition.fromJson(
            json
          );
                case 'battle_boost':
          return ProjectItemBattleBoostEffectDefinition.fromJson(
            json
          );
                case 'battle_preparation':
          return ProjectItemBattlePreparationEffectDefinition.fromJson(
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
                case 'fishing':
          return ProjectItemFishingEffectDefinition.fromJson(
            json
          );
                case 'bicycle':
          return ProjectItemBicycleEffectDefinition.fromJson(
            json
          );
                case 'escape_rope':
          return ProjectItemEscapeRopeEffectDefinition.fromJson(
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectItemHealHpEffectDefinition value)?  healHp,TResult Function( ProjectItemFullRestoreEffectDefinition value)?  fullRestore,TResult Function( ProjectItemVitaminEffectDefinition value)?  vitamin,TResult Function( ProjectItemBattleBoostEffectDefinition value)?  battleBoost,TResult Function( ProjectItemBattlePreparationEffectDefinition value)?  battlePreparation,TResult Function( ProjectItemCureStatusEffectDefinition value)?  cureStatus,TResult Function( ProjectItemReviveEffectDefinition value)?  revive,TResult Function( ProjectItemRestorePpEffectDefinition value)?  restorePp,TResult Function( ProjectItemRepelEffectDefinition value)?  repel,TResult Function( ProjectItemFishingEffectDefinition value)?  fishing,TResult Function( ProjectItemBicycleEffectDefinition value)?  bicycle,TResult Function( ProjectItemEscapeRopeEffectDefinition value)?  escapeRope,TResult Function( ProjectItemSemanticActionEffectDefinition value)?  semanticAction,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition() when healHp != null:
return healHp(_that);case ProjectItemFullRestoreEffectDefinition() when fullRestore != null:
return fullRestore(_that);case ProjectItemVitaminEffectDefinition() when vitamin != null:
return vitamin(_that);case ProjectItemBattleBoostEffectDefinition() when battleBoost != null:
return battleBoost(_that);case ProjectItemBattlePreparationEffectDefinition() when battlePreparation != null:
return battlePreparation(_that);case ProjectItemCureStatusEffectDefinition() when cureStatus != null:
return cureStatus(_that);case ProjectItemReviveEffectDefinition() when revive != null:
return revive(_that);case ProjectItemRestorePpEffectDefinition() when restorePp != null:
return restorePp(_that);case ProjectItemRepelEffectDefinition() when repel != null:
return repel(_that);case ProjectItemFishingEffectDefinition() when fishing != null:
return fishing(_that);case ProjectItemBicycleEffectDefinition() when bicycle != null:
return bicycle(_that);case ProjectItemEscapeRopeEffectDefinition() when escapeRope != null:
return escapeRope(_that);case ProjectItemSemanticActionEffectDefinition() when semanticAction != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectItemHealHpEffectDefinition value)  healHp,required TResult Function( ProjectItemFullRestoreEffectDefinition value)  fullRestore,required TResult Function( ProjectItemVitaminEffectDefinition value)  vitamin,required TResult Function( ProjectItemBattleBoostEffectDefinition value)  battleBoost,required TResult Function( ProjectItemBattlePreparationEffectDefinition value)  battlePreparation,required TResult Function( ProjectItemCureStatusEffectDefinition value)  cureStatus,required TResult Function( ProjectItemReviveEffectDefinition value)  revive,required TResult Function( ProjectItemRestorePpEffectDefinition value)  restorePp,required TResult Function( ProjectItemRepelEffectDefinition value)  repel,required TResult Function( ProjectItemFishingEffectDefinition value)  fishing,required TResult Function( ProjectItemBicycleEffectDefinition value)  bicycle,required TResult Function( ProjectItemEscapeRopeEffectDefinition value)  escapeRope,required TResult Function( ProjectItemSemanticActionEffectDefinition value)  semanticAction,}){
final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition():
return healHp(_that);case ProjectItemFullRestoreEffectDefinition():
return fullRestore(_that);case ProjectItemVitaminEffectDefinition():
return vitamin(_that);case ProjectItemBattleBoostEffectDefinition():
return battleBoost(_that);case ProjectItemBattlePreparationEffectDefinition():
return battlePreparation(_that);case ProjectItemCureStatusEffectDefinition():
return cureStatus(_that);case ProjectItemReviveEffectDefinition():
return revive(_that);case ProjectItemRestorePpEffectDefinition():
return restorePp(_that);case ProjectItemRepelEffectDefinition():
return repel(_that);case ProjectItemFishingEffectDefinition():
return fishing(_that);case ProjectItemBicycleEffectDefinition():
return bicycle(_that);case ProjectItemEscapeRopeEffectDefinition():
return escapeRope(_that);case ProjectItemSemanticActionEffectDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectItemHealHpEffectDefinition value)?  healHp,TResult? Function( ProjectItemFullRestoreEffectDefinition value)?  fullRestore,TResult? Function( ProjectItemVitaminEffectDefinition value)?  vitamin,TResult? Function( ProjectItemBattleBoostEffectDefinition value)?  battleBoost,TResult? Function( ProjectItemBattlePreparationEffectDefinition value)?  battlePreparation,TResult? Function( ProjectItemCureStatusEffectDefinition value)?  cureStatus,TResult? Function( ProjectItemReviveEffectDefinition value)?  revive,TResult? Function( ProjectItemRestorePpEffectDefinition value)?  restorePp,TResult? Function( ProjectItemRepelEffectDefinition value)?  repel,TResult? Function( ProjectItemFishingEffectDefinition value)?  fishing,TResult? Function( ProjectItemBicycleEffectDefinition value)?  bicycle,TResult? Function( ProjectItemEscapeRopeEffectDefinition value)?  escapeRope,TResult? Function( ProjectItemSemanticActionEffectDefinition value)?  semanticAction,}){
final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition() when healHp != null:
return healHp(_that);case ProjectItemFullRestoreEffectDefinition() when fullRestore != null:
return fullRestore(_that);case ProjectItemVitaminEffectDefinition() when vitamin != null:
return vitamin(_that);case ProjectItemBattleBoostEffectDefinition() when battleBoost != null:
return battleBoost(_that);case ProjectItemBattlePreparationEffectDefinition() when battlePreparation != null:
return battlePreparation(_that);case ProjectItemCureStatusEffectDefinition() when cureStatus != null:
return cureStatus(_that);case ProjectItemReviveEffectDefinition() when revive != null:
return revive(_that);case ProjectItemRestorePpEffectDefinition() when restorePp != null:
return restorePp(_that);case ProjectItemRepelEffectDefinition() when repel != null:
return repel(_that);case ProjectItemFishingEffectDefinition() when fishing != null:
return fishing(_that);case ProjectItemBicycleEffectDefinition() when bicycle != null:
return bicycle(_that);case ProjectItemEscapeRopeEffectDefinition() when escapeRope != null:
return escapeRope(_that);case ProjectItemSemanticActionEffectDefinition() when semanticAction != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ProjectItemAmountMode mode,  int? amount)?  healHp,TResult Function()?  fullRestore,TResult Function( ProjectItemVitaminStat stat, @JsonKey(fromJson: _itemEffectInteger)  int amount, @JsonKey(fromJson: _itemEffectInteger)  int maximumPerStat, @JsonKey(fromJson: _itemEffectInteger)  int maximumTotal, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainLow, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainMedium, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainHigh)?  vitamin,TResult Function( ProjectItemBattleStat stat, @JsonKey(fromJson: _itemEffectInteger)  int stages)?  battleBoost,TResult Function( ProjectItemBattlePreparationKind effect, @JsonKey(fromJson: _itemEffectNullableInteger)  int? turns)?  battlePreparation,TResult Function( ProjectItemStatusCureMode mode,  Set<String> statusIds)?  cureStatus,TResult Function( int rateNumerator,  int rateDenominator)?  revive,TResult Function( ProjectItemAmountMode mode,  int? amount)?  restorePp,TResult Function( int steps)?  repel,TResult Function( ProjectFishingRodKind rodKind)?  fishing,TResult Function()?  bicycle,TResult Function()?  escapeRope,TResult Function( String actionId)?  semanticAction,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition() when healHp != null:
return healHp(_that.mode,_that.amount);case ProjectItemFullRestoreEffectDefinition() when fullRestore != null:
return fullRestore();case ProjectItemVitaminEffectDefinition() when vitamin != null:
return vitamin(_that.stat,_that.amount,_that.maximumPerStat,_that.maximumTotal,_that.friendshipGainLow,_that.friendshipGainMedium,_that.friendshipGainHigh);case ProjectItemBattleBoostEffectDefinition() when battleBoost != null:
return battleBoost(_that.stat,_that.stages);case ProjectItemBattlePreparationEffectDefinition() when battlePreparation != null:
return battlePreparation(_that.effect,_that.turns);case ProjectItemCureStatusEffectDefinition() when cureStatus != null:
return cureStatus(_that.mode,_that.statusIds);case ProjectItemReviveEffectDefinition() when revive != null:
return revive(_that.rateNumerator,_that.rateDenominator);case ProjectItemRestorePpEffectDefinition() when restorePp != null:
return restorePp(_that.mode,_that.amount);case ProjectItemRepelEffectDefinition() when repel != null:
return repel(_that.steps);case ProjectItemFishingEffectDefinition() when fishing != null:
return fishing(_that.rodKind);case ProjectItemBicycleEffectDefinition() when bicycle != null:
return bicycle();case ProjectItemEscapeRopeEffectDefinition() when escapeRope != null:
return escapeRope();case ProjectItemSemanticActionEffectDefinition() when semanticAction != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ProjectItemAmountMode mode,  int? amount)  healHp,required TResult Function()  fullRestore,required TResult Function( ProjectItemVitaminStat stat, @JsonKey(fromJson: _itemEffectInteger)  int amount, @JsonKey(fromJson: _itemEffectInteger)  int maximumPerStat, @JsonKey(fromJson: _itemEffectInteger)  int maximumTotal, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainLow, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainMedium, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainHigh)  vitamin,required TResult Function( ProjectItemBattleStat stat, @JsonKey(fromJson: _itemEffectInteger)  int stages)  battleBoost,required TResult Function( ProjectItemBattlePreparationKind effect, @JsonKey(fromJson: _itemEffectNullableInteger)  int? turns)  battlePreparation,required TResult Function( ProjectItemStatusCureMode mode,  Set<String> statusIds)  cureStatus,required TResult Function( int rateNumerator,  int rateDenominator)  revive,required TResult Function( ProjectItemAmountMode mode,  int? amount)  restorePp,required TResult Function( int steps)  repel,required TResult Function( ProjectFishingRodKind rodKind)  fishing,required TResult Function()  bicycle,required TResult Function()  escapeRope,required TResult Function( String actionId)  semanticAction,}) {final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition():
return healHp(_that.mode,_that.amount);case ProjectItemFullRestoreEffectDefinition():
return fullRestore();case ProjectItemVitaminEffectDefinition():
return vitamin(_that.stat,_that.amount,_that.maximumPerStat,_that.maximumTotal,_that.friendshipGainLow,_that.friendshipGainMedium,_that.friendshipGainHigh);case ProjectItemBattleBoostEffectDefinition():
return battleBoost(_that.stat,_that.stages);case ProjectItemBattlePreparationEffectDefinition():
return battlePreparation(_that.effect,_that.turns);case ProjectItemCureStatusEffectDefinition():
return cureStatus(_that.mode,_that.statusIds);case ProjectItemReviveEffectDefinition():
return revive(_that.rateNumerator,_that.rateDenominator);case ProjectItemRestorePpEffectDefinition():
return restorePp(_that.mode,_that.amount);case ProjectItemRepelEffectDefinition():
return repel(_that.steps);case ProjectItemFishingEffectDefinition():
return fishing(_that.rodKind);case ProjectItemBicycleEffectDefinition():
return bicycle();case ProjectItemEscapeRopeEffectDefinition():
return escapeRope();case ProjectItemSemanticActionEffectDefinition():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ProjectItemAmountMode mode,  int? amount)?  healHp,TResult? Function()?  fullRestore,TResult? Function( ProjectItemVitaminStat stat, @JsonKey(fromJson: _itemEffectInteger)  int amount, @JsonKey(fromJson: _itemEffectInteger)  int maximumPerStat, @JsonKey(fromJson: _itemEffectInteger)  int maximumTotal, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainLow, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainMedium, @JsonKey(fromJson: _itemEffectInteger)  int friendshipGainHigh)?  vitamin,TResult? Function( ProjectItemBattleStat stat, @JsonKey(fromJson: _itemEffectInteger)  int stages)?  battleBoost,TResult? Function( ProjectItemBattlePreparationKind effect, @JsonKey(fromJson: _itemEffectNullableInteger)  int? turns)?  battlePreparation,TResult? Function( ProjectItemStatusCureMode mode,  Set<String> statusIds)?  cureStatus,TResult? Function( int rateNumerator,  int rateDenominator)?  revive,TResult? Function( ProjectItemAmountMode mode,  int? amount)?  restorePp,TResult? Function( int steps)?  repel,TResult? Function( ProjectFishingRodKind rodKind)?  fishing,TResult? Function()?  bicycle,TResult? Function()?  escapeRope,TResult? Function( String actionId)?  semanticAction,}) {final _that = this;
switch (_that) {
case ProjectItemHealHpEffectDefinition() when healHp != null:
return healHp(_that.mode,_that.amount);case ProjectItemFullRestoreEffectDefinition() when fullRestore != null:
return fullRestore();case ProjectItemVitaminEffectDefinition() when vitamin != null:
return vitamin(_that.stat,_that.amount,_that.maximumPerStat,_that.maximumTotal,_that.friendshipGainLow,_that.friendshipGainMedium,_that.friendshipGainHigh);case ProjectItemBattleBoostEffectDefinition() when battleBoost != null:
return battleBoost(_that.stat,_that.stages);case ProjectItemBattlePreparationEffectDefinition() when battlePreparation != null:
return battlePreparation(_that.effect,_that.turns);case ProjectItemCureStatusEffectDefinition() when cureStatus != null:
return cureStatus(_that.mode,_that.statusIds);case ProjectItemReviveEffectDefinition() when revive != null:
return revive(_that.rateNumerator,_that.rateDenominator);case ProjectItemRestorePpEffectDefinition() when restorePp != null:
return restorePp(_that.mode,_that.amount);case ProjectItemRepelEffectDefinition() when repel != null:
return repel(_that.steps);case ProjectItemFishingEffectDefinition() when fishing != null:
return fishing(_that.rodKind);case ProjectItemBicycleEffectDefinition() when bicycle != null:
return bicycle();case ProjectItemEscapeRopeEffectDefinition() when escapeRope != null:
return escapeRope();case ProjectItemSemanticActionEffectDefinition() when semanticAction != null:
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

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class ProjectItemFullRestoreEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemFullRestoreEffectDefinition({final  String? $type}): $type = $type ?? 'full_restore',super._();
  factory ProjectItemFullRestoreEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemFullRestoreEffectDefinitionFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ProjectItemFullRestoreEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemFullRestoreEffectDefinition);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectItemEffectDefinition.fullRestore()';
}


}




/// @nodoc

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class ProjectItemVitaminEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemVitaminEffectDefinition({required this.stat, @JsonKey(fromJson: _itemEffectInteger) required this.amount, @JsonKey(fromJson: _itemEffectInteger) required this.maximumPerStat, @JsonKey(fromJson: _itemEffectInteger) this.maximumTotal = 510, @JsonKey(fromJson: _itemEffectInteger) this.friendshipGainLow = 0, @JsonKey(fromJson: _itemEffectInteger) this.friendshipGainMedium = 0, @JsonKey(fromJson: _itemEffectInteger) this.friendshipGainHigh = 0, final  String? $type}): $type = $type ?? 'vitamin',super._();
  factory ProjectItemVitaminEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemVitaminEffectDefinitionFromJson(json);

 final  ProjectItemVitaminStat stat;
@JsonKey(fromJson: _itemEffectInteger) final  int amount;
@JsonKey(fromJson: _itemEffectInteger) final  int maximumPerStat;
@JsonKey(fromJson: _itemEffectInteger) final  int maximumTotal;
@JsonKey(fromJson: _itemEffectInteger) final  int friendshipGainLow;
@JsonKey(fromJson: _itemEffectInteger) final  int friendshipGainMedium;
@JsonKey(fromJson: _itemEffectInteger) final  int friendshipGainHigh;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemVitaminEffectDefinitionCopyWith<ProjectItemVitaminEffectDefinition> get copyWith => _$ProjectItemVitaminEffectDefinitionCopyWithImpl<ProjectItemVitaminEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemVitaminEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemVitaminEffectDefinition&&(identical(other.stat, stat) || other.stat == stat)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.maximumPerStat, maximumPerStat) || other.maximumPerStat == maximumPerStat)&&(identical(other.maximumTotal, maximumTotal) || other.maximumTotal == maximumTotal)&&(identical(other.friendshipGainLow, friendshipGainLow) || other.friendshipGainLow == friendshipGainLow)&&(identical(other.friendshipGainMedium, friendshipGainMedium) || other.friendshipGainMedium == friendshipGainMedium)&&(identical(other.friendshipGainHigh, friendshipGainHigh) || other.friendshipGainHigh == friendshipGainHigh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stat,amount,maximumPerStat,maximumTotal,friendshipGainLow,friendshipGainMedium,friendshipGainHigh);

@override
String toString() {
  return 'ProjectItemEffectDefinition.vitamin(stat: $stat, amount: $amount, maximumPerStat: $maximumPerStat, maximumTotal: $maximumTotal, friendshipGainLow: $friendshipGainLow, friendshipGainMedium: $friendshipGainMedium, friendshipGainHigh: $friendshipGainHigh)';
}


}

/// @nodoc
abstract mixin class $ProjectItemVitaminEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemVitaminEffectDefinitionCopyWith(ProjectItemVitaminEffectDefinition value, $Res Function(ProjectItemVitaminEffectDefinition) _then) = _$ProjectItemVitaminEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 ProjectItemVitaminStat stat,@JsonKey(fromJson: _itemEffectInteger) int amount,@JsonKey(fromJson: _itemEffectInteger) int maximumPerStat,@JsonKey(fromJson: _itemEffectInteger) int maximumTotal,@JsonKey(fromJson: _itemEffectInteger) int friendshipGainLow,@JsonKey(fromJson: _itemEffectInteger) int friendshipGainMedium,@JsonKey(fromJson: _itemEffectInteger) int friendshipGainHigh
});




}
/// @nodoc
class _$ProjectItemVitaminEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemVitaminEffectDefinitionCopyWith<$Res> {
  _$ProjectItemVitaminEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemVitaminEffectDefinition _self;
  final $Res Function(ProjectItemVitaminEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stat = null,Object? amount = null,Object? maximumPerStat = null,Object? maximumTotal = null,Object? friendshipGainLow = null,Object? friendshipGainMedium = null,Object? friendshipGainHigh = null,}) {
  return _then(ProjectItemVitaminEffectDefinition(
stat: null == stat ? _self.stat : stat // ignore: cast_nullable_to_non_nullable
as ProjectItemVitaminStat,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,maximumPerStat: null == maximumPerStat ? _self.maximumPerStat : maximumPerStat // ignore: cast_nullable_to_non_nullable
as int,maximumTotal: null == maximumTotal ? _self.maximumTotal : maximumTotal // ignore: cast_nullable_to_non_nullable
as int,friendshipGainLow: null == friendshipGainLow ? _self.friendshipGainLow : friendshipGainLow // ignore: cast_nullable_to_non_nullable
as int,friendshipGainMedium: null == friendshipGainMedium ? _self.friendshipGainMedium : friendshipGainMedium // ignore: cast_nullable_to_non_nullable
as int,friendshipGainHigh: null == friendshipGainHigh ? _self.friendshipGainHigh : friendshipGainHigh // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class ProjectItemBattleBoostEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemBattleBoostEffectDefinition({required this.stat, @JsonKey(fromJson: _itemEffectInteger) required this.stages, final  String? $type}): $type = $type ?? 'battle_boost',super._();
  factory ProjectItemBattleBoostEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemBattleBoostEffectDefinitionFromJson(json);

 final  ProjectItemBattleStat stat;
@JsonKey(fromJson: _itemEffectInteger) final  int stages;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemBattleBoostEffectDefinitionCopyWith<ProjectItemBattleBoostEffectDefinition> get copyWith => _$ProjectItemBattleBoostEffectDefinitionCopyWithImpl<ProjectItemBattleBoostEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemBattleBoostEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemBattleBoostEffectDefinition&&(identical(other.stat, stat) || other.stat == stat)&&(identical(other.stages, stages) || other.stages == stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stat,stages);

@override
String toString() {
  return 'ProjectItemEffectDefinition.battleBoost(stat: $stat, stages: $stages)';
}


}

/// @nodoc
abstract mixin class $ProjectItemBattleBoostEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemBattleBoostEffectDefinitionCopyWith(ProjectItemBattleBoostEffectDefinition value, $Res Function(ProjectItemBattleBoostEffectDefinition) _then) = _$ProjectItemBattleBoostEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 ProjectItemBattleStat stat,@JsonKey(fromJson: _itemEffectInteger) int stages
});




}
/// @nodoc
class _$ProjectItemBattleBoostEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemBattleBoostEffectDefinitionCopyWith<$Res> {
  _$ProjectItemBattleBoostEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemBattleBoostEffectDefinition _self;
  final $Res Function(ProjectItemBattleBoostEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stat = null,Object? stages = null,}) {
  return _then(ProjectItemBattleBoostEffectDefinition(
stat: null == stat ? _self.stat : stat // ignore: cast_nullable_to_non_nullable
as ProjectItemBattleStat,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class ProjectItemBattlePreparationEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemBattlePreparationEffectDefinition({required this.effect, @JsonKey(fromJson: _itemEffectNullableInteger) this.turns, final  String? $type}): $type = $type ?? 'battle_preparation',super._();
  factory ProjectItemBattlePreparationEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemBattlePreparationEffectDefinitionFromJson(json);

 final  ProjectItemBattlePreparationKind effect;
@JsonKey(fromJson: _itemEffectNullableInteger) final  int? turns;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemBattlePreparationEffectDefinitionCopyWith<ProjectItemBattlePreparationEffectDefinition> get copyWith => _$ProjectItemBattlePreparationEffectDefinitionCopyWithImpl<ProjectItemBattlePreparationEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemBattlePreparationEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemBattlePreparationEffectDefinition&&(identical(other.effect, effect) || other.effect == effect)&&(identical(other.turns, turns) || other.turns == turns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,effect,turns);

@override
String toString() {
  return 'ProjectItemEffectDefinition.battlePreparation(effect: $effect, turns: $turns)';
}


}

/// @nodoc
abstract mixin class $ProjectItemBattlePreparationEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemBattlePreparationEffectDefinitionCopyWith(ProjectItemBattlePreparationEffectDefinition value, $Res Function(ProjectItemBattlePreparationEffectDefinition) _then) = _$ProjectItemBattlePreparationEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 ProjectItemBattlePreparationKind effect,@JsonKey(fromJson: _itemEffectNullableInteger) int? turns
});




}
/// @nodoc
class _$ProjectItemBattlePreparationEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemBattlePreparationEffectDefinitionCopyWith<$Res> {
  _$ProjectItemBattlePreparationEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemBattlePreparationEffectDefinition _self;
  final $Res Function(ProjectItemBattlePreparationEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? effect = null,Object? turns = freezed,}) {
  return _then(ProjectItemBattlePreparationEffectDefinition(
effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as ProjectItemBattlePreparationKind,turns: freezed == turns ? _self.turns : turns // ignore: cast_nullable_to_non_nullable
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

@JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
class ProjectItemFishingEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemFishingEffectDefinition({required this.rodKind, final  String? $type}): $type = $type ?? 'fishing',super._();
  factory ProjectItemFishingEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemFishingEffectDefinitionFromJson(json);

 final  ProjectFishingRodKind rodKind;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemFishingEffectDefinitionCopyWith<ProjectItemFishingEffectDefinition> get copyWith => _$ProjectItemFishingEffectDefinitionCopyWithImpl<ProjectItemFishingEffectDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemFishingEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemFishingEffectDefinition&&(identical(other.rodKind, rodKind) || other.rodKind == rodKind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rodKind);

@override
String toString() {
  return 'ProjectItemEffectDefinition.fishing(rodKind: $rodKind)';
}


}

/// @nodoc
abstract mixin class $ProjectItemFishingEffectDefinitionCopyWith<$Res> implements $ProjectItemEffectDefinitionCopyWith<$Res> {
  factory $ProjectItemFishingEffectDefinitionCopyWith(ProjectItemFishingEffectDefinition value, $Res Function(ProjectItemFishingEffectDefinition) _then) = _$ProjectItemFishingEffectDefinitionCopyWithImpl;
@useResult
$Res call({
 ProjectFishingRodKind rodKind
});




}
/// @nodoc
class _$ProjectItemFishingEffectDefinitionCopyWithImpl<$Res>
    implements $ProjectItemFishingEffectDefinitionCopyWith<$Res> {
  _$ProjectItemFishingEffectDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemFishingEffectDefinition _self;
  final $Res Function(ProjectItemFishingEffectDefinition) _then;

/// Create a copy of ProjectItemEffectDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rodKind = null,}) {
  return _then(ProjectItemFishingEffectDefinition(
rodKind: null == rodKind ? _self.rodKind : rodKind // ignore: cast_nullable_to_non_nullable
as ProjectFishingRodKind,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ProjectItemBicycleEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemBicycleEffectDefinition({final  String? $type}): $type = $type ?? 'bicycle',super._();
  factory ProjectItemBicycleEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemBicycleEffectDefinitionFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ProjectItemBicycleEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemBicycleEffectDefinition);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectItemEffectDefinition.bicycle()';
}


}




/// @nodoc

@JsonSerializable(explicitToJson: true)
class ProjectItemEscapeRopeEffectDefinition extends ProjectItemEffectDefinition {
  const ProjectItemEscapeRopeEffectDefinition({final  String? $type}): $type = $type ?? 'escape_rope',super._();
  factory ProjectItemEscapeRopeEffectDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemEscapeRopeEffectDefinitionFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ProjectItemEscapeRopeEffectDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemEscapeRopeEffectDefinition);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectItemEffectDefinition.escapeRope()';
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
