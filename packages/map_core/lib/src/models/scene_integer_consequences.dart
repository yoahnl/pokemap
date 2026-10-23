part of 'scene_consequence.dart';

@immutable
final class SceneCalculateIntegerFactsConsequence extends SceneConsequence {
  SceneCalculateIntegerFactsConsequence({
    required List<String> factIds,
    required this.operation,
    required this.operand,
    required this.minimum,
    required this.maximum,
    this.zeroDivisorPolicy = SceneZeroDivisorPolicy.reject,
    this.boundaryPolicy = SceneIntegerBoundaryPolicy.clamp,
  }) : factIds = List.unmodifiable(factIds) {
    if (factIds.isEmpty ||
        factIds.length > 1024 ||
        factIds.toSet().length != factIds.length) {
      throw ArgumentError(
        'Integer calculation requires 1 to 1024 unique Fact targets.',
      );
    }
    for (final id in factIds) {
      sceneIntegerIdentity(id, 'factIds');
    }
    sceneIntegerBounds(minimum, maximum);
  }
  factory SceneCalculateIntegerFactsConsequence.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['kind'] != 'calculateIntegerFacts')
      throw const FormatException('Invalid calculation kind.');
    sceneIntegerFields(json, {
      'kind',
      'factIds',
      'operation',
      'operand',
      'minimum',
      'maximum',
      'zeroDivisorPolicy',
      'boundaryPolicy',
    });
    final ids = json['factIds'];
    if (ids is! List ||
        ids.any((id) => id is! String) ||
        json['operand'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid integer targets or operand.');
    }
    try {
      return SceneCalculateIntegerFactsConsequence(
        factIds: ids.cast<String>(),
        operation: sceneIntegerEnum(
          SceneIntegerOperation.values,
          json['operation'],
        ),
        operand: SceneIntegerOperand.fromJson(
          json['operand'] as Map<String, dynamic>,
        ),
        minimum: sceneIntegerInt(json, 'minimum'),
        maximum: sceneIntegerInt(json, 'maximum'),
        zeroDivisorPolicy: json['zeroDivisorPolicy'] == null
            ? SceneZeroDivisorPolicy.reject
            : sceneIntegerEnum(
                SceneZeroDivisorPolicy.values,
                json['zeroDivisorPolicy'],
              ),
        boundaryPolicy: json['boundaryPolicy'] == null
            ? SceneIntegerBoundaryPolicy.clamp
            : sceneIntegerEnum(
                SceneIntegerBoundaryPolicy.values,
                json['boundaryPolicy'],
              ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }
  final List<String> factIds;
  final SceneIntegerOperation operation;
  final SceneIntegerOperand operand;
  final int minimum, maximum;
  final SceneZeroDivisorPolicy zeroDivisorPolicy;
  final SceneIntegerBoundaryPolicy boundaryPolicy;
  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.calculateIntegerFacts;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'factIds': factIds,
    'operation': operation.name,
    'operand': operand.toJson(),
    'minimum': minimum,
    'maximum': maximum,
    'zeroDivisorPolicy': zeroDivisorPolicy.name,
    'boundaryPolicy': boundaryPolicy.name,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneCalculateIntegerFactsConsequence &&
      other.operation == operation &&
      other.operand == operand &&
      other.minimum == minimum &&
      other.maximum == maximum &&
      other.zeroDivisorPolicy == zeroDivisorPolicy &&
      other.boundaryPolicy == boundaryPolicy &&
      other.factIds.length == factIds.length &&
      factIds.indexed.every((entry) => entry.$2 == other.factIds[entry.$1]);
  @override
  int get hashCode => Object.hash(
    operation,
    operand,
    minimum,
    maximum,
    zeroDivisorPolicy,
    boundaryPolicy,
    Object.hashAll(factIds),
  );
}

@immutable
final class SceneAdjustMoneyConsequence extends SceneConsequence {
  SceneAdjustMoneyConsequence({
    required this.operation,
    required this.amount,
    required this.minimum,
    required this.maximum,
    this.expectedBalance,
  }) {
    sceneIntegerBounds(minimum, maximum);
    if (minimum < 0 || amount.kind == SceneIntegerOperandKind.random)
      throw ArgumentError(
        'Money requires nonnegative bounds and a deterministic operand.',
      );
    if (expectedBalance != null) {
      NarrativeValue.integer(expectedBalance!);
      if (expectedBalance! < 0)
        throw ArgumentError('Expected balance must be nonnegative.');
    }
  }
  factory SceneAdjustMoneyConsequence.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'adjustMoney')
      throw const FormatException('Invalid money mutation kind.');
    sceneIntegerFields(json, {
      'kind',
      'operation',
      'amount',
      'minimum',
      'maximum',
      'expectedBalance',
    });
    if (json['amount'] is! Map<String, dynamic>)
      throw const FormatException('Money amount must be an operand.');
    try {
      return SceneAdjustMoneyConsequence(
        operation: sceneIntegerEnum(
          SceneMoneyOperation.values,
          json['operation'],
        ),
        amount: SceneIntegerOperand.fromJson(
          json['amount'] as Map<String, dynamic>,
        ),
        minimum: sceneIntegerInt(json, 'minimum'),
        maximum: sceneIntegerInt(json, 'maximum'),
        expectedBalance: json['expectedBalance'] == null
            ? null
            : sceneIntegerInt(json, 'expectedBalance'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }
  final SceneMoneyOperation operation;
  final SceneIntegerOperand amount;
  final int minimum, maximum;
  final int? expectedBalance;
  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.adjustMoney;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'operation': operation.name,
    'amount': amount.toJson(),
    'minimum': minimum,
    'maximum': maximum,
    if (expectedBalance != null) 'expectedBalance': expectedBalance,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneAdjustMoneyConsequence &&
      other.operation == operation &&
      other.amount == amount &&
      other.minimum == minimum &&
      other.maximum == maximum &&
      other.expectedBalance == expectedBalance;
  @override
  int get hashCode =>
      Object.hash(operation, amount, minimum, maximum, expectedBalance);
}
