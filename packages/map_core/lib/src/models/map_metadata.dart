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
abstract class MapMetadata with _$MapMetadata {
  @JsonSerializable(explicitToJson: true)
  const factory MapMetadata({
    @Default('') String displayName,
    @Default(MapType.route) MapType mapType,

    /// Musique d'ambiance de la carte — BETA-BAT-015 (parité RMXP
    /// `Game_Map#autoplay`). Chemin relatif au projet ; nul = silence.
    /// S'appelait `musicId` sans catalogue derrière (politique pré-1.0.0 :
    /// renommage propre, aucun porteur de valeur dans les données).
    String? musicPath,

    /// Musique de combat des rencontres sur cette carte — BETA-BAT-015.
    ///
    /// Chemin relatif au projet. C'est l'analogue déclaratif du « Change
    /// Battle BGM » persistant de la référence : un écart assumé, parce que ce
    /// moteur n'a pas d'interpréteur d'événements et que le no-code first
    /// préfère un champ de carte à un état de sauvegarde invisible.
    String? battleMusicPath,
    @Default(MapWeather.none) MapWeather weather,
    @Default(false) bool isIndoor,
    @Default(true) bool allowEscapeRope,
    String? defaultSpawnId,
    @Default([]) List<String> tags,
  }) = _MapMetadata;

  factory MapMetadata.fromJson(Map<String, dynamic> json) =>
      _$MapMetadataFromJson(json);
}
