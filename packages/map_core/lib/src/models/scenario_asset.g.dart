// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario_asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScenarioAssetImpl _$$ScenarioAssetImplFromJson(Map<String, dynamic> json) =>
    _$ScenarioAssetImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      entryNodeId: json['entryNodeId'] as String,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => ScenarioNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ScenarioNode>[],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => ScenarioEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ScenarioEdge>[],
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ScenarioAssetImplToJson(_$ScenarioAssetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'entryNodeId': instance.entryNodeId,
      'nodes': instance.nodes.map((e) => e.toJson()).toList(),
      'edges': instance.edges.map((e) => e.toJson()).toList(),
      'metadata': instance.metadata,
    };

_$ScenarioNodeImpl _$$ScenarioNodeImplFromJson(Map<String, dynamic> json) =>
    _$ScenarioNodeImpl(
      id: json['id'] as String,
      type: $enumDecodeNullable(_$ScenarioNodeTypeEnumMap, json['type']) ??
          ScenarioNodeType.action,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      position: json['position'] == null
          ? const ScenarioNodePosition(x: 0, y: 0)
          : ScenarioNodePosition.fromJson(
              json['position'] as Map<String, dynamic>),
      binding: json['binding'] == null
          ? const ScenarioNodeBinding()
          : ScenarioNodeBinding.fromJson(
              json['binding'] as Map<String, dynamic>),
      payload: json['payload'] == null
          ? const ScenarioNodePayload()
          : ScenarioNodePayload.fromJson(
              json['payload'] as Map<String, dynamic>),
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ScenarioNodeImplToJson(_$ScenarioNodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ScenarioNodeTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'position': instance.position.toJson(),
      'binding': instance.binding.toJson(),
      'payload': instance.payload.toJson(),
      'metadata': instance.metadata,
    };

const _$ScenarioNodeTypeEnumMap = {
  ScenarioNodeType.start: 'start',
  ScenarioNodeType.dialogue: 'dialogue',
  ScenarioNodeType.action: 'action',
  ScenarioNodeType.condition: 'condition',
  ScenarioNodeType.choice: 'choice',
  ScenarioNodeType.reference: 'reference',
  ScenarioNodeType.end: 'end',
};

_$ScenarioNodePositionImpl _$$ScenarioNodePositionImplFromJson(
        Map<String, dynamic> json) =>
    _$ScenarioNodePositionImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$$ScenarioNodePositionImplToJson(
        _$ScenarioNodePositionImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

_$ScenarioNodeBindingImpl _$$ScenarioNodeBindingImplFromJson(
        Map<String, dynamic> json) =>
    _$ScenarioNodeBindingImpl(
      mapId: json['mapId'] as String?,
      eventId: json['eventId'] as String?,
      entityId: json['entityId'] as String?,
      warpId: json['warpId'] as String?,
      triggerId: json['triggerId'] as String?,
      trainerId: json['trainerId'] as String?,
      dialogueId: json['dialogueId'] as String?,
      scriptId: json['scriptId'] as String?,
      flagName: json['flagName'] as String?,
      variableName: json['variableName'] as String?,
    );

Map<String, dynamic> _$$ScenarioNodeBindingImplToJson(
        _$ScenarioNodeBindingImpl instance) =>
    <String, dynamic>{
      'mapId': instance.mapId,
      'eventId': instance.eventId,
      'entityId': instance.entityId,
      'warpId': instance.warpId,
      'triggerId': instance.triggerId,
      'trainerId': instance.trainerId,
      'dialogueId': instance.dialogueId,
      'scriptId': instance.scriptId,
      'flagName': instance.flagName,
      'variableName': instance.variableName,
    };

_$ScenarioNodePayloadImpl _$$ScenarioNodePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$ScenarioNodePayloadImpl(
      actionKind: json['actionKind'] as String?,
      message: json['message'] as String?,
      condition: json['condition'] == null
          ? null
          : ScriptCondition.fromJson(json['condition'] as Map<String, dynamic>),
      choiceLabels: (json['choiceLabels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      params: (json['params'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ScenarioNodePayloadImplToJson(
        _$ScenarioNodePayloadImpl instance) =>
    <String, dynamic>{
      'actionKind': instance.actionKind,
      'message': instance.message,
      'condition': instance.condition?.toJson(),
      'choiceLabels': instance.choiceLabels,
      'params': instance.params,
    };

_$ScenarioEdgeImpl _$$ScenarioEdgeImplFromJson(Map<String, dynamic> json) =>
    _$ScenarioEdgeImpl(
      id: json['id'] as String,
      fromNodeId: json['fromNodeId'] as String,
      toNodeId: json['toNodeId'] as String,
      label: json['label'] as String? ?? '',
      kind: $enumDecodeNullable(_$ScenarioEdgeKindEnumMap, json['kind']) ??
          ScenarioEdgeKind.next,
      order: (json['order'] as num?)?.toInt() ?? 0,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ScenarioEdgeImplToJson(_$ScenarioEdgeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromNodeId': instance.fromNodeId,
      'toNodeId': instance.toNodeId,
      'label': instance.label,
      'kind': _$ScenarioEdgeKindEnumMap[instance.kind]!,
      'order': instance.order,
      'metadata': instance.metadata,
    };

const _$ScenarioEdgeKindEnumMap = {
  ScenarioEdgeKind.next: 'next',
  ScenarioEdgeKind.trueBranch: 'trueBranch',
  ScenarioEdgeKind.falseBranch: 'falseBranch',
  ScenarioEdgeKind.choice: 'choice',
  ScenarioEdgeKind.reference: 'reference',
};
