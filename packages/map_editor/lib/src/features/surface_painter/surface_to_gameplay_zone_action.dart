import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';

bool applyTallGrassEncounterGameplayZonePlan({
  required EditorNotifier notifier,
  required String? Function() selectedGameplayZoneId,
  required SurfaceGameplayZoneGenerationPlan plan,
}) {
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isTallGrassEncounterZone(zone))) {
    return false;
  }

  String? firstCreatedZoneId;
  for (final zone in zones) {
    notifier.addGameplayZoneAt(zone.area.pos);
    final createdZoneId = selectedGameplayZoneId();
    if (createdZoneId == null) {
      return false;
    }
    firstCreatedZoneId ??= zone.id;
    notifier.updateGameplayZone(
      zoneId: createdZoneId,
      id: zone.id,
      name: zone.name,
      kind: zone.kind,
      area: zone.area,
      priority: zone.priority,
      encounter: zone.encounter,
      movement: null,
      hazard: null,
      special: null,
    );
  }

  if (firstCreatedZoneId != null) {
    notifier.selectGameplayZone(firstCreatedZoneId);
  }
  return true;
}

bool _isTallGrassEncounterZone(MapGameplayZone zone) {
  return zone.kind == GameplayZoneKind.encounter &&
      zone.encounter != null &&
      zone.encounter?.encounterKind == EncounterKind.walk;
}
