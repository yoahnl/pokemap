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
      cells: (json['cells'] as List<dynamic>?)
              ?.map((e) => GridPos.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ElementCollisionProfileImplToJson(
        _$ElementCollisionProfileImpl instance) =>
    <String, dynamic>{
      'source': _$ElementCollisionProfileSourceEnumMap[instance.source]!,
      'cells': instance.cells.map((e) => e.toJson()).toList(),
    };

const _$ElementCollisionProfileSourceEnumMap = {
  ElementCollisionProfileSource.generated: 'generated',
  ElementCollisionProfileSource.manual: 'manual',
};
