import 'dart:math' as math;

import 'package:map_core/map_core.dart';

final class RailJourneyAccessState {
  const RailJourneyAccessState({
    this.completedStoryStepIds = const <String>{},
    this.activeFactIds = const <String>{},
    this.itemIds = const <String>{},
    this.stampIds = const <String>{},
  });

  final Set<String> completedStoryStepIds;
  final Set<String> activeFactIds;
  final Set<String> itemIds;
  final Set<String> stampIds;
}

enum RailJourneyBeginRefusal {
  invalidRequest,
  invalidLifecycle,
  wrongStation,
  requirementsNotMet,
  segmentLocked,
  insufficientFunds,
  idempotencyConflict,
}

sealed class RailJourneyBeginResult {
  const RailJourneyBeginResult({required this.progress});

  final RailJourneyProgress progress;
}

final class RailJourneyBeginApplied extends RailJourneyBeginResult {
  const RailJourneyBeginApplied({
    required super.progress,
    required this.chargedAmount,
  });

  final int chargedAmount;
}

final class RailJourneyBeginAlreadyApplied extends RailJourneyBeginResult {
  const RailJourneyBeginAlreadyApplied({required super.progress});
}

final class RailJourneyBeginRefused extends RailJourneyBeginResult {
  const RailJourneyBeginRefused({
    required super.progress,
    required this.reason,
  });

  final RailJourneyBeginRefusal reason;
}

enum RailJourneyAdvanceEvent {
  doorsClosed,
  arrivalReached,
  destinationDoorUsed,
}

enum RailJourneyAdvanceRefusal {
  invalidRequest,
  invalidState,
  invalidLifecycle,
  idempotencyConflict,
}

sealed class RailJourneyAdvanceResult {
  const RailJourneyAdvanceResult({required this.progress});

  final RailJourneyProgress progress;
}

final class RailJourneyAdvanceApplied extends RailJourneyAdvanceResult {
  const RailJourneyAdvanceApplied({required super.progress});
}

final class RailJourneyAdvanceAlreadyApplied extends RailJourneyAdvanceResult {
  const RailJourneyAdvanceAlreadyApplied({required super.progress});
}

final class RailJourneyAdvanceRefused extends RailJourneyAdvanceResult {
  const RailJourneyAdvanceRefused({
    required super.progress,
    required this.reason,
  });

  final RailJourneyAdvanceRefusal reason;
}

final class RailJourneyFareReserve {
  const RailJourneyFareReserve({
    required this.semanticCurrencyId,
    required this.balance,
    required this.requiredAmount,
    required this.reservedAmount,
    required this.spendableAmount,
    required this.shortfallAmount,
    this.nextJourneyId,
  });

  final String semanticCurrencyId;
  final String? nextJourneyId;
  final int balance;
  final int requiredAmount;
  final int reservedAmount;
  final int spendableAmount;
  final int shortfallAmount;
}

final class RailJourneyService {
  const RailJourneyService();

  RailJourneyBeginResult begin({
    required RailJourneyDefinition definition,
    required RailJourneyProgress progress,
    required RailJourneyAccessState access,
    required String operationInstanceId,
    required RailJourneyDirection direction,
    required String currentStationMapId,
    required RailJourneyDoorSide doorSide,
  }) {
    final normalizedOperationId = operationInstanceId.trim();
    final normalizedStationMapId = currentStationMapId.trim();
    if (normalizedOperationId.isEmpty || normalizedStationMapId.isEmpty) {
      return RailJourneyBeginRefused(
        progress: progress,
        reason: RailJourneyBeginRefusal.invalidRequest,
      );
    }

    late final RailJourneyDefinition journey;
    late final RailJourneyProgress current;
    try {
      journey = definition.validated();
      current = progress.validated();
    } on StateError {
      return RailJourneyBeginRefused(
        progress: progress,
        reason: RailJourneyBeginRefusal.invalidRequest,
      );
    }

    final expectedStationMapId = direction == RailJourneyDirection.outbound
        ? journey.origin.stationMapId
        : journey.destination.stationMapId;
    final operationBinding = RailJourneyOperationBinding(
      kind: RailJourneyOperationKind.begin,
      journeyId: journey.id,
      direction: direction,
      stationMapId: expectedStationMapId,
      doorSide: doorSide,
    ).validated();
    final existingBinding = current.appliedOperations[normalizedOperationId];
    if (existingBinding != null) {
      if (existingBinding == operationBinding) {
        return RailJourneyBeginAlreadyApplied(progress: progress);
      }
      return RailJourneyBeginRefused(
        progress: progress,
        reason: RailJourneyBeginRefusal.idempotencyConflict,
      );
    }
    if (current.lifecycle != RailJourneyLifecycle.idleAtOrigin) {
      return RailJourneyBeginRefused(
        progress: progress,
        reason: RailJourneyBeginRefusal.invalidLifecycle,
      );
    }

    if (normalizedStationMapId != expectedStationMapId) {
      return RailJourneyBeginRefused(
        progress: progress,
        reason: RailJourneyBeginRefusal.wrongStation,
      );
    }

    final alreadyUnlocked = current.unlockedJourneyIds.contains(journey.id);
    if (direction == RailJourneyDirection.returnJourney && !alreadyUnlocked) {
      return RailJourneyBeginRefused(
        progress: progress,
        reason: RailJourneyBeginRefusal.segmentLocked,
      );
    }
    if (!alreadyUnlocked && !_meets(journey.requirements, access)) {
      return RailJourneyBeginRefused(
        progress: progress,
        reason: RailJourneyBeginRefusal.requirementsNotMet,
      );
    }

    var chargedAmount = 0;
    final balances = Map<String, int>.of(current.semanticCurrencyBalances);
    if (!alreadyUnlocked &&
        journey.fare.policy == RailJourneyFarePolicy.firstUnlockOnly) {
      final currencyId = journey.fare.semanticCurrencyId!;
      final balance = balances[currencyId] ?? 0;
      if (balance < journey.fare.amount) {
        return RailJourneyBeginRefused(
          progress: progress,
          reason: RailJourneyBeginRefusal.insufficientFunds,
        );
      }
      chargedAmount = journey.fare.amount;
      balances[currencyId] = balance - chargedAmount;
    }

    final unlockedJourneyIds = <String>{
      ...current.unlockedJourneyIds,
      journey.id,
    };
    final paidJourneyIds = <String>{
      ...current.firstUnlockPaidJourneyIds,
      if (chargedAmount > 0) journey.id,
    };
    final next = current.copyWith(
      activeJourneyId: journey.id,
      direction: direction,
      lifecycle: RailJourneyLifecycle.boarding,
      unlockedJourneyIds: unlockedJourneyIds,
      firstUnlockPaidJourneyIds: paidJourneyIds,
      unlockedStationMapIds: <String>{
        ...current.unlockedStationMapIds,
        journey.origin.stationMapId,
        journey.destination.stationMapId,
      },
      semanticCurrencyBalances: balances,
      appliedOperations: <String, RailJourneyOperationBinding>{
        ...current.appliedOperations,
        normalizedOperationId: operationBinding,
      },
    );
    return RailJourneyBeginApplied(
      progress: next.validated(),
      chargedAmount: chargedAmount,
    );
  }

  RailJourneyAdvanceResult advance({
    required RailJourneyProgress progress,
    required String operationInstanceId,
    required String journeyId,
    required RailJourneyAdvanceEvent event,
    RailJourneyDoorSide? doorSide,
  }) {
    final normalizedOperationId = operationInstanceId.trim();
    final normalizedJourneyId = journeyId.trim();
    if (normalizedOperationId.isEmpty || normalizedJourneyId.isEmpty) {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidRequest,
      );
    }
    late final RailJourneyProgress current;
    try {
      current = progress.validated();
    } on StateError {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidState,
      );
    }

    final existingBinding = current.appliedOperations[normalizedOperationId];
    final direction = current.direction ?? existingBinding?.direction;
    if (direction == null) {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidState,
      );
    }
    late final RailJourneyOperationBinding operationBinding;
    try {
      operationBinding = RailJourneyOperationBinding(
        kind: switch (event) {
          RailJourneyAdvanceEvent.doorsClosed =>
            RailJourneyOperationKind.doorsClosed,
          RailJourneyAdvanceEvent.arrivalReached =>
            RailJourneyOperationKind.arrivalReached,
          RailJourneyAdvanceEvent.destinationDoorUsed =>
            RailJourneyOperationKind.destinationDoorUsed,
        },
        journeyId: normalizedJourneyId,
        direction: direction,
        doorSide: doorSide,
      ).validated();
    } on StateError {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidRequest,
      );
    }
    if (existingBinding != null) {
      if (existingBinding == operationBinding) {
        return RailJourneyAdvanceAlreadyApplied(progress: progress);
      }
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.idempotencyConflict,
      );
    }
    if (current.activeJourneyId != normalizedJourneyId) {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidLifecycle,
      );
    }

    final nextLifecycle = switch ((current.lifecycle, event)) {
      (
        RailJourneyLifecycle.boarding,
        RailJourneyAdvanceEvent.doorsClosed,
      ) =>
        RailJourneyLifecycle.inTransit,
      (
        RailJourneyLifecycle.inTransit,
        RailJourneyAdvanceEvent.arrivalReached,
      ) =>
        RailJourneyLifecycle.arrived,
      (
        RailJourneyLifecycle.arrived,
        RailJourneyAdvanceEvent.destinationDoorUsed,
      ) =>
        RailJourneyLifecycle.disembarked,
      _ => null,
    };
    if (nextLifecycle == null) {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidLifecycle,
      );
    }
    return RailJourneyAdvanceApplied(
      progress: current.copyWith(
        lifecycle: nextLifecycle,
        appliedOperations: <String, RailJourneyOperationBinding>{
          ...current.appliedOperations,
          normalizedOperationId: operationBinding,
        },
      ).validated(),
    );
  }

  RailJourneyAdvanceResult acknowledgeDisembark({
    required RailJourneyProgress progress,
    required String operationInstanceId,
    required String journeyId,
  }) {
    final normalizedOperationId = operationInstanceId.trim();
    final normalizedJourneyId = journeyId.trim();
    if (normalizedOperationId.isEmpty || normalizedJourneyId.isEmpty) {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidRequest,
      );
    }
    late final RailJourneyProgress current;
    try {
      current = progress.validated();
    } on StateError {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidState,
      );
    }
    final existingBinding = current.appliedOperations[normalizedOperationId];
    final direction = current.direction ?? existingBinding?.direction;
    if (direction == null) {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidState,
      );
    }
    final operationBinding = RailJourneyOperationBinding(
      kind: RailJourneyOperationKind.acknowledge,
      journeyId: normalizedJourneyId,
      direction: direction,
    ).validated();
    if (existingBinding != null) {
      if (existingBinding == operationBinding) {
        return RailJourneyAdvanceAlreadyApplied(progress: progress);
      }
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.idempotencyConflict,
      );
    }
    if (current.activeJourneyId != normalizedJourneyId) {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidLifecycle,
      );
    }
    if (current.lifecycle != RailJourneyLifecycle.disembarked) {
      return RailJourneyAdvanceRefused(
        progress: progress,
        reason: RailJourneyAdvanceRefusal.invalidLifecycle,
      );
    }
    return RailJourneyAdvanceApplied(
      progress: current.copyWith(
        activeJourneyId: null,
        direction: null,
        lifecycle: RailJourneyLifecycle.idleAtOrigin,
        appliedOperations: <String, RailJourneyOperationBinding>{
          ...current.appliedOperations,
          normalizedOperationId: operationBinding,
        },
      ).validated(),
    );
  }

  RailJourneyFareReserve nextFareReserve({
    required RailJourneyProgress progress,
    required Iterable<RailJourneyDefinition> orderedJourneys,
    required String semanticCurrencyId,
  }) {
    final currencyId = semanticCurrencyId.trim();
    if (currencyId.isEmpty) {
      throw ArgumentError.value(
        semanticCurrencyId,
        'semanticCurrencyId',
        'must not be empty',
      );
    }
    final current = progress.validated();
    final balance = current.semanticCurrencyBalances[currencyId] ?? 0;
    RailJourneyDefinition? nextJourney;
    for (final definition in orderedJourneys) {
      final journey = definition.validated();
      if (current.unlockedJourneyIds.contains(journey.id) ||
          journey.fare.policy != RailJourneyFarePolicy.firstUnlockOnly ||
          journey.fare.semanticCurrencyId != currencyId) {
        continue;
      }
      nextJourney = journey;
      break;
    }
    final requiredAmount = nextJourney?.fare.amount ?? 0;
    final reservedAmount = math.min(balance, requiredAmount);
    return RailJourneyFareReserve(
      semanticCurrencyId: currencyId,
      nextJourneyId: nextJourney?.id,
      balance: balance,
      requiredAmount: requiredAmount,
      reservedAmount: reservedAmount,
      spendableAmount: math.max(0, balance - requiredAmount),
      shortfallAmount: math.max(0, requiredAmount - balance),
    );
  }

  bool _meets(
    RailJourneyRequirements requirements,
    RailJourneyAccessState access,
  ) {
    if (!access.completedStoryStepIds
        .containsAll(requirements.completedStoryStepIds)) {
      return false;
    }
    if (!access.activeFactIds.containsAll(requirements.requiredFactIds)) {
      return false;
    }
    if (requirements.requiredAnyFactIds.isNotEmpty &&
        !requirements.requiredAnyFactIds.any(access.activeFactIds.contains)) {
      return false;
    }
    return access.itemIds.containsAll(requirements.requiredItemIds) &&
        access.stampIds.containsAll(requirements.requiredStampIds);
  }
}
