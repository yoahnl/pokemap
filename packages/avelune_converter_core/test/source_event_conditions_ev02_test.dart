import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  test('a known false AND child dominates unavailable contextual values', () {
    final condition = SourceEventCondition(
      kind: SourceEventConditionKind.all,
      children: [
        SourceEventCondition(kind: SourceEventConditionKind.playerOnEvent),
        SourceEventCondition(
          kind: SourceEventConditionKind.globalSwitch,
          factId: 'source:project:switch:1',
        ),
      ],
    );
    expect(condition.evaluate(), isFalse);
  });

  test('temporary switch context is explicit and defaults each A-D to false',
      () {
    for (final letter in ['A', 'B', 'C', 'D']) {
      final condition = SourceEventCondition(
        kind: SourceEventConditionKind.tempSwitch,
        tempSwitchLetter: letter,
        expectedValue: false,
      );
      expect(condition.evaluate(), isNull);
      expect(condition.evaluate(eventTempSwitches: {}), isTrue);
      expect(condition.evaluate(eventTempSwitches: {letter: true}), isFalse);
      expect(
          condition.evaluate(eventTempSwitches: {'other-event:$letter': true}),
          isTrue);
    }
  });

  test('position and direction require supplied execution context', () {
    final condition = SourceEventCondition(
      kind: SourceEventConditionKind.all,
      children: [
        SourceEventCondition(kind: SourceEventConditionKind.playerOnEvent),
        SourceEventCondition(
            kind: SourceEventConditionKind.playerFacing, sourceDirection: 6),
      ],
    );
    expect(condition.evaluate(), isNull);
    expect(condition.evaluate(playerOnEvent: true, playerFacing: 6), isTrue);
    expect(condition.evaluate(playerOnEvent: false), isFalse);
    expect(condition.evaluate(playerOnEvent: true, playerFacing: 4), isFalse);
  });

  test('AND never treats an unavailable or unqualified child as true', () {
    final unavailable = SourceEventCondition(
      kind: SourceEventConditionKind.all,
      children: [
        SourceEventCondition(kind: SourceEventConditionKind.always),
        SourceEventCondition(kind: SourceEventConditionKind.playerOnEvent),
      ],
    );
    expect(unavailable.evaluate(), isNull);
    final unqualified = SourceEventCondition(
      kind: SourceEventConditionKind.all,
      children: [
        SourceEventCondition(kind: SourceEventConditionKind.unqualified),
        SourceEventCondition(
            kind: SourceEventConditionKind.globalSwitch, factId: 'gate'),
      ],
    );
    expect(unqualified.evaluate(), isFalse);
    expect(unqualified.isQualified, isFalse);
    expect(unqualified.evaluate(facts: {'gate': true}), isNull);
    final malformed = SourceEventCondition(
        kind: SourceEventConditionKind.all,
        sourceDirection: 6,
        children: [
          SourceEventCondition(kind: SourceEventConditionKind.always)
        ]);
    expect(malformed.isQualified, isFalse);
    expect(malformed.evaluate(), isNull);
  });

  test('variable minimum is inclusive and item context reaches nested children',
      () {
    final condition = SourceEventCondition(
      kind: SourceEventConditionKind.all,
      children: [
        SourceEventCondition(
            kind: SourceEventConditionKind.variableAtLeast,
            factId: 'count',
            variableId: 1,
            minimum: 3),
        SourceEventCondition(
            kind: SourceEventConditionKind.itemPresence,
            sourceItemSymbol: 'POTION'),
      ],
    );
    expect(condition.evaluate(variables: {1: 2}, itemQuantities: {'POTION': 1}),
        isFalse);
    expect(condition.evaluate(variables: {1: 3}, itemQuantities: {'POTION': 1}),
        isTrue);
    expect(condition.evaluate(variables: {1: 4}), isFalse);
  });
}
