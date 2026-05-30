// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_event_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MapEventDefinitionImpl _$$MapEventDefinitionImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEventDefinitionImpl(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      pages: (json['pages'] as List<dynamic>)
          .map((e) => MapEventPage.fromJson(e as Map<String, dynamic>))
          .toList(),
      position:
          EventPosition.fromJson(json['position'] as Map<String, dynamic>),
      type: $enumDecodeNullable(_$MapEventTypeEnumMap, json['type']) ??
          MapEventType.actor,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapEventDefinitionImplToJson(
        _$MapEventDefinitionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'pages': instance.pages.map((e) => e.toJson()).toList(),
      'position': instance.position.toJson(),
      'type': _$MapEventTypeEnumMap[instance.type]!,
      'metadata': instance.metadata,
    };

const _$MapEventTypeEnumMap = {
  MapEventType.actor: 'actor',
  MapEventType.object: 'object',
  MapEventType.triggerZone: 'triggerZone',
  MapEventType.effect: 'effect',
};

_$EventPositionImpl _$$EventPositionImplFromJson(Map<String, dynamic> json) =>
    _$EventPositionImpl(
      layerId: json['layerId'] as String,
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
    );

Map<String, dynamic> _$$EventPositionImplToJson(_$EventPositionImpl instance) =>
    <String, dynamic>{
      'layerId': instance.layerId,
      'x': instance.x,
      'y': instance.y,
    };

_$MapEventSceneTargetImpl _$$MapEventSceneTargetImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEventSceneTargetImpl(
      sceneId: json['sceneId'] as String,
    );

Map<String, dynamic> _$$MapEventSceneTargetImplToJson(
        _$MapEventSceneTargetImpl instance) =>
    <String, dynamic>{
      'sceneId': instance.sceneId,
    };

_$MapEventPageImpl _$$MapEventPageImplFromJson(Map<String, dynamic> json) =>
    _$MapEventPageImpl(
      pageNumber: (json['pageNumber'] as num).toInt(),
      condition: json['condition'] == null
          ? null
          : ScriptCondition.fromJson(json['condition'] as Map<String, dynamic>),
      script: json['script'] == null
          ? null
          : ScriptRef.fromJson(json['script'] as Map<String, dynamic>),
      spriteId: json['spriteId'] as String?,
      message: json['message'] as String?,
      sceneTarget: json['sceneTarget'] == null
          ? null
          : MapEventSceneTarget.fromJson(
              json['sceneTarget'] as Map<String, dynamic>),
      isHidden: json['isHidden'] as bool? ?? false,
      isDisabled: json['isDisabled'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapEventPageImplToJson(_$MapEventPageImpl instance) =>
    <String, dynamic>{
      'pageNumber': instance.pageNumber,
      'condition': instance.condition?.toJson(),
      'script': instance.script?.toJson(),
      'spriteId': instance.spriteId,
      'message': instance.message,
      if (instance.sceneTarget?.toJson() case final value?)
        'sceneTarget': value,
      'isHidden': instance.isHidden,
      'isDisabled': instance.isDisabled,
      'metadata': instance.metadata,
    };

_$ScriptRefImpl _$$ScriptRefImplFromJson(Map<String, dynamic> json) =>
    _$ScriptRefImpl(
      scriptId: json['scriptId'] as String,
      startNode: json['startNode'] as String?,
    );

Map<String, dynamic> _$$ScriptRefImplToJson(_$ScriptRefImpl instance) =>
    <String, dynamic>{
      'scriptId': instance.scriptId,
      'startNode': instance.startNode,
    };

_$ActiveEventPageImpl _$$ActiveEventPageImplFromJson(
        Map<String, dynamic> json) =>
    _$ActiveEventPageImpl(
      eventId: json['eventId'] as String,
      page: MapEventPage.fromJson(json['page'] as Map<String, dynamic>),
      pageIndex: (json['pageIndex'] as num).toInt(),
    );

Map<String, dynamic> _$$ActiveEventPageImplToJson(
        _$ActiveEventPageImpl instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'page': instance.page,
      'pageIndex': instance.pageIndex,
    };
