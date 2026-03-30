// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'script_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScriptAsset _$ScriptAssetFromJson(Map<String, dynamic> json) {
  return _ScriptAsset.fromJson(json);
}

/// @nodoc
mixin _$ScriptAsset {
  /// Identifiant unique du script.
  String get id => throw _privateConstructorUsedError;

  /// Noeuds du script.
  List<ScriptNode> get nodes => throw _privateConstructorUsedError;

  /// Noeud de démarrage par défaut.
  String get defaultStartNode => throw _privateConstructorUsedError;

  /// Métadonnées (auteur, version, notes).
  Map<String, String> get metadata => throw _privateConstructorUsedError;

  /// Serializes this ScriptAsset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScriptAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScriptAssetCopyWith<ScriptAsset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptAssetCopyWith<$Res> {
  factory $ScriptAssetCopyWith(
          ScriptAsset value, $Res Function(ScriptAsset) then) =
      _$ScriptAssetCopyWithImpl<$Res, ScriptAsset>;
  @useResult
  $Res call(
      {String id,
      List<ScriptNode> nodes,
      String defaultStartNode,
      Map<String, String> metadata});
}

/// @nodoc
class _$ScriptAssetCopyWithImpl<$Res, $Val extends ScriptAsset>
    implements $ScriptAssetCopyWith<$Res> {
  _$ScriptAssetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nodes = null,
    Object? defaultStartNode = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      nodes: null == nodes
          ? _value.nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<ScriptNode>,
      defaultStartNode: null == defaultStartNode
          ? _value.defaultStartNode
          : defaultStartNode // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScriptAssetImplCopyWith<$Res>
    implements $ScriptAssetCopyWith<$Res> {
  factory _$$ScriptAssetImplCopyWith(
          _$ScriptAssetImpl value, $Res Function(_$ScriptAssetImpl) then) =
      __$$ScriptAssetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      List<ScriptNode> nodes,
      String defaultStartNode,
      Map<String, String> metadata});
}

/// @nodoc
class __$$ScriptAssetImplCopyWithImpl<$Res>
    extends _$ScriptAssetCopyWithImpl<$Res, _$ScriptAssetImpl>
    implements _$$ScriptAssetImplCopyWith<$Res> {
  __$$ScriptAssetImplCopyWithImpl(
      _$ScriptAssetImpl _value, $Res Function(_$ScriptAssetImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nodes = null,
    Object? defaultStartNode = null,
    Object? metadata = null,
  }) {
    return _then(_$ScriptAssetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      nodes: null == nodes
          ? _value._nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<ScriptNode>,
      defaultStartNode: null == defaultStartNode
          ? _value.defaultStartNode
          : defaultStartNode // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScriptAssetImpl implements _ScriptAsset {
  const _$ScriptAssetImpl(
      {required this.id,
      required final List<ScriptNode> nodes,
      this.defaultStartNode = 'start',
      final Map<String, String> metadata = const {}})
      : _nodes = nodes,
        _metadata = metadata;

  factory _$ScriptAssetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptAssetImplFromJson(json);

  /// Identifiant unique du script.
  @override
  final String id;

  /// Noeuds du script.
  final List<ScriptNode> _nodes;

  /// Noeuds du script.
  @override
  List<ScriptNode> get nodes {
    if (_nodes is EqualUnmodifiableListView) return _nodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodes);
  }

  /// Noeud de démarrage par défaut.
  @override
  @JsonKey()
  final String defaultStartNode;

  /// Métadonnées (auteur, version, notes).
  final Map<String, String> _metadata;

  /// Métadonnées (auteur, version, notes).
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'ScriptAsset(id: $id, nodes: $nodes, defaultStartNode: $defaultStartNode, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptAssetImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._nodes, _nodes) &&
            (identical(other.defaultStartNode, defaultStartNode) ||
                other.defaultStartNode == defaultStartNode) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_nodes),
      defaultStartNode,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of ScriptAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptAssetImplCopyWith<_$ScriptAssetImpl> get copyWith =>
      __$$ScriptAssetImplCopyWithImpl<_$ScriptAssetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptAssetImplToJson(
      this,
    );
  }
}

abstract class _ScriptAsset implements ScriptAsset {
  const factory _ScriptAsset(
      {required final String id,
      required final List<ScriptNode> nodes,
      final String defaultStartNode,
      final Map<String, String> metadata}) = _$ScriptAssetImpl;

  factory _ScriptAsset.fromJson(Map<String, dynamic> json) =
      _$ScriptAssetImpl.fromJson;

  /// Identifiant unique du script.
  @override
  String get id;

  /// Noeuds du script.
  @override
  List<ScriptNode> get nodes;

  /// Noeud de démarrage par défaut.
  @override
  String get defaultStartNode;

  /// Métadonnées (auteur, version, notes).
  @override
  Map<String, String> get metadata;

  /// Create a copy of ScriptAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptAssetImplCopyWith<_$ScriptAssetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScriptNode _$ScriptNodeFromJson(Map<String, dynamic> json) {
  return _ScriptNode.fromJson(json);
}

/// @nodoc
mixin _$ScriptNode {
  /// Identifiant unique dans le script.
  String get id => throw _privateConstructorUsedError;

  /// Titre optionnel (pour l'éditeur / debug).
  String get title => throw _privateConstructorUsedError;

  /// Commandes à exécuter dans ce noeud.
  List<ScriptCommand> get commands => throw _privateConstructorUsedError;

  /// Identifiant du noeud suivant (optionnel).
  /// Si null, le script se termine après ce noeud.
  String? get nextNodeId => throw _privateConstructorUsedError;

  /// Serializes this ScriptNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScriptNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScriptNodeCopyWith<ScriptNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptNodeCopyWith<$Res> {
  factory $ScriptNodeCopyWith(
          ScriptNode value, $Res Function(ScriptNode) then) =
      _$ScriptNodeCopyWithImpl<$Res, ScriptNode>;
  @useResult
  $Res call(
      {String id,
      String title,
      List<ScriptCommand> commands,
      String? nextNodeId});
}

/// @nodoc
class _$ScriptNodeCopyWithImpl<$Res, $Val extends ScriptNode>
    implements $ScriptNodeCopyWith<$Res> {
  _$ScriptNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? commands = null,
    Object? nextNodeId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      commands: null == commands
          ? _value.commands
          : commands // ignore: cast_nullable_to_non_nullable
              as List<ScriptCommand>,
      nextNodeId: freezed == nextNodeId
          ? _value.nextNodeId
          : nextNodeId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScriptNodeImplCopyWith<$Res>
    implements $ScriptNodeCopyWith<$Res> {
  factory _$$ScriptNodeImplCopyWith(
          _$ScriptNodeImpl value, $Res Function(_$ScriptNodeImpl) then) =
      __$$ScriptNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      List<ScriptCommand> commands,
      String? nextNodeId});
}

/// @nodoc
class __$$ScriptNodeImplCopyWithImpl<$Res>
    extends _$ScriptNodeCopyWithImpl<$Res, _$ScriptNodeImpl>
    implements _$$ScriptNodeImplCopyWith<$Res> {
  __$$ScriptNodeImplCopyWithImpl(
      _$ScriptNodeImpl _value, $Res Function(_$ScriptNodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? commands = null,
    Object? nextNodeId = freezed,
  }) {
    return _then(_$ScriptNodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      commands: null == commands
          ? _value._commands
          : commands // ignore: cast_nullable_to_non_nullable
              as List<ScriptCommand>,
      nextNodeId: freezed == nextNodeId
          ? _value.nextNodeId
          : nextNodeId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScriptNodeImpl implements _ScriptNode {
  const _$ScriptNodeImpl(
      {required this.id,
      this.title = '',
      final List<ScriptCommand> commands = const [],
      this.nextNodeId})
      : _commands = commands;

  factory _$ScriptNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptNodeImplFromJson(json);

  /// Identifiant unique dans le script.
  @override
  final String id;

  /// Titre optionnel (pour l'éditeur / debug).
  @override
  @JsonKey()
  final String title;

  /// Commandes à exécuter dans ce noeud.
  final List<ScriptCommand> _commands;

  /// Commandes à exécuter dans ce noeud.
  @override
  @JsonKey()
  List<ScriptCommand> get commands {
    if (_commands is EqualUnmodifiableListView) return _commands;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_commands);
  }

  /// Identifiant du noeud suivant (optionnel).
  /// Si null, le script se termine après ce noeud.
  @override
  final String? nextNodeId;

  @override
  String toString() {
    return 'ScriptNode(id: $id, title: $title, commands: $commands, nextNodeId: $nextNodeId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptNodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._commands, _commands) &&
            (identical(other.nextNodeId, nextNodeId) ||
                other.nextNodeId == nextNodeId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title,
      const DeepCollectionEquality().hash(_commands), nextNodeId);

  /// Create a copy of ScriptNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptNodeImplCopyWith<_$ScriptNodeImpl> get copyWith =>
      __$$ScriptNodeImplCopyWithImpl<_$ScriptNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptNodeImplToJson(
      this,
    );
  }
}

abstract class _ScriptNode implements ScriptNode {
  const factory _ScriptNode(
      {required final String id,
      final String title,
      final List<ScriptCommand> commands,
      final String? nextNodeId}) = _$ScriptNodeImpl;

  factory _ScriptNode.fromJson(Map<String, dynamic> json) =
      _$ScriptNodeImpl.fromJson;

  /// Identifiant unique dans le script.
  @override
  String get id;

  /// Titre optionnel (pour l'éditeur / debug).
  @override
  String get title;

  /// Commandes à exécuter dans ce noeud.
  @override
  List<ScriptCommand> get commands;

  /// Identifiant du noeud suivant (optionnel).
  /// Si null, le script se termine après ce noeud.
  @override
  String? get nextNodeId;

  /// Create a copy of ScriptNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptNodeImplCopyWith<_$ScriptNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScriptCommand _$ScriptCommandFromJson(Map<String, dynamic> json) {
  return _ScriptCommand.fromJson(json);
}

/// @nodoc
mixin _$ScriptCommand {
  ScriptCommandType get type => throw _privateConstructorUsedError;

  /// Paramètres de la commande (dépend du type).
  Map<String, String> get params => throw _privateConstructorUsedError;

  /// Serializes this ScriptCommand to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScriptCommand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScriptCommandCopyWith<ScriptCommand> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptCommandCopyWith<$Res> {
  factory $ScriptCommandCopyWith(
          ScriptCommand value, $Res Function(ScriptCommand) then) =
      _$ScriptCommandCopyWithImpl<$Res, ScriptCommand>;
  @useResult
  $Res call({ScriptCommandType type, Map<String, String> params});
}

/// @nodoc
class _$ScriptCommandCopyWithImpl<$Res, $Val extends ScriptCommand>
    implements $ScriptCommandCopyWith<$Res> {
  _$ScriptCommandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptCommand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? params = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ScriptCommandType,
      params: null == params
          ? _value.params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScriptCommandImplCopyWith<$Res>
    implements $ScriptCommandCopyWith<$Res> {
  factory _$$ScriptCommandImplCopyWith(
          _$ScriptCommandImpl value, $Res Function(_$ScriptCommandImpl) then) =
      __$$ScriptCommandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ScriptCommandType type, Map<String, String> params});
}

/// @nodoc
class __$$ScriptCommandImplCopyWithImpl<$Res>
    extends _$ScriptCommandCopyWithImpl<$Res, _$ScriptCommandImpl>
    implements _$$ScriptCommandImplCopyWith<$Res> {
  __$$ScriptCommandImplCopyWithImpl(
      _$ScriptCommandImpl _value, $Res Function(_$ScriptCommandImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptCommand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? params = null,
  }) {
    return _then(_$ScriptCommandImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ScriptCommandType,
      params: null == params
          ? _value._params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScriptCommandImpl implements _ScriptCommand {
  const _$ScriptCommandImpl(
      {required this.type, final Map<String, String> params = const {}})
      : _params = params;

  factory _$ScriptCommandImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptCommandImplFromJson(json);

  @override
  final ScriptCommandType type;

  /// Paramètres de la commande (dépend du type).
  final Map<String, String> _params;

  /// Paramètres de la commande (dépend du type).
  @override
  @JsonKey()
  Map<String, String> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  String toString() {
    return 'ScriptCommand(type: $type, params: $params)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptCommandImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._params, _params));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, const DeepCollectionEquality().hash(_params));

  /// Create a copy of ScriptCommand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptCommandImplCopyWith<_$ScriptCommandImpl> get copyWith =>
      __$$ScriptCommandImplCopyWithImpl<_$ScriptCommandImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptCommandImplToJson(
      this,
    );
  }
}

abstract class _ScriptCommand implements ScriptCommand {
  const factory _ScriptCommand(
      {required final ScriptCommandType type,
      final Map<String, String> params}) = _$ScriptCommandImpl;

  factory _ScriptCommand.fromJson(Map<String, dynamic> json) =
      _$ScriptCommandImpl.fromJson;

  @override
  ScriptCommandType get type;

  /// Paramètres de la commande (dépend du type).
  @override
  Map<String, String> get params;

  /// Create a copy of ScriptCommand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptCommandImplCopyWith<_$ScriptCommandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

YarnDialogueRef _$YarnDialogueRefFromJson(Map<String, dynamic> json) {
  return _YarnDialogueRef.fromJson(json);
}

/// @nodoc
mixin _$YarnDialogueRef {
  /// Chemin du fichier .yarn (relatif au projet).
  String get filePath => throw _privateConstructorUsedError;

  /// Noeud de départ dans le fichier.
  /// Si null, utilise le premier noeud.
  String? get startNode => throw _privateConstructorUsedError;

  /// Serializes this YarnDialogueRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of YarnDialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $YarnDialogueRefCopyWith<YarnDialogueRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $YarnDialogueRefCopyWith<$Res> {
  factory $YarnDialogueRefCopyWith(
          YarnDialogueRef value, $Res Function(YarnDialogueRef) then) =
      _$YarnDialogueRefCopyWithImpl<$Res, YarnDialogueRef>;
  @useResult
  $Res call({String filePath, String? startNode});
}

/// @nodoc
class _$YarnDialogueRefCopyWithImpl<$Res, $Val extends YarnDialogueRef>
    implements $YarnDialogueRefCopyWith<$Res> {
  _$YarnDialogueRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of YarnDialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filePath = null,
    Object? startNode = freezed,
  }) {
    return _then(_value.copyWith(
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      startNode: freezed == startNode
          ? _value.startNode
          : startNode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$YarnDialogueRefImplCopyWith<$Res>
    implements $YarnDialogueRefCopyWith<$Res> {
  factory _$$YarnDialogueRefImplCopyWith(_$YarnDialogueRefImpl value,
          $Res Function(_$YarnDialogueRefImpl) then) =
      __$$YarnDialogueRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String filePath, String? startNode});
}

/// @nodoc
class __$$YarnDialogueRefImplCopyWithImpl<$Res>
    extends _$YarnDialogueRefCopyWithImpl<$Res, _$YarnDialogueRefImpl>
    implements _$$YarnDialogueRefImplCopyWith<$Res> {
  __$$YarnDialogueRefImplCopyWithImpl(
      _$YarnDialogueRefImpl _value, $Res Function(_$YarnDialogueRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of YarnDialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filePath = null,
    Object? startNode = freezed,
  }) {
    return _then(_$YarnDialogueRefImpl(
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      startNode: freezed == startNode
          ? _value.startNode
          : startNode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$YarnDialogueRefImpl implements _YarnDialogueRef {
  const _$YarnDialogueRefImpl({required this.filePath, this.startNode});

  factory _$YarnDialogueRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$YarnDialogueRefImplFromJson(json);

  /// Chemin du fichier .yarn (relatif au projet).
  @override
  final String filePath;

  /// Noeud de départ dans le fichier.
  /// Si null, utilise le premier noeud.
  @override
  final String? startNode;

  @override
  String toString() {
    return 'YarnDialogueRef(filePath: $filePath, startNode: $startNode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$YarnDialogueRefImpl &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.startNode, startNode) ||
                other.startNode == startNode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, filePath, startNode);

  /// Create a copy of YarnDialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$YarnDialogueRefImplCopyWith<_$YarnDialogueRefImpl> get copyWith =>
      __$$YarnDialogueRefImplCopyWithImpl<_$YarnDialogueRefImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$YarnDialogueRefImplToJson(
      this,
    );
  }
}

abstract class _YarnDialogueRef implements YarnDialogueRef {
  const factory _YarnDialogueRef(
      {required final String filePath,
      final String? startNode}) = _$YarnDialogueRefImpl;

  factory _YarnDialogueRef.fromJson(Map<String, dynamic> json) =
      _$YarnDialogueRefImpl.fromJson;

  /// Chemin du fichier .yarn (relatif au projet).
  @override
  String get filePath;

  /// Noeud de départ dans le fichier.
  /// Si null, utilise le premier noeud.
  @override
  String? get startNode;

  /// Create a copy of YarnDialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$YarnDialogueRefImplCopyWith<_$YarnDialogueRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
