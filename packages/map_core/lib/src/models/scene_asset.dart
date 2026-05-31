import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'scene_consequence.dart';

enum SceneNodeKind {
  start,
  end,
  yarnDialogue,
  condition,
  action,
  battle,
  cinematic,
  branchByOutcome,
  merge,
}

enum SceneEdgeKind {
  defaultFlow,
  conditionTrue,
  conditionFalse,
  dialogueOutcome,
  battleVictory,
  battleDefeat,
  cinematicCompleted,
  actionCompleted,
  branchOutcome,
  error,
  blocked,
}

enum SceneConditionSourceKind {
  fact,
  factLikeStoryFlag,
  storyStepCompletion,
  consumedEvent,
  storyStepActive,
  inventoryItem,
  partyState,
  trainerDefeated,
  dialogueOutcome,
  battleOutcome,
  scriptVariable,
  worldState,
}

enum SceneConditionOperator {
  isTrue,
  isFalse,
  equals,
}

abstract final class SceneConditionValues {
  static const completed = 'completed';
  static const notCompleted = 'notCompleted';
}

@immutable
final class SceneConditionSource {
  SceneConditionSource({
    required this.sourceKind,
    required this.sourceId,
    required this.operator,
    this.field,
    this.value,
    this.label,
    this.debugTechnicalLabel,
  }) {
    _requireNotBlank(sourceId, 'SceneConditionSource.sourceId');
    _requireOptionalNotBlank(field, 'SceneConditionSource.field');
    _requireOptionalNotBlank(value, 'SceneConditionSource.value');
    _requireOptionalNotBlank(label, 'SceneConditionSource.label');
    _requireOptionalNotBlank(
      debugTechnicalLabel,
      'SceneConditionSource.debugTechnicalLabel',
    );
  }

  factory SceneConditionSource.fromJson(Map<String, dynamic> json) {
    return SceneConditionSource(
      sourceKind: _readEnum(
        SceneConditionSourceKind.values,
        json['sourceKind'],
        'conditionSource.sourceKind',
      ),
      sourceId: _readRequiredString(json, 'sourceId'),
      field: _readOptionalString(json, 'field'),
      operator: _readEnum(
        SceneConditionOperator.values,
        json['operator'],
        'conditionSource.operator',
      ),
      value: _readOptionalString(json, 'value'),
      label: _readOptionalString(json, 'label'),
      debugTechnicalLabel: _readOptionalString(json, 'debugTechnicalLabel'),
    );
  }

  Map<String, dynamic> toJson() => _withoutNulls({
        'sourceKind': _enumToJson(sourceKind),
        'sourceId': sourceId,
        'field': field,
        'operator': _enumToJson(operator),
        'value': value,
        'label': label,
        'debugTechnicalLabel': debugTechnicalLabel,
      });

  final SceneConditionSourceKind sourceKind;
  final String sourceId;
  final String? field;
  final SceneConditionOperator operator;
  final String? value;
  final String? label;
  final String? debugTechnicalLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneConditionSource &&
          other.sourceKind == sourceKind &&
          other.sourceId == sourceId &&
          other.field == field &&
          other.operator == operator &&
          other.value == value &&
          other.label == label &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        sourceKind,
        sourceId,
        field,
        operator,
        value,
        label,
        debugTechnicalLabel,
      );
}

@immutable
final class SceneAsset {
  SceneAsset({
    required this.id,
    required this.name,
    this.description,
    this.storylineId,
    this.chapterId,
    List<String> tags = const <String>[],
    required this.graph,
    SceneGraphLayout? layout,
    List<SceneOutcome> declaredOutcomes = const <SceneOutcome>[],
    Map<String, String> metadata = const <String, String>{},
  })  : tags = _immutableNonBlankUniqueStrings(tags, 'SceneAsset.tags'),
        layout = layout ?? SceneGraphLayout(),
        declaredOutcomes = List<SceneOutcome>.unmodifiable(declaredOutcomes),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'SceneAsset.id');
    _requireNotBlank(name, 'SceneAsset.name');
    _requireOptionalNotBlank(storylineId, 'SceneAsset.storylineId');
    _requireOptionalNotBlank(chapterId, 'SceneAsset.chapterId');
    _validateUniqueIds(
      this.declaredOutcomes.map((outcome) => outcome.id),
      'SceneAsset.declaredOutcomes',
    );
    this.layout._validateAgainst(graph);
  }

  factory SceneAsset.fromJson(Map<String, dynamic> json) {
    return SceneAsset(
      id: _readRequiredString(json, 'id'),
      name: _readRequiredString(json, 'name'),
      description: _readOptionalString(json, 'description'),
      storylineId: _readOptionalString(json, 'storylineId'),
      chapterId: _readOptionalString(json, 'chapterId'),
      tags: _readStringList(json, 'tags'),
      graph: SceneGraph.fromJson(_readRequiredObject(json, 'graph')),
      layout: _readOptionalObject(json, 'layout', SceneGraphLayout.fromJson),
      declaredOutcomes: _readObjectList(
        json,
        'declaredOutcomes',
        SceneOutcome.fromJson,
      ),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'name': name,
      'description': description,
      'storylineId': storylineId,
      'chapterId': chapterId,
      'tags': tags,
      'graph': graph.toJson(),
      'layout': layout.toJson(),
      'declaredOutcomes':
          declaredOutcomes.map((outcome) => outcome.toJson()).toList(),
      'metadata': metadata,
    });
  }

  final String id;
  final String name;
  final String? description;
  final String? storylineId;
  final String? chapterId;
  final List<String> tags;
  final SceneGraph graph;
  final SceneGraphLayout layout;
  final List<SceneOutcome> declaredOutcomes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneAsset &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.storylineId == storylineId &&
          other.chapterId == chapterId &&
          _listEquals(other.tags, tags) &&
          other.graph == graph &&
          other.layout == layout &&
          _listEquals(other.declaredOutcomes, declaredOutcomes) &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        storylineId,
        chapterId,
        Object.hashAll(tags),
        graph,
        layout,
        Object.hashAll(declaredOutcomes),
        _mapHash(metadata),
      );

  @override
  String toString() => 'SceneAsset(id: $id, name: $name)';
}

@immutable
final class SceneGraph {
  SceneGraph({
    required this.startNodeId,
    List<SceneNode> nodes = const <SceneNode>[],
    List<SceneEdge> edges = const <SceneEdge>[],
  })  : nodes = List<SceneNode>.unmodifiable(nodes),
        edges = List<SceneEdge>.unmodifiable(edges) {
    _requireNotBlank(startNodeId, 'SceneGraph.startNodeId');
    _validateUniqueIds(this.nodes.map((node) => node.id), 'SceneGraph.nodes');
    _validateUniqueIds(this.edges.map((edge) => edge.id), 'SceneGraph.edges');

    final nodeIds = this.nodes.map((node) => node.id).toSet();
    final startNode = this
        .nodes
        .where((node) => node.id == startNodeId)
        .cast<SceneNode?>()
        .firstOrNull;
    if (startNode == null) {
      throw ValidationException(
        'SceneGraph.startNodeId must reference an existing node: $startNodeId',
      );
    }
    if (startNode.kind != SceneNodeKind.start) {
      throw const ValidationException(
        'SceneGraph.startNodeId must reference a start node',
      );
    }

    for (final edge in this.edges) {
      if (!nodeIds.contains(edge.fromNodeId)) {
        throw ValidationException(
          'SceneGraph.edges contains unknown fromNodeId: ${edge.fromNodeId}',
        );
      }
      if (!nodeIds.contains(edge.toNodeId)) {
        throw ValidationException(
          'SceneGraph.edges contains unknown toNodeId: ${edge.toNodeId}',
        );
      }
    }
  }

  factory SceneGraph.fromJson(Map<String, dynamic> json) {
    return SceneGraph(
      startNodeId: _readRequiredString(json, 'startNodeId'),
      nodes: _readObjectList(json, 'nodes', SceneNode.fromJson),
      edges: _readObjectList(json, 'edges', SceneEdge.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startNodeId': startNodeId,
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
    };
  }

  final String startNodeId;
  final List<SceneNode> nodes;
  final List<SceneEdge> edges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGraph &&
          other.startNodeId == startNodeId &&
          _listEquals(other.nodes, nodes) &&
          _listEquals(other.edges, edges);

  @override
  int get hashCode => Object.hash(
        startNodeId,
        Object.hashAll(nodes),
        Object.hashAll(edges),
      );
}

@immutable
final class SceneGraphLayout {
  SceneGraphLayout({
    List<SceneNodeLayout> nodeLayouts = const <SceneNodeLayout>[],
    List<SceneEdgeLayout> edgeLayouts = const <SceneEdgeLayout>[],
  })  : nodeLayouts = List<SceneNodeLayout>.unmodifiable(nodeLayouts),
        edgeLayouts = List<SceneEdgeLayout>.unmodifiable(edgeLayouts) {
    _validateUniqueIds(
      this.nodeLayouts.map((layout) => layout.nodeId),
      'SceneGraphLayout.nodeLayouts',
    );
    _validateUniqueIds(
      this.edgeLayouts.map((layout) => layout.edgeId),
      'SceneGraphLayout.edgeLayouts',
    );
  }

  factory SceneGraphLayout.fromJson(Map<String, dynamic> json) {
    return SceneGraphLayout(
      nodeLayouts: _readObjectList(
        json,
        'nodeLayouts',
        SceneNodeLayout.fromJson,
      ),
      edgeLayouts: _readObjectList(
        json,
        'edgeLayouts',
        SceneEdgeLayout.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeLayouts': nodeLayouts.map((layout) => layout.toJson()).toList(),
      'edgeLayouts': edgeLayouts.map((layout) => layout.toJson()).toList(),
    };
  }

  void _validateAgainst(SceneGraph graph) {
    final nodeIds = graph.nodes.map((node) => node.id).toSet();
    final edgeIds = graph.edges.map((edge) => edge.id).toSet();

    for (final layout in nodeLayouts) {
      if (!nodeIds.contains(layout.nodeId)) {
        throw ValidationException(
          'SceneGraphLayout.nodeLayouts references unknown nodeId: '
          '${layout.nodeId}',
        );
      }
    }
    for (final layout in edgeLayouts) {
      if (!edgeIds.contains(layout.edgeId)) {
        throw ValidationException(
          'SceneGraphLayout.edgeLayouts references unknown edgeId: '
          '${layout.edgeId}',
        );
      }
    }
  }

  final List<SceneNodeLayout> nodeLayouts;
  final List<SceneEdgeLayout> edgeLayouts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGraphLayout &&
          _listEquals(other.nodeLayouts, nodeLayouts) &&
          _listEquals(other.edgeLayouts, edgeLayouts);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(nodeLayouts),
        Object.hashAll(edgeLayouts),
      );
}

@immutable
final class SceneNodeLayout {
  SceneNodeLayout({
    required this.nodeId,
    required this.x,
    required this.y,
  }) {
    _requireNotBlank(nodeId, 'SceneNodeLayout.nodeId');
    _requireFiniteNumber(x, 'SceneNodeLayout.x');
    _requireFiniteNumber(y, 'SceneNodeLayout.y');
  }

  factory SceneNodeLayout.fromJson(Map<String, dynamic> json) {
    return SceneNodeLayout(
      nodeId: _readRequiredString(json, 'nodeId'),
      x: _readRequiredDouble(json, 'x'),
      y: _readRequiredDouble(json, 'y'),
    );
  }

  Map<String, dynamic> toJson() => {'nodeId': nodeId, 'x': x, 'y': y};

  final String nodeId;
  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneNodeLayout &&
          other.nodeId == nodeId &&
          other.x == x &&
          other.y == y;

  @override
  int get hashCode => Object.hash(nodeId, x, y);
}

@immutable
final class SceneEdgeLayout {
  SceneEdgeLayout({
    required this.edgeId,
    List<SceneLayoutPoint> controlPoints = const <SceneLayoutPoint>[],
  }) : controlPoints = List<SceneLayoutPoint>.unmodifiable(controlPoints) {
    _requireNotBlank(edgeId, 'SceneEdgeLayout.edgeId');
  }

  factory SceneEdgeLayout.fromJson(Map<String, dynamic> json) {
    return SceneEdgeLayout(
      edgeId: _readRequiredString(json, 'edgeId'),
      controlPoints: _readObjectList(
        json,
        'controlPoints',
        SceneLayoutPoint.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'edgeId': edgeId,
      'controlPoints': controlPoints.map((point) => point.toJson()).toList(),
    };
  }

  final String edgeId;
  final List<SceneLayoutPoint> controlPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneEdgeLayout &&
          other.edgeId == edgeId &&
          _listEquals(other.controlPoints, controlPoints);

  @override
  int get hashCode => Object.hash(edgeId, Object.hashAll(controlPoints));
}

@immutable
final class SceneLayoutPoint {
  SceneLayoutPoint({required this.x, required this.y}) {
    _requireFiniteNumber(x, 'SceneLayoutPoint.x');
    _requireFiniteNumber(y, 'SceneLayoutPoint.y');
  }

  factory SceneLayoutPoint.fromJson(Map<String, dynamic> json) {
    return SceneLayoutPoint(
      x: _readRequiredDouble(json, 'x'),
      y: _readRequiredDouble(json, 'y'),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneLayoutPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

@immutable
final class SceneNode {
  SceneNode({
    required this.id,
    required this.kind,
    this.title,
    this.description,
    SceneNodePayload? payload,
  }) : payload = payload ?? SceneNodePayload.emptyForKind(kind) {
    _requireNotBlank(id, 'SceneNode.id');
    if (this.payload.kind != kind) {
      throw ValidationException(
        'SceneNode.payload kind ${this.payload.kind.name} is incompatible '
        'with SceneNode.kind ${kind.name}',
      );
    }
  }

  factory SceneNode.fromJson(Map<String, dynamic> json) {
    final kind = _readEnum(SceneNodeKind.values, json['kind'], 'kind');
    return SceneNode(
      id: _readRequiredString(json, 'id'),
      kind: kind,
      title: _readOptionalString(json, 'title'),
      description: _readOptionalString(json, 'description'),
      payload: _readOptionalObject(
            json,
            'payload',
            (payloadJson) => SceneNodePayload.fromJson(
              payloadJson,
              expectedKind: kind,
            ),
          ) ??
          SceneNodePayload.emptyForKind(kind),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'kind': _enumToJson(kind),
      'title': title,
      'description': description,
      'payload': payload.toJson(),
    });
  }

  final String id;
  final SceneNodeKind kind;
  final String? title;
  final String? description;
  final SceneNodePayload payload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneNode &&
          other.id == id &&
          other.kind == kind &&
          other.title == title &&
          other.description == description &&
          other.payload == payload;

  @override
  int get hashCode => Object.hash(id, kind, title, description, payload);
}

abstract base class SceneNodePayload {
  const SceneNodePayload();

  factory SceneNodePayload.fromJson(
    Map<String, dynamic> json, {
    SceneNodeKind? expectedKind,
  }) {
    final kind = _readEnum(
      SceneNodeKind.values,
      json['kind'],
      'payload.kind',
      defaultValue: expectedKind,
    );
    if (expectedKind != null && kind != expectedKind) {
      throw ValidationException(
        'SceneNodePayload.kind ${kind.name} is incompatible with '
        'SceneNode.kind ${expectedKind.name}',
      );
    }
    return switch (kind) {
      SceneNodeKind.start => SceneStartPayload.fromJson(json),
      SceneNodeKind.end => SceneEndPayload.fromJson(json),
      SceneNodeKind.yarnDialogue => SceneYarnDialoguePayload.fromJson(json),
      SceneNodeKind.condition => SceneConditionPayload.fromJson(json),
      SceneNodeKind.action => SceneActionPayload.fromJson(json),
      SceneNodeKind.battle => SceneBattlePayload.fromJson(json),
      SceneNodeKind.cinematic => SceneCinematicPayload.fromJson(json),
      SceneNodeKind.branchByOutcome =>
        SceneBranchByOutcomePayload.fromJson(json),
      SceneNodeKind.merge => SceneMergePayload.fromJson(json),
    };
  }

  static SceneNodePayload emptyForKind(SceneNodeKind kind) {
    return switch (kind) {
      SceneNodeKind.start => SceneStartPayload(),
      SceneNodeKind.end => SceneEndPayload(),
      SceneNodeKind.yarnDialogue => throw const ValidationException(
          'SceneNode.kind yarnDialogue requires an explicit payload',
        ),
      SceneNodeKind.condition => SceneConditionPayload(),
      SceneNodeKind.action => throw const ValidationException(
          'SceneNode.kind action requires an explicit payload',
        ),
      SceneNodeKind.battle => throw const ValidationException(
          'SceneNode.kind battle requires an explicit payload',
        ),
      SceneNodeKind.cinematic => throw const ValidationException(
          'SceneNode.kind cinematic requires an explicit payload',
        ),
      SceneNodeKind.branchByOutcome => SceneBranchByOutcomePayload(),
      SceneNodeKind.merge => SceneMergePayload(),
    };
  }

  SceneNodeKind get kind;

  Map<String, dynamic> toJson();
}

@immutable
final class SceneStartPayload extends SceneNodePayload {
  SceneStartPayload({this.notes});

  factory SceneStartPayload.fromJson(Map<String, dynamic> json) {
    return SceneStartPayload(notes: _readOptionalString(json, 'notes'));
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.start;

  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneStartPayload && other.notes == notes;

  @override
  int get hashCode => notes.hashCode;
}

@immutable
final class SceneEndPayload extends SceneNodePayload {
  SceneEndPayload({this.sceneOutcomeId, this.notes}) {
    _requireOptionalNotBlank(sceneOutcomeId, 'SceneEndPayload.sceneOutcomeId');
  }

  factory SceneEndPayload.fromJson(Map<String, dynamic> json) {
    return SceneEndPayload(
      sceneOutcomeId: _readOptionalString(json, 'sceneOutcomeId'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.end;

  final String? sceneOutcomeId;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'sceneOutcomeId': sceneOutcomeId,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneEndPayload &&
          other.sceneOutcomeId == sceneOutcomeId &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(sceneOutcomeId, notes);
}

@immutable
final class SceneYarnDialoguePayload extends SceneNodePayload {
  SceneYarnDialoguePayload({
    required this.dialogueId,
    this.yarnNodeName,
    List<String> expectedOutcomes = const <String>[],
    List<String> speakerHints = const <String>[],
  })  : expectedOutcomes = _immutableNonBlankUniqueStrings(
          expectedOutcomes,
          'SceneYarnDialoguePayload.expectedOutcomes',
        ),
        speakerHints = _immutableNonBlankUniqueStrings(
          speakerHints,
          'SceneYarnDialoguePayload.speakerHints',
        ) {
    _requireNotBlank(dialogueId, 'SceneYarnDialoguePayload.dialogueId');
    _requireOptionalNotBlank(
      yarnNodeName,
      'SceneYarnDialoguePayload.yarnNodeName',
    );
  }

  factory SceneYarnDialoguePayload.fromJson(Map<String, dynamic> json) {
    return SceneYarnDialoguePayload(
      dialogueId: _readRequiredString(json, 'dialogueId'),
      yarnNodeName: _readOptionalString(json, 'yarnNodeName'),
      expectedOutcomes: _readStringList(json, 'expectedOutcomes'),
      speakerHints: _readStringList(json, 'speakerHints'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.yarnDialogue;

  final String dialogueId;
  final String? yarnNodeName;
  final List<String> expectedOutcomes;
  final List<String> speakerHints;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'dialogueId': dialogueId,
        'yarnNodeName': yarnNodeName,
        'expectedOutcomes': expectedOutcomes,
        'speakerHints': speakerHints,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneYarnDialoguePayload &&
          other.dialogueId == dialogueId &&
          other.yarnNodeName == yarnNodeName &&
          _listEquals(other.expectedOutcomes, expectedOutcomes) &&
          _listEquals(other.speakerHints, speakerHints);

  @override
  int get hashCode => Object.hash(
        dialogueId,
        yarnNodeName,
        Object.hashAll(expectedOutcomes),
        Object.hashAll(speakerHints),
      );
}

@immutable
final class SceneConditionPayload extends SceneNodePayload {
  SceneConditionPayload({
    this.conditionLabel,
    this.conditionRef,
    this.conditionDraft,
    this.conditionSource,
  }) {
    _requireOptionalNotBlank(
      conditionLabel,
      'SceneConditionPayload.conditionLabel',
    );
    _requireOptionalNotBlank(
      conditionRef,
      'SceneConditionPayload.conditionRef',
    );
    _requireOptionalNotBlank(
      conditionDraft,
      'SceneConditionPayload.conditionDraft',
    );
  }

  factory SceneConditionPayload.fromJson(Map<String, dynamic> json) {
    return SceneConditionPayload(
      conditionLabel: _readOptionalString(json, 'conditionLabel'),
      conditionRef: _readOptionalString(json, 'conditionRef'),
      conditionDraft: _readOptionalString(json, 'conditionDraft'),
      conditionSource: _readOptionalObject(
        json,
        'conditionSource',
        SceneConditionSource.fromJson,
      ),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.condition;

  final String? conditionLabel;
  final String? conditionRef;
  final String? conditionDraft;
  final SceneConditionSource? conditionSource;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'conditionLabel': conditionLabel,
        'conditionRef': conditionRef,
        'conditionDraft': conditionDraft,
        'conditionSource': conditionSource?.toJson(),
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneConditionPayload &&
          other.conditionLabel == conditionLabel &&
          other.conditionRef == conditionRef &&
          other.conditionDraft == conditionDraft &&
          other.conditionSource == conditionSource;

  @override
  int get hashCode => Object.hash(
        conditionLabel,
        conditionRef,
        conditionDraft,
        conditionSource,
      );
}

@immutable
final class SceneActionPayload extends SceneNodePayload {
  SceneActionPayload({
    String? actionKind,
    Map<String, String> parameters = const <String, String>{},
    this.consequence,
  })  : actionKind = _trimOptional(actionKind),
        parameters = Map<String, String>.unmodifiable(parameters) {
    if (this.actionKind == null && consequence == null) {
      throw ArgumentError.value(
        actionKind,
        'actionKind',
        'SceneActionPayload requires a legacy actionKind or a typed consequence.',
      );
    }
  }

  factory SceneActionPayload.consequence(
    SceneConsequence consequence, {
    String? actionKind,
    Map<String, String> parameters = const <String, String>{},
  }) {
    return SceneActionPayload(
      actionKind: actionKind,
      parameters: parameters,
      consequence: consequence,
    );
  }

  factory SceneActionPayload.fromJson(Map<String, dynamic> json) {
    return SceneActionPayload(
      actionKind: _readOptionalString(json, 'actionKind'),
      parameters: _readStringMap(json, 'parameters'),
      consequence: _readOptionalObject(
        json,
        'consequence',
        SceneConsequence.fromJson,
      ),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.action;

  final String? actionKind;
  final Map<String, String> parameters;
  final SceneConsequence? consequence;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'actionKind': actionKind,
        'parameters': parameters,
        'consequence': consequence?.toJson(),
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneActionPayload &&
          other.actionKind == actionKind &&
          _mapEquals(other.parameters, parameters) &&
          other.consequence == consequence;

  @override
  int get hashCode =>
      Object.hash(actionKind, _mapHash(parameters), consequence);
}

@immutable
final class SceneBattlePayload extends SceneNodePayload {
  SceneBattlePayload({
    required this.battleKind,
    this.trainerId,
    this.battleTemplateId,
    this.npcEntityId,
    List<String> declaredOutcomes = const <String>[],
  }) : declaredOutcomes = _immutableNonBlankUniqueStrings(
          declaredOutcomes,
          'SceneBattlePayload.declaredOutcomes',
        ) {
    _requireNotBlank(battleKind, 'SceneBattlePayload.battleKind');
    _requireOptionalNotBlank(trainerId, 'SceneBattlePayload.trainerId');
    _requireOptionalNotBlank(
      battleTemplateId,
      'SceneBattlePayload.battleTemplateId',
    );
    _requireOptionalNotBlank(npcEntityId, 'SceneBattlePayload.npcEntityId');
  }

  factory SceneBattlePayload.fromJson(Map<String, dynamic> json) {
    return SceneBattlePayload(
      battleKind: _readRequiredString(json, 'battleKind'),
      trainerId: _readOptionalString(json, 'trainerId'),
      battleTemplateId: _readOptionalString(json, 'battleTemplateId'),
      npcEntityId: _readOptionalString(json, 'npcEntityId'),
      declaredOutcomes: _readStringList(json, 'declaredOutcomes'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.battle;

  final String battleKind;
  final String? trainerId;
  final String? battleTemplateId;
  final String? npcEntityId;
  final List<String> declaredOutcomes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'battleKind': battleKind,
        'trainerId': trainerId,
        'battleTemplateId': battleTemplateId,
        'npcEntityId': npcEntityId,
        'declaredOutcomes': declaredOutcomes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneBattlePayload &&
          other.battleKind == battleKind &&
          other.trainerId == trainerId &&
          other.battleTemplateId == battleTemplateId &&
          other.npcEntityId == npcEntityId &&
          _listEquals(other.declaredOutcomes, declaredOutcomes);

  @override
  int get hashCode => Object.hash(
        battleKind,
        trainerId,
        battleTemplateId,
        npcEntityId,
        Object.hashAll(declaredOutcomes),
      );
}

@immutable
final class SceneCinematicPayload extends SceneNodePayload {
  SceneCinematicPayload({required this.cinematicId}) {
    _requireNotBlank(cinematicId, 'SceneCinematicPayload.cinematicId');
  }

  factory SceneCinematicPayload.fromJson(Map<String, dynamic> json) {
    return SceneCinematicPayload(
      cinematicId: _readRequiredString(json, 'cinematicId'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.cinematic;

  final String cinematicId;

  @override
  Map<String, dynamic> toJson() => {
        'kind': _enumToJson(kind),
        'cinematicId': cinematicId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneCinematicPayload && other.cinematicId == cinematicId;

  @override
  int get hashCode => cinematicId.hashCode;
}

@immutable
final class SceneBranchByOutcomePayload extends SceneNodePayload {
  SceneBranchByOutcomePayload({
    this.sourceNodeId,
    this.sourceOutcomeSetRef,
    this.fallbackPolicy,
  }) {
    _requireOptionalNotBlank(
      sourceNodeId,
      'SceneBranchByOutcomePayload.sourceNodeId',
    );
    _requireOptionalNotBlank(
      sourceOutcomeSetRef,
      'SceneBranchByOutcomePayload.sourceOutcomeSetRef',
    );
    _requireOptionalNotBlank(
      fallbackPolicy,
      'SceneBranchByOutcomePayload.fallbackPolicy',
    );
  }

  factory SceneBranchByOutcomePayload.fromJson(Map<String, dynamic> json) {
    return SceneBranchByOutcomePayload(
      sourceNodeId: _readOptionalString(json, 'sourceNodeId'),
      sourceOutcomeSetRef: _readOptionalString(json, 'sourceOutcomeSetRef'),
      fallbackPolicy: _readOptionalString(json, 'fallbackPolicy'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.branchByOutcome;

  final String? sourceNodeId;
  final String? sourceOutcomeSetRef;
  final String? fallbackPolicy;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'sourceNodeId': sourceNodeId,
        'sourceOutcomeSetRef': sourceOutcomeSetRef,
        'fallbackPolicy': fallbackPolicy,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneBranchByOutcomePayload &&
          other.sourceNodeId == sourceNodeId &&
          other.sourceOutcomeSetRef == sourceOutcomeSetRef &&
          other.fallbackPolicy == fallbackPolicy;

  @override
  int get hashCode =>
      Object.hash(sourceNodeId, sourceOutcomeSetRef, fallbackPolicy);
}

@immutable
final class SceneMergePayload extends SceneNodePayload {
  SceneMergePayload({this.label, this.notes}) {
    _requireOptionalNotBlank(label, 'SceneMergePayload.label');
  }

  factory SceneMergePayload.fromJson(Map<String, dynamic> json) {
    return SceneMergePayload(
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.merge;

  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneMergePayload &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(label, notes);
}

@immutable
final class SceneEdge {
  SceneEdge({
    required this.id,
    required this.fromNodeId,
    required this.fromPortId,
    required this.toNodeId,
    required this.kind,
    this.label,
  }) {
    _requireNotBlank(id, 'SceneEdge.id');
    _requireNotBlank(fromNodeId, 'SceneEdge.fromNodeId');
    _requireNotBlank(fromPortId, 'SceneEdge.fromPortId');
    _requireNotBlank(toNodeId, 'SceneEdge.toNodeId');
  }

  factory SceneEdge.fromJson(Map<String, dynamic> json) {
    return SceneEdge(
      id: _readRequiredString(json, 'id'),
      fromNodeId: _readRequiredString(json, 'fromNodeId'),
      fromPortId: _readRequiredString(json, 'fromPortId'),
      toNodeId: _readRequiredString(json, 'toNodeId'),
      kind: _readSceneEdgeKind(json['kind'], 'kind'),
      label: _readOptionalString(json, 'label'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'fromNodeId': fromNodeId,
      'fromPortId': fromPortId,
      'toNodeId': toNodeId,
      'kind': _sceneEdgeKindToJson(kind),
      'label': label,
    });
  }

  final String id;
  final String fromNodeId;
  final String fromPortId;
  final String toNodeId;
  final SceneEdgeKind kind;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneEdge &&
          other.id == id &&
          other.fromNodeId == fromNodeId &&
          other.fromPortId == fromPortId &&
          other.toNodeId == toNodeId &&
          other.kind == kind &&
          other.label == label;

  @override
  int get hashCode =>
      Object.hash(id, fromNodeId, fromPortId, toNodeId, kind, label);
}

@immutable
final class SceneOutcome {
  SceneOutcome({
    required this.id,
    required this.label,
    this.description,
  }) {
    _requireNotBlank(id, 'SceneOutcome.id');
    _requireNotBlank(label, 'SceneOutcome.label');
  }

  factory SceneOutcome.fromJson(Map<String, dynamic> json) {
    return SceneOutcome(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      description: _readOptionalString(json, 'description'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'label': label,
      'description': description,
    });
  }

  final String id;
  final String label;
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneOutcome &&
          other.id == id &&
          other.label == label &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, label, description);
}

void _requireNotBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ValidationException('$field must not be blank');
  }
}

void _requireOptionalNotBlank(String? value, String field) {
  if (value != null && value.trim().isEmpty) {
    throw ValidationException('$field must not be blank when provided');
  }
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

void _requireFiniteNumber(double value, String field) {
  if (!value.isFinite) {
    throw ValidationException('$field must be finite');
  }
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string');
  }
  _requireNotBlank(value, key);
  return value;
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$key must be a string');
  }
  _requireOptionalNotBlank(value, key);
  return value;
}

double _readRequiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('$key must be a number');
  }
  final number = value.toDouble();
  _requireFiniteNumber(number, key);
  return number;
}

Map<String, dynamic> _readRequiredObject(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('$key must be a JSON object');
  }
  return _jsonObject(value, key);
}

T? _readOptionalObject<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! Map) {
    throw FormatException('$key must be a JSON object');
  }
  return fromJson(_jsonObject(value, key));
}

List<T> _readObjectList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final value = json[key];
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw FormatException('$key must be a list');
  }
  return [
    for (final item in value)
      if (item is Map)
        fromJson(_jsonObject(item, key))
      else
        throw FormatException('$key entries must be JSON objects'),
  ];
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw FormatException('$key must be a list');
  }
  final strings = <String>[];
  for (final item in value) {
    if (item is! String) {
      throw FormatException('$key entries must be strings');
    }
    strings.add(item);
  }
  return _immutableNonBlankUniqueStrings(strings, key);
}

Map<String, String> _readStringMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const {};
  }
  if (value is! Map) {
    throw FormatException('$key must be a JSON object');
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! String) {
      throw FormatException('$key entries must be strings');
    }
    result[entry.key as String] = entry.value as String;
  }
  return Map<String, String>.unmodifiable(result);
}

Map<String, dynamic> _jsonObject(Map json, String field) {
  return json.map((key, value) {
    if (key is! String) {
      throw FormatException('$field JSON keys must be strings');
    }
    return MapEntry(key, value);
  });
}

T _readEnum<T extends Enum>(
  List<T> values,
  Object? value,
  String field, {
  T? defaultValue,
}) {
  if (value == null && defaultValue != null) {
    return defaultValue;
  }
  if (value is! String) {
    throw FormatException('$field must be a string');
  }
  for (final candidate in values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  throw FormatException('Unknown $field value: $value');
}

SceneEdgeKind _readSceneEdgeKind(Object? value, String field) {
  if (value is! String) {
    throw FormatException('$field must be a string');
  }
  if (value == 'default') {
    return SceneEdgeKind.defaultFlow;
  }
  for (final candidate in SceneEdgeKind.values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  throw FormatException('Unknown $field value: $value');
}

String _enumToJson(Enum value) => value.name;

String _sceneEdgeKindToJson(SceneEdgeKind kind) {
  return switch (kind) {
    SceneEdgeKind.defaultFlow => 'default',
    _ => kind.name,
  };
}

List<String> _immutableNonBlankUniqueStrings(
  Iterable<String> values,
  String field,
) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    _requireNotBlank(value, field);
    if (!seen.add(value)) {
      throw ValidationException('$field contains duplicate id: $value');
    }
    result.add(value);
  }
  return List<String>.unmodifiable(result);
}

void _validateUniqueIds(Iterable<String> ids, String field) {
  final seen = <String>{};
  for (final id in ids) {
    _requireNotBlank(id, field);
    if (!seen.add(id)) {
      throw ValidationException('$field contains duplicate id: $id');
    }
  }
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
  return {
    for (final entry in values.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) {
      return false;
    }
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) {
  return Object.hashAll(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
