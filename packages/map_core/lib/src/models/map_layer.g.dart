// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TileLayerPaletteEntryImpl _$$TileLayerPaletteEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$TileLayerPaletteEntryImpl(
      tilesetId: json['tilesetId'] as String,
      localTileId: (json['localTileId'] as num).toInt(),
      transform: json['transform'] == null
          ? const SmartTileSpriteTransform()
          : SmartTileSpriteTransform.fromJson(
              json['transform'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TileLayerPaletteEntryImplToJson(
        _$TileLayerPaletteEntryImpl instance) =>
    <String, dynamic>{
      'tilesetId': instance.tilesetId,
      'localTileId': instance.localTileId,
      'transform': instance.transform.toJson(),
    };

_$MapPlacedTileImpl _$$MapPlacedTileImplFromJson(Map<String, dynamic> json) =>
    _$MapPlacedTileImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      className: json['className'] as String? ?? '',
      tile:
          TileLayerPaletteEntry.fromJson(json['tile'] as Map<String, dynamic>),
      anchorX: (json['anchorX'] as num).toDouble(),
      anchorY: (json['anchorY'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      quarterTurns: (json['quarterTurns'] as num?)?.toInt() ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      importMetadata: json['importMetadata'] as Map<String, dynamic>? ??
          const <String, Object?>{},
    );

Map<String, dynamic> _$$MapPlacedTileImplToJson(_$MapPlacedTileImpl instance) =>
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

_$TileLayerImpl _$$TileLayerImplFromJson(Map<String, dynamic> json) =>
    _$TileLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      purpose: $enumDecodeNullable(_$MapLayerPurposeEnumMap, json['purpose']) ??
          MapLayerPurpose.visual,
      palette: (json['palette'] as List<dynamic>?)
              ?.map((e) =>
                  TileLayerPaletteEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TileLayerPaletteEntry>[],
      cells: (json['cells'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TileLayerImplToJson(_$TileLayerImpl instance) =>
    <String, dynamic>{
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

_$CollisionLayerImpl _$$CollisionLayerImplFromJson(Map<String, dynamic> json) =>
    _$CollisionLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      collisions: (json['collisions'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$CollisionLayerImplToJson(
        _$CollisionLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'collisions': instance.collisions,
      'runtimeType': instance.$type,
    };

_$SmartTileLayerImpl _$$SmartTileLayerImplFromJson(Map<String, dynamic> json) =>
    _$SmartTileLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      presetId: json['presetId'] as String,
      usage: $enumDecode(_$SmartTileUsageEnumMap, json['usage']),
      materialPalette: (json['materialPalette'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[''],
      field: SmartTileField.fromJson(json['field'] as Map<String, dynamic>),
      patternStrokes: (json['patternStrokes'] as List<dynamic>?)
              ?.map((e) =>
                  SmartTilePatternStroke.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SmartTilePatternStroke>[],
      layerSeed: (json['layerSeed'] as num?)?.toInt() ?? 0,
      candidateWeights:
          (json['candidateWeights'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              const <String, int>{},
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$SmartTileLayerImplToJson(
        _$SmartTileLayerImpl instance) =>
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
      if (_candidateWeightsToJson(instance.candidateWeights) case final value?)
        'candidateWeights': value,
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };

const _$SmartTileUsageEnumMap = {
  SmartTileUsage.terrain: 'terrain',
  SmartTileUsage.path: 'path',
  SmartTileUsage.forestSurface: 'forest_surface',
};

_$ObjectLayerImpl _$$ObjectLayerImplFromJson(Map<String, dynamic> json) =>
    _$ObjectLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      purpose: $enumDecodeNullable(_$MapLayerPurposeEnumMap, json['purpose']) ??
          MapLayerPurpose.visual,
      tileObjects: (json['tileObjects'] as List<dynamic>?)
              ?.map((e) => MapPlacedTile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MapPlacedTile>[],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ObjectLayerImplToJson(_$ObjectLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'purpose': _$MapLayerPurposeEnumMap[instance.purpose]!,
      'tileObjects': instance.tileObjects.map((e) => e.toJson()).toList(),
      'runtimeType': instance.$type,
    };

_$EnvironmentLayerImpl _$$EnvironmentLayerImplFromJson(
        Map<String, dynamic> json) =>
    _$EnvironmentLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      content: json['content'] == null
          ? EnvironmentLayerContent.emptyContent
          : decodeEnvironmentLayerContent(json['content']),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$EnvironmentLayerImplToJson(
        _$EnvironmentLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'content': encodeEnvironmentLayerContent(instance.content),
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };

_$BorderLayerImpl _$$BorderLayerImplFromJson(Map<String, dynamic> json) =>
    _$BorderLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      content: _readBorderLayerContent(json, 'content') == null
          ? BorderLayerContent.emptyContent
          : _borderLayerContentFromJson(
              _readBorderLayerContent(json, 'content')),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$BorderLayerImplToJson(_$BorderLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'content': _borderLayerContentToJson(instance.content),
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };
