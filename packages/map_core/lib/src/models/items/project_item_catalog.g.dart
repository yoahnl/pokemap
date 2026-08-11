// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_item_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectItemCatalog _$ProjectItemCatalogFromJson(Map<String, dynamic> json) =>
    _ProjectItemCatalog(
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => ProjectItemDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProjectItemCatalogToJson(_ProjectItemCatalog instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };
