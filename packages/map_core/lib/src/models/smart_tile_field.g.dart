// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_tile_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmartTileCellField _$SmartTileCellFieldFromJson(Map<String, dynamic> json) =>
    SmartTileCellField(
      semanticCells:
          (json['semanticCells'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$SmartTileCellFieldToJson(SmartTileCellField instance) =>
    <String, dynamic>{
      'semanticCells': instance.semanticCells,
      'kind': instance.$type,
    };

SmartTileCornerField _$SmartTileCornerFieldFromJson(
  Map<String, dynamic> json,
) => SmartTileCornerField(
  semanticCells:
      (json['semanticCells'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  corners:
      (json['corners'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$SmartTileCornerFieldToJson(
  SmartTileCornerField instance,
) => <String, dynamic>{
  'semanticCells': instance.semanticCells,
  'corners': instance.corners,
  'kind': instance.$type,
};

SmartTileEdgeField _$SmartTileEdgeFieldFromJson(Map<String, dynamic> json) =>
    SmartTileEdgeField(
      semanticCells:
          (json['semanticCells'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      horizontalEdges:
          (json['horizontalEdges'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      verticalEdges:
          (json['verticalEdges'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$SmartTileEdgeFieldToJson(SmartTileEdgeField instance) =>
    <String, dynamic>{
      'semanticCells': instance.semanticCells,
      'horizontalEdges': instance.horizontalEdges,
      'verticalEdges': instance.verticalEdges,
      'kind': instance.$type,
    };

SmartTileMixedField _$SmartTileMixedFieldFromJson(Map<String, dynamic> json) =>
    SmartTileMixedField(
      semanticCells:
          (json['semanticCells'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      horizontalEdges:
          (json['horizontalEdges'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      verticalEdges:
          (json['verticalEdges'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      corners:
          (json['corners'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$SmartTileMixedFieldToJson(
  SmartTileMixedField instance,
) => <String, dynamic>{
  'semanticCells': instance.semanticCells,
  'horizontalEdges': instance.horizontalEdges,
  'verticalEdges': instance.verticalEdges,
  'corners': instance.corners,
  'kind': instance.$type,
};
