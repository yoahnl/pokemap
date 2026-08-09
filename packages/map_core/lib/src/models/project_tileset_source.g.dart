// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_tileset_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VisualTileProperty _$VisualTilePropertyFromJson(Map<String, dynamic> json) =>
    _VisualTileProperty(
      tileId: (json['tileId'] as num).toInt(),
      passable: json['passable'] as bool? ?? true,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
    );

Map<String, dynamic> _$VisualTilePropertyToJson(_VisualTileProperty instance) =>
    <String, dynamic>{
      'tileId': instance.tileId,
      'passable': instance.passable,
      'tags': instance.tags,
    };

_ProjectTilesetProperty _$ProjectTilesetPropertyFromJson(
  Map<String, dynamic> json,
) => _ProjectTilesetProperty(
  name: json['name'] as String,
  type: $enumDecode(_$ProjectTilesetPropertyTypeEnumMap, json['type']),
  value: json['value'],
  customType: json['customType'] as String?,
);

Map<String, dynamic> _$ProjectTilesetPropertyToJson(
  _ProjectTilesetProperty instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': _$ProjectTilesetPropertyTypeEnumMap[instance.type]!,
  'value': instance.value,
  'customType': ?instance.customType,
};

const _$ProjectTilesetPropertyTypeEnumMap = {
  ProjectTilesetPropertyType.string: 'string',
  ProjectTilesetPropertyType.integer: 'integer',
  ProjectTilesetPropertyType.decimal: 'decimal',
  ProjectTilesetPropertyType.boolean: 'boolean',
  ProjectTilesetPropertyType.color: 'color',
  ProjectTilesetPropertyType.assetReference: 'asset_reference',
  ProjectTilesetPropertyType.objectReference: 'object_reference',
  ProjectTilesetPropertyType.structured: 'structured',
};

_ProjectTilesetPixelRect _$ProjectTilesetPixelRectFromJson(
  Map<String, dynamic> json,
) => _ProjectTilesetPixelRect(
  x: (json['x'] as num).toInt(),
  y: (json['y'] as num).toInt(),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
);

Map<String, dynamic> _$ProjectTilesetPixelRectToJson(
  _ProjectTilesetPixelRect instance,
) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
  'width': instance.width,
  'height': instance.height,
};

_ProjectTilesetPixelPoint _$ProjectTilesetPixelPointFromJson(
  Map<String, dynamic> json,
) => _ProjectTilesetPixelPoint(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
);

Map<String, dynamic> _$ProjectTilesetPixelPointToJson(
  _ProjectTilesetPixelPoint instance,
) => <String, dynamic>{'x': instance.x, 'y': instance.y};

_ProjectTilesetCollisionObject _$ProjectTilesetCollisionObjectFromJson(
  Map<String, dynamic> json,
) => _ProjectTilesetCollisionObject(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String? ?? '',
  type: json['type'] as String? ?? '',
  shape:
      $enumDecodeNullable(
        _$ProjectTilesetCollisionShapeEnumMap,
        json['shape'],
      ) ??
      ProjectTilesetCollisionShape.rectangle,
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  width: (json['width'] as num?)?.toDouble() ?? 0,
  height: (json['height'] as num?)?.toDouble() ?? 0,
  rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
  points:
      (json['points'] as List<dynamic>?)
          ?.map(
            (e) => ProjectTilesetPixelPoint.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ProjectTilesetPixelPoint>[],
  properties:
      (json['properties'] as List<dynamic>?)
          ?.map(
            (e) => ProjectTilesetProperty.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ProjectTilesetProperty>[],
);

Map<String, dynamic> _$ProjectTilesetCollisionObjectToJson(
  _ProjectTilesetCollisionObject instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'shape': _$ProjectTilesetCollisionShapeEnumMap[instance.shape]!,
  'x': instance.x,
  'y': instance.y,
  'width': instance.width,
  'height': instance.height,
  'rotation': instance.rotation,
  'points': instance.points.map((e) => e.toJson()).toList(),
  'properties': instance.properties.map((e) => e.toJson()).toList(),
};

const _$ProjectTilesetCollisionShapeEnumMap = {
  ProjectTilesetCollisionShape.rectangle: 'rectangle',
  ProjectTilesetCollisionShape.ellipse: 'ellipse',
  ProjectTilesetCollisionShape.polygon: 'polygon',
  ProjectTilesetCollisionShape.polyline: 'polyline',
  ProjectTilesetCollisionShape.point: 'point',
};

_ProjectImageCollectionPage _$ProjectImageCollectionPageFromJson(
  Map<String, dynamic> json,
) => _ProjectImageCollectionPage(
  id: json['id'] as String,
  assetId: json['assetId'] as String,
  pixelWidth: (json['pixelWidth'] as num).toInt(),
  pixelHeight: (json['pixelHeight'] as num).toInt(),
);

Map<String, dynamic> _$ProjectImageCollectionPageToJson(
  _ProjectImageCollectionPage instance,
) => <String, dynamic>{
  'id': instance.id,
  'assetId': instance.assetId,
  'pixelWidth': instance.pixelWidth,
  'pixelHeight': instance.pixelHeight,
};

_ProjectImageCollectionAnimationFrame
_$ProjectImageCollectionAnimationFrameFromJson(Map<String, dynamic> json) =>
    _ProjectImageCollectionAnimationFrame(
      tileId: (json['tileId'] as num).toInt(),
      durationMs: (json['durationMs'] as num).toInt(),
    );

Map<String, dynamic> _$ProjectImageCollectionAnimationFrameToJson(
  _ProjectImageCollectionAnimationFrame instance,
) => <String, dynamic>{
  'tileId': instance.tileId,
  'durationMs': instance.durationMs,
};

_ProjectRegularAtlasTileAnimation _$ProjectRegularAtlasTileAnimationFromJson(
  Map<String, dynamic> json,
) => _ProjectRegularAtlasTileAnimation(
  tileId: (json['tileId'] as num).toInt(),
  frames: (json['frames'] as List<dynamic>)
      .map(
        (e) => ProjectImageCollectionAnimationFrame.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
);

Map<String, dynamic> _$ProjectRegularAtlasTileAnimationToJson(
  _ProjectRegularAtlasTileAnimation instance,
) => <String, dynamic>{
  'tileId': instance.tileId,
  'frames': instance.frames.map((e) => e.toJson()).toList(),
};

_ProjectImageCollectionTileDefinition
_$ProjectImageCollectionTileDefinitionFromJson(Map<String, dynamic> json) =>
    _ProjectImageCollectionTileDefinition(
      tileId: (json['tileId'] as num).toInt(),
      pageId: json['pageId'] as String,
      sourceRect: ProjectTilesetPixelRect.fromJson(
        json['sourceRect'] as Map<String, dynamic>,
      ),
      offsetX: (json['offsetX'] as num?)?.toInt() ?? 0,
      offsetY: (json['offsetY'] as num?)?.toInt() ?? 0,
      animation:
          (json['animation'] as List<dynamic>?)
              ?.map(
                (e) => ProjectImageCollectionAnimationFrame.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <ProjectImageCollectionAnimationFrame>[],
      properties:
          (json['properties'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ProjectTilesetProperty.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ProjectTilesetProperty>[],
      collisionObjects:
          (json['collisionObjects'] as List<dynamic>?)
              ?.map(
                (e) => ProjectTilesetCollisionObject.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <ProjectTilesetCollisionObject>[],
    );

Map<String, dynamic> _$ProjectImageCollectionTileDefinitionToJson(
  _ProjectImageCollectionTileDefinition instance,
) => <String, dynamic>{
  'tileId': instance.tileId,
  'pageId': instance.pageId,
  'sourceRect': instance.sourceRect.toJson(),
  'offsetX': instance.offsetX,
  'offsetY': instance.offsetY,
  'animation': instance.animation.map((e) => e.toJson()).toList(),
  'properties': instance.properties.map((e) => e.toJson()).toList(),
  'collisionObjects': instance.collisionObjects.map((e) => e.toJson()).toList(),
};
