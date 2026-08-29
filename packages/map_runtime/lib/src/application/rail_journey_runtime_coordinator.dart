import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

enum RailJourneyRuntimeBlockReason {
  invalidCatalog,
  unknownJourney,
  wrongMap,
  outsideBoardingArea,
  doorSideNotAllowed,
  inactiveJourney,
  invalidArrivalPosition,
  serviceRefused,
}

final class RailJourneyRuntimeTransition {
  const RailJourneyRuntimeTransition({
    required this.destinationMapId,
    required this.destinationPosition,
    required this.doorSide,
    required this.sourceDoorPlacedElementId,
    required this.destinationDoorPlacedElementId,
  });

  final String destinationMapId;
  final GridPos destinationPosition;
  final RailJourneyDoorSide doorSide;
  final String sourceDoorPlacedElementId;
  final String destinationDoorPlacedElementId;

  @override
  bool operator ==(Object other) =>
      other is RailJourneyRuntimeTransition &&
      other.destinationMapId == destinationMapId &&
      other.destinationPosition == destinationPosition &&
      other.doorSide == doorSide &&
      other.sourceDoorPlacedElementId == sourceDoorPlacedElementId &&
      other.destinationDoorPlacedElementId == destinationDoorPlacedElementId;

  @override
  int get hashCode => Object.hash(
        destinationMapId,
        destinationPosition,
        doorSide,
        sourceDoorPlacedElementId,
        destinationDoorPlacedElementId,
      );
}

sealed class RailJourneyRuntimeResult {
  const RailJourneyRuntimeResult({required this.gameState});

  final GameState gameState;
  String get outputPortId;
}

final class RailJourneyRuntimeCompleted extends RailJourneyRuntimeResult {
  const RailJourneyRuntimeCompleted({
    required super.gameState,
    this.transition,
    this.alreadyApplied = false,
  });

  final RailJourneyRuntimeTransition? transition;
  final bool alreadyApplied;

  @override
  String get outputPortId => 'completed';
}

final class RailJourneyRuntimeBlocked extends RailJourneyRuntimeResult {
  const RailJourneyRuntimeBlocked({
    required super.gameState,
    required this.reason,
    this.serviceReason,
  });

  final RailJourneyRuntimeBlockReason reason;
  final Object? serviceReason;

  @override
  String get outputPortId => 'blocked';
}

final class RailJourneyRuntimeCoordinator {
  const RailJourneyRuntimeCoordinator({
    this.service = const RailJourneyService(),
  });

  final RailJourneyService service;

  RailJourneyRuntimeResult execute({
    required SceneRailJourneyInteractiveCommand command,
    required String operationInstanceId,
    required RailJourneyCatalog catalog,
    required GameState gameState,
  }) {
    late final RailJourneyCatalog validatedCatalog;
    try {
      validatedCatalog = catalog.validated();
    } on StateError {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.invalidCatalog,
      );
    }
    final definition = _definition(validatedCatalog, command.journeyId);
    if (definition == null) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.unknownJourney,
      );
    }
    return switch (command.operation) {
      SceneRailJourneyOperation.begin => _begin(
          command: command,
          operationInstanceId: operationInstanceId,
          definition: definition,
          gameState: gameState,
        ),
      SceneRailJourneyOperation.advance => _advance(
          command: command,
          operationInstanceId: operationInstanceId,
          definition: definition,
          gameState: gameState,
        ),
      SceneRailJourneyOperation.acknowledge => _acknowledge(
          command: command,
          operationInstanceId: operationInstanceId,
          definition: definition,
          gameState: gameState,
        ),
    };
  }

  RailJourneyRuntimeResult _begin({
    required SceneRailJourneyInteractiveCommand command,
    required String operationInstanceId,
    required RailJourneyDefinition definition,
    required GameState gameState,
  }) {
    final direction = command.direction!;
    final endpoint = direction == RailJourneyDirection.outbound
        ? definition.origin
        : definition.destination;
    final result = service.begin(
      definition: definition,
      progress: gameState.railJourneyProgress,
      access: _access(gameState),
      operationInstanceId: operationInstanceId,
      direction: direction,
      currentStationMapId: gameState.currentMapId,
      doorSide: command.doorSide!,
    );
    if (result is RailJourneyBeginAlreadyApplied) {
      return RailJourneyRuntimeCompleted(
        gameState: gameState,
        alreadyApplied: true,
      );
    }
    if (result
        case RailJourneyBeginRefused(
          reason: RailJourneyBeginRefusal.idempotencyConflict ||
              RailJourneyBeginRefusal.invalidRequest,
        )) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.serviceRefused,
        serviceReason: result.reason,
      );
    }
    if (gameState.currentMapId != endpoint.stationMapId) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.wrongMap,
      );
    }
    if (!_contains(endpoint.boardingArea, gameState.playerPosition)) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.outsideBoardingArea,
      );
    }
    final door = endpoint.doorForSide(command.doorSide!);
    if (door == null) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.doorSideNotAllowed,
      );
    }
    if (result case RailJourneyBeginRefused(:final reason)) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.serviceRefused,
        serviceReason: reason,
      );
    }
    return RailJourneyRuntimeCompleted(
      gameState: gameState.copyWith(railJourneyProgress: result.progress),
      transition: RailJourneyRuntimeTransition(
        destinationMapId: definition.vehicleMapId,
        destinationPosition: endpoint.trainEntryPos,
        doorSide: command.doorSide!,
        sourceDoorPlacedElementId: door.stationPlacedElementId,
        destinationDoorPlacedElementId: door.vehiclePlacedElementId,
      ),
      alreadyApplied: result is RailJourneyBeginAlreadyApplied,
    );
  }

  RailJourneyAccessState _access(GameState gameState) {
    return RailJourneyAccessState(
      completedStoryStepIds: gameState.progression.completedStepIds.toSet(),
      activeFactIds: <String>{
        for (final entry
            in gameState.narrativeFactRuntimeState.valuesByFactId.entries)
          if (entry.value.kind == NarrativeValueKind.boolean &&
              entry.value.boolValue)
            entry.key,
      },
      itemIds: <String>{
        for (final entry in gameState.bag.entries)
          if (entry.quantity > 0) entry.itemId,
      },
      stampIds: gameState.railJourneyProgress.earnedStampIds,
    );
  }

  RailJourneyRuntimeResult _advance({
    required SceneRailJourneyInteractiveCommand command,
    required String operationInstanceId,
    required RailJourneyDefinition definition,
    required GameState gameState,
  }) {
    final progress = gameState.railJourneyProgress;
    final existingBinding =
        progress.appliedOperations[operationInstanceId.trim()];
    final effectiveDirection = progress.direction ?? existingBinding?.direction;
    final event = command.advanceEvent!;
    final result = service.advance(
      progress: progress,
      operationInstanceId: operationInstanceId,
      journeyId: definition.id,
      event: switch (event) {
        SceneRailJourneyAdvanceEvent.doorsClosed =>
          RailJourneyAdvanceEvent.doorsClosed,
        SceneRailJourneyAdvanceEvent.arrivalReached =>
          RailJourneyAdvanceEvent.arrivalReached,
        SceneRailJourneyAdvanceEvent.destinationDoorUsed =>
          RailJourneyAdvanceEvent.destinationDoorUsed,
      },
      doorSide: command.doorSide,
    );
    if (result is RailJourneyAdvanceAlreadyApplied &&
        effectiveDirection != null) {
      return RailJourneyRuntimeCompleted(
        gameState: gameState,
        alreadyApplied: true,
      );
    }
    if (result
        case RailJourneyAdvanceRefused(
          reason: RailJourneyAdvanceRefusal.idempotencyConflict ||
              RailJourneyAdvanceRefusal.invalidRequest ||
              RailJourneyAdvanceRefusal.invalidState,
        )) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.serviceRefused,
        serviceReason: result.reason,
      );
    }
    if (progress.activeJourneyId != definition.id ||
        progress.direction == null) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.inactiveJourney,
      );
    }
    if (gameState.currentMapId != definition.vehicleMapId) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.wrongMap,
      );
    }
    final arrivalEndpoint = progress.direction == RailJourneyDirection.outbound
        ? definition.destination
        : definition.origin;
    final arrivalDoor =
        event == SceneRailJourneyAdvanceEvent.destinationDoorUsed
            ? arrivalEndpoint.doorForSide(command.doorSide!)
            : null;
    if (event == SceneRailJourneyAdvanceEvent.destinationDoorUsed &&
        arrivalDoor == null) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.doorSideNotAllowed,
      );
    }
    if (result case RailJourneyAdvanceRefused(:final reason)) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.serviceRefused,
        serviceReason: reason,
      );
    }
    return RailJourneyRuntimeCompleted(
      gameState: gameState.copyWith(railJourneyProgress: result.progress),
      transition: event == SceneRailJourneyAdvanceEvent.destinationDoorUsed
          ? RailJourneyRuntimeTransition(
              destinationMapId: arrivalEndpoint.stationMapId,
              destinationPosition: arrivalEndpoint.stationArrivalPos,
              doorSide: command.doorSide!,
              sourceDoorPlacedElementId: arrivalDoor!.vehiclePlacedElementId,
              destinationDoorPlacedElementId:
                  arrivalDoor.stationPlacedElementId,
            )
          : null,
    );
  }

  RailJourneyRuntimeResult _acknowledge({
    required SceneRailJourneyInteractiveCommand command,
    required String operationInstanceId,
    required RailJourneyDefinition definition,
    required GameState gameState,
  }) {
    final progress = gameState.railJourneyProgress;
    final existingBinding =
        progress.appliedOperations[operationInstanceId.trim()];
    final effectiveDirection = progress.direction ?? existingBinding?.direction;
    final result = service.acknowledgeDisembark(
      progress: progress,
      operationInstanceId: operationInstanceId,
      journeyId: command.journeyId,
    );
    if (result is RailJourneyAdvanceAlreadyApplied) {
      return RailJourneyRuntimeCompleted(
        gameState: gameState,
        alreadyApplied: true,
      );
    }
    if (result
        case RailJourneyAdvanceRefused(
          reason: RailJourneyAdvanceRefusal.idempotencyConflict ||
              RailJourneyAdvanceRefusal.invalidRequest ||
              RailJourneyAdvanceRefusal.invalidState,
        )) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.serviceRefused,
        serviceReason: result.reason,
      );
    }
    if (progress.activeJourneyId != definition.id ||
        effectiveDirection == null) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.inactiveJourney,
      );
    }
    final arrivalEndpoint = effectiveDirection == RailJourneyDirection.outbound
        ? definition.destination
        : definition.origin;
    if (gameState.currentMapId != arrivalEndpoint.stationMapId) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.wrongMap,
      );
    }
    if (gameState.playerPosition != arrivalEndpoint.stationArrivalPos) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.invalidArrivalPosition,
      );
    }
    if (result case RailJourneyAdvanceRefused(:final reason)) {
      return RailJourneyRuntimeBlocked(
        gameState: gameState,
        reason: RailJourneyRuntimeBlockReason.serviceRefused,
        serviceReason: reason,
      );
    }
    return RailJourneyRuntimeCompleted(
      gameState: gameState.copyWith(railJourneyProgress: result.progress),
    );
  }

  RailJourneyDefinition? _definition(
    RailJourneyCatalog catalog,
    String journeyId,
  ) {
    for (final definition in catalog.journeys) {
      if (definition.id == journeyId) return definition;
    }
    return null;
  }

  bool _contains(MapRect rect, GridPos position) {
    return position.x >= rect.pos.x &&
        position.y >= rect.pos.y &&
        position.x < rect.pos.x + rect.size.width &&
        position.y < rect.pos.y + rect.size.height;
  }
}
