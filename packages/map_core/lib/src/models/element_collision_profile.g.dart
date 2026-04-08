// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'element_collision_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ElementCollisionProfileImpl _$$ElementCollisionProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ElementCollisionProfileImpl(
      source: $enumDecodeNullable(
              _$ElementCollisionProfileSourceEnumMap, json['source']) ??
          ElementCollisionProfileSource.generated,
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
