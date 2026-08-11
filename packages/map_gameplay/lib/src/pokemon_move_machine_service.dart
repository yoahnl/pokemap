import 'package:map_core/map_core.dart';

import 'items/bag_operation_result.dart';
import 'items/bag_operations.dart';

const _maximumKnownMoveCount = 4;

final class PokemonMoveMachineCandidate {
  const PokemonMoveMachineCandidate({
    required this.itemId,
    required this.moveId,
    required this.maxPp,
    required this.consumable,
  });

  final String itemId;
  final String moveId;
  final int maxPp;
  final bool consumable;

  PokemonMoveMachineCandidate validated() {
    final normalizedItemId = itemId.trim();
    final normalizedMoveId = moveId.trim();
    if (normalizedItemId.isEmpty || normalizedMoveId.isEmpty) {
      throw ArgumentError('Move machine item and move ids must not be empty.');
    }
    RangeError.checkValueInInterval(maxPp, 1, 99, 'maxPp');
    if (normalizedItemId == itemId && normalizedMoveId == moveId) return this;
    return PokemonMoveMachineCandidate(
      itemId: normalizedItemId,
      moveId: normalizedMoveId,
      maxPp: maxPp,
      consumable: consumable,
    );
  }
}

sealed class PokemonMoveMachineDecision {
  const PokemonMoveMachineDecision();

  const factory PokemonMoveMachineDecision.learn() =
      LearnPokemonMoveMachineDecision;

  const factory PokemonMoveMachineDecision.replace({
    required String expectedMoveId,
  }) = ReplacePokemonMoveMachineDecision;

  const factory PokemonMoveMachineDecision.decline() =
      DeclinePokemonMoveMachineDecision;
}

final class LearnPokemonMoveMachineDecision extends PokemonMoveMachineDecision {
  const LearnPokemonMoveMachineDecision();
}

final class ReplacePokemonMoveMachineDecision
    extends PokemonMoveMachineDecision {
  const ReplacePokemonMoveMachineDecision({
    required this.expectedMoveId,
  });

  final String expectedMoveId;
}

final class DeclinePokemonMoveMachineDecision
    extends PokemonMoveMachineDecision {
  const DeclinePokemonMoveMachineDecision();
}

enum PokemonMoveMachineUseStatus {
  learned,
  replaced,
  declined,
  replacementRequired,
  failed,
}

enum PokemonMoveMachineUseFailure {
  invalidRequest,
  invalidTarget,
  insufficientQuantity,
  alreadyKnown,
  invalidReplacement,
}

final class PokemonMoveMachineUseResult {
  const PokemonMoveMachineUseResult({
    required this.state,
    required this.status,
    this.failure,
    this.replacedMoveId,
    this.consumptionReceipt,
  });

  final GameState state;
  final PokemonMoveMachineUseStatus status;
  final PokemonMoveMachineUseFailure? failure;
  final String? replacedMoveId;
  final ItemConsumptionReceipt? consumptionReceipt;

  bool get isSuccess =>
      status == PokemonMoveMachineUseStatus.learned ||
      status == PokemonMoveMachineUseStatus.replaced;
}

/// Applies a compatibility-resolved TM/HM decision as one pure transaction.
final class PokemonMoveMachineService {
  const PokemonMoveMachineService();

  static const _bagOperations = BagOperations();

  PokemonMoveMachineUseResult apply(
    GameState state, {
    required int partyIndex,
    required PokemonMoveMachineCandidate candidate,
    required PokemonMoveMachineDecision decision,
  }) {
    if (decision is DeclinePokemonMoveMachineDecision) {
      return PokemonMoveMachineUseResult(
        state: state,
        status: PokemonMoveMachineUseStatus.declined,
      );
    }
    final machine = candidate.validated();
    if (partyIndex < 0 || partyIndex >= state.party.members.length) {
      return _failed(
        state,
        PokemonMoveMachineUseFailure.invalidTarget,
      );
    }
    if (_bagOperations.quantityOf(state.bag, machine.itemId) <= 0) {
      return _failed(
        state,
        PokemonMoveMachineUseFailure.insufficientQuantity,
      );
    }

    final pokemon = state.party.members[partyIndex];
    final moves = [...pokemon.knownMoveIds];
    if (moves.contains(machine.moveId)) {
      return _failed(state, PokemonMoveMachineUseFailure.alreadyKnown);
    }

    String? replacedMoveId;
    if (moves.length >= _maximumKnownMoveCount) {
      if (decision is! ReplacePokemonMoveMachineDecision) {
        return PokemonMoveMachineUseResult(
          state: state,
          status: PokemonMoveMachineUseStatus.replacementRequired,
        );
      }
      final expectedMoveId = decision.expectedMoveId.trim();
      final replaceIndex = moves.indexOf(expectedMoveId);
      if (expectedMoveId.isEmpty || replaceIndex < 0) {
        return _failed(
          state,
          PokemonMoveMachineUseFailure.invalidReplacement,
        );
      }
      replacedMoveId = moves[replaceIndex];
      moves[replaceIndex] = machine.moveId;
    } else {
      if (decision is ReplacePokemonMoveMachineDecision) {
        return _failed(
          state,
          PokemonMoveMachineUseFailure.invalidReplacement,
        );
      }
      moves.add(machine.moveId);
    }

    final ppByMoveId = <String, int>{
      ...?pokemon.currentPpByMoveId,
    };
    if (replacedMoveId != null) ppByMoveId.remove(replacedMoveId);
    ppByMoveId[machine.moveId] = machine.maxPp;
    final consumption = machine.consumable
        ? _bagOperations.consume(
            BagConsumeRequest(
              bag: state.bag,
              itemId: machine.itemId,
              quantity: 1,
              reason: ItemConsumptionReason.appliedEffect,
            ),
          )
        : null;
    if (consumption != null && !consumption.isSuccess) {
      return _failed(
        state,
        PokemonMoveMachineUseFailure.insufficientQuantity,
      );
    }
    final nextBag = consumption?.bag ?? state.bag;
    final nextMembers = [...state.party.members];
    nextMembers[partyIndex] = pokemon.copyWith(
      knownMoveIds: moves,
      currentPpByMoveId: ppByMoveId,
    );
    return PokemonMoveMachineUseResult(
      state: state.copyWith(
        party: PlayerParty(members: nextMembers).normalized(),
        bag: nextBag,
      ),
      status: replacedMoveId == null
          ? PokemonMoveMachineUseStatus.learned
          : PokemonMoveMachineUseStatus.replaced,
      replacedMoveId: replacedMoveId,
      consumptionReceipt: consumption?.consumptionReceipt,
    );
  }

  PokemonMoveMachineUseResult _failed(
    GameState state,
    PokemonMoveMachineUseFailure failure,
  ) {
    return PokemonMoveMachineUseResult(
      state: state,
      status: PokemonMoveMachineUseStatus.failed,
      failure: failure,
    );
  }
}
