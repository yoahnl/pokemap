import 'package:map_core/map_core.dart';

import 'field_action.dart';
import 'field_traversal_action.dart';
import 'field_traversal_geometry.dart';
import 'gameplay_world_state.dart';

enum WhirlpoolBlockReason {
  disabled,
  unsupportedMap,
  invalidTarget,
  wrongDirection,
  requiresSurf,
  missingMove,
  locked,
  obstructed,
  requiresWater
}

sealed class WhirlpoolEvaluation {
  const WhirlpoolEvaluation();
}

final class CanUseWhirlpool extends WhirlpoolEvaluation {
  const CanUseWhirlpool(this.partyIndex, this.cells);
  final int partyIndex;
  final List<GridPos> cells;
}

final class WhirlpoolUnavailable extends WhirlpoolEvaluation {
  const WhirlpoolUnavailable(this.reason);
  final WhirlpoolBlockReason reason;
}

final class WhirlpoolActionTicket extends FieldTraversalActionTicket {
  const WhirlpoolActionTicket(
      {required super.fieldAction,
      required super.zone,
      required super.entryState,
      required super.instance});
}

bool isWhirlpoolZone(MapGameplayZone zone) =>
    isFieldTraversalZone(zone) &&
    zone.fieldAction!.actionKind == FieldActionZoneKind.whirlpool;

List<GridPos> whirlpoolRouteCells(MapGameplayZone zone) =>
    fieldTraversalRouteCells(zone);

EntityFacing whirlpoolFacing(MapGameplayZone zone) =>
    fieldTraversalFacing(zone);

MapGameplayZone? findWhirlpoolTarget(
        {required MapData map, required GameState gameState}) =>
    findAllGameplayZonesAtPos(map, gameState.playerPosition)
        .where(isWhirlpoolZone)
        .where((zone) =>
            whirlpoolRouteCells(zone).first == gameState.playerPosition)
        .firstOrNull;

WhirlpoolEvaluation evaluateWhirlpoolAttempt({
  required MapData map,
  required GameState gameState,
  required String zoneId,
  GameplayWorldState? world,
  ProjectManifest? project,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) {
  final result = evaluateFieldTraversalAttempt(
      ability: FieldAbility.whirlpool,
      kind: FieldActionZoneKind.whirlpool,
      map: map,
      gameState: gameState,
      zoneId: zoneId,
      world: world,
      project: project,
      dynamicBlockedCells: dynamicBlockedCells,
      characterReservations: characterReservations);
  final reason = result.reason;
  if (reason == null) return CanUseWhirlpool(result.partyIndex!, result.cells);
  return WhirlpoolUnavailable(WhirlpoolBlockReason.values.byName(reason.name));
}

FieldActionRefusal? validateWhirlpoolTicket({
  required WhirlpoolActionTicket ticket,
  required MapData map,
  required GameState gameState,
  required int currentStateRevision,
  ProjectSettings? projectSettings,
}) =>
    validateFieldTraversalTicket(
        ticket: ticket,
        ability: FieldAbility.whirlpool,
        map: map,
        gameState: gameState,
        currentStateRevision: currentStateRevision,
        projectSettings: projectSettings);
