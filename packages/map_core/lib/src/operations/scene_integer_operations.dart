import '../models/game_state.dart';
import '../models/narrative_value.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/scene_integer_operand.dart';
import 'narrative_fact_runtime.dart';

enum SceneIntegerOperationError {
  unknownFact,
  ambiguousFact,
  invalidRuntimeKey,
  typeMismatch,
  zeroDivisor,
  staleBalance,
}

final class SceneIntegerOperationResult {
  const SceneIntegerOperationResult(this.gameState, [this.error]);
  final GameState gameState;
  final SceneIntegerOperationError? error;
  bool get success => error == null;
}

final class SceneIntegerOperations {
  const SceneIntegerOperations(this.resolver);
  final NarrativeFactRuntimeResolver resolver;

  int read(GameState state, SceneIntegerOperand operand) =>
      switch (operand.kind) {
        SceneIntegerOperandKind.literal => operand.value!,
        SceneIntegerOperandKind.integerFact => _fact(state, operand.factId!),
        SceneIntegerOperandKind.gameRead => switch (operand.read!) {
          SceneIntegerGameRead.money => state.trainerProfile.money,
          SceneIntegerGameRead.partyCount => state.party.members.length,
          SceneIntegerGameRead.itemCount =>
            state.bag.entries
                .where((entry) => entry.itemId == operand.itemId)
                .fold(0, (total, entry) => total + entry.quantity),
        },
        SceneIntegerOperandKind.random => throw StateError(
          'A random operand requires a committed calculation.',
        ),
      };

  int _fact(GameState state, String id) {
    final resolved = resolver.resolve(
      factId: id,
      runtimeState: state.narrativeFactRuntimeState,
      storyFlags: state.storyFlags,
    );
    return switch (resolved) {
      NarrativeFactRuntimeResolved()
          when resolved.fact.valueKind == NarrativeValueKind.integer &&
              resolved.narrativeValue.kind == NarrativeValueKind.integer =>
        resolved.narrativeValue.intValue,
      NarrativeFactRuntimeResolved() =>
        throw SceneIntegerOperationError.typeMismatch,
      NarrativeFactRuntimeUnknownFact() =>
        throw SceneIntegerOperationError.unknownFact,
      NarrativeFactRuntimeAmbiguousFact() =>
        throw SceneIntegerOperationError.ambiguousFact,
      NarrativeFactRuntimeInvalidRuntimeKey() =>
        throw SceneIntegerOperationError.invalidRuntimeKey,
    };
  }

  SceneIntegerOperationResult calculate(
    GameState state,
    SceneCalculateIntegerFactsConsequence command,
  ) {
    try {
      var next = state;
      final int scalar;
      if (command.operand.kind == SceneIntegerOperandKind.random) {
        final drawn = state.sceneRandomState.draw(
          saveId: state.saveId,
          minimum: command.operand.minimum!,
          maximum: command.operand.maximum!,
        );
        scalar = drawn.value;
        next = state.copyWith(sceneRandomState: drawn.next);
      } else {
        scalar = read(state, command.operand);
      }
      final oldValues = {
        for (final id in command.factIds) id: _fact(state, id),
      };
      final division =
          command.operation == SceneIntegerOperation.floorDivide ||
          command.operation == SceneIntegerOperation.modulo;
      if (division &&
          (scalar == 0 ||
              scalar == 1 &&
                  command.zeroDivisorPolicy ==
                      SceneZeroDivisorPolicy.keepValueForZeroOrOne)) {
        if (command.zeroDivisorPolicy == SceneZeroDivisorPolicy.reject)
          return SceneIntegerOperationResult(
            state,
            SceneIntegerOperationError.zeroDivisor,
          );
        return SceneIntegerOperationResult(next);
      }
      final operand = BigInt.from(scalar);
      for (final entry in oldValues.entries) {
        if (command.boundaryPolicy ==
                SceneIntegerBoundaryPolicy.preserveSaturated &&
            (command.operation == SceneIntegerOperation.assign && entry.value == scalar ||
             command.operation == SceneIntegerOperation.multiply && scalar == 1 ||
             command.operation == SceneIntegerOperation.add &&
                    entry.value >= command.maximum ||
                command.operation == SceneIntegerOperation.subtract &&
                    entry.value <= command.minimum))
          continue;
        final old = BigInt.from(entry.value);
        final value = switch (command.operation) {
          SceneIntegerOperation.assign => operand,
          SceneIntegerOperation.add => old + operand,
          SceneIntegerOperation.subtract => old - operand,
          SceneIntegerOperation.multiply => old * operand,
          SceneIntegerOperation.floorDivide => _floor(old, operand),
          SceneIntegerOperation.modulo => old - _floor(old, operand) * operand,
        };
        final low = BigInt.from(command.minimum),
            high = BigInt.from(command.maximum);
        final bounded = value < low
            ? low
            : value > high
            ? high
            : value;
        final result = NarrativeFactRuntimeWriter(resolver).setFactValue(
          gameState: next,
          factId: entry.key,
          value: NarrativeValue.integer(bounded.toInt()),
        );
        if (!result.success)
          throw StateError(
            'Validated integer Fact changed during a pure calculation.',
          );
        next = result.gameState;
      }
      return SceneIntegerOperationResult(next);
    } on SceneIntegerOperationError catch (error) {
      return SceneIntegerOperationResult(state, error);
    }
  }

  SceneIntegerOperationResult adjustMoney(
    GameState state,
    SceneAdjustMoneyConsequence command,
  ) {
    try {
      if (command.expectedBalance != null &&
          command.expectedBalance != state.trainerProfile.money)
        return SceneIntegerOperationResult(
          state,
          SceneIntegerOperationError.staleBalance,
        );
      final amount = read(state, command.amount);

      final old = BigInt.from(state.trainerProfile.money),
          delta = BigInt.from(amount);
      final value = command.operation == SceneMoneyOperation.add
          ? old + delta
          : old - delta;
      final low = BigInt.from(command.minimum),
          high = BigInt.from(command.maximum);
      final bounded = value < low
          ? low
          : value > high
          ? high
          : value;
      return SceneIntegerOperationResult(
        state.copyWith(
          trainerProfile: state.trainerProfile.copyWith(money: bounded.toInt()),
        ),
      );
    } on SceneIntegerOperationError catch (error) {
      return SceneIntegerOperationResult(state, error);
    }
  }

  bool compare(GameState state, SceneConditionSource source) {
    if (source.sourceKind != SceneConditionSourceKind.integerComparison)
      throw ArgumentError('Expected an integer comparison.');
    return NarrativeValue.integer(read(state, source.integerLeft!)).matches(
      source.integerComparisonOperator!,
      NarrativeValue.integer(read(state, source.integerRight!)),
    );
  }
}

BigInt _floor(BigInt left, BigInt right) {
  final quotient = left ~/ right;
  return left.remainder(right) != BigInt.zero &&
          left.isNegative != right.isNegative
      ? quotient - BigInt.one
      : quotient;
}
