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

enum MapConnectionDirection {
  @JsonValue('north')
  north,
  @JsonValue('south')
  south,
  @JsonValue('east')
  east,
  @JsonValue('west')
  west,
}

extension MapConnectionDirectionX on MapConnectionDirection {
  MapConnectionDirection get opposite => switch (this) {
        MapConnectionDirection.north => MapConnectionDirection.south,
        MapConnectionDirection.south => MapConnectionDirection.north,
        MapConnectionDirection.east => MapConnectionDirection.west,
        MapConnectionDirection.west => MapConnectionDirection.east,
      };

  bool get usesHorizontalOffset =>
      this == MapConnectionDirection.north ||
      this == MapConnectionDirection.south;
}

enum MapEntityKind {
  @JsonValue('npc')
  npc,
  @JsonValue('sign')
  sign,
  @JsonValue('item')
  item,
  @JsonValue('spawn')
  spawn,
  @JsonValue('custom')
  custom,
}

enum TriggerType {
  @JsonValue('warp')
  warp,
  @JsonValue('message')
  message,
  @JsonValue('interaction')
  interaction,
  @JsonValue('event')
  event,
  @JsonValue('spawn')
  spawn,
  @JsonValue('camera')
  camera,
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
  @JsonValue('path')
  path,
  @JsonValue('object')
  object,
}

enum TerrainType {
  @JsonValue('none')
  none,
  @JsonValue('grass')
  grass,
  @JsonValue('dirt')
  dirt,
  @JsonValue('sand')
  sand,
  @JsonValue('rock')
  rock,
  @JsonValue('stone')
  stone,
  @JsonValue('indoor')
  indoor,
}

extension TerrainTypeX on TerrainType {
  bool get isBackgroundPaintable => this != TerrainType.none;
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
  innerCornerNE,
  innerCornerSE,
  innerCornerSW,
  innerCornerNW,
  teeNorth,
  teeEast,
  teeSouth,
  teeWest,
  cross,
}

enum PresetLibraryKind {
  @JsonValue('terrain')
  terrain,
  @JsonValue('path')
  path,
}

enum PathSurfaceKind {
  @JsonValue('path')
  path,
  @JsonValue('road')
  road,
  @JsonValue('water')
  water,
  @JsonValue('tall_grass')
  tallGrass,
  @JsonValue('ice')
  ice,
  @JsonValue('lava')
  lava,
  @JsonValue('swamp')
  swamp,
  @JsonValue('rails')
  rails,
  @JsonValue('bridge')
  bridge,
  @JsonValue('special')
  special,
  @JsonValue('custom')
  custom,
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
