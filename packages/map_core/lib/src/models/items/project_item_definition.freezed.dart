// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_item_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectItemDefinition {

 String get id; String get displayName; List<String> get aliases; String get pocketId; String? get description; int? get buyPrice; int? get sellPrice; Set<String> get tags; List<ProjectItemUseDefinition> get uses; ProjectCaptureItemDefinition? get capture; ProjectMoveMachineItemDefinition? get machine; String? get heldEffectId;
/// Create a copy of ProjectItemDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemDefinitionCopyWith<ProjectItemDefinition> get copyWith => _$ProjectItemDefinitionCopyWithImpl<ProjectItemDefinition>(this as ProjectItemDefinition, _$identity);

  /// Serializes this ProjectItemDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&const DeepCollectionEquality().equals(other.aliases, aliases)&&(identical(other.pocketId, pocketId) || other.pocketId == pocketId)&&(identical(other.description, description) || other.description == description)&&(identical(other.buyPrice, buyPrice) || other.buyPrice == buyPrice)&&(identical(other.sellPrice, sellPrice) || other.sellPrice == sellPrice)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.uses, uses)&&(identical(other.capture, capture) || other.capture == capture)&&(identical(other.machine, machine) || other.machine == machine)&&(identical(other.heldEffectId, heldEffectId) || other.heldEffectId == heldEffectId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,const DeepCollectionEquality().hash(aliases),pocketId,description,buyPrice,sellPrice,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(uses),capture,machine,heldEffectId);

@override
String toString() {
  return 'ProjectItemDefinition(id: $id, displayName: $displayName, aliases: $aliases, pocketId: $pocketId, description: $description, buyPrice: $buyPrice, sellPrice: $sellPrice, tags: $tags, uses: $uses, capture: $capture, machine: $machine, heldEffectId: $heldEffectId)';
}


}

/// @nodoc
abstract mixin class $ProjectItemDefinitionCopyWith<$Res>  {
  factory $ProjectItemDefinitionCopyWith(ProjectItemDefinition value, $Res Function(ProjectItemDefinition) _then) = _$ProjectItemDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, List<String> aliases, String pocketId, String? description, int? buyPrice, int? sellPrice, Set<String> tags, List<ProjectItemUseDefinition> uses, ProjectCaptureItemDefinition? capture, ProjectMoveMachineItemDefinition? machine, String? heldEffectId
});


$ProjectCaptureItemDefinitionCopyWith<$Res>? get capture;$ProjectMoveMachineItemDefinitionCopyWith<$Res>? get machine;

}
/// @nodoc
class _$ProjectItemDefinitionCopyWithImpl<$Res>
    implements $ProjectItemDefinitionCopyWith<$Res> {
  _$ProjectItemDefinitionCopyWithImpl(this._self, this._then);

  final ProjectItemDefinition _self;
  final $Res Function(ProjectItemDefinition) _then;

/// Create a copy of ProjectItemDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? aliases = null,Object? pocketId = null,Object? description = freezed,Object? buyPrice = freezed,Object? sellPrice = freezed,Object? tags = null,Object? uses = null,Object? capture = freezed,Object? machine = freezed,Object? heldEffectId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,pocketId: null == pocketId ? _self.pocketId : pocketId // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,buyPrice: freezed == buyPrice ? _self.buyPrice : buyPrice // ignore: cast_nullable_to_non_nullable
as int?,sellPrice: freezed == sellPrice ? _self.sellPrice : sellPrice // ignore: cast_nullable_to_non_nullable
as int?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as Set<String>,uses: null == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as List<ProjectItemUseDefinition>,capture: freezed == capture ? _self.capture : capture // ignore: cast_nullable_to_non_nullable
as ProjectCaptureItemDefinition?,machine: freezed == machine ? _self.machine : machine // ignore: cast_nullable_to_non_nullable
as ProjectMoveMachineItemDefinition?,heldEffectId: freezed == heldEffectId ? _self.heldEffectId : heldEffectId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProjectItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCaptureItemDefinitionCopyWith<$Res>? get capture {
    if (_self.capture == null) {
    return null;
  }

  return $ProjectCaptureItemDefinitionCopyWith<$Res>(_self.capture!, (value) {
    return _then(_self.copyWith(capture: value));
  });
}/// Create a copy of ProjectItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectMoveMachineItemDefinitionCopyWith<$Res>? get machine {
    if (_self.machine == null) {
    return null;
  }

  return $ProjectMoveMachineItemDefinitionCopyWith<$Res>(_self.machine!, (value) {
    return _then(_self.copyWith(machine: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectItemDefinition].
extension ProjectItemDefinitionPatterns on ProjectItemDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectItemDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectItemDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectItemDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ProjectItemDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectItemDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectItemDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  List<String> aliases,  String pocketId,  String? description,  int? buyPrice,  int? sellPrice,  Set<String> tags,  List<ProjectItemUseDefinition> uses,  ProjectCaptureItemDefinition? capture,  ProjectMoveMachineItemDefinition? machine,  String? heldEffectId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectItemDefinition() when $default != null:
return $default(_that.id,_that.displayName,_that.aliases,_that.pocketId,_that.description,_that.buyPrice,_that.sellPrice,_that.tags,_that.uses,_that.capture,_that.machine,_that.heldEffectId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  List<String> aliases,  String pocketId,  String? description,  int? buyPrice,  int? sellPrice,  Set<String> tags,  List<ProjectItemUseDefinition> uses,  ProjectCaptureItemDefinition? capture,  ProjectMoveMachineItemDefinition? machine,  String? heldEffectId)  $default,) {final _that = this;
switch (_that) {
case _ProjectItemDefinition():
return $default(_that.id,_that.displayName,_that.aliases,_that.pocketId,_that.description,_that.buyPrice,_that.sellPrice,_that.tags,_that.uses,_that.capture,_that.machine,_that.heldEffectId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  List<String> aliases,  String pocketId,  String? description,  int? buyPrice,  int? sellPrice,  Set<String> tags,  List<ProjectItemUseDefinition> uses,  ProjectCaptureItemDefinition? capture,  ProjectMoveMachineItemDefinition? machine,  String? heldEffectId)?  $default,) {final _that = this;
switch (_that) {
case _ProjectItemDefinition() when $default != null:
return $default(_that.id,_that.displayName,_that.aliases,_that.pocketId,_that.description,_that.buyPrice,_that.sellPrice,_that.tags,_that.uses,_that.capture,_that.machine,_that.heldEffectId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectItemDefinition extends ProjectItemDefinition {
  const _ProjectItemDefinition({required this.id, required this.displayName, final  List<String> aliases = const <String>[], required this.pocketId, this.description, this.buyPrice, this.sellPrice, final  Set<String> tags = const <String>{}, final  List<ProjectItemUseDefinition> uses = const <ProjectItemUseDefinition>[], this.capture, this.machine, this.heldEffectId}): _aliases = aliases,_tags = tags,_uses = uses,super._();
  factory _ProjectItemDefinition.fromJson(Map<String, dynamic> json) => _$ProjectItemDefinitionFromJson(json);

@override final  String id;
@override final  String displayName;
 final  List<String> _aliases;
@override@JsonKey() List<String> get aliases {
  if (_aliases is EqualUnmodifiableListView) return _aliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aliases);
}

@override final  String pocketId;
@override final  String? description;
@override final  int? buyPrice;
@override final  int? sellPrice;
 final  Set<String> _tags;
@override@JsonKey() Set<String> get tags {
  if (_tags is EqualUnmodifiableSetView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_tags);
}

 final  List<ProjectItemUseDefinition> _uses;
@override@JsonKey() List<ProjectItemUseDefinition> get uses {
  if (_uses is EqualUnmodifiableListView) return _uses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_uses);
}

@override final  ProjectCaptureItemDefinition? capture;
@override final  ProjectMoveMachineItemDefinition? machine;
@override final  String? heldEffectId;

/// Create a copy of ProjectItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectItemDefinitionCopyWith<_ProjectItemDefinition> get copyWith => __$ProjectItemDefinitionCopyWithImpl<_ProjectItemDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectItemDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&const DeepCollectionEquality().equals(other._aliases, _aliases)&&(identical(other.pocketId, pocketId) || other.pocketId == pocketId)&&(identical(other.description, description) || other.description == description)&&(identical(other.buyPrice, buyPrice) || other.buyPrice == buyPrice)&&(identical(other.sellPrice, sellPrice) || other.sellPrice == sellPrice)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._uses, _uses)&&(identical(other.capture, capture) || other.capture == capture)&&(identical(other.machine, machine) || other.machine == machine)&&(identical(other.heldEffectId, heldEffectId) || other.heldEffectId == heldEffectId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,const DeepCollectionEquality().hash(_aliases),pocketId,description,buyPrice,sellPrice,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_uses),capture,machine,heldEffectId);

@override
String toString() {
  return 'ProjectItemDefinition(id: $id, displayName: $displayName, aliases: $aliases, pocketId: $pocketId, description: $description, buyPrice: $buyPrice, sellPrice: $sellPrice, tags: $tags, uses: $uses, capture: $capture, machine: $machine, heldEffectId: $heldEffectId)';
}


}

/// @nodoc
abstract mixin class _$ProjectItemDefinitionCopyWith<$Res> implements $ProjectItemDefinitionCopyWith<$Res> {
  factory _$ProjectItemDefinitionCopyWith(_ProjectItemDefinition value, $Res Function(_ProjectItemDefinition) _then) = __$ProjectItemDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, List<String> aliases, String pocketId, String? description, int? buyPrice, int? sellPrice, Set<String> tags, List<ProjectItemUseDefinition> uses, ProjectCaptureItemDefinition? capture, ProjectMoveMachineItemDefinition? machine, String? heldEffectId
});


@override $ProjectCaptureItemDefinitionCopyWith<$Res>? get capture;@override $ProjectMoveMachineItemDefinitionCopyWith<$Res>? get machine;

}
/// @nodoc
class __$ProjectItemDefinitionCopyWithImpl<$Res>
    implements _$ProjectItemDefinitionCopyWith<$Res> {
  __$ProjectItemDefinitionCopyWithImpl(this._self, this._then);

  final _ProjectItemDefinition _self;
  final $Res Function(_ProjectItemDefinition) _then;

/// Create a copy of ProjectItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? aliases = null,Object? pocketId = null,Object? description = freezed,Object? buyPrice = freezed,Object? sellPrice = freezed,Object? tags = null,Object? uses = null,Object? capture = freezed,Object? machine = freezed,Object? heldEffectId = freezed,}) {
  return _then(_ProjectItemDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,pocketId: null == pocketId ? _self.pocketId : pocketId // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,buyPrice: freezed == buyPrice ? _self.buyPrice : buyPrice // ignore: cast_nullable_to_non_nullable
as int?,sellPrice: freezed == sellPrice ? _self.sellPrice : sellPrice // ignore: cast_nullable_to_non_nullable
as int?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as Set<String>,uses: null == uses ? _self._uses : uses // ignore: cast_nullable_to_non_nullable
as List<ProjectItemUseDefinition>,capture: freezed == capture ? _self.capture : capture // ignore: cast_nullable_to_non_nullable
as ProjectCaptureItemDefinition?,machine: freezed == machine ? _self.machine : machine // ignore: cast_nullable_to_non_nullable
as ProjectMoveMachineItemDefinition?,heldEffectId: freezed == heldEffectId ? _self.heldEffectId : heldEffectId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProjectItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCaptureItemDefinitionCopyWith<$Res>? get capture {
    if (_self.capture == null) {
    return null;
  }

  return $ProjectCaptureItemDefinitionCopyWith<$Res>(_self.capture!, (value) {
    return _then(_self.copyWith(capture: value));
  });
}/// Create a copy of ProjectItemDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectMoveMachineItemDefinitionCopyWith<$Res>? get machine {
    if (_self.machine == null) {
    return null;
  }

  return $ProjectMoveMachineItemDefinitionCopyWith<$Res>(_self.machine!, (value) {
    return _then(_self.copyWith(machine: value));
  });
}
}

// dart format on
