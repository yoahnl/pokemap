// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MapMetadataImpl _$$MapMetadataImplFromJson(Map<String, dynamic> json) =>
    _$MapMetadataImpl(
      displayName: json['displayName'] as String? ?? '',
      mapType: $enumDecodeNullable(_$MapTypeEnumMap, json['mapType']) ??
          MapType.route,
      musicId: json['musicId'] as String?,
      weather: $enumDecodeNullable(_$MapWeatherEnumMap, json['weather']) ??
          MapWeather.none,
      isIndoor: json['isIndoor'] as bool? ?? false,
      allowEscapeRope: json['allowEscapeRope'] as bool? ?? true,
      defaultSpawnId: json['defaultSpawnId'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$MapMetadataImplToJson(_$MapMetadataImpl instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'mapType': _$MapTypeEnumMap[instance.mapType]!,
      'musicId': instance.musicId,
      'weather': _$MapWeatherEnumMap[instance.weather]!,
      'isIndoor': instance.isIndoor,
      'allowEscapeRope': instance.allowEscapeRope,
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
