import 'package:map_core/map_core.dart';

import 'field_action.dart';
import 'field_traversal_action.dart';
import 'field_traversal_geometry.dart';
import 'gameplay_world_state.dart';

enum WaterfallBlockReason {
  disabled,
  unsupportedMap,
  invalidTarget,
  wrongDirection,
  requiresSurf,
  missingMove,
  locked,
  obstructed
}

sealed class WaterfallEvaluation {
  const WaterfallEvaluation();
}

final class CanUseWaterfall extends WaterfallEvaluation {
  const CanUseWaterfall(this.partyIndex, this.cells);
  final int partyIndex;
  final List<GridPos> cells;
}

final class WaterfallUnavailable extends WaterfallEvaluation {
  const WaterfallUnavailable(this.reason);
  final WaterfallBlockReason reason;
}

final class WaterfallActionTicket extends FieldTraversalActionTicket {
  const WaterfallActionTicket(
      {required super.fieldAction,
      required super.zone,
      required super.entryState,
      required super.instance});
}

bool isWaterfallZone(MapGameplayZone zone) =>
    isFieldTraversalZone(zone) &&
    zone.fieldAction!.actionKind == FieldActionZoneKind.waterfall;

List<GridPos> waterfallRouteCells(MapGameplayZone zone) =>
    fieldTraversalRouteCells(zone);

EntityFacing waterfallFacing(MapGameplayZone zone) =>
    fieldTraversalFacing(zone);

MapGameplayZone? findWaterfallTarget(
        {required MapData map, required GameState gameState}) =>
    findAllGameplayZonesAtPos(map, gameState.playerPosition)
        .where(isWaterfallZone)
        .where((zone) =>
            waterfallRouteCells(zone).first == gameState.playerPosition)
        .firstOrNull;

WaterfallEvaluation evaluateWaterfallAttempt({
  required MapData map,
  required GameState gameState,
  required String zoneId,
  GameplayWorldState? world,
  ProjectManifest? project,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) {
  final result = evaluateFieldTraversalAttempt(
      ability: FieldAbility.waterfall,
      kind: FieldActionZoneKind.waterfall,
      map: map,
      gameState: gameState,
      zoneId: zoneId,
      world: world,
      project: project,
      dynamicBlockedCells: dynamicBlockedCells,
      characterReservations: characterReservations);
  final reason = result.reason;
  if (reason == null) return CanUseWaterfall(result.partyIndex!, result.cells);
  return WaterfallUnavailable(reason == FieldTraversalBlockReason.requiresWater
      ? WaterfallBlockReason.obstructed
      : WaterfallBlockReason.values.byName(reason.name));
}

FieldActionRefusal? validateWaterfallTicket({
  required WaterfallActionTicket ticket,
  required MapData map,
  required GameState gameState,
  required int currentStateRevision,
  ProjectSettings? projectSettings,
}) =>
    validateFieldTraversalTicket(
        ticket: ticket,
        ability: FieldAbility.waterfall,
        map: map,
        gameState: gameState,
        currentStateRevision: currentStateRevision,
        projectSettings: projectSettings);
