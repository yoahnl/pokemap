// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_tile_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SmartTileCellFieldImpl _$$SmartTileCellFieldImplFromJson(
        Map<String, dynamic> json) =>
    _$SmartTileCellFieldImpl(
      semanticCells: (json['semanticCells'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$SmartTileCellFieldImplToJson(
        _$SmartTileCellFieldImpl instance) =>
    <String, dynamic>{
      'semanticCells': instance.semanticCells,
      'kind': instance.$type,
    };

_$SmartTileCornerFieldImpl _$$SmartTileCornerFieldImplFromJson(
        Map<String, dynamic> json) =>
    _$SmartTileCornerFieldImpl(
      semanticCells: (json['semanticCells'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      corners: (json['corners'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$SmartTileCornerFieldImplToJson(
        _$SmartTileCornerFieldImpl instance) =>
    <String, dynamic>{
      'semanticCells': instance.semanticCells,
      'corners': instance.corners,
      'kind': instance.$type,
    };

_$SmartTileEdgeFieldImpl _$$SmartTileEdgeFieldImplFromJson(
        Map<String, dynamic> json) =>
    _$SmartTileEdgeFieldImpl(
      semanticCells: (json['semanticCells'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      horizontalEdges: (json['horizontalEdges'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      verticalEdges: (json['verticalEdges'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$SmartTileEdgeFieldImplToJson(
        _$SmartTileEdgeFieldImpl instance) =>
    <String, dynamic>{
      'semanticCells': instance.semanticCells,
      'horizontalEdges': instance.horizontalEdges,
      'verticalEdges': instance.verticalEdges,
      'kind': instance.$type,
    };

_$SmartTileMixedFieldImpl _$$SmartTileMixedFieldImplFromJson(
        Map<String, dynamic> json) =>
    _$SmartTileMixedFieldImpl(
      semanticCells: (json['semanticCells'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      horizontalEdges: (json['horizontalEdges'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      verticalEdges: (json['verticalEdges'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      corners: (json['corners'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$SmartTileMixedFieldImplToJson(
        _$SmartTileMixedFieldImpl instance) =>
    <String, dynamic>{
      'semanticCells': instance.semanticCells,
      'horizontalEdges': instance.horizontalEdges,
      'verticalEdges': instance.verticalEdges,
      'corners': instance.corners,
      'kind': instance.$type,
    };
