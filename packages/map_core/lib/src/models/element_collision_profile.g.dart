// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'element_collision_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ElementCollisionPixelMaskImpl _$$ElementCollisionPixelMaskImplFromJson(
        Map<String, dynamic> json) =>
    _$ElementCollisionPixelMaskImpl(
      widthPx: (json['widthPx'] as num).toInt(),
      heightPx: (json['heightPx'] as num).toInt(),
      encoding: $enumDecodeNullable(
              _$ElementCollisionMaskEncodingEnumMap, json['encoding']) ??
          ElementCollisionMaskEncoding.packedBitsV1,
      dataBase64: json['dataBase64'] as String? ?? '',
    );

Map<String, dynamic> _$$ElementCollisionPixelMaskImplToJson(
        _$ElementCollisionPixelMaskImpl instance) =>
    <String, dynamic>{
      'widthPx': instance.widthPx,
      'heightPx': instance.heightPx,
      'encoding': _$ElementCollisionMaskEncodingEnumMap[instance.encoding]!,
      'dataBase64': instance.dataBase64,
    };

const _$ElementCollisionMaskEncodingEnumMap = {
  ElementCollisionMaskEncoding.packedBitsV1: 'packed_bits_v1',
};

_$ElementCollisionProfileImpl _$$ElementCollisionProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ElementCollisionProfileImpl(
      source: $enumDecodeNullable(
              _$ElementCollisionProfileSourceEnumMap, json['source']) ??
          ElementCollisionProfileSource.generated,
      visualMask: json['visualMask'] == null
          ? null
          : ElementCollisionPixelMask.fromJson(
              json['visualMask'] as Map<String, dynamic>),
      collisionMask: json['pixelMask'] == null
          ? null
          : ElementCollisionPixelMask.fromJson(
              json['pixelMask'] as Map<String, dynamic>),
      occlusionMask: json['occlusionMask'] == null
          ? null
          : ElementCollisionPixelMask.fromJson(
              json['occlusionMask'] as Map<String, dynamic>),
      padding: json['padding'] == null
          ? const WarpTriggerPadding()
          : WarpTriggerPadding.fromJson(
              json['padding'] as Map<String, dynamic>),
      shapeCells: (json['shapeCells'] as List<dynamic>?)
              ?.map((e) => GridPos.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      cells: (json['cells'] as List<dynamic>?)
              ?.map((e) => GridPos.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      manualAddedCells: (json['manualAddedCells'] as List<dynamic>?)
              ?.map((e) => GridPos.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      manualRemovedCells: (json['manualRemovedCells'] as List<dynamic>?)
              ?.map((e) => GridPos.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ElementCollisionProfileImplToJson(
        _$ElementCollisionProfileImpl instance) =>
    <String, dynamic>{
      'source': _$ElementCollisionProfileSourceEnumMap[instance.source]!,
      'visualMask': instance.visualMask?.toJson(),
      'pixelMask': instance.collisionMask?.toJson(),
      'occlusionMask': instance.occlusionMask?.toJson(),
      'padding': instance.padding.toJson(),
      'shapeCells': instance.shapeCells.map((e) => e.toJson()).toList(),
      'cells': instance.cells.map((e) => e.toJson()).toList(),
      'manualAddedCells':
          instance.manualAddedCells.map((e) => e.toJson()).toList(),
      'manualRemovedCells':
          instance.manualRemovedCells.map((e) => e.toJson()).toList(),
    };

const _$ElementCollisionProfileSourceEnumMap = {
  ElementCollisionProfileSource.generated: 'generated',
  ElementCollisionProfileSource.manual: 'manual',
};
