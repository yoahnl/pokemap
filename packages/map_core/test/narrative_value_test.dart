import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeValue', () {
    test('round-trips the closed bool int and Unicode string values', () {
      final values = [
        const NarrativeValue.boolean(false),
        NarrativeValue.integer(42),
        const NarrativeValue.string('Brume 🌫️'),
      ];

      for (final value in values) {
        expect(
          NarrativeValue.fromJson(value.toJson(), declaredKind: value.kind),
          value,
        );
      }
    });

    test('exposes only operators compatible with each type', () {
      expect(
        NarrativeValueKind.boolean.compatibleOperators,
        [NarrativeFactOperator.equals, NarrativeFactOperator.notEquals],
      );
      expect(
        NarrativeValueKind.integer.compatibleOperators,
        containsAll([
          NarrativeFactOperator.equals,
          NarrativeFactOperator.greaterThan,
          NarrativeFactOperator.lessThanOrEqual,
        ]),
      );
      expect(
        NarrativeValueKind.string.compatibleOperators,
        [NarrativeFactOperator.equals, NarrativeFactOperator.notEquals],
      );
    });

    test('evaluates compatible comparisons and rejects type mismatch', () {
      expect(
        NarrativeValue.integer(7).matches(
          NarrativeFactOperator.greaterThan,
          NarrativeValue.integer(3),
        ),
        isTrue,
      );
      expect(
        const NarrativeValue.string('port').matches(
          NarrativeFactOperator.notEquals,
          const NarrativeValue.string('phare'),
        ),
        isTrue,
      );
      expect(
        () => const NarrativeValue.boolean(true).matches(
          NarrativeFactOperator.equals,
          NarrativeValue.integer(1),
        ),
        throwsArgumentError,
      );
      expect(
        () => const NarrativeValue.string('a').matches(
          NarrativeFactOperator.greaterThan,
          const NarrativeValue.string('b'),
        ),
        throwsArgumentError,
      );
    });

    test('rejects integers outside the exact JSON interoperability range', () {
      expect(
        () => NarrativeValue.integer(9007199254740992),
        throwsArgumentError,
      );
      expect(
        () => NarrativeValue.integer(-9007199254740992),
        throwsArgumentError,
      );
    });
  });
}
