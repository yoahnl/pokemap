import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

class AddGameplayZoneToMapUseCase {
  MapData execute(
    MapData map, {
    ProjectManifest? manifest,
    required MapGameplayZone zone,
  }) {
    final updated = addGameplayZoneToMap(map, zone: zone);
    MapValidator.validate(updated, projectDialogueContext: manifest);
    return updated;
  }
}

class UpdateGameplayZoneOnMapUseCase {
  MapData execute(
    MapData map, {
    ProjectManifest? manifest,
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,

    /// Passer `null` pour effacer le payload, sentinel pour conserver.
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final updated = updateGameplayZoneOnMap(
      map,
      zoneId: zoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
    final canonical = movementEffect is MovementEffectZonePayload
        ? const TriggerZoneActions().setMovementEffectPayload(
            updated,
            zoneId: id?.trim() ?? zoneId,
            payload: movementEffect,
          )
        : updated;
    MapValidator.validate(canonical, projectDialogueContext: manifest);
    return canonical;
  }
}

class DeleteGameplayZoneFromMapUseCase {
  MapData execute(
    MapData map, {
    ProjectManifest? manifest,
    required String zoneId,
  }) {
    final updated = removeGameplayZoneFromMap(map, zoneId: zoneId);
    MapValidator.validate(updated, projectDialogueContext: manifest);
    return updated;
  }
}
