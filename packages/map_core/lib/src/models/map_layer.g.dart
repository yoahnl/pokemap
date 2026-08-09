// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TileLayerPaletteEntry _$TileLayerPaletteEntryFromJson(
  Map<String, dynamic> json,
) => _TileLayerPaletteEntry(
  tilesetId: json['tilesetId'] as String,
  localTileId: (json['localTileId'] as num).toInt(),
  transform: json['transform'] == null
      ? const SmartTileSpriteTransform()
      : SmartTileSpriteTransform.fromJson(
          json['transform'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$TileLayerPaletteEntryToJson(
  _TileLayerPaletteEntry instance,
) => <String, dynamic>{
  'tilesetId': instance.tilesetId,
  'localTileId': instance.localTileId,
  'transform': instance.transform.toJson(),
};

_MapPlacedTile _$MapPlacedTileFromJson(Map<String, dynamic> json) =>
    _MapPlacedTile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      className: json['className'] as String? ?? '',
      tile: TileLayerPaletteEntry.fromJson(
        json['tile'] as Map<String, dynamic>,
      ),
      anchorX: (json['anchorX'] as num).toDouble(),
      anchorY: (json['anchorY'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      quarterTurns: (json['quarterTurns'] as num?)?.toInt() ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      importMetadata:
          json['importMetadata'] as Map<String, dynamic>? ??
          const <String, Object?>{},
    );

Map<String, dynamic> _$MapPlacedTileToJson(_MapPlacedTile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'className': instance.className,
      'tile': instance.tile.toJson(),
      'anchorX': instance.anchorX,
      'anchorY': instance.anchorY,
      'width': instance.width,
      'height': instance.height,
      'quarterTurns': instance.quarterTurns,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'importMetadata': instance.importMetadata,
    };

TileLayer _$TileLayerFromJson(Map<String, dynamic> json) => TileLayer(
  id: json['id'] as String,
  name: json['name'] as String,
  isVisible: json['isVisible'] as bool? ?? true,
  opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
  purpose:
      $enumDecodeNullable(_$MapLayerPurposeEnumMap, json['purpose']) ??
      MapLayerPurpose.visual,
  palette:
      (json['palette'] as List<dynamic>?)
          ?.map(
            (e) => TileLayerPaletteEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <TileLayerPaletteEntry>[],
  cells:
      (json['cells'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$TileLayerToJson(TileLayer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'isVisible': instance.isVisible,
  'opacity': instance.opacity,
  'purpose': _$MapLayerPurposeEnumMap[instance.purpose]!,
  'palette': instance.palette.map((e) => e.toJson()).toList(),
  'cells': instance.cells,
  'runtimeType': instance.$type,
};

const _$MapLayerPurposeEnumMap = {
  MapLayerPurpose.visual: 'visual',
  MapLayerPurpose.data: 'data',
};

CollisionLayer _$CollisionLayerFromJson(Map<String, dynamic> json) =>
    CollisionLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      collisions:
          (json['collisions'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CollisionLayerToJson(CollisionLayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'collisions': instance.collisions,
      'runtimeType': instance.$type,
    };

SmartTileLayer _$SmartTileLayerFromJson(Map<String, dynamic> json) =>
    SmartTileLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      presetId: json['presetId'] as String,
      usage: $enumDecode(_$SmartTileUsageEnumMap, json['usage']),
      materialPalette:
          (json['materialPalette'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[''],
      field: SmartTileField.fromJson(json['field'] as Map<String, dynamic>),
      patternStrokes:
          (json['patternStrokes'] as List<dynamic>?)
              ?.map(
                (e) =>
                    SmartTilePatternStroke.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <SmartTilePatternStroke>[],
      layerSeed: (json['layerSeed'] as num?)?.toInt() ?? 0,
      candidateWeights:
          (json['candidateWeights'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      properties:
          (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$SmartTileLayerToJson(SmartTileLayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'presetId': instance.presetId,
      'usage': _$SmartTileUsageEnumMap[instance.usage]!,
      'materialPalette': instance.materialPalette,
      'field': instance.field.toJson(),
      'patternStrokes': instance.patternStrokes.map((e) => e.toJson()).toList(),
      'layerSeed': instance.layerSeed,
      'candidateWeights': ?_candidateWeightsToJson(instance.candidateWeights),
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };

const _$SmartTileUsageEnumMap = {
  SmartTileUsage.terrain: 'terrain',
  SmartTileUsage.path: 'path',
  SmartTileUsage.forestSurface: 'forest_surface',
};

ObjectLayer _$ObjectLayerFromJson(Map<String, dynamic> json) => ObjectLayer(
  id: json['id'] as String,
  name: json['name'] as String,
  isVisible: json['isVisible'] as bool? ?? true,
  opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
  purpose:
      $enumDecodeNullable(_$MapLayerPurposeEnumMap, json['purpose']) ??
      MapLayerPurpose.visual,
  tileObjects:
      (json['tileObjects'] as List<dynamic>?)
          ?.map((e) => MapPlacedTile.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MapPlacedTile>[],
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ObjectLayerToJson(ObjectLayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'purpose': _$MapLayerPurposeEnumMap[instance.purpose]!,
      'tileObjects': instance.tileObjects.map((e) => e.toJson()).toList(),
      'runtimeType': instance.$type,
    };

EnvironmentLayer _$EnvironmentLayerFromJson(Map<String, dynamic> json) =>
    EnvironmentLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      content: json['content'] == null
          ? EnvironmentLayerContent.emptyContent
          : decodeEnvironmentLayerContent(json['content']),
      properties:
          (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$EnvironmentLayerToJson(EnvironmentLayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'content': encodeEnvironmentLayerContent(instance.content),
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };

BorderLayer _$BorderLayerFromJson(Map<String, dynamic> json) => BorderLayer(
  id: json['id'] as String,
  name: json['name'] as String,
  isVisible: json['isVisible'] as bool? ?? true,
  opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
  content: _readBorderLayerContent(json, 'content') == null
      ? BorderLayerContent.emptyContent
      : _borderLayerContentFromJson(_readBorderLayerContent(json, 'content')),
  properties:
      (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$BorderLayerToJson(BorderLayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'content': _borderLayerContentToJson(instance.content),
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };
