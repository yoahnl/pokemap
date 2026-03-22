import 'package:freezed_annotation/freezed_annotation.dart';

enum ProjectVersion { v1 }

enum MapGroupType {
  @JsonValue('city')
  city,
  @JsonValue('village')
  village,
  @JsonValue('route')
  route,
  @JsonValue('dungeon')
  dungeon,
  @JsonValue('cave')
  cave,
  @JsonValue('forest')
  forest,
  @JsonValue('tower')
  tower,
  @JsonValue('facility')
  facility,
  @JsonValue('special')
  special,
}

enum MapRole {
  @JsonValue('exterior')
  exterior,
  @JsonValue('interior')
  interior,
  @JsonValue('basement')
  basement,
  @JsonValue('upper_floor')
  upper_floor,
  @JsonValue('connector')
  connector,
  @JsonValue('gate')
  gate,
  @JsonValue('room')
  room,
  @JsonValue('section')
  section,
  @JsonValue('sub_area')
  sub_area,
}

enum EntityType {
  @JsonValue('npc')
  npc,
  @JsonValue('monster')
  monster,
  @JsonValue('chest')
  chest,
  @JsonValue('sign')
  sign,
  @JsonValue('custom')
  custom,
}

enum TriggerType {
  @JsonValue('script')
  script,
  @JsonValue('sound')
  sound,
  @JsonValue('cutscene')
  cutscene,
  @JsonValue('battle')
  battle,
  @JsonValue('custom')
  custom,
}

enum MapLayerKind {
  @JsonValue('tile')
  tile,
  @JsonValue('collision')
  collision,
  @JsonValue('terrain')
  terrain,
  @JsonValue('object')
  object,
}

enum TerrainType {
  @JsonValue('none')
  none,
  @JsonValue('normal')
  normal,
  @JsonValue('path')
  path,
  @JsonValue('water')
  water,
  @JsonValue('tallGrass')
  tallGrass,
  @JsonValue('sand')
  sand,
  @JsonValue('ice')
  ice,
}

enum TerrainPathVariant {
  isolated,
  endNorth,
  endEast,
  endSouth,
  endWest,
  horizontal,
  vertical,
  cornerNE,
  cornerSE,
  cornerSW,
  cornerNW,
  teeNorth,
  teeEast,
  teeSouth,
  teeWest,
  cross,
}

enum TilesetScope {
  @JsonValue('global')
  global,
  @JsonValue('group')
  group,
}

enum PaletteCategory {
  @JsonValue('floors')
  floors,
  @JsonValue('paths')
  paths,
  @JsonValue('water')
  water,
  @JsonValue('buildings')
  buildings,
  @JsonValue('roofs')
  roofs,
  @JsonValue('plants')
  plants,
  @JsonValue('trees')
  trees,
  @JsonValue('cliffs')
  cliffs,
  @JsonValue('decorations')
  decorations,
  @JsonValue('interiors')
  interiors,
  @JsonValue('objects')
  objects,
  @JsonValue('uncategorized')
  uncategorized,
}
