import 'package:map_core/map_core.dart';

import 'field_ability_gate.dart';
import 'field_action.dart';

enum FlyBlockReason {
  underwater,
  unsupportedMap,
  indoor,
  invalidDestination,
  notVisited,
  invalidSpawn,
  missingMove,
  locked,
}

sealed class FlyEvaluation {
  const FlyEvaluation();
}

final class FlyUnavailable extends FlyEvaluation {
  const FlyUnavailable(this.reason);
  final FlyBlockReason reason;
}

final class FlyArrival {
  const FlyArrival(
      {required this.mapId,
      required this.entityId,
      required this.position,
      required this.facing});
  final String mapId;
  final String entityId;
  final GridPos position;
  final EntityFacing facing;

  @override
  bool operator ==(Object other) =>
      other is FlyArrival &&
      mapId == other.mapId &&
      entityId == other.entityId &&
      position == other.position &&
      facing == other.facing;
  @override
  int get hashCode => Object.hash(mapId, entityId, position, facing);
}

final class CanUseFly extends FlyEvaluation {
  const CanUseFly(
      {required this.pointId, required this.partyIndex, required this.arrival});
  final String pointId;
  final int partyIndex;
  final FlyArrival arrival;
}

FlyEvaluation evaluateFlyAttempt({
  required MapData sourceMap,
  required MapRole sourceRole,
  required MapData? targetMap,
  required GameState gameState,
  required ProjectRegionalMapCatalog catalog,
  required String pointId,
}) {
  if (sourceMap.spatialScene != null ||
      sourceMap.version != ProjectVersion.v8 ||
      (targetMap != null &&
          (targetMap.spatialScene != null ||
              targetMap.version != ProjectVersion.v8))) {
    return const FlyUnavailable(FlyBlockReason.unsupportedMap);
  }
  if (gameState.playerMovementMode == MovementMode.dive) {
    return const FlyUnavailable(FlyBlockReason.underwater);
  }
  if (sourceRole == MapRole.interior ||
      sourceMap.mapMetadata.isIndoor ||
      const {MapType.building, MapType.interior, MapType.cave, MapType.facility}
          .contains(sourceMap.mapMetadata.mapType)) {
    return const FlyUnavailable(FlyBlockReason.indoor);
  }
  final points =
      catalog.pointsOfInterest.where((point) => point.id == pointId).toList();
  if (sourceMap.id != gameState.currentMapId || points.length != 1) {
    return const FlyUnavailable(FlyBlockReason.invalidDestination);
  }
  final point = points.single;
  final destination = point.destination;
  if (point.visibility == ProjectRegionPointVisibility.hidden ||
      destination == null ||
      catalog.regions.where((region) => region.id == point.regionId).length !=
          1 ||
      targetMap == null ||
      targetMap.id != destination.mapId) {
    return const FlyUnavailable(FlyBlockReason.invalidDestination);
  }
  final visited = {
    ...gameState.narrativeEventProgress.visitedNarrativeMapIds,
    gameState.currentMapId
  };
  if (!point.mapIds.any(visited.contains)) {
    return const FlyUnavailable(FlyBlockReason.notVisited);
  }
  final spawnId = destination.spawnId;
  final spawns = targetMap.entities
      .where((entity) =>
          entity.kind == MapEntityKind.spawn &&
          entity.spawn != null &&
          spawnId != null &&
          (entity.id == spawnId || entity.spawn!.spawnKey == spawnId))
      .toList();
  if (spawns.length != 1 ||
      spawns.single.pos.x < 0 ||
      spawns.single.pos.y < 0 ||
      spawns.single.pos.x >= targetMap.size.width ||
      spawns.single.pos.y >= targetMap.size.height) {
    return const FlyUnavailable(FlyBlockReason.invalidSpawn);
  }
  final gate = evaluateFieldAbilityGate(
      ability: FieldAbility.fly,
      supportedAbilities: const {FieldAbility.fly},
      unlockedFieldAbilities:
          gameState.progression.unlockedFieldAbilities.toSet(),
      party: gameState.party);
  if (gate.status != FieldAbilityGateStatus.usable) {
    return FlyUnavailable(gate.status == FieldAbilityGateStatus.locked
        ? FlyBlockReason.locked
        : FlyBlockReason.missingMove);
  }
  final spawn = spawns.single;
  return CanUseFly(
      pointId: pointId,
      partyIndex: gate.partyIndex!,
      arrival: FlyArrival(
          mapId: targetMap.id,
          entityId: spawn.id,
          position: spawn.pos,
          facing: spawn.spawn!.facing));
}

final class FlyActionTicket {
  const FlyActionTicket(
      {required this.evaluation,
      required this.gameState,
      required this.sourceMap,
      required this.targetMap,
      required this.catalog,
      required this.issuedAtStateRevision});
  final CanUseFly evaluation;
  final GameState gameState;
  final MapData sourceMap;
  final MapData targetMap;
  final ProjectRegionalMapCatalog catalog;
  final int issuedAtStateRevision;
}

sealed class FlyCommit {
  const FlyCommit();
}

final class FlyReady extends FlyCommit {
  const FlyReady(this.arrival);
  final FlyArrival arrival;
}

final class FlyRefused extends FlyCommit {
  const FlyRefused(this.refusal, {this.evaluation});
  final FieldActionRefusal refusal;
  final FlyEvaluation? evaluation;
}

FlyCommit commitFlyAction(
    {required FlyActionTicket ticket,
    required MapData sourceMap,
    required MapRole sourceRole,
    required MapData? targetMap,
    required GameState gameState,
    required ProjectRegionalMapCatalog catalog,
    required int currentStateRevision}) {
  if (ticket.issuedAtStateRevision != currentStateRevision ||
      ticket.gameState != gameState) {
    return const FlyRefused(FieldActionRefusal.staleStateRevision);
  }
  if (ticket.sourceMap != sourceMap ||
      ticket.targetMap != targetMap ||
      ticket.catalog != catalog) {
    return const FlyRefused(FieldActionRefusal.targetChanged);
  }
  final evaluation = evaluateFlyAttempt(
      sourceMap: sourceMap,
      sourceRole: sourceRole,
      targetMap: targetMap,
      gameState: gameState,
      catalog: catalog,
      pointId: ticket.evaluation.pointId);
  if (evaluation is! CanUseFly ||
      evaluation.arrival != ticket.evaluation.arrival) {
    return FlyRefused(FieldActionRefusal.noLongerAvailable,
        evaluation: evaluation);
  }
  return FlyReady(evaluation.arrival);
}
