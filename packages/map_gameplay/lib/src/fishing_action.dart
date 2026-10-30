import 'dart:math';

import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_encounter.dart';
import 'gameplay_world_state.dart';
import 'items/bag_operations.dart';
import 'movement_terrain_policy.dart';
import 'script_condition_evaluator.dart';
import 'spatial_fishing_target.dart';
import 'spatial_movement_controller.dart';

enum FishingBlockReason {
  unsupportedMap,
  unavailableContext,
  invalidItem,
  insufficientQuantity,
  notWater,
  noEncounterSource,
  encounterUnavailable,
  staleAttempt,
  handoffBusy,
  checkpointFailed,
}

ProjectFishingRodKind? fishingRodKindForItem(ProjectItemDefinition item) {
  final uses = item.uses.where(
    (use) => use.contexts.contains(ProjectItemUseContext.overworld),
  );
  if (!item.tags.contains('key-item') || uses.length != 1) return null;
  final use = uses.single;
  if (use.contexts.length != 1 ||
      use.target != ProjectItemTargetKind.world ||
      use.consumption != ProjectItemConsumptionPolicy.never) {
    return null;
  }
  final effect = use.effect;
  return effect is ProjectItemFishingEffectDefinition ? effect.rodKind : null;
}

final class FishingAttemptEvaluation {
  const FishingAttemptEvaluation(
      {this.reason, this.source, this.encounterCheck});

  final FishingBlockReason? reason;
  final EncounterSource? source;
  final GameplayEncounterCheckResult? encounterCheck;
  bool get isReady => reason == null && source != null;
}

FishingAttemptEvaluation evaluateFishingAttempt({
  required GameplayWorldState world,
  required ProjectManifest project,
  required GameState gameState,
  required ProjectItemDefinition item,
  ScriptEvaluationContext? conditionContext,
  EncounterEvaluationContext? encounterContext,
  SpatialMovementController? spatialMovement,
}) {
  final map = world.map;
  final spatial = map.version == ProjectVersion.v9 && map.spatialScene != null;
  if (!spatial &&
      (map.version != ProjectVersion.v8 || map.spatialScene != null)) {
    return const FishingAttemptEvaluation(
        reason: FishingBlockReason.unsupportedMap);
  }
  if (gameState.currentMapId != map.id ||
      gameState.playerPosition != world.player.pos ||
      gameState.playerFacing != world.player.facing.asFacing ||
      gameState.playerMovementMode != world.player.movementMode ||
      !{MovementMode.walk, MovementMode.bicycle, MovementMode.surf}
          .contains(world.player.movementMode)) {
    return const FishingAttemptEvaluation(
        reason: FishingBlockReason.unavailableContext);
  }
  final rodKind = fishingRodKindForItem(item);
  if (rodKind == null) {
    return const FishingAttemptEvaluation(
        reason: FishingBlockReason.invalidItem);
  }
  if (const BagOperations().quantityOf(gameState.bag, item.id) < 1) {
    return const FishingAttemptEvaluation(
        reason: FishingBlockReason.insufficientQuantity);
  }
  final target = spatial
      ? spatialFishingTarget(world, gameState,
          models: project.models3d, movement: spatialMovement)
      : GridPos(
          x: world.player.pos.x + world.player.facing.dx,
          y: world.player.pos.y + world.player.facing.dy,
        );
  if (target == null ||
      !world.isWaterCell(target.x, target.y) ||
      movementTerrainAt(map, target.x, target.y) !=
          GameplayMovementTerrain.surf) {
    return const FishingAttemptEvaluation(reason: FishingBlockReason.notWater);
  }
  final resolution = resolveEncounterSourceAtPosition(
    map,
    position: target,
    encounterKind: rodKind.encounterKind,
  );
  final source = resolution.source;
  if (source == null) {
    return FishingAttemptEvaluation(
      reason: FishingBlockReason.noEncounterSource,
      encounterCheck: GameplayEncounterCheckResult(
        status: resolution.status == EncounterSourceResolutionStatus.ambiguous
            ? GameplayEncounterCheckStatus.ambiguousSource
            : GameplayEncounterCheckStatus.noSource,
        encounterKind: rodKind.encounterKind,
        ambiguousSourceIds: resolution.ambiguousSourceIds,
      ),
    );
  }
  final refusal = validateEncounterSource(
    project: project,
    source: source,
    encounterKind: rodKind.encounterKind,
    gameState: gameState,
    conditionContext: conditionContext,
    encounterContext: encounterContext,
  );
  return FishingAttemptEvaluation(
    reason: refusal == null ? null : FishingBlockReason.encounterUnavailable,
    source: source,
    encounterCheck: refusal,
  );
}

final class FishingActionTicket {
  const FishingActionTicket({
    required this.attemptId,
    required this.map,
    required this.project,
    required this.gameState,
    required this.item,
    required this.issuedAtStateRevision,
    required this.mapActivationId,
  });

  final String attemptId;
  final MapData map;
  final ProjectManifest project;
  final GameState gameState;
  final ProjectItemDefinition item;
  final int issuedAtStateRevision;
  final String mapActivationId;
}

bool isFishingAttemptCurrent({
  required FishingActionTicket ticket,
  required GameplayWorldState world,
  required ProjectManifest project,
  required GameState gameState,
  required ProjectItemDefinition item,
  required int currentStateRevision,
  required String? mapActivationId,
}) =>
    ticket.attemptId.isNotEmpty &&
    ticket.map == world.map &&
    ticket.project == project &&
    ticket.gameState == gameState &&
    ticket.item == item &&
    ticket.issuedAtStateRevision == currentStateRevision &&
    ticket.mapActivationId == mapActivationId &&
    ticket.gameState.mapInstanceWorldState.instanceRef(ticket.map.id) ==
        gameState.mapInstanceWorldState.instanceRef(world.map.id);

final class FishingAttemptResult {
  const FishingAttemptResult({this.reason, this.encounterCheck});
  final FishingBlockReason? reason;
  final GameplayEncounterCheckResult? encounterCheck;
}

FishingAttemptResult resolveFishingAttempt({
  required FishingActionTicket ticket,
  required GameplayWorldState world,
  required ProjectManifest project,
  required GameState gameState,
  required ProjectItemDefinition item,
  required int currentStateRevision,
  required String? mapActivationId,
  ScriptEvaluationContext? conditionContext,
  EncounterEvaluationContext? encounterContext,
  SpatialMovementController? spatialMovement,
  Random? random,
}) {
  if (!isFishingAttemptCurrent(
      ticket: ticket,
      world: world,
      project: project,
      gameState: gameState,
      item: item,
      currentStateRevision: currentStateRevision,
      mapActivationId: mapActivationId)) {
    return const FishingAttemptResult(reason: FishingBlockReason.staleAttempt);
  }
  final evaluation = evaluateFishingAttempt(
      world: world,
      project: project,
      gameState: gameState,
      item: item,
      conditionContext: conditionContext,
      encounterContext: encounterContext,
      spatialMovement: spatialMovement);
  if (!evaluation.isReady) {
    return FishingAttemptResult(
        reason: evaluation.reason, encounterCheck: evaluation.encounterCheck);
  }
  return FishingAttemptResult(
      encounterCheck: checkEncounterFromSource(
    world: world,
    project: project,
    source: evaluation.source!,
    encounterKind: fishingRodKindForItem(item)!.encounterKind,
    gameState: gameState,
    conditionContext: conditionContext,
    encounterContext: encounterContext,
    random: random,
  ));
}

enum FishingAttemptPhase {
  casting,
  waiting,
  bite,
  noBite,
  readyForBattle,
  finished,
  cancelled
}

final class FishingAttemptFlow {
  FishingAttemptPhase _phase = FishingAttemptPhase.casting;
  FishingAttemptResult? _result;
  FishingAttemptPhase get phase => _phase;
  FishingAttemptResult? get result => _result;
  double _elapsed = 0;

  void cancel() {
    _phase = FishingAttemptPhase.cancelled;
  }

  void advance(double seconds,
      {required FishingAttemptResult Function() resolve}) {
    if (!seconds.isFinite || seconds <= 0) return;
    _elapsed += seconds;
    switch (_phase) {
      case FishingAttemptPhase.casting:
        if (_elapsed >= .35) {
          _phase = FishingAttemptPhase.waiting;
          _elapsed = 0;
        }
      case FishingAttemptPhase.waiting:
        if (_elapsed >= 1) {
          _result = resolve();
          _phase = result?.encounterCheck?.triggered == true
              ? FishingAttemptPhase.bite
              : FishingAttemptPhase.noBite;
          _elapsed = 0;
        }
      case FishingAttemptPhase.bite:
        if (_elapsed >= .65) _phase = FishingAttemptPhase.readyForBattle;
      case FishingAttemptPhase.noBite:
        if (_elapsed >= .65) _phase = FishingAttemptPhase.finished;
      case FishingAttemptPhase.readyForBattle:
      case FishingAttemptPhase.finished:
      case FishingAttemptPhase.cancelled:
        break;
    }
  }
}
