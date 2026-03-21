// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectManifestImpl _$$ProjectManifestImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectManifestImpl(
      name: json['name'] as String,
      version: json['version'] as String? ?? 'v1',
      maps: (json['maps'] as List<dynamic>)
          .map((e) => ProjectMapEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      tilesets: (json['tilesets'] as List<dynamic>)
          .map((e) => ProjectTilesetEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      globalProperties:
          json['globalProperties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ProjectManifestImplToJson(
        _$ProjectManifestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'maps': instance.maps.map((e) => e.toJson()).toList(),
      'tilesets': instance.tilesets.map((e) => e.toJson()).toList(),
      'globalProperties': instance.globalProperties,
    };

_$ProjectMapEntryImpl _$$ProjectMapEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectMapEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
    );

Map<String, dynamic> _$$ProjectMapEntryImplToJson(
        _$ProjectMapEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
    };

_$ProjectTilesetEntryImpl _$$ProjectTilesetEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTilesetEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
    );

Map<String, dynamic> _$$ProjectTilesetEntryImplToJson(
        _$ProjectTilesetEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
    };
