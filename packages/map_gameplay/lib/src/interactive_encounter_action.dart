import 'dart:math';
import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_encounter.dart';
import 'gameplay_world_state.dart';
import 'script_condition_evaluator.dart';

enum InteractiveEncounterBlockReason {
  unsupportedMap,
  unavailableContext,
  invalidTarget,
  missingMapInstance,
  alreadyConsumed,
  missingMove,
  conditionsNotMet,
  encounterUnavailable,
  staleAttempt
}

final class InteractiveEncounterEvaluation {
  const InteractiveEncounterEvaluation(
      {this.reason, this.source, this.encounterCheck});
  final InteractiveEncounterBlockReason? reason;
  final EncounterSource? source;
  final GameplayEncounterCheckResult? encounterCheck;
  bool get isReady => reason == null && source != null;
}

InteractiveEncounterEvaluation evaluateInteractiveEncounter({
  required GameplayWorldState world,
  required ProjectManifest project,
  required GameState gameState,
  required MapEntity entity,
  ScriptEvaluationContext? conditionContext,
  EncounterEvaluationContext? encounterContext,
}) {
  final map = world.map, payload = entity.interactiveEncounter;
  if (map.version != ProjectVersion.v8 ||
      map.spatialScene != null ||
      project.settings.dimension != ProjectDimension.twoD) {
    return const InteractiveEncounterEvaluation(
        reason: InteractiveEncounterBlockReason.unsupportedMap);
  }
  if (gameState.currentMapId != map.id ||
      gameState.playerPosition != world.player.pos ||
      gameState.playerFacing != world.player.facing.asFacing ||
      gameState.playerMovementMode != world.player.movementMode ||
      world.player.movementMode != MovementMode.walk) {
    return const InteractiveEncounterEvaluation(
        reason: InteractiveEncounterBlockReason.unavailableContext);
  }
  final scope = gameState.mapInstanceWorldState.instanceRef(map.id);
  if (scope == null) {
    return const InteractiveEncounterEvaluation(
        reason: InteractiveEncounterBlockReason.missingMapInstance);
  }
  if (entity.pos.x < 0 ||
      entity.pos.y < 0 ||
      entity.pos.x >= map.size.width ||
      entity.pos.y >= map.size.height ||
      payload == null ||
      entity.pos !=
          GridPos(
              x: world.player.pos.x + world.player.facing.dx,
              y: world.player.pos.y + world.player.facing.dy)) {
    return const InteractiveEncounterEvaluation(
        reason: InteractiveEncounterBlockReason.invalidTarget);
  }
  final active =
      map.entities.where((candidate) => candidate.id == entity.id).toList();
  if (payload.trigger == InteractiveEncounterTrigger.headbutt
      ? active.length != 1 ||
          active.single != entity ||
          world.entityAt(entity.pos.x, entity.pos.y) != entity ||
          gameState.mapInstanceWorldState
              .isFieldObstacleCleared(scope, entity.id)
      : active.isNotEmpty ||
          !gameState.mapInstanceWorldState
              .isFieldObstacleCleared(scope, entity.id)) {
    return const InteractiveEncounterEvaluation(
        reason: InteractiveEncounterBlockReason.invalidTarget);
  }
  try {
    assertValidMapEntityTypedPayloads(entity);
  } on Object {
    return const InteractiveEncounterEvaluation(
        reason: InteractiveEncounterBlockReason.invalidTarget);
  }
  if (payload.reusePolicy ==
          InteractiveEncounterReusePolicy.oncePerMapInstance &&
      gameState.mapInstanceWorldState
          .isInteractiveEncounterConsumed(scope, entity.id)) {
    return const InteractiveEncounterEvaluation(
        reason: InteractiveEncounterBlockReason.alreadyConsumed);
  }
  const evaluator = ScriptConditionEvaluator();
  if (payload.trigger == InteractiveEncounterTrigger.headbutt &&
      !evaluator.evaluate(
          ScriptConditionFactory.partyHasUsableMove('headbutt'), gameState,
          context: conditionContext)) {
    return const InteractiveEncounterEvaluation(
        reason: InteractiveEncounterBlockReason.missingMove);
  }
  for (final condition in payload.conditions) {
    if (!evaluator.evaluate(condition, gameState, context: conditionContext)) {
      return const InteractiveEncounterEvaluation(
          reason: InteractiveEncounterBlockReason.conditionsNotMet);
    }
  }
  final source = EncounterSource(
      kind: EncounterSourceKind.interactiveObject,
      id: 'entity:${entity.id}',
      priority: 0,
      encounter: payload.presentation);
  final refusal = validateEncounterSource(
      project: project,
      source: source,
      encounterKind: payload.encounterKind,
      gameState: gameState,
      conditionContext: conditionContext,
      encounterContext: encounterContext);
  return InteractiveEncounterEvaluation(
      reason: refusal == null
          ? null
          : InteractiveEncounterBlockReason.encounterUnavailable,
      source: source,
      encounterCheck: refusal);
}

final class InteractiveEncounterTicket {
  const InteractiveEncounterTicket(
      {required this.attemptId,
      required this.map,
      required this.project,
      required this.gameState,
      required this.entity,
      required this.playerPixelPosition,
      required this.issuedAtStateRevision,
      required this.mapActivationId});
  final String attemptId;
  final MapData map;
  final ProjectManifest project;
  final GameState gameState;
  final MapEntity entity;
  final PixelOffset playerPixelPosition;
  final int issuedAtStateRevision;
  final String mapActivationId;
}

bool isInteractiveEncounterCurrent(
        {required InteractiveEncounterTicket ticket,
        required GameplayWorldState world,
        required ProjectManifest project,
        required GameState gameState,
        required int currentStateRevision,
        required String? mapActivationId}) =>
    ticket.attemptId.isNotEmpty &&
    ticket.playerPixelPosition.x == world.player.playerPositionPx.leftPx &&
    ticket.playerPixelPosition.y == world.player.playerPositionPx.topPx &&
    ticket.map == world.map &&
    ticket.project == project &&
    ticket.gameState == gameState &&
    ticket.issuedAtStateRevision == currentStateRevision &&
    ticket.mapActivationId == mapActivationId;

final class InteractiveEncounterResult {
  const InteractiveEncounterResult({this.reason, this.encounterCheck});
  final InteractiveEncounterBlockReason? reason;
  final GameplayEncounterCheckResult? encounterCheck;
}

InteractiveEncounterResult resolveInteractiveEncounter(
    {required InteractiveEncounterTicket ticket,
    required GameplayWorldState world,
    required ProjectManifest project,
    required GameState gameState,
    required int currentStateRevision,
    required String? mapActivationId,
    ScriptEvaluationContext? conditionContext,
    EncounterEvaluationContext? encounterContext,
    Random? random}) {
  if (!isInteractiveEncounterCurrent(
      ticket: ticket,
      world: world,
      project: project,
      gameState: gameState,
      currentStateRevision: currentStateRevision,
      mapActivationId: mapActivationId)) {
    return const InteractiveEncounterResult(
        reason: InteractiveEncounterBlockReason.staleAttempt);
  }
  final evaluation = evaluateInteractiveEncounter(
      world: world,
      project: project,
      gameState: gameState,
      entity: ticket.entity,
      conditionContext: conditionContext,
      encounterContext: encounterContext);
  if (!evaluation.isReady) {
    return InteractiveEncounterResult(
        reason: evaluation.reason, encounterCheck: evaluation.encounterCheck);
  }
  return InteractiveEncounterResult(
      encounterCheck: checkEncounterFromSource(
          world: world,
          project: project,
          source: evaluation.source!,
          encounterKind: ticket.entity.interactiveEncounter!.encounterKind,
          gameState: gameState,
          conditionContext: conditionContext,
          encounterContext: encounterContext,
          random: random));
}
