// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MapMetadata _$MapMetadataFromJson(Map<String, dynamic> json) => _MapMetadata(
  displayName: json['displayName'] as String? ?? '',
  mapType:
      $enumDecodeNullable(_$MapTypeEnumMap, json['mapType']) ?? MapType.route,
  musicPath: json['musicPath'] as String?,
  musicVolume: _mapMusicVolumeFromJson(json['musicVolume']),
  battleMusicPath: json['battleMusicPath'] as String?,
  weather:
      $enumDecodeNullable(_$MapWeatherEnumMap, json['weather']) ??
      MapWeather.none,
  isIndoor: json['isIndoor'] as bool? ?? false,
  allowBicycle: json['allowBicycle'] as bool? ?? true,
  allowEscapeRope: json['allowEscapeRope'] as bool? ?? true,
  escapeRopeDungeonId: json['escapeRopeDungeonId'] as String?,
  defaultSpawnId: json['defaultSpawnId'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$MapMetadataToJson(_MapMetadata instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'mapType': _$MapTypeEnumMap[instance.mapType]!,
      'musicPath': instance.musicPath,
      'musicVolume': instance.musicVolume,
      'battleMusicPath': instance.battleMusicPath,
      'weather': _$MapWeatherEnumMap[instance.weather]!,
      'isIndoor': instance.isIndoor,
      'allowBicycle': instance.allowBicycle,
      'allowEscapeRope': instance.allowEscapeRope,
      'escapeRopeDungeonId': instance.escapeRopeDungeonId,
      'defaultSpawnId': instance.defaultSpawnId,
      'tags': instance.tags,
    };

const _$MapTypeEnumMap = {
  MapType.route: 'route',
  MapType.city: 'city',
  MapType.building: 'building',
  MapType.interior: 'interior',
  MapType.cave: 'cave',
  MapType.forest: 'forest',
  MapType.facility: 'facility',
  MapType.special: 'special',
  MapType.custom: 'custom',
};

const _$MapWeatherEnumMap = {
  MapWeather.none: 'none',
  MapWeather.rain: 'rain',
  MapWeather.storm: 'storm',
  MapWeather.snow: 'snow',
  MapWeather.fog: 'fog',
  MapWeather.sandstorm: 'sandstorm',
  MapWeather.harshSunlight: 'harsh_sunlight',
  MapWeather.custom: 'custom',
};
