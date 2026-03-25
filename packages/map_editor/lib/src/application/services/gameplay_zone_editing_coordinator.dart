import 'package:map_core/map_core.dart' as core;

class GameplayZoneEditingCoordinator {
  const GameplayZoneEditingCoordinator();

  core.MapGameplayZone? findZoneAtPos(
    core.MapData map,
    core.GridPos pos,
  ) {
    return core.findGameplayZoneAtPos(map, pos);
  }

  core.MapGameplayZone? findZoneById(
    core.MapData map,
    String zoneId,
  ) {
    return core.findGameplayZoneById(map, zoneId);
  }

  String generateUniqueZoneId(core.MapData map) {
    final ids = map.gameplayZones.map((z) => z.id).toSet();
    if (!ids.contains('zone')) return 'zone';
    var index = 1;
    while (ids.contains('zone_$index')) {
      index++;
    }
    return 'zone_$index';
  }

  /// Crée une zone par défaut (1×1) à la position [pos].
  core.MapGameplayZone createDefaultZone(
    core.MapData map,
    core.GridPos pos,
  ) {
    final id = generateUniqueZoneId(map);
    return core.MapGameplayZone(
      id: id,
      name: id,
      kind: core.GameplayZoneKind.encounter,
      area: core.MapRect(
        pos: pos,
        size: const core.GridSize(width: 1, height: 1),
      ),
      encounter: const core.EncounterZonePayload(),
    );
  }

  /// Crée une zone avec l'aire [rect] définie par clic+glisser.
  core.MapGameplayZone createZoneFromRect(
    core.MapData map,
    core.MapRect rect, {
    core.GameplayZoneKind kind = core.GameplayZoneKind.encounter,
  }) {
    final id = generateUniqueZoneId(map);
    return core.MapGameplayZone(
      id: id,
      name: id,
      kind: kind,
      area: rect,
      encounter: kind == core.GameplayZoneKind.encounter
          ? const core.EncounterZonePayload()
          : null,
    );
  }
}
