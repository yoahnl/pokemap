// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_item_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectItemDefinition _$ProjectItemDefinitionFromJson(
  Map<String, dynamic> json,
) => _ProjectItemDefinition(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  aliases:
      (json['aliases'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  pocketId: json['pocketId'] as String,
  description: json['description'] as String?,
  buyPrice: (json['buyPrice'] as num?)?.toInt(),
  sellPrice: (json['sellPrice'] as num?)?.toInt(),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
      const <String>{},
  uses:
      (json['uses'] as List<dynamic>?)
          ?.map(
            (e) => ProjectItemUseDefinition.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ProjectItemUseDefinition>[],
  capture: json['capture'] == null
      ? null
      : ProjectCaptureItemDefinition.fromJson(
          json['capture'] as Map<String, dynamic>,
        ),
  machine: json['machine'] == null
      ? null
      : ProjectMoveMachineItemDefinition.fromJson(
          json['machine'] as Map<String, dynamic>,
        ),
  heldEffectId: json['heldEffectId'] as String?,
);

Map<String, dynamic> _$ProjectItemDefinitionToJson(
  _ProjectItemDefinition instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'aliases': instance.aliases,
  'pocketId': instance.pocketId,
  'description': instance.description,
  'buyPrice': instance.buyPrice,
  'sellPrice': instance.sellPrice,
  'tags': instance.tags.toList(),
  'uses': instance.uses.map((e) => e.toJson()).toList(),
  'capture': instance.capture?.toJson(),
  'machine': instance.machine?.toJson(),
  'heldEffectId': instance.heldEffectId,
};
