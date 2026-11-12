import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';

extension StudioLabels on AppLocalizations {
  String obstacleKindName(FieldObstacleKind kind) => switch (kind) {
    FieldObstacleKind.cutTree => obstacleCutTree,
    FieldObstacleKind.strengthBoulder => obstacleStrengthBoulder,
    FieldObstacleKind.rockSmashRock => obstacleRockSmashRock,
    FieldObstacleKind.iceBlock => obstacleIceBlock,
  };

  String obstacleResetName(FieldObstacleResetPolicy policy) => switch (policy) {
    FieldObstacleResetPolicy.mapInstance => obstacleResetMapInstance,
    FieldObstacleResetPolicy.persistent => obstacleResetPersistent,
  };

  String encounterKindName(EncounterKind kind) => switch (kind) {
    EncounterKind.walk => encounterKindWalk,
    EncounterKind.surf => encounterKindSurf,
    EncounterKind.headbutt => encounterKindHeadbutt,
    EncounterKind.oldRod => encounterKindOldRod,
    EncounterKind.goodRod => encounterKindGoodRod,
    EncounterKind.superRod => encounterKindSuperRod,
    EncounterKind.gift => encounterKindGift,
    EncounterKind.special => encounterKindSpecial,
  };

  String movementMode(MovementMode mode) => switch (mode) {
    MovementMode.walk => movementModeWalk,
    MovementMode.surf => movementModeSurf,
    MovementMode.dive => movementModeDive,
    MovementMode.fly => movementModeFly,
    MovementMode.cut => movementModeCut,
    MovementMode.bicycle => movementModeBicycle,
    MovementMode.strength => movementModeStrength,
    MovementMode.rockSmash => movementModeRockSmash,
  };

  String movementEffect(MovementEffectZoneKind kind) => switch (kind) {
    MovementEffectZoneKind.slide => effectSlide,
    MovementEffectZoneKind.movementCost => effectMovementCost,
    MovementEffectZoneKind.directedJump => effectDirectedJump,
  };

  String spawnRoleName(EntitySpawnRole role) => switch (role) {
    EntitySpawnRole.playerStart => spawnRolePlayerStart,
    EntitySpawnRole.event => spawnRoleEvent,
    EntitySpawnRole.npcSpawn => spawnRoleNpcSpawn,
    EntitySpawnRole.debug => spawnRoleDebug,
    EntitySpawnRole.other => spawnRoleOther,
  };

  String facing(EntityFacing facing) => switch (facing) {
    EntityFacing.north => facingNorth,
    EntityFacing.south => facingSouth,
    EntityFacing.east => facingEast,
    EntityFacing.west => facingWest,
  };

  String direction(MapConnectionDirection direction) => switch (direction) {
    MapConnectionDirection.north => directionNorth,
    MapConnectionDirection.east => directionEast,
    MapConnectionDirection.south => directionSouth,
    MapConnectionDirection.west => directionWest,
  };

  String mapRole(MapRole role) => switch (role) {
    MapRole.exterior => roleExterior,
    MapRole.interior => roleInterior,
    MapRole.basement => roleBasement,
    MapRole.upper_floor => roleUpperFloor,
    MapRole.connector => roleConnector,
    MapRole.gate => roleGate,
    MapRole.room => roleRoom,
    MapRole.section => roleSection,
    MapRole.sub_area => roleSubArea,
  };

  String resourceCategory(ResourceUsageCategory category) => switch (category) {
    ResourceUsageCategory.vegetation => categoryVegetation,
    ResourceUsageCategory.ground => categoryGround,
    ResourceUsageCategory.path => categoryPath,
    ResourceUsageCategory.water => categoryWater,
    ResourceUsageCategory.relief => categoryRelief,
    ResourceUsageCategory.building => categoryBuilding,
    ResourceUsageCategory.furniture => categoryFurniture,
    ResourceUsageCategory.object => categoryObject,
  };

  String resourceType(ResourceItem item) => switch (item.canonicalKind) {
    'element' => typeDecor,
    'model3d' => typeModel,
    'smartTilePreset' => typeSmartTile,
    'tileset' => typeImage,
    'borderBlueprint' => typeBorder,
    'environmentPreset' => typeEnvironment,
    'character' => typeCharacter,
    _ => switch (item.kind) {
      ResourceKind.decors => typeDecor,
      ResourceKind.terrains => typeSmartTile,
      ResourceKind.images => typeImage,
    },
  };

  String resourceContext(ResourceCatalogContext context) => switch (context) {
    ResourceCatalogContext.all => contextAll,
    ResourceCatalogContext.interior => contextInterior,
    ResourceCatalogContext.exterior => contextExterior,
    ResourceCatalogContext.unspecified => contextUnspecified,
  };
}
