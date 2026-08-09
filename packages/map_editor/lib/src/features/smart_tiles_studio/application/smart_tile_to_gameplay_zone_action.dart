import 'package:map_core/map_core.dart';

import '../../editor/state/editor_notifier.dart';

bool applyTallGrassEncounterGameplayZonePlan({
  required EditorNotifier notifier,
  required SmartTileGameplayZoneGenerationPlan plan,
}) {
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isTallGrassEncounterZone(zone))) {
    return false;
  }

  return notifier.applyGeneratedGameplayZones(
    plan: plan,
    selectZoneId: zones.first.id,
    statusMessage: 'Zones de rencontre synchronisées depuis le Smart Tile',
  );
}

bool applySurfableWaterGameplayZonePlan({
  required EditorNotifier notifier,
  required SmartTileGameplayZoneGenerationPlan plan,
}) {
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isSurfableWaterMovementZone(zone))) {
    return false;
  }

  return notifier.applyGeneratedGameplayZones(
    plan: plan,
    selectZoneId: zones.first.id,
    statusMessage: 'Zones Surf synchronisées depuis le Smart Tile',
  );
}

bool applyLavaHazardGameplayZonePlan({
  required EditorNotifier notifier,
  required SmartTileGameplayZoneGenerationPlan plan,
}) {
  // Authoring only: this stores lava damage metadata on gameplay zones.
  // HP / party mutation is intentionally left to gameplay/runtime consumers.
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isLavaHazardZone(zone))) {
    return false;
  }

  return notifier.applyGeneratedGameplayZones(
    plan: plan,
    selectZoneId: zones.first.id,
    statusMessage: 'Zones de lave synchronisées depuis le Smart Tile',
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

bool _isLavaHazardZone(MapGameplayZone zone) {
  return zone.kind == GameplayZoneKind.hazard &&
      zone.hazard != null &&
      zone.hazard?.hazardKind == HazardKind.lava &&
      (zone.hazard?.damagePerStep ?? 0) > 0;
}
