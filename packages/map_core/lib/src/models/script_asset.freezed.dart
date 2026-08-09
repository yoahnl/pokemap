// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'script_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScriptAsset {

/// Identifiant unique du script.
 String get id;/// Noeuds du script.
 List<ScriptNode> get nodes;/// Noeud de démarrage par défaut.
 String get defaultStartNode;/// Métadonnées (auteur, version, notes).
 Map<String, String> get metadata;
/// Create a copy of ScriptAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptAssetCopyWith<ScriptAsset> get copyWith => _$ScriptAssetCopyWithImpl<ScriptAsset>(this as ScriptAsset, _$identity);

  /// Serializes this ScriptAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptAsset&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.nodes, nodes)&&(identical(other.defaultStartNode, defaultStartNode) || other.defaultStartNode == defaultStartNode)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(nodes),defaultStartNode,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ScriptAsset(id: $id, nodes: $nodes, defaultStartNode: $defaultStartNode, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ScriptAssetCopyWith<$Res>  {
  factory $ScriptAssetCopyWith(ScriptAsset value, $Res Function(ScriptAsset) _then) = _$ScriptAssetCopyWithImpl;
@useResult
$Res call({
 String id, List<ScriptNode> nodes, String defaultStartNode, Map<String, String> metadata
});




}
/// @nodoc
class _$ScriptAssetCopyWithImpl<$Res>
    implements $ScriptAssetCopyWith<$Res> {
  _$ScriptAssetCopyWithImpl(this._self, this._then);

  final ScriptAsset _self;
  final $Res Function(ScriptAsset) _then;

/// Create a copy of ScriptAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nodes = null,Object? defaultStartNode = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<ScriptNode>,defaultStartNode: null == defaultStartNode ? _self.defaultStartNode : defaultStartNode // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScriptAsset].
extension ScriptAssetPatterns on ScriptAsset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScriptAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScriptAsset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScriptAsset value)  $default,){
final _that = this;
switch (_that) {
case _ScriptAsset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScriptAsset value)?  $default,){
final _that = this;
switch (_that) {
case _ScriptAsset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<ScriptNode> nodes,  String defaultStartNode,  Map<String, String> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScriptAsset() when $default != null:
return $default(_that.id,_that.nodes,_that.defaultStartNode,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<ScriptNode> nodes,  String defaultStartNode,  Map<String, String> metadata)  $default,) {final _that = this;
switch (_that) {
case _ScriptAsset():
return $default(_that.id,_that.nodes,_that.defaultStartNode,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<ScriptNode> nodes,  String defaultStartNode,  Map<String, String> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ScriptAsset() when $default != null:
return $default(_that.id,_that.nodes,_that.defaultStartNode,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScriptAsset implements ScriptAsset {
  const _ScriptAsset({required this.id, required final  List<ScriptNode> nodes, this.defaultStartNode = 'start', final  Map<String, String> metadata = const {}}): _nodes = nodes,_metadata = metadata;
  factory _ScriptAsset.fromJson(Map<String, dynamic> json) => _$ScriptAssetFromJson(json);

/// Identifiant unique du script.
@override final  String id;
/// Noeuds du script.
 final  List<ScriptNode> _nodes;
/// Noeuds du script.
@override List<ScriptNode> get nodes {
  if (_nodes is EqualUnmodifiableListView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nodes);
}

/// Noeud de démarrage par défaut.
@override@JsonKey() final  String defaultStartNode;
/// Métadonnées (auteur, version, notes).
 final  Map<String, String> _metadata;
/// Métadonnées (auteur, version, notes).
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ScriptAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScriptAssetCopyWith<_ScriptAsset> get copyWith => __$ScriptAssetCopyWithImpl<_ScriptAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptAssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScriptAsset&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._nodes, _nodes)&&(identical(other.defaultStartNode, defaultStartNode) || other.defaultStartNode == defaultStartNode)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_nodes),defaultStartNode,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ScriptAsset(id: $id, nodes: $nodes, defaultStartNode: $defaultStartNode, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ScriptAssetCopyWith<$Res> implements $ScriptAssetCopyWith<$Res> {
  factory _$ScriptAssetCopyWith(_ScriptAsset value, $Res Function(_ScriptAsset) _then) = __$ScriptAssetCopyWithImpl;
@override @useResult
$Res call({
 String id, List<ScriptNode> nodes, String defaultStartNode, Map<String, String> metadata
});




}
/// @nodoc
class __$ScriptAssetCopyWithImpl<$Res>
    implements _$ScriptAssetCopyWith<$Res> {
  __$ScriptAssetCopyWithImpl(this._self, this._then);

  final _ScriptAsset _self;
  final $Res Function(_ScriptAsset) _then;

/// Create a copy of ScriptAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nodes = null,Object? defaultStartNode = null,Object? metadata = null,}) {
  return _then(_ScriptAsset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<ScriptNode>,defaultStartNode: null == defaultStartNode ? _self.defaultStartNode : defaultStartNode // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$ScriptNode {

/// Identifiant unique dans le script.
 String get id;/// Titre optionnel (pour l'éditeur / debug).
 String get title;/// Commandes à exécuter dans ce noeud.
 List<ScriptCommand> get commands;/// Identifiant du noeud suivant (optionnel).
/// Si null, le script se termine après ce noeud.
 String? get nextNodeId;
/// Create a copy of ScriptNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptNodeCopyWith<ScriptNode> get copyWith => _$ScriptNodeCopyWithImpl<ScriptNode>(this as ScriptNode, _$identity);

  /// Serializes this ScriptNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptNode&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.commands, commands)&&(identical(other.nextNodeId, nextNodeId) || other.nextNodeId == nextNodeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(commands),nextNodeId);

@override
String toString() {
  return 'ScriptNode(id: $id, title: $title, commands: $commands, nextNodeId: $nextNodeId)';
}


}

/// @nodoc
abstract mixin class $ScriptNodeCopyWith<$Res>  {
  factory $ScriptNodeCopyWith(ScriptNode value, $Res Function(ScriptNode) _then) = _$ScriptNodeCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<ScriptCommand> commands, String? nextNodeId
});




}
/// @nodoc
class _$ScriptNodeCopyWithImpl<$Res>
    implements $ScriptNodeCopyWith<$Res> {
  _$ScriptNodeCopyWithImpl(this._self, this._then);

  final ScriptNode _self;
  final $Res Function(ScriptNode) _then;

/// Create a copy of ScriptNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? commands = null,Object? nextNodeId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,commands: null == commands ? _self.commands : commands // ignore: cast_nullable_to_non_nullable
as List<ScriptCommand>,nextNodeId: freezed == nextNodeId ? _self.nextNodeId : nextNodeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScriptNode].
extension ScriptNodePatterns on ScriptNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScriptNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScriptNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScriptNode value)  $default,){
final _that = this;
switch (_that) {
case _ScriptNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScriptNode value)?  $default,){
final _that = this;
switch (_that) {
case _ScriptNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<ScriptCommand> commands,  String? nextNodeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScriptNode() when $default != null:
return $default(_that.id,_that.title,_that.commands,_that.nextNodeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<ScriptCommand> commands,  String? nextNodeId)  $default,) {final _that = this;
switch (_that) {
case _ScriptNode():
return $default(_that.id,_that.title,_that.commands,_that.nextNodeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<ScriptCommand> commands,  String? nextNodeId)?  $default,) {final _that = this;
switch (_that) {
case _ScriptNode() when $default != null:
return $default(_that.id,_that.title,_that.commands,_that.nextNodeId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScriptNode implements ScriptNode {
  const _ScriptNode({required this.id, this.title = '', final  List<ScriptCommand> commands = const [], this.nextNodeId}): _commands = commands;
  factory _ScriptNode.fromJson(Map<String, dynamic> json) => _$ScriptNodeFromJson(json);

/// Identifiant unique dans le script.
@override final  String id;
/// Titre optionnel (pour l'éditeur / debug).
@override@JsonKey() final  String title;
/// Commandes à exécuter dans ce noeud.
 final  List<ScriptCommand> _commands;
/// Commandes à exécuter dans ce noeud.
@override@JsonKey() List<ScriptCommand> get commands {
  if (_commands is EqualUnmodifiableListView) return _commands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_commands);
}

/// Identifiant du noeud suivant (optionnel).
/// Si null, le script se termine après ce noeud.
@override final  String? nextNodeId;

/// Create a copy of ScriptNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScriptNodeCopyWith<_ScriptNode> get copyWith => __$ScriptNodeCopyWithImpl<_ScriptNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScriptNode&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._commands, _commands)&&(identical(other.nextNodeId, nextNodeId) || other.nextNodeId == nextNodeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_commands),nextNodeId);

@override
String toString() {
  return 'ScriptNode(id: $id, title: $title, commands: $commands, nextNodeId: $nextNodeId)';
}


}

/// @nodoc
abstract mixin class _$ScriptNodeCopyWith<$Res> implements $ScriptNodeCopyWith<$Res> {
  factory _$ScriptNodeCopyWith(_ScriptNode value, $Res Function(_ScriptNode) _then) = __$ScriptNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<ScriptCommand> commands, String? nextNodeId
});




}
/// @nodoc
class __$ScriptNodeCopyWithImpl<$Res>
    implements _$ScriptNodeCopyWith<$Res> {
  __$ScriptNodeCopyWithImpl(this._self, this._then);

  final _ScriptNode _self;
  final $Res Function(_ScriptNode) _then;

/// Create a copy of ScriptNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? commands = null,Object? nextNodeId = freezed,}) {
  return _then(_ScriptNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,commands: null == commands ? _self._commands : commands // ignore: cast_nullable_to_non_nullable
as List<ScriptCommand>,nextNodeId: freezed == nextNodeId ? _self.nextNodeId : nextNodeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ScriptCommand {

 ScriptCommandType get type;/// Paramètres de la commande (dépend du type).
 Map<String, String> get params;
/// Create a copy of ScriptCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptCommandCopyWith<ScriptCommand> get copyWith => _$ScriptCommandCopyWithImpl<ScriptCommand>(this as ScriptCommand, _$identity);

  /// Serializes this ScriptCommand to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptCommand&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.params, params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(params));

@override
String toString() {
  return 'ScriptCommand(type: $type, params: $params)';
}


}

/// @nodoc
abstract mixin class $ScriptCommandCopyWith<$Res>  {
  factory $ScriptCommandCopyWith(ScriptCommand value, $Res Function(ScriptCommand) _then) = _$ScriptCommandCopyWithImpl;
@useResult
$Res call({
 ScriptCommandType type, Map<String, String> params
});




}
/// @nodoc
class _$ScriptCommandCopyWithImpl<$Res>
    implements $ScriptCommandCopyWith<$Res> {
  _$ScriptCommandCopyWithImpl(this._self, this._then);

  final ScriptCommand _self;
  final $Res Function(ScriptCommand) _then;

/// Create a copy of ScriptCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? params = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ScriptCommandType,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScriptCommand].
extension ScriptCommandPatterns on ScriptCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScriptCommand value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScriptCommand() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScriptCommand value)  $default,){
final _that = this;
switch (_that) {
case _ScriptCommand():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScriptCommand value)?  $default,){
final _that = this;
switch (_that) {
case _ScriptCommand() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScriptCommandType type,  Map<String, String> params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScriptCommand() when $default != null:
return $default(_that.type,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScriptCommandType type,  Map<String, String> params)  $default,) {final _that = this;
switch (_that) {
case _ScriptCommand():
return $default(_that.type,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScriptCommandType type,  Map<String, String> params)?  $default,) {final _that = this;
switch (_that) {
case _ScriptCommand() when $default != null:
return $default(_that.type,_that.params);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScriptCommand implements ScriptCommand {
  const _ScriptCommand({required this.type, final  Map<String, String> params = const {}}): _params = params;
  factory _ScriptCommand.fromJson(Map<String, dynamic> json) => _$ScriptCommandFromJson(json);

@override final  ScriptCommandType type;
/// Paramètres de la commande (dépend du type).
 final  Map<String, String> _params;
/// Paramètres de la commande (dépend du type).
@override@JsonKey() Map<String, String> get params {
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_params);
}


/// Create a copy of ScriptCommand
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScriptCommandCopyWith<_ScriptCommand> get copyWith => __$ScriptCommandCopyWithImpl<_ScriptCommand>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptCommandToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScriptCommand&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_params));

@override
String toString() {
  return 'ScriptCommand(type: $type, params: $params)';
}


}

/// @nodoc
abstract mixin class _$ScriptCommandCopyWith<$Res> implements $ScriptCommandCopyWith<$Res> {
  factory _$ScriptCommandCopyWith(_ScriptCommand value, $Res Function(_ScriptCommand) _then) = __$ScriptCommandCopyWithImpl;
@override @useResult
$Res call({
 ScriptCommandType type, Map<String, String> params
});




}
/// @nodoc
class __$ScriptCommandCopyWithImpl<$Res>
    implements _$ScriptCommandCopyWith<$Res> {
  __$ScriptCommandCopyWithImpl(this._self, this._then);

  final _ScriptCommand _self;
  final $Res Function(_ScriptCommand) _then;

/// Create a copy of ScriptCommand
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? params = null,}) {
  return _then(_ScriptCommand(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ScriptCommandType,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$YarnDialogueRef {

/// Chemin du fichier .yarn (relatif au projet).
 String get filePath;/// Noeud de départ dans le fichier.
/// Si null, utilise le premier noeud.
 String? get startNode;
/// Create a copy of YarnDialogueRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YarnDialogueRefCopyWith<YarnDialogueRef> get copyWith => _$YarnDialogueRefCopyWithImpl<YarnDialogueRef>(this as YarnDialogueRef, _$identity);

  /// Serializes this YarnDialogueRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YarnDialogueRef&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.startNode, startNode) || other.startNode == startNode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,filePath,startNode);

@override
String toString() {
  return 'YarnDialogueRef(filePath: $filePath, startNode: $startNode)';
}


}

/// @nodoc
abstract mixin class $YarnDialogueRefCopyWith<$Res>  {
  factory $YarnDialogueRefCopyWith(YarnDialogueRef value, $Res Function(YarnDialogueRef) _then) = _$YarnDialogueRefCopyWithImpl;
@useResult
$Res call({
 String filePath, String? startNode
});




}
/// @nodoc
class _$YarnDialogueRefCopyWithImpl<$Res>
    implements $YarnDialogueRefCopyWith<$Res> {
  _$YarnDialogueRefCopyWithImpl(this._self, this._then);

  final YarnDialogueRef _self;
  final $Res Function(YarnDialogueRef) _then;

/// Create a copy of YarnDialogueRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filePath = null,Object? startNode = freezed,}) {
  return _then(_self.copyWith(
filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,startNode: freezed == startNode ? _self.startNode : startNode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [YarnDialogueRef].
extension YarnDialogueRefPatterns on YarnDialogueRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YarnDialogueRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YarnDialogueRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YarnDialogueRef value)  $default,){
final _that = this;
switch (_that) {
case _YarnDialogueRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YarnDialogueRef value)?  $default,){
final _that = this;
switch (_that) {
case _YarnDialogueRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String filePath,  String? startNode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YarnDialogueRef() when $default != null:
return $default(_that.filePath,_that.startNode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String filePath,  String? startNode)  $default,) {final _that = this;
switch (_that) {
case _YarnDialogueRef():
return $default(_that.filePath,_that.startNode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String filePath,  String? startNode)?  $default,) {final _that = this;
switch (_that) {
case _YarnDialogueRef() when $default != null:
return $default(_that.filePath,_that.startNode);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _YarnDialogueRef implements YarnDialogueRef {
  const _YarnDialogueRef({required this.filePath, this.startNode});
  factory _YarnDialogueRef.fromJson(Map<String, dynamic> json) => _$YarnDialogueRefFromJson(json);

/// Chemin du fichier .yarn (relatif au projet).
@override final  String filePath;
/// Noeud de départ dans le fichier.
/// Si null, utilise le premier noeud.
@override final  String? startNode;

/// Create a copy of YarnDialogueRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YarnDialogueRefCopyWith<_YarnDialogueRef> get copyWith => __$YarnDialogueRefCopyWithImpl<_YarnDialogueRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YarnDialogueRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YarnDialogueRef&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.startNode, startNode) || other.startNode == startNode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,filePath,startNode);

@override
String toString() {
  return 'YarnDialogueRef(filePath: $filePath, startNode: $startNode)';
}


}

/// @nodoc
abstract mixin class _$YarnDialogueRefCopyWith<$Res> implements $YarnDialogueRefCopyWith<$Res> {
  factory _$YarnDialogueRefCopyWith(_YarnDialogueRef value, $Res Function(_YarnDialogueRef) _then) = __$YarnDialogueRefCopyWithImpl;
@override @useResult
$Res call({
 String filePath, String? startNode
});




}
/// @nodoc
class __$YarnDialogueRefCopyWithImpl<$Res>
    implements _$YarnDialogueRefCopyWith<$Res> {
  __$YarnDialogueRefCopyWithImpl(this._self, this._then);

  final _YarnDialogueRef _self;
  final $Res Function(_YarnDialogueRef) _then;

/// Create a copy of YarnDialogueRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filePath = null,Object? startNode = freezed,}) {
  return _then(_YarnDialogueRef(
filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,startNode: freezed == startNode ? _self.startNode : startNode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
