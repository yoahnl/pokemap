// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GridPos _$GridPosFromJson(Map<String, dynamic> json) =>
    _GridPos(x: (json['x'] as num).toInt(), y: (json['y'] as num).toInt());

Map<String, dynamic> _$GridPosToJson(_GridPos instance) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
};

_GridSize _$GridSizeFromJson(Map<String, dynamic> json) => _GridSize(
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
);

Map<String, dynamic> _$GridSizeToJson(_GridSize instance) => <String, dynamic>{
  'width': instance.width,
  'height': instance.height,
};

_MapRect _$MapRectFromJson(Map<String, dynamic> json) => _MapRect(
  pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
  size: GridSize.fromJson(json['size'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MapRectToJson(_MapRect instance) => <String, dynamic>{
  'pos': instance.pos,
  'size': instance.size,
};
