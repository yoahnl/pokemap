// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GridPosImpl _$$GridPosImplFromJson(Map<String, dynamic> json) =>
    _$GridPosImpl(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
    );

Map<String, dynamic> _$$GridPosImplToJson(_$GridPosImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

_$GridSizeImpl _$$GridSizeImplFromJson(Map<String, dynamic> json) =>
    _$GridSizeImpl(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$$GridSizeImplToJson(_$GridSizeImpl instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
    };

_$MapRectImpl _$$MapRectImplFromJson(Map<String, dynamic> json) =>
    _$MapRectImpl(
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      size: GridSize.fromJson(json['size'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapRectImplToJson(_$MapRectImpl instance) =>
    <String, dynamic>{
      'pos': instance.pos,
      'size': instance.size,
    };
