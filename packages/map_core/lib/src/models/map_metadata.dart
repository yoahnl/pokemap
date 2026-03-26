import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_metadata.freezed.dart';
part 'map_metadata.g.dart';

enum MapType {
  @JsonValue('route')
  route,
  @JsonValue('city')
  city,
  @JsonValue('building')
  building,
  @JsonValue('interior')
  interior,
  @JsonValue('cave')
  cave,
  @JsonValue('forest')
  forest,
  @JsonValue('facility')
  facility,
  @JsonValue('special')
  special,
  @JsonValue('custom')
  custom,
}

enum MapWeather {
  @JsonValue('none')
  none,
  @JsonValue('rain')
  rain,
  @JsonValue('storm')
  storm,
  @JsonValue('snow')
  snow,
  @JsonValue('fog')
  fog,
  @JsonValue('sandstorm')
  sandstorm,
  @JsonValue('harsh_sunlight')
  harshSunlight,
  @JsonValue('custom')
  custom,
}

@freezed
class MapMetadata with _$MapMetadata {
  @JsonSerializable(explicitToJson: true)
  const factory MapMetadata({
    @Default('') String displayName,
    @Default(MapType.route) MapType mapType,
    String? musicId,
    @Default(MapWeather.none) MapWeather weather,
    @Default(false) bool isIndoor,
    @Default(true) bool allowEscapeRope,
    String? defaultSpawnId,
    @Default([]) List<String> tags,
  }) = _MapMetadata;

  factory MapMetadata.fromJson(Map<String, dynamic> json) =>
      _$MapMetadataFromJson(json);
}
