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

/// Orientation d’un sprite / d’un spawn sur la grille (vue top-down).
enum EntityFacing {
  @JsonValue('north')
  north,
  @JsonValue('south')
  south,
  @JsonValue('east')
  east,
  @JsonValue('west')
  west,
}

enum ItemPickupMode {
  @JsonValue('once')
  once,
  @JsonValue('always')
  always,
  @JsonValue('quest_gated')
  questGated,
}

enum ItemRespawnPolicy {
  @JsonValue('none')
  none,
  @JsonValue('on_map_reload')
  onMapReload,
  @JsonValue('timed')
  timed,
}

enum EntitySpawnRole {
  @JsonValue('player_start')
  playerStart,
  @JsonValue('event')
  event,
  @JsonValue('npc_spawn')
  npcSpawn,
  @JsonValue('debug')
  debug,
  @JsonValue('other')
  other,
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

/// Kind de zone gameplay posée sur une map.
/// Sépare explicitement le visuel (PathSurfaceKind / TerrainType) du comportement.
///
/// Chaque kind correspond à un payload typé ([EncounterZonePayload],
/// [MovementZonePayload], [HazardZonePayload], [SpecialZonePayload]).
/// `custom` est réservé aux extensions futures — ne pas l'utiliser dans du
/// nouveau code ; préférer un kind typé.
enum GameplayZoneKind {
  @JsonValue('encounter')
  encounter, // Zone de rencontre aléatoire (herbes, grotte, surf, etc.)
  @JsonValue('movement')
  movement, // Zone à contrainte de déplacement (surf requis, glace, etc.)
  @JsonValue('hazard')
  hazard, // Danger environnemental (lave, marais, etc.)
  @JsonValue('special')
  special, // Comportement scripté ou spécial
  /// Fallback non-typé pour les extensions futures.
  /// Ne pas utiliser dans du nouveau code.
  @JsonValue('custom')
  custom,
}

/// Sous-type de danger environnemental pour [GameplayZoneKind.hazard].
enum HazardKind {
  @JsonValue('lava')
  lava, // Contact : dommage direct
  @JsonValue('poison')
  poison, // Empoisonnement au passage
  @JsonValue('swamp')
  swamp, // Ralentissement / enlisement
  @JsonValue('pitfall')
  pitfall, // Chute dans un trou
  @JsonValue('other')
  other,
}

/// Mode de déplacement requis ou appliqué dans une zone gameplay.
enum MovementMode {
  @JsonValue('walk')
  walk,
  @JsonValue('surf')
  surf,
  @JsonValue('fly')
  fly,
  @JsonValue('cut')
  cut,
  @JsonValue('strength')
  strength,
  @JsonValue('rock_smash')
  rockSmash,
}

/// Mode de déclenchement d'une rencontre Pokémon-like.
enum EncounterKind {
  @JsonValue('walk')
  walk, // Herbes hautes, caverne, etc.
  @JsonValue('surf')
  surf, // Navigation sur l'eau
  @JsonValue('headbutt')
  headbutt, // Secouer un arbre
  @JsonValue('old_rod')
  oldRod,
  @JsonValue('good_rod')
  goodRod,
  @JsonValue('super_rod')
  superRod,
  @JsonValue('gift')
  gift, // Rencontre / don statique
  @JsonValue('special')
  special, // Déclenchement ad-hoc
}

enum CharacterAnimationState {
  @JsonValue('idle')
  idle,
  @JsonValue('walk')
  walk,
  @JsonValue('run')
  run,
}

enum TilesetScope {
  @JsonValue('global')
  global,
  @JsonValue('group')
  group,
}

enum ElementPresetKind {
  @JsonValue('generic')
  generic,
  @JsonValue('tree')
  tree,
  @JsonValue('building')
  building,
  @JsonValue('rock')
  rock,
  @JsonValue('cliff')
  cliff,
  @JsonValue('tall_decoration')
  tallDecoration,
}

enum ElementCollisionProfileSource {
  @JsonValue('generated')
  generated,
  @JsonValue('manual')
  manual,
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
