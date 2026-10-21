import 'dart:convert';

import '../operations/narrative_event_canonical_json.dart';
import 'enums.dart';
import 'geometry.dart';
import 'map_data.dart';
import 'map_event_definition.dart';
import 'map_spatial_scene.dart';
import 'moving_platform.dart';
import 'moving_prop.dart';
import 'narrative_map_view.dart';

final class NarrativeMapProjection implements NarrativeMapView {
  NarrativeMapProjection._({
    required this.id,
    required this.name,
    required this.version,
    required this.size,
    required this.spatialScene,
    required this.sourceMapFingerprint,
    required List<String> layerIds,
    required List<MapEntity> entities,
    required List<MapTrigger> triggers,
    required List<MapEventDefinition> events,
    required List<MapWarp> warps,
    required List<MovingPropDefinition> movingProps,
    required List<MovingPlatformDefinition> movingPlatforms,
    required List<MapPlacedElement> placedElements,
  }) : layerIds = List.unmodifiable(layerIds),
       entities = List.unmodifiable(entities),
       triggers = List.unmodifiable(triggers),
       events = List.unmodifiable(events),
       warps = List.unmodifiable(warps),
       movingProps = List.unmodifiable(movingProps),
       movingPlatforms = List.unmodifiable(movingPlatforms),
       placedElements = List.unmodifiable(placedElements);

  factory NarrativeMapProjection.fromMapData(MapData map) {
    final original = map.toJson();
    return NarrativeMapProjection.fromJson({
      'formatVersion': 1,
      'sourceMapFingerprint':
          'sha256:${narrativeEventCanonicalSha256(jsonDecode(jsonEncode(original)))}',
      'id': map.id,
      'name': map.name,
      'version': map.version.name,
      'size': map.size.toJson(),
      'spatialScene': map.spatialScene?.toJson(),
      'layerIds': narrativeMapLayerIds(map),
      'entities': [for (final value in map.entities) value.toJson()],
      'triggers': [for (final value in map.triggers) value.toJson()],
      'events': [for (final value in map.events) value.toJson()],
      'warps': [for (final value in map.warps) value.toJson()],
      'movingProps': [for (final value in map.movingProps) value.toJson()],
      'movingPlatforms': [
        for (final value in map.movingPlatforms) value.toJson(),
      ],
      'placedElements': [
        for (final value in map.placedElements)
          if (value.behaviors.isNotEmpty) value.toJson(),
      ],
    });
  }

  factory NarrativeMapProjection.fromJson(Map<String, Object?> source) {
    const keys = {
      'formatVersion',
      'sourceMapFingerprint',
      'id',
      'name',
      'version',
      'size',
      'spatialScene',
      'layerIds',
      'entities',
      'triggers',
      'events',
      'warps',
      'movingProps',
      'movingPlatforms',
      'placedElements',
    };
    if (source.length != keys.length ||
        !source.keys.every(keys.contains) ||
        source['formatVersion'] is! int ||
        source['formatVersion'] != 1) {
      throw const FormatException('Invalid narrative map projection schema.');
    }
    try {
      final json = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
      final fingerprint = json['sourceMapFingerprint'];
      if (fingerprint is! String ||
          !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(fingerprint)) {
        throw const FormatException(
          'Invalid narrative map source fingerprint.',
        );
      }
      final version = ProjectVersion.values.singleWhere(
        (value) => value.name == json['version'],
      );
      final size = _object(json['size']);
      if (size.length != 2 || size['width'] is! int || size['height'] is! int) {
        throw const FormatException('Invalid narrative map size.');
      }
      return NarrativeMapProjection._(
        id: json['id'] as String,
        name: json['name'] as String,
        version: version,
        size: GridSize.fromJson(size),
        spatialScene: json['spatialScene'] == null
            ? null
            : MapSpatialScene.fromJson(_object(json['spatialScene'])),
        sourceMapFingerprint: fingerprint,
        layerIds: (json['layerIds'] as List).cast<String>(),
        entities: _decodeList(json['entities'], MapEntity.fromJson),
        triggers: _decodeList(json['triggers'], MapTrigger.fromJson),
        events: _decodeList(json['events'], MapEventDefinition.fromJson),
        warps: _decodeList(json['warps'], MapWarp.fromJson),
        movingProps: _decodeList(
          json['movingProps'],
          MovingPropDefinition.fromJson,
        ),
        movingPlatforms: _decodeList(
          json['movingPlatforms'],
          MovingPlatformDefinition.fromJson,
        ),
        placedElements: _decodeList(
          json['placedElements'],
          MapPlacedElement.fromJson,
        ),
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid narrative map projection: $error');
    }
  }

  @override
  final String id;
  @override
  final String name;
  @override
  final ProjectVersion version;
  @override
  final GridSize size;
  @override
  final MapSpatialScene? spatialScene;
  final String sourceMapFingerprint;
  final List<String> layerIds;
  @override
  final List<MapEntity> entities;
  @override
  final List<MapTrigger> triggers;
  @override
  final List<MapEventDefinition> events;
  @override
  final List<MapWarp> warps;
  @override
  final List<MovingPropDefinition> movingProps;
  @override
  final List<MovingPlatformDefinition> movingPlatforms;
  @override
  final List<MapPlacedElement> placedElements;

  Map<String, Object?> toJson() => {
    'formatVersion': 1,
    'sourceMapFingerprint': sourceMapFingerprint,
    'id': id,
    'name': name,
    'version': version.name,
    'size': size.toJson(),
    'spatialScene': spatialScene?.toJson(),
    'layerIds': layerIds,
    'entities': [for (final value in entities) value.toJson()],
    'triggers': [for (final value in triggers) value.toJson()],
    'events': [for (final value in events) value.toJson()],
    'warps': [for (final value in warps) value.toJson()],
    'movingProps': [for (final value in movingProps) value.toJson()],
    'movingPlatforms': [for (final value in movingPlatforms) value.toJson()],
    'placedElements': [for (final value in placedElements) value.toJson()],
  };
}

Map<String, dynamic> _object(Object? value) =>
    Map<String, dynamic>.from(value! as Map);

List<T> _decodeList<T>(
  Object? value,
  T Function(Map<String, dynamic>) decode,
) => [for (final item in value! as List) decode(_object(item))];
