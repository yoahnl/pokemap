import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_entity_field_obstacle.dart';
import '../models/project_manifest.dart';

abstract final class FieldObstacleCapabilities {
  static const capabilityId = 'gameplay.field-obstacles@1';
  static const extendedCapabilityId = 'gameplay.field-obstacles@2';

  static const animationStates = {
    CharacterAnimationState.cut,
    CharacterAnimationState.rockSmash,
  };

  static bool requiresCapability(
    ProjectManifest project, {
    required Iterable<MapData> maps,
  }) =>
      maps.any(
        (map) => map.entities.any(
          (entity) =>
              entity.fieldObstacle != null &&
              !entity.fieldObstacle!.isPushable &&
              (entity.fieldObstacle!.resetPolicy ==
                      FieldObstacleResetPolicy.persistent ||
                  map.spatialScene != null &&
                      !entity.fieldObstacle!.isPushable),
        ),
      ) ||
      project.characters.any(
        (character) => character.animations.any(
          (animation) => animationStates.contains(animation.state),
        ),
      );
  static bool requiresExtendedCapability(
    ProjectManifest project, {
    required Iterable<MapData> maps,
  }) => maps.any((map) => map.entities.any((entity) =>
      entity.fieldObstacle?.kind == FieldObstacleKind.strengthBoulder &&
      (map.spatialScene != null || entity.fieldObstacle!.resetPolicy == FieldObstacleResetPolicy.persistent))) ||
      project.characters.any((character) => character.animations.any((animation) =>
          animation.state == CharacterAnimationState.strength || animation.state == CharacterAnimationState.push));
}

bool isValidSpatialFieldObstacle(MapData map, MapEntity entity) {
  final obstacle = entity.fieldObstacle;
  final scene = map.spatialScene;
  if (scene == null ||
      obstacle == null ||
      obstacle.kind == FieldObstacleKind.iceBlock ||
      entity.kind != MapEntityKind.custom ||
      !entity.blocksMovement ||
      entity.size.width != 1 ||
      entity.size.height != 1 ||
      entity.npc != null ||
      entity.sign != null ||
      entity.item != null ||
      entity.spawn != null ||
      entity.healingDisplay != null ||
      entity.interactiveEncounter != null ||
      entity.presentation != null) {
    return false;
  }
  final bindings = scene.instances
      .where((instance) => instance.entityId == entity.id)
      .toList();
  return bindings.length == 1 &&
      bindings.single.blocksMovement &&
      bindings.single.animationIndex == null &&
      bindings.single.clip == null &&
      !scene.lifts.any((lift) => lift.instanceId == bindings.single.id) &&
      bindings.single.position.x.floor() == entity.pos.x &&
      bindings.single.position.z.floor() == entity.pos.y;
}
