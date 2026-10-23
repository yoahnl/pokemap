import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final facts = [
    NarrativeFactDefinition(id: 'a', label: 'A', initialValue: NarrativeValue.integer(3)),
    NarrativeFactDefinition(id: 'b', label: 'B', initialValue: NarrativeValue.integer(-7)),
    NarrativeFactDefinition(id: 'flag', label: 'Flag'),
  ];
  final evaluator = SceneIntegerOperations(NarrativeFactRuntimeResolver.fromFacts(facts));
  const state = GameState(saveId: 'integer');
  SceneCalculateIntegerFactsConsequence calculation({
    List<String> targets = const ['a', 'b'],
    SceneIntegerOperation operation = SceneIntegerOperation.add,
    SceneIntegerOperand? operand,
    SceneZeroDivisorPolicy zero = SceneZeroDivisorPolicy.reject,
    int minimum = -100,
    int maximum = 100,
  }) => SceneCalculateIntegerFactsConsequence(
    factIds: targets, operation: operation,
    operand: operand ?? SceneIntegerOperand.integerFact('a'),
    minimum: minimum, maximum: maximum, zeroDivisorPolicy: zero,
  );
  int value(GameState result, String id) => result.narrativeFactRuntimeState.valueFor(id)!.intValue;

  test('range operand is captured once and saved values are reusable', () {
    final command = calculation();
    expect(SceneConsequence.fromJson(command.toJson()), command);
    final result = evaluator.calculate(state, command);
    expect(result.success, isTrue);
    expect(value(result.gameState, 'a'), 6);
    expect(value(result.gameState, 'b'), -4);
    final saved = gameStateFromSaveData(saveDataFromGameState(result.gameState));
    final again = evaluator.calculate(saved, command);
    expect(value(again.gameState, 'a'), 12);
    expect(value(again.gameState, 'b'), 2);
    expect(state.narrativeFactRuntimeState.valuesByFactId, isEmpty);
  });
  test('floor division and modulo follow signed integer semantics', () {
    final divided = evaluator.calculate(state, calculation(operation: SceneIntegerOperation.floorDivide));
    expect(value(divided.gameState, 'b'), -3);
    final modulo = evaluator.calculate(state, calculation(operation: SceneIntegerOperation.modulo));
    expect(value(modulo.gameState, 'b'), 2);
  });
  test('BigInt multiplication clamps before converting to interoperable integers', () {
    const limit = 9007199254740991;
    final result = evaluator.calculate(state, calculation(
      operation: SceneIntegerOperation.multiply, operand: SceneIntegerOperand.literal(limit),
      minimum: -limit, maximum: limit,
    ));
    expect(value(result.gameState, 'a'), limit);
    expect(value(result.gameState, 'b'), -limit);
  });
  test('missing or wrong typed target and operand reject atomically', () {
    for (final command in [
      calculation(targets: ['a', 'missing']),
      calculation(targets: ['a', 'flag']),
      calculation(operand: SceneIntegerOperand.integerFact('flag')),
      calculation(operand: SceneIntegerOperand.integerFact('missing')),
    ]) {
      final result = evaluator.calculate(state, command);
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(identical(result.gameState, state), isTrue);
    }
  });
  test('zero divisor rejects or preserves every old value explicitly', () {
    for (final operation in [SceneIntegerOperation.floorDivide, SceneIntegerOperation.modulo]) {
      final rejected = evaluator.calculate(state, calculation(operation: operation, operand: SceneIntegerOperand.literal(0)));
      expect(rejected.success, isFalse);
      expect(identical(rejected.gameState, state), isTrue);
      final kept = evaluator.calculate(state, calculation(operation: operation, operand: SceneIntegerOperand.literal(0), zero: SceneZeroDivisorPolicy.keepValue));
      expect(kept.success, isTrue);
      expect(kept.gameState, state);
    }
  });
  test('source unit divisor preservation is explicit and ordinary modulo remains mathematical', () {
    final command = SceneCalculateIntegerFactsConsequence(factIds: ['b'],
      operation: SceneIntegerOperation.modulo, operand: SceneIntegerOperand.literal(1),
      minimum: -100, maximum: 100, zeroDivisorPolicy: SceneZeroDivisorPolicy.keepValueForZeroOrOne);
    expect(evaluator.calculate(state, command).gameState, state);
    final ordinary = evaluator.calculate(state, calculation(operation: SceneIntegerOperation.modulo,
      operand: SceneIntegerOperand.literal(1)));
    expect(value(ordinary.gameState, 'b'), 0);
  });
  test('allowlisted game reads and balance mutations are bounded', () {
    const balance = GameState(saveId: 'balance', trainerProfile: TrainerProfile(name: 'Player', money: 70));
    final read = evaluator.calculate(balance, calculation(operation: SceneIntegerOperation.assign,
      operand: SceneIntegerOperand.gameRead(SceneIntegerGameRead.money)));
    expect(value(read.gameState, 'a'), 70);
    final mutation = SceneAdjustMoneyConsequence(operation: SceneMoneyOperation.subtract,
      amount: SceneIntegerOperand.literal(90), minimum: 0, maximum: 999);
    expect(SceneConsequence.fromJson(mutation.toJson()), mutation);
    final result = evaluator.adjustMoney(balance, mutation);
    expect(result.success, isTrue);
    expect(result.gameState.trainerProfile.money, 0);
    expect(balance.trainerProfile.money, 70);
    final debited = evaluator.adjustMoney(balance, SceneAdjustMoneyConsequence(
      operation: SceneMoneyOperation.add, amount: SceneIntegerOperand.literal(-2), minimum: 0, maximum: 999));
    expect(debited.success, isTrue);
    expect(debited.gameState.trainerProfile.money, 68);
    final credited = evaluator.adjustMoney(balance, SceneAdjustMoneyConsequence(
      operation: SceneMoneyOperation.subtract, amount: SceneIntegerOperand.literal(-2), minimum: 0, maximum: 999));
    expect(credited.success, isTrue);
    expect(credited.gameState.trainerProfile.money, 72);
  });
  test('typed comparisons read both operands from the same state', () {
    final source = SceneConditionSource.integerComparison(
      left: SceneIntegerOperand.integerFact('a'),
      comparison: NarrativeFactOperator.greaterThan,
      right: SceneIntegerOperand.integerFact('b'),
    );
    expect(SceneConditionSource.fromJson(source.toJson()), source);
    expect(evaluator.compare(state, source), isTrue);
  });
  test('random operands draw once per range and persist deterministic stream state', () {
    final command = calculation(operation: SceneIntegerOperation.assign,
      operand: SceneIntegerOperand.random(minimum: 1, maximum: 4));
    final first = evaluator.calculate(state, command);
    final replay = evaluator.calculate(state, command);
    expect(first.success, isTrue);
    expect(first.gameState, replay.gameState);
    expect(value(first.gameState, 'a'), inInclusiveRange(1, 4));
    expect(value(first.gameState, 'a'), value(first.gameState, 'b'));
    expect(first.gameState.sceneRandomState, isNot(state.sceneRandomState));
    final restored = gameStateFromSaveData(saveDataFromGameState(first.gameState));
    expect(evaluator.calculate(restored, command).gameState,
      evaluator.calculate(first.gameState, command).gameState);
    expect(() => SceneAdjustMoneyConsequence(operation: SceneMoneyOperation.add,
      amount: SceneIntegerOperand.random(minimum: 1, maximum: 4), minimum: 0, maximum: 999), throwsArgumentError);
  });
  test('preserve saturated policy preserves source identity operations before clamping', () {
    final beyond = state.copyWith(narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(valuesByFactId: {'a': NarrativeValue.integer(1000)}));
    for (final operation in [SceneIntegerOperation.assign, SceneIntegerOperation.multiply]) {
      final operand = SceneIntegerOperand.literal(operation == SceneIntegerOperation.assign ? 1000 : 1);
      final preserved = evaluator.calculate(beyond, SceneCalculateIntegerFactsConsequence(factIds: ['a'],
        operation: operation, operand: operand, minimum: -99, maximum: 99, boundaryPolicy: SceneIntegerBoundaryPolicy.preserveSaturated));
      expect(value(preserved.gameState, 'a'), 1000);
      final ordinary = evaluator.calculate(beyond, SceneCalculateIntegerFactsConsequence(factIds: ['a'],
        operation: operation, operand: operand, minimum: -99, maximum: 99));
      expect(value(ordinary.gameState, 'a'), 99);
    }
  });
  test('contract rejects duplicate ranges, invalid bounds and unknown operands', () {
    expect(() => calculation(targets: ['a', 'a']), throwsArgumentError);
    expect(() => calculation(minimum: 3, maximum: 2), throwsArgumentError);
    expect(() => SceneIntegerOperand.fromJson({'kind': 'gameRead', 'read': 'eval'}), throwsFormatException);
    expect(() => SceneIntegerOperand.fromJson({'kind': 'literal', 'value': 1, 'script': 'x'}), throwsFormatException);
  });
}
