// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScenarioAsset _$ScenarioAssetFromJson(Map<String, dynamic> json) {
  return _ScenarioAsset.fromJson(json);
}

/// @nodoc
mixin _$ScenarioAsset {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Couche fonctionnelle du scénario:
  /// - globalStory: progression centrale
  /// - localEventFlow: hooks monde locaux
  ///
  /// Cette séparation explicite est la base du modèle story-centric.
  ScenarioScope get scope => throw _privateConstructorUsedError;
  String get entryNodeId => throw _privateConstructorUsedError;

  /// Liste d'outcomes "métier" déclarés par ce scénario.
  ///
  /// Exemple:
  /// - professor_intro.completed
  /// - starter.selected.fire
  ///
  /// Objectif: rendre les transitions locales -> globales explicites.
  List<String> get declaredOutcomes => throw _privateConstructorUsedError;

  /// Gating optionnel du scénario.
  ///
  /// Si défini, le runtime n'activera ce scénario que lorsque la condition
  /// est vraie. Permet au graphe global de piloter l'activation des flows
  /// locaux sans dupliquer les règles partout.
  ScriptCondition? get activationCondition =>
      throw _privateConstructorUsedError;
  List<ScenarioNode> get nodes => throw _privateConstructorUsedError;
  List<ScenarioEdge> get edges => throw _privateConstructorUsedError;
  Map<String, String> get metadata => throw _privateConstructorUsedError;

  /// Serializes this ScenarioAsset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScenarioAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScenarioAssetCopyWith<ScenarioAsset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioAssetCopyWith<$Res> {
  factory $ScenarioAssetCopyWith(
          ScenarioAsset value, $Res Function(ScenarioAsset) then) =
      _$ScenarioAssetCopyWithImpl<$Res, ScenarioAsset>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      ScenarioScope scope,
      String entryNodeId,
      List<String> declaredOutcomes,
      ScriptCondition? activationCondition,
      List<ScenarioNode> nodes,
      List<ScenarioEdge> edges,
      Map<String, String> metadata});

  $ScriptConditionCopyWith<$Res>? get activationCondition;
}

/// @nodoc
class _$ScenarioAssetCopyWithImpl<$Res, $Val extends ScenarioAsset>
    implements $ScenarioAssetCopyWith<$Res> {
  _$ScenarioAssetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScenarioAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? scope = null,
    Object? entryNodeId = null,
    Object? declaredOutcomes = null,
    Object? activationCondition = freezed,
    Object? nodes = null,
    Object? edges = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as ScenarioScope,
      entryNodeId: null == entryNodeId
          ? _value.entryNodeId
          : entryNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      declaredOutcomes: null == declaredOutcomes
          ? _value.declaredOutcomes
          : declaredOutcomes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activationCondition: freezed == activationCondition
          ? _value.activationCondition
          : activationCondition // ignore: cast_nullable_to_non_nullable
              as ScriptCondition?,
      nodes: null == nodes
          ? _value.nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<ScenarioNode>,
      edges: null == edges
          ? _value.edges
          : edges // ignore: cast_nullable_to_non_nullable
              as List<ScenarioEdge>,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of ScenarioAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptConditionCopyWith<$Res>? get activationCondition {
    if (_value.activationCondition == null) {
      return null;
    }

    return $ScriptConditionCopyWith<$Res>(_value.activationCondition!, (value) {
      return _then(_value.copyWith(activationCondition: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ScenarioAssetImplCopyWith<$Res>
    implements $ScenarioAssetCopyWith<$Res> {
  factory _$$ScenarioAssetImplCopyWith(
          _$ScenarioAssetImpl value, $Res Function(_$ScenarioAssetImpl) then) =
      __$$ScenarioAssetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      ScenarioScope scope,
      String entryNodeId,
      List<String> declaredOutcomes,
      ScriptCondition? activationCondition,
      List<ScenarioNode> nodes,
      List<ScenarioEdge> edges,
      Map<String, String> metadata});

  @override
  $ScriptConditionCopyWith<$Res>? get activationCondition;
}

/// @nodoc
class __$$ScenarioAssetImplCopyWithImpl<$Res>
    extends _$ScenarioAssetCopyWithImpl<$Res, _$ScenarioAssetImpl>
    implements _$$ScenarioAssetImplCopyWith<$Res> {
  __$$ScenarioAssetImplCopyWithImpl(
      _$ScenarioAssetImpl _value, $Res Function(_$ScenarioAssetImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScenarioAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? scope = null,
    Object? entryNodeId = null,
    Object? declaredOutcomes = null,
    Object? activationCondition = freezed,
    Object? nodes = null,
    Object? edges = null,
    Object? metadata = null,
  }) {
    return _then(_$ScenarioAssetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as ScenarioScope,
      entryNodeId: null == entryNodeId
          ? _value.entryNodeId
          : entryNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      declaredOutcomes: null == declaredOutcomes
          ? _value._declaredOutcomes
          : declaredOutcomes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activationCondition: freezed == activationCondition
          ? _value.activationCondition
          : activationCondition // ignore: cast_nullable_to_non_nullable
              as ScriptCondition?,
      nodes: null == nodes
          ? _value._nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<ScenarioNode>,
      edges: null == edges
          ? _value._edges
          : edges // ignore: cast_nullable_to_non_nullable
              as List<ScenarioEdge>,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScenarioAssetImpl implements _ScenarioAsset {
  const _$ScenarioAssetImpl(
      {required this.id,
      required this.name,
      this.description = '',
      this.scope = ScenarioScope.localEventFlow,
      required this.entryNodeId,
      final List<String> declaredOutcomes = const <String>[],
      this.activationCondition,
      final List<ScenarioNode> nodes = const <ScenarioNode>[],
      final List<ScenarioEdge> edges = const <ScenarioEdge>[],
      final Map<String, String> metadata = const {}})
      : _declaredOutcomes = declaredOutcomes,
        _nodes = nodes,
        _edges = edges,
        _metadata = metadata;

  factory _$ScenarioAssetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioAssetImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String description;

  /// Couche fonctionnelle du scénario:
  /// - globalStory: progression centrale
  /// - localEventFlow: hooks monde locaux
  ///
  /// Cette séparation explicite est la base du modèle story-centric.
  @override
  @JsonKey()
  final ScenarioScope scope;
  @override
  final String entryNodeId;

  /// Liste d'outcomes "métier" déclarés par ce scénario.
  ///
  /// Exemple:
  /// - professor_intro.completed
  /// - starter.selected.fire
  ///
  /// Objectif: rendre les transitions locales -> globales explicites.
  final List<String> _declaredOutcomes;

  /// Liste d'outcomes "métier" déclarés par ce scénario.
  ///
  /// Exemple:
  /// - professor_intro.completed
  /// - starter.selected.fire
  ///
  /// Objectif: rendre les transitions locales -> globales explicites.
  @override
  @JsonKey()
  List<String> get declaredOutcomes {
    if (_declaredOutcomes is EqualUnmodifiableListView)
      return _declaredOutcomes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_declaredOutcomes);
  }

  /// Gating optionnel du scénario.
  ///
  /// Si défini, le runtime n'activera ce scénario que lorsque la condition
  /// est vraie. Permet au graphe global de piloter l'activation des flows
  /// locaux sans dupliquer les règles partout.
  @override
  final ScriptCondition? activationCondition;
  final List<ScenarioNode> _nodes;
  @override
  @JsonKey()
  List<ScenarioNode> get nodes {
    if (_nodes is EqualUnmodifiableListView) return _nodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodes);
  }

  final List<ScenarioEdge> _edges;
  @override
  @JsonKey()
  List<ScenarioEdge> get edges {
    if (_edges is EqualUnmodifiableListView) return _edges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_edges);
  }

  final Map<String, String> _metadata;
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'ScenarioAsset(id: $id, name: $name, description: $description, scope: $scope, entryNodeId: $entryNodeId, declaredOutcomes: $declaredOutcomes, activationCondition: $activationCondition, nodes: $nodes, edges: $edges, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioAssetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.entryNodeId, entryNodeId) ||
                other.entryNodeId == entryNodeId) &&
            const DeepCollectionEquality()
                .equals(other._declaredOutcomes, _declaredOutcomes) &&
            (identical(other.activationCondition, activationCondition) ||
                other.activationCondition == activationCondition) &&
            const DeepCollectionEquality().equals(other._nodes, _nodes) &&
            const DeepCollectionEquality().equals(other._edges, _edges) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      scope,
      entryNodeId,
      const DeepCollectionEquality().hash(_declaredOutcomes),
      activationCondition,
      const DeepCollectionEquality().hash(_nodes),
      const DeepCollectionEquality().hash(_edges),
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of ScenarioAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioAssetImplCopyWith<_$ScenarioAssetImpl> get copyWith =>
      __$$ScenarioAssetImplCopyWithImpl<_$ScenarioAssetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioAssetImplToJson(
      this,
    );
  }
}

abstract class _ScenarioAsset implements ScenarioAsset {
  const factory _ScenarioAsset(
      {required final String id,
      required final String name,
      final String description,
      final ScenarioScope scope,
      required final String entryNodeId,
      final List<String> declaredOutcomes,
      final ScriptCondition? activationCondition,
      final List<ScenarioNode> nodes,
      final List<ScenarioEdge> edges,
      final Map<String, String> metadata}) = _$ScenarioAssetImpl;

  factory _ScenarioAsset.fromJson(Map<String, dynamic> json) =
      _$ScenarioAssetImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;

  /// Couche fonctionnelle du scénario:
  /// - globalStory: progression centrale
  /// - localEventFlow: hooks monde locaux
  ///
  /// Cette séparation explicite est la base du modèle story-centric.
  @override
  ScenarioScope get scope;
  @override
  String get entryNodeId;

  /// Liste d'outcomes "métier" déclarés par ce scénario.
  ///
  /// Exemple:
  /// - professor_intro.completed
  /// - starter.selected.fire
  ///
  /// Objectif: rendre les transitions locales -> globales explicites.
  @override
  List<String> get declaredOutcomes;

  /// Gating optionnel du scénario.
  ///
  /// Si défini, le runtime n'activera ce scénario que lorsque la condition
  /// est vraie. Permet au graphe global de piloter l'activation des flows
  /// locaux sans dupliquer les règles partout.
  @override
  ScriptCondition? get activationCondition;
  @override
  List<ScenarioNode> get nodes;
  @override
  List<ScenarioEdge> get edges;
  @override
  Map<String, String> get metadata;

  /// Create a copy of ScenarioAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioAssetImplCopyWith<_$ScenarioAssetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScenarioNode _$ScenarioNodeFromJson(Map<String, dynamic> json) {
  return _ScenarioNode.fromJson(json);
}

/// @nodoc
mixin _$ScenarioNode {
  String get id => throw _privateConstructorUsedError;
  ScenarioNodeType get type => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  ScenarioNodePosition get position => throw _privateConstructorUsedError;
  ScenarioNodeBinding get binding => throw _privateConstructorUsedError;
  ScenarioNodePayload get payload => throw _privateConstructorUsedError;
  Map<String, String> get metadata => throw _privateConstructorUsedError;

  /// Serializes this ScenarioNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScenarioNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScenarioNodeCopyWith<ScenarioNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioNodeCopyWith<$Res> {
  factory $ScenarioNodeCopyWith(
          ScenarioNode value, $Res Function(ScenarioNode) then) =
      _$ScenarioNodeCopyWithImpl<$Res, ScenarioNode>;
  @useResult
  $Res call(
      {String id,
      ScenarioNodeType type,
      String title,
      String description,
      ScenarioNodePosition position,
      ScenarioNodeBinding binding,
      ScenarioNodePayload payload,
      Map<String, String> metadata});

  $ScenarioNodePositionCopyWith<$Res> get position;
  $ScenarioNodeBindingCopyWith<$Res> get binding;
  $ScenarioNodePayloadCopyWith<$Res> get payload;
}

/// @nodoc
class _$ScenarioNodeCopyWithImpl<$Res, $Val extends ScenarioNode>
    implements $ScenarioNodeCopyWith<$Res> {
  _$ScenarioNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScenarioNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? title = null,
    Object? description = null,
    Object? position = null,
    Object? binding = null,
    Object? payload = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ScenarioNodeType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as ScenarioNodePosition,
      binding: null == binding
          ? _value.binding
          : binding // ignore: cast_nullable_to_non_nullable
              as ScenarioNodeBinding,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as ScenarioNodePayload,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of ScenarioNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScenarioNodePositionCopyWith<$Res> get position {
    return $ScenarioNodePositionCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }

  /// Create a copy of ScenarioNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScenarioNodeBindingCopyWith<$Res> get binding {
    return $ScenarioNodeBindingCopyWith<$Res>(_value.binding, (value) {
      return _then(_value.copyWith(binding: value) as $Val);
    });
  }

  /// Create a copy of ScenarioNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScenarioNodePayloadCopyWith<$Res> get payload {
    return $ScenarioNodePayloadCopyWith<$Res>(_value.payload, (value) {
      return _then(_value.copyWith(payload: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ScenarioNodeImplCopyWith<$Res>
    implements $ScenarioNodeCopyWith<$Res> {
  factory _$$ScenarioNodeImplCopyWith(
          _$ScenarioNodeImpl value, $Res Function(_$ScenarioNodeImpl) then) =
      __$$ScenarioNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      ScenarioNodeType type,
      String title,
      String description,
      ScenarioNodePosition position,
      ScenarioNodeBinding binding,
      ScenarioNodePayload payload,
      Map<String, String> metadata});

  @override
  $ScenarioNodePositionCopyWith<$Res> get position;
  @override
  $ScenarioNodeBindingCopyWith<$Res> get binding;
  @override
  $ScenarioNodePayloadCopyWith<$Res> get payload;
}

/// @nodoc
class __$$ScenarioNodeImplCopyWithImpl<$Res>
    extends _$ScenarioNodeCopyWithImpl<$Res, _$ScenarioNodeImpl>
    implements _$$ScenarioNodeImplCopyWith<$Res> {
  __$$ScenarioNodeImplCopyWithImpl(
      _$ScenarioNodeImpl _value, $Res Function(_$ScenarioNodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScenarioNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? title = null,
    Object? description = null,
    Object? position = null,
    Object? binding = null,
    Object? payload = null,
    Object? metadata = null,
  }) {
    return _then(_$ScenarioNodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ScenarioNodeType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as ScenarioNodePosition,
      binding: null == binding
          ? _value.binding
          : binding // ignore: cast_nullable_to_non_nullable
              as ScenarioNodeBinding,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as ScenarioNodePayload,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScenarioNodeImpl implements _ScenarioNode {
  const _$ScenarioNodeImpl(
      {required this.id,
      this.type = ScenarioNodeType.action,
      this.title = '',
      this.description = '',
      this.position = const ScenarioNodePosition(x: 0, y: 0),
      this.binding = const ScenarioNodeBinding(),
      this.payload = const ScenarioNodePayload(),
      final Map<String, String> metadata = const {}})
      : _metadata = metadata;

  factory _$ScenarioNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioNodeImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final ScenarioNodeType type;
  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final ScenarioNodePosition position;
  @override
  @JsonKey()
  final ScenarioNodeBinding binding;
  @override
  @JsonKey()
  final ScenarioNodePayload payload;
  final Map<String, String> _metadata;
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'ScenarioNode(id: $id, type: $type, title: $title, description: $description, position: $position, binding: $binding, payload: $payload, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioNodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.binding, binding) || other.binding == binding) &&
            (identical(other.payload, payload) || other.payload == payload) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      title,
      description,
      position,
      binding,
      payload,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of ScenarioNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioNodeImplCopyWith<_$ScenarioNodeImpl> get copyWith =>
      __$$ScenarioNodeImplCopyWithImpl<_$ScenarioNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioNodeImplToJson(
      this,
    );
  }
}

abstract class _ScenarioNode implements ScenarioNode {
  const factory _ScenarioNode(
      {required final String id,
      final ScenarioNodeType type,
      final String title,
      final String description,
      final ScenarioNodePosition position,
      final ScenarioNodeBinding binding,
      final ScenarioNodePayload payload,
      final Map<String, String> metadata}) = _$ScenarioNodeImpl;

  factory _ScenarioNode.fromJson(Map<String, dynamic> json) =
      _$ScenarioNodeImpl.fromJson;

  @override
  String get id;
  @override
  ScenarioNodeType get type;
  @override
  String get title;
  @override
  String get description;
  @override
  ScenarioNodePosition get position;
  @override
  ScenarioNodeBinding get binding;
  @override
  ScenarioNodePayload get payload;
  @override
  Map<String, String> get metadata;

  /// Create a copy of ScenarioNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioNodeImplCopyWith<_$ScenarioNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScenarioNodePosition _$ScenarioNodePositionFromJson(Map<String, dynamic> json) {
  return _ScenarioNodePosition.fromJson(json);
}

/// @nodoc
mixin _$ScenarioNodePosition {
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;

  /// Serializes this ScenarioNodePosition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScenarioNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScenarioNodePositionCopyWith<ScenarioNodePosition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioNodePositionCopyWith<$Res> {
  factory $ScenarioNodePositionCopyWith(ScenarioNodePosition value,
          $Res Function(ScenarioNodePosition) then) =
      _$ScenarioNodePositionCopyWithImpl<$Res, ScenarioNodePosition>;
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class _$ScenarioNodePositionCopyWithImpl<$Res,
        $Val extends ScenarioNodePosition>
    implements $ScenarioNodePositionCopyWith<$Res> {
  _$ScenarioNodePositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScenarioNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScenarioNodePositionImplCopyWith<$Res>
    implements $ScenarioNodePositionCopyWith<$Res> {
  factory _$$ScenarioNodePositionImplCopyWith(_$ScenarioNodePositionImpl value,
          $Res Function(_$ScenarioNodePositionImpl) then) =
      __$$ScenarioNodePositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class __$$ScenarioNodePositionImplCopyWithImpl<$Res>
    extends _$ScenarioNodePositionCopyWithImpl<$Res, _$ScenarioNodePositionImpl>
    implements _$$ScenarioNodePositionImplCopyWith<$Res> {
  __$$ScenarioNodePositionImplCopyWithImpl(_$ScenarioNodePositionImpl _value,
      $Res Function(_$ScenarioNodePositionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScenarioNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_$ScenarioNodePositionImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScenarioNodePositionImpl implements _ScenarioNodePosition {
  const _$ScenarioNodePositionImpl({required this.x, required this.y});

  factory _$ScenarioNodePositionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioNodePositionImplFromJson(json);

  @override
  final double x;
  @override
  final double y;

  @override
  String toString() {
    return 'ScenarioNodePosition(x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioNodePositionImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y);

  /// Create a copy of ScenarioNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioNodePositionImplCopyWith<_$ScenarioNodePositionImpl>
      get copyWith =>
          __$$ScenarioNodePositionImplCopyWithImpl<_$ScenarioNodePositionImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioNodePositionImplToJson(
      this,
    );
  }
}

abstract class _ScenarioNodePosition implements ScenarioNodePosition {
  const factory _ScenarioNodePosition(
      {required final double x,
      required final double y}) = _$ScenarioNodePositionImpl;

  factory _ScenarioNodePosition.fromJson(Map<String, dynamic> json) =
      _$ScenarioNodePositionImpl.fromJson;

  @override
  double get x;
  @override
  double get y;

  /// Create a copy of ScenarioNodePosition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioNodePositionImplCopyWith<_$ScenarioNodePositionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ScenarioNodeBinding _$ScenarioNodeBindingFromJson(Map<String, dynamic> json) {
  return _ScenarioNodeBinding.fromJson(json);
}

/// @nodoc
mixin _$ScenarioNodeBinding {
  String? get mapId => throw _privateConstructorUsedError;
  String? get eventId => throw _privateConstructorUsedError;
  String? get entityId => throw _privateConstructorUsedError;
  String? get warpId => throw _privateConstructorUsedError;
  String? get triggerId => throw _privateConstructorUsedError;
  String? get trainerId => throw _privateConstructorUsedError;
  String? get dialogueId => throw _privateConstructorUsedError;
  String? get scriptId => throw _privateConstructorUsedError;

  /// Identifiant d'outcome explicite.
  ///
  /// Utilisé notamment par:
  /// - sourceOutcome (consommation côté global)
  /// - emitOutcome (production côté local)
  String? get outcomeId => throw _privateConstructorUsedError;
  String? get flagName => throw _privateConstructorUsedError;
  String? get variableName => throw _privateConstructorUsedError;

  /// Serializes this ScenarioNodeBinding to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScenarioNodeBinding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScenarioNodeBindingCopyWith<ScenarioNodeBinding> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioNodeBindingCopyWith<$Res> {
  factory $ScenarioNodeBindingCopyWith(
          ScenarioNodeBinding value, $Res Function(ScenarioNodeBinding) then) =
      _$ScenarioNodeBindingCopyWithImpl<$Res, ScenarioNodeBinding>;
  @useResult
  $Res call(
      {String? mapId,
      String? eventId,
      String? entityId,
      String? warpId,
      String? triggerId,
      String? trainerId,
      String? dialogueId,
      String? scriptId,
      String? outcomeId,
      String? flagName,
      String? variableName});
}

/// @nodoc
class _$ScenarioNodeBindingCopyWithImpl<$Res, $Val extends ScenarioNodeBinding>
    implements $ScenarioNodeBindingCopyWith<$Res> {
  _$ScenarioNodeBindingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScenarioNodeBinding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mapId = freezed,
    Object? eventId = freezed,
    Object? entityId = freezed,
    Object? warpId = freezed,
    Object? triggerId = freezed,
    Object? trainerId = freezed,
    Object? dialogueId = freezed,
    Object? scriptId = freezed,
    Object? outcomeId = freezed,
    Object? flagName = freezed,
    Object? variableName = freezed,
  }) {
    return _then(_value.copyWith(
      mapId: freezed == mapId
          ? _value.mapId
          : mapId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String?,
      warpId: freezed == warpId
          ? _value.warpId
          : warpId // ignore: cast_nullable_to_non_nullable
              as String?,
      triggerId: freezed == triggerId
          ? _value.triggerId
          : triggerId // ignore: cast_nullable_to_non_nullable
              as String?,
      trainerId: freezed == trainerId
          ? _value.trainerId
          : trainerId // ignore: cast_nullable_to_non_nullable
              as String?,
      dialogueId: freezed == dialogueId
          ? _value.dialogueId
          : dialogueId // ignore: cast_nullable_to_non_nullable
              as String?,
      scriptId: freezed == scriptId
          ? _value.scriptId
          : scriptId // ignore: cast_nullable_to_non_nullable
              as String?,
      outcomeId: freezed == outcomeId
          ? _value.outcomeId
          : outcomeId // ignore: cast_nullable_to_non_nullable
              as String?,
      flagName: freezed == flagName
          ? _value.flagName
          : flagName // ignore: cast_nullable_to_non_nullable
              as String?,
      variableName: freezed == variableName
          ? _value.variableName
          : variableName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScenarioNodeBindingImplCopyWith<$Res>
    implements $ScenarioNodeBindingCopyWith<$Res> {
  factory _$$ScenarioNodeBindingImplCopyWith(_$ScenarioNodeBindingImpl value,
          $Res Function(_$ScenarioNodeBindingImpl) then) =
      __$$ScenarioNodeBindingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? mapId,
      String? eventId,
      String? entityId,
      String? warpId,
      String? triggerId,
      String? trainerId,
      String? dialogueId,
      String? scriptId,
      String? outcomeId,
      String? flagName,
      String? variableName});
}

/// @nodoc
class __$$ScenarioNodeBindingImplCopyWithImpl<$Res>
    extends _$ScenarioNodeBindingCopyWithImpl<$Res, _$ScenarioNodeBindingImpl>
    implements _$$ScenarioNodeBindingImplCopyWith<$Res> {
  __$$ScenarioNodeBindingImplCopyWithImpl(_$ScenarioNodeBindingImpl _value,
      $Res Function(_$ScenarioNodeBindingImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScenarioNodeBinding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mapId = freezed,
    Object? eventId = freezed,
    Object? entityId = freezed,
    Object? warpId = freezed,
    Object? triggerId = freezed,
    Object? trainerId = freezed,
    Object? dialogueId = freezed,
    Object? scriptId = freezed,
    Object? outcomeId = freezed,
    Object? flagName = freezed,
    Object? variableName = freezed,
  }) {
    return _then(_$ScenarioNodeBindingImpl(
      mapId: freezed == mapId
          ? _value.mapId
          : mapId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String?,
      warpId: freezed == warpId
          ? _value.warpId
          : warpId // ignore: cast_nullable_to_non_nullable
              as String?,
      triggerId: freezed == triggerId
          ? _value.triggerId
          : triggerId // ignore: cast_nullable_to_non_nullable
              as String?,
      trainerId: freezed == trainerId
          ? _value.trainerId
          : trainerId // ignore: cast_nullable_to_non_nullable
              as String?,
      dialogueId: freezed == dialogueId
          ? _value.dialogueId
          : dialogueId // ignore: cast_nullable_to_non_nullable
              as String?,
      scriptId: freezed == scriptId
          ? _value.scriptId
          : scriptId // ignore: cast_nullable_to_non_nullable
              as String?,
      outcomeId: freezed == outcomeId
          ? _value.outcomeId
          : outcomeId // ignore: cast_nullable_to_non_nullable
              as String?,
      flagName: freezed == flagName
          ? _value.flagName
          : flagName // ignore: cast_nullable_to_non_nullable
              as String?,
      variableName: freezed == variableName
          ? _value.variableName
          : variableName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScenarioNodeBindingImpl implements _ScenarioNodeBinding {
  const _$ScenarioNodeBindingImpl(
      {this.mapId,
      this.eventId,
      this.entityId,
      this.warpId,
      this.triggerId,
      this.trainerId,
      this.dialogueId,
      this.scriptId,
      this.outcomeId,
      this.flagName,
      this.variableName});

  factory _$ScenarioNodeBindingImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioNodeBindingImplFromJson(json);

  @override
  final String? mapId;
  @override
  final String? eventId;
  @override
  final String? entityId;
  @override
  final String? warpId;
  @override
  final String? triggerId;
  @override
  final String? trainerId;
  @override
  final String? dialogueId;
  @override
  final String? scriptId;

  /// Identifiant d'outcome explicite.
  ///
  /// Utilisé notamment par:
  /// - sourceOutcome (consommation côté global)
  /// - emitOutcome (production côté local)
  @override
  final String? outcomeId;
  @override
  final String? flagName;
  @override
  final String? variableName;

  @override
  String toString() {
    return 'ScenarioNodeBinding(mapId: $mapId, eventId: $eventId, entityId: $entityId, warpId: $warpId, triggerId: $triggerId, trainerId: $trainerId, dialogueId: $dialogueId, scriptId: $scriptId, outcomeId: $outcomeId, flagName: $flagName, variableName: $variableName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioNodeBindingImpl &&
            (identical(other.mapId, mapId) || other.mapId == mapId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.warpId, warpId) || other.warpId == warpId) &&
            (identical(other.triggerId, triggerId) ||
                other.triggerId == triggerId) &&
            (identical(other.trainerId, trainerId) ||
                other.trainerId == trainerId) &&
            (identical(other.dialogueId, dialogueId) ||
                other.dialogueId == dialogueId) &&
            (identical(other.scriptId, scriptId) ||
                other.scriptId == scriptId) &&
            (identical(other.outcomeId, outcomeId) ||
                other.outcomeId == outcomeId) &&
            (identical(other.flagName, flagName) ||
                other.flagName == flagName) &&
            (identical(other.variableName, variableName) ||
                other.variableName == variableName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      mapId,
      eventId,
      entityId,
      warpId,
      triggerId,
      trainerId,
      dialogueId,
      scriptId,
      outcomeId,
      flagName,
      variableName);

  /// Create a copy of ScenarioNodeBinding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioNodeBindingImplCopyWith<_$ScenarioNodeBindingImpl> get copyWith =>
      __$$ScenarioNodeBindingImplCopyWithImpl<_$ScenarioNodeBindingImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioNodeBindingImplToJson(
      this,
    );
  }
}

abstract class _ScenarioNodeBinding implements ScenarioNodeBinding {
  const factory _ScenarioNodeBinding(
      {final String? mapId,
      final String? eventId,
      final String? entityId,
      final String? warpId,
      final String? triggerId,
      final String? trainerId,
      final String? dialogueId,
      final String? scriptId,
      final String? outcomeId,
      final String? flagName,
      final String? variableName}) = _$ScenarioNodeBindingImpl;

  factory _ScenarioNodeBinding.fromJson(Map<String, dynamic> json) =
      _$ScenarioNodeBindingImpl.fromJson;

  @override
  String? get mapId;
  @override
  String? get eventId;
  @override
  String? get entityId;
  @override
  String? get warpId;
  @override
  String? get triggerId;
  @override
  String? get trainerId;
  @override
  String? get dialogueId;
  @override
  String? get scriptId;

  /// Identifiant d'outcome explicite.
  ///
  /// Utilisé notamment par:
  /// - sourceOutcome (consommation côté global)
  /// - emitOutcome (production côté local)
  @override
  String? get outcomeId;
  @override
  String? get flagName;
  @override
  String? get variableName;

  /// Create a copy of ScenarioNodeBinding
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioNodeBindingImplCopyWith<_$ScenarioNodeBindingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScenarioNodePayload _$ScenarioNodePayloadFromJson(Map<String, dynamic> json) {
  return _ScenarioNodePayload.fromJson(json);
}

/// @nodoc
mixin _$ScenarioNodePayload {
  String? get actionKind => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  ScriptCondition? get condition => throw _privateConstructorUsedError;
  List<String> get choiceLabels => throw _privateConstructorUsedError;
  Map<String, String> get params => throw _privateConstructorUsedError;

  /// Serializes this ScenarioNodePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScenarioNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScenarioNodePayloadCopyWith<ScenarioNodePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioNodePayloadCopyWith<$Res> {
  factory $ScenarioNodePayloadCopyWith(
          ScenarioNodePayload value, $Res Function(ScenarioNodePayload) then) =
      _$ScenarioNodePayloadCopyWithImpl<$Res, ScenarioNodePayload>;
  @useResult
  $Res call(
      {String? actionKind,
      String? message,
      ScriptCondition? condition,
      List<String> choiceLabels,
      Map<String, String> params});

  $ScriptConditionCopyWith<$Res>? get condition;
}

/// @nodoc
class _$ScenarioNodePayloadCopyWithImpl<$Res, $Val extends ScenarioNodePayload>
    implements $ScenarioNodePayloadCopyWith<$Res> {
  _$ScenarioNodePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScenarioNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? actionKind = freezed,
    Object? message = freezed,
    Object? condition = freezed,
    Object? choiceLabels = null,
    Object? params = null,
  }) {
    return _then(_value.copyWith(
      actionKind: freezed == actionKind
          ? _value.actionKind
          : actionKind // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      condition: freezed == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as ScriptCondition?,
      choiceLabels: null == choiceLabels
          ? _value.choiceLabels
          : choiceLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      params: null == params
          ? _value.params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of ScenarioNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptConditionCopyWith<$Res>? get condition {
    if (_value.condition == null) {
      return null;
    }

    return $ScriptConditionCopyWith<$Res>(_value.condition!, (value) {
      return _then(_value.copyWith(condition: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ScenarioNodePayloadImplCopyWith<$Res>
    implements $ScenarioNodePayloadCopyWith<$Res> {
  factory _$$ScenarioNodePayloadImplCopyWith(_$ScenarioNodePayloadImpl value,
          $Res Function(_$ScenarioNodePayloadImpl) then) =
      __$$ScenarioNodePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? actionKind,
      String? message,
      ScriptCondition? condition,
      List<String> choiceLabels,
      Map<String, String> params});

  @override
  $ScriptConditionCopyWith<$Res>? get condition;
}

/// @nodoc
class __$$ScenarioNodePayloadImplCopyWithImpl<$Res>
    extends _$ScenarioNodePayloadCopyWithImpl<$Res, _$ScenarioNodePayloadImpl>
    implements _$$ScenarioNodePayloadImplCopyWith<$Res> {
  __$$ScenarioNodePayloadImplCopyWithImpl(_$ScenarioNodePayloadImpl _value,
      $Res Function(_$ScenarioNodePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScenarioNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? actionKind = freezed,
    Object? message = freezed,
    Object? condition = freezed,
    Object? choiceLabels = null,
    Object? params = null,
  }) {
    return _then(_$ScenarioNodePayloadImpl(
      actionKind: freezed == actionKind
          ? _value.actionKind
          : actionKind // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      condition: freezed == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as ScriptCondition?,
      choiceLabels: null == choiceLabels
          ? _value._choiceLabels
          : choiceLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      params: null == params
          ? _value._params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScenarioNodePayloadImpl implements _ScenarioNodePayload {
  const _$ScenarioNodePayloadImpl(
      {this.actionKind,
      this.message,
      this.condition,
      final List<String> choiceLabels = const <String>[],
      final Map<String, String> params = const {}})
      : _choiceLabels = choiceLabels,
        _params = params;

  factory _$ScenarioNodePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioNodePayloadImplFromJson(json);

  @override
  final String? actionKind;
  @override
  final String? message;
  @override
  final ScriptCondition? condition;
  final List<String> _choiceLabels;
  @override
  @JsonKey()
  List<String> get choiceLabels {
    if (_choiceLabels is EqualUnmodifiableListView) return _choiceLabels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_choiceLabels);
  }

  final Map<String, String> _params;
  @override
  @JsonKey()
  Map<String, String> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  String toString() {
    return 'ScenarioNodePayload(actionKind: $actionKind, message: $message, condition: $condition, choiceLabels: $choiceLabels, params: $params)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioNodePayloadImpl &&
            (identical(other.actionKind, actionKind) ||
                other.actionKind == actionKind) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.condition, condition) ||
                other.condition == condition) &&
            const DeepCollectionEquality()
                .equals(other._choiceLabels, _choiceLabels) &&
            const DeepCollectionEquality().equals(other._params, _params));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      actionKind,
      message,
      condition,
      const DeepCollectionEquality().hash(_choiceLabels),
      const DeepCollectionEquality().hash(_params));

  /// Create a copy of ScenarioNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioNodePayloadImplCopyWith<_$ScenarioNodePayloadImpl> get copyWith =>
      __$$ScenarioNodePayloadImplCopyWithImpl<_$ScenarioNodePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioNodePayloadImplToJson(
      this,
    );
  }
}

abstract class _ScenarioNodePayload implements ScenarioNodePayload {
  const factory _ScenarioNodePayload(
      {final String? actionKind,
      final String? message,
      final ScriptCondition? condition,
      final List<String> choiceLabels,
      final Map<String, String> params}) = _$ScenarioNodePayloadImpl;

  factory _ScenarioNodePayload.fromJson(Map<String, dynamic> json) =
      _$ScenarioNodePayloadImpl.fromJson;

  @override
  String? get actionKind;
  @override
  String? get message;
  @override
  ScriptCondition? get condition;
  @override
  List<String> get choiceLabels;
  @override
  Map<String, String> get params;

  /// Create a copy of ScenarioNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioNodePayloadImplCopyWith<_$ScenarioNodePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScenarioEdge _$ScenarioEdgeFromJson(Map<String, dynamic> json) {
  return _ScenarioEdge.fromJson(json);
}

/// @nodoc
mixin _$ScenarioEdge {
  String get id => throw _privateConstructorUsedError;
  String get fromNodeId => throw _privateConstructorUsedError;
  String get toNodeId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  ScenarioEdgeKind get kind => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  Map<String, String> get metadata => throw _privateConstructorUsedError;

  /// Serializes this ScenarioEdge to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScenarioEdge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScenarioEdgeCopyWith<ScenarioEdge> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioEdgeCopyWith<$Res> {
  factory $ScenarioEdgeCopyWith(
          ScenarioEdge value, $Res Function(ScenarioEdge) then) =
      _$ScenarioEdgeCopyWithImpl<$Res, ScenarioEdge>;
  @useResult
  $Res call(
      {String id,
      String fromNodeId,
      String toNodeId,
      String label,
      ScenarioEdgeKind kind,
      int order,
      Map<String, String> metadata});
}

/// @nodoc
class _$ScenarioEdgeCopyWithImpl<$Res, $Val extends ScenarioEdge>
    implements $ScenarioEdgeCopyWith<$Res> {
  _$ScenarioEdgeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScenarioEdge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromNodeId = null,
    Object? toNodeId = null,
    Object? label = null,
    Object? kind = null,
    Object? order = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fromNodeId: null == fromNodeId
          ? _value.fromNodeId
          : fromNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      toNodeId: null == toNodeId
          ? _value.toNodeId
          : toNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as ScenarioEdgeKind,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScenarioEdgeImplCopyWith<$Res>
    implements $ScenarioEdgeCopyWith<$Res> {
  factory _$$ScenarioEdgeImplCopyWith(
          _$ScenarioEdgeImpl value, $Res Function(_$ScenarioEdgeImpl) then) =
      __$$ScenarioEdgeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String fromNodeId,
      String toNodeId,
      String label,
      ScenarioEdgeKind kind,
      int order,
      Map<String, String> metadata});
}

/// @nodoc
class __$$ScenarioEdgeImplCopyWithImpl<$Res>
    extends _$ScenarioEdgeCopyWithImpl<$Res, _$ScenarioEdgeImpl>
    implements _$$ScenarioEdgeImplCopyWith<$Res> {
  __$$ScenarioEdgeImplCopyWithImpl(
      _$ScenarioEdgeImpl _value, $Res Function(_$ScenarioEdgeImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScenarioEdge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromNodeId = null,
    Object? toNodeId = null,
    Object? label = null,
    Object? kind = null,
    Object? order = null,
    Object? metadata = null,
  }) {
    return _then(_$ScenarioEdgeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fromNodeId: null == fromNodeId
          ? _value.fromNodeId
          : fromNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      toNodeId: null == toNodeId
          ? _value.toNodeId
          : toNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as ScenarioEdgeKind,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScenarioEdgeImpl implements _ScenarioEdge {
  const _$ScenarioEdgeImpl(
      {required this.id,
      required this.fromNodeId,
      required this.toNodeId,
      this.label = '',
      this.kind = ScenarioEdgeKind.next,
      this.order = 0,
      final Map<String, String> metadata = const {}})
      : _metadata = metadata;

  factory _$ScenarioEdgeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioEdgeImplFromJson(json);

  @override
  final String id;
  @override
  final String fromNodeId;
  @override
  final String toNodeId;
  @override
  @JsonKey()
  final String label;
  @override
  @JsonKey()
  final ScenarioEdgeKind kind;
  @override
  @JsonKey()
  final int order;
  final Map<String, String> _metadata;
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'ScenarioEdge(id: $id, fromNodeId: $fromNodeId, toNodeId: $toNodeId, label: $label, kind: $kind, order: $order, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioEdgeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromNodeId, fromNodeId) ||
                other.fromNodeId == fromNodeId) &&
            (identical(other.toNodeId, toNodeId) ||
                other.toNodeId == toNodeId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, fromNodeId, toNodeId, label,
      kind, order, const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of ScenarioEdge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioEdgeImplCopyWith<_$ScenarioEdgeImpl> get copyWith =>
      __$$ScenarioEdgeImplCopyWithImpl<_$ScenarioEdgeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioEdgeImplToJson(
      this,
    );
  }
}

abstract class _ScenarioEdge implements ScenarioEdge {
  const factory _ScenarioEdge(
      {required final String id,
      required final String fromNodeId,
      required final String toNodeId,
      final String label,
      final ScenarioEdgeKind kind,
      final int order,
      final Map<String, String> metadata}) = _$ScenarioEdgeImpl;

  factory _ScenarioEdge.fromJson(Map<String, dynamic> json) =
      _$ScenarioEdgeImpl.fromJson;

  @override
  String get id;
  @override
  String get fromNodeId;
  @override
  String get toNodeId;
  @override
  String get label;
  @override
  ScenarioEdgeKind get kind;
  @override
  int get order;
  @override
  Map<String, String> get metadata;

  /// Create a copy of ScenarioEdge
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioEdgeImplCopyWith<_$ScenarioEdgeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
