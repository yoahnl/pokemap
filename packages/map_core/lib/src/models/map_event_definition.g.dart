// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_event_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MapEventDefinition _$MapEventDefinitionFromJson(Map<String, dynamic> json) =>
    _MapEventDefinition(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      pages: (json['pages'] as List<dynamic>)
          .map((e) => MapEventPage.fromJson(e as Map<String, dynamic>))
          .toList(),
      position: EventPosition.fromJson(
        json['position'] as Map<String, dynamic>,
      ),
      type:
          $enumDecodeNullable(_$MapEventTypeEnumMap, json['type']) ??
          MapEventType.actor,
      metadata:
          (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$MapEventDefinitionToJson(_MapEventDefinition instance) =>
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

_EventPosition _$EventPositionFromJson(Map<String, dynamic> json) =>
    _EventPosition(
      layerId: json['layerId'] as String,
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
    );

Map<String, dynamic> _$EventPositionToJson(_EventPosition instance) =>
    <String, dynamic>{
      'layerId': instance.layerId,
      'x': instance.x,
      'y': instance.y,
    };

_MapEventSceneTarget _$MapEventSceneTargetFromJson(Map<String, dynamic> json) =>
    _MapEventSceneTarget(sceneId: json['sceneId'] as String);

Map<String, dynamic> _$MapEventSceneTargetToJson(
  _MapEventSceneTarget instance,
) => <String, dynamic>{'sceneId': instance.sceneId};

_MapEventPage _$MapEventPageFromJson(Map<String, dynamic> json) =>
    _MapEventPage(
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
              json['sceneTarget'] as Map<String, dynamic>,
            ),
      isHidden: json['isHidden'] as bool? ?? false,
      isDisabled: json['isDisabled'] as bool? ?? false,
      metadata:
          (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$MapEventPageToJson(_MapEventPage instance) =>
    <String, dynamic>{
      'pageNumber': instance.pageNumber,
      'condition': instance.condition?.toJson(),
      'script': instance.script?.toJson(),
      'spriteId': instance.spriteId,
      'message': instance.message,
      'sceneTarget': ?instance.sceneTarget?.toJson(),
      'isHidden': instance.isHidden,
      'isDisabled': instance.isDisabled,
      'metadata': instance.metadata,
    };

_ScriptRef _$ScriptRefFromJson(Map<String, dynamic> json) => _ScriptRef(
  scriptId: json['scriptId'] as String,
  startNode: json['startNode'] as String?,
);

Map<String, dynamic> _$ScriptRefToJson(_ScriptRef instance) =>
    <String, dynamic>{
      'scriptId': instance.scriptId,
      'startNode': instance.startNode,
    };

_ActiveEventPage _$ActiveEventPageFromJson(Map<String, dynamic> json) =>
    _ActiveEventPage(
      eventId: json['eventId'] as String,
      page: MapEventPage.fromJson(json['page'] as Map<String, dynamic>),
      pageIndex: (json['pageIndex'] as num).toInt(),
    );

Map<String, dynamic> _$ActiveEventPageToJson(_ActiveEventPage instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'page': instance.page,
      'pageIndex': instance.pageIndex,
    };
