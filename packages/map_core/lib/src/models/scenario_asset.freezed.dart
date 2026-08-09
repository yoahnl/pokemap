// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScenarioAsset {

 String get id; String get name; String get description;/// Couche fonctionnelle du scénario:
/// - globalStory: progression centrale
/// - localEventFlow: hooks monde locaux
///
/// Cette séparation explicite est la base du modèle story-centric.
 ScenarioScope get scope; String get entryNodeId;/// Liste d'outcomes "métier" déclarés par ce scénario.
///
/// Exemple:
/// - professor_intro.completed
/// - starter.selected.fire
///
/// Objectif: rendre les transitions locales -> globales explicites.
 List<String> get declaredOutcomes;/// Gating optionnel du scénario.
///
/// Si défini, le runtime n'activera ce scénario que lorsque la condition
/// est vraie. Permet au graphe global de piloter l'activation des flows
/// locaux sans dupliquer les règles partout.
 ScriptCondition? get activationCondition; List<ScenarioNode> get nodes; List<ScenarioEdge> get edges; Map<String, String> get metadata;
/// Create a copy of ScenarioAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioAssetCopyWith<ScenarioAsset> get copyWith => _$ScenarioAssetCopyWithImpl<ScenarioAsset>(this as ScenarioAsset, _$identity);

  /// Serializes this ScenarioAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.entryNodeId, entryNodeId) || other.entryNodeId == entryNodeId)&&const DeepCollectionEquality().equals(other.declaredOutcomes, declaredOutcomes)&&(identical(other.activationCondition, activationCondition) || other.activationCondition == activationCondition)&&const DeepCollectionEquality().equals(other.nodes, nodes)&&const DeepCollectionEquality().equals(other.edges, edges)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,scope,entryNodeId,const DeepCollectionEquality().hash(declaredOutcomes),activationCondition,const DeepCollectionEquality().hash(nodes),const DeepCollectionEquality().hash(edges),const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ScenarioAsset(id: $id, name: $name, description: $description, scope: $scope, entryNodeId: $entryNodeId, declaredOutcomes: $declaredOutcomes, activationCondition: $activationCondition, nodes: $nodes, edges: $edges, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ScenarioAssetCopyWith<$Res>  {
  factory $ScenarioAssetCopyWith(ScenarioAsset value, $Res Function(ScenarioAsset) _then) = _$ScenarioAssetCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, ScenarioScope scope, String entryNodeId, List<String> declaredOutcomes, ScriptCondition? activationCondition, List<ScenarioNode> nodes, List<ScenarioEdge> edges, Map<String, String> metadata
});


$ScriptConditionCopyWith<$Res>? get activationCondition;

}
/// @nodoc
class _$ScenarioAssetCopyWithImpl<$Res>
    implements $ScenarioAssetCopyWith<$Res> {
  _$ScenarioAssetCopyWithImpl(this._self, this._then);

  final ScenarioAsset _self;
  final $Res Function(ScenarioAsset) _then;

/// Create a copy of ScenarioAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? scope = null,Object? entryNodeId = null,Object? declaredOutcomes = null,Object? activationCondition = freezed,Object? nodes = null,Object? edges = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as ScenarioScope,entryNodeId: null == entryNodeId ? _self.entryNodeId : entryNodeId // ignore: cast_nullable_to_non_nullable
as String,declaredOutcomes: null == declaredOutcomes ? _self.declaredOutcomes : declaredOutcomes // ignore: cast_nullable_to_non_nullable
as List<String>,activationCondition: freezed == activationCondition ? _self.activationCondition : activationCondition // ignore: cast_nullable_to_non_nullable
as ScriptCondition?,nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<ScenarioNode>,edges: null == edges ? _self.edges : edges // ignore: cast_nullable_to_non_nullable
as List<ScenarioEdge>,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of ScenarioAsset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<$Res>? get activationCondition {
    if (_self.activationCondition == null) {
    return null;
  }

  return $ScriptConditionCopyWith<$Res>(_self.activationCondition!, (value) {
    return _then(_self.copyWith(activationCondition: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScenarioAsset].
extension ScenarioAssetPatterns on ScenarioAsset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioAsset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioAsset value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioAsset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioAsset value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioAsset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  ScenarioScope scope,  String entryNodeId,  List<String> declaredOutcomes,  ScriptCondition? activationCondition,  List<ScenarioNode> nodes,  List<ScenarioEdge> edges,  Map<String, String> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioAsset() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.scope,_that.entryNodeId,_that.declaredOutcomes,_that.activationCondition,_that.nodes,_that.edges,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  ScenarioScope scope,  String entryNodeId,  List<String> declaredOutcomes,  ScriptCondition? activationCondition,  List<ScenarioNode> nodes,  List<ScenarioEdge> edges,  Map<String, String> metadata)  $default,) {final _that = this;
switch (_that) {
case _ScenarioAsset():
return $default(_that.id,_that.name,_that.description,_that.scope,_that.entryNodeId,_that.declaredOutcomes,_that.activationCondition,_that.nodes,_that.edges,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  ScenarioScope scope,  String entryNodeId,  List<String> declaredOutcomes,  ScriptCondition? activationCondition,  List<ScenarioNode> nodes,  List<ScenarioEdge> edges,  Map<String, String> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioAsset() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.scope,_that.entryNodeId,_that.declaredOutcomes,_that.activationCondition,_that.nodes,_that.edges,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScenarioAsset implements ScenarioAsset {
  const _ScenarioAsset({required this.id, required this.name, this.description = '', this.scope = ScenarioScope.localEventFlow, required this.entryNodeId, final  List<String> declaredOutcomes = const <String>[], this.activationCondition, final  List<ScenarioNode> nodes = const <ScenarioNode>[], final  List<ScenarioEdge> edges = const <ScenarioEdge>[], final  Map<String, String> metadata = const {}}): _declaredOutcomes = declaredOutcomes,_nodes = nodes,_edges = edges,_metadata = metadata;
  factory _ScenarioAsset.fromJson(Map<String, dynamic> json) => _$ScenarioAssetFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
/// Couche fonctionnelle du scénario:
/// - globalStory: progression centrale
/// - localEventFlow: hooks monde locaux
///
/// Cette séparation explicite est la base du modèle story-centric.
@override@JsonKey() final  ScenarioScope scope;
@override final  String entryNodeId;
/// Liste d'outcomes "métier" déclarés par ce scénario.
///
/// Exemple:
/// - professor_intro.completed
/// - starter.selected.fire
///
/// Objectif: rendre les transitions locales -> globales explicites.
 final  List<String> _declaredOutcomes;
/// Liste d'outcomes "métier" déclarés par ce scénario.
///
/// Exemple:
/// - professor_intro.completed
/// - starter.selected.fire
///
/// Objectif: rendre les transitions locales -> globales explicites.
@override@JsonKey() List<String> get declaredOutcomes {
  if (_declaredOutcomes is EqualUnmodifiableListView) return _declaredOutcomes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_declaredOutcomes);
}

/// Gating optionnel du scénario.
///
/// Si défini, le runtime n'activera ce scénario que lorsque la condition
/// est vraie. Permet au graphe global de piloter l'activation des flows
/// locaux sans dupliquer les règles partout.
@override final  ScriptCondition? activationCondition;
 final  List<ScenarioNode> _nodes;
@override@JsonKey() List<ScenarioNode> get nodes {
  if (_nodes is EqualUnmodifiableListView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nodes);
}

 final  List<ScenarioEdge> _edges;
@override@JsonKey() List<ScenarioEdge> get edges {
  if (_edges is EqualUnmodifiableListView) return _edges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_edges);
}

 final  Map<String, String> _metadata;
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ScenarioAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioAssetCopyWith<_ScenarioAsset> get copyWith => __$ScenarioAssetCopyWithImpl<_ScenarioAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioAssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.entryNodeId, entryNodeId) || other.entryNodeId == entryNodeId)&&const DeepCollectionEquality().equals(other._declaredOutcomes, _declaredOutcomes)&&(identical(other.activationCondition, activationCondition) || other.activationCondition == activationCondition)&&const DeepCollectionEquality().equals(other._nodes, _nodes)&&const DeepCollectionEquality().equals(other._edges, _edges)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,scope,entryNodeId,const DeepCollectionEquality().hash(_declaredOutcomes),activationCondition,const DeepCollectionEquality().hash(_nodes),const DeepCollectionEquality().hash(_edges),const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ScenarioAsset(id: $id, name: $name, description: $description, scope: $scope, entryNodeId: $entryNodeId, declaredOutcomes: $declaredOutcomes, activationCondition: $activationCondition, nodes: $nodes, edges: $edges, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ScenarioAssetCopyWith<$Res> implements $ScenarioAssetCopyWith<$Res> {
  factory _$ScenarioAssetCopyWith(_ScenarioAsset value, $Res Function(_ScenarioAsset) _then) = __$ScenarioAssetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, ScenarioScope scope, String entryNodeId, List<String> declaredOutcomes, ScriptCondition? activationCondition, List<ScenarioNode> nodes, List<ScenarioEdge> edges, Map<String, String> metadata
});


@override $ScriptConditionCopyWith<$Res>? get activationCondition;

}
/// @nodoc
class __$ScenarioAssetCopyWithImpl<$Res>
    implements _$ScenarioAssetCopyWith<$Res> {
  __$ScenarioAssetCopyWithImpl(this._self, this._then);

  final _ScenarioAsset _self;
  final $Res Function(_ScenarioAsset) _then;

/// Create a copy of ScenarioAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? scope = null,Object? entryNodeId = null,Object? declaredOutcomes = null,Object? activationCondition = freezed,Object? nodes = null,Object? edges = null,Object? metadata = null,}) {
  return _then(_ScenarioAsset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as ScenarioScope,entryNodeId: null == entryNodeId ? _self.entryNodeId : entryNodeId // ignore: cast_nullable_to_non_nullable
as String,declaredOutcomes: null == declaredOutcomes ? _self._declaredOutcomes : declaredOutcomes // ignore: cast_nullable_to_non_nullable
as List<String>,activationCondition: freezed == activationCondition ? _self.activationCondition : activationCondition // ignore: cast_nullable_to_non_nullable
as ScriptCondition?,nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<ScenarioNode>,edges: null == edges ? _self._edges : edges // ignore: cast_nullable_to_non_nullable
as List<ScenarioEdge>,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of ScenarioAsset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<$Res>? get activationCondition {
    if (_self.activationCondition == null) {
    return null;
  }

  return $ScriptConditionCopyWith<$Res>(_self.activationCondition!, (value) {
    return _then(_self.copyWith(activationCondition: value));
  });
}
}


/// @nodoc
mixin _$ScenarioNode {

 String get id; ScenarioNodeType get type; String get title; String get description; ScenarioNodePosition get position; ScenarioNodeBinding get binding; ScenarioNodePayload get payload; Map<String, String> get metadata;
/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioNodeCopyWith<ScenarioNode> get copyWith => _$ScenarioNodeCopyWithImpl<ScenarioNode>(this as ScenarioNode, _$identity);

  /// Serializes this ScenarioNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioNode&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.position, position) || other.position == position)&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.payload, payload) || other.payload == payload)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,description,position,binding,payload,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ScenarioNode(id: $id, type: $type, title: $title, description: $description, position: $position, binding: $binding, payload: $payload, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ScenarioNodeCopyWith<$Res>  {
  factory $ScenarioNodeCopyWith(ScenarioNode value, $Res Function(ScenarioNode) _then) = _$ScenarioNodeCopyWithImpl;
@useResult
$Res call({
 String id, ScenarioNodeType type, String title, String description, ScenarioNodePosition position, ScenarioNodeBinding binding, ScenarioNodePayload payload, Map<String, String> metadata
});


$ScenarioNodePositionCopyWith<$Res> get position;$ScenarioNodeBindingCopyWith<$Res> get binding;$ScenarioNodePayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$ScenarioNodeCopyWithImpl<$Res>
    implements $ScenarioNodeCopyWith<$Res> {
  _$ScenarioNodeCopyWithImpl(this._self, this._then);

  final ScenarioNode _self;
  final $Res Function(ScenarioNode) _then;

/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? description = null,Object? position = null,Object? binding = null,Object? payload = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ScenarioNodeType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as ScenarioNodePosition,binding: null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as ScenarioNodeBinding,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ScenarioNodePayload,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScenarioNodePositionCopyWith<$Res> get position {

  return $ScenarioNodePositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScenarioNodeBindingCopyWith<$Res> get binding {

  return $ScenarioNodeBindingCopyWith<$Res>(_self.binding, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScenarioNodePayloadCopyWith<$Res> get payload {

  return $ScenarioNodePayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScenarioNode].
extension ScenarioNodePatterns on ScenarioNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioNode value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioNode value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ScenarioNodeType type,  String title,  String description,  ScenarioNodePosition position,  ScenarioNodeBinding binding,  ScenarioNodePayload payload,  Map<String, String> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioNode() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.description,_that.position,_that.binding,_that.payload,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ScenarioNodeType type,  String title,  String description,  ScenarioNodePosition position,  ScenarioNodeBinding binding,  ScenarioNodePayload payload,  Map<String, String> metadata)  $default,) {final _that = this;
switch (_that) {
case _ScenarioNode():
return $default(_that.id,_that.type,_that.title,_that.description,_that.position,_that.binding,_that.payload,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ScenarioNodeType type,  String title,  String description,  ScenarioNodePosition position,  ScenarioNodeBinding binding,  ScenarioNodePayload payload,  Map<String, String> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioNode() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.description,_that.position,_that.binding,_that.payload,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScenarioNode implements ScenarioNode {
  const _ScenarioNode({required this.id, this.type = ScenarioNodeType.action, this.title = '', this.description = '', this.position = const ScenarioNodePosition(x: 0, y: 0), this.binding = const ScenarioNodeBinding(), this.payload = const ScenarioNodePayload(), final  Map<String, String> metadata = const {}}): _metadata = metadata;
  factory _ScenarioNode.fromJson(Map<String, dynamic> json) => _$ScenarioNodeFromJson(json);

@override final  String id;
@override@JsonKey() final  ScenarioNodeType type;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  ScenarioNodePosition position;
@override@JsonKey() final  ScenarioNodeBinding binding;
@override@JsonKey() final  ScenarioNodePayload payload;
 final  Map<String, String> _metadata;
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioNodeCopyWith<_ScenarioNode> get copyWith => __$ScenarioNodeCopyWithImpl<_ScenarioNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioNode&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.position, position) || other.position == position)&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.payload, payload) || other.payload == payload)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,description,position,binding,payload,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ScenarioNode(id: $id, type: $type, title: $title, description: $description, position: $position, binding: $binding, payload: $payload, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ScenarioNodeCopyWith<$Res> implements $ScenarioNodeCopyWith<$Res> {
  factory _$ScenarioNodeCopyWith(_ScenarioNode value, $Res Function(_ScenarioNode) _then) = __$ScenarioNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, ScenarioNodeType type, String title, String description, ScenarioNodePosition position, ScenarioNodeBinding binding, ScenarioNodePayload payload, Map<String, String> metadata
});


@override $ScenarioNodePositionCopyWith<$Res> get position;@override $ScenarioNodeBindingCopyWith<$Res> get binding;@override $ScenarioNodePayloadCopyWith<$Res> get payload;

}
/// @nodoc
class __$ScenarioNodeCopyWithImpl<$Res>
    implements _$ScenarioNodeCopyWith<$Res> {
  __$ScenarioNodeCopyWithImpl(this._self, this._then);

  final _ScenarioNode _self;
  final $Res Function(_ScenarioNode) _then;

/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? description = null,Object? position = null,Object? binding = null,Object? payload = null,Object? metadata = null,}) {
  return _then(_ScenarioNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ScenarioNodeType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as ScenarioNodePosition,binding: null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as ScenarioNodeBinding,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as ScenarioNodePayload,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScenarioNodePositionCopyWith<$Res> get position {

  return $ScenarioNodePositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScenarioNodeBindingCopyWith<$Res> get binding {

  return $ScenarioNodeBindingCopyWith<$Res>(_self.binding, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of ScenarioNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScenarioNodePayloadCopyWith<$Res> get payload {

  return $ScenarioNodePayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}


/// @nodoc
mixin _$ScenarioNodePosition {

 double get x; double get y;
/// Create a copy of ScenarioNodePosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioNodePositionCopyWith<ScenarioNodePosition> get copyWith => _$ScenarioNodePositionCopyWithImpl<ScenarioNodePosition>(this as ScenarioNodePosition, _$identity);

  /// Serializes this ScenarioNodePosition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioNodePosition&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'ScenarioNodePosition(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $ScenarioNodePositionCopyWith<$Res>  {
  factory $ScenarioNodePositionCopyWith(ScenarioNodePosition value, $Res Function(ScenarioNodePosition) _then) = _$ScenarioNodePositionCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$ScenarioNodePositionCopyWithImpl<$Res>
    implements $ScenarioNodePositionCopyWith<$Res> {
  _$ScenarioNodePositionCopyWithImpl(this._self, this._then);

  final ScenarioNodePosition _self;
  final $Res Function(ScenarioNodePosition) _then;

/// Create a copy of ScenarioNodePosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ScenarioNodePosition].
extension ScenarioNodePositionPatterns on ScenarioNodePosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioNodePosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioNodePosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioNodePosition value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioNodePosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioNodePosition value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioNodePosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioNodePosition() when $default != null:
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y)  $default,) {final _that = this;
switch (_that) {
case _ScenarioNodePosition():
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioNodePosition() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScenarioNodePosition implements ScenarioNodePosition {
  const _ScenarioNodePosition({required this.x, required this.y});
  factory _ScenarioNodePosition.fromJson(Map<String, dynamic> json) => _$ScenarioNodePositionFromJson(json);

@override final  double x;
@override final  double y;

/// Create a copy of ScenarioNodePosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioNodePositionCopyWith<_ScenarioNodePosition> get copyWith => __$ScenarioNodePositionCopyWithImpl<_ScenarioNodePosition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioNodePositionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioNodePosition&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'ScenarioNodePosition(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$ScenarioNodePositionCopyWith<$Res> implements $ScenarioNodePositionCopyWith<$Res> {
  factory _$ScenarioNodePositionCopyWith(_ScenarioNodePosition value, $Res Function(_ScenarioNodePosition) _then) = __$ScenarioNodePositionCopyWithImpl;
@override @useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class __$ScenarioNodePositionCopyWithImpl<$Res>
    implements _$ScenarioNodePositionCopyWith<$Res> {
  __$ScenarioNodePositionCopyWithImpl(this._self, this._then);

  final _ScenarioNodePosition _self;
  final $Res Function(_ScenarioNodePosition) _then;

/// Create a copy of ScenarioNodePosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_ScenarioNodePosition(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ScenarioNodeBinding {

 String? get mapId; String? get eventId; String? get entityId; String? get warpId; String? get triggerId; String? get trainerId; String? get dialogueId; String? get scriptId;/// Identifiant d'outcome explicite.
///
/// Utilisé notamment par:
/// - sourceOutcome (consommation côté global)
/// - emitOutcome (production côté local)
 String? get outcomeId; String? get flagName; String? get variableName;
/// Create a copy of ScenarioNodeBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioNodeBindingCopyWith<ScenarioNodeBinding> get copyWith => _$ScenarioNodeBindingCopyWithImpl<ScenarioNodeBinding>(this as ScenarioNodeBinding, _$identity);

  /// Serializes this ScenarioNodeBinding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioNodeBinding&&(identical(other.mapId, mapId) || other.mapId == mapId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.warpId, warpId) || other.warpId == warpId)&&(identical(other.triggerId, triggerId) || other.triggerId == triggerId)&&(identical(other.trainerId, trainerId) || other.trainerId == trainerId)&&(identical(other.dialogueId, dialogueId) || other.dialogueId == dialogueId)&&(identical(other.scriptId, scriptId) || other.scriptId == scriptId)&&(identical(other.outcomeId, outcomeId) || other.outcomeId == outcomeId)&&(identical(other.flagName, flagName) || other.flagName == flagName)&&(identical(other.variableName, variableName) || other.variableName == variableName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mapId,eventId,entityId,warpId,triggerId,trainerId,dialogueId,scriptId,outcomeId,flagName,variableName);

@override
String toString() {
  return 'ScenarioNodeBinding(mapId: $mapId, eventId: $eventId, entityId: $entityId, warpId: $warpId, triggerId: $triggerId, trainerId: $trainerId, dialogueId: $dialogueId, scriptId: $scriptId, outcomeId: $outcomeId, flagName: $flagName, variableName: $variableName)';
}


}

/// @nodoc
abstract mixin class $ScenarioNodeBindingCopyWith<$Res>  {
  factory $ScenarioNodeBindingCopyWith(ScenarioNodeBinding value, $Res Function(ScenarioNodeBinding) _then) = _$ScenarioNodeBindingCopyWithImpl;
@useResult
$Res call({
 String? mapId, String? eventId, String? entityId, String? warpId, String? triggerId, String? trainerId, String? dialogueId, String? scriptId, String? outcomeId, String? flagName, String? variableName
});




}
/// @nodoc
class _$ScenarioNodeBindingCopyWithImpl<$Res>
    implements $ScenarioNodeBindingCopyWith<$Res> {
  _$ScenarioNodeBindingCopyWithImpl(this._self, this._then);

  final ScenarioNodeBinding _self;
  final $Res Function(ScenarioNodeBinding) _then;

/// Create a copy of ScenarioNodeBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mapId = freezed,Object? eventId = freezed,Object? entityId = freezed,Object? warpId = freezed,Object? triggerId = freezed,Object? trainerId = freezed,Object? dialogueId = freezed,Object? scriptId = freezed,Object? outcomeId = freezed,Object? flagName = freezed,Object? variableName = freezed,}) {
  return _then(_self.copyWith(
mapId: freezed == mapId ? _self.mapId : mapId // ignore: cast_nullable_to_non_nullable
as String?,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,warpId: freezed == warpId ? _self.warpId : warpId // ignore: cast_nullable_to_non_nullable
as String?,triggerId: freezed == triggerId ? _self.triggerId : triggerId // ignore: cast_nullable_to_non_nullable
as String?,trainerId: freezed == trainerId ? _self.trainerId : trainerId // ignore: cast_nullable_to_non_nullable
as String?,dialogueId: freezed == dialogueId ? _self.dialogueId : dialogueId // ignore: cast_nullable_to_non_nullable
as String?,scriptId: freezed == scriptId ? _self.scriptId : scriptId // ignore: cast_nullable_to_non_nullable
as String?,outcomeId: freezed == outcomeId ? _self.outcomeId : outcomeId // ignore: cast_nullable_to_non_nullable
as String?,flagName: freezed == flagName ? _self.flagName : flagName // ignore: cast_nullable_to_non_nullable
as String?,variableName: freezed == variableName ? _self.variableName : variableName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScenarioNodeBinding].
extension ScenarioNodeBindingPatterns on ScenarioNodeBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioNodeBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioNodeBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioNodeBinding value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioNodeBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioNodeBinding value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioNodeBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? mapId,  String? eventId,  String? entityId,  String? warpId,  String? triggerId,  String? trainerId,  String? dialogueId,  String? scriptId,  String? outcomeId,  String? flagName,  String? variableName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioNodeBinding() when $default != null:
return $default(_that.mapId,_that.eventId,_that.entityId,_that.warpId,_that.triggerId,_that.trainerId,_that.dialogueId,_that.scriptId,_that.outcomeId,_that.flagName,_that.variableName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? mapId,  String? eventId,  String? entityId,  String? warpId,  String? triggerId,  String? trainerId,  String? dialogueId,  String? scriptId,  String? outcomeId,  String? flagName,  String? variableName)  $default,) {final _that = this;
switch (_that) {
case _ScenarioNodeBinding():
return $default(_that.mapId,_that.eventId,_that.entityId,_that.warpId,_that.triggerId,_that.trainerId,_that.dialogueId,_that.scriptId,_that.outcomeId,_that.flagName,_that.variableName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? mapId,  String? eventId,  String? entityId,  String? warpId,  String? triggerId,  String? trainerId,  String? dialogueId,  String? scriptId,  String? outcomeId,  String? flagName,  String? variableName)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioNodeBinding() when $default != null:
return $default(_that.mapId,_that.eventId,_that.entityId,_that.warpId,_that.triggerId,_that.trainerId,_that.dialogueId,_that.scriptId,_that.outcomeId,_that.flagName,_that.variableName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScenarioNodeBinding implements ScenarioNodeBinding {
  const _ScenarioNodeBinding({this.mapId, this.eventId, this.entityId, this.warpId, this.triggerId, this.trainerId, this.dialogueId, this.scriptId, this.outcomeId, this.flagName, this.variableName});
  factory _ScenarioNodeBinding.fromJson(Map<String, dynamic> json) => _$ScenarioNodeBindingFromJson(json);

@override final  String? mapId;
@override final  String? eventId;
@override final  String? entityId;
@override final  String? warpId;
@override final  String? triggerId;
@override final  String? trainerId;
@override final  String? dialogueId;
@override final  String? scriptId;
/// Identifiant d'outcome explicite.
///
/// Utilisé notamment par:
/// - sourceOutcome (consommation côté global)
/// - emitOutcome (production côté local)
@override final  String? outcomeId;
@override final  String? flagName;
@override final  String? variableName;

/// Create a copy of ScenarioNodeBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioNodeBindingCopyWith<_ScenarioNodeBinding> get copyWith => __$ScenarioNodeBindingCopyWithImpl<_ScenarioNodeBinding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioNodeBindingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioNodeBinding&&(identical(other.mapId, mapId) || other.mapId == mapId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.warpId, warpId) || other.warpId == warpId)&&(identical(other.triggerId, triggerId) || other.triggerId == triggerId)&&(identical(other.trainerId, trainerId) || other.trainerId == trainerId)&&(identical(other.dialogueId, dialogueId) || other.dialogueId == dialogueId)&&(identical(other.scriptId, scriptId) || other.scriptId == scriptId)&&(identical(other.outcomeId, outcomeId) || other.outcomeId == outcomeId)&&(identical(other.flagName, flagName) || other.flagName == flagName)&&(identical(other.variableName, variableName) || other.variableName == variableName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mapId,eventId,entityId,warpId,triggerId,trainerId,dialogueId,scriptId,outcomeId,flagName,variableName);

@override
String toString() {
  return 'ScenarioNodeBinding(mapId: $mapId, eventId: $eventId, entityId: $entityId, warpId: $warpId, triggerId: $triggerId, trainerId: $trainerId, dialogueId: $dialogueId, scriptId: $scriptId, outcomeId: $outcomeId, flagName: $flagName, variableName: $variableName)';
}


}

/// @nodoc
abstract mixin class _$ScenarioNodeBindingCopyWith<$Res> implements $ScenarioNodeBindingCopyWith<$Res> {
  factory _$ScenarioNodeBindingCopyWith(_ScenarioNodeBinding value, $Res Function(_ScenarioNodeBinding) _then) = __$ScenarioNodeBindingCopyWithImpl;
@override @useResult
$Res call({
 String? mapId, String? eventId, String? entityId, String? warpId, String? triggerId, String? trainerId, String? dialogueId, String? scriptId, String? outcomeId, String? flagName, String? variableName
});




}
/// @nodoc
class __$ScenarioNodeBindingCopyWithImpl<$Res>
    implements _$ScenarioNodeBindingCopyWith<$Res> {
  __$ScenarioNodeBindingCopyWithImpl(this._self, this._then);

  final _ScenarioNodeBinding _self;
  final $Res Function(_ScenarioNodeBinding) _then;

/// Create a copy of ScenarioNodeBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mapId = freezed,Object? eventId = freezed,Object? entityId = freezed,Object? warpId = freezed,Object? triggerId = freezed,Object? trainerId = freezed,Object? dialogueId = freezed,Object? scriptId = freezed,Object? outcomeId = freezed,Object? flagName = freezed,Object? variableName = freezed,}) {
  return _then(_ScenarioNodeBinding(
mapId: freezed == mapId ? _self.mapId : mapId // ignore: cast_nullable_to_non_nullable
as String?,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,warpId: freezed == warpId ? _self.warpId : warpId // ignore: cast_nullable_to_non_nullable
as String?,triggerId: freezed == triggerId ? _self.triggerId : triggerId // ignore: cast_nullable_to_non_nullable
as String?,trainerId: freezed == trainerId ? _self.trainerId : trainerId // ignore: cast_nullable_to_non_nullable
as String?,dialogueId: freezed == dialogueId ? _self.dialogueId : dialogueId // ignore: cast_nullable_to_non_nullable
as String?,scriptId: freezed == scriptId ? _self.scriptId : scriptId // ignore: cast_nullable_to_non_nullable
as String?,outcomeId: freezed == outcomeId ? _self.outcomeId : outcomeId // ignore: cast_nullable_to_non_nullable
as String?,flagName: freezed == flagName ? _self.flagName : flagName // ignore: cast_nullable_to_non_nullable
as String?,variableName: freezed == variableName ? _self.variableName : variableName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ScenarioNodePayload {

 String? get actionKind; String? get message; ScriptCondition? get condition; List<String> get choiceLabels; Map<String, String> get params;
/// Create a copy of ScenarioNodePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioNodePayloadCopyWith<ScenarioNodePayload> get copyWith => _$ScenarioNodePayloadCopyWithImpl<ScenarioNodePayload>(this as ScenarioNodePayload, _$identity);

  /// Serializes this ScenarioNodePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioNodePayload&&(identical(other.actionKind, actionKind) || other.actionKind == actionKind)&&(identical(other.message, message) || other.message == message)&&(identical(other.condition, condition) || other.condition == condition)&&const DeepCollectionEquality().equals(other.choiceLabels, choiceLabels)&&const DeepCollectionEquality().equals(other.params, params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionKind,message,condition,const DeepCollectionEquality().hash(choiceLabels),const DeepCollectionEquality().hash(params));

@override
String toString() {
  return 'ScenarioNodePayload(actionKind: $actionKind, message: $message, condition: $condition, choiceLabels: $choiceLabels, params: $params)';
}


}

/// @nodoc
abstract mixin class $ScenarioNodePayloadCopyWith<$Res>  {
  factory $ScenarioNodePayloadCopyWith(ScenarioNodePayload value, $Res Function(ScenarioNodePayload) _then) = _$ScenarioNodePayloadCopyWithImpl;
@useResult
$Res call({
 String? actionKind, String? message, ScriptCondition? condition, List<String> choiceLabels, Map<String, String> params
});


$ScriptConditionCopyWith<$Res>? get condition;

}
/// @nodoc
class _$ScenarioNodePayloadCopyWithImpl<$Res>
    implements $ScenarioNodePayloadCopyWith<$Res> {
  _$ScenarioNodePayloadCopyWithImpl(this._self, this._then);

  final ScenarioNodePayload _self;
  final $Res Function(ScenarioNodePayload) _then;

/// Create a copy of ScenarioNodePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actionKind = freezed,Object? message = freezed,Object? condition = freezed,Object? choiceLabels = null,Object? params = null,}) {
  return _then(_self.copyWith(
actionKind: freezed == actionKind ? _self.actionKind : actionKind // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ScriptCondition?,choiceLabels: null == choiceLabels ? _self.choiceLabels : choiceLabels // ignore: cast_nullable_to_non_nullable
as List<String>,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of ScenarioNodePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<$Res>? get condition {
    if (_self.condition == null) {
    return null;
  }

  return $ScriptConditionCopyWith<$Res>(_self.condition!, (value) {
    return _then(_self.copyWith(condition: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScenarioNodePayload].
extension ScenarioNodePayloadPatterns on ScenarioNodePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioNodePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioNodePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioNodePayload value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioNodePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioNodePayload value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioNodePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? actionKind,  String? message,  ScriptCondition? condition,  List<String> choiceLabels,  Map<String, String> params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioNodePayload() when $default != null:
return $default(_that.actionKind,_that.message,_that.condition,_that.choiceLabels,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? actionKind,  String? message,  ScriptCondition? condition,  List<String> choiceLabels,  Map<String, String> params)  $default,) {final _that = this;
switch (_that) {
case _ScenarioNodePayload():
return $default(_that.actionKind,_that.message,_that.condition,_that.choiceLabels,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? actionKind,  String? message,  ScriptCondition? condition,  List<String> choiceLabels,  Map<String, String> params)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioNodePayload() when $default != null:
return $default(_that.actionKind,_that.message,_that.condition,_that.choiceLabels,_that.params);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScenarioNodePayload implements ScenarioNodePayload {
  const _ScenarioNodePayload({this.actionKind, this.message, this.condition, final  List<String> choiceLabels = const <String>[], final  Map<String, String> params = const {}}): _choiceLabels = choiceLabels,_params = params;
  factory _ScenarioNodePayload.fromJson(Map<String, dynamic> json) => _$ScenarioNodePayloadFromJson(json);

@override final  String? actionKind;
@override final  String? message;
@override final  ScriptCondition? condition;
 final  List<String> _choiceLabels;
@override@JsonKey() List<String> get choiceLabels {
  if (_choiceLabels is EqualUnmodifiableListView) return _choiceLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choiceLabels);
}

 final  Map<String, String> _params;
@override@JsonKey() Map<String, String> get params {
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_params);
}


/// Create a copy of ScenarioNodePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioNodePayloadCopyWith<_ScenarioNodePayload> get copyWith => __$ScenarioNodePayloadCopyWithImpl<_ScenarioNodePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioNodePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioNodePayload&&(identical(other.actionKind, actionKind) || other.actionKind == actionKind)&&(identical(other.message, message) || other.message == message)&&(identical(other.condition, condition) || other.condition == condition)&&const DeepCollectionEquality().equals(other._choiceLabels, _choiceLabels)&&const DeepCollectionEquality().equals(other._params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionKind,message,condition,const DeepCollectionEquality().hash(_choiceLabels),const DeepCollectionEquality().hash(_params));

@override
String toString() {
  return 'ScenarioNodePayload(actionKind: $actionKind, message: $message, condition: $condition, choiceLabels: $choiceLabels, params: $params)';
}


}

/// @nodoc
abstract mixin class _$ScenarioNodePayloadCopyWith<$Res> implements $ScenarioNodePayloadCopyWith<$Res> {
  factory _$ScenarioNodePayloadCopyWith(_ScenarioNodePayload value, $Res Function(_ScenarioNodePayload) _then) = __$ScenarioNodePayloadCopyWithImpl;
@override @useResult
$Res call({
 String? actionKind, String? message, ScriptCondition? condition, List<String> choiceLabels, Map<String, String> params
});


@override $ScriptConditionCopyWith<$Res>? get condition;

}
/// @nodoc
class __$ScenarioNodePayloadCopyWithImpl<$Res>
    implements _$ScenarioNodePayloadCopyWith<$Res> {
  __$ScenarioNodePayloadCopyWithImpl(this._self, this._then);

  final _ScenarioNodePayload _self;
  final $Res Function(_ScenarioNodePayload) _then;

/// Create a copy of ScenarioNodePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actionKind = freezed,Object? message = freezed,Object? condition = freezed,Object? choiceLabels = null,Object? params = null,}) {
  return _then(_ScenarioNodePayload(
actionKind: freezed == actionKind ? _self.actionKind : actionKind // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ScriptCondition?,choiceLabels: null == choiceLabels ? _self._choiceLabels : choiceLabels // ignore: cast_nullable_to_non_nullable
as List<String>,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of ScenarioNodePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<$Res>? get condition {
    if (_self.condition == null) {
    return null;
  }

  return $ScriptConditionCopyWith<$Res>(_self.condition!, (value) {
    return _then(_self.copyWith(condition: value));
  });
}
}


/// @nodoc
mixin _$ScenarioEdge {

 String get id; String get fromNodeId; String get toNodeId; String get label; ScenarioEdgeKind get kind; int get order; Map<String, String> get metadata;
/// Create a copy of ScenarioEdge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioEdgeCopyWith<ScenarioEdge> get copyWith => _$ScenarioEdgeCopyWithImpl<ScenarioEdge>(this as ScenarioEdge, _$identity);

  /// Serializes this ScenarioEdge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioEdge&&(identical(other.id, id) || other.id == id)&&(identical(other.fromNodeId, fromNodeId) || other.fromNodeId == fromNodeId)&&(identical(other.toNodeId, toNodeId) || other.toNodeId == toNodeId)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromNodeId,toNodeId,label,kind,order,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ScenarioEdge(id: $id, fromNodeId: $fromNodeId, toNodeId: $toNodeId, label: $label, kind: $kind, order: $order, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ScenarioEdgeCopyWith<$Res>  {
  factory $ScenarioEdgeCopyWith(ScenarioEdge value, $Res Function(ScenarioEdge) _then) = _$ScenarioEdgeCopyWithImpl;
@useResult
$Res call({
 String id, String fromNodeId, String toNodeId, String label, ScenarioEdgeKind kind, int order, Map<String, String> metadata
});




}
/// @nodoc
class _$ScenarioEdgeCopyWithImpl<$Res>
    implements $ScenarioEdgeCopyWith<$Res> {
  _$ScenarioEdgeCopyWithImpl(this._self, this._then);

  final ScenarioEdge _self;
  final $Res Function(ScenarioEdge) _then;

/// Create a copy of ScenarioEdge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromNodeId = null,Object? toNodeId = null,Object? label = null,Object? kind = null,Object? order = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromNodeId: null == fromNodeId ? _self.fromNodeId : fromNodeId // ignore: cast_nullable_to_non_nullable
as String,toNodeId: null == toNodeId ? _self.toNodeId : toNodeId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ScenarioEdgeKind,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScenarioEdge].
extension ScenarioEdgePatterns on ScenarioEdge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioEdge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioEdge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioEdge value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioEdge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioEdge value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioEdge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fromNodeId,  String toNodeId,  String label,  ScenarioEdgeKind kind,  int order,  Map<String, String> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioEdge() when $default != null:
return $default(_that.id,_that.fromNodeId,_that.toNodeId,_that.label,_that.kind,_that.order,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fromNodeId,  String toNodeId,  String label,  ScenarioEdgeKind kind,  int order,  Map<String, String> metadata)  $default,) {final _that = this;
switch (_that) {
case _ScenarioEdge():
return $default(_that.id,_that.fromNodeId,_that.toNodeId,_that.label,_that.kind,_that.order,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fromNodeId,  String toNodeId,  String label,  ScenarioEdgeKind kind,  int order,  Map<String, String> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioEdge() when $default != null:
return $default(_that.id,_that.fromNodeId,_that.toNodeId,_that.label,_that.kind,_that.order,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScenarioEdge implements ScenarioEdge {
  const _ScenarioEdge({required this.id, required this.fromNodeId, required this.toNodeId, this.label = '', this.kind = ScenarioEdgeKind.next, this.order = 0, final  Map<String, String> metadata = const {}}): _metadata = metadata;
  factory _ScenarioEdge.fromJson(Map<String, dynamic> json) => _$ScenarioEdgeFromJson(json);

@override final  String id;
@override final  String fromNodeId;
@override final  String toNodeId;
@override@JsonKey() final  String label;
@override@JsonKey() final  ScenarioEdgeKind kind;
@override@JsonKey() final  int order;
 final  Map<String, String> _metadata;
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ScenarioEdge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioEdgeCopyWith<_ScenarioEdge> get copyWith => __$ScenarioEdgeCopyWithImpl<_ScenarioEdge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioEdgeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioEdge&&(identical(other.id, id) || other.id == id)&&(identical(other.fromNodeId, fromNodeId) || other.fromNodeId == fromNodeId)&&(identical(other.toNodeId, toNodeId) || other.toNodeId == toNodeId)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromNodeId,toNodeId,label,kind,order,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ScenarioEdge(id: $id, fromNodeId: $fromNodeId, toNodeId: $toNodeId, label: $label, kind: $kind, order: $order, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ScenarioEdgeCopyWith<$Res> implements $ScenarioEdgeCopyWith<$Res> {
  factory _$ScenarioEdgeCopyWith(_ScenarioEdge value, $Res Function(_ScenarioEdge) _then) = __$ScenarioEdgeCopyWithImpl;
@override @useResult
$Res call({
 String id, String fromNodeId, String toNodeId, String label, ScenarioEdgeKind kind, int order, Map<String, String> metadata
});




}
/// @nodoc
class __$ScenarioEdgeCopyWithImpl<$Res>
    implements _$ScenarioEdgeCopyWith<$Res> {
  __$ScenarioEdgeCopyWithImpl(this._self, this._then);

  final _ScenarioEdge _self;
  final $Res Function(_ScenarioEdge) _then;

/// Create a copy of ScenarioEdge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromNodeId = null,Object? toNodeId = null,Object? label = null,Object? kind = null,Object? order = null,Object? metadata = null,}) {
  return _then(_ScenarioEdge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromNodeId: null == fromNodeId ? _self.fromNodeId : fromNodeId // ignore: cast_nullable_to_non_nullable
as String,toNodeId: null == toNodeId ? _self.toNodeId : toNodeId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ScenarioEdgeKind,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
