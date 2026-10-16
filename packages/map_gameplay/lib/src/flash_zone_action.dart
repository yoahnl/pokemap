import 'package:map_core/map_core.dart';

import 'field_ability_gate.dart';
import 'field_action.dart';

enum FlashBlockReason {
  unsupportedMap,
  invalidTarget,
  missingMapInstance,
  alreadyIlluminated,
  missingMove,
  locked,
}

sealed class FlashEvaluation {
  const FlashEvaluation();
}

final class CanUseFlash extends FlashEvaluation {
  const CanUseFlash(this.partyIndex);
  final int partyIndex;
}

final class FlashUnavailable extends FlashEvaluation {
  const FlashUnavailable(this.reason);
  final FlashBlockReason reason;
}

final class FlashActionTicket {
  const FlashActionTicket({
    required this.fieldAction,
    required this.instance,
    required this.zone,
    this.playerPixelPosition,
  });
  final FieldActionTicket fieldAction;
  final MapInstanceRef instance;
  final MapGameplayZone zone;
  final PixelOffset? playerPixelPosition;
}

sealed class FlashCommit {
  const FlashCommit();
}

final class FlashApplied extends FlashCommit {
  const FlashApplied(this.gameState);
  final GameState gameState;
}

final class FlashRefused extends FlashCommit {
  const FlashRefused(this.refusal, {this.evaluation});
  final FieldActionRefusal refusal;
  final FlashEvaluation? evaluation;
}

bool isDarknessZone(MapGameplayZone zone) =>
    zone.kind == GameplayZoneKind.fieldAction &&
    zone.fieldAction?.actionKind == FieldActionZoneKind.darkness;

FlashEvaluation evaluateFlashAttempt({
  required MapData map,
  required GameState gameState,
  required String zoneId,
}) {
  if (map.spatialScene != null || map.version == ProjectVersion.v9) {
    return const FlashUnavailable(FlashBlockReason.unsupportedMap);
  }
  if (map.id != gameState.currentMapId ||
      zoneId.isEmpty ||
      zoneId.trim() != zoneId) {
    return const FlashUnavailable(FlashBlockReason.invalidTarget);
  }
  final zones = map.gameplayZones.where((zone) => zone.id == zoneId).toList();
  if (zones.length != 1 ||
      !isDarknessZone(zones.single) ||
      !gameplayZoneContainsPosition(zones.single, gameState.playerPosition)) {
    return const FlashUnavailable(FlashBlockReason.invalidTarget);
  }
  try {
    validateFieldActionZone(map, zones.single);
  } on Object {
    return const FlashUnavailable(FlashBlockReason.invalidTarget);
  }
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  if (instance == null) {
    return const FlashUnavailable(FlashBlockReason.missingMapInstance);
  }
  if (gameState.mapInstanceWorldState.isZoneIlluminated(instance, zoneId)) {
    return const FlashUnavailable(FlashBlockReason.alreadyIlluminated);
  }
  final gate = evaluateFieldAbilityGate(
    ability: FieldAbility.flash,
    supportedAbilities: const {FieldAbility.flash},
    unlockedFieldAbilities:
        gameState.progression.unlockedFieldAbilities.toSet(),
    party: gameState.party,
  );
  return switch (gate.status) {
    FieldAbilityGateStatus.usable => CanUseFlash(gate.partyIndex!),
    FieldAbilityGateStatus.missingMove =>
      const FlashUnavailable(FlashBlockReason.missingMove),
    FieldAbilityGateStatus.locked =>
      const FlashUnavailable(FlashBlockReason.locked),
    FieldAbilityGateStatus.unsupported =>
      throw StateError('Flash gate is unavailable.'),
  };
}

FlashCommit commitFlashAction({
  required FlashActionTicket ticket,
  required MapData map,
  required GameState gameState,
  required int currentStateRevision,
}) {
  if (ticket.fieldAction.issuedAtStateRevision != currentStateRevision) {
    return const FlashRefused(FieldActionRefusal.staleStateRevision);
  }
  if (ticket.fieldAction.ability != FieldAbility.flash ||
      ticket.instance.mapId != map.id ||
      ticket.instance != gameState.mapInstanceWorldState.instanceRef(map.id) ||
      ticket.fieldAction.targetCell != gameState.playerPosition ||
      ticket.playerPixelPosition != gameState.playerPixelPosition ||
      map.gameplayZones.where((zone) => zone.id == ticket.zone.id).length !=
          1 ||
      findGameplayZoneById(map, ticket.zone.id) != ticket.zone) {
    return const FlashRefused(FieldActionRefusal.targetChanged);
  }
  final evaluation = evaluateFlashAttempt(
      map: map, gameState: gameState, zoneId: ticket.zone.id);
  if (evaluation is! CanUseFlash) {
    return FlashRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: evaluation);
  }
  return FlashApplied(gameState.copyWith(
    mapInstanceWorldState: gameState.mapInstanceWorldState
        .illuminateZone(ticket.instance, ticket.zone.id),
  ));
}

void validateFlashInstanceState(
    {required MapData map, required MapInstanceWorldState instances}) {
  for (final zone in map.gameplayZones.where(isDarknessZone)) {
    validateFieldActionZone(map, zone);
  }
  final state = instances.instancesByMapId[map.id];
  if (state == null) return;
  for (final id in state.illuminatedZoneIds) {
    final zones = map.gameplayZones.where((zone) => zone.id == id).toList();
    if (zones.length != 1 || !isDarknessZone(zones.single)) {
      throw StateError(
          'Saved illumination references an unknown darkness zone: ${map.id}/$id.');
    }
    validateFieldActionZone(map, zones.single);
  }
}

MapGameplayZone? findFlashTarget(
    {required MapData map, required GameState gameState}) {
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  for (final zone in findAllGameplayZonesAtPos(map, gameState.playerPosition)) {
    if (isDarknessZone(zone) &&
        (instance == null ||
            !gameState.mapInstanceWorldState
                .isZoneIlluminated(instance, zone.id))) {
      return zone;
    }
  }
  return null;
}

double resolveDarknessOpacity(
    {required MapData map, required GameState gameState}) {
  if (map.id != gameState.currentMapId ||
      map.spatialScene != null ||
      map.version == ProjectVersion.v9) {
    return 0;
  }
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  var opacity = 0.0;
  for (final zone in findAllGameplayZonesAtPos(map, gameState.playerPosition)) {
    if (isDarknessZone(zone) &&
        (instance == null ||
            !gameState.mapInstanceWorldState
                .isZoneIlluminated(instance, zone.id))) {
      final next = zone.fieldAction!.darkness.opacity;
      if (next > opacity) opacity = next;
    }
  }
  return opacity.clamp(0, .95);
}
