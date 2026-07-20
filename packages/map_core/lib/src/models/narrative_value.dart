import 'package:meta/meta.dart' show immutable;

enum NarrativeValueKind {
  boolean('bool'),
  integer('int'),
  string('string');

  const NarrativeValueKind(this.wireName);

  final String wireName;

  List<NarrativeFactOperator> get compatibleOperators => switch (this) {
        NarrativeValueKind.boolean || NarrativeValueKind.string => const [
            NarrativeFactOperator.equals,
            NarrativeFactOperator.notEquals,
          ],
        NarrativeValueKind.integer => NarrativeFactOperator.values,
      };

  static NarrativeValueKind fromWireName(String value) => switch (value) {
        'bool' => NarrativeValueKind.boolean,
        'int' => NarrativeValueKind.integer,
        'string' => NarrativeValueKind.string,
        _ => throw FormatException('Unknown NarrativeValue kind "$value".'),
      };
}

enum NarrativeFactOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
}

@immutable
final class NarrativeValue {
  const NarrativeValue.boolean(bool value)
      : kind = NarrativeValueKind.boolean,
        _value = value;

  factory NarrativeValue.integer(int value) {
    const maxExactJsonInteger = 9007199254740991;
    if (value < -maxExactJsonInteger || value > maxExactJsonInteger) {
      throw ArgumentError.value(
        value,
        'value',
        'must remain within the exact interoperable JSON integer range',
      );
    }
    return NarrativeValue._(NarrativeValueKind.integer, value);
  }

  const NarrativeValue.string(String value)
      : kind = NarrativeValueKind.string,
        _value = value;

  const NarrativeValue._(this.kind, this._value);

  factory NarrativeValue.fromJson(
    Object? value, {
    NarrativeValueKind? declaredKind,
  }) {
    final inferredKind = switch (value) {
      bool _ => NarrativeValueKind.boolean,
      int _ => NarrativeValueKind.integer,
      String _ => NarrativeValueKind.string,
      _ => throw FormatException(
          'NarrativeValue must be a bool, exact integer or string.',
        ),
    };
    if (declaredKind != null && declaredKind != inferredKind) {
      throw FormatException(
        'NarrativeValue kind ${declaredKind.wireName} does not match '
        '${inferredKind.wireName}.',
      );
    }
    return switch (inferredKind) {
      NarrativeValueKind.boolean => NarrativeValue.boolean(value as bool),
      NarrativeValueKind.integer => NarrativeValue.integer(value as int),
      NarrativeValueKind.string => NarrativeValue.string(value as String),
    };
  }

  final NarrativeValueKind kind;
  final Object _value;

  Object toJson() => _value;

  bool get boolValue => kind == NarrativeValueKind.boolean
      ? _value as bool
      : throw StateError('NarrativeValue is ${kind.wireName}, not bool.');

  int get intValue => kind == NarrativeValueKind.integer
      ? _value as int
      : throw StateError('NarrativeValue is ${kind.wireName}, not int.');

  String get stringValue => kind == NarrativeValueKind.string
      ? _value as String
      : throw StateError('NarrativeValue is ${kind.wireName}, not string.');

  bool matches(NarrativeFactOperator operator, NarrativeValue expected) {
    if (kind != expected.kind) {
      throw ArgumentError(
        'Cannot compare ${kind.wireName} with ${expected.kind.wireName}.',
      );
    }
    if (!kind.compatibleOperators.contains(operator)) {
      throw ArgumentError.value(
        operator,
        'operator',
        'is not compatible with ${kind.wireName}',
      );
    }
    final comparison = kind == NarrativeValueKind.integer
        ? intValue.compareTo(expected.intValue)
        : 0;
    return switch (operator) {
      NarrativeFactOperator.equals => this == expected,
      NarrativeFactOperator.notEquals => this != expected,
      NarrativeFactOperator.greaterThan => comparison > 0,
      NarrativeFactOperator.greaterThanOrEqual => comparison >= 0,
      NarrativeFactOperator.lessThan => comparison < 0,
      NarrativeFactOperator.lessThanOrEqual => comparison <= 0,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeValue && other.kind == kind && other._value == _value;

  @override
  int get hashCode => Object.hash(kind, _value);

  @override
  String toString() => 'NarrativeValue.${kind.wireName}($_value)';
}
