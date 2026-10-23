import 'package:meta/meta.dart' show immutable;

import 'narrative_value.dart';

enum SceneIntegerOperandKind { literal, integerFact, gameRead, random }

enum SceneIntegerGameRead { money, partyCount, itemCount }

enum SceneIntegerOperation {
  assign,
  add,
  subtract,
  multiply,
  floorDivide,
  modulo,
}

enum SceneZeroDivisorPolicy { reject, keepValue, keepValueForZeroOrOne }

enum SceneIntegerBoundaryPolicy { clamp, preserveSaturated }

enum SceneMoneyOperation { add, subtract }
enum SceneIntegerCancellationPolicy { leaveUnchanged, restoreInitialAndComplete }

@immutable
final class SceneIntegerOperand {
  const SceneIntegerOperand._(
    this.kind, {
    this.value,
    this.factId,
    this.read,
    this.itemId,
    this.minimum,
    this.maximum,
  });

  factory SceneIntegerOperand.literal(int value) {
    NarrativeValue.integer(value);
    return SceneIntegerOperand._(SceneIntegerOperandKind.literal, value: value);
  }

  factory SceneIntegerOperand.integerFact(String factId) =>
      SceneIntegerOperand._(
        SceneIntegerOperandKind.integerFact,
        factId: sceneIntegerIdentity(factId, 'factId'),
      );

  factory SceneIntegerOperand.gameRead(
    SceneIntegerGameRead read, {
    String? itemId,
  }) {
    if ((read == SceneIntegerGameRead.itemCount) != (itemId != null)) {
      throw ArgumentError('Only itemCount requires an itemId.');
    }
    return SceneIntegerOperand._(
      SceneIntegerOperandKind.gameRead,
      read: read,
      itemId: itemId == null ? null : sceneIntegerIdentity(itemId, 'itemId'),
    );
  }

  factory SceneIntegerOperand.random({
    required int minimum,
    required int maximum,
  }) {
    sceneIntegerBounds(minimum, maximum);
    if (BigInt.from(maximum) - BigInt.from(minimum) + BigInt.one >
        BigInt.from(4294967296)) {
      throw ArgumentError(
        'Random ranges must contain at most 4294967296 values.',
      );
    }
    return SceneIntegerOperand._(
      SceneIntegerOperandKind.random,
      minimum: minimum,
      maximum: maximum,
    );
  }

  factory SceneIntegerOperand.fromJson(Map<String, dynamic> json) {
    final kind = sceneIntegerEnum(SceneIntegerOperandKind.values, json['kind']);
    final fields = switch (kind) {
      SceneIntegerOperandKind.literal => {'kind', 'value'},
      SceneIntegerOperandKind.integerFact => {'kind', 'factId'},
      SceneIntegerOperandKind.gameRead => {
        'kind',
        'read',
        if (json['read'] == 'itemCount') 'itemId',
      },
      SceneIntegerOperandKind.random => {'kind', 'minimum', 'maximum'},
    };
    sceneIntegerFields(json, fields);
    try {
      return switch (kind) {
        SceneIntegerOperandKind.literal => SceneIntegerOperand.literal(
          sceneIntegerInt(json, 'value'),
        ),
        SceneIntegerOperandKind.integerFact => SceneIntegerOperand.integerFact(
          sceneIntegerString(json, 'factId'),
        ),
        SceneIntegerOperandKind.gameRead => SceneIntegerOperand.gameRead(
          sceneIntegerEnum(SceneIntegerGameRead.values, json['read']),
          itemId: json['read'] == 'itemCount'
              ? sceneIntegerString(json, 'itemId')
              : null,
        ),
        SceneIntegerOperandKind.random => SceneIntegerOperand.random(
          minimum: sceneIntegerInt(json, 'minimum'),
          maximum: sceneIntegerInt(json, 'maximum'),
        ),
      };
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final SceneIntegerOperandKind kind;
  final int? value, minimum, maximum;
  final String? factId, itemId;
  final SceneIntegerGameRead? read;
  Set<String> get referencedFactIds => factId == null ? const {} : {factId!};
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (value != null) 'value': value,
    if (factId != null) 'factId': factId,
    if (read != null) 'read': read!.name,
    if (itemId != null) 'itemId': itemId,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneIntegerOperand &&
      other.kind == kind &&
      other.value == value &&
      other.factId == factId &&
      other.read == read &&
      other.itemId == itemId &&
      other.minimum == minimum &&
      other.maximum == maximum;
  @override
  int get hashCode =>
      Object.hash(kind, value, factId, read, itemId, minimum, maximum);
}

String sceneIntegerIdentity(String value, String field) {
  if (value.isEmpty || value.trim() != value)
    throw ArgumentError.value(value, field);
  return value;
}

void sceneIntegerBounds(int minimum, int maximum) {
  NarrativeValue.integer(minimum);
  NarrativeValue.integer(maximum);
  if (minimum > maximum) throw ArgumentError('minimum must not exceed maximum');
}

void sceneIntegerFields(Map<String, dynamic> json, Set<String> fields) {
  if (json.keys.any((field) => !fields.contains(field)))
    throw const FormatException('Unknown integer contract field.');
}

T sceneIntegerEnum<T extends Enum>(List<T> values, Object? raw) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unknown integer contract enum: $raw.');
}

int sceneIntegerInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! int) throw FormatException('$field must be an integer.');
  return value;
}

String sceneIntegerString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}
