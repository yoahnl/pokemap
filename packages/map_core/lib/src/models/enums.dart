import 'package:freezed_annotation/freezed_annotation.dart';

enum ProjectVersion { v1 }

enum MapGroupType {
  @JsonValue('city') city,
  @JsonValue('village') village,
  @JsonValue('route') route,
  @JsonValue('dungeon') dungeon,
  @JsonValue('cave') cave,
  @JsonValue('forest') forest,
  @JsonValue('tower') tower,
  @JsonValue('facility') facility,
  @JsonValue('special') special,
}

enum MapRole {
  @JsonValue('exterior') exterior,
  @JsonValue('interior') interior,
  @JsonValue('basement') basement,
  @JsonValue('upper_floor') upper_floor,
  @JsonValue('connector') connector,
  @JsonValue('gate') gate,
  @JsonValue('room') room,
  @JsonValue('section') section,
  @JsonValue('sub_area') sub_area,
}

enum EntityType {
  @JsonValue('npc') npc,
  @JsonValue('monster') monster,
  @JsonValue('chest') chest,
  @JsonValue('sign') sign,
  @JsonValue('custom') custom,
}

enum TriggerType {
  @JsonValue('script') script,
  @JsonValue('sound') sound,
  @JsonValue('cutscene') cutscene,
  @JsonValue('battle') battle,
  @JsonValue('custom') custom,
}
