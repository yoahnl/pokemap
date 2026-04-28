import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';

bool applyTallGrassEncounterGameplayZonePlan({
  required EditorNotifier notifier,
  required SurfaceGameplayZoneGenerationPlan plan,
}) {
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isTallGrassEncounterZone(zone))) {
    return false;
  }

  return notifier.applyGeneratedGameplayZones(
    zones: zones,
    selectZoneId: zones.first.id,
    statusMessage: 'Zones de rencontre créées depuis la surface',
  );
}

bool applySurfableWaterGameplayZonePlan({
  required EditorNotifier notifier,
  required SurfaceGameplayZoneGenerationPlan plan,
}) {
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isSurfableWaterMovementZone(zone))) {
    return false;
  }

  return notifier.applyGeneratedGameplayZones(
    zones: zones,
    selectZoneId: zones.first.id,
    statusMessage: 'Zones Surf créées depuis la surface',
  );
}

bool _isTallGrassEncounterZone(MapGameplayZone zone) {
  return zone.kind == GameplayZoneKind.encounter &&
      zone.encounter != null &&
      zone.encounter?.encounterKind == EncounterKind.walk;
}

bool _isSurfableWaterMovementZone(MapGameplayZone zone) {
  return zone.kind == GameplayZoneKind.movement &&
      zone.movement != null &&
      zone.movement?.requiredMode == MovementMode.surf;
}
