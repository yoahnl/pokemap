// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScriptAssetImpl _$$ScriptAssetImplFromJson(Map<String, dynamic> json) =>
    _$ScriptAssetImpl(
      id: json['id'] as String,
      nodes: (json['nodes'] as List<dynamic>)
          .map((e) => ScriptNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultStartNode: json['defaultStartNode'] as String? ?? 'start',
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ScriptAssetImplToJson(_$ScriptAssetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nodes': instance.nodes.map((e) => e.toJson()).toList(),
      'defaultStartNode': instance.defaultStartNode,
      'metadata': instance.metadata,
    };

_$ScriptNodeImpl _$$ScriptNodeImplFromJson(Map<String, dynamic> json) =>
    _$ScriptNodeImpl(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      commands: (json['commands'] as List<dynamic>?)
              ?.map((e) => ScriptCommand.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      nextNodeId: json['nextNodeId'] as String?,
    );

Map<String, dynamic> _$$ScriptNodeImplToJson(_$ScriptNodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'commands': instance.commands.map((e) => e.toJson()).toList(),
      'nextNodeId': instance.nextNodeId,
    };

_$ScriptCommandImpl _$$ScriptCommandImplFromJson(Map<String, dynamic> json) =>
    _$ScriptCommandImpl(
      type: $enumDecode(_$ScriptCommandTypeEnumMap, json['type']),
      params: (json['params'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ScriptCommandImplToJson(_$ScriptCommandImpl instance) =>
    <String, dynamic>{
      'type': _$ScriptCommandTypeEnumMap[instance.type]!,
      'params': instance.params,
    };

const _$ScriptCommandTypeEnumMap = {
  ScriptCommandType.goto: 'goto',
  ScriptCommandType.end: 'end',
  ScriptCommandType.setFlag: 'setFlag',
  ScriptCommandType.clearFlag: 'clearFlag',
  ScriptCommandType.setVariable: 'setVariable',
  ScriptCommandType.incrementVariable: 'incrementVariable',
  ScriptCommandType.openDialogue: 'openDialogue',
  ScriptCommandType.waitForDialogue: 'waitForDialogue',
  ScriptCommandType.warpPlayer: 'warpPlayer',
  ScriptCommandType.giveItem: 'giveItem',
  ScriptCommandType.unlockFieldAbility: 'unlockFieldAbility',
  ScriptCommandType.markEventConsumed: 'markEventConsumed',
};

_$YarnDialogueRefImpl _$$YarnDialogueRefImplFromJson(
        Map<String, dynamic> json) =>
    _$YarnDialogueRefImpl(
      filePath: json['filePath'] as String,
      startNode: json['startNode'] as String?,
    );

Map<String, dynamic> _$$YarnDialogueRefImplToJson(
        _$YarnDialogueRefImpl instance) =>
    <String, dynamic>{
      'filePath': instance.filePath,
      'startNode': instance.startNode,
    };
